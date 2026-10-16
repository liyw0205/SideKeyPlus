import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.lang.reflect.Constructor;
import java.lang.reflect.Field;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.List;

public class TorchCtl {
    private static final String STATE_FILE = "/data/adb/SideKeyPlus/pid/flashlight.state";
    private static final String ID_FILE = "/data/adb/SideKeyPlus/pid/flashlight.camera";

    public static void main(String[] args) {
        try {
            exemptHiddenApi();
            prepareLooper();

            if (args.length < 1) {
                usage();
                return;
            }

            String cmd = args[0];

            Object context = getSystemContext();
            if (context == null) {
                fail("context is null", 2);
                return;
            }

            if ("apps".equals(cmd)) {
                printApps(context);
                return;
            }

            Object cameraManager = getCameraManager(context);
            if (cameraManager == null) {
                fail("CameraManager is null", 3);
                return;
            }

            if ("info".equals(cmd) || "list".equals(cmd)) {
                printInfo(cameraManager);
                return;
            }

            if ("on".equals(cmd)) {
                String id;

                if (args.length >= 2) {
                    id = args[1];
                    setTorch(cameraManager, id, true);
                } else {
                    id = setTorchAny(cameraManager, true);
                    if (id == null) {
                        fail("no cameraId accepted torch on", 4);
                        return;
                    }
                }

                writeState("on");
                writeCameraId(id);
                out("ok:on cameraId=" + id);
                return;
            }

            if ("hold".equals(cmd) || "daemon".equals(cmd)) {
                String id;

                if (args.length >= 2) {
                    id = args[1];
                    setTorch(cameraManager, id, true);
                } else {
                    id = setTorchAny(cameraManager, true);
                    if (id == null) {
                        fail("no cameraId accepted torch hold", 4);
                        return;
                    }
                }

                writeState("on");
                writeCameraId(id);
                out("ok:hold cameraId=" + id);

                Runtime.getRuntime().addShutdownHook(new ShutdownHook(cameraManager, id));
                holdForever();
                return;
            }

            if ("off".equals(cmd)) {
                if (args.length >= 2) {
                    String id = args[1];
                    setTorch(cameraManager, id, false);
                    writeState("off");
                    out("ok:off cameraId=" + id);
                } else {
                    int tried = setTorchAllOff(cameraManager);
                    writeState("off");
                    out("ok:off tried=" + tried);
                }

                return;
            }

            if ("toggle".equals(cmd)) {
                if ("on".equals(readState())) {
                    int tried = setTorchAllOff(cameraManager);
                    writeState("off");
                    out("ok:toggle off tried=" + tried);
                } else {
                    String id = setTorchAny(cameraManager, true);
                    if (id == null) {
                        fail("no cameraId accepted torch toggle on", 4);
                        return;
                    }

                    writeState("on");
                    writeCameraId(id);
                    out("ok:toggle on cameraId=" + id);
                }

                return;
            }

            if ("level".equals(cmd)) {
                if (args.length < 2) {
                    fail("missing level", 5);
                    return;
                }

                int level = parseInt(args[1], 1);
                String id = setTorchLevelAny(cameraManager, level);

                if (id == null) {
                    fail("no cameraId accepted torch level", 6);
                    return;
                }

                writeState("on");
                writeCameraId(id);
                out("ok:level " + level + " cameraId=" + id);
                return;
            }

            if ("hold-level".equals(cmd) || "daemon-level".equals(cmd)) {
                if (args.length < 2) {
                    fail("missing level", 5);
                    return;
                }

                int level = parseInt(args[1], 1);
                String id = setTorchLevelAny(cameraManager, level);

                if (id == null) {
                    fail("no cameraId accepted torch hold-level", 6);
                    return;
                }

                writeState("on");
                writeCameraId(id);
                out("ok:hold-level " + level + " cameraId=" + id);

                Runtime.getRuntime().addShutdownHook(new ShutdownHook(cameraManager, id));
                holdForever();
                return;
            }

            usage();
        } catch (Throwable e) {
            e.printStackTrace();
            System.exit(1);
        }
    }

    private static class ShutdownHook extends Thread {
        private final Object cameraManager;
        private final String cameraId;

        ShutdownHook(Object cm, String id) {
            this.cameraManager = cm;
            this.cameraId = id;
        }

        public void run() {
            try {
                setTorch(cameraManager, cameraId, false);
                writeState("off");
            } catch (Throwable ignored) {
            }
        }
    }

