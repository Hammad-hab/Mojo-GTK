# Uses Deprecated gtk4 dialog system, may or may not work
from gtk import *
from sys.ffi import CStringSlice
from memory import UnsafePointer, alloc

comptime ptr = LegacyUnsafePointer[NoneType]

@register_passable("trivial")
struct FileOpenData:
    var win: ptr
    var result_label: ptr
    var dialog: ptr

    fn __init__(out self, win: ptr, result_label: ptr):
        self.win = win
        self.result_label = result_label
        var dialogint8 = LegacyUnsafePointer[Int8].alloc(1)
        self.dialog = rebind[ptr](dialogint8)

comptime FileOpenDataPointer = LegacyUnsafePointer[FileOpenData]

@register_passable("trivial")
struct FileSaveData:
    var win: ptr
    var result_label: ptr
    var dialog: ptr

    fn __init__(out self, win: ptr, result_label: ptr):
        self.win = win
        self.result_label = result_label
        self.dialog = ptr()

comptime FileSaveDataPointer = LegacyUnsafePointer[FileSaveData]

@register_passable("trivial")
struct FolderData:
    var win: ptr
    var result_label: ptr
    var dialog: ptr

    fn __init__(out self, win: ptr, result_label: ptr):
        self.win = win
        self.result_label = result_label
        self.dialog = ptr()

comptime FolderDataPointer = LegacyUnsafePointer[FolderData]

@register_passable("trivial")
struct ColorData:
    var win: ptr
    var result_label: ptr
    var dialog: ptr

    fn __init__(out self, win: ptr, result_label: ptr):
        self.win = win
        self.result_label = result_label
        self.dialog = ptr()

comptime ColorDataPointer = LegacyUnsafePointer[ColorData]

@register_passable("trivial")
struct FontData:
    var win: ptr
    var result_label: ptr
    var dialog: ptr

    fn __init__(out self, win: ptr, result_label: ptr):
        self.win = win
        self.result_label = result_label
        self.dialog = ptr()

