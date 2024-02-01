local XUiPurchaseCoatingLBListItem = XClass(nil, "XUiPurchaseCoatingLBListItem")
local TextManager = CS.XTextManager
local RestTypeConfig
local Next = _G.next
local UpdateTimerTypeEnum = {
    SettOff = 1,
    SettOn = 2
}
function XUiPurchaseCoatingLBListItem:Ctor(ui, uiRoot)
    RestTypeConfig = XPurchaseConfigs.RestTypeConfig
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot
    XTool.InitUiObject(self)
    self.OriginSize = self.ImgIconLb.rectTransform.sizeDelta
    self.TimerUpdateCb = function(isRecover) self:UpdateTimer(isRecover) end
end

-- 更新数据
function XUiPurchaseCoatingLBListItem:OnRefresh(itemData)
    if not itemData then
        return
    end

    self.ItemData = itemData
    self:SetData()
    self:RefreshGift()
end

function XUiPurchaseCoatingLBListItem:Init(uiRoot, parent)
    self.UiRoot = uiRoot
    self.Parent = parent
end

function XUiPurchaseCoatingLBListItem:SetData()
    if self.ItemData.Icon then
        local iconPath = XPurchaseConfigs.GetIconPathByIconName(self.ItemData.Icon)
        if iconPath then
            if iconPath.CoverImgPath then
                self.ImgIconLb:SetRawImage(iconPath.CoverImgPath, function() self.ImgIconLb.rectTransform.sizeDelta = self.OriginSize end)
            elseif iconPath.AssetPath then
                self.ImgIconLb:SetRawImage(iconPath.AssetPath, function() self.ImgIconLb:SetNativeSize() end)
            end
        end
    end
    self.TxtName.text = self.ItemData.Name
    self.ImgSellout.gameObject:SetActive(false)
    self.ImgHave.gameObject:SetActive(false)
    self.TxtUnShelveTime.gameObject:SetActive(false)
    self.TextNotNeed.gameObject:SetActiveEx(false)
    self.Parent:RemoveTimerFun(self.ItemData.Id)
    self.RemainTime = 0
    local nowTime = XTime.GetServerNowTimestamp()

    self.IsDisCount = false
    local tag = self.ItemData.Tag
    local isShowTag = false
    if tag > 0 then
        isShowTag = true
        local path = XPurchaseConfigs.GetTagBgPath(tag)
        if path then
           self.UiRoot:SetUiSprite(self.ImgTagBg, path)
        end
        local tagText = XPurchaseConfigs.GetTagDes(tag)
        
        if XPurchaseConfigs.GetTagType(tag) == XPurchaseConfigs.PurchaseTagType.Discount then
            local disCountValue = XDataCenter.PurchaseManager.GetLBDiscountValue(self.ItemData)
            if disCountValue < 1 then
                local disCountStr = string.format("%.1f", disCountValue * 10)
                if self.ItemData.DiscountShowStr and self.ItemData.DiscountShowStr ~= "" then
                    disCountStr = self.ItemData.DiscountShowStr
                end
                tagText = disCountStr..tagText
                self.IsDisCount = true
            else
                isShowTag = false
            end
        end
        self.TxtTagDes.text = tagText
    else
        isShowTag = false
    end
    self.PanelLabel.gameObject:SetActive(isShowTag)

    local consumeCount = self.ItemData.ConsumeCount or 0
    self.RedPoint.gameObject:SetActive(false)
    if consumeCount == 0 then -- 免费的
        self.TxtHk.gameObject:SetActive(false)
        self.TxtHk2.gameObject:SetActiveEx(false)
        self.TxtFree.gameObject:SetActive(true)
        local isShowRedPoint = (self.ItemData.BuyTimes == 0 or self.ItemData.BuyTimes < self.ItemData.BuyLimitTimes) 
        and (self.ItemData.TimeToShelve == 0 or self.ItemData.TimeToShelve < nowTime)
        and (self.ItemData.TimeToUnShelve == 0 or self.ItemData.TimeToUnShelve > nowTime)
        self.RedPoint.gameObject:SetActive(isShowRedPoint)
    elseif self.IsDisCount or self.ItemData.ConvertSwitch < consumeCount then -- 打折或者存在拥有物品折扣的
        self.TxtFree.gameObject:SetActive(false)
        self.TxtHk.gameObject:SetActive(false)
        local path = XDataCenter.ItemManager.GetItemIcon(self.ItemData.ConsumeId)
        if path then
            self.RawConsumeImage2:SetRawImage(path)
        end
        if self.ItemData.ConvertSwitch <= 0 then
            self.TxtHk2.gameObject:SetActiveEx(false)
            self.TextNotNeed.gameObject:SetActiveEx(true)
        else
            self.TxtHk2.gameObject:SetActiveEx(true)
            --self.TextNotNeed.gameObject:SetActiveEx(false)
            local consumeNum = consumeCount
            if self.ItemData.ConvertSwitch > 0 and self.ItemData.ConvertSwitch < consumeCount then
                consumeNum = self.ItemData.ConvertSwitch
            end
            if self.IsDisCount then
                local disCountValue = XDataCenter.PurchaseManager.GetLBDiscountValue(self.ItemData)
                consumeNum = math.modf(disCountValue * consumeNum) or ""
            end
            self.TxtHk2.text = consumeNum
        end
        self.TxtPrice.text = self.ItemData.ConsumeCount or ""
    else
        self.TxtFree.gameObject:SetActive(false)
        self.TxtHk2.gameObject:SetActiveEx(false)
        self.TxtHk.gameObject:SetActive(true)
        local path = XDataCenter.ItemManager.GetItemIcon(self.ItemData.ConsumeId)
        if path then
            self.RawConsumeImage:SetRawImage(path)
        end
        self.TxtHk.text = self.ItemData.ConsumeCount or ""
    end

    -- 上架时间
    if self.ItemData.TimeToShelve > 0 and nowTime < self.ItemData.TimeToShelve then
        self.RemainTime = self.ItemData.TimeToShelve - XTime.GetServerNowTimestamp()
        if self.RemainTime > 0 then--大于0，注册。
            self.UpdateTimerType = UpdateTimerTypeEnum.SettOn
            self.Parent:RegisterTimerFun(self.ItemData.Id, function() self:UpdateTimer() end)
        else
            self.Parent:RemoveTimerFun(self.ItemData.Id)
        end
        self.TxtPutawayTime.gameObject:SetActive(true)
        self.TxtHk.gameObject:SetActive(false)
        self.TxtFree.gameObject:SetActive(false)
        self.TxtPutawayTime.text = TextManager.GetText("PurchaseSetOnTime", XUiHelper.GetTime(self.RemainTime, XUiHelper.TimeFormatType.PURCHASELB))
        self:SetBuyDes()
        return
    end

    -- 达到限购次数
    if self.ItemData.BuyLimitTimes and self.ItemData.BuyLimitTimes > 0 and self.ItemData.BuyTimes == self.ItemData.BuyLimitTimes then
        self.ImgSellout.gameObject:SetActive(true)
        self.TxtSetOut.text = TextManager.GetText("PurchaseSettOut")
        self.TxtFree.gameObject:SetActive(false)
        self.TxtHk.gameObject:SetActive(false)
        self.TxtQuota.text = TextManager.GetText("PurchaseLimitBuy", self.ItemData.BuyTimes, self.ItemData.BuyLimitTimes)
        return
    end

    --是否已拥有
    if self.ImgHave then
        local isShowHave = XDataCenter.PurchaseManager.IsLBHave(self.ItemData)
        self.ImgHave.gameObject:SetActive(isShowHave)
    end

    self.ImgQuota.gameObject:SetActive(true)
    self:SetBuyDes()

    --有失效时间只显示失效时间。
    -- 失效时间
    if self.ItemData.TimeToInvalid and self.ItemData.TimeToInvalid > 0 then
        self.RemainTime = self.ItemData.TimeToInvalid - XTime.GetServerNowTimestamp()
        if self.RemainTime > 0 then--大于0，注册。
            self.UpdateTimerType = UpdateTimerTypeEnum.SettOff
            self.Parent:RegisterTimerFun(self.ItemData.Id, self.TimerUpdateCb)
            self.TxtUnShelveTime.gameObject:SetActive(true)
            if self.IsDisCount then
                self.TxtUnShelveTime.text = TextManager.GetText("PurchaseSetOffTime", XUiHelper.GetTime(self.RemainTime, XUiHelper.TimeFormatType.PURCHASELB))
            else
                self.TxtUnShelveTime.text = TextManager.GetText("PurchaseSetOffTime", XUiHelper.GetTime(self.RemainTime, XUiHelper.TimeFormatType.PURCHASELB))
            end
        else
            self.Parent:RemoveTimerFun(self.ItemData.Id)
            self.TxtUnShelveTime.gameObject:SetActive(false)
            self.ImgSellout.gameObject:SetActive(true)
            self.TxtSetOut.text = TextManager.GetText("PurchaseLBSettOff")
        end
        return
    end

    -- 下架时间
    if self.ItemData.TimeToUnShelve > 0 then
        if nowTime < self.ItemData.TimeToUnShelve then
            self.RemainTime = self.ItemData.TimeToUnShelve - XTime.GetServerNowTimestamp()
            if self.RemainTime > 0 then--大于0，注册。
                self.UpdateTimerType = UpdateTimerTypeEnum.SettOff
                self.Parent:RegisterTimerFun(self.ItemData.Id, self.TimerUpdateCb)
                self.TxtUnShelveTime.gameObject:SetActive(true)
                if self.IsDisCount then
                    self.TxtUnShelveTime.text = TextManager.GetText("PurchaseSetOffTime", XUiHelper.GetTime(self.RemainTime, XUiHelper.TimeFormatType.PURCHASELB))
                else
                    self.TxtUnShelveTime.text = TextManager.GetText("PurchaseSetOffTime", XUiHelper.GetTime(self.RemainTime, XUiHelper.TimeFormatType.PURCHASELB))
                end
            else
                self.Parent:RemoveTimerFun(self.ItemData.Id)
                self.TxtUnShelveTime.gameObject:SetActive(false)
            end
        else
            self.ImgSellout.gameObject:SetActive(true)
            self.TxtUnShelveTime.text = ""
            self.TxtSetOut.text = TextManager.GetText("PurchaseLBSettOff")
        end
    else
        self.TxtUnShelveTime.gameObject:SetActive(false)
    end
