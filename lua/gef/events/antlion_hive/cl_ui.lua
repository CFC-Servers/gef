local tostring = tostring
local table_sort = table.sort
local math_Clamp = math.Clamp
local draw_RoundedBox = draw.RoundedBox
local surface_SetFont = surface.SetFont
local surface_DrawText = surface.DrawText
local surface_SetTextPos = surface.SetTextPos
local surface_GetTextSize = surface.GetTextSize
local surface_SetTextColor = surface.SetTextColor

surface.CreateFont( "GEF_AntlionHive_ScoreFont_Countdown", {
    font = "BudgetLabel",
    size = 36,
    weight = 900
} )

surface.CreateFont( "GEF_AntlionHive_ScoreFont_Score", {
    font = "DebugFixed",
    size = 38,
    weight = 700
} )


surface.CreateFont( "GEF_AntlionHive_ScoreFont_Details", {
    font = "Trebuchet MS",
    size = 40,
    weight = 700
} )

surface.CreateFont( "GEF_AntlionHive_ScoreFont_Details_Bold", {
    font = "Trebuchet MS",
    size = 40,
    weight = 900
} )


surface.CreateFont( "GEF_AntlionHive_ScoreFont", {
    font = "Trebuchet MS",
    size = 38,
    weight = 700
} )

surface.CreateFont( "GEF_AntlionHive_ScoreFont_Bold", {
    font = "Trebuchet MS",
    size = 38,
    weight = 900
} )


surface.CreateFont( "GEF_AntlionHive_ScoreFont_Header", {
    font = "Trebuchet MS",
    size = 44,
    weight = 900
} )


