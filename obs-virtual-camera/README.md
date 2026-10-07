# Fedora OBS Virtual Camera

Troubleshooting and configuring OBS Virtual Camera on Fedora Workstation with Secure Boot enabled.

## Overview

This project documents the process of getting the OBS Virtual Camera working on Fedora Workstation using `v4l2loopback`.

The main challenge was getting the required out-of-tree kernel module to load correctly while keeping Secure Boot enabled.

## Environment

- OS: Fedora Workstation
- Desktop: GNOME
- Application: OBS Studio
- Virtual camera: `v4l2loopback`
- Kernel module management: AKMOD
- Secure Boot: Enabled

## Problem

OBS Studio was installed and configured, but the Virtual Camera could not be used successfully as a webcam device.

The investigation showed that the required `v4l2loopback` kernel module needed to be properly built, signed, and loaded.

## Solution

The solution involved:

1. Installing the required `v4l2loopback` packages.
2. Configuring Fedora's AKMOD system.
3. Creating and enrolling a Machine Owner Key (MOK).
4. Rebuilding the kernel module.
5. Verifying the module signature.
6. Loading `v4l2loopback`.
7. Testing the virtual camera through OBS and other applications.

## Installation

Install the required packages:

```bash
sudo dnf install v4l2loopback kmod-v4l2loopback v4l-utils
```

## Kernel Module

After configuring the AKMOD signing process and enrolling the MOK certificate, rebuild the module for the current kernel:

```bash
sudo akmods --force --rebuild --kernels $(uname -r)
```

Verify the module:

```bash
modinfo v4l2loopback | grep -E 'filename|signer'
```

A successful configuration should show a valid module signer.

## Loading the Virtual Camera

Load the module:

```bash
sudo modprobe v4l2loopback \
  devices=1 \
  max_buffers=2 \
  exclusive_caps=1 \
  card_label="OBS Virtual Camera"
```

Verify that it is loaded:

```bash
lsmod | grep v4l2loopback
```

## Result

The OBS Virtual Camera was successfully detected and usable while Secure Boot remained enabled.

This demonstrated the complete process of troubleshooting an out-of-tree Linux kernel module, configuring module signing, and deploying a virtual video device.

## Skills Demonstrated

- Linux troubleshooting
- Fedora system administration
- Kernel module troubleshooting
- AKMOD
- Secure Boot
- MOK/module signing
- `v4l2loopback`
- OBS Studio
- Command-line troubleshooting
- Technical documentation

## Lessons Learned

This project reinforced the importance of understanding how Linux handles third-party kernel modules under Secure Boot.

The issue was not simply an OBS configuration problem. The underlying dependency was the kernel-level virtual video device provided by `v4l2loopback`, which required additional attention to module building and signing.

## Status

**Working**

OBS Virtual Camera successfully operates on Fedora Workstation with Secure Boot enabled.
