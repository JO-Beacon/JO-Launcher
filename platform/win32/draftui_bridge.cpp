#include "draftui_bridge.hpp"

#include <algorithm>
#include <cwchar>

#include "app.hpp"

namespace jol::win32 {
namespace {

COLORREF to_colorref(jo::draftui::Color color) {
    const auto channel = [](float value) {
        return static_cast<BYTE>(std::clamp(value, 0.0f, 1.0f) * 255.0f);
    };
    return RGB(channel(color.r), channel(color.g), channel(color.b));
}

D2D1_COLOR_F to_d2d(jo::draftui::Color color) {
    return D2D1::ColorF(color.r, color.g, color.b, color.a);
}

DWRITE_FONT_WEIGHT to_weight(jo::draftui::FontWeight weight) {
    switch (weight) {
        case jo::draftui::FontWeight::semi_bold:
            return DWRITE_FONT_WEIGHT_SEMI_BOLD;
        case jo::draftui::FontWeight::bold:
            return DWRITE_FONT_WEIGHT_BOLD;
        default:
            return DWRITE_FONT_WEIGHT_NORMAL;
    }
}

DWRITE_TEXT_ALIGNMENT to_alignment(jo::draftui::TextAlign align) {
    switch (align) {
        case jo::draftui::TextAlign::center:
            return DWRITE_TEXT_ALIGNMENT_CENTER;
        case jo::draftui::TextAlign::trailing:
            return DWRITE_TEXT_ALIGNMENT_TRAILING;
        default:
            return DWRITE_TEXT_ALIGNMENT_LEADING;
    }
}

}  // namespace

DraftCanvas::DraftCanvas(App& app, int dpi, jo::draftui::Theme theme)
    : app_(app), dpi_(dpi), theme_(std::move(theme)) {}

void DraftCanvas::clear(jo::draftui::Color color) {
    if (app_.target_ != nullptr) app_.target_->Clear(to_d2d(color));
}

void DraftCanvas::fill_rect(const jo::draftui::Rect& rect,
                            jo::draftui::Color color) {
    if (app_.target_ == nullptr) return;
    if (color.a < 1.0f) {
        app_.fill_rect_alpha(
            D2D1::RectF(rect.left, rect.top, rect.right, rect.bottom),
            to_colorref(color), color.a);
    } else {
        app_.fill_rect(
            D2D1::RectF(rect.left, rect.top, rect.right, rect.bottom),
            to_colorref(color));
    }
}

void DraftCanvas::fill_rounded_rect(const jo::draftui::Rect& rect, float,
                                    jo::draftui::Color color) {
    fill_rect(rect, color);
}

void DraftCanvas::stroke_rect(const jo::draftui::Rect& rect,
                              jo::draftui::Color color, float width) {
    if (app_.target_ == nullptr || app_.brush_ == nullptr) return;
    app_.brush_->SetColor(to_d2d(color));
    app_.target_->DrawRectangle(
        D2D1::RectF(rect.left, rect.top, rect.right, rect.bottom),
        app_.brush_.Get(), width);
}

void DraftCanvas::stroke_rounded_rect(const jo::draftui::Rect& rect, float,
                                      jo::draftui::Color color, float width) {
    stroke_rect(rect, color, width);
}

void DraftCanvas::draw_line(float x1, float y1, float x2, float y2,
                            jo::draftui::Color color, float width) {
    if (app_.target_ == nullptr || app_.brush_ == nullptr) return;
    app_.brush_->SetColor(to_d2d(color));
    app_.target_->DrawLine(D2D1::Point2F(x1, y1), D2D1::Point2F(x2, y2),
                          app_.brush_.Get(), width);
}

void DraftCanvas::draw_text(const jo::draftui::Rect& rect,
                            std::wstring_view text,
                            const jo::draftui::TextStyle& style) {
    if (text.empty()) return;
    if (style.family == jo::draftui::FontFamily::icon && text.size() == 1) {
        app_.draw_icon(
            static_cast<int>(text.front()),
            D2D1::RectF(rect.left, rect.top, rect.right, rect.bottom),
            static_cast<int>(style.size), to_colorref(style.color));
        return;
    }
    app_.draw_text(std::wstring(text),
                   D2D1::RectF(rect.left, rect.top, rect.right, rect.bottom),
                   static_cast<int>(style.size), to_colorref(style.color),
                   to_weight(style.weight), to_alignment(style.align),
                   style.wrap);
}

float DraftCanvas::measure_text(std::wstring_view text,
                                const jo::draftui::TextStyle& style) {
    if (app_.dwrite_ == nullptr || text.empty()) return 0.0f;
    const wchar_t* family = app_.text_font_collection_ != nullptr
                                ? L"Noto Sans SC"
                                : L"Segoe UI";
    Microsoft::WRL::ComPtr<IDWriteTextFormat> format;
    if (FAILED(app_.dwrite_->CreateTextFormat(
            family, app_.text_font_collection_.Get(), to_weight(style.weight),
            DWRITE_FONT_STYLE_NORMAL, DWRITE_FONT_STRETCH_NORMAL, style.size,
            L"", format.GetAddressOf()))) {
        return 0.0f;
    }
    format->SetWordWrapping(DWRITE_WORD_WRAPPING_NO_WRAP);
    Microsoft::WRL::ComPtr<IDWriteTextLayout> layout;
    if (FAILED(app_.dwrite_->CreateTextLayout(
            text.data(), static_cast<UINT32>(text.size()), format.Get(),
            100000.0f, style.size * 2.0f, layout.GetAddressOf()))) {
        return 0.0f;
    }
    DWRITE_TEXT_METRICS metrics{};
    if (FAILED(layout->GetMetrics(&metrics))) return 0.0f;
    return metrics.widthIncludingTrailingWhitespace;
}

void DraftCanvas::push_clip(const jo::draftui::Rect& rect) {
    if (app_.target_ == nullptr) return;
    app_.target_->PushAxisAlignedClip(
        D2D1::RectF(rect.left, rect.top, rect.right, rect.bottom),
        D2D1_ANTIALIAS_MODE_PER_PRIMITIVE);
}

void DraftCanvas::pop_clip() {
    if (app_.target_ != nullptr) app_.target_->PopAxisAlignedClip();
}

void DraftCanvas::push_translate(float x, float y) {
    if (app_.target_ == nullptr) return;
    D2D1_MATRIX_3X2_F transform{};
    app_.target_->GetTransform(&transform);
    transforms_.push_back(transform);
    app_.target_->SetTransform(D2D1::Matrix3x2F::Translation(x, y) * transform);
}

void DraftCanvas::pop_transform() {
    if (app_.target_ == nullptr || transforms_.empty()) return;
    app_.target_->SetTransform(transforms_.back());
    transforms_.pop_back();
}

}  // namespace jol::win32
