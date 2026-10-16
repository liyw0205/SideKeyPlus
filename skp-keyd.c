#define _GNU_SOURCE

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <dirent.h>
#include <poll.h>
#include <time.h>
#include <signal.h>
#include <stdarg.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <sys/time.h>
#include <linux/input.h>
#include <linux/uinput.h>

#ifndef KEY_MAX
#define KEY_MAX 0x2ff
#endif

#ifndef EV_MAX
#define EV_MAX 0x1f
#endif

#define MAX_DEVICES 32
#define CONFIG_PATH "/data/adb/SideKeyPlus/config.ini"
#define RUN_ACTION "/data/adb/modules/SideKeyPlus/run_action.sh"

#define LONG_PRESS_MS 600
#define DOUBLE_CLICK_MS 150
#define BOTH_KEY_MS 160
#define RESCAN_MS 3000
#define CONFIG_RELOAD_MS 2000

typedef struct {
    int fd;
    char path[128];
    char name[256];
    bool grabbed;
} InputDev;

typedef struct {
    bool volume_key_enable;
    bool block_volume_key;

    int action_volume_up_click_type;
    int action_volume_up_double_type;
    int action_volume_up_long_type;

    int action_volume_down_click_type;
    int action_volume_down_double_type;
    int action_volume_down_long_type;

    int action_volume_both_click_type;
} Config;

typedef struct {
    bool down;
    bool long_fired;
    bool injected_down;
    int64_t down_time;
} KeyState;

static volatile sig_atomic_t g_running = 1;

static InputDev g_devs[MAX_DEVICES];
static int g_dev_count = 0;

static Config g_cfg = {0};
static bool g_config_loaded = false;
static time_t g_config_mtime = 0;
static off_t g_config_size = 0;

static int g_uinput_fd = -1;

static KeyState g_up = {0};
static KeyState g_down = {0};

static bool g_pending_up_click = false;
static bool g_pending_down_click = false;
static int64_t g_pending_up_time = 0;
static int64_t g_pending_down_time = 0;

static bool g_both_fired = false;
static bool g_rescan_requested = true;

static int64_t now_ms(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ((int64_t)ts.tv_sec * 1000) + (ts.tv_nsec / 1000000);
}

static void wall_time_str(char *buf, size_t len) {
    time_t t = time(NULL);
    struct tm tmv;
    localtime_r(&t, &tmv);
    strftime(buf, len, "%F %T", &tmv);
}

static void log_line(const char *fmt, ...) {
    char tbuf[64];
    wall_time_str(tbuf, sizeof(tbuf));

    fprintf(stdout, "[%s] ", tbuf);

    va_list ap;
    va_start(ap, fmt);
    vfprintf(stdout, fmt, ap);
    va_end(ap);

    fprintf(stdout, "\n");
    fflush(stdout);
}

static void on_signal(int sig) {
    (void)sig;
    g_running = 0;
}

static bool str_bool(const char *s) {
    if (!s) return false;
    return strcmp(s, "1") == 0 ||
           strcasecmp(s, "true") == 0 ||
           strcasecmp(s, "yes") == 0 ||
           strcasecmp(s, "on") == 0;
}

static int str_int(const char *s, int def) {
    if (!s || !*s) return def;

    char *end = NULL;
    long v = strtol(s, &end, 10);
    if (end == s) return def;
    return (int)v;
}

static void trim(char *s) {
    if (!s) return;

    char *p = s;
    while (*p == ' ' || *p == '\t' || *p == '\r' || *p == '\n') p++;

    if (p != s) memmove(s, p, strlen(p) + 1);

    size_t n = strlen(s);
    while (n > 0) {
        char c = s[n - 1];
        if (c == ' ' || c == '\t' || c == '\r' || c == '\n') {
            s[n - 1] = 0;
            n--;
        } else {
            break;
        }
    }
}

