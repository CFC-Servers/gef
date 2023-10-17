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

--- Tracking table for the current missiles
--- @type table<AirstrikeMissile>
AirstrikeClass.Missiles = {}

--- Minimum number of missiles to shoot
AirstrikeClass.MinMissiles = 10

--- Maximum number of missiles to shoot
AirstrikeClass.MaxMissiles = 40

--- Gets the initial spawn position for a missile
--- @param target Entity
--- @param ceiling number
local function getSpawnPos( target, ceiling )
    local entPos = target:GetPos()
    local spawnPos = entPos + VectorRand( -3000, 3000 )
    spawnPos[3] = ceiling * math.Rand( 0.85, 0.98 )

    return spawnPos
end

--- Makes a new missile aimed at the given target
--- @param target Entity
--- @param spawnPos Vector
function AirstrikeClass:MakeMissile( target, spawnPos )
    local math_Rand = math.Rand

    local ent = ents.Create( "rpg_missile" )
    ent:SetPos( spawnPos )
    ent.GEF_AntlionHive_AirstrikeMissile = true

    local missile = {
        ent = ent,
        target = target,
        ang = 0,
        angSpeed = 0.015,
        forwardSpeed = math_Rand( 1750, 4000 ),
        wobble = math_Rand( 1800, 2500 ),
        _wobbleVec = Vector( 0, 0, 0 ),
        randomness = math.random( 9, 13 ),
    }

    table.insert( self.Missiles, missile )
end

do
    local math_sin = math.sin
    local math_cos = math.cos
    local math_Rand = math.Rand
    local math_random = math.random
    local under = Vector( 0, 0, 50 )

    --- Think function for an individual missile
    --- @param struct AirstrikeMissile
    function AirstrikeClass:MissileThink( struct )
        local missile = struct.ent

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
        local wobbleX = wobble * math_sin( ang )
        local wobbleY = wobble * math_cos( ang )
        local randomWobbleX = wobbleX + math_random() * randomness - randomness / 2
        local randomWobbleY = wobbleY + math_random() * randomness - randomness / 2

        wobbleVec:SetUnpacked( randomWobbleX, randomWobbleY, 0 )
        local newDirection = direction * forwardSpeed + wobbleVec

        -- Set the actual velocity
        missile:SetSaveValue( "m_vecAbsVelocity", newDirection )

        -- Change the visual angle of the missile
        missile:SetAngles( newDirection:Angle() )

        -- Update the angle for the next iteration
        local mod = math_Rand( 0.85, 1 )
        struct.ang = ang + mod * struct.angSpeed
    end
end

function AirstrikeClass:Think()
    local table_insert = table.insert
    local table_remove = table.remove

    local missiles = self.Missiles
    local missileCount = #missiles

    local toRemove = {}

    for i = 1, missileCount do
        local struct = missiles[i]
        local missile = struct.ent

        if missile:IsValid() then
            self:MissileThink( struct )
        else
            table_insert( toRemove, i )
        end
    end

    -- Remove the ones that are gone
    for i = #toRemove, 1, -1 do
        table_remove( missiles, toRemove[i] )
    end
end

--- Launches a new airstrike at the targets
--- @param targets table<Entity>
--- @param center Vector The center of the targets - used to determine how far up to spawn the missiles
--- @param count number How many of the targets to shoot missiles at
function AirstrikeClass:Start( targets, center, count )
    assert( #targets > 0, "Why aren't there any entities to shoot?" )

    local selected = GEF.Utils.PickRandom( targets, count )
    local selectedCount = #selected

    local ceiling = GEF.Utils.GetCeiling( center )
    local limit = math.min( selectedCount, self.MaxMissiles )
    print( "Creating: ", limit, "airstrike missiles" )

    for i = 1, limit do
        local target = selected[i]
        self:MakeMissile( target, getSpawnPos( target, ceiling ) )
    end

    -- With all the handlers in place, now we actually spawn the missiles
    print( "SV: Spawning missiles" )
    local missiles = self.Missiles
    local missileCount = #self.Missiles
    for i = 1, missileCount do
        local missile = missiles[i]
        missile.ent:Spawn()
        missile.ent:SetSaveValue( "m_flDamage", 800 )
        missile.ent:SetSaveValue( "m_flModelScale", 3.5 )
    end
end

function GEF.NewAirstriker()
    return setmetatable( {}, { __index = table.Copy( AirstrikeClass ) } )
end
