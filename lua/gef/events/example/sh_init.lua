EVENT.PrintName = "Example Event"
EVENT.Description = "This is an example event."
EVENT.Teams = {
    {
        Name = "Attackers",
        Color = Color( 255, 0, 0 ),
    },
    {
        Name = "Defenders",
        Color = Color( 0, 0, 255 ),
    },
}

function EVENT:Initialize( pos, ang )
    self:StartSignup( {
        -- The message header
        Message = "Sign up for the Example event!",

        -- The details of the event on the signup form
        Details = "Two teams fight in an Example arena, the team with the most Examples by the end of the event wins!",

        MinPlayers = 2,
        MaxPlayers = 20,

        -- How long the signup process takes. Ends early if the Maximum players have signed up
        Duration = 5 * 60,

        -- If players should be evenly distributed between teams when the event starts
        AutoBalance = true,

        -- If players should be able to select their preferred team
        TeamSelect = true
    } )

    self:SpawnArena( pos, ang )

    self:CreateEventZone( {
        -- The center of the event zone
        Position = pos,
        Angles = ang,

        -- If the event zone should be a sphere or a box
        Sphere = true,

        -- The size of the event zone in units
        Size = 1000,

        -- If the event zone should be visible to players
        Visible = true,

        PreventNoclip = true,
        PreventExternalEntities = true,

        -- Prevents players from spawning their own weapons
        PreventWeaponSpawns = true,
        PreventWeaponPickups = false,


        -- How to handle Intruders:

        -- Teleports the player back to a default spawn position (or something)
        TeleportIntruders = true,
        BounceIntruders = false,
        KillIntruders = false
    } )
end

function EVENT:OnStarted()
    -- This is called when the event starts
    -- This is where you should spawn the players and do any other setup

    for _, ply in ipairs( self:GetTeamPlayers( "Attackers" ) ) do
        self:SetupAttacker( ply )
    end

    for _, ply in ipairs( self:GetTeamPlayers( "Defenders" ) ) do
        self:SetupDefender( ply )
    end

    self:StartRound()
end

function EVENT:SignupComplete( participants )
    -- This is called when the signup process is complete

    for _, participant in ipairs( participants ) do
        local ply = participant.Player
        local teamIndex = participant.TeamIndex

        ply.EventTeam = self.Teams[teamIndex]
    end

    -- Send a message to all participants
    self:SendEventMessage( "The Event is starting! Participants will be teleported to the staging area in 10 seconds." )

    -- Send a message about the event to everyone
    self:BroadcastMessage( "The Example Event is starting! Signup is now closed." )

    timer.Simple( 10, function()
        self:Start()
    end )
end

