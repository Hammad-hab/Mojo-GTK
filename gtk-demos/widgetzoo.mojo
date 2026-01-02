from gtk import *
from sys.ffi import CStringSlice
from memory import UnsafePointer

comptime ptr = LegacyUnsafePointer[NoneType]

@register_passable("trivial")
struct WidgetDemo:
    @staticmethod
    fn on_button_clicked(button: ptr, gptr: ptr):
        print("Button clicked!")

    @staticmethod
    fn on_toggle_toggled(toggle: ptr, gptr: ptr):
        try:
            var active = gtk_toggle_button_get_active(toggle)
            print("Toggle state:", active)
        except:
            print("ERROR: toggle failed")
    
    @staticmethod
    fn on_scale_value_changed(scale: ptr, gptr: ptr):
        try:
            var value = gtk_range_get_value(scale)
            print("Scale value:", value)
        except:
            print("ERROR: scale failed")

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
    fn activate(app: ptr, gptr: ptr):
        try:
            # Window
            var win = gtk_application_window_new(app)
            gtk_window_set_title(win, "Mojo GTK4 Widget Demo")
            gtk_window_set_default_size(win, 600, 700)

            # Main container
            var main_box = gtk_box_new(1, 16)
            gtk_widget_set_margin_top(main_box, 20)
            gtk_widget_set_margin_bottom(main_box, 20)
            gtk_widget_set_margin_start(main_box, 20)
            gtk_widget_set_margin_end(main_box, 20)

            # ============ BUTTONS ============
            var buttons_box = WidgetDemo.create_section("Buttons")
            
            var btn_primary = gtk_button_new_with_label("Suggested Action")
            gtk_widget_add_css_class(btn_primary, "suggested-action")
            _ = g_signal_connect_data(btn_primary, "clicked", (WidgetDemo.on_button_clicked), ptr(), None, 0)
            
            var btn_destructive = gtk_button_new_with_label("Destructive Action")
            gtk_widget_add_css_class(btn_destructive, "destructive-action")
            
            var btn_flat = gtk_button_new_with_label("Flat Button")
            gtk_widget_add_css_class(btn_flat, "flat")
            
            var btn_row = gtk_box_new(0, 8)
            gtk_box_append(btn_row, btn_primary)
            gtk_box_append(btn_row, btn_destructive)
            gtk_box_append(btn_row, btn_flat)
            
            gtk_box_append(buttons_box, btn_row)
            gtk_box_append(main_box, gtk_widget_get_parent(buttons_box))

            # ============ TOGGLE CONTROLS ============
            var toggle_box = WidgetDemo.create_section("Toggle Controls")
            
            var toggle1 = gtk_toggle_button_new_with_label("Toggle Button")
            _ = g_signal_connect_data(toggle1, "toggled", (WidgetDemo.on_toggle_toggled), ptr(), None, 0)
            
            var check1 = gtk_check_button_new_with_label("Check Button")
            var check2 = gtk_check_button_new_with_label("Checked")
            gtk_check_button_set_active(check2, True)
            
            var switch_row = gtk_box_new(0, 8)
            var sw1 = gtk_switch_new()
            gtk_switch_set_active(sw1, True)
            gtk_box_append(switch_row, gtk_label_new("Switch:"))
            gtk_box_append(switch_row, sw1)
            
            gtk_box_append(toggle_box, toggle1)
            gtk_box_append(toggle_box, check1)
            gtk_box_append(toggle_box, check2)
            gtk_box_append(toggle_box, switch_row)
            
            gtk_box_append(main_box, gtk_widget_get_parent(toggle_box))

            # ============ TEXT INPUTS ============
            var text_box = WidgetDemo.create_section("Text Inputs")
            
            var entry1 = gtk_entry_new()
            gtk_entry_set_placeholder_text(entry1, "Standard Entry")
            
            var search = gtk_search_entry_new()
            gtk_entry_set_placeholder_text(search, "Search Entry")
            
            var spin_adj = gtk_adjustment_new(50.0, 0.0, 100.0, 1.0, 10.0, 0.0)
            var spin = gtk_spin_button_new(spin_adj, 1.0, 0)
            
            gtk_box_append(text_box, entry1)
            gtk_box_append(text_box, search)
            gtk_box_append(text_box, spin)
            
            gtk_box_append(main_box, gtk_widget_get_parent(text_box))

            # ============ SELECTION ============
            var select_box = WidgetDemo.create_section("Selection")
            
            var combo1 = gtk_combo_box_text_new()
            gtk_combo_box_text_append_text(combo1, "Option 1")
            gtk_combo_box_text_append_text(combo1, "Option 2")
            gtk_combo_box_text_append_text(combo1, "Option 3")
            gtk_combo_box_set_active(combo1, 0)
            
            gtk_box_append(select_box, combo1)
            gtk_box_append(main_box, gtk_widget_get_parent(select_box))

            # ============ SCALE ============
            var scale_box = WidgetDemo.create_section("Scale")
            
            var scale1_adj = gtk_adjustment_new(50.0, 0.0, 100.0, 1.0, 10.0, 0.0)
            var scale1 = gtk_scale_new(0, scale1_adj)
  
            gtk_range_set_increments(scale1, 1.0, 10.0)
            gtk_scale_set_draw_value(scale1, True)
            # _ = g_signal_connect_data(scale1, "value-changed", rebind[ptr](WidgetDemo.on_scale_value_changed), ptr(), None, 0)
            
            gtk_box_append(scale_box, scale1)
            gtk_box_append(main_box, gtk_widget_get_parent(scale_box))

            # ============ PROGRESS ============
            var progress_box = WidgetDemo.create_section("Progress")
            
            var progress1 = gtk_progress_bar_new()
            gtk_progress_bar_set_fraction(progress1, 0.65)
            gtk_progress_bar_set_show_text(progress1, True)
            
            var spinner = gtk_spinner_new()
            gtk_spinner_start(spinner)
            gtk_widget_set_size_request(spinner, 32, 32)
            
            var spinner_row = gtk_box_new(0, 12)
            gtk_box_append(spinner_row, gtk_label_new("Spinner:"))
            gtk_box_append(spinner_row, spinner)
            
            gtk_box_append(progress_box, progress1)
            gtk_box_append(progress_box, spinner_row)
            
            gtk_box_append(main_box, gtk_widget_get_parent(progress_box))

            # ============ ICONS ============
            var icon_box = WidgetDemo.create_section("Icons")
            
            var icon_row = gtk_box_new(0, 12)
            var icons = List[String]()
            icons.append("folder-symbolic")
            icons.append("document-open-symbolic")
            icons.append("edit-delete-symbolic")
            icons.append("starred-symbolic")
            
            for i in range(len(icons)):
                var img = gtk_image_new_from_icon_name(icons[i])
                gtk_image_set_pixel_size(img, 32)
                gtk_box_append(icon_row, img)
            
            gtk_box_append(icon_box, icon_row)
            gtk_box_append(main_box, gtk_widget_get_parent(icon_box))

            # ============ CONTAINERS ============
            var container_box = WidgetDemo.create_section("Containers")
            
            var expander = gtk_expander_new("Expandable Section")
            var exp_content = gtk_label_new("Hidden content revealed!")
            gtk_expander_set_child(expander, exp_content)
            
            gtk_box_append(container_box, expander)
            gtk_box_append(main_box, gtk_widget_get_parent(container_box))

            # Scrolled window
            var scrolled = gtk_scrolled_window_new()
            gtk_scrolled_window_set_child(scrolled, main_box)
            gtk_scrolled_window_set_policy(scrolled, 1, 1)

            gtk_window_set_child(win, scrolled)
            gtk_widget_show(win)

        except:
            print("ERROR: activation failed")

fn main() raises:
    var app = gtk_application_new("dev.mojo.gtkdemo", 0)
    _ = g_signal_connect_data(app, "activate", (WidgetDemo.activate), ptr(), None, 0)
    _ = g_application_run(app, 0, ptr())