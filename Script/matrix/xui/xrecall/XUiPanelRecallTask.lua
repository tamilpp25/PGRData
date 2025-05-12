local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiPanelRecallTask
---@field _Control XReCallActivityControl
local XUiPanelRecallTask = XClass(nil, "XUiPanelRecallTask")
local XUiReCallTaskGrid = require("XUi/XReCall/XUiReCallTaskGrid")

function XUiPanelRecallTask:Ctor(ui, parent, control)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Parent = parent
    self._Control = control
    XTool.InitUiObject(self)
    self:InitAutoScript()
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiPanelRecallTask:InitAutoScript()
    self:InitDynamicTable()
    self:AutoAddListener()
end

function XUiPanelRecallTask:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.SViewTask)
    self.DynamicTable:SetProxy(XUiReCallTaskGrid, self.Parent)
    self.DynamicTable:SetDelegate(self)
end

function XUiPanelRecallTask:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:RefreshTask(self.Tasks[index])
    end
end

function XUiPanelRecallTask:AutoAddListener()
    self.BtnCopy.CallBack = function() self:OnBtnCopyClick() end
end

function XUiPanelRecallTask:OnBtnCopyClick()
    XTool.CopyToClipboard(self._Control:PlayIdToHexUpper())
end

function XUiPanelRecallTask:Refresh()
    self.Tasks = self._Control:GetTaskList()
    self.DynamicTable:SetDataSource(self.Tasks)
    self.DynamicTable:ReloadDataASync()
    self.GridNewbieTaskItem.gameObject:SetActiveEx(false)
    self.CodeText.text = CS.XTextManager.GetText("HoldRegressionInviteCode",self._Control:PlayIdToHexUpper())
    self.InviteCountText.text = CS.XTextManager.GetText("HoldRegressionInvitenumber",self._Control:GetInviteCount())
end

return XUiPanelRecallTask