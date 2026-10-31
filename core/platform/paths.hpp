#pragma once

#include <filesystem>

namespace jol::platform {

/// Full path of the running executable.
std::filesystem::path executable_path();

/// Per-user roaming data directory (%APPDATA% on Windows, XDG_CONFIG_HOME on
/// Linux).
std::filesystem::path roaming_app_data();

/// Per-user local data directory (%LOCALAPPDATA% on Windows, XDG_DATA_HOME on
/// Linux).
std::filesystem::path local_app_data();

/// System temporary directory.
std::filesystem::path temp_directory();

/// True for a symlink, junction or any other reparse point.
bool is_reparse_point(const std::filesystem::path& path);

/// Default Minecraft directory (%APPDATA%/.minecraft or ~/.minecraft).
std::filesystem::path default_minecraft_directory();

/// Replaces `target` with `source` in one step.
bool atomic_replace(const std::filesystem::path& source,
                    const std::filesystem::path& target);

}  // namespace jol::platform
