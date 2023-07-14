local XEnhanceSkillGroup = XClass(nil, "XEnhanceSkillGroup")

function XEnhanceSkillGroup:Ctor(groupId, pos)
    self.Level = 0
    self.SkillGroupId = groupId
    self.Pos = pos
    self.IsUnLock = false
    self.ActiveSkillId = self:GetSkillIdList()[1]
end

function XEnhanceSkillGroup:UpdateData(data)
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
end

function XEnhanceSkillGroup:GetSkillGroupConfig()
    return XCharacterConfigs.GetEnhanceSkillGroupConfig(self:GetSkillGroupId())
end

function XEnhanceSkillGroup:GetSkillGradeConfig(skillId, level)
    return XCharacterConfigs.GetEnhanceSkillGradeBySkillIdAndLevel(skillId or self:GetActiveSkillId(), level or self:GetLevel())
end

function XEnhanceSkillGroup:GetSkillDescConfig(skillId, level)
    return XCharacterConfigs.GetEnhanceSkillGradeDescBySkillIdAndLevel(skillId or self:GetActiveSkillId(), level or self:GetLevel())
end

function XEnhanceSkillGroup:GetSkillEffectConfig(skillId, level)
    return XCharacterConfigs.GetEnhanceSkillLevelEffectBySkillIdAndLevel(skillId or self:GetActiveSkillId(), level or self:GetLevel())
end

function XEnhanceSkillGroup:GetSkillTypeConfig(skillId)
    return XCharacterConfigs.GetEnhanceSkillTypeConfig(skillId or self:GetActiveSkillId())
end

function XEnhanceSkillGroup:GetSkillTypeInfoConfig(type)
    return XCharacterConfigs.GetEnhanceSkillTypeInfoConfig(type)
end

-----------------------------------------------------------------------------------------------
function XEnhanceSkillGroup:GetSkillGroupId()
    return self.SkillGroupId
end

function XEnhanceSkillGroup:GetLevel()
    return self.Level
end

function XEnhanceSkillGroup:GetMaxLevel(skillId)
    return XCharacterConfigs.GetEnhanceSkillMaxLevelBySkillId(skillId or self:GetActiveSkillId())
end

function XEnhanceSkillGroup:GetIsMaxLevel()
    return self.Level == self:GetMaxLevel()
end

function XEnhanceSkillGroup:GetPos()
    return self.Pos
end

function XEnhanceSkillGroup:GetActiveSkillId()
    return self.ActiveSkillId
end

function XEnhanceSkillGroup:GetIsUnLock()
    return self.IsUnLock
end

function XEnhanceSkillGroup:GetSkillType(skillId)
    return self:GetSkillTypeConfig(skillId).Type
end

function XEnhanceSkillGroup:GetSkillTypeName(skillId)
    return self:GetSkillTypeInfoConfig(self:GetSkillType(skillId)).Name
end

-----------------------------技能组相关--------------------------------------
function XEnhanceSkillGroup:GetSkillIdList()
    return self:GetSkillGroupConfig().SkillId
end
-----------------------------技能信息相关-------------------------------------
function XEnhanceSkillGroup:GetName(skillId, level)
    return self:GetSkillDescConfig(skillId, level).Name
end

function XEnhanceSkillGroup:GetDesc(skillId, level)
    return self:GetSkillDescConfig(skillId, level).Intro
end

function XEnhanceSkillGroup:GetIcon(skillId, level)
    return self:GetSkillDescConfig(skillId, level).Icon
end

function XEnhanceSkillGroup:GetWeaponSkillDes(skillId, level)
    return self:GetSkillDescConfig(skillId, level).WeaponSkillDes
end

function XEnhanceSkillGroup:GetEntryIdList(skillId, level)
    return self:GetSkillDescConfig(skillId, level).EntryId
end
---------------------------------技能效果相关---------------------------------
function XEnhanceSkillGroup:GetBornMagicList(skillId, level)
    return self:GetSkillEffectConfig(skillId, level).BornMagic
end

function XEnhanceSkillGroup:GetSubSkillIdList(skillId, level)
    return self:GetSkillEffectConfig(skillId, level).SubSkillId
end

function XEnhanceSkillGroup:GetSubMagicIdList(skillId, level)
    return self:GetSkillEffectConfig(skillId, level).SubMagicId
end

function XEnhanceSkillGroup:GetAbility(skillId, level)
    return self:GetSkillEffectConfig(skillId, level).Ability
end

---------------------------------技能成长相关---------------------------------
function XEnhanceSkillGroup:GetConditionList(skillId, level)
    return self:GetSkillGradeConfig(skillId, level).ConditionId
end

function XEnhanceSkillGroup:GetCostItemIdList(skillId, level)
    return self:GetSkillGradeConfig(skillId, level).CostItem
end

function XEnhanceSkillGroup:GetCostItemCountList(skillId, level)
    return self:GetSkillGradeConfig(skillId, level).CostItemCount
end

function XEnhanceSkillGroup:GetCostItemList(skillId, level)
    local itemlist = {}
    local itemIdlist = self:GetCostItemIdList(skillId, level)
    local itemCountlist = self:GetCostItemCountList(skillId, level)
    for index,id in pairs(itemIdlist or {}) do
        local tmpData = {
            Id = id,
            Count = itemCountlist[index] or 0,
        }
        itemlist[index] = tmpData
    end
    return itemlist
end

function XEnhanceSkillGroup:GetBaseCostItem(skillId, level)--螺母
    local itemlist = self:GetCostItemList(skillId, level)
    return itemlist[1]
end

function XEnhanceSkillGroup:GetMaterialCostItemList(skillId, level)--素材
    local itemlist = self:GetCostItemList(skillId, level)
    table.remove(itemlist,1)
    return itemlist
end
--------------------------------技能词条相关----------------------------------
function XEnhanceSkillGroup:GetSkillEntryConfigList(skillId, level)
    local entryList = {}
    for _,entryId in pairs(self:GetEntryIdList(skillId, level) or {}) do
        local entry = XCharacterConfigs.GetEnhanceSkillEntryConfig(entryId)
        table.insert(entryList, entry)
    end
    return entryList
end

return XEnhanceSkillGroup