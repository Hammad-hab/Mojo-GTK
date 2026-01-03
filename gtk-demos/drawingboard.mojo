from gtk import *
from sys.ffi import CStringSlice, external_call
from memory import UnsafePointer
import math

comptime ptr = LegacyUnsafePointer[NoneType]

# Cairo drawing functions (you'll need to link with -l cairo)
fn cairo_set_source_rgb(cr: ptr, r: Float64, g: Float64, b: Float64):
    _ = external_call["cairo_set_source_rgb", NoneType](cr, r, g, b)

fn cairo_set_line_width(cr: ptr, width: Float64):
    _ = external_call["cairo_set_line_width", NoneType](cr, width)

fn cairo_move_to(cr: ptr, x: Float64, y: Float64):
    _ = external_call["cairo_move_to", NoneType](cr, x, y)

fn cairo_line_to(cr: ptr, x: Float64, y: Float64):
    _ = external_call["cairo_line_to", NoneType](cr, x, y)

fn cairo_stroke(cr: ptr):
    _ = external_call["cairo_stroke", NoneType](cr)

fn cairo_arc(cr: ptr, xc: Float64, yc: Float64, radius: Float64, angle1: Float64, angle2: Float64):
    _ = external_call["cairo_arc", NoneType](cr, xc, yc, radius, angle1, angle2)

fn cairo_fill(cr: ptr):
    _ = external_call["cairo_fill", NoneType](cr)

fn cairo_rectangle(cr: ptr, x: Float64, y: Float64, width: Float64, height: Float64):
    _ = external_call["cairo_rectangle", NoneType](cr, x, y, width, height)

fn cairo_paint(cr: ptr):
    _ = external_call["cairo_paint", NoneType](cr)

fn cairo_set_source_rgba(cr: ptr, r: Float64, g: Float64, b: Float64, a: Float64):
    _ = external_call["cairo_set_source_rgba", NoneType](cr, r, g, b, a)

fn cairo_image_surface_create(format: Int32, width: Int32, height: Int32) -> ptr:
    return external_call["cairo_image_surface_create", ptr](format, width, height)

fn cairo_create(surface: ptr) -> ptr:
    return external_call["cairo_create", ptr](surface)

fn cairo_destroy(cr: ptr):
    _ = external_call["cairo_destroy", NoneType](cr)

fn cairo_set_source_surface(cr: ptr, surface: ptr, x: Float64, y: Float64):
    _ = external_call["cairo_set_source_surface", NoneType](cr, surface, x, y)

alias CAIRO_FORMAT_ARGB32: Int32 = 0

@register_passable("trivial")
struct DrawingAppData:
    var drawing_area: ptr
    var surface: ptr
    var current_tool: Int32  # 0=pen, 1=circle, 2=rectangle, 3=eraser
    var current_color_r: Float64
    var current_color_g: Float64
    var current_color_b: Float64
    var line_width: Float64
    var is_drawing: Bool
    var last_x: Float64
    var last_y: Float64

    fn __init__(out self, drawing_area: ptr):
        self.drawing_area = drawing_area
        self.surface = ptr()
        self.current_tool = 0  # Pen by default
        self.current_color_r = 0.0
        self.current_color_g = 0.0
        self.current_color_b = 0.0
        self.line_width = 3.0
        self.is_drawing = False
        self.last_x = 0.0
        self.last_y = 0.0

comptime DrawingAppDataPointer = LegacyUnsafePointer[DrawingAppData]

