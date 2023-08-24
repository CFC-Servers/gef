GEF.EventBase = {}

local eventBase = GEF.EventBase
eventBase.Name = "Base Event"
eventBase.Description = "This is the base event. It does nothing."
eventBase.ID = "base"
eventBase.Players = {}
eventBase.isActive = false
eventBase._EventHooks = {}
eventBase.__index = eventBase

-- EventBase
function eventBase:Initialize()
end

function eventBase:Start()
end

function eventBase:End()
end

function eventBase:AddHook( hookName, callback )
    self._EventHooks[hookName] = callback

    hook.Add( hookName, "GEF_EVENTHOOK_" .. self.ID, function( ... )
        return callback( self, ... )
    end )
end

function eventBase:RemoveHook( hookName )
    self._EventHooks[hookName] = nil
    hook.Remove( hookName, "GEF_EVENTHOOK_" .. self.ID )
end

function eventBase:RemoveAllHooks()
    for hookName in pairs( self._EventHooks ) do
        self:RemoveHook( hookName )
    end
end

function eventBase:Cleanup()
    self:RemoveAllHooks()
    self.IsActive = false
    self.Players = {}
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
