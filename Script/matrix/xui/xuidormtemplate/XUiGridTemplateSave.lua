local XUiGridTemplateSave = XClass(nil, "XUiGridTemplateSave")

function XUiGridTemplateSave:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    self:AutoAddListener()
end

function XUiGridTemplateSave:Init(parent)
    self.Parent = parent
    self:SetSelect(false)
end

function XUiGridTemplateSave:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiGridTemplateSave:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiGridTemplateSave:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiGridTemplateSave:AutoAddListener()
    self:RegisterClickEvent(self.BtnClick, self.OnBtnClick)
end

function XUiGridTemplateSave:OnBtnClick()
    self.Parent:OnGridClick(self, self.Name, false, self.Index)
end

function XUiGridTemplateSave:SetSelect(status)
    self.PanelSelect.gameObject:SetActiveEx(status)
end

function XUiGridTemplateSave:CheckCoverSave()
    return self.HomeRoomData ~= nil
end

function XUiGridTemplateSave:Refresh(homeRoomData, collectCfg, isDefaultSelect, index)
    self:SetSelect(false)
    self.HomeRoomData = homeRoomData
    self.CollectCfg = collectCfg
    self.Index = index

    local isHave = homeRoomData ~= nil
    self.Name = isHave and self.HomeRoomData:GetRoomName() or collectCfg.DefaultName
    self.PanelTemplate.gameObject:SetActiveEx(homeRoomData ~= nil)
    self.PanelTemplateNone.gameObject:SetActiveEx(homeRoomData == nil)

    self.TxtName.text = self.Name
    if isDefaultSelect then
        self.Parent:OnGridClick(self, self.Name, true, self.Index)
    end

    if not isHave then
        return
    end

    self.HomeRoomData:GetRoomPicture(function(texture)
        if texture then
            self.RImgIcon.texture = texture
        else
            if isHave then
                local imgPath = self.CollectCfg.DefaultIcon
                self.RImgIcon:SetRawImage(imgPath, nil, false)
            end
        end
    end)
end

return XUiGridTemplateSave