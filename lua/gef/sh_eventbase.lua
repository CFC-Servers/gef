GEF.EventBase = {}
local eventBase = GEF.EventBase
eventBase.Name = "Base Event"
eventBase.Description = "This is the base event. It does nothing."
eventBase.ID = "base"
eventBase.Players = {}
eventBase.isActive = false
eventBase.__index = eventBase

-- EventBase
function eventBase:Initialize()
end

function eventBase:Start()
end

function eventBase:End()
end

if SERVER then
    function eventBase:BroadcastMethod( methodName, ... )
        net.Start( "GEF_EventMethod" )
        net.WriteString( self.ID )
        net.WriteString( methodName )
        net.WriteTable( { ... } )
        net.Broadcast()
    end

    function eventBase:StartSignup()
        GEF.StartSignup( self, self.SignupTime or 10 )
    end
end

if CLIENT then
    function eventBase:StartSignup()
    end

    net.Receive( "GEF_EventMethod", function()
        local eventID = net.ReadString()
        local methodName = net.ReadString()
        local args = net.ReadTable()

        local event = GEF.GetEvent( eventID )
        if event then
            local method = event[methodName]
            if method then
                method( event, unpack( args ) )
            end
        end
    end )
end
