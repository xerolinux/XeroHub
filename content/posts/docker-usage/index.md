---
title: "Docker & Docker-Compose"
date: 2024-06-27
draft: false
description: "How To Use Docker in a Nit-Shell"
tags: ["Docker", "Docker-Compose", "Tools", "Containers", "Linux", "Guide"]
---
### Intro

After messing with [Docker](https://www.docker.com) Containers for so long, I thought I would share the knowledge. Hopefully a video showing it in action soon. In this short tutorial we will be using the Docker Compose feature to deploy our containers. Just note we can do so much more, but this is just an introductory guide, you will have to discover the rest on your own. It's so much fun trust me. To get an idea how much I love them click [**Here**](https://blog.xerolinux.xyz/2024/06/docker-containers-a-love-story/) to read my thoughts...

![[Image: bbD4JDy.png]](https://i.imgur.com/bbD4JDy.png)

So without further delay let's gooooooooo...

### What are Docker containers ?

Docker containers are lightweight, portable units that package an application and its dependencies, ensuring consistent performance across different environments. Unlike virtual machines, containers share the host OS kernel, making them more efficient and faster to start.

### Key Points:

* Isolation: Containers run in isolated environments, using the host system’s resources without interference.
* Portability: Containers can be run anywhere with Docker installed, solving the "it works on my machine" issue.
* Efficiency: They use fewer resources than VMs since they don’t need a full OS for each instance.
* Consistency: Ensures the same environment across development, testing, and production.
* Scalability: Easily scalable with tools like Kubernetes, perfect for microservices.

### How It Works:

1. Dockerfile: Script defining how to build a Docker image.
2. Build: Create an image from the Dockerfile.
3. Run: Start a container from the image.
4. Manage: Use Docker commands to handle the container lifecycle.

Docker containers streamline development, improve resource utilization, and simplify deployment, making them ideal for modern application development.

### Install Docker Package

Before we can deploy our container(s) we will need to install docker and its dependencies then enable the service. To do so type this in terminal (ArchLinux) :

```Bash
sudo pacman -S docker docker-compose
```

Now that we have Docker installed we will need to add ourselves to the Docker group and start the service. Do it like this :

```Bash
sudo usermod -aG docker $USER
sudo systemctl enable --now docker
```

### Docker Compose file (Stack)

Ok, now that everything's set, we can go container hunting... I would highly recommend sites like, [SelfH](https://selfh.st/apps/) or [AwesomeSelfHosted](https://awesome-selfhosted.net). But for the sake of this tutorial, I will be showing you an example docker compose file from one of the services found there. I have selected [FileBrowser](https://demo.filebrowser.org/) (User : demo / Pass : demo)

Here's the docker compose file contents. Just create a folder called "FileBrowser", then inside it a file called "compose.yml" inside it paste the following :

```Yaml
services:
  filebrowser:
    image: hurlenko/filebrowser
    user: "1000:1000"
    ports:
      - 443:8080
    volumes:
      - /<path-to-shared-folder>:/data
      - ./config:/config
    environment:
      - FB_BASEURL=/
    restart: always
```

Just make sure to change the "443" port to one you prefer without touching part to the right which is the internal Docker one. Also in the "Volumes" section change the "- /<path-to-shared-folder>:/data" part, do not modify right side just the left, before the ":", and set it to what you want to share between your machines. DO NOT SHARE ROOT ! At least if you are going to make it public. If you want to keep it internal like me, do it if you so wish it's up to you.

Now save the file, and open Terminal inside the folder and run the following command to start it as a Daemon :

```Bash
docker compose up -d
```

If all was done correctly, you will now be able to access your newly created container via following URLs :

```Bash
http://localhost:443 (Same machine container is on)
http://<server-ip>:443 (From other machines on same network)
```

### Updating Docker Images

Deploying them images (containers) is nice and all, but now we need to maintain them, as in make sure they are up-to-date. In order to do so, we need to navigate to their respective folders, open terminal there, and run the following commands (FileBrowser) :

```Bash
docker compose down (Stop Container)
docker compose pull (Pull in latest version)
docker compose up -d (Start it up again)
```

Note :

>Keep in mind that some containers might require us to delete them before grabbing new version. Make sure to read their instructions on that before going forward. I just used what works for our example. Not all Containers function the same way...

### Other tools...

Kindly note that there are other tools we could use to make deployment much simpler. I just haven't used them in this guide so you can see how it all works. Tools that can be used are, [Portainer](https://www.portainer.io) and [Dockge](https://dockge.kuma.pet), among many others...

### Nginx Proxy & More...

So far what we have done here, is deploy container for local access. If you want to access it outside your Network, well, for this you will have to own your own Domain name, set up Nginx Proxy manager, use Cloudflare and so on. But that's for another day. This guide was to get your appetite wet, lol..

I hope you enjoy, and will see you in the next part.
