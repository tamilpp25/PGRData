-- 虚像地平线角色对象
local XExpeditionCharacter = XClass(nil, "XExpeditionCharacter")
--================
--构造函数
--================
function XExpeditionCharacter:Ctor(baseCharaId, startRank)
    self:InitData(startRank, baseCharaId)
end
--================
--初始化数据
--================
function XExpeditionCharacter:InitData(startRank, baseCharaId)
    self:ResetData(startRank)
    self:RefreshData(baseCharaId)
end
--================
--使用玩法基础角色ID刷新角色数据
--@param baseCharaId:虚像地平线基础角色ID
--================
function XExpeditionCharacter:RefreshData(baseCharaId)
    if not baseCharaId then return end
    self.BaseECharaCfg = XExpeditionConfig.GetBaseCharacterCfgById(baseCharaId)
    self.ECharaCfg = XExpeditionConfig.GetCharacterCfgByBaseIdAndRank(baseCharaId, self.Rank)
    self.MaxRank = XExpeditionConfig.GetCharacterMaxRankByBaseId(baseCharaId)
end
--================
--初始化角色数据
--================
function XExpeditionCharacter:ResetData(startRank, notResetDefaultTeam)
    self.Rank = startRank or 1
    self.Ability = nil
    self.IsInTeam = false
    self.Attrib = nil
    self.IsDefaultTeamMember = notResetDefaultTeam and self.IsDefaultTeamMember
end
--================
--获取角色现在等级
--================
function XExpeditionCharacter:GetRank()
    return self.Rank or 1
end
--================
--获取角色等级展示字符串
--================
function XExpeditionCharacter:GetRankStr()
    local rank = self:GetRank()
    if rank >= self.MaxRank then return CS.XTextManager.GetText("ExpeditionMaxRank") end
    return rank
end
--================
--获取角色能量列表
--================
function XExpeditionCharacter:GetCharacterElements()
    return XExpeditionConfig.GetCharacterElementByBaseId(self:GetBaseId())
end
--================
--获取角色关联的羁绊列表
--================
function XExpeditionCharacter:GetCharacterComboIds()
    return self.BaseECharaCfg and self.BaseECharaCfg.ReferenceComboId or {}
end
--================
--获取预览羁绊列表
--================
function XExpeditionCharacter:GetPreviewCombos()
    return XDataCenter.ExpeditionManager.GetComboList():GetPreviewCombosWhenRecruit()
end
--================
--获取角色是否在队伍里
--================
function XExpeditionCharacter:GetIsInTeam()
    return self.IsInTeam
end
--================
--设置角色是否在队伍里
--================
function XExpeditionCharacter:SetIsInTeam(isInTeam)
    self.IsInTeam = isInTeam
end
--================
--设置角色等级
--@param newRank:要设置的角色等级
--================
function XExpeditionCharacter:SetRank(newRank)
    if (not newRank) or (newRank <= 0) then return end
    if newRank > self.MaxRank then newRank = self.MaxRank end
    self.Rank = newRank
    self.ECharaCfg = XExpeditionConfig.GetCharacterCfgByBaseIdAndRank(self.BaseECharaCfg.Id, self:GetRank())
    self.Ability = nil
    self.Attrib = nil
end
--================
--角色升级
--@param rankUpNum:升级数
--================
function XExpeditionCharacter:RankUp(rankUpNum)
    self:SetRank(self:GetRank() + rankUpNum)
end
--================
--获取角色机器人ID
--================
function XExpeditionCharacter:GetRobotId()
    return self.ECharaCfg and self.ECharaCfg.RobotId
end
--================
--获取角色的游戏角色基础ID(非玩法角色Id，Character表)
--================
function XExpeditionCharacter:GetCharacterId()
    return self.BaseECharaCfg and self.BaseECharaCfg.CharacterId
end
--================
--获取角色基础Id
--================
function XExpeditionCharacter:GetBaseId()
    return self.BaseECharaCfg and self.BaseECharaCfg.Id
end
--================
--获取角色具体星级配置ID
--================
function XExpeditionCharacter:GetECharaId()
    return self.ECharaCfg and self.ECharaCfg.Id
end
--================
--获取角色小头像
--================
function XExpeditionCharacter:GetSmallHeadIcon()
    local fashionId = XCharacterConfigs.GetCharacterTemplate(self:GetCharacterId()).DefaultNpcFashtionId
    return XDataCenter.FashionManager.GetFashionSmallHeadIcon(fashionId)
