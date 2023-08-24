GEF.Events = {}

function GEF.GetEvent( eventName )
    return GEF.Events[eventName]
end

function GEF.LoadEvent( eventName )
    EVENT = setmetatable( {}, GEF.EventBase )

    if file.Exists( "gef/events/" .. eventName .. "/sh_init.lua", "LUA" ) then
        include( "gef/events/" .. eventName .. "/sh_init.lua" )

        if SERVER then
            AddCSLuaFile( "gef/events/" .. eventName .. "/sh_init.lua" )
        end
    end

    EVENT.ID = eventName
    GEF.Events[eventName] = table.Copy( EVENT )

    EVENT = {} -- Set empty for autoload
end

function GEF.LoadEvents()
    local _, folders = file.Find( "gef/events/*", "LUA" )

    for _, v in pairs( folders ) do
        GEF.LoadEvent( v )
        print( "GEF Loaded event: " .. v )
    end
end

GEF.LoadEvents()
