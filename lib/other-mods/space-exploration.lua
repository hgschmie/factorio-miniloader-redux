local const = require('lib.constants')

local SpaceExplorationSupport = {}

-- Support for space surface in Space Exploration. Only space and deep space miniloaders can be placed in space.
--
-- This is a hacky solution but it's the best I've got. 
-- SE provides the `se_allow_in_space` property in a prototype that allows 
-- entities (that would otherwise normally be blocked) to be placed in space.
-- However miniloaders aren't blocked from being placed in space since they are
-- actually inserters in disguise.

SpaceExplorationSupport.data_updates = function()
    for _, prototype in pairs(data.raw['inserter']) do
        if prototype.name:sub(1, #const.prefix) == const.prefix then
            if prototype.name:find('se-space', 1, true) ~= nil
                or prototype.name:find('se-deep-space', 1, true) ~= nil
            then
                -- ignore
            else
                -- Hacky... 
                if prototype.collision_mask then
                    prototype.collision_mask.layers['space_tile'] = true
                end
            end
        end
    end
end

return SpaceExplorationSupport