    private static void usage() {
        out("usage:");
        out("  TorchCtl info");
        out("  TorchCtl list");
        out("  TorchCtl apps");
        out("  TorchCtl on");
        out("  TorchCtl on <cameraId>");
        out("  TorchCtl hold");
        out("  TorchCtl hold <cameraId>");
        out("  TorchCtl off");
        out("  TorchCtl off <cameraId>");
        out("  TorchCtl toggle");
        out("  TorchCtl level <n>");
        out("  TorchCtl hold-level <n>");
    }

    private static void holdForever() {
        while (true) {
            try {
                Thread.sleep(3600L * 1000L);
            } catch (Throwable ignored) {
            }
        }
    }

    private static void out(String s) {
        System.out.println(s);
    }

    private static void err(String s) {
        System.err.println(s);
    }

    private static void fail(String s, int code) {
        err("failed: " + s);
        System.exit(code);
    }

    private static int parseInt(String s, int def) {
        try {
            return Integer.parseInt(s);
        } catch (Throwable e) {
            return def;
        }
    }

    private static void debugThrowable(String prefix, Throwable e) {
        if (e instanceof InvocationTargetException) {
            Throwable cause = ((InvocationTargetException) e).getCause();
            if (cause != null) {
                err(prefix + ": " + cause);
                return;
            }
        }

        err(prefix + ": " + e);
    }

    private static void exemptHiddenApi() {
        try {
            Class<?> vmRuntimeClass = Class.forName("dalvik.system.VMRuntime");

            Method getRuntime = vmRuntimeClass.getDeclaredMethod("getRuntime");
            getRuntime.setAccessible(true);

            Object runtime = getRuntime.invoke(null);

            Method setHiddenApiExemptions = vmRuntimeClass.getDeclaredMethod(
                    "setHiddenApiExemptions",
                    String[].class
            );

            setHiddenApiExemptions.setAccessible(true);
            setHiddenApiExemptions.invoke(runtime, (Object) new String[]{"L"});
        } catch (Throwable e) {
            debugThrowable("debug: exemptHiddenApi failed", e);
        }
    }

    private static void prepareLooper() {
        try {
            Class<?> looperClass = Class.forName("android.os.Looper");

            Method myLooper = looperClass.getDeclaredMethod("myLooper");
            myLooper.setAccessible(true);

            Object current = myLooper.invoke(null);
            if (current != null) {
                err("debug: Looper already prepared");
                return;
            }

            try {
                Method prepareMainLooper = looperClass.getDeclaredMethod("prepareMainLooper");
                prepareMainLooper.setAccessible(true);
                prepareMainLooper.invoke(null);
                err("debug: Looper.prepareMainLooper ok");
                return;
            } catch (Throwable e) {
                debugThrowable("debug: prepareMainLooper failed", e);
            }

            try {
                Method prepare = looperClass.getDeclaredMethod("prepare");
                prepare.setAccessible(true);
                prepare.invoke(null);
                err("debug: Looper.prepare ok");
            } catch (Throwable e) {
                debugThrowable("debug: Looper.prepare failed", e);
            }
        } catch (Throwable e) {
            debugThrowable("debug: prepareLooper failed", e);
        }
    }

    private static Object getSystemContext() throws Exception {
        exemptHiddenApi();
        prepareLooper();

        Class<?> atClass = Class.forName("android.app.ActivityThread");
        Object activityThread = null;

        try {
            Method currentActivityThread = atClass.getDeclaredMethod("currentActivityThread");
            currentActivityThread.setAccessible(true);
            activityThread = currentActivityThread.invoke(null);

            if (activityThread != null) {
                err("debug: got ActivityThread by currentActivityThread");
            }
        } catch (Throwable e) {
            debugThrowable("debug: currentActivityThread failed", e);
        }

        if (activityThread == null) {
            try {
                Method systemMain = atClass.getDeclaredMethod("systemMain");
                systemMain.setAccessible(true);
                activityThread = systemMain.invoke(null);

                if (activityThread != null) {
                    err("debug: got ActivityThread by systemMain");
                }
            } catch (Throwable e) {
                debugThrowable("debug: systemMain failed", e);
            }
        }

        if (activityThread == null) {
            try {
                Constructor<?> cons = atClass.getDeclaredConstructor();
                cons.setAccessible(true);
                activityThread = cons.newInstance();

                if (activityThread != null) {
                    err("debug: got ActivityThread by constructor");
                }
            } catch (Throwable e) {
                debugThrowable("debug: ActivityThread constructor failed", e);
            }
        }

        if (activityThread == null) {
            err("debug: ActivityThread is null");
            return null;
        }

        try {
            Class<?> contextImplClass = Class.forName("android.app.ContextImpl");

            Method createSystemContext = contextImplClass.getDeclaredMethod(
                    "createSystemContext",
                    atClass
            );

            createSystemContext.setAccessible(true);

            Object ctx = createSystemContext.invoke(null, activityThread);

            if (ctx != null) {
                err("debug: got Context by ContextImpl.createSystemContext");
                return ctx;
            }
        } catch (Throwable e) {
            debugThrowable("debug: createSystemContext failed", e);
        }

        try {
            Method getSystemContext = atClass.getDeclaredMethod("getSystemContext");
            getSystemContext.setAccessible(true);

            Object ctx = getSystemContext.invoke(activityThread);

            if (ctx != null) {
                err("debug: got Context by ActivityThread.getSystemContext");
                return ctx;
            }
        } catch (Throwable e) {
            debugThrowable("debug: getSystemContext failed", e);
        }

        return null;
    }

