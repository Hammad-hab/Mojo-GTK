from gtk import *
from sys.ffi import CStringSlice
from memory import UnsafePointer

comptime ptr = LegacyUnsafePointer[NoneType]

@register_passable("trivial")
struct AnimationDemo:
    @staticmethod
    fn on_spin_start(button: ptr, spinner: ptr):
        try:
            gtk_spinner_start(spinner)
            gtk_widget_set_sensitive(button, False)
        except:
            print("ERROR: spinner start failed")
    
    @staticmethod
    fn on_spin_stop(button: ptr, spinner: ptr):
        try:
            gtk_spinner_stop(spinner)
        except:
            print("ERROR: spinner stop failed")
    
    @staticmethod
    fn on_progress_update(button: ptr, progress: ptr):
        try:
            var current = gtk_progress_bar_get_fraction(progress)
            var new_val = current + 0.1
            if new_val > 1.0:
                new_val = 0.0
            gtk_progress_bar_set_fraction(progress, new_val)
        except:
            print("ERROR: progress update failed")
    
    @staticmethod
    fn on_revealer_toggle(toggle: ptr, revealer: ptr):
        try:
            var active = gtk_toggle_button_get_active(toggle)
            gtk_revealer_set_reveal_child(revealer, active)
        except:
            print("ERROR: revealer toggle failed")
    
    @staticmethod
    fn on_stack_next(button: ptr, stack: ptr):
        try:
            var visible = gtk_stack_get_visible_child_name(stack)
            var cstr = CStringSlice(unsafe_from_ptr=visible)
            var vis_str = ""
            cstr.write_to(vis_str)
            if vis_str == "page1":
                gtk_stack_set_visible_child_name(stack, "page2")
            elif vis_str == "page2":
                gtk_stack_set_visible_child_name(stack, "page3")
            else:
                gtk_stack_set_visible_child_name(stack, "page1")
        except:
            print("ERROR: stack next failed")

    @staticmethod
    fn on_transition_0(button: ptr, stack: ptr):
        try:
            gtk_stack_set_transition_type(stack, 0)
        except:
            pass
    
    @staticmethod
    fn on_transition_1(button: ptr, stack: ptr):
        try:
            gtk_stack_set_transition_type(stack, 1)
        except:
            pass
    
    @staticmethod
    fn on_transition_2(button: ptr, stack: ptr):
        try:
            gtk_stack_set_transition_type(stack, 2)
        except:
            pass
    
    @staticmethod
    fn on_transition_3(button: ptr, stack: ptr):
        try:
            gtk_stack_set_transition_type(stack, 3)
        except:
            pass
    
    @staticmethod
    fn on_transition_4(button: ptr, stack: ptr):
        try:
            gtk_stack_set_transition_type(stack, 4)
        except:
            pass
    
    @staticmethod
    fn on_transition_5(button: ptr, stack: ptr):
        try:
            gtk_stack_set_transition_type(stack, 5)
        except:
            pass
    
    @staticmethod
    fn on_transition_6(button: ptr, stack: ptr):
        try:
            gtk_stack_set_transition_type(stack, 6)
        except:
            pass
    
    @staticmethod
    fn on_transition_7(button: ptr, stack: ptr):
        try:
            gtk_stack_set_transition_type(stack, 7)
        except:
            pass

    @staticmethod
    fn on_level_0(button: ptr, bar: ptr):
        try:
            gtk_level_bar_set_value(bar, 0.0)
        except:
            pass
    
    @staticmethod
    fn on_level_25(button: ptr, bar: ptr):
        try:
            gtk_level_bar_set_value(bar, 25.0)
        except:
            pass
    
    @staticmethod
    fn on_level_50(button: ptr, bar: ptr):
        try:
            gtk_level_bar_set_value(bar, 50.0)
        except:
            pass
    
    @staticmethod
    fn on_level_75(button: ptr, bar: ptr):
        try:
            gtk_level_bar_set_value(bar, 75.0)
        except:
            pass
    
    @staticmethod
    fn on_level_100(button: ptr, bar: ptr):
        try:
            gtk_level_bar_set_value(bar, 100.0)
        except:
            pass

    @staticmethod
    fn create_section(title: String) raises -> ptr:
        var frame = gtk_frame_new(title)
        gtk_widget_add_css_class(frame, "card")
        var box = gtk_box_new(1, 12)
        gtk_widget_set_margin_top(box, 16)
        gtk_widget_set_margin_bottom(box, 16)
        gtk_widget_set_margin_start(box, 16)
        gtk_widget_set_margin_end(box, 16)
        gtk_frame_set_child(frame, box)
        return box

    @staticmethod
    fn activate(app: ptr, gptr: ptr):
        try:
            var win = gtk_application_window_new(app)
            gtk_window_set_title(win, "Mojo GTK4 Animation & Effects Demo")
            gtk_window_set_default_size(win, 900, 800)

            var main_box = gtk_box_new(1, 20)
            gtk_widget_set_margin_top(main_box, 24)
            gtk_widget_set_margin_bottom(main_box, 24)
            gtk_widget_set_margin_start(main_box, 24)
            gtk_widget_set_margin_end(main_box, 24)

            # Title
            var title = gtk_label_new("Animation & Visual Effects")
            gtk_widget_add_css_class(title, "title-1")
            gtk_box_append(main_box, title)

            # ============ SPINNER ANIMATIONS ============
            var spinner_box = AnimationDemo.create_section("Spinners - Loading Indicators")
            
            var spinner_row = gtk_box_new(0, 16)
            gtk_widget_set_halign(spinner_row, 3)
            
            var small_spinner = gtk_spinner_new()
            gtk_widget_set_size_request(small_spinner, 16, 16)
            gtk_spinner_start(small_spinner)
            
            var med_spinner = gtk_spinner_new()
            gtk_widget_set_size_request(med_spinner, 32, 32)
            gtk_spinner_start(med_spinner)
            
            var large_spinner = gtk_spinner_new()
            gtk_widget_set_size_request(large_spinner, 64, 64)
            gtk_spinner_start(large_spinner)
            
            gtk_box_append(spinner_row, small_spinner)
            gtk_box_append(spinner_row, med_spinner)
            gtk_box_append(spinner_row, large_spinner)
            gtk_box_append(spinner_box, spinner_row)
            
            var ctrl_row = gtk_box_new(0, 12)
            var ctrl_spinner = gtk_spinner_new()
            gtk_widget_set_size_request(ctrl_spinner, 32, 32)
            var start_btn = gtk_button_new_with_label("Start")
            var stop_btn = gtk_button_new_with_label("Stop")
            
            _ = g_signal_connect_data(start_btn, "clicked", AnimationDemo.on_spin_start, ctrl_spinner, None, 0)
            _ = g_signal_connect_data(stop_btn, "clicked", AnimationDemo.on_spin_stop, ctrl_spinner, None, 0)
            
            gtk_box_append(ctrl_row, ctrl_spinner)
            gtk_box_append(ctrl_row, start_btn)
            gtk_box_append(ctrl_row, stop_btn)
            gtk_box_append(spinner_box, ctrl_row)
            
            gtk_box_append(main_box, gtk_widget_get_parent(spinner_box))

            # ============ PROGRESS BARS ============
            var progress_box = AnimationDemo.create_section("Progress Bars - Animated Progress")
            
            var ind_progress = gtk_progress_bar_new()
            gtk_progress_bar_pulse(ind_progress)
            gtk_box_append(progress_box, gtk_label_new("Indeterminate (pulsing):"))
            gtk_box_append(progress_box, ind_progress)
            
            var det_progress = gtk_progress_bar_new()
            gtk_progress_bar_set_fraction(det_progress, 0.3)
            gtk_progress_bar_set_show_text(det_progress, True)
            var update_btn = gtk_button_new_with_label("Update Progress (+10%)")
            _ = g_signal_connect_data(update_btn, "clicked", AnimationDemo.on_progress_update, det_progress, None, 0)
            
            gtk_box_append(progress_box, gtk_label_new("Determinate:"))
            gtk_box_append(progress_box, det_progress)
            gtk_box_append(progress_box, update_btn)
            
            gtk_box_append(main_box, gtk_widget_get_parent(progress_box))

            # ============ REVEALER TRANSITIONS ============
            var reveal_box = AnimationDemo.create_section("Revealer - Animated Show/Hide")
            
            var transitions = List[String]()
            transitions.append("Slide Down")
            transitions.append("Slide Up")
            transitions.append("Slide Right")
            transitions.append("Slide Left")
            transitions.append("Crossfade")
            
            for i in range(len(transitions)):
                var rev_row = gtk_box_new(0, 12)
                
                var revealer = gtk_revealer_new()
                gtk_revealer_set_transition_type(revealer, i)
                gtk_revealer_set_transition_duration(revealer, 500)
                
                var content = gtk_label_new("✨ Revealed!")
                gtk_widget_add_css_class(content, "success")
                gtk_revealer_set_child(revealer, content)
                
                var toggle = gtk_toggle_button_new_with_label(transitions[i])
                gtk_widget_set_size_request(toggle, 120, -1)
                _ = g_signal_connect_data(toggle, "toggled", (AnimationDemo.on_revealer_toggle), revealer, None, 0)
                
                gtk_box_append(rev_row, toggle)
                gtk_box_append(rev_row, revealer)
                gtk_box_append(reveal_box, rev_row)
            
            gtk_box_append(main_box, gtk_widget_get_parent(reveal_box))

            # ============ STACK TRANSITIONS ============
            var stack_box = AnimationDemo.create_section("Stack - Page Transitions")
            
            var stack = gtk_stack_new()
            gtk_stack_set_transition_duration(stack, 400)
            
            var page1 = gtk_box_new(1, 8)
            gtk_widget_add_css_class(page1, "card")
            gtk_widget_set_size_request(page1, -1, 100)
            var p1_label = gtk_label_new("🔴 Page 1")
            gtk_widget_set_vexpand(p1_label, True)
            gtk_box_append(page1, p1_label)
            
            var page2 = gtk_box_new(1, 8)
            gtk_widget_add_css_class(page2, "card")
            gtk_widget_set_size_request(page2, -1, 100)
            var p2_label = gtk_label_new("🟢 Page 2")
            gtk_widget_set_vexpand(p2_label, True)
            gtk_box_append(page2, p2_label)
            
            var page3 = gtk_box_new(1, 8)
            gtk_widget_add_css_class(page3, "card")
            gtk_widget_set_size_request(page3, -1, 100)
            var p3_label = gtk_label_new("🔵 Page 3")
            gtk_widget_set_vexpand(p3_label, True)
            gtk_box_append(page3, p3_label)
            
            _ = gtk_stack_add_named(stack, page1, "page1")
            _ = gtk_stack_add_named(stack, page2, "page2")
            _ = gtk_stack_add_named(stack, page3, "page3")
            
            var trans_box = gtk_box_new(0, 8)
            
            var btn0 = gtk_button_new_with_label("None")
            _ = g_signal_connect_data(btn0, "clicked", (AnimationDemo.on_transition_0), stack, None, 0)
            gtk_box_append(trans_box, btn0)
            
            var btn1 = gtk_button_new_with_label("Crossfade")
            _ = g_signal_connect_data(btn1, "clicked", (AnimationDemo.on_transition_1), stack, None, 0)
            gtk_box_append(trans_box, btn1)
            
            var btn2 = gtk_button_new_with_label("Slide Right")
            _ = g_signal_connect_data(btn2, "clicked", (AnimationDemo.on_transition_2), stack, None, 0)
            gtk_box_append(trans_box, btn2)
            
            var btn3 = gtk_button_new_with_label("Slide Left")
            _ = g_signal_connect_data(btn3, "clicked", (AnimationDemo.on_transition_3), stack, None, 0)
            gtk_box_append(trans_box, btn3)
            
            var btn4 = gtk_button_new_with_label("Slide Up")
            _ = g_signal_connect_data(btn4, "clicked", AnimationDemo.on_transition_4, stack, None, 0)
            gtk_box_append(trans_box, btn4)
            
            var btn5 = gtk_button_new_with_label("Slide Down")
            _ = g_signal_connect_data(btn5, "clicked", AnimationDemo.on_transition_5, stack, None, 0)
            gtk_box_append(trans_box, btn5)
             
            var btn6 = gtk_button_new_with_label("Over Right")
            _ = g_signal_connect_data(btn6, "clicked", AnimationDemo.on_transition_6, stack, None, 0)
            gtk_box_append(trans_box, btn6)
            
            var btn7 = gtk_button_new_with_label("Over Left")
            _ = g_signal_connect_data(btn7, "clicked", AnimationDemo.on_transition_7, stack, None, 0)
            gtk_box_append(trans_box, btn7)
            
            var next_btn = gtk_button_new_with_label("Next Page →")
            gtk_widget_add_css_class(next_btn, "suggested-action")
            _ = g_signal_connect_data(next_btn, "clicked", AnimationDemo.on_stack_next, stack, None, 0)
            
            gtk_box_append(stack_box, gtk_label_new("Select transition type:"))
            gtk_box_append(stack_box, trans_box)
            gtk_box_append(stack_box, stack)
            gtk_box_append(stack_box, next_btn)
            
            gtk_box_append(main_box, gtk_widget_get_parent(stack_box))

            # ============ LEVEL BAR ANIMATION ============
            var level_box = AnimationDemo.create_section("Level Bar - Value Animation")
            
            var level_bar = gtk_level_bar_new()
            gtk_level_bar_set_min_value(level_bar, 0.0)
            gtk_level_bar_set_max_value(level_bar, 100.0)
            gtk_level_bar_set_value(level_bar, 0.0)
            
            var level_btns = gtk_box_new(0, 8)
            
            var lvl_btn0 = gtk_button_new_with_label("0%")
            _ = g_signal_connect_data(lvl_btn0, "clicked", AnimationDemo.on_level_0, level_bar, None, 0)
            gtk_box_append(level_btns, lvl_btn0)
            
            var lvl_btn25 = gtk_button_new_with_label("25%")
            _ = g_signal_connect_data(lvl_btn25, "clicked", AnimationDemo.on_level_25, level_bar, None, 0)
            gtk_box_append(level_btns, lvl_btn25)
            
            var lvl_btn50 = gtk_button_new_with_label("50%")
            _ = g_signal_connect_data(lvl_btn50, "clicked", AnimationDemo.on_level_50, level_bar, None, 0)
            gtk_box_append(level_btns, lvl_btn50)
            
            var lvl_btn75 = gtk_button_new_with_label("75%")
            _ = g_signal_connect_data(lvl_btn75, "clicked", AnimationDemo.on_level_75, level_bar, None, 0)
            gtk_box_append(level_btns, lvl_btn75)
            
            var lvl_btn100 = gtk_button_new_with_label("100%")
            _ = g_signal_connect_data(lvl_btn100, "clicked", AnimationDemo.on_level_100, level_bar, None, 0)
            gtk_box_append(level_btns, lvl_btn100)
            
            gtk_box_append(level_box, level_bar)
            gtk_box_append(level_box, level_btns)
            
            gtk_box_append(main_box, gtk_widget_get_parent(level_box))

            # Scrolled window
            var scrolled = gtk_scrolled_window_new()
            gtk_scrolled_window_set_child(scrolled, main_box)
            gtk_scrolled_window_set_policy(scrolled, 0, 1)

            gtk_window_set_child(win, scrolled)
            gtk_widget_show(win)

        except:
            print("ERROR: activation failed")

fn main() raises:
    var app = gtk_application_new("dev.mojo.animdemo", 0)
    _ = g_signal_connect_data(app, "activate", rebind[ptr](AnimationDemo.activate), ptr(), None, 0)
    _ = g_application_run(app, 0, ptr())