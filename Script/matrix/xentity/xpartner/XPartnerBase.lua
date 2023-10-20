---@class XPartnerBase
local XPartnerBase = XClass(nil, "XPartnerBase")

function XPartnerBase:Ctor(templateId)
    self.TemplateId = templateId
    self.StoryEntityDic = {}
    self.StorySettingDic = {}
end

----------------------------宠物基础属性--------------------------------
function XPartnerBase:GetPartnerCfg()
    return XPartnerConfigs.GetPartnerTemplateById(self.TemplateId)
end

function XPartnerBase:GetOriginalName()
    return self:GetPartnerCfg().Name
end

function XPartnerBase:GetDesc()
    return self:GetPartnerCfg().Desc
end

function XPartnerBase:GetRecommendElement()
    return self:GetPartnerCfg().RecommendElement
end

function XPartnerBase:GetIcon()
    return self:GetPartnerCfg().Icon
end

function XPartnerBase:GetPriority()
    return self:GetPartnerCfg().Priority
end

function XPartnerBase:GetInitQuality()
    return self:GetPartnerCfg().InitQuality
end

function XPartnerBase:GetCarryCharacterType()
    return self:GetPartnerCfg().CarryCharacterType
end

function XPartnerBase:GetChipItemId()
    return self:GetPartnerCfg().ChipItemId
end

function XPartnerBase:GetChipNeedCount()
    return self:GetPartnerCfg().ChipNeedCount
end

function XPartnerBase:GetDefaultLock()
    return self:GetPartnerCfg().DefaultLock
end

function XPartnerBase:GeMainSkillCount()
    return self:GetPartnerCfg().MainSkillCount
end

function XPartnerBase:GetPassiveSkillCount()
    return self:GetPartnerCfg().PassiveSkillCount
end

function XPartnerBase:GetDecomposeItemId()
    return self:GetPartnerCfg().DecomposeItemId
end

function XPartnerBase:GetDecomposeItemCount()
    return self:GetPartnerCfg().DecomposeItemCount
end

function XPartnerBase:GetDecomposeBackItem()
    local itemlist = {}
    local itemIdlist = self:GetDecomposeItemId()
    local itemCountlist = self:GetDecomposeItemCount()
    for index,id in pairs(itemIdlist or {}) do
        local tmpData = {
            Id = id,
            Count = itemCountlist[index] or 0,
        }
        itemlist[index] = tmpData
    end
    return itemlist
end

----------------------------------宠物模型-------------------------------
function XPartnerBase:GetModelCfg()
    return XPartnerConfigs.GetPartnerModelById(self.TemplateId)
end

function XPartnerBase:GetStandbyModel()
    return self:GetModelCfg().StandbyModel
end

function XPartnerBase:GetCombatModel()
    return self:GetModelCfg().CombatModel
end

function XPartnerBase:GetSToCAnime()--待机转战斗动画
    return self:GetModelCfg().SToCAnime
end

function XPartnerBase:GetStandbyBornAnime()--出生动画
    return self:GetModelCfg().StandbyBornAnime
end

function XPartnerBase:GetCToSAnime()--动画转待机动画
    return self:GetModelCfg().CToSAnime
end

function XPartnerBase:GetCombatBornAnime()--出生动画
    return self:GetModelCfg().CombatBornAnime
end

function XPartnerBase:GetSToCVoice()--待机转战斗音效
    return self:GetModelCfg().SToCVoice
end

function XPartnerBase:GetCToSVoice()--动画转待机音效
    return self:GetModelCfg().CToSVoice
end

function XPartnerBase:GetSToCEffect()--待机转战斗特效
    return self:GetModelCfg().SToCEffect
end

function XPartnerBase:GetStandbyBornEffect()--待机出生特效
    return self:GetModelCfg().StandbyBornEffect
end

function XPartnerBase:GetCToSEffect()--战斗转待机特效
    return self:GetModelCfg().CToSEffect
end

function XPartnerBase:GetCombatBornEffect()--战斗出生特效
    return self:GetModelCfg().CombatBornEffect
end

-------------------------------------宠物故事---------------------------------

function XPartnerBase:GetStoryEntityDic()
    return self.StoryEntityDic
end

function XPartnerBase:GetStorySettingDic()
    return self.StorySettingDic
end

function XPartnerBase:GetStoryEntityList()
    local list = {}
    for _,entity in pairs(self.StoryEntityDic or {}) do
        table.insert(list, entity)
    end
    return XMVCA.XArchive:SortByOrder(list)
end

function XPartnerBase:GetSettingEntityList()
    local list = {}
    for _,entity in pairs(self.StorySettingDic or {}) do
        table.insert(list, entity)
    end
    return XMVCA.XArchive:SortByOrder(list)
end

return XPartnerBase