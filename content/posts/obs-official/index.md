---
title: "OBS Studio Official Package"
date: 2024-06-27
draft: false
description: "Best way to get OBS-Studio"
tags: ["video", "streaming", "obs", "flatpak", "tools", "linux"]
---
### What is OBS Studio?

**OBS Studio** is a free and open-source, cross-platform screencasting and streaming app. It is available for Windows, macOS, Linux distributions, and BSD. The OBS Project raises funds on Open Collective and Patreon.

{{< figure src="lDWEJbL.jpeg" alt="obs" class="center-image" >}}

### Info

We ship the "Official" Flatpak version of OBS-Studio via our toolkit. The best part of it is, we don't just ship the main package alone, we have included some extra plugins too.. Specifically made for the flatpak version.

{{< figure src="nckiQXt.png" alt="obs" class="center-image" >}}

### Installing it

To install manually, here's how to grab the entire OBS flatpak plugins via terminal, just copy paste below and hit enter then wait for install to be done...

- Flathub (Flatpak)
```Bash
flatpak install -y com.obsproject.Studio com.obsproject.Studio.Plugin.Draw com.obsproject.Studio.Plugin.waveform com.obsproject.Studio.Plugin.WebSocket com.obsproject.Studio.Plugin.TransitionTable com.obsproject.Studio.Plugin.SceneSwitcher com.obsproject.Studio.Plugin.ScaleToSound com.obsproject.Studio.Plugin.OBSVkCapture com.obsproject.Studio.Plugin.OBSLivesplitOne com.obsproject.Studio.Plugin.DistroAV com.obsproject.Studio.Plugin.MoveTransition com.obsproject.Studio.Plugin.Gstreamer com.obsproject.Studio.Plugin.GStreamerVaapi com.obsproject.Studio.Plugin.DroidCam com.obsproject.Studio.Plugin.BackgroundRemoval com.obsproject.Studio.Plugin.AitumMultistream com.obsproject.Studio.Plugin.AdvancedMasks com.obsproject.Studio.Plugin.CompositeBlur com.obsproject.Studio.Plugin.SourceClone com.obsproject.Studio.Plugin.DownstreamKeyer com.obsproject.Studio.Plugin.Shaderfilter com.obsproject.Studio.Plugin.FreezeFilter com.obsproject.Studio.Plugin.SourceRecord com.obsproject.Studio.Plugin._3DEffect org.freedesktop.LinuxAudio.Plugins.x42Plugins
```

{{< github repo="obsproject/obs-studio" >}}

Have fun :heart:
