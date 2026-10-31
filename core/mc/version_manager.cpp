#include "json_io.hpp"
#include "platform/paths.hpp"
#include "version_manager.hpp"

#include "fs_safe.hpp"
#include "platform/text.hpp"
#include "manifest_lookup.hpp"

#include <algorithm>
#include <chrono>
#include <random>
#include <fstream>
#include <stdexcept>
#include <system_error>
#include <vector>

#include <miniz.h>
#include <nlohmann/json.hpp>

namespace jol {
namespace {

using json = nlohmann::json;

std::string narrow(const std::wstring& value) {
    return platform::narrow(value);
}

void validateName(const std::string& name) {
    if (name.empty() || name == "." || name == "..") {
        throw std::runtime_error("Version name must not be empty.");
    }
    if (name.find_first_of("\\/:*?\"<>|") != std::string::npos) {
        throw std::runtime_error("Version name contains an invalid character.");
    }
    if (name.back() == ' ' || name.back() == '.' || name.front() == ' ') {
        throw std::runtime_error(
            "Version name must not start or end with a space or dot.");
    }
    for (const char c : name) {
        if (static_cast<unsigned char>(c) < 0x20) {
            throw std::runtime_error(
                "Version name contains a control character.");
        }
    }
    std::string upper = name;
    std::transform(upper.begin(), upper.end(), upper.begin(),
                   [](unsigned char c) {
                       return static_cast<char>(std::toupper(c));
                   });
    const auto dot = upper.find('.');
    if (dot != std::string::npos) upper.resize(dot);
    static const char* kReserved[] = {"CON",  "PRN",  "AUX",  "NUL",
                                      "COM1", "COM2", "COM3", "COM4",
                                      "COM5", "COM6", "COM7", "COM8",
                                      "COM9", "LPT1", "LPT2", "LPT3",
                                      "LPT4", "LPT5", "LPT6", "LPT7",
                                      "LPT8", "LPT9"};
    for (const char* reserved : kReserved) {
        if (upper == reserved) {
            throw std::runtime_error(
                "Version name is reserved by Windows.");
        }
    }
}

std::filesystem::path versionDir(const std::filesystem::path& game_dir,
                                 const std::string& name) {
    return game_dir / L"versions" / platform::path_from_utf8(name);
}

std::filesystem::path findManifest(const std::filesystem::path& dir,
                                  const std::string& preferred) {
    return mc::find_manifest_file(dir, preferred);
}

json readJson(const std::filesystem::path& file) {
    json root = jsonio::read(file);
    if (!root.is_object()) {
        throw std::runtime_error("Version manifest is not an object.");
    }
    return root;
}

void writeJson(const std::filesystem::path& file, const json& root) {
    std::filesystem::path temp = file;
    temp += L".tmp";
    {
        std::ofstream stream(temp, std::ios::binary | std::ios::trunc);
        if (!stream) throw std::runtime_error("Could not write version manifest.");
        stream << root.dump(2, ' ', false, nlohmann::json::error_handler_t::replace) << '\n';
        if (!stream) throw std::runtime_error("Could not write version manifest.");
    }
    std::error_code ec;
    if (!platform::atomic_replace(temp, file)) {
        std::filesystem::remove(temp, ec);
        throw std::runtime_error("Could not replace version manifest.");
    }
    if (ec) throw std::runtime_error("Could not replace version manifest.");
}

void renameManifestFile(const std::filesystem::path& dir,
                        const std::string& old_name,
                        const std::string& new_name) {
    const auto manifest = findManifest(dir, old_name.empty() ? new_name
                                                             : old_name);
    if (manifest.empty()) {
        throw std::runtime_error("Version manifest not found.");
    }
    json root = readJson(manifest);
    root["id"] = new_name;
    if (!old_name.empty() && root.contains("jar") && root["jar"].is_string() &&
        root["jar"].get<std::string>() == old_name) {
        root["jar"] = new_name;
    }
    writeJson(manifest, root);

    const auto target = dir / platform::path_from_utf8(new_name + ".json");
    if (manifest != target) {
        std::error_code ec;
        std::filesystem::rename(manifest, target, ec);
        if (ec) throw std::runtime_error("Could not rename version manifest.");
    }
}

bool hasVersionManifest(const std::filesystem::path& dir) {
    const auto manifest = findManifest(dir, fs::to_utf8(dir.filename()));
    if (manifest.empty()) return false;
    try {
        const json root = readJson(manifest);
        return root.contains("id") || root.contains("mainClass") ||
               root.contains("inheritsFrom");
    } catch (...) {
        return false;
    }
}

std::filesystem::path resolveSource(const std::filesystem::path& root) {
    std::vector<std::filesystem::path> candidates;
    std::error_code ec;
    const auto versions = root / L"versions";
    if (std::filesystem::is_directory(versions, ec)) {
        for (const auto& entry : std::filesystem::directory_iterator(versions, ec)) {
            if (ec) break;
            if (entry.is_directory() && hasVersionManifest(entry.path())) {
                candidates.push_back(entry.path());
            }
        }
    }
    if (hasVersionManifest(root)) return root;
    for (const auto& entry : std::filesystem::directory_iterator(root, ec)) {
        if (ec) break;
        if (entry.is_directory() && hasVersionManifest(entry.path())) {
            candidates.push_back(entry.path());
        }
    }
    if (candidates.size() == 1) return candidates.front();
    if (candidates.size() > 1) {
        throw std::runtime_error("Archive contains multiple versions.");
    }
    throw std::runtime_error("Archive contains no version manifest.");
}

std::string manifestId(const std::filesystem::path& dir) {
    const auto manifest = findManifest(dir, fs::to_utf8(dir.filename()));
    if (manifest.empty()) return {};
    try {
        const json root = readJson(manifest);
        const auto id = root.find("id");
        if (id != root.end() && id->is_string()) return id->get<std::string>();
    } catch (...) {
        // Fall through to the folder name.
    }
    return {};
}

void extractZip(const std::filesystem::path& zip_path,
                const std::filesystem::path& target) {
    mz_zip_archive archive{};
    const std::string zip_text = narrow(zip_path.wstring());
    if (!mz_zip_reader_init_file(&archive, zip_text.c_str(), 0)) {
        throw std::runtime_error("Could not read the zip archive.");
    }

    const auto fail = [&archive](const std::string& message) {
        mz_zip_reader_end(&archive);
        throw std::runtime_error(message);
    };

    std::error_code ec;
    constexpr std::uint64_t kMaxTotalBytes = 2ull * 1024 * 1024 * 1024;
    std::uint64_t total_bytes = 0;
    const mz_uint file_count = mz_zip_reader_get_num_files(&archive);
    if (file_count > 200000) fail("Archive contains too many entries.");
    for (unsigned int i = 0; i < file_count; ++i) {
        mz_zip_archive_file_stat stat{};
        if (!mz_zip_reader_file_stat(&archive, i, &stat)) {
            fail("Archive contains an unreadable entry.");
        }
        // A stored entry writes m_comp_size bytes even when m_uncomp_size
        // claims something smaller, so count the larger of the two.
        const std::uint64_t entry_bytes =
            std::max(stat.m_uncomp_size, stat.m_comp_size);
        if (entry_bytes > kMaxTotalBytes - total_bytes) {
            fail("Archive is too large when unpacked.");
        }
        total_bytes += entry_bytes;
        const mz_uint name_size = mz_zip_reader_get_filename(
            &archive, i, nullptr, 0);
        if (name_size == 0) fail("Archive contains an invalid entry name.");
        std::string name(name_size, '\0');
        mz_zip_reader_get_filename(&archive, i, name.data(), name_size);
        if (!name.empty() && name.back() == '\0') name.pop_back();
        std::replace(name.begin(), name.end(), '\\', '/');

        std::vector<std::string> parts;
        std::string part;
        for (const char c : name) {
            if (c == '/') {
                if (!part.empty()) parts.push_back(part);
                part.clear();
            } else {
                part.push_back(c);
            }
        }
        if (!part.empty()) parts.push_back(part);
        if (name.empty() || name.front() == '/' || parts.empty()) {
            fail("Archive contains an unsafe path.");
        }
        for (const auto& segment : parts) {
            if (!fs::safe_segment(segment)) {
                fail("Archive contains an unsafe path.");
            }
        }

        std::filesystem::path output = target;
        for (const auto& segment : parts) output /= platform::path_from_utf8(segment);
        if (!fs::is_within(target, output)) {
            fail("Archive contains an unsafe path.");
        }
        const bool is_directory = !name.empty() && name.back() == '/';
        if (is_directory) {
            std::filesystem::create_directories(output, ec);
            if (ec) fail("Could not create an archive directory.");
            continue;
        }
        std::filesystem::create_directories(output.parent_path(), ec);
        if (ec) fail("Could not create an archive directory.");
        if (!mz_zip_reader_extract_to_file(
                &archive, i, narrow(output.wstring()).c_str(), 0)) {
            fail("Could not extract the zip archive.");
        }
    }
    mz_zip_reader_end(&archive);
}

std::string zipStem(const std::filesystem::path& zip_path) {
    return narrow(zip_path.stem().wstring());
}

}  // namespace

void renameVersion(const std::filesystem::path& game_dir,
                   const std::string& old_name,
                   const std::string& new_name) {
    validateName(old_name);
    validateName(new_name);
    if (old_name == new_name) return;
    const auto versions_dir = game_dir / L"versions";
    const auto source = versionDir(game_dir, old_name);
    if (!fs::is_within(versions_dir, source) || source == versions_dir) {
        throw std::runtime_error("Version path is outside the game directory.");
    }
    const auto target = versionDir(game_dir, new_name);
    if (!std::filesystem::is_directory(source)) {
        throw std::runtime_error("Version does not exist.");
    }
    std::string old_lower = old_name;
    std::string new_lower = new_name;
    std::transform(old_lower.begin(), old_lower.end(), old_lower.begin(),
                   [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
    std::transform(new_lower.begin(), new_lower.end(), new_lower.begin(),
                   [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
    const bool case_only = old_lower == new_lower;
    if (!case_only && std::filesystem::exists(target)) {
        throw std::runtime_error("A version with that name already exists.");
    }

    std::error_code ec;
    if (case_only) {
        // Windows treats "foo" and "Foo" as the same path, so go through a
        // temporary name.
        const auto temp =
            versions_dir / platform::path_from_utf8(old_name + ".rename-tmp");
        std::filesystem::rename(source, temp, ec);
        if (ec) throw std::runtime_error("Could not rename the version folder.");
        std::filesystem::rename(temp, target, ec);
        if (ec) {
            std::filesystem::rename(temp, source, ec);
            throw std::runtime_error("Could not rename the version folder.");
        }
    } else {
        std::filesystem::rename(source, target, ec);
        if (ec) {
            throw std::runtime_error("Could not rename the version folder.");
        }
    }

    const auto old_jar = target / platform::path_from_utf8(old_name + ".jar");
    const auto new_jar = target / platform::path_from_utf8(new_name + ".jar");
    bool jar_renamed = false;
    try {
        std::error_code jar_ec;
        if (std::filesystem::is_regular_file(old_jar, jar_ec)) {
            std::filesystem::rename(old_jar, new_jar, jar_ec);
            if (jar_ec) {
                throw std::runtime_error("Could not rename the client jar.");
            }
            jar_renamed = true;
        }
        renameManifestFile(target, old_name, new_name);
    } catch (...) {
        if (jar_renamed) {
            std::error_code jar_ec;
            std::filesystem::rename(new_jar, old_jar, jar_ec);
        }
        std::error_code rollback;
        std::filesystem::rename(target, source, rollback);
        throw;
    }

    // Children that inherit from this version must follow the new name.
    std::error_code child_ec;
    for (const auto& entry :
         std::filesystem::directory_iterator(versions_dir, child_ec)) {
        if (child_ec) break;
        if (!entry.is_directory(child_ec)) continue;
        try {
            const std::string child_name =
                platform::path_to_utf8(entry.path().filename());
            const auto manifest =
                findManifest(entry.path(), child_name);
            if (manifest.empty()) continue;
            json root = readJson(manifest);
            bool changed = false;
            if (root.contains("inheritsFrom") &&
                root["inheritsFrom"].is_string() &&
                root["inheritsFrom"].get<std::string>() == old_name) {
                root["inheritsFrom"] = new_name;
                changed = true;
            }
            if (root.contains("jar") && root["jar"].is_string() &&
                root["jar"].get<std::string>() == old_name) {
                root["jar"] = new_name;
                changed = true;
            }
            if (changed) writeJson(manifest, root);
        } catch (...) {
            // A broken child manifest must not undo a successful rename.
        }
    }
}

void deleteVersion(const std::filesystem::path& game_dir,
                   const std::string& name) {
    validateName(name);
    const auto versions_dir = game_dir / L"versions";
    const auto target = versionDir(game_dir, name);
    if (!fs::is_within(versions_dir, target) || target == versions_dir) {
        throw std::runtime_error("Version path is outside the game directory.");
    }
    if (!std::filesystem::is_directory(target)) {
        throw std::runtime_error("Version does not exist.");
    }
    if (platform::is_reparse_point(target)) {
        throw std::runtime_error("Version directory is a link.");
    }
    std::error_code ec;
    std::filesystem::remove_all(target, ec);
    if (ec) throw std::runtime_error("Could not delete the version folder.");
}

void importVersionFolder(const std::filesystem::path& game_dir,
                         const std::filesystem::path& source_dir,
                         const std::string& name) {
    validateName(name);
    if (!std::filesystem::is_directory(source_dir)) {
        throw std::runtime_error("The selected folder does not exist.");
    }
    const auto target = versionDir(game_dir, name);
    if (std::filesystem::exists(target)) {
        throw std::runtime_error("A version with that name already exists.");
    }
    if (!hasVersionManifest(source_dir)) {
        throw std::runtime_error(
            "The selected folder does not contain a version manifest.");
    }
    if (fs::is_within(source_dir, target)) {
        throw std::runtime_error(
            "The version folder cannot be created inside its source.");
    }

    std::error_code ec;
    for (const auto& entry :
         std::filesystem::recursive_directory_iterator(source_dir, ec)) {
        if (ec) break;
        if (platform::is_reparse_point(entry.path()) || entry.is_symlink(ec)) {
            throw std::runtime_error(
                "The selected folder contains links or junctions.");
        }
    }
    const std::string source_name =
        platform::path_to_utf8(source_dir.filename());
    std::filesystem::create_directories(target.parent_path(), ec);
    std::filesystem::copy(source_dir, target,
                          std::filesystem::copy_options::recursive |
                              std::filesystem::copy_options::skip_symlinks,
                          ec);
    if (ec) {
        std::filesystem::remove_all(target, ec);
        throw std::runtime_error("Could not copy the version folder.");
    }
    try {
        // An imported package must not be able to point the launcher at an
        // arbitrary executable through its bundled config.
        const auto imported_config = target / L"jolauncher.json";
        std::error_code config_ec;
        if (std::filesystem::is_regular_file(imported_config, config_ec)) {
            try {
                json config = readJson(imported_config);
                if (config.is_object() && config.contains("javaPath")) {
                    config["javaPath"] = nullptr;
                    writeJson(imported_config, config);
                }
            } catch (...) {
                std::filesystem::remove(imported_config, config_ec);
            }
        }
        for (const auto& entry :
             std::filesystem::recursive_directory_iterator(target, ec)) {
            if (ec) break;
            if (platform::is_reparse_point(entry.path())) {
                throw std::runtime_error(
                    "The imported folder contains links or junctions.");
            }
        }
        if (!source_name.empty() && source_name != name) {
            const auto source_jar =
                target / platform::path_from_utf8(source_name + ".jar");
            std::error_code jar_ec;
            if (std::filesystem::is_regular_file(source_jar, jar_ec)) {
                std::filesystem::rename(
                    source_jar,
                    target / platform::path_from_utf8(name + ".jar"), jar_ec);
                if (jar_ec) {
                    throw std::runtime_error(
                        "Could not rename the client jar.");
                }
            }
        }
        renameManifestFile(target, source_name, name);
    } catch (...) {
        std::filesystem::remove_all(target, ec);
        throw;
    }
}

std::string importVersionZip(const std::filesystem::path& game_dir,
                             const std::filesystem::path& zip_path) {
    if (!std::filesystem::is_regular_file(zip_path)) {
        throw std::runtime_error("The selected zip file does not exist.");
    }

    std::error_code ec;
    std::filesystem::path temp;
    std::random_device random;
    for (int attempt = 0; attempt < 32 && temp.empty(); ++attempt) {
        const auto candidate =
            std::filesystem::temp_directory_path() /
            (L"jolauncher-version-" + std::to_wstring(random()) + L"-" +
             std::to_wstring(random()));
        if (std::filesystem::create_directory(candidate, ec)) {
            temp = candidate;
        }
        ec.clear();
    }
    if (temp.empty()) {
        throw std::runtime_error("Could not create a temporary directory.");
    }

    try {
        extractZip(zip_path, temp);
        const auto source = resolveSource(temp);
        std::string name = source == temp
                               ? manifestId(source)
                               : narrow(source.filename().wstring());
        if (name.empty()) name = zipStem(zip_path);
        importVersionFolder(game_dir, source, name);
        std::filesystem::remove_all(temp, ec);
        return name;
    } catch (...) {
        std::filesystem::remove_all(temp, ec);
        throw;
    }
}

}  // namespace jol
