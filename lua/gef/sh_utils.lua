GEF.Utils = {}

local Utils = GEF.Utils


--- Takes a table or single element and turns it into a boolean lookup table.
--- The input table can either be a single non-table item, a sequential list, or a lookup table.
---
--- Examples:
--- - tbl = somePlayer -- Good
--- - tbl = { "a", "b", "c" } -- Good
--- - tbl = { a = true, b = true, c = true } -- Good
--- - tbl = { "a", "b", c = true } -- Bad
--- @param tbl table
function Utils.MakeLookupTable( tbl )
    if tbl == nil then return {} end
    if type( tbl ) ~= "table" then return { [tbl] = true } end

    local lookup = {}

    if #tbl == table.Count( tbl ) then
        -- Sequential table
        for _, v in ipairs( tbl ) do
            lookup[v] = true
        end
    else
        -- Lookup table
        for k in pairs( tbl ) do
            lookup[k] = true
        end
    end

    return lookup
end

--- Returns a new table with all the elements from the first table that are not in the second table.
--- @param allObjects table The sequential list to filter through
--- @param excludedObjects? any
--- @return table
function Utils.Exclude( allObjects, excludedObjects )
    if type( allObjects ) ~= "table" then error( "Expected allObjects to be a table" ) end
    if excludedObjects == nil then return allObjects end

    local disallowedLookup = GEF.Utils.MakeLookupTable( excludedObjects )
    local allowedObjects = {}

    for _, obj in ipairs( allObjects ) do
        if not disallowedLookup[obj] then
            table.insert( allowedObjects, obj )
        end
    end

    return allowedObjects
end

--- Picks a number of random elements from the given table                                                                                                                                  --- @param tbl table The sequential table to pick from
--- @param count number The number of elements to return
function Utils.PickRandom( tbl, count )
    local keys = table.GetKeys( tbl )

    if count >= #keys then
        return tbl
    end

    table.Shuffle( keys )

    local selected = {}
    for i = 1, count do
        local key = keys[i]
        selected[key] = tbl[key]
    end

    if not table.IsSequential( tbl ) then
        return selected
    end

    -- If the input table is sequential, so should the output
    return table.ClearKeys( selected )
end

--- Gets the maximum Z position still within the world above the given pos
--- @param pos Vector
function Utils.GetCeiling( pos )
    local _, max = game.GetWorld():GetModelBounds()

    -- FIXME: Technically the trace only needs to go up to (MaxZ - CurrentZ)
    local maxZ = max[3]

    local tr = util.TraceLine( {
        start = pos,
        endpos = pos + Vector( 0, 0, maxZ ),
        mask = MASK_SOLID_BRUSHONLY,
        collisiongroup = COLLISION_GROUP_WORLD,
        ignoreworld = false
    } )

    return tr.HitPos[3]
end
