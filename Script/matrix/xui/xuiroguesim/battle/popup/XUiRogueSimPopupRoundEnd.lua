local XUiPanelRogueSimAgencyEvent = require("XUi/XUiRogueSim/Battle/Panel/XUiPanelRogueSimAgencyEvent")
local XUiPanelRogueSimMarket = require("XUi/XUiRogueSim/Battle/Panel/XUiPanelRogueSimMarket")
local XUiPanelRogueSimProduce = require("XUi/XUiRogueSim/Battle/Panel/XUiPanelRogueSimProduce")
local XUiPanelRogueSimSell = require("XUi/XUiRogueSim/Battle/Panel/XUiPanelRogueSimSell")
local XUiGridRogueSimCityTask = require("XUi/XUiRogueSim/Battle/Grid/XUiGridRogueSimCityTask")
---@class XUiRogueSimPopupRoundEnd : XLuaUi
---@field private _Control XRogueSimControl
---@field BtnGroup XUiButtonGroup
local XUiRogueSimPopupRoundEnd = XLuaUiManager.Register(XLuaUi, "UiRogueSimPopupRoundEnd")

function XUiRogueSimPopupRoundEnd:OnAwake()
    self:RegisterUiEvents()
    self.GridCity.gameObject:SetActiveEx(false)
    self.Auto.gameObject:SetActiveEx(false)
    self.PanelBubble.gameObject:SetActiveEx(false)
    self.PanelProduce.gameObject:SetActiveEx(false)
    self.PanelSell.gameObject:SetActiveEx(false)
    ---@type XUiGridRogueSimCityTask[]
    self.GridCityTaskList = {}
end

function XUiRogueSimPopupRoundEnd:OnStart()
    self._Control:CheckAndUpdateTempSellPlan()
    self.BtnGroup:Init({ self.BtnProduce, self.BtnSell }, function(index)
        self:OnBtnGroupClick(index)
    end)
end

function XUiRogueSimPopupRoundEnd:OnEnable()
    self:RefreshAgencyEvent()
    self:RefreshMarket()
    self:RefreshCityTask()
    self:CheckAutoSell()
    self.BtnGroup:SelectIndex(1)
end

-- 刷新代办事件
function XUiRogueSimPopupRoundEnd:RefreshAgencyEvent()
    if not self.PanelEventUi then
        ---@type XUiPanelRogueSimAgencyEvent
        self.PanelEventUi = XUiPanelRogueSimAgencyEvent.New(self.PanelEvent, self)
    end
    self.PanelEventUi:Open()
    self.PanelEventUi:Refresh()
end

-- 刷新市场情况
function XUiRogueSimPopupRoundEnd:RefreshMarket()
    if not self.PanelMarketUi then
        ---@type XUiPanelRogueSimMarket
        self.PanelMarketUi = XUiPanelRogueSimMarket.New(self.PanelPrice, self)
    end
    self.PanelMarketUi:Open()
    self.PanelMarketUi:Refresh()
end

-- 刷新城邦任务
function XUiRogueSimPopupRoundEnd:RefreshCityTask()
    local cityIds = self._Control.MapSubControl:GetCityTaskUnfinishedOrCanLevelUpIds()
    self.TxtNone.gameObject:SetActiveEx(XTool.IsTableEmpty(cityIds))
    for index, id in pairs(cityIds) do
        local grid = self.GridCityTaskList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridCity, self.Content)
            grid = XUiGridRogueSimCityTask.New(go, self)
            self.GridCityTaskList[index] = grid
        end
        grid:Open()
        grid:Refresh(id)
    end
    for i = #cityIds + 1, #self.GridCityTaskList do
        self.GridCityTaskList[i]:Close()
    end
end

-- 生产和出售按钮点击
function XUiRogueSimPopupRoundEnd:OnBtnGroupClick(index)
    if index == 1 then
        -- 生产
        self:CloseSell()
        self:OpenProduce()
    elseif index == 2 then
        -- 出售
        self:CloseProduce()
        self:OpenSell()
    end
    self:PlayAnimation("QieHuan")
