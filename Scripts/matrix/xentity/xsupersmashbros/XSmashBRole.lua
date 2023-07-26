local XBaseRole = require("XEntity/XRole/XBaseRole")
--===========================
--超限乱斗角色对象
--模块负责：吕天元
--===========================
---@class XSmashBCharacter:XBaseRole
local XSmashBRole = XClass(XBaseRole, "XSmashBCharacter")

--==================
--构造函数
--@param
--rawData : XCharacter或XRobot
--==================
function XSmashBRole:Ctor(rawData)
    self.RawData = rawData
    self.EquipCore = nil
    self.HpLeft = 100
    self.SpLeft = 100
    self.EggOrgId = 0
    self.IsEggOpen = nil
    self.Unknown = nil
    self.ShowOrgEnable = nil
end
--==================
--获取剩余的生命值百分比
--==================
function XSmashBRole:GetHpLeft()
    return self.HpLeft
end
--==================
--设置剩余的生命值百分比
--==================
function XSmashBRole:SetHpLeft(value)
    self.HpLeft = value
end
--==================
--获取剩余的能量百分比
--==================
function XSmashBRole:GetSpLeft()
    return self.SpLeft
end
--==================
--设置剩余的能量百分比
--==================
function XSmashBRole:SetSpLeft(value)
    self.SpLeft = value
end
--==================
--获取正在装备的核心
--==================
function XSmashBRole:GetCore()
    if self.CoreId and self.CoreId > 0 then
        return XDataCenter.SuperSmashBrosManager.GetCoreById(self.CoreId)
    end
    return nil
end
--==================
--设置正在装备的核心Id
--==================
function XSmashBRole:SetCore(coreId)
    self.CoreId = coreId or 0
end
--==================
--设置为超限乱斗彩蛋机器人 并加入彩蛋配置 cxldV2
--==================
function XSmashBRole:SetSuperSmashEggRobot(config)
    self.IsEggRobot = true
    self.EggConfig = config
end
--==================
--是否为超限乱斗彩蛋机器人 cxldV2
--==================
function XSmashBRole:IsSmashEggRobot()
    return self.IsEggRobot
end
--==================
--获得彩蛋机器人揭开前的角色id cxldV2
--==================
function XSmashBRole:GetEggRobotOrgId()
    return self.EggOrgId
end
--==================
--设置是否显示彩蛋机器人原角色 在ready界面定义 cxldV2
--==================
function XSmashBRole:SetShowEggOrgCharEnable(flag)
    self.ShowOrgEnable = flag
end
--==================
--是否显示彩蛋机器人原角色 cxldV2
--==================
function XSmashBRole:GetShowEggOrgCharEnable(flag)
    return self.ShowOrgEnable
end
--==================
--设置彩蛋机器人揭开前的角色id cxldV2
--==================
function XSmashBRole:SetEggRobotOrgId(orgId)
    if not self:IsSmashEggRobot() then
        return
    end
    self.EggOrgId = orgId
end
--==================
--彩蛋是否已揭开 cxldV2
--==================
function XSmashBRole:GetIsEggOpen()
    if not self:IsSmashEggRobot() then
        return false
    end
    return self.IsEggOpen
end
--==================
--揭开彩蛋 cxldV2
--==================
function XSmashBRole:SetOpenEgg()
    if not self:IsSmashEggRobot() then
        self.IsEggOpen = false
        return
    end
    self.IsEggOpen = true
end
--==================
--关闭彩蛋且关闭彩蛋角色绑定 cxldV2
--==================
function XSmashBRole:SetCloseEgg()
    self.IsEggOpen = false
    self.EggOrgId = 0
end
--==================
--根据彩蛋是否揭开获取角色或者原角色 cxldV2
--==================
function XSmashBRole:GetOrgOrEggRoleByEggOpen()
    local char = nil
    if self:GetIsEggOpen() then
        char = XDataCenter.SuperSmashBrosManager.GetRoleById(self:GetEggRobotOrgId())
    else
        char = self
    end
    return char
end
--==================
--获取彩蛋配置 cxldV2
--==================
function XSmashBRole:GetEggConfig()
    return self.EggConfig
end
--==================
--设为强制随机的未知状态 cxldV2
--==================
function XSmashBRole:SetUnknown(flag)
    self.Unknown = flag
end
--==================
--获取强制随机状态 cxldV2
--==================
function XSmashBRole:GetIsUnknown()
    return self.Unknown
end
--==================
--获取当前角色战力
--==================
function XSmashBRole:GetAbility()
    local coreAbility = 0
    local core = self:GetCore()
    local manager = XDataCenter.SuperSmashBrosManager
    if core then
        coreAbility = (core:GetAtkLevel() * manager.GetAtkUpAbilityByLevel()) + (core:GetLifeLevel() * manager.GetLifeUpAbilityByLevel())
    end
    local teamLevelAbility = XDataCenter.SuperSmashBrosManager.GetNowTeamLevelConfig().AbilityUp
    return coreAbility + self:GetCharacterViewModel():GetAbility() + teamLevelAbility
end
--==================
--NpcId
--==================
--function XSmashBRole:GetNpcId()
--    --XCharacter或XRobot
--    if self.RawData.__cname == "XCharacter" then
--        return self.RawData.NpcId
--    end
--    if self.RawData.__cname == "XRobot" then
--        return self.RawData.Id
--    end
--    XLog.Error("[XSmashBRole] unhandled rawData")
--    return 0
--end
--==================
--援助技能
--==================
function XSmashBRole:GetAssistantSkillDesc()
    return XSuperSmashBrosConfig.GetAssistantSkillDesc(self)
end
--==================
--援助技能名称
--==================
function XSmashBRole:GetAssistantSkillName()
    return XSuperSmashBrosConfig.GetAssistantSkillName(self)
end

function XSmashBRole:IsNoCareer()
    return false
end

function XSmashBRole:GetAssistanceCharacterImg()
    local id = self:GetId()
    local config = XSuperSmashBrosConfig.GetCfgByIdKey(XSuperSmashBrosConfig.TableKey.Assistance, id, true)
    if config then
        return config.RoleCharacterBig
    end
end

return XSmashBRole