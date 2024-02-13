AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "sh_init.lua" )
include( "sh_init.lua" )

function ENT:Initialize()
    self:SetModel( "models/hunter/blocks/cube025x025x025.mdl" )
    self:SetMoveType( MOVETYPE_NONE )
    self:SetTrigger( true )
end

--- Setup the area of the trigger
--- @param min Vector
--- @param max Vector
function ENT:Setup( min, max )
    self:PhysicsInitBox( min, max )
    self:SetCollisionBounds( min, max )
    self:SetNotSolid( true )

    local phys = self:GetPhysicsObject()
    if phys and phys:IsValid() then
        phys:EnableMotion( false )
        phys:EnableGravity( false )
        phys:EnableDrag( false )
    end

    self:SetMin( min )
    self:SetMax( max )
end

function ENT:SetCallback( callback )
    self.Callback = callback
end

--- @param ent Entity
function ENT:StartTouch( ent )
    print( "StartTouch", self, ent )
    if not ent then return end
    if ent:IsWorld() then return end

    local callback = self.Callback
    if not callback then return end

    ProtectedCall( function()
        callback( ent )
    end )
end
