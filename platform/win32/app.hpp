#pragma once

#include <windows.h>
#include <d2d1.h>
#include <dwrite.h>
#include <dwrite_3.h>
#include <wrl/client.h>

#include <atomic>
#include <filesystem>
#include <functional>
#include <map>
#include <mutex>
#include <set>
#include <memory>
#include <string>
#include <thread>
#include <utility>
#include <vector>

#include "auth/account_store.hpp"
#include "l10n.hpp"
#include "mc/version.hpp"
#include "mc/version_config.hpp"
#include "global_settings_store.hpp"
#include "settings_store.hpp"
#include "launch/launch.hpp"
#include "secure_wipe.hpp"

namespace jol::launch {
class GameProcess;
}

namespace jol::win32 {

struct Palette {
    COLORREF bg;
    COLORREF surface;
    COLORREF border;
    COLORREF text;
    COLORREF secondary;
    COLORREF accent;
    COLORREF hover;
};

class App {
public:
    App();
    ~App();

    void paint(HWND window);
    void resize(HWND window);
    void click(HWND window, int x, int y);
    void mouseMove(HWND window, int x, int y);
    void mouseLeave(HWND window);
    void key_char(HWND window, wchar_t character);
    void key_down(HWND window, int key);
    void ime_start(HWND window);
    void ime_composition(HWND window, LPARAM flags);
    void ime_end(HWND window);
    void mouseUp(HWND window);
    void rightClick(HWND window, int x, int y);
    void middleDown(HWND window, int x, int y);
    void middleUp(HWND window);
    void autoscrollTick(HWND window);
    void wheel(HWND window, int delta);
    void apply_initial_window(HWND window);
    void capture_window_state(HWND window);
    void doubleClick(HWND window, int x, int y);
    void animate_theme(HWND window);
    void animate_transitions(HWND window);
    void poll_game(HWND window);
    void apply_window_theme(HWND window);
    /// Warm the Java runtime cache in the background (called once at startup).
    void warm_java_cache(HWND window);

    struct LoginResult {
        bool ok = false;
        jol::auth::Account account;
        std::string error;
        std::string error_key;
        std::uint64_t generation = 0;

        ~LoginResult() {
            jol::secure::clear_string(account.access_token);
            jol::secure::clear_string(account.refresh_token);
        }
    };

    struct LaunchResult {
        bool ok = false;
        std::string error;
        jol::launch::GameProcess* process = nullptr;
        HWND window = nullptr;
        bool auth_expired = false;
        bool java_missing = false;
        std::vector<jol::launch::JavaRuntime> runtimes;
        std::string error_key;
        bool files_missing = false;
        std::size_t missing_count = 0;
        std::string missing_sample;
        jol::auth::Account account;
        bool account_refreshed = false;

        ~LaunchResult() {
            delete process;
            process = nullptr;
            jol::secure::clear_string(account.access_token);
            jol::secure::clear_string(account.refresh_token);
        }
    };

    struct JavaDetectResult {
        std::vector<jol::launch::JavaRuntime> runtimes;
    };


    struct ManageImportResult {
        bool ok = false;
        std::string name;
        std::string error;
    };


    void handle_login_result(LoginResult* result);
    void handle_launch_result(LaunchResult* result);
    void handle_manage_import(ManageImportResult* result);
    void handle_java_detection(JavaDetectResult* result);
    void handle_login_code(HWND window, jol::auth::DeviceCodeInfo* code);

private:
    template <typename T>
    using ComPtr = Microsoft::WRL::ComPtr<T>;

    enum class Page {
        launch,
        versions,
        settings,
        manage
    };
    enum class SettingsSubpage { none, privacy, licenses };

    struct VersionRow {
        std::filesystem::path dir;
        std::string name;
        std::string game_version;
        std::string loader;
        std::string loader_version;
    };

    struct FadeState {
        bool active = false;
        float progress = 1.0f;
        ULONGLONG started = 0;
        int from = 0;
        int to = 0;
    };

