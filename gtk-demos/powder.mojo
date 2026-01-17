from gtk import *
from sys.ffi import CStringSlice, external_call
from memory import UnsafePointer
import math
import random

comptime ptr = LegacyUnsafePointer[NoneType]

# GLib timer function
fn g_timeout_add(interval: UInt32, function: fn(ptr) -> Bool, data: ptr) -> UInt32:
    return external_call["g_timeout_add", UInt32](interval, function, data)

# Cairo surface dimension functions
fn cairo_image_surface_get_width(surface: ptr) -> Int32:
    return external_call["cairo_image_surface_get_width", Int32](surface)

fn cairo_image_surface_get_height(surface: ptr) -> Int32:
    return external_call["cairo_image_surface_get_height", Int32](surface)

# Cairo drawing functions
fn cairo_set_source_rgb(cr: ptr, r: Float64, g: Float64, b: Float64):
    _ = external_call["cairo_set_source_rgb", NoneType](cr, r, g, b)

fn cairo_rectangle(cr: ptr, x: Float64, y: Float64, width: Float64, height: Float64):
    _ = external_call["cairo_rectangle", NoneType](cr, x, y, width, height)

fn cairo_fill(cr: ptr):
    _ = external_call["cairo_fill", NoneType](cr)

fn cairo_paint(cr: ptr):
    _ = external_call["cairo_paint", NoneType](cr)

fn cairo_image_surface_create(format: Int32, width: Int32, height: Int32) -> ptr:
    return external_call["cairo_image_surface_create", ptr](format, width, height)

fn cairo_create(surface: ptr) -> ptr:
    return external_call["cairo_create", ptr](surface)

fn cairo_destroy(cr: ptr):
    _ = external_call["cairo_destroy", NoneType](cr)

fn cairo_set_source_surface(cr: ptr, surface: ptr, x: Float64, y: Float64):
    _ = external_call["cairo_set_source_surface", NoneType](cr, surface, x, y)

alias CAIRO_FORMAT_ARGB32: Int32 = 0

# Particle types
alias EMPTY: Int32 = 0
alias SAND: Int32 = 1
alias WATER: Int32 = 2
alias STONE: Int32 = 3
alias FIRE: Int32 = 4
alias WOOD: Int32 = 5

# Grid dimensions
alias GRID_WIDTH: Int32 = 600
alias GRID_HEIGHT: Int32 = 450
alias PIXEL_SIZE: Int32 = 2

@register_passable("trivial")
struct PowderSimData:
    var drawing_area: ptr
    var surface: ptr
    var grid: LegacyUnsafePointer[Int32]  # Grid of particle types
    var current_particle: Int32
    var brush_size: Int32
    var is_drawing: Bool
    var timer_id: UInt32
    var paused: Bool

    fn __init__(out self, drawing_area: ptr):
        self.drawing_area = drawing_area
        self.surface = ptr()
        var grid_size = Int(GRID_WIDTH * GRID_HEIGHT)
        self.grid = LegacyUnsafePointer[Int32].alloc(grid_size)
        self.current_particle = SAND
        self.brush_size = 5
        self.is_drawing = False
        self.timer_id = 0
        self.paused = False
        
        # Initialize grid to empty
        for i in range(grid_size):
            self.grid[i] = EMPTY

comptime PowderSimDataPointer = LegacyUnsafePointer[PowderSimData]

@register_passable("trivial")
struct ColorRGB:
    var r: Float64
    var g: Float64
    var b: Float64
    
    fn __init__(out self, r: Float64, g: Float64, b: Float64):
        self.r = r
        self.g = g
        self.b = b

