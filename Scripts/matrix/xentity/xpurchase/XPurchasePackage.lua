local XPurchasePackage = XClass(nil, "XPurchasePackage")

function XPurchasePackage:Ctor(id)
    -- XPurchaseClientInfo
    self.Data = nil
end

-- XPurchaseClientInfo
function XPurchasePackage:InitWithServerData(data)
    self.Data = data
end

function XPurchasePackage:GetRawData()
    return self.Data
end

function XPurchasePackage:GetId()
    return self.Data.Id
end

function XPurchasePackage:GetName()
    return self.Data.Name
end

function XPurchasePackage:GetDesc()
    return self.Data.Desc
end

function XPurchasePackage:GetIcon()
    return self.Data.Icon
end

function XPurchasePackage:GetUiType()
    return self.Data.UiType
end

-- 获取购买次数限制
function XPurchasePackage:GetBuyLimitTime()
    return self.Data.BuyLimitTimes
end

-- 获取当前购买次数
function XPurchasePackage:GetCurrentBuyTime()
    return self.Data.BuyTimes
end

-- 获取每日奖励领取剩余天数
function XPurchasePackage:GetDailyRewardRemainDay()
    if self.Data.BuyTimes > 0 then
        return self.Data.DailyRewardRemainDay
    end
    return 0
end

function XPurchasePackage:GetConsumeCount()
    return self.Data.ConsumeCount
end

function XPurchasePackage:GetConsumeId()
    return self.Data.ConsumeId
end

function XPurchasePackage:GetClientResetInfo()
    return self.Data.ClientResetInfo
end

--######################## 将旧Ui耦合的逻辑直接迁移到数据层中处理 BEGIN ########################
function XPurchasePackage:CheckCanBuy(count, disCountCouponIndex, notEnoughCb)
    count = count or 1
    disCountCouponIndex = disCountCouponIndex or 0
    if self.Data.BuyLimitTimes > 0 and self.Data.BuyTimes == self.Data.BuyLimitTimes then --卖完了，不管。
        XUiManager.TipText("PurchaseLiSellOut")
        return 0
    end
    if self.Data.TimeToShelve > 0 and self.Data.TimeToShelve > XTime.GetServerNowTimestamp() then --没有上架
        XUiManager.TipText("PurchaseBuyNotSet")
        return 0
    end
    if self.Data.TimeToUnShelve > 0 and self.Data.TimeToUnShelve < XTime.GetServerNowTimestamp() then --下架了
        XUiManager.TipText("PurchaseSettOff")
        return 0
    end
    if self.Data.TimeToInvalid > 0 and self.Data.TimeToInvalid < XTime.GetServerNowTimestamp() then --失效了
        XUiManager.TipText("PurchaseSettOff")
        return 0
    end
    if self.Data.ConsumeCount > 0 and self.Data.ConvertSwitch <= 0 then -- 礼包内容全部拥有
        XUiManager.TipText("PurchaseRewardAllHaveErrorTips")
        return 0
    end
    local consumeCount = self.Data.ConsumeCount
    if disCountCouponIndex and disCountCouponIndex ~= 0 then
        local disCountValue = XDataCenter.PurchaseManager.GetLBCouponDiscountValue(self.Data, disCountCouponIndex)
        consumeCount = math.floor(disCountValue * consumeCount)
    else
        if self.Data.ConvertSwitch and consumeCount > self.Data.ConvertSwitch then -- 已经被服务器计算了抵扣和折扣后的钱
            consumeCount = self.Data.ConvertSwitch
        end
        if XPurchaseConfigs.GetTagType(self.Data.Tag) == XPurchaseConfigs.PurchaseTagType.Discount then -- 计算打折后的钱(普通打折或者选择了打折券)
            local disCountValue = XDataCenter.PurchaseManager.GetLBDiscountValue(self.Data)
            consumeCount = math.floor(disCountValue * consumeCount)
        end
    end
    consumeCount = count * consumeCount -- 全部数量的总价
    if consumeCount > 0 and consumeCount > XDataCenter.ItemManager.GetCount(self.Data.ConsumeId) then --钱不够
        -- local name = XDataCenter.ItemManager.GetItemName(self.Data.ConsumeId) or ""
        -- local tips = XUiHelper.GetText("PurchaseBuyKaCountTips", name)
        if XUiHelper.CanBuyInOtherPlatformHongKa(consumeCount) then
            return 2
        end
        local tips = XUiHelper.GetCountNotEnoughTips(self.Data.ConsumeId);
        XUiManager.TipMsg(tips,XUiManager.UiTipType.Wrong)
        if self.Data.ConsumeId == XDataCenter.ItemManager.ItemId.PaidGem then
            if notEnoughCb then
                notEnoughCb(XPurchaseConfigs.TabsConfig.HK)
            end
        elseif self.Data.ConsumeId == XDataCenter.ItemManager.ItemId.HongKa then
            if notEnoughCb then
                notEnoughCb(XPurchaseConfigs.TabsConfig.Pay)
            end
        end
        return 0
    end
    return 1
