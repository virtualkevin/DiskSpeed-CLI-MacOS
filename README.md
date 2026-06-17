# DiskSpeed CLI macOS

> ⚡️ **Native macOS terminal tool to benchmark disk read/write speed — safely, instantly, and without bloat.**

A lightweight, dependency-free script to **measure storage performance** on any Mac — internal SSD, external drive, SD card, or APFS volume.  
Uses only built-in macOS tools (`dd`, `df`, `osascript`) and works out of the box on **macOS 10.10 through Sequoia (15)**.

Perfect for developers, sysadmins, or curious users who want real-world disk speed — **without risking data or installing third-party apps**.

---

## ✨ Features

- 🍏 **macOS-native**: built with Apple’s own command-line ecosystem
- 🖥️ **Interactive GUI mode**: pick a volume using the native Finder dialog
- ⌨️ **CLI mode**: specify `--path` and `--size` for scripting and automation
- 🧼 **Zero footprint**: temporary test file is **auto-deleted**, even on crash
- 🔎 **Optional verification**: use `--verify` to checksum the data read back from disk
- 🔒 **No sudo, no install**: runs safely in user space
- 📊 **Clear results**: shows write & read speeds in **MB/s**
- 💻 Works on **Intel and Apple Silicon** (M1/M2/M3/M4)

---

## ▶️ Quick Start

Make it executable:

```bash
chmod +x diskspeed.sh
```
and run.

If run without arguments, the script will open a Finder dialog to select a disk, and the test file size will be 1 GB.

With arguments, usage is as follows:

```bash
./diskspeed.sh -p "/Volumes/My SSD" -s 512
```
or
```bash
./diskspeed.sh --path /Volumes/MySSD --size 512
```

File size is specified in **megabytes (MB)**.

To verify that the data read back matches the data written, add `--verify`:

```bash
./diskspeed.sh --path /Volumes/MySSD --size 512 --verify
```

Verification uses SHA-256 checksums, so the reported write and read speeds include checksum overhead.
