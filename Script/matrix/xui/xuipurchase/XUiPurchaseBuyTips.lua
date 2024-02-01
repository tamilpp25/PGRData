local TextManager = CS.XTextManager
local DropdownOptionData = CS.UnityEngine.UI.Dropdown.OptionData
local XUiPurchaseLBTipsListItem = require("XUi/XUiPurchase/XUiPurchaseLBTipsListItem")
local XUiPurchaseSignTip = require("XUi/XUiPurchase/XUiPurchaseSignTip/XUiPurchaseSignTip")
local XUiBatchPanel = require("XUi/XUiPurchase/XUiBatchPanel")
local RestTypeConfig
local LBGetTypeConfig
local Next = _G.next
local UpdateTimerTypeEnum = {
    SettOff = 1,
    SettOn = 2
}
local CurrentSchedule = nil
-- v1.28 采购优化-购买CD
local PurchaseBuyPayCD = CS.XGame.ClientConfig:GetInt("PurchaseBuyPayCD") / 1000

local XUiPurchaseBuyTips = XLuaUiManager.Register(XLuaUi, "UiPurchaseBuyTips")

function XUiPurchaseBuyTips:OnAwake()
    self:Init()
end

-- 更新数据
function XUiPurchaseBuyTips:OnStart(data, checkBuyFun, updateCb, beforeBuyReqFun, uiTypeList)
    if not data then
        return
    end

    self.Data = data
    self.CheckBuyFun = checkBuyFun
    self.UpdateCb = updateCb
    self.BeforeBuyReqFun = beforeBuyReqFun
    self.UiTypeList = uiTypeList
    CS.XAudioManager.PlaySound(1100)
    
    RestTypeConfig = XPurchaseConfigs.RestTypeConfig
    LBGetTypeConfig = XPurchaseConfigs.LBGetTypeConfig
    self.CurState = false
    self.TimerFun = {} -- 计时器方法表
    self.TitleGoPool = {}
    self.ItemPool = {}
    self.PurchaseSignTipDic = {}    -- 签到礼包的奖励预览脚本实例，key:PrefabPath，value:{ PurchaseSignTip, Resource }
    self.OpenBuyTipsList = {}

    -- 检查是否是签到礼包
    if self:CheckSignLBAndOpen() then
        return
    else
        self.PanelSignGiftPack.gameObject:SetActiveEx(false)
    end

    self.PanelCommon.gameObject:SetActiveEx(true)
    self:AutoRegisterListener()

    self.TxtName.text = data.Name
    local path = XPurchaseConfigs.GetIconPathByIconName(data.Icon)
    if path and path.AssetPath then
        self.RawImageIcon:SetRawImage(path.AssetPath)
    end

    -- 下列方法存在公用变量，注意调用顺序
    self:CheckLBIsUseMail()
    -- self:SetList()
    self:InitAndRegisterTimer()
    self:InitAndCheckNormalDiscount()
    self:CheckLBRewardIsHave()
    self:CheckLBCouponDiscount()
    self:InitAndCheckMultiply()
    self:SetBuyDes()

    self:StartTimer()
end

function XUiPurchaseBuyTips:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_PURCHASE_QUICK_BUY_SKIP, self.Close, self)
    -- SetList 放在Enable中跳出充值界面返回显示的时候重新刷新奖励列表
    self:SetList()
end

function XUiPurchaseBuyTips:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_PURCHASE_QUICK_BUY_SKIP, self.Close, self)
end

function XUiPurchaseBuyTips:Init()
    self.AssetPanel = XUiPanelAsset.New(self,self.PanelAssetPay,XDataCenter.ItemManager.ItemId.FreeGem,XDataCenter.ItemManager.ItemId.HongKa)
end

