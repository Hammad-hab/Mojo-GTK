from gtk import *
from sys.ffi import CStringSlice
from memory import UnsafePointer

comptime ptr = LegacyUnsafePointer[NoneType]

@register_passable("trivial")
struct FormData:
    var username: ptr
    var email: ptr
    var password: ptr
    var confirm: ptr
    var age: ptr
    var country: ptr
    var language: ptr
    var notif_switch: ptr
    var dark_switch: ptr
    var radio1: ptr
    var radio2: ptr
    var radio3: ptr
    var radio4: ptr
    var payment: ptr
    var autorenew: ptr
    var rating: ptr
    var text_view: ptr
    var terms: ptr
    var window: ptr
    
    fn __init__(out self, username: ptr, email: ptr, password: ptr, confirm: ptr, age: ptr,
                country: ptr, language: ptr, notif_switch: ptr, dark_switch: ptr,
                radio1: ptr, radio2: ptr, radio3: ptr, radio4: ptr,
                payment: ptr, autorenew: ptr, rating: ptr, text_view: ptr, terms: ptr, window: ptr):
        self.username = username
        self.email = email
        self.password = password
        self.confirm = confirm
        self.age = age
        self.country = country
        self.language = language
        self.notif_switch = notif_switch
        self.dark_switch = dark_switch
        self.radio1 = radio1
        self.radio2 = radio2
        self.radio3 = radio3
        self.radio4 = radio4
        self.payment = payment
        self.autorenew = autorenew
        self.rating = rating
        self.text_view = text_view
        self.terms = terms
        self.window = window

