from gtk import *
from sys.ffi import CStringSlice
from memory import UnsafePointer

comptime ptr = LegacyUnsafePointer[NoneType]

@register_passable("trivial")
struct LayoutDemo:
    @staticmethod
    fn on_grid_button_clicked(button: ptr, gptr: ptr):
        print("Grid button clicked!")
    
    @staticmethod
    fn on_paned_position_changed(paned: ptr, gptr: ptr):
        try:
            var pos = gtk_paned_get_position(paned)
            print("Paned position:", pos)
        except:
            pass

    @staticmethod
    fn create_header(title: String) -> ptr:
        try:
            var label = gtk_label_new(title)
            gtk_widget_add_css_class(label, "title-2")
            gtk_widget_set_margin_top(label, 8)
            gtk_widget_set_margin_bottom(label, 8)
            return label
        except:
            return ptr()

    @staticmethod
    fn activate(app: ptr, gptr: ptr):
        try:
            # Window
            var win = gtk_application_window_new(app)
            gtk_window_set_title(win, "Mojo GTK4 Layout Demo")
            gtk_window_set_default_size(win, 1000, 700)

            # Main notebook for tabs
            var notebook = gtk_notebook_new()
            gtk_notebook_set_tab_pos(notebook, 2)  # Top tabs

            # ============ TAB 1: GRID LAYOUT ============
            var grid_page = gtk_box_new(1, 16)
            gtk_widget_set_margin_top(grid_page, 20)
            gtk_widget_set_margin_bottom(grid_page, 20)
            gtk_widget_set_margin_start(grid_page, 20)
            gtk_widget_set_margin_end(grid_page, 20)

            gtk_box_append(grid_page, LayoutDemo.create_header("Grid Layout - Organized in Rows & Columns"))

            var grid = gtk_grid_new()
            gtk_grid_set_row_spacing(grid, 12)
            gtk_grid_set_column_spacing(grid, 12)
            gtk_widget_set_hexpand(grid, True)

            # Create grid items
            var colors = List[String]()
            colors.append("suggested-action")
            colors.append("destructive-action")
            colors.append("success")
            colors.append("warning")
            colors.append("error")
            colors.append("accent")

            for row in range(3):
                for col in range(4):
                    var idx = row * 4 + col
                    var btn = gtk_button_new_with_label("Button " + String(idx + 1))
                    if idx < len(colors):
                        gtk_widget_add_css_class(btn, colors[idx])
                    gtk_widget_set_hexpand(btn, True)
                    gtk_widget_set_vexpand(btn, True)
                    _ = g_signal_connect_data(btn, "clicked", rebind[ptr](LayoutDemo.on_grid_button_clicked), ptr(), None, 0)
                    gtk_grid_attach(grid, btn, col, row, 1, 1)

            gtk_box_append(grid_page, grid)

            # Grid spanning example
            gtk_box_append(grid_page, gtk_label_new("Spanning cells:"))
            var grid2 = gtk_grid_new()
            gtk_grid_set_row_spacing(grid2, 8)
            gtk_grid_set_column_spacing(grid2, 8)
            
            var span_btn1 = gtk_button_new_with_label("Spans 2 columns")
            var span_btn2 = gtk_button_new_with_label("Spans 2 rows")
            var normal1 = gtk_button_new_with_label("Normal")
            var normal2 = gtk_button_new_with_label("Normal")
            
            gtk_grid_attach(grid2, span_btn1, 0, 0, 2, 1)  # Span 2 columns
            gtk_grid_attach(grid2, span_btn2, 2, 0, 1, 2)  # Span 2 rows
            gtk_grid_attach(grid2, normal1, 0, 1, 1, 1)
            gtk_grid_attach(grid2, normal2, 1, 1, 1, 1)
            
            gtk_box_append(grid_page, grid2)

            var grid_label = gtk_label_new("Grid Layout Demo")
            gtk_notebook_append_page(notebook, grid_page, grid_label)

            # ============ TAB 2: PANED (SPLIT VIEW) ============
            var paned_page = gtk_box_new(1, 16)
            gtk_widget_set_margin_top(paned_page, 20)
            gtk_widget_set_margin_bottom(paned_page, 20)
            gtk_widget_set_margin_start(paned_page, 20)
            gtk_widget_set_margin_end(paned_page, 20)

            gtk_box_append(paned_page, LayoutDemo.create_header("Paned - Resizable Split Containers"))

            # Horizontal paned
            var h_paned = gtk_paned_new(0)  # Horizontal
            gtk_widget_set_vexpand(h_paned, True)
            
            var left_box = gtk_box_new(1, 8)
            gtk_widget_add_css_class(left_box, "card")
            gtk_widget_set_margin_top(left_box, 12)
            gtk_widget_set_margin_bottom(left_box, 12)
            gtk_widget_set_margin_start(left_box, 12)
            gtk_widget_set_margin_end(left_box, 12)
            gtk_box_append(left_box, gtk_label_new("Left Pane"))
            gtk_box_append(left_box, gtk_button_new_with_label("Button 1"))
            gtk_box_append(left_box, gtk_button_new_with_label("Button 2"))
            
            # Nested vertical paned
            var v_paned = gtk_paned_new(1)  # Vertical
            
            var top_box = gtk_box_new(1, 8)
            gtk_widget_add_css_class(top_box, "card")
            gtk_widget_set_margin_top(top_box, 12)
            gtk_widget_set_margin_bottom(top_box, 12)
            gtk_widget_set_margin_start(top_box, 12)
            gtk_widget_set_margin_end(top_box, 12)
            gtk_box_append(top_box, gtk_label_new("Top Right Pane"))
            gtk_box_append(top_box, gtk_entry_new())
            
            var bottom_box = gtk_box_new(1, 8)
            gtk_widget_add_css_class(bottom_box, "card")
            gtk_widget_set_margin_top(bottom_box, 12)
            gtk_widget_set_margin_bottom(bottom_box, 12)
            gtk_widget_set_margin_start(bottom_box, 12)
            gtk_widget_set_margin_end(bottom_box, 12)
            gtk_box_append(bottom_box, gtk_label_new("Bottom Right Pane"))
            var text_view = gtk_text_view_new()
            gtk_widget_set_size_request(text_view, -1, 100)
            gtk_box_append(bottom_box, text_view)
            
            gtk_paned_set_start_child(v_paned, top_box)
            gtk_paned_set_end_child(v_paned, bottom_box)
            gtk_paned_set_position(v_paned, 150)
            
            gtk_paned_set_start_child(h_paned, left_box)
            gtk_paned_set_end_child(h_paned, v_paned)
            gtk_paned_set_position(h_paned, 300)
            
            gtk_box_append(paned_page, h_paned)

            var paned_label = gtk_label_new("Paned Layout")
            gtk_notebook_append_page(notebook, paned_page, paned_label)

            # ============ TAB 3: FLOWBOX ============
            var flow_page = gtk_box_new(1, 16)
            gtk_widget_set_margin_top(flow_page, 20)
            gtk_widget_set_margin_bottom(flow_page, 20)
            gtk_widget_set_margin_start(flow_page, 20)
            gtk_widget_set_margin_end(flow_page, 20)

            gtk_box_append(flow_page, LayoutDemo.create_header("FlowBox - Dynamic Wrapping Layout"))

            var flowbox = gtk_flow_box_new()
            gtk_flow_box_set_selection_mode(flowbox, 0)  # None
            gtk_flow_box_set_max_children_per_line(flowbox, 5)
            gtk_flow_box_set_row_spacing(flowbox, 12)
            gtk_flow_box_set_column_spacing(flowbox, 12)
            gtk_widget_set_vexpand(flowbox, True)

            # Add items to flowbox
            for i in range(20):
                var item_box = gtk_box_new(1, 8)
                gtk_widget_add_css_class(item_box, "card")
                gtk_widget_set_size_request(item_box, 120, 100)
                
                var icon = gtk_image_new_from_icon_name("folder-symbolic")
                gtk_image_set_pixel_size(icon, 48)
                
                var label = gtk_label_new("Item " + String(i + 1))
                
                gtk_box_append(item_box, icon)
                gtk_box_append(item_box, label)
                
                gtk_flow_box_insert(flowbox, item_box, -1)

            var flow_scroll = gtk_scrolled_window_new()
            gtk_scrolled_window_set_child(flow_scroll, flowbox)
            gtk_scrolled_window_set_policy(flow_scroll, 0, 1)  # Never horizontal, automatic vertical
            
            gtk_box_append(flow_page, flow_scroll)

            var flow_label = gtk_label_new("FlowBox")
            gtk_notebook_append_page(notebook, flow_page, flow_label)

            # ============ TAB 4: OVERLAY ============
            var overlay_page = gtk_box_new(1, 16)
            gtk_widget_set_margin_top(overlay_page, 20)
            gtk_widget_set_margin_bottom(overlay_page, 20)
            gtk_widget_set_margin_start(overlay_page, 20)
            gtk_widget_set_margin_end(overlay_page, 20)

            gtk_box_append(overlay_page, LayoutDemo.create_header("Overlay - Layered Widgets"))

            var overlay = gtk_overlay_new()
            gtk_widget_set_size_request(overlay, 400, 300)
            
            # Base layer
            var base = gtk_box_new(1, 0)
            gtk_widget_add_css_class(base, "card")
            var base_label = gtk_label_new("Base Layer\n(Background)")
            gtk_widget_set_vexpand(base_label, True)
            gtk_box_append(base, base_label)
            gtk_overlay_set_child(overlay, base)
            
            # Overlay buttons at different positions
            var overlay_btn1 = gtk_button_new_with_label("Top Overlay")
            gtk_widget_set_halign(overlay_btn1, 3)  # Center
            gtk_widget_set_valign(overlay_btn1, 1)  # Start (top)
            gtk_widget_set_margin_top(overlay_btn1, 20)
            gtk_overlay_add_overlay(overlay, overlay_btn1)
            
            var overlay_btn2 = gtk_button_new_with_label("Bottom Right")
            gtk_widget_set_halign(overlay_btn2, 2)  # End (right)
            gtk_widget_set_valign(overlay_btn2, 2)  # End (bottom)
            gtk_widget_set_margin_end(overlay_btn2, 20)
            gtk_widget_set_margin_bottom(overlay_btn2, 20)
            gtk_overlay_add_overlay(overlay, overlay_btn2)
            
            var center_box = gtk_box_new(1, 8)
            gtk_widget_add_css_class(center_box, "card")
            gtk_widget_set_halign(center_box, 3)  # Center
            gtk_widget_set_valign(center_box, 3)  # Center
            gtk_widget_set_size_request(center_box, 200, 100)
            gtk_box_append(center_box, gtk_label_new("Centered Overlay"))
            gtk_box_append(center_box, gtk_button_new_with_label("Click Me"))
            gtk_overlay_add_overlay(overlay, center_box)
            
            gtk_box_append(overlay_page, overlay)
            gtk_box_append(overlay_page, gtk_label_new("Overlay allows stacking widgets on top of each other"))

            var overlay_label = gtk_label_new("Overlay")
            gtk_notebook_append_page(notebook, overlay_page, overlay_label)

            # ============ TAB 5: LISTBOX ============
            var list_page = gtk_box_new(1, 16)
            gtk_widget_set_margin_top(list_page, 20)
            gtk_widget_set_margin_bottom(list_page, 20)
            gtk_widget_set_margin_start(list_page, 20)
            gtk_widget_set_margin_end(list_page, 20)

            gtk_box_append(list_page, LayoutDemo.create_header("ListBox - Selectable List Container"))

            var listbox = gtk_list_box_new()
            gtk_widget_add_css_class(listbox, "boxed-list")
            
            for i in range(10):
                var row_box = gtk_box_new(0, 12)
                gtk_widget_set_margin_top(row_box, 8)
                gtk_widget_set_margin_bottom(row_box, 8)
                gtk_widget_set_margin_start(row_box, 12)
                gtk_widget_set_margin_end(row_box, 12)
                
                var icon = gtk_image_new_from_icon_name("mail-unread-symbolic")
                var text_box = gtk_box_new(1, 4)
                var title = gtk_label_new("List Item " + String(i + 1))
                gtk_widget_set_halign(title, 1)  # Left align
                var subtitle = gtk_label_new("This is a subtitle for item " + String(i + 1))
                gtk_widget_set_halign(subtitle, 1)  # Left align
                gtk_widget_add_css_class(subtitle, "dim-label")
                
                gtk_box_append(text_box, title)
                gtk_box_append(text_box, subtitle)
                gtk_widget_set_hexpand(text_box, True)
                
                var action_btn = gtk_button_new_from_icon_name("user-trash-symbolic")
                gtk_widget_add_css_class(action_btn, "flat")
                
                gtk_box_append(row_box, icon)
                gtk_box_append(row_box, text_box)
                gtk_box_append(row_box, action_btn)
                
                gtk_list_box_append(listbox, row_box)

            var list_scroll = gtk_scrolled_window_new()
            gtk_scrolled_window_set_child(list_scroll, listbox)
            gtk_scrolled_window_set_policy(list_scroll, 0, 1)
            gtk_widget_set_vexpand(list_scroll, True)
            
            gtk_box_append(list_page, list_scroll)

            var list_label = gtk_label_new("ListBox")
            gtk_notebook_append_page(notebook, list_page, list_label)

            gtk_window_set_child(win, notebook)
            gtk_widget_show(win)

        except:
            print("ERROR: activation failed")

fn main() raises:
    var app = gtk_application_new("dev.mojo.layoutdemo", 0)
    _ = g_signal_connect_data(app, "activate", rebind[ptr](LayoutDemo.activate), ptr(), None, 0)
    _ = g_application_run(app, 0, ptr())