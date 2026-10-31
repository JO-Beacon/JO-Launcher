#include "version.hpp"

#include "fs_safe.hpp"
#include "json_io.hpp"
#include "platform/paths.hpp"
#include "manifest_lookup.hpp"

#include <algorithm>
#include <cctype>
#include <fstream>
#include <optional>
#include <stdexcept>
#include <system_error>

#include <nlohmann/json.hpp>

namespace jol {
namespace {

using json = nlohmann::json;

bool isDir(const std::filesystem::path& path) {
    std::error_code ec;
    return std::filesystem::is_directory(path, ec);
}

std::string lowercase(std::string value) {
    std::transform(value.begin(), value.end(), value.begin(),
                   [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
    return value;
}

std::optional<std::filesystem::path> findManifest(
    const std::filesystem::path& dir, const std::string& name) {
    const auto path = mc::find_manifest_file(dir, name);
    if (path.empty()) return std::nullopt;
    return path;
}

std::string stringField(const json& object, const char* key) {
    if (!object.is_object()) return {};
    const auto it = object.find(key);
    if (it == object.end() || !it->is_string()) return {};
    return it->get<std::string>();
}

std::optional<std::string> argumentValue(const json& root,
                                         const std::string& key) {
    if (!root.is_object()) return std::nullopt;
    const auto arguments = root.find("arguments");
    if (arguments == root.end() || !arguments->is_object()) return std::nullopt;
    const auto game = arguments->find("game");
    if (game == arguments->end() || !game->is_array()) return std::nullopt;

    for (size_t i = 0; i + 1 < game->size(); ++i) {
        if ((*game)[i].is_string() && (*game)[i].get<std::string>() == key &&
            (*game)[i + 1].is_string()) {
            return (*game)[i + 1].get<std::string>();
        }
    }
    return std::nullopt;
}

bool libraryContains(const json& root, const std::string& needle) {
    if (!root.is_object()) return false;
    const auto libraries = root.find("libraries");
    if (libraries == root.end() || !libraries->is_array()) return false;
    for (const auto& library : *libraries) {
        if (!library.is_object()) continue;
        const std::string name = stringField(library, "name");
        if (lowercase(name).find(needle) != std::string::npos) return true;
    }
    return false;
}

VersionInfo parseVersion(const std::filesystem::path& dir,
                         const std::string& name) {
    VersionInfo info{name, name, "vanilla", "", dir};
    const auto manifest = findManifest(dir, name);
    if (!manifest) throw std::runtime_error("manifest missing");

    std::ifstream stream(*manifest);
    if (!stream) throw std::runtime_error("manifest unreadable");
    json root;
    stream >> root;
    if (!root.is_object()) throw std::runtime_error("manifest is not an object");

    const std::string id = stringField(root, "id");
    const std::string inherited = stringField(root, "inheritsFrom");
    const auto fmlMc = argumentValue(root, "--fml.mcVersion");
    const auto fmlNeo = argumentValue(root, "--fml.neoForgeVersion");
    const auto fmlForge = argumentValue(root, "--fml.forgeVersion");

    const bool fabric = libraryContains(root, "fabric-loader");
    const bool quilt = libraryContains(root, "quilt-loader");
    const bool neoforge = libraryContains(root, "neoforge") ||
                          libraryContains(root, "fancymodloader") ||
                          fmlNeo.has_value();
    const bool forge = libraryContains(root, "minecraftforge") ||
                       libraryContains(root, "fmlloader") ||
                       fmlForge.has_value();

    if (fabric) {
        info.loader = "fabric";
    } else if (quilt) {
        info.loader = "quilt";
    } else if (neoforge) {
        info.loader = "neoforge";
        info.loader_version = fmlNeo.value_or("");
    } else if (forge) {
        info.loader = "forge";
        info.loader_version = fmlForge.value_or("");
    }

    if (!inherited.empty()) {
        info.game_version = inherited;
    } else if (fmlMc.has_value()) {
        info.game_version = *fmlMc;
    } else if (!id.empty()) {
        info.game_version = id;
    }

    return info;
}

}  // namespace

VersionScanResult scanVersions(const std::filesystem::path& gameDir) {
    VersionScanResult result;
    const std::filesystem::path versionsDir = gameDir / L"versions";
    if (!isDir(versionsDir)) return result;

    std::error_code ec;
    for (const auto& entry : std::filesystem::directory_iterator(versionsDir, ec)) {
        if (ec) break;
        if (!entry.is_directory(ec)) continue;
        const std::string name = fs::to_utf8(entry.path().filename());
        if (platform::is_reparse_point(entry.path()) ||
            !fs::is_within(versionsDir, entry.path())) {
            result.broken.push_back(name);
            continue;
        }
        try {
            result.versions.push_back(parseVersion(entry.path(), name));
        } catch (...) {
            result.broken.push_back(name);
        }
    }

    std::sort(result.versions.begin(), result.versions.end(),
              [](const VersionInfo& a, const VersionInfo& b) {
                  return lowercase(a.name) < lowercase(b.name);
              });
    std::sort(result.broken.begin(), result.broken.end());
    return result;
}

}  // namespace jol
