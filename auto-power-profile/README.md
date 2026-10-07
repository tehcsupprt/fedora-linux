# Fedora Automatic AC Power Profile

A small Fedora Linux automation project that automatically switches the system power profile based on whether the laptop is connected to AC power.

When connected to AC power:

```text
AC connected → Performance
```

When running on battery:

```text
Battery → Balanced
```

The project uses Fedora's `tuned-ppd` power-profile integration, the standard `net.hadess.PowerProfiles` D-Bus interface, a Bash script, systemd, and udev.

## Project Goal

The purpose of this project is to automatically select the appropriate power profile without manually changing the profile whenever the laptop is plugged in or unplugged.

This was developed and tested on an MSI Thin 15 running Fedora Workstation 44 with GNOME.

## Environment

- Laptop: MSI Thin 15
- CPU: Intel Core i5-13420H
- GPU: NVIDIA GeForce RTX 2050 Laptop GPU
- RAM: 16 GB DDR4-3200
- OS: Fedora Workstation 44
- Desktop: GNOME
- Hostname: `nova`

## Power Management Stack

The system uses:

- `tuned`
- `tuned-ppd`

The project does **not** use `power-profiles-daemon`.

Fedora exposes the active power profile through the standard:

```text
net.hadess.PowerProfiles
```

D-Bus interface.

The active profile can be checked with:

```bash
busctl get-property \
    net.hadess.PowerProfiles \
    /net/hadess/PowerProfiles \
    net.hadess.PowerProfiles \
    ActiveProfile
```

Example:

```text
s "performance"
```

or:

```text
s "balanced"
```

## How It Works

The system consists of three components.

### 1. Bash Script

The main script is:

```text
/usr/local/bin/auto-power-profile.sh
```

It checks the AC adapter state:

```text
/sys/class/power_supply/ADP1/online
```

If the value is `1`, the laptop is connected to AC power and the script sets the power profile to:

```text
performance
```

If the value is `0`, the laptop is running on battery and the script sets the profile to:

```text
balanced
```

The script changes the profile through the Power Profiles D-Bus API rather than directly manipulating CPU governors.

### 2. systemd Service

The service is:

```text
/etc/systemd/system/auto-power-profile.service
```

Its purpose is to apply the correct power profile when the system starts.

The service runs after `tuned-ppd.service`:

```ini
[Unit]
Description=Automatically switch power profile based on AC power
After=tuned-ppd.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/auto-power-profile.sh
```

Because this is a `oneshot` service, it runs the script and then exits.

This is expected behavior.

### 3. udev Rule

The udev rule is:

```text
/etc/udev/rules.d/99-auto-power-profile.rules
```

It watches for changes to the AC power supply:

```text
SUBSYSTEM=="power_supply", ACTION=="change", ENV{POWER_SUPPLY_NAME}=="ADP1", TAG+="systemd", ENV{SYSTEMD_WANTS}="auto-power-profile.service"
```

When the AC adapter state changes, udev asks systemd to run the service again.

The overall flow is:

```text
                         ┌─────────────────┐
                         │  Laptop starts  │
                         └────────┬────────┘
                                  │
                                  ▼
                       systemd runs service
                                  │
                                  ▼
                       Check ADP1/online
                                  │
                    ┌─────────────┴─────────────┐
                    │                           │
                  AC = 1                     AC = 0
                    │                           │
                    ▼                           ▼
               Performance                  Balanced


                  Charger state changes
                           │
                           ▼
                    udev detects event
                           │
                           ▼
                 systemd starts service
                           │
                           ▼
                 Script checks AC state
                           │
                           ▼
                 Appropriate profile
```

## Installation

### Dependencies

The system requires Fedora's TuneD power-profile integration:

```bash
sudo dnf install tuned tuned-ppd
```

Enable and start `tuned-ppd`:

```bash
sudo systemctl enable --now tuned-ppd.service
```

Verify:

