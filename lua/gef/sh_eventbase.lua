--- @class GEF_Event
GEF.EventBase = {}

--- @class GEF_Event
local eventBase = GEF.EventBase
eventBase.PrintName = "Base Event"
eventBase.Description = "This is the base event. It does nothing."
eventBase.SignupDuration = 30
eventBase.IsGEFEvent = true
eventBase.__index = eventBase

eventBase._signingUp = false
eventBase._signupEndsAt = 0

local getListenerName

--- Starts the event, which calls :OnStarted() and the GEF_EventStarted hook.
--- @return nil
function eventBase:Start()
    if self:HasStarted() then return end

    self._started = true
    self:OnStarted()
    self:BroadcastMethod( "Start" )

    hook.Run( "GEF_EventStarted", self )
end

--- Checks if the event has started
--- @return boolean
function eventBase:HasStarted()
    return self._started
end

--- Ends the event, which calls :OnEnded() and the GEF_EventEnded hook.
--- - Note: this can be called even if the event hasn't started yet.
--- - You can use self:HasStarted() to check for this.
--- - In effect, :End() is an Event's equivalent to Entity:Remove().
--- - After :OnEnded() finishes, the event instance is no longer valid.
--- - Additionally, anything previously made with Event:HookAdd(), Event:CreateTimer(), etc. will automatically be cleaned up.
--- @return nil
function eventBase:End()
    self._ended = true
    self:OnEnded()
    self:BroadcastMethod( "End" )

    hook.Run( "GEF_EventEnded", self )
end

--- Equivalent to hook.Add( hookName, listenerName, callback )
--- - This should be used in place of all hook.Add() calls tied to specific event instances.
--- - These will automatically be cleaned up when the event ends.
--- - Note: the callback will still trigger even if the event hasn't started yet.
--- @return nil
function eventBase:HookAdd( hookName, listenerName, callback )
    assert( isstring( hookName ), "Expected hookname to be a string" )
    assert( isstring( listenerName ), "Expected listenerName to be a string" )
    assert( isfunction( callback ), "Expected callback to be a function" )

    listenerName = getListenerName( self, listenerName )

    local listeners = self._hookListeners[hookName]
    if not listeners then
        listeners = {}
        self._hookListeners[hookName] = listeners
    end

    listeners[listenerName] = true

    hook.Add( hookName, listenerName, callback )
end

--- Remove an event hook
--- @param hookName string
--- @param listenerName string
--- @return nil
function eventBase:HookRemove( hookName, listenerName )
    assert( isstring( hookName ), "Expected hookname to be a string" )
    assert( isstring( listenerName ), "Expected listenerName to be a string" )

    listenerName = getListenerName( self, listenerName )

    local listeners = self._hookListeners[hookName]

    if listeners then
        listeners[listenerName] = nil
    end

    hook.Remove( hookName, listenerName )
end

--- Creates an event timer
--- - This should be used in place of all timer.Create() calls tied to specific event instances.
--- - These will automatically be cleaned up when the event ends.
--- - Note: that the callback will still trigger even if the event hasn't started yet.
--- @param timerName string
--- @param interval number
--- @param repetitions number
--- @param callback function
--- @return nil
function eventBase:TimerCreate( timerName, interval, repetitions, callback )
    assert( isstring( timerName ), "Expected timerName to be a string" )
    assert( isnumber( interval ), "Expected interval to be a number" )
    assert( isnumber( repetitions ), "Expected repetitions to be a number" )
    assert( isfunction( callback ), "Expected callback to be a function" )

    timerName = getListenerName( self, timerName )
    self._timers[timerName] = true
    timer.Create( timerName, interval, repetitions, callback )
end

--- Removes an event timer with the given name
--- @param timerName string
--- @return nil
function eventBase:TimerRemove( timerName )
    if type( timerName ) ~= "string" then error( "Expected timerName to be a string" ) end

    timerName = getListenerName( self, timerName )
    self._timers[timerName] = nil
    timer.Remove( timerName )
end

--- Adjusts the given event timer
--- @param timerName string
--- @param delay number
--- @param repetitions number?
--- @param callback function?
--- @return nil
function eventBase:TimerAdjust( timerName, delay, repetitions, callback )
    if type( timerName ) ~= "string" then error( "Expected timerName to be a string" ) end

    return timer.Adjust( getListenerName( self, timerName ), delay, repetitions, callback )
end

--- Starts the given timer
--- @param timerName string
--- @return nil
function eventBase:TimerStart( timerName )
    return timer.Start( getListenerName( self, timerName ) )
end

--- Checks if the given timer exists for the event
--- @param timerName string
--- @return boolean
function eventBase:TimerExists( timerName )
    if type( timerName ) ~= "string" then error( "Expected timerName to be a string" ) end

    return timer.Exists( getListenerName( self, timerName ) )
end

