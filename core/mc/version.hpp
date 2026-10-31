#pragma once

#include <filesystem>
#include <string>
#include <vector>

namespace jol {

struct VersionInfo {
    std::string name;
    std::string game_version;
    std::string loader;
    std::string loader_version;
    std::filesystem::path directory;
};

struct VersionScanResult {
    std::vector<VersionInfo> versions;
    std::vector<std::string> broken;
};

/// Reads `<game dir>/versions/*/*.json` without modifying the game directory.
/// Unreadable folders are reported in `broken`, not silently ignored.
VersionScanResult scanVersions(const std::filesystem::path& gameDir);

}  // namespace jol
