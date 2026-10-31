#include "auth.hpp"
#include "secure_wipe.hpp"

#include "client_id.hpp"

#include <algorithm>
#include <chrono>
#include <cstdlib>
#include <ctime>
#include <string>
#include <thread>


#include <nlohmann/json.hpp>

#include "../net/http.hpp"

namespace jol::auth {
namespace {

using json = nlohmann::json;

constexpr const wchar_t* kLoginHost = L"login.microsoftonline.com";
constexpr const wchar_t* kXblHost = L"user.auth.xboxlive.com";
constexpr const wchar_t* kXstsHost = L"xsts.auth.xboxlive.com";
constexpr const wchar_t* kMinecraftHost = L"api.minecraftservices.com";

std::string url_encode(const std::string& value) {
    static const char* hex = "0123456789ABCDEF";
    std::string out;
    for (const unsigned char c : value) {
        if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
            (c >= '0' && c <= '9') || c == '-' || c == '_' || c == '.' ||
            c == '~') {
            out.push_back(static_cast<char>(c));
        } else {
            out.push_back('%');
            out.push_back(hex[c >> 4]);
            out.push_back(hex[c & 0x0F]);
        }
    }
    return out;
}

json parse_json(const net::HttpResponse& response, const char* key) {
    try {
        json value = json::parse(response.body);
        if (value.is_object()) return value;
    } catch (...) {
    }
    throw AuthError(key, "HTTP " + std::to_string(response.status));
}

std::string string_field(const json& value, const char* key) {
    const auto it = value.find(key);
    if (it == value.end() || !it->is_string()) return {};
    return it->get<std::string>();
}

int int_field(const json& value, const char* key) {
    const auto it = value.find(key);
    if (it == value.end() || !it->is_number_integer()) return 0;
    return it->get<int>();
}

std::string user_hash(const json& value) {
    try {
        return value.at("DisplayClaims").at("xui").at(0).at("uhs")
            .get<std::string>();
    } catch (...) {
        return {};
    }
}

net::HttpResponse post_form(const std::wstring& path,
                            const std::string& body) {
    return net::send(net::HttpRequest{
        kLoginHost, path, L"POST", body,
        {{L"Content-Type", L"application/x-www-form-urlencoded"},
         {L"Accept", L"application/json"}}});
}

net::HttpResponse post_json(const std::wstring& host,
                            const std::wstring& path,
                            const json& body) {
    return net::send(net::HttpRequest{
        host, path, L"POST", body.dump(),
        {{L"Content-Type", L"application/json"},
         {L"Accept", L"application/json"},
         {L"x-xbl-contract-version", L"1"}}});
}

void require_client_id(const std::string& client_id) {
    if (client_id.empty()) {
        throw AuthError("auth.error.noClientId",
                        "This build has no embedded client ID.");
    }
}

}  // namespace

AuthService::AuthService(std::string client_id)
    : client_id_(std::move(client_id)) {}

AuthService::~AuthService() {
    if (!client_id_.empty()) {
        secure::secure_zero(client_id_.data(), client_id_.size());
        client_id_.clear();
    }
}

std::string AuthService::client_id_from_environment() {
    return resolve_client_id();
}

