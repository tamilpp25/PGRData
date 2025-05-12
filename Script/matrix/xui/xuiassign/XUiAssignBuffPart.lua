local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiAssignBuffPart = XClass(nil, "XUiAssignBuffPart")

local XUiGridAssignBuffPart = require("XUi/XUiAssign/XUiGridAssignBuffPart")

function XUiAssignBuffPart:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self:InitComponent()
end

function XUiAssignBuffPart:InitComponent()
    self.GridBuff.gameObject:SetActiveEx(false)
    self.DynamicTable = XDynamicTableNormal.New(self.PanelBufftList)
    self.DynamicTable:SetProxy(XUiGridAssignBuffPart)
    self.DynamicTable:SetDelegate(self)
end

function XUiAssignBuffPart:Show()
    self.GameObject:SetActiveEx(true)
    return self:Refresh()
end

function XUiAssignBuffPart:Close()
    self.GameObject:SetActiveEx(false)
end

--动态列表事件
function XUiAssignBuffPart:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT or event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local chapterId = self.ListData[index]
        grid:Refresh(chapterId)
    end
end

--设置动态列表
function XUiAssignBuffPart:Refresh()
    --刷新数据
    self.ListData = XDataCenter.FubenAssignManager.GetUnlockChapterIdList()
    self.DynamicTable:SetDataSource(self.ListData)
    self.DynamicTable:ReloadDataASync()
    return (#self.ListData > 0)
end

return XUiAssignBuffPart