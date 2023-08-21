GEF = {}
GEF.Events = {}

function GEF.addEvent( name, data )
    local events = GEF.Events[name]
    if not events then
        events = {}
        GEF.Events[name] = events
    end

    table.insert( events, data )
end

--- @return EventData
function GEF.EventData()
    --- @class EventData
    local data = {}

    do
        --- Set the Angles for the Event
        --- @param angles Angle
        function data:SetAngles( angles )
            self._angles = angles
        end

        --- Get the Angles for the Event
        --- @return Angle
        function data:GetAngles()
            return self._angles
        end
    end

    do
        --- Set the Color for the Event
        --- @param color Color
        function data:SetColor( color )
            self._color = color
        end

        --- Get the Color for the Event
        --- @return Color
        function data:GetColor()
            return self._color
        end
    end

    do
        --- Set the Origin for the Event
        --- @param origin Vector
        function data:SetOrigin( origin )
            self._origin = origin
        end

        --- Get the Origin for the Event
        --- @return Vector
        function data:GetOrigin()
            return self._origin
        end
    end

    return data
end

--- @param name string
--- @param data EventData
function GEF.Event( name, data )
end


