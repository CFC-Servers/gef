local math_random = math.random

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

EVENT.ActiveCars = {}

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
            local plyNormal = ( pos - origin ):GetNormalized()

            local mod = 1 - ( distance / maxDistance )
            local force = plyNormal * 1200 * mod
            force:Add( Vector( 0, 0, 750 * mod ) )

            v:SetVelocity( force )
        end
    end
end

do
    local VectorRand = VectorRand
    local defaultOffset = Vector( 0, 0, 2000 )

    -- TODO: Check the outer bounds of the model as well and make sure it won't get caught on walls
    --- Finds a valid path for a vehicle
    local function getPathSingle( tr, min, max )
        local offset = VectorRand( min, max )
        offset[3] = 0

        local carOrigin = origin + offset
        carOrigin.z = math_random( 1000, 2100 )

        local carDestination = origin - offset
        util.TraceLine( { start = carOrigin, endpos = carDestination - Vector( 0, 0, 10 ), collisiongroup = COLLISION_GROUP_WORLD, output = tr } )

        local hitPos = tr.HitPos
        if not tr.HitWorld then return false end
        if hitPos:Distance( carDestination ) > 100 then return false end
        if tr.HitNormal ~= originNormal then return false end

        return {
            origin = carOrigin,
            destination = carDestination,
        }
    end

    --- Attemps to find a valid path for a vehicle
    local function getPath()
        local tr = {}
        local min, max = -2000, 2000

        for _ = 1, 80 do
            local path = getPathSingle( tr, min, max )
            if path then return path end
        end

        ErrorNoHaltWithStack( "[GEF] [AstroScrappers] Failed to find a valid path for a vehicle!" )
        return { origin = origin + defaultOffset, destination = origin }
    end

    --- Given a car, find a path and set up its position
    --- @param car Entity
    function EVENT:PositionCar( car )
        local path = getPath()
        local carOrigin = path.origin
        local destination = path.destination

        local pathNormal = ( destination - carOrigin ):GetNormalized()
        car:SetPos( carOrigin )
        car:SetAngles( pathNormal:Angle() )

        self:SetEntVar( car, "pathNormal", pathNormal )
    end
end

--- Called once the car is fully settled after landing
--- @param car Entity
function EVENT:OnCarSettled( car )
    local maxDistance = 1200

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
    launchPlayersFrom( destination, maxDistance )

    -- Slight delay to make sure players are launched before the car is settled
    self:TimerSimple( 0.1, function()
        if not IsValid( car ) then return end
        car:SetCollisionGroup( COLLISION_GROUP_NONE )
    end )
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
            car:SetPos( hpos + ( sinkOffset * ratio ) )
        end )
    end
end

function EVENT:LaunchCar( car )
    if not IsValid( car ) then return end

    car:SetCollisionGroup( COLLISION_GROUP_WORLD )

    local phys = car:GetPhysicsObject()
    phys:SetMass( 999999 )

    -- Shoot it at the target
    phys:SetVelocityInstantaneous( pathNormal * math_random( 3000, 7500 ) * phys:GetMass() * 3 )

    -- Add some spin
    local angMomentum = VectorRand( -400, 400 )
    phys:AddAngleVelocity( angMomentum )

    -- Alert clients
    self:BroadcastMethodToPlayers( "DebugCarLines", carOrigin, destination, car )

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

    self:SetNW2Bool( car, "IsMeteor", true )
    table.insert( self.ActiveCars, car )

    -- TODO: Remove this timer and have cleanups done naturally
    timer.Simple( 20, function()
        if not IsValid( car ) then return end
        car:Remove()
    end )
end
