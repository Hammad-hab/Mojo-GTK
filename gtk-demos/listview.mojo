from gtk import *
from sys.ffi import CStringSlice
from memory import UnsafePointer

comptime ptr = LegacyUnsafePointer[NoneType]

@register_passable("trivial")
struct ListsDemo:
    
    @staticmethod
    fn on_row_activated(list_view: ptr, position: UInt32, gptr: ptr):
        print("Row activated:", position)
    
    @staticmethod
    fn on_selection_changed(selection: ptr, gptr: ptr):
        try:
            var selected = gtk_single_selection_get_selected(selection)
            if selected != 4294967295:  # GTK_INVALID_LIST_POSITION
                print("Selected row:", selected)
        except:
            pass
    
    @staticmethod
    fn create_section(title: String) raises -> ptr:
        var frame = gtk_frame_new(title)
        gtk_widget_add_css_class(frame, "card")
        var box = gtk_box_new(1, 0)
        gtk_widget_set_margin_top(box, 16)
        gtk_widget_set_margin_bottom(box, 16)
        gtk_widget_set_margin_start(box, 16)
        gtk_widget_set_margin_end(box, 16)
        gtk_frame_set_child(frame, box)
        return box
    
    @staticmethod
    fn create_simple_list() raises -> ptr:
        """Create a simple string list"""
        var string_list = gtk_string_list_new(["Apple"])
        
        # Add items
        gtk_string_list_append(string_list, "Apple")
        gtk_string_list_append(string_list, "Banana")
        gtk_string_list_append(string_list, "Cherry")
        gtk_string_list_append(string_list, "Date")
        gtk_string_list_append(string_list, "Elderberry")
        gtk_string_list_append(string_list, "Fig")
        gtk_string_list_append(string_list, "Grape")
        gtk_string_list_append(string_list, "Honeydew")
        
        # Create selection model
        var selection = gtk_single_selection_new(string_list)
        
        # Create factory for rendering items
        var factory = gtk_signal_list_item_factory_new()
        _ = g_signal_connect_data[fn(factory: ptr, list_item: ptr, gptr: ptr)](factory, "setup", (ListsDemo.setup_list_item), ptr(), None, 0)
        _ = g_signal_connect_data[fn(factory: ptr, list_item: ptr, gptr: ptr)](factory, "bind", (ListsDemo.bind_list_item), ptr(), None, 0)
        
        # Create list view
        var list_view = gtk_list_view_new(selection, factory)
        
        # Connect signals
        _ = g_signal_connect_data[fn(list_view: ptr, position: UInt32, gptr: ptr)](list_view, "activate", (ListsDemo.on_row_activated), ptr(), None, 0)
        _ = g_signal_connect_data[fn(selection: ptr, gptr: ptr)](selection, "selection-changed", (ListsDemo.on_selection_changed), ptr(), None, 0)
        
        return list_view
    
    @staticmethod
    fn setup_list_item(factory: ptr, list_item: ptr, gptr: ptr):
        try:
            var label = gtk_label_new("")
            gtk_widget_set_halign(label, 1)  # Left align
            gtk_widget_set_margin_start(label, 12)
            gtk_widget_set_margin_end(label, 12)
            gtk_widget_set_margin_top(label, 8)
            gtk_widget_set_margin_bottom(label, 8)
            gtk_list_item_set_child(list_item, label)
        except:
            pass
    
    @staticmethod
    fn bind_list_item(factory: ptr, list_item: ptr, gptr: ptr):
        try:
            var label = gtk_list_item_get_child(list_item)
            var item = gtk_list_item_get_item(list_item)
            var string_obj = rebind[ptr](item)
            var ccharptr = gtk_string_object_get_string(string_obj)
            var cstr = CStringSlice(unsafe_from_ptr=ccharptr)
            var text = ""
            cstr.write_to(text)
            gtk_label_set_text(label, text)
        except:
            pass
    
    @staticmethod
    fn create_column_view() raises -> ptr:
        """Create a multi-column table view."""
        var string_list = gtk_string_list_new(["John Doe|john@example.com|Developer|5"])
        
        # Add sample data (we'll parse this in the columns)
        gtk_string_list_append(string_list, "John Doe|john@example.com|Developer|5")
        gtk_string_list_append(string_list, "Jane Smith|jane@example.com|Designer|3")
        gtk_string_list_append(string_list, "Bob Johnson|bob@example.com|Manager|8")
        gtk_string_list_append(string_list, "Alice Brown|alice@example.com|Engineer|4")
        gtk_string_list_append(string_list, "Charlie Davis|charlie@example.com|Analyst|6")
        gtk_string_list_append(string_list, "Diana Wilson|diana@example.com|Director|10")
        
        var selection = gtk_single_selection_new(string_list)
        var column_view = gtk_column_view_new(selection)
        
        # Create columns
        ListsDemo.add_column(column_view, "Name", 0)
        ListsDemo.add_column(column_view, "Email", 1)
        ListsDemo.add_column(column_view, "Role", 2)
        ListsDemo.add_column(column_view, "Years", 3)
        
        return column_view
    
    @staticmethod
    fn add_column(column_view: ptr, title: String, column_index: Int) raises:
        var factory = gtk_signal_list_item_factory_new()
        
        # Store column index in factory's data (we'll use a simple approach)
        var index_ptr = LegacyUnsafePointer[Int].alloc(1)
        index_ptr[] = column_index
        
        _ = g_signal_connect_data[fn(factory: ptr, list_item: ptr, gptr: ptr)](factory, "setup", (ListsDemo.setup_column_item), ptr(), None, 0)
        _ = g_signal_connect_data[fn(factory: ptr, list_item: ptr, gptr: ptr)](factory, "bind", (ListsDemo.bind_column_item), index_ptr.bitcast[NoneType](), None, 0)
        
        var column = gtk_column_view_column_new(title, factory)
        gtk_column_view_column_set_expand(column, True)
        gtk_column_view_append_column(column_view, column)
    
    @staticmethod
    fn setup_column_item(factory: ptr, list_item: ptr, gptr: ptr):
        try:
            var label = gtk_label_new("")
            gtk_widget_set_halign(label, 1)  # Left align
            gtk_widget_set_margin_start(label, 12)
            gtk_widget_set_margin_end(label, 12)
            gtk_widget_set_margin_top(label, 8)
            gtk_widget_set_margin_bottom(label, 8)
            gtk_list_item_set_child(list_item, label)
        except:
            pass
    
    @staticmethod
    fn bind_column_item(factory: ptr, list_item: ptr, index_ptr: ptr):
        try:
            var column_index = index_ptr.bitcast[Int]()[]
            var label = gtk_list_item_get_child(list_item)
            var item = gtk_list_item_get_item(list_item)
            var string_obj = rebind[ptr](item)
            var text = gtk_string_object_get_string(string_obj)
            
            # Parse the pipe-delimited string
            var text_str = String()
            var text_slice = CStringSlice(unsafe_from_ptr=text)
            text_slice.write_to(text_str)
            
            # Extract the column value
            var parts = text_str.split("|")
            if column_index < len(parts):
                gtk_label_set_text(label, String(parts[column_index]))
        except:
            pass
    
    @staticmethod
    fn create_list_box() raises -> ptr:
        """Create a simple ListBox (easier alternative to ListView)."""
        var list_box = gtk_list_box_new()
        gtk_list_box_set_selection_mode(list_box, 1)  # Single selection
        
        # Add rows
        var items = List[String]()
        items.append("📧 Inbox (12)")
        items.append("📤 Sent")
        items.append("📝 Drafts (3)")
        items.append("⭐ Starred")
        items.append("🗑️ Trash")
        
        for i in range(len(items)):
            var row = gtk_list_box_row_new()
            var label = gtk_label_new(items[i])
            gtk_widget_set_margin_start(label, 12)
            gtk_widget_set_margin_end(label, 12)
            gtk_widget_set_margin_top(label, 12)
            gtk_widget_set_margin_bottom(label, 12)
            gtk_widget_set_halign(label, 1)
            gtk_list_box_row_set_child(row, label)
            gtk_list_box_append(list_box, row)
        
        return list_box
    
    @staticmethod
    fn create_grid_view() raises -> ptr:
        """Create a grid view for icon-like display."""
        var string_list = gtk_string_list_new(["🎨 Design"])
        
        # Add items
        var emojis = List[String]()
        emojis.append("🎨 Design")
        emojis.append("💻 Code")
        emojis.append("📊 Data")
        emojis.append("🎵 Music")
        emojis.append("📷 Photos")
        emojis.append("🎮 Games")
        emojis.append("📚 Books")
        emojis.append("✈️ Travel")
        emojis.append("🍕 Food")
        emojis.append("⚽ Sports")
        emojis.append("🎬 Movies")
        emojis.append("🛍️ Shopping")
        
        for i in range(len(emojis)):
            gtk_string_list_append(string_list, emojis[i])
        
        var selection = gtk_single_selection_new(string_list)
        
        var factory = gtk_signal_list_item_factory_new()
        _ = g_signal_connect_data[fn(factory: ptr, list_item: ptr, gptr: ptr)](factory, "setup", (ListsDemo.setup_grid_item), ptr(), None, 0)
        _ = g_signal_connect_data[fn(factory: ptr, list_item: ptr, gptr: ptr)](factory, "bind", (ListsDemo.bind_grid_item), ptr(), None, 0)
        
        var grid_view = gtk_grid_view_new(selection, factory)
        gtk_grid_view_set_max_columns(grid_view, 4)
        gtk_grid_view_set_min_columns(grid_view, 2)
        
        return grid_view
    
    @staticmethod
    fn setup_grid_item(factory: ptr, list_item: ptr, gptr: ptr):
        try:
            var box = gtk_box_new(1, 8)
            gtk_widget_set_halign(box, 3)  # Center
            gtk_widget_set_margin_start(box, 16)
            gtk_widget_set_margin_end(box, 16)
            gtk_widget_set_margin_top(box, 16)
            gtk_widget_set_margin_bottom(box, 16)
            
            var label = gtk_label_new("")
            gtk_widget_add_css_class(label, "title-3")
            gtk_box_append(box, label)
            
            gtk_list_item_set_child(list_item, box)
        except:
            pass
    
    @staticmethod
    fn bind_grid_item(factory: ptr, list_item: ptr, gptr: ptr):
        try:
            var box = gtk_list_item_get_child(list_item)
            var label = gtk_widget_get_first_child(box)
            var item = gtk_list_item_get_item(list_item)
            var string_obj = rebind[ptr](item)
            var ccharptr = gtk_string_object_get_string(string_obj)
            var cstr = CStringSlice(unsafe_from_ptr=ccharptr)
            var text = ""
            cstr.write_to(text)
            gtk_label_set_text(label, text)
        except:
            pass

    @staticmethod
    fn activate(app: ptr, gptr: ptr):
        try:
            var win = gtk_application_window_new(app)
            gtk_window_set_title(win, "Mojo GTK4 Lists & Tables Demo")
            gtk_window_set_default_size(win, 1200, 800)

            var main_box = gtk_box_new(1, 20)
            gtk_widget_set_margin_top(main_box, 24)
            gtk_widget_set_margin_bottom(main_box, 24)
            gtk_widget_set_margin_start(main_box, 24)
            gtk_widget_set_margin_end(main_box, 24)

            # Title
            var title = gtk_label_new("Lists, Tables & Data Grids")
            gtk_widget_add_css_class(title, "title-1")
            gtk_box_append(main_box, title)
            
            # Create notebook for tabs
            var notebook = gtk_notebook_new()
            gtk_notebook_set_scrollable(notebook, True)
            
            # ============ SIMPLE LIST ============
            var list_section = ListsDemo.create_section("Simple Fruit List")
            var simple_list = ListsDemo.create_simple_list()
            print('Seg fault 1 resolved')
            
            var list_scroll = gtk_scrolled_window_new()
            gtk_scrolled_window_set_child(list_scroll, simple_list)
            gtk_scrolled_window_set_policy(list_scroll, 0, 1)
            gtk_widget_set_size_request(list_scroll, -1, 300)
            gtk_box_append(list_section, list_scroll)
            
            var list_page = gtk_widget_get_parent(list_section)
            var list_label = gtk_label_new("Simple List")
            gtk_notebook_append_page(notebook, list_page, list_label)
            
            # ============ COLUMN VIEW (TABLE) ============
            var table_section = ListsDemo.create_section("Employee Table")
            var column_view = ListsDemo.create_column_view()
            
            var table_scroll = gtk_scrolled_window_new()
            gtk_scrolled_window_set_child(table_scroll, column_view)
            gtk_scrolled_window_set_policy(table_scroll, 1, 1)
            gtk_widget_set_size_request(table_scroll, -1, 300)
            gtk_box_append(table_section, table_scroll)
            
            var table_page = gtk_widget_get_parent(table_section)
            var table_label = gtk_label_new("Table View")
            gtk_notebook_append_page(notebook, table_page, table_label)
            
            # ============ LIST BOX ============
            var listbox_section = ListsDemo.create_section("Mail Folders")
            var list_box = ListsDemo.create_list_box()
            gtk_box_append(listbox_section, list_box)
            
            var listbox_page = gtk_widget_get_parent(listbox_section)
            var listbox_label = gtk_label_new("List Box")
            gtk_notebook_append_page(notebook, listbox_page, listbox_label)
            
            # ============ GRID VIEW ============
            var grid_section = ListsDemo.create_section("Category Grid")
            var grid_view = ListsDemo.create_grid_view()
            
            var grid_scroll = gtk_scrolled_window_new()
            gtk_scrolled_window_set_child(grid_scroll, grid_view)
            gtk_scrolled_window_set_policy(grid_scroll, 0, 1)
            gtk_widget_set_size_request(grid_scroll, -1, 400)
            gtk_box_append(grid_section, grid_scroll)
            
            var grid_page = gtk_widget_get_parent(grid_section)
            var grid_label = gtk_label_new("Grid View")
            gtk_notebook_append_page(notebook, grid_page, grid_label)
            
            gtk_box_append(main_box, notebook)

            # Scrolled window for main content
            var scrolled = gtk_scrolled_window_new()
            gtk_scrolled_window_set_child(scrolled, main_box)
            gtk_scrolled_window_set_policy(scrolled, 0, 1)

            gtk_window_set_child(win, scrolled)
            gtk_widget_show(win)

        except e:
            print("ERROR: activation failed -", e)

fn main() raises:
    var app = gtk_application_new("dev.mojo.listsdemo", 0)
    _ = g_signal_connect_data(app, "activate", (ListsDemo.activate), ptr(), None, 0)
    _ = g_application_run(app, 0, ptr())