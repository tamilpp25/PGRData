local Default = {
    _TemplateId = 0,
    _CharacterId = 0,
    _Site = 0,
    _Exist = false,
    _Name = "",
    _Icon = "",
    _QualityIcon = "",
    _EquipDesc = "",
    _AttrMap = {},
    _EquipType = XArrangeConfigs.Types.Weapon,
}


local XEquipGuideModel = XClass(XDataEntityBase, "XEquipGuideModel")

function XEquipGuideModel:Ctor(templateId)
    self:Init(Default, templateId)
end

function XEquipGuideModel:InitData(id)
    self:SetProperty("_TemplateId", id)
    self:SetProperty("_Name", XMVCA.XEquip:GetEquipName(self._TemplateId))
    self:SetProperty("_Icon", XMVCA.XEquip:GetEquipIconPath(self._TemplateId))
    self:SetProperty("_QualityIcon", XMVCA.XEquip:GetEquipQualityPath(self._TemplateId))
    self:SetProperty("_EquipDesc", XMVCA.XEquip:GetEquipDescription(self._TemplateId))
    self:SetProperty("_EquipType", XArrangeConfigs.GetType(self._TemplateId))
    self:SetProperty("_Site", XMVCA.XEquip:GetEquipSite(self._TemplateId))
end

function XEquipGuideModel:SetCharacterId(characterId)
    self:SetProperty("_CharacterId", characterId)
end

-- 是否存在目标装备
function XEquipGuideModel:IsExistEquip()
    local equips = XMVCA.XEquip:GetEquipsByTemplateId(self._TemplateId, true)
    return #equips > 0
end

-- 是否穿戴目标装备
function XEquipGuideModel:IsWearTemplateIdEquip()
    local equip = self:GetWearEquip()
    if equip then
        return equip.TemplateId == self._TemplateId
    end
    return false
end

-- 获取当前穿戴的装备Id
function XEquipGuideModel:GetWearEquip()
    return XMVCA.XEquip:GetCharacterEquip(self._CharacterId, self._Site)
end

-- 穿戴装备是否满级满突破
function XEquipGuideModel:IsMaxLevelAndBreakthrough()
    local equip = self:GetWearEquip()
    if equip then
        return equip:IsMaxLevelAndBreakthrough()
    end
    return false
end

-- 获取最佳的装备
function XEquipGuideModel:GetBestOneEquip()
    local equips = XMVCA.XEquip:GetEquipsByTemplateId(self._TemplateId, true)
    if #equips == 0 then return end
    
    table.sort(equips, function(a, b) 
        local baseScoreA = XEquipGuideConfigs.CalEquipBaseScore(a.Id)
        local baseScoreB = XEquipGuideConfigs.CalEquipBaseScore(b.Id)
        if baseScoreA ~= baseScoreB then
            return baseScoreA > baseScoreB
        end

        local resonanceScoreA = XEquipGuideConfigs.CalEquipResonanceScore(a.Id, self._CharacterId)
        local resonanceScoreB = XEquipGuideConfigs.CalEquipResonanceScore(b.Id, self._CharacterId)
        if resonanceScoreA ~= resonanceScoreB then
            return resonanceScoreA > resonanceScoreB
        end

        return a.Id < b.Id
    end)
    return equips[1]
end

-- 获取装备属性
function XEquipGuideModel:GetAttrMap()
    if self:IsWearTemplateIdEquip() then
        local equip = self:GetWearEquip()
        return XMVCA.XEquip:GetEquipAttrMap(equip.Id, equip.Breakthrough, equip.Level)
    else
        return XMVCA.XEquip:ConstructTemplateEquipAttrMap(self._TemplateId, 0, 0)
    end
end

return XEquipGuideModel