end

-- 打开生产界面
function XUiRogueSimPopupRoundEnd:OpenProduce()
    if not self.PanelProduceUi then
        ---@type XUiPanelRogueSimProduce
        self.PanelProduceUi = XUiPanelRogueSimProduce.New(self.PanelProduce, self)
    end
    self.PanelProduceUi:Open()
    self.PanelProduceUi:Refresh()
    --self.PanelBubble.gameObject:SetActiveEx(true)
end

-- 打开出售界面
function XUiRogueSimPopupRoundEnd:OpenSell()
    if not self.PanelSellUi then
        ---@type XUiPanelRogueSimSell
        self.PanelSellUi = XUiPanelRogueSimSell.New(self.PanelSell, self)
    end
    self.PanelSellUi:Open()
    self.PanelSellUi:Refresh()
end

-- 关闭生产界面
function XUiRogueSimPopupRoundEnd:CloseProduce()
    if self.PanelProduceUi then
        self.PanelProduceUi:Close()
    end
    --self.PanelBubble.gameObject:SetActiveEx(false)
end

-- 获取生产评分
function XUiRogueSimPopupRoundEnd:GetProducePlanScore()
    if self.PanelProduceUi then
        return self.PanelProduceUi:GetProducePlanScore()
    end
    return {}
end

-- 检查并修复出售预设计划
function XUiRogueSimPopupRoundEnd:CheckAndFixSellPresetPlan()
    if self.PanelSellUi then
        self.PanelSellUi:CheckAndFixSellPresetPlan()
    end
end

-- 关闭出售界面
function XUiRogueSimPopupRoundEnd:CloseSell()
    if self.PanelSellUi then
        self.PanelSellUi:Close()
    end
end

-- 刷新回合结束按钮
function XUiRogueSimPopupRoundEnd:RefreshBtnEnd()
    -- 主城可升级
    local canLevelUp = self._Control:CheckMainLevelCanLevelUp()
    -- 城邦可升级
    local cityCanLevelUpIds = self._Control.MapSubControl:GetCityCanLevelUpIds()
    local cityCanLevelUp = not XTool.IsTableEmpty(cityCanLevelUpIds)
    -- 有生产点未分配完或者生产点超出
    local remainingPopulation = self._Control:GetActualRemainingPopulation()
    -- 有可领取的事件投机/挂起事件中剩余回合数等于1的事件需要完成后才能进入下一回合
    local hasEventDeal = self._Control.MapSubControl:CheckHasEventGambleReward() or self._Control.MapSubControl:CheckHasPendingEvent()
    self.BtnEnd:SetDisable(canLevelUp or cityCanLevelUp or remainingPopulation ~= 0 or hasEventDeal)
end

-- 检查是否自动出售
function XUiRogueSimPopupRoundEnd:CheckAutoSell()
    local isAutoSell = self._Control:CheckCommodityIsAutoSell()
    self.Auto.gameObject:SetActiveEx(isAutoSell)
end

-- 检测生产力是否分配完毕
function XUiRogueSimPopupRoundEnd:CheckPopulationIsFull()
    -- 检是是否有剩余的生产力
    local remainingPopulation = self._Control:GetActualRemainingPopulation()
    if remainingPopulation > 0 then
        XUiManager.TipMsg(self._Control:GetClientConfig("RoundEndRemainPopulationTips"))
        return false
    end
    -- 检查生产力是否超出
    if remainingPopulation < 0 then
        XUiManager.TipMsg(self._Control:GetClientConfig("RoundEndPopulationOverFlowTips"))
        return false
    end
    return true
end

