EVENT.PrintName = "Gun Game"
EVENT.Description = "This is an example event."
EVENT.EventDuration = 60
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


function EVENT:Initialize()
    self.BaseClass.Initialize( self )

    if SERVER then
        self:StartSimpleSignup()
    end
end

function EVENT:OnStarted()
    if CLIENT then return end

    PrintMessage( HUD_PRINTTALK, "Gun Game event started!" )

    for _, ply in ipairs( self:GetPlayers() ) do
        ply:StripWeapons()
        ply:Give( self.WeaponProgression[1] )

        self.PlayerProgression[ply] = 1
    end

    self:HookAdd( "PlayerSpawn", "GEF_GunGame_GiveWeapons", function( ply )
        if not self:HasStarted() then return end
        if not self:HasPlayer( ply ) then return end
        ply:StripWeapons()

        timer.Simple( 0.01, function()
            ply:Give( EVENT.PlayerProgression[ply] )
        end )
    end )

    self:HookAdd( "PlayerDeath", "GEF_GunGame_HandleDeath", function( victim, _, attacker )
        if not self:HasStarted() then return end
        if not self:HasPlayer( victim ) then return end
        if not self:HasPlayer( attacker ) then return end

        self.PlayerProgression[attacker] = self.PlayerProgression[attacker] + 1
        if self.PlayerProgression[attacker] > #self.WeaponProgression then
            PrintMessage( HUD_PRINTTALK, attacker:Nick() .. " has won the Gun Game event!" )

            for _, ply in ipairs( self:GetPlayers() ) do
                ply:Spawn()
            end

            self:End()
            return
        else
            attacker:StripWeapons()

            timer.Simple( 0, function()
                attacker:Give( self.WeaponProgression[self.PlayerProgression[attacker]] )
            end )
        end
    end )

    self:TimerCreate( "GEF_GunGame_EndEvent", self.EventDuration, 1, function()
        print( "Gun Game event ended!" )

        self:End()
    end )
end

function EVENT:OnEnded()
    if SERVER then
        PrintMessage( HUD_PRINTTALK, "Gun Game event ended!" )
    end
end
