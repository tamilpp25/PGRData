--兵法蓝图角色模型类
local XRpgTowerCharacter = XClass(nil, "XRpgTowerCharacter")
local XRpgTowerTalent = require("XEntity/XRpgTower/XRpgTowerTalent")
local XRpgTowerItem = require("XEntity/XRpgTower/XRpgTowerItem")
--[[
*********属性说明
RCharaCfg 兵法蓝图角色配置
TalentIds 已激活的天赋ID列表
TalentPoints 剩余的天赋点
Order 在队伍列表中的位置
]]

--[[
================
构造函数
================
]]
function XRpgTowerCharacter:Ctor(characterId, teamOrder)
    self.RCharaCfg = XRpgTowerConfig.GetRCharacterCfgByCharacterIdAndLevel(characterId, 1)
    self.RBaseCharaCfg = XRpgTowerConfig.GetRBaseCharaCfgByCharacterId(characterId)
    self.RobotId = self.RCharaCfg.RobotId
    self.Order = teamOrder
    self.TalentType = 1
    self.TalentIds = {}
end
--[[
================
刷新角色数据(刷新角色数据时使用)
@param XRpgCharacterData: 通信用角色数据模型数据
================
]]
function XRpgTowerCharacter:RefreshCharacterData(XRpgCharacterData)
    self.RCharaCfg = XRpgTowerConfig.GetRCharacterCfgByCharacterIdAndLevel(XRpgCharacterData.CharacterId, XDataCenter.RpgTowerManager.GetCurrentLevel())
    self.RBaseCharaCfg = XRpgTowerConfig.GetRBaseCharaCfgByCharacterId(XRpgCharacterData.CharacterId)
    self.TalentPoint = XRpgTowerItem.New(XDataCenter.RpgTowerManager.GetTalentItemId())
    self.TalentTeamPoint = XRpgTowerItem.New(XDataCenter.RpgTowerManager.GetTalentItemId())
    self.Points = { self.TalentPoint, self.TalentTeamPoint}
    self.RobotId = self.RCharaCfg.RobotId
    self.TalentIds = self:InitTalentIds(XRpgCharacterData.TalentIds)
    self.TalentPoint:SetNum(XRpgCharacterData.TalentPoints)
    self.TalentTeamPoint:SetNum(XRpgCharacterData.TalentTeamPoints)
    self:ResetInfo()
    self:InitTalents()
    self.TalentType = XRpgCharacterData.UseTalentType
end

function XRpgTowerCharacter:ResetInfo()
    self:InitSkillInfo()
    self:InitAbility()
end
--[[
================
清空角色技能信息
================
]]
function XRpgTowerCharacter:InitSkillInfo()
    self.RoleListSkill = nil
end
--[[
================
清空角色战力信息
================
]]
function XRpgTowerCharacter:InitAbility()
    self.Ability = nil
end
--[[
================
初始化天赋开启数据
================
]]
function XRpgTowerCharacter:InitTalentIds(activeTalentIds)
    local talentActiveDic = {}
    for _, activeTalentId in pairs(activeTalentIds) do
        talentActiveDic[activeTalentId] = true
    end
    return talentActiveDic
end
--[[
================
初始化角色天赋信息
================
]]
function XRpgTowerCharacter:InitTalents()
    local talents = XRpgTowerConfig.GetTalentCfgsByCharacterId(self:GetCharacterId())
    self.Talents = {}
    self.Type2TalentsDic = {}
    for layerId, talentLayer in pairs(talents) do
        if not self.Talents[layerId] then self.Talents[layerId] = {} end
        for index, talentCfg in pairs(talentLayer) do
            if not self.Type2TalentsDic[talentCfg.TalentType] then
                self.Type2TalentsDic[talentCfg.TalentType] = {}
            end
            if not self.Type2TalentsDic[talentCfg.TalentType][layerId] then
                self.Type2TalentsDic[talentCfg.TalentType][layerId] = {}
            end
            local newTalent = XRpgTowerTalent.New(talentCfg.TalentId, self.TalentIds[talentCfg.TalentId], self)
            table.insert(self.Talents[layerId], newTalent)
            table.insert(self.Type2TalentsDic[talentCfg.TalentType][layerId], newTalent)
        end
        table.sort(self.Talents[layerId], function(rTalent1, rTalent2)
                return rTalent1:GetId() < rTalent2:GetId()
            end)
    end
    for _, talentDic in pairs(self.Type2TalentsDic) do
        for _, talentList in pairs(talentDic) do
            table.sort(talentList, function(rTalent1, rTalent2)
                    return rTalent1:GetId() < rTalent2:GetId()
                end)
        end
    end
end

