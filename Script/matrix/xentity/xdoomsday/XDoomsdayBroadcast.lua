

local XDoomsdayBroadcast = XClass(XDataEntityBase, "XDoomsdayBroadcast")

function XDoomsdayBroadcast:Ctor(type, count)
    self._Type = type
    self._Count = count or 0
end 

function XDoomsdayBroadcast:GetDesc()
    local desc = XDoomsdayConfigs.BroadcastConfig:GetProperty(self._Type, "Desc")
    if self._Type == XDoomsdayConfigs.BROADCAST_TYPE.DEATH then
        return string.format(desc, self._Count)
    end
    return desc
end 

function XDoomsdayBroadcast:GetIcon()
    return XDoomsdayConfigs.BroadcastConfig:GetProperty(self._Type, "Icon")
end

function XDoomsdayBroadcast:GetTitle()
    return XDoomsdayConfigs.BroadcastConfig:GetProperty(self._Type, "Title")
end

function XDoomsdayBroadcast:GetDuration()
    return XDoomsdayConfigs.BroadcastConfig:GetProperty(self._Type, "Duration")
end 

return XDoomsdayBroadcast