---@class XReform2ndEnv
local XReform2ndEnv = XClass(nil, "XReform2ndEnv")

function XReform2ndEnv:Ctor(id)
    self._Id = id
end

function XReform2ndEnv:GetId()
    return self._Id
end

---@param model XReformModel
function XReform2ndEnv:GetName(model)
    return model:GetEnvironmentName(self._Id)
end

function XReform2ndEnv:GetIcon(model)
    return model:GetEnvironmentIcon(self._Id)
end

function XReform2ndEnv:GetAddScore(model)
    return model:GetEnvironmentAddScore(self._Id)
end

function XReform2ndEnv:GetDesc(model)
    return model:GetEnvironmentDesc(self._Id)
end

function XReform2ndEnv:GetTextIcon(model)
    local icon = model:GetEnvironmentTextIcon(self._Id)
    return icon
end

return XReform2ndEnv