end

function XPurchasePackage:HandleBeforeBuy(successCb)
    if self.__OpenBuyTipsList == nil then self.__OpenBuyTipsList = {} end
    -- 礼包被计算拥有物品折扣价后，拥有物品不会下发，所以无需二次提示转化碎片
    if self.Data.ConvertSwitch and self.Data.ConsumeCount > self.Data.ConvertSwitch then
        if successCb then successCb() end
        return
    end
    local rewardGoodsList = self.Data.RewardGoodsList
    if not rewardGoodsList then
        if successCb then successCb() end
        return
    end
    for _, v in pairs(rewardGoodsList) do
        if XRewardManager.IsRewardWeaponFashion(v.RewardType, v.TemplateId) then
            local isHave, ownRewardIsLimitTime, rewardIsLimitTime, leftTime = XRewardManager.CheckRewardOwn(v.RewardType, v.TemplateId)
            if isHave then
                if not ownRewardIsLimitTime or not rewardIsLimitTime then
                    local tipContent = {}
                    tipContent["title"] = XUiHelper.GetText("WeaponFashionConverseTitle")
                    --自己拥有的武器涂装是限时的去买永久的
                    if ownRewardIsLimitTime and not rewardIsLimitTime then          
                        local timeText = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
                        tipContent["content"] = #rewardGoodsList > 1 and XUiHelper.GetText("OwnLimitBuyForeverWeaponFashionGiftConverseText", timeText) or XUiHelper.GetText("OwnLimitBuyForeverWeaponFashionConverseText", timeText)
                    --自己拥有的武器涂装是永久的去买限时的
                    elseif not ownRewardIsLimitTime and rewardIsLimitTime then      
                        tipContent["content"] = XUiHelper.GetText("OwnForeverBuyLimitWeaponFashionConverseText")
                    --自己拥有的武器涂装是永久的去买永久的
                    elseif not ownRewardIsLimitTime and not rewardIsLimitTime then  
                        tipContent["content"] = XUiHelper.GetText("OwnForeverBuyForeverWeaponFashionConverseText")
                    end
                    table.insert(self.__OpenBuyTipsList, tipContent)
                else
                    --自己拥有的武器涂装是限时的去买限时的
                    self.__IsCheckOpenAddTimeTips = true
                end
            end
        elseif XRewardManager.IsRewardFashion(v.RewardType, v.TemplateId) 
            and XRewardManager.CheckRewardOwn(v.RewardType, v.TemplateId) then
            local tipContent = {}
            tipContent["title"] = XUiHelper.GetText("PurchaseFashionRepeatTipsTitle")
            tipContent["content"] = XUiHelper.GetText("PurchaseFashionRepeatTipsContent")
            table.insert(self.__OpenBuyTipsList, tipContent)
        end
    end
    if #self.__OpenBuyTipsList > 0 then
        self:__OpenBuyTips(successCb)
        return
    end
    if successCb then successCb() end
end

function XPurchasePackage:__OpenBuyTips(cb)
    local tipContent = table.remove(self.__OpenBuyTipsList, 1)
    local sureCallback = function ()
        if #self.__OpenBuyTipsList > 0 then
            self:__OpenBuyTips()
        else
            if cb then cb() end
        end
    end
    local closeCallback = function()
        self.__OpenBuyTipsList = {}
    end
    XUiManager.DialogTip(tipContent["title"], tipContent["content"], XUiManager.DialogType.Normal, closeCallback, sureCallback)
end

function XPurchasePackage:HandleBuyFinished(rewardList)
    if self.__IsCheckOpenAddTimeTips then
        if not rewardList then return end
        if self.__TipsTemplateContentList == nil then self.__TipsTemplateContentList = {} end
        local descStr
        for _, v in pairs(rewardList) do
            if XRewardManager.IsRewardWeaponFashion(v.RewardType, v.TemplateId)then
                descStr = self:GetRewardWeaponFashionDescStr(v.TemplateId)
                if descStr then
                    table.insert(self.__TipsTemplateContentList, descStr)
                end
            end
        end
        self:__OpenAddTimeTips()
        self.__IsCheckOpenAddTimeTips = nil
    end
end

