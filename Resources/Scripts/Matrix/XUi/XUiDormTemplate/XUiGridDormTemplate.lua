local XUiGridDormTemplate = XClass(nil, "XUiGridDormTemplate")

function XUiGridDormTemplate:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    self:AutoAddListener()
end

function XUiGridDormTemplate:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiGridDormTemplate:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiGridDormTemplate:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiGridDormTemplate:AutoAddListener()
    self:RegisterClickEvent(self.BtnTemplate, self.OnBtnTemplate)
    self:RegisterClickEvent(self.BtnNone, self.OnBtnNone)
end

function XUiGridDormTemplate:SetPanelActive(isHave)
    self.PanelTemplate.gameObject:SetActiveEx(isHave)
    self.PanelTemplateNone.gameObject:SetActiveEx(not isHave)
end

function XUiGridDormTemplate:OnBtnTemplate()
    XLuaUiManager.Open("UiDormTemplateDetail", self.HomeRoomData, self.EnterSenceCb, self.CurDormId)
end

function XUiGridDormTemplate:OnBtnNone()
    if self.EnterSenceCb then self.EnterSenceCb() end
    local enterRoomId = self.CollectCfg.SkipTemplateId
    XDataCenter.DormManager.EnterTeamplateDormitory(enterRoomId, XDormConfig.DormDataType.CollectNone)
end

function XUiGridDormTemplate:Refresh(homeRoomData, roomType, collectCfg, enterSenceCb, curDormId)
    self.HomeRoomData = homeRoomData
    self.RoomType = roomType
    self.CollectCfg = collectCfg
    self.EnterSenceCb = enterSenceCb
    self.CurDormId = curDormId
    
    if homeRoomData then
        self:SetPanelHave()
        return
    end

    self:SetPanelNone()
end

function XUiGridDormTemplate:SetPanelHave()
    self:SetPanelActive(true)
    local imgPath = self.HomeRoomData:GetRoomPicturePath()
    if self.RoomType == XDormConfig.DormDataType.Template then
        self.RImgIcon:SetRawImage(imgPath, nil, false)
    elseif self.RoomType == XDormConfig.DormDataType.Collect then
        self.HomeRoomData:GetRoomPicture(function(texture)
            if not texture then
                imgPath = self.CollectCfg.DefaultIcon
                self.RImgIcon:SetRawImage(imgPath, nil, false)
            else
                self.RImgIcon:SetRawImageTexture(texture, nil)
            end
        end)
    end

    self.TxtName.text = self.HomeRoomData:GetRoomName()
    local connectDormId = self.HomeRoomData:GetConnectDormId()
    self.PanelConnect.gameObject:SetActiveEx(connectDormId > 0)
    if connectDormId > 0 then
        local id = self.HomeRoomData:GetRoomId()
        local prrcent = XDataCenter.DormManager.GetDormTemplatePercent(id, connectDormId)
        local name = XDataCenter.DormManager.GetRoomDataByRoomId(connectDormId):GetRoomName()
        self.TxtPercent.text = prrcent .. "%"
        self.TxtConnectDorm.text = name
    end
end

function XUiGridDormTemplate:SetPanelNone()
    self:SetPanelActive(false)
end

return XUiGridDormTemplate