GEF.EventClasses = {} -- Event classes are stored here, indexed by their folder name.
GEF.ActiveEvents = {}
GEF.ActiveEventsByID = {}
GEF.ActiveEventsByType = {}

local eventIncrement = 0
local loadEventClassFile
local createEvent
local prepareEventClass
local makeEventID
local trackEvent


--[[
    - Creates and initializes a new event instance.
    - The event must be loaded first, which is handled by the rest of this file.
    - Addtional args are sent to the event's :Initialize() function.
    - If used on SERVER:
        - The event will be made both on SERVER and on CLIENT, with their ID's being synced.
        - Varargs (...) will be networked to the client, so make sure they are safely networkable.
    - If used on CLIENT:
        - The event will be made on CLIENT only.
        - The event will have its own clientside ID, which is of the form "cl_" .. INTEGER.
--]]
function GEF.CreateEvent( eventName, ... )
    local eventClass = GEF.EventClasses[eventName]
    if not eventClass then error( "Could not find an event with the name " .. eventName ) end

    return eventClass:Create( ... )
end

-- Loads an event class from the given folder name, but does not cache it into GEF.EventClasses.
function GEF.LoadEventClass( eventName )
    local eventClass = loadEventClassFile( eventName )

    -- Receursively define base event class
    if eventClass.BaseEventName then
        local baseClass = GEF.LoadEventClass( eventClass.BaseEventName )

        eventClass = table.Inherit( eventClass, baseClass )
    else
        eventClass = table.Inherit( eventClass, GEF.EventBase )
    end

    prepareEventClass( eventClass, eventName )

    return eventClass
end

-- Loads and caches all event classes.
function GEF.LoadEventClasses()
    local _, folders = file.Find( "gef/events/*", "LUA" )

    for _, v in pairs( folders ) do
        GEF.EventClasses[v] = GEF.LoadEventClass( v )
        print( "GEF Registered event: " .. v )
    end
end


----- PRIVATE FUNCTIONS -----

-- include()'s the event class file.
loadEventClassFile = function( eventName )
    EVENT = {}

    if file.Exists( "gef/events/" .. eventName .. "/sh_init.lua", "LUA" ) then
        include( "gef/events/" .. eventName .. "/sh_init.lua" )

        if SERVER then
            AddCSLuaFile( "gef/events/" .. eventName .. "/sh_init.lua" )
        end
    end

    local eventClass = EVENT
    EVENT = nil

    return eventClass
end

-- Creates and networks an event instance.
createEvent = function( eventClass, eventName, cl_id, ... )
    local event = setmetatable( {}, { __index = table.Copy( eventClass ) } )
    -- NOTE: table.Copy() does not perform deep clones of Vectors and Angles, those will be passed by reference.
    -- TODO: Either document this somewhere with a warning to treat all Vectors/Angles as constants, or make a deep clone function.

    function event:Create()
        error( ":Create() does not exist on GEF Event instances, use GEF.CreateEvent( eventName, ... ) instead." )
    end

    local id = makeEventID( cl_id )
    event._id = id

    trackEvent( event, eventName, id )

    if SERVER then
        net.Start( "GEF_CreateEvent" )
        net.WriteString( eventName )
        net.WriteUInt( id, 32 )
        net.WriteTable( { ... } )
        net.Broadcast()
    end

    event:Initialize( ... )
    hook.Run( "GEF_EventCreated", event )

    return event
end

-- Prepares the event class (auto-defined vars, creation function, etc).
prepareEventClass = function( eventClass, eventName )
    eventClass._name = eventName

    --[[
        - Creates and initializes a new event instance.
        - Args are sent to the event's :Initialize() function.
        - If used on SERVER, the args will also be networked to all clients, so make sure they're safely networkable values.
    --]]
    function eventClass:Create( ... )
        local event = createEvent( eventClass, eventName, nil, ... )

        return event
    end
end

makeEventID = function( cl_id )
    if SERVER then
        eventIncrement = eventIncrement + 1

        return eventIncrement
    end

    if not cl_id then
        eventIncrement = eventIncrement + 1
        cl_id = "cl_" .. eventIncrement
    end

    return cl_id
end

trackEvent = function( event, eventName, id )
    local eventsByType = GEF.ActiveEventsByType[eventName]

    if not eventsByType then
        eventsByType = {}
        GEF.ActiveEventsByType[eventName] = eventsByType
    end

    table.insert( eventsByType, event )
    table.insert( GEF.ActiveEvents, event )
    GEF.ActiveEventsByID[id] = event
end


----- SETUP -----

if SERVER then
    concommand.Add( "gef_reload_events", function( ply )
        if IsValid( ply ) and not ply:IsSuperAdmin() then return end

        net.Start( "GEF_ReloadEventClasses" )
        net.Broadcast()
        GEF.LoadEventClasses()

        print( "GEF Reloaded events" )
    end )
end

if CLIENT then
    net.Receive( "GEF_ReloadEventClasses", function()
        GEF.LoadEventClasses()
    end )

    net.Receive( "GEF_CreateEvent", function()
        local eventName = net.ReadString()
        local eventID = net.ReadUInt( 32 )
        local clientArgs = net.ReadTable()

        local eventClass = GEF.EventClasses[eventName]
        if not eventClass then return ErrorNoHaltWithStack( "Couldn't find an event with the name " .. eventClass ) end

        createEvent( eventClass, eventName, eventID, unpack( clientArgs ) )
    end )
end

GEF.LoadEventClasses()