function XPurchasePackage:__OpenAddTimeTips()
    if #self.__TipsTemplateContentList > 0 then
        local content = table.remove(self.__TipsTemplateContentList)
        XUiManager.TipMsg(content, nil, function() self:__OpenAddTimeTips() end)
    end
end

-- v1.28-采购优化-检测是否礼包内是否第一件物品为时装
function XPurchasePackage:CheckIsSingleFashion()
    --部分礼包配表没有RewardId，只有MailId
    if self.Data.RewardGoodsList == nil then
        return false
    end

    local good = self.Data.RewardGoodsList[1]
    if good.RewardType == XRewardManager.XRewardType.Fashion then
        return good.TemplateId, false
    elseif good.RewardType == XRewardManager.XRewardType.WeaponFashion then
        return good.TemplateId, true
    elseif XDataCenter.ItemManager.IsWeaponFashion(good.TemplateId) then
        local templateId = XDataCenter.ItemManager.GetWeaponFashionId(good.TemplateId)
        return templateId, true
    end
    return false
end

function XPurchasePackage:GetUiFashionDetailBuyData(buyFinishedFunc, notEnoughCb)
    local disCountValue = XDataCenter.PurchaseManager.GetLBDiscountValue(self.Data)    
    local buyData = {}
    -- 全部拥有才算购买过该礼包
    buyData.IsHave = XRewardManager.CheckRewardGoodsListIsOwnWithAll(self.Data.RewardGoodsList)
    buyData.ItemIcon = XDataCenter.ItemManager.GetItemIcon(self.Data.ConsumeId)
    buyData.ItemCount = math.modf(self.Data.ConvertSwitch * disCountValue)
    buyData.BuyCallBack = function() 
        if self:CheckCanBuy(nil, nil, notEnoughCb) then
            if self.Data and self.Data.Id then
                local mergeBuyFinishedCb = function(rewardList)
                    self:HandleBuyFinished(rewardList)
                    if buyFinishedFunc then
                        buyFinishedFunc()
                    end
                end
                XDataCenter.PurchaseManager.PurchaseRequest(self.Data.Id, mergeBuyFinishedCb, 1, nil, self:GetUiTypes())
            end
        end
    end
    buyData.FashionLabel = self.Data.FashionLabel
    -- v1.28-采购优化-赠品队列过滤涂装
    local graftRewartdIds = {}
    for index, item in ipairs(self.Data.RewardGoodsList) do
        if index ~= 1 then
            table.insert(graftRewartdIds, item)
        end
    end
    buyData.GiftRewardId = #graftRewartdIds > 0 and graftRewartdIds or nil
    return buyData
end

--######################## 将旧Ui耦合的逻辑直接迁移到数据层中处理 END ########################

function XPurchasePackage:GetUiType()
    return self.Data.UiType
end

function XPurchasePackage:GetUiTypes()
    local result = {}
    local config = XPurchaseConfigs.GetUiTypeConfigByType(self:GetUiType())
    local configs = XPurchaseConfigs.GetUiTypesByTab(config.GroupType)
    for _, value in pairs(configs) do
        table.insert(result, value.UiType)
    end
    return result
end

function XPurchasePackage:GetIsSellOut()
    -- 逻辑直接迁移历史Ui逻辑
    local nowTime = XTime.GetServerNowTimestamp()
    if self.Data.TimeToInvalid and self.Data.TimeToInvalid > 0 then
        local remainTime = self.Data.TimeToInvalid - nowTime
        if remainTime <= 0 then
            return true
        end
    end
    if self.Data.BuyLimitTimes and self.Data.BuyLimitTimes > 0 
        and self.Data.BuyTimes == self.Data.BuyLimitTimes then
        return true
    end
    if self.Data.TimeToUnShelve > 0 then
        if nowTime >= self.Data.TimeToUnShelve then
            return true
        end
    end
    return false
end

-- v1.31检查礼包奖励是否全部拥有
function XPurchasePackage:GetIsHave()

    --部分礼包配表没有RewardId，只有MailId
    if self.Data.RewardGoodsList == nil then
        return false
    end

    -- 全部奖励都已拥有
    local isHave = XRewardManager.CheckRewardGoodsListIsOwnWithAll(self.Data.RewardGoodsList)
    if isHave then 
        return true
    end

    -- 非折价礼包：拥有涂装，仍为原价/0元。有涂装视为拥有此礼包
    local isHaveFashion = XRewardManager.CheckRewardGoodsListIsOwnWithAll({self.Data.RewardGoodsList[1]})
    if isHaveFashion and (self.Data.ConvertSwitch == self.Data.ConsumeCount or self.Data.ConvertSwitch == 0) then 
        return true
    end

    return false
end

return XPurchasePackage