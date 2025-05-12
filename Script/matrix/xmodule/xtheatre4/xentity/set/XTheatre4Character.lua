---@class XTheatre4Character
local XTheatre4Character = XClass(nil, "XTheatre4Character")

function XTheatre4Character:Ctor()
    -- 不等价角色ID， 这是肉鸽4内部ID
    self._Id = nil

    self._CharacterId = nil
    self._RobotId = nil
    self._StarGroupId = nil
    self._Desc = nil
end

function XTheatre4Character:SetFromConfig(config)
    self._Id = config
    self._CharacterId = config.CharacterId
    self._RobotId = config.RobotId
    self._StarGroupId = config.StarGroupId
    self._Desc = config.Desc
end

function XTheatre4Character:GetId()
    return self._Id
end

---@param character XTheatre4Character
function XTheatre4Character:Equals(character)
    if not character then
        return false
    end
    return self:GetId() == character:GetId()
end

function XTheatre4Character:GetModelId()
    local modelId
    if self._CharacterId and self._CharacterId > 0 then
        modelId = self._CharacterId
    elseif self._RobotId and self._RobotId > 0 then
        modelId = self._RobotId
    end
    return modelId
end

---@return XCharacterViewModel
function XTheatre4Character:GetViewModel()
    local viewModel
    if self._CharacterId and self._CharacterId > 0 then
        local character = XMVCA.XCharacter:GetCharacter(self._CharacterId)
        if character then
            viewModel = character:GetCharacterViewModel()
        end
    end
    if not viewModel then
        if self._RobotId and self._RobotId > 0 then
            local robot = XRobotManager.GetRobotById(self._RobotId)
            if robot then
                viewModel = robot:GetCharacterViewModel()
            end
        end
    end
    return viewModel
end

function XTheatre4Character:GetName()
    local viewModel = self:GetViewModel()
    if not viewModel then
        XLog.Error("[XTheatre4Character] 角色配置对应的viewModel不存在", self._CharacterId .. "|" .. self._RobotId)
        return ""
    end
    return viewModel:GetName()
end

function XTheatre4Character:GetFullName()
    local viewModel = self:GetViewModel()
    if not viewModel then
        XLog.Error("[XTheatre4Character] 角色配置对应的viewModel不存在", self._CharacterId .. "|" .. self._RobotId)
        return ""
    end
    return viewModel:GetFullName()
end

---@param model XTheatre4Model
function XTheatre4Character:GetStarGroup(model, star)
    local starConfig = model:GetCharacterStarConfigs()
    for i, config in pairs(starConfig) do
        if config.GroupId == self._StarGroupId and config.Star == star then
            return config.ColorLevel
        end
    end
    XLog.Error("[XTheatre4Character] 找不到角色对应的颜色配置", self._StarGroupId .. "|" .. star)
    return {}
end

return XTheatre4Character