    Page page_ = Page::launch;
    SettingsSubpage settings_subpage_ = SettingsSubpage::none;
    FadeState page_fade_;
    FadeState manage_fade_;
    FadeState settings_fade_;
    bool manage_open_ = false;
    std::filesystem::path game_dir_;
    std::vector<VersionRow> versions_;
    std::vector<std::string> broken_versions_;
    std::string current_version_;
    bool show_versions_ = false;
    int hover_nav_ = -1;
    bool hover_account_ = false;
    int hover_action_ = -1;
    int hover_version_ = -1;
    jol::auth::AccountStore account_store_;
    jol::auth::Account account_;
    bool has_account_ = false;
    bool account_expired_ = false;
    bool login_busy_ = false;
    bool login_dialog_ = false;
    bool privacy_dialog_ = false;
    bool privacy_view_only_ = false;
    jol::GlobalSettings global_settings_;
    std::string login_error_;
    std::string login_code_;
    std::string login_uri_;
    std::string login_notice_;
    std::atomic_bool login_cancel_{false};
    std::uint64_t login_generation_ = 0;
    std::atomic_bool launch_cancel_{false};
    std::atomic_bool java_cancel_{false};
    std::atomic_bool import_cancel_{false};
    std::thread login_thread_;
    bool launch_busy_ = false;
    std::string launch_error_;
    std::thread launch_thread_;
    std::unique_ptr<jol::launch::GameProcess> running_;
    std::string running_version_;
    std::string game_log_;
    bool game_log_dialog_ = false;
    bool game_stopped_ = false;
    int game_exit_code_ = 0;
    bool java_prompt_ = false;
    bool pending_launch_ = false;
    std::vector<jol::launch::JavaRuntime> java_runtimes_;
    int java_required_ = 0;
    bool java_detecting_ = false;
    /// True once a scan has completed; the version page then reads the cache.
    bool java_scanned_ = false;
    std::wstring java_auto_status_;
    std::wstring java_manual_status_;
    bool java_manual_ok_ = false;
    std::thread java_thread_;
    jol::VersionConfig config_;
    bool manual_java_ = false;
    int focus_field_ = -1;
    std::wstring java_text_;
    std::wstring client_id_text_;
    std::wstring min_memory_text_;
    std::wstring max_memory_text_;
    std::wstring jvm_text_;
    std::string config_error_;
    bool config_saved_ = false;
    std::wstring rename_text_;
    bool manage_rename_dialog_ = false;
    std::string manage_rename_target_;
    std::string manage_error_;
    std::wstring manage_notice_;
    bool manage_import_busy_ = false;
    std::thread manage_import_thread_;

    struct InputState {
        std::size_t caret = 0;
        std::size_t anchor = 0;
        float scroll = 0.0f;
    };
    std::map<int, InputState> input_states_;
    std::map<int, RECT> input_rects_;
    int input_drag_id_ = -1;

