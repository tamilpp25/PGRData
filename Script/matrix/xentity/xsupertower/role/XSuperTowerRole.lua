local XSuperTowerPlugin = require("XEntity/XSuperTower/Plugin/XSuperTowerPlugin")
local XSuperTowerRole = XClass(nil, "XSuperTowerRole")

-- rawData : XCharacter | XRobot
function XSuperTowerRole:Ctor(rawData)
    -- XCharacter | XRobot
    self.RawData = rawData
    -- 超限解锁插件
    self.TransfinitePlugin = nil
    self.Id = self.RawData.Id
end

function XSuperTowerRole:GetId()
    return self.RawData.Id
end

-- 获取超级爬塔生命百分比(0-100)
function XSuperTowerRole:GetHpLeft()
    return XDataCenter.SuperTowerManager.GetRoleManager():GetTierRoleHpLeft(self:GetCharacterId())
end

-- 获取超限等级
function XSuperTowerRole:GetSuperLevel()
    return XDataCenter.SuperTowerManager.GetRoleManager():GetTransfiniteLevel(self:GetCharacterId())
end

function XSuperTowerRole:GetIsRobot()
    return XRobotManager.CheckIsRobotId(self.RawData.Id)
end

function XSuperTowerRole:GetCurrentExp()
    return XDataCenter.SuperTowerManager.GetRoleManager():GetTransfiniteExp(self:GetCharacterId())
end

function XSuperTowerRole:GetMaxExp(level)
    if level == nil then level = self:GetSuperLevel() end
    if level <= 0 then return 1 end
    local levelConfig = XSuperTowerConfigs.GetCharacterLevelConfig(self:GetCharacterId()
        , math.min(level + 1, self:GetMaxSuperLevel()))
    if levelConfig then
        return levelConfig.UpExp
    end
    levelConfig = XSuperTowerConfigs.GetCharacterLevelConfig(self:GetCharacterId(), level)
    return levelConfig.UpExp
end

-- 获取是否为特典中
function XSuperTowerRole:GetIsInDult()
    local superTowerManager = XDataCenter.SuperTowerManager
    -- 特典权限没开启不需要处理
    if not superTowerManager.CheckFunctionUnlockByKey(superTowerManager.FunctionName.BonusChara) then
        return false
    end
    local result, _ = superTowerManager.GetRoleManager():GetCharacterIsInDultAndConfig(self:GetCharacterId())
    return result
end

function XSuperTowerRole:GetTransfinitePlugin()
    if self.TransfinitePlugin == nil then
        local pluginConfig = XSuperTowerConfigs.GetCharacterPluginConfig(self:GetCharacterId())
        if not pluginConfig then return end
        self.TransfinitePlugin = XSuperTowerPlugin.New(pluginConfig.ActivatePlugin)
    end
    return self.TransfinitePlugin
end

function XSuperTowerRole:GetTransfinitePluginName()
    local pluginConfig = XSuperTowerConfigs.GetCharacterPluginConfig(self:GetCharacterId())
    if not pluginConfig then return "" end
    return pluginConfig.Name
end

function XSuperTowerRole:GetTransfinitePluginId()
    local pluginConfig = XSuperTowerConfigs.GetCharacterPluginConfig(self:GetCharacterId())
    if not pluginConfig then return -1 end
    return pluginConfig.ActivatePlugin
end

function XSuperTowerRole:GetTransfinitePluginDesc()
    local pluginConfig = XSuperTowerConfigs.GetCharacterPluginConfig(self:GetCharacterId())
    if not pluginConfig then return "" end
    return pluginConfig.Desc
end

function XSuperTowerRole:GetTransfinitePluginIsActive()
    local pluginId = XDataCenter.SuperTowerManager.GetRoleManager():GetTransfinitePluginId(self:GetCharacterId())
    return pluginId ~= nil
end

function XSuperTowerRole:GetCharacterViewModel()
    return self.RawData:GetCharacterViewModel()
end

function XSuperTowerRole:GetCharacterType()
    return self.RawData:GetCharacterViewModel():GetCharacterType()
end

function XSuperTowerRole:GetCharacterId()
    if XRobotManager.CheckIsRobotId(self.RawData.Id) then
        local robotConfig = XRobotManager.GetRobotTemplate(self.RawData.Id)
        return robotConfig.CharacterId
    else
        return self.RawData.Id
    end
end

function XSuperTowerRole:GetAbility(level)
    local superTowerManager = XDataCenter.SuperTowerManager
    if level == nil then level = self:GetSuperLevel() end
    local ablity = 0
    -- 要求超限权限开启才会显示这部分战力
    if level > 0 
        and superTowerManager.CheckFunctionUnlockByKey(superTowerManager.FunctionName.Transfinite) then
        local levelConfig = XSuperTowerConfigs.GetCharacterLevelConfig(self:GetCharacterId(), level)
        ablity = levelConfig.Ability
    end
    return ablity + self:GetCharacterViewModel():GetAbility()
end

function XSuperTowerRole:GetMaxSuperLevel()
    return XSuperTowerConfigs.GetCharacterMaxLevel(self:GetCharacterId())
end

-- attributeType : XNpcAttribType
function XSuperTowerRole:GetAttributeValue(attributeType, level)
    if level == nil then level = self:GetSuperLevel() end
    if level <= 0 then
        return 0
    end
    local levelConfig = XSuperTowerConfigs.GetCharacterLevelConfig(self:GetCharacterId(), level)
    for i, attributeId in ipairs(levelConfig.AttributeId) do
        if attributeId == attributeType then
            return levelConfig.AttributeValue[i]
        end
    end
    return 0
end

function XSuperTowerRole:GetSmallHeadIcon()
    if self:GetIsRobot() then
        return XRobotManager.GetRobotSmallHeadIcon(self.RawData.Id)
    else
        return XMVCA.XCharacter:GetCharSmallHeadIcon(self.RawData.Id)
    end
end

function XSuperTowerRole:GetCaptainSkillDesc()
    if self:GetIsRobot() then
        return XRobotManager.GetRobotCaptainSkillDesc(self.RawData.Id)
    else
        return XMVCA.XCharacter:GetCaptainSkillDesc(self.RawData.Id)
    end
end

function XSuperTowerRole:GetPartner()
    local result
    if XRobotManager.CheckIsRobotId(self.RawData.Id) then
        result = self.RawData:GetPartner()
    else
        result = XDataCenter.PartnerManager.GetCarryPartnerEntityByCarrierId(self.RawData.Id)
    end
    return result
end

function XSuperTowerRole:GetEquipViewModels()
    local result = {}
    if XRobotManager.CheckIsRobotId(self.RawData.Id) then
        result = self.RawData:GetEquipViewModels()
    end
    return result
end

return XSuperTowerRole
