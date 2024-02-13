local IsValid = IsValid
local math_random = math.random

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

        -- Slight delay to make sure players are launched before the car is settled
        self:TimerSimple( 0.1, function()
            if not IsValid( car ) then return end
            car:SetCollisionGroup( COLLISION_GROUP_NONE )
        end )
    end
end

do
    local VectorRand = VectorRand
    local COLLISION_GROUP_WORLD = COLLISION_GROUP_WORLD

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
