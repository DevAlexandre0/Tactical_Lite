# Tactical Lite 🛡️💣

**Tactical Lite** is a lightweight, standalone resource that adds high-quality **Tactical Leaning (Q/E)** and a **Quick Throw (G)** system to your server.

It is designed to be purely mechanical and performance-friendly (0.00ms idle), focusing solely on movement and utility without interfering with your existing weapon or recoil scripts.

## ✨ Features

### 📐 Tactical Leaning (Q / E)
- **Third Person View (TPV) Optimized:** Camera transitions are smooth and calculated based on camera distance (Lerp).
- **State Synced:** Fully synced with OneSync (uses State Bags).
- **Dynamic Stance:** Supports both standing and crouching lean animations.
- **Collision Check:** Prevents camera clipping through walls when leaning.
- **FPS Safe:** Leaning is automatically disabled in First Person View to prevent visual bugs.

### 💣 Quick Throw (G)
- **Smart Selection:** Automatically picks the "best" throwable in your inventory (Grenade > Molotov > Smoke, etc.).
- **Cooldown System:** Prevents grenade spamming.
- **Visual Feedback:** Plays a specialized throwing animation while keeping the crosshair active.
- **Server-Side Security:** Validates item existence server-side before removing it.

## 📦 Dependencies

- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_inventory](https://github.com/overextended/ox_inventory)

## 🛠️ Installation

1. **Download** the resource and place it in your `resources` folder.
2. **Animation Files:** All required `.ycd` animation files are **already included** in the `stream` folder. No extra downloads required.
3. Add `ensure tactical_lite` to your `server.cfg`.
4. Configure settings in `config.lua` if needed.

## ⚙️ Configuration

You can adjust camera offsets, cooldowns, and priority of throwable items in `config.lua`.

```lua
Config.Lean = {
    TPV = {
        lateralOffsetClose = 0.50, -- How far the camera moves sideways
        cameraRoll = 10.0,         -- Camera tilt angle
        -- ...
    }
}

Config.QuickThrow = {
    Key = 'G',
    Cooldown = 1500,
    Throwables = {
        -- Priority List (Top to Bottom)
        { item = 'WEAPON_GRENADE', hash = `WEAPON_GRENADE`, speed = 35.0 },
        { item = 'WEAPON_MOLOTOV', hash = `WEAPON_MOLOTOV`, speed = 30.0 },
        -- ...
    }
}

```

## 👏 Credits

Special thanks to the creators of the animation assets used in this resource:

* **Leaning Left Animations:** [Rifle Tactical Poses Pack 2](https://www.gta5-mods.com/misc/rifle-tactical-poses-pack-2-sp-fivem-ready-add-on)
* **Leaning Right Animations:** [Rifle Based Tactical Pose Pack](https://www.gta5-mods.com/misc/rifle-based-tactical-pose-pack-fivem-ready)