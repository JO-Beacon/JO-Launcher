#include "platform/environment.hpp"
#include "platform/mutex.hpp"
#include "platform/paths.hpp"
#include "platform/secret.hpp"
#include "platform/system.hpp"
#include "platform/text.hpp"

#include <windows.h>
#include <shlobj.h>
#include <wincrypt.h>

#include <string>
#include <vector>

namespace jol::platform {
namespace {

constexpr BYTE kEntropy[] = {'J', 'O', 'L', '-', 'A', 'c', 'c', 'o', 'u', 'n', 't'};

std::wstring to_wide(const std::string& text) {
    if (text.empty()) return {};
    const int size = MultiByteToWideChar(CP_UTF8, 0, text.c_str(),
                                         static_cast<int>(text.size()),
                                         nullptr, 0);
    if (size <= 0) return {};
    std::wstring result(static_cast<std::size_t>(size), L'\0');
    MultiByteToWideChar(CP_UTF8, 0, text.c_str(),
                        static_cast<int>(text.size()), result.data(), size);
    return result;
}

std::string to_utf8(const std::wstring& text) {
    if (text.empty()) return {};
    const int size = WideCharToMultiByte(CP_UTF8, 0, text.c_str(),
                                         static_cast<int>(text.size()),
                                         nullptr, 0, nullptr, nullptr);
    if (size <= 0) return {};
    std::string result(static_cast<std::size_t>(size), '\0');
    WideCharToMultiByte(CP_UTF8, 0, text.c_str(),
                        static_cast<int>(text.size()), result.data(), size,
                        nullptr, nullptr);
    return result;
}

std::optional<std::wstring> env_wide(const char* name) {
    const std::wstring wide = to_wide(name);
    if (wide.empty()) return std::nullopt;
    const DWORD size = GetEnvironmentVariableW(wide.c_str(), nullptr, 0);
    if (size == 0) return std::nullopt;
    std::wstring value(size, L'\0');
    const DWORD written = GetEnvironmentVariableW(wide.c_str(), value.data(), size);
    if (written == 0 || written >= size) return std::nullopt;
    value.resize(written);
    return value;
}

std::filesystem::path known_folder(REFKNOWNFOLDERID id) {
    PWSTR raw = nullptr;
    if (FAILED(SHGetKnownFolderPath(id, 0, nullptr, &raw))) return {};
    std::filesystem::path result(raw);
    CoTaskMemFree(raw);
    return result;
}

struct MutexImpl {
    HANDLE handle = nullptr;
    bool locked = false;
};

}  // namespace

std::uint64_t total_physical_memory() {
    MEMORYSTATUSEX status{};
    status.dwLength = sizeof(status);
    if (!GlobalMemoryStatusEx(&status)) return 0;
    return status.ullTotalPhys;
}

std::vector<std::filesystem::path> java_roots() {
    std::vector<std::filesystem::path> roots;
    if (const auto program_files = environment_path("ProgramFiles")) {
        const auto base = *program_files;
        roots.push_back(base / L"Java");
        roots.push_back(base / L"Eclipse Adoptium");
        roots.push_back(base / L"Microsoft");
        roots.push_back(base / L"Zulu");
        roots.push_back(base / L"BellSoft");
    }
    if (const auto local = environment_path("LOCALAPPDATA")) {
        const auto base = *local;
        roots.push_back(base / L"Programs" / L"Eclipse Adoptium");
        roots.push_back(base / L"Programs" / L"Microsoft");
        roots.push_back(base / L"Programs" / L"Java");
        roots.push_back(base / L".minecraft" / L"runtime");
    }
    if (const auto roaming = environment_path("APPDATA")) {
        roots.push_back(*roaming / L".minecraft" / L"runtime");
    }
    return roots;
}

std::filesystem::path launcher_runtime_dir() {
    if (const auto local = platform::local_app_data(); !local.empty()) {
        return local / L"Programs" / L"JO-Launcher" / L"runtime";
    }
    return {};
}

const char* os_arch() {
#if defined(_M_ARM64)
    return "arm64";
#elif defined(_M_X64)
    return "x86_64";
#else
    return "x86";
#endif
}

const char* os_name() { return "windows"; }

char classpath_separator() { return ';'; }

const char* natives_classifier() { return "windows"; }

std::string java_console_name() { return "java.exe"; }

std::string java_windowless_name() { return "javaw.exe"; }

std::filesystem::path console_java(const std::filesystem::path& executable) {
    if (executable.filename() != L"javaw.exe") return executable;
    const auto console = executable.parent_path() / L"java.exe";
    std::error_code ec;
    return std::filesystem::is_regular_file(console, ec) ? console : executable;
}

std::filesystem::path executable_path() {
    std::wstring buffer(32768, L'\0');
    const DWORD length = GetModuleFileNameW(
        nullptr, buffer.data(), static_cast<DWORD>(buffer.size()));
    buffer.resize(length);
    return std::filesystem::path(buffer);
}

std::filesystem::path roaming_app_data() {
    return known_folder(FOLDERID_RoamingAppData);
}

std::filesystem::path local_app_data() {
    return known_folder(FOLDERID_LocalAppData);
}

bool is_reparse_point(const std::filesystem::path& path) {
    const DWORD attributes = GetFileAttributesW(path.c_str());
    return attributes != INVALID_FILE_ATTRIBUTES &&
           (attributes & FILE_ATTRIBUTE_REPARSE_POINT) != 0;
}

std::filesystem::path default_minecraft_directory() {
    const auto base = roaming_app_data();
    if (!base.empty()) return base / L".minecraft";
    return {};
}

std::filesystem::path temp_directory() {
    return std::filesystem::temp_directory_path();
}

bool atomic_replace(const std::filesystem::path& source,
                    const std::filesystem::path& target) {
    return MoveFileExW(source.c_str(), target.c_str(),
                       MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH) != 0;
}

std::optional<std::filesystem::path> environment_path(const char* name) {
    if (const auto value = env_wide(name); value && !value->empty()) {
        return std::filesystem::path(*value);
    }
    return std::nullopt;
}

std::optional<std::string> environment_string(const char* name) {
    if (const auto value = env_wide(name); value && !value->empty()) {
        return to_utf8(*value);
    }
    return std::nullopt;
}

std::wstring widen(const std::string& utf8) { return to_wide(utf8); }

std::string narrow(const std::wstring& wide) { return to_utf8(wide); }

std::filesystem::path path_from_utf8(const std::string& utf8) {
    return std::filesystem::path(widen(utf8));
}

std::string path_to_utf8(const std::filesystem::path& path) {
    return narrow(path.wstring());
}

std::vector<std::uint8_t> protect_secret(const std::string& plain) {
    DATA_BLOB input{static_cast<DWORD>(plain.size()),
                    reinterpret_cast<BYTE*>(const_cast<char*>(plain.data()))};
    DATA_BLOB entropy{static_cast<DWORD>(sizeof(kEntropy)),
                      const_cast<BYTE*>(kEntropy)};
    DATA_BLOB output{};
    if (!CryptProtectData(&input, L"JO-Launcher account", &entropy, nullptr,
                          nullptr, 0, &output)) {
        return {};
    }
    std::vector<std::uint8_t> result(output.pbData, output.pbData + output.cbData);
    LocalFree(output.pbData);
    return result;
}

std::optional<std::string> unprotect_secret(
    const std::vector<std::uint8_t>& cipher) {
    if (cipher.empty()) return std::nullopt;
    DATA_BLOB input{static_cast<DWORD>(cipher.size()),
                    const_cast<BYTE*>(cipher.data())};
    DATA_BLOB entropy{static_cast<DWORD>(sizeof(kEntropy)),
                      const_cast<BYTE*>(kEntropy)};
    DATA_BLOB output{};
    if (!CryptUnprotectData(&input, nullptr, &entropy, nullptr, nullptr, 0,
                            &output)) {
        return std::nullopt;
    }
    std::string result(reinterpret_cast<char*>(output.pbData), output.cbData);
    SecureZeroMemory(output.pbData, output.cbData);
    LocalFree(output.pbData);
    return result;
}

NamedMutex::NamedMutex(const char* name) {
    auto* impl = new MutexImpl;
    const std::wstring wide = to_wide(name);
    impl->handle = CreateMutexW(nullptr, FALSE, wide.c_str());
    if (impl->handle != nullptr) {
        const DWORD result = WaitForSingleObject(impl->handle, INFINITE);
        // WAIT_ABANDONED still means we own the mutex: the previous owner
        // died without releasing it.
        impl->locked = result == WAIT_OBJECT_0 || result == WAIT_ABANDONED;
    }
    impl_ = impl;
}

NamedMutex::~NamedMutex() {
    auto* impl = static_cast<MutexImpl*>(impl_);
    if (impl == nullptr) return;
    if (impl->handle != nullptr) {
        if (impl->locked) ReleaseMutex(impl->handle);
        CloseHandle(impl->handle);
    }
    delete impl;
}

bool NamedMutex::locked() const {
    const auto* impl = static_cast<const MutexImpl*>(impl_);
    return impl != nullptr && impl->locked;
}

}  // namespace jol::platform
