GEF = {}

if SERVER then
    util.AddNetworkString( "GEF_StartEvent" )
    util.AddNetworkString( "GEF_EventMethod" )
    util.AddNetworkString( "GEF_ReloadEvents" )

    AddCSLuaFile( "gef/sh_eventbase.lua" )
    AddCSLuaFile( "gef/sh_eventloader.lua" )
    AddCSLuaFile( "gef/cl_eventrunner.lua" )
end

include( "gef/sh_eventbase.lua" )
include( "gef/sh_eventloader.lua" )

if SERVER then
    include( "gef/sv_eventrunner.lua" )
end

EVENT = {}
