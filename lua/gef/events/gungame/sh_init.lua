EVENT.Name = "Gun Game"
EVENT.Description = "This is an example event."
EVENT.UsesTeams = false

function EVENT:Initialize()
    print( "Gun Game event initialized!" )
    self:StartSignup()
end

function EVENT:Start()
    print( "Gun Game event started!" )

    if SERVER then
        timer.Simple( 5, function()
            print "Gun Game event ended!"
            self:End()
        end )
    end
end

function EVENT:End()
    PrintMessage( HUD_PRINTTALK, "Gun Game event ended!" )
end
