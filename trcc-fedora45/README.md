# Thermalright TRCC on Fedora KDE 45

This page documents troubleshooting Thermalright TRCC (TRCC Linux) on **Fedora KDE Plasma 45** after upgrading from Fedora 44.

> **Status: Working.** TRCC is now running on this Fedora KDE system. The exact final step that resolved the installation has not yet been recorded, so it should not be guessed.

## Environment

- Operating system: Fedora KDE Plasma 45
- Kernel recorded during troubleshooting: `7.2.9-300.fc45.x86_64`
- Secure Boot: Enabled
- Upstream project: [Thermalright TRCC Linux Releases](https://github.com/Lexonight1/thermalright-trcc-linux/releases)

## What happened

During the Fedora 44 to Fedora 45 upgrade, the installed package was:

`trcc-linux-9.10.9-1.fc44.noarch`

The RPM required Python 3.14 dependencies, while the Fedora 45 environment used Python 3.15. DNF could not satisfy those requirements, and the package was removed during dependency resolution.

This did not mean TRCC itself could not run on Fedora 45. It meant the existing Fedora 44 RPM's declared dependencies did not match the upgraded system.

## Verify the system

```bash
cat /etc/fedora-release
echo "$XDG_CURRENT_DESKTOP"
uname -r
mokutil --sb-state
rpm -q trcc-linux
command -v trcc
```

## Attempt 1: Install the upstream RPM

The following command was attempted:

```bash
sudo dnf install https://github.com/Lexonight1/thermalright-trcc-linux/releases/latest/download/trcc-linux-latest.noarch.rpm
```

The download succeeded, but dependency resolution failed because the RPM required Python 3.14 dependencies that were unavailable in the Fedora 45 environment.

Do not force-install the incompatible RPM or bypass its dependencies.

## Attempt 2: Install through pipx

The goal was to install TRCC in an isolated Python environment instead of relying on the incompatible Fedora 44 RPM.

### Runtime dependencies

```bash
sudo dnf install pipx sg3_utils python3-pyside6 portaudio ffmpeg
```

### Build dependencies

The first `pipx install trcc-linux` attempt failed while building `hidapi` because libusb development metadata was missing. These packages were then installed:

```bash
sudo dnf install libusb1-devel pkgconf-pkg-config gcc python3-devel
```

A subsequent build attempt reported a missing libudev header:

```text
fatal error: libudev.h: No such file or directory
```

The next troubleshooting step identified was:

```bash
sudo dnf install systemd-devel
```

TRCC is now working, but this page does not claim that the command above alone was the final fix.

## Check the installed CLI

To inspect the commands provided by the installed version:

```bash
trcc --help
```

The following commands were considered during troubleshooting; use them only if supported by the installed CLI:

```bash
trcc system setup
trcc gui
```

## Findings

- Fedora 45 upgrade completed successfully.
- Secure Boot remained enabled.
- The Fedora 44 TRCC RPM was removed because its Python dependency requirements could not be satisfied.
- Installing TRCC through the upstream RPM failed dependency resolution.
- The pipx build initially required libusb development metadata and later reported a missing `libudev.h` header.
- TRCC is now working on Fedora KDE Plasma 45.

## Follow-up

- [ ] Record the exact final commands that resulted in a working installation.
- [ ] Confirm the TRCC GUI detects and communicates with the Thermalright hardware.
- [ ] Update the troubleshooting steps with any additional dependency packages that were required.

## References

- [Thermalright TRCC Linux repository](https://github.com/Lexonight1/thermalright-trcc-linux)
- [Thermalright TRCC Linux releases](https://github.com/Lexonight1/thermalright-trcc-linux/releases)
- [pipx documentation](https://pipx.pypa.io/stable/)

## Notes

This is a record of the Fedora KDE troubleshooting process. The current installation works; the precise final fix should be added after confirming which command or dependency resolved the remaining issue.
