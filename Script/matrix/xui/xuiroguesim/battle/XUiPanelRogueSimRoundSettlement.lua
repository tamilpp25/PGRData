---@class XUiPanelRogueSimRoundSettlement : XUiNode
---@field private _Control XRogueSimControl
---@field private Parent XUiRogueSimBattle
local XUiPanelRogueSimRoundSettlement = XClass(XUiNode, "XUiPanelRogueSimRoundSettlement")
local CSInstantiate = CS.UnityEngine.Object.Instantiate

function XUiPanelRogueSimRoundSettlement:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
    XUiHelper.RegisterClickEvent(self, self.BtnEnd, self.OnBtnEndClick)
    self.GridSell.gameObject:SetActiveEx(false)
    ---@type XUiGridRogueSimRoundSettlementSell[]
    self.GridSellList = {}
end

function XUiPanelRogueSimRoundSettlement:Refresh()
    -- 剩余行动点
    self.TxtNum.text = self._Control:GetCurActionPoint()
    -- 代办事件
    self:RefreshEvent()
    -- 贸易
    self:RefreshSell()
    -- 生产
    self:RefreshProduce()
end

function XUiPanelRogueSimRoundSettlement:OnGetLuaEvents()
    return {
        XEventId.EVENT_ROGUE_SIM_COMMODITY_SETUP_SELL,
        XEventId.EVENT_ROGUE_SIM_COMMODITY_SETUP_PRODUCE,
    }
end

function XUiPanelRogueSimRoundSettlement:OnNotify(event, ...)
    if event == XEventId.EVENT_ROGUE_SIM_COMMODITY_SETUP_SELL then
        self:RefreshSell()
        self:RefreshProduce()
    elseif event == XEventId.EVENT_ROGUE_SIM_COMMODITY_SETUP_PRODUCE then
        self:RefreshProduce()
    end
end

-- 跳转主城升级
function XUiPanelRogueSimRoundSettlement:OnClickGridLevelUp()
    self:Close()
    self._Control:CameraFocusMainGrid(function()
        XLuaUiManager.Open("UiRogueSimLv")
    end)
end

-- 跳转建筑购买
function XUiPanelRogueSimRoundSettlement:OnClickGridBuild(id)
    self:Close()
    self._Control.MapSubControl:ExploreBuildingGrid(id)
end

-- 跳转处理事件
function XUiPanelRogueSimRoundSettlement:OnClickGridEvent(id)
    self:Close()
    self._Control.MapSubControl:ExploreEventGrid(id)
end

-- 跳转处理道具选择
function XUiPanelRogueSimRoundSettlement:OnClickGridItem(id)
    self:Close()
    self._Control.MapSubControl:ExplorePropGrid(id)
end

-- 事件
function XUiPanelRogueSimRoundSettlement:RefreshEvent()
    local haveEvent = false

    -- 主城升级
    local isCanLevelUp = self._Control:CheckMainLevelCanLevelUp()
    self.GridLevelUp.gameObject:SetActiveEx(isCanLevelUp)
    if isCanLevelUp then
        haveEvent = true
        self.GridLevelUp.CallBack = function()
            self:OnClickGridLevelUp()
        end
    end

    -- 建筑购买
    self.GridBuilds = self.GridBuilds or { self.GridBuild }
    for _, build in ipairs(self.GridBuilds) do
        build.gameObject:SetActiveEx(false)
    end
    local buildingIds = self._Control.MapSubControl:GetUnBuyBuildingIds()
    for i, id in ipairs(buildingIds) do
        haveEvent = true
        local btn = self.GridBuilds[i]
        if not btn then
            btn = CSInstantiate(self.GridBuild, self.EventList)
            self.GridBuilds[i] = btn
        end
        btn.gameObject:SetActiveEx(true)
        btn.transform:SetAsLastSibling()

        local tempId = id
        btn.CallBack = function()
            self:OnClickGridBuild(tempId)
        end
    end

    -- 事件
    self.GridEvents = self.GridEvents or { self.GridEvent }
    for _, event in ipairs(self.GridEvents) do
        event.gameObject:SetActiveEx(false)
    end
    local eventIds = self._Control.MapSubControl:GetPendingEventIds()
    for i, id in ipairs(eventIds) do
        haveEvent = true
        local btn = self.GridEvents[i]
        if not btn then
            btn = CSInstantiate(self.GridEvent, self.EventList)
            self.GridEvents[i] = btn
        end
        btn.gameObject:SetActiveEx(true)
        btn.transform:SetAsLastSibling()

        local tempId = id
        btn.CallBack = function()
            self:OnClickGridEvent(tempId)
        end
    end

    -- 格子奖励
    self.GridItems = self.GridItems or { self.GridItem }
    for _, event in ipairs(self.GridItems) do
        event.gameObject:SetActiveEx(false)
    end
    local rewards = self._Control:GetRewardData()
    local index = 1
    for _, reward in pairs(rewards) do
        haveEvent = true
        local btn = self.GridItems[index]
        if not btn then
            btn = CSInstantiate(self.GridItem, self.EventList)
            self.GridItems[index] = btn
        end
        btn.gameObject:SetActiveEx(true)
        btn.transform:SetAsLastSibling()

        local tempId = reward:GetId()
        btn.CallBack = function()
            self:OnClickGridItem(tempId)
        end
        index = index + 1
    end

    self.EventList.gameObject:SetActiveEx(haveEvent)
    self.TxtEventNone.gameObject:SetActiveEx(not haveEvent)
end