function XUiPurchaseBuyTips:InitBatchPanel()
    local batchPanelParam = {
        MaxCount = self.MaxBuyCount,
        MinCount = 1,
        BtnAddCallBack = function() self:OnBtnAddClick() end,
        BtnReduceCallBack = function() self:OnBtnReduceClick() end,
        BtnAddLongCallBack = function() self:BtnAddLongClick() end,
        BtnReduceLongCallBack = function() self:BtnReduceLongClick() end,
        BtnMaxCallBack = function() self:OnBtnMaxClick() end,
        SelectTextChangeCallBack = function(count) self:OnSelectTextChange(count) end,
        SelectTextInputEndCallBack = function(count) self:OnSelectTextInputEnd(count) end,
    }
    self.BatchPanel = XUiBatchPanel.New(self, self.PanelBatch, batchPanelParam)
end

function XUiPurchaseBuyTips:OnCouponDropDownValueChanged(index)
    if index == 0 then
        self.CurDiscountCouponIndex = index
        self:RefreshDiscount(index)
    else
        local discountInfo = self.CurData.DiscountCouponInfos[index]
        local couponItemId = discountInfo.ItemId
        local couponName = XDataCenter.ItemManager.GetItemName(couponItemId)
        if XPurchaseConfigs.GetTagType(self.CurData.Tag) == XPurchaseConfigs.PurchaseTagType.Discount then -- 配置了打折需要进行比较
            local normalDisCountValue = XDataCenter.PurchaseManager.GetLBDiscountValue(self.CurData)
            local normalDiscountConsume = math.floor(normalDisCountValue * self.CurData.ConsumeCount)
            local couponDisCountValue = XDataCenter.PurchaseManager.GetLBCouponDiscountValue(self.CurData, index)
            local couponDisCountConsume = math.floor(couponDisCountValue * self.CurData.ConsumeCount)
            if couponDisCountConsume >= normalDiscountConsume then                                         -- 普通打折比选择的打折券便宜
                self.BuyUiTips.DrdSort.value = self.CurDiscountCouponIndex and self.CurDiscountCouponIndex or 0
                XUiManager.TipMsg(TextManager.GetText("NormalDiscountIsBetter")..couponName)
                return
            end
        end
        local needCount = discountInfo.ItemCount
        local count = XDataCenter.ItemManager.GetCount(couponItemId)
        if count < needCount then
            self.BuyUiTips.DrdSort.value = self.CurDiscountCouponIndex and self.CurDiscountCouponIndex or 0
            XUiManager.TipMsg(TextManager.GetText("CouponCountInsufficient", needCount))
            return
        end
        self.CurDiscountCouponIndex = index
        self:RefreshDiscount(index)
    end
end

function XUiPurchaseBuyTips:RefreshDiscount(discountItemIndex) -- 打折券刷新显示
    if discountItemIndex == 0 then
        if XPurchaseConfigs.GetTagType(self.Data.Tag) == XPurchaseConfigs.PurchaseTagType.Discount and self.NormalDisCountValue < 1 then -- 打折的
            self.RawImageConsume.gameObject:SetActiveEx(true)
            self.BtnBuy:SetName(math.modf(self.Data.ConsumeCount * self.NormalDisCountValue))
            local icon = XDataCenter.ItemManager.GetItemIcon(self.Data.ConsumeId)
            if icon then
                self.RawImageConsume:SetRawImage(icon)
            end
            self.TxtPrice.gameObject:SetActiveEx(true)
            self.TxtPrice.text = self.Data.ConsumeCount
        else
            self.BtnBuy:SetName(self.Data.ConsumeCount)
            self.TxtPrice.gameObject:SetActiveEx(false)
        end
    else
        local couponDisCountValue = XDataCenter.PurchaseManager.GetLBCouponDiscountValue(self.Data, discountItemIndex)
        self.RawImageConsume.gameObject:SetActiveEx(true)
        self.BtnBuy:SetName(math.modf(self.Data.ConsumeCount * couponDisCountValue))
        self.TxtPrice.gameObject:SetActiveEx(true)
        self.TxtPrice.text = self.Data.ConsumeCount
    end
end

