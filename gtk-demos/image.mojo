# Type bug, may not compile on all systems
from gtk import *
from sys.ffi import CStringSlice
from memory import UnsafePointer

comptime ptr = LegacyUnsafePointer[NoneType]
comptime str = String
@register_passable("trivial")
struct AppData:
    var win: ptr
    var image_widget: ptr
    var status_label: ptr
    var file_path_label: ptr
    
    fn __init__(out self, win: ptr, image_widget: ptr, status_label: ptr, file_path_label: ptr):
        self.win = win
        self.image_widget = image_widget
        self.status_label = status_label
        self.file_path_label = file_path_label

comptime AppDataPointer = LegacyUnsafePointer[AppData]

@register_passable("trivial")
struct ImageDemo:
    
    # ==================== Image Loading ====================
    
    @staticmethod
    fn on_open_image(button: ptr, user_data: ptr) raises:
        """Open file dialog to load an image"""
        try:
            var app = rebind[AppDataPointer](user_data)
            var dialog = gtk_file_dialog_new()
            gtk_file_dialog_set_title(dialog, "Open Image")
            gtk_file_dialog_set_modal(dialog, True)
            
            # Set file filters for images
            var filter = gtk_file_filter_new()
            gtk_file_filter_set_name(filter, "Image Files")
            gtk_file_filter_add_mime_type(filter, "image/png")
            gtk_file_filter_add_mime_type(filter, "image/jpeg")
            gtk_file_filter_add_mime_type(filter, "image/jpg")
            gtk_file_filter_add_mime_type(filter, "image/gif")
            gtk_file_filter_add_mime_type(filter, "image/bmp")
            gtk_file_filter_add_mime_type(filter, "image/webp")
            
            var filter_list = g_list_store_new(ptr())
            g_list_store_append(filter_list, filter)
            gtk_file_dialog_set_filters(dialog, filter_list)
            
            external_call["gtk_file_dialog_open", NoneType](dialog, app[].win, ptr(), (ImageDemo.on_file_open_finish), user_data)
        except:
            ImageDemo.update_status(rebind[AppDataPointer](user_data), "⚠️ Failed to open file dialog", "error")
    
    @staticmethod
    fn on_file_open_finish(source: ptr, res: ptr, user_data: ptr) raises:
        """Handle file selection"""
        try:
            var data_ptr = rebind[AppDataPointer](user_data)
            var file = gtk_file_dialog_open_finish(source, res)
            
            if file:
                var path = g_file_get_path(file)
                if path:
                    var path_str = String(CStringSlice(unsafe_from_ptr=path))
                    ImageDemo.load_image(data_ptr, path_str)
                else:
                    ImageDemo.update_status(data_ptr, "⚠️ Could not get file path", "error")
            else:
                ImageDemo.update_status(data_ptr, "❌ No file selected", "info")
        except:
            ImageDemo.update_status(rebind[AppDataPointer](user_data), "⚠️ Error opening file", "error")
    
    @staticmethod
    fn load_image(data_ptr: AppDataPointer, path: String) raises:
        """Load and display the image"""
        try:
            # Load image from file
            gtk_image_set_from_file(data_ptr[].image_widget, path)
            
            # Update labels
            gtk_label_set_text(data_ptr[].file_path_label, path)
            ImageDemo.update_status(data_ptr, "✅ Image loaded successfully!", "success")
            
        except e:
            ImageDemo.update_status(data_ptr, "⚠️ Failed to load image: " + str(e), "error")
    
    @staticmethod
    fn on_load_from_icon(button: ptr, user_data: ptr) raises:
        """Load from icon name"""
        try:
            var data_ptr = rebind[AppDataPointer](user_data)
            
            # Load a system icon
            gtk_image_set_from_icon_name(data_ptr[].image_widget, "face-smile")
            gtk_image_set_pixel_size(data_ptr[].image_widget, 256)
            
            gtk_label_set_text(data_ptr[].file_path_label, "System Icon: face-smile")
            ImageDemo.update_status(data_ptr, "✅ Loaded system icon", "success")
        except:
            ImageDemo.update_status(rebind[AppDataPointer](user_data), "⚠️ Failed to load icon", "error")
    
    @staticmethod
    fn on_clear_image(button: ptr, user_data: ptr) raises:
        """Clear the displayed image"""
        try:
            var data_ptr = rebind[AppDataPointer](user_data)
            gtk_image_clear(data_ptr[].image_widget)
            gtk_label_set_text(data_ptr[].file_path_label, "No image loaded")
            ImageDemo.update_status(data_ptr, "🗑️ Image cleared", "info")
        except:
            pass
    
    @staticmethod
    fn on_scale_fit(button: ptr, user_data: ptr) raises:
        """Scale image to fit"""
        try:
            var data_ptr = rebind[AppDataPointer](user_data)
            gtk_image_set_pixel_size(data_ptr[].image_widget, -1)  # Auto size
            ImageDemo.update_status(data_ptr, "📐 Scaled to fit", "info")
        except:
            pass
    
    @staticmethod
    fn on_scale_small(button: ptr, user_data: ptr) raises:
        """Scale image to small size"""
        try:
            var data_ptr = rebind[AppDataPointer](user_data)
            gtk_image_set_pixel_size(data_ptr[].image_widget, 128)
            ImageDemo.update_status(data_ptr, "📐 Scaled to 128px", "info")
        except:
            pass
    
    @staticmethod
    fn on_scale_medium(button: ptr, user_data: ptr) raises:
        """Scale image to medium size"""
        try:
            var data_ptr = rebind[AppDataPointer](user_data)
            gtk_image_set_pixel_size(data_ptr[].image_widget, 256)
            ImageDemo.update_status(data_ptr, "📐 Scaled to 256px", "info")
        except:
            pass
    
    @staticmethod
    fn on_scale_large(button: ptr, user_data: ptr) raises:
        """Scale image to large size"""
        try:
            var data_ptr = rebind[AppDataPointer](user_data)
            gtk_image_set_pixel_size(data_ptr[].image_widget, 512)
            ImageDemo.update_status(data_ptr, "📐 Scaled to 512px", "info")
        except:
            pass
    
    @staticmethod
    fn update_status(data_ptr: AppDataPointer, message: String, type: String) raises:
        """Update status label with markup"""
        try:
            var markup = ""
            if type == "success":
                markup = "<span foreground='#2ecc71'>" + message + "</span>"
            elif type == "error":
                markup = "<span foreground='#e74c3c'>" + message + "</span>"
            else:
                markup = "<span foreground='#3498db'>" + message + "</span>"
            
            gtk_label_set_markup(data_ptr[].status_label, markup)
        except:
            gtk_label_set_text(data_ptr[].status_label, message)

