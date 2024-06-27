---
title: "Warehouse Flatpak Toolbox"
date: 2024-06-27
draft: false
description: "Manage Flatpaks with ease"
tags: ["flatpak", "manager", "tools", "flathub", "linux"]
---
### What is it ?

**Warehouse** is a versatile toolbox for managing flatpak user data, viewing flatpak app info, and batch managing installed flatpaks.

**Main Features :**

**- Viewing Flatpak Info:** 📋 Warehouse can display all the information provided by the flatpak list command in a user-friendly graphical window. Each item includes a button for easy copying.

**- Managing User Data:** 🗑️ Flatpaks store user data in a specific system location, often left behind when an app is uninstalled. Warehouse can uninstall an app and delete its data, delete data without uninstalling, or simply show if an app has user data.

**- Batch Actions:** ⚡ Warehouse features a batch mode for swift uninstallations, user data deletions, and app ID copying in bulk.

**- Leftover Data Management:** 📁 Warehouse scans the user data folder to check for installed apps associated with the data. If none are found, it can delete the data or attempt to install a matching flatpak.

**- Manage Remotes:** 📦 Installed and enabled Flatpak remotes can be deleted, and new remotes can be added.

{{< youtube pr_bj_Re5dk >}}

### Installing it

To install it, either do it via your favourite GUI package manager if supported or in terminal via :
```Bash
flatpak install io.github.flattool.Warehouse
```

{{< github repo="flattool/warehouse" >}}
