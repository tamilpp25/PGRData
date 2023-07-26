local XUiGridSpringFestivalRequestItem = XClass(nil, "XUiGridSpringFestivalRequestItem")

function XUiGridSpringFestivalRequestItem:Ctor(ui, callback)
    self.GameObject = ui
    self.Transform = ui.transform
    self.CallBack = callback
    XTool.InitUiObject(self)
    self:RegisterButtonEvent()
end

function XUiGridSpringFestivalRequestItem:RegisterButtonEvent()
    XUiHelper.RegisterClickEvent(self, self.Btn, self.OnSelect)
    XUiHelper.RegisterClickEvent(self, self.Btn2, self.OnClickBtnWord)
end

function XUiGridSpringFestivalRequestItem:OnClickBtnWord()
    local itemData = XDataCenter.ItemManager.GetItemTemplate(self.WordId)
    XLuaUiManager.Open("UiTip", itemData, false)
end

function XUiGridSpringFestivalRequestItem:OnSelect()
    if self.CallBack then
        self.CallBack(self.WordId)
    end
end

function XUiGridSpringFestivalRequestItem:ShowSelectBg(isShow)
    self.ImgSelect.gameObject:SetActive(isShow)
end

function XUiGridSpringFestivalRequestItem:Refresh(wordId)
    self.WordId = wordId
    self:RefreshIcon()
    self:RefreshCount()
end

function XUiGridSpringFestivalRequestItem:RefreshIcon()
    local icon = XDataCenter.ItemManager.GetItemIcon(self.WordId)
    if icon then
        self.RImgIcon:SetRawImage(icon)
    end
end

function XUiGridSpringFestivalRequestItem:RefreshCount()
    local count = XDataCenter.ItemManager.GetCount(self.WordId)
    self.TxtCount.text = count
end

return XUiGridSpringFestivalRequestItem