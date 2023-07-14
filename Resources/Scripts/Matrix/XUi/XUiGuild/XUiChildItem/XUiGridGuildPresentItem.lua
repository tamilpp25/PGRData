local XUiGridGuildPresentItem = XClass(nil, "XUiGridGuildPresentItem")

function XUiGridGuildPresentItem:Ctor(ui, uiRoot, callback)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot
    XTool.InitUiObject(self)
    self.ClickCallback = callback
    self.BtnGiftDetail.CallBack = function() self:OnBtnGiftDetailsClick() end

    XUiHelper.RegisterClickEvent(self, self.BtnSelect, self.OnBtnSelectClick)
end

-- ItemId = itemId,
-- ItemCount = itemCount,
-- Popularity = present.Popularity,
function XUiGridGuildPresentItem:RefreshGiftItem(gift, gridIndex)
    self.Gift = gift
    self.CurSelectNum = 0
    self.GridIndex = gridIndex
    self:SetSelectNum(self.CurSelectNum)

    local itemId = self.Gift.ItemId
    self.RImgIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(itemId))
    
    local itemQuality = XDataCenter.ItemManager.GetItemQuality(itemId)
    XUiHelper.SetQualityIcon(self.UiRoot, self.ImgIconQuality, itemQuality)

    self.TxtName.text = XDataCenter.ItemManager.GetItemName(itemId)
    self.TxtOwnCount.text = self.Gift.ItemCount
end


function XUiGridGuildPresentItem:SetSelectState(isSelected, forceRefresh)
    if isSelected ~= self.SelectState then
        self.SelectState = isSelected
        self:RefreshSelectState()
    else
        if forceRefresh then
            self:RefreshSelectState()
        end
    end
end

function XUiGridGuildPresentItem:RefreshSelectState()
    if self.ImgSelect then
        self.ImgSelect.gameObject:SetActive(self.SelectState)
    end
end

function XUiGridGuildPresentItem:GetSelectNums()
    local selectNum = self.CurSelectNum or 0
    local totalPopularity = 0
    totalPopularity = selectNum * self.Gift.Popularity
    return self.Gift.ItemId, selectNum, totalPopularity
end

function XUiGridGuildPresentItem:SetSelectNum(num)
    self.CurSelectNum = num
end

function XUiGridGuildPresentItem:OnBtnGiftDetailsClick()
    if not self.Gift then return end
    XLuaUiManager.Open("UiTip", self.Gift.ItemId)
end

function XUiGridGuildPresentItem:OnBtnSelectClick()
    if self.ClickCallback then
        self.ClickCallback({ Data = self.Gift, GridIndex = self.GridIndex, CurSelectNum = self.CurSelectNum }, self)
    end
end

function XUiGridGuildPresentItem:OnBtnAddSelectClick()
    if not self.Gift then return end
    if self.CurSelectNum + 1 <= self.Gift.ItemCount then
        self.CurSelectNum = self.CurSelectNum + 1
        self:SetSelectNum(self.CurSelectNum)
    end
end

function XUiGridGuildPresentItem:OnBtnMinusSelectClick()
    if self.CurSelectNum - 1 >= 0 then
        self.CurSelectNum = self.CurSelectNum - 1
        self:SetSelectNum(self.CurSelectNum)
    end 
end

return XUiGridGuildPresentItem