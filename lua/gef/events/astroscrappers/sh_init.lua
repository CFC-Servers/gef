AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "sh_scoring.lua" )
AddCSLuaFile( "cl_drawing.lua" )

EVENT.PrintName = "Astro Scrappers!"
EVENT.Description = "Precious scrap is raining from the sky! Collect as much as you can!"
EVENT.UsesTeams = false
-- EVENT.Origin = Vector( -725.1123046875, -939.87512207031, -11139.96875 )
EVENT.Origin = Vector ( 639.26086425781, -10264.444335938, -12799.96875 )

EVENT.CapturePointSize = 250
EVENT.CapturePoints = {
    -- Vector( -2727.44140625, 865.72546386719, -11139.96875 ),
    -- Vector( -1393.7622070312, -3755.2333984375, -11143.96875 ),
    -- Vector( 2411.1982421875, -2201.1936035156, -11143.96875 )
    Vector( 918.35791015625, -5181.9951171875, -12799.96875 ),
    Vector( -3143.1127929688, -11287.927734375, -12799.96875 ),
    Vector( 3578.919921875, -11232.208984375, -12799.96875 )

}

--- The total duration of the event
EVENT.EventDuration = 10 * 60

EVENT.PuntDropChance = 7 -- Out of 100, liklihood of dropping scrap when being punted
EVENT.PuntCritChance = 5 -- Out of 100, liklihood of a punt being a critical hit
EVENT.PuntsRequiredBig = 20
EVENT.PuntsRequiredSmall = 12
EVENT.PuntsRequiredDropped = 4

EVENT.PuntResetTime = 1.2
EVENT.CarSpawnInterval = 10

--- TODO: Team support
EVENT.Scores = {}

----- STATIC FUNCTIONS -----

function EVENT:Initialize()
    print( "SH: Event Initialize" )
    self.BaseClass.Initialize( self )

    if SERVER then
        self:StartSimpleSignup( 1 )
    end

    if CLIENT then
        -- self:ShowScoreboard()
        return
    end
end

----- IMPLEMENTED FUNCTIONS -----

function EVENT:Cleanup()
    self.BaseClass.Cleanup( self )
end

function EVENT:OnEnded()
    self:Cleanup()
    PrintMessage( HUD_PRINTTALK, "AstroScrappers event ended!" )
end

--- @param ply Player
function EVENT:OnPlayerAdded( ply )
    print( "Player added", ply )
    self.Scores[ply] = 0
end

if SERVER then
    include( "sv_init.lua" )
else
    include( "cl_init.lua" )
    include( "cl_drawing.lua" )
end

include( "sh_scoring.lua" )
