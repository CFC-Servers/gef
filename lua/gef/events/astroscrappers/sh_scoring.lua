--- TODO: Team support
EVENT.Scores = {}

--- Increments the score count by 1 for the given player
--- @param ply Player
--- @return number score The score for the player
function EVENT:IncrementScore( ply )
    local score = self.Scores

    local new = score[ply] + 1
    score[ply] = new

    return new
end

if SERVER then
    local IsValid = IsValid

    --- Called when a player picks up scrap
    --- @param ply Player
    function EVENT:OnPickupScrap( ply )
        PrintMessage( HUD_PRINTTALK, ply:Nick() .. " has gathered a scrap!" )

        local new = self:IncrementScore( ply )
        self:BroadcastMethodToPlayers( "SetKills", ply, new )
    end

    --- Called when a player grav punts a meteor
    --- @param ply Player
    --- @param meteor Entity
    function EVENT:OnPuntMeteor( ply, meteor )
        if self:GetNW2Bool( ply, "HoldingScrap", false ) then return false end

        local currentTarget = self:GetNW2Entity( ply, "CurrentTarget" )
        if currentTarget ~= meteor then
            self:SetNW2Entity( ply, "CurrentTarget", meteor )
            self:SetNW2Int( ply, "Punts", 0 )
        end

        local punts = self:GetNW2Int( ply, "Punts", 0 ) + 1
        self:SetNW2Int( ply, "Punts", punts )

        local resetTimer = "PuntReset_" .. ply:SteamID64()

        if punts >= self.PuntsToGather then
            self:SetNW2Int( ply, "Punts", 0 )
            self:SetNW2Bool( ply, "HoldingScrap", true )
            self:SetNW2Entity( ply, "CurrentTarget", nil )

            self:TimerRemove( resetTimer )
            meteor:Remove()

            self:OnPickupScrap( ply )
        else
            self:TimerCreate( resetTimer, self.PuntResetTime, 1, function()
                if not IsValid( ply ) then return end
                self:SetNW2Int( ply, "Punts", 0 )
                self:SetNW2Entity( ply, "CurrentTarget", nil )
            end )
        end
    end

    --- Called when a player grav punts another player
    --- @param ply Player
    --- @param target Player|Entity
    function EVENT:OnPuntPlayer( ply, target )
        if self:GetNW2Bool( ply, "HoldingScrap", false ) then return false end
        if not self:GetNW2Bool( target, "HoldingScrap", false ) then return false end

        return true
    end

    --- Called on GravGunPunt
    --- @param ply Player
    --- @param ent Entity
    function EVENT:OnGravPunt( ply, ent )
        if not self:HasPlayer( ply ) then return end

        if self:GetNW2Bool( ent, "IsCar", false ) then
            return self:OnPuntMeteor( ply, ent )
        end

        if self:HasPlayer( ent ) then
            return self:OnPuntPlayer( ply, ent )
        end
    end
end

if CLIENT then
    --- @param ply Player
    --- @return number
    function EVENT:SetKills( ply, value )
        self.Score[ply] = value
    end

    --- Called when a player punts a player
    --- @param _ Player
    --- @param target Player|Entity
    function EVENT:OnPuntPlayer( _, target )
        return self:GetNW2Bool( target, "HoldingScrap", false )
    end

    --- Called when a player grav punts a meteor
    --- @param ply Player
    --- @param _ Entity
    function EVENT:OnPuntMeteor( ply, _ )
        if self:GetNW2Bool( ply, "HoldingScrap", false ) then
            if ply == LocalPlayer() then
                surface.PlaySound( "buttons/button16.wav" )
            end

            return false
        end
    end

    --- Called on GravGunPunt
    --- @param ply Player
    --- @param ent Entity
    function EVENT:OnGravPunt( ply, ent )
        if not self:HasPlayer( ply ) then return end

        if self:GetNW2Bool( ent, "IsCar", false ) then
            return self:OnPuntMeteor( ply, ent )
        end

        if self:HasPlayer( ent ) then
            return self:OnPuntPlayer( ply, ent )
        end
    end
end
