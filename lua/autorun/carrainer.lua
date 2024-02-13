if SERVER then
    util.AddNetworkString( "carlines" )
    util.AddNetworkString( "carhit" )
    local carModels = {
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
    }

    local bigModels = {
        "models/props_vehicles/tanker001a.mdl",
        "models/props_vehicles/apc001.mdl",
        "models/props_trainstation/train001.mdl",
        "models/props_trainstation/train002.mdl",
        "models/props_trainstation/train003.mdl",
        "models/props_combine/CombineTrain01a.mdl",
        "models/props_combine/combine_train02b.mdl",
        "models/props_combine/combine_train02a.mdl",
    }

    if allCurrentCars then
        for _, v in ipairs( allCurrentCars ) do
            if IsValid( v ) then v:Remove() end
        end
    end

    allCurrentCars = {}

    local function launchPlayersFrom( origin, maxDistance )
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

    -- for bigcity
    local origin = Vector( -725.1123046875, -939.87512207031, -11139.96875 )
    local originNormal = Vector( 0, 0, 1 )

    -- TODO: Check the outer bounds of the model as well and make sure it won't get caught on walls
    local function getPathSingle( tr, min, max )
        local offset = VectorRand( min, max )
        offset[3] = 0

        local carOrigin = origin + offset
        carOrigin.z = math.random( 1000, 2100 )

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

    local function getPath()
        local tr = {}
        local min, max = -2000, 2000

        for _ = 1, 80 do
            local path = getPathSingle( tr, min, max )
            if path then return path end
        end

        print( "Warning! Failed to find a path" )
        return { origin = origin + Vector( 0, 0, 2000 ), destination = origin }
    end

    local function positionCar( car )
        local path = getPath()
        local carOrigin = path.origin
        local destination = path.destination

        local pathNormal = ( destination - carOrigin ):GetNormalized()
        car:SetPos( carOrigin )
        car:SetAngles( pathNormal:Angle() )

        car:AddCallback( "PhysicsCollide", function( _, data )
            local hitEnt = data.HitEntity
            if not hitEnt:IsWorld() then return end
            data.PhysObject:EnableMotion( false )

            local carRadius = car:GetModelRadius()
            local sinkDepth = 20 + carRadius * 0.5
            local sinkDestination = pathNormal * sinkDepth

            local steps = 8
            local duration = 0.15
            local hpos = car:GetPos()
            for i = 1, steps do
                local ratio = i / steps
                timer.Simple( duration * ratio, function()
                    car:SetPos( hpos + ( sinkDestination * ratio ) )
                end )
            end

            timer.Simple( duration, function()
                local maxDistance = 1200

                -- Hit the ground
                -- net.Start( "carhit" )
                -- net.WriteVector( destination )
                -- net.WriteEntity( car )
                -- net.Broadcast()

                local effectCount = 50
                local ed = EffectData()
                ed:SetOrigin( destination )
                ed:SetEntity( car )

                for i = 1, effectCount do
                    local ratio = i / effectCount
                    ed:SetScale( maxDistance * ratio )
                    util.Effect( "ThumperDust", ed )
                end

                util.ScreenShake( destination, 20, 40, 1, maxDistance, true )
                launchPlayersFrom( destination, maxDistance )

                timer.Simple( 0.1, function()
                    if not IsValid( car ) then return end
                    car:SetCollisionGroup( COLLISION_GROUP_NONE )
                end )
            end )

        end )

        timer.Simple( 0.2, function()
            if not IsValid( car ) then return end

            car:SetCollisionGroup( COLLISION_GROUP_WORLD )

            local phys = car:GetPhysicsObject()
            phys:SetMass( 999999 )

            -- Shoot it at the target
            phys:SetVelocityInstantaneous( pathNormal * math.random( 3000, 7500 ) * phys:GetMass() * 3 )

            -- Add some spin
            local angMomentum = VectorRand( -400, 400 )
            phys:AddAngleVelocity( angMomentum )

            -- Alert clients
            net.Start( "carlines" )
            net.WriteVector( carOrigin )
            net.WriteVector( destination )
            net.WriteEntity( car )
            net.Broadcast()

            phys:EnableGravity( false )
        end )
    end


    local function spawnCar()
        local isBig = math.random( 1, 10 ) == 1
        local modelSet = isBig and bigModels or carModels
        local model = modelSet[math.random( 1, #modelSet )]

        local meteor = ents.Create( "prop_physics" )
        meteor:SetModel( model )
        positionCar( meteor )
        meteor:Spawn()
        meteor:Activate()

        table.insert( allCurrentCars, meteor )

        timer.Simple( 20, function()
            if not IsValid( meteor ) then return end
            meteor:Remove()
        end )
    end

    timer.Create( "spawner", 5, 30, spawnCar )
end

if CLIENT then
    net.Receive( "carlines", function()
        debugoverlay.Line( net.ReadVector(), net.ReadVector(), 4, color_white, false )
    end )

    net.Receive( "carhit", function()
    end )
end
