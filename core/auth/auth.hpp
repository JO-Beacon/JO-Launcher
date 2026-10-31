#pragma once

#include <atomic>
#include <cstdint>
#include <functional>
#include <optional>
#include <stdexcept>
#include <string>
#include <utility>

namespace jol::auth {

struct DeviceCodeInfo {
    std::string user_code;
    std::string device_code;
    std::string verification_uri;
    int expires_in = 0;
    int interval = 0;
};

struct Account {
    std::string name;
    std::string uuid;
    std::string refresh_token;
    std::string access_token;
    std::int64_t access_expires_at = 0;  // Unix seconds.
};

inline std::string redact_secrets(std::string text) {
    for (const char* key : {"access_token", "refresh_token", "Token", "token"}) {
        const std::string needle = std::string("\"") + key + "\"";
        std::size_t pos = 0;
        while ((pos = text.find(needle, pos)) != std::string::npos) {
            const auto colon = text.find(':', pos + needle.size());
            if (colon == std::string::npos) break;
            const auto open = text.find('"', colon);
            if (open == std::string::npos) break;
            const auto close = text.find('"', open + 1);
            if (close == std::string::npos) break;
            text.replace(open + 1, close - open - 1, "***");
            pos = open + 4;
        }
    }
    return text;
}

class AuthError : public std::runtime_error {
public:
    AuthError(std::string key, std::string detail)
        : std::runtime_error(redact_secrets(std::move(detail))),
          key_(std::move(key)) {}

    const std::string& key() const { return key_; }

private:
    std::string key_;
};

class AuthService {
public:
    explicit AuthService(std::string client_id);
    ~AuthService();

    DeviceCodeInfo request_device_code() const;

    /// Returns nullopt while the user has not finished sign-in.
    std::optional<Account> poll_device_code(const DeviceCodeInfo& info) const;

    Account refresh(const Account& account) const;

    Account login(const std::function<void(const DeviceCodeInfo&)>& on_code,
                  const std::atomic_bool& cancelled) const;

    static std::string client_id_from_environment();

private:
    std::string client_id_;

    Account exchange(const std::string& ms_access_token,
                     const std::string& refresh_token) const;
};

}  // namespace jol::auth
