#include "account_store.hpp"

#include "product_info.hpp"
#include "platform/mutex.hpp"
#include "platform/paths.hpp"
#include "platform/secret.hpp"
#include "secure_wipe.hpp"

#include <cstdint>
#include <fstream>
#include <vector>

#include <nlohmann/json.hpp>

namespace jol::auth {
namespace {

using json = nlohmann::json;

std::filesystem::path account_dir() {
    const auto base = platform::roaming_app_data();
    if (!base.empty()) {
        return base / L"JO-Beacon" / kDataDirectoryName;
    }
    return platform::temp_directory() / kDataDirectoryName;
}

std::vector<std::uint8_t> protect(const std::string& plain) {
    const auto cipher = platform::protect_secret(plain);
    return std::vector<std::uint8_t>(cipher.begin(), cipher.end());
}

std::optional<std::string> unprotect(const std::vector<std::uint8_t>& cipher) {
    const std::vector<std::uint8_t> bytes(cipher.begin(), cipher.end());
    return platform::unprotect_secret(bytes);
}

}  // namespace

AccountStore::AccountStore() : path_(account_dir() / L"account.dat") {}

std::optional<Account> AccountStore::load() const {
    platform::NamedMutex lock("Local\\JO-Launcher-Account");
    std::error_code size_ec;
    const auto size = std::filesystem::file_size(path_, size_ec);
    if (!size_ec && size > 1024 * 1024) return std::nullopt;
    std::ifstream stream(path_, std::ios::binary);
    if (!stream) return std::nullopt;
    const std::vector<std::uint8_t> cipher((std::istreambuf_iterator<char>(stream)),
                                   std::istreambuf_iterator<char>());
    auto plain = unprotect(cipher);
    if (!plain) return std::nullopt;

    try {
        const json value = json::parse(*plain);
        if (!value.is_object()) {
            secure::clear_string(*plain);
            return std::nullopt;
        }
        Account account;
        account.name = value.value("name", "");
        account.uuid = value.value("uuid", "");
        account.refresh_token = value.value("refresh_token", "");
        account.access_token = value.value("access_token", "");
        account.access_expires_at = value.value("access_expires_at", 0LL);
        if (account.name.empty() || account.uuid.empty() ||
            account.refresh_token.empty() || account.access_token.empty()) {
            secure::clear_string(*plain);
            return std::nullopt;
        }
        secure::clear_string(*plain);
        return account;
    } catch (...) {
        secure::clear_string(*plain);
        return std::nullopt;
    }
}

bool AccountStore::save(const Account& account) const {
    platform::NamedMutex lock("Local\\JO-Launcher-Account");
    std::error_code ec;
    std::filesystem::create_directories(path_.parent_path(), ec);
    if (ec) return false;

    const json value{{"name", account.name},
                     {"uuid", account.uuid},
                     {"refresh_token", account.refresh_token},
                     {"access_token", account.access_token},
                     {"access_expires_at", account.access_expires_at}};
    std::string plain = value.dump();
    const std::vector<std::uint8_t> cipher = protect(plain);
    jol::secure::clear_string(plain);
    if (cipher.empty()) return false;

    const auto temp = path_.parent_path() / (path_.filename().wstring() + L".tmp");
    {
        std::ofstream stream(temp, std::ios::binary | std::ios::trunc);
        if (!stream) return false;
        stream.write(reinterpret_cast<const char*>(cipher.data()),
                     static_cast<std::streamsize>(cipher.size()));
        if (!stream.good()) {
            stream.close();
            std::filesystem::remove(temp, ec);
            return false;
        }
    }
    if (!platform::atomic_replace(temp, path_)) {
        std::filesystem::remove(temp, ec);
        return false;
    }
    return true;
}

void AccountStore::clear() const {
    platform::NamedMutex lock("Local\\JO-Launcher-Account");
    std::error_code ec;
    std::filesystem::remove(path_, ec);
}

}  // namespace jol::auth
