# Miniloader (Redux)

A compact loader that can replace inserters in many situations when loading from/to a belt.

Miniloaders can have different modes:

- _Normal mode_ (which is the default)
  - supports sideloading from/to a belt
  - In Space Age, supports spoilage priority
  - degrades with belts above 240 items/sec(The fastest "official" in-game belts are Space Age Turbo Belts, which move at 60 items/sec)
- _Speed mode_
  - can interact only with entities that are a container or container-like (e.g. cargo wagons or assembly machines)
  - spupports speeds up to 480 items/sec
- _Lane filter mode_
  - only available in Speed Mode
  - has a single filter for each lane, one for the left lane and one for the right lane

- All modes
  - 1x1 compact size
  - Extended UI
  - can be moved with [Even Pickier Dollies](https://mods.factorio.com/mod/even-pickier-dollies)
  - flips through belt directions and orientation when rotating
  - supports Fast replacement, Blueprinting, Copy&Paste, Cloning
  - supports undo/redo for configuration changes
  - supports parameterized blueprints
  - supports migrating 1.1 games from the "old" Miniloaders to Miniloader (Redux) with a startup setting
  - when stacking is available (Space Age), stacking is supported by "Vanilla", Fast and Turbo loaders

There are three tiers in the base game ("Vanilla", Fast and Express) and four when playing Space Age (adds Turbo mode) which match the belt speeds.

A simple "chute" loader is available early in the game (enable in Startup settings). The chute loader only supports normal mode and has no GUI.

![All supported Loader types](https://raw.githubusercontent.com/hgschmie/factorio-miniloader-redux/refs/heads/main/portal/all-belts.gif)
![All supported Stacking Loader types](https://raw.githubusercontent.com/hgschmie/factorio-miniloader-redux/refs/heads/main/portal/all-belts-stacked.gif)
![Lane Filter Mode](https://raw.githubusercontent.com/hgschmie/factorio-miniloader-redux/refs/heads/main/portal/lane-filter.gif)
![Sideloading from/to a belt](https://raw.githubusercontent.com/hgschmie/factorio-miniloader-redux/refs/heads/main/portal/sideloading.gif)
![Extended rotation](https://raw.githubusercontent.com/hgschmie/factorio-miniloader-redux/refs/heads/main/portal/extended_rotation.gif)
![Moving Miniloaders](https://raw.githubusercontent.com/hgschmie/factorio-miniloader-redux/refs/heads/main/portal/picker-dollies.gif)
![Normal Mode GUI](https://raw.githubusercontent.com/hgschmie/factorio-miniloader-redux/refs/heads/main/portal/normal-mode-gui.png)
![Speed Mode GUI](https://raw.githubusercontent.com/hgschmie/factorio-miniloader-redux/refs/heads/main/portal/speed-mode-gui.png)

Miniloader supports some other mods:

- [Matt's Logistics](https://mods.factorio.com/mod/matts-logistics)
- [Krastorio 2](https://mods.factorio.com/mod/Krastorio2)
- [Bob's Logistics](https://mods.factorio.com/mod/boblogistics)
- [Advanced Furnaces 2 SpaceAgeFix](https://mods.factorio.com/mod/Load-Furn-2-SpaceAgeFix)
- [Space Exploration](https://mods.factorio.com/mod/space-exploration)
- [TurboBelt](https://mods.factorio.com/mod/TurboBelt)

The miniloaders are activated if the corresponding module is detected.

Getting the speeds for additional tiers beyond the basic levels (base games and Space Age DLC) is tricky and the game mechanics are stretched when going faster than ~ 120 items/sec. Supporting faster loaders is at best unreliable and might be outright wrong. YMMV.

I am open to support additional tiers from other mods from PRs (see below) but I do not plan to actively add any support for other mods.

## Limitations

- High speed (> 120 items/sec) miniloaders will only achieve maximum throughput when using Speed Mode.
- When sideloading in Normal Mode onto a belt with High speed miniloaders, they may spray items across both lanes of the belt they are loading to.
- Stacking (in Space Age) is only available for some Miniloaders. Stacking for the "Turbo" miniloader is equivalent to the pre-1.0 Stacking miniloader. Existing Stacking Miniloaders are converted to "Turbo" Miniloaders.

### Fixing Collision mask failures

When using Miniloaders with some other mods (most prominent offender seems to be the [Advanced Furnaces 2 SpaceAgeFix](https://mods.factorio.com/mod/Load-Furn-2-SpaceAgeFix) mod), the game fails to load with an error message like this:

``` text
Failed to load mods: entity prototype "... some miniloader entity ending in -l..." (loader-1x1) collision_mask(Modifications: Miniloader (Redux)) must collide with entity prototype "... some entity ... " (loader-1x1) collision_mask(...).
```

This happens when the other mod does not declare collision with the `transport_belt` layer. The default collision mask for loaders includes this and most custom loader should simply use the default.

Starting with version 0.10.2, there is now a startup switch (`Sanitize non-Miniloader loader entities`) that tries to 'fix up' such loaders. It adds the `transport_belt` layer to the collision mask of all configured loaders.

Note that this may break functionality of those other loaders. If that is the case, the mod and Miniloader are not compatible.

If you encounter this error, try enabling this setting first. It has no permanent effect on the game; if it breaks another mod, simply uncheck it again.

To enable this setting, when the game fails to start:

- first disable the _other_ mod that causes the problem. Keep Miniloader enabled
- set the startup setting and restart the game
- re-enable the other mod

### Pre-1.0 Blueprints

Miniloader can read blueprints that were created with pre-1.0 versions of the Miniloader. However, any pre-1.0 Miniloader will not be able to read 1.0 or later Blueprints (and will, in fact, crash the game).

## How you can help

I am not a graphics person. E.g. Matt's Logistics belts have a different tint and I convinced ChatGPT to recolor the existing graphics with a different tint that somewhat matches the belts. But getting better graphics would be greatly appreciated.

See [adding more miniloaders for other mods](https://github.com/hgschmie/factorio-miniloader-redux/blob/main/ADD_NEW_LOADERS.md) for details on how to add loaders for other belt tiers.

## Config options

### Loader Snapping (Runtime, per Map)

Similar to other mods, Loaders can automatically "snap" to entities that are either placed around them or when they are placed next to entities. The snapping algorithm differs from other loaders, though. It only takes entities at the "loader" end into account and tries to be smart (the old Miniloader notoriously "flipped" around if it was placed with the non-loader side next to a belt).

Default value is "on".

### Enable Chute miniloader (Startup)

Enables a simple, "gravity driven" Miniloader that is very slow (1/4 speed of a "Vanilla" Miniloader but still much faster than e.g. a "Vanilla" Inserter). It is available as soon as "Logistics" has been researched and 100 iron gear wheels have been crafted.

The chute loader is very helpful in the base game but may be considered OP compared to regular inserters.

Default value is "off".

### Don't consume power (Startup)

All miniloaders no longer consume any electrical (or other) power. They just work. Because they are not OP enough as-is.

Default value is "off".

### Check Speed Mode (Startup)

All miniloaders are checked whether they interact with a chest or an assembly machine. If yes, enable Speed Mode for that miniloader. This is useful when migrating a game that uses miniloaders before 1.0.

Default value is "off".

### Migrate Factorio 1.1 Miniloaders (Startup)

(This setting has not been tested in a while. If you use it and encounter errors, I am very interested in hearing about them)

This option needs to be enabled before opening a 1.1 saved game in Factorio 2.0. It is _not_ necessary to have the old Miniloader module installed (which is not 2.0 compatible). When opening the game, all existing Miniloaders will be migrated to Miniloader (Redux) and all blueprints in the game library and in players' main inventory, that reference the old miniloaders will be automatically updated as well (The player library can not be updated as it is read-only to mods).

- Miniloader, Filter Miniloader -> Miniloader
- Fast Miniloader, Fast Filter Miniloader -> Fast Miniloader
- Express Miniloader, Express Filter Miniloader -> Express Miniloader

Note that this will not migrate any custom tier loaders (as of now).

Default value is "off".

### Sanitize non-Miniloader loader entities (Startup)

Patch non-Miniloader loader-1x1 entities to collide with the `transport_belt` layer. See the section `Fixing Collision mask failures` above for an explanation. This is a highly experimental and dangerous setting. If you do not encounter any errors with other mods, do not enable.

Default value is "off".

### Support Blueprint Mods (Startup)

This is a workaround for an issue with the Factorio game itself (see https://forums.factorio.com/viewtopic.php?t=133860). It allows Blueprinting mods such as [Blueprint Sandboxes](https://mods.factorio.com/mod/blueprint-sandboxes) or [Blueprint Shotgun](https://mods.factorio.com/mod/blueprint-shotgun)
to upgrade/downgrade Miniloaders. This is a "best effort" working around the issue and a Miniloader may lose part or all of its configuration in the process. This is a highly experimental and dangerous setting. If you encounter any errors with this setting, do not enable.

Default value is "off".

### Debugging Mode (Startup)

Show pickup, dropoff positions for the internal inserters and the area scanned when placing loaders or other entities when loader snapping is enabled. Useful for troubleshooting / but reporting but should not be needed otherwise.

Default value is "off".

## Console commands

### /inspect-miniloaders - Inspect miniloader status

There are a number of spurious bug reports from users where the miniloader module crashes with

```text
Error while running event miniloader-redux::on_built_entity (ID 6)
miniloader-redux/scripts/controller.lua:181: assertion failed!
stack traceback:
[C]: in function 'assert'
miniloader-redux/scripts/controller.lua:181: in function 'create_loader'
```

This should only happen if a miniloader was not cleaned out correctly and some of the internal (invisible) entities have remained. In that case, the `/inspect-miniloaders` command can scan all miniloaders and remove such remnants. When the command completes, it will report:

```text
[Inspect Miniloaders] Invalid entities detected: MiniLoaders: 0 / Internal Loaders: 0 / Internal Inserters: 0.
[Inspect Miniloaders] Invalid entities removed: Entities: 0, MiniLoaders: 0 / Internal Loaders: 0 / Internal Inserters: 0.
```

The first line lists all entities that were discovered but are invalid. Such entities have been marked for deconstruction or are otherwise invalid. This line should normally have all 0 values.

The second line lists the number of inconsistent entities that were removed. A non-zero value here means, that there _might_ be miniloaders removed from the current game. The last three numbers are orphaned internal entities.

If the error above occurs, please run the command when reloading the game.

Please file a bug [on github](https://github.com/hgschmie/factorio-miniloader-redux/issues/) when

- running the command reports all '0' values in the second line (especially the "Internal Loader" value)
- The command reports all '0' values but the crash still occurs.

### /control-miniloader-inserters (on|off)

Turn the internal inserters in all (!) miniloaders on and off. This is only for debugging. When running `/control-miniloader-inserters off`, all miniloaders should cease to move items. If any miniloader still moves items after running this command, please file a bug report. All inserters are reactivate with `/control-miniloader-inserters on`.

### /rebuild-miniloader-inserters

Tear down and rebuild all internal inserters. This is useful for debugging if a template changed and the hand size and/or inserter count for a miniloader change.

### /resync-miniloaders [speed]

Reloads the configuration for all miniloaders. If the `speed` parameter is given, also check whether Speed mode can be enabled.

## Planned features

- There are no additional features planned.

## Known issues

- Power consumption is a mess. There are a number of "hidden" entities which show up in the power graph. Miniloader have the same "peak" power consumption in every mode but may pull different amount. Generally, Speed mode will have a higher base consumption independently of the number of items moved while normal mode will scale with the number of items moved.
- Wire connections are invisible (see [this forum post](https://forums.factorio.com/viewtopic.php?t=134043)).
- The entity info on the right side will show "disabled by script" in Speed Mode.
- The Loader UI will show "Stack Size Override" for stacking.
- Similar to the old Miniloader module, Blueprints do not show the "correct" orientation of the loader due to limitations of the game.
- The rotation speed reported for a miniloader is wildly different based on the hand size and the inserter count.
- Higher speed (> 240 items/sec) loaders behave strange in Speed Mode. To get maximum performance, match the loader and belt speed exactly.

## Credits

- Therax for the original miniloader.
- Kirazy &mdash; for the original graphics; taken from the miniloader mod

## Legal

(C) 2024-2026 Henning Schmiedehausen (hgschmie). Released under the MIT License.
