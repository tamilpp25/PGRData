
local XUiGridTemplateItem = XClass(nil, "XUiGridTemplateItem")

function XUiGridTemplateItem:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
    self.TemplateCollect = XDormConfig.GetDormTemplateCollectList()
    self.IsSelect = false
    
    XUiHelper.RegisterClickEvent(self, self.Transform, self.OnBtnClick)
end

function XUiGridTemplateItem:Init(parentUi, rootUi)
    self.ParentUi = parentUi
    self.RootUi = rootUi
end

--- 
---@param data XHomeRoomData 
---@return
--------------------------
function XUiGridTemplateItem:Refresh(data, curRoomId, selectId, dataType, index)
    self.Index = index
    self.Data = data or self.Data
    self.CurRoomId = curRoomId or self.CurRoomId
    self.SelectId = selectId or self.SelectId
    self.DataType = dataType or self.DataType
    self.IsReform = XDataCenter.FurnitureManager.GetInReform()
    local isEmpty = XTool.IsTableEmpty(data)
    self.PanelTemplateNone.gameObject:SetActiveEx(isEmpty)
    self.PanelTemplate.gameObject:SetActiveEx(not isEmpty)
    self:SetSelect(selectId == self:GetSelectId())
    if isEmpty then
        return
    end
    local roomType = data:GetRoomDataType()
    if roomType == XDormConfig.DormDataType.Template then
        self.RImgIcon:SetRawImage(data:GetRoomPicturePath())
    elseif roomType == XDormConfig.DormDataType.Collect then
        data:GetRoomPicture(function(texture)
            if not texture then
                local cfg = self.TemplateCollect[self.Index]
                self.RImgIcon:SetRawImage(cfg.DefaultIcon)
            else
                self.RImgIcon:SetRawImageTexture(texture)
            end
        end)
    end
    self.TxtName.text = string.format("%s %d/%d", data:GetRoomName(), 
            XDataCenter.DormManager.GetRoomAndTemplateFurnitureCount(self.CurRoomId, data:GetRoomId(), roomType))
    local roomData = XDataCenter.DormManager.GetRoomDataByRoomId(self.CurRoomId, dataType)
    local isTarget = roomData:GetConnectDormId() == data:GetRoomId()
    self.PanelTarget.gameObject:SetActiveEx(isTarget)
    local roomId = data:GetRoomId()
    
    local showProgress = isTarget and not self.IsReform
    self.PanelConnect.gameObject:SetActiveEx(showProgress)
    if showProgress then
        local percent = XDataCenter.DormManager.GetDormTemplatePercent(self.CurRoomId, data:GetRoomId())
        self.TxtConnectDorm.text = percent .. "%"
    end
end

function XUiGridTemplateItem:OnBtnClick()
    if self.IsSelect then
        return
    end

    if self.RootUi and self.RootUi.CheckNeedSaveTemplate and self.RootUi:CheckNeedSaveTemplate() then
        XUiManager.DialogTip(XUiHelper.GetText("FurnitureTips"), XUiHelper.GetText("FurnitureIsSave"),
                nil, function()
                    self:DoBtnClick()
                end, function()
                    self.RootUi:DoSaveRoom(false)
                end)
    else
        self:DoBtnClick()
    end
end

function XUiGridTemplateItem:DoBtnClick()
    self.ParentUi:OnGridClick(self, self.Index)
    self:SetSelect(true)

    if self.OnClick then
        self.OnClick()
        return
    end

    if XTool.IsTableEmpty(self.Data) then
        local cfg = self.TemplateCollect[self.Index]
        local enterRoomId = cfg.SkipTemplateId
        XDataCenter.DormManager.EnterTemplateDormitory(enterRoomId, XDormConfig.DormDataType.CollectNone, self.CurRoomId)
        return
    end
    if self.IsReform then
        self:ReplaceRoomFurniture(self.Data:GetRoomId(), self.Data:GetRoomDataType())
    else
        self:ChangeRoom(self.Data:GetRoomId(), self.Data:GetRoomDataType())
    end
end

function XUiGridTemplateItem:ReplaceClickCb(onClick)
    self.OnClick = onClick
end

function XUiGridTemplateItem:SetSelect(select)
    self.IsSelect = select
    self.Select.gameObject:SetActiveEx(select)
end

function XUiGridTemplateItem:GetSelectId()
    if self.Data and self.Data.GetRoomId then
        return self.Data:GetRoomId()
    end
    local cfg = self.TemplateCollect[self.Index]
    
    return cfg.Id
end

function XUiGridTemplateItem:ChangeRoom(roomId, roomType)
    local isCollectNone = roomType == XDormConfig.DormDataType.CollectNone
    if isCollectNone then
        roomType = XDormConfig.DormDataType.Template
    end
    local data = XDataCenter.DormManager.GetRoomDataByRoomId(roomId, roomType)
    if isCollectNone then
        local defaultFurniture = XDataCenter.FurnitureManager.GetCollectNoneFurniture(roomId)
        if defaultFurniture then
            data:SetFurnitureDic(defaultFurniture)
        end
    end
    XHomeDormManager.LoadRooms({ data }, roomType, true)
    XHomeDormManager.SetSelectedRoom(roomId, true)
end

function XUiGridTemplateItem:ReplaceRoomFurniture(roomId, roomType)
    local roomData = XDataCenter.DormManager.GetRoomDataByRoomId(roomId, roomType)
    local room = XHomeDormManager.GetRoom(self.CurRoomId)
    if room then
        room:ReplaceFurniture(roomData)
    end
end

return XUiGridTemplateItem