ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName		= "GEF Area Handler"
ENT.Author			= "CFC Servers"

ENT.Spawnable			= false
ENT.AdminSpawnable		= false

function ENT:SetupDataTables()
    self:NetworkVar( "Vector", 0, "Min" )
    self:NetworkVar( "Vector", 1, "Max" )
end
