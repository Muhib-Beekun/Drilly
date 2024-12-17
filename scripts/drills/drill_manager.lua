-- drill_manager.lua
local resource_manager = require("scripts.resources.resource_manager")
local drill_calculations = require("scripts.drills.drill_calculations")
local gui = require("gui.gui")

local drill_manager = {}

-- Initialize the storage tables
function drill_manager.initialize_storage()
    if not storage then
        storage = {}
    end
    storage.drills = storage.drills or {}
    storage.drill_unit_numbers = storage.drill_unit_numbers or {}
    storage.drill_processing_index = 1
    storage.force_update = true
    storage.surface_data = storage.surface_data or {}
    storage.minable_entities = storage.minable_entities or {}
    storage.temporary_alerts = storage.temporary_alerts or {}
    storage.player_data = storage.player_data or {}
end

-- Initialize drills
function drill_manager.initialize_drills()
    drill_manager.initialize_storage()

    -- Add drills from all surfaces
    for _, surface in pairs(game.surfaces) do
        storage.surface_data[surface.index] = storage.surface_data[surface.index] or {}
        local drills = surface.find_entities_filtered { type = "mining-drill", force = game.forces.player }

        for _, drill in pairs(drills) do
            if drill.valid and not storage.drills[drill.unit_number] then
                drill_manager.add_drill(drill, false) -- add quietly
            end
        end
    end

    -- Remove invalid drills
    local invalid = {}
    for unit_number, drill_data in pairs(storage.drills) do
        local drill = drill_data.entity
        if not (drill and drill.valid) then
            table.insert(invalid, unit_number)
        end
    end
    for _, unit_number in ipairs(invalid) do
        drill_manager.remove_drill({ unit_number = unit_number }, false)
    end

    -- Refresh UI once after bulk initialization
    drill_manager.refresh_ui()
end

-- Refresh the UI for all players
function drill_manager.refresh_ui()
    for _, player in pairs(game.connected_players) do
        if player.gui.screen.drill_inspector_frame then
            gui.update_drill_count(player)
            gui.update_drilly_surface_dropdown(player)
        end
    end
end

-- Add a drill
-- @param drill (LuaEntity) The drill entity being added
-- @param update_ui (boolean) If true or omitted, the UI is refreshed immediately
function drill_manager.add_drill(drill, update_ui)
    if not drill or not drill.valid then return end
    if storage.drills[drill.unit_number] then return end

    local drill_data = {
        entity = drill,
        unit_number = drill.unit_number,
        name = drill.name,
        position = drill.position,
        surface_index = drill.surface.index,
        yield_per_second = 0,
        total_resources = {},
        status = drill.status,
        last_updated_tick = game.tick,
    }

    storage.drills[drill.unit_number] = drill_data
    table.insert(storage.drill_unit_numbers, drill.unit_number)

    -- Update minable entities
    local resource_entities = resource_manager.get_resource_entities(drill)
    resource_manager.update_minable_entities_for_drill(drill, true, resource_entities)

    if update_ui ~= false then
        drill_manager.refresh_ui()
    end
end

-- Remove a drill
-- @param drill_or_data table or LuaEntity
-- @param update_ui (boolean) If true or omitted, the UI is refreshed immediately
function drill_manager.remove_drill(drill_or_data, update_ui)
    if not drill_or_data then return end

    local drill_entity
    local unit_number

    if drill_or_data.object_name == "LuaEntity" then
        drill_entity = drill_or_data
        unit_number = drill_entity.unit_number
    else
        -- If passed a table like {unit_number = X}, retrieve the drill entity from storage
        unit_number = drill_or_data.unit_number
        local drill_data = storage.drills[unit_number]
        if drill_data then
            drill_entity = drill_data.entity
        end
    end

    if not unit_number then return end

    storage.drills[unit_number] = nil
    for i, num in ipairs(storage.drill_unit_numbers) do
        if num == unit_number then
            table.remove(storage.drill_unit_numbers, i)
            break
        end
    end

    if drill_entity and drill_entity.valid then
        -- Update minable_entities
        local resource_entities = resource_manager.get_resource_entities(drill_entity)
        resource_manager.update_minable_entities_for_drill(drill_entity, false, resource_entities)
    end

    if update_ui ~= false then
        drill_manager.refresh_ui()
    end
end