end
--================
--获取角色大头像
--================
function XExpeditionCharacter:GetBigHeadIcon()
    local fashionId = XCharacterConfigs.GetCharacterTemplate(self:GetCharacterId()).DefaultNpcFashtionId
    return XDataCenter.FashionManager.GetFashionBigHeadIcon(fashionId)
end
--================
--获取角色战力
--================
function XExpeditionCharacter:GetAbility()
    if self.Ability then return self.Ability end
    --这里的只计算机器人战力（含机器人装备）
    self.Ability = XRobotManager.GetRobotAbility(self:GetRobotId())
    return self.Ability
end
--================
--获取角色名称
--================
function XExpeditionCharacter:GetCharaName()
    return XCharacterConfigs.GetCharacterName(self:GetCharacterId())
end
--================
--获取角色机型名称
--================
function XExpeditionCharacter:GetCharacterTradeName()
    return XCharacterConfigs.GetCharacterTradeName(self:GetCharacterId())
end

function XExpeditionCharacter:GetCharaFullName()
    return XCharacterConfigs.GetCharacterFullNameStr(self:GetCharacterId())
end
--================
--获取角色属性值
--================
function XExpeditionCharacter:GetCharaAttributes()
    if not self.Attrib then self.Attrib = XRobotManager.GetRobotAttribs(self:GetRobotId()) end
    return self.Attrib
end
--================
--获取角色职业图标
--================
function XExpeditionCharacter:GetJobTypeIcon()
    local jobType = XRobotManager.GetRobotJobType(self:GetRobotId())
    return XCharacterConfigs.GetNpcTypeIcon(jobType)
end
--================
--获取角色可解锁技能列表
--================
function XExpeditionCharacter:GetLockSkill()
    if (not self.BaseECharaCfg) or (not self.BaseECharaCfg.LockSkill) then
        return {}
    end
    local skills = {}
    for index, skillId in pairs(self.BaseECharaCfg.LockSkill) do
        local skillInfo = XCharacterConfigs.GetSkillGradeDesConfig(skillId, self.BaseECharaCfg.SkillLevel[index])
        local skillData = {
            IconPath = skillInfo.Icon,
            Level = self.BaseECharaCfg.SkillLevel[index],
            SkillInfo = skillInfo,
            LockLevel = self.BaseECharaCfg.LockLevel[index],
            IsLock = self:GetRank() < self.BaseECharaCfg.LockLevel[index]
        }
        table.insert(skills, skillData)
    end
    return skills
end
--================
--获取角色是否已满级
--================
function XExpeditionCharacter:GetIsMaxLevel()
    return self:GetRank() >= self.MaxRank
end
--================
--获取角色是否状态被更新(用于招募后判断是否播放更新特效，一次性取值)
--================
function XExpeditionCharacter:GetIsNew()
    if self.IsNew then self.IsNew = false return true end
    return false
end
--================
--设置角色被更新状态
--================
function XExpeditionCharacter:SetIsNew()
    self.IsNew = true
end
--================
--获取是否空白角色对象
--================
function XExpeditionCharacter:GetIsBlank()
    return not self.BaseECharaCfg
end
--================
--设置是否预设队伍角色
--================
function XExpeditionCharacter:SetDefaultTeamMember(value)
    self.IsDefaultTeamMember = value
end
--================
--获取是否预设队伍角色
--================
function XExpeditionCharacter:GetIsDefaultTeamMember()
    return self.IsDefaultTeamMember
end
--================
--获取角色基础Id
--================
function XExpeditionCharacter:Fired(notResetDefaultTeam)
    self:ResetData(nil, notResetDefaultTeam)
    self.ECharaCfg = XExpeditionConfig.GetCharacterCfgByBaseIdAndRank(self:GetBaseId(), self:GetRank())
end
--================
--获取机器人装备
--================
function XExpeditionCharacter:GetWeaponViewModel()
    local entity = XRobotManager.GetRobotById(self:GetRobotId())
    return entity and entity:GetWeaponViewModel()
end
--================
--获取机器人意识
--================
function XExpeditionCharacter:GetAwarenessViewModelDic(siteId)
    local entity = XRobotManager.GetRobotById(self:GetRobotId())
    local dic = entity:GetAwarenessViewModelDic()
    return dic[siteId]
end

return XExpeditionCharacter