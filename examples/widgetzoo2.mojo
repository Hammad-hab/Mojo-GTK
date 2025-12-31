from gtk import *
from sys.ffi import CStringSlice
from memory import UnsafePointer

comptime ptr = LegacyUnsafePointer[NoneType]

@register_passable("trivial")
struct WidgetZoo2:
    @staticmethod
    fn on_link_clicked(button: ptr, gptr: ptr) -> Bool:
        print("Link button clicked!")
        return True
    
    @staticmethod
    fn on_menu_item_activated(item: ptr, gptr: ptr):
        print("Menu item activated!")
    
    @staticmethod
    fn on_text_changed(buffer: ptr, gptr: ptr):
        print("Text buffer changed!")

    @staticmethod
    fn create_section(title: String) -> ptr:
        try:
            var frame = gtk_frame_new(title)
            gtk_widget_add_css_class(frame, "widget-section")
            var box = gtk_box_new(1, 8)
            gtk_widget_set_margin_top(box, 12)
            gtk_widget_set_margin_bottom(box, 12)
            gtk_widget_set_margin_start(box, 12)
            gtk_widget_set_margin_end(box, 12)
            gtk_frame_set_child(frame, box)
            return box
        except:
            print("ERROR: create_section failed")
            return ptr()

    @staticmethod
    fn toggle_handler(button: ptr, user_data: ptr):
        try:
            var active = gtk_toggle_button_get_active(button)
            gtk_revealer_set_reveal_child(user_data, active)
        except:
            ...

    @staticmethod
    fn activate(app: ptr, gptr: ptr):
        try:
            # Window
            var win = gtk_application_window_new(app)
            gtk_window_set_title(win, "Mojo GTK4 Widget Zoo 2")
            gtk_window_set_default_size(win, 900, 700)

            # Two column layout
            var columns = gtk_box_new(0, 16)  # Horizontal box
            gtk_widget_set_margin_top(columns, 20)
            gtk_widget_set_margin_bottom(columns, 20)
            gtk_widget_set_margin_start(columns, 20)
            gtk_widget_set_margin_end(columns, 20)

            # Left column
            var left_col = gtk_box_new(1, 16)
            gtk_widget_set_hexpand(left_col, True)
            
            # Right column
            var right_col = gtk_box_new(1, 16)
            gtk_widget_set_hexpand(right_col, True)

            # ============ LEFT COLUMN ============
            
            # LINK BUTTONS
            var link_box = WidgetZoo2.create_section("Link Buttons")
            var link1 = gtk_link_button_new("https://www.gtk.org")
            gtk_button_set_label(link1, "GTK Website")
            var link2 = gtk_link_button_new_with_label("https://www.example.com", "Example.com")
            gtk_box_append(link_box, link1)
            gtk_box_append(link_box, link2)
            gtk_box_append(left_col, gtk_widget_get_parent(link_box))

            # MENU BUTTON
            var menu_box = WidgetZoo2.create_section("Menu Button")
            var menu = g_menu_new()
            g_menu_append(menu, "New", "app.new")
            g_menu_append(menu, "Open", "app.open")
            g_menu_append(menu, "Save", "app.save")
            var popover = gtk_popover_menu_new_from_model(menu)
            var menu_btn = gtk_menu_button_new()
            gtk_menu_button_set_label(menu_btn, "Menu")
            gtk_menu_button_set_popover(menu_btn, popover)
            gtk_box_append(menu_box, menu_btn)
            gtk_box_append(left_col, gtk_widget_get_parent(menu_box))

            # SEPARATORS
            var sep_box = WidgetZoo2.create_section("Separators")
            var h_sep = gtk_separator_new(0)
            var v_box = gtk_box_new(0, 8)
            var v_sep = gtk_separator_new(1)
            gtk_widget_set_size_request(v_sep, -1, 40)
            gtk_box_append(v_box, gtk_label_new("Left"))
            gtk_box_append(v_box, v_sep)
            gtk_box_append(v_box, gtk_label_new("Right"))
            gtk_box_append(sep_box, h_sep)
            gtk_box_append(sep_box, v_box)
            gtk_box_append(left_col, gtk_widget_get_parent(sep_box))

            # LEVEL BAR
            var level_box = WidgetZoo2.create_section("Level Bar")
            var level1 = gtk_level_bar_new()
            gtk_level_bar_set_min_value(level1, 0.0)
            gtk_level_bar_set_max_value(level1, 100.0)
            gtk_level_bar_set_value(level1, 75.0)
            gtk_box_append(level_box, gtk_label_new("Progress:"))
            gtk_box_append(level_box, level1)
            gtk_box_append(left_col, gtk_widget_get_parent(level_box))

            # COLOR & FONT BUTTONS
            var picker_box = WidgetZoo2.create_section("Pickers")
            var color_btn = gtk_color_button_new()
            var font_btn = gtk_font_button_new()
            gtk_font_chooser_set_font(font_btn, "Sans Bold 12")
            gtk_box_append(picker_box, gtk_label_new("Color:"))
            gtk_box_append(picker_box, color_btn)
            gtk_box_append(picker_box, gtk_label_new("Font:"))
            gtk_box_append(picker_box, font_btn)
            gtk_box_append(left_col, gtk_widget_get_parent(picker_box))

            # PASSWORD ENTRY
            var pwd_box = WidgetZoo2.create_section("Password Entry")
            var pwd = gtk_password_entry_new()
            gtk_password_entry_set_show_peek_icon(pwd, True)
            gtk_box_append(pwd_box, pwd)
            gtk_box_append(left_col, gtk_widget_get_parent(pwd_box))

            # ============ RIGHT COLUMN ============

            # TEXT VIEW
            var text_box = WidgetZoo2.create_section("Text View")
            var text_view = gtk_text_view_new()
            gtk_text_view_set_wrap_mode(text_view, 2)
            gtk_widget_set_size_request(text_view, -1, 80)
            var buffer = gtk_text_view_get_buffer(text_view)
            gtk_text_buffer_set_text(buffer, "Multiline text editor.\nEdit me!", -1)
            var sw = gtk_scrolled_window_new()
            gtk_scrolled_window_set_child(sw, text_view)
            gtk_scrolled_window_set_policy(sw, 1, 1)
            gtk_widget_set_size_request(sw, -1, 80)
            gtk_box_append(text_box, sw)
            gtk_box_append(right_col, gtk_widget_get_parent(text_box))

            # STACK & SWITCHER
            var stack_box = WidgetZoo2.create_section("Stack Switcher")
            var stack = gtk_stack_new()
            gtk_stack_set_transition_type(stack, 1)
            var page1 = gtk_label_new("Page 1 content")
            var page2 = gtk_label_new("Page 2 content")
            var page3 = gtk_label_new("Page 3 content")
            gtk_stack_add_titled(stack, page1, "page1", "First")
            gtk_stack_add_titled(stack, page2, "page2", "Second")
            gtk_stack_add_titled(stack, page3, "page3", "Third")
            var switcher = gtk_stack_switcher_new()
            gtk_stack_switcher_set_stack(switcher, stack)
            gtk_box_append(stack_box, switcher)
            gtk_box_append(stack_box, stack)
            gtk_box_append(right_col, gtk_widget_get_parent(stack_box))

            # REVEALER
            var reveal_box = WidgetZoo2.create_section("Revealer")
            var revealer = gtk_revealer_new()
            gtk_revealer_set_transition_type(revealer, 0)
            gtk_revealer_set_transition_duration(revealer, 300)
            var reveal_content = gtk_label_new("🎉 Revealed!")
            gtk_revealer_set_child(revealer, reveal_content)
            var reveal_toggle = gtk_toggle_button_new_with_label("Toggle")    
            
            _ = g_signal_connect_data(reveal_toggle, "toggled", rebind[ptr](WidgetZoo2.toggle_handler), revealer, None, 0)
            gtk_box_append(reveal_box, reveal_toggle)
            gtk_box_append(reveal_box, revealer)
            gtk_box_append(right_col, gtk_widget_get_parent(reveal_box))

            # ACTION BAR
            var action_box = WidgetZoo2.create_section("Action Bar")
            var action_bar = gtk_action_bar_new()
            var action_btn1 = gtk_button_new_with_label("Left")
            var action_btn2 = gtk_button_new_with_label("Right")
            gtk_action_bar_pack_start(action_bar, action_btn1)
            gtk_action_bar_pack_end(action_bar, action_btn2)
            gtk_box_append(action_box, action_bar)
            gtk_box_append(right_col, gtk_widget_get_parent(action_box))

            # INFOBAR
            var info_box = WidgetZoo2.create_section("InfoBar")
            var infobar = gtk_info_bar_new()
            gtk_info_bar_set_message_type(infobar, 0)
            gtk_info_bar_set_show_close_button(infobar, True)
            gtk_info_bar_add_child(infobar, gtk_label_new("This is some info"))
            gtk_box_append(info_box, infobar)
            gtk_box_append(right_col, gtk_widget_get_parent(info_box))

            # Add columns to main container
            gtk_box_append(columns, left_col)
            gtk_box_append(columns, right_col)

            # Scrolled window
            var scrolled = gtk_scrolled_window_new()
            gtk_scrolled_window_set_child(scrolled, columns)
            gtk_scrolled_window_set_policy(scrolled, 1, 1)

            gtk_window_set_child(win, scrolled)
            gtk_widget_show(win)

        except:
            print("ERROR: activation failed")

fn main() raises:
    var app = gtk_application_new("dev.mojo.gtkzoo2", 0)
    _ = g_signal_connect_data(app, "activate", rebind[ptr](WidgetZoo2.activate), ptr(), None, 0)
    _ = g_application_run(app, 0, ptr())