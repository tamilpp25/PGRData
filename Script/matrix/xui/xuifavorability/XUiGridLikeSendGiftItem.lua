
XUiGridLikeSendGiftItem = XClass(nil, "XUiGridLikeSendGiftItem")

local mathFloor = math.floor
local XMathClamp = XMath.Clamp
local stringFormat = string.format

local LongClickIntervel = 100
local AddCountPerPressTime = 1 / 150

function XUiGridLikeSendGiftItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.BtnMax.CallBack = function() self:OnClickBtnMax() end
    self.BtnMinus.CallBack = function() self:OnClickBtnMinus() end
    self.BtnAdd.CallBack = function() self:OnClickBtnAdd() end
    XUiButtonLongClick.New(self.PointerAdd, LongClickIntervel, self, nil, self.OnLongClickBtnAdd, nil, true)
    XUiButtonLongClick.New(self.PointerMinus, LongClickIntervel, self, nil, self.OnLongClickBtnMinus, nil, true)
    self.SelectCount = 0
    self.BtnMax.gameObject:SetActiveEx(false)

end

function XUiGridLikeSendGiftItem:Init(uiRoot,checkCall,changeCall,preCheck)
    self.UiRoot = uiRoot
    self.AddCountCheckCb= checkCall
    self.AddCountCb = changeCall
    self.PreCheck = preCheck
end

function XUiGridLikeSendGiftItem:ResetSelect()
    self:OnSelect(false)
end

function XUiGridLikeSendGiftItem:OnRefresh(trustItemData,count)
    self.SelectCount = count or 0
    self.TrustItem = trustItemData
    self.ItemId = trustItemData.Id
    local characterId = self.UiRoot:GetCurrFavorabilityCharacter()
    self.RImgIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(trustItemData.Id))
    self.ImgFlag.gameObject:SetActive(self:IsContains(trustItemData.FavorCharacterId, characterId))
    local giftQuality = XDataCenter.ItemManager.GetItemQuality(trustItemData.Id)
    self.UiRoot:SetUiSprite(self.ImgIconBg, XFavorabilityConfigs.GetQualityIconByQuality(giftQuality))
    self.ItemCount = XDataCenter.ItemManager.GetCount(trustItemData.Id)
    self.TxtCount.text = self.ItemCount
    self.TxtName.text = XDataCenter.ItemManager.GetItemName(self.ItemId)

    self:OnSelectCountChange(self.SelectCount)

end

function XUiGridLikeSendGiftItem:IsContains(container, item)
    for _, v in pairs(container or {}) do
        if v == item then
            return true
        end
    end
    return false
end

-- checkCount小于等于拥有数量时返回true
function XUiGridLikeSendGiftItem:CheckItemCount(checkCount)
    local isCountEnough = checkCount >= 0 and checkCount <= self.ItemCount
    if not isCountEnough then
        return false
    end
    local config = XFavorabilityConfigs.GetLikeTrustItemCfg(self.ItemId)
    if config and config.TrustItemType == XFavorabilityConfigs.TrustItemType.Communication and checkCount > 1 then
        XUiManager.TipText("SelectMultiSpecialGiftText")
        return false
    end
    return true
end

function XUiGridLikeSendGiftItem:OnSelectCountChange(newCount)
    self.SelectCount = newCount
    if newCount > 0 then
        self.TxtSelectNum.text = stringFormat("x%d", newCount)
        self.ImgSelect.gameObject:SetActiveEx(true)
        self.BtnMinus.gameObject:SetActiveEx(true)
        self.BtnMax.gameObject:SetActiveEx(true)
    else
        self.ImgSelect.gameObject:SetActiveEx(false)
        self.BtnMinus.gameObject:SetActiveEx(false)
        self.BtnMax.gameObject:SetActiveEx(false)
    end
end

function XUiGridLikeSendGiftItem:OnClickBtnAdd()
    local addCount = 1
    local newCount = self.SelectCount + addCount
    local itemId = self.ItemId

    if not self.PreCheck(itemId) then
        return
    end

    if not self:CheckItemCount(newCount) then
        XUiManager.TipMsg(CS.XTextManager.GetText("FavorabilityMaxGiftNum"))
        return
    end

    if not self.AddCountCheckCb(itemId, addCount) and itemId ~= 40801 then
        return
    end

    self:OnSelectCountChange(newCount)
    self.AddCountCb(itemId, addCount)
end

function XUiGridLikeSendGiftItem:OnLongClickBtnAdd(pressingTime)
    local addCount = 1
    local totalCount = XMathClamp(mathFloor(pressingTime * AddCountPerPressTime), 0, self.ItemCount)
    local newCount = self.SelectCount
    local itemId = self.ItemId

    if not self.PreCheck(itemId) then
        return
    end

    for _ = 1, totalCount do
        if not self.AddCountCheckCb(itemId, addCount) then
            break
        end

        newCount = newCount + addCount
        if not self:CheckItemCount(newCount) then
            XUiManager.TipMsg(CS.XTextManager.GetText("FavorabilityMaxGiftNum"))
            newCount = newCount - addCount
            break
        end

        self.AddCountCb(itemId, addCount)
    end

    self:OnSelectCountChange(newCount)
end

function XUiGridLikeSendGiftItem:OnClickBtnMinus()
    local addCount = -1
    addCount = addCount + self.SelectCount < 0 and -self.SelectCount or addCount
    local newCount = self.SelectCount + addCount
    local itemId = self.ItemId

    self:OnSelectCountChange(newCount)
    self.AddCountCb(itemId, addCount)
end

function XUiGridLikeSendGiftItem:OnLongClickBtnMinus(pressingTime)
    local addCount = -mathFloor(pressingTime * AddCountPerPressTime)
    addCount = addCount + self.SelectCount < 0 and -self.SelectCount or addCount
    local newCount = self.SelectCount + addCount
    local itemId = self.ItemId

    self:OnSelectCountChange(newCount)
    self.AddCountCb(itemId, addCount)
end

function XUiGridLikeSendGiftItem:OnClickBtnMax()
    local addCount = 1
    local totalCount = self.ItemCount
    local newCount = self.SelectCount
    local itemId = self.ItemId

    if not self.PreCheck(itemId) then
        return
    end

    for _ = 1, totalCount do
        if not self.AddCountCheckCb(itemId, addCount) then
            break
        end

        local total = newCount + addCount
        

        if not self:CheckItemCount(total) then
            break
        end
        
        newCount = total

        self.AddCountCb(itemId, addCount)
    end

    self:OnSelectCountChange(newCount)
end


return XUiGridLikeSendGiftItem