#pragma once

#include <cstdint>
#include <optional>
#include <string>
#include <vector>

namespace jol::platform {

/// Encrypts a secret for storage on this machine. Returns an empty vector when
/// the platform backend is unavailable.
std::vector<std::uint8_t> protect_secret(const std::string& plain);

/// Decrypts data produced by protect_secret().
std::optional<std::string> unprotect_secret(
    const std::vector<std::uint8_t>& cipher);

}  // namespace jol::platform
