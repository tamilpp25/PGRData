local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiGachaCanLiverPopupBuyAsset: XLuaUi
---@field _Control XGachaCanLiverControl
local XUiGachaCanLiverPopupBuyAsset = XLuaUiManager.Register(XLuaUi, 'UiGachaCanLiverPopupBuyAsset')
local BuyCountMax = 10
local BuyAmount = nil
local TargetCanBuyTimestamp = nil -- 用于cd购买
local CDTime = 1

--region 生命周期
function XUiGachaCanLiverPopupBuyAsset:OnAwake()
    self:InitButton()
end

function XUiGachaCanLiverPopupBuyAsset:OnStart(gachaCfg, itemData, targetData, gachaCount, successCb)
    self.GachaCfg = gachaCfg
    self.ItemData = itemData
    self.TargetData = targetData
    self.SuccessCb = successCb
    self.GachaBuyTicketRuleConfig = XGachaConfigs.GetGachaItemExchangeCfgById(self.GachaCfg.ExchangeId)
    self.BuyCount = gachaCount
    BuyCountMax = self.GachaBuyTicketRuleConfig.BuyCountMax
    BuyAmount = nil

end

function XUiGachaCanLiverPopupBuyAsset:OnEnable()
    self:Refresh()
    if self.BuyCount then
        self:OnSelfSetBuyCount(self.BuyCount)
    end
end
--endregion

--region 初始化
function XUiGachaCanLiverPopupBuyAsset:InitButton()
    self:RegisterClickEvent(self.BtnTanchuangClose, self.Close)
    self:RegisterClickEvent(self.BtnMax, self.OnBtnMaxClick)
    self:RegisterClickEvent(self.BtnAddSelect, self.OnBtnAddSelectClick)
    self:RegisterClickEvent(self.BtnMinusSelect, self.OnBtnMinusSelectClick)
    self:RegisterClickEvent(self.BtnConfirm, self.OnBtnBuyClick)
    self:RegisterClickEvent(self.BtnSkip, self.OnBtnSkipClick)
    self:RegisterClickEvent(self.BtnFreeGetSkip, self.OnBtnFreeGetSkip)
    self.TxtSelect.onValueChanged:AddListener(function() self:OnSelectTextChange() end)
end
--endregion

--region 界面刷新
function XUiGachaCanLiverPopupBuyAsset:Refresh()
    self:RefreshBuyAmount(tonumber(self.TxtSelect.text))
    self:RefreshUiShow()
end

function XUiGachaCanLiverPopupBuyAsset:RefreshBuyAmount(count)
    BuyAmount = count
end

function XUiGachaCanLiverPopupBuyAsset:RefreshUiShow()
    -- 显示消耗道具
    self.RawImageConsume:SetRawImage(XDataCenter.ItemManager.GetItemIcon(self.ItemData.ItemId))
    self.ConsumeTxtPossess.text = CS.XTextManager.GetText("UiBuyAssetHasNum", XDataCenter.ItemManager.GetCount(self.ItemData.ItemId))
    self.TxtConsumeName.text = XDataCenter.ItemManager.GetItemName(self.ItemData.ItemId)
    -- 消耗道具量
    local needCostCount = (BuyAmount or 1) * self.ItemData.CostNum
    local isMoreThanHave = needCostCount > XDataCenter.ItemManager.GetCount(self.ItemData.ItemId)
    self.TxtConsumeCount.gameObject:SetActiveEx(not isMoreThanHave)
    self.TxtConsumeCountRed.gameObject:SetActiveEx(isMoreThanHave)

    self.TxtConsumeCount.text = needCostCount
    self.TxtConsumeCountRed.text = needCostCount
    
    -- 显示目标道具
    self.RawImageTarget:SetRawImage(XDataCenter.ItemManager.GetItemIcon(self.TargetData.ItemId))
    self.TargetTxtPossess.text = CS.XTextManager.GetText("UiBuyAssetHasNum", XDataCenter.ItemManager.GetCount(self.TargetData.ItemId))
    self.TxtTargetName.text = XDataCenter.ItemManager.GetItemName(self.TargetData.ItemId)
    
    self.TargetItemGrid = XUiGridCommon.New(self, self.FurnitureBlueItem)
    self.TargetItemGrid:Refresh(self.TargetData.ItemId)
    
    self:RefreshFreeCount()
    
end

