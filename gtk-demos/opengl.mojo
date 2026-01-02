from gtk import *
from sys.ffi import CStringSlice, OwnedDLHandle, c_char
import math

alias UnsafePointer = LegacyUnsafePointer
alias ptr = LegacyUnsafePointer[NoneType]
alias charptr = LegacyUnsafePointer[c_char]

# OpenGL Constants
alias GL_COLOR_BUFFER_BIT: UInt32 = 0x00004000
alias GL_DEPTH_BUFFER_BIT: UInt32 = 0x00000100
alias GL_TRIANGLES: UInt32 = 0x0004
alias GL_VERSION: UInt32 = 0x1F02
alias GL_ARRAY_BUFFER: UInt32 = 0x8892
alias GL_STATIC_DRAW: UInt32 = 0x88E4
alias GL_FLOAT: UInt32 = 0x1406
alias GL_FALSE: UInt32 = 0
alias GL_TRUE: UInt32 = 1
# alias GL_VERT÷EX_SHADER: UInt32 = 0x8B31
# alias GL_FRAGMENT_SHADER: UInt32 = 0x8DD9
comptime GL_VERTEX_SHADER   = 0x8B31
comptime GL_FRAGMENT_SHADER = 0x8B30
comptime GL_GEOMETRY_SHADER = 0x8DD9

alias GL_COMPILE_STATUS: UInt32 = 0x8B81
alias GL_LINK_STATUS: UInt32 = 0x8B82
alias GL_INFO_LOG_LENGTH: UInt32 = 0x8B84

@register_passable("trivial")
struct GLAppData:
    var gl_area: ptr
    var vbo: UInt32
    var vao: UInt32
    var program: UInt32

    fn __init__(out self, gl_area: ptr):
        self.gl_area = gl_area
        self.vbo = 0
        self.vao = 0
        self.program = 0

alias GLAppDataPointer = LegacyUnsafePointer[GLAppData]

