#include <gtk/gtk.h>
#include <webkit/webkit.h>
#include <math.h>
#include <stdio.h>
#include <string.h>

typedef struct {
    GtkApplication *app;
    GtkWidget *window;
    GtkWidget *overlay;
    GtkWidget *web_view;
    GtkWidget *progress_bar;
    GtkWidget *hud_box;
    GtkWidget *search_box;
    GtkWidget *search_entry;
    GtkWidget *btn_back;
    GtkWidget *btn_forward;
    GtkWidget *btn_reload;
    GtkWidget *btn_search;
    GtkWidget *btn_home;
    char *initial_url;
} WatchBrowserApp;

static WatchBrowserApp g_app_data;

static void navigate_to(WatchBrowserApp *app, const char *input)
{
    if (!input || strlen(input) == 0) return;

    if (g_str_has_prefix(input, "http://") ||
        g_str_has_prefix(input, "https://") ||
        g_str_has_prefix(input, "file://")) {
        webkit_web_view_load_uri(WEBKIT_WEB_VIEW(app->web_view), input);
    } else if (strchr(input, '.') && !strchr(input, ' ')) {
        char *full_url = g_strdup_printf("https://%s", input);
        webkit_web_view_load_uri(WEBKIT_WEB_VIEW(app->web_view), full_url);
        g_free(full_url);
    } else {
        char *escaped = g_uri_escape_string(input, NULL, TRUE);
        char *search_url = g_strdup_printf("https://html.duckduckgo.com/html/?q=%s", escaped);
        webkit_web_view_load_uri(WEBKIT_WEB_VIEW(app->web_view), search_url);
        g_free(escaped);
        g_free(search_url);
    }
}

static void on_load_changed(WebKitWebView *web_view, WebKitLoadEvent load_event, gpointer user_data)
{
    WatchBrowserApp *app = (WatchBrowserApp *)user_data;

    switch (load_event) {
    case WEBKIT_LOAD_STARTED:
        gtk_widget_set_visible(app->progress_bar, TRUE);
        gtk_progress_bar_set_fraction(GTK_PROGRESS_BAR(app->progress_bar), 0.1);
        break;
    case WEBKIT_LOAD_COMMITTED:
        gtk_progress_bar_set_fraction(GTK_PROGRESS_BAR(app->progress_bar), 0.5);
        break;
    case WEBKIT_LOAD_FINISHED:
        gtk_widget_set_visible(app->progress_bar, FALSE);
        gtk_progress_bar_set_fraction(GTK_PROGRESS_BAR(app->progress_bar), 0.0);
        break;
    default:
        break;
    }

    gtk_widget_set_sensitive(app->btn_back, webkit_web_view_can_go_back(web_view));
    gtk_widget_set_sensitive(app->btn_forward, webkit_web_view_can_go_forward(web_view));
}

static void on_notify_progress(GObject *object, GParamSpec *pspec, gpointer user_data)
{
    WatchBrowserApp *app = (WatchBrowserApp *)user_data;
    double progress = webkit_web_view_get_estimated_load_progress(WEBKIT_WEB_VIEW(object));
    gtk_progress_bar_set_fraction(GTK_PROGRESS_BAR(app->progress_bar), progress);
}

static void on_btn_back_clicked(GtkButton *btn, gpointer user_data)
{
    WatchBrowserApp *app = (WatchBrowserApp *)user_data;
    if (webkit_web_view_can_go_back(WEBKIT_WEB_VIEW(app->web_view))) {
        webkit_web_view_go_back(WEBKIT_WEB_VIEW(app->web_view));
    }
}

static void on_btn_forward_clicked(GtkButton *btn, gpointer user_data)
{
    WatchBrowserApp *app = (WatchBrowserApp *)user_data;
    if (webkit_web_view_can_go_forward(WEBKIT_WEB_VIEW(app->web_view))) {
        webkit_web_view_go_forward(WEBKIT_WEB_VIEW(app->web_view));
    }
}

static void on_btn_reload_clicked(GtkButton *btn, gpointer user_data)
{
    WatchBrowserApp *app = (WatchBrowserApp *)user_data;
    if (webkit_web_view_is_loading(WEBKIT_WEB_VIEW(app->web_view))) {
        webkit_web_view_stop_loading(WEBKIT_WEB_VIEW(app->web_view));
    } else {
        webkit_web_view_reload(WEBKIT_WEB_VIEW(app->web_view));
    }
}

