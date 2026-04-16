---
title: "Age Verification"
date: 2026-02-27
draft: false
description: "What we are doing about it"
tags: ["XeroLinux", "Age Verification", "Arch", "ArchLinux", "Linux", "ID", "SystemD"]
image: "/images/updates/ageverification.png"
---

## XeroLinux & The Great Age Attestation Circus

Alright folks, let's talk about the elephant in the room, or more accurately, the birthday cake that nobody asked systemd to bake.

So here's what happened. The systemd project merged a pull request adding a new `birthDate` field to the JSON user records managed by userdb, in response to age verification laws in California, Colorado, and Brazil. In plain English: your Linux system now has a slot where someone can write down your date of birth. Fun!

Now before anyone reaches for the pitchforks, let's be fair about what this actually is. This is age *attestation*, not verification. There are no ID checks, no facial recognition, no third-party verification services. You can enter any value, including January 1st, 1900. There is no proof required, no ID scanning, and no external tracking. It's basically the same honor system every dodgy early-2000s website used when they asked "are you 18?" and you clicked yes without a second thought. We all know how well that worked.

![Image](/images/age_verification.png)

The field was designed so only administrators can set it via the `homectl` utility, and the actual birth date would never be revealed to applications directly. The idea is that a portal acts as a gatekeeper, and apps only get a simple yes/no signal. Technically harmless? Probably. The beginning of a slippery slope? That's the part that has a lot of people, including us, raising an eyebrow.

Because here's the thing. Linux has always been the platform where YOU are in charge. Your machine, your rules. The second we start letting legislation from California, Colorado, or Brazil dictate what fields live in our system's user database, we've started down a road that doesn't have a great track record of stopping at "just one more field." Today it's a birthday. Tomorrow? Who knows.

Other Arch-based distros like Garuda Linux have already drawn a line in the sand, stating they will not implement any age verification measures since their legal jurisdictions have no laws mandating it. We respect that position, and at **XeroLinux HQ**, we're taking the same stance.

## What We're Doing About It

We at **XeroLinux HQ** will be disabling the relevant systemd services that ship with these changes in upcoming releases. You shouldn't have to think about this. It should just be handled, and it will be.

## Already on XeroLinux? Here's How to Opt Out

If you're an existing user and you'd like to take matters into your own hands (as any self-respecting Linux user would), you can disable and mask the relevant services with these two commands:

```bash
sudo systemctl disable --now systemd-userdb-load-credentials.service systemd-userdbd.service systemd-userdbd.socket
sudo systemctl mask systemd-userdb-load-credentials.service systemd-userdbd.service systemd-userdbd.socket
```

That's it. Two commands and your system goes back to minding its own business, the way it always should.

## Wrapping Up

Look, we're not here to demonize the developers involved. The person who submitted the PR is a longtime open-source contributor who faced a genuinely ugly wave of harassment over this, which is absolutely not okay. Disagreeing with a technical decision is one thing. Making someone's life miserable over it is another thing entirely, and we want no part of that energy.

But disagreeing with the decision itself? That we'll do loudly and cheerfully. XeroLinux has always been about giving you a clean, fast, privacy-respecting desktop that gets out of your way. We're not about to let a birthday field change that.

Your machine. Your rules. Always.

**- The XeroLinux HQ Team**

