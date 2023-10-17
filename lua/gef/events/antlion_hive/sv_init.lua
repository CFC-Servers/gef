--- How many antlions to spawn per wave
EVENT.GroupsPerWave = 3

--- Maximum number of antlions that can be spawned at any one time
EVENT.MaxSpawned = 70

--- How many time in seconds between the first and second wave
--- (It increases in speed as the event goes on and more players join)
EVENT.InitialDelay = 10

-- The delay of the final wave
-- (This limit can be reached sooner if more players join, but it will never be faster than this)
EVENT.PeakDelay = 0.15

-- On server, it's a lookup table so we can just keep track of the current ones
EVENT.NPCs = {}

--- @param npc NPC
function EVENT:AddNPC( npc )
    print( "SV: AddNPC", npc )
    self.NPCs[npc] = true
    self:BroadcastMethodToPlayers( "AddNPC", npc )
end

--- @param npc NPC
function EVENT:RemoveNPC( npc )
    print( "SV: RemoveNPC", npc )
    self.NPCs[npc] = nil
    self:BroadcastMethodToPlayers( "RemoveNPC", npc )
end

--- Increments the kill count by 1 for the given player
--- @param ply Player
--- @return number killCount The new kill count for the player
function EVENT:IncrementKills( ply )
    print( "SV: IncrementKills", ply )
    local kills = self.Kills

    local new = kills[ply] + 1
    kills[ply] = new

    return new
end

--- Increments and broadcasts the kill count for the given player
--- @param ply Player
function EVENT:AddKill( ply )
    print( "SV: AddKill", ply )
    local new = self:IncrementKills( ply )
    self:BroadcastMethodToPlayers( "SetKills", ply, new )
end

--- Spawns a single Antlion as part of a wave
--- @param squadName string The name of the squad for the NPC
--- @param waveCenter Vector the center of this Wave's NPCs
--- @param players table<Player>
function EVENT:SpawnAntlion( squadName, waveCenter, players )
    if table.Count( self.NPCs ) > self.MaxSpawned then
        return
    end

    local waveNumber = self.WaveNumber

    local npc = ents.Create( "npc_antlion" )
    -- npc:SetSaveValue( "startburrowed", true )
    npc:SetSaveValue( "skin", math.random( 0, 3 ) )
    npc:SetSaveValue( "squadname", squadName )
    npc:SetSaveValue( "wakesquad", true )
    npc:SetSaveValue( "wakeradius", 1000 )
    npc:SetSaveValue( "unburroweffects", true )
    npc:SetSaveValue( "ignoreunseenenemies", true )
    npc:SetSaveValue( "spawnflags", bit.bor( SF_NPC_FADE_CORPSE, SF_NPC_GAG ) )
    npc:SetSaveValue( "max_health", 60 + ( waveNumber * 2 ) )

    local spawnPos = waveCenter + VectorRand( -150, 150 )
    spawnPos[3] = waveCenter[3] + 100
    npc:SetPos( spawnPos )

    local canSpawn = hook.Run( "GEF_AntlionHive_AntlionSpawn", npc )
    if canSpawn == false then return end

    npc:Spawn()
    -- timer.Simple( math.random() * 2, function()
    --     npc:Fire( "unburrow" )
    -- end )

    npc:CallOnRemove( "GEF_AntlionHive_Cleanup", function()
        self:RemoveNPC( npc )
    end )

    -- Neutral towards all players
    npc:AddRelationship( "player D_NU 98" )

    -- Really hates the players in the game though
    local playerCount = #players
    for i = 1, playerCount do
        local ply = players[i]
        npc:AddEntityRelationship( ply, D_HT, 99 )
    end

    npc.GEF_AntlionHive = true
    hook.Run( "GEF_AntlionHive_AntlionSpawned", npc )

    timer.Simple( 0, function()
        if npc:IsValid() then
            self:AddNPC( npc )
        end
    end )
end

function EVENT:SpawnWave()
    -- Always have to do 2 per squad
    -- Because engine something-another
    local count = 2
    local origin = self.Origin
    local players = self:GetPlayers()
    local waveNumber = self.WaveNumber

    local ID = self:GetID()

    for _ = 1, self.GroupsPerWave do
        local waveCenter = origin + VectorRand( -900, 900 )
        waveCenter[3] = waveCenter[3]

        local squadName = "antlions_" .. ID .. "_" .. waveNumber

        for _ = 1, count do
            self:SpawnAntlion( squadName, waveCenter, players )
        end
    end

    self.WaveNumber = waveNumber + 1
    self:BroadcastMethodToPlayers( "OnNextWave" )
end

function EVENT:OnStarted()
    self.Airstrike = GEF.NewAirstriker()

    local NPCs = self.NPCs
    local Kills = self.Kills

    self:HookAdd( "OnNPCKilled", "CountKills", function( npc, attacker )
        print( npc, attacker )
        if not NPCs[npc] then return end
        if not attacker:IsPlayer() then return end

        self:RemoveNPC( npc )

        if self:HasPlayer( attacker ) then
            -- If the player already exists, do a basic update
            self:AddKill( attacker )
        else
            -- If this player is jumping in halfway through, add them and send them all the data they need
            print( "Player wasn't involved, but got an Antlion kill. Patching them in", attacker )
            self:AddPlayer( attacker )

            self:IncrementKills( attacker )
            self:SendMethod( attacker, "SetAllKills", Kills )
            self:SendMethod( attacker, "SetAllNPCs", NPCs )
        end
    end )

    local peakDelay = self.PeakDelay
    local initialDelay = self.InitialDelay
    local eventDuration = self.EventDuration

    local spawning = true

    local function spawnAndAdjust()
        self:SpawnWave()
        if not spawning then return end

        local numPlayers = #self:GetPlayers()

        local adjustment = (self.WaveNumber + numPlayers) * 0.55
        local nextDelay = initialDelay - adjustment
        nextDelay = math.max( peakDelay, nextDelay )

        -- print( "SV: New wave delay:", nextDelay )
        self:TimerCreate( "WaveSpawn", nextDelay, 1, spawnAndAdjust )
    end
    self:TimerCreate( "WaveSpawn", initialDelay, 1, spawnAndAdjust )

    self:TimerCreate( "StartAirstrike", eventDuration, 1, function()
        spawning = false
        self:TimerRemove( "WaveSpawn" )

        PrintMessage( HUD_PRINTTALK, "AIRSTRIKE STARTING" )

        local npcs = table.GetKeys( NPCs )
        self.Airstrike:Start( npcs, self.Origin, #npcs / 2, 800, 3 )

        self:HookAdd( "Think", "Airstrike", function()
            self.Airstrike:Think()
        end )

        self:TimerCreate( "EndEvent", 25, 1, function()
            print( "Antlion event ended!" )
            self:End()
        end )
    end )
end

function EVENT:DestroyNPCs()
    for npc in pairs( self.NPCs ) do
        if npc and npc:IsValid() then
            npc:Fire( "kill" )
        end
    end
end