namespace {

bool allowed_verification_uri(const std::string& uri) {
    const std::string prefix = "https://";
    if (uri.size() <= prefix.size() ||
        uri.compare(0, prefix.size(), prefix) != 0) {
        return false;
    }
    const auto authority_end = uri.find_first_of("/?#", prefix.size());
    std::string authority =
        uri.substr(prefix.size(), authority_end - prefix.size());
    if (authority.empty() || authority.find('@') != std::string::npos ||
        authority.find('\\') != std::string::npos) {
        return false;
    }
    std::string host = authority;
    const auto port_sep = authority.rfind(':');
    if (port_sep != std::string::npos) {
        if (authority.substr(port_sep + 1) != "443") return false;
        host = authority.substr(0, port_sep);
    }
    std::transform(host.begin(), host.end(), host.begin(),
                   [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
    const auto matches = [&host](const char* suffix) {
        const std::string dotted = std::string(".") + suffix;
        return host == suffix ||
               (host.size() > dotted.size() &&
                host.compare(host.size() - dotted.size(), dotted.size(),
                             dotted) == 0);
    };
    return matches("microsoft.com") || matches("microsoftonline.com") ||
           matches("live.com");
}

}  // namespace

DeviceCodeInfo AuthService::request_device_code() const {
    require_client_id(client_id_);
    const std::string body =
        "client_id=" + url_encode(client_id_) +
        "&scope=" + url_encode("XboxLive.signin offline_access");
    const net::HttpResponse response =
        post_form(L"/consumers/oauth2/v2.0/devicecode", body);
    const json value = parse_json(response, "auth.error.deviceCode");
    if (response.status < 200 || response.status >= 300) {
        throw AuthError("auth.error.deviceCode", response.body);
    }

    DeviceCodeInfo info;
    info.user_code = string_field(value, "user_code");
    info.device_code = string_field(value, "device_code");
    info.verification_uri = string_field(value, "verification_uri");
    info.expires_in = int_field(value, "expires_in");
    info.interval = int_field(value, "interval");
    if (info.user_code.empty() || info.device_code.empty() ||
        info.verification_uri.empty() || info.expires_in <= 0 ||
        info.interval <= 0 || !allowed_verification_uri(info.verification_uri)) {
        throw AuthError("auth.error.deviceCodeIncomplete", response.body);
    }
    info.interval = std::clamp(info.interval, 1, 60);
    info.expires_in = std::min(info.expires_in, 3600);
    return info;
}

std::optional<Account> AuthService::poll_device_code(
    const DeviceCodeInfo& info) const {
    require_client_id(client_id_);
    const std::string body =
        "client_id=" + url_encode(client_id_) +
        "&grant_type=" +
        url_encode("urn:ietf:params:oauth:grant-type:device_code") +
        "&device_code=" + url_encode(info.device_code);
    const net::HttpResponse response =
        post_form(L"/consumers/oauth2/v2.0/token", body);
    const json value = parse_json(response, "auth.error.ms");

    if (response.status >= 200 && response.status < 300) {
        const std::string access = string_field(value, "access_token");
        const std::string refresh = string_field(value, "refresh_token");
        const int expires = int_field(value, "expires_in");
        if (access.empty() || refresh.empty() || expires <= 0) {
            throw AuthError("auth.error.tokenIncomplete", response.body);
        }
        return exchange(access, refresh);
    }

    const std::string error = string_field(value, "error");
    if (error == "authorization_pending") return std::nullopt;
    if (error == "slow_down") {
        throw AuthError("auth.error.slowDown", response.body);
    }
    if (error == "authorization_declined") {
        throw AuthError("auth.error.declined", response.body);
    }
    if (error == "expired_token") {
        throw AuthError("auth.error.codeExpired", response.body);
    }
    if (error == "bad_verification_code") {
        throw AuthError("auth.error.codeInvalid", response.body);
    }
    throw AuthError("auth.error.ms", response.body);
}

Account AuthService::refresh(const Account& account) const {
    require_client_id(client_id_);
    const std::string body =
        "client_id=" + url_encode(client_id_) +
        "&grant_type=refresh_token&refresh_token=" +
        url_encode(account.refresh_token) +
        "&scope=" + url_encode("XboxLive.signin offline_access");
    const net::HttpResponse response =
        post_form(L"/consumers/oauth2/v2.0/token", body);
    const json value = parse_json(response, "auth.error.refresh");
    if (response.status < 200 || response.status >= 300) {
        if (string_field(value, "error") == "invalid_grant") {
            throw AuthError("auth.error.refreshExpired", response.body);
        }
        throw AuthError("auth.error.refresh", response.body);
    }
    std::string access = string_field(value, "access_token");
    std::string refresh_token = string_field(value, "refresh_token");
    const int expires = int_field(value, "expires_in");
    if (access.empty() || refresh_token.empty() || expires <= 0) {
        throw AuthError("auth.error.refreshIncomplete", response.body);
    }
    Account refreshed = exchange(access, refresh_token);
    secure::clear_string(access);
    secure::clear_string(refresh_token);
    return refreshed;
}

Account AuthService::exchange(const std::string& ms_access_token,
                              const std::string& refresh_token) const {
    const net::HttpResponse xbl_response = post_json(
        kXblHost, L"/user/authenticate",
        json{{"Properties",
              {{"AuthMethod", "RPS"},
               {"SiteName", "user.auth.xboxlive.com"},
               {"RpsTicket", "d=" + ms_access_token}}},
             {"RelyingParty", "http://auth.xboxlive.com"},
             {"TokenType", "JWT"}});
    const json xbl_json = parse_json(xbl_response, "auth.error.xbox");
    std::string xbl_token = string_field(xbl_json, "Token");
    const std::string xbl_hash = user_hash(xbl_json);
    if (xbl_response.status < 200 || xbl_response.status >= 300 ||
        xbl_token.empty() || xbl_hash.empty()) {
        throw AuthError("auth.error.xbox", xbl_response.body);
    }

    const net::HttpResponse xsts_response = post_json(
        kXstsHost, L"/xsts/authorize",
        json{{"Properties",
              {{"SandboxId", "RETAIL"}, {"UserTokens", {xbl_token}}}},
             {"RelyingParty", "rp://api.minecraftservices.com/"},
             {"TokenType", "JWT"}});
    const json xsts_json = parse_json(xsts_response, "auth.error.xsts");
    if (xsts_response.status == 401) {
        throw AuthError("auth.error.xboxRejected", xsts_response.body);
    }
    std::string xsts_token = string_field(xsts_json, "Token");
    const std::string xsts_hash = user_hash(xsts_json);
    if (xsts_response.status < 200 || xsts_response.status >= 300 ||
        xsts_token.empty() || xsts_hash.empty()) {
        throw AuthError("auth.error.xsts", xsts_response.body);
    }

    const net::HttpResponse mc_response = post_json(
        kMinecraftHost, L"/authentication/login_with_xbox",
        json{{"identityToken", "XBL3.0 x=" + xsts_hash + ";" + xsts_token}});
    const json mc_json = parse_json(mc_response, "auth.error.minecraft");
    if (mc_response.status == 403) {
        const std::string message = string_field(mc_json, "errorMessage");
        if (message.find("Invalid app registration") != std::string::npos) {
            throw AuthError("auth.error.whitelist", message);
        }
        throw AuthError("auth.error.minecraftRejected", message);
    }
    std::string mc_access = string_field(mc_json, "access_token");
    const int mc_expires = int_field(mc_json, "expires_in");
    if (mc_response.status < 200 || mc_response.status >= 300 ||
        mc_access.empty() || mc_expires <= 0) {
        throw AuthError("auth.error.minecraft", mc_response.body);
    }

    const net::HttpResponse profile_response = net::send(net::HttpRequest{
        kMinecraftHost, L"/minecraft/profile", L"GET", {},
        {{L"Authorization", L"Bearer " + std::wstring(mc_access.begin(),
                                                       mc_access.end())},
         {L"Accept", L"application/json"}}});
    const json profile = parse_json(profile_response, "auth.error.profile");
    if (profile_response.status < 200 || profile_response.status >= 300) {
        throw AuthError("auth.error.profile", profile_response.body);
    }
    const std::string name = string_field(profile, "name");
    const std::string uuid = string_field(profile, "id");
    if (name.empty() || uuid.empty()) {
        throw AuthError("auth.error.profileIncomplete", profile_response.body);
    }

    Account account;
    account.name = name;
    account.uuid = uuid;
    account.refresh_token = refresh_token;
    account.access_token = mc_access;
    account.access_expires_at =
        static_cast<std::int64_t>(std::time(nullptr)) + mc_expires;
    secure::clear_string(xbl_token);
    secure::clear_string(xsts_token);
    secure::clear_string(mc_access);
    return account;
}

Account AuthService::login(
    const std::function<void(const DeviceCodeInfo&)>& on_code,
    const std::atomic_bool& cancelled) const {
    const DeviceCodeInfo info = request_device_code();
    on_code(info);

    const auto deadline = std::chrono::steady_clock::now() +
                          std::chrono::seconds(info.expires_in);
    int wait_seconds = info.interval;
    while (!cancelled.load()) {
        if (std::chrono::steady_clock::now() >= deadline) {
            throw AuthError("auth.error.timeout", "device code expired");
        }
        for (int i = 0; i < wait_seconds * 10 && !cancelled.load(); ++i) {
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
        }
        if (cancelled.load()) break;
        try {
            if (auto account = poll_device_code(info)) {
                if (cancelled.load()) {
                    throw AuthError("auth.error.cancelled", "cancelled");
                }
                return *account;
            }
        } catch (const AuthError& error) {
            if (error.key() == "auth.error.slowDown") {
                wait_seconds = std::min(wait_seconds + 5, 60);
                continue;
            }
            throw;
        }
    }
    throw AuthError("auth.error.cancelled", "cancelled");
}

}  // namespace jol::auth
