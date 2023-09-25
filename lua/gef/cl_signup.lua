--- @class GEF_CL_Signup
GEF.Signup = {}
GEF.Signup.UpcomingEvents = {}

--- @class GEF_CL_Signup
local Signup = GEF.Signup
local UpcomingEvents = GEF.Signup.UpcomingEvents

--local signupPanel = nil -- TODO: There should be a signup panel that lists multiple events if more than one is upcoming.
local allowedPlyLookupByEvent = {}

-- Tries to sign up LocalPlayer to the event.
-- Returns false if the player couldn't be added, nil if they were already signed up, or true if they were added.
-- Note that client-only events have string IDs, and thus will intentionally error if used here.
function Signup.SignUpTo( event )
    if not IsValid( event ) or not event.IsGEFEvent then error( "Expected event to be a valid GEF Event" ) end
    if not event:IsSigningUp() then return false end
    if event:HasPlayer( LocalPlayer() ) then return end
    if not allowedPlyLookupByEvent[event][LocalPlayer()] then return end

    net.Start( "GEF_SignupRequest" )
    net.WriteUInt( event:GetID(), 32 )
    net.WriteBool( true )
    net.SendToServer()

    return true
end

--- Tries to remove LocalPlayer from the event.
--- Returns false if the player couldn't be removed, nil if they weren't signed up, or true if they were removed.
--- @return boolean | nil
function Signup.UnsignUpFrom( event )
    if not IsValid( event ) or not event.IsGEFEvent then error( "Expected event to be a valid GEF Event" ) end
    if not event:IsSigningUp() then return false end
    if not event:HasPlayer( LocalPlayer() ) then return end

    net.Start( "GEF_SignupRequest" )
    net.WriteUInt( event:GetID(), 32 )
    net.WriteBool( false )
    net.SendToServer()

    return true
end


--- Starts the signup process for the given Event
--- @param event GEF_Event
--- @param duration number
--- @param allowedPlys table<Player>
--- @return nil
local startSignup = function( event, duration, allowedPlys )
    if event:IsSigningUp() then return end

    local allowedPlyLookup = GEF.Utils.MakeLookupTable( allowedPlys )

    event._signingUp = true
    allowedPlyLookupByEvent[event] = allowedPlyLookup
    table.insert( UpcomingEvents, event )

    -- TEMP MESSAGE (TODO: Make better, account for disallowed events, add util for time formatting)
    LocalPlayer():ChatPrint( event:GetPrintName() .. " is starting in " .. duration .. " seconds! Type !join to join the event!" )

    -- TODO: vgui panel stuff (should make use of allowedPlys for showing a player list and allowedPlyLookup for greying out disallowed events)
end

--- @return nil
local stopSignup = function( event, hidePrint )
    if not event:IsSigningUp() then return end

    event._signingUp = false
    allowedPlyLookupByEvent[event] = nil
    table.RemoveByValue( UpcomingEvents, event )

    if hidePrint then return end

    -- TEMP MESSAGE
    LocalPlayer():ChatPrint( event:GetPrintName() .. " can no longer be signed up to!" )
end

hook.Add( "GEF_EventEnded", "GEF_Signup_CancelSignup", function( event )
    stopSignup( event, true )
end )

net.Receive( "GEF_StartSignup", function()
    local event = GEF.ActiveEventsByID[net.ReadUInt( 32 )]
    if not event then return end

    local duration = net.ReadFloat()
    local plys = net.ReadTable()

    startSignup( event, duration, plys )
end )

net.Receive( "GEF_StopSignup", function()
    local event = GEF.ActiveEventsByID[net.ReadUInt( 32 )]
    if not event then return end

    stopSignup( event, net.ReadBool() )
end )




