local TextManager = CS.XTextManager
local DropdownOptionData = CS.UnityEngine.UI.Dropdown.OptionData
local RestTypeConfig
local LBGetTypeConfig
local Next = _G.next
local UpdateTimerTypeEnum = {
    SettOff = 1,
    SettOn = 2
}

local XUiChongzhiTanchuangListItem = require("XUi/XUiGuardCamp/XUiChongzhiTanchuangListItem")

local XUiChongzhiTanchuang = XLuaUiManager.Register(XLuaUi, "UiChongzhiTanchuang")

function XUiChongzhiTanchuang:OnStart(data, buyCb, dropDownCb)
    RestTypeConfig = XPurchaseConfigs.RestTypeConfig
    LBGetTypeConfig = XPurchaseConfigs.LBGetTypeConfig
    self.CurState = false
    self.TitleGoPool = {}
    self.ItemPool = {}
    self.OpenBuyTipsList = {}
    self.BuyCb = buyCb
    self.DropDownCb = dropDownCb
    self.Data = data
    self:AutoAddListener()
end

function XUiChongzhiTanchuang:OnEnable()
    self:OnRefresh(self.Data)
end

function XUiChongzhiTanchuang:OnDisable()
    self:StopUpdateTimer()
end

function XUiChongzhiTanchuang:AutoAddListener()
    local closefun = function() self:Close() end
    self:RegisterClickEvent(self.BtnBgClick, self.Close)
    self:RegisterClickEvent(self.BtnCloseBg, self.Close)
    self:RegisterClickEvent(self.BtnBuy, self.OnBtnBuy)
    self.DrdSort.onValueChanged:RemoveAllListeners()
    self.DrdSort.onValueChanged:AddListener(function(index)
        if self.DropDownCb then
            self.DropDownCb(index)
        end
    end)
end

function XUiChongzhiTanchuang:OnDestroy()
    for _, v in pairs(self.ItemPool) do
        v.Transform:SetParent(self.PoolGo)
        v.GameObject:SetActive(false)
    end

    for _, v in pairs(self.TitleGoPool) do
        v:SetParent(self.PoolGo)
        v.gameObject:SetActive(false)
    end
end

