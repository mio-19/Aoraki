/*
 * AsteroidOS Smartwatch Web Browser
 * High-performance, low-memory WebKitGTK 6.0 browser tailored for wearable displays
 * Reference & upstream architecture: https://asteroidos.org/
 */

#include <gtk/gtk.h>
#include <webkit/webkit.h>
#include <stdlib.h>
#include <string.h>

#define DEFAULT_USER_AGENT "Mozilla/5.0 (Linux; Android 10; Smartwatch; AsteroidOS) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36"
#define DEFAULT_ZOOM_LEVEL 0.85
#define SEARCH_URL_PREFIX "https://html.duckduckgo.com/html/?q="

typedef struct {
    GtkWidget *window;
    GtkWidget *header_box;
    GtkWidget *url_entry;
    GtkWidget *back_btn;
    GtkWidget *forward_btn;
    GtkWidget *reload_btn;
    GtkWidget *home_btn;
    GtkWidget *zoom_in_btn;
    GtkWidget *zoom_out_btn;
    GtkWidget *progress_bar;
    GtkWidget *web_view;
    gchar *portal_url;
    gdouble zoom_level;
} AsteroidBrowserApp;

static void update_navigation_buttons(AsteroidBrowserApp *app) {
    if (!app->web_view) return;
    gtk_widget_set_sensitive(app->back_btn, webkit_web_view_can_go_back(WEBKIT_WEB_VIEW(app->web_view)));
    gtk_widget_set_sensitive(app->forward_btn, webkit_web_view_can_go_forward(WEBKIT_WEB_VIEW(app->web_view)));
}

static void on_load_changed(WebKitWebView *web_view, WebKitLoadEvent load_event, gpointer user_data) {
    AsteroidBrowserApp *app = (AsteroidBrowserApp *)user_data;
    const gchar *uri = webkit_web_view_get_uri(web_view);

    switch (load_event) {
        case WEBKIT_LOAD_STARTED:
            gtk_widget_set_visible(app->progress_bar, TRUE);
            gtk_button_set_label(GTK_BUTTON(app->reload_btn), "✕");
            break;
        case WEBKIT_LOAD_COMMITTED:
            if (uri && g_strcmp0(uri, app->portal_url) != 0) {
                gtk_editable_set_text(GTK_EDITABLE(app->url_entry), uri);
            } else {
                gtk_editable_set_text(GTK_EDITABLE(app->url_entry), "");
            }
            break;
        case WEBKIT_LOAD_FINISHED:
            gtk_widget_set_visible(app->progress_bar, FALSE);
            gtk_button_set_label(GTK_BUTTON(app->reload_btn), "↻");
            update_navigation_buttons(app);
            break;
    }
}

static void on_notify_estimated_load_progress(WebKitWebView *web_view, GParamSpec *pspec, gpointer user_data) {
    AsteroidBrowserApp *app = (AsteroidBrowserApp *)user_data;
    gdouble progress = webkit_web_view_get_estimated_load_progress(web_view);
    gtk_progress_bar_set_fraction(GTK_PROGRESS_BAR(app->progress_bar), progress);
}

static void navigate_to_query_or_url(AsteroidBrowserApp *app, const gchar *input) {
    if (!input || strlen(input) == 0) {
        webkit_web_view_load_uri(WEBKIT_WEB_VIEW(app->web_view), app->portal_url);
        return;
    }

    gchar *target_url = NULL;
    if (g_str_has_prefix(input, "http://") ||
        g_str_has_prefix(input, "https://") ||
        g_str_has_prefix(input, "file://") ||
        g_str_has_prefix(input, "about:")) {
        target_url = g_strdup(input);
    } else if (strchr(input, '.') != NULL && strchr(input, ' ') == NULL) {
        // Domain name entered without protocol
        target_url = g_strdup_printf("https://%s", input);
    } else {
        // Search query
        gchar *escaped = g_uri_escape_string(input, NULL, TRUE);
        target_url = g_strdup_printf("%s%s", SEARCH_URL_PREFIX, escaped);
        g_free(escaped);
    }

    webkit_web_view_load_uri(WEBKIT_WEB_VIEW(app->web_view), target_url);
    g_free(target_url);
}

static void on_url_entry_activate(GtkEntry *entry, gpointer user_data) {
    AsteroidBrowserApp *app = (AsteroidBrowserApp *)user_data;
    const gchar *text = gtk_editable_get_text(GTK_EDITABLE(entry));
    navigate_to_query_or_url(app, text);
    gtk_widget_grab_focus(app->web_view);
}

static void on_back_clicked(GtkButton *btn, gpointer user_data) {
    AsteroidBrowserApp *app = (AsteroidBrowserApp *)user_data;
    if (webkit_web_view_can_go_back(WEBKIT_WEB_VIEW(app->web_view))) {
        webkit_web_view_go_back(WEBKIT_WEB_VIEW(app->web_view));
    } else {
        webkit_web_view_load_uri(WEBKIT_WEB_VIEW(app->web_view), app->portal_url);
    }
}

