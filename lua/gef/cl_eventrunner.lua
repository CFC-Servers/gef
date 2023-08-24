GEF.ActiveEvent = nil
net.Receive( "GEF_EventLoad", function()
    local eventName = net.ReadString()
    local event = GEF.LoadEvent( eventName )

    GEF.ActiveEvent = event

    event:Initialize()
end )

net.Receive( "GEF_EventEnded", function()
    GEF.ActiveEvent:Cleanup()
    GEF.ActiveEvent = nil
end )
