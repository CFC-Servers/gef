local launchVector = Vector( 0, 0, 0 )

--- Launches all players within maxDistance of origin
--- @param origin Vector
--- @param maxDistance number
function EVENT:LaunchPlayersFrom( origin, maxDistance )
    local inRange = ents.FindInSphere( origin, maxDistance )
    local inRangeCount = #inRange

    for i = 1, inRangeCount do
        local v = inRange[i]
        if v:IsPlayer() then
            local pos = v:GetPos()
            local distance = pos:Distance( origin )
            local plyNormal = (pos - origin):GetNormalized()

            local mod = 1 - (distance / maxDistance)
            local force = plyNormal * 1200 * mod

            launchVector:SetUnpacked( 0, 0, 750 * mod )
            force:Add( launchVector )

            v:SetVelocity( force )
        end
    end
end

function EVENT:SetupCapturePoints()
    local size = self.CapturePointSize

    local mins = Vector( -size, -size, -size )
    local maxs = Vector( size, size, size )

    for _, pos in ipairs( self.CapturePoints ) do
        self:CreateArea( pos, mins, maxs, function( ent )
            if not ent:IsPlayer() then return end

            self:OnPlayerEnterCaptureZone( ent )
        end )
    end
end

function EVENT:OnStarted()
    GEF.Signup.Stop( self, true )

    self:SetupCapturePoints()
    self:SetupCarsModule()

    self:HookAdd( "GravGunPunt", "CheckPunt", function( ply, ent )
        return self:OnGravPunt( ply, ent )
    end )

    self:TimerCreate( "SpawnCars", self.CarSpawnInterval, 0, function()
        self:SpawnCar()
    end )
    self:SpawnCar()

    self:TimerCreate( "Stop", self.EventDuration, 1, function()
        self:End()
    end )
end

include( "sv_cars.lua" )

