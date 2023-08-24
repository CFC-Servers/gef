GEF.ActiveEvent = nil

function GEF.GetActiveEvent()
    return GEF.ActiveEvent or false
end

function GEF.StartEvent( eventName )
    local event = GEF.GetEvent( eventName )
    local active = table.Copy( event )

    GEF.ActiveEvent = active
    PrintTable( active )
    active:Initialize()
    active:BroadcastMethod( "Initialize" )
end

function GEF.StopActiveEvent()
    local event = GEF.ActiveEvent
    if not event then return end

    event:BroadcastMethod( "Cleanup" )
    event:Cleanup()
end

local activeSignup = false
function GEF.StartSignup( event )
    if activeSignup then return end

    PrintMessage( HUD_PRINTTALK, event.Name .. " has started! Type !join to join the event!" )

    activeSignup = true

    timer.Simple( event.SignupTime or 10, function()
        activeSignup = false
        PrintMessage( HUD_PRINTTALK, "Event signup has ended!" )
        event:Start()
        event:BroadcastMethod( "Start" )
    end )
end

hook.Add( "PlayerSay", "GEF.Signup", function( ply, text )
    if text ~= "!join" then return end

    if not activeSignup then
        ply:ChatPrint( "There is no active event signup!" )
        return ""
    end

    local event = GEF.GetActiveEvent()
    event.Players[ply] = true

    ply:ChatPrint( "You have joined the event!" )

    return ""
end )