-- 更新倒计时
function XUiPurchaseBuyTips:UpdateTimerFun()
    self:UpdateCouponRemainTime()

    self.RemainTime = self.RemainTime - 1

    if self.RemainTime <= 0 then
        self:RemoveTimerFun(self.Data.Id)
        if self.UpdateTimerType == UpdateTimerTypeEnum.SettOff then
            self.TXtTime.text = TextManager.GetText("PurchaseLBSettOff")
            return
        end

        self.TXtTime.text = ""
        return
    end

    if self.UpdateTimerType == UpdateTimerTypeEnum.SettOff then
        self.TXtTime.text = TextManager.GetText("PurchaseSetOffTime",XUiHelper.GetTime(self.RemainTime, XUiHelper.TimeFormatType.PURCHASELB))
        return
    end

    self.TXtTime.text = TextManager.GetText("PurchaseSetOnTime",XUiHelper.GetTime(self.RemainTime))
end

function XUiPurchaseBuyTips:UpdateCouponRemainTime()     -- 打折券倒计时更新
    if not self.IsHasCoupon then
        return
    end

    local nowTime = XTime.GetServerNowTimestamp()
    local remainTime = self.AllCouponMaxEndTime - nowTime
    if remainTime > 0 then
        self.TxtTimeCoupon.text = TextManager.GetText("CouponEndTime", XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.SHOP))
    else
        self.DrdSort.value = 0
        self.TxtTimeCoupon.text = ""
        self.DrdSort.gameObject:SetActiveEx(false)
        self.IsHasCoupon = false
    end
end

function XUiPurchaseBuyTips:OnBtnAddClick()
    self.CurrentBuyCount = self.CurrentBuyCount + 1
    if self.MaxBuyCount and self.CurrentBuyCount > self.MaxBuyCount then
        self.CurrentBuyCount = self.MaxBuyCount
    end
    self:RefreshBtnBuyPrice()
end

function XUiPurchaseBuyTips:OnBtnReduceClick()
    self.CurrentBuyCount = self.CurrentBuyCount - 1
    if self.CurrentBuyCount < 1 then self.CurrentBuyCount = 1 end
    self:RefreshBtnBuyPrice()
end

function XUiPurchaseBuyTips:BtnAddLongClick()
    self:OnBtnAddClick()
end

function XUiPurchaseBuyTips:BtnReduceLongClick()
    self:OnBtnReduceClick()
end

function XUiPurchaseBuyTips:OnBtnMaxClick()
    local consumeCount = self.Data.ConsumeCount
    consumeCount = math.floor(self.NormalDisCountValue * consumeCount)
    local canBuyCount = math.floor(XDataCenter.ItemManager.GetCount(self.Data.ConsumeId) / consumeCount)
    if canBuyCount <= 0 then canBuyCount = 1 end -- 最小可购买数量为1

    if not self.MaxBuyCount then
        if canBuyCount < self.BatchPanel.MaxCount then
            self.CurrentBuyCount = canBuyCount
        else
            self.CurrentBuyCount = self.BatchPanel.MaxCount
        end
    else
        if canBuyCount < self.MaxBuyCount then
            self.CurrentBuyCount = canBuyCount
        else
            self.CurrentBuyCount = self.MaxBuyCount
        end
    end
    self:RefreshBtnBuyPrice()
end

function XUiPurchaseBuyTips:OnSelectTextChange(count)
    self.CurrentBuyCount = count
    self:RefreshBtnBuyPrice()
end

function XUiPurchaseBuyTips:OnSelectTextInputEnd(count)
    self.CurrentBuyCount = count
    self:RefreshBtnBuyPrice()
end

function XUiPurchaseBuyTips:CloseTips()
    if (self.Data or {}).SignInId and self.Data.SignInId ~= 0 then
        -- 签到礼包展示预览关闭
        if (self.PurchaseSignTipDic[self.CurPrefabPath] or {}).PurchaseSignTip then
            self.PurchaseSignTipDic[self.CurPrefabPath].PurchaseSignTip:OnClose()
            self.CurPrefabPath = nil
        end
    else
        for _,v in pairs(self.ItemPool) do
            v.Transform:SetParent(self.PoolGo)
            v.GameObject:SetActiveEx(false)
        end

        for _,v in pairs(self.TitleGoPool) do
            v:SetParent(self.PoolGo)
            v.gameObject:SetActiveEx(false)
        end

        if self.UpdateTimerType then
            self:RemoveTimerFun(self.Data.Id)
        end
    end

    self:Close()
