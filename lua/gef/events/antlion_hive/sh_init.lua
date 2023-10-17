AddCSLuaFile( "cl_init.lua" )

EVENT.PrintName = "Antlion Hive!"
EVENT.Description = "A horde of Antlions is erupting from somewhere on the map!"
EVENT.UsesTeams = false
EVENT.Origin = Vector( -1621, 10375, -11143 )

--- The total duration of the event
EVENT.EventDuration = 5 * 60

--- The current Wave Number
EVENT.WaveNumber = 0

----- STATIC FUNCTIONS -----

function EVENT:Initialize()
    print( "SH: Event Initialize" )
    self.BaseClass.Initialize( self )

    if CLIENT then return end
    self:StartSimpleSignup( 5 )
end

----- INSTANCE -----
EVENT.Kills = {}

--- @param ply Player
function EVENT:OnPlayerAdded( ply )
    print( "SH: OnPlayerAdded", ply )
    self.Kills[ply] = 0
end

----- IMPLEMENTED FUNCTIONS -----

function EVENT:Cleanup()
    self:TimerRemove( "EndEvent" )
    self:TimerRemove( "WaveSpawn" )
    self:TimerRemove( "StartAirstrike" )
    self:HookRemove( "Think", "Airstrike" )
    self:HookRemove( "PreDrawHalos", "Halos" )
    self:HookRemove( "OnNPCKilled", "CountKills" )

    if SERVER then
        self:DestroyNPCs()
    end
end

function EVENT:OnEnded()
    if CLIENT then return end

    self:Cleanup()

    PrintMessage( HUD_PRINTTALK, "Antlion Hive event ended!" )
end

if SERVER then
    include( "sv_init.lua" )
else
    include( "cl_init.lua" )
end