end

function XUiPurchaseCoatingLBListItem:SetBuyDes()
    local clientResetInfo = self.ItemData.ClientResetInfo or {}
    if Next(clientResetInfo) == nil then
        if self.ItemData.BuyLimitTimes > 0 then
            self.TxtQuota.text = TextManager.GetText("PurchaseLimitBuy", self.ItemData.BuyTimes, self.ItemData.BuyLimitTimes)
        else
            self.ImgQuota.gameObject:SetActive(false)
        end
        return
    end

    local textKey = ""
    if clientResetInfo.ResetType == RestTypeConfig.Interval then
        self.TxtQuota.text = TextManager.GetText("PurchaseRestTypeInterval", clientResetInfo.DayCount, self.ItemData.BuyTimes, self.ItemData.BuyLimitTimes)
        return
    elseif clientResetInfo.ResetType == RestTypeConfig.Day then
        textKey = "PurchaseRestTypeDay"
    elseif clientResetInfo.ResetType == RestTypeConfig.Week then
        textKey = "PurchaseRestTypeWeek"
    elseif clientResetInfo.ResetType == RestTypeConfig.Month then
        textKey = "PurchaseRestTypeMonth"
    end
    self.TxtQuota.text = TextManager.GetText(textKey, self.ItemData.BuyTimes, self.ItemData.BuyLimitTimes)