--- Marks a set of existing entities as being managed by this event
--- (So they will be cleand up when the event ends)
--- @param entities table<Entity>
function eventBase:TrackEntities( entities )
    local entCount = #entities

    for i = 1, entCount do
        table.insert( self._entities, entities[i] )
    end
end

--- Creates a new Entity scoped to, and managed by this event
--- @param className string
--- @return Entity | NPC
function eventBase:EntCreate( className )
    local creator = SERVER and ents.Create or ents.CreateClientside

    local ent = creator( className )
    table.insert( self._entities, ent )

    return ent
end

--- Tells clients to run a method on the event instance with the given arguments.
--- @param methodName string
--- @param ... any
--- @return nil
function eventBase:BroadcastMethod( methodName, ... )
    if CLIENT then return end

    net.Start( "GEF_EventMethod" )
    net.WriteUInt( self:GetID(), 32 )
    net.WriteString( methodName )
    net.WriteTable( { ... } )
    net.Broadcast()
end

--- Tells all current event players to run a method on the event instance with the given arguments.
--- @param methodName string
--- @param ... any
--- @return nil
function eventBase:BroadcastMethodToPlayers( methodName, ... )
    if CLIENT then return end

    net.Start( "GEF_EventMethod" )
    net.WriteUInt( self:GetID(), 32 )
    net.WriteString( methodName )
    net.WriteTable( { ... } )
    net.Send( self:GetPlayers() )
end

--- Tells the specified Client to run a method on the event instance with the given arguments.
--- @param methodName string
--- @param ... any
--- @return nil
function eventBase:SendMethod( ply, methodName, ... )
    if CLIENT then return end

    net.Start( "GEF_EventMethod" )
    net.WriteUInt( self:GetID(), 32 )
    net.WriteString( methodName )
    net.WriteTable( { ... } )
    net.Send( ply )
end

--- Adds a player to the Event
--- @param ply Player
--- @return boolean successful True if successful, False if they were already in the event
function eventBase:AddPlayer( ply )
    if self:HasPlayer( ply ) then return false end
    assert( ply and ply:IsValid() and ply:IsPlayer(), "Expected ply to be a valid player" )

    table.insert( self._players, ply )
    self._playerLookup[ply] = true

    self:OnPlayerAdded( ply )
    self:BroadcastMethod( "AddPlayer", ply )

    if SERVER then
        -- When a player joins, they should see all Event entities
        self:ShowNetworkEnts( ply )
    end

    return true
end

--- Removes a player from the Event
--- @param ply Player
--- @return boolean successful True if successful, False if they did not exist in the event
function eventBase:RemovePlayer( ply )
    if not self:HasPlayer( ply ) then return false end
    assert( IsValid( ply ) and ply:IsPlayer(), "Expected ply to be a valid player" )

    table.RemoveByValue( self._players, ply )
    self._playerLookup[ply] = nil

    self:OnPlayerRemoved( ply )
    self:BroadcastMethod( "RemovePlayer", ply )

    if SERVER then
        -- When a player leaves, they should stop seeing all Event entities
        self:HideNetworkEnts( ply )
    end

    return true
end

--- Checks if the player exists in the Event
--- @param ply Player
--- @return boolean
function eventBase:HasPlayer( ply )
    if not ply then return false end

    return self._playerLookup[ply] ~= nil
end

--- Gets all players who have signed up for the Event
--- @return table<Player>
function eventBase:GetPlayers()
    return self._players
end

--- Gets all players who have not signed up for the event
--- @return table<Player>
function eventBase:GetAbsent()
    local table_insert = table.insert
    local playerLookup = self._playerLookup

    local absent = {}
    local all = player.GetAll()

    local plyCount = #all
    for i = 1, plyCount do
        local ply = all[i]

        if not playerLookup[ply] then
            table_insert( absent, ply )
        end
    end

    return absent
end

--- Checks if the Event is in the Signup Phase
--- @return boolean
function eventBase:IsSigningUp()
    return self._signingUp
end

--- Returns the CurTime-based timestamp of the end of the Signup process
--- @return number
function eventBase:SignupEndsAt()
    return self._signupEndsAt
end

--- Gets the printed name for the Event
--- @return string
function eventBase:GetPrintName()
    return self.PrintName
end

--- Gets the Event description
--- @return string
function eventBase:GetDescription()
    return self.Description
end

--- Gets the internal name of the Event
--- @return string
function eventBase:GetInternalName()
    return self._name
end

--- Gets the Instance name for the Event
--- @return string
function eventBase:GetInstanceName()
    return self:GetInternalName() .. "_" .. self:GetID()
end

--- Gets the Event ID
--- @return number
function eventBase:GetID()
    return self._id
end

--- Returns if the Event is valid
--- @return boolean
function eventBase:IsValid()
    return true
end

