#include "json_io.hpp"
#include "platform/paths.hpp"
#include "settings_store.hpp"
#include "platform/text.hpp"

#include <algorithm>
#include <fstream>
#include <system_error>

#include <nlohmann/json.hpp>

namespace jol {
namespace {

using json = nlohmann::json;

std::filesystem::path instance_settings_dir(
    const std::filesystem::path& executable_path) {
    if (executable_path.empty()) return {};
    const auto parent = executable_path.parent_path();
    if (parent.empty()) return {};
    return parent / L".jo-launcher";
}

LauncherSettings parse_settings(const std::filesystem::path& file) {
    LauncherSettings settings;
    try {
        std::error_code file_ec;
        if (!std::filesystem::is_regular_file(file, file_ec)) return settings;
        std::ifstream stream(file);
        if (!stream) return settings;
        json root = jsonio::read(file, 1024 * 1024);
        if (!root.is_object()) return settings;
        const auto game = root.find("gameDir");
        if (game != root.end() && game->is_string()) {
            const std::string text = game->get<std::string>();
            settings.game_dir = platform::path_from_utf8(text);
        }
        const auto dark = root.find("darkMode");
        if (dark != root.end() && dark->is_boolean()) {
            settings.dark_mode = dark->get<bool>();
        }
        const auto version = root.find("currentVersion");
        if (version != root.end() && version->is_string()) {
            settings.current_version = version->get<std::string>();
        }
        const auto follow = root.find("followSystem");
        if (follow != root.end() && follow->is_boolean()) {
            settings.follow_system = follow->get<bool>();
        }
        const auto rail = root.find("railWidth");
        if (rail != root.end() && rail->is_number_integer()) {
            const int width = rail->get<int>();
            if (width >= 200 && width <= 360) settings.rail_width = width;
        }
        const auto window = root.find("window");
        if (window != root.end() && window->is_object()) {
            const auto x = window->find("x");
            const auto y = window->find("y");
            const auto width = window->find("width");
            const auto height = window->find("height");
            if (x != window->end() && x->is_number_integer() &&
                y != window->end() && y->is_number_integer() &&
                width != window->end() && width->is_number_integer() &&
                height != window->end() && height->is_number_integer()) {
                const auto clamp = [](std::int64_t value, int low, int high) {
                    if (value < low) return low;
                    if (value > high) return high;
                    return static_cast<int>(value);
                };
                settings.window.x = clamp(x->get<std::int64_t>(), -100000, 100000);
                settings.window.y = clamp(y->get<std::int64_t>(), -100000, 100000);
                settings.window.width = clamp(width->get<std::int64_t>(), 200, 10000);
                settings.window.height = clamp(height->get<std::int64_t>(), 150, 10000);
                settings.window.maximized = window->value("maximized", false);
                settings.window.valid =
                    settings.window.width > 200 && settings.window.height > 150;
            }
        }
    } catch (...) {
    }
    return settings;
}

}  // namespace

LauncherSettings readLauncherSettings(
    const std::filesystem::path& executable_path) {
    const auto instance = instance_settings_dir(executable_path);
    if (!instance.empty()) {
        const auto file = instance / L"settings.json";
        if (std::filesystem::is_regular_file(file)) {
            return parse_settings(file);
        }
    }
    return {};
}

void writeLauncherSettings(const LauncherSettings& settings,
                           const std::filesystem::path& executable_path) {
    const auto dir = instance_settings_dir(executable_path);
    if (dir.empty()) return;
    std::error_code ec;
    std::filesystem::create_directories(dir, ec);

    json root = json::object();
    if (settings.game_dir.empty()) {
        root["gameDir"] = nullptr;
    } else {
        const auto text = settings.game_dir.u8string();
        root["gameDir"] = std::string(reinterpret_cast<const char*>(text.data()),
                                       text.size());
    }
    root["darkMode"] = settings.dark_mode;
    if (settings.current_version.empty()) {
        root["currentVersion"] = nullptr;
    } else {
        root["currentVersion"] = settings.current_version;
    }
    root["followSystem"] = settings.follow_system;
    root["railWidth"] = settings.rail_width;
    if (settings.window.valid) {
        root["window"] = json{{ "x", settings.window.x },
                              { "y", settings.window.y },
                              { "width", settings.window.width },
                              { "height", settings.window.height },
                              { "maximized", settings.window.maximized }};
    }

    const auto file = dir / L"settings.json";
    const auto temp = dir / L"settings.json.tmp";
    {
        std::ofstream out(temp, std::ios::binary | std::ios::trunc);
        if (!out) return;
        out << root.dump(2, ' ', false, nlohmann::json::error_handler_t::replace) << '\n';
        if (!out) return;
    }
    if (!platform::atomic_replace(temp, file)) {
        std::filesystem::remove(temp, ec);
        return;
    }
}

}  // namespace jol
