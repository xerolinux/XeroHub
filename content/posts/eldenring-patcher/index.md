---
title: "Elden Ring Patcher"
date: 2024-08-02
draft: false
description: "Unlock the game's true potential"
tags: ["Elden Ring", "Gaming", "Game", "Patcher", "FPS", "Proton", "Linux"]
---
Do you love **Elden Ring** and want to unlock its true potential? Want to get rid of the 60FPS frame cap? Well, do we have the tool for you. Read on my dear adventurer...

### What is this?

**ER-Patcher** is a sophisticated tool crafted to significantly enhance your **Elden Ring** gameplay on Linux through Proton and natively on Windows. It offers a suite of features tailored to improve both performance and visual experience.

### What does it do?

Think of it as your in-game *cheat code*, but for real-life gaming bliss. Here's an in-depth look at what it brings to the table:

- **Custom Frame Rate Limits:** Fine-tune the game's frame rate to achieve the smoothest gameplay possible, ensuring an optimal balance between performance and visual quality.
- **Ultrawide Monitor Support:** Fully utilize your ultrawide monitor, eliminating those pesky black bars and immersing you deeper into the game’s stunning landscapes.
- **Protect Your Runes:** Disable rune loss upon death, providing a more forgiving gameplay experience and allowing you to focus on your adventure without the fear of losing progress.
- **Skip Intro Logos:** Get straight to the action by bypassing the introductory logos, saving time and keeping you engaged in the game.
- **Enhanced Visual Clarity:** Remove visual effects like vignette and chromatic aberration for a cleaner, sharper image, making every detail of the game world more vivid and enjoyable.

### How it works

When you launch the game through **Steam**, **ER-Patcher** creates a temporary patched version of `eldenring.exe`, leaving the original file untouched. If the `--with-eac` flag is not set, the tool modifies the Steam launch command to use the patched executable instead of `start_protected_game.exe`. This ensures the patched version never runs with **Easy Anti-Cheat (EAC)** enabled. After you close the game, the patched executable is automatically removed, maintaining the integrity of the original game files.

### How to use ER-Patcher

The Patcher is super easy to use. There's nothing to worry about here. But before moving on, please read the warning below, it's very important that you do.

{{< alert icon="fire" cardColor="#e63946" iconColor="#1d3557" textColor="#f1faee" >}}
**Use at your own risk!** This tool is based on patching the game executable through hex-edits. However it is done in a safe and non-destructive way, that ensures the patched executable is never run with **EAC** enabled (unless explicity told to do so).
{{< /alert >}}

- **Installation:** Place the er-patcher tool in your Elden Ring game directory.
- **Configuration:** Set the Steam launch options to integrate the patcher seamlessly with the game using the command: `python er-patcher ARGS -- %command%`
- **Launch Game:** Start the game via Steam, and enjoy the enhanced features immediately.

{{< youtube Aj0Mi03Wy8I >}}

**ER-Patcher** transforms your **Elden Ring** experience, making it smoother, more visually stunning, and more accessible, whether you are on Linux or Windows. For detailed instructions and additional configuration options, visit the project **GitHub** page.

{{< github repo="gurrgur/er-patcher" >}}

### Wrapping Up

To clarify, I do not play these types of games, so, though I did not test this myself, as you saw in the included video, my good friend [**@A1RM4X**](https://www.youtube.com/@A1RM4X/videos) did and it seems solid enough.

But after watching many of his streams where he was using this tool, I have noticed that it can be flaky at times, especially when game is transitioning from in-game footage to a cut-scene after killing a Boss, causing game to crash.

That's why I would **Highly** recommend you disable it during a Boss fight, especially a big one, and re-enable it once cut-scene is over and done. That's the only instability I have seen thus far.

Also, beware using this in **Online-Mode**, I wouldn't recommend it fearing the **Ban-Hammer**. So if you do decide to use it while online and get banned, you got only yourself to blame.

That’s it folks, have fun with unlocked gaming...

Cheers !
