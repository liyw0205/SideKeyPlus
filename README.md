
# SideKeyPlus 编译与使用说明

SideKeyPlus 通过监听音量键输入事件，实现单击、双击、长按、音量上下同时按等快捷动作，并支持通过 `TorchCtl` 控制手电筒。

本项目包含两个主要组件：

| 文件 | 作用 |
|---|---|
| `skp-keyd.c` | 音量键监听守护进程 |
| `build.sh` | 编译 `skp-keyd` |
| `TorchCtl.java` | 手电筒控制工具 |
| `build_torchctl.sh` | 编译 `TorchCtl` 为 dex jar |

---

## 一、环境要求

### 设备要求

- Android 设备
- 已 Root
- 已安装 Magisk / KernelSU / APatch 等 Root 环境
- 已安装 Termux

### Termux 依赖

在 Termux 中执行：

```sh
pkg update
pkg install clang openjdk-17 curl zip
```

其中：

- `clang`：用于编译 `skp-keyd`
- `openjdk-17`：用于编译 `TorchCtl.java`
- `curl`：用于下载 R8/D8
- `zip`：用于打包 dex jar

---

## 二、目录结构建议

建议将文件放在同一个目录，例如：

```text
SideKeyPlus/
├── skp-keyd.c
├── build.sh
├── TorchCtl.java
├── build_torchctl.sh
├── config.ini
└── run_action.sh
```

进入目录：

```sh
cd /path/to/SideKeyPlus
```

如果你是在 Termux 下载或解压的项目，例如：

```sh
cd ~/SideKeyPlus
```

---

## 三、编译 skp-keyd

`skp-keyd` 是负责监听音量键的守护进程。

### 1. 添加执行权限

```sh
chmod +x build.sh
```

### 2. 编译

```sh
./build.sh
```

编译成功后会生成：

```text
skp-keyd
```

示例输出：

```text
[1/3] check clang
[2/3] fix includes
[3/3] build
build ok:
-rwxr-xr-x ... skp-keyd
```

---

## 四、编译 TorchCtl

`TorchCtl` 用于控制系统手电筒，例如开灯、关灯、切换、亮度等级等。

### 1. 添加执行权限

```sh
chmod +x build_torchctl.sh
```

### 2. 编译

```sh
./build_torchctl.sh
```

首次编译时会自动下载 R8/D8：

```text
r8-8.3.37.jar
```

编译成功后会生成：

```text
torchctl.dex.jar
```

---

## 五、安装到模块目录

项目默认使用的路径为：

```text
/data/adb/SideKeyPlus/
```

你可以手动创建目录：

```sh
su -c 'mkdir -p /data/adb/SideKeyPlus'
su -c 'mkdir -p /data/adb/SideKeyPlus/pid'
```

复制文件：

```sh
su -c 'cp skp-keyd /data/adb/SideKeyPlus/'
su -c 'cp torchctl.dex.jar /data/adb/SideKeyPlus/'
su -c 'chmod 0755 /data/adb/SideKeyPlus/skp-keyd'
su -c 'chmod 0644 /data/adb/SideKeyPlus/torchctl.dex.jar'
```

如果你有 `config.ini` 和 `run_action.sh`，也复制进去：

```sh
su -c 'cp config.ini /data/adb/SideKeyPlus/'
su -c 'cp run_action.sh /data/adb/SideKeyPlus/'
su -c 'chmod 0644 /data/adb/SideKeyPlus/config.ini'
su -c 'chmod 0755 /data/adb/SideKeyPlus/run_action.sh'
```

---

## 六、配置文件说明

配置文件路径固定为：

```text
/data/adb/SideKeyPlus/config.ini
```

示例配置：

```ini
# 是否启用音量键快捷功能
VOLUME_KEY_ENABLE=1

# 是否拦截系统原始音量键
# 1 = 拦截，音量键不会直接调节音量
# 0 = 不拦截，系统仍然可以收到音量键
BLOCK_VOLUME_KEY=1

# 音量上单击动作
ACTION_VOLUME_UP_CLICK_TYPE=1

# 音量上双击动作
ACTION_VOLUME_UP_DOUBLE_TYPE=2

# 音量上长按动作
ACTION_VOLUME_UP_LONG_TYPE=3

# 音量下单击动作
ACTION_VOLUME_DOWN_CLICK_TYPE=4

# 音量下双击动作
ACTION_VOLUME_DOWN_DOUBLE_TYPE=5

# 音量下长按动作
ACTION_VOLUME_DOWN_LONG_TYPE=6

# 音量上下同时按动作
ACTION_VOLUME_BOTH_CLICK_TYPE=7
```

