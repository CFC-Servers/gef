EVENT.PrintName = "Astro Scrappers!"
EVENT.Description = "Precious scrap is raining from the sky! Collect as much as you can!"
EVENT.UsesTeams = false
EVENT.Origin = Vector( -725.1123046875, -939.87512207031, -11139.96875 )

--- The total duration of the event
EVENT.EventDuration = 1 * 60

EVENT.PuntsToGather = 12
EVENT.PuntResetTime = 1.2

----- STATIC FUNCTIONS -----

function EVENT:Initialize()
    print( "SH: Event Initialize" )
    self.BaseClass.Initialize( self )

    if SERVER then
        self:StartSimpleSignup( 5 )
    end

    if CLIENT then
        self:ShowScoreboard()
        return
    end
end

----- IMPLEMENTED FUNCTIONS -----

function EVENT:Cleanup()
    self.BaseClass.Cleanup( self )
end

function EVENT:OnEnded()
    self:Cleanup()

    if CLIENT then
        self:AnnounceWinner()
        return
    end

    PrintMessage( HUD_PRINTTALK, "AstroScrappers event ended!" )
end

if SERVER then
    include( "sv_init.lua" )
else
    include( "cl_init.lua" )
end
