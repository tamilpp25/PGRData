--==================
--装备面板
--==================
local XUiSBBCEquip = XClass(nil, "XUiSBBCEquip")

function XUiSBBCEquip:Ctor(uiPrefab)
    XTool.InitUiObjectByUi(self, uiPrefab)
    self:InitBtns()
end

function XUiSBBCEquip:Refresh(chara)
end

function XUiSBBCEquip:InitBtns()
    --XUiHelper.RegisterClickEvent(self, self.BtnAwarenessReplace6, self.OnBtnAwarenessReplace6Click)
end

function XUiSBBCEquip:Show()
    self.GameObject:SetActiveEx(true)
end

function XUiSBBCEquip:Hide()
    self.GameObject:SetActiveEx(false)
end

return XUiSBBCEquip