end

function XUiPurchaseBuyTips:SetList()
    -- 直接获得的道具
    self.ListDirData = {}
    self.ListDayData = {}
    local rewards0 = self.Data.RewardGoodsList or {}
    for _,v in pairs(rewards0) do
        v.LBGetType = LBGetTypeConfig.Direct
        table.insert(self.ListDirData,v)
    end
    -- v1.31-采购优化-涂装增加CG展示道具
    for _,v in pairs(rewards0) do
        if v.RewardType == XRewardManager.XRewardType.Fashion then
            local subItems = XDataCenter.FashionManager.GetFashionSubItems(v.TemplateId)
            if subItems then
                local isHave = XRewardManager.CheckRewardOwn(v.RewardType, v.TemplateId)
                for _, itemTemplateId in ipairs(subItems) do
                    table.insert(self.ListDirData, {TemplateId = itemTemplateId, Count = 1, LBGetType = LBGetTypeConfig.Direct, 
                    IsSubItem = true, IsHave = isHave})
                end
            end
        end
    end
    -- 每日获得的道具
    local rewards1 = self.Data.DailyRewardGoodsList or {}
    for _,v in pairs(rewards1) do
        v.LBGetType = LBGetTypeConfig.Day
        table.insert(self.ListDayData,v)
    end

    local index1 = 1
    local index2 = 1

    if Next(self.ListDirData) ~= nil then
        local obj = self:GetTitleGo(index1)
        index1 = index1 + 1
        obj.transform:Find("TxtTitle"):GetComponent("Text").text =  TextManager.GetText("PurchaseDirGet")
        for _,v in pairs(self.ListDirData)do
            local item = self:GetItemObj(index2)
            item:OnRefresh(v)
            index2 = index2 + 1

            -- v1.31-采购优化-涂装CG展示已拥有
            if (v.IsSubItem and v.IsHave) or (self.Data.ConsumeCount ~= 0 and self.Data.ConvertSwitch == 0) then
                item.GridItemUi.TxtHave.gameObject:SetActiveEx(true)
                item.GridItemUi.TxtCount.gameObject:SetActiveEx(false)
            end
        end
    end

    if Next(self.ListDayData) ~= nil then
        local obj = self:GetTitleGo(index1)
        obj.transform:Find("TxtTitle"):GetComponent("Text").text = self.Data.Desc or ""
        for _,v in pairs(self.ListDayData)do
            local item = self:GetItemObj(index2)
            item:OnRefresh(v)
            index2 = index2 + 1
        end
    end
end

function XUiPurchaseBuyTips:GetTitleGo(index)
    if self.TitleGoPool[index] then
        self.TitleGoPool[index].gameObject:SetActiveEx(true)
        self.TitleGoPool[index]:SetParent(self.PanelReward)
        return self.TitleGoPool[index]
    end

    local obj = CS.UnityEngine.Object.Instantiate(self.ImgTitle,self.PanelReward)
    obj.gameObject:SetActiveEx(true)
    obj:SetParent(self.PanelReward)
    table.insert(self.TitleGoPool, obj)
    return obj
end

function XUiPurchaseBuyTips:GetItemObj(index)
    if self.ItemPool[index] then
        self.ItemPool[index].GameObject:SetActiveEx(true)
        self.ItemPool[index].Transform:SetParent(self.PanelReward)
        return self.ItemPool[index]
    end  

    local itemObj = CS.UnityEngine.Object.Instantiate(self.PanelPropItem,self.PanelReward)
    itemObj.gameObject:SetActiveEx(true)
    itemObj:SetParent(self.PanelReward)
    local item = XUiPurchaseLBTipsListItem.New(itemObj)
    item:Init(self)
    table.insert(self.ItemPool, item)
    return item
end

