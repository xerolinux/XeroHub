---
title: "Zed Rust based IDE"
date: 2024-07-11
draft: false
description: "GPU Accelerated IDE"
tags: ["Zed", "IDE", "Dev", "Developers", "Atom", "Linux"]
---

{{< youtube JGz7Ou0Nwo8 >}}

A quick one for today. I stumbled upon this new IDE called **ZED**, and I thought I'd share it with y'all.

The *Linux* version has been in development for a while, they just announced its availablability via their >> [**Linux when? Linux now**](https://zed.dev/blog/zed-on-linux) post...

### Some Information

[**Zed**](https://zed.dev) is a high-performance, open-source code editor built using the Rust programming language. Here are the key points about Zed:

- **Built with Rust:** Zed is written entirely in **Rust**, a systems programming language known for its speed, safety, and concurrency features. This allows Zed to offer superior performance compared to many other code editors.
- **Fast and Responsive:** Zed's innovative GPU-based user interface (GPUI) framework allows it to efficiently leverage the GPU to provide an incredibly fast and responsive coding experience, with instant file loading and smooth UI updates.
- **Collaborative Coding:** Zed supports real-time collaboration, allowing multiple developers to work on the same codebase simultaneously from different locations.
- **Customizable:** Zed provides a range of customization options, including themes, plugins, and adjustable settings, allowing developers to tailor the editor to their specific needs and workflows.
- **Open-Source:** Zed was open-sourced in 2024 and is available under the MIT license, allowing developers to contribute to its development and extend its functionality.
- **Cross-Platform:** Zed is currently available for macOS, with plans for Linux support in the future. Windows support is not yet available.

In summary, Zed is a modern, high-performance code editor built using the Rust programming language, offering developers a fast, collaborative, and customizable coding experience. Its open-source nature and focus on performance and productivity make it an exciting new option in the code editor landscape.

### Extension Support

Zed's extension support is a key aspect of its customizability and flexibility as a code editor. While Zed is built on a robust core, its true power lies in the ability to extend its functionality through a vibrant ecosystem of plugins and extensions.

Developers can tap into a growing library of community-contributed extensions that add support for a wide range of programming languages, integrate with popular tools and services, and enhance the overall coding experience. From syntax highlighting and code formatting to advanced debugging and deployment workflows, Zed's extension system allows users to tailor the editor to their specific needs.

![Zed](https://i.imgur.com/r8icrSg.png)

The extension system is designed to be intuitive and easy to use, with a straightforward process for discovering, installing, and managing extensions directly within the Zed interface. This empowers developers to quickly find and implement the tools and features they require, without the need for complex configuration or external setup.

As Zed continues to gain traction and attract a dedicated user base, the extension ecosystem is expected to flourish, with more and more developers contributing their own custom extensions and integrations. This extensibility is a key factor that sets Zed apart, allowing it to evolve and adapt to the changing needs of modern software development.

### Assistant integrations

Zed's assistant integration is a key feature that allows developers to seamlessly collaborate with AI language models within the code editor. Here are the main points about Zed's assistant capabilities:

- **Conversational Interface:** Zed provides a dedicated assistant editor panel that functions similar to a chat interface. Users can type prompts and queries, and the assistant's responses are displayed in real-time below.
- **Multiple Roles:** The assistant editor supports different message blocks for the "You", "Assistant", and "System" roles, allowing for structured conversations and context management.
- **Customizable Models:** Zed allows users to select the AI model they want to use, including options like OpenAI's GPT models and Anthropic's Claude. Users can also specify custom API endpoints for the models.
- **Code Interaction:** The assistant can interact with code snippets, with users able to easily insert code from the editor into the conversation and have the assistant provide feedback or generate new code.
- **Prompt Library:** Zed includes a prompt library feature that allows users to save and reuse custom prompts to guide the assistant's responses, including a "default prompt" that sets the initial context.
- **Streaming Responses:** Responses from the assistant are streamed in real-time, and users can cancel the stream at any point if the response is not what they were expecting.

Overall, Zed's assistant integration provides a seamless way for developers to leverage the capabilities of large language models directly within their coding workflow, enhancing productivity and collaboration.

### Installing & configuring Zed

It's available on the **Arch Extra Repos**, you can easily install it from there via :

```Bash
sudo pacman -S --needed zed
```

- **Configure Zed**

Use `⌘ + ,` to open your custom settings to set things like fonts, formatting settings, per-language settings, and more. You can access the default configuration using the `Zed > Settings > Open Default Settings` menu item. See Configuring Zed for all available settings.

- **Set up your key bindings**

You can access the default key binding set using the `Zed > Settings > Open Default Key Bindings` menu item. Use `⌘ + K`, `⌘ + S` to open your custom keymap to add your key bindings. See [**Key Bindings**](https://zed.dev/docs/key-bindings.html) for more info.

To all you `Vim` users out there visit the => [**Vim Docs**](https://zed.dev/docs/vim.html).

⌘ => Super Key

### What I think of it

I love this thing. It's slowly replacing my current IDE **Kate**. It's more flexible, cutomizable and most importantly it's got **GPU Acceleration** where Kate doesn't, at least not as well. Oh it's also super lightweight.

While it's not as the video says, a 1:1 **VSCode** replacement, with some lacking features, it's getting there. It's relatively new, so I only see good things in its future, it just needs time to cook.

However, it already includes support for the main plugins I, myself care about, like **Git**, **Docker Compose**, **Toml**, **Yaml**, **Make**, **Java**, **Bash**, **Markdown** among others, with more in the pipeline...This post was written using it BTW...

And if you know me by now I love its theme engine, with the likes of **Dracula**, **Catppuccin**, **Nord**, **Synthwave '84** among others already available to install.. It's one of the main things that attracted me to it lol. Nothing else to say about it except that I highly recommend you give it a try.

It has way more than what I mentioned here, so if you want to know more about it, either go to the >> [**Docs/Wiki**](https://zed.dev/docs/) page, or visit their **Git Repo** below.

{{< github repo="zed-industries/zed" >}}

That’s it folks ..

Cheers !