    private static Object getCameraManager(Object context) throws Exception {
        Method getSystemService = context.getClass().getMethod("getSystemService", String.class);
        return getSystemService.invoke(context, "camera");
    }

    private static void printApps(Object context) {
        try {
            Method getPackageManager = context.getClass().getMethod("getPackageManager");
            Object packageManager = getPackageManager.invoke(context);
            Class<?> appInfoClass = Class.forName("android.content.pm.ApplicationInfo");
            Class<?> packageManagerClass = Class.forName("android.content.pm.PackageManager");
            Method getInstalledApplications = packageManagerClass.getMethod(
                    "getInstalledApplications",
                    int.class
            );
            Method getApplicationLabel = packageManagerClass.getMethod(
                    "getApplicationLabel",
                    appInfoClass
            );
            Method getLaunchIntentForPackage = packageManagerClass.getMethod(
                    "getLaunchIntentForPackage",
                    String.class
            );
            Field packageNameField = appInfoClass.getField("packageName");

            Object result = getInstalledApplications.invoke(packageManager, 0);
            StringBuilder json = new StringBuilder("{\"ok\":true,\"apps\":[");
            boolean first = true;

            if (result instanceof List) {
                for (Object app : (List<?>) result) {
                    if (app == null) continue;

                    try {
                        Object packageValue = packageNameField.get(app);
                        String pkg = packageValue == null ? "" : String.valueOf(packageValue);
                        if (pkg.length() == 0) continue;
                        if (getLaunchIntentForPackage.invoke(packageManager, pkg) == null) continue;

                        Object labelValue = getApplicationLabel.invoke(packageManager, app);
                        String label = labelValue == null ? pkg : String.valueOf(labelValue).trim();
                        if (label.length() == 0) label = pkg;

                        if (!first) json.append(',');
                        first = false;
                        json.append("{\"name\":\"")
                                .append(jsonEscape(label))
                                .append("\",\"package\":\"")
                                .append(jsonEscape(pkg))
                                .append("\"}");
                    } catch (Throwable e) {
                        debugThrowable("debug: app metadata failed", e);
                    }
                }
            }

            json.append("]}");
            out(json.toString());
        } catch (Throwable e) {
            debugThrowable("debug: list apps failed", e);
            out("{\"ok\":false,\"apps\":[]}");
        }
    }

    private static String jsonEscape(String value) {
        StringBuilder out = new StringBuilder();
        for (int i = 0; i < value.length(); i++) {
            char c = value.charAt(i);
            switch (c) {
                case '\\': out.append("\\\\"); break;
                case '"': out.append("\\\""); break;
                case '\n': out.append("\\n"); break;
                case '\r': out.append("\\r"); break;
                case '\t': out.append("\\t"); break;
                default:
                    if (c < 0x20) {
                        out.append(String.format("\\u%04x", (int) c));
                    } else {
                        out.append(c);
                    }
            }
        }
        return out.toString();
    }

    private static String[] getCameraIdList(Object cameraManager) throws Exception {
        Method m = cameraManager.getClass().getMethod("getCameraIdList");
        return (String[]) m.invoke(cameraManager);
    }

    private static Object getCharacteristics(Object cameraManager, String cameraId) throws Exception {
        Method m = cameraManager.getClass().getMethod("getCameraCharacteristics", String.class);
        return m.invoke(cameraManager, cameraId);
    }

