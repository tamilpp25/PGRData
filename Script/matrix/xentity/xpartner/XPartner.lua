local XPartnerMainSkillGroup = require("XEntity/XPartner/XPartnerMainSkillGroup")
local XPartnerPassiveSkillGroup = require("XEntity/XPartner/XPartnerPassiveSkillGroup")
local XPartnerBase = require("XEntity/XPartner/XPartnerBase")

---@class XPartner : XPartnerBase
local XPartner = XClass(XPartnerBase, "XPartner")
local DefaultQuality = 1
local DefaultBreakthrough = 0
local MoneyIndex = 1

function XPartner:Ctor(id, templateId, isComplete, IsPreview)
    self.Id = id--Id
    self.TemplateId = templateId--伙伴Id
    self.Name = ""--名字
    self.CharacterId = 0--被携带的角色
    self.Level = 1--等级
    self.Exp = 0--经验值
    self.BreakThrough = 0--突破次数
    self.Quality = self:GetInitQuality()
    self.IsLock = false--是否上锁
    self.StarSchedule = 0--进化节点进度
    self.SkillList = {}--技能列表
    self.UnlockSkillGroup = {}--解锁技能组列表
    self.CreateTime = 0--创建时间
    
--------------------------------------------------------
    self.IsPreview = IsPreview--是否是预览模式 为true时主动技能会按照默认装备技能组来初始化可以不用设置SkillList和UnlockSkillGroup
    self.Ability = nil
    self.IsComplete = isComplete--是否完整（合成界面非完整）
    self.ChipBaseCount = 0--当前持有碎片
    self.StackCount = 0--堆叠数
    self.BreakthroughLimit = XPartnerConfigs.GetPartnerBreakthroughLimit(self.TemplateId)--最大突破次数
    self.QualityLimit = XPartnerConfigs.GetQualityLimit(self.TemplateId)--最大品质
    self.MainSkillGroupEntityDic = {}
    self.PassiveSkillGroupEntityDic = {}
    self.UnlockSkillGroupDic = {}
    self.StoryEntityDic = {}
-------------------------------------------------
    -- 是否属于自身玩家的或非玩家的(好友)
    -- 默认都是属于自己的，目前在好友展示详情创建的伙伴数据是不属于自己的
    self.IsBelongSelf = true

    self:InitChipBaseCount()
    self:InitPartnerSkill()
    self:CreateSkillEntityDic()
    self:CreateStoryEntityDic()
end

function XPartner:UpdateData(data)
    if type(data) == "table" then
        for key, value in pairs(data or {}) do
            self[key] = value
        end
    else
        local tmpData = XTool.CsObjectFields2LuaTable(data)
        for key, value in pairs(tmpData or {}) do
            self[key] = value
        end
    end
    self:ResetAbility()
    self:UpdateSkillEntity()
end

function XPartner:InitPartnerSkill()
    local mainSkillCount = self:GeMainSkillCount()
end

function XPartner:InitChipBaseCount()--设置基础碎片
    if self.IsComplete then
        self.ChipBaseCount = self:GetChipNeedCount()
    end
end

function XPartner:ResetAbility()--重置战力
    self.Ability = nil
end
-------------------------宠物功能属性--------------------------
function XPartner:GetId()
    return self.Id
end

function XPartner:GetName()
    if not self.IsBelongSelf then
        return self:GetOriginalName()
    end
    if not self.Name or self.Name == "" then
        return self:GetOriginalName()
    end
    return self.Name
end

function XPartner:GetTemplateId()
    return self.TemplateId
end

function XPartner:GetCharacterId()
    return self.CharacterId
end

function XPartner:GetCreateTime()
    return self.CreateTime
end

function XPartner:GetQuality()
    return self.Quality == 0 and self:GetInitQuality() or self.Quality
end

function XPartner:GetQualityIcon()
    return XCharacterConfigs.GetCharQualityIcon(self:GetQuality())
end

function XPartner:GetCharacterQualityIcon()
    return XCharacterConfigs.GetCharacterQualityIcon(self:GetQuality())