static void reload_config(void) {
    struct stat config_stat;
    bool config_exists = stat(CONFIG_PATH, &config_stat) == 0;

    if (g_config_loaded && config_exists &&
        config_stat.st_mtime == g_config_mtime &&
        config_stat.st_size == g_config_size) {
        return;
    }

    if (g_config_loaded && !config_exists && g_config_mtime == 0) {
        return;
    }

    Config old = g_cfg;
    Config new_cfg;
    memset(&new_cfg, 0, sizeof(new_cfg));

    FILE *fp = fopen(CONFIG_PATH, "r");
    if (!fp) {
        g_cfg = new_cfg;
        g_config_loaded = true;
        g_config_mtime = 0;
        g_config_size = 0;
        if (memcmp(&old, &g_cfg, sizeof(Config)) != 0) {
            log_line("reload_config: config missing, use default");
        }
        return;
    }

    char line[1024];

    while (fgets(line, sizeof(line), fp)) {
        trim(line);

        if (line[0] == 0 || line[0] == '#') continue;

        char *eq = strchr(line, '=');
        if (!eq) continue;

        *eq = 0;
        char *key = line;
        char *val = eq + 1;

        trim(key);
        trim(val);

        if (strcmp(key, "VOLUME_KEY_ENABLE") == 0) {
            new_cfg.volume_key_enable = str_bool(val);
        } else if (strcmp(key, "BLOCK_VOLUME_KEY") == 0) {
            new_cfg.block_volume_key = str_bool(val);
        } else if (strcmp(key, "ACTION_VOLUME_UP_CLICK_TYPE") == 0) {
            new_cfg.action_volume_up_click_type = str_int(val, 0);
        } else if (strcmp(key, "ACTION_VOLUME_UP_DOUBLE_TYPE") == 0) {
            new_cfg.action_volume_up_double_type = str_int(val, 0);
        } else if (strcmp(key, "ACTION_VOLUME_UP_LONG_TYPE") == 0) {
            new_cfg.action_volume_up_long_type = str_int(val, 0);
        } else if (strcmp(key, "ACTION_VOLUME_DOWN_CLICK_TYPE") == 0) {
            new_cfg.action_volume_down_click_type = str_int(val, 0);
        } else if (strcmp(key, "ACTION_VOLUME_DOWN_DOUBLE_TYPE") == 0) {
            new_cfg.action_volume_down_double_type = str_int(val, 0);
        } else if (strcmp(key, "ACTION_VOLUME_DOWN_LONG_TYPE") == 0) {
            new_cfg.action_volume_down_long_type = str_int(val, 0);
        } else if (strcmp(key, "ACTION_VOLUME_BOTH_CLICK_TYPE") == 0) {
            new_cfg.action_volume_both_click_type = str_int(val, 0);
        }
    }

    fclose(fp);

    g_cfg = new_cfg;
    g_config_loaded = true;
    g_config_mtime = config_exists ? config_stat.st_mtime : 0;
    g_config_size = config_exists ? config_stat.st_size : 0;

    log_line("reload_config: VOLUME_KEY_ENABLE=%d BLOCK_VOLUME_KEY=%d UP_CLICK=%d UP_DOUBLE=%d UP_LONG=%d DOWN_CLICK=%d DOWN_DOUBLE=%d DOWN_LONG=%d BOTH=%d",
             g_cfg.volume_key_enable ? 1 : 0,
             g_cfg.block_volume_key ? 1 : 0,
             g_cfg.action_volume_up_click_type,
             g_cfg.action_volume_up_double_type,
             g_cfg.action_volume_up_long_type,
             g_cfg.action_volume_down_click_type,
             g_cfg.action_volume_down_double_type,
             g_cfg.action_volume_down_long_type,
             g_cfg.action_volume_both_click_type);

    if (memcmp(&old, &g_cfg, sizeof(Config)) != 0) {
        log_line("config_changed");
    }
}

static bool event_has_action(const char *event) {
    if (!event) return false;

    if (strcmp(event, "VOLUME_UP_CLICK") == 0) {
        return g_cfg.action_volume_up_click_type != 0;
    } else if (strcmp(event, "VOLUME_UP_DOUBLE") == 0) {
        return g_cfg.action_volume_up_double_type != 0;
    } else if (strcmp(event, "VOLUME_UP_LONG") == 0) {
        return g_cfg.action_volume_up_long_type != 0;
    } else if (strcmp(event, "VOLUME_DOWN_CLICK") == 0) {
        return g_cfg.action_volume_down_click_type != 0;
    } else if (strcmp(event, "VOLUME_DOWN_DOUBLE") == 0) {
        return g_cfg.action_volume_down_double_type != 0;
    } else if (strcmp(event, "VOLUME_DOWN_LONG") == 0) {
        return g_cfg.action_volume_down_long_type != 0;
    } else if (strcmp(event, "VOLUME_BOTH_CLICK") == 0) {
        return g_cfg.action_volume_both_click_type != 0;
    }

    return false;
}

