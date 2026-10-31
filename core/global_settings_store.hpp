#pragma once

#include <string>

namespace jol {

/// User-wide settings shared by every launcher instance.
/// Stored at %APPDATA%\JO-Beacon\<product>\global-settings.json
/// The directory name comes from `kDataDirectoryName`.
/// Bump when PRIVACY.md changes in a way that needs fresh consent.
inline constexpr int kPrivacyNoticeVersion = 1;

struct GlobalSettings {
    bool privacy_accepted = false;
    /// Version of the privacy notice the user accepted; 0 = never recorded.
    int privacy_version = 0;
    std::string language = "en_US";
    bool follow_system_language = false;
    /// Azure application (client) id entered by the user. Empty means the
    /// environment variable fallback is used.
    std::string client_id;
};

GlobalSettings readGlobalSettings();
void writeGlobalSettings(const GlobalSettings& settings);

}  // namespace jol