function EVENT:ShowScoreboard()
    local me = LocalPlayer()
    local kills = self.Kills
    local killsData = self.KillsData

    local function sorter( a, b )
        local aCount = a.count
        local bCount = b.count

        -- Sort first by count
        if aCount > bCount then
            return true
        end

        -- Then by name
        if aCount == bCount then
            return a.nick > b.nick
        end

        return false
    end

    self:TimerCreate( "ScoreSorter", 0.15, 0, function()
        table_sort( killsData, sorter )
    end )

    local function drawPlayerRow( i, row, x, y, w, h, yOffset )
        if i == 1 then
            surface_SetFont( "GEF_AntlionHive_ScoreFont_Bold" )
        else
            surface.SetFont( "GEF_AntlionHive_ScoreFont" )
        end

        surface_SetTextPos( x + (w * 0.1), y + (h * 0.016) + yOffset )
        surface_SetTextColor( row.r, row.g, row.b, 255 )
        surface_DrawText( row.nick )

        surface_SetFont( "GEF_AntlionHive_ScoreFont_Score" )

        local score = row.count
        local textWidth = surface_GetTextSize( tostring( score ) )

        -- Only draw special color if they have at least 1 kill
        if score > 0 then
            if i == 1 then
                -- Gold
                surface_SetTextColor( 255, 215, 0, 255 )
            elseif i == 2 then
                -- Silver
                surface_SetTextColor( 192, 192, 192, 255 )
            elseif i == 3 then
                -- Bronze
                surface_SetTextColor( 205, 127, 50, 255 )
            else
                -- White
                surface_SetTextColor( 255, 255, 255, 255 )
            end
        else
            -- White
            surface_SetTextColor( 255, 255, 255, 255 )
        end

        surface_SetTextPos( x + (w * 0.8) - textWidth, y + (h * 0.016) + yOffset )
        surface_DrawText( score )
    end

    local function drawScores( x, y, w, h )
        local yOffset = h * 0.1

        --- Max players to show on the scoreboard
        local maxPlayers = 10

        for i, row in ipairs( killsData ) do
            if i > maxPlayers then break end

            drawPlayerRow( i, row, x, y, w, h, yOffset )

            yOffset = yOffset + (h * 0.0733)
        end

        local myData = kills[me]
        if not myData then return end

        -- Draw personal score
        surface_SetFont( "GEF_AntlionHive_ScoreFont" )
        surface_SetTextColor( 255, 255, 255, 255 )
        surface_SetTextPos( x + w * 0.05, y + h - 42 )
        surface_DrawText( "You: " .. myData.count )
    end

    local function drawInfo( x, y )
        surface_SetFont( "GEF_AntlionHive_ScoreFont_Details" )
        surface_SetTextColor( 240, 245, 240, 255 )

        surface_SetTextPos( x + 10, y + 60 )
        surface_DrawText( "Hundreds of Antlions are pouring out of the hive" )

        surface_SetTextPos( x + 10, y + 95 )
        surface_DrawText( "Compete with other players and see who can get the most kills" )

        surface_SetFont( "GEF_AntlionHive_ScoreFont_Details_Bold" )
        surface_SetTextColor( 125, 255, 125, 255 )
        surface_SetTextPos( x + 10, y + 150 )
        surface_DrawText( "Join the battle by killing an Antlion!" )
    end

    local scoreBackground = Color( 0, 0, 0, 215 )
    local exclamation = Material( "icon16/exclamation.png" )

    local function drawBoard( color, w, h, drawContent )
        local x = -(w / 2)
        local y = -(h / 2)
        -- Draw outer rectangle with rounded corners
        draw_RoundedBox( 25, x, y, w, h, color )

        surface.SetDrawColor( 255, 255, 255, 255 )
        surface.SetMaterial( exclamation )
        surface.DrawTexturedRect( x + 12, y + 18, 28, 28 )

        -- Draw Header
        surface_SetFont( "GEF_AntlionHive_ScoreFont_Header" )
        surface_SetTextColor( 255, 65, 65, 255 )
        surface_SetTextPos( x + 48, y + 9 )
        surface_DrawText( "Antlion Attack!" )

        -- Draw Countdown
        surface_SetFont( "GEF_AntlionHive_ScoreFont_Countdown" )
        surface_SetTextColor( 255, 255, 255, 255 )

        local remaining = math.max( 0, self.EndTime - CurTime() )
        local fmt = string.FormattedTime( remaining, "%02i:%02i" )
        local size = surface_GetTextSize( fmt )
        surface_SetTextPos( (w / 2) - size - 10, y + 14 )
        surface_DrawText( fmt )

        drawContent( x, y, w, h )
    end

    local Lerp = Lerp
    local CurTime = CurTime

    local minScale, maxScale = 1, 2.5
    local minDot, maxDot = 0.92, 0.999
    local minZ, maxZ = 335, 925

    local maxDistance = 5000

    local vertOffset = Vector( 0, 0, 0 )
    local fadedBackground = Color( 0, 0, 0, 50 )

    local totalYaw = 0
    local ang = Angle( 180, 0, -90 )
    local spinAngle = Angle( 180, 0, -90 )
    self:HookAdd( "PostDrawTranslucentRenderables", "Scoreboard", function( _, skybox, skybox3d )
        if skybox3d then return end

        local ply = me

        local origin = self.Origin
        local distance = ply:GetPos():Distance( origin )
        if distance > maxDistance then return end

        local fraction = distance / maxDistance

        -- As the player gets farther away, the non-looked panel gets more transparent
        local alpha = Lerp( fraction, 100, 10 )
        fadedBackground.a = alpha

        -- As the player gets farther away, it goes farther off the ground
        local z = Lerp( fraction, minZ, maxZ )
        vertOffset:SetUnpacked( 0, 0, z )

        -- Orient the board correctly
        local pos = origin + vertOffset
        local dirToBoard = (pos - ply:GetPos()):GetNormalized()
        local plyForward = ply:EyeAngles():Forward()

        local looking = false
        local smoothing = 0.3

        -- As the player gets farther away, the "aim" window for the panel gets smaller
        local scaledDot = Lerp( fraction, minDot, maxDot )

        -- Face towards the player
        if dirToBoard:Dot( plyForward ) > scaledDot then
            local newAng = (ply:GetPos() - pos):Angle()
            newAng:RotateAroundAxis( newAng:Forward(), 90 )
            newAng:RotateAroundAxis( newAng:Right(), -90 )
            looking = true

            -- Limit how much the panel can "tilt" up and down to face the player
            ang = LerpAngle( smoothing, ang, newAng )
            ang.roll = math_Clamp( ang.roll, 50, 110 )
        else
            -- If not being looked at, do a nice slow circle animation
            local yaw = ((CurTime() * 10) + totalYaw) % 360

            -- Make sure the player only sees the text side
            local visibleSide = dirToBoard:Dot( spinAngle:Up() )
            if visibleSide >= 0 then
                -- If the panel is about to show its backside, do a seamless flip
                yaw = yaw + 180
                spinAngle.yaw = yaw
                ang:Set( spinAngle )

                totalYaw = totalYaw + 180
                if totalYaw == 360 then
                    totalYaw = 0
                end
            else
                -- Otherwise, perform a smooth translation from the last angle to the new one
                spinAngle.yaw = yaw
                ang = LerpAngle( smoothing, ang, spinAngle )
            end
        end

        -- It gets bigger when you get farther away
        local scale = Lerp( fraction, minScale, maxScale )
        cam.Start3D2D( pos, ang, scale )

        local participating = self:HasPlayer( me )
        local w, h, drawer

        if participating then
            w = 450
            h = 655
            drawer = drawScores
        else
            w = 975
            h = 215
            drawer = drawInfo
        end

        drawBoard( looking and scoreBackground or fadedBackground, w, h, drawer )

        cam.End3D2D()
    end )
end
