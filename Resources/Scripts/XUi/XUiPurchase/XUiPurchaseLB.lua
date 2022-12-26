local XUiPurchaseLB = XClass(nil, "XUiPurchaseLB")
local Next = _G.next
local CSXTextManagerGetText = CS.XTextManager.GetText
local XUiPurchaseLBListItem = require("XUi/XUiPurchase/XUiPurchaseLBListItem")
local CurrentSchedule = nil

function XUiPurchaseLB:Ctor(ui,uiRoot, callBack)
    self.CurState = false
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.CallBack = callBack
    self.UiRoot = uiRoot
    self.TimeFuns = {}
    self.TimeSaveFuns = {}
    XTool.InitUiObject(self)
    self.ListData = {}
    self.IsCheckOpenAddTimeTips = false
    self.TipsTemplateContentList = {}
    self.OpenBuyTipsList = {}
    self:Init()
end

-- 先分类后排序
function XUiPurchaseLB:OnSortFun(data)
    print("XUiPurchaseLB:OnSortFun");
    self.SellOutList = {}--买完了
    self.SellingList = {}--在上架中
    self.SellOffList = {}--下架了
    self.SellWaitList = {}--待上架中
    self.ListData = {}

    local nowTime = XTime.GetServerNowTimestamp()
    for _,v in pairs(data)do
        if v and not v.IsSelloutHide then
            if v.TimeToUnShelve > 0 and v.TimeToUnShelve <= nowTime then--下架了
                table.insert(self.SellOffList,v)
            elseif v.TimeToShelve > 0 and v.TimeToShelve > nowTime then--待上架中
                table.insert(self.SellWaitList,v)
            elseif v.BuyTimes > 0 and v.BuyLimitTimes > 0 and v.BuyTimes >= v.BuyLimitTimes then--买完了
                table.insert(self.SellOutList,v)
            else                                                       --在上架中,还能买。
                table.insert(self.SellingList,v)
            end
        end
    end

    --在上架中,还能买。
    if Next(self.SellingList) then
        table.sort(self.SellingList, XUiPurchaseLB.SortByPriority)
        for _,v in pairs(self.SellingList) do
            table.insert(self.ListData, v)
        end
    end

    --待上架中
    if Next(self.SellWaitList) then
        table.sort(self.SellWaitList, XUiPurchaseLB.SortByPriority)
        for _,v in pairs(self.SellWaitList) do
            table.insert(self.ListData, v)
        end
    end

    --买完了
    if Next(self.SellOutList) then
        table.sort(self.SellOutList, XUiPurchaseLB.SortByPriority)
        for _,v in pairs(self.SellOutList) do
            table.insert(self.ListData, v)
        end
    end

    --下架了
    if Next(self.SellOffList) then
        table.sort(self.SellOffList, XUiPurchaseLB.SortByPriority)
        for _,v in pairs(self.SellOffList) do
            table.insert(self.ListData, v)
        end
    end

end

function XUiPurchaseLB.SortByPriority(a,b)
    return a.Priority < b.Priority
end

function XUiPurchaseLB:StartLBTimer()
    if self.IsStart then
        return
    end

    self.IsStart = true
    CurrentSchedule = XScheduleManager.ScheduleForever(function() self:UpdateLBTimer()end, 1000)
end

function XUiPurchaseLB:UpdateLBTimer()
    if Next(self.TimeFuns) then
        for _,timerFun in pairs(self.TimeFuns)do
            if timerFun then
                timerFun()
            end
        end
        return
    end
    self:DestroyTimer()
end

function XUiPurchaseLB:RemoveTimerFun(id)
    self.TimeFuns[id] = nil
end

function XUiPurchaseLB:RecoverTimerFun(id)
    self.TimeFuns[id] = self.TimeSaveFuns[id]
    if self.TimeFuns[id] then
        self.TimeFuns[id](true)
    end
    self.TimeSaveFuns[id] = nil
end

function XUiPurchaseLB:RegisterTimerFun(id,fun,isSave)
    if not isSave then
        self.TimeFuns[id] = fun
        return
     end

    self.TimeSaveFuns[id] = self.TimeFuns[id]
    self.TimeFuns[id] = fun

end

-- 更新数据
function XUiPurchaseLB:OnRefresh(uiType)
    local data = XDataCenter.PurchaseManager.GetDatasByUiType(uiType)
    XLog.Debug(data);
    if not data then
        return
    end

    self.CurUiType = uiType
    self.GameObject:SetActive(true)
    if Next(data) ~= nil then
        self:OnSortFun(data)
    end
    self.TimeFuns = {}
    self.TimeSaveFuns = {}
    self.DynamicTable:SetDataSource(self.ListData)
    self.DynamicTable:ReloadDataASync(1)
    self:StartLBTimer()
end

function XUiPurchaseLB:OnUpdate(rewardList)
    if self.IsCheckOpenAddTimeTips then
        self:CheckAddTimeTips(rewardList)
        self.IsCheckOpenAddTimeTips = false
    end
    if self.CurUiType then
        self:OnRefresh(self.CurUiType)
    end