@register_passable("trivial")
struct DrawingApp:
    
    @staticmethod
    fn on_draw(area: ptr, cr: ptr, width: Int32, height: Int32, user_data: ptr):
        """Draw callback - called when the drawing area needs to be redrawn"""
        try:
            var data_ptr = rebind[DrawingAppDataPointer](user_data)
            
            # If surface doesn't exist, create it
            if not data_ptr[].surface:
                data_ptr[].surface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, width, height)
                var surface_cr = cairo_create(data_ptr[].surface)
                # Fill with white
                cairo_set_source_rgb(surface_cr, 1.0, 1.0, 1.0)
                cairo_paint(surface_cr)
                cairo_destroy(surface_cr)
            
            # Draw the surface to the widget
            cairo_set_source_surface(cr, data_ptr[].surface, 0.0, 0.0)
            cairo_paint(cr)
            
        except e:
            print("Error in on_draw:", e)

    @staticmethod
    fn on_drag_begin(gesture: ptr, x: Float64, y: Float64, user_data: ptr):
        """Called when user starts dragging"""
        try:
            var data_ptr = rebind[DrawingAppDataPointer](user_data)
            data_ptr[].is_drawing = True
            data_ptr[].last_x = x
            data_ptr[].last_y = y
            print("Started drawing at:", x, y)
        except e:
            print("Error in on_drag_begin:", e)

    @staticmethod
    fn on_drag_update(gesture: ptr, offset_x: Float64, offset_y: Float64, user_data: ptr):
        """Called while user is dragging"""
        try:
            var data_ptr = rebind[DrawingAppDataPointer](user_data)
            
            if not data_ptr[].is_drawing or not data_ptr[].surface:
                return
            
            # Get start point from gesture
            var start_x: Float64 = 0.0
            var start_y: Float64 = 0.0
            gtk_gesture_drag_get_start_point(gesture, LegacyUnsafePointer[Float64](to=start_x), LegacyUnsafePointer[Float64](to=start_y))
            
            var current_x = start_x + offset_x
            var current_y = start_y + offset_y
            
            # Draw on the persistent surface
            var surface_cr = cairo_create(data_ptr[].surface)
            
            # Set color and line width
            cairo_set_source_rgb(surface_cr, 
                data_ptr[].current_color_r,
                data_ptr[].current_color_g,
                data_ptr[].current_color_b
            )
            cairo_set_line_width(surface_cr, data_ptr[].line_width)
            
            var tool = data_ptr[].current_tool
            
            if tool == 0:  # Pen - draw line
                cairo_move_to(surface_cr, data_ptr[].last_x, data_ptr[].last_y)
                cairo_line_to(surface_cr, current_x, current_y)
                cairo_stroke(surface_cr)
                
            elif tool == 3:  # Eraser - draw white line
                cairo_set_source_rgb(surface_cr, 1.0, 1.0, 1.0)
                cairo_set_line_width(surface_cr, data_ptr[].line_width * 3.0)
                cairo_move_to(surface_cr, data_ptr[].last_x, data_ptr[].last_y)
                cairo_line_to(surface_cr, current_x, current_y)
                cairo_stroke(surface_cr)
            
            cairo_destroy(surface_cr)
            
            data_ptr[].last_x = current_x
            data_ptr[].last_y = current_y
            
            # Queue redraw
            gtk_widget_queue_draw(data_ptr[].drawing_area)
            
        except e:
            print("Error in on_drag_update:", e)

    @staticmethod
    fn on_drag_end(gesture: ptr, offset_x: Float64, offset_y: Float64, user_data: ptr):
        """Called when user stops dragging"""
        try:
            var data_ptr = rebind[DrawingAppDataPointer](user_data)
            
            if not data_ptr[].is_drawing or not data_ptr[].surface:
                return
                
            # Get start point from gesture
            var start_x: Float64 = 0.0
            var start_y: Float64 = 0.0
            gtk_gesture_drag_get_start_point(gesture, LegacyUnsafePointer[Float64](to=start_x), LegacyUnsafePointer[Float64](to=start_y))
            
            var end_x = start_x + offset_x
            var end_y = start_y + offset_y
            
            var tool = data_ptr[].current_tool
            
            # For shapes, draw them once at the end
            if tool == 1 or tool == 2:
                var surface_cr = cairo_create(data_ptr[].surface)
                cairo_set_source_rgb(surface_cr, 
                    data_ptr[].current_color_r,
                    data_ptr[].current_color_g,
                    data_ptr[].current_color_b
                )
                cairo_set_line_width(surface_cr, data_ptr[].line_width)
                
                if tool == 1:  # Circle
                    var radius = math.sqrt((end_x - start_x) ** 2 + (end_y - start_y) ** 2)
                    cairo_arc(surface_cr, start_x, start_y, radius, 0.0, 2.0 * 3.14159265359)
                    cairo_stroke(surface_cr)
                    
                elif tool == 2:  # Rectangle
                    var width = end_x - start_x
                    var height = end_y - start_y
                    cairo_rectangle(surface_cr, start_x, start_y, width, height)
                    cairo_stroke(surface_cr)
                
                cairo_destroy(surface_cr)
                gtk_widget_queue_draw(data_ptr[].drawing_area)
            
            data_ptr[].is_drawing = False
            print("Stopped drawing")
        except e:
            print("Error in on_drag_end:", e)

    @staticmethod
    fn on_pen_clicked(button: ptr, user_data: ptr):
        try:
            var data_ptr = rebind[DrawingAppDataPointer](user_data)
            data_ptr[].current_tool = 0
            data_ptr[].current_color_r = 0.0
            data_ptr[].current_color_g = 0.0
            data_ptr[].current_color_b = 0.0
            print("🖊️ Pen tool selected")
        except:
            pass

    @staticmethod
    fn on_circle_clicked(button: ptr, user_data: ptr):
        try:
            var data_ptr = rebind[DrawingAppDataPointer](user_data)
            data_ptr[].current_tool = 1
            print("⭕ Circle tool selected")
        except:
            pass

    @staticmethod
    fn on_rect_clicked(button: ptr, user_data: ptr):
        try:
            var data_ptr = rebind[DrawingAppDataPointer](user_data)
            data_ptr[].current_tool = 2
            print("▭ Rectangle tool selected")
        except:
            pass

    @staticmethod
    fn on_eraser_clicked(button: ptr, user_data: ptr):
        try:
            var data_ptr = rebind[DrawingAppDataPointer](user_data)
            data_ptr[].current_tool = 3
            print("🧹 Eraser selected")
        except:
            pass

    @staticmethod
    fn on_red_clicked(button: ptr, user_data: ptr):
        try:
            var data_ptr = rebind[DrawingAppDataPointer](user_data)
            data_ptr[].current_color_r = 1.0
            data_ptr[].current_color_g = 0.0
            data_ptr[].current_color_b = 0.0
            print("🔴 Red color selected")
        except:
            pass

    @staticmethod
    fn on_green_clicked(button: ptr, user_data: ptr):
        try:
            var data_ptr = rebind[DrawingAppDataPointer](user_data)
            data_ptr[].current_color_r = 0.0
            data_ptr[].current_color_g = 1.0
            data_ptr[].current_color_b = 0.0
            print("🟢 Green color selected")
        except:
            pass

    @staticmethod
    fn on_blue_clicked(button: ptr, user_data: ptr):
        try:
            var data_ptr = rebind[DrawingAppDataPointer](user_data)
            data_ptr[].current_color_r = 0.0
            data_ptr[].current_color_g = 0.0
            data_ptr[].current_color_b = 1.0
            print("🔵 Blue color selected")
        except:
            pass

    @staticmethod
    fn on_clear_clicked(button: ptr, user_data: ptr):
        """Clear the canvas"""
        try:
            var data_ptr = rebind[DrawingAppDataPointer](user_data)
            
            if data_ptr[].surface:
                # Fill surface with white
                var surface_cr = cairo_create(data_ptr[].surface)
                cairo_set_source_rgb(surface_cr, 1.0, 1.0, 1.0)
                cairo_paint(surface_cr)
                cairo_destroy(surface_cr)
                
                gtk_widget_queue_draw(data_ptr[].drawing_area)
                print("🗑️ Canvas cleared")
        except e:
            print("Error in on_clear_clicked:", e)

    @staticmethod
    fn activate(app: ptr, gptr: ptr):
        try:
            var win = gtk_application_window_new(app)
            gtk_window_set_title(win, "🎨 Mojo Drawing Canvas")
            gtk_window_set_default_size(win, 1000, 700)
            
            # CSS Styling
            var css_provider = gtk_css_provider_new()
            gtk_css_provider_load_from_string(css_provider, """
                window {
                    background: #2c3e50;
                }
                
                .toolbar {
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    padding: 16px;
                    border-radius: 12px;
                    margin: 12px;
                    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
                }
                
                .tool-btn {
                    background: rgba(255, 255, 255, 0.2);
                    color: white;
                    border-radius: 8px;
                    padding: 12px 20px;
                    margin: 0 6px;
                    font-size: 18px;
                    font-weight: 600;
                    border: 2px solid rgba(255, 255, 255, 0.3);
                }
                
                .tool-btn:hover {
                    background: rgba(255, 255, 255, 0.35);
                    border-color: rgba(255, 255, 255, 0.6);
                }
                
                .tool-btn:active {
                    background: rgba(255, 255, 255, 0.5);
                }
                
                .color-btn {
                    min-width: 45px;
                    min-height: 45px;
                    border-radius: 50%;
                    border: 3px solid white;
                    margin: 0 6px;
                    box-shadow: 0 4px 8px rgba(0, 0, 0, 0.3);
                }
                
                .color-btn:hover {
                    border-width: 4px;
                }
                
                .color-red {
                    background: #e74c3c;
                }
                
                .color-green {
                    background: #2ecc71;
                }
                
                .color-blue {
                    background: #3498db;
                }
                
                .color-yellow {
                    background: #f39c12;
                }
                
                .color-purple {
                    background: #9b59b6;
                }
                
                .canvas-area {
                    background: white;
                    border-radius: 12px;
                    margin: 12px;
                    box-shadow: 0 8px 24px rgba(0, 0, 0, 0.4);
                }
                
                .title-label {
                    color: white;
                    font-size: 20px;
                    font-weight: bold;
                }
            """)
            
            gtk_style_context_add_provider_for_display(
                gtk_widget_get_display(win),
                css_provider,
                800
            )
            
            # Main layout
            var main_box = gtk_box_new(1, 0)  # Vertical
            
            # Toolbar
            var toolbar = gtk_box_new(0, 12)  # Horizontal
            gtk_widget_add_css_class(toolbar, "toolbar")
            
            var title_label = gtk_label_new("🎨 Drawing Tools")
            gtk_widget_add_css_class(title_label, "title-label")
            gtk_box_append(toolbar, title_label)
            
            # Tool buttons
            var pen_btn = gtk_button_new_with_label("🖊️ Pen")
            var circle_btn = gtk_button_new_with_label("⭕ Circle")
            var rect_btn = gtk_button_new_with_label("▭ Rectangle")
            var eraser_btn = gtk_button_new_with_label("🧹 Eraser")
            
            gtk_widget_add_css_class(pen_btn, "tool-btn")
            gtk_widget_add_css_class(circle_btn, "tool-btn")
            gtk_widget_add_css_class(rect_btn, "tool-btn")
            gtk_widget_add_css_class(eraser_btn, "tool-btn")
            
            gtk_box_append(toolbar, pen_btn)
            gtk_box_append(toolbar, circle_btn)
            gtk_box_append(toolbar, rect_btn)
            gtk_box_append(toolbar, eraser_btn)
            
            # Color buttons
            var red_btn = gtk_button_new()
            var green_btn = gtk_button_new()
            var blue_btn = gtk_button_new()
            
            gtk_widget_add_css_class(red_btn, "color-btn")
            gtk_widget_add_css_class(red_btn, "color-red")
            gtk_widget_add_css_class(green_btn, "color-btn")
            gtk_widget_add_css_class(green_btn, "color-green")
            gtk_widget_add_css_class(blue_btn, "color-btn")
            gtk_widget_add_css_class(blue_btn, "color-blue")
            
            gtk_box_append(toolbar, red_btn)
            gtk_box_append(toolbar, green_btn)
            gtk_box_append(toolbar, blue_btn)
            
            # Spacer
            var spacer = gtk_box_new(0, 0)
            gtk_widget_set_hexpand(spacer, True)
            gtk_box_append(toolbar, spacer)
            
            # Clear button
            var clear_btn = gtk_button_new_with_label("🗑️ Clear")
            gtk_widget_add_css_class(clear_btn, "tool-btn")
            gtk_box_append(toolbar, clear_btn)
            
            # Drawing area
            var drawing_area = gtk_drawing_area_new()
            gtk_widget_add_css_class(drawing_area, "canvas-area")
            gtk_widget_set_vexpand(drawing_area, True)
            gtk_widget_set_hexpand(drawing_area, True)
            gtk_drawing_area_set_content_width(drawing_area, 800)
            gtk_drawing_area_set_content_height(drawing_area, 600)
            
            # Set up app data
            var data = DrawingAppData(drawing_area)
            var data_ptr = DrawingAppDataPointer.alloc(1)
            data_ptr[] = data
            
            # Connect drawing function
            external_call["gtk_drawing_area_set_draw_func", NoneType](
                drawing_area,
                DrawingApp.on_draw,
                rebind[ptr](data_ptr),
                None
            )
            
            # Add gesture for drawing
            var drag_gesture = gtk_gesture_drag_new()
            gtk_widget_add_controller(drawing_area, drag_gesture)
            
            _ = g_signal_connect_data(
                drag_gesture,
                "drag-begin",
                DrawingApp.on_drag_begin,
                rebind[ptr](data_ptr),
                None,
                0
            )
            
            _ = g_signal_connect_data(
                drag_gesture,
                "drag-update",
                DrawingApp.on_drag_update,
                rebind[ptr](data_ptr),
                None,
                0
            )
            
            _ = g_signal_connect_data(
                drag_gesture,
                "drag-end",
                DrawingApp.on_drag_end,
                rebind[ptr](data_ptr),
                None,
                0
            )
            
            # Connect tool buttons
            _ = g_signal_connect_data(pen_btn, "clicked", DrawingApp.on_pen_clicked, rebind[ptr](data_ptr), None, 0)
            _ = g_signal_connect_data(circle_btn, "clicked", DrawingApp.on_circle_clicked, rebind[ptr](data_ptr), None, 0)
            _ = g_signal_connect_data(rect_btn, "clicked", DrawingApp.on_rect_clicked, rebind[ptr](data_ptr), None, 0)
            _ = g_signal_connect_data(eraser_btn, "clicked", DrawingApp.on_eraser_clicked, rebind[ptr](data_ptr), None, 0)
            
            # Connect color buttons
            _ = g_signal_connect_data(red_btn, "clicked", DrawingApp.on_red_clicked, rebind[ptr](data_ptr), None, 0)
            _ = g_signal_connect_data(green_btn, "clicked", DrawingApp.on_green_clicked, rebind[ptr](data_ptr), None, 0)
            _ = g_signal_connect_data(blue_btn, "clicked", DrawingApp.on_blue_clicked, rebind[ptr](data_ptr), None, 0)
            
            # Connect clear button
            _ = g_signal_connect_data(clear_btn, "clicked", DrawingApp.on_clear_clicked, rebind[ptr](data_ptr), None, 0)
            
            # Assemble UI
            gtk_box_append(main_box, toolbar)
            gtk_box_append(main_box, drawing_area)
            
            gtk_window_set_child(win, main_box)
            gtk_widget_show(win)
            gtk_window_present(win)
            
            print("✅ Drawing canvas initialized!")
            print("💡 Click and drag to draw!")
            
        except e:
            print("ERROR: Failed to create drawing app!", e)

fn main() raises:
    var app = gtk_application_new("dev.mojo.drawing.canvas", 0)
    _ = g_signal_connect_data(
        app,
        "activate",
        DrawingApp.activate,
        ptr(),
        None,
        0
    )
    _ = g_application_run(app, 0, ptr())