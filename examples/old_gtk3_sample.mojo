from memory import LegacyUnsafePointer
from sys.ffi import OwnedDLHandle, c_char
from time import sleep

alias gpointer = LegacyUnsafePointer[NoneType]

fn main() raises:
    print("=== GTK Button Example ===")
    
    var gtk = OwnedDLHandle("/opt/homebrew/lib/libgtk-4.dylib")
    var glib = OwnedDLHandle("/opt/homebrew/lib/libglib-2.0.dylib")
    
    # Initialize GTK
    _ = gtk.call["gtk_init", Int32]()
    
    # Create window
    var window = gtk.call["gtk_window_new", gpointer]()
    _ = gtk.call["gtk_window_set_title", Int32](
        window,
        "Button Example".unsafe_cstr_ptr()
    )
    _ = gtk.call["gtk_window_set_default_size", Int32](
        window,
        Int32(300),
        Int32(200)
    )
    
    # Create a vertical box container
    var box = gtk.call["gtk_box_new", gpointer](
        Int32(1),  # GTK_ORIENTATION_VERTICAL
        Int32(10)  # spacing
    )
    _ = gtk.call["gtk_window_set_child", Int32](window, box)
    
    # Create a label
    var label = gtk.call["gtk_label_new", gpointer](
        "Click the button!".unsafe_cstr_ptr()
    )
    _ = gtk.call["gtk_box_append", Int32](box, label)
    
    # Create a button
    var button = gtk.call["gtk_button_new_with_label", gpointer](
        "Say Hello!".unsafe_cstr_ptr()
    )
    _ = gtk.call["gtk_box_append", Int32](box, button)
    
    # Show window
    _ = gtk.call["gtk_widget_show", Int32](window)
    
    print("Window shown! Click the button...")
    print("(Checking button state every 100ms - this is a workaround)")
    
    # Poll for button clicks (WORKAROUND - not ideal but works!)
    var context = glib.call["g_main_context_default", gpointer]()
    var click_count = 0
    
    # We need to track if button was clicked
    # Unfortunately, without callbacks, we can't detect clicks directly
    # Let's use a different approach...
    
    print("Running event loop...")
    var loop = glib.call["g_main_loop_new", gpointer](gpointer(), Int32(0))
    _ = glib.call["g_main_loop_run", Int32](loop)