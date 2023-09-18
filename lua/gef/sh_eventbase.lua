GEF.EventBase = {}

local eventBase = GEF.EventBase
eventBase.PrintName = "Base Event"
eventBase.Description = "This is the base event. It does nothing."
eventBase.SignupDuration = 30


eventBase.IsGEFEvent = true
eventBase.__index = eventBase

local getListenerName
local cleanupEvent



----- INSTANCE FUNCTIONS -----

-- Starts the event, which calls :OnStarted() and the GEF_EventStarted hook.
function eventBase:Start()
    if self:HasStarted() then return end

    self._started = true
    self:OnStarted()
    self:BroadcastMethod( "Start" )

    hook.Run( "GEF_EventStarted", self )
end

function eventBase:HasStarted()
    return self._started
end

--[[
    - Ends the event, which calls :OnEnded() and the GEF_EventEnded hook.
    - Note that this can be called even if the event hasn't started yet.
        - You can use self:HasStarted() to check for this.
        - In effect, :End() is an Event's equivalent to Entity:Remove().
    - After :OnEnded() finishes, the event instance is no longer valid.
        - Additionally, anything previously made with Event:HookAdd(), Event:CreateTimer(), etc. will automatically be cleaned up.
--]]
function eventBase:End()
    self._ended = true
    self:OnEnded()
    self:BroadcastMethod( "End" )

    hook.Run( "GEF_EventEnded", self )

    cleanupEvent( self )
end

--[[
    - Equivalent to hook.Add( hookName, listenerName, callback )
    - This should be used in place of all hook.Add() calls tied to specific event instances.
    - These will automatically be cleaned up when the event ends.
    - Note that the callback will still trigger even if the event hasn't started yet.
--]]
function eventBase:HookAdd( hookName, listenerName, callback )
    if type( hookName ) ~= "string" then error( "Expected hookname to be a string" ) end
    if type( listenerName ) ~= "string" then error( "Expected listenerName to be a string" ) end
    if type( callback ) ~= "function" then error( "Expected callback to be a function" ) end

    listenerName = getListenerName( self, listenerName )

    local listeners = self._hookListeners[hookName]
    if not listeners then
        listeners = {}
        self._hookListeners[hookName] = listeners
    end

    listeners[listenerName] = true

    hook.Add( hookName, listenerName, callback )
end

function eventBase:HookRemove( hookName, listenerName )
    if type( hookName ) ~= "string" then error( "Expected hookname to be a string" ) end
    if type( listenerName ) ~= "string" then error( "Expected listenerName to be a string" ) end

    listenerName = getListenerName( self, listenerName )

    local listeners = self._hookListeners[hookName]

    if listeners then
        listeners[listenerName] = nil
    end

    hook.Remove( hookName, listenerName )
end

--[[
    - Creates a timer.
    - This should be used in place of all timer.Create() calls tied to specific event instances.
    - These will automatically be cleaned up when the event ends.
    - Note that the callback will still trigger even if the event hasn't started yet.
--]]
function eventBase:TimerCreate( timerName, interval, repetitions, callback )
    if type( timerName ) ~= "string" then error( "Expected timerName to be a string" ) end
    if type( interval ) ~= "number" then error( "Expected interval to be a number" ) end
    if type( repetitions ) ~= "number" then error( "Expected repetitions to be a number" ) end
    if type( callback ) ~= "function" then error( "Expected callback to be a function" ) end

    timerName = getListenerName( self, timerName )
    self._timers[timerName] = true
    timer.Create( timerName, interval, repetitions, callback )
end

function eventBase:TimerRemove( timerName )
    if type( timerName ) ~= "string" then error( "Expected timerName to be a string" ) end

    timerName = getListenerName( self, timerName )
    self._timers[timerName] = nil
    timer.Remove( timerName )
end

