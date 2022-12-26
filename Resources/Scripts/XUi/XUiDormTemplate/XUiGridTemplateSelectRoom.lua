local XUiGridTemplateSelectRoom = XClass(nil, "XUiGridTemplateSelectRoom")

function XUiGridTemplateSelectRoom:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:AutoAddListener()
end

function XUiGridTemplateSelectRoom:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiGridTemplateSelectRoom:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiGridTemplateSelectRoom:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiGridTemplateSelectRoom:AutoAddListener()
    self:RegisterClickEvent(self.BtnClick, self.OnBtnClickClick)
end

function XUiGridTemplateSelectRoom:OnBtnClickClick()
    if self.SelectCb then
        self.SelectCb(self.RoomId)
    end
end

function XUiGridTemplateSelectRoom:SetSelected(status)
    self.PanelSelect.gameObject:SetActiveEx(status)
end

function XUiGridTemplateSelectRoom:Refresh(roomData, connectId, selectCb, curDormId)
    self.RoomData = roomData
    self.SelectCb = selectCb
    self.RoomId = roomData:GetRoomId()
    self:SetSelected(connectId == self.RoomId)

    local name = roomData:GetRoomName()
    self.TxtCategoryName.text = name
    self.TxtCategoryNameSelect.text = name
    self.TxtTag.gameObject:SetActiveEx(curDormId == self.RoomId)
end

return XUiGridTemplateSelectRoom