if SERVER then
    hook.Add( "GravGunPunt", "carpunt", function( ply, ent )
        if not ent.GEF_AstroScrappers_IsMeteor then return end
        if ply:GetNW2Bool( "GEF_AstroScrappers_HoldingScrap", false ) then return false end

        local plyTable = ply:GetTable()
        local currentTarget = plyTable.GEF_AstroScrappers_CurrentTarget
        if currentTarget ~= ent then
            plyTable.GEF_AstroScrappers_CurrentTarget = ent
            plyTable.GEF_AstroScrappers_Punts = 0
        end

        plyTable.GEF_AstroScrappers_Punts = plyTable.GEF_AstroScrappers_Punts + 1

        local resetTimer = "GEF_AstroScrappers_PuntReset_" .. ply:SteamID64()
        if plyTable.GEF_AstroScrappers_Punts >= puntsToGather then
            plyTable.GEF_AstroScrappers_Punts = 0
            plyTable.GEF_AstroScrappers_CurrentTarget = nil

            ply:SetNW2Bool( "GEF_AstroScrappers_HoldingScrap", true )

            timer.Remove( resetTimer )
            ent:Remove()
        else
            timer.Create( resetTimer, puntResetTime, 1, function()
                if not IsValid( ply ) then return end
                plyTable.GEF_AstroScrappers_Punts = 0
                plyTable.GEF_AstroScrappers_CurrentTarget = nil
            end )
        end
    end )
end

if CLIENT then
    net.Receive( "carlines", function()
        debugoverlay.Line( net.ReadVector(), net.ReadVector(), 4, color_white, false )
    end )

    net.Receive( "carhit", function()
    end )

    hook.Add( "GravGunPunt", "carpunt", function( ply, ent )
        if not ent:GetNW2Bool( "GEF_AstroScrappers_IsMeteor", false ) then return end
        if ply:GetNW2Bool( "GEF_AstroScrappers_HoldingScrap", false ) then
            if ply == LocalPlayer() then
                surface.PlaySound( "buttons/button16.wav" )
            end

            return false
        end
    end )
end