    private static Object getKey(String name) throws Exception {
        Class<?> cc = Class.forName("android.hardware.camera2.CameraCharacteristics");
        Field f = cc.getField(name);
        return f.get(null);
    }

    private static Object charGet(Object characteristics, Object key) throws Exception {
        Class<?> keyClass = Class.forName("android.hardware.camera2.CameraCharacteristics$Key");
        Method get = characteristics.getClass().getMethod("get", keyClass);
        return get.invoke(characteristics, key);
    }

    private static Integer getIntField(String className, String name) {
        try {
            Class<?> c = Class.forName(className);
            Field f = c.getField(name);
            Object v = f.get(null);

            if (v instanceof Integer) {
                return (Integer) v;
            }
        } catch (Throwable ignored) {
        }

        return null;
    }

    private static void setTorch(Object cameraManager, String cameraId, boolean enabled) throws Exception {
        Method m = cameraManager.getClass().getMethod("setTorchMode", String.class, boolean.class);

        err("debug: setTorchMode cameraId=" + cameraId + " enabled=" + enabled);

        m.invoke(cameraManager, cameraId, enabled);
    }

    private static void turnOnTorchWithStrengthLevel(Object cameraManager, String cameraId, int level) throws Exception {
        Method m = cameraManager.getClass().getMethod(
                "turnOnTorchWithStrengthLevel",
                String.class,
                int.class
        );

        err("debug: turnOnTorchWithStrengthLevel cameraId=" + cameraId + " level=" + level);

        m.invoke(cameraManager, cameraId, level);
    }

    private static String setTorchAny(Object cameraManager, boolean enabled) throws Exception {
        String last = readCameraId();

        if (last != null && last.length() > 0) {
            try {
                setTorch(cameraManager, last, enabled);
                return last;
            } catch (Throwable e) {
                debugThrowable("debug: cached cameraId failed " + last, e);
            }
        }

        String preferred = findPreferredTorchCamera(cameraManager);
        if (preferred != null && preferred.length() > 0) {
            try {
                setTorch(cameraManager, preferred, enabled);
                return preferred;
            } catch (Throwable e) {
                debugThrowable("debug: preferred cameraId failed " + preferred, e);
            }
        }

        String[] ids = getCameraIdList(cameraManager);

        for (String id : ids) {
            try {
                setTorch(cameraManager, id, enabled);
                return id;
            } catch (Throwable e) {
                debugThrowable("debug: setTorchMode failed cameraId=" + id, e);
            }
        }

        return null;
    }

    private static int setTorchAllOff(Object cameraManager) throws Exception {
        int tried = 0;

        String last = readCameraId();

        if (last != null && last.length() > 0) {
            try {
                tried++;
                setTorch(cameraManager, last, false);
            } catch (Throwable e) {
                debugThrowable("debug: off cached failed cameraId=" + last, e);
            }
        }

        String[] ids = getCameraIdList(cameraManager);

        for (String id : ids) {
            if (last != null && last.equals(id)) {
                continue;
            }

            try {
                tried++;
                setTorch(cameraManager, id, false);
            } catch (Throwable e) {
                debugThrowable("debug: off failed cameraId=" + id, e);
            }
        }

        return tried;
    }

    private static String setTorchLevelAny(Object cameraManager, int level) throws Exception {
        if (level < 1) {
            level = 1;
        }

        String last = readCameraId();

        if (last != null && last.length() > 0) {
            try {
                turnOnTorchWithStrengthLevel(cameraManager, last, level);
                return last;
            } catch (Throwable e) {
                debugThrowable("debug: level cached failed cameraId=" + last, e);
            }
        }

        String preferred = findPreferredTorchCamera(cameraManager);
        if (preferred != null && preferred.length() > 0) {
            try {
                turnOnTorchWithStrengthLevel(cameraManager, preferred, level);
                return preferred;
            } catch (Throwable e) {
                debugThrowable("debug: level preferred failed cameraId=" + preferred, e);
            }
        }

        String[] ids = getCameraIdList(cameraManager);

        for (String id : ids) {
            try {
                turnOnTorchWithStrengthLevel(cameraManager, id, level);
                return id;
            } catch (Throwable e) {
                debugThrowable("debug: level failed cameraId=" + id, e);
            }
        }

        err("debug: level failed for all, fallback to setTorchMode on");
        return setTorchAny(cameraManager, true);
    }

