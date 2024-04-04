<h1 align="center"><img src="https://raw.githubusercontent.com/misile00/misilix/main/misilix-logo.png" alt="Misilix logo" width="180" height="180" loading="lazy"></h1>
<p align="center">
Minimal and optimized Linux distribution for Raspberry Pi (toy project)
<p align="center">
• <a href="https://github.com/misile00/misilix/releases" target="_blank" rel="noopener">Downloads</a> •

## Introduction

Misilix is a Linux distribution based on Arch Linux ARM, designed for Raspberry Pi. It aims to be minimalistic, user-friendly, and optimized.

## Installation

To install Misilix, you'll need a Micro SD Card with a minimum capacity of 8GB. Afterward, you'll need to download the image. To write the downloaded image, use the following commands:
```bash
xz --decompress --keep misilix-*.img.xz
dd if=misilix-*.img of=/dev/sda oflag=sync bs=4M status=progress
```
> **Note:** Make sure to replace `misilix-*.img` with the actual name of the Misilix image file you downloaded, and `/dev/sda` with the appropriate destination on your system.

Alternatively, you can use the Raspberry Pi Imager. All you need to do is, in the operating system selection step, choose the "Use custom" option and select the downloaded misilix-*.img.xz file. When using the Raspberry Pi Imager, there's no need to extract the .xz file.

#### Default Users and Passwords:

* *Username*: **root** *Password*: **root**
* *Username*: **alarm** *Password*: **alarm**

## Task List

- [x] Server edition
- [ ] Desktop edition (WIP)
- [ ] Raspberry Pi 3 support (not tested)
- [X] Raspberry Pi 4 support (tested)
- [ ] Raspberry Pi 5 support (not tested)