function XUiPurchaseBuyTips:SetBuyDes()
    if self.Data.BuyLimitTimes and self.Data.BuyLimitTimes ~= 0 then
        local clientResetInfo = self.Data.ClientResetInfo or {}
        if Next(clientResetInfo) == nil then --不限时
            -- if self.Data.CanMultiply and self.MaxBuyCount and self.MaxBuyCount > 0 then
            if true and self.MaxBuyCount and self.MaxBuyCount > 0 then
                self.TxtLimitBuy.gameObject:SetActiveEx(true)
                self.TxtLimitBuy.text = TextManager.GetText("PurchaseCanBuyText", self.MaxBuyCount)
            else
                self.TxtLimitBuy.gameObject:SetActiveEx(false)
            end
        else -- 限时刷新
            local textKey = nil
            if clientResetInfo.ResetType == RestTypeConfig.Interval then
                self.TxtLimitBuy.gameObject:SetActiveEx(true)
                self.TxtLimitBuy.text = TextManager.GetText("PurchaseRestTypeInterval",clientResetInfo.DayCount,self.Data.BuyTimes,self.Data.BuyLimitTimes)
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
            self.TxtLimitBuy.text = TextManager.GetText(textKey,self.Data.BuyTimes,self.Data.BuyLimitTimes)
        end
    else
        self.TxtLimitBuy.gameObject:SetActiveEx(false)
    end
end

function XUiPurchaseBuyTips:RefreshBtnBuyPrice()
    local consumeCount = self.Data.ConsumeCount
    if self.Data.ConvertSwitch and self.Data.ConvertSwitch < consumeCount and self.Data.ConvertSwitch > 0 then
        consumeCount = self.Data.ConvertSwitch
    end
    local disCountConsume = math.floor(self.NormalDisCountValue * consumeCount)
    self.TxtPrice.text = consumeCount * self.CurrentBuyCount
    self.BtnBuy:SetName(disCountConsume * self.CurrentBuyCount)
end

function XUiPurchaseBuyTips:OnDestroy()
    self:DestroyTimer()

    if not self.PurchaseSignTipDic or not next(self.PurchaseSignTipDic) then
        return
    end

    for _, v in pairs(self.PurchaseSignTipDic) do
        if v.Resource then
            v.Resource:Release()
        end

        if v.PurchaseSignTip then
            v.PurchaseSignTip:OnClose()
            CS.UnityEngine.Object.Destroy(v.PurchaseSignTip.GameObject)
        end
    end
end

function XUiPurchaseBuyTips:RegisterTimerFun(id, fun)
    if id and fun then
        self.TimerFun[id] = fun
    end
end

function XUiPurchaseBuyTips:RemoveTimerFun(id)
    if self.TimerFun[id] then
        self.TimerFun[id] = nil
    end
end

function XUiPurchaseBuyTips:AutoRegisterListener()
    self.BtnBuy.CallBack = function() self:OnBtnBuyClick() end
    self.BtnBgClick.CallBack = function() self:CloseTips() end
    self.BtnCloseBg.CallBack = function() self:CloseTips() end

    self.DrdSort.onValueChanged:RemoveAllListeners()
    self.DrdSort.onValueChanged:AddListener(function(index) self:OnCouponDropDownValueChanged(index) end)
end

function XUiPurchaseBuyTips:CheckSignLBAndOpen()
    if self.Data.SignInId and self.Data.SignInId ~= 0 then
        -- 签到礼包展示预览
        self.PanelCommon.gameObject:SetActiveEx(false)
        self.PanelSignGiftPack.gameObject:SetActiveEx(true)

        self.BtnSignGiftPackBgClose.CallBack = function() self:CloseTips() end
        self.BtnSignGiftPackClose.CallBack = function() self:CloseTips() end
        for _, v in pairs(self.PurchaseSignTipDic) do
            v.PurchaseSignTip.GameObject:SetActiveEx(false)
        end

        self.CurPrefabPath = XSignInConfigs.GetSignPrefabPath(self.Data.SignInId)
        local purchaseSignTip = (self.PurchaseSignTipDic[self.CurPrefabPath] or {}).PurchaseSignTip
        if not purchaseSignTip then
            -- 生成对应prefab的实例
            local resource = CS.XResourceManager.Load(self.CurPrefabPath)
            local go = CS.UnityEngine.Object.Instantiate(resource.Asset)
            go.transform:SetParent(self.SignGiftPackNode, false)
            go.gameObject:SetLayerRecursively(self.SignGiftPackNode.gameObject.layer)
            purchaseSignTip = XUiPurchaseSignTip.New(go, self)

            local info = {}
            info.PurchaseSignTip = purchaseSignTip
            info.Resource = resource
            self.PurchaseSignTipDic[self.CurPrefabPath] = info
        end

        purchaseSignTip:Refresh(self.Data, function() self:OnBtnBuyClick() end)
        purchaseSignTip.GameObject:SetActiveEx(true)
        return true
    else
        return false
    end
