local CSXTextManagerGetText = CS.XTextManager.GetText
local TableInsert = table.insert
local Next = _G.next
local XUiDrawPurchaseLB = XLuaUiManager.Register(XLuaUi, "UiDrawPurchaseLB")
local XUiPurchaseLBListItem = require("XUi/XUiPurchase/XUiPurchaseLBListItem")
local CurrentSchedule = nil

function XUiDrawPurchaseLB:OnAwake()
    self:AutoRegisterListener()
    self:InitDynamicTable()
end

function XUiDrawPurchaseLB:OnStart(parent)
    self.Parent = parent
    self.CheckBuyFun = function(count, disCountCouponIndex) return self:CheckBuy(count, disCountCouponIndex) end
    -- self.BeforeBuyReqFun = function(successCb) self:CheckIsOpenBuyTips(successCb) end
    self.UpdateCb = function(rewardList) self:OnUpdate(rewardList) end
end

function XUiDrawPurchaseLB:OnEnable()
    self.DrawInfo = self.Parent.DrawInfo
    self.TimeFuns = {}
    self:OnRefresh()
    self:StartLBTimer()
    XEventManager.AddEventListener(XEventId.EVENT_PURCAHSE_BUYUSERIYUAN, self.OnUpdate, self) -- 海外修改
end

function XUiDrawPurchaseLB:OnDisable()
    self:DestroyTimer()
    XEventManager.RemoveEventListener(XEventId.EVENT_PURCAHSE_BUYUSERIYUAN, self.OnUpdate, self) -- 海外修改
end

function XUiDrawPurchaseLB:OnRefresh()
    local drawPurchaseList = XDataCenter.DrawManager.GetDrawPurchase(self.DrawInfo.Id)
    self.PurchaseDatas = self:OnSortFun(drawPurchaseList)
    if not self.PurchaseDatas or not next(self.PurchaseDatas) then
        self.PanelLb.gameObject:SetActiveEx(false)
        self.PanelSoldOut.gameObject:SetActiveEx(true)
    else
        self.PanelLb.gameObject:SetActiveEx(true)
        self.PanelSoldOut.gameObject:SetActiveEx(false)
    end

    -- 少于3个插入空表
    local dataCount = #self.PurchaseDatas
    if dataCount < 3 then
        for i = 1, 3 - dataCount do
            TableInsert(self.PurchaseDatas, {})
        end
    end

    self.DynamicTable:SetDataSource(self.PurchaseDatas)
    self.DynamicTable:ReloadDataASync()
end

function XUiDrawPurchaseLB:AutoRegisterListener()
    self.BtnMask.CallBack = function () self:Close() end
    self.BtnClose.CallBack = function () self:Close() end
end

function XUiDrawPurchaseLB:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelLb)
    self.DynamicTable:SetProxy(XUiPurchaseLBListItem)
    self.DynamicTable:SetDelegate(self)
end

function XUiDrawPurchaseLB:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self, self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.PurchaseDatas[index]
        grid:OnRefresh(data)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local data = self.PurchaseDatas[index]
        if not data or not next(data) then
            return
        end

        XDataCenter.PurchaseManager.RemoveNotInTimeDiscountCoupon(data) -- 移除未到时间的打折券
        self.CurData = data
        XLuaUiManager.Open("UiPurchaseBuyTips", data, self.CheckBuyFun, self.UpdateCb, nil, XPurchaseConfigs.GetLBUiTypesList())
        -- CS.XAudioManager.PlaySound(1011)
    end
end

function XUiDrawPurchaseLB:CheckBuy(count, disCountCouponIndex)
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
            XLuaUiManager.Open("UiPurchase", XPurchaseConfigs.TabsConfig.HK, false)
        elseif self.CurData.ConsumeId == XDataCenter.ItemManager.ItemId.HongKa then
            XLuaUiManager.Open("UiPurchase", XPurchaseConfigs.TabsConfig.Pay, false)
        end
        return false
    end
    
    return true
end

function XUiDrawPurchaseLB:OnUpdate(rewardList)
    --self.Parent:UpdateItemCount()
    self:OnRefresh()
end

function XUiDrawPurchaseLB:OnSortFun(data) -- 排序方法来自 XUiPurchaseLB
    self.SellOutList = {}--买完了
    self.SellingList = {}--在上架中
    self.SellOffList = {}--下架了
    self.SellWaitList = {}--待上架中
    local listData = {}

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
        table.sort(self.SellingList, XUiDrawPurchaseLB.SortByPriority)
        for _,v in pairs(self.SellingList) do
            table.insert(listData, v)
        end
    end
    --待上架中
    if Next(self.SellWaitList) then
        table.sort(self.SellWaitList, XUiDrawPurchaseLB.SortByPriority)
        for _,v in pairs(self.SellWaitList) do
            table.insert(listData, v)
        end
    end
    --买完了
    if Next(self.SellOutList) then
        table.sort(self.SellOutList, XUiDrawPurchaseLB.SortByPriority)
        for _,v in pairs(self.SellOutList) do
            table.insert(listData, v)
        end
    end
    --下架了
    if Next(self.SellOffList) then
        table.sort(self.SellOffList, XUiDrawPurchaseLB.SortByPriority)
        for _,v in pairs(self.SellOffList) do
            table.insert(listData, v)
        end
    end

    return listData
end

function XUiDrawPurchaseLB.SortByPriority(a,b)
    return a.Priority < b.Priority
end

-- 计时器相关
function XUiDrawPurchaseLB:StartLBTimer()
    if self.IsStart then
        return
    end

    self.IsStart = true
    CurrentSchedule = XScheduleManager.ScheduleForever(function() self:UpdateLBTimer()end, 1000)
end

function XUiDrawPurchaseLB:UpdateLBTimer()
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

function XUiDrawPurchaseLB:RemoveTimerFun(id)
    if id and self.TimeFuns[id] then
        self.TimeFuns[id] = nil
    end
end

function XUiDrawPurchaseLB:RecoverTimerFun(id)
    if self.TimeFuns[id] then
        self.TimeFuns[id](true)
    end
end

function XUiDrawPurchaseLB:RegisterTimerFun(id, fun)
    self.TimeFuns[id] = fun
end

function XUiDrawPurchaseLB:DestroyTimer()
    if CurrentSchedule then
        self.IsStart = false
        XScheduleManager.UnSchedule(CurrentSchedule)
        CurrentSchedule = nil
    end
end