end

function XUiPurchaseLB:HidePanel()
    self:DestroyTimer()
    XEventManager.RemoveEventListener(XEventId.EVENT_PURCAHSE_BUYUSERIYUAN, self.OnUpdate, self)
    self.GameObject:SetActive(false)
end

function XUiPurchaseLB:ShowPanel()
    self.GameObject:SetActive(true)
    XEventManager.AddEventListener(XEventId.EVENT_PURCAHSE_BUYUSERIYUAN, self.OnUpdate, self)
end

function XUiPurchaseLB:DestroyTimer()
    if CurrentSchedule then
        self.IsStart = false
        XScheduleManager.UnSchedule(CurrentSchedule)
        CurrentSchedule = nil
    end
end

function XUiPurchaseLB:Init()
    self:InitList()
    self.CheckBuyFun = function(count, disCountCouponIndex) return self:CheckBuy(count, disCountCouponIndex) end
    self.BeforeBuyReqFun = function(successCb) self:CheckIsOpenBuyTips(successCb) end
    self.UpdateCb = function(rewardList) self:OnUpdate(rewardList) end
end

function XUiPurchaseLB:InitList()
    self.DynamicTable = XDynamicTableNormal.New(self.Transform)
    self.DynamicTable:SetProxy(XUiPurchaseLBListItem)
    self.DynamicTable:SetDelegate(self)
end

-- [监听动态列表事件]
function XUiPurchaseLB:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.UiRoot,self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.ListData[index]
        grid:OnRefresh(data)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local data = self.ListData[index]
        if not data then
            return
        end

        XDataCenter.PurchaseManager.RemoveNotInTimeDiscountCoupon(data) -- 移除未到时间的打折券
        self.CurData = data
        XLuaUiManager.Open("UiPurchaseBuyTips", data, self.CheckBuyFun, self.UpdateCb, self.BeforeBuyReqFun, XPurchaseConfigs.GetLBUiTypesList(),self.CurUiType)
        CS.XAudioManager.PlaySound(1011)
    end
end



function XUiPurchaseLB:CheckBuy(count, disCountCouponIndex)
    count = count or 1
    disCountCouponIndex = disCountCouponIndex or 0

    if not XDataCenter.PayManager.CheckCanBuy(self.CurData.Id) then
        return false
    end

    if self.CurData.BuyLimitTimes > 0 and self.CurData.BuyTimes == self.CurData.BuyLimitTimes then --卖完了，不管。
        XUiManager.TipText("PurchaseLiSellOut")
        return false
    end

    if self.CurData.TimeToShelve > 0 and self.CurData.TimeToShelve > XTime.GetServerNowTimestamp() then --没有上架
        XUiManager.TipText("PurchaseBuyNotSet")
        return false
    end

    if self.CurData.TimeToUnShelve > 0 and self.CurData.TimeToUnShelve < XTime.GetServerNowTimestamp() then --下架了
        XUiManager.TipText("PurchaseSettOff")
        return false
    end

    if self.CurData.TimeToInvalid > 0 and self.CurData.TimeToInvalid < XTime.GetServerNowTimestamp() then --失效了
        XUiManager.TipText("PurchaseSettOff")
        return false
    end

    if self.CurData.ConsumeCount > 0 and self.CurData.ConvertSwitch <= 0 then -- 礼包内容全部拥有
        XUiManager.TipText("PurchaseRewardAllHaveErrorTips")
        return false
    end

    local consumeCount = self.CurData.ConsumeCount
    if disCountCouponIndex and disCountCouponIndex ~= 0 then
        local disCountValue = XDataCenter.PurchaseManager.GetLBCouponDiscountValue(self.CurData, disCountCouponIndex)
        consumeCount = math.floor(disCountValue * consumeCount)
    else
        if self.CurData.ConvertSwitch and consumeCount > self.CurData.ConvertSwitch then -- 已经被服务器计算了抵扣和折扣后的钱
            consumeCount = self.CurData.ConvertSwitch
        end

        if XPurchaseConfigs.GetTagType(self.CurData.Tag) == XPurchaseConfigs.PurchaseTagType.Discount then -- 计算打折后的钱(普通打折或者选择了打折券)
            local disCountValue = XDataCenter.PurchaseManager.GetLBDiscountValue(self.CurData)
            consumeCount = math.floor(disCountValue * consumeCount)
        end
    end
    
    consumeCount = count * consumeCount -- 全部数量的总价
    if consumeCount > 0 and consumeCount > XDataCenter.ItemManager.GetCount(self.CurData.ConsumeId) then --钱不够
        local name = XDataCenter.ItemManager.GetItemName(self.CurData.ConsumeId) or ""
        local tips = CSXTextManagerGetText("PurchaseBuyKaCountTips", name)
        XUiManager.TipMsg(tips,XUiManager.UiTipType.Wrong)
        if self.CurData.ConsumeId == XDataCenter.ItemManager.ItemId.PaidGem then
            self.CallBack(XPurchaseConfigs.TabsConfig.HK)
        elseif self.CurData.ConsumeId == XDataCenter.ItemManager.ItemId.HongKa then
            self.CallBack(XPurchaseConfigs.TabsConfig.Pay)
        end
        return false
    end

    return true
