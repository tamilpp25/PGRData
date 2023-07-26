local XUiPanelExpeditionEquipment = XClass(nil, "XUiPanelExpeditionEquipment")
local XUiGridExpeditionEquipment = require("XUi/XUiExpedition/Recruit/XUiExpeditionRoleDetails/XUiGridExpeditionEquipment")

function XUiPanelExpeditionEquipment:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self:RegisterUiEvents()
    self.AwarenessGrids = {}
end

function XUiPanelExpeditionEquipment:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnWeaponReplace, self.OnBtnWeaponReplaceClick)
    XUiHelper.RegisterClickEvent(self, self.BtnAwarenessReplace1, self.OnBtnAwarenessReplace1Click)
    XUiHelper.RegisterClickEvent(self, self.BtnAwarenessReplace6, self.OnBtnAwarenessReplace6Click)
end

function XUiPanelExpeditionEquipment:OnBtnWeaponReplaceClick()
    XLuaUiManager.Open("UiExpeditionEquipDetail", self.RobotCfg.WeaponId, self.RobotCfg.WeaponBeakThrough, self.RobotCfg.WeaponLevel)
end

function XUiPanelExpeditionEquipment:OnBtnAwarenessReplace1Click()
    self:OnAwarenessClick(1)
end

function XUiPanelExpeditionEquipment:OnBtnAwarenessReplace6Click()
    self:OnAwarenessClick(6)
end

function XUiPanelExpeditionEquipment:OnAwarenessClick(site)
    if not self.RobotCfg.WaferId[site] then return end
    XLuaUiManager.Open("UiExpeditionEquipDetail", self.RobotCfg.WaferId[site], self.RobotCfg.WaferBreakThrough[site], self.RobotCfg.WaferLevel[site])
end

function XUiPanelExpeditionEquipment:Refresh(eChara)
    self.EChara = eChara
    
    local RobotId = self.EChara:GetRobotId()
    self.RobotCfg = XRobotManager.GetRobotTemplate(RobotId)
    
    self.WeaponGrid = XUiGridExpeditionEquipment.New(self.GridWeapon, self)
    local weapon = self.EChara:GetWeaponViewModel()
    if weapon then
        self.WeaponGrid:Refresh(weapon.TemplateId, weapon.Breakthrough, weapon.Level)
    end
    for i = 1, 6, 5 do
        self.AwarenessGrids[i] = self.AwarenessGrids[i] or XUiGridExpeditionEquipment.New(self["GridAwareness"..i], self)
        local equip = self.EChara:GetAwarenessViewModelDic(i)
        
        self["GridAwareness"..i].gameObject:SetActiveEx(equip ~= nil)
        self["BtnAwarenessReplace"..i].gameObject:SetActiveEx(equip ~= nil)
        
        if equip then
            self.AwarenessGrids[i]:Refresh(equip.TemplateId, equip.Breakthrough, equip.Level)
        end
    end
end

return XUiPanelExpeditionEquipment