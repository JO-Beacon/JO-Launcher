#pragma once

#include <cstddef>
#include <string>

namespace jol::secure {

/// Overwrites memory that held a secret. The volatile writes keep the compiler
/// from dropping the store as dead.
inline void secure_zero(void* data, std::size_t size) {
    auto* bytes = static_cast<volatile unsigned char*>(data);
    while (size-- > 0) *bytes++ = 0;
}

/// Overwrites the string's buffer before clearing it, so tokens do not linger
/// in memory.
inline void clear_string(std::string& value) {
    if (value.empty()) return;
    // Overwrite the whole allocation, not just the current length: a shorter
    // value may still leave earlier token bytes in the spare capacity.
    const std::size_t capacity = value.capacity();
    value.assign(capacity, static_cast<char>(0));
    secure_zero(value.data(), capacity);
    value.clear();
}

}  // namespace jol::secure
