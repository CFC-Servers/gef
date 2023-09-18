GEF.Utils = {}

local Utils = GEF.Utils


--[[
    - Takes a table or single element and turns it into a boolean lookup table.
    - The input table can either be a single non-table item, a sequential list, or a lookup table.

    - Examples:
        tbl = somePlayer -- Good
        tbl = { "a", "b", "c" } -- Good
        tbl = { a = true, b = true, c = true } -- Good
        tbl = { "a", "b", c = true } -- Bad
--]]
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

--[[
    - Returns a new table with all the elements from the first table that are not in the second table.

    allObjects: (table)
        - The sequential list to filter through.
    excludedObjects: (optional) (table or any)
        - If nil, then allObjects will be returned.
        - If a non-table value, then it will be converted to a lookup table.
        - If a table, then all the elements in it will be excluded from the results.
--]]
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