end

function XUiPurchaseBuyTips:CheckLBIsUseMail()
    local isUseMail = self.Data.IsUseMail or false
    self.TxtContinue.gameObject:SetActiveEx(isUseMail)
end

function XUiPurchaseBuyTips:InitAndRegisterTimer()
    self.RemainTime = 0
    self.UpdateTimerType = nil
    self.NowTime = XTime.GetServerNowTimestamp()
    if self.Data.TimeToInvalid and self.Data.TimeToInvalid > 0 then
        self.RemainTime = self.Data.TimeToInvalid - self.NowTime
        self.UpdateTimerType = UpdateTimerTypeEnum.SettOff
        if self.RemainTime > 0 then--大于0，注册。
            self.TXtTime.gameObject:SetActiveEx(true)
            self:RegisterTimerFun(self.Data.Id, function() self:UpdateTimerFun() end)
            self.TXtTime.text = TextManager.GetText("PurchaseSetOffTime",XUiHelper.GetTime(self.RemainTime, XUiHelper.TimeFormatType.PURCHASELB))
        else
            self.TXtTime.gameObject:SetActiveEx(false)
            self:RemoveTimerFun(self.Data.Id)
        end
    else
        if (self.Data.TimeToShelve == nil or self.Data.TimeToShelve == 0) and (self.Data.TimeToUnShelve == nil or self.Data.TimeToUnShelve == 0) then
            self.TXtTime.gameObject:SetActiveEx(false)
        else
            self.TXtTime.gameObject:SetActiveEx(true)
            if self.Data.TimeToUnShelve > 0 then
                self.RemainTime = self.Data.TimeToUnShelve - self.NowTime
                self.UpdateTimerType = UpdateTimerTypeEnum.SettOff
                self.TXtTime.text = TextManager.GetText("PurchaseSetOffTime",XUiHelper.GetTime(self.RemainTime, XUiHelper.TimeFormatType.PURCHASELB))
            else
                self.RemainTime = self.Data.TimeToShelve-self.NowTime
                self.UpdateTimerType = UpdateTimerTypeEnum.SettOn
                self.TXtTime.text = TextManager.GetText("PurchaseSetOnTime",XUiHelper.GetTime(self.RemainTime))
            end
            if self.RemainTime > 0 then--大于0，注册。
                self:RegisterTimerFun(self.Data.Id, function() self:UpdateTimerFun() end)
            else
                self:RemoveTimerFun(self.Data.Id)
            end
        end
    end
end

function XUiPurchaseBuyTips:InitAndCheckNormalDiscount()
    self.NormalDisCountValue = XDataCenter.PurchaseManager.GetLBDiscountValue(self.Data)
    self.IsDisCount = XPurchaseConfigs.GetTagType(self.Data.Tag) == XPurchaseConfigs.PurchaseTagType.Discount and self.NormalDisCountValue < 1
    if self.Data.ConsumeCount == 0 then
        self.TxtPrice.gameObject:SetActiveEx(false)
        self.RawImageConsume.gameObject:SetActiveEx(false)
        self.BtnBuy:SetName(TextManager.GetText("PurchaseFreeText"))
    else
        self.RawImageConsume.gameObject:SetActiveEx(true)
        if self.IsDisCount then -- 打折的
            self.BtnBuy:SetName(math.modf(self.Data.ConsumeCount * self.NormalDisCountValue))
            self.TxtPrice.gameObject:SetActiveEx(true)
            self.TxtPrice.text = self.Data.ConsumeCount
        else
            self.TxtPrice.gameObject:SetActiveEx(false)
            self.BtnBuy:SetName(self.Data.ConsumeCount)
        end

        local icon = XDataCenter.ItemManager.GetItemIcon(self.Data.ConsumeId)
        if icon then
            self.RawImageConsume:SetRawImage(icon)
        end
    end
