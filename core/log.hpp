#pragma once

#include <filesystem>
#include <string>
#include <string_view>

namespace jol::log {

enum class Level { debug, info, warn, error };

/// Opens the launcher log in `directory` (created when missing). Safe to call
/// more than once; the first call wins.
void init(const std::filesystem::path& directory);
void shutdown();

/// Writes one line. Never throws: logging must not take the launcher down.
void write(Level level, std::string_view module,
           std::string_view message) noexcept;

inline void debug(std::string_view module, std::string_view message) {
    write(Level::debug, module, message);
}
inline void info(std::string_view module, std::string_view message) {
    write(Level::info, module, message);
}
inline void warn(std::string_view module, std::string_view message) {
    write(Level::warn, module, message);
}
inline void error(std::string_view module, std::string_view message) {
    write(Level::error, module, message);
}

/// Current log file, empty when logging is not initialised.
std::filesystem::path file();

}  // namespace jol::log