```bash
systemctl status tuned-ppd.service
```

### Install the Script

Copy `auto-power-profile.sh` to:

```text
/usr/local/bin/
```

Then make it executable:

```bash
sudo chmod +x /usr/local/bin/auto-power-profile.sh
```

### Install the systemd Service

Copy:

```text
auto-power-profile.service
```

to:

```text
/etc/systemd/system/
```

Reload systemd:

```bash
sudo systemctl daemon-reload
```

### Install the udev Rule

Copy:

```text
99-auto-power-profile.rules
```

to:

```text
/etc/udev/rules.d/
```

Reload udev:

```bash
sudo udevadm control --reload-rules
```

## Testing

Check the current AC state:

```bash
cat /sys/class/power_supply/ADP1/online
```

Expected values:

```text
1 = AC connected
0 = Running on battery
```

Check the current profile:

```bash
busctl get-property \
    net.hadess.PowerProfiles \
    /net/hadess/PowerProfiles \
    net.hadess.PowerProfiles \
    ActiveProfile
```

Run the service manually:

```bash
sudo systemctl start auto-power-profile.service
```

Check its result:

```bash
systemctl status auto-power-profile.service --no-pager
```

A successful `oneshot` execution will normally finish with:

```text
Active: inactive (dead)
```

along with:

```text
code=exited, status=0/SUCCESS
```

This is expected because the service performs its task and exits.

## Verification

On the development system, the service successfully executed with:

```text
code=exited, status=0/SUCCESS
```

The laptop's current configuration exposes:

```text
AC adapter: ADP1
Battery: BAT1
```

and the active profile can be queried through the Power Profiles D-Bus interface.

## Uninstallation

Stop and disable the service if necessary:

```bash
sudo systemctl disable --now auto-power-profile.service
```

Remove the installed files:

```bash
sudo rm /usr/local/bin/auto-power-profile.sh
sudo rm /etc/systemd/system/auto-power-profile.service
sudo rm /etc/udev/rules.d/99-auto-power-profile.rules
```

Reload systemd and udev:

```bash
sudo systemctl daemon-reload
sudo udevadm control --reload-rules
```

## Limitations

This implementation was developed for and tested on an MSI Thin 15 running Fedora Workstation 44.

The current version assumes the AC adapter is exposed as:

```text
ADP1
```

Linux systems may expose AC adapters using different names.

For broader compatibility, a future version could dynamically discover the active power-supply device instead of relying on `ADP1`.

The project also assumes that Fedora's `tuned-ppd` integration provides the expected Power Profiles D-Bus interface.

## Why Use D-Bus?

The script does not directly manipulate CPU frequency governors or TuneD profiles.

Instead, it uses the system's standard Power Profiles interface:

```text
net.hadess.PowerProfiles
```

This keeps the script at the same abstraction level as the desktop power-profile system.

The result is a simple automation layer:

```text
AC state
   ↓
Bash script
   ↓
Power Profiles D-Bus API
   ↓
tuned-ppd
   ↓
TuneD
   ↓
System performance profile
```

## Skills Demonstrated

- Fedora Linux administration
- Bash scripting
- systemd services
- udev rules
- D-Bus
- TuneD
- `tuned-ppd`
- Linux power management
- Event-driven automation
- Troubleshooting
- Technical documentation

## Lessons Learned

This project demonstrated how several Linux subsystems can work together to automate a simple system-management task.

The important part was not directly changing CPU governors. Instead, the script interacts with Fedora's existing power-profile infrastructure and allows TuneD/tuned-ppd to handle the underlying system configuration.

The project also demonstrated the difference between:

- A script that performs an action once
- A systemd service that executes the script
- A udev rule that reacts to hardware state changes

Together, these components turn a simple Bash script into an automatic event-driven system.

## Status

**Working**

The system automatically selects:

```text
AC power  → Performance
Battery   → Balanced
```

on the development laptop.
