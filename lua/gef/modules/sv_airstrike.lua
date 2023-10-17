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

--- Minimum number of missiles to shoot
AirstrikeClass.MinMissiles = 10

--- Gets the initial spawn position for a missile
--- @param target Entity
--- @param ceiling number
local function getSpawnPos( target, ceiling )
    local entPos = target:GetPos()
    local spawnPos = entPos + VectorRand( -3000, 3000 )
    spawnPos[3] = ceiling * math.Rand( 0.90, 0.98 )

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
        forwardSpeed = math_Rand( 3500, 4250 ),
        wobble = math_Rand( 1800, 2850 ),
        _wobbleVec = Vector( 0, 0, 0 ),
        randomness = math.random( 7, 15 ),
        reversed = math.random( 1, 2 ) == 1,
        spawned = false,
    }

    table.insert( self.Missiles, missile )
end

do
    local math_sin = math.sin
    local math_cos = math.cos
    local math_random = math.random
    local under = Vector( 0, 0, 50 )

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

    if #missiles == 0 then
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
function AirstrikeClass:Start( targets, center, count, damage, scale )
    assert( #targets > 0, "Why aren't there any entities to shoot?" )

    count = count or #targets
    local selected = GEF.Utils.PickRandom( targets, count )
    local selectedCount = #selected

    -- If we want more missiles than we have objects,
    -- we use a circular table to keep looping over the same objects
    if selectedCount < count then
        selected = GEF.Utils.CircularTable( selected )
    end

    local ceiling = GEF.Utils.GetCeiling( center )

    for i = 1, count do
        local target = selected[i]
        self:MakeMissile( target, getSpawnPos( target, ceiling ) )
    end

    -- With all the handlers in place, now we actually spawn the missiles
    local missiles = self.Missiles
    local missileCount = #self.Missiles

    local iteration = 0
    local iterations = 20
    local perIteration = math.ceil( missileCount / iterations )

    -- We spawn them in up to 20 waves for a "bombardment" effect
    for t = 0, (iterations - 1) do
        local startIdx = (t * perIteration) + 1
        local stopIdx = math.min( missileCount, startIdx + perIteration - 1 )

        timer.Simple( t * 0.15, function()
            for i = startIdx, stopIdx do
                local missile = missiles[i]
                missile.ent:Spawn()
                missile.ent:SetSaveValue( "m_flDamage", damage or 100 )
                missile.ent:SetSaveValue( "m_flModelScale", scale or 1 )
                missile.spawned = true
            end
        end )

        iteration = iteration + 1
    end
end

function GEF.NewAirstriker()
    return setmetatable( {}, { __index = table.Copy( AirstrikeClass ) } )
end