-- 更新数据
function XUiChongzhiTanchuang:OnRefresh(data)
    if not data then
        return
    end
    CS.XAudioManager.PlaySound(1100)
    self.RetimeSec = 0
    self.UpdateTimerType = nil
    local curtime = XTime.GetServerNowTimestamp()
    
    self.Data = data

    -- 直接获得的道具
    self.ListDirData = {}
    self.ListDayData = {}
    local rewards0 = data.RewardGoodsList or {}
    for _, v in pairs(rewards0) do
        v.LBGetType = LBGetTypeConfig.Direct
        table.insert(self.ListDirData, v)
    end
    -- 每日获得的道具
    local rewards1 = data.DailyRewardGoodsList or {}
    for _, v in pairs(rewards1) do
        v.LBGetType = LBGetTypeConfig.Day
        table.insert(self.ListDayData, v)
    end
    local isUseMail = self.Data.IsUseMail or false
    self.TxtContinue.gameObject:SetActive(isUseMail)
    self:SetList()

    if data.TimeToInvalid and data.TimeToInvalid > 0 then
        self.RetimeSec = data.TimeToInvalid - curtime
        self.UpdateTimerType = UpdateTimerTypeEnum.SettOff
        if self.RetimeSec > 0 then
            self.TXtTime.gameObject:SetActive(true)
            self:StartUpdateTimer()
            self.TXtTime.text = TextManager.GetText("PurchaseSetOffTime", XUiHelper.GetTime(self.RetimeSec))
        else
            self.TXtTime.gameObject:SetActive(false)
            self:StopUpdateTimer()
        end
    else
        if (data.TimeToShelve == nil or data.TimeToShelve == 0) and (data.TimeToUnShelve == nil or data.TimeToUnShelve == 0) then
            self.TXtTime.gameObject:SetActive(false)
        else
            self.TXtTime.gameObject:SetActive(true)
            if data.TimeToUnShelve > 0 then
                self.RetimeSec = data.TimeToUnShelve - curtime
                self.UpdateTimerType = UpdateTimerTypeEnum.SettOff
                self.TXtTime.text = TextManager.GetText("PurchaseSetOffTime", XUiHelper.GetTime(self.RetimeSec))
            else
                self.RetimeSec = data.TimeToShelve - curtime
                self.UpdateTimerType = UpdateTimerTypeEnum.SettOn
                self.TXtTime.text = TextManager.GetText("PurchaseSetOnTime", XUiHelper.GetTime(self.RetimeSec))
            end
            if self.RetimeSec > 0 then
                self:StartUpdateTimer()
            else
                self:StopUpdateTimer()
            end
        end
    end

    self.TxtName.text = data.Name
    local assetpath = XPurchaseConfigs.GetIconPathByIconName(data.Icon)
    if assetpath and assetpath.AssetPath then
        self.RawImageIcon:SetRawImage(assetpath.AssetPath)
    end
    self:SetBuyDes()
    local disCountValue = XDataCenter.PurchaseManager.GetLBDiscountValue(data)
    if data.ConsumeCount == 0 then
        self.TxtPrice.gameObject:SetActiveEx(false)
        self.RawImageConsume.gameObject:SetActive(false)
        self.BtnBuy:SetName(TextManager.GetText("PurchaseFreeText"))
    elseif XPurchaseConfigs.GetTagType(data.Tag) == XPurchaseConfigs.PurchaseTagType.Discount and disCountValue < 1 then -- 打折的
        self.RawImageConsume.gameObject:SetActive(true)
        self.BtnBuy:SetName(math.modf(data.ConsumeCount * disCountValue))
        local icon = XDataCenter.ItemManager.GetItemIcon(data.ConsumeId)
        if icon then
            self.RawImageConsume:SetRawImage(icon)
        end
        self.TxtPrice.gameObject:SetActiveEx(true)
        self.TxtPrice.text = data.ConsumeCount
    else
        self.TxtPrice.gameObject:SetActiveEx(false)
        self.RawImageConsume.gameObject:SetActive(true)
        self.BtnBuy:SetName(data.ConsumeCount)
        local icon = XDataCenter.ItemManager.GetItemIcon(data.ConsumeId)
        if icon then
            self.RawImageConsume:SetRawImage(icon)
        end
    end

    --是否已拥有
    local isHave, isLimitTime = XRewardManager.CheckRewardGoodsListIsOwn(data.RewardGoodsList)
    local isShowHave = isHave and not isLimitTime
    self.TxtHave.gameObject:SetActive(isShowHave)
    if isShowHave then
        if #data.RewardGoodsList > 1 then
            self.TxtHave.text = TextManager.GetText("PurchaseLBHaveFashion")
            self.BtnBuy:SetDisable(not isShowHave)
        else
            self.TxtHave.text = TextManager.GetText("PurchaseLBHaveFashionCantBuy")
            self.BtnBuy:SetDisable(isShowHave, not isShowHave)
        end
    else
        self.BtnBuy:SetDisable(false)
        if (data.BuyLimitTimes > 0 and data.BuyTimes == data.BuyLimitTimes) or (data.TimeToShelve > 0 and data.TimeToShelve <= curtime) or (data.TimeToUnShelve > 0 and data.TimeToUnShelve <= curtime) then --卖完了，不管。
            self.TXtTime.text = ""
            if self.UpdateTimerType then
                self:StopUpdateTimer()
            end
            self.TxtPrice.gameObject:SetActiveEx(false)
            self.BtnBuy:SetButtonState(XUiButtonState.Disable)
        else
            self.BtnBuy:SetButtonState(XUiButtonState.Normal)
        end
    end

    if data.DiscountCouponInfos and #data.DiscountCouponInfos > 0 then
        self.DrdSort.gameObject:SetActiveEx(true)
        self.DrdSort:ClearOptions()
        local od = DropdownOptionData(TextManager.GetText("UnUsedCouponDiscount"))
        self.DrdSort.options:Add(od)
        self.DrdSort.captionText.text = TextManager.GetText("UnUsedCouponDiscount")
        self.AllCoupouMaxEndTime = 0
        for _, optionData in ipairs(data.DiscountCouponInfos) do
            local itemId = optionData.ItemId
            local itemName = XDataCenter.ItemManager.GetItemName(itemId)
            local count = XDataCenter.ItemManager.GetCount(itemId)
            local od = DropdownOptionData(itemName .. TextManager.GetText("DiscountCouponRemain", count))
            self.DrdSort.options:Add(od)
            if optionData.EndTime > self.AllCoupouMaxEndTime then
                self.AllCoupouMaxEndTime = optionData.EndTime
            end
        end
        self.DrdSort.value = 0
        local nowTime = XTime.GetServerNowTimestamp()
        self.TxtTimeCoupon.text = TextManager.GetText("CouponEndTime", XUiHelper.GetTime(self.AllCoupouMaxEndTime - nowTime, XUiHelper.TimeFormatType.SHOP))
        self.IsHasCoupon = true
    else
        self.DrdSort.gameObject:SetActiveEx(false)
        self.IsHasCoupon = false
    end
end

function XUiChongzhiTanchuang:StartUpdateTimer()
    self:StopUpdateTimer()
    self.Timer = XScheduleManager.ScheduleForever(function()
        self:UpdateTimer()
    end, XScheduleManager.SECOND, 0)