@register_passable("trivial")
struct PowderSim:
    
    @staticmethod
    fn get_particle_color(particle_type: Int32) -> ColorRGB:
        """Get RGB color for particle type"""
        if particle_type == SAND:
            return ColorRGB(0.93, 0.79, 0.35)
        elif particle_type == WATER:
            return ColorRGB(0.2, 0.4, 0.9)
        elif particle_type == STONE:
            return ColorRGB(0.5, 0.5, 0.5)
        elif particle_type == FIRE:
            return ColorRGB(1.0, 0.3 + random.random_float64() * 0.3, 0.0)
        elif particle_type == WOOD:
            return ColorRGB(0.4, 0.26, 0.13)
        else:  # EMPTY
            return ColorRGB(0.1, 0.1, 0.15)

    @staticmethod
    fn get_grid_index(x: Int32, y: Int32) -> Int32:
        """Convert x,y to grid index"""
        if x < 0 or x >= GRID_WIDTH or y < 0 or y >= GRID_HEIGHT:
            return -1
        return y * GRID_WIDTH + x

    @staticmethod
    fn update_physics(data_ptr: PowderSimDataPointer) raises:
        """Update particle physics - process from bottom to top"""
        if data_ptr[].paused:
            return
            
        # Process from bottom to top, randomize left/right
        for y in range(GRID_HEIGHT - 2, -1, -1):
            var x_start: Int32 = 0
            var x_end: Int32 = GRID_WIDTH
            var x_step: Int32 = 1
            
            # Randomize direction each row
            if random.random_ui64(0, 1) == 0:
                x_start = GRID_WIDTH - 1
                x_end = -1
                x_step = -1
            
            var x = x_start
            while x != x_end:
                var idx = PowderSim.get_grid_index(x, y)
                if idx >= 0:
                    var particle = data_ptr[].grid[idx]
                    
                    if particle == SAND:
                        PowderSim.update_sand(data_ptr, x, y)
                    elif particle == WATER:
                        PowderSim.update_water(data_ptr, x, y)
                    elif particle == FIRE:
                        PowderSim.update_fire(data_ptr, x, y)
                
                x += x_step

    @staticmethod
    fn update_sand(data_ptr: PowderSimDataPointer, x: Int32, y: Int32):
        """Update sand particle - falls down, slides diagonally"""
        var current_idx = PowderSim.get_grid_index(x, y)
        
        # Try to fall down
        var below_idx = PowderSim.get_grid_index(x, y + 1)
        if below_idx >= 0 and data_ptr[].grid[below_idx] == EMPTY:
            data_ptr[].grid[below_idx] = SAND
            data_ptr[].grid[current_idx] = EMPTY
            return
        
        # Try to slide diagonally
        var dir: Int32 = -1 if random.random_ui64(0, 1) == 0 else 1
        var diag_idx = PowderSim.get_grid_index(x + dir, y + 1)
        if diag_idx >= 0 and data_ptr[].grid[diag_idx] == EMPTY:
            data_ptr[].grid[diag_idx] = SAND
            data_ptr[].grid[current_idx] = EMPTY
            return
        
        # Try other diagonal
        diag_idx = PowderSim.get_grid_index(x - dir, y + 1)
        if diag_idx >= 0 and data_ptr[].grid[diag_idx] == EMPTY:
            data_ptr[].grid[diag_idx] = SAND
            data_ptr[].grid[current_idx] = EMPTY

    @staticmethod
    fn update_water(data_ptr: PowderSimDataPointer, x: Int32, y: Int32):
        """Update water particle - falls, spreads horizontally"""
        var current_idx = PowderSim.get_grid_index(x, y)
        
        # Try to fall down
        var below_idx = PowderSim.get_grid_index(x, y + 1)
        if below_idx >= 0 and data_ptr[].grid[below_idx] == EMPTY:
            data_ptr[].grid[below_idx] = WATER
            data_ptr[].grid[current_idx] = EMPTY
            return
        
        # Try to spread horizontally
        var dir: Int32 = -1 if random.random_ui64(0, 1) == 0 else 1
        var side_idx = PowderSim.get_grid_index(x + dir, y)
        if side_idx >= 0 and data_ptr[].grid[side_idx] == EMPTY:
            data_ptr[].grid[side_idx] = WATER
            data_ptr[].grid[current_idx] = EMPTY
            return
        
        # Try other side
        side_idx = PowderSim.get_grid_index(x - dir, y)
        if side_idx >= 0 and data_ptr[].grid[side_idx] == EMPTY:
            data_ptr[].grid[side_idx] = WATER
            data_ptr[].grid[current_idx] = EMPTY
            return
        
        # Try diagonal down
        var diag_idx = PowderSim.get_grid_index(x + dir, y + 1)
        if diag_idx >= 0 and data_ptr[].grid[diag_idx] == EMPTY:
            data_ptr[].grid[diag_idx] = WATER
            data_ptr[].grid[current_idx] = EMPTY

    @staticmethod
    fn update_fire(data_ptr: PowderSimDataPointer, x: Int32, y: Int32):
        """Update fire particle - rises, burns wood, dies randomly"""
        var current_idx = PowderSim.get_grid_index(x, y)
        
        # Fire has a chance to die
        if random.random_ui64(0, 10) < 3:
            data_ptr[].grid[current_idx] = EMPTY
            return
        
        # Check for wood to burn
        for dx in range(-1, 2):
            for dy in range(-1, 2):
                var neighbor_idx = PowderSim.get_grid_index(x + dx, y + dy)
                if neighbor_idx >= 0 and data_ptr[].grid[neighbor_idx] == WOOD:
                    if random.random_ui64(0, 10) < 5:
                        data_ptr[].grid[neighbor_idx] = FIRE
        
        # Try to rise
        var above_idx = PowderSim.get_grid_index(x, y - 1)
        if above_idx >= 0 and data_ptr[].grid[above_idx] == EMPTY:
            data_ptr[].grid[above_idx] = FIRE
            data_ptr[].grid[current_idx] = EMPTY
            return
        
        # Spread horizontally
        var dir: Int32 = -1 if random.random_ui64(0, 1) == 0 else 1
        var side_idx = PowderSim.get_grid_index(x + dir, y)
        if side_idx >= 0 and data_ptr[].grid[side_idx] == EMPTY:
            data_ptr[].grid[side_idx] = FIRE
            data_ptr[].grid[current_idx] = EMPTY

    @staticmethod
    fn render_grid(data_ptr: PowderSimDataPointer):
        """Render the particle grid to the surface"""
        if not data_ptr[].surface:
            return
        
        var cr = cairo_create(data_ptr[].surface)
        
        # Get the actual surface dimensions
        var surface_width = external_call["cairo_image_surface_get_width", Int32](data_ptr[].surface)
        var surface_height = external_call["cairo_image_surface_get_height", Int32](data_ptr[].surface)
        
        # Background
        cairo_set_source_rgb(cr, 0.1, 0.1, 0.15)
        cairo_paint(cr)
        
        # Calculate pixel size based on surface dimensions
        var pixel_width = Float64(surface_width) / Float64(GRID_WIDTH)
        var pixel_height = Float64(surface_height) / Float64(GRID_HEIGHT)
        
        # Draw particles
        for y in range(GRID_HEIGHT):
            for x in range(GRID_WIDTH):
                var idx = PowderSim.get_grid_index(x, y)
                if idx >= 0:
                    var particle = data_ptr[].grid[idx]
                    if particle != EMPTY:
                        var colors = PowderSim.get_particle_color(particle)
                        
                        cairo_set_source_rgb(cr, colors.r, colors.g, colors.b)
                        cairo_rectangle(cr, 
                            Float64(x) * pixel_width, 
                            Float64(y) * pixel_height,
                            pixel_width, 
                            pixel_height)
                        cairo_fill(cr)
        
        cairo_destroy(cr)

    @staticmethod
    fn on_draw(area: ptr, cr: ptr, width: Int32, height: Int32, user_data: ptr):
        """Draw callback"""
        try:
            var data_ptr = rebind[PowderSimDataPointer](user_data)
            
            # Create surface to match actual widget size
            if not data_ptr[].surface:
                data_ptr[].surface = cairo_image_surface_create(
                    CAIRO_FORMAT_ARGB32, 
                    width, 
                    height
                )
            
            # Recreate surface if size changed
            var current_width = external_call["cairo_image_surface_get_width", Int32](data_ptr[].surface)
            var current_height = external_call["cairo_image_surface_get_height", Int32](data_ptr[].surface)
            
            if current_width != width or current_height != height:
                # Size changed, recreate surface
                data_ptr[].surface = cairo_image_surface_create(
                    CAIRO_FORMAT_ARGB32, 
                    width, 
                    height
                )
            
            # Draw the surface
            cairo_set_source_surface(cr, data_ptr[].surface, 0.0, 0.0)
            cairo_paint(cr)
            
        except e:
            print("Error in on_draw:", e)

    @staticmethod
    fn on_timer(user_data: ptr) -> Bool:
        """Timer callback for physics updates"""
        try:
            var data_ptr = rebind[PowderSimDataPointer](user_data)
            PowderSim.update_physics(data_ptr)
            PowderSim.render_grid(data_ptr)
            gtk_widget_queue_draw(data_ptr[].drawing_area)
        except e:
            print("Error in timer:", e)
        return True

    @staticmethod
    fn place_particle(data_ptr: PowderSimDataPointer, x: Float64, y: Float64):
        """Place particle at position with brush"""
        if not data_ptr[].surface:
            return
            
        # Get surface dimensions
        var surface_width = external_call["cairo_image_surface_get_width", Int32](data_ptr[].surface)
        var surface_height = external_call["cairo_image_surface_get_height", Int32](data_ptr[].surface)
        
        # Convert screen coordinates to grid coordinates
        var grid_x = Int32((x / Float64(surface_width)) * Float64(GRID_WIDTH))
        var grid_y = Int32((y / Float64(surface_height)) * Float64(GRID_HEIGHT))
        
        for dx in range(-data_ptr[].brush_size, data_ptr[].brush_size + 1):
            for dy in range(-data_ptr[].brush_size, data_ptr[].brush_size + 1):
                var px = grid_x + dx
                var py = grid_y + dy
                var idx = PowderSim.get_grid_index(px, py)
                if idx >= 0:
                    # Don't overwrite stone
                    if data_ptr[].grid[idx] != STONE or data_ptr[].current_particle == EMPTY:
                        data_ptr[].grid[idx] = data_ptr[].current_particle

    @staticmethod
    fn on_drag_begin(gesture: ptr, x: Float64, y: Float64, user_data: ptr):
        try:
            var data_ptr = rebind[PowderSimDataPointer](user_data)
            data_ptr[].is_drawing = True
            PowderSim.place_particle(data_ptr, x, y)
        except:
            pass

    @staticmethod
    fn on_drag_update(gesture: ptr, offset_x: Float64, offset_y: Float64, user_data: ptr):
        try:
            var data_ptr = rebind[PowderSimDataPointer](user_data)
            if data_ptr[].is_drawing:
                var start_x: Float64 = 0.0
                var start_y: Float64 = 0.0
                gtk_gesture_drag_get_start_point(gesture, 
                    LegacyUnsafePointer[Float64](to=start_x), 
                    LegacyUnsafePointer[Float64](to=start_y))
                
                PowderSim.place_particle(data_ptr, start_x + offset_x, start_y + offset_y)
        except:
            pass

    @staticmethod
    fn on_drag_end(gesture: ptr, offset_x: Float64, offset_y: Float64, user_data: ptr):
        try:
            var data_ptr = rebind[PowderSimDataPointer](user_data)
            data_ptr[].is_drawing = False
        except:
            pass

    # Button callbacks
    @staticmethod
    fn on_sand_clicked(button: ptr, user_data: ptr):
        var data_ptr = rebind[PowderSimDataPointer](user_data)
        data_ptr[].current_particle = SAND
        print("Sand selected")

    @staticmethod
    fn on_water_clicked(button: ptr, user_data: ptr):
        var data_ptr = rebind[PowderSimDataPointer](user_data)
        data_ptr[].current_particle = WATER
        print("Water selected")

    @staticmethod
    fn on_stone_clicked(button: ptr, user_data: ptr):
        var data_ptr = rebind[PowderSimDataPointer](user_data)
        data_ptr[].current_particle = STONE
        print("Stone selected")

    @staticmethod
    fn on_fire_clicked(button: ptr, user_data: ptr):
        var data_ptr = rebind[PowderSimDataPointer](user_data)
        data_ptr[].current_particle = FIRE
        print("Fire selected")

    @staticmethod
    fn on_wood_clicked(button: ptr, user_data: ptr):
        var data_ptr = rebind[PowderSimDataPointer](user_data)
        data_ptr[].current_particle = WOOD
        print("Wood selected")

    @staticmethod
    fn on_eraser_clicked(button: ptr, user_data: ptr):
        var data_ptr = rebind[PowderSimDataPointer](user_data)
        data_ptr[].current_particle = EMPTY
        print("Eraser selected")

    @staticmethod
    fn on_clear_clicked(button: ptr, user_data: ptr):
        try:
            var data_ptr = rebind[PowderSimDataPointer](user_data)
            var grid_size = Int(GRID_WIDTH * GRID_HEIGHT)
            for i in range(grid_size):
                data_ptr[].grid[i] = EMPTY
            print("Grid cleared")
        except:
            pass

    @staticmethod
    fn on_pause_clicked(button: ptr, user_data: ptr):
        var data_ptr = rebind[PowderSimDataPointer](user_data)
        data_ptr[].paused = not data_ptr[].paused
        if data_ptr[].paused:
            print("Paused")
        else:
            print("Resumed")

    @staticmethod
    fn activate(app: ptr, gptr: ptr):
        try:
            var win = gtk_application_window_new(app)
            gtk_window_set_title(win, "Powder Physics Simulator")
            gtk_window_set_default_size(win, 1240, 960)
            
            # CSS - Clean, professional design
            var css_provider = gtk_css_provider_new()
            gtk_css_provider_load_from_string(css_provider, """
                window {
                    background: #1e1e1e;
                }
                
                .toolbar {
                    background: #2d2d2d;
                    padding: 12px 16px;
                    border-bottom: 1px solid #3e3e3e;
                }
                
                .tool-btn {
                    background: #3e3e3e;
                    color: #e0e0e0;
                    border-radius: 4px;
                    padding: 8px 16px;
                    margin: 0 4px;
                    font-size: 13px;
                    font-weight: 500;
                    border: 1px solid #4e4e4e;
                    min-width: 80px;
                }
                
                .tool-btn:hover {
                    background: #4e4e4e;
                    border-color: #5e5e5e;
                }
                
                .tool-btn:active {
                    background: #2e2e2e;
                }
                
                .canvas-area {
                    background: #0d0d0d;
                    margin: 0;
                }
                
                .control-btn {
                    background: #3e3e3e;
                    color: #e0e0e0;
                    border-radius: 4px;
                    padding: 8px 20px;
                    margin: 0 4px;
                    font-size: 13px;
                    font-weight: 500;
                    border: 1px solid #4e4e4e;
                }
                
                .control-btn:hover {
                    background: #4e4e4e;
                }
            """)
            
            gtk_style_context_add_provider_for_display(
                gtk_widget_get_display(win),
                css_provider,
                800
            )
            
            # Main layout
            var main_box = gtk_box_new(1, 0)
            
            # Toolbar
            var toolbar = gtk_box_new(0, 8)
            gtk_widget_add_css_class(toolbar, "toolbar")
            
            var sand_btn = gtk_button_new_with_label("Sand")
            var water_btn = gtk_button_new_with_label("Water")
            var stone_btn = gtk_button_new_with_label("Stone")
            var fire_btn = gtk_button_new_with_label("Fire")
            var wood_btn = gtk_button_new_with_label("Wood")
            var eraser_btn = gtk_button_new_with_label("Eraser")
            
            gtk_widget_add_css_class(sand_btn, "tool-btn")
            gtk_widget_add_css_class(water_btn, "tool-btn")
            gtk_widget_add_css_class(stone_btn, "tool-btn")
            gtk_widget_add_css_class(fire_btn, "tool-btn")
            gtk_widget_add_css_class(wood_btn, "tool-btn")
            gtk_widget_add_css_class(eraser_btn, "tool-btn")
            
            gtk_box_append(toolbar, sand_btn)
            gtk_box_append(toolbar, water_btn)
            gtk_box_append(toolbar, stone_btn)
            gtk_box_append(toolbar, fire_btn)
            gtk_box_append(toolbar, wood_btn)
            gtk_box_append(toolbar, eraser_btn)
            
            # Spacer
            var spacer = gtk_box_new(0, 0)
            gtk_widget_set_hexpand(spacer, True)
            gtk_box_append(toolbar, spacer)
            
            var pause_btn = gtk_button_new_with_label("Pause")
            var clear_btn = gtk_button_new_with_label("Clear")
            gtk_widget_add_css_class(pause_btn, "control-btn")
            gtk_widget_add_css_class(clear_btn, "control-btn")
            gtk_box_append(toolbar, pause_btn)
            gtk_box_append(toolbar, clear_btn)
            
            # Drawing area - FILL THE ENTIRE SCREEN
            var drawing_area = gtk_drawing_area_new()
            gtk_widget_add_css_class(drawing_area, "canvas-area")
            gtk_widget_set_vexpand(drawing_area, True)
            gtk_widget_set_hexpand(drawing_area, True)
            # Don't set fixed content size - let it expand!
            
            # Initialize data
            var data = PowderSimData(drawing_area)
            var data_ptr = PowderSimDataPointer.alloc(1)
            data_ptr[] = data
            
            # Connect drawing
            external_call["gtk_drawing_area_set_draw_func", NoneType](
                drawing_area,
                PowderSim.on_draw,
                rebind[ptr](data_ptr),
                None
            )
            
            # Add drag gesture
            var drag_gesture = gtk_gesture_drag_new()
            gtk_widget_add_controller(drawing_area, drag_gesture)
            
            _ = g_signal_connect_data(drag_gesture, "drag-begin", 
                PowderSim.on_drag_begin, rebind[ptr](data_ptr), None, 0)
            _ = g_signal_connect_data(drag_gesture, "drag-update", 
                PowderSim.on_drag_update, rebind[ptr](data_ptr), None, 0)
            _ = g_signal_connect_data(drag_gesture, "drag-end", 
                PowderSim.on_drag_end, rebind[ptr](data_ptr), None, 0)
            
            # Connect buttons
            _ = g_signal_connect_data(sand_btn, "clicked", PowderSim.on_sand_clicked, rebind[ptr](data_ptr), None, 0)
            _ = g_signal_connect_data(water_btn, "clicked", PowderSim.on_water_clicked, rebind[ptr](data_ptr), None, 0)
            _ = g_signal_connect_data(stone_btn, "clicked", PowderSim.on_stone_clicked, rebind[ptr](data_ptr), None, 0)
            _ = g_signal_connect_data(fire_btn, "clicked", PowderSim.on_fire_clicked, rebind[ptr](data_ptr), None, 0)
            _ = g_signal_connect_data(wood_btn, "clicked", PowderSim.on_wood_clicked, rebind[ptr](data_ptr), None, 0)
            _ = g_signal_connect_data(eraser_btn, "clicked", PowderSim.on_eraser_clicked, rebind[ptr](data_ptr), None, 0)
            _ = g_signal_connect_data(clear_btn, "clicked", PowderSim.on_clear_clicked, rebind[ptr](data_ptr), None, 0)
            _ = g_signal_connect_data(pause_btn, "clicked", PowderSim.on_pause_clicked, rebind[ptr](data_ptr), None, 0)
            
            # Start timer for physics updates (30 FPS)
            data_ptr[].timer_id = g_timeout_add(33, PowderSim.on_timer, rebind[ptr](data_ptr))
            
            # Assemble UI
            gtk_box_append(main_box, toolbar)
            gtk_box_append(main_box, drawing_area)
            
            gtk_window_set_child(win, main_box)
            gtk_widget_show(win)
            gtk_window_present(win)
            
            print("Powder simulator initialized")
            print("Click and drag to place particles")
            
        except e:
            print("ERROR: Failed to create simulator!", e)

fn main() raises:
    var app = gtk_application_new("dev.mojo.powder.sim", 0)
    _ = g_signal_connect_data(app, "activate", PowderSim.activate, ptr(), None, 0)
    _ = g_application_run(app, 0, ptr())