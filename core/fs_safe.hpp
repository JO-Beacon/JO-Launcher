#pragma once

#include <algorithm>
#include <cwctype>
#include <filesystem>
#include <string>

namespace jol::fs {

/// Rejects archive path segments that Windows would resolve outside the
/// extraction root. Trailing spaces and dots are stripped by the filesystem,
/// so ".. " would otherwise slip past a plain ".." check.
inline bool safe_segment(std::string segment) {
    while (!segment.empty() &&
           (segment.back() == ' ' || segment.back() == '.')) {
        segment.pop_back();
    }
    if (segment.empty() || segment == "." || segment == "..") return false;
    if (segment.find(':') != std::string::npos) return false;
    return std::none_of(segment.begin(), segment.end(),
                        [](unsigned char c) { return c < 0x20; });
}

/// True when `candidate` resolves inside `base` (case-insensitive on Windows).
inline bool is_within(const std::filesystem::path& base,
                      const std::filesystem::path& candidate) {
    std::error_code ec;
    const auto root = std::filesystem::weakly_canonical(base, ec);
    if (ec) return false;
    const auto target = std::filesystem::weakly_canonical(candidate, ec);
    if (ec) return false;

    auto expected = root.begin();
    auto actual = target.begin();
    for (; expected != root.end(); ++expected, ++actual) {
        if (actual == target.end()) return false;
        std::wstring left = expected->wstring();
        std::wstring right = actual->wstring();
#if defined(_WIN32)
        // Windows paths are case-insensitive.
        std::transform(left.begin(), left.end(), left.begin(), towlower);
        std::transform(right.begin(), right.end(), right.begin(), towlower);
#endif
        if (left != right) return false;
    }
    return true;
}

/// UTF-8 representation of a path (C++20 returns char8_t, which the rest of
/// the code base does not use).
inline std::string to_utf8(const std::filesystem::path& path) {
    const std::u8string text = path.u8string();
    return std::string(reinterpret_cast<const char*>(text.data()), text.size());
}

}  // namespace jol::fs