--================
--获取角色ID
--================
function XRpgTowerCharacter:GetId()
    return self.RCharaCfg and self.RCharaCfg.CharacterId
end
--[[
================
获取角色ID
================
]]
function XRpgTowerCharacter:GetCharacterId()
    return self.RCharaCfg and self.RCharaCfg.CharacterId
end
--[[
================
获取机器人ID
================
]]
function XRpgTowerCharacter:GetRobotId()
    return self.RobotId
end
--[[
================
获取机器人配置
================
]]
function XRpgTowerCharacter:GetRobotCfg()
    return XRobotManager.GetRobotTemplate(self:GetRobotId())
end
--[[
================
获取角色在队伍中的排序
================
]]
function XRpgTowerCharacter:GetOrder()
    return self.Order
end
--[[
================
获取角色要展示的基础属性类型组数据
================
]]
function XRpgTowerCharacter:GetDisplayAttrTypeData()
    local attrData = {}
    for i in pairs(self.RBaseCharaCfg.DisplayAttriName) do
        local attr = {
            Name = self.RBaseCharaCfg.DisplayAttriName[i],
            Type = self.RBaseCharaCfg.DisplayAttriType[i]
        }
        table.insert(attrData, attr)
    end
    return attrData
end
--[[
================
获取角色战力
================
]]
function XRpgTowerCharacter:GetAbility()
    if self.Ability then return self.Ability end
    --二期简化了技能树类型，可以直接读取机器人表的ShowAbility
    self.Ability = XRobotManager.GetRobotAbility(self:GetRobotId())
    for _, talentLayer in pairs(self.Type2TalentsDic[self:GetCharaTalentType()] or {}) do
        for index, talent in pairs(talentLayer) do
            if talent:GetIsUnLock() then
                self.Ability = self.Ability + talent:GetSpecialAbility()
            end
        end
    end
    return self.Ability
end
--[[
================
获取角色四围属性值
================
]]
function XRpgTowerCharacter:GetCharaAttributes()
    local extraAttribIds = {}
    for _, talentLayer in pairs(self.Talents or {}) do
        for index, talent in pairs(talentLayer) do
            if talent:GetIsUnLock() then
                local attribId = talent:GetAttribPlus()
                if attribId then
                    table.insert(extraAttribIds, attribId)
                end
            end
        end
    end
    return XRobotManager.GetRobotAttribWithExtraAttrib(self.RobotId, extraAttribIds)
end
--[[
================
获取角色天赋属性加值
================
]]
function XRpgTowerCharacter:GetCharaTalentPlusAttr()
    local extraAttr
    for _, talentLayer in pairs(self.Talents) do
        for index, talent in pairs(talentLayer) do
            if talent:GetIsUnLock() then
                local attribId = talent:GetAttribPlus()
                if not extraAttr and attribId then
                    extraAttr = XTool.Clone(XAttribManager.GetAttribByAttribId(attribId))
                elseif attribId then
                    XAttribManager.DoAddAttribsByAttrAndAddId(extraAttr, attribId)
                end
            end
        end
    end
    return extraAttr
end
--[[
================
获取角色名称
================
]]
function XRpgTowerCharacter:GetCharaName()
    return XMVCA.XCharacter:GetCharacterName(self.RCharaCfg.CharacterId)
end
--[[
================
获取角色名称+型号全称
================
]]
function XRpgTowerCharacter:GetFullName()
    return XMVCA.XCharacter:GetCharacterFullNameStr(self.RCharaCfg.CharacterId)
end
--[[
================
获取角色型号名
================
]]
function XRpgTowerCharacter:GetModelName()
    return XMVCA.XCharacter:GetCharacterTradeName(self.RCharaCfg.CharacterId)
