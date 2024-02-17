local backgroundColor = Color( 0, 0, 0, 200 )
local progressColor = Color( 0, 255, 0, 200 )

local ScrW = ScrW
local ScrH = ScrH
local Lerp = Lerp
local draw_RoundedBox = draw.RoundedBox
local FrameTime = FrameTime

local lastProgress = 0
local function drawProgress( current, total )
    local w = 200
    local h = 40

    local x = ScrW() / 2 - w / 2
    local y = ScrH() * 0.75

    local newProgress = current / total
    local currentProgress = Lerp( FrameTime() * 10, lastProgress, newProgress )
    lastProgress = currentProgress

    draw_RoundedBox( 0, x, y, w, h, backgroundColor )
    draw_RoundedBox( 0, x, y, w * currentProgress, h, progressColor )
end

function EVENT:DrawOverlay()
    local me = LocalPlayer()

    local holding = self:GetNW2Bool( me, "IsHoldingScrap", false )
    if holding then
        drawHoldingScrap()
    else
        local target = self:GetNW2Entity( me, "CurrentTarget", nil )
        if not target then
            lastProgress = 0
            return
        end

        local punts = self:GetNW2Int( me, "Punts", 0 )
        local required = self:GetNW2Int( target, "PuntsRequired", 1 )
        drawProgress( punts, required )
    end
end

do
    local verticalOffset = Vector( 0, 0, 10 )
    local angZero = Angle( 0, 0, 0 )
    local cam_Start3D2D = cam.Start3D2D
    local cam_End3D2D = cam.End3D2D
    local surface_SetDrawColor = surface.SetDrawColor
    local surface_DrawRect = surface.DrawRect
    local surface_DrawOutlinedRect = surface.DrawOutlinedRect
    function EVENT:DrawCapturePoints()
        local capturePoints = self.CapturePoints
        local capturePointSize = self.CapturePointSize

        for i = 1, #capturePoints do
            local point = capturePoints[i]

            cam_Start3D2D( point + verticalOffset, angZero, 1 )
            surface_SetDrawColor( 85, 200, 100, 255 )
            surface_DrawRect( -capturePointSize, -capturePointSize, capturePointSize * 2, capturePointSize * 2 )

            surface_SetDrawColor( 0, 0, 0, 255 )
            surface_DrawOutlinedRect( -capturePointSize, -capturePointSize, capturePointSize * 2, capturePointSize * 2, 5 )
            cam_End3D2D()
        end
    end
end

function EVENT:SetupDrawingModule()
    self:HookAdd( "PostDrawHUD", "DrawHUD", function()
        self:DrawOverlay()
    end )

    self:HookAdd( "PostDrawTranslucentRenderables", "DrawCapturePoints", function()
        self:DrawCapturePoints()
    end )
end