---

## 七、配置项说明

### 总开关

```ini
VOLUME_KEY_ENABLE=1
```

| 值 | 说明 |
|---|---|
| `1` | 启用音量键监听 |
| `0` | 禁用音量键监听 |

---

### 是否拦截音量键

```ini
BLOCK_VOLUME_KEY=1
```

| 值 | 说明 |
|---|---|
| `1` | 拦截系统音量键，防止原始音量键传给系统 |
| `0` | 不拦截，系统仍然可以正常调节音量 |

如果设置为 `1`，程序会使用 `EVIOCGRAB` 抓取输入设备。

---

### 动作类型

以下配置项的值如果为 `0`，表示不执行自定义动作：

```ini
ACTION_VOLUME_UP_CLICK_TYPE=0
ACTION_VOLUME_UP_DOUBLE_TYPE=0
ACTION_VOLUME_UP_LONG_TYPE=0
ACTION_VOLUME_DOWN_CLICK_TYPE=0
ACTION_VOLUME_DOWN_DOUBLE_TYPE=0
ACTION_VOLUME_DOWN_LONG_TYPE=0
ACTION_VOLUME_BOTH_CLICK_TYPE=0
```

只要对应值不为 `0`，`skp-keyd` 就会调用：

```text
/data/adb/modules/SideKeyPlus/run_action.sh
```

并传入对应事件名称。

---

## 八、事件名称

`run_action.sh` 会收到以下参数：

| 操作 | 事件名 |
|---|---|
| 音量上单击 | `VOLUME_UP_CLICK` |
| 音量上双击 | `VOLUME_UP_DOUBLE` |
| 音量上长按 | `VOLUME_UP_LONG` |
| 音量下单击 | `VOLUME_DOWN_CLICK` |
| 音量下双击 | `VOLUME_DOWN_DOUBLE` |
| 音量下长按 | `VOLUME_DOWN_LONG` |
| 音量上下同时按 | `VOLUME_BOTH_CLICK` |

---

## 九、run_action.sh 示例

路径：

```text
/data/adb/modules/SideKeyPlus/run_action.sh
```

示例：

```sh
#!/system/bin/sh

EVENT="$1"

TORCH_JAR="/data/adb/SideKeyPlus/torchctl.dex.jar"
TORCH_CMD="/system/bin/app_process64 -Djava.class.path=$TORCH_JAR /system/bin TorchCtl"

case "$EVENT" in
  VOLUME_UP_CLICK)
    input keyevent KEYCODE_VOLUME_UP
    ;;

  VOLUME_DOWN_CLICK)
    input keyevent KEYCODE_VOLUME_DOWN
    ;;

  VOLUME_UP_DOUBLE)
    su -c "$TORCH_CMD toggle"
    ;;

  VOLUME_DOWN_DOUBLE)
    input keyevent KEYCODE_POWER
    ;;

  VOLUME_UP_LONG)
    su -c "$TORCH_CMD hold"
    ;;

  VOLUME_DOWN_LONG)
    su -c "$TORCH_CMD off"
    ;;

  VOLUME_BOTH_CLICK)
    su -c "$TORCH_CMD toggle"
    ;;

  *)
    ;;
esac
```

添加权限：

```sh
su -c 'chmod 0755 /data/adb/modules/SideKeyPlus/run_action.sh'
```

> 注意：源码中 `RUN_ACTION` 的路径是：
>
> ```c
> #define RUN_ACTION "/data/adb/modules/SideKeyPlus/run_action.sh"
> ```
>
> 如果你的脚本放在 `/data/adb/SideKeyPlus/run_action.sh`，需要修改源码里的路径后重新编译，或者把脚本复制到 `/data/adb/modules/SideKeyPlus/run_action.sh`。

---

## 十、运行 skp-keyd

### 前台运行测试

```sh
su -c '/data/adb/SideKeyPlus/skp-keyd'
```

正常启动后会输出类似：

