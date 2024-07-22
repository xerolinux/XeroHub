---
title: "Docmost Notes"
date: 2024-07-22
draft: false
description: "The Ultimate Wiki for Your Inner Nerd"
tags: ["Docmost", "Notes", "Docker", "Wiki", "Self-Hosted", "Linux"]
---
{{< youtube ntCyF2nLWZs >}}

### Discover Docmost

Ever dreamt of a magical realm where creating, collaborating, and sharing knowledge is as smooth as casting a spell? Welcome to Docmost, the open-source documentation software that's like Hogwarts for your inner nerd. Buckle up for a journey through the enchanted features of [**Docmost**](https://docmost.com).

![Docmost](https://i.imgur.com/lkKoQdi.jpeg)

### Real-Time Collaboration: Dance of the Docs

Imagine a symphony of users editing a document at the same time, without stepping on each other's toes. Docmost’s real-time collaboration is like a well-rehearsed dance routine for your documentation. Its rich-text editor is equipped with tables, LaTex for the math wizards, and callouts to highlight those "aha!" moments. It's the perfect stage for a collaborative performance.

### Permissions : The Gatekeeper of Knowledge

For those who like to keep things under control, Docmost's permissions system is your trusty gatekeeper. Decide who gets to view, edit, and manage content like a benevolent ruler of your digital kingdom. Your secrets remain safe, and your wisdom is shared with the chosen few.

### Spaces and Groups: Organized Chaos

In Docmost, you can organize your content into distinct spaces for different teams, projects, or even your cat's elaborate adventures. User groups allow you to grant permissions efficiently, ensuring everyone has just the right amount of access. It’s like herding cats, but more organized.

### Inline Comments and Page History: The Digital Time Machine

Engage in discussions directly on your pages with inline commenting. It’s like having sticky notes on your documents, but way cooler. And if things go awry, the page history feature is your digital time machine, letting you track changes and revert to previous versions with ease. No flux capacitor required.

### Powerful Search and Nested Pages: Psychic Powers Unleashed

Docmost’s search, powered by Postgres full-text search, is so fast you'll feel like a psychic. Finding information is a breeze. Nested pages and drag-and-drop functionality make organizing your content as satisfying as arranging a puzzle. Everything falls into place effortlessly.

### Attachments Galore: Clip, Click, Done

Need to attach images or videos? Just paste them directly into Docmost. With support for both S3 and local storage, your visual aids are always at your fingertips. It's as simple as clip, click, done.

### Quick Installation Guide: Summon Docmost in a Jiffy

Ready to summon Docmost into your digital realm? Follow these steps for a quick and easy installation:

**Prerequisites :**

Before you begin, make sure you have Docker installed on your server. See the [**official Docker installation guide**](https://docs.docker.com/engine/install/) based on your OS.

- **Setup the Docker compose file**

Create a new directory for Docmost and download the Docker compose file with commands below:

```Bash
mkdir docmost
cd docmost
curl -O https://raw.githubusercontent.com/docmost/docmost/main/docker-compose.yml
```

Next, open the docker-compose.yml file. On Linux, you can use vim:

```Bash
vi docker-compose.yml
```

The downloaded `docker-compose.yml` file should contain the template below with default environment variables.

- **Replace the default configs :**

You are to replace the default environment variables in the `docker-compose.yml` file.

The `APP_URL` should be replaced with your chosen domain. E.g. `https://example.com` or `https://docmost.example.com`.

The `APP_SECRET` value must be replaced with a long random secret key. You can generate the secret with `openssl rand -hex 32`. If you leave the default value, the app will fail to start.

Replace `STRONG_DB_PASSWORD` in the `POSTGRES_PASSWORD` environment variable with a secure password.

Update the `DATABASE_URL` default `STRONG_DB_PASSWORD` value with your chosen Postgres password.

To configure Emails or File storage driver, see the [**Configuration**](https://docmost.com/docs/self-hosting/configuration) doc. The default File storage driver is `local storage`. You don't have to do anything unless you wish to use S3 storage.

- **Start the Services :**

Make sure you are inside the docmost directory which contains the `docker-compose.yml` file.

To start the services, run:

```Bash
docker compose up -d
```

Once the services are up and running, verify the installation by opening your web browser and navigating to: `http://localhost:3000` or the domain that points to your server.

If all is set, you should see the Docmost setup page which will enable you set up your workspace and account.

After a successful setup, you will become the workspace owner. You can then invite other users to join your workspace. Congratulations 🎉.

If you encounter any issues, feel free to create an issue or discussion on the **GitHub** repo.

{{< github repo="docmost/docmost" >}}

- **Upgrade :**

To upgrade to the latest Docmost version, run the following commands:

```Bash
docker pull docmost/docmost
docker compose up --force-recreate --build docmost -d
```

For more detailed info visit the >> [**Official Docmost Docs**](https://docmost.com/docs/installation/) Page...

### Embrace the Magic

Docmost is not just a tool; it’s your new best friend for managing wikis, knowledge bases, and documentation. Dive in, collaborate like a pro, and watch your documentation transform into an epic saga. Whether you're a lone wizard or part of a guild, Docmost has the magic to make your documentation dreams come true.

### Wrapping Up

So there you have it, folks! Docmost is your one-stop solution for all things documentation. It's packed with features that make collaboration smooth and efficient, all while keeping your content organized and easily accessible. Whether you're working on a team project or creating a personal knowledge base, Docmost has everything you need to turn your documentation into a well-oiled machine.

Why wait? Dive into the world of Docmost and let your documentation journey begin. With its user-friendly interface and powerful features, you'll wonder how you ever managed without it. Happy documenting!

That’s it folks ..

Cheers !
