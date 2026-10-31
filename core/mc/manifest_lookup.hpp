#pragma once

#include <algorithm>
#include <filesystem>
#include <string>
#include <vector>

#include "fs_safe.hpp"

namespace jol::mc {

/// Builds a path from UTF-8 bytes, which is what the rest of the code base
/// uses for version names.
inline std::filesystem::path path_from_utf8(const std::string& text) {
    return std::filesystem::path(std::u8string(text.begin(), text.end()));
}

inline bool is_settings_file(const std::filesystem::path& file) {
    std::string name = fs::to_utf8(file.filename());
    std::transform(name.begin(), name.end(), name.begin(),
                   [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
    return name == "jolauncher.json";
}

inline std::vector<std::filesystem::path> manifest_candidates(
    const std::filesystem::path& dir) {
    std::vector<std::filesystem::path> files;
    std::error_code ec;
    for (const auto& entry : std::filesystem::directory_iterator(dir, ec)) {
        if (ec) break;
        if (!entry.is_regular_file(ec)) continue;
        if (entry.path().extension() != L".json") continue;
        if (is_settings_file(entry.path())) continue;
        files.push_back(entry.path());
    }
    return files;
}

/// Finds the version manifest: exact <preferred>.json first, then the only
/// JSON in the folder, then a case-insensitive name match.
inline std::filesystem::path find_manifest_file(
    const std::filesystem::path& dir, const std::string& preferred) {
    std::error_code ec;
    const auto exact = dir / path_from_utf8(preferred + ".json");
    if (std::filesystem::is_regular_file(exact, ec)) return exact;

    const auto files = manifest_candidates(dir);
    if (files.size() == 1) return files.front();

    std::string wanted = preferred + ".json";
    std::transform(wanted.begin(), wanted.end(), wanted.begin(),
                   [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
    for (const auto& file : files) {
        std::string name = fs::to_utf8(file.filename());
        std::transform(name.begin(), name.end(), name.begin(),
                       [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
        if (name == wanted) return file;
    }
    return {};
}

}  // namespace jol::mc
