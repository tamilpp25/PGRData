local XUiGridCategory = XClass(nil, "XUiGridCategory")

function XUiGridCategory:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:AutoAddListener()
end

function XUiGridCategory:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiGridCategory:RegisterClickEvent函数错误, 参数fun不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiGridCategory:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiGridCategory:AutoAddListener()
    self:RegisterClickEvent(self.BtnClick, self.OnBtnClickClick)
end

function XUiGridCategory:OnBtnClickClick()
    XEventManager.DispatchEvent(XEventId.EVENT_CLICKCATEGORY_GRID, self.CategoryInfo.Id, self)
end

function XUiGridCategory:SetSelected(status)
    self.PanelSelect.gameObject:SetActiveEx(status)
end

function XUiGridCategory:IsSelected()
    return self.PanelSelect.gameObject.activeSelf
end

function XUiGridCategory:Refresh(categoryInfo, isSelected)
    self.CategoryInfo = categoryInfo

    self:SetSelected(isSelected)
    self.TxtCategoryName.text = categoryInfo.CategoryName
    self.TxtCategoryNameSelect.text = categoryInfo.CategoryName
end

function XUiGridCategory:RefreshSuit(categoryInfo, isSelected)
    self.CategoryInfo = categoryInfo

    self:SetSelected(isSelected)
    self.TxtCategoryName.text = categoryInfo.SuitName
    self.TxtCategoryNameSelect.text = categoryInfo.SuitName
end


return XUiGridCategory