# How to add miniloaders for other mods

This is a short explanation how the template system works. It is not perfect and there will be corner cases where the code needs to be changed; if you struggle adding your mod, file an issue or a draft PR and I will help as time permits.

All changes should be in the `prototypes/templates.lua` file. The examples below omit the existing elements in the tables for illustration purposes. Do *not* remove any of the other entries, all changes should only add things.

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

* basic - #c3c3c3
* turbo - #b700ff
* ultimate - #1aeb2e

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

* `d[a]-h` is the chute loader, if enabled
* `d[a]-m` is the standard loader
* `d[a]-n` is the fast loader
* `d[a]-o` is the express loader
* `d[a]-p` is the turbo loader, if space age is enabled
* `d[a]-t` is the stack loader, if space age is enabled

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

* `speed` is usually derived from the belt speed. Use the `dash_prefix` parameter to find the transport belt in the `data.raw` table.
* `upgrade_from` is the loader tier from which this loader is an upgrade. This can be a bit tricky when adding loaders to existing tiers.

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

* two loaders of the previous tier, if a previous tier exists
* one underground belt of the current tier
* some additional ingredients representing the inserters. Simplest is two inserters of a tier that supports the current belt speed.

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

* `entity_gfx` selects the actual graphic that represents the miniloader. The default is the light colored miniloader that matches the game belts. An alternative variant, `matt` exists that is dark colored and matches the [Matt's Logistics](https://mods.factorio.com/mod/matts-logistics) belts. If a mod brings very differently colored belts, another set of graphics (`entity/<xxx>-miniloader-structure-base.png`) must be added, otherwise the design of the loader will not match the belts.
* `loader_gfx` selects the explosion and remnants graphics and reuses the underground belt graphics sets. Those must be named *exactly* `<xxx>-underground-belt-explosion` and `<xxx>-underground-belt-remnants`. If they are named differently, they can not be used (I am looking at you, [Krastorio 2](https://mods.factorio.com/mod/Krastorio2)).
* `belt_gfx` selects the graphics used for the belt animation in the loader. As loader tiers are usually created for a specific new belt type, this should rarely need to be set.

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

* `localized_name` - controls the localized name of the mini loader. Rarely needed to change.
* `unit` - defines the [TechnologyUnit](https://lua-api.factorio.com/latest/types/TechnologyUnit.html) to research this miniloader. If undefined and no `research_trigger` is defined, the value of the first prerequisite is used.
* `energy_source` - set the energy source and consumption. This is normally auto-computed based on the loader speed. It can be set here to adjust or use a different energy source (e.g. the chute uses `void` as it does not need electric energy). It should be a function that returns two values, one [EnergySource](https://lua-api.factorio.com/latest/types/BaseEnergySource.html) and an [Energy](https://lua-api.factorio.com/latest/types/Energy.html) value.
* `bulk` - enable [bulk](https://wiki.factorio.com/Bulk_inserter) support for the internal inserters. This affects a number of settings:
  * `wait_for_full_hand` will be `true`, otherwise `false`
  * `grab_less_to_match_belt_stack` will be true, otherwise `false`
  * `stack_size_bonus` will be 4, otherwise 0
  * `max_belt_stack_size` will be 4, otherwise 0
  * the inserter will use 50% more power
* `nerf_mode` - Turn off some inserter features:
  * Filtering is disabled
  * No wires can be conneceted