static bool test_bit(const unsigned long *bits, int bit) {
    return !!(bits[bit / (8 * sizeof(unsigned long))] &
              (1UL << (bit % (8 * sizeof(unsigned long)))));
}

static bool device_has_key(int fd, int key) {
    unsigned long bits[(KEY_MAX + 8 * sizeof(unsigned long)) / (8 * sizeof(unsigned long))];
    memset(bits, 0, sizeof(bits));

    if (ioctl(fd, EVIOCGBIT(EV_KEY, sizeof(bits)), bits) < 0) {
        return false;
    }

    return test_bit(bits, key);
}

static bool device_has_ev_key(int fd) {
    unsigned long bits[(EV_MAX + 8 * sizeof(unsigned long)) / (8 * sizeof(unsigned long))];
    memset(bits, 0, sizeof(bits));

    if (ioctl(fd, EVIOCGBIT(0, sizeof(bits)), bits) < 0) {
        return false;
    }

    return test_bit(bits, EV_KEY);
}

static bool bad_device_name(const char *name) {
    if (!name || !name[0]) return false;

    if (strcasestr(name, "Button Jack")) return true;
    if (strcasestr(name, "snd-card")) return true;
    if (strcasestr(name, "sound")) return true;
    if (strcasestr(name, "Headset")) return true;
    if (strcasestr(name, "headphone")) return true;
    if (strcasestr(name, "h2w")) return true;
    if (strcasestr(name, "jack")) return true;

    if (strcasestr(name, "SideKeyPlus")) return true;
    if (strcasestr(name, "virtual")) return true;
    if (strcasestr(name, "uinput")) return true;

    return false;
}

static void close_devices(void) {
    for (int i = 0; i < g_dev_count; i++) {
        if (g_devs[i].fd >= 0) {
            if (g_devs[i].grabbed) {
                ioctl(g_devs[i].fd, EVIOCGRAB, 0);
            }
            close(g_devs[i].fd);
        }
    }

    memset(g_devs, 0, sizeof(g_devs));
    g_dev_count = 0;
}

static bool same_device_opened(const char *path) {
    for (int i = 0; i < g_dev_count; i++) {
        if (strcmp(g_devs[i].path, path) == 0) return true;
    }
    return false;
}

static void apply_grab_state(void) {
    bool should_grab = g_cfg.volume_key_enable && g_cfg.block_volume_key;

    for (int i = 0; i < g_dev_count; i++) {
        if (should_grab && !g_devs[i].grabbed) {
            if (ioctl(g_devs[i].fd, EVIOCGRAB, 1) == 0) {
                g_devs[i].grabbed = true;
                log_line("EVIOCGRAB on: %s name=%s", g_devs[i].path, g_devs[i].name);
            } else {
                log_line("EVIOCGRAB on failed: %s errno=%d %s",
                         g_devs[i].path, errno, strerror(errno));
            }
        } else if (!should_grab && g_devs[i].grabbed) {
            ioctl(g_devs[i].fd, EVIOCGRAB, 0);
            g_devs[i].grabbed = false;
            log_line("EVIOCGRAB off: %s name=%s", g_devs[i].path, g_devs[i].name);
        }
    }
}

