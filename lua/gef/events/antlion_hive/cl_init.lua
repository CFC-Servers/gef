local table_insert = table.insert
local table_remove = table.remove

include( "cl_ui.lua" )

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
    local user = ULib.ucl.users[ply:SteamID()]
    local groupName = user and user.group or "user"

    local team = ULib.ucl.groups[groupName].team

    return Color(
        team.color_red,
        team.color_green,
        team.color_blue
    )
end

local function makePlayerData( ply, count )
    count = count or 0

    local override = hook.Run( "GEF_AntlionHive_PlayerScoreColor", ply )
    local color = override or getPlayerColor( ply )

    return {
        r = color.r,
        g = color.g,
        b = color.b,
        a = color.a,
        count = count,
        nick = ply:Nick(),
    }
end


-- On client, it's a flat table so we can use it in halos
EVENT.NPCs = {}

--- @param npc Entity
function EVENT:AddNPC( npc )
    print( "CL: AddNPC", npc )
    table_insert( self.NPCs, npc )
end

--- Removes the given NPC, and any invalid NPCs from the NPC list
--- @param npc Entity
function EVENT:RemoveNPC( npc )
    print( "CL: RemoveNPC", npc )
    local toRemove = {}

    -- Keep track of everything we intend to remove
    local npcs = self.NPCs
    local npcCount = #npcs
    for i = 1, npcCount do
        local n = npcs[i]
        if n == NULL or n == npc then
            table_insert( toRemove, i )
        end
    end

    -- Slightly more efficient to remove them in reverse
    local removeCount = #toRemove
    for i = removeCount, 1, -1 do
        table_remove( npcs, toRemove[i] )
    end
end

--- @param new table<Entity, boolean>
function EVENT:SetAllNPCs( new )
    print( "CL: SetAllNPCs" )

    local npcs = self.NPCs
    table.Empty( npcs )

    for npc in pairs( new ) do
        table_insert( npcs, npc )
    end
end

--- @param new table<Player, number>
function EVENT:SetAllKills( new )
    print( "CL: SetAllKills" )

    local kills = self.Kills
    local killsData = self.KillsData

    table.Empty( kills )
    table.Empty( killsData )

    for ply, count in ipairs( new ) do
        local tbl = makePlayerData( ply, count )
        table.insert( killsData, tbl )

        kills[ply] = tbl
    end
end

--- Sets up the data tables for the given player
--- @param ply Player
--- @param count number? The count to initialize the player at
function EVENT:SetupPlayer( ply, count )
    local tbl = makePlayerData( ply, count )
    table.insert( self.KillsData, tbl )
    self.Kills[ply] = tbl

    return tbl
end

--- @param ply Player
function EVENT:OnPlayerAdded( ply )
    self:SetupPlayer( ply )

    if ply == LocalPlayer() then
        self:ShowScoreboard()
    end
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

    local halo_Add = halo.Add
    local badguys = Color( 255, 75, 75, 255 )
    self:HookAdd( "PreDrawHalos", "Halos", function()
        halo_Add( self.NPCs, badguys, 2, 2, 2, true, true )
    end )
end