end

function XPartner:GetQualityLimit()
    return self.QualityLimit
end

function XPartner:GetLevel()
    return self.Level
end

function XPartner:GetExp()
    return self.Exp
end

function XPartner:GetBreakthrough()
    return self.BreakThrough
end

function XPartner:GetBreakthroughIcon()
    return XPartnerConfigs.GetPartnerBreakThroughIcon(self.BreakThrough)
end

function XPartner:GetBreakthroughLimit()
    return self.BreakthroughLimit
end

function XPartner:GetIsLock()
    return self.IsLock
end

function XPartner:SetIsLock(isLock) --设置是否上锁
    self.IsLock = isLock
end

function XPartner:GetStarSchedule()
    return self.StarSchedule
end

function XPartner:GetSkillList()
    return self.SkillList
end

function XPartner:GetStackCount()
    return self:GetIsByOneself() and self.StackCount or 0
end

function XPartner:GetChipCurCount()--当前持有碎片数（基础+升阶进度）
    return self.ChipBaseCount + self.StarSchedule
end

function XPartner:GetIsCanCompose()--能够合成(必须要非完整)
    return not self.IsComplete and self.ChipBaseCount >= self:GetChipNeedCount()
end

function XPartner:GetIsCarry()--是否被装备
    return self.CharacterId > 0
end

function XPartner:GetIsByOneself()
    local IsNotHasExp = self.Exp == 0
    local IsNotBreakthrough = self.BreakThrough == 0
    local IsNotLevel = self.Level == 1
    local IsNotEatPartner = self:GetStarSchedule() == 0
    local IsNotUpQuality = self.Quality == self:GetInitQuality()
    local IsNotUpSkill = self:CheckIsNotUpSkill()
    local IsNotChangeSkill = self:IsNotChangeSkill()
    local IsNotLock = not self.IsLock
    local IsNotUsed = not self:GetIsCarry()
    local IsNotChangeName = self:GetName() == self:GetOriginalName()

    return IsNotHasExp and
    IsNotBreakthrough and
    IsNotLevel and
    IsNotEatPartner and
    IsNotUpQuality and
    IsNotUpSkill and
    IsNotChangeSkill and
    IsNotLock and
    IsNotUsed and
    IsNotChangeName
end

function XPartner:GetIsNotTraining()
    local IsNotHasExp = self.Exp == 0
    local IsNotBreakthrough = self.BreakThrough == 0
    local IsNotLevel = self.Level == 1
    local IsNotEatPartner = self:GetStarSchedule() == 0
    local IsNotUpQuality = self.Quality == self:GetInitQuality()
    local IsNotUpSkill = self:CheckIsNotUpSkill()
  

    return IsNotHasExp and
    IsNotBreakthrough and
    IsNotLevel and
    IsNotEatPartner and
    IsNotUpQuality and
    IsNotUpSkill
end

function XPartner:GetIsMaxBreakthrough()
    return self.BreakThrough >= self.BreakthroughLimit
end

function XPartner:GetIsMaxQuality()
    return self.Quality >= self.QualityLimit
end

function XPartner:GetAttribs(level)
    return XFightPartnerManager.GetPartnerAttribs(self, level)
end

function XPartner:GetPartnerAttrMap(level)
    local partnerAttrMap = XDataCenter.PartnerManager.ConstructPartnerAttrMap(self:GetAttribs(level), false, false)
    return partnerAttrMap
end

function XPartner:GetSkillAbility()
    local skillAbility = 0
    for _, groupEntity in pairs(self.MainSkillGroupEntityDic or {}) do
        if groupEntity:GetIsCarry() then
            skillAbility = skillAbility + groupEntity:GetActiveSkillAbility()
        end
    end

    for _, groupEntity in pairs(self.PassiveSkillGroupEntityDic or {}) do
        if groupEntity:GetIsCarry() then
            skillAbility = skillAbility + groupEntity:GetActiveSkillAbility()
        end
    end
    return skillAbility
