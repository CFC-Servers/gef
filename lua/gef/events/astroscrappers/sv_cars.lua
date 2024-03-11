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

    --- Create a Car, ready to be thrown
    --- @param model string
    function EVENT:CreateCar( model )
        local path = getPath( self.Origin )
        local carOrigin = path.origin
        local destination = path.destination
        local pathNormal = (destination - carOrigin):GetNormalized()
        local pathAngle = pathNormal:Angle()

        local car = self:EntCreate( "prop_physics" )
        car:SetModel( model )
        car:SetPos( carOrigin )
        car:SetAngles( pathAngle )
        car:SetCollisionGroup( COLLISION_GROUP_IN_VEHICLE )
        car:Spawn()
        car:Activate()

        local collider = self:EntCreate( "prop_physics" )
        collider:SetModel( "models/hunter/misc/sphere025x025.mdl" )
        collider:SetNoDraw( true )
        collider:SetPos( car:WorldSpaceCenter() )
        collider:SetAngles( pathAngle )
        collider:Spawn()
        collider:Activate()

        car:SetParent( collider )

        local colliderPhys = collider:GetPhysicsObject()
        colliderPhys:SetMass( 99999 )
        colliderPhys:EnableDrag( false )
        colliderPhys:EnableGravity( false )

        self:SetEntVar( car, "origin", origin )
        self:SetEntVar( car, "pathNormal", pathNormal )
        self:SetEntVar( car, "destination", destination )
        self:SetEntVar( collider, "car", car )

        return car, collider
    end
end

do
    local AngleRand = AngleRand
    local verticalOffset = Vector( 0, 0, 0 )

    --- Explodes scrap from an origin
    --- @param pos Vector
    function EVENT:LaunchScrapPiecesFrom( pos )
        local count = math_random( 2, 12 )
        local scrapModels = self.ScrapModels

        for _ = 1, count do
            local piece = self:EntCreate( "prop_physics" )
            piece:SetModel( scrapModels[math_random( 1, #scrapModels )] )

            local offset = VectorRand( -1, 1 )

            piece:SetPos( pos + offset * 100 )
            piece:SetAngles( AngleRand() )
            piece:Spawn()
            piece:Activate()

            local radius = piece:GetModelRadius()
            verticalOffset:SetUnpacked( 0, 0, math_random( radius, radius * 2 ) )

            local phys = piece:GetPhysicsObject()
            phys:SetMass( math_random( 100, 250 ) )
            phys:SetVelocityInstantaneous( offset * math_random( 300, 1400 ) + verticalOffset )

            local angMomentum = VectorRand( -400, 400 )
            phys:AddAngleVelocity( angMomentum )

            self:SetEntVar( piece, "IsScrapPiece", true )

            local decayAverage = self.CarSpawnInterval * 5
            local minDecay = decayAverage
            local maxDecay = decayAverage * 1.5
            local decayTime = math_random( minDecay, maxDecay )

            self:TimerCreate( "ScrapTimeout_" .. piece:GetCreationID(), decayTime, 1, function()
                if not self:IsValid() then return end
                if not IsValid( piece ) then return end
                self:DissolveEnt( piece )
            end )
        end
    end
end

do
    local EffectData = EffectData

    --- Called once the car is fully settled after landing
    --- @param car Entity
    function EVENT:OnCarSettled( car )
        local maxDistance = 900
        local destination = self:GetEntVar( car, "destination" )

        local effectCount = 15
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
        self:LaunchScrapPiecesFrom( destination )
    end
end

function EVENT:LaunchCar( collider )
    if not IsValid( collider ) then return end
    local car = self:GetEntVar( collider, "car" )

    -- Shoot it at the target
    local pathNormal = self:GetEntVar( car, "pathNormal" )
    local phys = collider:GetPhysicsObject()
    phys:SetVelocityInstantaneous( pathNormal * math_random( 3000, 7500 ) * phys:GetMass() * 3 )

    -- Add some spin
    local angMomentum = VectorRand( -100, 100 )
    phys:AddAngleVelocity( angMomentum )
end

--- @param collider Entity
function EVENT:SetupOnCollide( collider )
    local id

    id = self:AddEntCallback( collider, "PhysicsCollide", function( _, data )
        local hitEnt = data.HitEntity
        if not hitEnt:IsWorld() then return end
        self:RemoveEntCallback( collider, "PhysicsCollide", id )
        self:HandleCarLanding( collider, data.PhysObject )
    end )
end

function EVENT:SpawnCar()
    local models = self.CarModels

    local isBig = math_random( 1, 10 ) == 1
    local modelSet = isBig and models.big or models.small
    local model = modelSet[math_random( 1, #modelSet )]

    local car, collider = self:CreateCar( model )
    self:SetupOnCollide( collider )
    self:LaunchCar( collider )

    self:SetNW2Bool( car, "IsScrap", true )
    self:SetNW2Int( car, "PuntsRequired", isBig and self.PuntsRequiredBig or self.PuntsRequiredSmall )
end

--- @param collider Entity
function EVENT:HandleCarLanding( collider, colliderPhys )
    colliderPhys:EnableMotion( false )
    local pos = colliderPhys:GetPos()
    local angles = colliderPhys:GetAngles()

    -- Remove the car from the handler, freeze it, and delete the collider
    local car = self:GetEntVar( collider, "car" )
    local carPhys = car:GetPhysicsObject()
    carPhys:EnableMotion( false )

    timer.Simple( 0, function()
        car:SetParent( nil )
        car:SetPos( pos )
        car:SetAngles( angles )
        collider:Remove()

        self:OnCarSettled( car )
        car:SetCollisionGroup( COLLISION_GROUP_NONE )

        self:TimerCreate( "ScrapTimeout_" .. car:GetCreationID(), self.CarSpawnInterval * 7, 1, function()
            if not self:IsValid() then return end
            if not IsValid( car ) then return end
            self:DissolveEnt( car )
        end )
    end )
end

--- Initializes the AstroScrappers Cars module
function EVENT:SetupCarsModule()
    --- @param ent Entity
    local function resetTimer( _, ent )
        local isScrap = self:GetNW2Bool( ent, "IsScrap" )
        isScrap = isScrap or self:GetEntVar( ent, "IsScrapPiece" )

        if not isScrap then return end

        self:TimerStart( "ScrapTimeout_" .. ent:GetCreationID() )
    end

    self:HookAdd( "GravGunOnPickedUp", "ResetScrapTimers", resetTimer )
    self:HookAdd( "GravGunPunt", "ResetScrapTimers", resetTimer )

    self:HookAdd( "EntityTakeDamage", "ReducePhysicsDamage", function( ent, dmg )
        if not self:HasPlayer( ent ) then return end

        if dmg:IsDamageType( DMG_CRUSH ) then
            dmg:ScaleDamage( 0.075 )
        end
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