end

function XUiChongzhiTanchuang:StopUpdateTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

-- 更新倒计时
function XUiChongzhiTanchuang:UpdateTimer()
    self:UpdateCouponRemainTime()

    self.RetimeSec = self.RetimeSec - 1

    if self.RetimeSec <= 0 then
        self:StopUpdateTimer(self.Data.Id)
        if self.UpdateTimerType == UpdateTimerTypeEnum.SettOff then
            self.TXtTime.text = TextManager.GetText("PurchaseLBSettOff")
            return
        end

        self.TXtTime.text = ""
        return
    end

    if self.UpdateTimerType == UpdateTimerTypeEnum.SettOff then
        self.TXtTime.text = TextManager.GetText("PurchaseSetOffTime", XUiHelper.GetTime(self.RetimeSec))
        return
    end

    self.TXtTime.text = TextManager.GetText("PurchaseSetOnTime", XUiHelper.GetTime(self.RetimeSec))
end

function XUiChongzhiTanchuang:UpdateCouponRemainTime()     -- 打折券倒计时更新
    if not self.IsHasCoupon then
        return
    end

    local nowTime = XTime.GetServerNowTimestamp()
    local remainTime = self.AllCoupouMaxEndTime - nowTime
    if remainTime > 0 then
        self.TxtTimeCoupon.text = TextManager.GetText("CouponEndTime", XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.SHOP))
    else
        self.DrdSort.value = 0
        self.TxtTimeCoupon.text = ""
        self.DrdSort.gameObject:SetActiveEx(false)
        self.IsHasCoupon = false
    end
end

function XUiChongzhiTanchuang:SetList()
    local index1 = 1
    local index2 = 1

    if Next(self.ListDirData) ~= nil then
        local obj = self:GetTitleGo(index1)
        index1 = index1 + 1
        obj.transform:Find("TxtTitle"):GetComponent("Text").text = TextManager.GetText("PurchaseDirGet")
        for _, v in pairs(self.ListDirData) do
            local item = self:GetItemObj(index2)
            item:OnRefresh(v)
            index2 = index2 + 1
        end
    end

    if Next(self.ListDayData) ~= nil then
        local obj = self:GetTitleGo(index1)
        obj.transform:Find("TxtTitle"):GetComponent("Text").text = self.Data.Desc or ""
        for _, v in pairs(self.ListDayData) do
            local item = self:GetItemObj(index2)
            item:OnRefresh(v)
            index2 = index2 + 1
        end
    end
end

function XUiChongzhiTanchuang:GetTitleGo(index)
    if self.TitleGoPool[index] then
        self.TitleGoPool[index].gameObject:SetActive(true)
        self.TitleGoPool[index]:SetParent(self.PanelReward)
        return self.TitleGoPool[index]
    end

    local obj = CS.UnityEngine.Object.Instantiate(self.ImgTitle, self.PanelReward)
    obj.gameObject:SetActive(true)
    obj:SetParent(self.PanelReward)
    table.insert(self.TitleGoPool, obj)
    return obj
end

function XUiChongzhiTanchuang:GetItemObj(index)
    if self.ItemPool[index] then
        self.ItemPool[index].GameObject:SetActive(true)
        self.ItemPool[index].Transform:SetParent(self.PanelReward)
        return self.ItemPool[index]
    end

    local itemobj = CS.UnityEngine.Object.Instantiate(self.PanelPropItem, self.PanelReward)
    itemobj.gameObject:SetActive(true)
    itemobj:SetParent(self.PanelReward)
    local item = XUiChongzhiTanchuangListItem.New(itemobj)
    item:Init(self)
    table.insert(self.ItemPool, item)
    return item
end

-- [监听动态列表事件]
-- function XUiChongzhiTanchuang:OnDynamicTableEvent(event, index, grid)
--     if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
--         grid:Init(self, self)
--     elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
--         local data = self.ListData[index]
--         grid:OnRefresh(data)
--     end
-- end

function XUiChongzhiTanchuang:SetBuyDes()
    local clientResetInfo = self.Data.ClientResetInfo or {}
    if Next(clientResetInfo) == nil then
        self.TxtLimitBuy.gameObject:SetActiveEx(false)
        self.TxtLimitBuy.text = ""
        return
    end

    local textKey = nil
    if clientResetInfo.ResetType == RestTypeConfig.Interval then
        self.TxtLimitBuy.gameObject:SetActiveEx(true)
        self.TxtLimitBuy.text = TextManager.GetText("PurchaseRestTypeInterval", clientResetInfo.DayCount, self.Data.BuyTimes, self.Data.BuyLimitTimes)
        return
    elseif clientResetInfo.ResetType == RestTypeConfig.Day then
        textKey = "PurchaseRestTypeDay"
    elseif clientResetInfo.ResetType == RestTypeConfig.Week then
        textKey = "PurchaseRestTypeWeek"
    elseif clientResetInfo.ResetType == RestTypeConfig.Month then
        textKey = "PurchaseRestTypeMonth"
    end

    if not textKey then
        self.TxtLimitBuy.text = ""
        self.TxtLimitBuy.gameObject:SetActiveEx(false)
        return
    end
    self.TxtLimitBuy.gameObject:SetActiveEx(true)
    self.TxtLimitBuy.text = TextManager.GetText(textKey, self.Data.BuyTimes, self.Data.BuyLimitTimes)
