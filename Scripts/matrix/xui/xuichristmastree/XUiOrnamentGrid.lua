XUiOrnamentGrid = XClass(nil, "XUiOrnamentGrid")

function XUiOrnamentGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.GiftNone = self.Transform:Find("GiftNone")
end

function XUiOrnamentGrid:Init(uiRoot)
    self.UiRoot = uiRoot
end

function XUiOrnamentGrid:Refresh(data, index)
    self.Index = index
    self.Data = data
    self.IsOwn = XDataCenter.ChristmasTreeManager.CheckOrnamentOwn(data.Id)
    local iconPath = XItemConfigs.GetItemIconById(data.ItemId)
    if self.IsOwn then
        self.RImgIcon.gameObject:SetActiveEx(true)
        self.RImgIcon:SetRawImage(iconPath)
        self.RImgLock.gameObject:SetActiveEx(false)
        self.GiftNone.gameObject:SetActiveEx(false)
    else
        self.RImgIcon.gameObject:SetActiveEx(false)
        self.RImgLock.gameObject:SetActiveEx(true)
        self.RImgLock:SetRawImage(iconPath)
        self.GiftNone.gameObject:SetActiveEx(true)
    end
    -- self.RImgIcon:CrossFadeAlpha( and 1 or 0.5, 0, false);
    self.TxtName.text = data.Name
    local isUnread = XDataCenter.ChristmasTreeManager.CheckOrnamentUnread(data.Id)
    --XLog.Warning("isUnread", isUnread, data.Id)
    self.RedPoint.gameObject:SetActiveEx(isUnread)
    CsXUiHelper.RegisterClickEvent(self.RImgBg, function() self:OpenDetail() end)
end

function XUiOrnamentGrid:ShowAttr(index)
    self.TxtName.text = string.format("%s：%d", XDataCenter.ChristmasTreeManager.GetAttrName(index), self.Data.Attr[index])
end

function XUiOrnamentGrid:OpenDetail()
    if self.UiRoot.ClickLock then return end
    XDataCenter.ChristmasTreeManager.SetOrnamentRead(self.Data.Id)
    local data = XDataCenter.ChristmasTreeManager.GetTempItemData(self.Data.Id)
    XLuaUiManager.Open("UiTip", data)
end

function XUiOrnamentGrid:GetInfo()
    -- 第三个参数是 isPlaced
    return self.Data, self.Index, false, self.IsOwn
end

return XUiOrnamentGrid