end

function XUiPurchaseLB:CheckIsOpenBuyTips(successCb)
    if self.CurData.ConvertSwitch and self.CurData.ConsumeCount > self.CurData.ConvertSwitch then -- 礼包被计算拥有物品折扣价后，拥有物品不会下发，所以无需二次提示转化碎片
        if successCb then successCb() end
        return
    end

    local rewardGoodsList = self.CurData.RewardGoodsList
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
                    tipContent["title"] = CSXTextManagerGetText("WeaponFashionConverseTitle")
                    if ownRewardIsLimitTime and not rewardIsLimitTime then          --自己拥有的武器涂装是限时的去买永久的
                        local timeText = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
                        tipContent["content"] = #rewardGoodsList > 1 and CSXTextManagerGetText("OwnLimitBuyForeverWeaponFashionGiftConverseText", timeText) or CSXTextManagerGetText("OwnLimitBuyForeverWeaponFashionConverseText", timeText)
                    elseif not ownRewardIsLimitTime and rewardIsLimitTime then      --自己拥有的武器涂装是永久的去买限时的
                        tipContent["content"] = CSXTextManagerGetText("OwnForeverBuyLimitWeaponFashionConverseText")
                    elseif not ownRewardIsLimitTime and not rewardIsLimitTime then  --自己拥有的武器涂装是永久的去买永久的
                        tipContent["content"] = CSXTextManagerGetText("OwnForeverBuyForeverWeaponFashionConverseText")
                    end
                    table.insert(self.OpenBuyTipsList, tipContent)
                else
                    --自己拥有的武器涂装是限时的去买限时的
                    self.IsCheckOpenAddTimeTips = true
                end
            end
        elseif XRewardManager.IsRewardFashion(v.RewardType, v.TemplateId) and XRewardManager.CheckRewardOwn(v.RewardType, v.TemplateId) then
            local tipContent = {}
            tipContent["title"] = CSXTextManagerGetText("PurchaseFashionRepeatTipsTitle")
            tipContent["content"] = CSXTextManagerGetText("PurchaseFashionRepeatTipsContent")
            table.insert(self.OpenBuyTipsList, tipContent)
        end
    end

    if #self.OpenBuyTipsList > 0 then
        self:OpenBuyTips(successCb)
        return
    end

    if successCb then successCb() end
end

function XUiPurchaseLB:OpenBuyTips(successCb)
    if #self.OpenBuyTipsList > 0 then
        local tipContent = table.remove(self.OpenBuyTipsList, 1)
        local sureCallback = function ()
            if #self.OpenBuyTipsList > 0 then
                self:OpenBuyTips()
            else
                if successCb then successCb() end
            end
        end
        local closeCallback = function()
            self.OpenBuyTipsList = {}
        end
        XUiManager.DialogTip(tipContent["title"], tipContent["content"], XUiManager.DialogType.Normal, closeCallback, sureCallback)
    end
end

function XUiPurchaseLB:CheckAddTimeTips(rewardList)
    if not rewardList then return end
    local descStr
    for _, v in pairs(rewardList) do
        if XRewardManager.IsRewardWeaponFashion(v.RewardType, v.TemplateId)then
            descStr = self:GetRewardWeaponFashionDescStr(v.TemplateId)
            if descStr then
                table.insert(self.TipsTemplateContentList, descStr)
            end
        end
    end
    self:OpenAddTimeTips()
end

function XUiPurchaseLB:GetRewardWeaponFashionDescStr(templateId)
    local weaponFashionId = XDataCenter.ItemManager.GetWeaponFashionId(templateId)
    local weaponFashion = XDataCenter.WeaponFashionManager.GetWeaponFashion(weaponFashionId)
    local time = XDataCenter.ItemManager.GetWeaponFashionAddTime(templateId)
    if weaponFashion and weaponFashion:IsTimeLimit() and time then
        --此时提示叠加时长信息
        local addTime = XUiHelper.GetTime(time, XUiHelper.TimeFormatType.DEFAULT)
        local weaponFashionName = XDataCenter.WeaponFashionManager.GetWeaponFashionName(weaponFashionId)
        return CSXTextManagerGetText("WeaponFashionLimitGetAlreadyHaveLimit", weaponFashionName, addTime)
    end
end

function XUiPurchaseLB:OpenAddTimeTips()
    if #self.TipsTemplateContentList > 0 then
        local content = table.remove(self.TipsTemplateContentList)
        XUiManager.TipMsg(content, nil, function() self:OpenAddTimeTips() end)
    end
end

return XUiPurchaseLB