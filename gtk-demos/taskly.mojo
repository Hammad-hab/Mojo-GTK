from gtk import *
from sys.ffi import CStringSlice, c_char
from memory import UnsafePointer

comptime ptr = LegacyUnsafePointer[NoneType]

@register_passable("trivial")
struct ModernApp:
    @staticmethod
    fn on_add_task(button: ptr, entry_ptr: ptr):
        try:
            var entry = entry_ptr
            var buffer = gtk_entry_buffer_get_text(gtk_entry_get_buffer(entry))
            var text = CStringSlice(unsafe_from_ptr=buffer)
            var task = ""
            text.write_to(task)
            if len(task) > 0:
                print("New task:", task)
                # gtk_entry_set_text(entry, "")
        except:
            pass
    
    @staticmethod
    fn on_nav_clicked(button: ptr, label_ptr: ptr):
        print("Navigation clicked")
    
    @staticmethod
    fn on_task_toggle(check: ptr, gptr: ptr):
        try:
            var active = gtk_check_button_get_active(check)
            print("Task toggled:", active)
        except:
            pass

    @staticmethod
    fn create_task_item(title: String, subtitle: String, priority: Int) raises -> ptr:
        var row = gtk_box_new(0, 16)
        gtk_widget_set_margin_top(row, 12)
        gtk_widget_set_margin_bottom(row, 12)
        gtk_widget_set_margin_start(row, 16)
        gtk_widget_set_margin_end(row, 16)
        
        # Checkbox
        var check = gtk_check_button_new()
        gtk_widget_set_valign(check, 3)
        _ = g_signal_connect_data(check, "toggled", (ModernApp.on_task_toggle), ptr(), None, 0)
        
        # Content
        var content = gtk_box_new(1, 6)
        gtk_widget_set_hexpand(content, True)
        
        var title_label = gtk_label_new(title)
        gtk_widget_add_css_class(title_label, "task-title")
        gtk_widget_set_halign(title_label, 1)
        gtk_label_set_ellipsize(title_label, 3)  # End ellipsize
        
        var subtitle_label = gtk_label_new(subtitle)
        gtk_widget_add_css_class(subtitle_label, "task-subtitle")
        gtk_widget_set_halign(subtitle_label, 1)
        
        gtk_box_append(content, title_label)
        gtk_box_append(content, subtitle_label)
        
        # Priority badge
        var badge_text = "Low"
        var badge_class = "badge-low"
        if priority == 2:
            badge_text = "High"
            badge_class = "badge-high"
        elif priority == 1:
            badge_text = "Medium"
            badge_class = "badge-medium"
        
        var badge = gtk_label_new(badge_text)
        gtk_widget_add_css_class(badge, "priority-badge")
        gtk_widget_add_css_class(badge, badge_class)
        gtk_widget_set_valign(badge, 3)
        
        # More button
        var more_btn = gtk_button_new_from_icon_name("view-more-symbolic")
        gtk_widget_add_css_class(more_btn, "task-more-btn")
        gtk_widget_set_valign(more_btn, 3)
        
        gtk_box_append(row, check)
        gtk_box_append(row, content)
        gtk_box_append(row, badge)
        gtk_box_append(row, more_btn)
        
        return row

    @staticmethod
    fn load_custom_css(window: ptr) raises:
        var css_provider = gtk_css_provider_new()
        var css = """
        /* Reset and base */
        * {
            outline: none;
        }
        
        window {
            background-color: #fafafa;
        }
        
        /* Header */
        .titlebar {
            background: linear-gradient(180deg, #ffffff 0%, #fafafa 100%);
            border-bottom: 1px solid #e0e0e0;
            padding: 12px 20px;
            min-height: 56px;
        }
        
        .app-title {
            font-size: 18px;
            font-weight: 600;
            color: #1a1a1a;
            letter-spacing: -0.3px;
        }
        
        .header-icon-btn {
            background: transparent;
            border: none;
            border-radius: 8px;
            padding: 8px;
            color: #666666;
            min-width: 36px;
            min-height: 36px;
        }
        
        .header-icon-btn:hover {
            background-color: #f0f0f0;
            color: #1a1a1a;
        }
        
        .user-avatar {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border-radius: 8px;
            padding: 8px 12px;
            font-weight: 600;
            font-size: 13px;
            border: none;
            min-width: 40px;
        }
        
        .user-avatar:hover {
            opacity: 0.9;
        }
        
        /* Search */
        searchentry {
            background-color: #f5f5f5;
            border: 1px solid transparent;
            border-radius: 10px;
            padding: 8px 16px;
            min-width: 280px;
            color: #1a1a1a;
        }
        
        searchentry:focus {
            background-color: #ffffff;
            border-color: #667eea;
            box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
        }
        
        searchentry > text {
            background: transparent;
        }
        
        /* Sidebar */
        .sidebar {
            background-color: #ffffff;
            border-right: 1px solid #e8e8e8;
            padding: 24px 16px;
        }
        
        .sidebar-header {
            font-size: 11px;
            font-weight: 700;
            color: #999999;
            letter-spacing: 0.8px;
            text-transform: uppercase;
            margin-bottom: 12px;
            padding: 0 12px;
        }
        
        .nav-item {
            background: transparent;
            border: none;
            border-radius: 10px;
            padding: 11px 16px;
            margin: 3px 0;
            color: #4a4a4a;
            font-weight: 500;
            font-size: 14px;
            text-align: left;
            transition: all 120ms ease;
        }
        
        .nav-item:hover {
            background-color: #f7f7f7;
            color: #1a1a1a;
        }
        
        .nav-item:checked {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            box-shadow: 0 2px 8px rgba(102, 126, 234, 0.25);
        }
        
        .nav-item:checked:hover {
            opacity: 0.95;
        }
        
        /* Main content */
        .content-area {
            background-color: #fafafa;
            padding: 32px;
        }
        
        /* Stats section */
        .stats-container {
            margin-bottom: 32px;
        }
        
        .stat-card {
            background: white;
            border-radius: 16px;
            padding: 24px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
            border: 1px solid #f0f0f0;
            min-width: 160px;
            transition: all 200ms ease;
        }
        
        .stat-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
        }
        
        .stat-value {
            font-size: 36px;
            font-weight: 700;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            line-height: 1;
            margin-bottom: 8px;
        }
        
        .stat-label {
            font-size: 13px;
            color: #666666;
            font-weight: 500;
        }
        
        .stat-change {
            font-size: 12px;
            color: #10b981;
            font-weight: 600;
            margin-top: 4px;
        }
        
        /* Card sections */
        .card {
            background: white;
            border-radius: 16px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
            border: 1px solid #f0f0f0;
            margin-bottom: 24px;
            overflow: hidden;
        }
        
        .card-header {
            padding: 20px 24px;
            border-bottom: 1px solid #f5f5f5;
        }
        
        .card-title {
            font-size: 17px;
            font-weight: 600;
            color: #1a1a1a;
            letter-spacing: -0.2px;
        }
        
        .card-body {
            padding: 0;
        }
        
        /* Task items */
        .task-row {
            border-bottom: 1px solid #f5f5f5;
            transition: all 150ms ease;
        }
        
        .task-row:hover {
            background-color: #fafafa;
        }
        
        .task-row:last-child {
            border-bottom: none;
        }
        
        .task-title {
            font-size: 14px;
            font-weight: 500;
            color: #1a1a1a;
        }
        
        .task-subtitle {
            font-size: 13px;
            color: #999999;
        }
        
        .priority-badge {
            padding: 5px 12px;
            border-radius: 6px;
            font-size: 11px;
            font-weight: 600;
            letter-spacing: 0.3px;
        }
        
        .badge-high {
            background-color: #fee;
            color: #dc2626;
        }
        
        .badge-medium {
            background-color: #fffbeb;
            color: #d97706;
        }
        
        .badge-low {
            background-color: #eff6ff;
            color: #2563eb;
        }
        
        .task-more-btn {
            background: transparent;
            border: none;
            border-radius: 6px;
            padding: 6px;
            color: #999999;
            min-width: 32px;
            min-height: 32px;
        }
        
        .task-more-btn:hover {
            background-color: #f5f5f5;
            color: #1a1a1a;
        }
        
        /* Add task section */
        .add-task-row {
            padding: 16px 24px;
        }
        
        entry {
            background-color: #f8f8f8;
            border: 1px solid #e8e8e8;
            border-radius: 10px;
            padding: 12px 16px;
            color: #1a1a1a;
            font-size: 14px;
        }
        
        entry:focus {
            background-color: #ffffff;
            border-color: #667eea;
            box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
        }
        
        .btn-primary {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            border-radius: 10px;
            padding: 12px 24px;
            font-weight: 600;
            font-size: 14px;
            box-shadow: 0 2px 8px rgba(102, 126, 234, 0.25);
            transition: all 150ms ease;
        }
        
        .btn-primary:hover {
            box-shadow: 0 4px 12px rgba(102, 126, 234, 0.35);
            transform: translateY(-1px);
        }
        
        .btn-primary:active {
            transform: translateY(0);
        }
        
        .btn-secondary {
            background-color: #f5f5f5;
            color: #4a4a4a;
            border: 1px solid #e8e8e8;
            border-radius: 10px;
            padding: 12px 24px;
            font-weight: 500;
            font-size: 14px;
        }
        
        .btn-secondary:hover {
            background-color: #eeeeee;
            border-color: #d0d0d0;
        }
        
        /* Check buttons */
        checkbutton {
            min-width: 20px;
            min-height: 20px;
        }
        
        checkbutton check {
            border: 2px solid #d0d0d0;
            border-radius: 6px;
            min-width: 20px;
            min-height: 20px;
            background-color: white;
        }
        
        checkbutton check:checked {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border-color: #667eea;
        }
        
        /* Progress bar */
        progressbar {
            background-color: #f0f0f0;
            border-radius: 8px;
            min-height: 8px;
        }
        
        progressbar progress {
            background: linear-gradient(90deg, #667eea 0%, #764ba2 100%);
            border-radius: 8px;
        }
        
        /* Scrollbar */
        scrollbar {
            background: transparent;
            border: none;
        }
        
        scrollbar slider {
            background-color: #d0d0d0;
            border-radius: 8px;
            min-width: 8px;
            min-height: 40px;
            border: 2px solid transparent;
        }
        
        scrollbar slider:hover {
            background-color: #b0b0b0;
        }
        
        scrollbar.vertical slider {
            min-width: 8px;
        }
        
        scrollbar.horizontal slider {
            min-height: 8px;
        }
        """
        
        gtk_css_provider_load_from_string(css_provider, css)
        var display = gtk_widget_get_display(window)
        gtk_style_context_add_provider_for_display(
            display,
            css_provider,
            600
        )

    @staticmethod
    fn activate(app: ptr, gptr: ptr):
        try:
            var win = gtk_application_window_new(app)
            gtk_window_set_title(win, "Taskly")
            gtk_window_set_default_size(win, 1280, 820)
            
            ModernApp.load_custom_css(win)
            
            var main_box = gtk_box_new(1, 0)
            
            # ========== HEADER ==========
            var header = gtk_box_new(0, 16)
            gtk_widget_add_css_class(header, "titlebar")
            
            var left_header = gtk_box_new(0, 16)
            gtk_widget_set_hexpand(left_header, True)
            
            var title = gtk_label_new("Taskly")
            gtk_widget_add_css_class(title, "app-title")
            
            var search = gtk_search_entry_new()
            gtk_entry_set_placeholder_text(search, "Search tasks...")
            
            gtk_box_append(left_header, title)
            gtk_box_append(left_header, search)
            
            var right_header = gtk_box_new(0, 8)
            
            var bell_btn = gtk_button_new_from_icon_name("preferences-system-notifications-symbolic")
            gtk_widget_add_css_class(bell_btn, "header-icon-btn")
            
            var settings_btn = gtk_button_new_from_icon_name("emblem-system-symbolic")
            gtk_widget_add_css_class(settings_btn, "header-icon-btn")
            
            var user_btn = gtk_button_new_with_label("JD")
            gtk_widget_add_css_class(user_btn, "user-avatar")
            
            gtk_box_append(right_header, bell_btn)
            gtk_box_append(right_header, settings_btn)
            gtk_box_append(right_header, user_btn)
            
            gtk_box_append(header, left_header)
            gtk_box_append(header, right_header)
            gtk_box_append(main_box, header)
            
            # ========== CONTENT ==========
            var paned = gtk_paned_new(0)
            gtk_widget_set_vexpand(paned, True)
            
            # Sidebar
            var sidebar = gtk_box_new(1, 0)
            gtk_widget_add_css_class(sidebar, "sidebar")
            gtk_widget_set_size_request(sidebar, 240, -1)
            
            var nav_header = gtk_label_new("WORKSPACE")
            gtk_widget_add_css_class(nav_header, "sidebar-header")
            gtk_widget_set_halign(nav_header, 1)
            gtk_box_append(sidebar, nav_header)
            
            var navs = List[String]()
            navs.append("📋 All Tasks")
            navs.append("⭐ Important")
            navs.append("📅 Today")
            navs.append("📊 Projects")
            navs.append("✅ Completed")
            
            for i in range(len(navs)):
                var btn = gtk_toggle_button_new_with_label(navs[i])
                gtk_widget_add_css_class(btn, "nav-item")
                if i == 0:
                    gtk_toggle_button_set_active(btn, True)
                _ = g_signal_connect_data(btn, "clicked", (ModernApp.on_nav_clicked), ptr(), None, 0)
                gtk_box_append(sidebar, btn)
            
            # Main content
            var content = gtk_box_new(1, 0)
            gtk_widget_add_css_class(content, "content-area")
            
            # Stats
            var stats_box = gtk_box_new(1, 0)
            gtk_widget_add_css_class(stats_box, "stats-container")
            
            var stats_row = gtk_box_new(0, 16)
            
            var stat1 = gtk_box_new(1, 0)
            gtk_widget_add_css_class(stat1, "stat-card")
            var stat1_val = gtk_label_new("28")
            gtk_widget_add_css_class(stat1_val, "stat-value")
            var stat1_lbl = gtk_label_new("Total Tasks")
            gtk_widget_add_css_class(stat1_lbl, "stat-label")
            gtk_widget_set_halign(stat1_lbl, 1)
            var stat1_change = gtk_label_new("↑ 12% from last week")
            gtk_widget_add_css_class(stat1_change, "stat-change")
            gtk_widget_set_halign(stat1_change, 1)
            gtk_box_append(stat1, stat1_val)
            gtk_box_append(stat1, stat1_lbl)
            gtk_box_append(stat1, stat1_change)
            
            var stat2 = gtk_box_new(1, 0)
            gtk_widget_add_css_class(stat2, "stat-card")
            var stat2_val = gtk_label_new("19")
            gtk_widget_add_css_class(stat2_val, "stat-value")
            var stat2_lbl = gtk_label_new("Completed")
            gtk_widget_add_css_class(stat2_lbl, "stat-label")
            gtk_widget_set_halign(stat2_lbl, 1)
            var stat2_change = gtk_label_new("↑ 8% from last week")
            gtk_widget_add_css_class(stat2_change, "stat-change")
            gtk_widget_set_halign(stat2_change, 1)
            gtk_box_append(stat2, stat2_val)
            gtk_box_append(stat2, stat2_lbl)
            gtk_box_append(stat2, stat2_change)
            
            var stat3 = gtk_box_new(1, 0)
            gtk_widget_add_css_class(stat3, "stat-card")
            var stat3_val = gtk_label_new("9")
            gtk_widget_add_css_class(stat3_val, "stat-value")
            var stat3_lbl = gtk_label_new("In Progress")
            gtk_widget_add_css_class(stat3_lbl, "stat-label")
            gtk_widget_set_halign(stat3_lbl, 1)
            var stat3_change = gtk_label_new("↑ 4 active now")
            gtk_widget_add_css_class(stat3_change, "stat-change")
            gtk_widget_set_halign(stat3_change, 1)
            gtk_box_append(stat3, stat3_val)
            gtk_box_append(stat3, stat3_lbl)
            gtk_box_append(stat3, stat3_change)
            
            gtk_box_append(stats_row, stat1)
            gtk_box_append(stats_row, stat2)
            gtk_box_append(stats_row, stat3)
            gtk_box_append(stats_box, stats_row)
            gtk_box_append(content, stats_box)
            
            # Add task card
            var add_card = gtk_box_new(1, 0)
            gtk_widget_add_css_class(add_card, "card")
            
            var add_header = gtk_box_new(0, 0)
            gtk_widget_add_css_class(add_header, "card-header")
            var add_title = gtk_label_new("Quick Add")
            gtk_widget_add_css_class(add_title, "card-title")
            gtk_widget_set_halign(add_title, 1)
            gtk_box_append(add_header, add_title)
            
            var add_body = gtk_box_new(0, 12)
            gtk_widget_add_css_class(add_body, "add-task-row")
            var task_entry = gtk_entry_new()
            gtk_entry_set_placeholder_text(task_entry, "What needs to be done?")
            gtk_widget_set_hexpand(task_entry, True)
            var add_btn = gtk_button_new_with_label("Add Task")
            gtk_widget_add_css_class(add_btn, "btn-primary")
            _ = g_signal_connect_data(add_btn, "clicked", (ModernApp.on_add_task), task_entry, None, 0)
            gtk_box_append(add_body, task_entry)
            gtk_box_append(add_body, add_btn)
            
            gtk_box_append(add_card, add_header)
            gtk_box_append(add_card, add_body)
            gtk_box_append(content, add_card)
            
            # Tasks card
            var tasks_card = gtk_box_new(1, 0)
            gtk_widget_add_css_class(tasks_card, "card")
            
            var tasks_header = gtk_box_new(0, 0)
            gtk_widget_add_css_class(tasks_header, "card-header")
            var tasks_title = gtk_label_new("Today's Tasks")
            gtk_widget_add_css_class(tasks_title, "card-title")
            gtk_widget_set_halign(tasks_title, 1)
            gtk_box_append(tasks_header, tasks_title)
            
            var tasks_body = gtk_box_new(1, 0)
            gtk_widget_add_css_class(tasks_body, "card-body")
            
            var task1 = gtk_box_new(0, 0)
            gtk_widget_add_css_class(task1, "task-row")
            gtk_box_append(task1, ModernApp.create_task_item("Design new landing page mockups", "Due in 2 hours • Marketing", 2))
            
            var task2 = gtk_box_new(0, 0)
            gtk_widget_add_css_class(task2, "task-row")
            gtk_box_append(task2, ModernApp.create_task_item("Review pull request #847", "Due in 45 min • Development", 2))
            
            var task3 = gtk_box_new(0, 0)
            gtk_widget_add_css_class(task3, "task-row")
            gtk_box_append(task3, ModernApp.create_task_item("Update project documentation", "Due tomorrow • Documentation", 0))
            
            var task4 = gtk_box_new(0, 0)
            gtk_widget_add_css_class(task4, "task-row")
            gtk_box_append(task4, ModernApp.create_task_item("Team standup meeting", "Due in 3 hours • Meeting", 1))
            
            var task5 = gtk_box_new(0, 0)
            gtk_widget_add_css_class(task5, "task-row")
            gtk_box_append(task5, ModernApp.create_task_item("Respond to client emails", "Due today • Communication", 1))
            
            var task6 = gtk_box_new(0, 0)
            gtk_widget_add_css_class(task6, "task-row")
            gtk_box_append(task6, ModernApp.create_task_item("Prepare Q4 presentation slides", "Due Friday • Planning", 0))
            
            gtk_box_append(tasks_body, task1)
            gtk_box_append(tasks_body, task2)
            gtk_box_append(tasks_body, task3)
            gtk_box_append(tasks_body, task4)
            gtk_box_append(tasks_body, task5)
            gtk_box_append(tasks_body, task6)
            
            gtk_box_append(tasks_card, tasks_header)
            gtk_box_append(tasks_card, tasks_body)
            gtk_box_append(content, tasks_card)
            
            var scrolled = gtk_scrolled_window_new()
            gtk_scrolled_window_set_child(scrolled, content)
            gtk_scrolled_window_set_policy(scrolled, 0, 1)
            
            gtk_paned_set_start_child(paned, sidebar)
            gtk_paned_set_end_child(paned, scrolled)
            gtk_paned_set_position(paned, 240)
            
            gtk_box_append(main_box, paned)
            gtk_window_set_child(win, main_box)
            gtk_widget_show(win)
            
        except:
            print("ERROR: activation failed")

fn main() raises:
    var app = gtk_application_new("dev.mojo.taskly", 0)
    _ = g_signal_connect_data(app, "activate", (ModernApp.activate), ptr(), None, 0)
    _ = g_application_run(app, 0, ptr())