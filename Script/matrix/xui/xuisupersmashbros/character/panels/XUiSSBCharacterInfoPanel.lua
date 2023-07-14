--==================
--角色详细面板
--==================
local XUiSSBCharacterInfoPanel = XClass(nil, "XUiSSBCharacterInfoPanel")

local TabIndex = {
        Core = 1,
        Equip = 2,
    }

function XUiSSBCharacterInfoPanel:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
    self:InitPanel()
end

function XUiSSBCharacterInfoPanel:InitPanel()
    self:InitInfo()
    self:InitCore()
    self:InitEquip()
    self:InitBtnTabs()
end

function XUiSSBCharacterInfoPanel:InitInfo()
    local script = require("XUi/XUiSuperSmashBros/Character/Panels/XUiSSBCInfo")
    self.Info = script.New(self.PanelInfo)
end

function XUiSSBCharacterInfoPanel:InitCore()
    local script = require("XUi/XUiSuperSmashBros/Character/Panels/XUiSSBCCore")
    self.Core = script.New(self.PanelCore)
end

function XUiSSBCharacterInfoPanel:InitEquip()
    local script = require("XUi/XUiSuperSmashBros/Character/Panels/XUiSBBCEquip")
    self.Equip = script.New(self.PanelEquip)
end

function XUiSSBCharacterInfoPanel:InitBtnTabs()
    self.BtnTabGroup:Init({self.BtnTabCore, self.BtnTabEquip}, function(index) self:SelectIndex(index) end)
end

function XUiSSBCharacterInfoPanel:SelectIndex(index)
    if index == TabIndex.Core then
        self.Core:Show()
        self.Equip:Hide()
    elseif index == TabIndex.Equip then
        self.Equip:Show()
        self.Core:Hide()
    end
end

function XUiSSBCharacterInfoPanel:Refresh(xRole)
    if xRole then self.Chara = xRole end
    self.Info:Refresh(self.Chara)
    self.Core:Refresh(self.Chara)
    self.Equip:Refresh(self.Chara)
    self.BtnTabGroup:SelectIndex(TabIndex.Core)
end

function XUiSSBCharacterInfoPanel:OnRefresh()
    self.Info:Refresh(self.Chara)
    self.Core:Refresh(self.Chara)
    self.Equip:Refresh(self.Chara)
end

function XUiSSBCharacterInfoPanel:OnEnable()

end

function XUiSSBCharacterInfoPanel:OnDisable()

end

function XUiSSBCharacterInfoPanel:OnDestroy()

end

return XUiSSBCharacterInfoPanel