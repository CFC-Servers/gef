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

-- Locals
local type = type
local assert = assert
local IsValid = IsValid
local isnumber = isnumber
local isstring = isstring
local isfunction = isfunction
local table_insert = table.insert

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

--- Creates an event timer
--- - This should be used in place of all timer.Simple() calls tied to specific event instances.
--- - These will automatically be cleaned up when the event ends.
--- - Note: that the callback will still trigger even if the event hasn't started yet.
--- @param interval number
--- @param callback function
--- @return nil
function eventBase:TimerSimple( interval, callback )
    assert( isnumber( interval ), "Expected interval to be a number" )
    assert( isfunction( callback ), "Expected callback to be a function" )

    local timerName = getListenerName( self, "SimpleTimer_" .. CurTime() )
    self._timers[timerName] = true
    timer.Create( timerName, interval, 1, callback )
end


--- Marks a set of existing entities as being managed by this event
--- (So they will be cleaned up when the event ends)
--- @param entities table<Entity>
function eventBase:TrackEntities( entities )
    local entCount = #entities
    local entTable = self._entities

    for i = 1, entCount do
        table_insert( entTable, entities[i] )
    end
end

--- Creates a new Entity scoped to, and managed by this event
--- @param className string
--- @return Entity | NPC
function eventBase:EntCreate( className )
    local creator = SERVER and ents.Create or ents.CreateClientside

    local ent = creator( className )
    table_insert( self._entities, ent )

    return ent
end

--- Tells event clients to run a method on the event instance with the given arguments.
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

    table_insert( self._players, ply )
    self._playerLookup[ply] = true

    self:OnPlayerAdded( ply )
    self:BroadcastMethod( "AddPlayer", ply )

    if SERVER then
        -- When a player joins, they should see all Event entities
        self:ShowNetworkEnts( ply )
    end

    hook.Run( "GEF_PlayerJoinedEvent", ply, self )

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

    hook.Run( "GEF_PlayerLeftEvent", ply, self )

    return true
end

--- Checks if the player exists in the Event
--- @param ply Player|Entity
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

--- Gets a CRecpientFilter for the Event's players
--- @return CRecipientFilter
function eventBase:GetPlayersFilter()
    local filter = CRecipientFilter()
    filter:AddPlayers( self:GetPlayers() )

    return filter
end

--- Gets all players who have not signed up for the event
--- @return table<Player>
function eventBase:GetAbsent()
    local absent = {}
    local all = player.GetAll()

    local plyCount = #all
    for i = 1, plyCount do
        local ply = all[i]

        if not self:HasPlayer( ply ) then
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

-- ===== Entity Vars =====
do
    -- This is a set of managed Entity Var functions
    -- These let you set vars on an entity that will be automatically cleaned up

    --- Sets a managed var in the Entity's table
    --- Note: This will be automatically cleaned up when the event ends
    --- Note: You should use this in place of ent:GetTable()[name] = value
    --- @param ent Entity
    --- @param key string
    --- @param value any?
    function eventBase:SetEntVar( ent, key, value )
        local entVars = self._entVars[ent]
        if not entVars then
            entVars = {}
            self._entVars[ent] = entVars
        end

        local newKey = getListenerName( self, key )
        table_insert( entVars, newKey )

        local entTable = ent:GetTable()
        entTable[newKey] = value
    end

    --- Sets multiple managed vars in the Entity's table
    --- Note: These will be automatically cleaned up when the event ends
    --- Note: You should use this in place of multiple ent:GetTable()[name] = value
    --- Note: This is a minor optimization and should only be used when you have many vars to set
    --- @param ent Entity
    --- @param vars table<string, any>
    function eventBase:SetEntVars( ent, vars )
        local entVars = self._entVars[ent]
        if not entVars then
            entVars = {}
            self._entVars[ent] = entVars
        end

        local entTable = ent:GetTable()
        for key, value in pairs( vars ) do
            local newKey = getListenerName( self, key )
            table_insert( entVars, newKey )

            entTable[newKey] = value
        end
    end

    --- Gets a managed var in the Entity's table
    --- Note: You should use this in place of ent:GetTable()[name]
    --- @param ent Entity
    --- @param name string
    --- @return any?
    function eventBase:GetEntVar( ent, name )
        local entTable = ent:GetTable()
        return entTable[getListenerName( self, name )]
    end
end