end

function XUiChongzhiTanchuang:OnBtnBuy()
    if self.Data.BuyLimitTimes and self.Data.BuyTimes and self.Data.BuyLimitTimes > 0 and self.Data.BuyTimes == self.Data.BuyLimitTimes then --卖完了，不管。
        XUiManager.TipText("PurchaseLiSellOut")
        return
    end

    if self.Data.TimeToShelve and self.Data.TimeToShelve > 0 and self.Data.TimeToShelve > XTime.GetServerNowTimestamp() then --没有上架
        XUiManager.TipText("PurchaseBuyNotSet")
        return
    end

    if self.Data.TimeToUnShelve and self.Data.TimeToUnShelve > 0 and self.Data.TimeToUnShelve < XTime.GetServerNowTimestamp() then --下架了
        XUiManager.TipText("PurchaseSettOff")
        return
    end

    if self.Data.TimeToInvalid and self.Data.TimeToInvalid > 0 and self.Data.TimeToInvalid < XTime.GetServerNowTimestamp() then --失效了
        XUiManager.TipText("PurchaseSettOff")
        return
    end

    local consumeCount = self.Data.ConsumeCount
    if consumeCount and self.Data.Tag and XPurchaseConfigs.GetTagType(self.Data.Tag) == XPurchaseConfigs.PurchaseTagType.Discount then -- 计算打折后的钱
        local disCountValue = XDataCenter.PurchaseManager.GetLBDiscountValue(self.Data)
        consumeCount = math.floor(disCountValue * consumeCount)
    end
    if consumeCount and self.Data.ConsumeId and consumeCount > 0 and consumeCount > XDataCenter.ItemManager.GetCount(self.Data.ConsumeId) then --钱不够
        local name = XDataCenter.ItemManager.GetItemName(self.Data.ConsumeId) or ""
        local tips = CS.XTextManager.GetText("PurchaseBuyKaCountTips", name)
        XUiManager.TipMsg(tips,XUiManager.UiTipType.Wrong)
        if self.Data.ConsumeId == XDataCenter.ItemManager.ItemId.PaidGem then
            XLuaUiManager.Open("UiPurchase", XPurchaseConfigs.TabsConfig.HK, false)
        elseif self.Data.ConsumeId == XDataCenter.ItemManager.ItemId.HongKa then
            XLuaUiManager.Open("UiPurchase", XPurchaseConfigs.TabsConfig.Pay, false)
        end
        return
    end

    if self:CheckIsOpenBuyTips(self.Data.RewardGoodsList) then
        return
    end

    self:PurchaseRequest()
end

function XUiChongzhiTanchuang:CheckIsOpenBuyTips(rewardGoodsList)
    if not rewardGoodsList then return false end
    for k, v in pairs(rewardGoodsList) do
        if XRewardManager.CheckRewardOwn(v.RewardType, v.TemplateId) then
            local tipContent = {}
            tipContent["title"] = CSXTextManagerGetText("PurchaseFashionRepeatTipsTitle")
            tipContent["content"] = CSXTextManagerGetText("PurchaseFashionRepeatTipsContent")
            table.insert(self.OpenBuyTipsList, tipContent)
        end
    end
    if #self.OpenBuyTipsList > 0 then
        self:OpenBuyTips()
        return true
    end
    return false
end

function XUiChongzhiTanchuang:OpenBuyTips()
    if #self.OpenBuyTipsList > 0 then
        local tipContent = table.remove(self.OpenBuyTipsList, 1)
        local sureCallback = function ()
            if #self.OpenBuyTipsList > 0 then
                self:OpenBuyTips()
            else
                self:PurchaseRequest()
            end
        end
        local closeCallback = function()
            self.OpenBuyTipsList = {}
        end
        XUiManager.DialogTip(tipContent["title"], tipContent["content"], XUiManager.DialogType.Normal, closeCallback, sureCallback)
    end
end

function XUiChongzhiTanchuang:PurchaseRequest()
    if self.Data and self.Data.Id then
        XDataCenter.PurchaseManager.PurchaseRequest(self.Data.Id, self.BuyCb)
        self:Close()
    end
end