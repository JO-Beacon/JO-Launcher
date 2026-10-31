#pragma once

#include <filesystem>
#include <optional>

#include "auth.hpp"

namespace jol::auth {

/// Stores the account in a DPAPI-protected file under
/// `%APPDATA%\JO-Beacon\<product>`.
class AccountStore {
public:
    AccountStore();

    std::optional<Account> load() const;
    bool save(const Account& account) const;
    void clear() const;

private:
    std::filesystem::path path_;
};

}  // namespace jol::auth