    private static String findPreferredTorchCamera(Object cameraManager) {
        try {
            String[] ids = getCameraIdList(cameraManager);

            Object flashKey = getKey("FLASH_INFO_AVAILABLE");
            Object facingKey = getKey("LENS_FACING");

            Integer backConst = getIntField(
                    "android.hardware.camera2.CameraCharacteristics",
                    "LENS_FACING_BACK"
            );

            String fallback = null;

            for (String id : ids) {
                try {
                    Object c = getCharacteristics(cameraManager, id);

                    Object flashObj = charGet(c, flashKey);
                    Object facingObj = charGet(c, facingKey);

                    boolean flash = false;

                    if (flashObj instanceof Boolean) {
                        flash = (Boolean) flashObj;
                    }

                    if (!flash) {
                        continue;
                    }

                    if (fallback == null) {
                        fallback = id;
                    }

                    if (backConst != null && facingObj instanceof Integer) {
                        int facing = (Integer) facingObj;

                        if (facing == backConst) {
                            err("debug: preferred back torch cameraId=" + id);
                            return id;
                        }
                    }
                } catch (Throwable e) {
                    debugThrowable("debug: characteristics failed cameraId=" + id, e);
                }
            }

            if (fallback != null) {
                err("debug: preferred fallback torch cameraId=" + fallback);
            }

            return fallback;
        } catch (Throwable e) {
            debugThrowable("debug: findPreferredTorchCamera failed", e);
            return null;
        }
    }

    private static void printInfo(Object cameraManager) throws Exception {
        String[] ids = getCameraIdList(cameraManager);

        out("sdk=" + getSdkInt());
        out("cameraCount=" + ids.length);

        for (String id : ids) {
            out("cameraId=" + id);
            printCameraInfoSafe(cameraManager, id);
        }

        out("state=" + readState());
        out("lastCameraId=" + readCameraId());
        out("mode=java_camera_manager_hold_cross_device");
    }

    private static void printCameraInfoSafe(Object cameraManager, String id) {
        try {
            Object c = getCharacteristics(cameraManager, id);

            Object flashKey = getKey("FLASH_INFO_AVAILABLE");
            Object facingKey = getKey("LENS_FACING");

            Object flash = charGet(c, flashKey);
            Object facing = charGet(c, facingKey);

            out("  flash=" + flash);
            out("  facing=" + facing);

            try {
                Object maxKey = getKey("FLASH_INFO_STRENGTH_MAXIMUM_LEVEL");
                Object defKey = getKey("FLASH_INFO_STRENGTH_DEFAULT_LEVEL");

                Object max = charGet(c, maxKey);
                Object def = charGet(c, defKey);

                out("  strengthMax=" + max);
                out("  strengthDefault=" + def);
            } catch (Throwable ignored) {
                out("  strengthControl=false");
            }
        } catch (Throwable e) {
            out("  characteristics=unavailable:" + shortError(e));
        }
    }

    private static String shortError(Throwable e) {
        if (e instanceof InvocationTargetException) {
            Throwable c = ((InvocationTargetException) e).getCause();
            if (c != null) {
                return c.getClass().getSimpleName() + ":" + c.getMessage();
            }
        }

        return e.getClass().getSimpleName() + ":" + e.getMessage();
    }

    private static int getSdkInt() {
        try {
            Class<?> buildVersion = Class.forName("android.os.Build$VERSION");
            Field sdkInt = buildVersion.getField("SDK_INT");
            return sdkInt.getInt(null);
        } catch (Throwable e) {
            return -1;
        }
    }

    private static String readState() {
        String s = readFile(STATE_FILE);

        if ("on".equals(s)) {
            return "on";
        }

        return "off";
    }

    private static void writeState(String s) {
        writeFile(STATE_FILE, s);
    }

    private static String readCameraId() {
        return readFile(ID_FILE);
    }

    private static void writeCameraId(String id) {
        writeFile(ID_FILE, id);
    }

    private static String readFile(String path) {
        try {
            File f = new File(path);

            if (!f.exists()) {
                return "";
            }

            FileInputStream in = new FileInputStream(f);
            byte[] buf = new byte[128];
            int n = in.read(buf);
            in.close();

            if (n <= 0) {
                return "";
            }

            return new String(buf, 0, n).trim();
        } catch (Throwable e) {
            return "";
        }
    }

    private static void writeFile(String path, String s) {
        try {
            File f = new File(path);
            File parent = f.getParentFile();

            if (parent != null) {
                parent.mkdirs();
            }

            FileOutputStream out = new FileOutputStream(f, false);
            out.write(s.getBytes());
            out.write('\n');
            out.close();
        } catch (Throwable ignored) {
        }
    }
}