static void scan_devices(void) {
    close_devices();

    DIR *dir = opendir("/dev/input");
    if (!dir) {
        log_line("opendir /dev/input failed: errno=%d %s", errno, strerror(errno));
        return;
    }

    struct dirent *de;

    while ((de = readdir(dir)) != NULL) {
        if (strncmp(de->d_name, "event", 5) != 0) continue;
        if (g_dev_count >= MAX_DEVICES) break;

        char path[128];
        snprintf(path, sizeof(path), "/dev/input/%s", de->d_name);

        if (same_device_opened(path)) continue;

        int fd = open(path, O_RDONLY | O_NONBLOCK | O_CLOEXEC);
        if (fd < 0) continue;

        char name[256] = {0};
        ioctl(fd, EVIOCGNAME(sizeof(name)), name);

        bool has_ev_key = device_has_ev_key(fd);
        bool has_up = device_has_key(fd, KEY_VOLUMEUP);
        bool has_down = device_has_key(fd, KEY_VOLUMEDOWN);
        bool bad_name = bad_device_name(name);

        if (has_ev_key && (has_up || has_down) && !bad_name) {
            InputDev *d = &g_devs[g_dev_count++];
            d->fd = fd;
            d->grabbed = false;
            snprintf(d->path, sizeof(d->path), "%s", path);
            snprintf(d->name, sizeof(d->name), "%s", name[0] ? name : "unknown");

            log_line("selected input device: %s name=%s has_up=%d has_down=%d",
                     d->path, d->name, has_up ? 1 : 0, has_down ? 1 : 0);
        } else {
            if (has_up || has_down || strcasestr(name, "Button") || strcasestr(name, "key")) {
                log_line("skip input device: %s name=%s has_up=%d has_down=%d bad_name=%d",
                         path, name[0] ? name : "unknown",
                         has_up ? 1 : 0, has_down ? 1 : 0, bad_name ? 1 : 0);
            }
            close(fd);
        }
    }

    closedir(dir);

    apply_grab_state();

    if (g_dev_count == 0) {
        log_line("no volume key input device selected");
    }
}

static int setup_uinput(void) {
    int fd = open("/dev/uinput", O_WRONLY | O_NONBLOCK | O_CLOEXEC);
    if (fd < 0) {
        fd = open("/dev/input/uinput", O_WRONLY | O_NONBLOCK | O_CLOEXEC);
    }

    if (fd < 0) {
        log_line("open uinput failed: errno=%d %s", errno, strerror(errno));
        return -1;
    }

    ioctl(fd, UI_SET_EVBIT, EV_KEY);
    ioctl(fd, UI_SET_EVBIT, EV_SYN);
    ioctl(fd, UI_SET_KEYBIT, KEY_VOLUMEUP);
    ioctl(fd, UI_SET_KEYBIT, KEY_VOLUMEDOWN);

    struct uinput_setup usetup;
    memset(&usetup, 0, sizeof(usetup));

    snprintf(usetup.name, UINPUT_MAX_NAME_SIZE, "SideKeyPlus virtual volume");
    usetup.id.bustype = BUS_VIRTUAL;
    usetup.id.vendor = 0x534b;
    usetup.id.product = 0x502b;
    usetup.id.version = 1;

    if (ioctl(fd, UI_DEV_SETUP, &usetup) < 0) {
        log_line("UI_DEV_SETUP failed: errno=%d %s", errno, strerror(errno));
        close(fd);
        return -1;
    }

    if (ioctl(fd, UI_DEV_CREATE) < 0) {
        log_line("UI_DEV_CREATE failed: errno=%d %s", errno, strerror(errno));
        close(fd);
        return -1;
    }

    log_line("uinput created");
    return fd;
}

static void emit_event(int type, int code, int value) {
    if (g_uinput_fd < 0) return;

    struct input_event ev;
    memset(&ev, 0, sizeof(ev));
    gettimeofday(&ev.time, NULL);
    ev.type = type;
    ev.code = code;
    ev.value = value;

    ssize_t wr = write(g_uinput_fd, &ev, sizeof(ev));
    (void)wr;
}

static void emit_syn(void) {
    emit_event(EV_SYN, SYN_REPORT, 0);
}

static void emit_key(int key, int value) {
    emit_event(EV_KEY, key, value);
    emit_syn();
}

static void inject_short_press(int key) {
    if (!(g_cfg.volume_key_enable && g_cfg.block_volume_key)) return;

    emit_key(key, 1);
    emit_key(key, 0);

    log_line("uinput short press passthrough: code=%d", key);
}