end

function XUiPurchaseBuyTips:CheckLBRewardIsHave()
    if self.Data.ConvertSwitch and self.Data.ConvertSwitch < self.Data.ConsumeCount then -- 礼包存在已拥有物品折扣
        local remainPrice = self.Data.ConvertSwitch
        if remainPrice < 0 then remainPrice = 0 end
        if remainPrice == 0 then -- 全部都拥有
            self.TxtHave.gameObject:SetActiveEx(true)
            self.TxtHave.text = TextManager.GetText("PurchaseLBOwnAll")
            self.BtnBuy:SetName(TextManager.GetText("PurchaseLBDontNeed"))
            self.BtnBuy:SetDisable(true, false)
            self.TxtPrice.gameObject:SetActiveEx(false)
        else -- 未拥有和拥有同时存在
            self.TxtHave.gameObject:SetActiveEx(true)
            self.TxtHave.text = TextManager.GetText("PurchaseLBHaveFashion")
            self.BtnBuy:SetDisable(false)
            if self.IsDisCount then
                remainPrice = math.modf(remainPrice * self.NormalDisCountValue)
            end
            self.BtnBuy:SetName(remainPrice)
            self.TxtPrice.gameObject:SetActiveEx(true)
            self.TxtPrice.text = self.Data.ConsumeCount
        end
    else
        -- 默认检测是否已拥有逻辑
        local isHave, isLimitTime = XRewardManager.CheckRewardGoodsListIsOwn(self.Data.RewardGoodsList)
        local isShowHave = isHave and not isLimitTime
        self.TxtHave.gameObject:SetActiveEx(isShowHave)
        if isShowHave then
            if #self.Data.RewardGoodsList > 1 then
                self.TxtHave.text = TextManager.GetText("PurchaseLBHaveFashion")
                self.BtnBuy:SetDisable(not isShowHave)
            else
                self.TxtHave.text = TextManager.GetText("PurchaseLBHaveFashionCantBuy")
                self.BtnBuy:SetDisable(isShowHave, not isShowHave)
            end
        else
            self.BtnBuy:SetDisable(false)
            if (self.Data.BuyLimitTimes > 0 and self.Data.BuyTimes == self.Data.BuyLimitTimes) or (self.Data.TimeToShelve > 0 and self.Data.TimeToShelve <= self.NowTime) or (self.Data.TimeToUnShelve > 0 and self.Data.TimeToUnShelve <= self.NowTime) then --卖完了，不管。
                self.TXtTime.text = ""
                if self.UpdateTimerType then
                    self:RemoveTimerFun(self.Data.Id)
                end
                self.TxtPrice.gameObject:SetActiveEx(false)
                self.BtnBuy:SetButtonState(XUiButtonState.Disable)
            else
                self.BtnBuy:SetButtonState(XUiButtonState.Normal)
            end
        end
    end
end

function XUiPurchaseBuyTips:CheckLBCouponDiscount()
    if self.Data.DiscountCouponInfos and #self.Data.DiscountCouponInfos > 0 then
        self.CurDiscountCouponIndex = 0
        self.DrdSort.gameObject:SetActiveEx(true)
        self.DrdSort:ClearOptions()
        local od = DropdownOptionData(TextManager.GetText("UnUsedCouponDiscount"))
        self.DrdSort.options:Add(od)
        self.DrdSort.captionText.text = TextManager.GetText("UnUsedCouponDiscount")
        self.AllCouponMaxEndTime = 0
        for _, optionData in ipairs(self.Data.DiscountCouponInfos) do
            local itemId = optionData.ItemId
            local itemName = XDataCenter.ItemManager.GetItemName(itemId)
            local count = XDataCenter.ItemManager.GetCount(itemId)
            local od = DropdownOptionData(itemName..TextManager.GetText("DiscountCouponRemain", count))
            self.DrdSort.options:Add(od)
            if optionData.EndTime > self.AllCouponMaxEndTime then
                self.AllCouponMaxEndTime = optionData.EndTime
            end
        end
        self.DrdSort.value = 0
        self.TxtTimeCoupon.text = TextManager.GetText("CouponEndTime", XUiHelper.GetTime(self.AllCouponMaxEndTime - self.NowTime, XUiHelper.TimeFormatType.SHOP))
        self.IsHasCoupon = true
    else
        self.DrdSort.gameObject:SetActiveEx(false)
        self.IsHasCoupon = false
    end
