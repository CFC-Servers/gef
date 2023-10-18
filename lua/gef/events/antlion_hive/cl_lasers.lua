local pendingLasers = {}
local enabledLasers = {}

--- @class GEF_Antlion_Laser
--- @field origin Entity
--- @field target Entity
--- @field lastTargetPos Vector

--- @param finishLockingIn number How many seconds until we should be fully locked 
function EVENT:StartLasers( finishLockingIn )
    print( "Starting lasers" )
    local smoothing = 0.25
    local maxDelay = finishLockingIn / #pendingLasers

    local function enableNext()
        local laser = table.remove( pendingLasers )
        if not laser then
            print( "Done enabling all lasers" )
            return
        end

        table.insert( enabledLasers, laser )

        local delay = math.Rand( 0, maxDelay )
        self:TimerAdjust( "LaserEnabler", delay, 1, enableNext )
        self:TimerStart( "LaserEnabler" )
    end

    self:TimerCreate( "LaserEnabler", 0, 1, enableNext )

    local red = Color( 255, 0, 0, 200 )
    local LerpVector = LerpVector
    local render_DrawBeam = render.DrawBeam
    local render_SetMaterial = render.SetMaterial
    local laserMat = Material( "cable/redlaser" )

    self:HookAdd( "PostDrawTranslucentRenderables", "DrawLasers", function( _, _, skybox3d )
        if skybox3d then return end

        local enabledCount = #enabledLasers
        for i = 1, enabledCount do
            local laser = enabledLasers[i]

            local origin = laser.origin
            local target = laser.target
            local lastTargetPos = laser.lastTargetPos

            --- This is where we're supposed to be
            local correctPos = target:IsValid() and target:GetPos()
            local endPos = correctPos

            -- If we're not already on-target, then we lerp our way over there
            if correctPos ~= lastTargetPos then
                endPos:Set( LerpVector( smoothing, lastTargetPos, endPos ) )
            end

            -- Keep track of this new position so we can lerp against it next iteration
            lastTargetPos:Set( endPos )

            render_SetMaterial( laserMat )
            render_DrawBeam( origin:GetPos(), endPos, 2, 0, 12.5, red )
        end
    end )
end

function EVENT:StopLasers()
    table.Empty( enabledLasers )
    table.Empty( pendingLasers )
end

function EVENT:AddLaserGroup( group, targets )
    print( "Adding laser group", group, #targets )
    local targetsCount = #targets

    for i = 1, targetsCount do
        local target = targets[i]

        --- @type GEF_Antlion_Laser
        local newLaser = {
            origin = group,
            target = target,
            lastTargetPos = target:GetPos()
        }

        table.insert( pendingLasers, newLaser )
    end
end
