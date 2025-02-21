---
title: "Konsave TUI"
date: 2024-06-27
draft: false
description: "Save your Plasma Setup with ease."
tags: ["Themes", "Plasma", "KDE", "tools", "linux"]
---
### Intro

I have recently stumbled upon a handy little tool for us who love customizing KDE but hate the work of switching between rices... It's called Konsave.

{{< youtube c54iZyEXlas >}}

As you can see from above video, tool is very useful. What I love about it is the fact that we can export & share our configs. I have been having so much fun with it, it made my ricing life so much easier now...

### Something to note

Just something the author forgot to mention is that the tool will not save anything from outside the $HOME directory. You can only include directories under *$HOME* to the tool's config file, since anything coming from outside there will require root which isn't supported. What this means, is, that any themes you install from any repo or AUR that are applied system wide `/usr/share/themes` will not be included in your exports, only in local saves.. Just keep that in mind.

![Image](https://user-images.githubusercontent.com/39525869/109611033-a6732c80-7b53-11eb-9ece-ffd9cef49047.gif)

### How to get it ?

It's available on the AUR. Otherwise, below is a link to tool's GitHub.

```Bash
paru -S konsave
```

{{< github repo="Prayag2/konsave" >}}

Have fun and start sharing your configs