end

-- 更新倒计时
function XUiPurchaseCoatingLBListItem:UpdateTimer(isRecover)
    if self.ItemData.TimeToInvalid == 0 and self.ItemData.TimeToUnShelve == 0 and self.ItemData.TimeToShelve == 0 then
        return
    end

    if isRecover then
        if self.UpdateTimerType == UpdateTimerTypeEnum.SettOff then
            if self.ItemData.TimeToInvalid > 0 then
                self.RemainTime = self.ItemData.TimeToInvalid - XTime.GetServerNowTimestamp()
            else
                self.RemainTime = self.ItemData.TimeToUnShelve - XTime.GetServerNowTimestamp()
            end
        else
            self.RemainTime = self.ItemData.TimeToShelve - XTime.GetServerNowTimestamp()
        end
    else
        self.RemainTime = self.RemainTime - 1
    end

    if self.RemainTime <= 0 then
        self.Parent:RemoveTimerFun(self.ItemData.Id)
        if self.UpdateTimerType == UpdateTimerTypeEnum.SettOff then
            self.ImgSellout.gameObject:SetActive(true)
            self.TxtUnShelveTime.text = ""
            if self.ItemData.BuyLimitTimes and self.ItemData.BuyLimitTimes > 0 and self.ItemData.BuyTimes == self.ItemData.BuyLimitTimes then
                self.TxtSetOut.text = TextManager.GetText("PurchaseSettOut")
            else
                self.TxtSetOut.text = TextManager.GetText("PurchaseLBSettOff")
            end
            return
        end

        self.TxtPutawayTime.text = ""
        return
    end

    if self.UpdateTimerType == UpdateTimerTypeEnum.SettOff then
        self.TxtUnShelveTime.text = TextManager.GetText("PurchaseSetOffTime", XUiHelper.GetTime(self.RemainTime, XUiHelper.TimeFormatType.PURCHASELB))
        return
    end
    self.TxtPutawayTime.text = TextManager.GetText("PurchaseSetOnTime", XUiHelper.GetTime(self.RemainTime, XUiHelper.TimeFormatType.PURCHASELB))
end

function XUiPurchaseCoatingLBListItem:RefreshGift()
    for i, data in pairs(self.ItemData.RewardGoodsList) do
        --2.10 涂装赠品
        if data.RewardType == XRewardManager.XRewardType.Fashion then
            local fashionId = data.TemplateId
            local fashionCfg = XFashionConfigs.GetFashionTemplate(fashionId)
            if fashionCfg and XTool.IsNumberValid(fashionCfg.GiftId) then
                self.ImgTabLb.gameObject:SetActiveEx(true)
                break
            else
                self.ImgTabLb.gameObject:SetActiveEx(false)
            end
        else
            self.ImgTabLb.gameObject:SetActiveEx(false)
        end
    end
    
end

return XUiPurchaseCoatingLBListItem