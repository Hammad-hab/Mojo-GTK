from gtk import *
from sys.ffi import CStringSlice
from memory import UnsafePointer

comptime ptr = LegacyUnsafePointer[NoneType]

@register_passable("trivial")
struct AppData:
    var win: ptr
    var result_label: ptr

    fn __init__(out self, win: ptr, result_label: ptr):
        self.win = win
        self.result_label = result_label

comptime AppDataPointer = LegacyUnsafePointer[AppData]

@register_passable("trivial")
struct DialogDemos:

    @staticmethod
    fn set_result(data_ptr: AppDataPointer, text: String):
        try:
            gtk_label_set_text(data_ptr[].result_label, text)
        except:
            pass

    # ==================== Dialog Handlers (unchanged logic, just cleaner messages) ====================

    @staticmethod
    fn show_file_open(button: ptr, user_data: ptr):
        try:
            var app = rebind[AppDataPointer](user_data)
            var dialog = gtk_file_dialog_new()
            gtk_file_dialog_set_title(dialog, "Open File")
            gtk_file_dialog_set_modal(dialog, True)
            gtk_file_dialog_open(dialog, app[].win, ptr(), rebind[ptr](DialogDemos.on_file_open_finish), user_data)
        except:
            DialogDemos.set_result(rebind[AppDataPointer](user_data), "⚠️ Failed to launch Open File dialog")

    @staticmethod
    fn on_file_open_finish(source: ptr, res: ptr, user_data: ptr):
        try:
            var data_ptr = rebind[AppDataPointer](user_data)
            var file = gtk_file_dialog_open_finish(source, res)
            if file:
                var path = g_file_get_path(file)
                if path:
                    var path_str = String(CStringSlice(unsafe_from_ptr=path))
                    DialogDemos.set_result(data_ptr, "<b>📂 File Opened</b>\n<span font_family='monospace'>" + path_str + "</span>")
                else:
                    DialogDemos.set_result(data_ptr, "<b>📂 File Opened</b>\n<i>(Remote or virtual file)</i>")
            else:
                DialogDemos.set_result(data_ptr, "❌ Operation cancelled")
        except:
            DialogDemos.set_result(rebind[AppDataPointer](user_data), "⚠️ Error reading file")

    @staticmethod
    fn show_file_save(button: ptr, user_data: ptr):
        try:
            var app = rebind[AppDataPointer](user_data)
            var dialog = gtk_file_dialog_new()
            gtk_file_dialog_set_title(dialog, "Save File")
            gtk_file_dialog_set_modal(dialog, True)
            gtk_file_dialog_save(dialog, app[].win, ptr(), rebind[ptr](DialogDemos.on_file_save_finish), user_data)
        except:
            DialogDemos.set_result(rebind[AppDataPointer](user_data), "⚠️ Failed to launch Save dialog")

    @staticmethod
    fn on_file_save_finish(source: ptr, res: ptr, user_data: ptr):
        try:
            var data_ptr = rebind[AppDataPointer](user_data)
            var file = gtk_file_dialog_save_finish(source, res)
            if file:
                var path = g_file_get_path(file)
                if path:
                    var path_str = String(CStringSlice(unsafe_from_ptr=path))
                    DialogDemos.set_result(data_ptr, "<b>💾 Save Location</b>\n<span font_family='monospace'>" + path_str + "</span>")
                else:
                    DialogDemos.set_result(data_ptr, "<b>💾 Save Location</b>\n<i>(Remote location selected)</i>")
            else:
                DialogDemos.set_result(data_ptr, "❌ Operation cancelled")
        except:
            DialogDemos.set_result(rebind[AppDataPointer](user_data), "⚠️ Error processing save")

    @staticmethod
    fn show_select_folder(button: ptr, user_data: ptr):
        try:
            var app = rebind[AppDataPointer](user_data)
            var dialog = gtk_file_dialog_new()
            gtk_file_dialog_set_title(dialog, "Select Folder")
            gtk_file_dialog_set_modal(dialog, True)
            gtk_file_dialog_select_folder(dialog, app[].win, ptr(), rebind[ptr](DialogDemos.on_select_folder_finish), user_data)
        except:
            DialogDemos.set_result(rebind[AppDataPointer](user_data), "⚠️ Failed to launch folder dialog")

    @staticmethod
    fn on_select_folder_finish(source: ptr, res: ptr, user_data: ptr):
        try:
            var data_ptr = rebind[AppDataPointer](user_data)
            var file = gtk_file_dialog_select_folder_finish(source, res)
            if file:
                var path = g_file_get_path(file)
                if path:
                    var path_str = String(CStringSlice(unsafe_from_ptr=path))
                    DialogDemos.set_result(data_ptr, "<b>📁 Folder Selected</b>\n<span font_family='monospace'>" + path_str + "</span>")
                else:
                    DialogDemos.set_result(data_ptr, "<b>📁 Folder Selected</b>\n<i>(Remote folder)</i>")
            else:
                DialogDemos.set_result(data_ptr, "❌ Operation cancelled")
        except:
            DialogDemos.set_result(rebind[AppDataPointer](user_data), "⚠️ Error selecting folder")

    @staticmethod
    fn show_open_multiple(button: ptr, user_data: ptr):
        try:
            var app = rebind[AppDataPointer](user_data)
            var dialog = gtk_file_dialog_new()
            gtk_file_dialog_set_title(dialog, "Open Multiple Files")
            gtk_file_dialog_set_modal(dialog, True)
            gtk_file_dialog_open_multiple(dialog, app[].win, ptr(), rebind[ptr](DialogDemos.on_open_multiple_finish), user_data)
        except:
            DialogDemos.set_result(rebind[AppDataPointer](user_data), "⚠️ Failed to launch multiple dialog")

    @staticmethod
    fn on_open_multiple_finish(source: ptr, res: ptr, user_data: ptr):
        try:
            var data_ptr = rebind[AppDataPointer](user_data)
            var list = gtk_file_dialog_open_multiple_finish(source, res)
            if list:
                var model = rebind[ptr](list)
                var n = g_list_model_get_n_items(model)
                if n == 0:
                    DialogDemos.set_result(data_ptr, "⚠️ No files selected")
                else:
                    var result = "<b>📄 Selected " + String(n) + " file(s)</b>\n\n"
                    for i in range(n):
                        var item = g_list_model_get_object(model, i)
                        if item:
                            var path = g_file_get_path(item)
                            if path:
                                result += "• <span font_family='monospace'>" + String(CStringSlice(unsafe_from_ptr=path)) + "</span>\n"
                    DialogDemos.set_result(data_ptr, result)
            else:
                DialogDemos.set_result(data_ptr, "❌ Operation cancelled")
        except:
            DialogDemos.set_result(rebind[AppDataPointer](user_data), "⚠️ Error reading files")

    @staticmethod
    fn show_about(button: ptr, user_data: ptr):
        try:
            var app = rebind[AppDataPointer](user_data)
            var about = gtk_about_dialog_new()
            gtk_about_dialog_set_program_name(about, "Mojo GTK4 Dialog Demos")
            gtk_about_dialog_set_version(about, "1.0")
            gtk_about_dialog_set_comments(about, "Mojo GTK Bindings Dialog demo")
            gtk_window_set_transient_for(about, app[].win)
            gtk_window_set_modal(about, True)
            gtk_widget_show(about)
        except:
            DialogDemos.set_result(rebind[AppDataPointer](user_data), "⚠️ Could not show About dialog")

