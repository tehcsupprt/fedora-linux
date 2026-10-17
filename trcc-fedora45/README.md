# Thermalright TRCC on Fedora 45

This document records troubleshooting steps for Thermalright TRCC (TRCC Linux) after upgrading Fedora Workstation from Fedora 44 to Fedora 45.

> **Status: Work in progress.** The original Fedora 44 RPM failed dependency resolution. Installing TRCC through `pipx` has also encountered build dependency errors. A working installation has not yet been confirmed.

## Environment

- Operating system: Fedora Workstation 45
- Kernel: `7.2.9-300.fc45.x86_64`
- Secure Boot: Enabled
- Upstream project: [Thermalright TRCC Linux Releases](https://github.com/Lexonight1/thermalright-trcc-linux/releases)

## 1. What Happened

During the Fedora 44 to Fedora 45 upgrade, the installed package was:

`trcc-linux-9.10.9-1.fc44.noarch`

The RPM required Python 3.14 dependencies, while the Fedora 45 environment used Python 3.15. DNF could not satisfy those requirements, and the package was removed during dependency resolution.

This does not establish that TRCC itself is incompatible with Fedora 45. It means the existing Fedora 44 RPM's declared dependencies did not match the upgraded system.

## 2. Verify the System

Run these commands to check the current environment:

```bash
cat /etc/fedora-release
uname -r
mokutil --sb-state
rpm -q trcc-linux
command -v trcc
```

After the upgrade, Fedora 45 was confirmed, Secure Boot remained enabled, and the original TRCC RPM was no longer installed.

## 3. Attempt 1: Install the Upstream RPM

The following command was attempted:

```bash
sudo dnf install https://github.com/Lexonight1/thermalright-trcc-linux/releases/latest/download/trcc-linux-latest.noarch.rpm
```

The download succeeded, but dependency resolution failed because the RPM required Python 3.14 dependencies that were unavailable in the Fedora 45 environment.

**Do not force-install the incompatible RPM or bypass its dependencies.**

## 4. Attempt 2: Install Through pipx

The goal is to install TRCC in an isolated Python environment rather than relying on the incompatible Fedora 44 RPM.

### 4.1 Install runtime dependencies

The following packages were installed:

```bash
sudo dnf install pipx sg3_utils python3-pyside6 portaudio ffmpeg
```

### 4.2 Install build dependencies

The first `pipx install trcc-linux` attempt failed while building `hidapi` because libusb development metadata was missing.

The following packages were installed:

```bash
sudo dnf install libusb1-devel pkgconf-pkg-config gcc python3-devel
```

A subsequent installation attempt failed while compiling the HIDRAW backend with this error:

```text
fatal error: libudev.h: No such file or directory
```

### 4.3 Next troubleshooting step

Install the Fedora package that provides the libudev development header:

```bash
sudo dnf install systemd-devel
```

Then retry the installation:

```bash
pipx install trcc-linux
```

If the previous attempt left an incomplete environment, inspect the pipx installations:

```bash
pipx list
```

If necessary, remove only the failed TRCC pipx environment and retry:

```bash
pipx uninstall trcc-linux
pipx install trcc-linux
```

Do not uninstall or replace the system Python. Do not use `sudo pip` or bypass system package protections.

## 5. If Installation Succeeds

Only after `pipx install trcc-linux` completes successfully, check the available CLI commands:

```bash
trcc --help
```

If supported by the installed version, try:

```bash
trcc system setup
trcc gui
```

Confirm the commands against the installed CLI help and upstream documentation. These commands have not yet been verified on this Fedora 45 installation.

## 6. Verified Findings

The following observations have been confirmed:

- The Fedora 44 to Fedora 45 upgrade completed.
- Secure Boot remained enabled.
- The original `trcc-linux` RPM was absent after the upgrade.
- The upstream Fedora 44 RPM failed dependency resolution because of its Python 3.14 requirements.
- The first pipx build encountered missing libusb development metadata.
- After installing libusb development files and build tools, the next build attempt reported a missing `libudev.h` header.

## 7. Remaining Tasks

- [ ] Install `systemd-devel`.
- [ ] Retry `pipx install trcc-linux`.
- [ ] Resolve any additional build or runtime dependencies.
- [ ] Confirm that TRCC launches successfully on Fedora 45.
- [ ] Verify that the TRCC GUI detects and communicates with the Thermalright hardware.
- [ ] Update this document with the final working installation procedure.
- [ ] Update the status at the top once the installation and hardware tests succeed.

## 8. References

- [Thermalright TRCC Linux GitHub Repository](https://github.com/Lexonight1/thermalright-trcc-linux)
- [Thermalright TRCC Linux Releases](https://github.com/Lexonight1/thermalright-trcc-linux/releases)
- [pipx Documentation](https://pipx.pypa.io/stable/)

## Notes

This document is a troubleshooting log, not a confirmed end-to-end installation guide. The steps that remain untested are explicitly marked above. Update the documentation only after the relevant commands and hardware behavior have been verified.
