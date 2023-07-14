--==================
--装备面板
--==================
local XUiSBBCEquip = XClass(nil, "XUiSBBCEquip")

function XUiSBBCEquip:Ctor(uiPrefab)
    XTool.InitUiObjectByUi(self, uiPrefab)
    self.WearingAwarenessGrids = {}
    self:InitBtns()
end

function XUiSBBCEquip:Refresh(chara)
    self.Chara = chara
    local equipGrid = require("XUi/XUiSuperSmashBros/Character/Grids/XUiSBBCEquipGrid")
    self.WeaponGrid = equipGrid.New(self.GridWeapon, nil, self)
    local weapon = self.Chara:GetWeaponEquipView()
    if weapon then
        self.WeaponGrid:Refresh(weapon, weapon.Breakthrough, 0, true, weapon.Level)
    end
    for i = 1, 6 do
        self.WearingAwarenessGrids[i] = self.WearingAwarenessGrids[i] or equipGrid.New(CS.UnityEngine.Object.Instantiate(self.GridAwareness), nil, self)
        self.WearingAwarenessGrids[i].Transform:SetParent(self["PanelAwareness" .. i], false)
        local equip = self.Chara:GetAwarenessEquipViewBySiteId(i)
        if not equip then
            self.WearingAwarenessGrids[i].GameObject:SetActive(false)
            self["PanelNoAwareness" .. i].gameObject:SetActive(true)
        else
            self.WearingAwarenessGrids[i].GameObject:SetActive(true)
            self["BtnAwarenessReplace" .. i].transform:SetAsLastSibling()
            self["PanelNoAwareness" .. i].gameObject:SetActive(false)
            self.WearingAwarenessGrids[i]:Refresh(equip, equip.Breakthrough, i, false, equip.Level)
        end
    end
    local partner = self.Chara:GetPartner()
    self.PanelNoPartner.gameObject:SetActiveEx(not partner)
    self.PartnerIcon.gameObject:SetActiveEx(partner)
    self.PartnerIcon:SetRawImage(partner and partner:GetIcon())
end

function XUiSBBCEquip:InitBtns()
    XUiHelper.RegisterClickEvent(self, self.BtnAwarenessReplace6, self.OnBtnAwarenessReplace6Click)
    XUiHelper.RegisterClickEvent(self, self.BtnAwarenessReplace5, self.OnBtnAwarenessReplace5Click)
    XUiHelper.RegisterClickEvent(self, self.BtnAwarenessReplace4, self.OnBtnAwarenessReplace4Click)
    XUiHelper.RegisterClickEvent(self, self.BtnAwarenessReplace3, self.OnBtnAwarenessReplace3Click)
    XUiHelper.RegisterClickEvent(self, self.BtnAwarenessReplace2, self.OnBtnAwarenessReplace2Click)
    XUiHelper.RegisterClickEvent(self, self.BtnAwarenessReplace1, self.OnBtnAwarenessReplace1Click)
    XUiHelper.RegisterClickEvent(self, self.BtnWeaponReplace, self.OnBtnWeaponReplaceClick)
    self.BtnCarryPartner.CallBack = function() self:OnClickBtnPartner() end
end

function XUiSBBCEquip:OnBtnAwarenessReplace5Click()
    self:OnAwarenessClick(5)
end

function XUiSBBCEquip:OnBtnAwarenessReplace4Click()
    self:OnAwarenessClick(4)
end

function XUiSBBCEquip:OnBtnAwarenessReplace3Click()
    self:OnAwarenessClick(3)
end

function XUiSBBCEquip:OnBtnAwarenessReplace2Click()
    self:OnAwarenessClick(2)
end

function XUiSBBCEquip:OnBtnAwarenessReplace1Click()
    self:OnAwarenessClick(1)
end

function XUiSBBCEquip:OnBtnAwarenessReplace6Click()
    self:OnAwarenessClick(6)
end

function XUiSBBCEquip:OnBtnWeaponReplaceClick()
    if self.Chara:GetIsRobot() then
        XUiManager.TipText("SSBRobotCantEditEquip")
        return
    end
    XLuaUiManager.Open("UiEquipReplaceNew", self.Chara:GetId(), nil, true)
end

function XUiSBBCEquip:OnAwarenessClick(site)
    if self.Chara:GetIsRobot() then
        XUiManager.TipText("SSBRobotCantEditEquip")
        return
    end
    XLuaUiManager.Open("UiEquipAwarenessReplace", self.Chara:GetId(), nil, true)
end

function XUiSBBCEquip:OnClickBtnPartner()
    if self.Chara:GetIsRobot() then
        XUiManager.TipText("SSBRobotCantEditEquip")
        return
    end
    XDataCenter.PartnerManager.GoPartnerCarry(self.Chara:GetId(), false)
end

function XUiSBBCEquip:Show()
    self.GameObject:SetActiveEx(true)
end

function XUiSBBCEquip:Hide()
    self.GameObject:SetActiveEx(false)
end

return XUiSBBCEquip