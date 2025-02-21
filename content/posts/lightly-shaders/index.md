---
title: "LightlyShaders Effects"
date: 2024-06-27
draft: false
description: "Add more blur to Windows"
tags: ["ricing", "kde", "plasma", "themes", "linux"]
---
### What is it ?

I would like to share a neat little "Effect" if you will, called LightlyShaders which is a fork of another project that is a simple KWin/5 effect that simply rounds corners of windows, to do this it uses an opengl shader and is able to round any window, like mpv video for example will have rounded corners.

![[Image: ngDtR0J.jpeg]](https://i.imgur.com/ngDtR0J.jpeg)

{{< alert "warn" >}}
1. This effect is basically a hack!

Due to the changes introduced in Plasma 5.x there is no way to draw original shadows under rounded corners any more. In order to work around that, this fork uses a hack that tries to restore the shadow in the cut out regions based on the data from the closest regions with shadows.

Because of this it may work differently with different themes, corner radiuses or shadow settings. Your mileage may vary.

2. This effect can be resource-hungry!

Thanks to recent changes the performance of this plugin has improved. But depending on your hardware, you still can have performance hit.
{{< /alert >}}

### Where to get it ?

1- Install Dependencies :


```
sudo pacman -S git make cmake gcc gettext extra-cmake-modules qt5-tools qt5-x11extras kcrash kglobalaccel kde-dev-utils kio knotifications kinit kwin
```

2- Git Clone Repo & Build :

```
git clone https://github.com/a-parhom/LightlyShaders
cd LightlyShaders; mkdir qt5build; cd qt5build; cmake ../ -DCMAKE_INSTALL_PREFIX=/usr && make && sudo make install && (kwin_x11 --replace &)
```

3- Enable the Effect :

It's highly recommended to reboot after install. Once that's done head on over to `Settings > Workspace Behavior > Desktop Effects` and Enable it. Press the Gear if you want to increase/decrease radius...

![[Image: HmT5hnm.png]](https://i.imgur.com/HmT5hnm.png)


Note :

> After some updates of Plasma this plugin may need to be recompiled in order to work with changes introduced to KWin.

{{< github repo="a-parhom/LightlyShaders" >}}