static void run_action_async(const char *event) {
    if (!event || !event[0]) return;

    if (!g_cfg.volume_key_enable) {
        log_line("run_action skipped because VOLUME_KEY_ENABLE=0: %s", event);
        return;
    }

    log_line("run_action: %s", event);

    pid_t pid = fork();
    if (pid == 0) {
        setsid();
        for (int i = 0; i < g_dev_count; i++) {
            if (g_devs[i].fd >= 0) close(g_devs[i].fd);
        }
        if (g_uinput_fd >= 0) close(g_uinput_fd);
        execl("/system/bin/sh", "sh", RUN_ACTION, event, (char *)NULL);
        execl("/bin/sh", "sh", RUN_ACTION, event, (char *)NULL);
        _exit(127);
    }

    if (pid < 0) {
        log_line("run_action fork failed: errno=%d %s", errno, strerror(errno));
    }
}

static void reap_children(void) {
    int status;
    while (waitpid(-1, &status, WNOHANG) > 0) {}
}

static KeyState *state_for_key(int code) {
    if (code == KEY_VOLUMEUP) return &g_up;
    if (code == KEY_VOLUMEDOWN) return &g_down;
    return NULL;
}

static void clear_pending_for_key(int code) {
    if (code == KEY_VOLUMEUP) {
        g_pending_up_click = false;
        g_pending_up_time = 0;
    } else if (code == KEY_VOLUMEDOWN) {
        g_pending_down_click = false;
        g_pending_down_time = 0;
    }
}

static bool has_pending_for_key(int code) {
    if (code == KEY_VOLUMEUP) return g_pending_up_click;
    if (code == KEY_VOLUMEDOWN) return g_pending_down_click;
    return false;
}

static int64_t pending_time_for_key(int code) {
    if (code == KEY_VOLUMEUP) return g_pending_up_time;
    if (code == KEY_VOLUMEDOWN) return g_pending_down_time;
    return 0;
}

static void set_pending_for_key(int code, int64_t t) {
    if (code == KEY_VOLUMEUP) {
        g_pending_up_click = true;
        g_pending_up_time = t;
    } else if (code == KEY_VOLUMEDOWN) {
        g_pending_down_click = true;
        g_pending_down_time = t;
    }
}

static void fire_pending_clicks_if_due(void) {
    int64_t t = now_ms();

    if (g_pending_up_click && t - g_pending_up_time > DOUBLE_CLICK_MS) {
        g_pending_up_click = false;

        if (event_has_action("VOLUME_UP_CLICK")) {
            run_action_async("VOLUME_UP_CLICK");
        } else {
            inject_short_press(KEY_VOLUMEUP);
        }
    }

    if (g_pending_down_click && t - g_pending_down_time > DOUBLE_CLICK_MS) {
        g_pending_down_click = false;

        if (event_has_action("VOLUME_DOWN_CLICK")) {
            run_action_async("VOLUME_DOWN_CLICK");
        } else {
            inject_short_press(KEY_VOLUMEDOWN);
        }
    }
}

static void start_injected_long_press(int key, KeyState *st) {
    if (!(g_cfg.volume_key_enable && g_cfg.block_volume_key)) return;
    if (st->injected_down) return;

    emit_key(key, 1);
    st->injected_down = true;
    log_line("uinput key down for long press: code=%d", key);
}

static void stop_injected_long_press(int key, KeyState *st) {
    if (!st->injected_down) return;

    emit_key(key, 0);
    st->injected_down = false;
    log_line("uinput key up for long press: code=%d", key);
}

static void reset_input_state(void) {
    stop_injected_long_press(KEY_VOLUMEUP, &g_up);
    stop_injected_long_press(KEY_VOLUMEDOWN, &g_down);
    memset(&g_up, 0, sizeof(g_up));
    memset(&g_down, 0, sizeof(g_down));
    g_pending_up_click = false;
    g_pending_down_click = false;
    g_pending_up_time = 0;
    g_pending_down_time = 0;
    g_both_fired = false;
}

static void remove_device_fd(int fd) {
    for (int i = 0; i < g_dev_count; i++) {
        if (g_devs[i].fd != fd) continue;

        log_line("remove input device: %s name=%s fd=%d",
                 g_devs[i].path, g_devs[i].name, fd);
        if (g_devs[i].grabbed) {
            ioctl(g_devs[i].fd, EVIOCGRAB, 0);
        }
        close(g_devs[i].fd);

        for (int j = i + 1; j < g_dev_count; j++) {
            g_devs[j - 1] = g_devs[j];
        }
        g_dev_count--;
        memset(&g_devs[g_dev_count], 0, sizeof(g_devs[g_dev_count]));
        reset_input_state();
        g_rescan_requested = true;
        return;
    }
}

static void check_long_press(void) {
    int64_t t = now_ms();

    if (g_up.down && !g_up.long_fired && t - g_up.down_time >= LONG_PRESS_MS) {
        g_up.long_fired = true;
        clear_pending_for_key(KEY_VOLUMEUP);

        if (event_has_action("VOLUME_UP_LONG")) {
            run_action_async("VOLUME_UP_LONG");
        }

        start_injected_long_press(KEY_VOLUMEUP, &g_up);
    }

    if (g_down.down && !g_down.long_fired && t - g_down.down_time >= LONG_PRESS_MS) {
        g_down.long_fired = true;
        clear_pending_for_key(KEY_VOLUMEDOWN);

        if (event_has_action("VOLUME_DOWN_LONG")) {
            run_action_async("VOLUME_DOWN_LONG");
        }

        start_injected_long_press(KEY_VOLUMEDOWN, &g_down);
    }
}

static void handle_click_release(int code, int64_t t) {
    if (g_both_fired) {
        clear_pending_for_key(code);
        return;
    }

    if (has_pending_for_key(code) && t - pending_time_for_key(code) <= DOUBLE_CLICK_MS) {
        clear_pending_for_key(code);

        if (code == KEY_VOLUMEUP) {
            if (event_has_action("VOLUME_UP_DOUBLE")) {
                run_action_async("VOLUME_UP_DOUBLE");
            } else {
                inject_short_press(KEY_VOLUMEUP);
                inject_short_press(KEY_VOLUMEUP);
            }
        } else if (code == KEY_VOLUMEDOWN) {
            if (event_has_action("VOLUME_DOWN_DOUBLE")) {
                run_action_async("VOLUME_DOWN_DOUBLE");
            } else {
                inject_short_press(KEY_VOLUMEDOWN);
                inject_short_press(KEY_VOLUMEDOWN);
            }
        }
    } else {
        set_pending_for_key(code, t);
    }
}

static void handle_key_event(int code, int value) {
    if (code != KEY_VOLUMEUP && code != KEY_VOLUMEDOWN) return;

    int64_t t = now_ms();
    KeyState *st = state_for_key(code);
    if (!st) return;

    if (value == 1) {
        st->down = true;
        st->long_fired = false;
        st->injected_down = false;
        st->down_time = t;

        if ((code == KEY_VOLUMEUP && g_down.down) ||
            (code == KEY_VOLUMEDOWN && g_up.down)) {
            int64_t other_down_time = (code == KEY_VOLUMEUP) ? g_down.down_time : g_up.down_time;

            if (llabs(t - other_down_time) <= BOTH_KEY_MS) {
                g_both_fired = true;
                clear_pending_for_key(KEY_VOLUMEUP);
                clear_pending_for_key(KEY_VOLUMEDOWN);

                if (event_has_action("VOLUME_BOTH_CLICK")) {
                    run_action_async("VOLUME_BOTH_CLICK");
                }
            }
        }

        log_line("key down: code=%d", code);
    } else if (value == 0) {
        bool was_long = st->long_fired;
        int64_t dur = t - st->down_time;

        stop_injected_long_press(code, st);

        st->down = false;
        st->long_fired = false;

        log_line("key up: code=%d duration=%lldms long=%d both=%d",
                 code, (long long)dur, was_long ? 1 : 0, g_both_fired ? 1 : 0);

        if (!was_long && dur < LONG_PRESS_MS) {
            handle_click_release(code, t);
        }

        if (!g_up.down && !g_down.down) {
            g_both_fired = false;
        }
    } else if (value == 2) {
        if (st->long_fired && g_cfg.volume_key_enable && g_cfg.block_volume_key) {
            emit_key(code, 2);
        }
    }
}

