#pragma once

#include <filesystem>
#include <optional>
#include <string>

namespace jol::platform {

/// Reads an environment variable as a path. Windows reads UTF-16 so names with
/// non-ASCII characters survive; Linux reads the byte string as UTF-8.
std::optional<std::filesystem::path> environment_path(const char* name);

/// Reads an environment variable as UTF-8 text.
std::optional<std::string> environment_string(const char* name);

}  // namespace jol::platform