function XUiGachaCanLiverPopupBuyAsset:RefreshFreeCount()
    -- 显示免费次数
    local freeCoinLimit = self._Control:GetCurActivityFreeItemGainUpLimit()
    local hasGotFreeCount = self._Control:GetCurActivityFreeItemIdGainTimes()
    local leftCanGetCount = freeCoinLimit - hasGotFreeCount
    self.FreeImgIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(self._Control:GetCurActivityFreeItemId()))
    self.TxtFreeNum.text = leftCanGetCount
    
    -- 剩余免费次数为0时需隐藏入口
    self.BtnFreeGetSkip.transform.parent.gameObject:SetActiveEx(leftCanGetCount > 0)
end
--endregion

--region 事件回调
function XUiGachaCanLiverPopupBuyAsset:OnBtnMaxClick()
    local targetCount = BuyCountMax
    local res = self:CheckBuyAmountLimit(targetCount)
    if res then
        targetCount = res
    end

    self.TxtSelect.text = targetCount
end

function XUiGachaCanLiverPopupBuyAsset:OnBtnAddSelectClick()
    local count = tonumber(self.TxtSelect.text)
    local targetCount = count + 1
    local resultCount = self:CheckBuyAmountLimit(targetCount)
    if not XTool.IsNumberValid(resultCount) then
        XUiManager.TipMsg(XGachaConfigs.GetClientConfig('TicketBuyCountIsMaxTips'))
        return
    end

    if resultCount == count then
        XUiManager.TipMsg(XGachaConfigs.GetClientConfig('TicketBuyCountIsMaxTips'))
    end
    
    self.TxtSelect.text = targetCount
end

function XUiGachaCanLiverPopupBuyAsset:OnBtnMinusSelectClick()
    local count = tonumber(self.TxtSelect.text)
    local targetCount = count - 1
    local resultCount = self:CheckBuyAmountLimit(targetCount)
    if not XTool.IsNumberValid(resultCount) then
        return
    end

    self.TxtSelect.text = targetCount
end

-- text改动的回调
function XUiGachaCanLiverPopupBuyAsset:OnSelectTextChange()
    local count = tonumber(self.TxtSelect.text)
    local isLimitNum = self:CheckBuyAmountLimit(count)
    if isLimitNum then -- 输入超了强行改回
        self.TxtSelect.text = isLimitNum
        count = isLimitNum
    end

    self:RefreshBuyAmount(count)
    self:RefreshUiShow()
end

-- 如果想要在程序直接控制文本的购买数量 只能调用该接口
function XUiGachaCanLiverPopupBuyAsset:OnSelfSetBuyCount(count)
    local targetCount = count
    
    local result = self:CheckBuyAmountLimit(targetCount)
    if not XTool.IsNumberValid(result) then
        return
    end
    
    targetCount = result

    self.TxtSelect.text = targetCount
end

function XUiGachaCanLiverPopupBuyAsset:OnBtnSkipClick()
    --- 兑换数 = 目标购买数*单价 - 当前拥有数
    local needCostCount = (BuyAmount or 1) * self.ItemData.CostNum - XDataCenter.ItemManager.GetCount(self.ItemData.ItemId)

    if needCostCount > 0 then
        XLuaUiManager.Open("UiBuyAsset", self.ItemData.ItemId, function()
            self:RefreshUiShow()
        end, nil, needCostCount)
    else
        XUiManager.TipMsg(XGachaConfigs.GetClientConfig('TicketConsumeCountEnoughTips', 1))
    end
end

