--- Debugging function to draw lines between the car and its destination
--- @param carOrigin Vector
--- @param destination Vector
function EVENT:DebugCarLines( carOrigin, destination )
    -- debugoverlay.Line( carOrigin, destination, 4, color_white, false )
end

function EVENT:OnStarted()
    self:HookAdd( "GravGunPunt", "CheckPunt", function( ply, ent )
        return self:OnGravPunt( ply, ent )
    end )

    self:HookAdd( "PostDrawHUD", "DrawHUD", function()
        self:DrawOverlay()
    end )

    self:HookAdd( "PostDrawTranslucentRenderables", "DrawCapturePoints", function()
        self:DrawCapturePoints()
    end )
end