static void event_loop(void) {
    int64_t last_scan = now_ms();
    int64_t last_config = 0;

    while (g_running) {
        reap_children();

        int64_t t = now_ms();

        if (t - last_config >= CONFIG_RELOAD_MS) {
            reload_config();
            apply_grab_state();
            last_config = t;
        }

        if (g_rescan_requested ||
            (g_dev_count == 0 && t - last_scan >= RESCAN_MS)) {
            scan_devices();
            last_scan = t;
            g_rescan_requested = false;
        }

        struct pollfd pfds[MAX_DEVICES];
        int n = 0;

        for (int i = 0; i < g_dev_count; i++) {
            pfds[n].fd = g_devs[i].fd;
            pfds[n].events = POLLIN;
            pfds[n].revents = 0;
            n++;
        }

        int timeout = 1000;
        int64_t wait_ms = CONFIG_RELOAD_MS - (t - last_config);
        if (wait_ms < timeout) timeout = wait_ms > 0 ? (int)wait_ms : 0;

        if (g_dev_count == 0) {
            wait_ms = RESCAN_MS - (t - last_scan);
            if (wait_ms < timeout) timeout = wait_ms > 0 ? (int)wait_ms : 0;
        }

        if (g_pending_up_click) {
            wait_ms = DOUBLE_CLICK_MS - (t - g_pending_up_time);
            if (wait_ms < timeout) timeout = wait_ms > 0 ? (int)wait_ms : 0;
        }
        if (g_pending_down_click) {
            wait_ms = DOUBLE_CLICK_MS - (t - g_pending_down_time);
            if (wait_ms < timeout) timeout = wait_ms > 0 ? (int)wait_ms : 0;
        }
        if (g_up.down && !g_up.long_fired) {
            wait_ms = LONG_PRESS_MS - (t - g_up.down_time);
            if (wait_ms < timeout) timeout = wait_ms > 0 ? (int)wait_ms : 0;
        }
        if (g_down.down && !g_down.long_fired) {
            wait_ms = LONG_PRESS_MS - (t - g_down.down_time);
            if (wait_ms < timeout) timeout = wait_ms > 0 ? (int)wait_ms : 0;
        }

        int ret = poll(pfds, (nfds_t)n, timeout);

        check_long_press();
        fire_pending_clicks_if_due();

        if (ret < 0) {
            if (errno == EINTR) continue;
            log_line("poll failed: errno=%d %s", errno, strerror(errno));
            usleep(200 * 1000);
            continue;
        }

        if (ret == 0) continue;

        for (int i = 0; i < n; i++) {
            short revents = pfds[i].revents;
            if (!revents) continue;

            bool device_bad = (revents & (POLLERR | POLLHUP | POLLNVAL)) != 0;

            if (revents & POLLIN) {
                struct input_event ev;
                ssize_t rd;

                while ((rd = read(pfds[i].fd, &ev, sizeof(ev))) == sizeof(ev)) {
                    if (ev.type == EV_KEY &&
                        (ev.code == KEY_VOLUMEUP || ev.code == KEY_VOLUMEDOWN)) {
                        handle_key_event(ev.code, ev.value);
                    }
                }

                if (rd == 0 || (rd < 0 && errno != EAGAIN && errno != EINTR)) {
                    device_bad = true;
                }
            }

            if (device_bad) {
                log_line("device state changed: fd=%d revents=0x%x", pfds[i].fd, revents);
                remove_device_fd(pfds[i].fd);
            }
        }
    }
}

int main(void) {
    signal(SIGINT, on_signal);
    signal(SIGTERM, on_signal);
    signal(SIGHUP, on_signal);

    log_line("===== skp-keyd start =====");

    reload_config();

    g_uinput_fd = setup_uinput();

    scan_devices();
    g_rescan_requested = false;

    event_loop();

    log_line("===== skp-keyd stop =====");

    close_devices();

    if (g_uinput_fd >= 0) {
        ioctl(g_uinput_fd, UI_DEV_DESTROY);
        close(g_uinput_fd);
        g_uinput_fd = -1;
    }

    return 0;
}
