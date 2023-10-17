local table_insert = table.insert
local table_remove = table.remove

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
    table.Empty( self.Kills )

    for ply, count in ipairs( new ) do
        kills[ply] = count
    end
end

--- @param ply Player
--- @param kills number
function EVENT:SetKills( ply, kills )
    print( "CL: SetKills", ply, kills )
    self.Kills[ply] = kills
end

function EVENT:OnNextWave()
    print( "CL: Next Wave", self.WaveNumber + 1 )
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
