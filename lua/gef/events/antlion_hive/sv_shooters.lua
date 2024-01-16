local startAng = Angle( -90, 0, 0 )

--- @param count number How many positions to generate
--- @param ceiling Vector The maximum Z position in this area
local function getPositions( count, origin, radius, ceiling )
    local positions = {}

    for i = 1, count do
        local angle = (math.pi * 2) * (i / count)
        local x = math.cos( angle ) * radius
        local y = math.sin( angle ) * radius
        table.insert( positions, Vector( origin.x + x, origin.y + y, ceiling * 0.55 ) )
    end

    return positions
end

function EVENT:MakeShooter( pos, soundFilter )
    local shooter = self:EntCreate( "prop_physics" )
    shooter:SetPos( pos )
    shooter:SetAngles( startAng )
    shooter:SetModel( "models/props_combine/headcrabcannister01a.mdl" )
    shooter:Spawn()
    shooter:Activate()
    shooter:SetCollisionGroup( COLLISION_GROUP_WORLD )

    local trail = self:EntCreate( "prop_effect" )
    trail:SetPos( pos )
    trail:SetModel( "models/effects/portalfunnel.mdl" )
    trail:Spawn()
    trail:Activate()
    trail:SetParent( shooter )
    trail:SetCollisionGroup( COLLISION_GROUP_WORLD )

    shooter:DeleteOnRemove( trail )

    local snd = CreateSound( shooter, "ambient/alarms/citadel_alert_loop2.wav", soundFilter )

    snd:PlayEx( 0.15, 98 )
    snd:SetSoundLevel( 0 )
    snd:ChangeVolume( 1, 4 )

    shooter:CallOnRemove( "stop_sound", function()
        snd:Stop()
    end )

    local phys = shooter:GetPhysicsObject()
    if phys:IsValid() then
        phys:EnableMotion( false )
    else
        ErrorNoHaltWithStack( "Launcher doens't have phys object yet" )
    end

    self:OnlyTransmitToEvent( { shooter, trail } )

    return shooter
end

--- Spawns a number of shooters around the event area
--- @param count number
--- @param radius number
function EVENT:SpawnShooters( count, radius )
    local origin = self.Origin
    local ceiling = GEF.Utils.GetCeiling( origin )

    self.Shooters = {}
    local shooters = self.Shooters
    local positions = getPositions( count, origin, radius, ceiling )

    local soundFilter = RecipientFilter()
    for _, ply in ipairs( self:GetPlayers() ) do
        soundFilter:AddPlayer( ply )
    end

    local rawShooters = {}
    for i = 1, count do
        local shooter = self:MakeShooter( positions[i], soundFilter )
        local initialAngle = 2 * math.pi * i / count
        table.insert( shooters, {
            shooter = shooter,
            initialAngle = initialAngle,
            seed = math.random() * 20
        } )

        table.insert( rawShooters, shooter )
    end

    local math_pi = math.pi
    local math_sin = math.sin
    local math_cos = math.cos
    self:HookAdd( "Think", "ShooterMovement", function()
        local now = CurTime()
        local circleSpeed = 0.021
        local bobSpeed = 0.5
        local bobHeight = 400

        for i = 1, count do
            local struct = shooters[i]
            local seed = struct.seed
            local initialAngle = struct.initialAngle
            local shooter = struct.shooter

            -- Calculate new position
            local angle = ( now * circleSpeed * 2 * math_pi ) + initialAngle
            local bob = math_sin( (now + seed) * bobSpeed ) * bobHeight

            local x = origin.x + math_cos( angle ) * radius
            local y = origin.y + math_sin( angle ) * radius
            local z = ceiling + bob

            shooter:SetPos( Vector( x, y, z ) )
        end
    end )

    return rawShooters
end

function EVENT:DestroyShooters()
    for _, struct in ipairs( self.Shooters or {} ) do
        local shooter = struct.shooter
        if shooter:IsValid() then
            shooter:Remove()
        end
    end
end