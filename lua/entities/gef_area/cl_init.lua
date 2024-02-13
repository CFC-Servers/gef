local angZero = Angle( 0, 0, 0 )
local red = Color( 255, 0, 0 )
include( "sh_init.lua" )

local developer = GetConVar( "developer" )

function ENT:Draw()
    if developer:GetInt() == 0 then return end
    local pos = self:GetPos()

    local min = self:GetMin()
    local max = self:GetMax()

    render.DrawWireframeBox( pos, angZero, min, max, red, false )
end
