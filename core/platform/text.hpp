#pragma once

#include <filesystem>
#include <string>

namespace jol::platform {

/// UTF-8 to the platform's wide string.
std::wstring widen(const std::string& utf8);

/// Wide string to UTF-8.
std::string narrow(const std::wstring& wide);

/// UTF-8 bytes to a filesystem path.
std::filesystem::path path_from_utf8(const std::string& utf8);

/// Filesystem path to UTF-8 bytes.
std::string path_to_utf8(const std::filesystem::path& path);

}  // namespace jol::platform
