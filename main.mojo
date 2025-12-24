from bindings import *


@register_passable('trivial')
struct App:

    @staticmethod
    fn activate(app: GTKInterface, gptr: GTKInterface):
        try:
            print('Welcome to GTK!')
            var win = gtk_application_window_new(app)
            gtk_window_set_default_size(win, 500, 500)
            gtk_window_set_title(win, "GTK")

            var center = gtk_center_box_new()
            gtk_widget_set_hexpand(center, True)
            gtk_widget_set_vexpand(center, True)
            gtk_window_set_child(win, center)

            var label = gtk_label_new("Hello World")
            gtk_widget_set_halign(label, 3)
            gtk_widget_set_valign(label, 3)

            # Make text large using CSS
            var css = gtk_css_provider_new()
            gtk_css_provider_load_from_data(
                css,
                "label { font-size: 48px; font-weight: bold; }",
                -1
            )
            gtk_style_context_add_provider_for_display(
                gtk_widget_get_display(win),
                css,
                600
            )

            gtk_center_box_set_center_widget(center, label)

            gtk_window_present(win)

        except e:
            print('Failed to open window due to an error', e) 

fn main():
    try:
        var app = gtk_application_new("examples.gtk.main", 0)
        _ = g_signal_connect_data(app, "activate", rebind[GTKInterface](App.activate), GTKInterface(), None, 0)
        _ = g_application_run(app, 0, GTKInterface())
    except e:
        print('Failed to intialize app due to an error', e) 