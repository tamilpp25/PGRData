---@class XUiGridAction 拍照前动作列表的格子
---@field RootUi XUiPanelAction
local XUiGridAction = XClass(nil, "XUiGridAction")

function XUiGridAction:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiGridAction:Init(rootUi)
    self.RootUi = rootUi
end

--- 设置数据
---@param actionId - CaptureV217NpcAction表的Id
function XUiGridAction:SetData(actionId, isUnlock)
    self.ActionId = actionId
    self.IsUnlock = isUnlock
    local name = self.RootUi._Control._Model:GetActionName(actionId) or ""
    self.BtnAction:SetName(name)
    self:Refresh()
end

function XUiGridAction:Refresh()
    if not self.IsUnlock then
        self.BtnAction:SetDisable(not self.IsUnlock, self.IsUnlock)
        return
    end

    if self.BtnAction.ButtonState == CS.UiButtonState.Disable then
        self.BtnAction:SetDisable(false)
    end
    self.BtnAction:SetButtonState(self.ActionId == self.RootUi.SelectActionId and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

return XUiGridAction