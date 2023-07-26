local type = type

--动作塔防插件数据
local XDoubleTowerPluginDb = XClass(nil, "XDoubleTowerPluginDb")

local Default = {
    _Id = 0,
    _Level = 0,
}

function XDoubleTowerPluginDb:Ctor()
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
end

function XDoubleTowerPluginDb:UpdateData(data)
    self._Id = data.Id
    self:SetLevel(data.Level)
end

function XDoubleTowerPluginDb:SetLevel(level)
    self._Level = level
end

function XDoubleTowerPluginDb:GetLevel()
    return self._Level
end

function XDoubleTowerPluginDb:GetId()
    return self._Id
end

return XDoubleTowerPluginDb