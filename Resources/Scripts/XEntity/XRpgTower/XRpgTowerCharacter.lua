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
    self.RobotId = self.RCharaCfg.RobotId
    self.TalentIds = self:InitTalentIds(XRpgCharacterData.TalentIds)
    self.TalentPoint:SetNum(XRpgCharacterData.TalentPoints)
    self:ResetInfo()
    self:InitTalents()
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
    for layerId, talentLayer in pairs(talents) do
        if not self.Talents[layerId] then self.Talents[layerId] = {} end
        for index, talentCfg in pairs(talentLayer) do
            table.insert(self.Talents[layerId], XRpgTowerTalent.New(talentCfg.TalentId, self.TalentIds[talentCfg.TalentId], self)) 
        end
        table.sort(self.Talents[layerId], function(rTalent1, rTalent2)
                    return rTalent1:GetId() < rTalent2:GetId()
                end)
    end
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
    --[[
    self.Ability = 0
    --这里的角色属性已包含装备
    local robotAttrib = self:GetCharaAttributes()
    local attribAbility = XAttribManager.GetAttribAbility(robotAttrib)   
    --构建机器人技能数据
    local skillData = XRobotManager.GetRobotSkillLevelDic(self.RobotId)
    ]]
    if self.Talents then
        for _, talentLayer in pairs(self.Talents) do
            for index, talent in pairs(talentLayer) do
                if talent:GetIsUnLock() then
                    self.Ability = self.Ability + talent:GetSpecialAbility()
                    --[[
                    local skillInfo = talent:GetSkillPlus()
                    if skillInfo then
                        for skillId, addLevel in pairs(skillInfo) do
                            skillData[skillId] = skillData[skillId] + addLevel
                        end
                    end
                    ]]
                end
            end
        end
    end
    --local skillAbility = XDataCenter.CharacterManager.GetSkillAbility(skillData)   
    --self.Ability = self.Ability + attribAbility + skillAbility
    return self.Ability
end
--[[
================
获取角色四围属性值
================
]]
function XRpgTowerCharacter:GetCharaAttributes()
    local extraAttribIds = {}
    for _, talentLayer in pairs(self.Talents) do
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
    return XCharacterConfigs.GetCharacterName(self.RCharaCfg.CharacterId)
end
--[[
================
获取角色名称+型号全称
================
]]
function XRpgTowerCharacter:GetFullName()
    return XCharacterConfigs.GetCharacterFullNameStr(self.RCharaCfg.CharacterId)
end
--[[
================
获取角色型号名
================
]]
function XRpgTowerCharacter:GetModelName()
    return XCharacterConfigs.GetCharacterTradeName(self.RCharaCfg.CharacterId)
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
        [22] = true,
        [24] = true,
        [25] = true,
        [26] = true,
        [27] = true
    } -- 队长技，SS,SSS,SSS+与终阶解放技能不展示
    --增加角色天赋里面的技能增益
    local plusSkillData = self:GetSkillPlusData()
    for skillId, skillLevel in pairs(plusSkillData) do
        skillData[skillId] = skillData[skillId] + skillLevel
    end
    --按SkillId排序
    local tempList = {}
    for skillId, skillLevel in pairs(skillData) do
        local skillNo = skillId % 100
        if not removeNo[skillNo] then
            local skillInfo = XCharacterConfigs.GetSkillGradeDesConfig(skillId, skillLevel)
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
    local fashionId = XCharacterConfigs.GetCharacterTemplate(self.RCharaCfg.CharacterId).DefaultNpcFashtionId
    return XDataCenter.FashionManager.GetFashionSmallHeadIcon(fashionId)
end
--[[
================
获取角色大头像
================
]]
function XRpgTowerCharacter:GetBigHeadIcon()
    local fashionId = XCharacterConfigs.GetCharacterTemplate(self.RCharaCfg.CharacterId).DefaultNpcFashtionId
    return XDataCenter.FashionManager.GetFashionBigHeadIcon(fashionId)
end
--[[
================
获取角色职介图标
================
]]
function XRpgTowerCharacter:GetJobTypeIcon()
    local jobType = XRobotManager.GetRobotJobType(self.RobotId)
    return XCharacterConfigs.GetNpcTypeIcon(jobType)
end
--[[
================
是否已经满级
================
]]
function XRpgTowerCharacter:GetIsMaxLevel()
    return self.RCharaCfg and (self:GetLevel() >= XDataCenter.RpgTowerManager.GetMaxLevel())
end
--[[
================
获取角色的天赋点
================
]]
function XRpgTowerCharacter:GetTalentPoints()
    return self.TalentPoint:GetNum()
end
--[[
================
获取角色的天赋对象列表
================
]]
function XRpgTowerCharacter:GetTalents()
    return self.Talents
end
--================
--根据等级获取角色的天赋对象列表
--================
function XRpgTowerCharacter:GetTalentsByLayer(layer)
    return self.Talents[layer]
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
    local detailElementsList = XCharacterConfigs.GetCharDetailTemplate(self:GetCharacterId())
    local elements = {}
    if detailElementsList then
        for i = 1, #detailElementsList.ObtainElementList do
            local elementConfig = XCharacterConfigs.GetCharElement(detailElementsList.ObtainElementList[i])
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
    self.TalentPoint:SetNum(talentPoints)
    rTalent:UnLock()
    self:ResetInfo()
end
--[[
================
角色重置天赋
@param talentPoints:重置后的天赋点
================
]]
function XRpgTowerCharacter:CharacterReset(talentPoints)
    self.TalentPoint:SetNum(talentPoints)
    for _, talentLayer in pairs(self.Talents) do
        for index, talent in pairs(talentLayer) do
            talent:Lock()
        end
    end
    self:ResetInfo()
end
--[[
================
获取角色天赋道具
================
]]
function XRpgTowerCharacter:GetTalentItem()
    return self.TalentPoint
end
--[[
================
检查角色是否有能激活的天赋
================
]]
function XRpgTowerCharacter:CheckCanActiveTalent()
    if not self.Talents then return false end
    for _, talentLayer in pairs(self.Talents) do
        for index, talent in pairs(talentLayer) do
            if not talent:GetIsUnLock() and talent:GetCanUnLock() then return true end
        end
    end
    return false
end
return XRpgTowerCharacter