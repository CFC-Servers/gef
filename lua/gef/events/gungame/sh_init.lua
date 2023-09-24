EVENT.PrintName = "Gun Game"
EVENT.Description = "This is an example event."
EVENT.EventDuration = 5 * 60
EVENT.UsesTeams = false
EVENT.WeaponProgression = {
    "m9k_minigun",
    "m9k_m249lmg",
    "m9k_m60",
    "m9k_ak47",
    "m9k_m4a1",
    "m9k_m16a4_acog",
    "m9k_winchester73",
    "m9k_ithacam37",
    "m9k_1897winchester",
    "m9k_svt40",
    "m9k_psg1",
    "m9k_m29satan"
}
EVENT.PlayerProgression = {}


----- STATIC FUNCTIONS -----

function EVENT:Initialize()
    self.BaseClass.Initialize( self )

    if SERVER then
        self:StartSimpleSignup()
    end
end


----- INSTANCE FUNCTIONS -----

--- Returns the max progress a player can have for the event.
--- Once a player reaches this progress, the event will end.
--- @return number
function EVENT:GetProgressMax()
    return #self.WeaponProgression
end

--- Sets the progress of a player.
--- @param ply Player
--- @param progress number
function EVENT:SetPlayerProgress( ply, progress )
    self.PlayerProgression[ply] = progress
end

--- Returns the progress of a player.
--- @param ply Player
--- @return number
function EVENT:GetPlayerProgress( ply )
    return self.PlayerProgression[ply]
end

--- Returns the weapon class for a player's current progress.
--- @param ply Player
--- @return string
function EVENT:GetPlayerWeaponClass( ply )
    return self.WeaponProgression[self:GetPlayerProgress( ply )]
end


----- IMPLEMENTED FUNCTIONS -----

function EVENT:OnStarted()
    if CLIENT then return end

    PrintMessage( HUD_PRINTTALK, "Gun Game event started!" )

    for _, ply in ipairs( self:GetPlayers() ) do
        ply:StripWeapons()
        ply:Give( self.WeaponProgression[1] )

        self:SetPlayerProgress( ply, 1 )
    end

    self:HookAdd( "PlayerSpawn", "GEF_GunGame_GiveWeapons", function( ply )
        if not self:HasStarted() then return end
        if not self:HasPlayer( ply ) then return end

        timer.Simple( 0.01, function()
            if not IsValid( ply ) then return end

            ply:StripWeapons()
            ply:Give( self:GetPlayerWeaponClass( ply ) )
        end )
    end )

    self:HookAdd( "PlayerDeath", "GEF_GunGame_HandleDeath", function( victim, _, attacker )
        if not self:HasStarted() then return end
        if not self:HasPlayer( victim ) then return end
        if not self:HasPlayer( attacker ) then return end

        local progress = self:GetPlayerProgress( attacker ) + 1

        self:SetPlayerProgress( attacker, progress )

        if progress > self:GetProgressMax() then
            PrintMessage( HUD_PRINTTALK, attacker:Nick() .. " has won the Gun Game event!" )
            self:End()

            return
        end

        attacker:StripWeapons()

        timer.Simple( 0, function()
            if not IsValid( attacker ) then return end

            attacker:Give( self:GetPlayerWeaponClass( attacker ) )
        end )
    end )

    self:TimerCreate( "GEF_GunGame_EndEvent", self.EventDuration, 1, function()
        print( "Gun Game event ended!" )

        self:End()
    end )
end

function EVENT:OnEnded()
    if CLIENT then return end

    for _, ply in ipairs( self:GetPlayers() ) do
        if IsValid( ply ) and ply:Alive() then
            ply:Spawn()
        end
    end

    PrintMessage( HUD_PRINTTALK, "Gun Game event ended!" )
end