@register_passable("trivial")
struct ImageApp:
    @staticmethod
    fn activate(app: ptr, gptr: ptr):
        try:
            var win = gtk_application_window_new(app)
            gtk_window_set_title(win, "Image Viewer Demo")
            gtk_window_set_default_size(win, 900, 700)

            # CSS for styling
            var css_provider = gtk_css_provider_new()
            gtk_css_provider_load_from_string(css_provider, """
                window {
                    background: #2c3e50;
                }
                
                .header-bar {
                    background: linear-gradient(to bottom, #34495e, #2c3e50);
                    padding: 12px;
                    border-bottom: 2px solid #1abc9c;
                }
                
                .title-label {
                    font-size: 20px;
                    font-weight: bold;
                    color: #ecf0f1;
                }
                
                .control-panel {
                    background: #34495e;
                    padding: 16px;
                    border-radius: 8px;
                    margin: 16px;
                }
                
                .control-panel button {
                    margin: 4px;
                    padding: 8px 16px;
                    border-radius: 6px;
                    background: #3498db;
                    color: white;
                    font-weight: 500;
                }
                
                .control-panel button:hover {
                    background: #2980b9;
                }
                
                .image-frame {
                    background: #ecf0f1;
                    border-radius: 8px;
                    padding: 20px;
                    margin: 16px;
                }
                
                .status-bar {
                    background: #34495e;
                    padding: 8px 16px;
                    border-top: 1px solid #1abc9c;
                }
                
                .status-label {
                    color: #ecf0f1;
                    font-size: 14px;
                }
                
                .file-path-label {
                    color: #95a5a6;
                    font-size: 12px;
                    font-family: monospace;
                }
            """)
            
            gtk_style_context_add_provider_for_display(
                gtk_widget_get_display(win),
                css_provider,
                800
            )

            # Main layout
            var main_box = gtk_box_new(1, 0)  # Vertical

            # Header
            var header = gtk_box_new(0, 0)  # Horizontal
            gtk_widget_add_css_class(header, "header-bar")
            
            var title = gtk_label_new("🖼️ Mojo Image Viewer")
            gtk_widget_add_css_class(title, "title-label")
            gtk_box_append(header, title)

            # Control panel
            var control_box = gtk_box_new(1, 12)  # Vertical with spacing
            gtk_widget_add_css_class(control_box, "control-panel")

            # Load buttons row
            var load_row = gtk_box_new(0, 8)  # Horizontal
            var open_btn = gtk_button_new_with_label("📁 Open Image")
            var icon_btn = gtk_button_new_with_label("🎨 Load Icon")
            var clear_btn = gtk_button_new_with_label("🗑️ Clear")
            
            gtk_box_append(load_row, open_btn)
            gtk_box_append(load_row, icon_btn)
            gtk_box_append(load_row, clear_btn)

            # Scale buttons row
            var scale_row = gtk_box_new(0, 8)  # Horizontal
            var fit_btn = gtk_button_new_with_label("📐 Fit")
            var small_btn = gtk_button_new_with_label("Small (128px)")
            var medium_btn = gtk_button_new_with_label("Medium (256px)")
            var large_btn = gtk_button_new_with_label("Large (512px)")
            
            gtk_box_append(scale_row, fit_btn)
            gtk_box_append(scale_row, small_btn)
            gtk_box_append(scale_row, medium_btn)
            gtk_box_append(scale_row, large_btn)

            gtk_box_append(control_box, load_row)
            gtk_box_append(control_box, scale_row)

            # Image display area (scrollable)
            var scrolled = gtk_scrolled_window_new()
            gtk_widget_set_vexpand(scrolled, True)
            gtk_widget_set_hexpand(scrolled, True)
            gtk_scrolled_window_set_policy(scrolled, 1, 1)  # Automatic scrollbars
            
            var image_frame = gtk_box_new(1, 0)
            gtk_widget_add_css_class(image_frame, "image-frame")
            gtk_widget_set_halign(image_frame, 3)  # Center
            gtk_widget_set_valign(image_frame, 3)  # Center
            
            var image_widget = gtk_image_new()
            gtk_image_set_from_icon_name(image_widget, "image-x-generic")
            gtk_image_set_pixel_size(image_widget, 256)
            
            gtk_box_append(image_frame, image_widget)
            gtk_scrolled_window_set_child(scrolled, image_frame)

            # Status bar
            var status_box = gtk_box_new(1, 4)  # Vertical
            gtk_widget_add_css_class(status_box, "status-bar")
            
            var status_label = gtk_label_new("ℹ️ Ready to load an image")
            gtk_label_set_use_markup(status_label, True)
            gtk_widget_add_css_class(status_label, "status-label")
            gtk_widget_set_halign(status_label, 1)  # Start
            
            var file_path_label = gtk_label_new("No image loaded")
            gtk_widget_add_css_class(file_path_label, "file-path-label")
            gtk_widget_set_halign(file_path_label, 1)  # Start
            gtk_label_set_selectable(file_path_label, True)
            
            gtk_box_append(status_box, status_label)
            gtk_box_append(status_box, file_path_label)

            # Assemble UI
            gtk_box_append(main_box, header)
            gtk_box_append(main_box, control_box)
            gtk_box_append(main_box, scrolled)
            gtk_box_append(main_box, status_box)

            # Create app data
            var data = AppData(win, image_widget, status_label, file_path_label)
            var data_ptr = AppDataPointer.alloc(1)
            data_ptr[] = data

            # Connect signals
            _ = g_signal_connect_data(open_btn, "clicked", (ImageDemo.on_open_image), rebind[ptr](data_ptr), None, 0)
            _ = g_signal_connect_data(icon_btn, "clicked", (ImageDemo.on_load_from_icon), rebind[ptr](data_ptr), None, 0)
            _ = g_signal_connect_data(clear_btn, "clicked", (ImageDemo.on_clear_image), rebind[ptr](data_ptr), None, 0)
            _ = g_signal_connect_data(fit_btn, "clicked", (ImageDemo.on_scale_fit), rebind[ptr](data_ptr), None, 0)
            _ = g_signal_connect_data(small_btn, "clicked", (ImageDemo.on_scale_small), rebind[ptr](data_ptr), None, 0)
            _ = g_signal_connect_data(medium_btn, "clicked", (ImageDemo.on_scale_medium), rebind[ptr](data_ptr), None, 0)
            _ = g_signal_connect_data(large_btn, "clicked", (ImageDemo.on_scale_large), rebind[ptr](data_ptr), None, 0)

            gtk_window_set_child(win, main_box)
            gtk_widget_show(win)

        except e:
            print("ERROR: Failed to create UI:", e)

fn main() raises:
    var app = gtk_application_new("dev.mojo.imageviewer", 0)
    _ = g_signal_connect_data(app, "activate", (ImageApp.activate), ptr(), None, 0)
    _ = g_application_run(app, 0, ptr())