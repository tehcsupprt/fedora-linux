# ATK/VXE Web Driver on Fedora Linux

Troubleshooting Linux HIDRAW permissions and WebHID detection for ATK/VXE mouse configuration tools on Fedora Linux.

## Overview

This project documents the investigation and resolution of an ATK/VXE Web Driver detection issue on Fedora Linux.

The mouse functioned normally in Linux, but the browser-based Web Driver reported the device as **"Sleep."**

The investigation initially focused on Linux HIDRAW permissions and eventually identified an additional factor: the mouse was connected through Bluetooth instead of the 2.4 GHz receiver.

## Environment

- OS: Fedora Linux
- Desktop: Fedora KDE
- Laptop: Fedora GNOME
- Browser: Chromium
- Mouse: VXE R1 / VXE R1S
- Configuration software: ATK/VXE Web Driver
- Linux user: `jaydes`

## Problem

The ATK/VXE browser-based Web Driver reported the mouse as:

> Sleep

However, the mouse itself was functioning normally.

Basic mouse input worked correctly, indicating that the Linux HID stack was detecting and communicating with the device.

This suggested that the problem was related to the Web Driver's direct access to the HID device rather than a hardware failure.

## Investigation

### 1. USB Device Identification

The first step was identifying the mouse and receiver using USB Vendor ID (VID) and Product ID (PID).

### Desktop — VXE R1

| Connection | VID:PID | Device |
|---|---|---|
| 2.4 GHz receiver | `373b:1085` | CX Wireless mouse -1k dongle |
| Wired | `373b:1271` | Compx VXE R1 |

### Laptop — VXE R1S

| Connection | VID:PID | Device |
|---|---|---|
| Wired | `373b:124d` | ATK VXE R1 S NK |
| 2.4 GHz receiver | `373b:1216` | ATK NK mouse NANO dongle |

Using VID/PID values is more reliable than identifying devices only by their `/dev/hidrawX` number.

## HIDRAW Investigation

Browser-based configuration tools can use WebHID to communicate directly with HID devices.

Linux exposes HIDRAW interfaces through:

```text
/dev/hidraw*
```

Normal mouse input can continue working even when a browser application does not have the required permissions to access the HIDRAW interface.

This explained why the mouse itself worked while the Web Driver reported the device as unavailable or "Sleep."

### R1S HIDRAW Mapping

The following interfaces were observed after connecting the R1S:

```text
/dev/hidraw0
/dev/hidraw1
/dev/hidraw2
    VXE_R1_S_NK (VID:PID 373b:124d)

 /dev/hidraw3
 /dev/hidraw4
 /dev/hidraw5
    NK_mouse_NANO_dongle (VID:PID 373b:1216)
```

An additional `/dev/hidraw6` interface was also present but did not contain relevant model information.

### Important

`/dev/hidrawX` numbers are dynamic.

They can change when devices are disconnected, reconnected, or when udev events are triggered.

For this reason, the udev rules use **VID/PID matching instead of hard-coded HIDRAW device numbers**.

## Solution

The solution was to create udev rules that automatically grant the logged-in user read/write access to the relevant HIDRAW interfaces.

Fedora already had `setfacl` available. If it is missing:

```bash
sudo dnf install acl
```

### Desktop VXE R1

Create:

```text
/etc/udev/rules.d/99-vxe-mouse.rules
```

Example:

```text
SUBSYSTEM=="hidraw", ATTRS{idVendor}=="373b", ATTRS{idProduct}=="1085", RUN+="/usr/bin/setfacl -m u:YOUR_USERNAME:rw $env{DEVNAME}"
SUBSYSTEM=="hidraw", ATTRS{idVendor}=="373b", ATTRS{idProduct}=="1271", RUN+="/usr/bin/setfacl -m u:YOUR_USERNAME:rw $env{DEVNAME}"
```

### Laptop VXE R1S

Create:

```text
/etc/udev/rules.d/99-vxe-r1s.rules
```

Example:

```text
SUBSYSTEM=="hidraw", ATTRS{idVendor}=="373b", ATTRS{idProduct}=="124d", RUN+="/usr/bin/setfacl -m u:YOUR_USERNAME:rw $env{DEVNAME}"
SUBSYSTEM=="hidraw", ATTRS{idVendor}=="373b", ATTRS{idProduct}=="1216", RUN+="/usr/bin/setfacl -m u:YOUR_USERNAME:rw $env{DEVNAME}"
```

Replace `YOUR_USERNAME` with the actual Linux username.

## Reload udev Rules

After creating the rules:

```bash
sudo udevadm control --reload-rules
sudo udevadm trigger
```

Reconnect the mouse or receiver if necessary.

## Verification

The resulting permissions can be checked using:

```bash
getfacl /dev/hidraw0 /dev/hidraw1 /dev/hidraw2
```

and:

```bash
getfacl /dev/hidraw3 /dev/hidraw4 /dev/hidraw5
```

The relevant interface should contain an entry similar to:

```text
user:YOUR_USERNAME:rw-
```

On the tested R1S system, all six relevant HIDRAW interfaces received the expected ACL entry.

## Final Discovery

During final testing, the R1S appeared to still show **"Sleep"** in the Web Driver.

The actual cause at that point was that the mouse was connected through **Bluetooth**.

After switching to the **2.4 GHz Nano receiver**, the Web Driver detected the R1S correctly.

### Final Result

```text
Fedora USB detection       → OK
HIDRAW permissions         → OK
udev ACL rules             → OK
R1S 2.4 GHz detection      → OK
ATK/VXE Web Driver         → Working
Bluetooth Web Driver       → Not assumed/supported by this investigation
```

The original issue was therefore a combination of:

1. Understanding the WebHID/HIDRAW permission requirements.
2. Configuring persistent device-specific permissions.
3. Using the correct connection method for the Web Driver.

## Why udev + ACL?

A simple workaround such as:

```bash
sudo chmod a+rw /dev/hidrawX
```

is not ideal.

It is temporary and grants access to everyone.

The udev + ACL approach is preferable because it:

- Persists across device reconnects.
- Targets specific VID/PID combinations.
- Grants access only to the intended user.
- Avoids making HIDRAW devices globally writable.
- Works with dynamically assigned `/dev/hidrawX` numbers.

## Skills Demonstrated

- Fedora Linux troubleshooting
- Linux HID/HIDRAW
- udev rules
- POSIX ACLs
- `setfacl`
- USB VID/PID identification
- WebHID troubleshooting
- Browser/device integration
- Root-cause analysis
- Linux permissions
- Technical documentation

## Lessons Learned

A device can function normally through the Linux HID stack while still being inaccessible to a browser-based configuration utility.

When troubleshooting hardware configuration tools on Linux, it is important to distinguish between:

- Kernel-level device functionality
- HIDRAW access
- User permissions
- Browser WebHID access
- Connection method

The investigation also reinforced why persistent device rules should identify hardware using stable attributes such as VID/PID rather than dynamic device paths.

## Status

**Working**

The ATK/VXE Web Driver successfully detected the VXE R1S through the 2.4 GHz Nano receiver after the HIDRAW permissions were configured correctly.