-- 检查生产是否溢出
function XUiRogueSimPopupRoundEnd:CheckProduceFull()
    local populationInfo = self._Control:GetActualCommodityPopulationPlan()
    if XTool.IsTableEmpty(populationInfo) then
        return false
    end
    -- 收集超出储存上限的商品
    local overflowIds = {}
    for id, _ in pairs(populationInfo) do
        if self._Control.ResourceSubControl:CheckCommodityIsExceedLimit(id) then
            table.insert(overflowIds, id)
        end
    end
    if #overflowIds > 0 then
        local tips = self._Control:GetClientConfig("RoundSettlementExceedLimitTips")
        local names = {}
        for _, id in pairs(overflowIds) do
            table.insert(names, self._Control.ResourceSubControl:GetCommodityName(id))
        end
        XUiManager.TipMsg(string.format(tips, table.concat(names, ",")))
        return true
    end
    -- 收集预估产量超出储存上限的商品
    overflowIds = {}
    for id, _ in pairs(populationInfo) do
        if self._Control.ResourceSubControl:CheckProduceRateIsExceedLimit(id) then
            table.insert(overflowIds, id)
        end
    end
    if #overflowIds > 0 then
        -- 生产爆仓二次确认弹框
        local confirmTitle = self._Control:GetClientConfig("RoundSettlementConfirmTitle", 2)
        local confirmContent = self._Control:GetClientConfig("RoundSettlementConfirmContent", 2)
        local names = {}
        for _, id in pairs(overflowIds) do
            table.insert(names, self._Control.ResourceSubControl:GetCommodityName(id))
        end
        confirmContent = string.format(confirmContent, table.concat(names, ","))
        self._Control:ShowCommonTip(confirmTitle, confirmContent, nil, function()
            self:CommoditySetupPlans(function()
                self:RequestRoundSettlement()
            end)
        end)
        return true
    end
    return false
end

-- 检查是否有可购买区域
function XUiRogueSimPopupRoundEnd:CheckCanBuyArea()
    -- 是否跳过二次确认
    local isSkipTips = self._Control:IsSkipBuyAreaTips()
    if isSkipTips then
        return false
    end
    -- 有可购买区域
    local areaBuyGridIds = self._Control.MapSubControl:GetCanBuyAreaGridIds()
    if XTool.IsTableEmpty(areaBuyGridIds) then
        return false
    end
    local confirmTitle = self._Control:GetClientConfig("RoundSettlementConfirmTitle", 3)
    local confirmContent = self._Control:GetClientConfig("RoundSettlementConfirmContent", 3)
    self._Control:ShowCommonTip(confirmTitle, confirmContent, nil, function()
        self:CommoditySetupPlans(function()
            self:RequestRoundSettlement()
        end)
    end, nil, function(isSkip)
        self._Control:SetSkipBuyAreaTips(isSkip)
    end, { IsShowSkip = true })
    return true
end

-- 检查是否有可探索格子
function XUiRogueSimPopupRoundEnd:CheckCanExploreGrid()
    -- 是否跳过二次确认
    local isSkipTips = self._Control:IsSkipExploreGridTips()
    if isSkipTips then
        return false
    end
    -- 有可探索格子
    local exploreGridIds = self._Control:GetCanExploreGridIds()
    if XTool.IsTableEmpty(exploreGridIds) then
        return false
    end
    local confirmTitle = self._Control:GetClientConfig("RoundSettlementConfirmTitle", 1)
    local confirmContent = self._Control:GetClientConfig("RoundSettlementConfirmContent", 1)
    self._Control:ShowCommonTip(confirmTitle, confirmContent, nil, function()
        self:CommoditySetupPlans(function()
            self:RequestRoundSettlement()
        end)
    end, nil, function(isSkip)
        self._Control:SetSkipExploreGridTips(isSkip)
    end, { IsShowSkip = true })
    return true
end

function XUiRogueSimPopupRoundEnd:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBgClose, self.OnBtnCloseClick)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnEnd, self.OnBtnEndClick)
end

function XUiRogueSimPopupRoundEnd:OnBtnCloseClick()
    self:CheckAndFixSellPresetPlan()
    self:Close()
end