end

function XPartner:GetAbility() --获取宠物战力
    if not self.Ability then
        local baseAbility = XAttribManager.GetPartnerAttribAbility(self:GetAttribs()) or 0
        local skillAbility = self:GetSkillAbility()
        self.Ability = XMath.ToMinInt(baseAbility + skillAbility)
    end
    return self.Ability
end

-----------------------------宠物品质--------------------------------
function XPartner:GetQualityCfg(tagQuality)--无参代表当前品质
    return XPartnerConfigs.GePartnerQualityByIdAndNum(self.TemplateId, tagQuality or self.Quality) or {}
end

function XPartner:GetQualitySkillColumnCount(tagQuality)
    return self:GetQualityCfg(tagQuality).SkillColumnCount
end

function XPartner:GetQualityEvolutionAttribId(tagQuality)
    return self:GetQualityCfg(tagQuality).EvolutionAttrId
end

function XPartner:GetQualityEvolutionCostItemId(tagQuality)
    return self:GetQualityCfg(tagQuality).EvolutionCostItemId
end

function XPartner:GetQualityEvolutionCostItemCount(tagQuality)
    return self:GetQualityCfg(tagQuality).EvolutionCostItemCount
end

function XPartner:GetQualityEvolutionCostItem(tagQuality)
    local itemlist = {}
    local itemIdlist = self:GetQualityEvolutionCostItemId(tagQuality)
    local itemCountlist = self:GetQualityEvolutionCostItemCount(tagQuality)
    for index,id in pairs(itemIdlist or {}) do
        local tmpData = {
            Id = id,
            Count = itemCountlist[index] or 0,
        }
        itemlist[index] = tmpData
    end
    return itemlist
end

function XPartner:GetQualityEvolutionMoney(tagQuality)
    return self:GetQualityEvolutionCostItem(tagQuality)[MoneyIndex]
end

function XPartner:GetQualityEvolutionItem(tagQuality)
    local list = self:GetQualityEvolutionCostItem(tagQuality)
    table.remove(list, MoneyIndex)
    return list
end

function XPartner:GetQualityStarCostChipCount(tagQuality)
    return self:GetQualityCfg(tagQuality).StarCostChipCount
end

function XPartner:GetQualityStarAttribId(tagQuality)
    return self:GetQualityCfg(tagQuality).AttrId
end

function XPartner:GetQualityStarAttribs(tagQuality)
    local attribList = {}
    local attribIdList = self:GetQualityStarAttribId(tagQuality)
    for _,id in pairs(attribIdList or {}) do
        table.insert(attribList, XAttribManager.GetBaseAttribs(id))
    end
    return attribList
end

function XPartner:GetCanActivateStarCount(tagQuality, chipCount)--已激活多少个星
    local starCostList = self:GetQualityStarCostChipCount(tagQuality)
    local curStarCount = 0
    local curChipCount = chipCount or self.StarSchedule
    for index,starCost in pairs(starCostList or {}) do
        if curChipCount >= starCost and index > curStarCount then
            curStarCount = index
        end
    end
    return curStarCount
end

function XPartner:GetMaxStarCount(tagQuality)
    local starCostList = self:GetQualityStarCostChipCount(tagQuality)
    return #starCostList
end

function XPartner:GetCanUpQuality(tagQuality)
    local curStarCount = self:GetCanActivateStarCount(tagQuality)
    return curStarCount >= self:GetMaxStarCount()
end

