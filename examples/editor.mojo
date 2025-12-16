from bindings import *
from sys.ffi import CStringSlice, OwnedDLHandle
from memory import UnsafePointer

comptime ptr = LegacyUnsafePointer[NoneType]

@register_passable("trivial")
struct SaveData:
    var win: ptr
    var text_view: ptr
    var dialog: ptr

    fn __init__(out self, win: ptr, text_view: ptr):
        self.win = win
        self.text_view = text_view
        self.dialog = ptr()

comptime SaveDataPointer = LegacyUnsafePointer[SaveData]

@register_passable("trivial")
struct SaveDialogEvents:
    @staticmethod
    fn on_save_clicked(button: ptr, user_data: ptr):
        try:
            var data_ptr = rebind[SaveDataPointer](user_data)
            var dialog = gtk_file_chooser_native_new(
                "Save File", 
                data_ptr[].win, 
                1,  # GTK_FILE_CHOOSER_ACTION_SAVE
                "_Save", 
                "_Cancel"
            )
            
            # Set default filename
            gtk_file_chooser_set_current_name(dialog, "untitled.txt")
            data_ptr[].dialog = dialog
            # Pass the original SaveDataPointer through to the response handler
            _ = g_signal_connect_data(
                dialog, 
                "response", 
                rebind[ptr](SaveDialogEvents.on_save_response), 
                user_data,  # Pass the same SaveDataPointer
                None, 
                0
            )
            
            gtk_native_dialog_show(dialog)
        except e:
            print("Error in on_save_clicked:", e)

    @staticmethod
    fn on_save_response(native: ptr, response_id: Int32, user_data: ptr):
        try:
            print("=== Response callback triggered ===")
            print("Response ID:", response_id)
            
            if response_id == -3:  # GTK_RESPONSE_ACCEPT
                print("User clicked Save")
                print("Attempting to get file...")
                
                # Load the C helper library
                
                # Use C helper to safely get the file path
                var data_ptr = rebind[SaveDataPointer](user_data)
                var file = gtk_file_chooser_get_file(data_ptr[].dialog)
                var path = g_file_get_path(file)
                # var path = helper.call["get_selected_file_path", ptr](data_ptr)
                
                if path:
                    print("✅ Selected path:", path)
                    
                    # Get the text view from user_data
                    var text_view = data_ptr[].text_view
                    
                    # Get the text buffer
                    var buffer = gtk_text_view_get_buffer(text_view)
                    var start = LegacyUnsafePointer[Int8].alloc(128)
                    var end = LegacyUnsafePointer[Int8].alloc(128)
                    gtk_text_buffer_get_start_iter(buffer, (start).bitcast[NoneType]())
                    gtk_text_buffer_get_end_iter(buffer, (end).bitcast[NoneType]())

                    gtk_text_buffer_get_start_iter(buffer, start.bitcast[NoneType]())
                    gtk_text_buffer_get_end_iter(buffer, end.bitcast[NoneType]())
                        
                    # Get text - IMMEDIATELY after getting iterators
                    var text_ptr = gtk_text_buffer_get_text(
                            buffer,
                            start.bitcast[NoneType](),
                            end.bitcast[NoneType](),
                            False  # Use Int32(0) not False
                        )

                    if text_ptr: 
                        var cntent_str = ""
                        var text = CStringSlice(unsafe_from_ptr=text_ptr)
                        text.write_to(cntent_str)
                        
                        # # Write to file
                        
                        var path_str =""
                        var path_cslice = CStringSlice(unsafe_from_ptr=path)
                        path_cslice.write_to(path_str)
                        
                        with open(path_str, "w") as f:
                            f.write(cntent_str)
                        
                        print("✅ File saved successfully!")
                    
                    # Free the path
                else:
                    print("❌ Failed to get file path")
            else:
                print("User cancelled")
            
            # Clean up dialog
            g_object_unref(native)
            print("Dialog cleaned up")
            
        except e:
            print("Exception in on_save_response:", e)


