# open77_quickhack

Cyberpunk 2077's scanner and quickhack interface for [Open77](https://open2077.net) servers, drawn
on NativeUI and played with the game's own sounds. It is a framework: the resource owns the
experience and the server rules, and your resource decides which quickhacks exist and what they do.

- **What the resource draws:**
  - the scanner vision, the target lock and the DATA / HACKING panel;
  - the `AVAILABLE QUICKHACKS` list and the Cyberdeck RAM bar;
  - the upload bar over the target, and the warning the hacked player sees;
  - result cards ("report cards") that stay on screen after the scanner closes.
- **What your resource decides:** which quickhacks exist, who may use them on what, what they cost,
  and what happens when one lands.

Everything is server-authoritative. The client only asks (`scan`, `execute`). The server checks the
target, bucket, range, RAM, cooldown and your `canUse`, runs the upload timer, then calls your
`onExecute`.

Full documentation: **[open2077.net/docs/quickhack](https://open2077.net/docs/quickhack)**
(also in [docs/guide.md](docs/guide.md)). Complete examples (a netrunner class, device heists,
police scanners, safe zones, NPC missions):
**[open2077.net/docs/quickhack-examples](https://open2077.net/docs/quickhack-examples)**.

## Requirements

- An Open77 server and a 2.5 client with NativeUI.
- Nothing else: the resource has no dependency.

## Install

The resource already ships with every Open77 server package (freeroam template), switched off until
something uses it. Clone this repository only to get a newer copy or to fork it:

```sh
git clone https://github.com/Open2077/open77_quickhack.git resources/open77_quickhack
```

The directory must stay named `open77_quickhack`. Add it to `server.jsonc`:

```jsonc
"resources": { "load": [ /* ... */ "open77_quickhack" ] }
```

The manifest has `auto_start false`. A resource that declares the dependency starts it together
with itself:

```lua
dependency "open77_quickhack"
```

An operator can also `refresh` then `ensure open77_quickhack` in the server console. Nothing changes
on a server that does not use it.

## Quick start

Hooks are **export names in your resource**: closures do not cross resources.

```lua
local qh = exports.open77_quickhack

-- One of the game's quickhacks (name, icon, RAM, upload time, cooldown), with your own rules.
qh:registerPreset("short_circuit", { canUse = "myCanUse", onExecute = "myExecute", range = 35 })

-- A quickhack of your own.
qh:register({
    id = "blackout", label = "Blackout", icon = "system_reset", category = "ultimate",
    ram = 12, upload = 2.5, cooldown = 40, range = 30, targets = { "point" },
    description = "Cuts the power around the device.",
    onExecute = "myExecute",
})

-- A device in the world that can be hacked.
qh:addTarget({
    kind = "point", id = "bank_terminal", position = { x = -1290.4, y = 1980.2, z = 18.1 },
    name = "Bank Terminal", tone = "device", quickhacks = { "blackout" },
})

exports("myCanUse", function(ctx)            -- ctx = { source, target, quickhack, check }
    return true
end)

exports("myExecute", function(ctx)           -- ctx = { source, target = { kind, id, position }, quickhack, uploadId }
    if ctx.quickhack == "short_circuit" and ctx.target.kind == "npc" then
        Open77.npcs.applyDamage(ctx.target.id, 25, ctx.source, "quickhack")
    end
end)
```

Players, every network NPC and every canonical vehicle are targets without any code. Points
(terminals, cameras, door panels) and props are added with `addTarget`.

## Player controls

| Key (rebindable) | Action |
|---|---|
| hold **Tab** | Scanner. Look at a target to lock and scan it. |
| mouse wheel / ↑ ↓ | Move through the quickhack list. |
| **F** | Upload the selected quickhack. |
| **1** / **3** | Previous / next target on screen. |
| **Z** | DATA / HACKING tab. |
| **H** | Help line. |

While the scanner is open, firing, melee, grenades and weapon changes are blocked.

## What is in it

| | |
| --- | --- |
| Definitions | `register`, `registerPreset`, `presets`, `preset` (21 of the game's quickhacks) |
| Targets | `addTarget`, `updateTarget`, `removeTarget`, `setPlayerInfo`, `setAutoTargets` |
| Decks | `setDeck`, `getDeck`, `setRam`, `addRam`, `setLoadout`, `setCooldown`, `setEnabled` |
| Uploads | `uploads`, `cancel`, `report` (result cards) |
| Server events | `open77_quickhack:started`, `open77_quickhack:executed`, `open77_quickhack:cancelled` |
| Client exports | `isScanning`, `getLockedTarget`, `open`, `close`, `selectNext`, `selectPrevious`, `execute`, `nextTarget`, `previousTarget`, `toggleTab`, `setTheme`, `playSound` |
| Client events | `open77_quickhack:scannerOpened`, `open77_quickhack:scannerClosed`, `open77_quickhack:targetLocked` |
| Bundled examples | One **Ping** per target kind (`ping_player`, `ping_npc`, `ping_vehicle`, `ping_device`), off with `examples = false` |

Every field, default and permission is in [docs/guide.md](docs/guide.md).

## Layout

| Path | Content |
|---|---|
| `shared/config.lua` | Defaults: deck, keys, vision, the game's sound events, ranges |
| `shared/presets.lua` | The game's quickhacks (names, costs, timings) for `registerPreset` |
| `server/main.lua` | Authority: registry, targets, decks, scans, uploads, exports |
| `server/examples.lua` | The four Ping quickhacks, as templates |
| `client/main.lua` | Input, target pick and anchors, net, vision, sounds |
| `client/ui.lua` | NativeUI presentation (motion, decode text, code rain) |
| `ui/quickhack.rml`, `ui/quickhack.rcss` | The NativeUI document |
| `ui/icons/*.png` | Built-in icons, drawn by `tools/make_icons.py` (original line art) |
| `tests/` | The server rules without a game: `python tests/run.py` (needs `pip install lupa`, Lua 5.4) |

## License

[MIT](LICENSE). The sound events and the scanner vision are the game's own and are played by the
client; this repository ships none of the game's files.
