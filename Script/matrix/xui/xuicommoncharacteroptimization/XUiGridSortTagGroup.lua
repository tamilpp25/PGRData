-- 角色筛选界面的的标签组
local XUiGridSortTagGroup = XClass(nil, "XUiGridSortTagGroup")

function XUiGridSortTagGroup:Ctor(ui, rootUi, tagId, isSelected)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.Id = tagId
    self.IsSelected = isSelected -- 是否选中

    self:AutoInit()
    XTool.InitUiObject(self)
    self:Refresh()
end

-- 刷新当前显示的状态
function XUiGridSortTagGroup:Refresh()
    self.PanelSelect.gameObject:SetActiveEx(self.IsSelected)
    self.PanelNormal.gameObject:SetActiveEx(not self.IsSelected)
end

function XUiGridSortTagGroup:AutoInit()
    self.Button = self.Transform:GetComponent("XUiButton")
    self.PanelSelect = self.Transform:Find("Select")
    self.PanelNormal = self.Transform:Find("Normal")

    XUiHelper.RegisterClickEvent(self, self.Button, self.OnTagClick)
end

function XUiGridSortTagGroup:OnTagClick()
    if self.IsSelected then
        return
    end

    self.IsSelected = true
    -- 如果当前为选中状态则切换为未选中状态，反之
    self:Refresh()
    self.RootUi:OnTagClick(self.Id)
end

-- 取消选中
function XUiGridSortTagGroup:CancelSelect()
    self.IsSelected = false
    self:Refresh()
end

return XUiGridSortTagGroup