-- Update a single drill's data
function drill_manager.update_drill_data(drill_data)
    if not storage.minable_entities then
        game.print(
        "[Drilly Mod] Warning: storage.minable_entities not initialized at UpdateDrillData. Initializing now.")
        drill_manager.initialize_drills()
    end

    local drill = drill_data.entity
    if not (drill and drill.valid) then
        drill_manager.remove_drill(drill, true)
        return
    end

    local current_status = drill.status

    local needs_update = false
    if storage.force_update then
        needs_update = true
    elseif current_status == defines.entity_status.working then
        needs_update = true
    elseif drill_data.yield_per_second == 0 then
        needs_update = true
    elseif drill_data.status ~= current_status then
        needs_update = true
    end

    if not needs_update then
        return
    end

    drill_data.status = current_status
    local productivity_bonus = drill.productivity_bonus or 0
    drill_data.productivity_bonus = 1 + productivity_bonus

    local resource_entities = resource_manager.get_resource_entities(drill)
    local mining_categories = drill.prototype.resource_categories

    local valid_resources = {}
    for _, resource in pairs(resource_entities) do
        if mining_categories[resource.prototype.resource_category] then
            local resource_name = resource.name
            if settings.global["drilly-group-deep-resources"].value then
                resource_name = resource_name:gsub("^deep%-", "")
            end
            valid_resources[resource_name] = valid_resources[resource_name] or {}
            table.insert(valid_resources[resource_name], resource)
        end
    end

    if next(valid_resources) == nil then
        drill_data.yield_per_second = 0
        drill_data.total_resources = {}
        drill_data.last_updated_tick = game.tick
        return
    end

    local total_yield_per_second = 0
    local total_resources = {}

    for resource_name, resources in pairs(valid_resources) do
        local yield_per_second = 0
        if script.active_mods["space-exploration"] and drill.name == "se-core-miner-drill" then
            yield_per_second = drill_calculations.calculate_core_miner_yield(drill, resources[1])
        else
            yield_per_second = drill_calculations.calculate_regular_miner_yield(drill, resources[1])
        end

        local num_tiles = #resources
        local total_resource_tiles = 0
        for _, res_list in pairs(valid_resources) do
            total_resource_tiles = total_resource_tiles + #res_list
        end
        local fraction = num_tiles / total_resource_tiles
        local frac_yield_per_second = yield_per_second * fraction
        total_yield_per_second = total_yield_per_second + frac_yield_per_second

        local total_amount = 0
        for _, resource in pairs(resources) do
            local resource_key = (resource.surface.index .. "_" .. resource.position.x .. "_" .. resource.position.y)
            if not storage.minable_entities[resource_key] then
                resource_manager.update_minable_entities_for_drill(drill, true, resource_entities)
            end
            local drills_covering = storage.minable_entities[resource_key] and
                storage.minable_entities[resource_key].drills or {}
            local num_drills_covering = 0
            for _ in pairs(drills_covering) do
                num_drills_covering = num_drills_covering + 1
            end
            local adjusted_amount = (resource.amount or 0) / math.max(num_drills_covering, 1)
            total_amount = total_amount + adjusted_amount
        end

        total_resources[resource_name] = {
            amount = total_amount * drill_data.productivity_bonus,
            yield_per_second = yield_per_second,
        }
    end

    drill_data.yield_per_second = total_yield_per_second
    drill_data.total_resources = total_resources
    drill_data.last_updated_tick = game.tick
end

-- Function to search drills based on resource, status, and surface
function drill_manager.search_drills(resource, status, surface, drill_type)
    local filtered_drills = {}

    for _, drill_data in pairs(storage.drills) do
        local drill_entity = drill_data.entity
        if drill_entity and drill_entity.valid then
            local drill_status = drill_data.status
            local drill_surface = game.surfaces[drill_entity.surface.name]
            if tostring(drill_status) == tostring(status) then
                if (not drill_type) or (drill_type == drill_entity.name) then
                    if drill_data.total_resources and drill_data.total_resources[resource] then
                        if surface == "Aggregate" or surface == drill_surface.name then
                            table.insert(filtered_drills, drill_data)
                        end
                    end
                end
            end
        end
    end
    return filtered_drills
end

return {
    initialize_drills = drill_manager.initialize_drills,
    add_drill = drill_manager.add_drill,
    remove_drill = drill_manager.remove_drill,
    update_drill_data = drill_manager.update_drill_data,
    refresh_ui = drill_manager.refresh_ui,
    search_drills = drill_manager.search_drills
}