```text
===== skp-keyd start =====
reload_config: ...
uinput created
selected input device: /dev/input/eventX name=...
```

此时按音量键可以查看日志。

---

### 后台运行

```sh
su -c 'nohup /data/adb/SideKeyPlus/skp-keyd > /data/adb/SideKeyPlus/keyd.log 2>&1 &'
```

查看日志：

```sh
su -c 'tail -f /data/adb/SideKeyPlus/keyd.log'
```

停止进程：

```sh
su -c 'pkill skp-keyd'
```

---

## 十一、开机自启示例

如果你是 Magisk 模块，可以在模块的 `service.sh` 中加入：

```sh
#!/system/bin/sh

MODDIR=${0%/*}

sleep 10

chmod 0755 "$MODDIR/skp-keyd"

nohup "$MODDIR/skp-keyd" > /data/adb/SideKeyPlus/keyd.log 2>&1 &
```

如果 `skp-keyd` 放在：

```text
/data/adb/SideKeyPlus/skp-keyd
```

则可以写：

```sh
#!/system/bin/sh

sleep 10

nohup /data/adb/SideKeyPlus/skp-keyd > /data/adb/SideKeyPlus/keyd.log 2>&1 &
```

---

## 十二、TorchCtl 使用说明

`TorchCtl` 需要通过 `app_process64` 运行。

基础命令格式：

```sh
su -c '/system/bin/app_process64 -Djava.class.path=/data/adb/SideKeyPlus/torchctl.dex.jar /system/bin TorchCtl <命令>'
```

为了方便，可以定义变量：

```sh
TORCH_JAR="/data/adb/SideKeyPlus/torchctl.dex.jar"
TORCH_CMD="/system/bin/app_process64 -Djava.class.path=$TORCH_JAR /system/bin TorchCtl"
```

---

### 查看摄像头和闪光灯信息

```sh
su -c "$TORCH_CMD info"
```

或者：

```sh
su -c "$TORCH_CMD list"
```

输出示例：

```text
sdk=35
cameraCount=4
cameraId=0
  flash=true
  facing=1
  strengthMax=10
  strengthDefault=5
state=off
lastCameraId=0
mode=java_camera_manager_hold_cross_device
```

---

### 打开手电筒

```sh
su -c "$TORCH_CMD on"
```

指定 cameraId：

```sh
su -c "$TORCH_CMD on 0"
```

---

### 关闭手电筒

```sh
su -c "$TORCH_CMD off"
```

指定 cameraId：

```sh
su -c "$TORCH_CMD off 0"
```

---

### 切换手电筒

```sh
su -c "$TORCH_CMD toggle"
```

如果当前记录状态为 `on`，则关闭。

如果当前记录状态为 `off`，则打开。

状态文件路径：

```text
/data/adb/SideKeyPlus/pid/flashlight.state
```

上次使用的 cameraId 文件路径：

```text
/data/adb/SideKeyPlus/pid/flashlight.camera
```

---

### 常驻打开手电筒

```sh
su -c "$TORCH_CMD hold"
```

指定 cameraId：

```sh
su -c "$TORCH_CMD hold 0"
```

`hold` 模式会保持进程不退出，适合部分设备必须保持进程存活才能稳定维持手电筒的情况。

关闭：

```sh
su -c "$TORCH_CMD off"
```

或者杀掉对应进程。

---

### 设置手电筒亮度等级

Android 13+ 部分设备支持手电筒亮度等级。

```sh
su -c "$TORCH_CMD level 5"
```

常驻亮度模式：

```sh
su -c "$TORCH_CMD hold-level 5"
```

如果设备不支持亮度控制，会自动回退到普通打开手电筒。

---

## 十三、TorchCtl 支持命令

```text
TorchCtl info
TorchCtl list
TorchCtl on
TorchCtl on <cameraId>
TorchCtl hold
TorchCtl hold <cameraId>
TorchCtl off
TorchCtl off <cameraId>
TorchCtl toggle
TorchCtl level <n>
TorchCtl hold-level <n>
```

---

## 十四、常见问题

### 1. `clang not found`

执行：

```sh
pkg install clang
```

---

### 2. `javac not found`

执行：

```sh
pkg install openjdk-17
```

---

### 3. `curl not found`

执行：

