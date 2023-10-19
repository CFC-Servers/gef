--- @class GEF_Airstrike
local AirstrikeClass = {}

--- @class AirstrikeMissile
--- @field ent Entity
--- @field target? Entity
--- @field targetPos Vector? Fallback pos in case the target dies
--- @field ang number
--- @field angSpeed number
--- @field forwardSpeed number
--- @field wobble number
--- @field _wobbleVec Vector Internal use, optimization
--- @field randomness number
--- @field reversed boolean
--- @field spawned boolean

--- Tracking table for the current missiles
--- @type table<AirstrikeMissile>
AirstrikeClass.Missiles = {}

--- Gets the initial spawn position for a missile
--- @param target Entity
--- @param ceiling number
--- @param origins table<Entity>
local function getSpawnPos( target, ceiling, origins )
    local originCount = #origins
    if originCount > 0 then
        local origin = origins[math.random( originCount )]
        if origin:IsValid() then
            return origin:GetPos()
        end
    end

    local entPos = target:GetPos()
    local spawnPos = entPos + VectorRand( -3000, 3000 )
    spawnPos[3] = ceiling * math.Rand( 0.90, 0.98 )

    return spawnPos
end


--- Makes a new missile aimed at the given target
--- @param target Entity
function AirstrikeClass:MakeMissile( target )
    local ent = ents.Create( "rpg_missile" )
    ent.GEF_AntlionHive_AirstrikeMissile = true

    hook.Run( "GEF_AntlionHive_AirstrikeMissile", ent )

    local missile = {
        ent = ent,
        target = target,
        ang = 0,
        angSpeed = 0.005,
        -- forwardSpeed = math.Rand( 3500, 4250 ),
        forwardSpeed = math.Rand( 1350, 1850 ),
        wobble = math.Rand( 500, 1200 ),
        _wobbleVec = Vector( 0, 0, 0 ),
        randomness = math.random( 1, 5 ),
        reversed = math.random( 1, 2 ) == 1,
        spawned = false,
    }

    table.insert( self.Missiles, missile )
end

do
    local math_sin = math.sin
    local math_cos = math.cos
    local math_random = math.random
    local under = Vector( 0, 0, 300 )

    --- Think function for an individual missile
    --- @param struct AirstrikeMissile
    function AirstrikeClass:MissileThink( struct )
        local missile = struct.ent
        if not struct.spawned then return end

        local targetPos
        local targetEnt = struct.target

        -- If the target is valid, use its position
        -- If it's not, set it to nil so we use the last saved targetPos
        if targetEnt then
            if targetEnt:IsValid() then
                targetPos = targetEnt:GetPos() - under
                struct.targetPos = targetPos
            else
                struct.target = nil
                targetEnt = nil
            end
        end

        if not targetEnt then
            targetPos = struct.targetPos
        end

        local wobble = struct.wobble
        local wobbleVec = struct._wobbleVec
        local randomness = struct.randomness
        local forwardSpeed = struct.forwardSpeed

        local direction = (targetPos - missile:GetPos()):GetNormalized()

        local ang = struct.ang
        local reversed = struct.reversed
        local wobbleX = wobble * (reversed and math_cos( ang ) or math_sin( ang ))
        local wobbleY = wobble * (reversed and math_sin( ang ) or math_cos( ang ))
        local randomWobbleX = wobbleX + math_random() * randomness - randomness / 2
        local randomWobbleY = wobbleY + math_random() * randomness - randomness / 2

        wobbleVec:SetUnpacked( randomWobbleX, randomWobbleY, 0 )
        local newDirection = direction * forwardSpeed + wobbleVec

        -- Set the actual velocity
        missile:SetSaveValue( "m_vecAbsVelocity", newDirection )

        -- Change the visual angle of the missile
        missile:SetAngles( newDirection:Angle() )

        -- Update the angle for the next iteration
        struct.ang = ang + struct.angSpeed
    end
end

function AirstrikeClass:Think()
    local missiles = self.Missiles
    local missileCount = #missiles

    local deadCount = 0

    for i = 1, missileCount do
        local struct = missiles[i]
        local missile = struct.ent

        if missile:IsValid() then
            self:MissileThink( struct )
        else
            deadCount = deadCount + 1
        end
    end

    if deadCount == missileCount then
        return false
    end

    return true
end

--- Launches a new airstrike at the targets
--- @param targets table<Entity>
--- @param center Vector The center of the targets - used to determine how far up to spawn the missiles
--- @param count number? How many of the targets to shoot missiles at (if larger than the length of the table, multiple missiles will fire at the same target)
--- @param damage number? How much damage (and how much amplitude) the explosions have
--- @param scale number? The visual scale of the missiles
--- @param origins table<Entity>? A table of Entities for the missiles to originate from
function AirstrikeClass:Start( targets, center, count, damage, scale, origins )
    local targetsCount = #targets
    assert( targetsCount > 0, "Why aren't there any entities to shoot?" )

    origins = origins or {}

    count = count or targetsCount

    local limit
    local selected

    if count < targetsCount then
        -- Select a randon set of targets to shoot missiles at
        selected = GEF.Utils.PickRandom( targets, count )
        limit = #selected
    elseif count == targetsCount then
        -- If we send 1 missile to each target, we can just loop over the targets
        selected = targets
        limit = targetsCount
    else
        -- If we want more missiles than we have objects,
        -- we use a circular table to keep looping over the same objects
        selected = GEF.Utils.CircularTable( targets )
        limit = count
    end

    local ceiling = GEF.Utils.GetCeiling( center )

    for i = 1, limit do
        local target = selected[i]
        self:MakeMissile( target )
    end

    -- With all the handlers in place, now we actually spawn the missiles
    local missiles = self.Missiles
    local missileCount = #self.Missiles

    local iteration = 0
    local iterations = math.min( missileCount, 20 )
    local perIteration = math.ceil( missileCount / iterations )

    -- We spawn them in up to 20 waves for a "bombardment" effect
    for t = 0, (iterations - 1) do
        local startIdx = (t * perIteration) + 1
        local stopIdx = math.min( missileCount, startIdx + perIteration - 1 )

        timer.Simple( t * 0.15, function()
            for i = startIdx, stopIdx do
                local missile = missiles[i]
                local ent = missile.ent

                ent:SetPos( getSpawnPos( missile.target, ceiling, origins ) )
                ent:Spawn()
                ent:SetSaveValue( "m_flDamage", damage or 100 )
                ent:SetSaveValue( "m_flModelScale", scale or 1 )
                ent:SetCollisionGroup( COLLISION_GROUP_WORLD )
                ent:Activate()

                -- gotta wait for the trail to exist..
                timer.Simple( 0.35, function()
                    local trail = ent:GetInternalVariable( "m_hRocketTrail" )
                    trail:SetSaveValue( "m_StartSize", 5 )
                    trail:SetSaveValue( "m_StartSize", 30 )
                    trail:SetSaveValue( "m_ParticleLifetime", 7 )
                    trail:SetSaveValue( "m_Opacity", 1 )
                    trail:SetSaveValue( "m_MaxSpeed", 7 )
                    trail:SetSaveValue( "m_SpawnRadius", 15 )
                    trail:SetSaveValue( "m_SpawnRate", 1024 )
                end )

                missile.spawned = true
            end
        end )

        iteration = iteration + 1
    end
end

function GEF.NewAirstriker()
    return setmetatable( {}, { __index = table.Copy( AirstrikeClass ) } )
end