function XUiGachaCanLiverPopupBuyAsset:OnBtnBuyClick()
    -- CD检测
    if not self:CheckBuyCD() then
        XUiManager.TipError(CS.XTextManager.GetText("BuySpeedLimit"))
        return
    end

    -- 购买上限检测: 购买余量由卡池抽取次数决定，不以在该卡池兑换决定，因为可能有前置卡池遗留道具，或其他途径
    local curExchangeItemCount =  XDataCenter.GachaManager.GetTotalGachaTimes(self.GachaCfg.Id)
    local newHaveTotalCount = curExchangeItemCount + BuyAmount
    
    if newHaveTotalCount > self.GachaBuyTicketRuleConfig.TotalBuyCountMax then
        XUiManager.TipError(CS.XTextManager.GetText("BuyItemCountLimit", XDataCenter.ItemManager.GetItemName(self.GachaCfg.ConsumeId)))
        self:Close()
        return
    end

    -- 检查物品数量是否足够，不够弹出购买
    local currItemData = self.ItemData
    local itemId = currItemData.ItemId
    local currentCount = XDataCenter.ItemManager.GetCount(itemId)
    local needCount = currItemData.CostNum * (BuyAmount or 1)
    if currentCount < needCount then
        if itemId == XDataCenter.ItemManager.ItemId.FreeGem or itemId == XDataCenter.ItemManager.ItemId.PaidGem then
            XUiManager.TipError(CS.XTextManager.GetText("MoeWarDailyVoteItemNotEnoughTip", XDataCenter.ItemManager.GetItemName(itemId)))
            XLuaUiManager.Open("UiPurchase", XPurchaseConfigs.TabsConfig.HK)
        elseif itemId == XDataCenter.ItemManager.ItemId.HongKa then
            XUiManager.TipError(CS.XTextManager.GetText("MoeWarDailyVoteItemNotEnoughTip", XDataCenter.ItemManager.GetItemName(itemId)))
            XLuaUiManager.Open("UiPurchase", XPurchaseConfigs.TabsConfig.Pay)
        elseif XItemConfigs.GetBuyAssetTemplateById(itemId) then
            XLuaUiManager.Open("UiBuyAsset", itemId, function()
                if self.CurNum then
                    self.CurNum.text = XDataCenter.ItemManager.GetItem(self.TicketData.ItemId).Count
                end
                self:RefreshUiShow()
            end, nil, needCount - currentCount)
        else
            XUiManager.TipError(XUiHelper.GetText("AssetsBuyConsumeNotEnough", XDataCenter.ItemManager.GetItemName(itemId)))
        end
        return
    end

    -- 购买协议
    XDataCenter.GachaManager.BuyTicket(self.GachaCfg.Id, BuyAmount, 0, function (rewardList) -- index-1 服务器下标0开始
        self:Close()
        if self.SuccessCb then
            self.SuccessCb()
        end
        XUiManager.OpenUiObtain(rewardList)
    end)
end

function XUiGachaCanLiverPopupBuyAsset:OnBtnFreeGetSkip()
    XLuaUiManager.OpenWithCloseCallback('UiGachaCanLiverTask', function()
        self:RefreshFreeCount()
    end)
end
--endregion

function XUiGachaCanLiverPopupBuyAsset:CheckBuyAmountLimit(count)
    if type(count) ~= "number" then
        return 1
    end
    -- 道具的剩余可购买次数 = 总兑换次数 - 当前卡池抽取次数
    -- 总的剩余可购买次数 = min(道具剩余，卡池余量）
    -- 当次的剩余可购买次数 = min（总剩余，单次最大） - 已拥有免费 - 已拥有道具
    local totalLeftCanBuy = self.GachaBuyTicketRuleConfig.TotalBuyCountMax - XDataCenter.GachaManager.GetTotalGachaTimes(self.GachaCfg.Id)
    if not XDataCenter.GachaManager.GetIsInfinite(self.GachaCfg.Id) then
        --- 当前抽取的次数
        local curCount = XDataCenter.GachaManager.GetCurCountOfAll(self.GachaCfg.Id)
        --- 可抽取的最大次数
        local maxCount = XDataCenter.GachaManager.GetMaxCountOfAll(self.GachaCfg.Id)
        --- 剩余次数
        local leftCount = maxCount - curCount
        
        totalLeftCanBuy = math.min(totalLeftCanBuy, leftCount)
    end
    local curLeftCanBuy = math.min(BuyCountMax, totalLeftCanBuy) - self._Control:GetCurActivityFreeItemCount() - XDataCenter.ItemManager.GetCount(self.TargetData.ItemId)
    
    if count > curLeftCanBuy then
        if curLeftCanBuy <= 0 then
            curLeftCanBuy = 1
        end
        if curLeftCanBuy > BuyCountMax then
            return BuyCountMax
        end
        return curLeftCanBuy
    elseif count > BuyCountMax then
        return BuyCountMax
    elseif count < 1 then
        return 1
    end

    return count
end

function XUiGachaCanLiverPopupBuyAsset:CheckBuyCD()
    local nowTime = XTime.GetServerNowTimestamp() -- 使用目标时间点做标记来替代计时器
    -- 第一次必定可以请求
    if not TargetCanBuyTimestamp then
        TargetCanBuyTimestamp = nowTime + CDTime
        return true
    end

    local leftTime = TargetCanBuyTimestamp - nowTime
    if leftTime >= 0 then
        return false
    end

    TargetCanBuyTimestamp = nowTime + CDTime
    return true
end

return XUiGachaCanLiverPopupBuyAsset