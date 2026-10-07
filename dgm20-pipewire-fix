# Fixing MAONO DGM20 USB Microphone Input on Fedora KDE Plasma

## Overview

The MAONO DGM20 USB microphone was detected correctly by Fedora KDE Plasma, but it was not appearing as a microphone input device.

The device appeared under PipeWire audio devices and was exposed as an audio sink/output instead of an audio source/input.

The issue was caused by the active PipeWire/ALSA profile being set to:

    output:analog-stereo

instead of:

    input:analog-stereo

No driver installation or kernel modification was required.

## Environment

- OS: Fedora Workstation
- Desktop: KDE Plasma
- Audio stack: PipeWire + WirePlumber
- Microphone: MAONO DGM20 USB Microphone
- PipeWire: 1.6.9

## Symptoms

Running:

    wpctl status

showed the DGM20 under Sinks:

    Sinks:
        DGM20 USB Microphone Analog Stereo

but it did not appear under Sources.

This meant Fedora was treating the microphone as an audio output device.

Interestingly, the default configured input was already pointing to the DGM20:

    Audio/Source
    alsa_input.usb-Maono_DGM20_USB_Microphone_20230101-00.analog-stereo

So the USB device itself was being detected correctly.

## Confirming the USB Device

Check the PipeWire devices:

    wpctl status

The DGM20 appeared as:

    DGM20 USB Microphone [alsa]

Check the ALSA cards:

    pactl list cards short

The DGM20 appeared as:

    843    alsa_card.usb-Maono_DGM20_USB_Microphone_20230101-00    alsa

This confirmed that the hardware and USB audio driver were functioning.

## Inspecting the Audio Profiles

To inspect the available profiles:

    pactl list cards | grep -A 80 -B 5 'Maono_DGM20'

The important section was:

    Profiles:
        off: Off
        output:analog-stereo: Analog Stereo Output
        output:iec958-stereo: Digital Stereo Output
        input:analog-stereo: Analog Stereo Input
        input:iec958-stereo: Digital Stereo Input
        pro-audio: Pro Audio

    Active Profile: output:analog-stereo

The problem was immediately visible.

The DGM20 supported an input profile, but Fedora had selected the output profile.

## The Fix

Switch the DGM20 to the analog input profile:

    pactl set-card-profile \
    alsa_card.usb-Maono_DGM20_USB_Microphone_20230101-00 \
    input:analog-stereo

Then verify:

    wpctl status

The DGM20 should now appear under Sources:

    Sources:
        EMEET SmartCam C960 Ultra Analog Stereo
    *   DGM20 USB Microphone Analog Stereo

The asterisk indicates that it is the current default input device.

## Why Did This Happen?

The DGM20 is not simply a microphone from the USB audio subsystem's perspective.

It exposes both audio input and audio output capabilities.

Its available profiles included:

    input:analog-stereo
    output:analog-stereo
    pro-audio

Fedora had selected:

    output:analog-stereo

Therefore PipeWire created a sink for the DGM20 instead of a source.

The microphone itself was working correctly. The problem was the selected audio profile.

This made the problem particularly confusing because:

- The USB device was detected.
- ALSA detected the device.
- PipeWire detected the device.
- The device appeared in KDE audio settings.
- The default input configuration pointed to the DGM20.

However, the active profile exposed the device as an output instead of an input.

## Result

After switching to:

    input:analog-stereo

the DGM20 became a proper PipeWire audio source.

The resulting setup was:

    Microphone
    └── MAONO DGM20
        └── PipeWire Source
            └── Default Input

    Speakers
    └── EDIFIER M90
        └── PipeWire Sink
            └── Default Output

## Testing the Microphone

A simple PipeWire recording test can be performed with:

    pw-record /tmp/dgm20-test.wav

Speak into the microphone for several seconds, then press Ctrl+C.

Play the recording:

    pw-play /tmp/dgm20-test.wav

If the recording plays back correctly, the microphone is working through PipeWire.

## Troubleshooting Process

The troubleshooting process was:

1. Verify that the USB device was detected.
2. Check whether PipeWire exposed it as a Source or Sink.
3. Inspect the ALSA/PipeWire card profiles.
4. Check the active profile.
5. Switch to the appropriate input profile.
6. Verify that PipeWire now exposes the microphone as a Source.
7. Test actual audio capture.

## What I Learned

This turned out not to be a driver problem.

The important lesson was:

> A USB microphone can be detected perfectly while still being assigned the wrong audio profile.

Before reinstalling drivers or assuming the hardware is defective, check the active PipeWire/ALSA profile.

## Useful Commands

### Check PipeWire Devices

    wpctl status

### List ALSA Cards

    pactl list cards short

### Inspect the DGM20 Profile

    pactl list cards | grep -A 80 -B 5 'Maono_DGM20'

### Switch to Microphone Input

    pactl set-card-profile \
    alsa_card.usb-Maono_DGM20_USB_Microphone_20230101-00 \
    input:analog-stereo

### Test Microphone Recording

    pw-record /tmp/dgm20-test.wav

### Play the Recording

    pw-play /tmp/dgm20-test.wav

## Conclusion

The MAONO DGM20 worked correctly on Fedora KDE Plasma once the correct PipeWire profile was selected.

No proprietary driver was required, and the Linux kernel did not need to be modified.

The issue was simply:

    Wrong:
    output:analog-stereo

    Correct:
    input:analog-stereo

This was a good example of why Linux hardware troubleshooting should start by checking what the system actually sees before reinstalling drivers or replacing hardware.