static void on_forward_clicked(GtkButton *btn, gpointer user_data) {
    AsteroidBrowserApp *app = (AsteroidBrowserApp *)user_data;
    if (webkit_web_view_can_go_forward(WEBKIT_WEB_VIEW(app->web_view))) {
        webkit_web_view_go_forward(WEBKIT_WEB_VIEW(app->web_view));
    }
}

static void on_reload_clicked(GtkButton *btn, gpointer user_data) {
    AsteroidBrowserApp *app = (AsteroidBrowserApp *)user_data;
    if (webkit_web_view_is_loading(WEBKIT_WEB_VIEW(app->web_view))) {
        webkit_web_view_stop_loading(WEBKIT_WEB_VIEW(app->web_view));
    } else {
        webkit_web_view_reload(WEBKIT_WEB_VIEW(app->web_view));
    }
}

static void on_home_clicked(GtkButton *btn, gpointer user_data) {
    AsteroidBrowserApp *app = (AsteroidBrowserApp *)user_data;
    webkit_web_view_load_uri(WEBKIT_WEB_VIEW(app->web_view), app->portal_url);
}

static void on_zoom_in_clicked(GtkButton *btn, gpointer user_data) {
    AsteroidBrowserApp *app = (AsteroidBrowserApp *)user_data;
    app->zoom_level += 0.10;
    if (app->zoom_level > 2.0) app->zoom_level = 2.0;
    webkit_web_view_set_zoom_level(WEBKIT_WEB_VIEW(app->web_view), app->zoom_level);
}

static void on_zoom_out_clicked(GtkButton *btn, gpointer user_data) {
    AsteroidBrowserApp *app = (AsteroidBrowserApp *)user_data;
    app->zoom_level -= 0.10;
    if (app->zoom_level < 0.40) app->zoom_level = 0.40;
    webkit_web_view_set_zoom_level(WEBKIT_WEB_VIEW(app->web_view), app->zoom_level);
}

static void load_custom_css(const gchar *share_dir) {
    gchar *css_path = g_strdup_printf("%s/watch-gtk.css", share_dir);
    GFile *css_file = g_file_new_for_path(css_path);

    if (g_file_query_exists(css_file, NULL)) {
        GtkCssProvider *provider = gtk_css_provider_new();
        gtk_css_provider_load_from_file(provider, css_file);
        gtk_style_context_add_provider_for_display(
            gdk_display_get_default(),
            GTK_STYLE_PROVIDER(provider),
            GTK_STYLE_PROVIDER_PRIORITY_APPLICATION
        );
        g_object_unref(provider);
    }

    g_object_unref(css_file);
    g_free(css_path);
}