    Microsoft::WRL::ComPtr<IDWriteTextLayout> make_input_layout(
        const std::wstring& text, int dpi) const;
    std::wstring* input_text(int field_id);
    InputState& input_state(int field_id);
    void reset_input(int field_id);
    void focus_input(HWND window, int field_id, bool select_all = false);
    bool input_char(HWND window, int field_id, wchar_t character);
    bool input_key(HWND window, int field_id, int key);
    bool input_insert(HWND window, int field_id, const std::wstring& value);
    bool input_mouse(HWND window, int field_id, int x, int y, bool extend);
    int input_at(int x, int y) const;
    std::size_t input_index_at(int field_id, int x, int dpi);
    void input_select_word(HWND window, int field_id, std::size_t index);
    bool input_has_selection(int field_id) const;
    void input_copy(int field_id);
    void input_cut(HWND window, int field_id);
    void input_select_all(HWND window, int field_id);
    void input_after_change(HWND window, int field_id);
    void input_set_caret(HWND window, int field_id, std::size_t caret,
                         bool extend);
    void update_ime_position(HWND window);
    std::wstring clipboard_text() const;
    bool set_clipboard_text(const std::wstring& text) const;
    bool dark_mode_ = true;
    bool follow_system_ = false;
    Language language_ = Language::en;
    bool follow_system_language_ = false;
    int rail_width_ = 232;
    jol::WindowState window_state_;
    bool window_state_applied_ = false;
    bool hover_splitter_ = false;
    bool dragging_splitter_ = false;
    int splitter_start_x_ = 0;
    int splitter_start_width_ = 232;
    int scroll_ = 0;
    int scroll_max_ = 0;
    int scroll_view_top_ = -1;
    RECT scrollbar_track_{};
    RECT scrollbar_thumb_{};
    bool scrollbar_hover_ = false;
    bool scrollbar_dragging_ = false;
    int scrollbar_drag_offset_ = 0;
    bool autoscroll_active_ = false;
    POINT autoscroll_origin_{};
    float autoscroll_velocity_ = 0.0f;
    float autoscroll_accum_ = 0.0f;
    ULONGLONG autoscroll_last_tick_ = 0;
    int autoscroll_mode_ = 0;
    bool autoscroll_middle_down_ = false;
    D2D1_MATRIX_3X2_F scroll_saved_transform_{};
    bool theme_animating_ = false;
    float theme_progress_ = 1.0f;
    ULONGLONG theme_started_ = 0;
    Palette theme_from_{};
    Palette theme_to_{};

    ComPtr<ID2D1Factory> d2d_;
    ComPtr<IDWriteFactory> dwrite_;
    ComPtr<ID2D1HwndRenderTarget> target_;
    ComPtr<ID2D1Layer> layer_;
    ComPtr<ID2D1SolidColorBrush> brush_;
    ComPtr<IDWriteFontCollection> icon_font_collection_;
    ComPtr<IDWriteInMemoryFontFileLoader> icon_font_loader_;
    ComPtr<IDWriteFontCollection> text_font_collection_;
    ComPtr<IDWriteInMemoryFontFileLoader> text_font_loader_;
    ComPtr<IDWriteFontFallback> text_font_fallback_;
    ComPtr<IDWriteFontCollection> system_font_collection_;
    std::map<std::tuple<int, int, bool>, ComPtr<IDWriteTextFormat>>
        text_formats_;
    std::map<int, ComPtr<IDWriteTextFormat>> icon_formats_;

    struct UiField {
        std::wstring label;
        std::wstring hint;
        int height = 42;
        int control_width = 0;
        int control_height = 30;
        bool full_width = false;
        int action = -1;
        std::function<void(const RECT&)> paint;
    };

    struct UiSection {
        std::wstring title;
        std::vector<UiField> fields;
    };

    struct UiHit {
        RECT rect{};
        int action = -1;
    };

    std::vector<UiHit> ui_hits_;

    static UiField make_field(std::wstring label, std::wstring hint,
                              int height, int control_width, bool full_width,
                              int action,
                              std::function<void(const RECT&)> paint);

    /// Posts a heap payload to the window; drops it when the window is gone.
    /// Dim overlay + centred panel shared by every dialog.
    struct DialogFrame {
        int left = 0;
        int top = 0;
        int right = 0;
        int bottom = 0;
    };
    static DialogFrame dialog_rect(const RECT& client, int dpi, int width,
                                   int height);
    DialogFrame begin_dialog(const RECT& client, int dpi, int width,
                             int height);

    template <typename T>
    static void post_event(HWND window, UINT message, T* payload) {
        remember_payload(payload);
        if (PostMessage(window, message, 0,
                        reinterpret_cast<LPARAM>(payload)) == FALSE) {
            forget_payload(payload);
            delete payload;
        }
    }

