do
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
end

do
    local VectorRand = VectorRand
    local math_random = math.random
    local COLLISION_GROUP_WORLD = COLLISION_GROUP_WORLD

    local originNormal = Vector( 0, 0, 1 )
    local traceEndOffset = Vector( 0, 0, -10 )
    local defaultOffset = Vector( 0, 0, 2000 )

    -- TODO: Check the outer bounds of the model as well and make sure it won't get caught on walls
    --- Finds a valid path for a vehicle
    --- @param origin Vector Event origin
    --- @param min number Minimum offset
    --- @param max number Maximum offset
    --- @param tr table? Empty table to hold trace result
    local function getPathSingle( origin, min, max, tr )
        local offset = VectorRand( min, max )
        offset[3] = 0

        local carOrigin = origin + offset
        carOrigin.z = math_random( 1000, 2100 )

        local carDestination = origin - offset
        util.TraceLine( { start = carOrigin, endpos = carDestination + traceEndOffset, collisiongroup = COLLISION_GROUP_WORLD, output = tr } )

        local hitPos = tr.HitPos
        if not tr.HitWorld then return false end
        if hitPos:Distance( carDestination ) > 100 then return false end
        if tr.HitNormal ~= originNormal then return false end

        return {
            origin = carOrigin,
            destination = carDestination,
        }
    end

    --- Attempts to find a valid path for a vehicle
    --- @param origin Vector
    local function getPath( origin )
        local tr = {}
        local min, max = -2000, 2000

        for _ = 1, 80 do
            local path = getPathSingle( origin, min, max, tr )
            if path then return path end
        end

        ErrorNoHaltWithStack( "[GEF] [AstroScrappers] Failed to find a valid path for a vehicle!" )
        return { origin = origin + defaultOffset, destination = origin }
    end

    --- Given a car, find a path and set up its position
    --- @param car Entity
    function EVENT:PositionCar( car )
        local path = getPath( self.Origin )
        local carOrigin = path.origin
        local destination = path.destination

        local pathNormal = (destination - carOrigin):GetNormalized()
        car:SetPos( carOrigin )
        car:SetAngles( pathNormal:Angle() )

        self:SetEntVar( car, "origin", origin )
        self:SetEntVar( car, "pathNormal", pathNormal )
        self:SetEntVar( car, "destination", destination )
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

    self:HookAdd( "GravGunPunt", "CheckPunt", function( ply, ent )
        return self:OnGravPunt( ply, ent )
    end )

    self:TimerCreate( "SpawnCars", self.CarSpawnInterval, 0, function()
        self:SpawnCar()
    end )
end

include( "sv_cars.lua" )