@register_passable("trivial")
struct TextEditorApp:
    @staticmethod
    fn on_about_clicked(button: ptr, user_data: ptr):
        try:
            var dialog = gtk_window_new()
            gtk_window_set_title(dialog, "About")
            gtk_widget_add_css_class(dialog, "about-window")

            gtk_window_set_default_size(dialog, 400, 300)
            gtk_window_set_decorated(dialog, False)
            gtk_window_set_transient_for(dialog, user_data)
            gtk_window_set_modal(dialog, True)
            
            var box = gtk_box_new(1, 20)
            gtk_widget_set_margin_start(box, 30)
            gtk_widget_set_margin_end(box, 30)
            gtk_widget_set_margin_top(box, 30)
            gtk_widget_set_margin_bottom(box, 30)
            
            var app_name = gtk_label_new("📝 MojoText Editor")
            gtk_widget_add_css_class(app_name, "about-title")
            
            var version = gtk_label_new("Version 1.0.0")
            gtk_widget_add_css_class(version, "about-version")
            
            var separator = gtk_separator_new(0)
            gtk_widget_add_css_class(separator, "dialog-separator")
            
            var description = gtk_label_new("A simple, lightweight text editor\nbuilt with Mojo and GTK4")
            gtk_label_set_wrap(description, True)
            gtk_widget_add_css_class(description, "about-description")
            gtk_label_set_justify(description, 2)
            
            var copyright = gtk_label_new("© 2024 MojoText Team")
            gtk_widget_add_css_class(copyright, "about-copyright")
            
            var ok_btn = gtk_button_new_with_label("OK")
            gtk_widget_set_halign(ok_btn, 3)
            _ = g_signal_connect_data(ok_btn, "clicked", rebind[ptr](TextEditorApp.on_close_dialog), dialog, None, 0)
            
            gtk_box_append(box, app_name)
            gtk_box_append(box, version)
            gtk_box_append(box, separator)
            gtk_box_append(box, description)
            gtk_box_append(box, copyright)
            gtk_box_append(box, ok_btn)
            
            gtk_window_set_child(dialog, box)
            gtk_widget_show(dialog)
            gtk_window_present(dialog)
        except:
            print("Error showing about dialog")

    @staticmethod
    fn on_close_dialog(button: ptr, dialog: ptr):
        try:
            gtk_window_destroy(dialog)
        except:
            print("Error closing dialog")

    @staticmethod
    fn activate(app: ptr, gptr: ptr):
        try:
            # Create main window
            var win = gtk_application_window_new(app)
            gtk_window_set_title(win, "MojoText Editor")
            gtk_window_set_default_size(win, 900, 600)

            # Apply CSS styling
            var css_provider = gtk_css_provider_new()
            gtk_css_provider_load_from_string(css_provider, """
                window {
                    background: #f8f9fa;
                }
                
                .toolbar {
                    padding: 8px 12px;
                    border-bottom: 1px solid #dee2e6;
                }

                .toolbar button {
                    color: #495057;
                    border-radius: 6px;
                    padding: 3px 6px;
                    font-size: 15px;
                    font-weight: 500;
                    margin: 0 4px;
                }
                
                .toolbar button:hover {
                    background: #e9ecef;
                    border-color: #adb5bd;
                }
                
                textview {
                    background: #ffffff;
                    color: #212529;
                    padding: 20px;
                    font-family: arial;
                    font-size: 14px;
                    line-height: 1.6;
                }
                
                textview text {
                    background: #ffffff;
                    color: #212529;
                }
                
                .about-title {
                    font-size: 28px;
                    font-weight: bold;
                    color: #212529;
                }
                
                .about-version {
                    font-size: 14px;
                    color: #6c757d;
                }
                
                .about-description {
                    font-size: 14px;
                    color: #495057;
                    line-height: 1.6;
                }
                
                .about-copyright {
                    font-size: 12px;
                    color: #868e96;
                }
                
                .dialog-separator {
                    background: #dee2e6;
                    margin: 12px 0;
                }
            """)
            
            gtk_style_context_add_provider_for_display(
                gtk_widget_get_display(win),
                css_provider,
                800
            )

            # Create main vertical box
            var main_vbox = gtk_box_new(1, 0)

            # Create toolbar
            var toolbar = gtk_box_new(0, 8)  # Horizontal with 8px spacing
            gtk_widget_add_css_class(toolbar, "toolbar")
            
            # Create scrolled window for text view
            var scrolled = gtk_scrolled_window_new()
            gtk_widget_set_vexpand(scrolled, True)
            gtk_widget_set_hexpand(scrolled, True)

            # Create text view
            var textview = gtk_text_view_new()
            gtk_text_view_set_wrap_mode(textview, 2)
            gtk_text_view_set_left_margin(textview, 12)
            gtk_text_view_set_right_margin(textview, 12)
            gtk_text_view_set_top_margin(textview, 12)
            gtk_text_view_set_bottom_margin(textview, 12)
            
            # IMPORTANT: Allocate SaveData on the heap so it persists!
            var data = SaveData(win, textview)
            var data_ptr = SaveDataPointer.alloc(1)
            data_ptr[] = data
            
            # Create buttons and connect signals
            var save_btn = gtk_button_new_with_label("💾")
            var about_btn = gtk_button_new_with_label("ⓘ")
            
            _ = g_signal_connect_data(
                save_btn, 
                "clicked", 
                rebind[ptr](SaveDialogEvents.on_save_clicked), 
                rebind[ptr](data_ptr),  # Pass heap-allocated pointer
                None, 
                0
            )
            _ = g_signal_connect_data(
                about_btn, 
                "clicked", 
                rebind[ptr](TextEditorApp.on_about_clicked), 
                win, 
                None, 
                0
            )
            
            gtk_box_append(toolbar, save_btn)
            gtk_box_append(toolbar, about_btn)
            
            # Get text buffer and set initial text
            var buffer = gtk_text_view_get_buffer(textview)
            gtk_text_buffer_set_text(buffer, "Welcome to MojoText Editor!\n\nStart typing your document here...", -1)

            # Add text view to scrolled window
            gtk_scrolled_window_set_child(scrolled, textview)

            # Assemble the UI
            gtk_box_append(main_vbox, toolbar)
            gtk_box_append(main_vbox, scrolled)

            # Set main box as window child
            gtk_window_set_child(win, main_vbox)

            # Show window

            gtk_widget_show(win)
            gtk_window_present(win)
            TextEditorApp.on_about_clicked(about_btn, win)
        except e:
            print("ERROR: Failed to create the application!", e)

fn main() raises:
    # Create GTK application
    var app = gtk_application_new("dev.mojotext.editor", 0)

    # Connect activate signal
    _ = g_signal_connect_data(app, "activate", rebind[ptr](TextEditorApp.activate), ptr(), None, 0)

    # Run the application
    _ = g_application_run(app, 0, ptr())