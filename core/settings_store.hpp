#pragma once

#include <filesystem>
#include <string>

namespace jol {

struct WindowState {
    int x = 0;
    int y = 0;
    int width = 0;
    int height = 0;
    bool maximized = false;
    bool valid = false;
};

/// Per-instance launcher settings stored at
/// `<launcher directory>\.jo-launcher\settings.json`.
struct LauncherSettings {
    std::filesystem::path game_dir;
    bool dark_mode = true;
    bool follow_system = false;
    /// Version selected on the Launch page, empty when nothing was chosen yet.
    std::string current_version;
    int rail_width = 232;
    WindowState window;
};

/// Reads the instance settings. There is no global fallback.
LauncherSettings readLauncherSettings(
    const std::filesystem::path& executable_path);

/// Writes the instance settings. Empty paths are written as `null`.
void writeLauncherSettings(const LauncherSettings& settings,
                           const std::filesystem::path& executable_path);

}  // namespace jol
