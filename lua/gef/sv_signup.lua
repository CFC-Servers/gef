GEF.Signup = {}
GEF.Signup.UpcomingEvents = {}

local Signup = GEF.Signup
local UpcomingEvents = GEF.Signup.UpcomingEvents

local allowedPlyLookupByEvent = {}


--[[
    - Begins a simple signup process for players to join an event.
    - Once the time is up, the event will automatically start.

    duration: (optional) (number)
        - How long the signup process should last for.
        - Defaults to event.SignupDuration.
    excludedPlayers: (optional) (Player or table of Players)
        - Players who should not be allowed to join the event.
        - Defaults to nil (no players are excluded).
    showToExcludedPlayers: (optional) (bool)
        - Whether or not excluded players should see this in their signup list, while still being unable to join.
--]]
function Signup.StartSimple( event, duration, excludedPlayers, showToExcludedPlayers )
    if not IsValid( event ) or not event.IsGEFEvent then error( "Expected event to be a valid GEF Event" ) end
    if duration ~= nil and type( duration ) ~= "number" then error( "Expected duration to be a number or nil" ) end
    if event:IsSigningUp() then return end

    local plys = GEF.Utils.Exclude( player.GetAll(), excludedPlayers )
    duration = duration or event.SignupDuration or 60

    table.insert( UpcomingEvents, event )
    event._signingUp = true
    allowedPlyLookupByEvent[event] = GEF.Utils.MakeLookupTable( plys )

    event:TimerCreate( "GEF_Signup_AutoStartEvent", duration, 1, function()
        Signup.Stop( event, true )
        event:Start()
    end )

    net.Start( "GEF_StartSignup" )
    net.WriteUInt( event:GetID(), 32 )
    net.WriteFloat( duration )
    net.WriteTable( plys )

    if showToExcludedPlayers then
        net.Broadcast()
    else
        net.Send( plys )
    end
end

--[[
    - Clears an event from the signup list.
    - Any players who were added while the event was signing up will remain in the event.
    - Pass hidePrint as true to hide the "signup cancelled" print.
--]]
function Signup.Stop( event, hidePrint )
    if not IsValid( event ) or not event.IsGEFEvent then error( "Expected event to be a valid GEF Event" ) end
    if not event:IsSigningUp() then return end

    table.RemoveByValue( UpcomingEvents, event )
    event._signingUp = false
    allowedPlyLookupByEvent[event] = nil
    event:TimerRemove( "GEF_Signup_AutoStartEvent" )

    net.Start( "GEF_EndSignup" )
    net.WriteUInt( event:GetID(), 32 )
    net.WriteBool( hidePrint == true )
    net.Broadcast()
end

--[[
    - Signs a player up to a listed event.
    - Returns false if the player couldn't be added, nil if they were already signed up, or true if they were added.
--]]
function Signup.SignUpPlayer( event, ply )
    if not IsValid( event ) or not event.IsGEFEvent then error( "Expected event to be a valid GEF Event" ) end
    if not event:IsSigningUp() then return false end
    if not IsValid( ply ) or not ply:IsPlayer() then error( "Expected ply to be a valid player" ) end
    if not allowedPlyLookupByEvent[event][ply] then return false end

    return event:AddPlayer( ply )
end

--[[
    - Unsigns a player from a listed event.
    - Returns false if the player couldn't be removed, nil if they weren't signed up, or true if they were removed.
--]]
function Signup.UnsignUpPlayer( event, ply )
    if not IsValid( event ) or not event.IsGEFEvent then error( "Expected event to be a valid GEF Event" ) end
    if not event:IsSigningUp() then return false end
    if not IsValid( ply ) or not ply:IsPlayer() then error( "Expected ply to be a valid player" ) end

    return event:RemovePlayer( ply )
end


----- SETUP -----

hook.Add( "GEF_EventEnded", "GEF_Signup_CancelListing", function( event )
    Signup.Stop( event, true )
end )

hook.Add( "PlayerSay", "GEF_Signup_SignUpViaChat", function( ply, msg )
    if msg ~= "!join" then return end

    -- TODO: Handle cases where more than one event is signing up at a time.
    -- TODO: Handle leaving the event.

    local event = UpcomingEvents[1]

    if not IsValid( event ) then
        ply:ChatPrint( "There are no events currently signing up." )

        return ""
    end

    local result = Signup.SignUpPlayer( event, ply )

    if result == true then
        ply:ChatPrint( "You have signed up for the event!" )
    elseif result == false then
        ply:ChatPrint( "You are not allowed to sign up for this event." )
    else -- nil
        ply:ChatPrint( "You are already signed up for this event." )
    end

    return ""
end )

net.Receive( "GEF_SignupRequest", function( _, ply )
    local id = net.ReadUInt( 32 )
    local event = GEF.ActiveEventsByID[id]
    if not IsValid( event ) then return end

    if net.ReadBool() then
        Signup.SignUpPlayer( event, ply )
    else
        Signup.UnsignUpPlayer( event, ply )
    end
end )
