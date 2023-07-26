local Default = {
    _Id = 0,
    _TemplateId = 0,
    _Level = 0,
    _Breakthrough = 0,
    _Resonances = 0,
    _CharacterId = 0,
    _Site = 0,
    _Exist = false,
    _Name = "",
    _Icon = "",
    _QualityIcon = "",
    _EquipDesc = "",
    _AttrMap = {},
    _BreakthroughIcon = "",
    _EquipType = XArrangeConfigs.Types.Weapon,
}


local XEquipGuideModel = XClass(XDataEntityBase, "XEquipGuideModel")

function XEquipGuideModel:Ctor(templateId)
    self:Init(Default, templateId)
end

function XEquipGuideModel:InitData(id)
    self:SetProperty("_TemplateId", id)
    self:SetProperty("_Name", XDataCenter.EquipManager.GetEquipName(self._TemplateId))
    self:SetProperty("_Icon", XDataCenter.EquipManager.GetEquipIconPath(self._TemplateId))
    self:SetProperty("_QualityIcon", XDataCenter.EquipManager.GetEquipQualityPath(self._TemplateId))
    self:SetProperty("_EquipDesc", XDataCenter.EquipManager.GetEquipDescription(self._TemplateId))
    self:SetProperty("_EquipType", XArrangeConfigs.GetType(self._TemplateId))
    self:SetProperty("_Site", XDataCenter.EquipManager.GetEquipSiteByTemplateId(self._TemplateId))
end

function XEquipGuideModel:Refresh(equipId)
    self:SetProperty("_Id", equipId)
    local exist = XTool.IsNumberValid(self._Id)
    local lv, breakthrough, resonances, characterId = 1, 0, 0, 0
    local attrMap
    if exist then
        local equip = XDataCenter.EquipManager.GetEquip(self._Id)
        lv = equip.Level
        breakthrough = equip.Breakthrough
        for i = 1, XEquipConfig.MAX_RESONANCE_SKILL_COUNT do
            if XDataCenter.EquipManager.CheckEquipPosResonanced(self._Id, i) then
                resonances = resonances + 1
            end
        end
        attrMap = XDataCenter.EquipManager.GetEquipAttrMap(self._Id, lv)
        characterId = equip.CharacterId
    else
        attrMap = XDataCenter.EquipManager.ConstructTemplateEquipAttrMap(self._TemplateId, breakthrough, lv)
    end
    self:SetProperty("_Level", lv)
    self:SetProperty("_Breakthrough", breakthrough)
    self:SetProperty("_Resonances", resonances)
    self:SetProperty("_CharacterId", characterId)
    self:SetProperty("_Exist", exist)
    self:SetProperty("_AttrMap", attrMap)
    self:SetProperty("_BreakthroughIcon", breakthrough > 0 and XEquipConfig.GetEquipBreakThroughSmallIcon(breakthrough) or "")
end

function XEquipGuideModel:IsWearing(characterId)
    return XDataCenter.EquipGuideManager.CheckEquipIsWearingOnCharacter(self._Id, characterId)
end

function XEquipGuideModel:IsExist()
    return XTool.IsNumberValid(self._Id)
end

return XEquipGuideModel