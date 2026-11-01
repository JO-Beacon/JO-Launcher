#include "launch.hpp"

#include "platform/environment.hpp"
#include "platform/paths.hpp"
#include "platform/process.hpp"
#include "platform/system.hpp"
#include "platform/text.hpp"
#include "fs_safe.hpp"
#include "json_io.hpp"
#include "log.hpp"
#include "product_info.hpp"
#include "mc/manifest_lookup.hpp"
#include "secure_wipe.hpp"

#include <algorithm>
#include <array>
#include <chrono>
#include <cctype>
#include <cstdlib>
#include <fstream>
#include <map>
#include <mutex>
#include <optional>
#include <set>
#include <sstream>
#include <stdexcept>
#include <string>
#include <thread>
#include <vector>

#include <miniz.h>
#include <nlohmann/json.hpp>

namespace jol::launch {
namespace {

using json = nlohmann::json;

struct Rule {
    std::string action = "allow";
    std::string os_name;
    std::string os_arch;
    std::map<std::string, bool> features;
};

struct Argument {
    std::vector<std::string> values;
    std::vector<Rule> rules;
};

struct Download {
    std::string path;
    std::string url;
    std::string sha1;
    std::uint64_t size = 0;
};

struct Library {
    std::string name;
    std::vector<Rule> rules;
    std::optional<Download> artifact;
    std::map<std::string, Download> classifiers;
    std::map<std::string, std::string> natives;
};

struct Manifest {
    std::string id;
    std::string parent;
    std::string main_class;
    std::string asset_index;
    std::string asset_index_url;
    std::string asset_index_sha1;
    std::uint64_t asset_index_size = 0;
    std::string assets;
    std::string jar;
    std::string minecraft_arguments;
    std::vector<Argument> game_arguments;
    std::vector<Argument> jvm_arguments;
    std::vector<Library> libraries;
    Download client;
    int java_major = 0;
};

std::string lower(std::string value) {
    std::transform(value.begin(), value.end(), value.begin(),
                   [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
    return value;
}

std::string string_field(const json& value, const char* key) {
    const auto it = value.find(key);
    if (it == value.end() || !it->is_string()) return {};
    return it->get<std::string>();
}

std::vector<Rule> parse_rules(const json& item) {
    std::vector<Rule> rules;
    const auto raw = item.find("rules");
    if (raw == item.end() || !raw->is_array()) return rules;
    for (const auto& entry : *raw) {
        if (!entry.is_object()) continue;
        Rule rule;
        rule.action = string_field(entry, "action");
        if (rule.action.empty()) rule.action = "allow";
        const auto os = entry.find("os");
        if (os != entry.end() && os->is_object()) {
            rule.os_name = string_field(*os, "name");
            rule.os_arch = string_field(*os, "arch");
        }
        const auto features = entry.find("features");
        if (features != entry.end() && features->is_object()) {
            for (const auto& [key, value] : features->items()) {
                if (value.is_boolean()) {
                    rule.features[key] = value.get<bool>();
                }
            }
        }
        rules.push_back(rule);
    }
    return rules;
}

bool feature_state(const std::string& name) {
    // The launcher never enables demo mode, custom resolution or quick play.
    (void)name;
    return false;
}

bool rules_allow(const std::vector<Rule>& rules) {
    if (rules.empty()) return true;
    bool allow = false;
    for (const auto& rule : rules) {
        if (!rule.os_name.empty() && rule.os_name != platform::os_name()) continue;
        if (!rule.os_arch.empty() && rule.os_arch != platform::os_arch()) continue;
        bool matches = true;
        for (const auto& [name, expected] : rule.features) {
            if (feature_state(name) != expected) {
                matches = false;
                break;
            }
        }
        if (!matches) continue;
        allow = rule.action == "allow";
    }
    return allow;
}

std::vector<Argument> parse_arguments(const json& value) {
    std::vector<Argument> out;
    if (!value.is_array()) return out;
    for (const auto& item : value) {
        Argument argument;
        if (item.is_string()) {
            argument.values.push_back(item.get<std::string>());
        } else if (item.is_object()) {
            const auto raw = item.find("value");
            if (raw != item.end()) {
                if (raw->is_string()) {
                    argument.values.push_back(raw->get<std::string>());
                } else if (raw->is_array()) {
                    for (const auto& entry : *raw) {
                        if (entry.is_string()) {
                            argument.values.push_back(entry.get<std::string>());
                        }
                    }
                }
            }
            argument.rules = parse_rules(item);
        }
        if (!argument.values.empty()) out.push_back(std::move(argument));
    }
    return out;
}

Download parse_download(const json& value) {
    Download result;
    result.path = string_field(value, "path");
    result.url = string_field(value, "url");
    result.sha1 = string_field(value, "sha1");
    const auto size = value.find("size");
    if (size != value.end() && size->is_number_unsigned()) {
        result.size = size->get<std::uint64_t>();
    }
    return result;
}

std::vector<Library> parse_libraries(const json& value) {
    std::vector<Library> out;
    if (!value.is_array()) return out;
    for (const auto& item : value) {
        if (!item.is_object()) continue;
        Library library;
        library.name = string_field(item, "name");
        if (library.name.empty()) continue;
        library.rules = parse_rules(item);

        const auto downloads = item.find("downloads");
        if (downloads != item.end() && downloads->is_object()) {
            const auto artifact = downloads->find("artifact");
            if (artifact != downloads->end() && artifact->is_object()) {
                library.artifact = parse_download(*artifact);
            }
            const auto classifiers = downloads->find("classifiers");
            if (classifiers != downloads->end() && classifiers->is_object()) {
                for (const auto& [key, entry] : classifiers->items()) {
                    if (entry.is_object()) {
                        library.classifiers[key] = parse_download(entry);
                    }
                }
            }
        }

        const auto natives = item.find("natives");
        if (natives != item.end() && natives->is_object()) {
            for (const auto& [key, entry] : natives->items()) {
                if (entry.is_string()) {
                    library.natives[key] = entry.get<std::string>();
                }
            }
        }
        out.push_back(std::move(library));
    }
    return out;
}

Manifest parse_manifest(const json& value) {
    Manifest result;
    result.id = string_field(value, "id");
    result.parent = string_field(value, "inheritsFrom");
    result.main_class = string_field(value, "mainClass");
    result.assets = string_field(value, "assets");
    result.jar = string_field(value, "jar");
    result.minecraft_arguments = string_field(value, "minecraftArguments");

    const auto arguments = value.find("arguments");
    if (arguments != value.end() && arguments->is_object()) {
        const auto game = arguments->find("game");
        if (game != arguments->end()) result.game_arguments = parse_arguments(*game);
        const auto jvm = arguments->find("jvm");
        if (jvm != arguments->end()) result.jvm_arguments = parse_arguments(*jvm);
    }
    const auto asset_index = value.find("assetIndex");
    if (asset_index != value.end() && asset_index->is_object()) {
        result.asset_index = string_field(*asset_index, "id");
        result.asset_index_url = string_field(*asset_index, "url");
        result.asset_index_sha1 = string_field(*asset_index, "sha1");
        const auto size = asset_index->find("size");
        if (size != asset_index->end() && size->is_number_unsigned()) {
            result.asset_index_size = size->get<std::uint64_t>();
        }
    }
    const auto downloads = value.find("downloads");
    if (downloads != value.end() && downloads->is_object()) {
        const auto client = downloads->find("client");
        if (client != downloads->end() && client->is_object()) {
            result.client = parse_download(*client);
        }
    }
    const auto libraries = value.find("libraries");
    if (libraries != value.end()) result.libraries = parse_libraries(*libraries);
    const auto java = value.find("javaVersion");
    if (java != value.end() && java->is_object()) {
        const auto major = java->find("majorVersion");
        if (major != java->end() && major->is_number_integer()) {
            result.java_major = major->get<int>();
        }
    }
    return result;
}

std::filesystem::path find_manifest(const std::filesystem::path& dir,
                                    const std::string& name) {
    return mc::find_manifest_file(dir, name);
}

bool valid_version_name(const std::string& name) {
    if (name.empty()) return false;
    if (name.find('/') != std::string::npos) return false;
    if (name.find('\\') != std::string::npos) return false;
    return fs::safe_segment(name);
}

Manifest load_manifest(const std::filesystem::path& game_dir,
                       const std::string& name,
                       std::set<std::string>& seen) {
    if (!valid_version_name(name)) {
        throw std::runtime_error("Invalid version name: " + name);
    }
    if (seen.size() >= 16) {
        throw std::runtime_error("Version inheritance is too deep: " + name);
    }
    std::string loop_key = name;
    std::transform(loop_key.begin(), loop_key.end(), loop_key.begin(),
                   [](unsigned char c) {
                       return static_cast<char>(std::tolower(c));
                   });
    if (!seen.insert(loop_key).second) {
        throw std::runtime_error("Version inheritance loop: " + name);
    }
    const auto versions_dir = game_dir / L"versions";
    const auto dir = versions_dir / platform::path_from_utf8(name);
    if (!fs::is_within(versions_dir, dir)) {
        throw std::runtime_error("Version path is outside the game directory.");
    }
    const auto file = find_manifest(dir, name);
    if (file.empty()) {
        throw std::runtime_error("Version manifest not found: " + name);
    }

    json value;
    try {
        value = jsonio::read(file);
    } catch (...) {
        throw std::runtime_error("Could not read version manifest: " +
                                 file.string());
    }
    Manifest child = parse_manifest(value);
    if (child.parent.empty()) return child;

    Manifest parent = load_manifest(game_dir, child.parent, seen);
    Manifest merged = parent;
    merged.id = child.id.empty() ? parent.id : child.id;
    merged.parent.clear();
    if (!child.main_class.empty()) merged.main_class = child.main_class;
    if (!child.asset_index.empty()) merged.asset_index = child.asset_index;
    if (!child.asset_index_url.empty()) {
        merged.asset_index_url = child.asset_index_url;
    }
    if (!child.asset_index_sha1.empty()) {
        merged.asset_index_sha1 = child.asset_index_sha1;
    }
    if (child.asset_index_size != 0) {
        merged.asset_index_size = child.asset_index_size;
    }
    if (!child.client.url.empty()) merged.client = child.client;
    if (!child.assets.empty()) merged.assets = child.assets;
    if (!child.jar.empty()) {
        merged.jar = child.jar;
    } else if (!parent.jar.empty()) {
        merged.jar = parent.jar;
    } else if (!parent.id.empty()) {
        // Inherited versions (Fabric, Quilt, ...) usually ship no client jar
        // of their own and rely on the base version's jar.
        merged.jar = parent.id;
    }
    if (!child.minecraft_arguments.empty()) {
        merged.minecraft_arguments = child.minecraft_arguments;
    }
    if (child.java_major != 0) merged.java_major = child.java_major;
    merged.game_arguments.insert(merged.game_arguments.end(),
                                child.game_arguments.begin(),
                                child.game_arguments.end());
    merged.jvm_arguments.insert(merged.jvm_arguments.end(),
                                child.jvm_arguments.begin(),
                                child.jvm_arguments.end());
    {
        // Forge and NeoForge re-declare some parent libraries with newer
        // versions. Key them by group:artifact so the child entry replaces the
        // parent one instead of ending up twice on the classpath.
        std::map<std::string, Library> by_key;
        std::vector<std::string> order;
        const auto add = [&by_key, &order](const Library& library) {
            // Key on group:artifact[:classifier] so a child build can replace
            // a parent library version without dropping native classifiers.
            std::vector<std::string> parts;
            std::string current;
            for (const char c : library.name) {
                if (c == ':') {
                    parts.push_back(current);
                    current.clear();
                } else {
                    current.push_back(c);
                }
            }
            parts.push_back(current);
            std::string key = parts.empty() ? library.name : parts[0];
            if (parts.size() >= 2) key += ":" + parts[1];
            if (parts.size() >= 4) key += ":" + parts[3];
            if (by_key.find(key) == by_key.end()) order.push_back(key);
            by_key[key] = library;
        };
        for (const auto& library : merged.libraries) add(library);
        for (const auto& library : child.libraries) add(library);
        merged.libraries.clear();
        for (const auto& key : order) {
            merged.libraries.push_back(by_key[key]);
        }
    }
    return merged;
}

std::string artifact_path(const std::string& name) {
    std::vector<std::string> parts;
    std::string part;
    for (const char c : name) {
        if (c == ':') {
            parts.push_back(part);
            part.clear();
        } else {
            part.push_back(c);
        }
    }
    parts.push_back(part);
    if (parts.size() < 3) return {};
    const std::string& group = parts[0];
    const std::string& artifact = parts[1];
    const std::string& version = parts[2];
    std::string path = group;
    std::replace(path.begin(), path.end(), '.', '/');
    path += "/" + artifact + "/" + version + "/" + artifact + "-" + version;
    if (parts.size() > 3) path += "-" + parts[3];
    return path + ".jar";
}

std::wstring widen(const std::string& value) {
    return platform::widen(value);
}

std::string narrow(const std::filesystem::path& value) {
    return platform::path_to_utf8(value);
}

std::vector<std::filesystem::path> path_entries(
    const std::filesystem::path& value) {
    std::vector<std::filesystem::path> result;
    const char separator = platform::classpath_separator();
    const std::string text = platform::path_to_utf8(value);
    std::size_t start = 0;
    while (start <= text.size()) {
        const std::size_t end = text.find(separator, start);
        const std::string part = text.substr(
            start, end == std::string::npos ? std::string::npos : end - start);
        if (!part.empty()) result.push_back(platform::path_from_utf8(part));
        if (end == std::string::npos) break;
        start = end + 1;
    }
    return result;
}

std::vector<std::filesystem::path> java_names_in(
    const std::filesystem::path& dir) {
    std::vector<std::filesystem::path> result;
    for (const auto& name :
         {platform::java_console_name(), platform::java_windowless_name()}) {
        if (!name.empty()) result.push_back(dir / platform::path_from_utf8(name));
    }
    return result;
}

std::string replace_variables(std::string value,
                              const std::map<std::string, std::string>& vars) {
    for (const auto& [key, replacement] : vars) {
        const std::string needle = "${" + key + "}";
        for (size_t pos = 0; (pos = value.find(needle, pos)) !=
                             std::string::npos;) {
            value.replace(pos, needle.size(), replacement);
            pos += replacement.size();
        }
    }
    return value;
}

std::vector<std::string> expand_arguments(
    const std::vector<Argument>& arguments,
    const std::map<std::string, std::string>& variables) {
    std::vector<std::string> out;
    for (const auto& argument : arguments) {
        if (!rules_allow(argument.rules)) continue;
        for (const auto& value : argument.values) {
            out.push_back(replace_variables(value, variables));
        }
    }
    return out;
}

std::vector<std::string> split_arguments(const std::string& value) {
    std::vector<std::string> out;
    std::string current;
    bool quoted = false;
    for (const char c : value) {
        if (c == '"') {
            quoted = !quoted;
            continue;
        }
        if (!quoted && std::isspace(static_cast<unsigned char>(c))) {
            if (!current.empty()) {
                out.push_back(current);
                current.clear();
            }
            continue;
        }
        current.push_back(c);
    }
    if (!current.empty()) out.push_back(current);
    return out;
}

bool has_classpath(const std::vector<std::string>& args) {
    return std::find(args.begin(), args.end(), "-cp") != args.end() ||
           std::find(args.begin(), args.end(), "-classpath") != args.end();
}

std::optional<JavaRuntime> probe_java(
    const std::filesystem::path& executable,
    const std::atomic_bool* cancelled = nullptr);

std::filesystem::path find_java(const LaunchRequest& request,
                                const Manifest& manifest) {
    const int required = manifest.java_major;

    if (!request.java_path.empty()) {
        const auto info = probe_java(request.java_path);
        if (!info) {
            throw JavaError(
                "The configured Java path is not a usable Java runtime: " +
                narrow(request.java_path));
        }
        if (required > 0 && info->major < required) {
            throw JavaError("Java " + std::to_string(info->major) +
                            " is too old for this version; Java " +
                            std::to_string(required) + " or newer is required.");
        }
        return info->path;
    }

    std::vector<std::filesystem::path> candidates;
    if (const auto home = platform::environment_path("JAVA_HOME");
        home && !home->empty()) {
        for (const auto& candidate : java_names_in(*home / L"bin")) {
            candidates.push_back(candidate);
        }
    }
    if (const auto path = platform::environment_path("PATH");
        path && !path->empty()) {
        for (const auto& dir : path_entries(*path)) {
            for (const auto& candidate : java_names_in(dir)) {
                candidates.push_back(candidate);
            }
        }
    }
    if (const auto runtime = platform::launcher_runtime_dir();
        !runtime.empty()) {
        std::error_code ec;
        if (std::filesystem::is_directory(runtime, ec)) {
            for (const auto& entry :
                 std::filesystem::recursive_directory_iterator(runtime, ec)) {
                if (ec) break;
                if (!entry.is_regular_file()) continue;
                const std::string name =
                    platform::path_to_utf8(entry.path().filename());
                if (name == platform::java_windowless_name() ||
                    name == platform::java_console_name()) {
                    candidates.push_back(entry.path());
                }
            }
        }
    }

    std::optional<JavaRuntime> best;
    for (const auto& candidate : candidates) {
        std::error_code ec;
        if (!std::filesystem::is_regular_file(candidate, ec)) continue;
        const auto info = probe_java(candidate);
        if (!info) continue;
        if (required > 0 && info->major < required) continue;
        if (!best || info->major < best->major) best = info;
    }
    if (best) return best->path;

    // detect_java_runtimes() sorts newest first; walking it backwards picks
    // the smallest major that satisfies the requirement, which is what old
    // Minecraft versions need.
    const std::vector<JavaRuntime> runtimes = detect_java_runtimes();
    for (auto it = runtimes.rbegin(); it != runtimes.rend(); ++it) {
        if (required == 0 || it->major >= required) return it->path;
    }
    if (runtimes.empty()) {
        throw JavaError(
            "No Java runtime was found; choose one in Version settings.");
    }
    throw JavaError("No Java " + std::to_string(required) +
                    " or newer was found; the newest installed is Java " +
                    std::to_string(runtimes.front().major) + ".");
}

std::filesystem::path resolve_inside(const std::filesystem::path& base,
                                    const std::string& relative,
                                    const char* what) {
    const auto rel = platform::path_from_utf8(relative);
    if (rel.empty() || rel.is_absolute() || rel.has_root_name() ||
        rel.has_root_directory()) {
        throw std::runtime_error(std::string("Invalid ") + what + " path.");
    }
    for (const auto& part : rel) {
        const std::string text = platform::path_to_utf8(part);
        if (text.empty() || text == "." || text == ".." ||
            text.back() == '.' || text.back() == ' ' ||
            text.find(':') != std::string::npos) {
            throw std::runtime_error(std::string("Invalid ") + what +
                                     " path.");
        }
    }
    const auto target = base / rel;
    if (!fs::is_within(base, target)) {
        throw std::runtime_error(std::string("Unsafe ") + what + " path.");
    }
    return target;
}

void extract_natives(const Manifest& manifest,
                     const std::filesystem::path& libraries_dir,
                     const std::filesystem::path& natives_dir) {
    std::error_code ec;
    if (platform::is_reparse_point(natives_dir)) {
        throw std::runtime_error("The natives directory is a link.");
    }
    // Drop the previous extraction so stale natives from another version
    // cannot be loaded.
    std::filesystem::remove_all(natives_dir, ec);
    std::filesystem::create_directories(natives_dir, ec);
    for (const auto& library : manifest.libraries) {
        if (!rules_allow(library.rules)) continue;
        const auto native = library.natives.find(platform::natives_classifier());
        if (native == library.natives.end()) continue;
        std::string classifier = native->second;
        const std::string arch =
            std::string(platform::os_arch()) == "x86" ? "32" : "64";
        for (size_t pos = 0; (pos = classifier.find("${arch}", pos)) !=
                             std::string::npos;) {
            classifier.replace(pos, 6, arch);
            pos += arch.size();
        }
        const auto download = library.classifiers.find(classifier);
        if (download == library.classifiers.end()) continue;
        const auto jar =
            resolve_inside(libraries_dir, download->second.path, "native");
        if (platform::is_reparse_point(jar)) {
            throw std::runtime_error("Native library is a link.");
        }
        if (!std::filesystem::is_regular_file(jar)) {
            throw std::runtime_error("Native library is missing: " + narrow(jar));
        }

        mz_zip_archive archive{};
        const std::string jar_text = narrow(jar);
        if (!mz_zip_reader_init_file(&archive, jar_text.c_str(), 0)) {
            throw std::runtime_error("Could not read natives archive: " +
                                     jar_text);
        }
        constexpr std::uint64_t kMaxNativeBytes = 512ull * 1024 * 1024;
        std::uint64_t native_bytes = 0;
        const mz_uint native_count = mz_zip_reader_get_num_files(&archive);
        if (native_count > 10000) {
            mz_zip_reader_end(&archive);
            throw std::runtime_error(
                "Native archive contains too many entries.");
        }
        for (unsigned int i = 0; i < native_count; ++i) {
            const mz_uint name_size = mz_zip_reader_get_filename(
                &archive, i, nullptr, 0);
            if (name_size == 0) continue;
            std::string name(name_size, '\0');
            mz_zip_reader_get_filename(&archive, i, name.data(), name_size);
            if (name.size() > 1 && name.back() == '\0') name.pop_back();
            std::replace(name.begin(), name.end(), '\\', '/');
            std::string lowered = name;
            std::transform(lowered.begin(), lowered.end(), lowered.begin(),
                           [](unsigned char c) {
                               return static_cast<char>(std::tolower(c));
                           });
            if (lowered.rfind("meta-inf/", 0) == 0) continue;
            if (!name.empty() && name.back() == '/') continue;

            mz_zip_archive_file_stat stat{};
            if (!mz_zip_reader_file_stat(&archive, i, &stat)) continue;
            if (stat.m_is_directory) continue;

            const std::filesystem::path entry = platform::path_from_utf8(name);
            if (entry.has_root_name() || entry.has_root_directory()) continue;

            bool safe = true;
            std::string part;
            for (const char c : std::string(name + '/')) {
                if (c == '/') {
                    if (!part.empty() && !fs::safe_segment(part)) safe = false;
                    part.clear();
                } else {
                    part.push_back(c);
                }
            }
            if (!safe) continue;

            const auto output = natives_dir / entry;
            if (!fs::is_within(natives_dir, output)) continue;

            const std::uint64_t entry_bytes =
                std::max(stat.m_uncomp_size, stat.m_comp_size);
            if (entry_bytes > kMaxNativeBytes - native_bytes) {
                mz_zip_reader_end(&archive);
                throw std::runtime_error("Native archive is too large.");
            }
            native_bytes += entry_bytes;
            std::filesystem::create_directories(output.parent_path(), ec);
            if (!mz_zip_reader_extract_to_file(&archive, i,
                                                narrow(output).c_str(), 0)) {
                mz_zip_reader_end(&archive);
                throw std::runtime_error("Could not extract native: " + name);
            }
        }
        mz_zip_reader_end(&archive);
    }
}

}  // namespace

struct GameProcess::Impl {
    platform::ChildProcess child;
};

GameProcess::GameProcess() = default;
GameProcess::~GameProcess() = default;
GameProcess::GameProcess(GameProcess&&) noexcept = default;
GameProcess& GameProcess::operator=(GameProcess&&) noexcept = default;
GameProcess::GameProcess(std::unique_ptr<Impl> impl) : impl_(std::move(impl)) {}

bool GameProcess::valid() const {
    return impl_ != nullptr && impl_->child.valid();
}

bool GameProcess::running() const {
    return valid() && impl_->child.running();
}

int GameProcess::pid() const { return valid() ? impl_->child.pid() : 0; }

void GameProcess::stop() {
    if (valid()) impl_->child.stop();
}

int GameProcess::wait() { return valid() ? impl_->child.wait() : -1; }

std::string GameProcess::take_output() {
    return impl_ == nullptr ? std::string() : impl_->child.take_output();
}

std::string GameProcess::take_output_after_exit(std::uint32_t timeout_ms) {
    return impl_ == nullptr ? std::string()
                            : impl_->child.take_output_after_exit(timeout_ms);
}

std::optional<int> required_java_major(const std::filesystem::path& game_dir,
                                       const std::string& version_name) {
    std::set<std::string> seen;
    const Manifest manifest = load_manifest(game_dir, version_name, seen);
    if (manifest.java_major > 0) return manifest.java_major;
    return std::nullopt;
}

namespace {

std::string read_java_version(const std::filesystem::path& java_exe,
                              const std::atomic_bool* cancelled) {
    platform::ProcessSpawn spawn;
    spawn.executable = java_exe;
    spawn.arguments = {"-version"};
    std::string error;
    auto child = platform::spawn_process(spawn, error);
    if (!child) return {};
    // A wedged runtime must not block the caller.
    const auto deadline =
        std::chrono::steady_clock::now() + std::chrono::seconds(5);
    while (child->wait(100) < 0) {
        if ((cancelled != nullptr && cancelled->load()) ||
            std::chrono::steady_clock::now() >= deadline) {
            child->stop();
            child->wait(1000);
            break;
        }
    }
    for (int i = 0; i < 200 && !child->output_closed(); ++i) {
        std::this_thread::sleep_for(std::chrono::milliseconds(5));
    }
    const std::string output = child->take_output();
    const size_t marker = output.find("version \"");
    if (marker == std::string::npos) return {};
    const size_t begin = marker + 9;
    const size_t quote_end = output.find('"', begin);
    if (quote_end == std::string::npos) return {};
    return output.substr(begin, quote_end - begin);
}

int major_from_version(const std::string& version) {
    if (version.rfind("1.", 0) == 0) {
        return std::atoi(version.c_str() + 2);
    }
    return std::atoi(version.c_str());
}

std::optional<JavaRuntime> probe_java(
    const std::filesystem::path& executable,
    const std::atomic_bool* cancelled) {
    const std::string file_name = platform::path_to_utf8(executable.filename());
    if (file_name != platform::java_console_name() &&
        file_name != platform::java_windowless_name()) {
        return std::nullopt;
    }
    std::error_code file_ec;
    if (!std::filesystem::is_regular_file(executable, file_ec)) {
        return std::nullopt;
    }
    const std::filesystem::path probe = platform::console_java(executable);
    const std::string version = read_java_version(probe, cancelled);
    const int major = major_from_version(version);
    if (major <= 0) return std::nullopt;
    JavaRuntime result;
    result.path = executable;
    result.major = major;
    result.version = version;
    return result;
}

void add_runtime(std::vector<JavaRuntime>& runtime,
                 std::set<std::string>& seen,
                 const std::filesystem::path& executable,
                 const std::atomic_bool* cancelled) {
    std::error_code ec;
    const auto canonical = std::filesystem::weakly_canonical(executable, ec);
    const std::string key = (ec ? executable : canonical).string();
    if (key.empty() || seen.contains(key)) return;
    seen.insert(key);
    if (cancelled != nullptr && cancelled->load()) return;
    if (const auto info = probe_java(executable, cancelled)) {
        runtime.push_back(*info);
    }
}

void add_bin(std::vector<JavaRuntime>& runtime,
             std::set<std::string>& seen,
             const std::filesystem::path& home,
             const std::atomic_bool* cancelled) {
    for (const auto& name :
         {platform::java_console_name(), platform::java_windowless_name()}) {
        if (name.empty()) continue;
        add_runtime(runtime, seen,
                    home / L"bin" / platform::path_from_utf8(name),
                    cancelled);
    }
}

}  // namespace

std::optional<JavaRuntime> inspect_java(
    const std::filesystem::path& executable) {
    return probe_java(executable);
}

std::vector<JavaRuntime> detect_java_runtimes(
    const std::atomic_bool* cancelled) {
    std::vector<JavaRuntime> runtime;
    std::set<std::string> seen;
    if (const auto home = platform::environment_path("JAVA_HOME");
        home && !home->empty()) {
        add_bin(runtime, seen, std::filesystem::path(*home), cancelled);
    }
    if (const auto path = platform::environment_path("PATH");
        path && !path->empty()) {
        for (const auto& dir : path_entries(*path)) {
            for (const auto& candidate : java_names_in(dir)) {
                add_runtime(runtime, seen, candidate, cancelled);
            }
        }
    }
    const std::vector<std::filesystem::path> roots = platform::java_roots();
    for (const auto& root : roots) {
        std::error_code ec;
        if (cancelled != nullptr && cancelled->load()) break;
        if (std::filesystem::is_directory(root / L"bin", ec)) {
            add_bin(runtime, seen, root, cancelled);
        }
        if (!std::filesystem::is_directory(root, ec)) continue;
        for (const auto& entry :
             std::filesystem::directory_iterator(root, ec)) {
            if (ec) break;
            if (!entry.is_directory()) continue;
            add_bin(runtime, seen, entry.path(), cancelled);
        }
    }
    std::sort(runtime.begin(), runtime.end(),
              [](const JavaRuntime& a, const JavaRuntime& b) {
                  return a.major > b.major;
              });
    return runtime;
}


GameProcess start(const LaunchRequest& request) {
    std::set<std::string> seen;
    const Manifest manifest =
        load_manifest(request.game_dir, request.version_name, seen);
    if (manifest.main_class.empty()) {
        throw std::runtime_error("Version manifest has no main class.");
    }

    const auto version_dir =
        request.game_dir / L"versions" /
        platform::path_from_utf8(request.version_name);
    const auto libraries_dir = request.game_dir / L"libraries";
    const auto natives_dir = version_dir / L"natives";
    const auto assets_dir = request.game_dir / L"assets";

    std::vector<std::string> classpath;
    auto add_classpath = [&classpath](const std::filesystem::path& path) {
        const std::string text = narrow(path);
        if (std::find(classpath.begin(), classpath.end(), text) == classpath.end()) {
            classpath.push_back(text);
        }
    };

    for (const auto& library : manifest.libraries) {
        if (!rules_allow(library.rules)) continue;
        std::filesystem::path file;
        if (library.artifact && !library.artifact->path.empty()) {
            file = resolve_inside(libraries_dir, library.artifact->path,
                                  "library");
        } else if (!library.natives.empty()) {
            // Natives-only entry: its jar belongs in the natives directory,
            // not on the classpath.
            continue;
        } else {
            const std::string derived = artifact_path(library.name);
            if (derived.empty()) continue;
            file = resolve_inside(libraries_dir, derived, "library");
        }
        if (!std::filesystem::is_regular_file(file)) {
            throw std::runtime_error("Library is missing: " + narrow(file));
        }
        add_classpath(file);
    }

    std::string jar_name = manifest.jar.empty() ? request.version_name : manifest.jar;
    auto client_jar = resolve_inside(version_dir, jar_name + ".jar", "jar");
    if (!std::filesystem::is_regular_file(client_jar)) {
        client_jar = resolve_inside(request.game_dir / L"versions", 
                                    jar_name + "/" + jar_name + ".jar", "jar");
    }
    if (!std::filesystem::is_regular_file(client_jar)) {
        throw std::runtime_error("Client jar is missing: " + narrow(client_jar));
    }
    add_classpath(client_jar);

    extract_natives(manifest, libraries_dir, natives_dir);

    std::string asset_index = manifest.asset_index.empty()
                                  ? manifest.assets
                                  : manifest.asset_index;
    if (asset_index.empty()) {
        throw std::runtime_error("Version manifest has no asset index.");
    }
    const auto asset_file = resolve_inside(assets_dir / L"indexes",
                                           asset_index + ".json", "asset index");
    if (!std::filesystem::is_regular_file(asset_file)) {
        throw std::runtime_error("Asset index is missing: " +
                                 narrow(asset_file));
    }

    const auto java = find_java(request, manifest);
    const std::string classpath_text = [&classpath] {
        std::string out;
        for (size_t i = 0; i < classpath.size(); ++i) {
            if (i != 0) out += platform::classpath_separator();
            out += classpath[i];
        }
        return out;
    }();

    std::map<std::string, std::string> variables{
        {"auth_player_name", request.account.name},
        {"version_name", request.version_name},
        {"game_directory", narrow(version_dir)},
        {"assets_root", narrow(assets_dir)},
        {"assets_index_name", asset_index},
        {"auth_uuid", request.account.uuid},
        {"auth_access_token", request.account.access_token},
        {"auth_session", "token:" + request.account.access_token + ":" +
                              request.account.uuid},
        {"clientid", request.client_id},
        {"auth_xuid", ""},
        {"user_type", "msa"},
        {"version_type", "release"},
        {"user_properties", "{}"},
        {"natives_directory", narrow(natives_dir)},
        {"classpath", classpath_text},
        {"classpath_separator",
         std::string(1, platform::classpath_separator())},
        {"library_directory", narrow(libraries_dir)},
        {"game_assets",
         narrow(assets_dir / L"virtual" /
                std::filesystem::path(widen(asset_index)))},
        {"launcher_name", "JO-Launcher"},
        {"launcher_version", jol::kVersion},
        {"resolution_width", "854"},
        {"resolution_height", "480"},
    };

    std::vector<std::string> jvm =
        expand_arguments(manifest.jvm_arguments, variables);
    if (jvm.empty()) {
        jvm.push_back("-Djava.library.path=" + variables["natives_directory"]);
        jvm.push_back("-cp");
        jvm.push_back(classpath_text);
    } else if (!has_classpath(jvm)) {
        jvm.push_back("-cp");
        jvm.push_back(classpath_text);
    }
    int min_memory = static_cast<int>(request.min_memory_mb);
    int max_memory = static_cast<int>(request.max_memory_mb);
    if (max_memory <= 0) {
        // No explicit limit: plan something sensible from the machine's RAM.
        const std::uint64_t total_bytes = platform::total_physical_memory();
        const int total_mb = static_cast<int>(total_bytes / (1024ull * 1024ull));
        if (total_mb > 0) {
            const auto mentions_loader = [](const std::string& text) {
                const std::string lowered = lower(text);
                return lowered.find("forge") != std::string::npos ||
                       lowered.find("fabric") != std::string::npos ||
                       lowered.find("quilt") != std::string::npos;
            };
            bool modded = mentions_loader(manifest.main_class) ||
                          mentions_loader(manifest.id);
            if (!modded) {
                for (const auto& library : manifest.libraries) {
                    if (mentions_loader(library.name)) {
                        modded = true;
                        break;
                    }
                }
            }
            if (!modded) {
                std::error_code mods_ec;
                modded = std::filesystem::is_directory(version_dir / L"mods",
                                                       mods_ec) ||
                         std::filesystem::is_directory(
                             request.game_dir / L"mods", mods_ec);
            }
            const int divisor = modded ? 3 : 4;
            max_memory = total_mb / divisor;
            max_memory = std::clamp(max_memory, modded ? 2048 : 1024,
                                    modded ? 12288 : 8192);
            if (max_memory > total_mb - 1024) {
                max_memory = std::max(1024, total_mb - 1024);
            }
            if (min_memory <= 0) min_memory = 512;
            jol::log::info("launch",
                           "auto memory: " + std::to_string(max_memory) +
                               " MB (physical " + std::to_string(total_mb) +
                               " MB)");
        }
    }
    if (min_memory > 0) {
        jvm.push_back("-Xms" + std::to_string(min_memory) + "M");
    }
    if (max_memory > 0) {
        jvm.push_back("-Xmx" + std::to_string(max_memory) + "M");
    }
    for (const auto& part : split_arguments(request.jvm_args)) {
        jvm.push_back(part);
    }

    std::vector<std::string> game =
        expand_arguments(manifest.game_arguments, variables);
    if (game.empty() && !manifest.minecraft_arguments.empty()) {
        game = split_arguments(manifest.minecraft_arguments);
        for (auto& part : game) part = replace_variables(part, variables);
    }

    std::vector<std::string> arguments = jvm;
    arguments.push_back(manifest.main_class);
    arguments.insert(arguments.end(), game.begin(), game.end());

    platform::ProcessSpawn spawn;
    spawn.executable = java;
    spawn.arguments = std::move(arguments);
    spawn.working_directory = version_dir;

    std::string error;
    auto child = platform::spawn_process(spawn, error);
    if (!child) throw std::runtime_error(error);

    for (auto& [key, value] : variables) {
        if (key == "auth_access_token" || key == "auth_session") {
            secure::clear_string(value);
        }
    }
    for (auto& argument : game) {
        secure::clear_string(argument);
    }
    for (auto& argument : jvm) {
        secure::clear_string(argument);
    }
    for (auto& argument : spawn.arguments) {
        secure::clear_string(argument);
    }

    auto impl = std::unique_ptr<GameProcess::Impl>(new GameProcess::Impl());
    impl->child = std::move(*child);
    return GameProcess(std::move(impl));
}

}  // namespace jol::launch
