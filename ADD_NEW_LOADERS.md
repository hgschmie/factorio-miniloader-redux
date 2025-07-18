# Adding miniloaders for other mods

This is the documentation on how the template system works. It is not perfect and there will be corner cases where the code needs to be changed; if you struggle adding your mod, [file an issue](https://github.com/hgschmie/factorio-miniloader-redux/issues) or a [draft PR](https://github.com/hgschmie/factorio-miniloader-redux/compare) and I will help as time permits.

## How the miniloader works

First, the actual truth: A miniloader is not really a "mini loader" but a collection of inserters disguising as a loader.
The performance of a miniloader is controlled through a few inserter related parameters:

- The rotation speed of an inserter
- The hand size of an inserter

Up until Factorio 2.0.59, the hand size automatically included the researched inserter capacity bonus of the force, which was often substantial. As a result, Miniloaders until release 0.8.0 had a much higher throughput than they were supposed to have, if the force has a large inserter capacity bonus researched.

Using a regular "one item at a time" inserter capacity and two inserters (one for each lane), the throughput of an inserter is controlled by [the rotation speed](https://wiki.factorio.com/Inserters#Rotation_Speed). A full rotation of an inserter (pick up an item, rotate, drop the item) takes an even number of ticks. The smallest supported number is 2 so the fastest that an inserter can move items is 30 items per second.Coincidentally this is also the fastest per-lane belt speed in the official game (Turbo Belts in the SpaceAge expansion).

The Miniloader performance is derived from the belt speed for a given tier. In the base and space age games, [four belt tiers](https://wiki.factorio.com/Transport_belts/Physics#Belt_speeds) exist:

| Belt Tier      | Speed (items/sec) |
|----------------|-------------------|
| Standard       | 15                |
| Fast           | 30                |
| Express        | 45                |
| Turbo          | 60                |

A belt can move eight items (four per lane) at a maximum speed of one tick per tile. So the max throughput of a fully saturated, non-stacked belt is 8 * 60 = 480 items/sec. The actual speed factor of a belt is the speed / 480:

| Belt Tier      | Speed (items/sec) | Belt Speed |
|----------------|-------------------|------------|
| Standard       | 15                | 0.03125    |
| Fast           | 30                | 0.0625     |
| Express        | 45                | 0.09375    |
| Turbo          | 60                | 0.125      |

The belt speed value can be read from the belt prototype in the `data.raw` array, e.g. `data.raw['transport-belt']['fast-transport-belt'].speed` is 0.0625.

The raw throughput of a belt is `belt speed * 480 * stack size`. For the fast belt this is `0.0625 * 480 * 1 = 30`. To keep up with the fully saturated belt, a miniloader must be capable to move 30 items per second across two belt lanes. Using two inserters, they need to move 15 items/sec each:

`number of inserters * hand size * 60 ticks/sec / items/sec = rotation speed in ticks/item`

For the fast belt, this is `2 inserters * hand size 1 * 60 / 30 = 4`. Each inserter in the fast miniloader needs to move an item in 4 ticks to get to 30 items/sec total throughput.

A miniloader can have up to eight inserters in total (four per lane). A miniloader always contains an even number of inserters (2, 4, 6 or 8) and an inserter must use an even number of ticks to move an item.

With a hand size of 1 and 30 items per second per inserter, this limits a miniloader with two inserters to 60 items per second:

`2 inserters * hand size 1 * 60 ticks/sec / 2 ticks/item = 60 items/sec`

The actual rotation speed for an inserter is `1 / ticks/item` and must be between 0 and 0.5. The inserter displays its rotation speed in 360º turns per second. The maximum rotation speed for an inserter is 10,800º/sec: `360º * 60 ticks/sec * 0.5 rotation/tick = 10800º/sec`

| Belt Tier      | Speed (items/sec) | Belt Speed | Ticks (Rotation Speed) |
|----------------|-------------------|------------|------------------------|
| Standard       | 15                | 0.03125    | 8 (0.125, 2700º)       |
| Fast           | 30                | 0.0625     | 4 (0.25, 5400º)        |
| Express        | 45                | 0.09375    | 2.66666 (0.375, 8100º) |
| Turbo          | 60                | 0.125      | 2 (0.5, 10800º)        |

This table shows a problem: For the Express inserter, using a hand size of 1 results in a fraction (2.66), which is not possible. The simplest solution would be to round the number down (nearest even number) to 2. Now the express miniloader and the turbo miniloader would be identical which is not ideal.

The goal is to achieve a throughput of 45 items/sec. This is the same as using the throughput of 15 items/sec but increase the hand size from 1 to 3 (adding a stack bonus of 2):

`2 inserters * hand size 3 * 60 ticks/sec / 45 items/sec = 8 ticks/item`

Every inserter now has eight ticks to move three items to achieve the throughput of 45 items / sec

It would also be possible to increase the number of inserters and keep the hand size at 1:

`6 inserters * hand size 1 * 60 ticks/sec / 45 items/sec = 8 ticks/item`

The miniloader automatically computes inserter count, hand size and ticks per item to achieve a throughput goal. When both increasing the inserter count and increasing the hand size are an option, the code prefers to increase the hand size (within reason) before increasing the inserter count:

| Belt Tier            | Speed (items/sec) | Belt Speed | Inserter Count | Hand Size | Ticks (Rotation Speed) |
|----------------------|-------------------|------------|----------------|-----------|------------------------|
| Chute                | 3.75              | 0.0078125  | 2              | 1         | 32 (0.03125, 675º)     |
| Standard             | 15                | 0.03125    | 2              | 1         | 8 (0.125, 2700º)       |
| Fast                 | 30                | 0.0625     | 2              | 1         | 4 (0.25, 5400º)        |
| Express              | 45                | 0.09375    | 2              | 3         | 8 (0.125, 2700º)       |
| Turbo                | 60                | 0.125      | 2              | 1         | 2 (0.5, 10800º)        |
| Stack                | 60                | 0.125      | 2              | 1 *)      | 2 (0.5, 10800º)        |
| Bob Basic            | 7.5               | 0.015625   | 2              | 1         | 16 (0.0625, 1350º)     |
| Bob Turbo            | 60                | 0.125      | 2              | 1         | 2 (0.5, 10800º)        |
| Bob Ultimate         | 75                | 0.15625    | 2              | 5         | 8 (0.125, 2700º)       |
| Krastorio Advanced   | 60                | 0.125      | 2              | 1         | 2 (0.5, 10800º)        |
| Krastorio Superior   | 90                | 0.1875     | 2              | 3         | 4 (0.25, 5400º)        |
| Matt Ultra Fast      | 90                | 0.1875     | 2              | 3         | 4 (0.25, 5400º)        |
| Matt Extreme Fast    | 180               | 0.375      | 2              | 3         | 2 (0.5, 10800º)        |
| Matt Ultra Express   | 270               | 0.5625     | 2              | 9         | 4 (0.25, 5400º)        |
| Matt Extreme Express | 360               | 0.75       | 2              | 6         | 2 (0.5, 10800º)        |
| Matt Ultimate        | 450               | 0.9375     | 6              | 10        | 8 (0.125, 2700º)       |

*) Stacking loaders are a special case.

For non-stacking belts, the theoretical maximum throughput is 480 items/sec (max belt speed) which can be achieved with two inserters:

`2 inserters * hand size 8 * 60 ticks/sec / 480 items/sec = 2 ticks/item`

With the exception of the Express loader, all standard tiers are using a hand size of 1. For mod specific miniloaders, the hand size and even inserter count may vary wildly; this has some impact on the FPS of the game but it should be minimal.

## Adding new miniloaders

All changes should be made in the `prototypes/templates.lua` file. The examples below omit the existing elements in the tables for illustration purposes. Do *not* remove any of the other entries, all changes should only add things.

Identify the mod you want to support. Add a line to the `supported_mods` table near the top of the file. E.g. to support Bob's logistics, the module is called `boblogistics`. Add a simple moniker:

```lua
local supported_mods = {
    -- here is more stuff in that table
    ['boblogistics'] = 'bob', -- support Bob's Logistics mod
}
```

At the end of the `template.loaders` table, add a note for the mod you support. If a mod adds new belt tiers, they are usually called `<something>-transport-belt`. For Bob, the new tiers are called `bob-basic`, `bob-turbo` and `bob-ultimate` (see [the bob belt prototypes](https://github.com/modded-factorio/bobsmods/blob/main/boblogistics/prototypes/entity/belt.lua) for details). For each tier, add an empty entry:

```lua
---@type table<string, miniloader.LoaderDefinition>
template.loaders = {
    -- here is more stuff in that table

    -- =================================================
    -- == Bob's Logistics
    -- =================================================

    ['bob-basic'] = {},
    ['bob-turbo'] = {},
    ['bob-ultimate'] = {},
}
```

Now identify under which condition these loaders should be visible. As this is an extra mod, there is a check needed to ensure that the mod is loaded. Bob also has a configuration switch. Add a condition check to each of the mods that returns `true` if the loader should be enabled. This can be an inline function or a `check_<xxx>` function:

```lua
local function check_bob()
    return game_mode.bob and (settings.startup['bobmods-logistics-beltoverhaul'].value == true)
end

---@type table<string, miniloader.LoaderDefinition>
template.loaders = {
    ['bob-basic'] = {
        condition = check_bob,
    },
}
```

Each of the belt tiers needs the same check.

There is a bit of boilerplate that every loader needs:

```lua
---@type table<string, miniloader.LoaderDefinition>
template.loaders = {
    ['bob-basic'] = {
        condition = check_bob,
        data = function(dash_prefix)
            return {
                subgroup = 'belt',
                stack_size = 50,
            }
        end,
    },
}
```

The `dash_prefix` parameter of the data function will contain the name of the loader ready to be prepended to any other string. It is usually `tier_name` + `-`.

`subgroup` defines where the loaders show up in the crafting and logistics menus. `stack_size` is the number of loaders in a stack. These rarely need to be changed.

Find the needed tint for the loader. This very much depends on the mod that loaders are added for. I tend to load the belt graphics into Gimp and look at the colors with the pipette tool.

For bob:

- basic - #c3c3c3
- turbo - #b700ff
- ultimate - #1aeb2e

Those don't have to be perfect, "close enough" usually suffices.

```lua
---@type table<string, miniloader.LoaderDefinition>
template.loaders = {
    ['bob-basic'] = {
        condition = check_bob,
        data = function(dash_prefix)
            return {
                subgroup = 'belt',
                stack_size = 50,
                tint = util.color('c3c3c3'),
            }
        end,
    },
}
```

Some more values to define:

`order` defines the order in which the loaders show up in the menus. Ordering uses the usual Factorio rules. The base and space age game loaders have a `d[a]` prefix:

- `d[a]-h` is the chute loader, if enabled
- `d[a]-m` is the standard loader
- `d[a]-n` is the fast loader
- `d[a]-o` is the express loader
- `d[a]-p` is the turbo loader, if space age is enabled
- `d[a]-t` is the stack loader, if space age is enabled

Other mods can slot loaders before and after the standard loaders if needed.

If a mod defines a full set of new loaders (which are usually faster than the standard loaders), they should define their own prefix and order.

Bob defines one tier "below" the standard loader and two above:

```lua
---@type table<string, miniloader.LoaderDefinition>
template.loaders = {
    ['bob-basic'] = {
        condition = check_bob,
        data = function(dash_prefix)
            return {
                order = 'd[a]-l', -- slower than standard, faster than chute
                subgroup = 'belt',
                stack_size = 50,
                tint = util.color('c3c3c3'),
            }
        end,
    },
}
```

- `speed` is usually derived from the belt speed. Use the `dash_prefix` parameter to find the transport belt in the `data.raw` table.
- `upgrade_from` is the loader tier from which this loader is an upgrade. This can be a bit tricky when adding loaders to existing tiers.

```lua
---@type table<string, miniloader.LoaderDefinition>
template.loaders = {
    ['bob-basic'] = {
        condition = check_bob,
        data = function(dash_prefix)
            local previous = 'chute' -- slots in between chute and the standard tier

            return {
                order = 'd[a]-l', -- slower than standard, faster than chute
                subgroup = 'belt',
                stack_size = 50,
                tint = util.color('c3c3c3'),
                speed = data.raw['transport-belt'][dash_prefix .. 'transport-belt'].speed,
                upgrade_from = const:name_from_prefix(previous),
            }
        end,
    },
}
```

Ingredients returns the set of ingredients for the loader. As some mods modify loader recipes, it is possible to define multiple recipes and select them based on the mods enabled.

This is a function so the ingredients can be dynamically computed.

Rule of thumb for defining a recipe is

- two loaders of the previous tier, if a previous tier exists
- one underground belt of the current tier
- some additional ingredients representing the inserters. Simplest is two inserters of a tier that supports the current belt speed.

```lua
---@type table<string, miniloader.LoaderDefinition>
template.loaders = {
    ['bob-basic'] = {
        condition = check_bob,
        data = function(dash_prefix)
            local previous = 'chute' -- slots in between chute and the standard tier

            return {
                order = 'd[a]-l', -- slower than standard, faster than chute
                subgroup = 'belt',
                stack_size = 50,
                tint = util.color('c3c3c3'),
                speed = data.raw['transport-belt'][dash_prefix .. 'transport-belt'].speed,
                upgrade_from = const:name_from_prefix(previous),
                ingredients = function()
                    return select_data {
                        bob = {
                            { type = 'item', name = const:name_from_prefix(previous),  amount = 1 },
                            { type = 'item', name = dash_prefix .. 'underground-belt', amount = 1 },
                            { type = 'item', name = 'bob-steam-inserter',              amount = 2 },
                        },
                    }
                end,
            }
        end,
    },
}
```

Finally the `prerequisites` field defines the technologies that need to be defined to unlock that miniloader.

This should include the previous miniloader and the logistics tier that enables the belt needed. If the other ingredients have different prerequisites, those should be included as well.

If no `technology_trigger` and no `unit` element (see below) is defined, the `prerequisites` field *must* be defined and have at least one entry. The `unit` value of that first entry is used for the miniloader (this is the cost to research the miniloader technology).

```lua
---@type table<string, miniloader.LoaderDefinition>
template.loaders = {
    ['bob-basic'] = {
        condition = check_bob,
        data = function(dash_prefix)
            local previous = 'chute' -- slots in between chute and the standard tier

            return {
                order = 'd[a]-l', -- slower than standard, faster than chute
                subgroup = 'belt',
                stack_size = 50,
                tint = util.color('c3c3c3'),
                speed = data.raw['transport-belt'][dash_prefix .. 'transport-belt'].speed,
                upgrade_from = const:name_from_prefix(previous),
                ingredients = function()
                    return select_data {
                        bob = {
                            { type = 'item', name = const:name_from_prefix(previous),  amount = 1 },
                            { type = 'item', name = dash_prefix .. 'underground-belt', amount = 1 },
                            { type = 'item', name = 'bob-steam-inserter',              amount = 2 },
                        },
                    }
                end,
                prerequisites = function()
                    return select_data {
                        bob = { 'logistics-0', const:name_from_prefix(previous), },
                    }
                end,
            }
        end,
    },
}
```

Three more settings are used to select graphics. All three are optional and if they don't exist, it is assumed that the belt brings the full set of graphics (belt, underground belt, explosion and remnants). This is true for the base game and space age belts but depends wildly on the different mods.

- `entity_gfx` selects the actual graphic that represents the miniloader. The default is the light colored miniloader that matches the game belts. An alternative variant, `matt`, exists that is dark colored and matches the [Matt's Logistics](https://mods.factorio.com/mod/matts-logistics) belts. If a mod brings very differently colored belts, another set of graphics (`entity/<xxx>-miniloader-structure-base.png`) must be added, otherwise the design of the loader will not match the belts.
- `loader_gfx` selects the explosion and remnants graphics and reuses the underground belt graphics sets. Those must be named *exactly* `<xxx>-underground-belt-explosion` and `<xxx>-underground-belt-remnants`. If they are named differently, they can not be used (I am looking at you, [Krastorio 2](https://mods.factorio.com/mod/Krastorio2)).
- `belt_gfx` selects the graphics used for the belt animation in the loader. As loader tiers are usually created for a specific new belt type, this should rarely need to be set.

For Bob, each tier brings a belt and we use the light colored entity. Only set the `loader_gfx`.

```lua
---@type table<string, miniloader.LoaderDefinition>
template.loaders = {
    ['bob-basic'] = {
        condition = check_bob,
        data = function(dash_prefix)
            local previous = 'chute' -- slots in between chute and the standard tier

            return {
                order = 'd[a]-l', -- slower than standard, faster than chute
                subgroup = 'belt',
                stack_size = 50,
                tint = util.color('c3c3c3'),
                speed = data.raw['transport-belt'][dash_prefix .. 'transport-belt'].speed,
                upgrade_from = const:name_from_prefix(previous),
                loader_gfx = '', -- use basic graphics for explosion and remnants
                ingredients = function()
                    return select_data {
                        bob = {
                            { type = 'item', name = const:name_from_prefix(previous),  amount = 1 },
                            { type = 'item', name = dash_prefix .. 'underground-belt', amount = 1 },
                            { type = 'item', name = 'bob-steam-inserter',              amount = 2 },
                        },
                    }
                end,
                prerequisites = function()
                    return select_data {
                        bob = { 'logistics-0', const:name_from_prefix(previous), },
                    }
                end,
            }
        end,
    },
}
```

The basic loader is very early in the game, so it should be triggered by a research trigger. As it is an upgrade to the chute which requires 100 iron gear wheels, add some more.

``` lua
    ['bob-basic'] = {
        condition = check_bob,
        data = function(dash_prefix)
            local previous = 'chute' -- slots in between chute and the standard tier

            return {
                order = 'd[a]-l', -- slower than standard, faster than chute
                subgroup = 'belt',
                stack_size = 50,
                tint = util.color('c3c3c3'),
                speed = data.raw['transport-belt'][dash_prefix .. 'transport-belt'].speed,
                upgrade_from = const:name_from_prefix(previous),
                loader_gfx = '', -- use basic graphics for explosion and remnants
                ingredients = function()
                    return select_data {
                        bob = {
                            { type = 'item', name = const:name_from_prefix(previous),  amount = 1 },
                            { type = 'item', name = dash_prefix .. 'underground-belt', amount = 1 },
                            { type = 'item', name = 'bob-steam-inserter',              amount = 2 },
                        },
                    }
                end,
                prerequisites = function()
                    return select_data {
                        bob = { 'logistics-0', const:name_from_prefix(previous), },
                    }
                end,
                research_trigger = {
                    type = 'craft-item', item = 'iron-gear-wheel', count = 200,
                },
            }
        end,
    },
```

Additional things that can be defined in a loader template:

- `localized_name` - controls the localized name of the mini loader. Rarely needed to change.
- `unit` - defines the [TechnologyUnit](https://lua-api.factorio.com/latest/types/TechnologyUnit.html) to research this miniloader. If undefined and no `research_trigger` is defined, the value of the first prerequisite is used.
- `energy_source` - set the energy source and consumption. This is normally auto-computed based on the loader speed. It can be set here to adjust or use a different energy source (e.g. the chute uses `void` as it does not need electric energy). It should be a function that returns two values, one [EnergySource](https://lua-api.factorio.com/latest/types/BaseEnergySource.html) and an [Energy](https://lua-api.factorio.com/latest/types/Energy.html) value.
- `bulk` - enable [bulk](https://wiki.factorio.com/Bulk_inserter) support for the internal inserters. Bulk support is tuned towards the space age stack inserter and may behave wrong/strange if enabled for other belt speeds. When `bulk` is enabled, some settings are locked:
  - `wait_for_full_hand` is `true`
  - `grab_less_to_match_belt_stack` is `true`
  - `stack_size_bonus` is 4
  - `max_belt_stack_size` is 4
  - the inserter uses 50% more power
- `nerf_mode` - Turn off some inserter features:
  - Filtering is disabled
  - No wires can be conneceted
