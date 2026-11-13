#pragma once

#include <vector>

#include <d2d1.h>

#include "jo_draftui/canvas.hpp"
#include "jo_draftui/theme.hpp"

namespace jol::win32 {

class App;

/// Bridges the existing JOL Direct2D target into the JO-DraftUI Canvas API.
/// Coordinates are physical pixels; the supplied theme carries the DPI scale.
class DraftCanvas final : public jo::draftui::Canvas {
public:
    DraftCanvas(App& app, int dpi, jo::draftui::Theme theme);

    const jo::draftui::Theme& theme() const { return theme_; }

    void clear(jo::draftui::Color color) override;
    void fill_rect(const jo::draftui::Rect& rect,
                   jo::draftui::Color color) override;
    void fill_rounded_rect(const jo::draftui::Rect& rect, float radius,
                           jo::draftui::Color color) override;
    void stroke_rect(const jo::draftui::Rect& rect, jo::draftui::Color color,
                     float width) override;
    void stroke_rounded_rect(const jo::draftui::Rect& rect, float radius,
                             jo::draftui::Color color, float width) override;
    void draw_line(float x1, float y1, float x2, float y2,
                   jo::draftui::Color color, float width) override;
    void draw_text(const jo::draftui::Rect& rect, std::wstring_view text,
                   const jo::draftui::TextStyle& style) override;
    float measure_text(std::wstring_view text,
                       const jo::draftui::TextStyle& style) override;
    void push_clip(const jo::draftui::Rect& rect) override;
    void pop_clip() override;
    void push_translate(float x, float y) override;
    void pop_transform() override;

private:
    App& app_;
    int dpi_ = 96;
    jo::draftui::Theme theme_;
    std::vector<D2D1_MATRIX_3X2_F> transforms_;
};

}  // namespace jol::win32
