#pragma once

#include <filesystem>
#include <optional>

namespace jol {

/// Returns the game directory when the launcher is running in portable mode:
/// the executable itself is inside `.minecraft`, inside a folder that already
/// looks like a game directory, or next to a `.minecraft` child.
std::optional<std::filesystem::path> portableGameDir(
    const std::filesystem::path& executablePath);

/// Portable directory first, then the platform default:
/// `%APPDATA%\.minecraft` on Windows, `~/.minecraft` on Linux.
std::filesystem::path defaultGameDir(
    const std::filesystem::path& executablePath);

}  // namespace jol