-- ===== Entity Callbacks =====
do
    -- This is a set of functions for managing Entity callbacks
    -- Callbacks will automatically be cleaned up when the event ends

    --- Adds a managed callback to the given Entity
    --- Note: This will be automatically cleaned up when the event ends
    --- Note: You should use this in place of ent:AddCallback( name, callback )
    --- @param ent Entity
    --- @param name string
    --- @param callback function
    --- @return number
    function eventBase:AddEntCallback( ent, name, callback )
        local allCallbacks = self._entCallbacks[ent]
        if not allCallbacks then
            allCallbacks = {}
            self._entCallbacks[ent] = allCallbacks
        end

        local hookCallbacks = allCallbacks[name]
        if not hookCallbacks then
            hookCallbacks = {}
            allCallbacks[name] = hookCallbacks
        end

        local id = ent:AddCallback( name, callback )
        table_insert( hookCallbacks, id )

        return id
    end

    --- Removes a managed callback from the given Entity
    --- Note: You should use this in place of ent:RemoveCallback( name, callback )
    --- @param ent Entity
    --- @param name string
    --- @param id number
    function eventBase:RemoveEntCallback( ent, name, id )
        local allCallbacks = self._entCallbacks[ent]
        if not allCallbacks then return end

        local hookCallbacks = allCallbacks[name]
        if not hookCallbacks then return end

        table.RemoveByValue( hookCallbacks, id )
        ent:RemoveCallback( name, id )
    end
end

-- ===== Networked Entities =====
do
    -- This is a set of tools that allows you to control the transmission of event entities
    -- Any managed entity will only be transmitted to players who have signed up for the event

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

                if ent and IsValid( ent ) then
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
    end
end

-- ===== Network Var Utils =====
do
    -- This is a set of managed NW2 Var functions
    -- These vars will automatically be cleaned up when the event ends
    -- Interally, these are just wrappers around Entity:SetNW2Var and Entity:GetNW2Var
    -- (those are the only functions that let you set nil)

    if SERVER then
        --- Sets a managed NW2 Var on the given Entity
        --- @param ent Entity
        --- @param key string
        --- @param value any?
        function eventBase:SetNW2Var( ent, key, value )
            local entVars = self._nw2Vars[ent]
            if not entVars then
                entVars = {}
                self._nw2Vars[ent] = entVars
            end

            local newKey = getListenerName( self, key )
            table_insert( entVars, newKey )

            ent:SetNW2Var( newKey, value )
        end

        --- Sets a managed NW2 Angle on the given Entity
        --- @param ent Entity
        --- @param key string
        --- @param value Angle?
        function eventBase:SetNW2Angle( ent, key, value )
            self:SetNW2Var( ent, key, value )
        end

        --- Sets a managed NW2 Boolean on the given Entity
        --- @param ent Entity
        --- @param key string
        --- @param value boolean?
        function eventBase:SetNW2Bool( ent, key, value )
            self:SetNW2Var( ent, key, value )
        end

        --- Sets a managed NW2 Entity on the given Entity
        --- @param ent Entity
        --- @param key string
        --- @param value Entity?
        function eventBase:SetNW2Entity( ent, key, value )
            self:SetNW2Var( ent, key, value )
        end

        --- Sets a managed NW2 Integer on the given Entity
        --- @param ent Entity
        --- @param key string
        --- @param value number?
        function eventBase:SetNW2Int( ent, key, value )
            self:SetNW2Var( ent, key, value )
        end

        --- Sets a managed NW2 String on the given Entity
        --- @param ent Entity
        --- @param key string
        --- @param value string?
        function eventBase:SetNW2String( ent, key, value )
            self:SetNW2Var( ent, key, value )
        end

        --- Sets a managed NW2 Vector on the given Entity
        --- @param ent Entity
        --- @param key string
        --- @param value Vector?
        function eventBase:SetNW2Vector( ent, key, value )
            self:SetNW2Var( ent, key, value )
        end
    end

    -- This is a set of managed NW2 Var functions
    -- These vars will automatically be cleaned up when the event ends
    -- Interally, these are just wrappers around Entity:SetNW2Var and Entity:GetNW2Var
    -- (those are the only functions that let you set nil)

    --- Gets a managed NW2 Var on the given Entity
    --- @param ent Entity
    --- @param key string
    --- @param default any?
    --- @return any?
    function eventBase:GetNW2Var( ent, key, default )
        return ent:GetNW2Var( getListenerName( self, key ), default )
    end

    --- Gets a managed NW2 Angle on the given Entity
    --- @param ent Entity
    --- @param key string
    --- @return Angle?
    function eventBase:GetNW2Angle( ent, key, default )
        return self:GetNW2Var( ent, key, default )
    end

    --- Gets a managed NW2 Boolean on the given Entity
    --- @param ent Entity
    --- @param key string
    --- @param default boolean?
    --- @return boolean?
    function eventBase:GetNW2Bool( ent, key, default )
        return self:GetNW2Var( ent, key, default )
    end

    --- Gets a managed NW2 Entity on the given Entity
    --- @param ent Entity
    --- @param key string
    --- @param default Entity?
    --- @return Entity?
    function eventBase:GetNW2Entity( ent, key, default )
        return self:GetNW2Var( ent, key, default )
    end

    --- Gets a managed NW2 Integer on the given Entity
    --- @param ent Entity
    --- @param key string
    --- @param default number?
    --- @return number?
    function eventBase:GetNW2Int( ent, key, default )
        return self:GetNW2Var( ent, key, default )
    end

    --- Gets a managed NW2 String on the given Entity
    --- @param ent Entity
    --- @param key string
    --- @param default string?
    --- @return string?
    function eventBase:GetNW2String( ent, key, default )
        return self:GetNW2Var( ent, key, default )
    end

    --- Sets a managed NW2 Vector on the given Entity
    --- @param ent Entity
    --- @param key string
    --- @param default Vector?
    --- @return Vector?
    function eventBase:GetNW2Vector( ent, key, default )
        self:GetNW2Var( ent, key, default )
    end