static void on_btn_home_clicked(GtkButton *btn, gpointer user_data)
{
    WatchBrowserApp *app = (WatchBrowserApp *)user_data;
    const char *portal_path = g_getenv("ASTEROID_BROWSER_SHARE");
    char *portal_file = NULL;

    if (portal_path) {
        portal_file = g_build_filename(portal_path, "portal.html", NULL);
    } else {
        portal_file = g_build_filename("/run/current-system/sw/share/asteroid-browser", "portal.html", NULL);
    }

    if (g_file_test(portal_file, G_FILE_TEST_EXISTS)) {
        char *file_uri = g_strdup_printf("file://%s", portal_file);
        webkit_web_view_load_uri(WEBKIT_WEB_VIEW(app->web_view), file_uri);
        g_free(file_uri);
    } else {
        webkit_web_view_load_uri(WEBKIT_WEB_VIEW(app->web_view), "https://html.duckduckgo.com/html/");
    }
    g_free(portal_file);
}

static void on_btn_search_clicked(GtkButton *btn, gpointer user_data)
{
    WatchBrowserApp *app = (WatchBrowserApp *)user_data;
    gboolean is_visible = gtk_widget_get_visible(app->search_box);
    gtk_widget_set_visible(app->search_box, !is_visible);
    if (!is_visible) {
        gtk_widget_grab_focus(app->search_entry);
    }
}

static void on_search_entry_activate(GtkEntry *entry, gpointer user_data)
{
    WatchBrowserApp *app = (WatchBrowserApp *)user_data;
    const char *text = gtk_editable_get_text(GTK_EDITABLE(entry));
    if (text && strlen(text) > 0) {
        navigate_to(app, text);
        gtk_widget_set_visible(app->search_box, FALSE);
    }
}

static gboolean on_crown_scroll(GtkEventControllerScroll *scroll, gdouble dx, gdouble dy, gpointer user_data)
{
    WebKitWebView *view = WEBKIT_WEB_VIEW(user_data);
    int delta = (int)(dy * 80.0);
    char *js = g_strdup_printf("window.scrollBy({ top: %d, behavior: 'smooth' });", delta);
    webkit_web_view_evaluate_javascript(view, js, -1, NULL, NULL, NULL, NULL, NULL);
    g_free(js);
    return GDK_EVENT_STOP;
}

static void on_swipe(GtkGestureSwipe *gesture, gdouble velocity_x, gdouble velocity_y, gpointer user_data)
{
    WatchBrowserApp *app = (WatchBrowserApp *)user_data;
    WebKitWebView *view = WEBKIT_WEB_VIEW(app->web_view);

    if (velocity_x > 350.0 && fabs(velocity_x) > fabs(velocity_y) * 1.5) {
        if (webkit_web_view_can_go_back(view)) {
            webkit_web_view_go_back(view);
        }
    } else if (velocity_x < -350.0 && fabs(velocity_x) > fabs(velocity_y) * 1.5) {
        if (webkit_web_view_can_go_forward(view)) {
            webkit_web_view_go_forward(view);
        }
    }
}

