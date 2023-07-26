--==============
--超限乱斗核心页签
--==============
local XUiSSBCoreTabGrid = XClass(nil, "XUiSSBCoreTabGrid")

function XUiSSBCoreTabGrid:Ctor(uiPrefab, core, onSelectCb)
    self.Transform = uiPrefab.transform
    self.GameObject = uiPrefab.gameObject
    self.Btn = self.GameObject:GetComponent("XUiButton")
    self.OnSelectCb = onSelectCb
    self:Refresh(core)
end

function XUiSSBCoreTabGrid:Refresh(core)
    self.Core = core
    self.Btn:SetName(self.Core:GetName() or "")
    self.Btn:SetButtonState(self.Core:CheckIsLock() and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
    self.Btn:ShowReddot(self.Core:CheckNew())
end

function XUiSSBCoreTabGrid:GetId()
    return self.Core:GetId()
end

function XUiSSBCoreTabGrid:GetButton()
    return self.Btn
end

function XUiSSBCoreTabGrid:OnSelect()
    if self.Core:CheckIsLock() then
        XUiManager.TipText("SSBCoreNotOpen")
        return
    end

    if self.Core:CheckNew() then
        XSaveTool.SaveData(
            "SuperSmashBrosLocalData_NewCore_Id_" .. self:GetId() ..
            "_Player_" .. XPlayer.Id ..
            "_Activity_" .. XDataCenter.SuperSmashBrosManager.GetActivityId()
            , true)
        self.Btn:ShowReddot(false)
    end
    if self.OnSelectCb then
        self.OnSelectCb(self.Core)
    end
end

return XUiSSBCoreTabGrid