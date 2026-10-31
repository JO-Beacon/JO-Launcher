#pragma once

#include <cstdint>
#include <filesystem>
#include <fstream>
#include <stdexcept>
#include <string>
#include <system_error>

#include <nlohmann/json.hpp>

namespace jol::jsonio {

/// Cheap nesting check so a hostile file cannot blow the parser stack.
inline bool depth_ok(const std::string& text, int limit = 64) {
    int depth = 0;
    bool in_string = false;
    bool escaped = false;
    for (const char c : text) {
        if (in_string) {
            if (escaped) {
                escaped = false;
            } else if (c == '\\') {
                escaped = true;
            } else if (c == '"') {
                in_string = false;
            }
            continue;
        }
        if (c == '"') {
            in_string = true;
        } else if (c == '{' || c == '[') {
            if (++depth > limit) return false;
        } else if (c == '}' || c == ']') {
            if (depth > 0) --depth;
        }
    }
    return true;
}

inline nlohmann::json read(const std::filesystem::path& file,
                           std::uintmax_t max_bytes = 16ull * 1024 * 1024) {
    std::error_code ec;
    const auto size = std::filesystem::file_size(file, ec);
    if (ec) throw std::runtime_error("Could not read JSON file size");
    if (size > max_bytes) throw std::runtime_error("JSON file is too large");
    std::ifstream stream(file, std::ios::binary);
    if (!stream) throw std::runtime_error("Could not open JSON file");
    std::string text(static_cast<std::size_t>(size), '\0');
    stream.read(text.data(), static_cast<std::streamsize>(size));
    if (!stream || static_cast<std::size_t>(stream.gcount()) != size) {
        throw std::runtime_error("Could not read JSON file");
    }
    if (!depth_ok(text)) throw std::runtime_error("JSON nesting is too deep");
    return nlohmann::json::parse(text, nullptr, true, false);
}

}  // namespace jol::jsonio
