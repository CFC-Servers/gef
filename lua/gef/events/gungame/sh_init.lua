EVENT.Name = "Gun Game"
EVENT.Description = "This is an example event."
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
    self:StartSignup()
end

function EVENT:Start()
    if CLIENT then return end
    PrintMessage( HUD_PRINTTALK, "Gun Game event started!" )

    for ply in pairs( self.Players ) do
        ply:StripWeapons()
        ply:Give( self.WeaponProgression[1] )

        self.PlayerProgression[ply] = 1
    end

    self:AddHook( "PlayerSpawn", function( ply )
        if not self.Players[ply] then return end
        ply:StripWeapons()

        timer.Simple( 0, function()
            ply:Give( EVENT.PlayerProgression[ply] )
        end )
    end )

    self:AddHook( "PlayerDeath", function( victim, _, attacker )
        --if not self.Players[victim] then return end
        if not self.Players[attacker] then return end

        self.PlayerProgression[attacker] = self.PlayerProgression[attacker] + 1
        if self.PlayerProgression[attacker] > #self.WeaponProgression then
            PrintMessage( HUD_PRINTTALK, attacker:Nick() .. " has won the Gun Game event!" )

            for ply in pairs( self.Players ) do
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

    timer.Simple( 60, function()
        if not self.IsActive then return end
        print( "Gun Game event ended!" )
        self:End()
    end )
end

function EVENT:End()
    if SERVER then
        PrintMessage( HUD_PRINTTALK, "Gun Game event ended!" )
    end

    self:Cleanup()
end
