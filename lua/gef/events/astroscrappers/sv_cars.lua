local IsValid = IsValid
local VectorRand = VectorRand
local math_random = math.random
local COLLISION_GROUP_WORLD = COLLISION_GROUP_WORLD

do
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
        tr = tr or {}

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

do
    local AngleRand = AngleRand
    local verticalOffset = Vector( 0, 0, 0 )

    --- Explodes scrap from an origin
    --- @param pos Vector
    function EVENT:LaunchScrapFrom( pos )
        local count = math_random( 1, 6 )
        local scrapModels = self.ScrapModels

        for _ = 1, count do
            local scrap = self:EntCreate( "prop_physics" )
            scrap:SetModel( scrapModels[math_random( 1, #scrapModels )] )

            local offset = VectorRand( -1, 1 )

            scrap:SetPos( pos + offset * 50 )
            scrap:SetAngles( AngleRand() )
            scrap:Spawn()
            scrap:Activate()

            verticalOffset:SetUnpacked( 0, 0, math_random( 300, 1400 ) )

            local phys = scrap:GetPhysicsObject()
            phys:SetMass( 250 )
            phys:SetVelocityInstantaneous( offset * math_random( 300, 1400 ) + verticalOffset )

            local angMomentum = VectorRand( -400, 400 )
            phys:AddAngleVelocity( angMomentum )

            self:SetEntVar( scrap, "IsScrap", true )

            -- local decayAverage = self.CarSpawnInterval * 2
            local decayAverage = 5
            local minDecay = decayAverage * 0.75
            local maxDecay = decayAverage * 1.25
            local decayTime = math_random( minDecay, maxDecay )

            self:TimerCreate( "ScrapTimeout_" .. scrap:GetCreationID(), decayTime, 1, function()
                if not self:IsValid() then return end
                if not IsValid( scrap ) then return end
                print( "Decaying scrap", self, scrap )
                self:DissolveEnt( scrap )
            end )
        end
    end
end

do
    local EffectData = EffectData
    local COLLISION_GROUP_NONE = COLLISION_GROUP_NONE

    --- Called once the car is fully settled after landing
    --- @param car Entity
    function EVENT:OnCarSettled( car )
        local maxDistance = 900
        local destination = self:GetEntVar( car, "destination" )

        local effectCount = 50
        local ed = EffectData()
        ed:SetOrigin( destination )
        ed:SetEntity( car )

        for i = 1, effectCount do
            local ratio = i / effectCount
            ed:SetScale( maxDistance * ratio )
            self:UtilEffect( "ThumperDust", ed )
        end

        self:UtilScreenshake( destination, 20, 40, 1, maxDistance, true )
        self:LaunchPlayersFrom( destination, maxDistance )
        self:LaunchScrapFrom( destination )

        -- Slight delay to make sure players are launched before the car is settled
        self:TimerSimple( 0.1, function()
            if not IsValid( car ) then return end
            car:SetCollisionGroup( COLLISION_GROUP_NONE )
        end )
    end
end

function EVENT:LaunchCar( car )
    if not IsValid( car ) then return end

    car:SetCollisionGroup( COLLISION_GROUP_WORLD )

    local phys = car:GetPhysicsObject()
    phys:SetMass( 999999 )

    -- Shoot it at the target
    local pathNormal = self:GetEntVar( car, "pathNormal" )
    phys:SetVelocityInstantaneous( pathNormal * math_random( 3000, 7500 ) * phys:GetMass() * 3 )

    -- Add some spin
    local angMomentum = VectorRand( -400, 400 )
    phys:AddAngleVelocity( angMomentum )

    -- Alert clients
    local carOrigin = self:GetEntVar( car, "origin" )
    local destination = self:GetEntVar( car, "destination" )
    self:BroadcastMethodToPlayers( "DebugCarLines", carOrigin, destination )

    phys:EnableGravity( false )
end

--- @param car Entity
function EVENT:SetupOnCollide( car )
    local id

    id = self:AddEntCallback( car, "PhysicsCollide", function( _, data )
        local hitEnt = data.HitEntity
        if not hitEnt:IsWorld() then return end
        data.PhysObject:EnableMotion( false )

        self:HandleCarLanding( car )
        self:RemoveEntCallback( car, "PhysicsCollide", id )
    end )
end

function EVENT:SpawnCar()
    local models = self.CarModels

    local isBig = math_random( 1, 10 ) == 1
    local modelSet = isBig and models.big or models.small
    local model = modelSet[math_random( 1, #modelSet )]

    local car = self:EntCreate( "prop_physics" )
    car:SetModel( model )

    self:PositionCar( car )
    self:SetupOnCollide( car )

    car:Spawn()
    car:Activate()
    self:LaunchCar( car )

    self:SetNW2Bool( car, "IsScrap", true )
    self:SetNW2Int( car, "PuntsRequired", isBig and self.PuntsRequiredBig or self.PuntsRequiredSmall )
end

--- @param car Entity
function EVENT:HandleCarLanding( car )
    local pathNormal = self:GetEntVar( car, "pathNormal" )

    local carRadius = car:GetModelRadius()
    local sinkDepth = 20 + carRadius * 0.5
    local sinkOffset = pathNormal * sinkDepth

    local steps = 8
    local duration = 0.15
    local hpos = car:GetPos()
    for i = 1, steps do
        local ratio = i / steps

        self:TimerSimple( duration * ratio, function()
            if not IsValid( car ) then return end
            car:SetPos( hpos + (sinkOffset * ratio) )
        end )
    end

    self:TimerSimple( duration, function()
        if not IsValid( car ) then return end
        self:OnCarSettled( car )
    end )
end

--- Initializes the AstroScrappers Cars module
function EVENT:SetupCarsModule()
    --- @param ent Entity
    local function resetTimer( ent )
        if self:GetEntVar( ent, "IsScrap" ) then
            self:TimerStart( "ScrapTimeout_" .. ent:GetCreationID() )
        end
    end

    self:HookAdd( "GravGunOnPickedUp", "ResetScrapTimers", resetTimer )
    self:HookAdd( "GravGunPunt", "ResetScrapTimers", resetTimer )
end

EVENT.CarModels = {
    small = {
        "models/props_vehicles/van001a_physics.mdl",
        "models/props_vehicles/truck003a.mdl",
        "models/props_vehicles/truck002a_cab.mdl",
        "models/props_vehicles/truck001a.mdl",
        "models/props_vehicles/car005b_physics.mdl",
        "models/props_vehicles/car005a_physics.mdl",
        "models/props_vehicles/car004b_physics.mdl",
        "models/props_vehicles/car004a_physics.mdl",
        "models/props_vehicles/car003b_physics.mdl",
        "models/props_vehicles/car003a_physics.mdl",
        "models/props_vehicles/car002b_physics.mdl",
        "models/props_vehicles/car001a_hatchback.mdl",
        "models/props_vehicles/car001a_phy.mdl",
        "models/props_vehicles/car001b_hatchback.mdl",
        "models/props_vehicles/car001b_phy.mdl",
        "models/props_vehicles/car002a_physics.mdl",
    },
    big = {
        "models/props_vehicles/tanker001a.mdl",
        "models/props_vehicles/apc001.mdl",
        "models/props_trainstation/train001.mdl",
        "models/props_trainstation/train002.mdl",
        "models/props_trainstation/train003.mdl",
        "models/props_combine/CombineTrain01a.mdl",
        "models/props_combine/combine_train02b.mdl",
        "models/props_combine/combine_train02a.mdl",
    }
}

EVENT.ScrapModels = {
    "models/props_borealis/mooring_cleat01.mdl",
    "models/props_borealis/door_wheel001a.mdl",
    "models/props_c17/canister01a.mdl",
    "models/props_c17/metalladder002b.mdl",
    "models/props_c17/TrapPropeller_Blade.mdl",
    "models/props_debris/metal_panel01a.mdl",
    "models/props_debris/metal_panel02a.mdl",
    "models/props_docks/channelmarker_gib01.mdl",
    "models/props_docks/channelmarker_gib03.mdl",
    "models/props_junk/meathook001a.mdl",
    "models/props_junk/MetalBucket01a.mdl",
    "models/props_junk/MetalBucket02a.mdl",
    "models/props_junk/metalgascan.mdl",
    "models/props_junk/PropaneCanister001a.mdl",
    "models/props_trainstation/TrackSign08.mdl",
    "models/props_c17/chair_office01a.mdl",
    "models/props_c17/tools_wrench01a.mdl",
    "models/props_c17/TrapPropeller_Engine.mdl",
    "models/props_c17/TrapPropeller_Lever.mdl",
    "models/props_junk/Wheebarrow01a.mdl",
    "models/props_vehicles/carparts_axel01a.mdl",
    "models/props_vehicles/carparts_door01a.mdl",
    "models/props_vehicles/carparts_muffler01a.mdl",
    "models/props_vehicles/carparts_tire01a.mdl",
    "models/props_vehicles/carparts_wheel01a.mdl",
    "models/props_wasteland/gear01.mdl",
    "models/props_wasteland/gear02.mdl",
    "models/props_wasteland/buoy01.mdl",
    "models/props_junk/iBeam01a.mdl",
    "models/props_trainstation/TrackSign01.mdl",
    "models/props_wasteland/light_spotlight01_lamp.mdl",
    "models/props_wasteland/light_spotlight02_lamp.mdl",
}