function eventBase:TimerAdjust( timerName, delay, repetitions, callback )
    if type( timerName ) ~= "string" then error( "Expected timerName to be a string" ) end

    return timer.Adjust( getListenerName( self, timerName ), delay, repetitions, callback )
end

function eventBase:TimerExists( timerName )
    if type( timerName ) ~= "string" then error( "Expected timerName to be a string" ) end

    return timer.Exists( getListenerName( self, timerName ) )
end

--[[
    - Tells clients to run a method on the event instance with the given arguments.
    - Does nothing on CLIENT.
--]]
function eventBase:BroadcastMethod( methodName, ... )
    if CLIENT then return end

    net.Start( "GEF_EventMethod" )
    net.WriteUInt( self:GetID(), 32 )
    net.WriteString( methodName )
    net.WriteTable( { ... } )
    net.Broadcast()
end

-- Adds a player, returning true if successful and they weren't already in the event, nil otherwise.
function eventBase:AddPlayer( ply )
    if self:HasPlayer( ply ) then return end
    if not IsValid( ply ) or not ply:IsPlayer() then error( "Expected ply to be a valid player" ) end

    table.insert( self._players, ply )
    self._playerLookup[ply] = true

    self:OnPlayerAdded( ply )
    self:BroadcastMethod( "AddPlayer", ply )

    return true
end

-- Removes a player, returning true if successful and they were in the event, nil otherwise.
function eventBase:RemovePlayer( ply )
    if not self:HasPlayer( ply ) then return end
    if not IsValid( ply ) or not ply:IsPlayer() then error( "Expected ply to be a valid player" ) end

    table.RemoveByValue( self._players, ply )
    self._playerLookup[ply] = nil

    self:OnPlayerRemoved( ply )
    self:BroadcastMethod( "RemovePlayer", ply )

    return true
end

function eventBase:HasPlayer( ply )
    if not ply then return end

    return self._playerLookup[ply] ~= nil
end

function eventBase:LacksPlayer( ply )
    if not ply then return true end

    return not self._playerLookup[ply]
end

function eventBase:GetPlayers()
    return self._players
end

function eventBase:IsSigningUp()
    return self._signingUp
end

function eventBase:GetPrintName()
    return self.PrintName
end

function eventBase:GetDescription()
    return self.Description
end

function eventBase:GetInternalName()
    return self._name
end

function eventBase:GetInstanceName()
    return self:GetInternalName() .. "_" .. self:GetID()
end

function eventBase:GetID()
    return self._id
end

function eventBase:IsValid()
    return true
end


if SERVER then
    --[[
        - Begins a simple signup process for players to join an event.
        - Once the time is up, the event will automatically start.

        duration: (optional) (number)
            - How long the signup process should last for.
            - Defaults to self.SignupDuration.
        excludedPlayers: (optional) (Player or table of Players)
            - Players who should not be allowed to join the event.
            - Defaults to nil (no players are excluded).
    --]]
    function eventBase:StartSimpleSignup( duration, excludedPlayers )
        GEF.Signup.StartSimple( self, duration, excludedPlayers )
    end
else
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
end

-- Called when the event starts.
function eventBase:OnStarted()
end

--[[
    - Called when the event ends.
    - After this finishes, the event instance is no longer valid.
--]]
function eventBase:OnEnded()
end

-- Called when a player is added to the event.
function eventBase:OnPlayerAdded( _ply )
end

-- Called when a player is removed from the event.
function eventBase:OnPlayerRemoved( _ply )
end


----- PRIVATE FUNCTIONS -----

getListenerName = function( event, name )
    return name .. "_" .. event:GetInstanceName()
end

cleanupEvent = function( event )
    for hookName, listeners in pairs( event._hookListeners ) do
        for listenerName in pairs( listeners ) do
            hook.Remove( hookName, listenerName )
        end
    end

    for timerName in pairs( event._timers ) do
        timer.Remove( timerName )
    end

    table.Empty( event )

    setmetatable( event, {
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
