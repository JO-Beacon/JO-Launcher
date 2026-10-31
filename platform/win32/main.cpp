#include <windows.h>
#include <windowsx.h>
#include <dwmapi.h>

#include "app.hpp"
#include "product_info.hpp"
#include "log.hpp"
#include "platform/paths.hpp"
#include "auth/client_id.hpp"
#include "resource.h"

namespace {

jol::win32::App* g_app = nullptr;
bool g_sizing = false;
bool g_tracking_mouse = false;

constexpr UINT_PTR kResizeTimer = 1;
constexpr UINT kResizeFrameMs = 16;

#ifndef DWMWA_USE_IMMERSIVE_DARK_MODE
#define DWMWA_USE_IMMERSIVE_DARK_MODE 20
#endif
#ifndef DWMWA_BORDER_COLOR
#define DWMWA_BORDER_COLOR 34
#endif
#ifndef DWMWA_CAPTION_COLOR
#define DWMWA_CAPTION_COLOR 35
#endif
#ifndef DWMWA_TEXT_COLOR
#define DWMWA_TEXT_COLOR 36
#endif

void applyDarkFrame(HWND window) {
    const BOOL dark = TRUE;
    DwmSetWindowAttribute(window, DWMWA_USE_IMMERSIVE_DARK_MODE, &dark,
                          sizeof(dark));

    const COLORREF caption = RGB(0x0E, 0x0F, 0x12);
    const COLORREF border = RGB(0x26, 0x2A, 0x31);
    const COLORREF text = RGB(0xE6, 0xE3, 0xDC);
    DwmSetWindowAttribute(window, DWMWA_CAPTION_COLOR, &caption,
                          sizeof(caption));
    DwmSetWindowAttribute(window, DWMWA_BORDER_COLOR, &border, sizeof(border));
    DwmSetWindowAttribute(window, DWMWA_TEXT_COLOR, &text, sizeof(text));
}

LRESULT CALLBACK windowProc(HWND window, UINT message, WPARAM wparam,
                            LPARAM lparam) {
    switch (message) {
        case WM_ERASEBKGND:
            return 1;
        case WM_PAINT:
            if (g_app != nullptr) g_app->paint(window);
            return 0;
        case WM_LBUTTONDOWN:
            if (g_app != nullptr) {
                g_app->click(window, GET_X_LPARAM(lparam),
                             GET_Y_LPARAM(lparam));
            }
            return 0;
        case WM_LBUTTONUP:
            if (g_app != nullptr) g_app->mouseUp(window);
            return 0;
        case WM_LBUTTONDBLCLK:
            if (g_app != nullptr) {
                g_app->doubleClick(window, GET_X_LPARAM(lparam),
                                   GET_Y_LPARAM(lparam));
            }
            return 0;
        case WM_MOUSEMOVE:
            if (g_app != nullptr) {
                if (!g_tracking_mouse) {
                    TRACKMOUSEEVENT track{};
                    track.cbSize = sizeof(track);
                    track.dwFlags = TME_LEAVE;
                    track.hwndTrack = window;
                    TrackMouseEvent(&track);
                    g_tracking_mouse = true;
                }
                g_app->mouseMove(window, GET_X_LPARAM(lparam),
                                 GET_Y_LPARAM(lparam));
            }
            return 0;
        case WM_MOUSEWHEEL:
            if (g_app != nullptr) {
                g_app->wheel(window, GET_WHEEL_DELTA_WPARAM(wparam));
            }
            return 0;
        case WM_CHAR:
            if (g_app != nullptr) {
                g_app->key_char(window, static_cast<wchar_t>(wparam));
            }
            return 0;
        case WM_KEYDOWN:
            if (g_app != nullptr) {
                g_app->key_down(window, static_cast<int>(wparam));
            }
            return 0;
        case WM_APP + 1:
            if (g_app != nullptr) {
                g_app->handle_login_result(
                    reinterpret_cast<jol::win32::App::LoginResult*>(lparam));
                InvalidateRect(window, nullptr, FALSE);
            }
            return 0;
        case WM_APP + 2:
            if (g_app != nullptr) {
                g_app->handle_launch_result(
                    reinterpret_cast<jol::win32::App::LaunchResult*>(lparam));
                InvalidateRect(window, nullptr, FALSE);
            }
            return 0;
        case WM_APP + 3:
            if (g_app != nullptr) {
                g_app->handle_login_code(
                    window,
                    reinterpret_cast<jol::auth::DeviceCodeInfo*>(lparam));
                InvalidateRect(window, nullptr, FALSE);
            }
            return 0;
        case WM_APP + 4:
            if (g_app != nullptr) {
                g_app->handle_manage_import(
                    reinterpret_cast<jol::win32::App::ManageImportResult*>(
                        lparam));
                InvalidateRect(window, nullptr, FALSE);
            }
            return 0;
        case WM_APP + 5:
            if (g_app != nullptr) {
                g_app->handle_java_detection(
                    reinterpret_cast<jol::win32::App::JavaDetectResult*>(
                        lparam));
                InvalidateRect(window, nullptr, FALSE);
            }
            return 0;
        case WM_SIZE:
            if (g_app != nullptr) {
                g_app->resize(window);
                if (!g_sizing) InvalidateRect(window, nullptr, FALSE);
            }
            return 0;
        case WM_ENTERSIZEMOVE:
            g_sizing = true;
            SetTimer(window, kResizeTimer, kResizeFrameMs, nullptr);
            return 0;
        case WM_EXITSIZEMOVE:
            g_sizing = false;
            if (g_app != nullptr) g_app->capture_window_state(window);
            KillTimer(window, kResizeTimer);
            InvalidateRect(window, nullptr, FALSE);
            return 0;
        case WM_TIMER:
            if (wparam == kResizeTimer) {
                InvalidateRect(window, nullptr, FALSE);
                return 0;
            }
            if (wparam == 2 || wparam == 3) {
                return 0;
            }
            if (wparam == 6 && g_app != nullptr) {
                g_app->animate_transitions(window);
                return 0;
            }
            if (wparam == 4 && g_app != nullptr) {
                g_app->animate_theme(window);
                return 0;
            }
            if (wparam == 5 && g_app != nullptr) {
                g_app->poll_game(window);
                return 0;
            }
            break;
        case WM_MOUSELEAVE:
            g_tracking_mouse = false;
            if (g_app != nullptr) g_app->mouseLeave(window);
            return 0;
        case WM_GETMINMAXINFO: {
            auto* info = reinterpret_cast<MINMAXINFO*>(lparam);
            const UINT dpi = GetDpiForWindow(window);
            info->ptMinTrackSize.x = MulDiv(800, dpi, 96);
            info->ptMinTrackSize.y = MulDiv(600, dpi, 96);
            return 0;
        }
        case WM_CLOSE:
            if (g_app != nullptr) g_app->capture_window_state(window);
            DestroyWindow(window);
            return 0;
        case WM_DESTROY:
            PostQuitMessage(0);
            return 0;
        default:
            return DefWindowProcW(window, message, wparam, lparam);
    }
    return DefWindowProcW(window, message, wparam, lparam);
}

}  // namespace