static void activate(GtkApplication *app, gpointer user_data)
{
    WatchBrowserApp *app_data = (WatchBrowserApp *)user_data;
    app_data->app = app;

    GtkWidget *window = gtk_application_window_new(app);
    app_data->window = window;
    gtk_window_set_title(GTK_WINDOW(window), "Browser");
    gtk_window_set_default_size(GTK_WINDOW(window), 400, 400);
    gtk_window_set_decorated(GTK_WINDOW(window), FALSE);

    /* AMOLED Dark Smartwatch CSS styling */
    GtkCssProvider *css = gtk_css_provider_new();
    gtk_css_provider_load_from_string(css,
        "window { background-color: #000000; color: #FFFFFF; }\n"
        ".watch-hud {\n"
        "  background: rgba(14, 20, 32, 0.94);\n"
        "  border: 1px solid rgba(0, 229, 255, 0.4);\n"
        "  border-radius: 28px;\n"
        "  padding: 4px 8px;\n"
        "  margin-bottom: 12px;\n"
        "}\n"
        ".watch-btn {\n"
        "  background: transparent;\n"
        "  border: none;\n"
        "  border-radius: 50%;\n"
        "  min-width: 36px;\n"
        "  min-height: 36px;\n"
        "  padding: 0;\n"
        "  color: #F0F4F8;\n"
        "  font-size: 15px;\n"
        "  font-weight: bold;\n"
        "}\n"
        ".watch-btn:hover, .watch-btn:active {\n"
        "  background: rgba(0, 229, 255, 0.3);\n"
        "  color: #00E5FF;\n"
        "}\n"
        ".watch-entry-box {\n"
        "  background: rgba(10, 15, 26, 0.96);\n"
        "  border: 1px solid #00E5FF;\n"
        "  border-radius: 22px;\n"
        "  padding: 4px 8px;\n"
        "  margin: 14px 20px;\n"
        "}\n"
        ".watch-entry {\n"
        "  background: transparent;\n"
        "  color: #FFFFFF;\n"
        "  border: none;\n"
        "  padding: 4px 8px;\n"
        "  font-size: 14px;\n"
        "}\n"
        ".watch-progress progressbar trough {\n"
        "  min-height: 3px;\n"
        "  background-color: transparent;\n"
        "  border: none;\n"
        "}\n"
        ".watch-progress progressbar progress {\n"
        "  min-height: 3px;\n"
        "  background-color: #00E5FF;\n"
        "  border-radius: 2px;\n"
        "}\n");
    gtk_style_context_add_provider_for_display(
        gdk_display_get_default(),
        GTK_STYLE_PROVIDER(css),
        GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
    g_object_unref(css);

    /* Root Overlay Layout */
    GtkWidget *overlay = gtk_overlay_new();
    app_data->overlay = overlay;
    gtk_window_set_child(GTK_WINDOW(window), overlay);

    /* WebKit Engine & Settings */
    WebKitSettings *settings = webkit_settings_new();
    webkit_settings_set_enable_javascript(settings, TRUE);
    webkit_settings_set_enable_smooth_scrolling(settings, TRUE);
    webkit_settings_set_enable_webgl(settings, TRUE);
    webkit_settings_set_enable_webaudio(settings, FALSE);
    webkit_settings_set_enable_page_cache(settings, FALSE);
    webkit_settings_set_user_agent(settings,
        "Mozilla/5.0 (Linux; Android 10; Wear OS) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36 AsteroidOS/1.0");

    GtkWidget *web_view = webkit_web_view_new();
    app_data->web_view = web_view;
    webkit_web_view_set_settings(WEBKIT_WEB_VIEW(web_view), settings);

    GdkRGBA black = { 0.0, 0.0, 0.0, 1.0 };
    webkit_web_view_set_background_color(WEBKIT_WEB_VIEW(web_view), &black);
    gtk_widget_set_hexpand(web_view, TRUE);
    gtk_widget_set_vexpand(web_view, TRUE);
    gtk_overlay_set_child(GTK_OVERLAY(overlay), web_view);

    /* Low-Memory Management for Wearable Profile */
    WebKitMemoryPressureSettings *pressure = webkit_memory_pressure_settings_new();
    webkit_memory_pressure_settings_set_memory_limit(pressure, 256);
    webkit_network_session_set_memory_pressure_settings(pressure);
    webkit_memory_pressure_settings_free(pressure);

    /* Progress bar */
    GtkWidget *progress = gtk_progress_bar_new();
    app_data->progress_bar = progress;
    gtk_widget_add_css_class(progress, "watch-progress");
    gtk_widget_set_valign(progress, GTK_ALIGN_START);
    gtk_widget_set_hexpand(progress, TRUE);
    gtk_widget_set_visible(progress, FALSE);
    gtk_overlay_add_overlay(GTK_OVERLAY(overlay), progress);

    g_signal_connect(web_view, "load-changed", G_CALLBACK(on_load_changed), app_data);
    g_signal_connect(web_view, "notify::estimated-load-progress", G_CALLBACK(on_notify_progress), app_data);

    /* Search & URL entry dialog box */
    GtkWidget *search_box = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 6);
    app_data->search_box = search_box;
    gtk_widget_add_css_class(search_box, "watch-entry-box");
    gtk_widget_set_halign(search_box, GTK_ALIGN_FILL);
    gtk_widget_set_valign(search_box, GTK_ALIGN_START);
    gtk_widget_set_visible(search_box, FALSE);

    GtkWidget *search_entry = gtk_entry_new();
    app_data->search_entry = search_entry;
    gtk_widget_add_css_class(search_entry, "watch-entry");
    gtk_entry_set_placeholder_text(GTK_ENTRY(search_entry), "Search or URL...");
    gtk_widget_set_hexpand(search_entry, TRUE);
    g_signal_connect(search_entry, "activate", G_CALLBACK(on_search_entry_activate), app_data);
    gtk_box_append(GTK_BOX(search_box), search_entry);

    GtkWidget *btn_go = gtk_button_new_with_label("Go");
    gtk_widget_add_css_class(btn_go, "watch-btn");
    g_signal_connect_swapped(btn_go, "clicked", G_CALLBACK(on_search_entry_activate), search_entry);
    gtk_box_append(GTK_BOX(search_box), btn_go);

    gtk_overlay_add_overlay(GTK_OVERLAY(overlay), search_box);

    /* Floating Navigation Action HUD */
    GtkWidget *hud = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 8);
    app_data->hud_box = hud;
    gtk_widget_add_css_class(hud, "watch-hud");
    gtk_widget_set_halign(hud, GTK_ALIGN_CENTER);
    gtk_widget_set_valign(hud, GTK_ALIGN_END);

    GtkWidget *btn_back = gtk_button_new_with_label("◀");
    app_data->btn_back = btn_back;
    gtk_widget_add_css_class(btn_back, "watch-btn");
    gtk_widget_set_sensitive(btn_back, FALSE);
    g_signal_connect(btn_back, "clicked", G_CALLBACK(on_btn_back_clicked), app_data);
    gtk_box_append(GTK_BOX(hud), btn_back);

    GtkWidget *btn_home = gtk_button_new_with_label("⌂");
    app_data->btn_home = btn_home;
    gtk_widget_add_css_class(btn_home, "watch-btn");
    g_signal_connect(btn_home, "clicked", G_CALLBACK(on_btn_home_clicked), app_data);
    gtk_box_append(GTK_BOX(hud), btn_home);

    GtkWidget *btn_search = gtk_button_new_with_label("🔍");
    app_data->btn_search = btn_search;
    gtk_widget_add_css_class(btn_search, "watch-btn");
    g_signal_connect(btn_search, "clicked", G_CALLBACK(on_btn_search_clicked), app_data);
    gtk_box_append(GTK_BOX(hud), btn_search);

    GtkWidget *btn_reload = gtk_button_new_with_label("↻");
    app_data->btn_reload = btn_reload;
    gtk_widget_add_css_class(btn_reload, "watch-btn");
    g_signal_connect(btn_reload, "clicked", G_CALLBACK(on_btn_reload_clicked), app_data);
    gtk_box_append(GTK_BOX(hud), btn_reload);

    GtkWidget *btn_forward = gtk_button_new_with_label("▶");
    app_data->btn_forward = btn_forward;
    gtk_widget_add_css_class(btn_forward, "watch-btn");
    gtk_widget_set_sensitive(btn_forward, FALSE);
    g_signal_connect(btn_forward, "clicked", G_CALLBACK(on_btn_forward_clicked), app_data);
    gtk_box_append(GTK_BOX(hud), btn_forward);

    gtk_overlay_add_overlay(GTK_OVERLAY(overlay), hud);

    /* Hardware Crown Scroll Controller */
    GtkEventController *scroll = gtk_event_controller_scroll_new(GTK_EVENT_CONTROLLER_SCROLL_VERTICAL | GTK_EVENT_CONTROLLER_SCROLL_DISCRETE);
    g_signal_connect(scroll, "scroll", G_CALLBACK(on_crown_scroll), web_view);
    gtk_widget_add_controller(window, scroll);

    /* Touch Edge Swipe Navigation */
    GtkGesture *swipe = gtk_gesture_swipe_new();
    g_signal_connect(swipe, "swipe", G_CALLBACK(on_swipe), app_data);
    gtk_widget_add_controller(window, GTK_EVENT_CONTROLLER(swipe));

    /* Load initial URL or Home */
    if (app_data->initial_url && strlen(app_data->initial_url) > 0) {
        navigate_to(app_data, app_data->initial_url);
    } else {
        on_btn_home_clicked(NULL, app_data);
    }

    gtk_window_present(GTK_WINDOW(window));
}

int main(int argc, char *argv[])
{
    memset(&g_app_data, 0, sizeof(WatchBrowserApp));

    if (argc > 1 && argv[1][0] != '-') {
        g_app_data.initial_url = g_strdup(argv[1]);
    }

    GtkApplication *app = gtk_application_new("org.asteroidos.browser", G_APPLICATION_DEFAULT_FLAGS);
    g_signal_connect(app, "activate", G_CALLBACK(activate), &g_app_data);

    int status = g_application_run(G_APPLICATION(app), argc, argv);

    g_object_unref(app);
    if (g_app_data.initial_url) {
        g_free(g_app_data.initial_url);
    }
    return status;
}