function XUiRogueSimPopupRoundEnd:OnBtnEndClick()
    -- 关卡数据为空时直接关闭当前界面
    if self._Control:CheckStageDataIsEmpty() then
        XLog.Error("error: stage data is empty")
        self:Close()
        return
    end
    -- 有可领取的事件投机
    if self._Control.MapSubControl:CheckHasEventGambleReward() then
        XUiManager.TipMsg(self._Control:GetClientConfig("RoundEndEventGambleRewardTips"))
        return
    end
    -- 挂起事件中剩余回合数等于1的事件需要完成后才能进入下一回合
    if self._Control.MapSubControl:CheckHasPendingEvent() then
        XUiManager.TipMsg(self._Control:GetClientConfig("RoundEndPendingEventTips"))
        return
    end
    -- 主城是否可升级
    if self._Control:CheckMainLevelCanLevelUp() then
        XUiManager.TipMsg(self._Control:GetClientConfig("RoundEndMainCanLevelUpTips"))
        return
    end
    -- 城邦是否可升级
    local cityCanLevelUpIds = self._Control.MapSubControl:GetCityCanLevelUpIds()
    if not XTool.IsTableEmpty(cityCanLevelUpIds) then
        XUiManager.TipMsg(self._Control:GetClientConfig("RoundEndCityCanLevelUpTips"))
        return
    end
    -- 生产力是否分配完毕
    if not self:CheckPopulationIsFull() then
        return
    end
    -- 生产溢出
    if self:CheckProduceFull() then
        return
    end
    -- 有可购买区域
    if self:CheckCanBuyArea() then
        return
    end
    -- 有可探索格子
    if self:CheckCanExploreGrid() then
        return
    end
    -- 请求回合结算
    self:CommoditySetupPlans(function()
        self:RequestRoundSettlement()
    end)
end

-- 设置商品计划
function XUiRogueSimPopupRoundEnd:CommoditySetupPlans(callback)
    self:CheckAndFixSellPresetPlan()
    local producePlan = self._Control:GetActualCommodityPopulationPlan()
    local sellPlan = self._Control:GetActualCommoditySellPlan()
    local sellPlanPreset = self._Control:GetActualCommoditySellPlanPreset()
    local producePlanScore = self:GetProducePlanScore()
    self._Control:RogueSimCommoditySetupPlansRequest(producePlan, sellPlan, sellPlanPreset, producePlanScore, callback)
end

-- 请求回合结算
function XUiRogueSimPopupRoundEnd:RequestRoundSettlement()
    self._Control:RogueSimTurnSettleRequest(function()
        if self._Control:CheckStageSettleDataIsEmpty() then
            self:Close()
            ---@type XUiRogueSimBattle
            local luaUi = XLuaUiManager.GetTopLuaUi("UiRogueSimBattle")
            if luaUi then
                -- 下一回合过场
                luaUi:OpenTransition()
            end
        else
            -- 直接打开回合开始界面
            XLuaUiManager.PopThenOpen("UiRogueSimPopupRoundStart")
        end
    end)
end

-- 关闭当前界面然后模拟格子点击
function XUiRogueSimPopupRoundEnd:CloseAndSimulateGridClick(gridId)
    self:CheckAndFixSellPresetPlan()
    self._Control:SimulateGridClickBefore(self.Name, gridId)
end

-- 关闭当前界面然后跳转到对应的格子
function XUiRogueSimPopupRoundEnd:CloseAndJumpToGrid(gridId)
    self:CheckAndFixSellPresetPlan()
    self._Control:JumpToGridBefore(self.Name, gridId)
end

-- 关闭当前界面然后打开挂起事件或者事件投机
function XUiRogueSimPopupRoundEnd:CloseAndOpenEventPopup(eventId, eventGambleId)
    self:CheckAndFixSellPresetPlan()
    self._Control:OpenEventPopupBefore(self.Name, eventId, eventGambleId)
end

return XUiRogueSimPopupRoundEnd
