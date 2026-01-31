# hypr-rotate-monitor

A Bash Script for rotating monitors in Hyprland that can be toggled via a keybind. It detects the focused monitor and cycles through its rotation modes: Landscape, Portrait, Inverted Landscape, and Inverted Portrait.

> AUR package release soon!

## Installation

**1.** `git clone https://github.com/isaiah76/hypr-rotate-monitor.git` **or download** `install.sh`

**2. Make sure the installer script is executable:**

```bash
chmod +x install-hypr-rotate-monitor.sh
```

**3. Run the installer:**

```bash
./install.sh
```

## Usage

**From the terminal:**

```bash
hypr-rotate-monitor
```

**Put as Keybind inside `.config/hypr/hyprland.conf`:**

```bash
bind = SUPER, R, exec, $HOME/.local/bin/hypr-rotate-monitor
```

Now pressing `SUPER + R` will rotate your active monitor.