function XPartner:GetClipMaxCount(tagQuality)
    local starCostList = self:GetQualityStarCostChipCount(tagQuality)
    return starCostList[#starCostList]
end
-----------------------------宠物突破------------------------------------
function XPartner:GetBreakthroughCfg(tagBreakthrough)--无参代表当前突破层数
    return XPartnerConfigs.GetPartnerBreakthroughByIdAndNum(self.TemplateId, tagBreakthrough or self.BreakThrough) or {}
end

function XPartner:GetBreakthroughLevelLimit(tagBreakthrough)
    return self:GetBreakthroughCfg(tagBreakthrough).LevelLimit
end

function XPartner:GetBreakthroughAttribId(tagBreakthrough)
    return self:GetBreakthroughCfg(tagBreakthrough).AttribId
end

function XPartner:GetBreakthroughAttribPromotedId(tagBreakthrough)
    return self:GetBreakthroughCfg(tagBreakthrough).AttribPromotedId
end

function XPartner:GetBreakthroughLevelUpTemplateId(tagBreakthrough)
    return self:GetBreakthroughCfg(tagBreakthrough).LevelUpTemplateId
end

function XPartner:GetBreakthroughCostItemId(tagBreakthrough)
    return self:GetBreakthroughCfg(tagBreakthrough).CostItemId
end

function XPartner:GetBreakthroughCostItemCount(tagBreakthrough)
    return self:GetBreakthroughCfg(tagBreakthrough).CostItemCount
end

function XPartner:GetBreakthroughCostItem(tagBreakthrough)
    local itemlist = {}
    local itemIdlist = self:GetBreakthroughCostItemId(tagBreakthrough)
    local itemCountlist = self:GetBreakthroughCostItemCount(tagBreakthrough)
    for index,id in pairs(itemIdlist or {}) do
        local tmpData = {
            Id = id,
            Count = itemCountlist[index] or 0,
        }
        itemlist[index] = tmpData
    end
    return itemlist
end

function XPartner:GetBreakthroughMoney(tagBreakthrough)
    return self:GetBreakthroughCostItem(tagBreakthrough)[MoneyIndex]
end

function XPartner:GetBreakthroughItem(tagBreakthrough)
    local list = self:GetBreakthroughCostItem(tagBreakthrough)
    table.remove(list, MoneyIndex)
    return list
end

function XPartner:GetIsLevelMax(tagBreakthrough)
    return self.Level >= self:GetBreakthroughLevelLimit(tagBreakthrough)
end

function XPartner:GetBreakthroughPromotedAttrMap(preBreakthrough)
    local attribPromotedId = self:GetBreakthroughAttribPromotedId(preBreakthrough)
    local map = XAttribManager.GetPromotedAttribs(attribPromotedId)
    return XDataCenter.PartnerManager.ConstructPartnerAttrMap(map, false, true)
end
-------------------------宠物等级------------------------------------

function XPartner:GetLevelUpCfg(tagBreakthrough, level)
    local levelUpTemplateId = self:GetBreakthroughLevelUpTemplateId(tagBreakthrough)
    return XPartnerConfigs.GetPartnerLevelUpTemplateByIdAndLevel(levelUpTemplateId, level or self.Level) or {}
end

function XPartner:GetLevelUpInfoExp(tagBreakthrough, level)
    return self:GetLevelUpCfg(tagBreakthrough, level).Exp
end

function XPartner:GetLevelUpInfoAllExp(tagBreakthrough, level)
    return self:GetLevelUpCfg(tagBreakthrough, level).AllExp
end

function XPartner:GetPartnerLevelTotalNeedExp(targetLevel)
    local totalExp = 0
    for level = self.Level, targetLevel - 1 do
        totalExp = totalExp + self:GetLevelUpInfoExp(nil, level)
    end
    totalExp = totalExp - self:GetExp()
    return totalExp
end

-------------------------宠物技能------------------------------------
function XPartner:CreateSkillEntityDic()
    self.MainSkillGroupEntityDic = {}
    self.PassiveSkillGroupEntityDic = {}
    
    for _,mainSkillGrpupId in pairs(self:GetMainSkillGroupIdList() or {}) do
        local IsDefaultSkillGroup = mainSkillGrpupId == self:GetDefaultSkillGroupId()
        self.MainSkillGroupEntityDic[mainSkillGrpupId] = XPartnerMainSkillGroup.New(mainSkillGrpupId, IsDefaultSkillGroup, self.IsPreview)
    end
    for _,passiveSkillGrpupId in pairs(self:GetPassiveSkillGroupIdList() or {}) do
        self.PassiveSkillGroupEntityDic[passiveSkillGrpupId] = XPartnerPassiveSkillGroup.New(passiveSkillGrpupId)
    end
end

function XPartner:UpdateSkillEntity()
    self.UnlockSkillGroupDic = {}
    for _,skillId in pairs(self.UnlockSkillGroup or {}) do
        self.UnlockSkillGroupDic[skillId] = true
    end
 -------------------------更新当前技能数据-----------------------------
    local carringMainSkillLevel = 1 --暂时只有一个主技能组
    local carringMainSkillGroupId = 0
    for _,skilldata in pairs(self.SkillList or {}) do
        local tmpData = {}
        tmpData.Level = skilldata.Level
        tmpData.IsCarry = skilldata.IsWear
        tmpData.ActiveSkillId = skilldata.Id
       
        if skilldata.Type == XPartnerConfigs.SkillType.MainSkill then
            local groupId = XPartnerConfigs.GetMainSkillGroupById(skilldata.Id)
            self.MainSkillGroupEntityDic[groupId]:UpdateData(tmpData)
            carringMainSkillLevel = tmpData.Level --暂时只有一个主技能组
            carringMainSkillGroupId = groupId --暂时只有一个主技能组
        elseif skilldata.Type == XPartnerConfigs.SkillType.PassiveSkill then
            local groupId = XPartnerConfigs.GetPassiveSkillGroupById(skilldata.Id)
            self.PassiveSkillGroupEntityDic[groupId]:UpdateData(tmpData)
        end
    end
    -------------------------更新主动技能携带情况-----------------------------
    for _, skillGroup in pairs(self.MainSkillGroupEntityDic or {}) do
        local isCarry = carringMainSkillGroupId == skillGroup.Id
        skillGroup:UpdateData({ IsCarry = isCarry })
    end
    ---------------------------------------------------------------------
    -------------------------更新未装备主技能数据--------------------------  
    for _,skillGroup in pairs(self.MainSkillGroupEntityDic or {}) do
       if not skillGroup:GetIsCarry() then
            local tmpData = {}
            tmpData.Level = carringMainSkillLevel
            tmpData.IsCarry = false
            if self:GetIsCarry() then
                local charId = self:GetCharacterId()
                local charElement = XMVCA.XCharacter:GetCharacterElement(charId)
                local skillId = skillGroup:GetSkillIdByElement(charElement)
                tmpData.ActiveSkillId = skillId
            else
                skillGroup:SetDefaultActiveSkillId()
            end
            skillGroup:UpdateData(tmpData)
       end
    end
  ---------------------------------------------------------------------
  -------------------------更新主技能解锁数据----------------------------
    for groupId,IsOpen in pairs(self.UnlockSkillGroupDic or {}) do
        local mainSkilldata = self.MainSkillGroupEntityDic[groupId]
        local passiveSkilldata = self.PassiveSkillGroupEntityDic[groupId]
        
        if mainSkilldata then
            mainSkilldata:UpdateData({IsLock = not IsOpen})
        end
    end
end

function XPartner:GetMainSkillGroupEntityDic()
    return self.MainSkillGroupEntityDic
end

function XPartner:GetPassiveSkillGroupEntityDic()
    return self.PassiveSkillGroupEntityDic
end

function XPartner:GetMainSkillGroupList()
    local list = {}
    for _,entity in pairs(self.MainSkillGroupEntityDic or {}) do
        table.insert(list, entity)
    end
    XPartnerSort.SkillSort(list)
    return list
end

function XPartner:GetPassiveSkillGroupList()
    local list = {}
    for _,entity in pairs(self.PassiveSkillGroupEntityDic or {}) do
        table.insert(list, entity)
    end
    XPartnerSort.SkillSort(list)
    return list
end

function XPartner:GetCarryMainSkillGroupList()
    local list = {}
    for _,entity in pairs(self.MainSkillGroupEntityDic or {}) do
        if entity:GetIsCarry() then
            table.insert(list, entity)
        end
    end
    XPartnerSort.SkillSort(list)
    return list
end

function XPartner:GetCarryPassiveSkillGroupList()
    local list = {}
    for _,entity in pairs(self.PassiveSkillGroupEntityDic or {}) do
        if entity:GetIsCarry() then
            table.insert(list, entity)
        end
    end
    XPartnerSort.SkillSort(list)
    return list
end

function XPartner:GetSkillById(skillId)
    for _,entity in pairs(self.MainSkillGroupEntityDic or {}) do
        if entity:GetActiveSkillId() == skillId then
            return entity
        end
    end
    for _,entity in pairs(self.PassiveSkillGroupEntityDic or {}) do
        if entity:GetActiveSkillId() == skillId then
            return entity
        end
    end
    return
end

--==============================
 ---@desc 获取技能组，通过默认的ActiveSkillId,避免了主动技能因角色不同的偏差
 ---@skillId ActiveSkillId 
 ---@return @class XPartnerMainSkillGroup or XPartnerPassiveSkillGroup
--==============================
function XPartner:GetSkillByDefaultId(skillId)
    for _,entity in pairs(self.MainSkillGroupEntityDic or {}) do
        if entity:GetDefaultActiveSkillId() == skillId then
            return entity
        end
    end
    for _,entity in pairs(self.PassiveSkillGroupEntityDic or {}) do
        if entity:GetDefaultActiveSkillId() == skillId then
            return entity
        end
    end
end

--==============================
 ---@desc 获取携带的主动技能的默认ActiveSkillId
 ---@return table
--==============================
function XPartner:GetCarryMainSkillDefaultIdList()
    local groupList = self:GetCarryMainSkillGroupList()
    local list = {}
    for _, group in ipairs(groupList or {}) do
        local defaultId = group:GetDefaultActiveSkillId()
        table.insert(list, defaultId)
    end
    return list
end

--==============================
---@desc 获取携带的被动技能的默认ActiveSkillId
---@return table
--==============================
function XPartner:GetCarryPassiveSkillDefaultIdList()
    local groupList = self:GetCarryPassiveSkillGroupList()
    local list = {}
    for _, group in ipairs(groupList or {}) do
        local defaultId = group:GetDefaultActiveSkillId()
        table.insert(list, defaultId)
    end
    return list
end

function XPartner:CheckIsNotUpSkill()
    for _,entity in pairs(self.MainSkillGroupEntityDic or {}) do
        if entity:GetLevel() > 1 then
            return false
        end
    end
    for _,entity in pairs(self.PassiveSkillGroupEntityDic or {}) do
        if entity:GetLevel() > 1 then
            return false
        end
    end
    return true
end

function XPartner:IsNotChangeSkill()
    return self:IsNotChangeMainSkill() and self:IsNotChangePassiveSkill()
end

function XPartner:IsNotChangeMainSkill()
    for _,entity in pairs(self.MainSkillGroupEntityDic or {}) do
        if entity:GetIsCarry() and entity:GetId() ~= self:GetDefaultSkillGroupId() then
            return false
        end
    end
    return true
end

function XPartner:IsNotChangePassiveSkill()
    for _,entity in pairs(self.PassiveSkillGroupEntityDic or {}) do
        if entity:GetIsCarry() then
            return false
        end
    end
    return true
end

function XPartner:GetSkillCfg()
    return XPartnerConfigs.GetPartnerSkillById(self.TemplateId)
end

function XPartner:GetSkillUpgradeCostItemId()
    return self:GetSkillCfg().UpgradeCostItemId
end

function XPartner:GetSkillUpgradeCostItemCount()
    return self:GetSkillCfg().UpgradeCostItemCount
end

function XPartner:GetSkillUpgradeCostItem()
    local itemlist = {}
    local itemIdlist = self:GetSkillUpgradeCostItemId()
    local itemCountlist = self:GetSkillUpgradeCostItemCount()
    for index,id in pairs(itemIdlist or {}) do
        local tmpData = {
            Id = id,
            Count = itemCountlist[index] or 0,
        }
        itemlist[index] = tmpData
    end
    return itemlist
end

function XPartner:GetSkillUpgradeMoney()
    return self:GetSkillUpgradeCostItem()[MoneyIndex]
end

function XPartner:GetSkillUpgradeItem()
    local list = self:GetSkillUpgradeCostItem()
    table.remove(list, MoneyIndex)
    return list
end

function XPartner:GetDefaultSkillGroupId()
    return self:GetSkillCfg().DefaultMainSkillGroupId
end

function XPartner:GetMainSkillGroupIdList()
    return self:GetSkillCfg().MainSkillGroupId
end

function XPartner:GetPassiveSkillGroupIdList()
    return self:GetSkillCfg().PassiveSkillGroupId
end

function XPartner:GetTotalSkillLevel()--总当前技能等级
    local level = 0
    for _,entity in pairs(self.MainSkillGroupEntityDic or {}) do
        if entity:GetIsCarry() then
            level = level + entity:GetLevel()--总技能共享等级，只需要取其中一个的等级即可
            break
        end
    end
    for _,entity in pairs(self.PassiveSkillGroupEntityDic or {}) do
        level = level + entity:GetLevel()
    end

    return level
end

function XPartner:GetTotalSkillLevelLimit()--总技能等级
    local levelLimit = 0
    for _,entity in pairs(self.MainSkillGroupEntityDic or {}) do
        if entity:GetIsCarry() then
            levelLimit = levelLimit + entity:GetLevelLimit()--总技能共享等级，只需要取其中一个的等级即可
            break
        end
    end
    for _,entity in pairs(self.PassiveSkillGroupEntityDic or {}) do
        levelLimit = levelLimit + entity:GetLevelLimit()
    end

    return levelLimit
end

function XPartner:GetMiniSkillLevelLimit()--最小技能等级
    local levelLimit = 0
    for _,entity in pairs(self.MainSkillGroupEntityDic or {}) do
        if entity:GetIsCarry() then
            levelLimit = levelLimit + 1
            break
        end
    end
    for _,entity in pairs(self.PassiveSkillGroupEntityDic or {}) do
        levelLimit = levelLimit + 1
    end

    return levelLimit
end

function XPartner:GetIsTotalSkillLevelMax()--总技能等级已满
    return self:GetTotalSkillLevel() >= self:GetTotalSkillLevelLimit()
end

function XPartner:GetSkillLevelGap()--总技能等级与满技能等级的差值
    return self:GetTotalSkillLevelLimit() - self:GetTotalSkillLevel()
end
-------------------------------------宠物故事---------------------------------

function XPartner:CreateStoryEntityDic()
    self.StoryEntityDic = {}
    local storyEntityList = XDataCenter.ArchiveManager.GetArchivePartnerSetting(self.TemplateId,XArchiveConfigs.PartnerSettingType.Story)
    for _,Entity in pairs(storyEntityList or {}) do
        self.StoryEntityDic[Entity:GetId()] = Entity
    end
end

function XPartner:UpdateStoryEntity(unLockStoryList)
    for _,id in pairs(unLockStoryList or {}) do
        if self.StoryEntityDic[id] then
            self.StoryEntityDic[id]:UpdateData({IsLock = false})
        end
    end
end

-------------------------------物品跳转----------------------------------
function XPartner:GetItemSkipCfg()
    return XPartnerConfigs.GetPartnerItemSkipById(self.TemplateId)
end

function XPartner:GetLevelUpSkipIdList()
    return self:GetItemSkipCfg().LevelUpSkipIdParams or {}
end

function XPartner:GetStageSkipId()
    return self:GetItemSkipCfg().StageSkipIdParam
end

-------------------------------宠物来源----------------------------------
function XPartner:SetIsBelongSelf(value)
    self.IsBelongSelf = value
end

function XPartner:GetIsComposePreview()
    return not self.IsComplete
end

return XPartner