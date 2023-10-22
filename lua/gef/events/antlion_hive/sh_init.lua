AddCSLuaFile( "cl_ui.lua" )
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "cl_lasers.lua" )

EVENT.PrintName = "Antlion Hive!"
EVENT.Description = "A horde of Antlions is erupting from somewhere on the map!"
EVENT.UsesTeams = false
-- EVENT.Origin = Vector (-1650.3996582031, 10371.4453125, -12629.30859375)
EVENT.Origin = Vector( 5060.4526367188, 6157.0590820312, -11143.96875 )

--- The total duration of the event
EVENT.EventDuration = 3.5 * 60

--- The current Wave Number
EVENT.WaveNumber = 0

----- STATIC FUNCTIONS -----

function EVENT:Initialize()
    print( "SH: Event Initialize" )
    self.BaseClass.Initialize( self )

    if CLIENT then return end
    self:StartSimpleSignup( 20 )
end

----- IMPLEMENTED FUNCTIONS -----

function EVENT:Cleanup()
    self:TimerRemove( "EndEvent" )
    self:TimerRemove( "WaveSpawn" )
    self:TimerRemove( "StartDarken" )
    self:TimerRemove( "ScoreSorter" )
    self:TimerRemove( "SpawnLasers" )
    self:TimerRemove( "LaserEnabler" )
    self:TimerRemove( "SpawnShooters" )
    self:TimerRemove( "ResetDarkness" )
    self:TimerRemove( "StartAirstrike" )

    self:HookRemove( "Think", "Airstrike" )
    self:HookRemove( "PreDrawHalos", "Halos" )
    self:HookRemove( "Think", "ShooterMovement" )
    self:HookRemove( "OnNPCKilled", "CountKills" )
    self:HookRemove( "RenderScreenspaceEffects", "Darken" )
    self:HookRemove( "PostDrawTranslucentRenderables", "Scoreboard" )
    self:HookRemove( "PostDrawTranslucentRenderables", "DrawLasers" )

    print( "Cleaned up timers and hooks" )

    if SERVER then
        self:DestroyNPCs()
        self:DestroyShooters()
    end
end

function EVENT:OnEnded()
    self:Cleanup()

    if CLIENT then
        self:AnnounceWinner()
        return
    end

    PrintMessage( HUD_PRINTTALK, "Antlion Hive event ended!" )
end

if SERVER then
    include( "sv_init.lua" )
else
    include( "cl_init.lua" )
end
