GEF = {}

if SERVER then
    util.AddNetworkString( "GEF_CreateEvent" )
    util.AddNetworkString( "GEF_EventMethod" )
    util.AddNetworkString( "GEF_ReloadEventClasses" )
    util.AddNetworkString( "GEF_StartSignup" )
    util.AddNetworkString( "GEF_EndSignup" )
    util.AddNetworkString( "GEF_SignupRequest" )

    AddCSLuaFile( "gef/sh_utils.lua" )
    AddCSLuaFile( "gef/cl_signup.lua" )
    AddCSLuaFile( "gef/sh_eventbase.lua" )
    AddCSLuaFile( "gef/sh_eventloader.lua" )
end

include( "gef/sh_utils.lua" )

if SERVER then
    include( "gef/sv_signup.lua" )
end

if CLIENT then
    include( "gef/cl_signup.lua" )
end

include( "gef/sh_eventbase.lua" )
include( "gef/sh_eventloader.lua" )

EVENT = {}
