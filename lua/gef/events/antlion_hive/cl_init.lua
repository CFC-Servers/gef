include( "cl_ui.lua" )
include( "cl_lasers.lua" )

--- @class AntlionHive_PlayerKills
--- @field nick string
--- @field ply Player
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
        ply = ply,
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
end

function EVENT:AnnounceWinner()
    local green = Color( 10, 245, 10 )
    local info = Color( 225, 225, 225 )

    chat.AddText( green, "The Antlion Hive has been defeated!" )
    chat.AddText( info, "The following players killed the most Antlions:" )

    local killsData = self.KillsData
    local count = math.min( #killsData, 3 )

    for i = 1, count do
        local data = killsData[i]
        local col = Color( data.r, data.g, data.b )

        chat.AddText(
            info, " " .. i .. ". ",
            col, data.nick,
            info, " - ", data.count
        )
    end
end

function EVENT:OnShootersSpawned()
    local sequence = {
        "npc/overwatch/radiovoice/attention.wav",
        "npc/overwatch/radiovoice/highpriorityregion.wav",
        "npc/overwatch/radiovoice/allteamsrespondcode3.wav"
    }

    GEF.Utils.PlaySoundSequence( sequence )
end

function EVENT:StartDarken()
    -- How long it takes to reach max darkness
    local duration = 3
    local startTime = CurTime()

    surface.PlaySound( "npc/overwatch/radiovoice/completesentencingatwill.wav" )

    local originalTab = {
        ["$pp_colour_addr"] = 0,
        ["$pp_colour_addg"] = 0,
        ["$pp_colour_addb"] = 0,
        ["$pp_colour_brightness"] = 0,
        ["$pp_colour_contrast"] = 1,
        ["$pp_colour_colour"] = 1,
        ["$pp_colour_mulr"] = 0,
        ["$pp_colour_mulg"] = 0,
        ["$pp_colour_mulb"] = 0
    }

    local targetTab = {
        ["$pp_colour_addr"] = 0.02,
        ["$pp_colour_addg"] = 0,
        ["$pp_colour_addb"] = 0,
        ["$pp_colour_brightness"] = -0.25,
        ["$pp_colour_contrast"] = 1.05,
        ["$pp_colour_colour"] = 0.15,
        ["$pp_colour_mulr"] = 0.15,
        ["$pp_colour_mulg"] = 0,
        ["$pp_colour_mulb"] = 0
    }

    self:HookAdd( "RenderScreenspaceEffects", "Darken", function()
        local elapsed = CurTime() - startTime
        local fraction = math.Clamp( elapsed / duration, 0, 1 )

        local tab = {}
        for k in pairs( originalTab ) do
            tab[k] = Lerp( fraction, originalTab[k], targetTab[k] )
        end

        DrawColorModify( tab )
    end )

    self:TimerCreate( "ResetDarkness", duration + 11, 1, function()
        local og = originalTab
        local tg = targetTab

        targetTab = og
        originalTab = tg

        duration = 1
        startTime = CurTime()

        timer.Simple( duration, function()
            self:HookRemove( "RenderScreenspaceEffects", "Darken" )
        end )
    end )
end