end

-- ===== Networked Utils =====
do
    --- These wrap some base functions and make them only operate on the current Event players
    if SERVER then
        --- Runs util.Effect for the Event's players
        --- NOTE: You should use this in place of util.Effect
        function eventBase:UtilEffect( effectName, data )
            local filter = self:GetPlayersFilter()
            util.Effect( effectName, data, false, filter )
        end

        --- Runs util.ScreenShake for the Event's players
        --- NOTE: You should use this in place of util.ScreenShake
        --- @param origin Vector
        --- @param amplitude number
        --- @param frequence number
        --- @param duration number
        --- @param radius number
        --- @param airshake boolean
        function eventBase:UtilScreenshake( origin, amplitude, frequence, duration, radius, airshake )
            self:BroadcastMethodToPlayers( "DoScreenshake", origin, amplitude, frequence, duration, radius, airshake )
        end
    end

    if CLIENT then
        --- Runs util.ScreenShake
        --- @param origin Vector
        --- @param amplitude number
        --- @param frequence number
        --- @param duration number
        --- @param radius number
        --- @param airshake boolean
        function eventBase:DoScreenshake( origin, amplitude, frequence, duration, radius, airshake )
            util.ScreenShake( origin, amplitude, frequence, duration, radius, airshake )
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
    self._nw2Vars = {}
    self._entVars = {}
    self._entCallbacks = {}
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

--- Called when evaluating whether or not a player can be added
--- @return boolean
function eventBase:CanPlayerJoin( _ply )
    return true
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
    for hookName, listeners in pairs( self._hookListeners or {} ) do
        for listenerName in pairs( listeners ) do
            hook.Remove( hookName, listenerName )
        end
    end

    -- Cleanup event timers
    for timerName in pairs( self._timers or {} ) do
        timer.Remove( timerName )
    end

    -- TODO: Cleanup managed CallOnRemove callbacks

    -- Cleanup event entities
    for _, ent in ipairs( self._entities or {} ) do
        if ent and ent:IsValid() then
            ent:Remove()
        end
    end

    -- Cleanup event NW2 Vars
    for ent, keys in pairs( self._nw2Vars or {} ) do
        if IsValid( ent ) then
            for _, key in ipairs( keys ) do
                ent:SetNW2Var( key, nil )
            end
        end
    end

    -- Cleanup event entity table Vars
    for ent, keys in pairs( self._entVars or {} ) do
        if IsValid( ent ) then
            local tbl = ent:GetTable()

            for _, key in ipairs( keys ) do
                tbl[key] = nil
            end
        end
    end

    -- Cleanup event entity callbacks
    for ent, hooks in pairs( self._entCallbacks or {} ) do
        if IsValid( ent ) then
            for hookName, callbackIDs in pairs( hooks ) do
                local idCount = #callbackIDs

                for i = 1, idCount do
                    local callbackID = callbackIDs[i]
                    ent:RemoveCallback( hookName, callbackID )
                end
            end
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

-- ===== Areas =====
do
    if SERVER then
        --- Creates a new area handler
        --- @param pos Vector
        --- @param min Vector
        --- @param max Vector
        --- @param callback function
        function eventBase:CreateArea( pos, min, max, callback )
            local area = self:EntCreate( "gef_area" )
            area:SetPos( pos )
            area:Spawn()
            area:Setup( min, max )
            area:SetCallback( callback )
        end
    end
end

----- SETUP -----

if SERVER then
    local function playerCanJoin( ply, event )
        if event:HasPlayer( ply ) then return end

        local canJoin = hook.Run( "GEF_CanPlayerJoinEvent", ply, event )
        if canJoin == false then return end

        return event:CanPlayerJoin( ply )
    end

    net.Receive( "GEF_JoinRequest", function( _, ply )
        local id = net.ReadUInt( 32 )
        local event = GEF.ActiveEventsByID[id]
        if not IsValid( event ) then return end

        if not playerCanJoin( ply, event ) then return end

        event:AddPlayer( ply )
    end )
end

if CLIENT then
    local unpack = unpack

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

    --- Sends a request to join the event
    --- TODO: Some kind of rate limits on this process are needed
    function eventBase:RequestToJoin()
        net.Start( "GEF_JoinRequest" )
        net.WriteUInt( self:GetID(), 32 )
        net.SendToServer()
    end
end
