if GEF then
    for _, event in ipairs( GEF.ActiveEvents ) do
        print( "Cleaning up existing event:", event:GetID() )
        if event:IsValid() then
            event:Cleanup()
        end
    end
end

--- @class GEF
GEF = {}

if SERVER then
    util.AddNetworkString( "GEF_CreateEvent" )
    util.AddNetworkString( "GEF_EventMethod" )
    util.AddNetworkString( "GEF_ReloadEventClasses" )
    util.AddNetworkString( "GEF_StartSignup" )
    util.AddNetworkString( "GEF_EndSignup" )
    util.AddNetworkString( "GEF_SignupRequest" )
    util.AddNetworkString( "GEF_JoinRequest" )


    AddCSLuaFile( "gef/sh_utils.lua" )
    AddCSLuaFile( "gef/cl_signup.lua" )
    AddCSLuaFile( "gef/sh_eventbase.lua" )
    AddCSLuaFile( "gef/sh_eventloader.lua" )
end

include( "gef/sh_utils.lua" )

if SERVER then
    include( "gef/sv_signup.lua" )
    include( "gef/modules/sv_airstrike.lua" )
end

if CLIENT then
    include( "gef/cl_signup.lua" )
end

include( "gef/sh_eventbase.lua" )
include( "gef/sh_eventloader.lua" )

--- @class GEF_Event
EVENT = {}