    static void remember_payload(void* payload);
    static void forget_payload(void* payload);
    static bool accept_payload(void* payload);

    static std::mutex payload_mutex_;
    static std::set<void*> pending_payloads_;

    void paint_sections(int left, int right, int& y, int dpi,
                        const std::vector<UiSection>& sections);

    void scan();
    bool ensure_target(HWND window);
    void release_target();
    void paint_rail(const RECT& client, int dpi);
    void paint_splitter(const RECT& client, int dpi);
    void paint_launch(const RECT& client, int dpi);
    void paint_versions(const RECT& client, int dpi);
    void paint_settings(const RECT& client, int dpi);
    void paint_settings_subpage(const RECT& client, int dpi,
                               SettingsSubpage page);
    void paint_manage(const RECT& client, int dpi);
    void paint_scrollbar(const RECT& client, int dpi);
    void paint_button(int x, int y, int width, int height,
                      const wchar_t* label, bool primary, bool enabled,
                      bool hovered, int dpi);
    void paint_input(int x, int y, int width, int height,
                     const std::wstring& text, bool focused, int dpi,
                     int field_id);
    void change_page(HWND window, int page_index);
    void paint_nav(int index, const wchar_t* label, int x, int y, int width,
                   int height, bool selected, bool hovered, int dpi);

    struct NavEntry {
        int page = -1;
        int category = -1;
        RECT rect{};
    };
    std::vector<NavEntry> nav_entries(int dpi) const;
    void paint_nav_category(const NavEntry& entry, int dpi);
    void begin_scroll(const RECT& client, int dpi, int top = -1);
    void end_scroll();
    void set_scroll_extent(int content_bottom, const RECT& client, int dpi);
    bool scrollbar_press(HWND window, int x, int y);
    void scrollbar_drag(HWND window, int y);
    void autoscrollMove(HWND window, int y);
    void autoscrollAdvance();
    void stopAutoscroll(HWND window);
    HCURSOR autoscrollCursor() const;
    void start_theme_animation(HWND window, bool dark);
    void fill_rect(const D2D1_RECT_F& rect, COLORREF color);
    void fill_rect_alpha(const D2D1_RECT_F& rect, COLORREF color,
                         float alpha);
    void draw_panel(const D2D1_RECT_F& rect);
    void draw_text(const std::wstring& text, const D2D1_RECT_F& rect,
                   int size, COLORREF color, DWRITE_FONT_WEIGHT weight,
                   DWRITE_TEXT_ALIGNMENT alignment, bool wrap = false);
    void draw_icon(int glyph, const D2D1_RECT_F& rect, int size,
                   COLORREF color);
    void load_icon_font();
    void load_text_font();
    std::string client_id() const;
    void begin_login(HWND window);
    void begin_launch(HWND window);
    void begin_manage_import(HWND window, const std::filesystem::path& source,
                            bool zip);
    void begin_java_detection(HWND window, bool force = false);
    void refresh_java_status();
    void validate_manual_java(bool probe);
    void commit_client_id();
    void click_launch(HWND window, int x, int y);
    void click_versions(HWND window, int x, int y);
    void click_version_manager(HWND window, int x, int y);
    void commit_manage_rename();
    void export_logs(HWND window);
    void click_settings(HWND window, int x, int y);
    void click_settings_subpage(HWND window, int x, int y);
    void paint_login_dialog(const RECT& client, int dpi);
    void paint_privacy_dialog(const RECT& client, int dpi);
    void paint_game_log(const RECT& client, int dpi);
    void paint_java_prompt(const RECT& client, int dpi);
    void choose_java_executable(HWND window);
    void cancel_login(HWND window);
    void set_manage_open(HWND window, bool open);
    void set_settings_subpage(HWND window, SettingsSubpage page);
    void start_fade(FadeState& state, int from, int to, HWND window);
    void load_version_config();
    void save_version_config();
    void save_settings();
};

}  // namespace jol::win32