end
--[[
================
获取角色详细界面的技能列表
================
]]
function XRpgTowerCharacter:GetRoleListSkill()
    if self.RoleListSkill then return self.RoleListSkill end
    local skillData = XRobotManager.GetRobotSkillLevelDic(self:GetRobotId(), true)
    self.RoleListSkill = {}
    local removeNo = {
        [16] = true, -- 普通技能
        [18] = true,
        [21] = true,
        [22] = true,
        [23] = true
    } -- 队长技（SS,SSS,SSS+与终阶解放技能不展示，4期又改成要展示）
    local forceNo = {
        [24] = true, --SS
        [25] = true, --SSS
        [26] = true, --SSS+
        [27] = true  --终解
    }
    --增加角色天赋里面的技能增益
    local plusSkillData = self:GetSkillPlusData()
    for skillId, skillLevel in pairs(plusSkillData) do
        skillData[skillId] = skillData[skillId] + skillLevel
    end
    --按SkillId排序
    local tempList = {}
    local skillHead
    for skillId, skillLevel in pairs(skillData) do
        local skillNo = skillId % 100
        skillHead = math.floor(skillId / 100)
        if not removeNo[skillNo] then
            local skillInfo = XMVCA.XCharacter:GetSkillGradeDesWithDetailConfig(skillId, skillLevel)
            local tempData = { Order = skillId, Info = skillInfo}
            table.insert(tempList, tempData)
        end
        if forceNo[skillNo] then
            forceNo[skillNo] = false
        end
    end
    for skillNo, forceAdd in pairs(forceNo) do
        if forceAdd then
            local skillId = skillHead * 100 + skillNo
            local skillInfo = XMVCA.XCharacter:GetSkillGradeDesWithDetailConfig(skillId, 0)
            local tempData = { Order = skillId, Info = skillInfo}
            table.insert(tempList, tempData)
        end
    end
    table.sort(tempList, function(a,b) return a.Order < b.Order end)
    for i = 1, #tempList do
        table.insert(self.RoleListSkill, tempList[i].Info)
    end
    return self.RoleListSkill
end
--[[
================
获取角色技能天赋增加部分数据
================
]]
function XRpgTowerCharacter:GetSkillPlusData()
    local plusSkillData = {}
    if not self.Talents then return plusSkillData end
    --统计每个激活天赋增加的技能
    for _, talentLayer in pairs(self.Talents) do
        for index, talent in pairs(talentLayer) do
            if talent:GetIsUnLock() then
                local skillInfo = talent:GetSkillPlus()
                if skillInfo then
                    for skillId, addLevel in pairs(skillInfo) do
                        if not plusSkillData[skillId] then plusSkillData[skillId] = 0 end
                        plusSkillData[skillId] = plusSkillData[skillId] + addLevel
                    end
                end
            end
        end
    end
    return plusSkillData
end
--[[
================
获取角色小头像
================
]]
function XRpgTowerCharacter:GetSmallHeadIcon()
    local fashionId = XMVCA.XCharacter:GetCharacterTemplate(self.RCharaCfg.CharacterId).DefaultNpcFashtionId
    return XDataCenter.FashionManager.GetFashionSmallHeadIcon(fashionId)
end
--[[
================
获取角色大头像
================
]]
function XRpgTowerCharacter:GetBigHeadIcon()
    local fashionId = XMVCA.XCharacter:GetCharacterTemplate(self.RCharaCfg.CharacterId).DefaultNpcFashtionId
    return XDataCenter.FashionManager.GetFashionBigHeadIcon(fashionId)
end
--[[
================
获取角色职介图标
================
]]
function XRpgTowerCharacter:GetJobTypeIcon()
    local jobType = XRobotManager.GetRobotJobType(self.RobotId)
    return XMVCA.XCharacter:GetNpcTypeIcon(jobType)
end
--================
--获取角色品质图标
--================
function XRpgTowerCharacter:GetCharaQualityIcon()
    local cfg = XRobotManager.GetRobotTemplate(self.RobotId)
    return XMVCA.XCharacter:GetCharacterQualityIcon(cfg.CharacterQuality)
end
--================
--获取角色天赋类型
--================
function XRpgTowerCharacter:GetCharaTalentType()
    return self.TalentType or 1
end
--================
--设置角色天赋类型
--================
function XRpgTowerCharacter:SetTalentType(talentTypeId)
    if self.TalentType == talentTypeId then return end
    self.TalentType = talentTypeId
    self:ResetInfo()
end
--================
--获取角色天赋类型名称
--================
function XRpgTowerCharacter:GetCharaTalentTypeName()
    -- return XRpgTowerConfig.GetTalentTypeNameById(self.TalentType)
    return XRpgTowerConfig.GetTalentTypeConfigByCharacterId(self:GetId(), self.TalentType).Name
end
--[[
================
是否已经满级
================
]]
function XRpgTowerCharacter:GetIsMaxLevel()
    return self.RCharaCfg and (self:GetLevel() >= XDataCenter.RpgTowerManager.GetMaxLevel())
end
--================
--获取角色的天赋点
--================
function XRpgTowerCharacter:GetTalentPoints(talentTypeId)
    return self.Points[talentTypeId]:GetNum()
end
--================
--增加角色的天赋点
--================
function XRpgTowerCharacter:AddTalentPoints(addNum, talentTypeId)
    self.Points[talentTypeId]:AddNum(addNum)
end
--================
--获取角色的天赋对象列表
--================
function XRpgTowerCharacter:GetTalents(talentTypeId)
    if talentTypeId then
        return self.Type2TalentsDic[talentTypeId]
    else
        return self.Talents
    end
