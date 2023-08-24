GEF.Events = {}

function GEF.LoadEvent( eventName )
    EVENT = setmetatable( {}, GEF.EventBase )

    if file.Exists( "gef/events/" .. eventName .. "/sh_init.lua", "LUA" ) then
        include( "gef/events/" .. eventName .. "/sh_init.lua" )

        if SERVER then
            AddCSLuaFile( "gef/events/" .. eventName .. "/sh_init.lua" )
        end
    end

    EVENT.ID = eventName

    local event = EVENT
    EVENT = nil

    return event
end

function GEF.LoadEvents()
    local _, folders = file.Find( "gef/events/*", "LUA" )

    for _, v in pairs( folders ) do
        GEF.Events[v] = true
        print( "GEF Registered event: " .. v )
    end
end

GEF.LoadEvents()

if SERVER then
    concommand.Add( "gef_reload_events", function( ply )
        if IsValid( ply ) and not ply:IsSuperAdmin() then return end

        net.Start( "GEF_ReloadEvents" )
        net.Broadcast()
        GEF.LoadEvents()

        print( "GEF Reloaded events" )
    end )
end

if CLIENT then
    net.Receive( "GEF_ReloadEvents", function()
        GEF.LoadEvents()
    end )
end
