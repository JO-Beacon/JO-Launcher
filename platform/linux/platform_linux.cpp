#include "platform/environment.hpp"
#include "platform/mutex.hpp"
#include "platform/paths.hpp"
#include "platform/secret.hpp"
#include "platform/system.hpp"
#include "platform/text.hpp"

#include <fcntl.h>
#include <sodium.h>
#include <sys/file.h>
#include <sys/stat.h>
#include <unistd.h>

#include <cstdlib>
#include <string>
#include <system_error>
#include <vector>

namespace jol::platform {
namespace {

struct MutexImpl {
    int fd = -1;
};

std::string sanitize(const char* name) {
    std::string result;
    for (const char* p = name; p != nullptr && *p != '\0'; ++p) {
        const unsigned char c = static_cast<unsigned char>(*p);
        result.push_back((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
                                 (c >= '0' && c <= '9')
                             ? static_cast<char>(c)
                             : '-');
    }
    return result;
}

}  // namespace

namespace {

std::wstring decode_utf8(const std::string& text) {
    std::wstring result;
    std::size_t i = 0;
    while (i < text.size()) {
        const unsigned char lead = static_cast<unsigned char>(text[i]);
        std::uint32_t code = 0;
        std::size_t extra = 0;
        if (lead < 0x80) {
            code = lead;
        } else if ((lead & 0xE0) == 0xC0) {
            code = lead & 0x1F;
            extra = 1;
        } else if ((lead & 0xF0) == 0xE0) {
            code = lead & 0x0F;
            extra = 2;
        } else if ((lead & 0xF8) == 0xF0) {
            code = lead & 0x07;
            extra = 3;
        } else {
            ++i;
            continue;
        }
        if (i + extra >= text.size()) break;
        for (std::size_t k = 1; k <= extra; ++k) {
            code = (code << 6) |
                   (static_cast<unsigned char>(text[i + k]) & 0x3F);
        }
        result.push_back(static_cast<wchar_t>(code));
        i += extra + 1;
    }
    return result;
}

std::string encode_utf8(const std::wstring& text) {
    std::string result;
    for (const wchar_t wide : text) {
        const std::uint32_t code = static_cast<std::uint32_t>(wide);
        if (code < 0x80) {
            result.push_back(static_cast<char>(code));
        } else if (code < 0x800) {
            result.push_back(static_cast<char>(0xC0 | (code >> 6)));
            result.push_back(static_cast<char>(0x80 | (code & 0x3F)));
        } else if (code < 0x10000) {
            result.push_back(static_cast<char>(0xE0 | (code >> 12)));
            result.push_back(static_cast<char>(0x80 | ((code >> 6) & 0x3F)));
            result.push_back(static_cast<char>(0x80 | (code & 0x3F)));
        } else {
            result.push_back(static_cast<char>(0xF0 | (code >> 18)));
            result.push_back(static_cast<char>(0x80 | ((code >> 12) & 0x3F)));
            result.push_back(static_cast<char>(0x80 | ((code >> 6) & 0x3F)));
            result.push_back(static_cast<char>(0x80 | (code & 0x3F)));
        }
    }
    return result;
}

}  // namespace

std::wstring widen(const std::string& utf8) { return decode_utf8(utf8); }

std::string narrow(const std::wstring& wide) { return encode_utf8(wide); }

std::filesystem::path path_from_utf8(const std::string& utf8) {
    return std::filesystem::path(utf8);
}

std::string path_to_utf8(const std::filesystem::path& path) {
    return path.string();
}

std::uint64_t total_physical_memory() {
    const long pages = ::sysconf(_SC_PHYS_PAGES);
    const long page_size = ::sysconf(_SC_PAGE_SIZE);
    if (pages <= 0 || page_size <= 0) return 0;
    return static_cast<std::uint64_t>(pages) *
           static_cast<std::uint64_t>(page_size);
}

std::vector<std::filesystem::path> java_roots() {
    std::vector<std::filesystem::path> roots{"/usr/lib/jvm", "/usr/java",
                                             "/opt/java"};
    if (const auto home = environment_path("HOME")) {
        roots.push_back(*home / ".sdkman" / "candidates" / "java");
        roots.push_back(*home / ".jdks");
    }
    return roots;
}

std::filesystem::path launcher_runtime_dir() {
    if (const auto data = platform::local_app_data(); !data.empty()) {
        return data / "JO-Launcher" / "runtime";
    }
    return {};
}

const char* os_arch() {
#if defined(__aarch64__)
    return "arm64";
#elif defined(__x86_64__)
    return "x86_64";
#else
    return "x86";
#endif
}

const char* os_name() { return "linux"; }

char classpath_separator() { return ':'; }

const char* natives_classifier() { return "linux"; }

std::string java_console_name() { return "java"; }

std::string java_windowless_name() { return {}; }

std::filesystem::path console_java(const std::filesystem::path& executable) {
    return executable;
}

std::filesystem::path executable_path() {
    std::error_code ec;
    const auto path = std::filesystem::read_symlink("/proc/self/exe", ec);
    return ec ? std::filesystem::path{} : path;
}

std::filesystem::path roaming_app_data() {
    if (const char* config = std::getenv("XDG_CONFIG_HOME");
        config != nullptr && *config != '\0') {
        return std::filesystem::path(config);
    }
    if (const char* home = std::getenv("HOME");
        home != nullptr && *home != '\0') {
        return std::filesystem::path(home) / ".config";
    }
    return {};
}

std::filesystem::path local_app_data() {
    if (const char* data = std::getenv("XDG_DATA_HOME");
        data != nullptr && *data != '\0') {
        return std::filesystem::path(data);
    }
    if (const char* home = std::getenv("HOME");
        home != nullptr && *home != '\0') {
        return std::filesystem::path(home) / ".local" / "share";
    }
    return {};
}

bool is_reparse_point(const std::filesystem::path& path) {
    std::error_code ec;
    return std::filesystem::is_symlink(path, ec);
}

std::filesystem::path default_minecraft_directory() {
    if (const auto home = environment_path("HOME")) {
        return *home / ".minecraft";
    }
    return {};
}

std::filesystem::path temp_directory() {
    return std::filesystem::temp_directory_path();
}

bool atomic_replace(const std::filesystem::path& source,
                    const std::filesystem::path& target) {
    return ::rename(source.c_str(), target.c_str()) == 0;
}

std::optional<std::filesystem::path> environment_path(const char* name) {
    const char* value = std::getenv(name);
    if (value == nullptr || *value == '\0') return std::nullopt;
    return std::filesystem::path(value);
}

std::optional<std::string> environment_string(const char* name) {
    const char* value = std::getenv(name);
    if (value == nullptr || *value == '\0') return std::nullopt;
    return std::string(value);
}

namespace {

std::filesystem::path secret_key_path() {
    const auto base = local_app_data();
    if (base.empty()) return {};
    return base / "JO-Launcher" / "secret.key";
}

std::vector<unsigned char> load_or_create_key() {
    std::vector<unsigned char> key(crypto_secretbox_KEYBYTES);
    const auto path = secret_key_path();
    if (path.empty()) return {};

    std::error_code ec;
    std::filesystem::create_directories(path.parent_path(), ec);
    ::chmod(path.parent_path().c_str(), 0700);

    const auto read_key = [&key, &path]() -> bool {
        const int fd = ::open(path.c_str(), O_RDONLY);
        if (fd < 0) return false;
        std::size_t done = 0;
        while (done < key.size()) {
            const ssize_t got =
                ::read(fd, key.data() + done, key.size() - done);
            if (got <= 0) break;
            done += static_cast<std::size_t>(got);
        }
        ::close(fd);
        return done == key.size();
    };

    if (read_key()) return key;

    const int fd = ::open(path.c_str(), O_CREAT | O_EXCL | O_WRONLY, 0600);
    if (fd < 0) {
        // Another process won the race; use the key it wrote.
        return read_key() ? key : std::vector<unsigned char>{};
    }
    randombytes_buf(key.data(), key.size());
    std::size_t done = 0;
    while (done < key.size()) {
        const ssize_t wrote = ::write(fd, key.data() + done, key.size() - done);
        if (wrote <= 0) break;
        done += static_cast<std::size_t>(wrote);
    }
    ::close(fd);
    if (done != key.size()) return {};
    return key;
}

}  // namespace

std::vector<std::uint8_t> protect_secret(const std::string& plain) {
    if (sodium_init() < 0) return {};
    auto key = load_or_create_key();
    if (key.size() != crypto_secretbox_KEYBYTES) {
        return {};
    }
    std::vector<std::uint8_t> out(crypto_secretbox_NONCEBYTES +
                                  crypto_secretbox_MACBYTES + plain.size());
    randombytes_buf(out.data(), crypto_secretbox_NONCEBYTES);
    const int status = crypto_secretbox_easy(
        out.data() + crypto_secretbox_NONCEBYTES,
        reinterpret_cast<const unsigned char*>(plain.data()), plain.size(),
        out.data(), key.data());
    sodium_memzero(key.data(), key.size());
    if (status != 0) return {};
    return out;
}

std::optional<std::string> unprotect_secret(
    const std::vector<std::uint8_t>& cipher) {
    if (cipher.size() <
        crypto_secretbox_NONCEBYTES + crypto_secretbox_MACBYTES) {
        return std::nullopt;
    }
    if (sodium_init() < 0) return std::nullopt;
    auto key = load_or_create_key();
    if (key.size() != crypto_secretbox_KEYBYTES) {
        return std::nullopt;
    }
    std::vector<unsigned char> plain(cipher.size() -
                                     crypto_secretbox_NONCEBYTES -
                                     crypto_secretbox_MACBYTES);
    const int status = crypto_secretbox_open_easy(
        plain.data(), cipher.data() + crypto_secretbox_NONCEBYTES,
        cipher.size() - crypto_secretbox_NONCEBYTES, cipher.data(),
        key.data());
    sodium_memzero(key.data(), key.size());
    if (status != 0) return std::nullopt;
    std::string result(reinterpret_cast<char*>(plain.data()), plain.size());
    sodium_memzero(plain.data(), plain.size());
    return result;
}

NamedMutex::NamedMutex(const char* name) {
    auto* impl = new MutexImpl;
    const auto path = temp_directory() / ("jo-launcher-" + sanitize(name) + ".lock");
    impl->fd = ::open(path.c_str(), O_CREAT | O_RDWR, 0600);
    if (impl->fd >= 0) {
        ::flock(impl->fd, LOCK_EX);
    }
    impl_ = impl;
}

NamedMutex::~NamedMutex() {
    auto* impl = static_cast<MutexImpl*>(impl_);
    if (impl == nullptr) return;
    if (impl->fd >= 0) {
        ::flock(impl->fd, LOCK_UN);
        ::close(impl->fd);
    }
    delete impl;
}

bool NamedMutex::locked() const {
    const auto* impl = static_cast<const MutexImpl*>(impl_);
    return impl != nullptr && impl->fd >= 0;
}

}  // namespace jol::platform