-- 贸易
function XUiPanelRogueSimRoundSettlement:RefreshSell()
    local commodityIds = self._Control.ResourceSubControl:GetSellCommodityIds()
    -- 货物
    local totalProfit = 0
    for index, id in pairs(commodityIds) do
        local grid = self.GridSellList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridSell, self.PanelSellList)
            grid = require("XUi/XUiRogueSim/Battle/XUiGridRogueSimRoundSettlementSell").New(go, self)
            self.GridSellList[index] = grid
        end
        grid:Open()
        grid:Refresh(id)
        totalProfit = totalProfit + grid:GetCurCommodityProfit()
    end
    for i = #commodityIds + 1, #self.GridSellList do
        self.GridSellList[i]:Close()
    end
    -- 总利润
    local goldId = XEnumConst.RogueSim.ResourceId.Gold
    self.RImgCoin:SetRawImage(self._Control.ResourceSubControl:GetResourceIcon(goldId))
    self.TxtProfit.text = string.format("+%d", totalProfit)
    -- 设置状态
    local isEmpty = XTool.IsTableEmpty(commodityIds)
    self.PanelProfit.gameObject:SetActiveEx(not isEmpty)
    self.TxtSellNone.gameObject:SetActiveEx(isEmpty)
end

-- 生产
function XUiPanelRogueSimRoundSettlement:RefreshProduce()
    -- 生产Id
    local id = self._Control.ResourceSubControl:GetProductCommodityId()
    local isValid = XTool.IsNumberValid(id)
    self.TxtProduceNone.gameObject:SetActiveEx(not isValid)
    if not isValid then
        self:CloseResource()
        self.TxtFull.gameObject:SetActiveEx(false)
        return
    end
    self:OpenResource(id)
    -- 溢出
    self.TxtFull.gameObject:SetActiveEx(self._Control.ResourceSubControl:CheckProduceRateIsExceedLimit(id))
end

-- 资源
function XUiPanelRogueSimRoundSettlement:OpenResource(id)
    if not self.Resource then
        ---@type XUiGridRogueSimResource
        self.Resource = require("XUi/XUiRogueSim/Common/XUiGridRogueSimResource").New(self.GridResource, self)
    end
    self.Resource:Open()
    self.Resource:SetShowStatus(false, true)
    self.Resource:SetProduceBubble()
    self.Resource:Refresh(id)
end

function XUiPanelRogueSimRoundSettlement:CloseResource()
    if self.Resource then
        self.Resource:Close()
    else
        self.GridResource.gameObject:SetActiveEx(false)
    end
end

function XUiPanelRogueSimRoundSettlement:OnBtnCloseClick()
    self:Close()
end

function XUiPanelRogueSimRoundSettlement:OnBtnEndClick()
    -- 挂起事件中剩余回合数等于1的事件需要完成后才能进入下一回合
    if self._Control.MapSubControl:CheckHasPendingEvent() then
        XUiManager.TipMsg(self._Control:GetClientConfig("TurnSettlePendingEventTips"))
        return
    end
    -- 未选择生产资源提示
    local id = self._Control.ResourceSubControl:GetProductCommodityId()
    if not XTool.IsNumberValid(id) then
        XUiManager.TipMsg(self._Control:GetClientConfig("ProduceNotSelectTips"))
        return
    end
    -- 有剩余行动点
    if self:CheckActionPoint() then
        return
    end
    -- 生产爆仓
    if self:CheckProduceRate() then
        return
    end
    self:RequestRoundSettlement()
end

-- 检测剩余行动点
function XUiPanelRogueSimRoundSettlement:CheckActionPoint()
    if self._Control:GetCurActionPoint() > 0 then
        -- 行动点二次确认弹框
        local confirmTitle = self._Control:GetClientConfig("RoundSettlementConfirmTitle", 1)
        local confirmContent = self._Control:GetClientConfig("RoundSettlementConfirmContent", 1)
        self._Control:ShowCommonTip(confirmTitle, confirmContent, nil, function()
            -- 生产爆仓
            if self:CheckProduceRate() then
                return
            end
            self:RequestRoundSettlement()
        end)
        return true
    end
    return false
end

-- 检测生产爆仓
function XUiPanelRogueSimRoundSettlement:CheckProduceRate()
    local id = self._Control.ResourceSubControl:GetProductCommodityId()
    if not XTool.IsNumberValid(id) then
        return false
    end
    if self._Control.ResourceSubControl:CheckProduceRateIsExceedLimit(id) then
        -- 生产爆仓二次确认弹框
        local confirmTitle = self._Control:GetClientConfig("RoundSettlementConfirmTitle", 2)
        local confirmContent = self._Control:GetClientConfig("RoundSettlementConfirmContent", 2)
        confirmContent = string.format(confirmContent, self._Control.ResourceSubControl:GetCommodityName(id))
        self._Control:ShowCommonTip(confirmTitle, confirmContent, nil, function()
            self:RequestRoundSettlement()
        end, function()
            -- 跳转到贸易界面
            XLuaUiManager.Open("UiRogueSimSell")
        end, { IsShowJump = true })
        return true
    end
    return false
end

-- 请求回合结算
function XUiPanelRogueSimRoundSettlement:RequestRoundSettlement()
    self._Control:RogueSimTurnSettleRequest(function()
        self:Close()
        if self._Control:CheckStageSettleDataIsEmpty() then
            -- 下一回合过场
            self.Parent:OpenTransition()
        else
            -- 直接打开回合开始界面
            self.Parent:OpenRoundStart()
        end
    end)
end

return XUiPanelRogueSimRoundSettlement