end

function XUiPurchaseBuyTips:InitAndCheckMultiply()
    self.CurrentBuyCount = 1 -- 每次打开把购买数量重置为1
    local isSellOut = self.Data.BuyLimitTimes and self.Data.BuyLimitTimes > 0 and self.Data.BuyTimes == self.Data.BuyLimitTimes
    if not isSellOut and self.Data.CanMultiply then -- 批量购买开关
        self.MaxBuyCount = XDataCenter.PurchaseManager.GetPurchaseMaxBuyCount(self.Data)
        self:InitBatchPanel()
        self.PanelBatch.gameObject:SetActiveEx(true)
        self:RefreshBtnBuyPrice()
    else
        self.MaxBuyCount = nil
        self.PanelBatch.gameObject:SetActiveEx(false)
    end
end

function XUiPurchaseBuyTips:OnBtnBuyClick()
    --v1.28-采购优化-礼包购买冷却
    local now = CS.UnityEngine.Time.realtimeSinceStartup
    if not self.LastBuyTime or (self.LastBuyTime and now - self.LastBuyTime > PurchaseBuyPayCD) then
        self.LastBuyTime = now
        if self.CheckBuyFun then -- 存在检测函数
            local result =  self.CheckBuyFun(self.CurrentBuyCount, self.CurDiscountCouponIndex)
            if result == 1 then
                if self.BeforeBuyReqFun then -- 购买前执行函数
                    self.BeforeBuyReqFun(function() self:BuyPurchaseRequest() end)
                    return
                end
                self:BuyPurchaseRequest()
            elseif result == 2 then
                XUiHelper.BuyInOtherPlatformHongka()
            elseif result ~= 3 then
                self:CloseTips()
            end
        else
            self:BuyPurchaseRequest()
        end
    end
end

function XUiPurchaseBuyTips:BuyPurchaseRequest()
    if self.Data and self.Data.Id then
        if not self.CurrentBuyCount or self.CurrentBuyCount == 0 then
            self.CurrentBuyCount = 1
        end
        local discountCouponId = nil
        if self.CurDiscountCouponIndex and self.CurDiscountCouponIndex ~= 0 then
            discountCouponId = self.CurData.DiscountCouponInfos[self.CurDiscountCouponIndex].Id
        end
        XDataCenter.PurchaseManager.PurchaseRequest(self.Data.Id, self.UpdateCb, self.CurrentBuyCount, discountCouponId, self.UiTypeList)
        self:CloseTips()
    end
end

function XUiPurchaseBuyTips:StartTimer()
    if self.IsTimerStart then
        return
    end

    if CurrentSchedule then
        XScheduleManager.UnSchedule(CurrentSchedule)
        CurrentSchedule = nil
    end

    CurrentSchedule = XScheduleManager.ScheduleForever(function() self:UpdateTimer() end, 1000)
    self.IsTimerStart = true
end

function XUiPurchaseBuyTips:DestroyTimer()
    if CurrentSchedule then
        XScheduleManager.UnSchedule(CurrentSchedule)
        CurrentSchedule = nil
        self.IsTimerStart = false
    end
end

function XUiPurchaseBuyTips:UpdateTimer()
    if self.TimerFun and next(self.TimerFun) then
        for _, fun in pairs(self.TimerFun) do
            fun()
        end
    end
end