```sh
pkg install curl
```

---

### 4. `zip not found`

执行：

```sh
pkg install zip
```

---

### 5. `open /dev/uinput failed`

可能原因：

- 当前 Root 环境没有权限访问 `/dev/uinput`
- 内核未启用 uinput
- SELinux 限制

可以先确认设备是否存在：

```sh
su -c 'ls -l /dev/uinput /dev/input/uinput'
```

---

### 6. 按音量键没有反应

检查守护进程是否运行：

```sh
su -c 'ps -A | grep skp-keyd'
```

查看日志：

```sh
su -c 'tail -f /data/adb/SideKeyPlus/keyd.log'
```

确认配置：

```ini
VOLUME_KEY_ENABLE=1
```

如果需要拦截音量键：

```ini
BLOCK_VOLUME_KEY=1
```

---

### 7. 音量键仍然会调节音量

确认：

```ini
BLOCK_VOLUME_KEY=1
```

然后重启 `skp-keyd`：

```sh
su -c 'pkill skp-keyd'
su -c 'nohup /data/adb/SideKeyPlus/skp-keyd > /data/adb/SideKeyPlus/keyd.log 2>&1 &'
```

---

### 8. 手电筒无法打开

先查看摄像头信息：

```sh
su -c '/system/bin/app_process64 -Djava.class.path=/data/adb/SideKeyPlus/torchctl.dex.jar /system/bin TorchCtl info'
```

再尝试指定 cameraId：

```sh
su -c '/system/bin/app_process64 -Djava.class.path=/data/adb/SideKeyPlus/torchctl.dex.jar /system/bin TorchCtl on 0'
```

如果 `0` 不行，可以尝试：

```sh
su -c '/system/bin/app_process64 -Djava.class.path=/data/adb/SideKeyPlus/torchctl.dex.jar /system/bin TorchCtl on 1'
```

---

### 9. `app_process64` 不存在

部分系统可能只有 `app_process`。

可以尝试：

```sh
su -c '/system/bin/app_process -Djava.class.path=/data/adb/SideKeyPlus/torchctl.dex.jar /system/bin TorchCtl info'
```

---

## 十五、推荐测试流程

### 1. 编译

```sh
pkg install clang openjdk-17 curl zip

chmod +x build.sh build_torchctl.sh

./build.sh
./build_torchctl.sh
```

### 2. 安装

```sh
su -c 'mkdir -p /data/adb/SideKeyPlus/pid'
su -c 'cp skp-keyd torchctl.dex.jar /data/adb/SideKeyPlus/'
su -c 'chmod 0755 /data/adb/SideKeyPlus/skp-keyd'
su -c 'chmod 0644 /data/adb/SideKeyPlus/torchctl.dex.jar'
```

### 3. 测试手电筒

```sh
su -c '/system/bin/app_process64 -Djava.class.path=/data/adb/SideKeyPlus/torchctl.dex.jar /system/bin TorchCtl info'

su -c '/system/bin/app_process64 -Djava.class.path=/data/adb/SideKeyPlus/torchctl.dex.jar /system/bin TorchCtl toggle'
```

### 4. 测试按键守护进程

```sh
su -c '/data/adb/SideKeyPlus/skp-keyd'
```

按音量键观察日志。

---

## 十六、卸载 / 清理

停止守护进程：

```sh
su -c 'pkill skp-keyd'
```

删除文件：

```sh
su -c 'rm -rf /data/adb/SideKeyPlus'
```

如果你放在 Magisk 模块目录，还需要删除对应模块目录：

```sh
su -c 'rm -rf /data/adb/modules/SideKeyPlus'
```

然后重启手机。

---

## 十七、注意事项

1. 本工具需要 Root 权限。
2. 不同设备的输入设备名称不同，`skp-keyd` 会自动扫描 `/dev/input/event*`。
3. 如果开启 `BLOCK_VOLUME_KEY=1`，音量键会被程序拦截。
4. 如果没有配置对应动作，程序会尽量透传原始音量键事件。
5. `TorchCtl` 使用 Android 隐藏 API 和 CameraManager，部分 ROM 可能限制较多。
6. 手电筒亮度等级并非所有设备都支持。
7. 修改 `config.ini` 后无需重启，`skp-keyd` 会定时自动重新加载配置。