comptime FontDataPointer = LegacyUnsafePointer[FontData]

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
    
    # File Chooser - Open File
    @staticmethod
    fn show_file_open(button: ptr, user_data: ptr):
        try:
            var app = rebind[FileOpenDataPointer](user_data)

            var file_data = FileOpenData(app[].win, app[].result_label)
            var file_data_ptr = FileOpenDataPointer.alloc(1)
            file_data_ptr[] = file_data

            var dialog = gtk_file_chooser_native_new(
                "Open File",
                app[].win,
                0,   # OPEN
                "_Open",
                "_Cancel"
            )
            # file_data_ptr[].dialog = dialog
            # app[].dialog = dialog

            _ = g_signal_connect_data(
                dialog,
                "response",
                rebind[ptr](DialogDemos.on_file_open_response),
                user_data,
                None,
                0
            )

            gtk_native_dialog_show(dialog)
        except:
            pass


    @staticmethod
    @export("on_file_open_response", ABI="C")
    fn on_file_open_response(native: ptr, response_id: Int32, dialog: ptr):
        try:
            # print("=== FILE OPEN RESPONSE ===")
            # print("Native pointer:", native)
            var data_ptr = rebind[FileOpenDataPointer](native)
            # native[] = dialog[]
            # var int8native_ptr = LegacyUnsafePointer[Int8].alloc(128)
            # var native_ptr = rebind[ptr](int8native_ptr)
            # native_ptr[] = data_ptr[].dialog
            # var native_ptr_native =  rebind[FileOpenDataPointer](int8native_ptr)
            # print("Stored dialog pointer:", data_ptr[].dialog)
            
            if response_id == -3:  # GTK_RESPONSE_ACCEPT
                # print("Getting file from dialog...")
                var file = gtk_file_chooser_get_file(dialog)
                # print("Got file:", file)
                var path = g_file_get_path(file)
                
                if path:
                    var path_str = ""
                    var path_cslice = CStringSlice(unsafe_from_ptr=path)
                    path_cslice.write_to(path_str)

                    with open(path_str, 'r') as f:
                        var content = f.read()
                        var result_text = content
                        print(result_text)
                        gtk_label_set_text(data_ptr[].result_label, result_text)
                        print("Selected file:", path_str)
            # else:
            #     gtk_label_set_text(data_ptr[].result_label, "❌ File selection cancelled")
            
            # g_object_unref(native)
            # Don't free data_ptr yet - let it leak for now to test
            # data_ptr.free()
        except e:
            print("Error in file open response:", e)
    
    # File Chooser - Save File
    @staticmethod
    fn show_file_save(button: ptr, user_data: ptr):
        try:
            var app_data_ptr = rebind[FileSaveDataPointer](user_data)
            
            # var file_data = FileSaveData(app_data_ptr[].win, app_data_ptr[].result_label)
            # var file_data_ptr = FileSaveDataPointer.alloc(1)
            # file_data_ptr[] = file_data
            
            var dialog = gtk_file_chooser_native_new(
                "Save File", 
                app_data_ptr[].win, 
                1,  # GTK_FILE_CHOOSER_ACTION_SAVE
                "_Save", 
                "_Cancel"
            )
            
            gtk_file_chooser_set_current_name(dialog, "untitled.txt")
            
            app_data_ptr[].dialog = dialog
            _ = g_signal_connect_data(
                dialog, 
                "response", 
                rebind[ptr](DialogDemos.on_file_save_response), 
                user_data,
                None, 
                0
            )
            
            gtk_native_dialog_show(dialog)
        except e:
            print("Error showing file save dialog:", e)
    
    @staticmethod
    fn on_file_save_response(native: ptr, response_id: Int32, user_data: ptr):
        try:
            var data_ptr = rebind[FileSaveDataPointer](user_data)
            
            if response_id == -3:  # GTK_RESPONSE_ACCEPT
                var file = gtk_file_chooser_get_file(data_ptr[].dialog)
                var path = g_file_get_path(file)
                
                if path:
                    var path_str = ""
                    var path_cslice = CStringSlice(unsafe_from_ptr=path)
                    path_cslice.write_to(path_str)
                    
                    var result_text = "💾 Save location:\n" + path_str
                    gtk_label_set_text(data_ptr[].result_label, result_text)
                    print("Save to:", path_str)
            else:
                gtk_label_set_text(data_ptr[].result_label, "❌ Save cancelled")
            
            g_object_unref(native)
            # Don't free data_ptr yet - let it leak for now to test
            # data_ptr.free()
        except e:
            print("Error in file save response:", e)
    
    # Folder Chooser
    @staticmethod
    fn show_folder_chooser(button: ptr, user_data: ptr):
        try:
            var app_data_ptr = rebind[AppDataPointer](user_data)
            
            var folder_data = FolderData(app_data_ptr[].win, app_data_ptr[].result_label)
            var folder_data_ptr = FolderDataPointer.alloc(1)

            folder_data_ptr[] = folder_data
            
            print("Creating file open dialog...")
            var dialog = gtk_file_chooser_native_new(
                "Select Folder", 
                folder_data_ptr[].win, 
                2,  # GTK_FILE_CHOOSER_ACTION_SELECT_FOLDER
                "_Select", 
                "_Cancel"
            )
            
            print("Dialog pointer:", dialog)

            folder_data_ptr[].dialog = dialog
            print("Stored in file_data_ptr[].dialog:", folder_data_ptr[].dialog)
            _ = g_signal_connect_data(
                dialog, 
                "response", 
                rebind[ptr](DialogDemos.on_folder_response), 
                rebind[ptr](folder_data_ptr),
                None, 
                0
            )
            
            gtk_native_dialog_show(dialog)
        except e:
            print("Error showing folder chooser:", e)
    
    @staticmethod
    fn on_folder_response(native: ptr, response_id: Int32, user_data: ptr):
        try:
            var data_ptr = rebind[FolderDataPointer](user_data)
            
            if response_id == -3:  # GTK_RESPONSE_ACCEPT
                var file = gtk_file_chooser_get_file(data_ptr[].dialog)
                var path = g_file_get_path(file)
                
                if path:
                    var path_str = ""
                    var path_cslice = CStringSlice(unsafe_from_ptr=path)
                    path_cslice.write_to(path_str)
                    
                    var result_text = "📁 Folder selected:\n" + path_str
                    gtk_label_set_text(data_ptr[].result_label, result_text)
                    print("Selected folder:", path_str)
                else:
                    gtk_label_set_text(data_ptr[].result_label, "❌ Could not get folder path")
            else:
                gtk_label_set_text(data_ptr[].result_label, "❌ Folder selection cancelled")
            
            g_object_unref(native)
            # Don't free data_ptr yet - let it leak for now to test
            # data_ptr.free()
        except e:
            print("Error in folder response:", e)
    
    # Color Chooser
    @staticmethod
    fn show_color_chooser(button: ptr, user_data: ptr):
        try:
            var app_data_ptr = rebind[AppDataPointer](user_data)
            
            var color_data = ColorData(app_data_ptr[].win, app_data_ptr[].result_label)
            var color_data_ptr = ColorDataPointer.alloc(1)
            color_data_ptr[] = color_data
            
            var dialog = gtk_color_chooser_dialog_new(
                "Choose a Color",
                color_data_ptr[].win
            )
            
            gtk_window_set_modal(dialog, True)
            
            color_data_ptr[].dialog = dialog
            _ = g_signal_connect_data(
                dialog, 
                "response", 
                rebind[ptr](DialogDemos.on_color_response), 
                rebind[ptr](color_data_ptr),
                None, 
                0
            )
            
            gtk_widget_show(dialog)
        except e:
            print("Error showing color chooser:", e)
    
    @staticmethod
    fn on_color_response(dialog: ptr, response_id: Int32, user_data: ptr):
        try:
            var data_ptr = rebind[ColorDataPointer](user_data)
            
            if response_id == -5:  # GTK_RESPONSE_OK
                var rgba_ptr = LegacyUnsafePointer[GTKRGBA].alloc(1)
                gtk_color_chooser_get_rgba(dialog, rgba_ptr)
                
                var rgba_doubles =  rgba_ptr[]
                var r = Int(rgba_doubles.red * 255)
                var g = Int(rgba_doubles.blue * 255)
                var b = Int(rgba_doubles.green * 255)
                var a = 1
                
                var result_text = "🎨 Color selected:\nRGB(" + String(r) + ", " + String(g) + ", " + String(b) + ")\nAlpha: " + String(a)
                gtk_label_set_text(data_ptr[].result_label, result_text)
                print("Selected color: RGB(", r, ",", g, ",", b, ") Alpha:", a)
                
                rgba_ptr.free()
            else:
                gtk_label_set_text(data_ptr[].result_label, "❌ Color selection cancelled")
            
            gtk_window_destroy(dialog)
            # Don't free data_ptr yet - let it leak for now to test
            # data_ptr.free()
        except e:
            print("Error in color response:", e)
    
    # Font Chooser
    @staticmethod
    fn show_font_chooser(button: ptr, user_data: ptr):
        try:
            var app_data_ptr = rebind[AppDataPointer](user_data)
            
            var font_data = FontData(app_data_ptr[].win, app_data_ptr[].result_label)
            var font_data_ptr = FontDataPointer.alloc(1)
            font_data_ptr[] = font_data
            
            var dialog = gtk_font_chooser_dialog_new(
                "Choose a Font",
                font_data_ptr[].win
            )
            
            gtk_window_set_modal(dialog, True)
            
            font_data_ptr[].dialog = dialog
            _ = g_signal_connect_data(
                dialog, 
                "response", 
                rebind[ptr](DialogDemos.on_font_response), 
                rebind[ptr](font_data_ptr),
                None, 
                0
            )
            
            gtk_widget_show(dialog)
        except e:
            print("Error showing font chooser:", e)
    
    @staticmethod
    fn on_font_response(dialog: ptr, response_id: Int32, user_data: ptr):
        try:
            var data_ptr = rebind[FontDataPointer](user_data)
            
            if response_id == -5:  # GTK_RESPONSE_OK
                var font_ptr = gtk_font_chooser_get_font(dialog)
                
                if font_ptr:
                    var font_str = ""
                    var font_cslice = CStringSlice(unsafe_from_ptr=font_ptr)
                    font_cslice.write_to(font_str)
                    
                    var result_text = "🔤 Font selected:\n" + font_str
                    gtk_label_set_text(data_ptr[].result_label, result_text)
                    print("Selected font:", font_str)
            else:
                gtk_label_set_text(data_ptr[].result_label, "❌ Font selection cancelled")
            
            gtk_window_destroy(dialog)
            # Don't free data_ptr yet - let it leak for now to test
            # data_ptr.free()
        except e:
            print("Error in font response:", e)

    @staticmethod
    fn activate(app: ptr, gptr: ptr):
        try:
            # Create main window
            var win = gtk_application_window_new(app)
            gtk_window_set_title(win, "GTK4 Dialog Demos")
            gtk_window_set_default_size(win, 700, 550)

            # Apply CSS
            var css_provider = gtk_css_provider_new()
            gtk_css_provider_load_from_string(css_provider, """
                window {
                    background: #f5f5f5;
                }
                
                .header {
                    background: linear-gradient(to bottom, #4a90e2, #357abd);
                    color: white;
                    padding: 25px;
                }
                
                .header-title {
                    font-size: 28px;
                    font-weight: bold;
                    color: white;
                }
                
                .header-subtitle {
                    font-size: 14px;
                    color: rgba(255, 255, 255, 0.9);
                    margin-top: 5px;
                }
                
                .content-box {
                    padding: 25px;
                }
                
                .button-grid {
                    padding: 10px;
                }
                
                .demo-button {
                    padding: 15px 20px;
                    font-size: 14px;
                    border-radius: 8px;
                    background: white;
                    border: 2px solid #ddd;
                    min-height: 50px;
                }
                
                .demo-button:hover {
                    background: #4a90e2;
                    color: white;
                    border-color: #357abd;
                }
                
                .result-box {
                    background: white;
                    border: 2px solid #ddd;
                    border-radius: 8px;
                    padding: 20px;
                    min-height: 120px;
                }
                
                .result-label {
                    font-size: 13px;
                    color: #333;
                }
            """)
            
            gtk_style_context_add_provider_for_display(
                gtk_widget_get_display(win),
                css_provider,
                800
            )

            # Main container
            var main_box = gtk_box_new(1, 0)
            
            # Header
            var header = gtk_box_new(1, 5)
            gtk_widget_add_css_class(header, "header")
            
            var title = gtk_label_new("📋 Native Dialog Demonstrations")
            gtk_widget_add_css_class(title, "header-title")
            gtk_widget_set_halign(title, 1)
            
            var subtitle = gtk_label_new("Click buttons to explore different native system dialogs")
            gtk_widget_add_css_class(subtitle, "header-subtitle")
            gtk_widget_set_halign(subtitle, 1)
            
            gtk_box_append(header, title)
            gtk_box_append(header, subtitle)
            
            # Content area
            var content = gtk_box_new(1, 20)
            gtk_widget_add_css_class(content, "content-box")
            
            # Button grid
            var grid = gtk_grid_new()
            gtk_widget_add_css_class(grid, "button-grid")
            gtk_grid_set_row_spacing(grid, 12)
            gtk_grid_set_column_spacing(grid, 12)
            gtk_grid_set_column_homogeneous(grid, True)
            
            # Result label
            var result_label = gtk_label_new("👆 Click any button above to test dialogs\nResults will appear here")
            gtk_widget_add_css_class(result_label, "result-label")
            gtk_label_set_justify(result_label, 2)
            
            var result_box = gtk_box_new(1, 0)
            gtk_widget_add_css_class(result_box, "result-box")
            gtk_box_append(result_box, result_label)
            
            # Create app data (shared across all dialogs)
            var data = AppData(win, result_label)
            var data_ptr = AppDataPointer.alloc(1)
            data_ptr[] = data
            
            # Create buttons
            var file_data = FileOpenData(win, result_label)
            var file_data_ptr = FileOpenDataPointer.alloc(1)
            file_data_ptr[] = file_data

            var btn_file_open = gtk_button_new_with_label("📂 Open File")
            gtk_widget_add_css_class(btn_file_open, "demo-button")
            _ = g_signal_connect_data(btn_file_open, "clicked", rebind[ptr](DialogDemos.show_file_open), rebind[ptr](file_data_ptr), None, 0)
            
            var btn_file_save = gtk_button_new_with_label("💾 Save File")
            gtk_widget_add_css_class(btn_file_save, "demo-button")
            _ = g_signal_connect_data(btn_file_save, "clicked", rebind[ptr](DialogDemos.show_file_save), rebind[ptr](data_ptr), None, 0)
            
            var btn_folder = gtk_button_new_with_label("📁 Select Folder")
            gtk_widget_add_css_class(btn_folder, "demo-button")
            _ = g_signal_connect_data(btn_folder, "clicked", rebind[ptr](DialogDemos.show_folder_chooser), rebind[ptr](data_ptr), None, 0)
            
            var btn_color = gtk_button_new_with_label("🎨 Choose Color")
            gtk_widget_add_css_class(btn_color, "demo-button")
            _ = g_signal_connect_data(btn_color, "clicked", rebind[ptr](DialogDemos.show_color_chooser), rebind[ptr](data_ptr), None, 0)
            
            var btn_font = gtk_button_new_with_label("🔤 Choose Font")
            gtk_widget_add_css_class(btn_font, "demo-button")
            _ = g_signal_connect_data(btn_font, "clicked", rebind[ptr](DialogDemos.show_font_chooser), rebind[ptr](data_ptr), None, 0)
            
            # Add buttons to grid (2 columns)
            gtk_grid_attach(grid, btn_file_open, 0, 0, 1, 1)
            gtk_grid_attach(grid, btn_file_save, 1, 0, 1, 1)
            gtk_grid_attach(grid, btn_folder, 0, 1, 1, 1)
            gtk_grid_attach(grid, btn_color, 1, 1, 1, 1)
            gtk_grid_attach(grid, btn_font, 0, 2, 2, 1)
            
            # Assemble UI
            gtk_box_append(content, grid)
            gtk_box_append(content, result_box)
            
            gtk_box_append(main_box, header)
            gtk_box_append(main_box, content)
            
            gtk_window_set_child(win, main_box)
            gtk_widget_show(win)
            gtk_window_present(win)
            
        except e:
            print("ERROR: Failed to create the application!", e)

fn main() raises:
    var app = gtk_application_new("dev.mojo.dialogs", 0)
    _ = g_signal_connect_data(app, "activate", rebind[ptr](DialogDemos.activate), ptr(), None, 0)
    _ = g_application_run(app, 0, ptr())