int main(int argc, char **argv) {
    const gchar *initial_url = NULL;
    for (int i = 1; i < argc; i++) {
        if (g_strcmp0(argv[i], "-h") == 0 || g_strcmp0(argv[i], "--help") == 0) {
            g_print("Usage: asteroid-browser [OPTIONS] [URL]\n");
            g_print("AsteroidOS Smartwatch Web Browser powered by WebKitGTK 6.0\n\n");
            g_print("Options:\n");
            g_print("  -h, --help    Show this help message\n");
            return 0;
        } else if (!initial_url && argv[i][0] != '-') {
            initial_url = argv[i];
        }
    }

    if (!gtk_init_check()) {
        g_printerr("Error: Failed to initialize GTK display connection\n");
        return 1;
    }

    const gchar *share_dir = g_getenv("ASTEROID_BROWSER_SHARE");
    if (!share_dir) {
        share_dir = "/usr/share/asteroid-browser";
    }

    AsteroidBrowserApp app = {0};
    app.zoom_level = DEFAULT_ZOOM_LEVEL;

    // Portal fallback
    app.portal_url = g_strdup_printf("file://%s/portal.html", share_dir);

    // Apply Asteroid watch theme
    load_custom_css(share_dir);

    // Main window setup
    app.window = gtk_window_new();
    gtk_window_set_title(GTK_WINDOW(app.window), "Asteroid Browser");
    gtk_window_set_default_size(GTK_WINDOW(app.window), 416, 416);
    gtk_window_fullscreen(GTK_WINDOW(app.window));

    // Outer vertical layout
    GtkWidget *main_vbox = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
    gtk_window_set_child(GTK_WINDOW(app.window), main_vbox);

    // AsteroidOS Smartwatch Navigation Header
    app.header_box = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 6);
    gtk_widget_add_css_class(app.header_box, "asteroid-header");
    gtk_box_append(GTK_BOX(main_vbox), app.header_box);

    // Back button
    app.back_btn = gtk_button_new_with_label("‹");
    gtk_widget_add_css_class(app.back_btn, "asteroid-nav-btn");
    gtk_widget_set_tooltip_text(app.back_btn, "Back");
    g_signal_connect(app.back_btn, "clicked", G_CALLBACK(on_back_clicked), &app);
    gtk_box_append(GTK_BOX(app.header_box), app.back_btn);

    // Forward button
    app.forward_btn = gtk_button_new_with_label("›");
    gtk_widget_add_css_class(app.forward_btn, "asteroid-nav-btn");
    gtk_widget_set_tooltip_text(app.forward_btn, "Forward");
    g_signal_connect(app.forward_btn, "clicked", G_CALLBACK(on_forward_clicked), &app);
    gtk_box_append(GTK_BOX(app.header_box), app.forward_btn);

    // URL / Search Entry
    app.url_entry = gtk_entry_new();
    gtk_widget_add_css_class(app.url_entry, "asteroid-url-entry");
    gtk_entry_set_placeholder_text(GTK_ENTRY(app.url_entry), "Search or URL...");
    gtk_widget_set_hexpand(app.url_entry, TRUE);
    g_signal_connect(app.url_entry, "activate", G_CALLBACK(on_url_entry_activate), &app);
    gtk_box_append(GTK_BOX(app.header_box), app.url_entry);

    // Reload / Stop button
    app.reload_btn = gtk_button_new_with_label("↻");
    gtk_widget_add_css_class(app.reload_btn, "asteroid-nav-btn");
    gtk_widget_set_tooltip_text(app.reload_btn, "Reload / Stop");
    g_signal_connect(app.reload_btn, "clicked", G_CALLBACK(on_reload_clicked), &app);
    gtk_box_append(GTK_BOX(app.header_box), app.reload_btn);

    // Home / Portal button
    app.home_btn = gtk_button_new_with_label("⌂");
    gtk_widget_add_css_class(app.home_btn, "asteroid-nav-btn");
    gtk_widget_set_tooltip_text(app.home_btn, "Watch Portal");
    g_signal_connect(app.home_btn, "clicked", G_CALLBACK(on_home_clicked), &app);
    gtk_box_append(GTK_BOX(app.header_box), app.home_btn);

    // Zoom out button
    app.zoom_out_btn = gtk_button_new_with_label("−");
    gtk_widget_add_css_class(app.zoom_out_btn, "asteroid-nav-btn");
    gtk_widget_set_tooltip_text(app.zoom_out_btn, "Zoom Out");
    g_signal_connect(app.zoom_out_btn, "clicked", G_CALLBACK(on_zoom_out_clicked), &app);
    gtk_box_append(GTK_BOX(app.header_box), app.zoom_out_btn);

    // Zoom in button
    app.zoom_in_btn = gtk_button_new_with_label("+");
    gtk_widget_add_css_class(app.zoom_in_btn, "asteroid-nav-btn");
    gtk_widget_set_tooltip_text(app.zoom_in_btn, "Zoom In");
    g_signal_connect(app.zoom_in_btn, "clicked", G_CALLBACK(on_zoom_in_clicked), &app);
    gtk_box_append(GTK_BOX(app.header_box), app.zoom_in_btn);

    // Progress Bar
    app.progress_bar = gtk_progress_bar_new();
    gtk_widget_add_css_class(app.progress_bar, "asteroid-progress-bar");
    gtk_widget_set_visible(app.progress_bar, FALSE);
    gtk_box_append(GTK_BOX(main_vbox), app.progress_bar);

    // WebKit WebView Setup
    WebKitSettings *settings = webkit_settings_new();
    webkit_settings_set_enable_page_cache(settings, FALSE); // Memory reduction for wearables
    webkit_settings_set_enable_smooth_scrolling(settings, TRUE);
    webkit_settings_set_hardware_acceleration_policy(settings, WEBKIT_HARDWARE_ACCELERATION_POLICY_ALWAYS);
    webkit_settings_set_user_agent(settings, DEFAULT_USER_AGENT);

    app.web_view = webkit_web_view_new();
    webkit_web_view_set_settings(WEBKIT_WEB_VIEW(app.web_view), settings);
    g_object_unref(settings);

    gtk_widget_add_css_class(app.web_view, "asteroid-webview");
    webkit_web_view_set_zoom_level(WEBKIT_WEB_VIEW(app.web_view), app.zoom_level);
    gtk_widget_set_vexpand(app.web_view, TRUE);
    gtk_widget_set_hexpand(app.web_view, TRUE);

    g_signal_connect(app.web_view, "load-changed", G_CALLBACK(on_load_changed), &app);
    g_signal_connect(app.web_view, "notify::estimated-load-progress", G_CALLBACK(on_notify_estimated_load_progress), &app);

    gtk_box_append(GTK_BOX(main_vbox), app.web_view);

    // Initial navigation
    if (initial_url) {
        navigate_to_query_or_url(&app, initial_url);
    } else {
        webkit_web_view_load_uri(WEBKIT_WEB_VIEW(app.web_view), app.portal_url);
    }

    gtk_window_present(GTK_WINDOW(app.window));

    while (g_list_model_get_n_items(gtk_window_get_toplevels()) > 0) {
        g_main_context_iteration(NULL, TRUE);
    }

    g_free(app.portal_url);
    return 0;
}