end
--================
--根据等级获取角色的天赋对象列表
--================
function XRpgTowerCharacter:GetTalentsByLayer(layer, talentTypeId)
    if talentTypeId then
        return self.Type2TalentsDic[talentTypeId][layer]
    else
        return self.Talents[layer]
    end
end
--================
--根据角色一览视图
--================
function XRpgTowerCharacter:GetCharacterViewModel()
    return XRobotManager.GetRobotById(self.RobotId):GetCharacterViewModel()
end
--================
--检查天赋层中没有可激活的天赋
--================
function XRpgTowerCharacter:CheckNoActiveByLayer(layer, talentTypeId)
    local talents = self:GetTalentsByLayer(layer, talentTypeId or self.TalentType or 1)
    local count = 0
    for _, talent in pairs(talents) do
        if talent:GetIsUnLock() then
            return false
        end
    end
    return true
end
--=================
--检查该天赋层是否只有1个以下天赋解锁
--=================
function XRpgTowerCharacter:CheckIsOneOrLessUnlockTalentInLayer(layer, talentTypeId)
    local talents = self:GetTalentsByLayer(layer, talentTypeId or self.TalentType or 1)
    local count = 0
    for _, talent in pairs(talents) do
        if talent:GetIsUnLock() then
            count = count + 1
            if count > 1 then return false end
        end
    end
    return true
end
--=================
--检查该天赋层是否有解锁的天赋
--=================
function XRpgTowerCharacter:CheckLayerHasUnLockTalent(layer, talentTypeId)
    local talents = self:GetTalentsByLayer(layer, talentTypeId or self.TalentType or 1)
    if not talents then return false end
    for _, talent in pairs(talents) do
        if talent:GetIsUnLock() then
            return true
        end
    end
    return false
end
--=================
--检查天赋是否能重置(单天赋重置时)
--=================
function XRpgTowerCharacter:CheckTalentCanReset(talent)
    local talentType = talent:GetTalentType()
    local layer = talent:GetLayer()
    if self:CheckIsOneOrLessUnlockTalentInLayer(layer) and
        self:CheckLayerHasUnLockTalent(layer + 1) then
        return false
    end
    return true
end
--[[
================
获取角色是否在出战队伍中
================
]]
function XRpgTowerCharacter:GetIsInTeam()
    return XDataCenter.RpgTowerManager.GetCharacterIsInTeam(self:GetCharacterId())
end
--[[
================
获取角色元素属性列表
================
]]
function XRpgTowerCharacter:GetElements()
    local detailElementsList = XMVCA.XCharacter:GetCharDetailTemplate(self:GetCharacterId())
    local elements = {}
    if detailElementsList then
        for i = 1, #detailElementsList.ObtainElementList do
            local elementConfig = XMVCA.XCharacter:GetCharElement(detailElementsList.ObtainElementList[i])
            elements[i] = elementConfig
        end
    end
    return elements
end
--[[
================
角色激活天赋
@param rTalent:天赋位置Id
================
]]
function XRpgTowerCharacter:TalentActive(rTalent, talentPoints)
    self.Points[rTalent:GetTalentType()]:SetNum(talentPoints)
    rTalent:UnLock()
    self:ResetInfo()
end
--[[
================
角色重置天赋
@param talentPoints:重置后的天赋点
================
]]
function XRpgTowerCharacter:CharacterReset(talentPoints, talentTypeId)
    self.Points[talentTypeId or self:GetCharaTalentType()]:SetNum(talentPoints)
    local talents
    talents = self.Type2TalentsDic[talentTypeId]
    for _, talentLayer in pairs(talents) do
        for index, talent in pairs(talentLayer) do
            talent:Lock()
        end
    end
    self:ResetInfo()
end
--================
--锁上一个天赋
--================
function XRpgTowerCharacter:LockOneTalent(talent)
    talent:Lock()
    local layer = talent:GetLayer()
    --检查所有重置天赋后面的下一层天赋
    local talents = self:GetTalentsByLayer(layer + 1, talent:GetTalentType())
    if talents then
        for _, talent in pairs(talents) do
            talent:CheckCanUnLock()
        end
    end
end
--[[
================
获取角色天赋道具
================
]]
function XRpgTowerCharacter:GetTalentItem(talentTypeId)
    return self.Points[talentTypeId]
end
--[[
================
检查角色是否有能激活的天赋
================
]]
function XRpgTowerCharacter:CheckCanActiveTalent()
    if not self.Talents then return false end
    for _, talentLayer in pairs(self:GetTalents(self:GetCharaTalentType())) do
        for index, talent in pairs(talentLayer) do
            if not talent:GetIsUnLock() and talent:GetCanUnLock() then return true end
        end
    end
    return false
end

return XRpgTowerCharacter