@register_passable("trivial")
struct MainApp:
    @staticmethod
    fn activate(app: ptr, gptr: ptr):
        try:
            var win = gtk_application_window_new(app)
            gtk_window_set_title(win, "Mojo GTK4 Dialog Demos")
            gtk_window_set_default_size(win, 960, 720)
            gtk_widget_add_css_class(win, "background")  # for light/dark theme support

            # === HeaderBar ===
        
            var title = gtk_label_new("Modern GTK4 File Dialogs Demo")
            gtk_label_set_use_markup(title, True)
            gtk_label_set_justify(title, 2)  # CENTER


            # === Main Layout ===
            var main_box = gtk_box_new(1, 0)
            gtk_widget_set_margin_top(main_box, 20)
            gtk_widget_set_margin_bottom(main_box, 40)
            gtk_widget_set_margin_start(main_box, 40)
            gtk_widget_set_margin_end(main_box, 40)

            # === Button Grid in a Card ===
            var button_card = gtk_frame_new("")
            gtk_widget_add_css_class(button_card, "card")
            gtk_widget_set_margin_bottom(button_card, 30)

            var grid_box = gtk_box_new(1, 20)
            gtk_widget_set_margin_top(grid_box, 30)
            gtk_widget_set_margin_bottom(grid_box, 30)
            gtk_widget_set_margin_start(grid_box, 40)
            gtk_widget_set_margin_end(grid_box, 40)

            var grid = gtk_grid_new()
            gtk_grid_set_row_spacing(grid, 20)
            gtk_grid_set_column_spacing(grid, 20)
            gtk_grid_set_column_homogeneous(grid, True)

            gtk_box_append(grid_box, grid)
            gtk_frame_set_child(button_card, grid_box)

            # === Result Card ===
            var result_label = gtk_label_new("👆 Click any button above to explore GTK4 dialogs\nResults will appear here in beautiful markup ✨")
            gtk_label_set_use_markup(result_label, True)
            gtk_label_set_selectable(result_label, True)
            gtk_label_set_wrap(result_label, True)
            gtk_label_set_wrap_mode(result_label, 1)
            gtk_label_set_xalign(result_label, 0)
            gtk_label_set_lines(result_label, 12)
            gtk_widget_set_margin_top(result_label, 24)
            gtk_widget_set_margin_bottom(result_label, 24)
            gtk_widget_set_margin_start(result_label, 32)
            gtk_widget_set_margin_end(result_label, 32)
            gtk_widget_add_css_class(result_label, "body")
            gtk_widget_add_css_class(result_label, "monospace")

            var result_card = gtk_frame_new("")
            gtk_widget_add_css_class(result_card, "card")
            gtk_widget_add_css_class(result_card, "view")
            gtk_widget_set_vexpand(result_card, True)
            gtk_frame_set_child(result_card, result_label)

            # === Shared Data ===
            var data = AppData(win, result_label)
            var data_ptr = AppDataPointer.alloc(1)
            data_ptr[] = data

            # === Beautiful Buttons ===
            var buttons = [
                ("📂 Open File", DialogDemos.show_file_open, "suggested-action"),
                ("💾 Save File", DialogDemos.show_file_save, "suggested-action"),
                ("📁 Select Folder", DialogDemos.show_select_folder, "pill-button"),
                ("📄 Open Multiple Files", DialogDemos.show_open_multiple, "pill-button"),
                ("ℹ️ About This App", DialogDemos.show_about, "flat"),
            ]

            var col = 0
            var row = 0
            for i in range(len(buttons)):
                var (label_text, handler, style) = buttons[i]
                var btn = gtk_button_new_with_label(label_text)
                gtk_widget_add_css_class(btn, "pill-button")
                gtk_widget_add_css_class(btn, "large-button")
                gtk_widget_add_css_class(btn, "font-weight-600")
                if style != "":
                    gtk_widget_add_css_class(btn, style)
                _ = g_signal_connect_data(btn, "clicked", rebind[ptr](handler), rebind[ptr](data_ptr), None, 0)
                gtk_grid_attach(grid, btn, col, row, 1, 1)
                col += 1
                if col >= 3:
                    col = 0
                    row += 1

            # === Assemble UI ===
            gtk_box_append(main_box, button_card)
            gtk_box_append(main_box, result_card)

            # Wrap in scrolled window for very tall content
            var scrolled = gtk_scrolled_window_new()
            gtk_scrolled_window_set_policy(scrolled, 0, 1)
            gtk_scrolled_window_set_child(scrolled, main_box)
            gtk_widget_set_vexpand(scrolled, True)

            gtk_window_set_child(win, scrolled)
            gtk_widget_show(win)

        except e:
            print("ERROR: Failed to create UI:", e)

fn main() raises:
    var app = gtk_application_new("dev.mojo.gtkdialogs.beautiful", 0)
    _ = g_signal_connect_data(app, "activate", rebind[ptr](MainApp.activate), ptr(), None, 0)
    _ = g_application_run(app, 0, ptr())