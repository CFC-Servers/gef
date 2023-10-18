AddCSLuaFile( "cl_ui.lua" )
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "cl_lasers.lua" )

EVENT.PrintName = "Antlion Hive!"
EVENT.Description = "A horde of Antlions is erupting from somewhere on the map!"
EVENT.UsesTeams = false
-- EVENT.Origin = Vector (-1650.3996582031, 10371.4453125, -12629.30859375)
EVENT.Origin = Vector (5352.0966796875, 6462.36328125, -11135.96875)

--- The total duration of the event
EVENT.EventDuration = 0.6 * 60

--- The current Wave Number
EVENT.WaveNumber = 0

----- STATIC FUNCTIONS -----

function EVENT:Initialize()
    print( "SH: Event Initialize" )
    self.BaseClass.Initialize( self )

    if CLIENT then return end
    self:StartSimpleSignup( 5 )
end

----- IMPLEMENTED FUNCTIONS -----

function EVENT:Cleanup()
    self:TimerRemove( "EndEvent" )
    self:TimerRemove( "WaveSpawn" )
    self:TimerRemove( "ScoreSorter" )
    self:TimerRemove( "LaserEnabler" )
    self:TimerRemove( "SpawnShooters" )
    self:TimerRemove( "StartAirstrike" )

    self:HookRemove( "Think", "Airstrike" )
    self:HookRemove( "Think", "ShooterMovement" )
    self:HookRemove( "PreDrawHalos", "Halos" )
    self:HookRemove( "PostDrawTranslucentRenderables", "Scoreboard" )
    self:HookRemove( "PostDrawTranslucentRenderables", "DrawLasers" )
    self:HookRemove( "OnNPCKilled", "CountKills" )

    print( "Cleaned up timers and hooks" )

    if SERVER then
        self:DestroyNPCs()
        self:DestroyShooters()
    end
end

function EVENT:OnEnded()
    self:Cleanup()

    if CLIENT then return end

    PrintMessage( HUD_PRINTTALK, "Antlion Hive event ended!" )
end

if SERVER then
    include( "sv_init.lua" )
else
    include( "cl_init.lua" )
end
