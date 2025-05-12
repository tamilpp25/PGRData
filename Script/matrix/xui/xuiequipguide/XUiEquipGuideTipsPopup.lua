local XUiGridEquipGuide = require("XUi/XUiEquipGuide/XUiGridEquipGuide")
local Color = {
    Blue = XUiHelper.Hexcolor2Color("0E70BDFF"),
    Black = XUiHelper.Hexcolor2Color("00000099"),
    Green = XUiHelper.Hexcolor2Color("188649ff"),
}
local CSMathf = CS.UnityEngine.Mathf
local Offset = CS.UnityEngine.Vector2(-1340, 270) --相对于格子的偏移
local MaxY, MinY = 125, -125 -- 提示框Y的范围

local XUiEquipGuideTipsPopup = XLuaUiManager.Register(XLuaUi, "UiEquipGuideTipsPopup")

function XUiEquipGuideTipsPopup:OnAwake()
    self:InitCb()
    
    self.EquipItem = XUiGridEquipGuide.New(self.GridEquipUsing)
end 

function XUiEquipGuideTipsPopup:OnStart(model, characterId, fixPos)
    self.Model = model
    self.CharacterId = characterId

    self:FixPosition(fixPos)
    
    self.EquipItem:RefreshEquip(self.Model)
    
    local attrList = model:GetAttrMap()
    for i, attr in ipairs(attrList or {}) do
        self["TxtUsingAttrName"..i].text = attr.Name
        self["TxtUsingAttrValue"..i].text = attr.Value
    end
    local exist = model:IsExistEquip()
    local wear = model:IsWearTemplateIdEquip()
    local fullLevel = self.Model:IsMaxLevelAndBreakthrough()
    local tips
    if wear and fullLevel then
        tips = XUiHelper.GetText("EquipGuideEquipFullLevel")
    elseif wear then
        tips = XUiHelper.GetText("EquipGuideEquipGrowing")
    elseif exist then
        tips = XUiHelper.GetText("EquipGuideEquipCanEquips")
    else
        tips = XUiHelper.GetText("EquipGuideEquipNotExist")
    end
    self.TxtStateDesc.text = tips
    self.TxtStateDesc.color = fullLevel and Color.Blue or Color.Black
    
    local type = model:GetProperty("_EquipType")
    if type == XArrangeConfigs.Types.Weapon then
        self:RefreshWeapon()
    elseif type == XArrangeConfigs.Types.Wafer then
        self:RefreshChip()
    end
end 

function XUiEquipGuideTipsPopup:RefreshWeapon()
    local templateId = self.Model:GetProperty("_TemplateId")
    local weaponTemplate = XMVCA.XEquip:GetConfigEquip(templateId)
    local skillTemplate = XMVCA.XEquip:GetConfigWeaponSkill(weaponTemplate.WeaponSkillId)
    local color = self.Model:IsWearTemplateIdEquip() and Color.Green or Color.Black
    self:RefreshTemplateGrids(
            {
                self.TxtSkillDesc
            }, 
            {
                skillTemplate
            },
            self.PanelContent,
            nil,
            "GridWeaponDesc",
            function(grid, tmp) 
                grid.TxtSkillDesc.text = tmp.Description
                grid.TxtTitle.text = tmp.Name
                grid.TxtSkillDesc.color = color
                grid.TxtTitle.color = color
            end
    )
end

function XUiEquipGuideTipsPopup:RefreshChip()
    local templateId, exist = self.Model:GetProperty("_TemplateId"), self.Model:IsExistEquip()
    
    local suitId = exist
            and XMVCA.XEquip:GetEquipSuitIdByEquipId(self.Model:GetBestOneEquip().Id) 
            or XMVCA.XEquip:GetEquipSuitId(templateId)
    local activeEquipsCount = XMVCA.XEquip:GetActiveSuitEquipsCount(self.CharacterId, suitId)
    local skillDesList = XMVCA.XEquip:GetSuitActiveSkillDesList(suitId, activeEquipsCount)
    self:RefreshTemplateGrids(self.TxtSkillDesc
    , skillDesList
    , self.PanelContent
    , nil
    , "GridChipsDesc"
    , function(grid, data) 
            local color = data.IsActive and Color.Green or Color.Black
            grid.TxtSkillDesc.text = data.SkillDes
            grid.TxtTitle.text = data.PosDes
            grid.TxtSkillDesc.color = color
            grid.TxtTitle.color = color
    end
    )
    
    
end

function XUiEquipGuideTipsPopup:FixPosition(pos)
    pos = pos + Offset
    --pos.y = CSMathf.Clamp(pos.y, MinY, MaxY)
    pos.y = 0
    self.PanelUsing.transform.anchoredPosition = pos
end

function XUiEquipGuideTipsPopup:InitCb()
    self.BtnClose.CallBack = function() self:Close() end
end 