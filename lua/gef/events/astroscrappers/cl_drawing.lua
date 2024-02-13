local backgroundColor = Color( 0, 0, 0, 200 )
local progressColor = Color( 0, 255, 0, 200 )

local ScrW = ScrW
local ScrH = ScrH
local draw_RoundedBox = draw.RoundedBox

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
        drawProgress( punts, self.PuntsToGather )
    end
end

local verticalOffset = Vector( 0, 0, 10 )
local angZero = Angle( 0, 0, 0 )
function EVENT:DrawCapturePoints()
    local capturePoints = self.CapturePoints
    local capturePointSize = self.CapturePointSize

    for i = 1, #capturePoints do
        local point = capturePoints[i]

        cam.Start3D2D( point + verticalOffset, angZero, 1 )
        surface.SetDrawColor( 85, 200, 100, 255 )
        surface.DrawRect( -capturePointSize, -capturePointSize, capturePointSize * 2, capturePointSize * 2 )

        surface.SetDrawColor( 0, 0, 0, 255 )
        surface.DrawOutlinedRect( -capturePointSize, -capturePointSize, capturePointSize * 2, capturePointSize * 2, 5 )
        cam.End3D2D()
    end
end
