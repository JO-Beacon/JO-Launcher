#include "global_settings_store.hpp"

#include "product_info.hpp"
#include "platform/mutex.hpp"
#include "json_io.hpp"
#include "platform/paths.hpp"

#include <climits>
#include <filesystem>
#include <fstream>
#include <system_error>

#include <nlohmann/json.hpp>

namespace jol {
namespace {

using json = nlohmann::json;

std::filesystem::path settings_dir() {
    const auto base = platform::roaming_app_data();
    if (base.empty()) return {};
    return base / L"JO-Beacon" / kDataDirectoryName;
}

json read_json(const std::filesystem::path& file) {
    try {
        std::ifstream stream(file);
        if (!stream) return {};
        json root = jsonio::read(file, 1024 * 1024);
        return root.is_object() ? root : json{};
    } catch (...) {
        return {};
    }
}

}  // namespace

GlobalSettings readGlobalSettings() {
    platform::NamedMutex lock("Local\\JO-Launcher-GlobalSettings");
    GlobalSettings result;
    const auto dir = settings_dir();
    if (dir.empty()) return result;

    const json root = read_json(dir / L"global-settings.json");
    if (root.contains("privacyAccepted") &&
        root["privacyAccepted"].is_boolean()) {
        result.privacy_accepted = root["privacyAccepted"].get<bool>();
    }
    if (root.contains("privacyVersion") && root["privacyVersion"].is_number()) {
        std::int64_t value = 0;
        if (root["privacyVersion"].is_number_unsigned()) {
            const auto raw = root["privacyVersion"].get<std::uint64_t>();
            value = raw > static_cast<std::uint64_t>(INT_MAX)
                        ? INT_MAX
                        : static_cast<std::int64_t>(raw);
        } else if (root["privacyVersion"].is_number_integer()) {
            value = root["privacyVersion"].get<std::int64_t>();
        }
        if (value > INT_MAX) value = INT_MAX;
        if (value < 0) value = 0;
        result.privacy_version = static_cast<int>(value);
    }
    if (root.contains("language") && root["language"].is_string()) {
        result.language = root["language"].get<std::string>();
    }
    if (root.contains("followSystemLanguage") &&
        root["followSystemLanguage"].is_boolean()) {
        result.follow_system_language =
            root["followSystemLanguage"].get<bool>();
    }
    if (root.contains("clientId") && root["clientId"].is_string()) {
        result.client_id = root["clientId"].get<std::string>();
    }
    return result;
}

void writeGlobalSettings(const GlobalSettings& settings) {
    platform::NamedMutex lock("Local\\JO-Launcher-GlobalSettings");
    const auto dir = settings_dir();
    if (dir.empty()) return;
    std::error_code ec;
    std::filesystem::create_directories(dir, ec);

    json root = json::object();
    root["privacyAccepted"] = settings.privacy_accepted;
    root["privacyVersion"] = settings.privacy_version;
    root["language"] = settings.language;
    root["followSystemLanguage"] = settings.follow_system_language;
    root["clientId"] = settings.client_id;

    const auto file = dir / L"global-settings.json";
    const auto temp = dir / L"global-settings.json.tmp";
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
