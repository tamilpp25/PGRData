-- 兵法蓝图天赋对象
local XRpgTowerTalent = XClass(nil, "XRpgTowerTalent")

function XRpgTowerTalent:Ctor(talentId, isUnLock, rChara)
    self.TalentCfg = XRpgTowerConfig.GetTalentCfgById(talentId)
    self.RCharacter = rChara
    if isUnLock then
        self:UnLock()
    else
        self:Lock()
    end
end
--================
--获取天赋ID
--================
function XRpgTowerTalent:GetId()
    return self.TalentCfg.TalentId
end
--================
--获取天赋是否解锁
--================
function XRpgTowerTalent:GetIsUnLock()
    return self.IsUnLock
end
--================
--获取天赋解锁所需天赋点
--================
function XRpgTowerTalent:GetTalentConsume()
    return self.TalentCfg.ConsumeCount
end
--================
--获取天赋名称
--================
function XRpgTowerTalent:GetTalentName()
    return self.TalentCfg.Name
end
--================
--获取天赋图标路径
--================
function XRpgTowerTalent:GetIconPath()
    return self.TalentCfg.Icon
end
--================
--获取天赋所属角色Id
--================
function XRpgTowerTalent:GetCharacterId()
    return self.TalentCfg.CharacterId
end
--================
--获取天赋技能描述
--================
function XRpgTowerTalent:GetDescription()
    return self.TalentCfg.Description
end
--================
--获取天赋属性加成Id
--================
function XRpgTowerTalent:GetAttribPlus()
    if not self.TalentCfg.AttribPoolGroupId then return nil end
    local groupAttrCfg = XAttribConfigs.GetAttribGroupCfgById(self.TalentCfg.AttribPoolGroupId)
    return groupAttrCfg and groupAttrCfg.AttribId
end
--================
--获取天赋技能加成
--skillInfo = { [skillId] = skillLevel ...}
--================
function XRpgTowerTalent:GetSkillPlus()
    if not self.TalentCfg.SkillIds then return {} end
    local skillInfo = {}
    for i = 1, #self.TalentCfg.SkillIds do
        skillInfo[self.TalentCfg.SkillIds[i]] = self.TalentCfg.SkillLevels[i]
    end
    return skillInfo
end
--================
--获取天赋特殊效果战力加成
--================
function XRpgTowerTalent:GetSpecialAbility()
    return self.TalentCfg.SpecialAbility or 0
end
--================
--获取天赋所属等级层
--================
function XRpgTowerTalent:GetLayer()
    return self.TalentCfg.LayerId
end
--================
--获取解锁天赋需要的等级
--================
function XRpgTowerTalent:GetNeedTeamLevel()
    if self.NeedTeamLevel then return self.NeedTeamLevel end
    local layer = self:GetLayer()
    local layerCfg = XRpgTowerConfig.GetTalentLayerCfgByLayerId(layer)
    self.NeedTeamLevel = layerCfg.NeedTeamLevel
    return self.NeedTeamLevel
end
--================
--获取天赋消耗点
--================
function XRpgTowerTalent:GetCost()
    return self.TalentCfg.ConsumeCount
end
--================
--获取天赋消耗字符串
--================
function XRpgTowerTalent:GetCostStr()
    local total = XDataCenter.RpgTowerManager.GetTeamMemberTalentPointsByCharacterId(self:GetCharacterId())
    local cost = self:GetCost()
    local str
    if total >= cost then
        str = CS.XTextManager.GetText("RpgTowerLevelUpCostStr", total, cost)
    else
        str = CS.XTextManager.GetText("RpgTowerLevelUpCostNotEnoughStr", total, cost)
    end
    return str
end
--================
--获取技能是否能解锁
--================
function XRpgTowerTalent:GetCanUnLock()
    if self.CanActive then
        return self.CanActive and (self:GetCost() <= XDataCenter.RpgTowerManager.GetTeamMemberTalentPointsByCharacterId(self:GetCharacterId()))
    end
    local layer = self:GetLayer()
    if layer > 1 then
        local preTalents = self.RCharacter:GetTalentsByLayer(layer - 1)
        local preActive = false
        for _, talent in pairs(preTalents) do
            if talent:GetIsUnLock() then
                preActive = true
                break
            end
        end
        local layerCfg = XRpgTowerConfig.GetTalentLayerCfgByLayerId(layer)
        local canActive = XDataCenter.RpgTowerManager.GetCurrentLevel() >= layerCfg.NeedTeamLevel and preActive
        self.CanActive = canActive
    else
        local layerCfg = XRpgTowerConfig.GetTalentLayerCfgByLayerId(layer)
        local canActive = XDataCenter.RpgTowerManager.GetCurrentLevel() >= layerCfg.NeedTeamLevel
        self.CanActive = canActive        
    end
    return self.CanActive and (self:GetCost() <= XDataCenter.RpgTowerManager.GetTeamMemberTalentPointsByCharacterId(self:GetCharacterId()))
end
--================
--检查角色是否足够改造点开启天赋
--================
function XRpgTowerTalent:CheckCostEnough()
    local talentPoints = XDataCenter.RpgTowerManager.GetTeamMemberTalentPointsByCharacterId(self:GetCharacterId())
    return self:GetCost() <= talentPoints
end
--================
--获取天赋是否已经到达要求队伍等级
--================
function XRpgTowerTalent:CheckNeedTeamLevel()
    local layerCfg = XRpgTowerConfig.GetTalentLayerCfgByLayerId(self:GetLayer())
    return XDataCenter.RpgTowerManager.GetCurrentLevel() >= layerCfg.NeedTeamLevel
end
--================
--解锁本天赋
--================
function XRpgTowerTalent:UnLock()
    self.IsUnLock = true
    if self.TalentCfg.ReplaceRobotId and self.TalentCfg.ReplaceRobotId > 0 then
        self.RCharacter:ReplaceRobot(self.TalentCfg.ReplaceRobotId)
    end
    XEventManager.DispatchEvent(XEventId.EVENT_RPGTOWER_ON_TALENT_UNLOCK, self)
end
--================
--锁上天赋（天赋重置时调用）
--================
function XRpgTowerTalent:Lock()
    self.IsUnLock = false
    self.CanActive = false
end
return XRpgTowerTalent