if SERVER then
    --- Entities that are only transmitted to players who are in the event
    eventBase._networkEnts = {}

    --- @param ent Entity
    --- @param ply Player
    --- @param stopTransmitting boolean
    local function preventTransmitRecursive( ent, ply, stopTransmitting )
        if not (ent and ent:IsValid()) then return end

        ent:SetPreventTransmit( ply, stopTransmitting )

        local children = ent:GetChildren()
        local childCount = #children

        for i = 1, childCount do
            local child = children[i]
            preventTransmitRecursive( child, ply, stopTransmitting )
        end
    end

    --- Prevents transmission of the Event's networked entities to the given player
    --- @param ply Player
    function eventBase:HideNetworkEnts( ply )
        for ent in pairs( self._networkEnts ) do
            preventTransmitRecursive( ent, ply, true )
        end
    end

    --- Allows transmission of the Event's networked entities to the given player
    --- @param ply Player
    function eventBase:ShowNetworkEnts( ply )
        for ent in pairs( self._networkEnts ) do
            preventTransmitRecursive( ent, ply, false )
        end
    end

    --- Sets a group of entities to only be transmitted to Players who have signed up for the event
    --- @param entities table<Entity>
    function eventBase:OnlyTransmitToEvent( entities )
        local entsCount = #entities
        local transmitEnts = self._networkEnts

        local absent = self:GetAbsent()
        local absentCount = #absent

        -- Hide the ents from players who are not in the event
        for i = 1, entsCount do
            local ent = entities[i]
            transmitEnts[ent] = true

            ent:CallOnRemove( "GEF_TransmitEnt_Cleanup", function()
                transmitEnts[ent] = nil
            end )

            for p = 1, absentCount do
                local ply = absent[p]
                preventTransmitRecursive( ent, ply, true )
            end
        end
    end
end


if SERVER then
    --- Begins a simple signup process for players to join an event.
    --- Once the time is up, the event will automatically start.
    --- @param duration? number How long the signup process should last for
    --- @param excludedPlayers? table<Player> Players who should not be allowed to join the event
    function eventBase:StartSimpleSignup( duration, excludedPlayers )
        print( "SV: StartSimpleSignup" )
        GEF.Signup.StartSimple( self, duration, excludedPlayers )
    end
else
    --- @return boolean
    function eventBase:IsClientOnly()
        return self._isClientOnly
    end
end


----- OVERRIDABLE FUNCTIONS -----

--[[
    - Called when the event instance is created via GEF.CreateEvent( eventName, ... )
    - Can be given additional arguments, which are acquired from the GEF.CreateEvent() call.
    - REMINDER: Like most other overridable functions, you should call self.BaseClass.Initialize( self, ... ) at the start of this function when overriding it.

    - Example:
        function MyEventClass:Initialize( arg1, arg2 )
            self.BaseClass.Initialize( self, arg1, arg2 )

            doStuff()
        end
--]]
function eventBase:Initialize()
    self._players = {}
    self._playerLookup = {}
    self._hookListeners = {}
    self._timers = {}
    self._entities = {}
end

--- Called when the event starts.
function eventBase:OnStarted()
end

--- Called when the event ends.
--- After this finishes, the event instance is no longer valid.
function eventBase:OnEnded()
end

--- Called when a player is added to the event.
function eventBase:OnPlayerAdded( _ply )
end

--- Called when a player is removed from the event.
function eventBase:OnPlayerRemoved( _ply )
end


----- PRIVATE FUNCTIONS -----

--- @param event GEF_Event
--- @param name string
--- @return string
getListenerName = function( event, name )
    return "GEF_" .. event:GetInstanceName() .. "_" .. name
end

function eventBase:Cleanup()
    -- Cleanup event hooks
    for hookName, listeners in pairs( self._hookListeners ) do
        for listenerName in pairs( listeners ) do
            hook.Remove( hookName, listenerName )
        end
    end

    -- Cleanup event timers
    for timerName in pairs( self._timers ) do
        timer.Remove( timerName )
    end

    -- Cleanup event entities
    for _, ent in ipairs( self._entities ) do
        if ent and ent:IsValid() then
            ent:Remove()
        end
    end

    if SERVER then
        -- Reset entity transmission
        -- TODO: Should we always re-transmit all network ents?

        local plys = player.GetAll()
        local plyCount = #plys

        for i = 1, plyCount do
            local ply = plys[i]
            self:ShowNetworkEnts( ply )
        end
    end

    table.Empty( self )

    setmetatable( self, {
        IsValid = function()
            return false
        end,

        __index = function()
            error( "This GEF Event is invalid" )
        end,

        __newindex = function()
            error( "This GEF Event is invalid" )
        end,
    } )
end


----- SETUP -----

if CLIENT then
    net.Receive( "GEF_EventMethod", function()
        local id = net.ReadUInt( 32 )
        local event = GEF.ActiveEventsByID[id]
        if not IsValid( event ) then return end

        local methodName = net.ReadString()
        local method = event[methodName]
        if not method then return end

        local args = net.ReadTable()

        method( event, unpack( args ) )
    end )
end
