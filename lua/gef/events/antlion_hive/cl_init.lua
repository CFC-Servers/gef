include( "cl_ui.lua" )
include( "cl_lasers.lua" )

--- @class AntlionHive_PlayerKills
--- @field nick string
--- @field count number
--- @field r number
--- @field g number
--- @field b number
--- @field a number

--- @type table<AntlionHive_PlayerKills>
EVENT.KillsData = {}

--- @type table<Player, AntlionHive_PlayerKills>
EVENT.Kills = {}

local function getPlayerColor( ply )
    return team.GetColor( ply:Team() )
end

local function makePlayerData( ply, count )
    count = count or 0

    local override = hook.Run( "GEF_AntlionHive_PlayerScoreColor", ply )
    local color = IsColor( override ) and override or getPlayerColor( ply )

    return {
        r = color.r,
        g = color.g,
        b = color.b,
        a = color.a,
        count = count,
        nick = ply:Nick(),
    }
end


--- @param new table<Player, number>
function EVENT:SetAllKills( new )
    local kills = self.Kills
    local killsData = self.KillsData

    table.Empty( kills )
    table.Empty( killsData )

    for ply, count in pairs( new ) do
        self:SetupPlayer( ply, count )
    end
end

--- Sets up the data tables for the given player
--- @param ply Player
--- @param count number? The count to initialize the player at
function EVENT:SetupPlayer( ply, count )
    if self.Kills[ply] then return end

    local tbl = makePlayerData( ply, count )
    table.insert( self.KillsData, tbl )
    self.Kills[ply] = tbl

    return tbl
end

--- @param ply Player
function EVENT:OnPlayerAdded( ply )
    self:SetupPlayer( ply )
end

--- @param ply Player
--- @param count number
function EVENT:SetKills( ply, count )
    local data = self.Kills[ply]
    if not data then
        self:SetupPlayer( ply, count )
        return
    end

    data.count = count
end

function EVENT:OnNextWave()
    self.WaveNumber = self.WaveNumber + 1
    -- Do more
end

function EVENT:OnStarted()
    chat.AddText( "The Antlions are emerging!" )
    self.EndTime = CurTime() + self.EventDuration
    self:ShowScoreboard()
end
