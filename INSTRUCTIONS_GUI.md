# Graphical environment
Additional instructions on getting a graphical interface working<br>
You should first make sure you have a *functioning* [basic environment](INSTRUCTIONS_BASIC.md) before proceeding

> [!CAUTION]
> ***STUB PAGE***<br>
> The `x11.sh` script has not been implemented and the instructions haven't been tested

## Install
Follow the same steps as the basic install, then...
1. Install the x11-repo (`pkg install x11-repo`)
2. Install the required packages:
```
pkg install termux-x11-nightly pulseaudio virglrenderer-android
```
3. Copy the `android/extra/x11.sh` script to termux's **non-root** *home* directory (`/data/data/com.termux/files/home`)
4. Ensure it's executable (`chmod +x /data/data/com.termux/files/home/x11.sh`)

## Usage 
Follow the same steps as the basic usage (apart from un-mounting, of course), then...
1. Open a separate **non-root** shell
2. Run the script, should be in your home folder:
```
(termux) $ ./x11.sh
```
3. Return to the chroot shell
4. Export the necessary variables:
```
(debian) $ export DISPLAY="127.0.0.1:0"
(debian) $ export PULSE_SERVER="127.0.0.1"
```

If you want hardware acceleration for your X apps, read below

# Hardware acceleration
The `x11.sh` script uses the compatible ANGLE-based virgl server by default<br>
If your device has Vulkan and has sane drivers (it's up to faith), 
you can try swapping it out for regular virgl and ZINK or ANGLE-based with Vulkan

## Renderers
- llvmpipe: software rendering by Mesa (slow, best compatibility) **(default)**
- softpipe: software rendering by Mesa (slowest, legacy)
- virgl (virpipe): remote 3D rendering by Mesa intended for QEMU virtual machines (slow/fast, worst compatibility)
- zink (requires regular virgl): ???

To set which renderer is used by an app, set the `GALLIUM_DRIVER` env variable:
```
# Use llvmpipe software renderer (this is the default)
GALLIUM_DRIVER=llvmpipe glxgears -swapinterval 0 -info

# Use softpipe software renderer (not recommended)
GALLIUM_DRIVER=softpipe glxgears -swapinterval 0 -info

# Use virpipe to offload the rendering to a virgl server (recommended for older games)
GALLIUM_DRIVER=virpipe glxgears -swapinterval 0 -info

# Use zink directly
GALLIUM_DRIVER=zink glxgears -swapinterval 0 -info
```

> [!TIP]
> Make sure to always check the renderer reported when using virgl/virpipe

## Server types
There are multiple virgl servers available on termux:
1. virgl_test_server (regular virgl)
2. virgl_test_server_android (ANGLE-based, termux/android specific)
4. turnip (not virgl, not a server): only for Adreno devices, see below for more information

> [!IMPORTANT]
> If you use the regular virgl server and your device does not support ZINK,<br>
> the virgl server will default to *llvmpipe*, which will be **SLOWER** than not using virgl at all

- virgl using ANGLE: (used by `x11.sh` by default)
```
virgl_test_server_android --angle-gl &
```

- Alternative virgl using ANGLE and Vulkan:
```
virgl_test_server_android --angle-vulkan &
```

> [!WARNING]
> **ANGLE-based** (Vulkan or not) virgl *usually* only has very old OpenGL versions (usually atmost OpenGL 2)<br>
> Newer versions are not guaranteed to be available, and may just crash instantly

- Regular virgl using Vulkan via ZINK:
```
MESA_NO_ERROR=1 MESA_GL_VERSION_OVERRIDE=4.3COMPAT MESA_GLES_VERSION_OVERRIDE=3.2 GALLIUM_DRIVER=zink ZINK_DESCRIPTORS=lazy virgl_test_server --use-egl-surfaceless --use-gles &
```

> [!TIP]
> If you can't use ZINK, it is recommended to just use llvmpipe (software rendering) on the chroot side (not via virgl),
> as it offers the best compatibility, and performance sometimes out performs ANGLE-based virgl

For more information, visit [LinuxDroidMaster's notes](https://github.com/LinuxDroidMaster/Termux-Desktops/blob/main/Documentation/HardwareAcceleration.md#hardware-acceleration-prootandchroot) 