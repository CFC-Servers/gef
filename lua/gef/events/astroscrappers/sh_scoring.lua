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
        PrintMessage( HUD_PRINTTALK, ply:Nick() .. " has gathered a scrap! Stop them before they capture it!" )
    end

    function EVENT:OnPlayerEnterCaptureZone( ply )
        if not self:GetNW2Bool( ply, "HoldingScrap", false ) then return end

        local score = self:IncrementScore( ply )
        self:SetNW2Bool( ply, "HoldingScrap", false )
        PrintMessage( HUD_PRINTTALK, ply:Nick() .. " has captured a scrap! Their score is now: " .. score )
    end

    --- Called when a player grav punts scrap
    --- @param ply Player
    --- @param meteor Entity
    function EVENT:OnPuntScrap( ply, meteor )
        if self:GetNW2Bool( ply, "HoldingScrap", false ) then return false end

        local currentTarget = self:GetNW2Entity( ply, "CurrentTarget" )
        if currentTarget ~= meteor then
            self:SetNW2Entity( ply, "CurrentTarget", meteor )
            self:SetNW2Int( ply, "Punts", 0 )
        end

        local punts = self:GetNW2Int( ply, "Punts", 0 ) + 1
        local puntsRequired = self:GetNW2Int( meteor, "PuntsRequired", 3 )
        self:SetNW2Int( ply, "Punts", punts )

        local resetTimer = "PuntReset_" .. ply:SteamID64()

        if punts >= puntsRequired then
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

    local dropOffset = Vector( 0, 0, 50 )
    function EVENT:DropScrap( ply )
        self:SetNW2Bool( ply, "HoldingScrap", false )
        self:SetNW2Entity( ply, "CurrentTarget", nil )
        self:SetNW2Int( ply, "Punts", 0 )

        local scrapEnt = self:EntCreate( "prop_physics" )
        scrapEnt:SetModel( "models/props_c17/SuitCase_Passenger_Physics.mdl" )
        scrapEnt:SetPos( ply:GetPos() + dropOffset + ply:GetForward() * 50 )

        local angles = Angle( 0, math_random( -180, 180 ), 0 )
        scrapEnt:SetAngles( angles )
        scrapEnt:Spawn()
        scrapEnt:Activate()

        local phys = scrapEnt:GetPhysicsObject()
        phys:EnableMotion( false )
        phys:SetVelocity( ply:GetVelocity() + VectorRand( -750, 750 ) )

        self:SetNW2Bool( scrapEnt, "IsScrap", true )
        self:SetNW2Int( scrapEnt, "PuntsRequired", 3 )
    end

    --- Called on GravGunPunt
    --- @param ply Player
    --- @param ent Entity
    function EVENT:OnGravPunt( ply, ent )
        if not self:HasPlayer( ply ) then return end

        if self:GetNW2Bool( ent, "IsScrap", false ) then
            return self:OnPuntScrap( ply, ent )
        end
    end

    function EVENT:SetupScoringModule()
        self:HookAdd( "GravGunPunt", "CheckPunt", function( ply, ent )
            return self:OnGravPunt( ply, ent )
        end )
    end
end

if CLIENT then
    --- @param ply Player
    --- @return number
    function EVENT:SetScore( ply, value )
        self.Scores[ply] = value
    end

    --- Called when a player grav punts a scrap
    --- @param ply Player
    --- @param _ Entity
    function EVENT:OnPuntScrap( ply, _ )
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

        if self:GetNW2Bool( ent, "IsScrap", false ) then
            return self:OnPuntScrap( ply, ent )
        end
    end

    function EVENT:SetupScoringModule()
        self:HookAdd( "GravGunPunt", "CheckPunt", function( ply, ent )
            return self:OnGravPunt( ply, ent )
        end )
    end
end