@register_passable("trivial")
struct FormsDemo:
    @staticmethod
    fn show_success_dialog(parent: ptr, form_data: FormData):
        try:
            var dialog = gtk_dialog_new()
            gtk_window_set_title(dialog, "Form Submitted Successfully!")
            gtk_window_set_transient_for(dialog, parent)
            gtk_window_set_modal(dialog, True)
            gtk_window_set_default_size(dialog, 500, 400)
            
            var content_area = gtk_dialog_get_content_area(dialog)
            
            var main_box = gtk_box_new(1, 16)
            gtk_widget_set_margin_top(main_box, 24)
            gtk_widget_set_margin_bottom(main_box, 24)
            gtk_widget_set_margin_start(main_box, 24)
            gtk_widget_set_margin_end(main_box, 24)
            
            # Success icon/title
            var title_box = gtk_box_new(1, 12)
            gtk_widget_set_halign(title_box, 3)  # Center
            
            var success_label = gtk_label_new("✓")
            gtk_widget_add_css_class(success_label, "title-1")
            gtk_box_append(title_box, success_label)
            
            var title_label = gtk_label_new("Registration Complete!")
            gtk_widget_add_css_class(title_label, "title-2")
            gtk_box_append(title_box, title_label)
            
            var subtitle = gtk_label_new("Thank you for submitting the form. Here's a summary:")
            gtk_widget_add_css_class(subtitle, "dim-label")
            gtk_box_append(title_box, subtitle)
            
            gtk_box_append(main_box, title_box)
            
            # Summary card
            var summary_frame = gtk_frame_new("")
            gtk_widget_add_css_class(summary_frame, "card")
            var summary_box = gtk_box_new(1, 8)
            gtk_widget_set_margin_top(summary_box, 16)
            gtk_widget_set_margin_bottom(summary_box, 16)
            gtk_widget_set_margin_start(summary_box, 16)
            gtk_widget_set_margin_end(summary_box, 16)
            
            # Username
            var username_text = gtk_editable_get_text(form_data.username)
            var username_str = String()
            var username_slice = CStringSlice(unsafe_from_ptr=username_text)
            username_slice.write_to(username_str)
            var username_label = gtk_label_new("Username: " + username_str)
            gtk_widget_set_halign(username_label, 1)
            gtk_box_append(summary_box, username_label)
            
            # Email
            var email_text = gtk_editable_get_text(form_data.email)
            var email_str = String()
            var email_slice = CStringSlice(unsafe_from_ptr=email_text)
            email_slice.write_to(email_str)
            var email_label = gtk_label_new("Email: " + email_str)
            gtk_widget_set_halign(email_label, 1)
            gtk_box_append(summary_box, email_label)
            
            # Age
            var age_val = gtk_spin_button_get_value(form_data.age)
            var age_str = String("Age: ")
            age_str += String(Int(age_val))
            var age_label = gtk_label_new(age_str)
            gtk_widget_set_halign(age_label, 1)
            gtk_box_append(summary_box, age_label)
            
            # Country
            var country_text = gtk_combo_box_text_get_active_text(form_data.country)
            var country_str = String()
            var country_slice = CStringSlice(unsafe_from_ptr=country_text)
            country_slice.write_to(country_str)
            var country_label = gtk_label_new("Country: " + country_str)
            gtk_widget_set_halign(country_label, 1)
            gtk_box_append(summary_box, country_label)
            
            # Plan
            var selected_plan = "Unknown"
            if gtk_check_button_get_active(form_data.radio1):
                selected_plan = "Free Plan"
            elif gtk_check_button_get_active(form_data.radio2):
                selected_plan = "Basic Plan"
            elif gtk_check_button_get_active(form_data.radio3):
                selected_plan = "Pro Plan"
            elif gtk_check_button_get_active(form_data.radio4):
                selected_plan = "Enterprise"
            var plan_label = gtk_label_new("Plan: " + selected_plan)
            gtk_widget_set_halign(plan_label, 1)
            gtk_box_append(summary_box, plan_label)
            
            gtk_frame_set_child(summary_frame, summary_box)
            gtk_box_append(main_box, summary_frame)
            
            # Confirmation message
            var confirm_msg = gtk_label_new("A confirmation email has been sent to your address.")
            gtk_widget_add_css_class(confirm_msg, "dim-label")
            gtk_widget_set_margin_top(confirm_msg, 8)
            gtk_box_append(main_box, confirm_msg)
            
            gtk_box_append(content_area, main_box)
            
            # Add close button
            var close_btn = gtk_button_new_with_label("Close")
            gtk_widget_add_css_class(close_btn, "suggested-action")
            gtk_widget_set_margin_top(close_btn, 16)
            gtk_widget_set_margin_start(close_btn, 24)
            gtk_widget_set_margin_end(close_btn, 24)
            gtk_widget_set_margin_bottom(close_btn, 16)
            
            _ = g_signal_connect_data(close_btn, "clicked", rebind[ptr](FormsDemo.on_dialog_close), dialog, None, 0)
            
            gtk_box_append(content_area, close_btn)
            
            gtk_widget_show(dialog)
            
        except e:
            print("ERROR: Failed to show success dialog -", e)
    
    @staticmethod
    fn on_dialog_close(button: ptr, dialog: ptr):
        try:
            gtk_window_destroy(dialog)
        except:
            pass
    
    @staticmethod
    fn on_submit_clicked(button: ptr, form_data_ptr: ptr):
        try:
            var form_data = form_data_ptr.bitcast[FormData]()[]
            
            print("\n" + "="*60)
            print("FORM SUBMISSION DATA")
            print("="*60)
            
            # User Registration
            print("\n[USER REGISTRATION]")
            var username_text = gtk_editable_get_text(form_data.username)
            var username_str = String()
            var username_slice = CStringSlice(unsafe_from_ptr=username_text)
            username_slice.write_to(username_str)
            print("Username:", username_str)
            
            var email_text = gtk_editable_get_text(form_data.email)
            var email_str = String()
            var email_slice = CStringSlice(unsafe_from_ptr=email_text)
            email_slice.write_to(email_str)
            print("Email:", email_str)
            
            var pwd_text = gtk_editable_get_text(form_data.password)
            var pwd_str = String()
            var pwd_slice = CStringSlice(unsafe_from_ptr=pwd_text)
            pwd_slice.write_to(pwd_str)
            print("Password:", "*" * len(pwd_str))
            
            var confirm_text = gtk_editable_get_text(form_data.confirm)
            var confirm_str = String()
            var confirm_slice = CStringSlice(unsafe_from_ptr=confirm_text)
            confirm_slice.write_to(confirm_str)
            print("Confirm Password:", "*" * len(confirm_str))
            
            var age_val = gtk_spin_button_get_value(form_data.age)
            print("Age:", Int(age_val))
            
            # User Preferences
            print("\n[USER PREFERENCES]")
            var country_idx = gtk_combo_box_get_active(form_data.country)
            var country_text = gtk_combo_box_text_get_active_text(form_data.country)
            var country_str = String()
            var country_slice = CStringSlice(unsafe_from_ptr=country_text)
            country_slice.write_to(country_str)
            print("Country:", country_str)
            
            var lang_text = gtk_combo_box_text_get_active_text(form_data.language)
            var lang_str = String()
            var lang_slice = CStringSlice(unsafe_from_ptr=lang_text)
            lang_slice.write_to(lang_str)
            print("Language:", lang_str)
            
            var notif_active = gtk_switch_get_active(form_data.notif_switch)
            var notif_status = "Disabled"
            if notif_active:
                notif_status = "Enabled"
            print("Notifications:", notif_status)
            
            var dark_active = gtk_switch_get_active(form_data.dark_switch)
            var dark_status = "Disabled"
            if dark_active:
                dark_status = "Enabled"
            print("Dark Mode:", dark_status)
            
            # Subscription
            print("\n[SUBSCRIPTION]")
            var selected_plan = "Unknown"
            if gtk_check_button_get_active(form_data.radio1):
                selected_plan = "Free Plan - $0/month"
            elif gtk_check_button_get_active(form_data.radio2):
                selected_plan = "Basic Plan - $9/month"
            elif gtk_check_button_get_active(form_data.radio3):
                selected_plan = "Pro Plan - $29/month"
            elif gtk_check_button_get_active(form_data.radio4):
                selected_plan = "Enterprise - $99/month"
            print("Selected Plan:", selected_plan)
            
            var payment_text = gtk_combo_box_text_get_active_text(form_data.payment)
            var payment_str = String()
            var payment_slice = CStringSlice(unsafe_from_ptr=payment_text)
            payment_slice.write_to(payment_str)
            print("Payment Method:", payment_str)
            
            var autorenew_active = gtk_check_button_get_active(form_data.autorenew)
            var autorenew_status = "No"
            if autorenew_active:
                autorenew_status = "Yes"
            print("Auto-renew:", autorenew_status)
            
            # Feedback
            print("\n[FEEDBACK]")
            var rating_val = gtk_range_get_value(form_data.rating)
            print("Rating:", Int(rating_val), "/ 5")
            
            var buffer = gtk_text_view_get_buffer(form_data.text_view)
            var start = LegacyUnsafePointer[GTKTextIter].alloc(1)
            var end = LegacyUnsafePointer[GTKTextIter].alloc(1)
            gtk_text_buffer_get_start_iter(buffer, start)
            gtk_text_buffer_get_end_iter(buffer, end)
            var comments_text = gtk_text_buffer_get_text(buffer, start, end, False)
            var comments_str = String()
            var comments_slice = CStringSlice(unsafe_from_ptr=comments_text)
            comments_slice.write_to(comments_str)
            print("Comments:", comments_str)
            
            var terms_active = gtk_check_button_get_active(form_data.terms)
            var terms_status = "No"
            if terms_active:
                terms_status = "Yes"
            print("Terms Accepted:", terms_status)
            
            print("\n" + "="*60)
            print("Form submitted successfully!")
            print("="*60 + "\n")
            
            # Show success dialog
            FormsDemo.show_success_dialog(form_data.window, form_data)
            
        except e:
            print("ERROR: Failed to collect form data -", e)
    
    @staticmethod
    fn on_reset_clicked(button: ptr, form_data_ptr: ptr):
        try:
            var form_data = form_data_ptr.bitcast[FormData]()[]
            
            # Reset registration fields
            gtk_editable_set_text(form_data.username, "")
            gtk_editable_set_text(form_data.email, "")
            gtk_editable_set_text(form_data.password, "")
            gtk_editable_set_text(form_data.confirm, "")
            gtk_spin_button_set_value(form_data.age, 25.0)
            
            # Reset preferences
            gtk_combo_box_set_active(form_data.country, 0)
            gtk_combo_box_set_active(form_data.language, 0)
            gtk_switch_set_active(form_data.notif_switch, True)
            gtk_switch_set_active(form_data.dark_switch, False)
            
            # Reset subscription
            gtk_check_button_set_active(form_data.radio1, True)
            gtk_combo_box_set_active(form_data.payment, 0)
            gtk_check_button_set_active(form_data.autorenew, True)
            
            # Reset feedback
            gtk_range_set_value(form_data.rating, 3.0)
            var buffer = gtk_text_view_get_buffer(form_data.text_view)
            gtk_text_buffer_set_text(buffer, "Enter your feedback here...", -1)
            gtk_check_button_set_active(form_data.terms, False)
            
            print("Form reset to default values!")
            
        except e:
            print("ERROR: Failed to reset form -", e)

    @staticmethod
    fn create_form_row(label_text: String, widget: ptr) raises -> ptr:
        var row = gtk_box_new(0, 12)
        gtk_widget_set_margin_top(row, 8)
        gtk_widget_set_margin_bottom(row, 8)
        
        var label = gtk_label_new(label_text)
        gtk_widget_set_size_request(label, 150, -1)
        gtk_widget_set_halign(label, 1)  # Left align
        
        gtk_box_append(row, label)
        gtk_box_append(row, widget)
        gtk_widget_set_hexpand(widget, True)
        
        return row

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
    fn activate(app: ptr, gptr: ptr):
        try:
            var win = gtk_application_window_new(app)
            gtk_window_set_title(win, "Mojo GTK4 Forms & Data Entry Demo")
            gtk_window_set_default_size(win, 900, 700)

            var main_box = gtk_box_new(1, 20)
            gtk_widget_set_margin_top(main_box, 24)
            gtk_widget_set_margin_bottom(main_box, 24)
            gtk_widget_set_margin_start(main_box, 24)
            gtk_widget_set_margin_end(main_box, 24)

            # Title
            var title = gtk_label_new("Forms & Data Entry Examples")
            gtk_widget_add_css_class(title, "title-1")
            gtk_box_append(main_box, title)

            # ============ USER REGISTRATION FORM ============
            var reg_box = FormsDemo.create_section("User Registration Form")
            
            # Username
            var username = gtk_entry_new()
            gtk_entry_set_placeholder_text(username, "Enter username")
            var username_row = FormsDemo.create_form_row("Username:", username)
            gtk_box_append(reg_box, username_row)
            
            # Email
            var email = gtk_entry_new()
            gtk_entry_set_placeholder_text(email, "user@example.com")
            gtk_entry_set_input_purpose(email, 5)  # Email purpose
            var email_row = FormsDemo.create_form_row("Email:", email)
            gtk_box_append(reg_box, email_row)
            
            # Password
            var password = gtk_password_entry_new()
            gtk_password_entry_set_show_peek_icon(password, True)
            var pwd_row = FormsDemo.create_form_row("Password:", password)
            gtk_box_append(reg_box, pwd_row)
            
            # Confirm Password
            var confirm = gtk_password_entry_new()
            var confirm_row = FormsDemo.create_form_row("Confirm:", confirm)
            gtk_box_append(reg_box, confirm_row)
            
            # Age (SpinButton)
            var age = gtk_spin_button_new_with_range(18.0, 100.0, 1.0)
            gtk_spin_button_set_value(age, 25.0)
            var age_row = FormsDemo.create_form_row("Age:", age)
            gtk_box_append(reg_box, age_row)
            
            gtk_box_append(main_box, gtk_widget_get_parent(reg_box))

            # ============ PREFERENCES FORM ============
            var pref_box = FormsDemo.create_section("User Preferences")
            
            # Country Selection
            var country = gtk_combo_box_text_new()
            gtk_combo_box_text_append_text(country, "United States")
            gtk_combo_box_text_append_text(country, "United Kingdom")
            gtk_combo_box_text_append_text(country, "Canada")
            gtk_combo_box_text_append_text(country, "Australia")
            gtk_combo_box_text_append_text(country, "Pakistan")
            gtk_combo_box_set_active(country, 0)
            var country_row = FormsDemo.create_form_row("Country:", country)
            gtk_box_append(pref_box, country_row)
            
            # Language Selection
            var language = gtk_combo_box_text_new()
            gtk_combo_box_text_append_text(language, "English")
            gtk_combo_box_text_append_text(language, "Spanish")
            gtk_combo_box_text_append_text(language, "French")
            gtk_combo_box_text_append_text(language, "German")
            gtk_combo_box_text_append_text(language, "Urdu")
            gtk_combo_box_set_active(language, 0)
            var lang_row = FormsDemo.create_form_row("Language:", language)
            gtk_box_append(pref_box, lang_row)
            
            # Notification Toggle
            var notif_switch = gtk_switch_new()
            gtk_switch_set_active(notif_switch, True)
            var notif_row = FormsDemo.create_form_row("Notifications:", notif_switch)
            gtk_widget_set_hexpand(notif_switch, False)
            gtk_box_append(pref_box, notif_row)
            
            # Dark Mode Toggle
            var dark_switch = gtk_switch_new()
            var dark_row = FormsDemo.create_form_row("Dark Mode:", dark_switch)
            gtk_widget_set_hexpand(dark_switch, False)
            gtk_box_append(pref_box, dark_row)
            
            gtk_box_append(main_box, gtk_widget_get_parent(pref_box))

            # ============ SUBSCRIPTION FORM ============
            var sub_box = FormsDemo.create_section("Subscription Options")
            
            # Radio buttons for plan selection
            var radio_box = gtk_box_new(1, 8)
            
            var radio1 = gtk_check_button_new_with_label("Free Plan - $0/month")
            var radio2 = gtk_check_button_new_with_label("Basic Plan - $9/month")
            gtk_check_button_set_group(radio2, radio1)
            var radio3 = gtk_check_button_new_with_label("Pro Plan - $29/month")
            gtk_check_button_set_group(radio3, radio1)
            var radio4 = gtk_check_button_new_with_label("Enterprise - $99/month")
            gtk_check_button_set_group(radio4, radio1)
            
            gtk_check_button_set_active(radio1, True)
            
            gtk_box_append(radio_box, radio1)
            gtk_box_append(radio_box, radio2)
            gtk_box_append(radio_box, radio3)
            gtk_box_append(radio_box, radio4)
            
            var plan_row = FormsDemo.create_form_row("Plan:", radio_box)
            gtk_box_append(sub_box, plan_row)
            
            # Payment method
            var payment = gtk_combo_box_text_new()
            gtk_combo_box_text_append_text(payment, "Credit Card")
            gtk_combo_box_text_append_text(payment, "PayPal")
            gtk_combo_box_text_append_text(payment, "Bank Transfer")
            gtk_combo_box_set_active(payment, 0)
            var payment_row = FormsDemo.create_form_row("Payment:", payment)
            gtk_box_append(sub_box, payment_row)
            
            # Auto-renew checkbox
            var autorenew = gtk_check_button_new_with_label("Automatically renew subscription")
            gtk_check_button_set_active(autorenew, True)
            gtk_box_append(sub_box, autorenew)
            
            gtk_box_append(main_box, gtk_widget_get_parent(sub_box))

            # ============ FEEDBACK FORM ============
            var feedback_box = FormsDemo.create_section("Send Feedback")
            
            # Rating scale
            var rating = gtk_scale_new_with_range(0, 1.0, 5.0, 1.0)
            gtk_scale_set_draw_value(rating, True)
            gtk_scale_set_digits(rating, 0)
            gtk_scale_add_mark(rating, 1.0, 1, "Poor")
            gtk_scale_add_mark(rating, 3.0, 1, "Average")
            gtk_scale_add_mark(rating, 5.0, 1, "Excellent")
            gtk_range_set_value(rating, 3.0)
            var rating_row = FormsDemo.create_form_row("Rating:", rating)
            gtk_box_append(feedback_box, rating_row)
            
            # Comments
            var comments_label = gtk_label_new("Comments:")
            gtk_widget_set_halign(comments_label, 1)
            gtk_widget_set_margin_bottom(comments_label, 8)
            gtk_box_append(feedback_box, comments_label)
            
            var text_view = gtk_text_view_new()
            gtk_text_view_set_wrap_mode(text_view, 2)
            gtk_widget_set_size_request(text_view, -1, 100)
            var buffer = gtk_text_view_get_buffer(text_view)
            gtk_text_buffer_set_text(buffer, "Enter your feedback here...", -1)
            
            var sw = gtk_scrolled_window_new()
            gtk_scrolled_window_set_child(sw, text_view)
            gtk_scrolled_window_set_policy(sw, 0, 1)
            gtk_widget_set_size_request(sw, -1, 100)
            gtk_box_append(feedback_box, sw)
            
            # Terms agreement
            var terms = gtk_check_button_new_with_label("I agree to the terms and conditions")
            gtk_widget_set_margin_top(terms, 12)
            gtk_box_append(feedback_box, terms)
            
            gtk_box_append(main_box, gtk_widget_get_parent(feedback_box))

            # Create FormData struct and store widget references
            var form_data = FormData(
                username, email, password, confirm, age,
                country, language, notif_switch, dark_switch,
                radio1, radio2, radio3, radio4,
                payment, autorenew, rating, text_view, terms, win
            )
            
            # Allocate memory for form data
            var form_data_ptr = LegacyUnsafePointer[FormData].alloc(1)
            form_data_ptr[] = form_data

            # ============ FORM ACTIONS ============
            var actions = gtk_box_new(0, 12)
            gtk_widget_set_halign(actions, 2)  # Right align
            gtk_widget_set_margin_top(actions, 20)
            
            var reset_btn = gtk_button_new_with_label("Reset")
            var cancel_btn = gtk_button_new_with_label("Cancel")
            var submit_btn = gtk_button_new_with_label("Submit")
            gtk_widget_add_css_class(submit_btn, "suggested-action")
            
            _ = g_signal_connect_data(submit_btn, "clicked", rebind[ptr](FormsDemo.on_submit_clicked), form_data_ptr.bitcast[NoneType](), None, 0)
            _ = g_signal_connect_data(reset_btn, "clicked", rebind[ptr](FormsDemo.on_reset_clicked), form_data_ptr.bitcast[NoneType](), None, 0)
            
            gtk_box_append(actions, reset_btn)
            gtk_box_append(actions, cancel_btn)
            gtk_box_append(actions, submit_btn)
            gtk_box_append(main_box, actions)

            # Scrolled window
            var scrolled = gtk_scrolled_window_new()
            gtk_scrolled_window_set_child(scrolled, main_box)
            gtk_scrolled_window_set_policy(scrolled, 0, 1)

            gtk_window_set_child(win, scrolled)
            gtk_widget_show(win)

        except e:
            print("ERROR: activation failed -", e)

fn main() raises:
    var app = gtk_application_new("dev.mojo.formsdemo", 0)
    _ = g_signal_connect_data(app, "activate", rebind[ptr](FormsDemo.activate), ptr(), None, 0)
    _ = g_application_run(app, 0, ptr())