#include "game_dir.hpp"

#include "platform/environment.hpp"
#include "platform/paths.hpp"

#include <system_error>

namespace jol {
namespace {

bool isDir(const std::filesystem::path& path) {
    std::error_code ec;
    return std::filesystem::is_directory(path, ec);
}

bool looksLikeGameDir(const std::filesystem::path& dir) {
    return isDir(dir / L"versions") || isDir(dir / L"libraries") ||
           isDir(dir / L"assets");
}

}  // namespace

std::optional<std::filesystem::path> portableGameDir(
    const std::filesystem::path& executablePath) {
    if (executablePath.empty()) return std::nullopt;

    const std::filesystem::path dir = executablePath.parent_path();
    if (dir.empty()) return std::nullopt;

    if (dir.filename() == L".minecraft" || looksLikeGameDir(dir)) {
        return dir;
    }

    const std::filesystem::path child = dir / L".minecraft";
    if (isDir(child)) return child;

    return std::nullopt;
}

std::filesystem::path defaultGameDir(
    const std::filesystem::path& executablePath) {
    if (const auto portable = portableGameDir(executablePath)) {
        return *portable;
    }

    if (const auto minecraft = platform::default_minecraft_directory();
        !minecraft.empty()) {
        return minecraft;
    }

    return std::filesystem::path(L".minecraft");
}

}  // namespace jol
