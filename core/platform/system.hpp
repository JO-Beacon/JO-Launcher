#pragma once

#include <cstdint>
#include <filesystem>
#include <string>
#include <vector>

namespace jol::platform {

/// Manifest `os.name` value for this platform.
const char* os_name();

/// CPU architecture name used in library manifests.
const char* os_arch();

/// Classpath separator: ';' on Windows, ':' elsewhere.
char classpath_separator();

/// Natives classifier used in library manifests.
const char* natives_classifier();

/// Java launcher file names to look for: console first, windowless second
/// (empty when the platform has none).
std::string java_console_name();
std::string java_windowless_name();

/// Maps a windowless launcher (javaw.exe) to its console counterpart.
std::filesystem::path console_java(const std::filesystem::path& executable);

/// Total physical memory in bytes (0 when unknown).
std::uint64_t total_physical_memory();

/// Directories that commonly contain Java installations.
std::vector<std::filesystem::path> java_roots();

/// Directory where the launcher may keep its own Java runtime.
std::filesystem::path launcher_runtime_dir();

}  // namespace jol::platform
