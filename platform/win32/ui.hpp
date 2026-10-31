#pragma once

#include <windows.h>

#include <vector>

namespace jol::win32::ui {

inline int px(int value, UINT dpi) {
    return MulDiv(value, static_cast<int>(dpi), 96);
}

// Shared geometry for a list card. All pages must use this instead of
// hand-positioning list items.
struct ListCardLayout {
    RECT card{};
    RECT content{};
    RECT primary_action{};
    RECT secondary_action{};
};

inline ListCardLayout list_card(int left, int right, int top, UINT dpi,
                                int action_count = 2) {
    ListCardLayout layout{};
    const int height = px(58, dpi);
    layout.card = RECT{left, top, right, top + height};
    layout.content = RECT{left + px(16, dpi), top,
                          right - px(250, dpi), top + height};
    if (action_count >= 2) {
        layout.primary_action =
            RECT{right - px(176, dpi), top + px(13, dpi),
                 right - px(104, dpi), top + px(43, dpi)};
        layout.secondary_action =
            RECT{right - px(96, dpi), top + px(13, dpi),
                 right - px(24, dpi), top + px(43, dpi)};
    }
    return layout;
}

inline int list_card_step(UINT dpi) {
    return px(66, dpi);
}

struct CardLayout {
    RECT card{};
    RECT content{};
};

inline CardLayout card(int left, int right, int top, int height, UINT dpi,
                       int padding = 24) {
    CardLayout layout{};
    layout.card = RECT{left, top, right, top + px(height, dpi)};
    layout.content = RECT{left + px(padding, dpi), top + px(padding, dpi),
                          right - px(padding, dpi),
                          top + px(height, dpi) - px(padding, dpi)};
    return layout;
}

// A section is a title outside a card, followed by rows separated by one
// pixel. Row height is explicit because some rows carry a hint and some do
// not; this mirrors the shared field layout.
struct FieldLayout {
    RECT row{};
    RECT label{};
    RECT hint{};
    RECT control{};
};

struct SectionLayout {
    RECT title{};
    RECT card{};
    std::vector<FieldLayout> fields;
};

inline SectionLayout section(int left, int right, int top, UINT dpi,
                             const std::vector<int>& row_heights,
                             int control_width = 0,
                             int control_height = 30) {
    SectionLayout layout{};
    layout.title = RECT{left, top, right, top + px(20, dpi)};
    const int card_top = top + px(22, dpi);
    int y = card_top;
    for (const int height : row_heights) {
        FieldLayout field{};
        field.row = RECT{left, y, right, y + px(height, dpi)};
        field.label = RECT{left + px(16, dpi), y + px(14, dpi),
                           right - px(16, dpi), y + px(38, dpi)};
        field.hint = RECT{left + px(16, dpi), y + px(34, dpi),
                          right - px(16, dpi), y + px(54, dpi)};
        if (control_width > 0) {
            field.control =
                RECT{right - px(16, dpi) - px(control_width, dpi),
                     y + (px(height, dpi) - px(control_height, dpi)) / 2,
                     right - px(16, dpi),
                     y + (px(height, dpi) + px(control_height, dpi)) / 2};
        }
        layout.fields.push_back(field);
        y += px(height, dpi);
    }
    layout.card = RECT{left, card_top, right, y};
    return layout;
}

inline SectionLayout section(int left, int right, int top, UINT dpi,
                             std::initializer_list<int> row_heights,
                             int control_width = 0,
                             int control_height = 30) {
    return section(left, right, top, dpi,
                   std::vector<int>(row_heights), control_width,
                   control_height);
}

inline int section_bottom(const SectionLayout& layout, UINT dpi) {
    return layout.card.bottom + px(24, dpi);
}

}  // namespace jol::win32::ui
