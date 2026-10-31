#include "app.hpp"

#include <algorithm>
#include <cctype>
#include <cstring>
#include <cwctype>
#include <string>

#include <shellapi.h>
#include <shobjidl.h>
#include <dwmapi.h>

#include "product_info.hpp"
#include "log.hpp"
#include "platform/paths.hpp"
#include "platform/system.hpp"
#include "platform/text.hpp"

#include "auth/auth.hpp"
#include "auth/client_id.hpp"
#include "game_dir.hpp"
#include "launch/launch.hpp"
#include "mc/version_manager.hpp"
#include "resource.h"
#include "secure_wipe.hpp"
#include "settings_store.hpp"
#include "ui.hpp"

#include <miniz.h>

namespace jol::win32 {
namespace {

COLORREF kBg = RGB(0x0E, 0x0F, 0x12);
COLORREF kSurface = RGB(0x16, 0x18, 0x1D);
COLORREF kBorder = RGB(0x26, 0x2A, 0x31);
COLORREF kText = RGB(0xE6, 0xE3, 0xDC);
COLORREF kSecondary = RGB(0x8A, 0x8F, 0x98);
COLORREF kAccent = RGB(0x8A, 0xA0, 0xB8);
COLORREF kHover = RGB(0x1C, 0x1F, 0x25);

Palette paletteFor(bool dark) {
    if (dark) {
        return Palette{RGB(0x0E, 0x0F, 0x12), RGB(0x16, 0x18, 0x1D),
                       RGB(0x26, 0x2A, 0x31), RGB(0xE6, 0xE3, 0xDC),
                       RGB(0x8A, 0x8F, 0x98), RGB(0x8A, 0xA0, 0xB8),
                       RGB(0x1C, 0x1F, 0x25)};
    }
    return Palette{RGB(0xF5, 0xF2, 0xEC), RGB(0xFB, 0xFA, 0xF6),
                   RGB(0xE0, 0xDA, 0xD0), RGB(0x1C, 0x1B, 0x19),
                   RGB(0x6E, 0x6A, 0x62), RGB(0x4A, 0x6B, 0x8A),
                   RGB(0xEC, 0xE7, 0xDD)};
}

Palette currentPalette() {
    return Palette{kBg, kSurface, kBorder, kText, kSecondary, kAccent,
                   kHover};
}

int blendChannel(int from, int to, float t) {
    return static_cast<int>(static_cast<float>(from) +
                            (static_cast<float>(to) - static_cast<float>(from)) *
                                t +
                            0.5f);
}

COLORREF blendColor(COLORREF from, COLORREF to, float t) {
    return RGB(blendChannel(GetRValue(from), GetRValue(to), t),
               blendChannel(GetGValue(from), GetGValue(to), t),
               blendChannel(GetBValue(from), GetBValue(to), t));
}

void applyPaletteBlend(const Palette& from, const Palette& to, float t) {
    kBg = blendColor(from.bg, to.bg, t);
    kSurface = blendColor(from.surface, to.surface, t);
    kBorder = blendColor(from.border, to.border, t);
    kText = blendColor(from.text, to.text, t);
    kSecondary = blendColor(from.secondary, to.secondary, t);
    kAccent = blendColor(from.accent, to.accent, t);
    kHover = blendColor(from.hover, to.hover, t);
}

void applyPalette(bool dark) {
    const Palette palette = paletteFor(dark);
    applyPaletteBlend(palette, palette, 1.0f);
}

int s(int value, UINT dpi) {
    return MulDiv(value, static_cast<int>(dpi), 96);
}

D2D1_COLOR_F color(COLORREF value) {
    return D2D1::ColorF(GetRValue(value) / 255.0f,
                        GetGValue(value) / 255.0f,
                        GetBValue(value) / 255.0f, 1.0f);
}

RECT label_band(const RECT& row, int dpi, bool with_hint) {
    const int label_height = s(24, dpi);
    const int hint_height = s(20, dpi);
    const int block = with_hint ? label_height + hint_height : label_height;
    const int height = static_cast<int>(row.bottom - row.top);
    const int top = static_cast<int>(row.top) + (height - block) / 2;
    return RECT{row.left, top, row.right, top + block};
}

D2D1_RECT_F rect(int left, int top, int right, int bottom) {
    return D2D1::RectF(static_cast<float>(left), static_cast<float>(top),
                       static_cast<float>(right), static_cast<float>(bottom));
}

std::wstring widen(const std::string& value) {
    if (value.empty()) return {};
    const int length = MultiByteToWideChar(CP_UTF8, 0, value.data(),
                                           static_cast<int>(value.size()),
                                           nullptr, 0);
    std::wstring result(static_cast<size_t>(length), L'\0');
    MultiByteToWideChar(CP_UTF8, 0, value.data(),
                        static_cast<int>(value.size()), result.data(), length);
    return result;
}

std::string narrow(const std::wstring& value) {
    if (value.empty()) return {};
    const int length = WideCharToMultiByte(CP_UTF8, 0, value.data(),
                                            static_cast<int>(value.size()),
                                            nullptr, 0, nullptr, nullptr);
    std::string result(static_cast<size_t>(length), '\0');
    WideCharToMultiByte(CP_UTF8, 0, value.data(),
                        static_cast<int>(value.size()), result.data(),
                        length, nullptr, nullptr);
    return result;
}

std::wstring trim(const std::wstring& value) {
    const auto first = value.find_first_not_of(L" \t\r\n");
    if (first == std::wstring::npos) return {};
    const auto last = value.find_last_not_of(L" \t\r\n");
    return value.substr(first, last - first + 1);
}

std::string displayLoader(std::string value) {
    if (!value.empty()) {
        value[0] = static_cast<char>(
            std::toupper(static_cast<unsigned char>(value[0])));
    }
    return value;
}

int contentLeft(int rail_width, UINT dpi) {
    return s(rail_width + 42, dpi);
}

int contentRight(const RECT& client, int rail_width, UINT dpi) {
    const int left = contentLeft(rail_width, dpi);
    return left + std::min(s(760, dpi),
                           static_cast<int>(client.right) - left - s(32, dpi));
}

bool hit(int x, int y, const RECT& rect) {
    return x >= rect.left && x < rect.right && y >= rect.top &&
           y < rect.bottom;
}

void clear_account_tokens(jol::auth::Account& account) {
    jol::secure::clear_string(account.refresh_token);
    jol::secure::clear_string(account.access_token);
}

bool systemPrefersDark() {
    DWORD value = 1;
    DWORD size = sizeof(value);
    RegGetValueW(HKEY_CURRENT_USER,
                 L"Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize",
                 L"AppsUseLightTheme", RRF_RT_REG_DWORD, nullptr, &value,
                 &size);
    return value == 0;
}

std::filesystem::path chooseFolder(HWND window,
                                   const std::filesystem::path& initial) {
    Microsoft::WRL::ComPtr<IFileOpenDialog> dialog;
    if (FAILED(CoCreateInstance(CLSID_FileOpenDialog, nullptr,
                                CLSCTX_INPROC_SERVER,
                                IID_PPV_ARGS(dialog.GetAddressOf())))) {
        return {};
    }
    DWORD options = 0;
    dialog->GetOptions(&options);
    dialog->SetOptions(options | FOS_PICKFOLDERS | FOS_FORCEFILESYSTEM);
    if (!initial.empty()) {
        Microsoft::WRL::ComPtr<IShellItem> folder;
        if (SUCCEEDED(SHCreateItemFromParsingName(
                initial.c_str(), nullptr,
                IID_PPV_ARGS(folder.GetAddressOf())))) {
            dialog->SetFolder(folder.Get());
        }
    }
    if (FAILED(dialog->Show(window))) return {};

    Microsoft::WRL::ComPtr<IShellItem> result;
    if (FAILED(dialog->GetResult(result.GetAddressOf()))) return {};
    PWSTR selected = nullptr;
    if (FAILED(result->GetDisplayName(SIGDN_FILESYSPATH, &selected))) return {};
    std::filesystem::path path(selected);
    CoTaskMemFree(selected);
    return path;
}

std::filesystem::path chooseZipFile(HWND window,
                                    const std::filesystem::path& initial,
                                    Language language) {
    Microsoft::WRL::ComPtr<IFileOpenDialog> dialog;
    if (FAILED(CoCreateInstance(CLSID_FileOpenDialog, nullptr,
                                CLSCTX_INPROC_SERVER,
                                IID_PPV_ARGS(dialog.GetAddressOf())))) {
        return {};
    }
    const COMDLG_FILTERSPEC filter{tr(language, Text::zipArchives),
                                   L"*.zip"};
    dialog->SetFileTypes(1, &filter);
    DWORD options = 0;
    dialog->GetOptions(&options);
    dialog->SetOptions(options | FOS_FILEMUSTEXIST | FOS_FORCEFILESYSTEM);
    if (!initial.empty()) {
        Microsoft::WRL::ComPtr<IShellItem> folder;
        if (SUCCEEDED(SHCreateItemFromParsingName(
                initial.c_str(), nullptr,
                IID_PPV_ARGS(folder.GetAddressOf())))) {
            dialog->SetFolder(folder.Get());
        }
    }
    if (FAILED(dialog->Show(window))) return {};

    Microsoft::WRL::ComPtr<IShellItem> result;
    if (FAILED(dialog->GetResult(result.GetAddressOf()))) return {};
    PWSTR selected = nullptr;
    if (FAILED(result->GetDisplayName(SIGDN_FILESYSPATH, &selected))) return {};
    std::filesystem::path path(selected);
    CoTaskMemFree(selected);
    return path;
}

std::filesystem::path chooseJavaFile(HWND window, Language language) {
    Microsoft::WRL::ComPtr<IFileOpenDialog> dialog;
    if (FAILED(CoCreateInstance(CLSID_FileOpenDialog, nullptr,
                                CLSCTX_INPROC_SERVER,
                                IID_PPV_ARGS(dialog.GetAddressOf())))) {
        return {};
    }
    const COMDLG_FILTERSPEC filter{tr(language, Text::javaExecutables),
                                   L"java.exe;javaw.exe"};
    dialog->SetFileTypes(1, &filter);
    DWORD options = 0;
    dialog->GetOptions(&options);
    dialog->SetOptions(options | FOS_FILEMUSTEXIST | FOS_FORCEFILESYSTEM);
    if (FAILED(dialog->Show(window))) return {};
    Microsoft::WRL::ComPtr<IShellItem> result;
    if (FAILED(dialog->GetResult(result.GetAddressOf()))) return {};
    PWSTR selected = nullptr;
    if (FAILED(result->GetDisplayName(SIGDN_FILESYSPATH, &selected))) return {};
    std::filesystem::path path(selected);
    CoTaskMemFree(selected);
    return path;
}

}  // namespace

std::mutex App::payload_mutex_;
std::set<void*> App::pending_payloads_;

void App::remember_payload(void* payload) {
    std::lock_guard<std::mutex> lock(payload_mutex_);
    pending_payloads_.insert(payload);
}

void App::forget_payload(void* payload) {
    std::lock_guard<std::mutex> lock(payload_mutex_);
    pending_payloads_.erase(payload);
}

bool App::accept_payload(void* payload) {
    std::lock_guard<std::mutex> lock(payload_mutex_);
    const auto it = pending_payloads_.find(payload);
    if (it == pending_payloads_.end()) return false;
    pending_payloads_.erase(it);
    return true;
}

std::string App::client_id() const {
    if (!global_settings_.client_id.empty()) return global_settings_.client_id;
    return jol::auth::resolve_client_id();
}

App::App() {
    jol::log::info("app", "creating main window");
    D2D1CreateFactory(D2D1_FACTORY_TYPE_SINGLE_THREADED, d2d_.GetAddressOf());
    DWriteCreateFactory(DWRITE_FACTORY_TYPE_SHARED, __uuidof(IDWriteFactory),
                        reinterpret_cast<IUnknown**>(
                            dwrite_.GetAddressOf()));
    game_dir_ = jol::defaultGameDir(jol::platform::executable_path());
    jol::log::info("app", "game directory: " +
                              jol::platform::path_to_utf8(game_dir_));
    const jol::LauncherSettings settings =
        jol::readLauncherSettings(jol::platform::executable_path());
    std::error_code settings_dir_ec;
    if (!settings.game_dir.empty() &&
        std::filesystem::is_directory(settings.game_dir, settings_dir_ec)) {
        game_dir_ = settings.game_dir;
        jol::log::info("app", "settings game directory: " +
                                  jol::platform::path_to_utf8(game_dir_));
    }
    dark_mode_ = settings.dark_mode;
    follow_system_ = settings.follow_system;
    rail_width_ = std::clamp(settings.rail_width, 200, 360);
    current_version_ = settings.current_version;
    window_state_ = settings.window;
    global_settings_ = jol::readGlobalSettings();
    follow_system_language_ = global_settings_.follow_system_language;
    language_ = follow_system_language_
                    ? system_language()
                    : language_from_code(global_settings_.language);
    client_id_text_ = widen(global_settings_.client_id);
    if (follow_system_) dark_mode_ = systemPrefersDark();
    applyPalette(dark_mode_);
    if (global_settings_.privacy_accepted &&
        global_settings_.privacy_version >= jol::kPrivacyNoticeVersion) {
        if (const auto account = account_store_.load()) {
            account_ = *account;
            has_account_ = true;
            jol::log::info("account", "stored account loaded");
        } else {
            jol::log::info("account", "no stored account");
        }
    } else {
        jol::log::info("account", "privacy notice not accepted yet");
    }
    scan();
}

App::~App() {
    jol::log::info("app", "shutting down");
    login_cancel_ = true;
    launch_cancel_ = true;
    java_cancel_ = true;
    import_cancel_ = true;
    if (login_thread_.joinable()) login_thread_.join();
    if (launch_thread_.joinable()) launch_thread_.join();
    if (manage_import_thread_.joinable()) manage_import_thread_.join();
    if (java_thread_.joinable()) java_thread_.join();
    clear_account_tokens(account_);
    jol::log::shutdown();
}

void App::handle_login_result(LoginResult* result) {
    if (result == nullptr || !accept_payload(result)) return;
    // The worker has already posted this message, so it is about to return.
    // Join it here; leaving the old thread joinable makes the next
    // `login_thread_ = std::thread(...)` call std::terminate.
    if (login_thread_.joinable()) login_thread_.join();
    login_busy_ = false;
    if (login_cancel_ || result->generation != login_generation_) {
        clear_account_tokens(result->account);
        delete result;
        return;
    }
    if (result->ok) {
        clear_account_tokens(account_);
        account_ = result->account;
        has_account_ = true;
        account_expired_ = false;
        login_error_.clear();
        login_dialog_ = false;
        account_store_.save(account_);
        jol::log::info("login", "sign-in succeeded");
    } else {
        jol::log::warn("login", "sign-in failed: " + result->error_key);
        const wchar_t* localized =
            auth_error_text(language_, result->error_key);
        login_error_ =
            localized != nullptr ? narrow(localized) : result->error;
    }
    delete result;
}

void App::handle_login_code(HWND window, jol::auth::DeviceCodeInfo* code) {
    if (code == nullptr || !accept_payload(code)) return;
    if (login_dialog_) {
        login_code_ = code->user_code;
        login_uri_ = code->verification_uri;
        login_notice_.clear();
        login_error_.clear();
        InvalidateRect(window, nullptr, FALSE);
    }
    delete code;
}

void App::handle_launch_result(LaunchResult* result) {
    if (result == nullptr || !accept_payload(result)) return;
    // The worker has already posted this message and is about to return; reap
    // it here, otherwise the next begin_launch() assigns over a joinable
    // std::thread and calls std::terminate.
    if (launch_thread_.joinable()) launch_thread_.join();
    launch_busy_ = false;
    if (result->account_refreshed && has_account_ &&
        account_.uuid == result->account.uuid) {
        account_ = result->account;
        account_store_.save(account_);
    }
    clear_account_tokens(result->account);
    if (result->ok && result->process != nullptr) {
        jol::log::info("launch", "game process started, pid=" +
                                     std::to_string(result->process->pid()));
    } else if (!result->ok) {
        jol::log::warn("launch", "launch failed: " + result->error);
    }
    if (!result->ok) {
        delete result->process;
        result->process = nullptr;
        if (result->java_missing) {
            java_runtimes_ = std::move(result->runtimes);
            java_detecting_ = false;
            launch_error_ = result->error;
            java_prompt_ = true;
            pending_launch_ = true;
        } else {
            account_expired_ = result->auth_expired;
            if (result->auth_expired) {
                launch_error_ =
                    narrow(tr(language_, Text::launchSessionExpired));
            } else {
                const wchar_t* localized =
                    auth_error_text(language_, result->error_key);
                launch_error_ = localized != nullptr
                                    ? narrow(localized)
                                    : result->error;
            }
        }
    } else {
        account_expired_ = false;
        running_.reset(result->process);
        result->process = nullptr;
        running_version_ = current_version_;
        game_log_.clear();
        game_stopped_ = false;
        game_exit_code_ = 0;
        launch_error_.clear();
        SetTimer(result->window, 5, 100, nullptr);
    }
    delete result;
}

void App::handle_manage_import(ManageImportResult* result) {
    if (result == nullptr || !accept_payload(result)) return;
    if (manage_import_thread_.joinable()) manage_import_thread_.join();
    manage_import_busy_ = false;
    if (result->ok) {
        jol::log::info("import", "imported version " + result->name);
        scan();
        current_version_ = result->name;
        rename_text_ = widen(result->name);
        load_version_config();
        save_settings();
        manage_error_.clear();
        manage_notice_ =
            std::wstring(tr(language_, Text::importDone)) + L" " +
            widen(result->name);
    } else {
        manage_notice_.clear();
        manage_error_ = result->error.empty()
                            ? narrow(tr(language_, Text::importFailed))
                            : result->error;
    }
    delete result;
}

void App::begin_manage_import(HWND window,
                              const std::filesystem::path& source, bool zip) {
    if (manage_import_busy_ || source.empty()) return;
    if (manage_import_thread_.joinable()) manage_import_thread_.join();
    manage_import_busy_ = true;
    import_cancel_ = false;
    manage_error_.clear();
    manage_notice_.clear();
    InvalidateRect(window, nullptr, FALSE);

    const std::filesystem::path game_dir = game_dir_;
    const std::string name = narrow(source.filename().wstring());
    manage_import_thread_ =
        std::thread([this, window, game_dir, source, name, zip] {
            if (import_cancel_.load()) return;
            std::string imported;
            std::string error;
            try {
                if (zip) {
                    imported = importVersionZip(game_dir, source);
                } else {
                    importVersionFolder(game_dir, source, name);
                    imported = name;
                }
            } catch (const std::exception& failure) {
                error = failure.what();
            }
            if (import_cancel_.load()) return;
            auto* result =
                new ManageImportResult{error.empty(), imported, error};
            post_event(window, WM_APP + 4, result);
        });
}

void App::refresh_java_status() {
    java_required_ = 0;
    if (!current_version_.empty()) {
        try {
            if (const auto required = jol::launch::required_java_major(
                    game_dir_, current_version_)) {
                java_required_ = *required;
            }
        } catch (const std::exception&) {
        }
    }

    const jol::launch::JavaRuntime* selected = nullptr;
    for (const auto& runtime : java_runtimes_) {
        if (java_required_ == 0 || runtime.major >= java_required_) {
            selected = &runtime;
            break;
        }
    }

    if (java_detecting_) {
        java_auto_status_ = tr(language_, Text::javaDetecting);
    } else if (selected != nullptr) {
        java_auto_status_ = L"Java " + std::to_wstring(selected->major) +
                            L" · " + selected->path.wstring();
    } else if (!java_runtimes_.empty()) {
        java_auto_status_ = std::wstring(tr(language_, Text::javaNeeds)) +
                            L" " + std::to_wstring(java_required_) + L" · " +
                            tr(language_, Text::javaNewest) + L" " +
                            std::to_wstring(java_runtimes_.front().major);
    } else if (java_required_ > 0) {
        java_auto_status_ = std::wstring(tr(language_, Text::javaNeeds)) +
                            L" " + std::to_wstring(java_required_);
    } else {
        java_auto_status_ = tr(language_, Text::javaNotFound);
    }
}

void App::validate_manual_java(bool probe) {
    java_manual_status_.clear();
    java_manual_ok_ = false;
    if (!manual_java_) return;
    const std::wstring text = trim(java_text_);
    if (text.empty()) return;
    const std::filesystem::path path(text);
    std::error_code ec;
    if (!std::filesystem::is_regular_file(path, ec)) {
        java_manual_status_ = tr(language_, Text::javaPathMissing);
        return;
    }
    std::optional<jol::launch::JavaRuntime> info;
    if (probe) {
        info = jol::launch::inspect_java(path);
        if (!info) {
            java_manual_status_ = tr(language_, Text::javaPathInvalid);
            return;
        }
    } else {
        const std::wstring wanted = path.wstring();
        for (const auto& runtime : java_runtimes_) {
            if (_wcsicmp(runtime.path.wstring().c_str(), wanted.c_str()) == 0) {
                info = runtime;
                break;
            }
        }
        if (!info) return;
    }
    if (java_required_ > 0 && info->major < java_required_) {
        java_manual_status_ = std::wstring(tr(language_, Text::javaTooOld)) +
                              L" " + std::to_wstring(info->major) + L" < " +
                              std::to_wstring(java_required_);
        return;
    }
    java_manual_ok_ = true;
    java_manual_status_ = L"Java " + std::to_wstring(info->major);
}

void App::warm_java_cache(HWND window) { begin_java_detection(window); }

void App::begin_java_detection(HWND window, bool force) {
    if (java_detecting_) return;
    if (!force && java_scanned_) return;
    if (java_thread_.joinable()) java_thread_.join();
    java_detecting_ = true;
    java_cancel_ = false;
    refresh_java_status();
    InvalidateRect(window, nullptr, FALSE);
    java_thread_ = std::thread([this, window] {
        auto* result = new JavaDetectResult{};
        try {
            result->runtimes = jol::launch::detect_java_runtimes(&java_cancel_);
        } catch (...) {
            // An unreadable directory must not take the process down; report
            // an empty list and let the UI fall back to the manual path.
        }
        if (java_cancel_.load()) {
            delete result;
            return;
        }
        post_event(window, WM_APP + 5, result);
    });
}

void App::handle_java_detection(JavaDetectResult* result) {
    if (result == nullptr || !accept_payload(result)) return;
    if (java_thread_.joinable()) java_thread_.join();
    java_detecting_ = false;
    java_scanned_ = true;
    java_runtimes_ = std::move(result->runtimes);
    delete result;
    refresh_java_status();
    validate_manual_java(false);
}


bool access_token_usable(const jol::auth::Account& account) {
    if (account.access_token.empty()) return false;
    const auto now = static_cast<std::int64_t>(std::time(nullptr));
    return account.access_expires_at > now + 60;
}

void App::begin_launch(HWND window) {
    if (!global_settings_.privacy_accepted ||
        global_settings_.privacy_version < jol::kPrivacyNoticeVersion) {
        privacy_dialog_ = true;
        InvalidateRect(window, nullptr, FALSE);
        return;
    }
    if (launch_busy_ || !has_account_ || current_version_.empty() ||
        (running_ && running_->running())) {
        return;
    }
    launch_busy_ = true;
    launch_error_.clear();
    jol::log::info("launch", "launching version " + current_version_);

    jol::launch::LaunchRequest request;
    request.game_dir = game_dir_;
    request.version_name = current_version_;
    request.account = account_;
    const std::string client_id_value = client_id();
    request.client_id = client_id_value;
    request.java_path = config_.java_path.empty()
                            ? std::filesystem::path{}
                            : std::filesystem::path(widen(config_.java_path));
    request.min_memory_mb = config_.min_memory_mb;
    request.max_memory_mb = config_.max_memory_mb;
    request.jvm_args = config_.jvm_args;

    launch_cancel_ = false;
    launch_thread_ = std::thread(
        [this, window, request = std::move(request), client_id_value]() mutable {
        jol::launch::LaunchRequest current = request;
        bool account_refreshed = false;
        try {
            if (launch_cancel_.load()) {
                clear_account_tokens(current.account);
                return;
            }
            if (!current.account.refresh_token.empty() &&
                !access_token_usable(current.account)) {
                jol::auth::AuthService auth(client_id_value);
                current.account = auth.refresh(current.account);
                account_refreshed = true;
                // The refreshed account travels back with the launch result
                // and is saved on the UI thread, so a sign-out that happens
                // meanwhile cannot be overwritten.
            }
            if (launch_cancel_.load()) {
                clear_account_tokens(current.account);
                return;
            }
            jol::launch::GameProcess process = jol::launch::start(current);
            auto* owned =
                new jol::launch::GameProcess(std::move(process));
            auto* result = new LaunchResult{true, {}, owned, window, false};
            result->account = current.account;
            result->account_refreshed = account_refreshed;
            post_event(window, WM_APP + 2, result);
        } catch (const jol::launch::JavaError& error) {
            std::vector<jol::launch::JavaRuntime> runtimes;
            try {
                runtimes = jol::launch::detect_java_runtimes();
            } catch (...) {
                runtimes.clear();
            }
            auto* result = new LaunchResult{false,     error.what(), nullptr,
                                            window,    false,        true,
                                            std::move(runtimes)};
            result->account = current.account;
            result->account_refreshed = account_refreshed;
            post_event(window, WM_APP + 2, result);
        } catch (const jol::auth::AuthError& error) {
            const bool expired = error.key() == "auth.error.refreshExpired";
            auto* result = new LaunchResult{false, error.what(), nullptr, window,
                                            expired, false, {}, error.key()};
            result->account = current.account;
            result->account_refreshed = account_refreshed;
            post_event(window, WM_APP + 2, result);
        } catch (const std::exception& error) {
            auto* result = new LaunchResult{false, error.what(), nullptr,
                                            window, false};
            result->account = current.account;
            result->account_refreshed = account_refreshed;
            post_event(window, WM_APP + 2, result);
        }
        clear_account_tokens(current.account);
        clear_account_tokens(request.account);
    });
}

void App::begin_login(HWND window) {
    if (login_busy_ || (has_account_ && !account_expired_)) return;
    const std::string client_id_value = client_id();
    if (client_id_value.empty()) {
        login_dialog_ = true;
        login_error_ =
            narrow(tr(language_, Text::noClientId));
        InvalidateRect(window, nullptr, FALSE);
        return;
    }
    if (!global_settings_.privacy_accepted ||
        global_settings_.privacy_version < jol::kPrivacyNoticeVersion) {
        privacy_dialog_ = true;
        InvalidateRect(window, nullptr, FALSE);
        return;
    }
    login_busy_ = true;
    login_dialog_ = true;
    const std::uint64_t login_generation = ++login_generation_;
    jol::log::info("login", "starting device-code sign-in");
    login_error_.clear();
    login_code_.clear();
    login_uri_.clear();
    login_notice_.clear();
    login_cancel_ = false;
    login_thread_ = std::thread([this, window, client_id_value, login_generation] {
        try {
            jol::auth::AuthService auth(client_id_value);
            const jol::auth::Account account = auth.login(
                [this, window](const jol::auth::DeviceCodeInfo& info) {
                    post_event(window, WM_APP + 3,
                               new jol::auth::DeviceCodeInfo(info));
                },
                login_cancel_);
            auto* result = new LoginResult{true, account, {}};
            result->generation = login_generation;
            post_event(window, WM_APP + 1, result);
        } catch (const jol::auth::AuthError& error) {
            auto* result =
                new LoginResult{false, {}, error.what(), error.key()};
            result->generation = login_generation;
            post_event(window, WM_APP + 1, result);
        } catch (const std::exception& error) {
            auto* result = new LoginResult{false, {}, error.what()};
            result->generation = login_generation;
            post_event(window, WM_APP + 1, result);
        }
    });
}

void App::cancel_login(HWND window) {
    login_cancel_ = true;
    ++login_generation_;
    login_dialog_ = false;
    login_code_.clear();
    login_uri_.clear();
    login_notice_.clear();
    InvalidateRect(window, nullptr, FALSE);
}

void App::start_fade(FadeState& state, int from, int to, HWND window) {
    state.active = true;
    state.progress = 0.0f;
    state.started = GetTickCount64();
    state.from = from;
    state.to = to;
    SetTimer(window, 6, 16, nullptr);
}

void App::animate_transitions(HWND window) {
    auto advance = [](FadeState& state) {
        if (!state.active) return false;
        const float elapsed =
            static_cast<float>(GetTickCount64() - state.started);
        state.progress = std::min(1.0f, elapsed / 160.0f);
        if (state.progress >= 1.0f) state.active = false;
        return true;
    };
    const bool any = advance(page_fade_) | advance(manage_fade_) |
                     advance(settings_fade_);
    if (!any) KillTimer(window, 6);
    InvalidateRect(window, nullptr, FALSE);
}

void App::set_manage_open(HWND window, bool open) {
    scroll_ = 0;
    scroll_max_ = 0;
    if (!open) {
        manage_rename_dialog_ = false;
        focus_field_ = -1;
    }
    if (open) {
        manage_error_.clear();
        manage_notice_.clear();
    }
    if (manage_open_ == open && !manage_fade_.active) return;
    const int from = manage_fade_.active
                         ? (manage_fade_.progress < 0.5f
                                ? manage_fade_.from
                                : manage_fade_.to)
                         : (manage_open_ ? 1 : 0);
    manage_open_ = open;
    start_fade(manage_fade_, from, open ? 1 : 0, window);
    InvalidateRect(window, nullptr, FALSE);
}

void App::set_settings_subpage(HWND window, SettingsSubpage page) {
    if (settings_subpage_ == page && !settings_fade_.active) return;
    const int from = settings_fade_.active
                         ? (settings_fade_.progress < 0.5f
                                ? settings_fade_.from
                                : settings_fade_.to)
                         : static_cast<int>(settings_subpage_);
    settings_subpage_ = page;
    scroll_ = 0;
    scroll_max_ = 0;
    start_fade(settings_fade_, from, static_cast<int>(page), window);
    InvalidateRect(window, nullptr, FALSE);
}

void App::change_page(HWND window, int page_index) {
    const Page next = static_cast<Page>(page_index);
    if (next == page_) return;
    scroll_ = 0;
    scroll_max_ = 0;
    manage_rename_dialog_ = false;
    focus_field_ = -1;
    const int from = static_cast<int>(page_);
    page_ = next;
    start_fade(page_fade_, from, page_index, window);
    manage_fade_.active = false;
    settings_fade_.active = false;
    manage_open_ = false;
    settings_subpage_ = SettingsSubpage::none;
    if (next == Page::versions) begin_java_detection(window);
    InvalidateRect(window, nullptr, FALSE);
}

void App::start_theme_animation(HWND window, bool dark) {
    theme_from_ = currentPalette();
    theme_to_ = paletteFor(dark);
    theme_progress_ = 0.0f;
    theme_started_ = GetTickCount64();
    theme_animating_ = true;
    SetTimer(window, 4, 16, nullptr);
    InvalidateRect(window, nullptr, FALSE);
}

void App::animate_theme(HWND window) {
    if (!theme_animating_) return;
    const ULONGLONG elapsed = GetTickCount64() - theme_started_;
    theme_progress_ =
        std::min(1.0f, static_cast<float>(elapsed) / 220.0f);
    const float eased =
        1.0f - (1.0f - theme_progress_) * (1.0f - theme_progress_);
    applyPaletteBlend(theme_from_, theme_to_, eased);
    apply_window_theme(window);
    if (theme_progress_ >= 1.0f) {
        theme_animating_ = false;
        KillTimer(window, 4);
        apply_window_theme(window);
    }
    InvalidateRect(window, nullptr, FALSE);
}

void App::poll_game(HWND window) {
    if (!running_) {
        KillTimer(window, 5);
        return;
    }
    std::string chunk = running_->take_output();
    if (!chunk.empty()) {
        game_log_ += chunk;
        if (game_log_.size() > 1024 * 1024) {
            game_log_.erase(0, game_log_.size() - 1024 * 1024);
        }
        if (game_log_dialog_) InvalidateRect(window, nullptr, FALSE);
    }
    if (!running_->running()) {
        const int code = running_->wait();
        const std::string tail = running_->take_output_after_exit();
        if (!tail.empty()) {
            game_log_ += tail;
            if (game_log_.size() > 1024 * 1024) {
                game_log_.erase(0, game_log_.size() - 1024 * 1024);
            }
        }
        running_.reset();
        KillTimer(window, 5);
        game_exit_code_ = code;
        if (code != 0 && !game_stopped_) {
            launch_error_ =
                "Game exited with code " + std::to_string(code) + ".";
        }
        jol::log::info("launch", "game exited with code " +
                                     std::to_string(code));
        game_stopped_ = false;
        InvalidateRect(window, nullptr, FALSE);
    }
}

void App::load_version_config() {
    config_ = {};
    config_error_.clear();
    config_saved_ = false;
    focus_field_ = -1;
    java_text_.clear();
    min_memory_text_.clear();
    max_memory_text_.clear();
    jvm_text_.clear();

    for (const auto& version : versions_) {
        if (version.name != current_version_) continue;
        config_ = readVersionConfig(version.dir);
        manual_java_ = !config_.java_path.empty();
        java_text_ = widen(config_.java_path);
        if (config_.min_memory_mb > 0) {
            min_memory_text_ = std::to_wstring(config_.min_memory_mb);
        }
        if (config_.max_memory_mb > 0) {
            max_memory_text_ = std::to_wstring(config_.max_memory_mb);
        }
        jvm_text_ = widen(config_.jvm_args);
        break;
    }
    refresh_java_status();
    validate_manual_java(false);
}

void App::save_version_config() {
    const VersionRow* selected = nullptr;
    for (const auto& version : versions_) {
        if (version.name == current_version_) {
            selected = &version;
            break;
        }
    }
    if (selected == nullptr) {
        config_error_ = narrow(tr(language_, Text::noVersionSelected));
        return;
    }

    if (manual_java_) {
        validate_manual_java(true);
        if (!java_manual_ok_ && !java_manual_status_.empty()) {
            config_error_ = narrow(java_manual_status_);
            config_saved_ = false;
            return;
        }
    }

    auto parse_memory = [](const std::wstring& text, int& value) -> bool {
        const std::wstring trimmed = trim(text);
        if (trimmed.empty()) {
            value = 0;
            return true;
        }
        try {
            size_t used = 0;
            const int parsed = std::stoi(trimmed, &used);
            if (used != trimmed.size() || parsed <= 0) return false;
            value = parsed;
            return true;
        } catch (...) {
            return false;
        }
    };

    VersionConfig next;
    next.java_path = manual_java_ ? narrow(trim(java_text_)) : std::string{};
    next.jvm_args = narrow(trim(jvm_text_));
    if (!parse_memory(min_memory_text_, next.min_memory_mb) ||
        !parse_memory(max_memory_text_, next.max_memory_mb)) {
        config_error_ = narrow(tr(language_, Text::memoryNumber));
        return;
    }
    if (next.min_memory_mb > 0 && next.max_memory_mb > 0 &&
        next.min_memory_mb > next.max_memory_mb) {
        config_error_ = narrow(tr(language_, Text::memoryRange));
        return;
    }

    try {
        writeVersionConfig(selected->dir, next);
        config_ = next;
        config_error_.clear();
        config_saved_ = true;
    } catch (const std::exception& error) {
        config_error_ = error.what();
        config_saved_ = false;
    }
}

void App::key_char(HWND window, wchar_t character) {
    if (focus_field_ < 0 || character < L' ') return;
    if (focus_field_ == 6) {
        client_id_text_.push_back(character);
        InvalidateRect(window, nullptr, FALSE);
        return;
    }
    bool needs_digit = (focus_field_ == 1 || focus_field_ == 2);
    if (needs_digit && !std::iswdigit(character)) return;
    std::wstring* target = nullptr;
    switch (focus_field_) {
        case 0: target = &java_text_; break;
        case 1: target = &min_memory_text_; break;
        case 2: target = &max_memory_text_; break;
        case 3: target = &jvm_text_; break;
        case 4: target = &rename_text_; break;
        case 6: target = &client_id_text_; break;
        default: return;
    }
    target->push_back(character);
    config_saved_ = false;
    config_error_.clear();
    if (focus_field_ == 0) validate_manual_java(false);
    InvalidateRect(window, nullptr, FALSE);
}

void App::key_down(HWND window, int key) {
    if (key == VK_TAB && focus_field_ == 6) {
        focus_field_ = -1;
        InvalidateRect(window, nullptr, FALSE);
        return;
    }
    if (key == VK_TAB) {
        const bool backwards = (GetKeyState(VK_SHIFT) & 0x8000) != 0;
        const int count =
            (page_ == Page::versions && manage_open_) ? 5 : 4;
        focus_field_ = focus_field_ < 0
                           ? 0
                           : (focus_field_ + (backwards ? count - 1 : 1)) %
                                 count;
        InvalidateRect(window, nullptr, FALSE);
        return;
    }
    if (key == VK_ESCAPE) {
        focus_field_ = -1;
        InvalidateRect(window, nullptr, FALSE);
        return;
    }
    if (key == VK_RETURN) {
        if (manage_rename_dialog_ && focus_field_ == 4) {
            commit_manage_rename();
            InvalidateRect(window, nullptr, FALSE);
            return;
        }
        if (focus_field_ == 6) {
            global_settings_.client_id = narrow(trim(client_id_text_));
            client_id_text_ = widen(global_settings_.client_id);
            jol::writeGlobalSettings(global_settings_);
            focus_field_ = -1;
            jol::log::info("settings", "client id updated");
            InvalidateRect(window, nullptr, FALSE);
            return;
        }
        save_version_config();
        InvalidateRect(window, nullptr, FALSE);
        return;
    }
    if (key != VK_BACK || focus_field_ < 0) return;
    std::wstring* target = nullptr;
    switch (focus_field_) {
        case 0: target = &java_text_; break;
        case 1: target = &min_memory_text_; break;
        case 2: target = &max_memory_text_; break;
        case 3: target = &jvm_text_; break;
        case 4: target = &rename_text_; break;
        default: return;
    }
    if (!target->empty()) target->pop_back();
    config_saved_ = false;
    config_error_.clear();
    if (focus_field_ == 0) validate_manual_java(false);
    InvalidateRect(window, nullptr, FALSE);
}

void App::paint_input(int x, int y, int width, int height,
                      const std::wstring& text, bool focused, int dpi) {
    const D2D1_RECT_F area = rect(x, y, x + width, y + height);
    fill_rect(area, kBg);
    if (brush_ != nullptr) {
        brush_->SetColor(color(focused ? kAccent : kBorder));
        target_->DrawRectangle(area, brush_.Get(), 1.0f);
    }
    draw_text(text, rect(x + s(10, dpi), y, x + width - s(8, dpi),
                         y + height),
              s(12, dpi), kText, DWRITE_FONT_WEIGHT_NORMAL,
              DWRITE_TEXT_ALIGNMENT_LEADING);
}

App::UiField App::make_field(std::wstring label, std::wstring hint,
                                 int height, int control_width, bool full_width,
                                 int action,
                                 std::function<void(const RECT&)> paint) {
    UiField value;
    value.label = std::move(label);
    value.hint = std::move(hint);
    value.height = height;
    value.control_width = control_width;
    value.full_width = full_width;
    value.action = action;
    value.paint = std::move(paint);
    return value;
}

void App::paint_sections(int left, int right, int& y, int dpi,
                         const std::vector<UiSection>& sections) {
    for (size_t section_index = 0; section_index < sections.size();
         ++section_index) {
        const UiSection& section = sections[section_index];
        std::vector<int> heights;
        heights.reserve(section.fields.size());
        for (const UiField& field : section.fields) {
            heights.push_back(field.height);
        }
        const ui::SectionLayout layout =
            ui::section(left, right, y, dpi, heights);
        draw_text(section.title,
                  rect(layout.title.left, layout.title.top,
                       layout.title.right, layout.title.bottom),
                  s(12, dpi), kSecondary, DWRITE_FONT_WEIGHT_NORMAL,
                  DWRITE_TEXT_ALIGNMENT_LEADING);
        draw_panel(rect(layout.card.left, layout.card.top,
                        layout.card.right, layout.card.bottom));
        for (size_t i = 0; i < section.fields.size(); ++i) {
            const UiField& field = section.fields[i];
            const ui::FieldLayout& row = layout.fields[i];
            if (i + 1 < section.fields.size()) {
                fill_rect(rect(row.row.left, row.row.bottom, row.row.right,
                               row.row.bottom + 1),
                          kBorder);
            }
            // Label + optional hint line form one block, centred vertically in
            // the row so 42/45/60 px rows all look aligned.
            const RECT band = label_band(row.row, dpi, !field.hint.empty());
            const int label_bottom = band.top + s(24, dpi);
            if (!field.label.empty()) {
                draw_text(field.label,
                          rect(row.row.left + s(16, dpi), band.top,
                               row.row.right - s(16, dpi), label_bottom),
                          s(14, dpi), kText, DWRITE_FONT_WEIGHT_NORMAL,
                          DWRITE_TEXT_ALIGNMENT_LEADING);
            }
            if (!field.hint.empty()) {
                draw_text(field.hint,
                          rect(row.row.left + s(16, dpi), label_bottom,
                               row.row.right - s(16, dpi), band.bottom),
                          s(12, dpi), kSecondary, DWRITE_FONT_WEIGHT_NORMAL,
                          DWRITE_TEXT_ALIGNMENT_LEADING);
            }
            RECT control{};
            if (field.full_width) {
                control = RECT{row.row.left + s(16, dpi),
                               row.row.top +
                                   (s(field.height, dpi) -
                                    s(field.control_height, dpi)) /
                                       2,
                               row.row.right - s(16, dpi),
                               row.row.top +
                                   (s(field.height, dpi) +
                                    s(field.control_height, dpi)) /
                                       2};
            } else if (field.control_width > 0) {
                control = RECT{
                    row.row.right - s(16, dpi) - s(field.control_width, dpi),
                    row.row.top +
                        (s(field.height, dpi) -
                         s(field.control_height, dpi)) /
                            2,
                    row.row.right - s(16, dpi),
                    row.row.top +
                        (s(field.height, dpi) +
                         s(field.control_height, dpi)) /
                            2};
            } else {
                control = row.row;
            }
            if (field.paint) field.paint(control);
            if (field.action >= 0) {
                ui_hits_.push_back(UiHit{control, field.action});
            }
        }
        y = layout.card.bottom +
            (section_index + 1 < sections.size() ? s(24, dpi) : 0);
    }
}

void App::save_settings() {
    jol::LauncherSettings settings;
    settings.game_dir = game_dir_;
    settings.dark_mode = dark_mode_;
    settings.follow_system = follow_system_;
    settings.rail_width = rail_width_;
    settings.current_version = current_version_;
    settings.window = window_state_;
    jol::writeLauncherSettings(settings, jol::platform::executable_path());
}

void App::apply_window_theme(HWND window) {
    const BOOL dark = dark_mode_ ? TRUE : FALSE;
    DwmSetWindowAttribute(window, 20, &dark, sizeof(dark));
    const COLORREF caption = kBg;
    const COLORREF border = kBorder;
    const COLORREF text = kText;
    DwmSetWindowAttribute(window, 35, &caption, sizeof(caption));
    DwmSetWindowAttribute(window, 34, &border, sizeof(border));
    DwmSetWindowAttribute(window, 36, &text, sizeof(text));
}

void App::scan() {
    VersionScanResult result;
    try {
        result = jol::scanVersions(game_dir_);
    } catch (const std::exception& error) {
        jol::log::error("scan", std::string("scan failed: ") + error.what());
        return;
    } catch (...) {
        jol::log::error("scan", "scan failed with an unknown error");
        return;
    }
    jol::log::info("scan", "found " + std::to_string(result.versions.size()) +
                               " version(s), " +
                               std::to_string(result.broken.size()) +
                               " broken");
    versions_.clear();
    broken_versions_ = result.broken;
    versions_.reserve(result.versions.size());
    for (const auto& version : result.versions) {
        versions_.push_back(VersionRow{version.directory, version.name,
                                       version.game_version, version.loader,
                                       version.loader_version});
    }
    bool found_current = false;
    for (const auto& version : versions_) {
        if (version.name == current_version_) found_current = true;
    }
    if (!found_current) {
        current_version_ = versions_.empty() ? "" : versions_.front().name;
    }
    load_version_config();
}

bool App::ensure_target(HWND window) {
    if (target_ != nullptr) return true;
    if (d2d_ == nullptr || dwrite_ == nullptr) return false;

    RECT client{};
    GetClientRect(window, &client);
    const D2D1_SIZE_U size = D2D1::SizeU(
        static_cast<UINT32>(std::max(1L, client.right)),
        static_cast<UINT32>(std::max(1L, client.bottom)));

    D2D1_RENDER_TARGET_PROPERTIES properties = D2D1::RenderTargetProperties();
    properties.dpiX = 96.0f;
    properties.dpiY = 96.0f;

    const D2D1_HWND_RENDER_TARGET_PROPERTIES hwnd_properties =
        D2D1::HwndRenderTargetProperties(window, size,
                                         D2D1_PRESENT_OPTIONS_NONE);
    if (FAILED(d2d_->CreateHwndRenderTarget(
            properties, hwnd_properties, target_.ReleaseAndGetAddressOf()))) {
        return false;
    }

    target_->SetAntialiasMode(D2D1_ANTIALIAS_MODE_PER_PRIMITIVE);
    if (FAILED(target_->CreateSolidColorBrush(
            color(kText), brush_.ReleaseAndGetAddressOf()))) {
        release_target();
        return false;
    }
    load_icon_font();
    load_text_font();
    if (FAILED(target_->CreateLayer(nullptr, layer_.ReleaseAndGetAddressOf()))) {
        layer_.Reset();
    }
    return true;
}

void App::release_target() {
    layer_.Reset();
    brush_.Reset();
    target_.Reset();
}

void App::load_icon_font() {
    if (dwrite_ == nullptr) return;

    Microsoft::WRL::ComPtr<IDWriteFactory5> factory5;
    if (FAILED(dwrite_.As(&factory5))) return;

    const HRSRC resource = FindResourceW(GetModuleHandleW(nullptr),
                                         MAKEINTRESOURCEW(IDR_FONT_REMIX),
                                         RT_RCDATA);
    if (resource == nullptr) return;
    const HGLOBAL loaded = LoadResource(GetModuleHandleW(nullptr), resource);
    if (loaded == nullptr) return;
    const DWORD size = SizeofResource(GetModuleHandleW(nullptr), resource);
    auto* bytes = static_cast<BYTE*>(LockResource(loaded));
    if (bytes == nullptr || size == 0) return;

    Microsoft::WRL::ComPtr<IDWriteInMemoryFontFileLoader> loader;
    if (FAILED(factory5->CreateInMemoryFontFileLoader(loader.GetAddressOf()))) {
        return;
    }
    if (FAILED(dwrite_->RegisterFontFileLoader(loader.Get()))) return;

    Microsoft::WRL::ComPtr<IDWriteFontFile> font_file;
    if (FAILED(loader->CreateInMemoryFontFileReference(
            dwrite_.Get(), bytes, size, nullptr, font_file.GetAddressOf()))) {
        return;
    }

    Microsoft::WRL::ComPtr<IDWriteFontSetBuilder> builder;
    if (FAILED(factory5->CreateFontSetBuilder(builder.GetAddressOf()))) return;
    Microsoft::WRL::ComPtr<IDWriteFontSetBuilder1> builder1;
    if (FAILED(builder.As(&builder1))) return;
    if (FAILED(builder1->AddFontFile(font_file.Get()))) return;

    Microsoft::WRL::ComPtr<IDWriteFontSet> font_set;
    if (FAILED(builder->CreateFontSet(font_set.GetAddressOf()))) return;

    Microsoft::WRL::ComPtr<IDWriteFontCollection1> collection;
    if (FAILED(factory5->CreateFontCollectionFromFontSet(
            font_set.Get(), collection.GetAddressOf()))) {
        return;
    }

    icon_font_collection_ = collection;
    icon_font_loader_ = loader;
}

void App::load_text_font() {
    if (dwrite_ == nullptr || text_font_collection_ != nullptr) return;

    Microsoft::WRL::ComPtr<IDWriteFactory5> factory5;
    if (FAILED(dwrite_.As(&factory5))) return;

    const HRSRC resource = FindResourceW(GetModuleHandleW(nullptr),
                                         MAKEINTRESOURCEW(IDR_FONT_NOTO),
                                         RT_RCDATA);
    if (resource == nullptr) return;
    const HGLOBAL loaded = LoadResource(GetModuleHandleW(nullptr), resource);
    if (loaded == nullptr) return;
    const DWORD size = SizeofResource(GetModuleHandleW(nullptr), resource);
    auto* bytes = static_cast<BYTE*>(LockResource(loaded));
    if (bytes == nullptr || size == 0) return;

    Microsoft::WRL::ComPtr<IDWriteInMemoryFontFileLoader> loader;
    if (FAILED(factory5->CreateInMemoryFontFileLoader(loader.GetAddressOf()))) {
        return;
    }
    if (FAILED(dwrite_->RegisterFontFileLoader(loader.Get()))) return;

    Microsoft::WRL::ComPtr<IDWriteFontFile> font_file;
    if (FAILED(loader->CreateInMemoryFontFileReference(
            dwrite_.Get(), bytes, size, nullptr, font_file.GetAddressOf()))) {
        return;
    }

    Microsoft::WRL::ComPtr<IDWriteFontSetBuilder> builder;
    if (FAILED(factory5->CreateFontSetBuilder(builder.GetAddressOf()))) return;
    Microsoft::WRL::ComPtr<IDWriteFontSetBuilder1> builder1;
    if (FAILED(builder.As(&builder1))) return;
    if (FAILED(builder1->AddFontFile(font_file.Get()))) return;

    Microsoft::WRL::ComPtr<IDWriteFontSet> font_set;
    if (FAILED(builder->CreateFontSet(font_set.GetAddressOf()))) return;

    Microsoft::WRL::ComPtr<IDWriteFontCollection1> collection;
    if (FAILED(factory5->CreateFontCollectionFromFontSet(
            font_set.Get(), collection.GetAddressOf()))) {
        return;
    }

    text_font_collection_ = collection;
    text_font_loader_ = loader;

    // Noto Sans SC covers Latin, CJK and kana but no Hangul at all, so Korean
    // text needs an explicit fallback. The chain stays on system fonts that
    // ship with every Windows 10/11 release.
    Microsoft::WRL::ComPtr<IDWriteFactory2> factory2;
    if (FAILED(dwrite_.As(&factory2))) return;
    if (FAILED(dwrite_->GetSystemFontCollection(
            system_font_collection_.GetAddressOf(), FALSE))) {
        return;
    }
    Microsoft::WRL::ComPtr<IDWriteFontFallbackBuilder> fallback_builder;
    if (FAILED(factory2->CreateFontFallbackBuilder(
            fallback_builder.GetAddressOf()))) {
        return;
    }
    static const DWRITE_UNICODE_RANGE hangul_ranges[] = {
        {0x1100, 0x11FF},  // Hangul Jamo
        {0x3130, 0x318F},  // Hangul Compatibility Jamo
        {0xA960, 0xA97F},  // Hangul Jamo Extended-A
        {0xAC00, 0xD7AF},  // Hangul Syllables
        {0xD7B0, 0xD7FF},  // Hangul Jamo Extended-B
    };
    const wchar_t* korean_families[] = {
        L"Malgun Gothic", L"Gulim", L"Dotum", L"Batang", L"Noto Sans KR",
    };
    if (FAILED(fallback_builder->AddMapping(
            hangul_ranges, 5, korean_families, 5,
            system_font_collection_.Get(), nullptr))) {
        return;
    }
    static const DWRITE_UNICODE_RANGE kana_ranges[] = {
        {0x3041, 0x30FF},  // Hiragana and Katakana
        {0x31F0, 0x31FF},  // Katakana Phonetic Extensions
        {0xFF66, 0xFF9F},  // Halfwidth Katakana
    };
    const wchar_t* japanese_families[] = {
        L"Yu Gothic UI", L"Yu Gothic", L"Meiryo", L"MS Gothic",
    };
    if (FAILED(fallback_builder->AddMapping(
            kana_ranges, 3, japanese_families, 4,
            system_font_collection_.Get(), nullptr))) {
        return;
    }
    fallback_builder->CreateFontFallback(text_font_fallback_.GetAddressOf());
}

void App::draw_icon(int glyph, const D2D1_RECT_F& area, int size,
                    COLORREF c) {
    if (icon_font_collection_ == nullptr || dwrite_ == nullptr ||
        target_ == nullptr || brush_ == nullptr) {
        return;
    }

    auto it = icon_formats_.find(size);
    if (it == icon_formats_.end()) {
        Microsoft::WRL::ComPtr<IDWriteTextFormat> format;
        if (FAILED(dwrite_->CreateTextFormat(
                L"remixicon", icon_font_collection_.Get(),
                DWRITE_FONT_WEIGHT_NORMAL, DWRITE_FONT_STYLE_NORMAL,
                DWRITE_FONT_STRETCH_NORMAL, static_cast<float>(size),
                L"en-us", format.GetAddressOf()))) {
            return;
        }
        format->SetTextAlignment(DWRITE_TEXT_ALIGNMENT_CENTER);
        format->SetParagraphAlignment(DWRITE_PARAGRAPH_ALIGNMENT_CENTER);
        format->SetWordWrapping(DWRITE_WORD_WRAPPING_NO_WRAP);
        it = icon_formats_.emplace(size, format).first;
    }

    brush_->SetColor(color(c));
    const std::wstring text(1, static_cast<wchar_t>(glyph));
    target_->DrawTextW(text.c_str(), 1, it->second.Get(), area, brush_.Get(),
                       D2D1_DRAW_TEXT_OPTIONS_CLIP);
}

void App::fill_rect(const D2D1_RECT_F& area, COLORREF c) {
    if (brush_ == nullptr) return;
    brush_->SetColor(color(c));
    target_->FillRectangle(area, brush_.Get());
}

void App::draw_panel(const D2D1_RECT_F& area) {
    fill_rect(area, kSurface);
    if (brush_ == nullptr) return;
    brush_->SetColor(color(kBorder));
    target_->DrawRectangle(area, brush_.Get(), 1.0f);
}

App::DialogFrame App::dialog_rect(const RECT& client, int dpi, int width,
                                  int height) {
    DialogFrame frame;
    const int w = s(width, dpi);
    const int h = s(height, dpi);
    frame.left = (static_cast<int>(client.right) - w) / 2;
    frame.top = (static_cast<int>(client.bottom) - h) / 2;
    frame.right = frame.left + w;
    frame.bottom = frame.top + h;
    return frame;
}

App::DialogFrame App::begin_dialog(const RECT& client, int dpi, int width,
                                   int height) {
    if (brush_ != nullptr) {
        brush_->SetColor(D2D1::ColorF(0.0f, 0.0f, 0.0f, 0.62f));
        target_->FillRectangle(
            rect(0, 0, static_cast<int>(client.right),
                 static_cast<int>(client.bottom)),
            brush_.Get());
    }
    const DialogFrame frame = dialog_rect(client, dpi, width, height);
    draw_panel(rect(frame.left, frame.top, frame.right, frame.bottom));
    return frame;
}

void App::draw_text(const std::wstring& text, const D2D1_RECT_F& area,
                    int size, COLORREF c, DWRITE_FONT_WEIGHT weight,
                    DWRITE_TEXT_ALIGNMENT alignment, bool wrap) {
    if (dwrite_ == nullptr || brush_ == nullptr || target_ == nullptr) return;

    const auto key =
        std::make_tuple(size, static_cast<int>(weight), wrap);
    auto it = text_formats_.find(key);
    if (it == text_formats_.end()) {
        Microsoft::WRL::ComPtr<IDWriteTextFormat> format;
        const wchar_t* family = text_font_collection_ != nullptr
                                   ? L"Noto Sans SC"
                                   : L"Segoe UI";
        if (FAILED(dwrite_->CreateTextFormat(
                family, text_font_collection_.Get(), weight,
                DWRITE_FONT_STYLE_NORMAL, DWRITE_FONT_STRETCH_NORMAL,
                static_cast<float>(size), L"en-us", format.GetAddressOf()))) {
            return;
        }
        if (text_font_fallback_ != nullptr) {
            Microsoft::WRL::ComPtr<IDWriteTextFormat1> format1;
            if (SUCCEEDED(format.As(&format1))) {
                format1->SetFontFallback(text_font_fallback_.Get());
            }
        }
        // Clip long single-line values with an ellipsis instead of cutting
        // mid glyph. Wrapped blocks are left alone so the last line can run
        // to the edge.
        if (!wrap) {
            Microsoft::WRL::ComPtr<IDWriteInlineObject> ellipsis;
            if (SUCCEEDED(dwrite_->CreateEllipsisTrimmingSign(
                    format.Get(), ellipsis.GetAddressOf()))) {
                static const DWRITE_TRIMMING trimming{
                    DWRITE_TRIMMING_GRANULARITY_CHARACTER, 0, 0};
                format->SetTrimming(&trimming, ellipsis.Get());
            }
        }
        it = text_formats_.emplace(key, format).first;
    }

    IDWriteTextFormat* format = it->second.Get();
    format->SetTextAlignment(alignment);
    format->SetParagraphAlignment(DWRITE_PARAGRAPH_ALIGNMENT_CENTER);
    format->SetWordWrapping(wrap ? DWRITE_WORD_WRAPPING_WRAP
                                 : DWRITE_WORD_WRAPPING_NO_WRAP);

    brush_->SetColor(color(c));
    target_->DrawTextW(text.c_str(), static_cast<UINT32>(text.size()),
                       format, area, brush_.Get(),
                       D2D1_DRAW_TEXT_OPTIONS_CLIP);
}

void App::paint_nav(int index, const wchar_t* label, int x, int y, int width,
                    int height, bool selected, bool hovered, int dpi) {
    const RECT row{x, y, x + width, y + height};
    if (selected) {
        fill_rect(rect(row.left, row.top, row.right, row.bottom), kSurface);
        fill_rect(rect(row.left, row.top, row.left + s(2, dpi), row.bottom),
                  kAccent);
    } else if (hovered) {
        fill_rect(rect(row.left, row.top, row.right, row.bottom), kHover);
    }

    int icon = ICON_SETTINGS;
    if (index == static_cast<int>(Page::launch)) {
        icon = ICON_ROCKET;
    } else if (index == static_cast<int>(Page::versions)) {
        icon = ICON_ARCHIVE;
    }
    const int icon_size = s(16, dpi);
    draw_icon(icon,
              rect(x + s(12, dpi), y + (height - icon_size) / 2,
                   x + s(12, dpi) + icon_size,
                   y + (height + icon_size) / 2),
              icon_size, selected ? kAccent : kSecondary);
    draw_text(label,
              rect(x + s(40, dpi), y, x + width - s(12, dpi), y + height),
              s(14, dpi), selected ? kAccent : (hovered ? kText : kSecondary),
              DWRITE_FONT_WEIGHT_NORMAL, DWRITE_TEXT_ALIGNMENT_LEADING);
}

void App::paint_button(int x, int y, int width, int height,
                       const wchar_t* label, bool primary, bool enabled,
                       bool hovered, int dpi) {
    const D2D1_RECT_F area = rect(x, y, x + width, y + height);
    if (hovered && enabled) fill_rect(area, kHover);
    if (brush_ != nullptr) {
        brush_->SetColor(color(hovered && enabled ? kAccent : kBorder));
        target_->DrawRectangle(area, brush_.Get(), 1.0f);
    }
    const COLORREF c = !enabled ? kSecondary : (primary ? kAccent : kSecondary);
    draw_text(label, area, s(12, dpi), c, DWRITE_FONT_WEIGHT_NORMAL,
              DWRITE_TEXT_ALIGNMENT_CENTER);
}

std::vector<App::NavEntry> App::nav_entries(int dpi) const {
    std::vector<NavEntry> entries;
    const int rail_width = s(rail_width_, dpi);
    const int start_y = s(12, dpi);
    const int row_height = s(37, dpi);
    int y = start_y;

    auto add_page = [&entries, &y, dpi, rail_width, row_height](int page) {
        entries.push_back(NavEntry{
            page, -1,
            RECT{s(8, dpi), y, s(8, dpi) + rail_width - s(16, dpi),
                 y + row_height}});
        y += row_height;
    };

    add_page(static_cast<int>(Page::launch));  // Launch
    add_page(static_cast<int>(Page::versions));  // Version settings
    add_page(static_cast<int>(Page::settings));  // Settings
    return entries;
}


void App::paint_rail(const RECT& client, int dpi) {
    const int rail_width = s(rail_width_, dpi);
    fill_rect(rect(0, 0, rail_width, client.bottom), kBg);

    for (const NavEntry& entry : nav_entries(dpi)) {
        const wchar_t* label = entry.page == 0   ? tr(language_, Text::navLaunch)
                               : entry.page == 1 ? tr(language_, Text::navVersions)
                                                 : tr(language_, Text::navSettings);
        paint_nav(entry.page, label, entry.rect.left, entry.rect.top,
                  entry.rect.right - entry.rect.left,
                  entry.rect.bottom - entry.rect.top,
                  static_cast<int>(page_) == entry.page,
                  hover_nav_ == entry.page, dpi);
    }

    const int account_y = client.bottom - s(58, dpi);
    if (!has_account_ && hover_account_) {
        fill_rect(rect(0, account_y, rail_width - 1, client.bottom), kHover);
    }
    fill_rect(rect(0, account_y, rail_width - 1, account_y + 1), kBorder);
    const D2D1_RECT_F avatar = rect(s(16, dpi), account_y + s(12, dpi),
                                    s(46, dpi), account_y + s(42, dpi));
    if (brush_ != nullptr) {
        brush_->SetColor(color(kBorder));
        target_->DrawRectangle(avatar, brush_.Get(), 1.0f);
    }
    const int icon_size = s(16, dpi);
    draw_icon(ICON_USER,
              rect(static_cast<int>(avatar.left) + s(7, dpi),
                   static_cast<int>(avatar.top) + s(7, dpi),
                   static_cast<int>(avatar.left) + s(7, dpi) + icon_size,
                   static_cast<int>(avatar.top) + s(7, dpi) + icon_size),
              icon_size, kSecondary);
    const std::wstring account_text = has_account_
        ? std::wstring(tr(language_, Text::signedInAs)) + widen(account_.name)
        : (login_busy_ ? tr(language_, Text::launchWaiting)
                       : tr(language_, Text::microsoftSignIn));
    draw_text(account_text,
              rect(s(58, dpi), account_y + s(12, dpi),
                   rail_width - s(16, dpi), account_y + s(42, dpi)),
              s(13, dpi), kSecondary, DWRITE_FONT_WEIGHT_NORMAL,
              DWRITE_TEXT_ALIGNMENT_LEADING);
}

void App::paint_splitter(const RECT& client, int dpi) {
    const int start = s(rail_width_, dpi);
    const int width = s(10, dpi);
    const bool lit = hover_splitter_ || dragging_splitter_;
    const int line_width = lit ? s(2, dpi) : s(1, dpi);
    const int center = start + width / 2;
    fill_rect(rect(center - line_width / 2, 0,
                   center + (line_width + 1) / 2, client.bottom),
              lit ? kAccent : kBorder);
}

void App::begin_scroll(const RECT& client, int dpi) {
    if (target_ == nullptr) return;
    target_->GetTransform(&scroll_saved_transform_);
    target_->PushAxisAlignedClip(
        rect(0, s(112, dpi), static_cast<int>(client.right),
             client.bottom - s(32, dpi) + s(34, dpi)),
        D2D1_ANTIALIAS_MODE_PER_PRIMITIVE);
    target_->SetTransform(D2D1::Matrix3x2F::Translation(
        0.0f, static_cast<float>(-s(34, dpi) - scroll_)));
}

void App::end_scroll() {
    if (target_ == nullptr) return;
    target_->SetTransform(scroll_saved_transform_);
    target_->PopAxisAlignedClip();
}

void App::set_scroll_extent(int content_bottom, const RECT& client,
                            int dpi) {
    const int max_scroll = std::max(
        0, content_bottom - s(34, dpi) -
               (static_cast<int>(client.bottom) - s(32, dpi)));
    scroll_max_ = max_scroll;
    scroll_ = std::clamp(scroll_, 0, scroll_max_);
}

void App::wheel(HWND window, int delta) {
    if (scroll_max_ <= 0) return;
    RECT client{};
    GetClientRect(window, &client);
    const int dpi = static_cast<int>(GetDpiForWindow(window));
    const int step = s(48, dpi) * (delta / WHEEL_DELTA);
    scroll_ = std::clamp(scroll_ - step, 0, scroll_max_);
    InvalidateRect(window, nullptr, FALSE);
}

void App::paint_scrollbar(const RECT& client, int dpi) {
    if (scroll_max_ <= 0) return;
    const int top = s(112, dpi) - s(34, dpi);
    const int bottom =
        static_cast<int>(client.bottom) - s(32, dpi);
    if (bottom <= top) return;
    const int track = bottom - top;
    const int total = track + scroll_max_;
    const int thumb_height =
        std::max(s(24, dpi), track * track / std::max(1, total));
    const int available = track - thumb_height;
    const int thumb_top =
        top + available * scroll_ / std::max(1, scroll_max_);
    fill_rect(rect(static_cast<int>(client.right) - s(14, dpi), thumb_top,
                   static_cast<int>(client.right) - s(4, dpi),
                   thumb_top + thumb_height),
              kSecondary);
}

// The Launch page is deliberately hand-laid-out: its card, version list and
// buttons are geometry-coded in paint_launch / click / mouseMove instead of
// going through ui_hits_. That is a known, temporary exception until the page
// is redesigned; do not "fix" it into the ui_hits_ pattern before then.
// Reason: its layout changes with state (version list open/closed, running
// card, java prompt) far more than the settings-style pages.
void App::paint_launch(const RECT& client, int dpi) {
    const int content_left = contentLeft(rail_width_, dpi);
    const int content_width = std::min(
        s(760, dpi),
        static_cast<int>(client.right) - content_left - s(32, dpi));
    const int content_right = content_left + content_width;

    draw_text(tr(language_, Text::launchTitle),
              rect(content_left, s(58, dpi), content_right, s(88, dpi)),
              s(20, dpi), kText, DWRITE_FONT_WEIGHT_BOLD,
              DWRITE_TEXT_ALIGNMENT_LEADING);
    draw_text(tr(language_, Text::launchSubtitle),
              rect(content_left, s(90, dpi), content_right, s(112, dpi)),
              s(12, dpi), kSecondary, DWRITE_FONT_WEIGHT_NORMAL,
              DWRITE_TEXT_ALIGNMENT_LEADING);
    const int refresh_size = s(16, dpi);
    draw_icon(ICON_REFRESH,
              rect(static_cast<int>(client.right) - s(48, dpi),
                   s(88, dpi),
                   static_cast<int>(client.right) - s(32, dpi),
                   s(88, dpi) + refresh_size),
              refresh_size, kSecondary);

    begin_scroll(client, dpi);
    const ui::CardLayout current_card =
        ui::card(content_left, content_right, s(120, dpi), s(172, dpi), dpi,
                 24);
    draw_panel(rect(current_card.card.left, current_card.card.top,
                    current_card.card.right, current_card.card.bottom));

    const std::wstring current = widen(current_version_);
    std::wstring meta;
    for (const auto& version : versions_) {
        if (version.name == current_version_) {
            meta = widen(version.game_version + " \u00B7 " +
                         displayLoader(version.loader));
            break;
        }
    }
    draw_text(current.empty() ? tr(language_, Text::launchNoVersion) : current,
              rect(current_card.content.left, current_card.content.top,
                   current_card.content.right - s(86, dpi),
                   current_card.content.top + s(24, dpi)),
              s(18, dpi), kText, DWRITE_FONT_WEIGHT_BOLD,
              DWRITE_TEXT_ALIGNMENT_LEADING);
    draw_text(meta,
              rect(current_card.content.left,
                   current_card.content.top + s(26, dpi),
                   current_card.content.right - s(86, dpi),
                   current_card.content.top + s(44, dpi)),
              s(12, dpi), kSecondary, DWRITE_FONT_WEIGHT_NORMAL,
              DWRITE_TEXT_ALIGNMENT_LEADING);

    paint_button(content_right - s(96, dpi), s(144, dpi), s(72, dpi),
                 s(34, dpi),
                 show_versions_ ? tr(language_, Text::launchCollapse)
                                : tr(language_, Text::launchSwitch),
                 false, true, hover_action_ == 0, dpi);
    paint_button(content_right - s(128, dpi), s(208, dpi), s(104, dpi),
                 s(34, dpi),
                 launch_busy_ ? tr(language_, Text::launchStarting)
                              : tr(language_, Text::launchButton),
                 true,
                 has_account_ && !current_version_.empty() && !launch_busy_ &&
                     !account_expired_ && !(running_ && running_->running()),
                 false, dpi);
    if (!launch_error_.empty()) {
        draw_text(widen(launch_error_),
                  rect(content_left + s(24, dpi), s(250, dpi),
                       content_right - s(24, dpi), s(268, dpi)),
                  s(12, dpi), kSecondary, DWRITE_FONT_WEIGHT_NORMAL,
                  DWRITE_TEXT_ALIGNMENT_LEADING);
    } else if (!has_account_) {
        draw_text(login_busy_ ? tr(language_, Text::launchWaiting)
                              : tr(language_, Text::launchSignIn),
                  rect(content_left + s(24, dpi), s(250, dpi),
                       content_right - s(24, dpi), s(268, dpi)),
                  s(12, dpi), kSecondary, DWRITE_FONT_WEIGHT_NORMAL,
                  DWRITE_TEXT_ALIGNMENT_LEADING);
    } else if (account_expired_) {
        draw_text(tr(language_, Text::launchSessionExpired),
                  rect(content_left + s(24, dpi), s(250, dpi),
                       content_right - s(24, dpi), s(268, dpi)),
                  s(12, dpi), kSecondary, DWRITE_FONT_WEIGHT_NORMAL,
                  DWRITE_TEXT_ALIGNMENT_LEADING);
    }

    int next_y = s(316, dpi);
    if (show_versions_) {
        const int row_height = s(54, dpi);
        const int list_top = s(300, dpi);
        const int list_bottom =
            list_top + static_cast<int>(versions_.size()) * row_height;
        draw_panel(rect(content_left, list_top, content_right, list_bottom));
        for (size_t i = 0; i < versions_.size(); ++i) {
            const int row_top = list_top + static_cast<int>(i) * row_height;
            const RECT row{content_left, row_top, content_right,
                           row_top + row_height};
            const bool selected = versions_[i].name == current_version_;
            if (i > 0) {
                fill_rect(rect(row.left, row.top, row.right, row.top + 1),
                          kBorder);
            }
            if (selected) {
                fill_rect(rect(row.left, row.top, row.right, row.bottom), kBg);
                fill_rect(rect(row.left, row.top, row.left + s(2, dpi),
                               row.bottom),
                          kAccent);
            } else if (hover_version_ == static_cast<int>(i)) {
                fill_rect(rect(row.left, row.top, row.right, row.bottom),
                          kHover);
            }
            draw_icon(ICON_ARCHIVE,
                      rect(row.left + s(16, dpi), row.top + s(11, dpi),
                           row.left + s(32, dpi), row.top + s(27, dpi)),
                      s(16, dpi), selected ? kAccent : kSecondary);
            draw_text(widen(versions_[i].name),
                      rect(row.left + s(44, dpi), row.top + s(8, dpi),
                           row.right - s(16, dpi), row.top + s(28, dpi)),
                      s(14, dpi), selected ? kAccent : kText,
                      DWRITE_FONT_WEIGHT_NORMAL,
                      DWRITE_TEXT_ALIGNMENT_LEADING);
            draw_text(widen(versions_[i].game_version + " · " +
                            displayLoader(versions_[i].loader)),
                      rect(row.left + s(44, dpi), row.top + s(28, dpi),
                           row.right - s(16, dpi), row.top + s(46, dpi)),
                      s(11, dpi), kSecondary, DWRITE_FONT_WEIGHT_NORMAL,
                      DWRITE_TEXT_ALIGNMENT_LEADING);
        }
        next_y = list_bottom + s(24, dpi);
    }

    UiSection running_section;
    running_section.title = tr(language_, Text::launchRunning);
    UiField running_field;
    running_field.height = 52;
    running_field.full_width = true;
    running_field.paint = [this, dpi, content_left, content_right](
                              const RECT& area) {
        if (running_ && running_->running()) {
            const std::wstring label =
                widen(running_version_) + L"  \u00B7  PID " +
                std::to_wstring(running_->pid());
            draw_text(label,
                      rect(area.left, area.top, area.right - s(150, dpi),
                           area.bottom),
                      s(13, dpi), kText, DWRITE_FONT_WEIGHT_NORMAL,
                      DWRITE_TEXT_ALIGNMENT_LEADING);
            paint_button(area.right - s(140, dpi), area.top, s(62, dpi),
                         area.bottom - area.top,
                         tr(language_, Text::launchLog), false, true, false,
                         dpi);
            paint_button(area.right - s(70, dpi), area.top, s(70, dpi),
                         area.bottom - area.top,
                         tr(language_, Text::launchStop), false, true, false,
                         dpi);
            ui_hits_.push_back(
                UiHit{RECT{area.right - s(140, dpi), area.top,
                           area.right - s(78, dpi), area.bottom}, 300});
            ui_hits_.push_back(
                UiHit{RECT{area.right - s(70, dpi), area.top, area.right,
                           area.bottom}, 301});
        } else {
            draw_text(tr(language_, Text::launchNoGames),
                      rect(area.left, area.top, area.right, area.bottom),
                      s(12, dpi), kSecondary, DWRITE_FONT_WEIGHT_NORMAL,
                      DWRITE_TEXT_ALIGNMENT_LEADING);
        }
    };
    running_section.fields.push_back(std::move(running_field));
    std::vector<UiSection> running_sections;
    running_sections.push_back(std::move(running_section));
    int running_y = next_y;
    paint_sections(content_left, content_right, running_y, dpi,
                   running_sections);
    set_scroll_extent(running_y, client, dpi);
    end_scroll();
}


void App::paint_versions(const RECT& client, int dpi) {
    const int left = contentLeft(rail_width_, dpi);
    const int right = contentRight(client, rail_width_, dpi);
    draw_text(tr(language_, Text::versionTitle),
              rect(left, s(58, dpi), right, s(88, dpi)),
              s(20, dpi), kText, DWRITE_FONT_WEIGHT_BOLD,
              DWRITE_TEXT_ALIGNMENT_LEADING);
    draw_icon(ICON_ARCHIVE,
              rect(static_cast<int>(client.right) - s(48, dpi),
                   s(88, dpi),
                   static_cast<int>(client.right) - s(32, dpi),
                   s(104, dpi)),
              s(16, dpi), kSecondary);
    draw_text(widen(current_version_),
              rect(left, s(90, dpi), right, s(112, dpi)), s(12, dpi),
              kSecondary, DWRITE_FONT_WEIGHT_NORMAL,
              DWRITE_TEXT_ALIGNMENT_LEADING);

    begin_scroll(client, dpi);
    const VersionRow* row = nullptr;
    for (const auto& version : versions_) {
        if (version.name == current_version_) {
            row = &version;
            break;
        }
    }

    auto field = [](std::wstring label, std::wstring hint, int height,
                    int control_width, bool full_width, int action,
                    std::function<void(const RECT&)> paint) {
        return make_field(std::move(label), std::move(hint), height,
                          control_width, full_width, action, std::move(paint));
    };
    // Values hug the right edge and share the label's baseline band, matching
    // the shared field layout (label left, value right).
    auto value_text = [&](std::wstring text) {
        return [this, dpi, text](const RECT& area) {
            draw_text(text,
                      rect(area.left + s(16, dpi), area.top + s(14, dpi),
                           area.right - s(16, dpi), area.top + s(38, dpi)),
                      s(12, dpi), kText, DWRITE_FONT_WEIGHT_NORMAL,
                      DWRITE_TEXT_ALIGNMENT_TRAILING);
        };
    };

    std::wstring loader =
        row == nullptr ? L"Vanilla" : widen(displayLoader(row->loader));
    if (row != nullptr && !row->loader_version.empty()) {
        loader += L" " + widen(row->loader_version);
    }

    std::vector<UiSection> sections;
    UiSection version;
    version.title = tr(language_, Text::appVersion);
    version.fields.push_back(field(
        tr(language_, Text::versionName), L"", 45, 0, false, -1,
        value_text(widen(current_version_))));
    version.fields.push_back(field(
        tr(language_, Text::versionGame), L"", 45, 0, false, -1,
        value_text(row == nullptr ? L"—" : widen(row->game_version))));
    version.fields.push_back(
        field(tr(language_, Text::versionLoader), L"", 45, 0, false, -1,
              value_text(loader)));
    const std::wstring directory =
        row == nullptr ? game_dir_.wstring() : row->dir.wstring();
    version.fields.push_back(field(
        L"", L"", 60, 0, false, -1,
        [this, dpi, directory, row](const RECT& area) {
            const RECT band = label_band(area, dpi, true);
            const int label_bottom = band.top + s(24, dpi);
            draw_text(tr(language_, Text::versionDirectory),
                      rect(area.left + s(16, dpi), band.top,
                           area.right - s(16, dpi), label_bottom),
                      s(14, dpi), kText, DWRITE_FONT_WEIGHT_NORMAL,
                      DWRITE_TEXT_ALIGNMENT_LEADING);
            draw_text(directory,
                      rect(area.left + s(16, dpi), label_bottom,
                           area.right - s(142, dpi), band.bottom),
                      s(12, dpi), kSecondary, DWRITE_FONT_WEIGHT_NORMAL,
                      DWRITE_TEXT_ALIGNMENT_LEADING);
            const int row_height = static_cast<int>(area.bottom - area.top);
            const int top = area.top + (row_height - s(28, dpi)) / 2;
            const RECT button{area.right - s(126, dpi), top,
                              area.right - s(16, dpi), top + s(28, dpi)};
            paint_button(button.left, button.top, button.right - button.left,
                         button.bottom - button.top,
                         tr(language_, Text::versionOpenFolder), false,
                         row != nullptr, hover_action_ == 2, dpi);
            ui_hits_.push_back(UiHit{button, 200});
        }));
    if (!broken_versions_.empty()) {
        std::wstring warning = tr(language_, Text::brokenVersions);
        for (const auto& name : broken_versions_) {
            warning += L" " + widen(name);
        }
        version.fields.push_back(field(
            L"", L"", 45, 0, false, -1,
            [this, dpi, warning](const RECT& area) {
                draw_text(warning,
                          rect(area.left + s(16, dpi), area.top,
                               area.right - s(16, dpi), area.bottom),
                          s(11, dpi), kSecondary, DWRITE_FONT_WEIGHT_NORMAL,
                          DWRITE_TEXT_ALIGNMENT_LEADING, true);
            }));
    }
    sections.push_back(std::move(version));

    UiSection java;
    java.title = tr(language_, Text::javaTitle);
    java.fields.push_back(field(
        L"", L"", 60, 0, false, -1,
        [this, dpi](const RECT& area) {
            const std::wstring status =
                java_auto_status_.empty()
                    ? std::wstring(tr(language_, Text::javaAutoHint))
                    : java_auto_status_;
            const RECT band = label_band(area, dpi, true);
            const int label_bottom = band.top + s(24, dpi);
            draw_text(tr(language_, Text::javaSource),
                      rect(area.left + s(16, dpi), band.top,
                           area.right - s(208, dpi), label_bottom),
                      s(14, dpi), kText, DWRITE_FONT_WEIGHT_NORMAL,
                      DWRITE_TEXT_ALIGNMENT_LEADING);
            draw_text(status,
                      rect(area.left + s(16, dpi), label_bottom,
                           area.right - s(208, dpi), band.bottom),
                      s(12, dpi),
                      hover_action_ == 4 ? kAccent : kSecondary,
                      DWRITE_FONT_WEIGHT_NORMAL,
                      DWRITE_TEXT_ALIGNMENT_LEADING);
            // Clicking the status line rescans; the result is cached otherwise.
            ui_hits_.push_back(UiHit{RECT{area.left + s(16, dpi), area.top,
                                          area.right - s(208, dpi),
                                          area.bottom},
                                     210});
            const int row_height = static_cast<int>(area.bottom - area.top);
            const int top = area.top + (row_height - s(28, dpi)) / 2;
            const int bottom = top + s(28, dpi);
            paint_button(area.right - s(200, dpi), top, s(64, dpi),
                         bottom - top, tr(language_, Text::javaAuto), false,
                         true, !manual_java_, dpi);
            paint_button(area.right - s(130, dpi), top, s(76, dpi),
                         bottom - top, tr(language_, Text::javaManual), false,
                         true, manual_java_, dpi);
            ui_hits_.push_back(UiHit{RECT{area.right - s(200, dpi), top,
                                          area.right - s(136, dpi), bottom},
                                     201});
            ui_hits_.push_back(UiHit{RECT{area.right - s(130, dpi), top,
                                          area.right - s(54, dpi), bottom},
                                     202});
        }));
    if (manual_java_) {
        java.fields.push_back(field(
            L"", L"", 60, 0, false, -1,
            [this, dpi](const RECT& area) {
                const int row_height = static_cast<int>(area.bottom - area.top);
                const int input_top = area.top + (row_height - s(30, dpi)) / 2;
                const RECT input{area.left + s(16, dpi), input_top,
                                 area.right - s(16, dpi),
                                 input_top + s(30, dpi)};
                paint_input(input.left, input.top, input.right - input.left,
                            input.bottom - input.top, java_text_,
                            focus_field_ == 0, dpi);
                ui_hits_.push_back(UiHit{input, 203});
                if (!java_manual_status_.empty()) {
                    draw_text(java_manual_status_,
                              rect(area.left + s(16, dpi),
                                   area.bottom - s(16, dpi),
                                   area.right - s(16, dpi), area.bottom),
                              s(11, dpi),
                              java_manual_ok_ ? kAccent : kSecondary,
                              DWRITE_FONT_WEIGHT_NORMAL,
                              DWRITE_TEXT_ALIGNMENT_LEADING);
                }
            }));
    }
    sections.push_back(std::move(java));

    UiSection memory;
    memory.title = tr(language_, Text::memoryTitle);
    auto memory_row = [&](std::wstring label, const std::wstring& text,
                          int field_id, int action) {
        return field(L"", L"", 60, 0, false, -1,
                     [this, dpi, label, &text, field_id, action](
                         const RECT& area) {
                         const RECT band = label_band(area, dpi, true);
                         const int label_bottom = band.top + s(24, dpi);
                         draw_text(label,
                                   rect(area.left + s(16, dpi), band.top,
                                        area.right - s(16, dpi), label_bottom),
                                   s(14, dpi), kText,
                                   DWRITE_FONT_WEIGHT_NORMAL,
                                   DWRITE_TEXT_ALIGNMENT_LEADING);
                         draw_text(tr(language_, Text::memoryHint),
                                   rect(area.left + s(16, dpi), label_bottom,
                                        area.right - s(200, dpi), band.bottom),
                                   s(12, dpi), kSecondary,
                                   DWRITE_FONT_WEIGHT_NORMAL,
                                   DWRITE_TEXT_ALIGNMENT_LEADING);
                         const int row_height =
                             static_cast<int>(area.bottom - area.top);
                         const int input_top =
                             area.top + (row_height - s(30, dpi)) / 2;
                         const RECT input{area.right - s(190, dpi), input_top,
                                          area.right - s(70, dpi),
                                          input_top + s(30, dpi)};
                         paint_input(input.left, input.top,
                                     input.right - input.left,
                                     input.bottom - input.top, text,
                                     focus_field_ == field_id, dpi);
                         draw_text(L"MB",
                                   rect(area.right - s(58, dpi), input.top,
                                        area.right - s(16, dpi),
                                        input.bottom),
                                   s(12, dpi), kSecondary,
                                   DWRITE_FONT_WEIGHT_NORMAL,
                                   DWRITE_TEXT_ALIGNMENT_LEADING);
                         ui_hits_.push_back(UiHit{input, action});
                     });
    };
    memory.fields.push_back(
        memory_row(tr(language_, Text::memoryMinimum), min_memory_text_, 1, 205));
    memory.fields.push_back(
        memory_row(tr(language_, Text::memoryMaximum), max_memory_text_, 2, 206));
    sections.push_back(std::move(memory));

    UiSection jvm;
    jvm.title = tr(language_, Text::jvmTitle);
    jvm.fields.push_back(field(
        L"", L"", 60, 0, false, -1,
        [this, dpi](const RECT& area) {
            const int row_height = static_cast<int>(area.bottom - area.top);
            const int input_top = area.top + (row_height - s(30, dpi)) / 2;
            const RECT input{area.left + s(16, dpi), input_top,
                             area.right - s(16, dpi),
                             input_top + s(30, dpi)};
            paint_input(input.left, input.top, input.right - input.left,
                        input.bottom - input.top, jvm_text_,
                        focus_field_ == 3, dpi);
            ui_hits_.push_back(UiHit{input, 207});
        }));
    sections.push_back(std::move(jvm));

    int section_y = s(124, dpi);
    paint_sections(left, right, section_y, dpi, sections);

    const int save_y = section_y + s(8, dpi);
    const RECT save_button{left, save_y, left + s(80, dpi), save_y + s(34, dpi)};
    paint_button(save_button.left, save_button.top, s(80, dpi), s(34, dpi),
                 tr(language_, Text::save), true, true, hover_action_ == 1,
                 dpi);
    ui_hits_.push_back(UiHit{save_button, 209});
    if (!config_error_.empty()) {
        draw_text(widen(config_error_),
                  rect(left + s(92, dpi), save_y + s(6, dpi),
                       right - s(16, dpi), save_y + s(28, dpi)),
                  s(11, dpi), kSecondary, DWRITE_FONT_WEIGHT_NORMAL,
                  DWRITE_TEXT_ALIGNMENT_LEADING);
    } else if (config_saved_) {
        draw_text(tr(language_, Text::saved),
                  rect(left + s(92, dpi), save_y + s(6, dpi),
                       right - s(16, dpi), save_y + s(28, dpi)),
                  s(11, dpi), kAccent, DWRITE_FONT_WEIGHT_NORMAL,
                  DWRITE_TEXT_ALIGNMENT_LEADING);
    }
    set_scroll_extent(save_y + s(42, dpi), client, dpi);
    end_scroll();
}

void App::paint_manage(const RECT& client, int dpi) {
    const int left = contentLeft(rail_width_, dpi);
    const int right = contentRight(client, rail_width_, dpi);
    draw_text(tr(language_, Text::managerTitle),
              rect(left, s(58, dpi), right, s(88, dpi)), s(20, dpi), kText,
              DWRITE_FONT_WEIGHT_BOLD,
              DWRITE_TEXT_ALIGNMENT_LEADING);
    draw_text(tr(language_, Text::managerSubtitle),
              rect(left, s(90, dpi), right, s(112, dpi)), s(12, dpi),
              kSecondary, DWRITE_FONT_WEIGHT_NORMAL,
              DWRITE_TEXT_ALIGNMENT_LEADING);
    draw_icon(ICON_ARROW_LEFT,
              rect(static_cast<int>(client.right) - s(104, dpi),
                   s(88, dpi), static_cast<int>(client.right) - s(88, dpi),
                   s(104, dpi)),
              s(16, dpi), kSecondary);
    draw_icon(ICON_REFRESH,
              rect(static_cast<int>(client.right) - s(48, dpi),
                   s(88, dpi), static_cast<int>(client.right) - s(32, dpi),
                   s(104, dpi)),
              s(16, dpi), kSecondary);

    begin_scroll(client, dpi);
    const bool import_enabled = !manage_import_busy_;
    paint_button(left, s(124, dpi), s(120, dpi), s(34, dpi),
                 tr(language_, Text::importFolder), false, import_enabled,
                 false, dpi);
    paint_button(left + s(132, dpi), s(124, dpi), s(100, dpi), s(34, dpi),
                 tr(language_, Text::importZip), false, import_enabled,
                 false, dpi);
    if (manage_import_busy_) {
        draw_text(tr(language_, Text::importing),
                  rect(left, s(168, dpi), right - s(16, dpi), s(190, dpi)),
                  s(11, dpi), kSecondary, DWRITE_FONT_WEIGHT_NORMAL,
                  DWRITE_TEXT_ALIGNMENT_LEADING);
    } else if (!manage_notice_.empty()) {
        draw_text(manage_notice_,
                  rect(left, s(168, dpi), right - s(16, dpi), s(190, dpi)),
                  s(11, dpi), kAccent, DWRITE_FONT_WEIGHT_NORMAL,
                  DWRITE_TEXT_ALIGNMENT_LEADING);
    } else if (!manage_error_.empty()) {
        draw_text(widen(manage_error_),
                  rect(left, s(168, dpi), right - s(16, dpi),
                       s(190, dpi)),
                  s(11, dpi), kSecondary, DWRITE_FONT_WEIGHT_NORMAL,
                  DWRITE_TEXT_ALIGNMENT_LEADING);
    }

    int row_top = s(200, dpi);
    for (const auto& version : versions_) {
        const ui::ListCardLayout card =
            ui::list_card(left, right, row_top, dpi);
        if (version.name == current_version_) {
            fill_rect(rect(card.card.left, card.card.top, card.card.right,
                           card.card.bottom), kSurface);
            if (brush_ != nullptr) {
                brush_->SetColor(color(kAccent));
                target_->DrawRectangle(
                    rect(card.card.left, card.card.top, card.card.right,
                         card.card.bottom), brush_.Get(), 1.0f);
            }
        } else {
            draw_panel(rect(card.card.left, card.card.top, card.card.right,
                            card.card.bottom));
        }
        if (version.name == current_version_) {
            fill_rect(rect(card.card.left, card.card.top,
                           card.card.left + s(2, dpi), card.card.bottom),
                      kAccent);
        }
        draw_text(widen(version.name),
                  rect(card.content.left, card.card.top + s(8, dpi),
                       right - s(300, dpi), card.card.top + s(28, dpi)),
                  s(14, dpi), kText, DWRITE_FONT_WEIGHT_NORMAL,
                  DWRITE_TEXT_ALIGNMENT_LEADING);
        std::wstring subtitle = widen(version.game_version + " \u00B7 " +
                                      displayLoader(version.loader));
        if (!version.loader_version.empty()) {
            subtitle += L" " + widen(version.loader_version);
        }
        draw_text(subtitle,
                  rect(card.content.left, card.card.top + s(30, dpi),
                       right - s(250, dpi), card.card.top + s(50, dpi)),
                  s(12, dpi), kSecondary, DWRITE_FONT_WEIGHT_NORMAL,
                  DWRITE_TEXT_ALIGNMENT_LEADING);
        if (version.name == current_version_) {
            const std::wstring name = widen(version.name);
            const int current_left = std::min(
                static_cast<int>(card.content.left) + s(12, dpi) +
                    static_cast<int>(name.size()) * s(8, dpi),
                static_cast<int>(card.content.right) - s(64, dpi));
            draw_text(tr(language_, Text::current),
                      rect(current_left, card.card.top + s(8, dpi),
                           current_left + s(64, dpi),
                           card.card.top + s(28, dpi)),
                      s(11, dpi), kAccent, DWRITE_FONT_WEIGHT_NORMAL,
                      DWRITE_TEXT_ALIGNMENT_LEADING);
        }
        paint_button(card.primary_action.left, card.primary_action.top,
                     card.primary_action.right - card.primary_action.left,
                     card.primary_action.bottom - card.primary_action.top,
                     tr(language_, Text::rename), false, true, false, dpi);
        paint_button(card.secondary_action.left, card.secondary_action.top,
                     card.secondary_action.right - card.secondary_action.left,
                     card.secondary_action.bottom - card.secondary_action.top,
                     tr(language_, Text::remove), false, true, false, dpi);
        row_top += ui::list_card_step(dpi);
    }
    if (versions_.empty()) {
        draw_text(tr(language_, Text::noVersions),
                  rect(left, s(214, dpi), right - s(16, dpi),
                       s(240, dpi)),
                  s(12, dpi), kSecondary, DWRITE_FONT_WEIGHT_NORMAL,
                  DWRITE_TEXT_ALIGNMENT_LEADING);
    }

    set_scroll_extent(std::max(row_top + s(24, dpi), s(602, dpi)), client,
                      dpi);
    end_scroll();

    if (manage_rename_dialog_) {
        // The page is drawn with a -34px translation; reset it so the dialog
        // lines up with the click rectangles, which use client coordinates.
        target_->SetTransform(D2D1::Matrix3x2F::Identity());
        const DialogFrame frame = begin_dialog(client, dpi, 420, 196);
        const int dialog_left = frame.left;
        const int dialog_top = frame.top;
        const int dialog_right = frame.right;
        const int dialog_bottom = frame.bottom;
        const int width = dialog_right - dialog_left;
        draw_text(tr(language_, Text::renameTitle),
                  rect(dialog_left + s(24, dpi), dialog_top + s(20, dpi),
                       dialog_right - s(24, dpi), dialog_top + s(48, dpi)),
                  s(16, dpi), kText, DWRITE_FONT_WEIGHT_SEMI_BOLD,
                  DWRITE_TEXT_ALIGNMENT_LEADING);
        paint_input(dialog_left + s(24, dpi), dialog_top + s(60, dpi),
                    width - s(48, dpi), s(34, dpi), rename_text_,
                    focus_field_ == 4, dpi);
        paint_button(dialog_right - s(188, dpi),
                     dialog_bottom - s(52, dpi), s(80, dpi), s(32, dpi),
                     tr(language_, Text::cancel), false, true, false, dpi);
        paint_button(dialog_right - s(96, dpi),
                     dialog_bottom - s(52, dpi), s(72, dpi), s(32, dpi),
                     tr(language_, Text::rename), true, true, false, dpi);
        target_->SetTransform(
            D2D1::Matrix3x2F::Translation(0.0f, -static_cast<float>(s(34, dpi))));
    }
}

void App::paint_settings(const RECT& client, int dpi) {
    const int left = contentLeft(rail_width_, dpi);
    const int right = contentRight(client, rail_width_, dpi);
    draw_text(tr(language_, Text::settingsTitle),
              rect(left, s(58, dpi), right, s(88, dpi)),
              s(20, dpi), kText, DWRITE_FONT_WEIGHT_BOLD,
              DWRITE_TEXT_ALIGNMENT_LEADING);
    draw_text(tr(language_, Text::settingsSubtitle),
              rect(left, s(90, dpi), right, s(112, dpi)), s(12, dpi),
              kSecondary, DWRITE_FONT_WEIGHT_NORMAL,
              DWRITE_TEXT_ALIGNMENT_LEADING);

    begin_scroll(client, dpi);

    auto field = [](std::wstring label, std::wstring hint, int height,
                    int control_width, int action,
                    std::function<void(const RECT&)> paint) {
        return make_field(std::move(label), std::move(hint), height,
                          control_width, false, action, std::move(paint));
    };
    auto button = [&](const wchar_t* text, bool selected) {
        return [this, dpi, text, selected](const RECT& area) {
            paint_button(area.left, area.top, area.right - area.left,
                         area.bottom - area.top, text, false, true,
                         selected, dpi);
        };
    };

    std::vector<UiSection> sections;
    UiSection language;
    language.title = tr(language_, Text::languageTitle);
    language.fields.push_back(
        field(tr(language_, Text::displayLanguage), L"", 42, 92, 100,
              button(language_name(language_), false)));
    language.fields.push_back(field(
        tr(language_, Text::followSystem), L"", 42, 92, 107,
        button(follow_system_language_
                   ? tr(language_, Text::enabled)
                   : tr(language_, Text::disabled),
               follow_system_language_)));
    sections.push_back(std::move(language));

    UiSection appearance;
    appearance.title = tr(language_, Text::appearanceTitle);
    appearance.fields.push_back(field(
        tr(language_, Text::dark), L"", 42, 92, 101,
        button(dark_mode_ ? tr(language_, Text::dark)
                          : tr(language_, Text::light),
               dark_mode_ && !follow_system_)));
    appearance.fields.push_back(field(
        tr(language_, Text::followSystem),
        tr(language_, Text::followHint), 60, 92, 102,
        button(follow_system_ ? tr(language_, Text::enabled)
                              : tr(language_, Text::disabled),
               follow_system_)));
    sections.push_back(std::move(appearance));

    UiSection game_directory;
    game_directory.title = tr(language_, Text::gameDirectoryTitle);
    const std::wstring directory = game_dir_.wstring();
    game_directory.fields.push_back(field(
        tr(language_, Text::currentDirectory), directory, 60, 92, 103,
        button(tr(language_, Text::change), false)));
    sections.push_back(std::move(game_directory));


    UiSection account;
    account.title = tr(language_, Text::accountTitle);
    const std::wstring account_hint =
        has_account_
            ? (account_expired_ ? widen(account_.name) + L" · " +
                                      tr(language_, Text::sessionExpired)
                                : widen(account_.name))
            : tr(language_, Text::signInHint);
    account.fields.push_back(field(
        tr(language_, Text::microsoftAccount), account_hint, 60, 92, 104,
        [this, dpi](const RECT& area) {
            paint_button(area.left, area.top, area.right - area.left,
                         area.bottom - area.top,
                         (has_account_ && !account_expired_)
                             ? tr(language_, Text::signOut)
                             : tr(language_, Text::signIn),
                         false, !login_busy_, false, dpi);
        }));
    account.fields.push_back(field(
        L"", L"", 62, 0, -1,
        [this, dpi](const RECT& area) {
            const RECT band = label_band(area, dpi, true);
            draw_text(tr(language_, Text::clientId),
                      rect(area.left + s(16, dpi), band.top,
                           area.right - s(16, dpi), band.top + s(24, dpi)),
                      s(14, dpi), kText, DWRITE_FONT_WEIGHT_NORMAL,
                      DWRITE_TEXT_ALIGNMENT_LEADING);
            draw_text(tr(language_, Text::clientIdHint),
                      rect(area.left + s(16, dpi), band.top + s(24, dpi),
                           area.right - s(320, dpi), band.bottom),
                      s(12, dpi), kSecondary, DWRITE_FONT_WEIGHT_NORMAL,
                      DWRITE_TEXT_ALIGNMENT_LEADING);
            const int input_top =
                area.top + (static_cast<int>(area.bottom - area.top) -
                            s(30, dpi)) / 2;
            const RECT input{area.right - s(300, dpi), input_top,
                             area.right - s(16, dpi), input_top + s(30, dpi)};
            paint_input(input.left, input.top, input.right - input.left,
                        input.bottom - input.top, client_id_text_,
                        focus_field_ == 6, dpi);
            ui_hits_.push_back(UiHit{input, 111});
        }));
    if (has_account_) {
        account.fields.push_back(field(
            tr(language_, Text::deleteAccountTitle),
            tr(language_, Text::deleteAccountHint), 60, 92, 110,
            button(tr(language_, Text::deleteAccountAction), false)));
    }
    sections.push_back(std::move(account));

    UiSection about;
    about.title = tr(language_, Text::aboutTitle);
    about.fields.push_back(field(
        tr(language_, Text::appVersion), L"", 60, 150, -1,
        [this, dpi](const RECT& area) {
            draw_text(L"0.1.0",
                      rect(area.left, area.top, area.right, area.bottom),
                      s(12, dpi), kSecondary, DWRITE_FONT_WEIGHT_NORMAL,
                      DWRITE_TEXT_ALIGNMENT_TRAILING);
        }));
    about.fields.push_back(field(
        tr(language_, Text::logs), L"", 60, 108, 108,
        button(tr(language_, Text::browse), false)));
    about.fields.push_back(field(
        tr(language_, Text::exportLogs), L"", 60, 108, 109,
        button(tr(language_, Text::save), false)));
    about.fields.push_back(field(
        tr(language_, Text::privacyTitle), tr(language_, Text::privacyHint),
        60, 108, 105, button(tr(language_, Text::view), false)));
    about.fields.push_back(field(
        tr(language_, Text::licensesTitle), tr(language_, Text::licensesHint),
        60, 108, 106, button(tr(language_, Text::view), false)));
    sections.push_back(std::move(about));

    int section_y = s(124, dpi);
    paint_sections(left, right, section_y, dpi, sections);
    set_scroll_extent(section_y + s(8, dpi), client, dpi);
    end_scroll();
}

void App::paint_settings_subpage(const RECT& client, int dpi,
                                 SettingsSubpage page) {
    const int left = contentLeft(rail_width_, dpi);
    const int right = contentRight(client, rail_width_, dpi);
    draw_icon(ICON_ARROW_LEFT,
              rect(left, s(58, dpi), left + s(16, dpi), s(74, dpi)),
              s(16, dpi), kSecondary);
    const bool privacy = page == SettingsSubpage::privacy;
    draw_text(privacy ? tr(language_, Text::privacyTitle)
                      : tr(language_, Text::licensesTitle),
              rect(left + s(28, dpi), s(58, dpi), right, s(84, dpi)),
              s(18, dpi), kText, DWRITE_FONT_WEIGHT_SEMI_BOLD,
              DWRITE_TEXT_ALIGNMENT_LEADING);

    if (privacy) {
        draw_text(tr(language_, Text::privacyText),
                  rect(left, s(118, dpi), right, s(230, dpi)), s(13, dpi),
                  kSecondary, DWRITE_FONT_WEIGHT_NORMAL,
                  DWRITE_TEXT_ALIGNMENT_LEADING, true);
        paint_button(left, s(250, dpi), s(180, dpi), s(34, dpi),
                     tr(language_, Text::fullNotice), false, true, false, dpi);
        return;
    }

    draw_text(tr(language_, Text::licensesThirdParty),
              rect(left, s(112, dpi), right, s(136, dpi)), s(12, dpi),
              kSecondary, DWRITE_FONT_WEIGHT_NORMAL,
              DWRITE_TEXT_ALIGNMENT_LEADING);
    const std::wstring own_license =
        std::wstring(jol::kProductName) + L" \u2014 " + jol::kLicenseName;
    const std::wstring licenses[] = {
        own_license,
        L"Noto Sans SC \u2014 SIL Open Font License 1.1",
        L"Remix Icon \u2014 Remix Icon License v1.0",
        L"miniz \u2014 public domain / Unlicense",
        L"nlohmann/json \u2014 MIT License",
    };
    int y = s(148, dpi);
    for (const std::wstring& license : licenses) {
        draw_panel(rect(left, y, right, y + s(42, dpi)));
        draw_text(license.c_str(),
                  rect(left + s(16, dpi), y, right - s(16, dpi),
                       y + s(42, dpi)),
                  s(13, dpi), kText, DWRITE_FONT_WEIGHT_NORMAL,
                  DWRITE_TEXT_ALIGNMENT_LEADING);
        y += s(50, dpi);
    }
}

void App::paint_login_dialog(const RECT& client, int dpi) {
    if (!login_dialog_) return;
    const DialogFrame frame = begin_dialog(client, dpi, 460, 330);
    const int left = frame.left;
    const int top = frame.top;
    const int right = frame.right;
    const int bottom = frame.bottom;
    draw_text(tr(language_, Text::loginTitle),
              rect(left + s(24, dpi), top + s(20, dpi), right - s(24, dpi),
                   top + s(48, dpi)),
              s(17, dpi), kText, DWRITE_FONT_WEIGHT_SEMI_BOLD,
              DWRITE_TEXT_ALIGNMENT_LEADING);

    if (!login_error_.empty()) {
        draw_text(widen(login_error_),
                  rect(left + s(24, dpi), top + s(62, dpi),
                       right - s(24, dpi), top + s(170, dpi)),
                  s(12, dpi), kSecondary, DWRITE_FONT_WEIGHT_NORMAL,
                  DWRITE_TEXT_ALIGNMENT_LEADING);
    } else if (login_code_.empty()) {
        draw_text(tr(language_, Text::loginRequesting),
                  rect(left + s(24, dpi), top + s(70, dpi),
                       right - s(24, dpi), top + s(100, dpi)),
                  s(13, dpi), kSecondary, DWRITE_FONT_WEIGHT_NORMAL,
                  DWRITE_TEXT_ALIGNMENT_LEADING);
    } else {
        draw_text(tr(language_, Text::loginInstruction),
                  rect(left + s(24, dpi), top + s(62, dpi),
                       right - s(24, dpi), top + s(88, dpi)),
                  s(12, dpi), kSecondary, DWRITE_FONT_WEIGHT_NORMAL,
                  DWRITE_TEXT_ALIGNMENT_LEADING);
        const D2D1_RECT_F code_box =
            rect(left + s(24, dpi), top + s(96, dpi), right - s(24, dpi),
                 top + s(154, dpi));
        fill_rect(code_box, kBg);
        if (brush_ != nullptr) {
            brush_->SetColor(color(kBorder));
            target_->DrawRectangle(code_box, brush_.Get(), 1.0f);
        }
        draw_text(widen(login_code_), code_box, s(28, dpi), kText,
                  DWRITE_FONT_WEIGHT_SEMI_BOLD,
                  DWRITE_TEXT_ALIGNMENT_CENTER);
        draw_text(widen(login_uri_),
                  rect(left + s(24, dpi), top + s(164, dpi),
                       right - s(24, dpi), top + s(190, dpi)),
                  s(11, dpi), kSecondary, DWRITE_FONT_WEIGHT_NORMAL,
                  DWRITE_TEXT_ALIGNMENT_LEADING);
        if (!login_notice_.empty()) {
            draw_text(widen(login_notice_),
                      rect(left + s(24, dpi), top + s(198, dpi),
                           right - s(24, dpi), top + s(220, dpi)),
                      s(11, dpi), kAccent, DWRITE_FONT_WEIGHT_NORMAL,
                      DWRITE_TEXT_ALIGNMENT_LEADING);
        }
    }

    paint_button(left + s(24, dpi), bottom - s(54, dpi), s(100, dpi),
                 s(32, dpi), tr(language_, Text::copyCode), false, !login_code_.empty(),
                 false, dpi);
    paint_button(left + s(134, dpi), bottom - s(54, dpi), s(100, dpi),
                 s(32, dpi), tr(language_, Text::openLink), false, !login_uri_.empty(), false,
                 dpi);
    paint_button(right - s(124, dpi), bottom - s(54, dpi), s(100, dpi),
                 s(32, dpi), tr(language_, Text::cancel), false, true, false, dpi);
}

void App::paint_privacy_dialog(const RECT& client, int dpi) {
    if (!privacy_dialog_) return;
    const DialogFrame frame = begin_dialog(client, dpi, 520, 360);
    const int left = frame.left;
    const int top = frame.top;
    const int right = frame.right;
    const int bottom = frame.bottom;
    draw_text(tr(language_, Text::privacyNotice),
              rect(left + s(24, dpi), top + s(20, dpi), right - s(24, dpi),
                   top + s(48, dpi)),
              s(17, dpi), kText, DWRITE_FONT_WEIGHT_SEMI_BOLD,
              DWRITE_TEXT_ALIGNMENT_LEADING);
    draw_text(tr(language_, Text::privacyText),
              rect(left + s(24, dpi), top + s(64, dpi), right - s(24, dpi),
                   top + s(250, dpi)),
              s(12, dpi), kSecondary, DWRITE_FONT_WEIGHT_NORMAL,
              DWRITE_TEXT_ALIGNMENT_LEADING, true);
    draw_text(tr(language_, Text::privacyAccept),
              rect(left + s(24, dpi), top + s(262, dpi),
                   right - s(24, dpi), top + s(286, dpi)),
              s(11, dpi), kSecondary, DWRITE_FONT_WEIGHT_NORMAL,
              DWRITE_TEXT_ALIGNMENT_LEADING);
    paint_button(right - s(220, dpi), bottom - s(54, dpi), s(90, dpi),
                 s(32, dpi), tr(language_, Text::cancel), false, true, false, dpi);
    paint_button(right - s(120, dpi), bottom - s(54, dpi), s(96, dpi),
                 s(32, dpi), tr(language_, Text::agree), true, true, false, dpi);
}

void App::paint_game_log(const RECT& client, int dpi) {
    if (!game_log_dialog_) return;
    const DialogFrame frame = begin_dialog(client, dpi, 640, 440);
    const int left = frame.left;
    const int top = frame.top;
    const int right = frame.right;
    const int bottom = frame.bottom;
    const std::wstring title =
        tr(language_, Text::gameLog) + (running_version_.empty()
                                            ? std::wstring()
                                            : L" \u00B7 " +
                                                  widen(running_version_));
    draw_text(title,
              rect(left + s(24, dpi), top + s(18, dpi), right - s(24, dpi),
                   top + s(46, dpi)),
              s(16, dpi), kText, DWRITE_FONT_WEIGHT_SEMI_BOLD,
              DWRITE_TEXT_ALIGNMENT_LEADING);
    std::string visible = game_log_;
    const int log_height = static_cast<int>(bottom - s(64, dpi)) -
                           static_cast<int>(top + s(58, dpi));
    const int max_lines = std::max(4, log_height / s(14, dpi));
    std::size_t cut = visible.size();
    std::size_t newlines = 0;
    for (std::size_t i = visible.size(); i-- > 0;) {
        if (visible[i] == static_cast<char>(10) &&
            ++newlines >= static_cast<std::size_t>(max_lines)) {
            cut = i + 1;
            break;
        }
    }
    visible = visible.substr(cut);
    if (visible.size() > 16000) visible = visible.substr(visible.size() - 16000);
    if (visible.empty()) {
        visible = narrow(tr(language_, Text::noOutput));
    }
    draw_text(widen(visible),
              rect(left + s(24, dpi), top + s(58, dpi), right - s(24, dpi),
                   bottom - s(64, dpi)),
              s(11, dpi), kSecondary, DWRITE_FONT_WEIGHT_NORMAL,
              DWRITE_TEXT_ALIGNMENT_LEADING, true);
    paint_button(right - s(112, dpi), bottom - s(50, dpi), s(88, dpi),
                 s(30, dpi), tr(language_, Text::close), false, true, false,
                 dpi);
}

void App::paint_java_prompt(const RECT& client, int dpi) {
    if (!java_prompt_) return;
    const DialogFrame frame = begin_dialog(client, dpi, 600, 440);
    const int left = frame.left;
    const int top = frame.top;
    const int right = frame.right;
    const int bottom = frame.bottom;
    draw_text(tr(language_, Text::selectJava),
              rect(left + s(24, dpi), top + s(18, dpi), right - s(24, dpi),
                   top + s(46, dpi)),
              s(17, dpi), kText, DWRITE_FONT_WEIGHT_SEMI_BOLD,
              DWRITE_TEXT_ALIGNMENT_LEADING);
    draw_text(tr(language_, Text::selectJavaHint),
              rect(left + s(24, dpi), top + s(50, dpi), right - s(24, dpi),
                   top + s(74, dpi)),
              s(11, dpi), kSecondary, DWRITE_FONT_WEIGHT_NORMAL,
              DWRITE_TEXT_ALIGNMENT_LEADING);

    int y = top + s(88, dpi);
    int shown = 0;
    for (const auto& runtime : java_runtimes_) {
        if (shown >= 5) break;
        const RECT row{left + s(24, dpi), y, right - s(24, dpi),
                       y + s(46, dpi)};
        draw_panel(rect(row.left, row.top, row.right, row.bottom));
        const std::wstring title =
            L"Java " + std::to_wstring(runtime.major) + L"  ·  " +
            widen(runtime.version);
        draw_text(title,
                  rect(row.left + s(12, dpi), row.top, row.right - s(12, dpi),
                       row.top + s(23, dpi)),
                  s(12, dpi), kText, DWRITE_FONT_WEIGHT_NORMAL,
                  DWRITE_TEXT_ALIGNMENT_LEADING);
        draw_text(runtime.path.wstring(),
                  rect(row.left + s(12, dpi), row.top + s(22, dpi),
                       row.right - s(12, dpi), row.bottom),
                  s(10, dpi), kSecondary, DWRITE_FONT_WEIGHT_NORMAL,
                  DWRITE_TEXT_ALIGNMENT_LEADING);
        y += s(52, dpi);
        ++shown;
    }
    if (java_runtimes_.empty()) {
        draw_text(tr(language_, Text::noJavaRuntimes),
                  rect(left + s(24, dpi), y, right - s(24, dpi),
                       y + s(30, dpi)),
                  s(12, dpi), kSecondary, DWRITE_FONT_WEIGHT_NORMAL,
                  DWRITE_TEXT_ALIGNMENT_LEADING);
    }
    paint_button(left + s(24, dpi), bottom - s(50, dpi), s(100, dpi),
                 s(30, dpi), tr(language_, Text::browse), false, true, false,
                 dpi);
    paint_button(right - s(112, dpi), bottom - s(50, dpi), s(88, dpi),
                 s(30, dpi), tr(language_, Text::cancel), false, true, false,
                 dpi);
}

void App::choose_java_executable(HWND window) {
    const auto path = chooseJavaFile(window, language_);
    if (path.empty()) return;
    config_.java_path = narrow(path.wstring());
    manual_java_ = true;
    java_text_ = path.wstring();
    save_version_config();
    java_prompt_ = false;
    pending_launch_ = false;
    begin_launch(window);
}

void App::paint(HWND window) {
    PAINTSTRUCT ps{};
    BeginPaint(window, &ps);
    if (ensure_target(window)) {
        target_->BeginDraw();
        target_->SetTransform(D2D1::Matrix3x2F::Identity());
        target_->Clear(color(kBg));
        ui_hits_.clear();

        RECT client{};
        GetClientRect(window, &client);
        const int dpi = static_cast<int>(GetDpiForWindow(window));
        paint_rail(client, dpi);
        paint_splitter(client, dpi);
        target_->SetTransform(D2D1::Matrix3x2F::Translation(
            0.0f, -static_cast<float>(s(34, dpi))));

        auto draw_versions = [&](bool manager, float opacity) {
            if (opacity <= 0.0f) return;
            const bool layered = layer_ != nullptr && opacity < 0.999f;
            if (layered) {
                const D2D1_LAYER_PARAMETERS parameters = D2D1::LayerParameters(
                    D2D1::InfiniteRect(), nullptr,
                    D2D1_ANTIALIAS_MODE_PER_PRIMITIVE,
                    D2D1::IdentityMatrix(), opacity, nullptr,
                    D2D1_LAYER_OPTIONS_NONE);
                target_->PushLayer(parameters, layer_.Get());
            }
            if (manager) {
                paint_manage(client, dpi);
            } else {
                paint_versions(client, dpi);
            }
            if (layered) target_->PopLayer();
        };

        auto draw_page = [&](Page page, float opacity) {
            if (opacity <= 0.0f) return;
            const bool layered = layer_ != nullptr && opacity < 0.999f;
            if (layered) {
                const D2D1_LAYER_PARAMETERS parameters = D2D1::LayerParameters(
                    D2D1::InfiniteRect(), nullptr,
                    D2D1_ANTIALIAS_MODE_PER_PRIMITIVE,
                    D2D1::IdentityMatrix(), opacity, nullptr,
                    D2D1_LAYER_OPTIONS_NONE);
                target_->PushLayer(parameters, layer_.Get());
            }
            switch (page) {
                case Page::launch:
                    paint_launch(client, dpi);
                    break;
                case Page::versions:
                    if (manage_open_) {
                        paint_manage(client, dpi);
                    } else {
                        paint_versions(client, dpi);
                    }
                    break;
                case Page::settings:
                    if (settings_subpage_ != SettingsSubpage::none) {
                        paint_settings_subpage(client, dpi, settings_subpage_);
                    } else {
                        paint_settings(client, dpi);
                    }
                    break;
                default:
                    break;
            }
            if (layered) target_->PopLayer();
        };

        auto draw_settings_state = [&](int state, float opacity) {
            if (opacity <= 0.0f) return;
            const bool layered = layer_ != nullptr && opacity < 0.999f;
            if (layered) {
                const D2D1_LAYER_PARAMETERS parameters = D2D1::LayerParameters(
                    D2D1::InfiniteRect(), nullptr,
                    D2D1_ANTIALIAS_MODE_PER_PRIMITIVE,
                    D2D1::IdentityMatrix(), opacity, nullptr,
                    D2D1_LAYER_OPTIONS_NONE);
                target_->PushLayer(parameters, layer_.Get());
            }
            if (state == static_cast<int>(SettingsSubpage::none)) {
                paint_settings(client, dpi);
            } else {
                paint_settings_subpage(client, dpi,
                                      static_cast<SettingsSubpage>(state));
            }
            if (layered) target_->PopLayer();
        };

        if (page_fade_.active) {
            draw_page(static_cast<Page>(page_fade_.from),
                      1.0f - page_fade_.progress);
            draw_page(static_cast<Page>(page_fade_.to), page_fade_.progress);
        } else if (page_ == Page::versions && manage_fade_.active) {
            draw_versions(manage_fade_.from != 0,
                          1.0f - manage_fade_.progress);
            draw_versions(manage_fade_.to != 0, manage_fade_.progress);
        } else if (page_ == Page::settings && settings_fade_.active) {
            draw_settings_state(settings_fade_.from,
                                1.0f - settings_fade_.progress);
            draw_settings_state(settings_fade_.to, settings_fade_.progress);
        } else if (page_ == Page::versions) {
            draw_versions(manage_open_, 1.0f);
        } else if (page_ == Page::settings) {
            draw_settings_state(static_cast<int>(settings_subpage_), 1.0f);
        } else {
            draw_page(page_, 1.0f);
        }

        target_->SetTransform(D2D1::Matrix3x2F::Identity());
        paint_scrollbar(client, dpi);
        paint_login_dialog(client, dpi);
        paint_privacy_dialog(client, dpi);
        paint_game_log(client, dpi);
        paint_java_prompt(client, dpi);

        if (target_->EndDraw() == D2DERR_RECREATE_TARGET) release_target();
    }
    EndPaint(window, &ps);
}

void App::resize(HWND window) {
    if (target_ == nullptr) return;
    RECT client{};
    GetClientRect(window, &client);
    if (client.right > 0 && client.bottom > 0) {
        target_->Resize(D2D1::SizeU(static_cast<UINT32>(client.right),
                                    static_cast<UINT32>(client.bottom)));
    }
}

void App::apply_initial_window(HWND window) {
    if (!window_state_.valid || window_state_applied_) return;
    window_state_applied_ = true;
    RECT r{window_state_.x, window_state_.y,
           window_state_.x + window_state_.width,
           window_state_.y + window_state_.height};
    MONITORINFO monitor{};
    monitor.cbSize = sizeof(monitor);
    HMONITOR handle = MonitorFromRect(&r, MONITOR_DEFAULTTONEAREST);
    if (handle == nullptr || !GetMonitorInfoW(handle, &monitor)) {
        return;
    }
    RECT visible{0, 0, 0, 0};
    if (!IntersectRect(&visible, &r, &monitor.rcWork)) {
        r.right = r.left + window_state_.width;
        r.bottom = r.top + window_state_.height;
        const int width = r.right - r.left;
        const int height = r.bottom - r.top;
        r.left = monitor.rcWork.left +
                 ((monitor.rcWork.right - monitor.rcWork.left) - width) / 2;
        r.top = monitor.rcWork.top +
                ((monitor.rcWork.bottom - monitor.rcWork.top) - height) / 2;
        r.right = r.left + width;
        r.bottom = r.top + height;
    }
    WINDOWPLACEMENT placement{};
    placement.length = sizeof(placement);
    placement.rcNormalPosition = r;
    placement.showCmd = window_state_.maximized ? SW_SHOWMAXIMIZED
                                                : SW_SHOWNORMAL;
    SetWindowPlacement(window, &placement);
}

void App::capture_window_state(HWND window) {
    if (IsIconic(window)) return;
    WINDOWPLACEMENT placement{};
    placement.length = sizeof(placement);
    if (!GetWindowPlacement(window, &placement)) return;
    const RECT& r = placement.rcNormalPosition;
    window_state_.x = r.left;
    window_state_.y = r.top;
    window_state_.width = r.right - r.left;
    window_state_.height = r.bottom - r.top;
    window_state_.maximized = placement.showCmd == SW_SHOWMAXIMIZED;
    window_state_.valid = window_state_.width > 200 && window_state_.height > 150;
    save_settings();
}

void App::click(HWND window, int x, int y) {
    if (page_fade_.active) return;
    RECT client{};
    GetClientRect(window, &client);
    const int dpi = static_cast<int>(GetDpiForWindow(window));


    if (java_prompt_) {
        const DialogFrame frame = dialog_rect(client, dpi, 600, 440);
        const int left = frame.left;
        const int top = frame.top;
        const int right = frame.right;
        const int bottom = frame.bottom;
        for (int index = 0;
             index < static_cast<int>(java_runtimes_.size()) && index < 5;
             ++index) {
            const int row_top = top + s(88 + index * 52, dpi);
            if (hit(x, y, RECT{left + s(24, dpi), row_top,
                               right - s(24, dpi), row_top + s(46, dpi)})) {
                config_.java_path =
                    narrow(java_runtimes_[index].path.wstring());
                manual_java_ = true;
                java_text_ = java_runtimes_[index].path.wstring();
                save_version_config();
                java_prompt_ = false;
                pending_launch_ = false;
                begin_launch(window);
                InvalidateRect(window, nullptr, FALSE);
                return;
            }
        }
        if (hit(x, y, RECT{left + s(24, dpi), bottom - s(50, dpi),
                           left + s(124, dpi), bottom - s(20, dpi)})) {
            choose_java_executable(window);
            InvalidateRect(window, nullptr, FALSE);
            return;
        }
        if (hit(x, y, RECT{right - s(112, dpi), bottom - s(50, dpi),
                           right - s(24, dpi), bottom - s(20, dpi)})) {
            java_prompt_ = false;
            pending_launch_ = false;
            InvalidateRect(window, nullptr, FALSE);
        }
        return;
    }

    if (game_log_dialog_) {
        const DialogFrame frame = dialog_rect(client, dpi, 640, 440);
        const int right = frame.right;
        const int bottom = frame.bottom;
        if (hit(x, y, RECT{right - s(112, dpi), bottom - s(50, dpi),
                           right - s(24, dpi), bottom - s(20, dpi)})) {
            game_log_dialog_ = false;
            InvalidateRect(window, nullptr, FALSE);
        }
        return;
    }

    if (privacy_dialog_) {
        const DialogFrame frame = dialog_rect(client, dpi, 520, 360);
        const int right = frame.right;
        const int bottom = frame.bottom;
        if (hit(x, y, RECT{right - s(120, dpi), bottom - s(54, dpi),
                           right - s(24, dpi), bottom - s(22, dpi)})) {
            global_settings_.privacy_accepted = true;
            global_settings_.privacy_version = jol::kPrivacyNoticeVersion;
            jol::writeGlobalSettings(global_settings_);
            if (!has_account_) {
                if (const auto account = account_store_.load()) {
                    account_ = *account;
                    has_account_ = true;
                }
            }
            privacy_dialog_ = false;
            if (privacy_view_only_) {
                privacy_view_only_ = false;
            } else {
                begin_login(window);
            }
            InvalidateRect(window, nullptr, FALSE);
            return;
        }
        if (hit(x, y, RECT{right - s(220, dpi), bottom - s(54, dpi),
                           right - s(130, dpi), bottom - s(22, dpi)})) {
            privacy_dialog_ = false;
            privacy_view_only_ = false;
            InvalidateRect(window, nullptr, FALSE);
            return;
        }
        return;
    }

    if (login_dialog_) {
        const DialogFrame frame = dialog_rect(client, dpi, 460, 330);
        const int left = frame.left;
        const int right = frame.right;
        const int bottom = frame.bottom;
        if (hit(x, y, RECT{right - s(124, dpi), bottom - s(54, dpi),
                           right - s(24, dpi), bottom - s(22, dpi)})) {
            cancel_login(window);
            return;
        }
        if (!login_code_.empty() &&
            hit(x, y, RECT{left + s(24, dpi), bottom - s(54, dpi),
                           left + s(124, dpi), bottom - s(22, dpi)})) {
            if (OpenClipboard(window)) {
                EmptyClipboard();
                const std::wstring code = widen(login_code_);
                const size_t bytes = (code.size() + 1) * sizeof(wchar_t);
                HGLOBAL memory = GlobalAlloc(GMEM_MOVEABLE, bytes);
                if (memory != nullptr) {
                    void* data = GlobalLock(memory);
                    if (data != nullptr) {
                        memcpy(data, code.c_str(), bytes);
                        GlobalUnlock(memory);
                        SetClipboardData(CF_UNICODETEXT, memory);
                    }
                }
                CloseClipboard();
                login_notice_ = narrow(tr(language_, Text::clipboardCopied));
                InvalidateRect(window, nullptr, FALSE);
            }
            return;
        }
        if (!login_uri_.empty() &&
            hit(x, y, RECT{left + s(134, dpi), bottom - s(54, dpi),
                           left + s(234, dpi), bottom - s(22, dpi)})) {
            if (login_uri_.rfind("https://", 0) == 0) {
                const std::wstring uri = widen(login_uri_);
                ShellExecuteW(window, L"open", uri.c_str(), nullptr, nullptr,
                              SW_SHOWNORMAL);
            }
            return;
        }
        return;
    }

    const int rail_width = s(rail_width_, dpi);
    if (x >= rail_width && x < rail_width + s(10, dpi)) {
        dragging_splitter_ = true;
        splitter_start_x_ = x;
        splitter_start_width_ = rail_width_;
        SetCapture(window);
        InvalidateRect(window, nullptr, FALSE);
        return;
    }
    if (x < rail_width) {
        for (const NavEntry& entry : nav_entries(dpi)) {
            if (!hit(x, y, entry.rect)) continue;
            if (entry.page >= 0) {
                change_page(window, entry.page);
                show_versions_ = false;
                if (entry.page == 1) load_version_config();
            }
            InvalidateRect(window, nullptr, FALSE);
            return;
        }
        if (!has_account_ && y >= client.bottom - s(58, dpi)) {
            begin_login(window);
            InvalidateRect(window, nullptr, FALSE);
        }
        return;
    }

    y += s(34, dpi);
    if (page_ == Page::settings &&
        settings_subpage_ != SettingsSubpage::none) {
        click_settings_subpage(window, x, y);
        return;
    }
    switch (page_) {
        case Page::launch:
            click_launch(window, x, y);
            return;
        case Page::versions:
            click_versions(window, x, y);
            click_version_manager(window, x, y);
            return;
        case Page::settings:
            click_settings(window, x, y);
            return;
        default:
            return;
    }
}

void App::click_settings_subpage(HWND window, int x, int y) {
    const int dpi = static_cast<int>(GetDpiForWindow(window));
    const int left = contentLeft(rail_width_, dpi);
    if (hit(x, y, RECT{left, s(58, dpi), left + s(28, dpi), s(78, dpi)})) {
        set_settings_subpage(window, SettingsSubpage::none);
        InvalidateRect(window, nullptr, FALSE);
        return;
    }
    if (settings_subpage_ == SettingsSubpage::privacy &&
        hit(x, y, RECT{left, s(250, dpi), left + s(180, dpi), s(284, dpi)})) {
        ShellExecuteW(
            window, L"open",
            L"https://github.com/JO-Beacon/JO-Launcher/blob/main/PRIVACY.md",
            nullptr, nullptr, SW_SHOWNORMAL);
    }
    return;
}

void App::click_versions(HWND window, int x, int y) {
    RECT client{};
    GetClientRect(window, &client);
    const int dpi = static_cast<int>(GetDpiForWindow(window));
    if (manage_rename_dialog_) return;
    if (manage_open_) {
        if (hit(x, y,
                RECT{static_cast<int>(client.right) - s(104, dpi), s(88, dpi),
                     static_cast<int>(client.right) - s(88, dpi),
                     s(104, dpi)})) {
            set_manage_open(window, false);
            scan();
            return;
        }
        if (hit(x, y,
                RECT{static_cast<int>(client.right) - s(48, dpi), s(88, dpi),
                     static_cast<int>(client.right) - s(32, dpi),
                     s(104, dpi)})) {
            scan();
            InvalidateRect(window, nullptr, FALSE);
            return;
        }
    } else {
        for (const UiHit& target : ui_hits_) {
            if (!hit(x, y + scroll_, target.rect)) continue;
            switch (target.action) {
            case 200:
                for (const auto& version : versions_) {
                    if (version.name == current_version_) {
                        ShellExecuteW(window, L"open", version.dir.c_str(),
                                      nullptr, nullptr, SW_SHOWNORMAL);
                        break;
                    }
                }
                return;
            case 210:
                begin_java_detection(window, true);
                InvalidateRect(window, nullptr, FALSE);
                return;
            case 201:
                manual_java_ = false;
                validate_manual_java(false);
                InvalidateRect(window, nullptr, FALSE);
                return;
            case 202:
                manual_java_ = true;
                focus_field_ = 0;
                validate_manual_java(false);
                InvalidateRect(window, nullptr, FALSE);
                return;
            case 203:
                focus_field_ = 0;
                InvalidateRect(window, nullptr, FALSE);
                return;
            case 205:
                focus_field_ = 1;
                InvalidateRect(window, nullptr, FALSE);
                return;
            case 206:
                focus_field_ = 2;
                InvalidateRect(window, nullptr, FALSE);
                return;
            case 207:
                focus_field_ = 3;
                InvalidateRect(window, nullptr, FALSE);
                return;
            case 208:
                InvalidateRect(window, nullptr, FALSE);
                return;
            case 209:
                save_version_config();
                InvalidateRect(window, nullptr, FALSE);
                return;
            default:
                break;
            }
        }
        if (hit(x, y,
                RECT{static_cast<int>(client.right) - s(48, dpi), s(88, dpi),
                     static_cast<int>(client.right) - s(32, dpi),
                     s(104, dpi)})) {
            set_manage_open(window, true);
            focus_field_ = -1;
            rename_text_ = widen(current_version_);
            manage_error_.clear();
            return;
        }
    }
}

void App::click_settings(HWND window, int x, int y) {
    y += scroll_;
    for (const UiHit& target : ui_hits_) {
        if (!hit(x, y, target.rect)) continue;
        switch (target.action) {
        case 100: {
            HMENU menu = CreatePopupMenu();
            if (menu == nullptr) return;
            for (int index = 0; index < 10; ++index) {
                const Language candidate = static_cast<Language>(index);
                UINT flags = MF_STRING;
                if (candidate == language_ && !follow_system_language_) {
                    flags |= MF_CHECKED;
                }
                AppendMenuW(menu, flags, static_cast<UINT_PTR>(index + 1),
                            language_name(candidate));
            }
            POINT point{};
            GetCursorPos(&point);
            const int command = TrackPopupMenu(
                menu, TPM_RETURNCMD | TPM_LEFTALIGN | TPM_TOPALIGN, point.x,
                point.y, 0, window, nullptr);
            DestroyMenu(menu);
            if (command > 0) {
                language_ = static_cast<Language>(command - 1);
                follow_system_language_ = false;
                global_settings_.language = language_code(language_);
                global_settings_.follow_system_language = false;
                jol::writeGlobalSettings(global_settings_);
                save_settings();
                InvalidateRect(window, nullptr, FALSE);
            }
            return;
        }
        case 107:
            follow_system_language_ = !follow_system_language_;
            if (follow_system_language_) {
                language_ = system_language();
            }
            global_settings_.language = language_code(language_);
            global_settings_.follow_system_language = follow_system_language_;
            jol::writeGlobalSettings(global_settings_);
            save_settings();
            InvalidateRect(window, nullptr, FALSE);
            return;
        case 101:
            follow_system_ = false;
            dark_mode_ = !dark_mode_;
            start_theme_animation(window, dark_mode_);
            save_settings();
            InvalidateRect(window, nullptr, FALSE);
            return;
        case 102:
            follow_system_ = !follow_system_;
            if (follow_system_) dark_mode_ = systemPrefersDark();
            start_theme_animation(window, dark_mode_);
            save_settings();
            InvalidateRect(window, nullptr, FALSE);
            return;
        case 103: {
            const auto chosen = chooseFolder(window, game_dir_);
            if (!chosen.empty()) {
                game_dir_ = chosen;
                scan();
                save_settings();
            }
            InvalidateRect(window, nullptr, FALSE);
            return;
        }
        case 110:
            if (has_account_) {
                if (MessageBoxW(window,
                                tr(language_, Text::deleteAccountMessage),
                                tr(language_, Text::deleteAccountTitle),
                                MB_YESNO | MB_ICONWARNING) == IDYES) {
                    account_store_.clear();
                    clear_account_tokens(account_);
                    account_ = {};
                    has_account_ = false;
                    account_expired_ = false;
                }
            }
            InvalidateRect(window, nullptr, FALSE);
            return;
        case 104:
            if (has_account_ && !account_expired_) {
                if (MessageBoxW(window, tr(language_, Text::signOutMessage),
                                tr(language_, Text::signOutTitle),
                                MB_YESNO | MB_ICONQUESTION) == IDYES) {
                    account_store_.clear();
                    clear_account_tokens(account_);
                    account_ = {};
                    has_account_ = false;
                }
            } else {
                begin_login(window);
            }
            InvalidateRect(window, nullptr, FALSE);
            return;
        case 105:
            set_settings_subpage(window, SettingsSubpage::privacy);
            InvalidateRect(window, nullptr, FALSE);
            return;
        case 106:
            set_settings_subpage(window, SettingsSubpage::licenses);
            InvalidateRect(window, nullptr, FALSE);
            return;
        case 111:
            focus_field_ = 6;
            InvalidateRect(window, nullptr, FALSE);
            return;
        case 109:
            export_logs(window);
            return;
        case 108: {
            auto directory = jol::log::file().parent_path();
            if (directory.empty()) {
                directory = jol::platform::local_app_data() / L"JO-Beacon" /
                            jol::kDataDirectoryName / L"logs";
            }
            ShellExecuteW(window, L"open", directory.c_str(), nullptr, nullptr,
                          SW_SHOWNORMAL);
            return;
        }
        default:
            break;
        }
    }
}

std::filesystem::path chooseSaveFile(HWND window,
                                     const std::wstring& default_name) {
    Microsoft::WRL::ComPtr<IFileSaveDialog> dialog;
    if (FAILED(CoCreateInstance(CLSID_FileSaveDialog, nullptr,
                                CLSCTX_INPROC_SERVER,
                                IID_PPV_ARGS(dialog.GetAddressOf())))) {
        return {};
    }
    const COMDLG_FILTERSPEC filter{L"Zip archive", L"*.zip"};
    dialog->SetFileTypes(1, &filter);
    dialog->SetDefaultExtension(L"zip");
    dialog->SetFileName(default_name.c_str());
    if (FAILED(dialog->Show(window))) return {};
    Microsoft::WRL::ComPtr<IShellItem> result;
    if (FAILED(dialog->GetResult(result.GetAddressOf()))) return {};
    PWSTR selected = nullptr;
    if (FAILED(result->GetDisplayName(SIGDN_FILESYSPATH, &selected))) return {};
    std::filesystem::path path(selected);
    CoTaskMemFree(selected);
    return path;
}

void App::export_logs(HWND window) {
    const auto log_path = jol::log::file();
    if (log_path.empty()) {
        MessageBoxW(window, tr(language_, Text::exportLogsFailed),
                    L"JO-Launcher", MB_OK | MB_ICONERROR);
        return;
    }

    SYSTEMTIME now{};
    GetLocalTime(&now);
    wchar_t name[64]{};
    swprintf_s(name, L"JO-Launcher-logs-%04u%02u%02u-%02u%02u%02u.zip",
               now.wYear, now.wMonth, now.wDay, now.wHour, now.wMinute,
               now.wSecond);
    const auto target = chooseSaveFile(window, name);
    if (target.empty()) return;

    mz_zip_archive zip{};
    const std::string target_text = jol::platform::path_to_utf8(target);
    bool ok = mz_zip_writer_init_file(&zip, target_text.c_str(), 0) != 0;
    const auto add_file = [&zip, &ok](const std::filesystem::path& file,
                                      const char* entry) {
        std::error_code ec;
        if (!std::filesystem::is_regular_file(file, ec)) return;
        const std::string text = jol::platform::path_to_utf8(file);
        ok = ok && mz_zip_writer_add_file(&zip, entry, text.c_str(), nullptr, 0,
                                          static_cast<mz_uint>(MZ_DEFAULT_COMPRESSION)) != 0;
    };
    if (ok) {
        add_file(log_path, "launcher.log");
        add_file(log_path.parent_path() / "launcher.1.log", "launcher.1.log");
        std::string info = "JO-Launcher 0.1.0\n";
        info += std::string("os: ") + jol::platform::os_name() + " " +
                jol::platform::os_arch() + "\n";
        info += "game dir: " + jol::platform::path_to_utf8(game_dir_) +
                "\n";
        info += "log file: " + jol::platform::path_to_utf8(log_path) +
                "\n";
        ok = ok && mz_zip_writer_add_mem(&zip, "system.txt", info.data(),
                                         info.size(),
                                         static_cast<mz_uint>(MZ_DEFAULT_COMPRESSION)) != 0;
        ok = ok && mz_zip_writer_finalize_archive(&zip) != 0;
    }
    mz_zip_writer_end(&zip);

    if (!ok) {
        std::error_code ec;
        std::filesystem::remove(target, ec);
        jol::log::error("logs", "export failed");
        MessageBoxW(window, tr(language_, Text::exportLogsFailed),
                    L"JO-Launcher", MB_OK | MB_ICONERROR);
        return;
    }

    jol::log::info("logs", "exported to " + target_text);
    const std::wstring message =
        std::wstring(tr(language_, Text::exportLogsDone)) + L"\n\n" +
        target.wstring();
    MessageBoxW(window, message.c_str(), L"JO-Launcher",
                MB_OK | MB_ICONINFORMATION);
}

void App::commit_manage_rename() {
    try {
        const std::string next = narrow(trim(rename_text_));
        renameVersion(game_dir_, manage_rename_target_, next);
        if (current_version_ == manage_rename_target_) {
            current_version_ = next;
        }
        scan();
        rename_text_ = widen(next);
        manage_error_.clear();
        save_settings();
        manage_rename_dialog_ = false;
        focus_field_ = -1;
    } catch (const std::exception& error) {
        manage_error_ = error.what();
    }
}

void App::click_version_manager(HWND window, int x, int y) {
    if (!manage_open_) return;
    RECT client{};
    GetClientRect(window, &client);
    const int dpi = static_cast<int>(GetDpiForWindow(window));
    const int left = contentLeft(rail_width_, dpi);
    const int right = contentRight(client, rail_width_, dpi);
    if (manage_rename_dialog_) {
        const int width = s(420, dpi);
        const int height = s(196, dpi);
        const int dialog_left = (static_cast<int>(client.right) - width) / 2;
        const int dialog_top = (static_cast<int>(client.bottom) - height) / 2;
        const int dialog_right = dialog_left + width;
        const int dialog_bottom = dialog_top + height;
        if (hit(x, y,
                RECT{dialog_left + s(24, dpi), dialog_top + s(60, dpi),
                     dialog_right - s(24, dpi), dialog_top + s(94, dpi)})) {
            focus_field_ = 4;
            InvalidateRect(window, nullptr, FALSE);
            return;
        }
        if (hit(x, y,
                RECT{dialog_right - s(188, dpi), dialog_bottom - s(52, dpi),
                     dialog_right - s(108, dpi), dialog_bottom - s(20, dpi)})) {
            manage_rename_dialog_ = false;
            focus_field_ = -1;
            InvalidateRect(window, nullptr, FALSE);
            return;
        }
        if (hit(x, y,
                RECT{dialog_right - s(96, dpi), dialog_bottom - s(52, dpi),
                     dialog_right - s(24, dpi), dialog_bottom - s(20, dpi)})) {
            commit_manage_rename();
            InvalidateRect(window, nullptr, FALSE);
            return;
        }
        return;
    }
    y += scroll_;
    if (!manage_import_busy_ &&
        hit(x, y, RECT{left, s(124, dpi), left + s(120, dpi), s(158, dpi)})) {
        const auto source = chooseFolder(window, game_dir_);
        if (!source.empty()) begin_manage_import(window, source, false);
        InvalidateRect(window, nullptr, FALSE);
        return;
    }
    if (!manage_import_busy_ && hit(x, y,
                                    RECT{left + s(132, dpi), s(124, dpi),
                                         left + s(232, dpi), s(158, dpi)})) {
        const auto archive = chooseZipFile(window, game_dir_, language_);
        if (!archive.empty()) begin_manage_import(window, archive, true);
        InvalidateRect(window, nullptr, FALSE);
        return;
    }
    int row_top = s(200, dpi);
    for (const auto& version : versions_) {
        const ui::ListCardLayout card =
            ui::list_card(left, right, row_top, dpi);
        if (hit(x, y, card.content)) {
            current_version_ = version.name;
            rename_text_ = widen(version.name);
            load_version_config();
            manage_error_.clear();
            InvalidateRect(window, nullptr, FALSE);
            return;
        }
        if (hit(x, y, card.primary_action)) {
            current_version_ = version.name;
            manage_rename_target_ = version.name;
            rename_text_ = widen(version.name);
            manage_rename_dialog_ = true;
            focus_field_ = 4;
            manage_error_.clear();
            InvalidateRect(window, nullptr, FALSE);
            return;
        }
        if (hit(x, y, card.secondary_action)) {
            const std::wstring message =
                std::wstring(tr(language_, Text::deleteAskPrefix)) +
                widen(version.name) + tr(language_, Text::deleteAskSuffix) +
                L"\n\n" + tr(language_, Text::deleteDetail);
            if (MessageBoxW(window, message.c_str(),
                            tr(language_, Text::deleteVersionTitle),
                            MB_YESNO | MB_ICONWARNING) == IDYES) {
                try {
                    deleteVersion(game_dir_, version.name);
                    if (current_version_ == version.name) {
                        current_version_.clear();
                    }
                    scan();
                    rename_text_ = widen(current_version_);
                    manage_error_.clear();
                    save_settings();
                } catch (const std::exception& error) {
                    manage_error_ = error.what();
                }
            }
            InvalidateRect(window, nullptr, FALSE);
            return;
        }
        row_top += ui::list_card_step(dpi);
    }
    return;
}

void App::click_launch(HWND window, int x, int y) {
    RECT client{};
    GetClientRect(window, &client);
    const int dpi = static_cast<int>(GetDpiForWindow(window));
    const int content_left = contentLeft(rail_width_, dpi);
    const int content_width =
        std::min(s(760, dpi),
                 static_cast<int>(client.right) - content_left - s(32, dpi));
    const int content_right = content_left + content_width;
    if (hit(x, y,
            RECT{static_cast<int>(client.right) - s(48, dpi), s(88, dpi),
                 static_cast<int>(client.right) - s(32, dpi), s(104, dpi)})) {
        scan();
        InvalidateRect(window, nullptr, FALSE);
        return;
    }

    // Same exception as paint_launch: geometry is duplicated here on
    // purpose until the Launch page redesign lands.
    y += scroll_;
    for (const UiHit& target : ui_hits_) {
        if (!hit(x, y, target.rect)) continue;
        if (target.action == 300) {
            game_log_dialog_ = true;
            InvalidateRect(window, nullptr, FALSE);
            return;
        }
        if (target.action == 301 && running_) {
            game_stopped_ = true;
            running_->stop();
            InvalidateRect(window, nullptr, FALSE);
            return;
        }
    }
    if (hit(x, y,
            RECT{content_right - s(96, dpi), s(144, dpi),
                 content_right - s(24, dpi), s(178, dpi)})) {
        show_versions_ = !show_versions_;
        hover_version_ = -1;
        InvalidateRect(window, nullptr, FALSE);
        return;
    }
    if (hit(x, y,
            RECT{content_right - s(128, dpi), s(208, dpi),
                 content_right - s(24, dpi), s(242, dpi)}) &&
        has_account_ && !account_expired_ && !launch_busy_) {
        begin_launch(window);
        InvalidateRect(window, nullptr, FALSE);
        return;
    }
    if (show_versions_) {
        const int row_height = s(54, dpi);
        const int list_top = s(300, dpi);
        for (size_t i = 0; i < versions_.size(); ++i) {
            const int row_top = list_top + static_cast<int>(i) * row_height;
            const RECT row{content_left, row_top, content_right,
                           row_top + row_height};
            if (!hit(x, y, row)) continue;
            current_version_ = versions_[i].name;
            show_versions_ = false;
            hover_version_ = -1;
            load_version_config();
            save_settings();
            InvalidateRect(window, nullptr, FALSE);
            return;
        }
    }
}

void App::mouseUp(HWND window) {
    if (!dragging_splitter_) return;
    dragging_splitter_ = false;
    ReleaseCapture();
    save_settings();
    InvalidateRect(window, nullptr, FALSE);
}

void App::doubleClick(HWND window, int x, int /*y*/) {
    RECT client{};
    GetClientRect(window, &client);
    const int dpi = static_cast<int>(GetDpiForWindow(window));
    const int rail_width = s(rail_width_, dpi);
    if (x >= rail_width && x < rail_width + s(10, dpi)) {
        rail_width_ = 232;
        save_settings();
        InvalidateRect(window, nullptr, FALSE);
    }
}

void App::mouseMove(HWND window, int x, int y) {
    RECT client{};
    GetClientRect(window, &client);
    const int dpi = static_cast<int>(GetDpiForWindow(window));
    const int rail_width = s(rail_width_, dpi);

    if (dragging_splitter_) {
        const double logical_delta =
            static_cast<double>(x - splitter_start_x_) * 96.0 / dpi;
        const double window_logical =
            static_cast<double>(client.right) * 96.0 / dpi;
        const int max_rail = std::clamp(
            static_cast<int>(window_logical) - 34 - 420, 200, 360);
        rail_width_ = std::clamp(
            splitter_start_width_ + static_cast<int>(logical_delta), 200,
            max_rail);
        SetCursor(LoadCursorW(nullptr, IDC_SIZEWE));
        InvalidateRect(window, nullptr, FALSE);
        return;
    }

    bool splitter = x >= rail_width && x < rail_width + s(10, dpi);
    SetCursor(LoadCursorW(nullptr, splitter ? IDC_SIZEWE : IDC_ARROW));

    int nav = -1;
    bool account = false;
    if (x < rail_width) {
        for (const NavEntry& entry : nav_entries(dpi)) {
            if (!hit(x, y, entry.rect)) continue;
            if (entry.page >= 0) {
                nav = entry.page;
            }
        }
        if (!has_account_ && y >= client.bottom - s(58, dpi)) {
            account = true;
        }
    }

    y += s(34, dpi);
    const int content_left = contentLeft(rail_width_, dpi);
    const int content_width = std::min(
        s(760, dpi),
        static_cast<int>(client.right) - content_left - s(32, dpi));
    const int content_right = content_left + content_width;
    int action = -1;
    int version = -1;
    if (page_ == Page::launch) {
        const int launch_y = y + scroll_;
        if (hit(x, launch_y, RECT{content_right - s(96, dpi), s(144, dpi),
                                  content_right - s(24, dpi), s(178, dpi)})) {
            action = 0;
        }
        if (show_versions_) {
            const int row_height = s(54, dpi);
            const int list_top = s(300, dpi);
            for (size_t i = 0; i < versions_.size(); ++i) {
                const int row_top = list_top + static_cast<int>(i) * row_height;
                if (hit(x, launch_y, RECT{content_left, row_top, content_right,
                                          row_top + row_height})) {
                    version = static_cast<int>(i);
                }
            }
        }
    } else if (page_ == Page::versions) {
        for (const UiHit& target : ui_hits_) {
            if (!hit(x, y + scroll_, target.rect)) continue;
            if (target.action == 209) action = 1;
            if (target.action == 200) action = 2;
            if (target.action == 208) action = 3;
            if (target.action == 210) action = 4;
        }
    }

    const bool category_changed = false;
    if (nav != hover_nav_ || action != hover_action_ ||
        version != hover_version_ || account != hover_account_ ||
        category_changed || splitter != hover_splitter_) {
        hover_nav_ = nav;
        hover_action_ = action;
        hover_version_ = version;
        hover_account_ = account;
        hover_splitter_ = splitter;
        InvalidateRect(window, nullptr, FALSE);
    }
}

void App::mouseLeave(HWND window) {
    if (dragging_splitter_) {
        dragging_splitter_ = false;
        ReleaseCapture();
        save_settings();
    }
    hover_nav_ = -1;
    hover_action_ = -1;
    hover_version_ = -1;
    hover_account_ = false;
    hover_splitter_ = false;
    SetCursor(LoadCursorW(nullptr, IDC_ARROW));
    InvalidateRect(window, nullptr, FALSE);
}


}  // namespace jol::win32