LONG WINAPI unhandled_exception(EXCEPTION_POINTERS* info) {
    if (info != nullptr && info->ExceptionRecord != nullptr) {
        char text[128]{};
        std::snprintf(text, sizeof(text), "unhandled exception 0x%08lX at %p",
                      static_cast<unsigned long>(
                          info->ExceptionRecord->ExceptionCode),
                      info->ExceptionRecord->ExceptionAddress);
        jol::log::error("crash", text);
    }
    jol::log::shutdown();
    return EXCEPTION_CONTINUE_SEARCH;
}

int WINAPI wWinMain(HINSTANCE instance, HINSTANCE, PWSTR, int show_command) {
    jol::log::init(jol::platform::local_app_data() / L"JO-Beacon" /
                   jol::kDataDirectoryName / L"logs");
    jol::log::info("startup", "JO-Launcher 0.1.0");
    SetUnhandledExceptionFilter(unhandled_exception);
    CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
    SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);

    jol::win32::App app;
    g_app = &app;

    const wchar_t* class_name = L"JOLauncherNativeWindow";
    WNDCLASSEXW window_class{};
    window_class.cbSize = sizeof(window_class);
    window_class.style = CS_DBLCLKS;
    window_class.lpfnWndProc = windowProc;
    window_class.hInstance = instance;
    window_class.hCursor = LoadCursorW(nullptr, IDC_ARROW);
    window_class.hIcon = LoadIconW(instance, MAKEINTRESOURCEW(IDI_APP_ICON));
    window_class.hIconSm = LoadIconW(instance, MAKEINTRESOURCEW(IDI_APP_ICON));
    window_class.hbrBackground = nullptr;
    window_class.lpszClassName = class_name;

    if (RegisterClassExW(&window_class) == 0) return 1;

    RECT frame{0, 0, 1280, 720};
    AdjustWindowRectExForDpi(&frame, WS_OVERLAPPEDWINDOW, FALSE, 0,
                             GetDpiForSystem());

    HWND window = CreateWindowExW(
        0, class_name, jol::kProductName, WS_OVERLAPPEDWINDOW, CW_USEDEFAULT,
        CW_USEDEFAULT, frame.right - frame.left, frame.bottom - frame.top,
        nullptr, nullptr, instance, nullptr);
    if (window == nullptr) return 1;

    app.apply_window_theme(window);
    ShowWindow(window, show_command);
    app.apply_initial_window(window);
    UpdateWindow(window);
    // One background scan at startup; the version page reuses this result
    // until the user asks for a refresh.
    app.warm_java_cache(window);

    MSG message{};
    while (GetMessageW(&message, nullptr, 0, 0) > 0) {
        TranslateMessage(&message);
        DispatchMessageW(&message);
    }
    g_app = nullptr;
    CoUninitialize();
    return static_cast<int>(message.wParam);
}