@register_passable("trivial")
struct OpenGLApp:
    
    @staticmethod
    fn on_realize(area: ptr, user_data: ptr):
        """Called when GL context is created - initialize OpenGL here."""
        try:
            gtk_gl_area_make_current(area)
            
            var error = gtk_gl_area_get_error(area)
            # if error:
            #     print("❌ Failed to initialize OpenGL")
            #     return
            
            var gl = OwnedDLHandle("/System/Library/Frameworks/OpenGL.framework/OpenGL")
            
            # Get OpenGL version
            var glGetString = gl.get_function[fn(UInt32) -> charptr]("glGetString")
            var version_ptr = glGetString(GL_VERSION)
            if version_ptr:
                var version_str = String()
                var version_cslice = CStringSlice(unsafe_from_ptr=version_ptr)
                version_cslice.write_to(version_str)
                print("OpenGL Version:", version_str)
            
            # Get functions for modern OpenGL
            var glGenVertexArrays = gl.get_function[fn(Int32, UnsafePointer[UInt32]) -> None]("glGenVertexArrays")
            var glBindVertexArray = gl.get_function[fn(UInt32) -> None]("glBindVertexArray")
            var glGenBuffers = gl.get_function[fn(Int32, UnsafePointer[UInt32]) -> None]("glGenBuffers")
            var glBindBuffer = gl.get_function[fn(UInt32, UInt32) -> None]("glBindBuffer")
            var glBufferData = gl.get_function[fn(UInt32, Int, ptr, UInt32) -> None]("glBufferData")
            var glVertexAttribPointer = gl.get_function[fn(UInt32, Int32, UInt32, UInt8, Int32, ptr) -> None]("glVertexAttribPointer")
            var glEnableVertexAttribArray = gl.get_function[fn(UInt32) -> None]("glEnableVertexAttribArray")
            var glCreateShader = gl.get_function[fn(UInt32) -> UInt32]("glCreateShader")
            var glShaderSource = gl.get_function[fn(UInt32, Int32, UnsafePointer[charptr], ptr) -> None]("glShaderSource")
            var glCompileShader = gl.get_function[fn(UInt32) -> None]("glCompileShader")
            var glGetShaderiv = gl.get_function[fn(UInt32, UInt32, UnsafePointer[Int32]) -> None]("glGetShaderiv")
            var glGetShaderInfoLog = gl.get_function[fn(UInt32, Int32, UnsafePointer[Int32], charptr) -> None]("glGetShaderInfoLog")
            var glCreateProgram = gl.get_function[fn() -> UInt32]("glCreateProgram")
            var glAttachShader = gl.get_function[fn(UInt32, UInt32) -> None]("glAttachShader")
            var glLinkProgram = gl.get_function[fn(UInt32) -> None]("glLinkProgram")
            var glGetProgramiv = gl.get_function[fn(UInt32, UInt32, UnsafePointer[Int32]) -> None]("glGetProgramiv")
            var glGetProgramInfoLog = gl.get_function[fn(UInt32, Int32, UnsafePointer[Int32], charptr) -> None]("glGetProgramInfoLog")
            var glDeleteShader = gl.get_function[fn(UInt32) -> None]("glDeleteShader")
            var glBindAttribLocation = gl.get_function[fn(UInt32, UInt32, charptr) -> None]("glBindAttribLocation")
            var glBindFragDataLocation = gl.get_function[fn(UInt32, UInt32, charptr) -> None]("glBindFragDataLocation")
            
            var data_ptr = rebind[GLAppDataPointer](user_data)
            
            # Use simple raw strings without String wrapper
            var vertex_source = "#version 330 core\nlayout(location = 0) in vec2 position;\nvoid main() {\n    gl_Position = vec4(position, 0.0, 1.0);\n}\n\0"
            
            var vertex_shader = glCreateShader(GL_VERTEX_SHADER)
            var vs_ptr = vertex_source.unsafe_ptr()
            var vs_ptr_array = UnsafePointer[charptr].alloc(1)
            vs_ptr_array[] = rebind[charptr](vs_ptr)
            glShaderSource(vertex_shader, 1, vs_ptr_array, ptr())
            glCompileShader(vertex_shader)
            
            # Check vertex shader compilation
            var vs_success = UnsafePointer[Int32].alloc(1)
            glGetShaderiv(vertex_shader, GL_COMPILE_STATUS, vs_success)
            if vs_success[] == 0:
                print("❌ Vertex shader compilation failed!")
                var log_buffer = UnsafePointer[c_char].alloc(512)
                glGetShaderInfoLog(vertex_shader, 512, LegacyUnsafePointer[Int32](), log_buffer)
                print("Log:", String(CStringSlice(unsafe_from_ptr=log_buffer)))
                return
            else:
                print("✅ Vertex shader compiled")
            
            # Fragment shader as raw string
            var fragment_source = "#version 330 core\nout vec4 FragColor;\nvoid main() {\n    FragColor = vec4(1.0, 1.0, 0.0, 1.0);\n}\n\0"
            
            var fragment_shader = glCreateShader(GL_FRAGMENT_SHADER)
            var fs_ptr = fragment_source.unsafe_ptr()
            var fs_ptr_array = UnsafePointer[charptr].alloc(1)
            fs_ptr_array[] = rebind[charptr](fs_ptr)
            glShaderSource(fragment_shader, 1, fs_ptr_array, ptr())
            glCompileShader(fragment_shader)
            
            # Check fragment shader compilation
            var fs_success = UnsafePointer[Int32].alloc(1)
            glGetShaderiv(fragment_shader, GL_COMPILE_STATUS, fs_success)
            if fs_success[] == 0:
                print("❌ Fragment shader compilation failed!")
                var log_buffer = UnsafePointer[c_char].alloc(512)
                glGetShaderInfoLog(fragment_shader, 512, LegacyUnsafePointer[Int32](), log_buffer)
                print("Log:", String(CStringSlice(unsafe_from_ptr=log_buffer)))
                return
            else:
                print("✅ Fragment shader compiled")
            
            # Create program - DON'T bind FragDataLocation, it might be causing issues
            var program = glCreateProgram()
            glAttachShader(program, vertex_shader)
            glAttachShader(program, fragment_shader)
            
            # Link immediately without any bindings
            glLinkProgram(program)
            
            # Check program linking with better error reporting
            var prog_success = UnsafePointer[Int32].alloc(1)
            glGetProgramiv(program, GL_LINK_STATUS, prog_success)
            if prog_success[] == 0:
                print("❌ Program linking failed!")
                # Get the error log
                var log_length = UnsafePointer[Int32].alloc(1)
                glGetProgramiv(program, GL_INFO_LOG_LENGTH, log_length)
                if log_length[] > 0:
                    var log_buffer = UnsafePointer[c_char].alloc(Int(log_length[]))
                    glGetProgramInfoLog(program, log_length[], LegacyUnsafePointer[Int32](), log_buffer)
                    print("Link Log:", String(CStringSlice(unsafe_from_ptr=log_buffer)))
                return
            else:
                print("✅ Program linked successfully!")
            
            glDeleteShader(vertex_shader)
            glDeleteShader(fragment_shader)
            
            data_ptr[].program = program
            
            # Create vertex data (just positions) - use Float32 explicitly
            var vertices = UnsafePointer[Float32].alloc(6)
            # Top vertex
            vertices[0] = 0.0    # x
            vertices[1] = 0.5    # y
            # Bottom left
            vertices[2] = -0.5   # x
            vertices[3] = -0.5   # y
            # Bottom right
            vertices[4] = 0.5    # x
            vertices[5] = -0.5   # y
            
            # Create VAO
            var vao_ptr = UnsafePointer[UInt32].alloc(1)
            glGenVertexArrays(1, vao_ptr)
            data_ptr[].vao = vao_ptr[]
            glBindVertexArray(data_ptr[].vao)
            print("VAO created:", data_ptr[].vao)
            
            # Create VBO
            var vbo_ptr = UnsafePointer[UInt32].alloc(1)
            glGenBuffers(1, vbo_ptr)
            data_ptr[].vbo = vbo_ptr[]
            glBindBuffer(GL_ARRAY_BUFFER, data_ptr[].vbo)
            print("VBO created:", data_ptr[].vbo)
            
            var vertices_ptr = rebind[ptr](vertices)
            glBufferData(GL_ARRAY_BUFFER, 6 * 4, vertices_ptr, GL_STATIC_DRAW)
            
            # Setup vertex attributes - just position
            # Position attribute (location = 0) - 2 floats, stride = 2 floats (8 bytes), offset = 0
            glVertexAttribPointer(0, 2, GL_FLOAT, 0, 8, ptr())
            glEnableVertexAttribArray(0)
            
            print("✅ OpenGL initialized successfully!")
            print("Program ID:", program)
            
        except e:
            print("Error in on_realize:", e)

    @staticmethod
    fn on_render(area: ptr, context: ptr, user_data: ptr) -> Int32:
        """Called every frame to render."""
        try:
            var gl = OwnedDLHandle("/System/Library/Frameworks/OpenGL.framework/OpenGL")
            var data_ptr = rebind[GLAppDataPointer](user_data)
            
            # Get OpenGL functions
            var glClearColor = gl.get_function[fn(Float32, Float32, Float32, Float32) -> None]("glClearColor")
            var glClear = gl.get_function[fn(UInt32) -> None]("glClear")
            var glUseProgram = gl.get_function[fn(UInt32) -> None]("glUseProgram")
            var glBindVertexArray = gl.get_function[fn(UInt32) -> None]("glBindVertexArray")
            var glDrawArrays = gl.get_function[fn(UInt32, Int32, Int32) -> None]("glDrawArrays")
            
            # Clear the screen
            glClearColor(0.1, 0.15, 0.25, 1.0)
            glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
            
            # Draw triangle
            if data_ptr[].program != 0 and data_ptr[].vao != 0:
                glUseProgram(data_ptr[].program)
                glBindVertexArray(data_ptr[].vao)
                glDrawArrays(GL_TRIANGLES, 0, 3)
            
            return 1  # TRUE
            
        except e:
            print("Error in on_render:", e)
            return 0  # FALSE

    @staticmethod
    fn on_unrealize(area: ptr, user_data: ptr):
        """Called when GL context is destroyed - cleanup here."""
        try:
            gtk_gl_area_make_current(area)
            
            var gl = OwnedDLHandle("/System/Library/Frameworks/OpenGL.framework/OpenGL")
            var data_ptr = rebind[GLAppDataPointer](user_data)
            
            var glDeleteVertexArrays = gl.get_function[fn(Int32, UnsafePointer[UInt32]) -> None]("glDeleteVertexArrays")
            var glDeleteBuffers = gl.get_function[fn(Int32, UnsafePointer[UInt32]) -> None]("glDeleteBuffers")
            var glDeleteProgram = gl.get_function[fn(UInt32) -> None]("glDeleteProgram")
            
            # Clean up
            var vao_ptr = UnsafePointer[UInt32].alloc(1)
            vao_ptr[] = data_ptr[].vao
            glDeleteVertexArrays(1, vao_ptr)
            
            var vbo_ptr = UnsafePointer[UInt32].alloc(1)
            vbo_ptr[] = data_ptr[].vbo
            glDeleteBuffers(1, vbo_ptr)
            
            glDeleteProgram(data_ptr[].program)
            
            print("🧹 Cleaned up OpenGL resources")
            
        except e:
            print("Error in on_unrealize:", e)

    @staticmethod
    fn activate(app: ptr, gptr: ptr):
        try:
            var win = gtk_application_window_new(app)
            gtk_window_set_title(win, "Mojo OpenGL in GTK4 🎨")
            gtk_window_set_default_size(win, 800, 600)
            
            # CSS styling
            var css_provider = gtk_css_provider_new()
            gtk_css_provider_load_from_string(css_provider, """
                window {
                    background: #1a1a2e;
                }
                
                .gl-area {
                    background: #0f0f1e;
                    border: 3px solid #16213e;
                    border-radius: 12px;
                    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.5);
                }
                
                .info-bar {
                    background: linear-gradient(90deg, #0f3460 0%, #16213e 100%);
                    padding: 16px;
                    border-radius: 8px;
                    margin: 12px;
                }
                
                .info-label {
                    color: #e94560;
                    font-size: 16px;
                    font-weight: bold;
                }
            """)
            
            gtk_style_context_add_provider_for_display(
                gtk_widget_get_display(win),
                css_provider,
                800
            )
            
            # Create UI
            var main_box = gtk_box_new(1, 0)
            
            var info_bar = gtk_box_new(0, 8)
            gtk_widget_add_css_class(info_bar, "info-bar")
            
            var info_label = gtk_label_new("🎨 Modern OpenGL Demo - RGB Triangle")
            gtk_widget_add_css_class(info_label, "info-label")
            gtk_box_append(info_bar, info_label)
            
            var gl_area = gtk_gl_area_new()
            gtk_widget_add_css_class(gl_area, "gl-area")
            gtk_widget_set_vexpand(gl_area, True)
            gtk_widget_set_hexpand(gl_area, True)
            gtk_widget_set_margin_start(gl_area, 12)
            gtk_widget_set_margin_end(gl_area, 12)
            gtk_widget_set_margin_bottom(gl_area, 12)
            
            # Request OpenGL 3.3 Core Profile
            gtk_gl_area_set_required_version(gl_area, 3, 3)
            
            # IMPORTANT: Set use_es to False for desktop OpenGL
            gtk_gl_area_set_use_es(gl_area, False)
            
            var data = GLAppData(gl_area)
            var data_ptr = GLAppDataPointer.alloc(1)
            data_ptr[] = data
            
            _ = g_signal_connect_data(gl_area, "realize", (OpenGLApp.on_realize), rebind[ptr](data_ptr), None, 0)
            _ = g_signal_connect_data(gl_area, "render", (OpenGLApp.on_render), rebind[ptr](data_ptr), None, 0)
            _ = g_signal_connect_data(gl_area, "unrealize", (OpenGLApp.on_unrealize), rebind[ptr](data_ptr), None, 0)
            
            gtk_box_append(main_box, info_bar)
            gtk_box_append(main_box, gl_area)
            
            gtk_window_set_child(win, main_box)
            gtk_widget_show(win)
            
        except e:
            print("ERROR:", e)

fn main() raises:
    var app = gtk_application_new("dev.mojo.opengl.modern", 0)
    _ = g_signal_connect_data(app, "activate", (OpenGLApp.activate), ptr(), None, 0)
    _ = g_application_run(app, 0, ptr())