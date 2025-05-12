XPayAgent = XClass(nil, "XPayAgent")

local Json = require("XCommon/Json")
local table = table
local tableInsert = table.insert
local tableRemove = table.remove

local pairs = pairs

local TipsQueue = {}
-- 网页支付提示弹框
local WebTipsQueue = {}

local PayType = {
    Base = 0,   -- 基础支付
    Web = 1,    -- 网页支付
}

local OnSaveOrders = function(playerId, orders)
    local orderStr = Json.encode(orders)
    CS.UnityEngine.PlayerPrefs.SetString(XPrefs.PayOrder .. playerId, orderStr)
    CS.UnityEngine.PlayerPrefs.Save()
end

local OnLoadOrders = function(playerId)
    local orderStr = CS.UnityEngine.PlayerPrefs.GetString(XPrefs.PayOrder .. playerId)
    if orderStr and #orderStr > 0 then
        local orders = Json.decode(orderStr)

        return orders
    end

    return {}
end

function XPayAgent:Ctor(playerId)
    self.PlayerId = playerId
    self.IsPaying = false
    self.OrderDict = OnLoadOrders(playerId)

    CsXGameEventManager.Instance:RegisterEvent(XEventId.EVENT_FIGHT_EXIT, function()
        self:TipsPaySuccess()
    end)
end

-- override this
function XPayAgent:Pay()
    --XUiManager.TipText("PaySuccess", XUiManager.UiTipType.Success)
end

function XPayAgent:AddOrder(order)
    local orderId = order.OrderId
    if not orderId or #orderId <= 0 then
        XLog.Error("XPayAgent.AddOrder error: order CpOrderId is nil")
        return
    end

    if not order.PlayerId or order.PlayerId ~= self.PlayerId then
        XLog.Error("XPayAgent.AddOrder error: order PlayerId is error, Order PlayerId is " .. order.PlayerId .. ", PlayerId is " .. self.PlayerId)
        return
    end

    if self.OrderDict[orderId] then
        XLog.Error("XPayAgent.AddOrder error: order is exsit, CpOrderId is " .. orderId)
        return
    end

    self.OrderDict[orderId] = order
    OnSaveOrders(self.PlayerId, self.OrderDict)
end

function XPayAgent:RemoveOrder(orderId)
    if not self.OrderDict[orderId] then
        return
    end

    self.OrderDict[orderId] = nil
    OnSaveOrders(self.PlayerId, self.OrderDict)
end

-- function XPayAgent:UpdateOrderCheckTimes()
--     local list = {}
--     for id, order in pairs(self.OrderDict) do
--         local times = order.Times and order.Times + 1 or 1
--         if times >= ORDER_CHECK_TIMES_LIMIT then
--             tableInsert(list, id)
--         else
--             order.Times = times
--         end
--     end
--     for _, id in pairs(list) do
--         self.OrderDict[id] = nil
--     end
--     OnSaveOrders(self.PlayerId, self.OrderDict)
-- end
-- override this
function XPayAgent:OnPaySuccess(order)
    self:AddOrder(order)
    XUiManager.TipText("PayAcceptTips", XUiManager.UiTipType.Success)
end

function XPayAgent:TipsPaySuccess()
    if CS.XFight.IsRunning then
        return
    end

    if not next(TipsQueue) then
        return
    end

    tableRemove(TipsQueue, 1)
    local text = CS.XTextManager.GetText("PaySuccess")

    XUiManager.TipMsg(text, XUiManager.UiTipType.Success, function()
        self:TipsPaySuccess()
        XEventManager.DispatchEvent(XEventId.EVENT_SUCCESS_PAY)
    end)
end

-- 网页充值成功弹框
function XPayAgent:WebTipsPaySuccess()
    if not self:CheckWebTips() then
        XEventManager.DispatchEvent(XEventId.EVENT_WEB_RECHARGE_SUCCESS_END)
        return
    end
    local payKey = tableRemove(WebTipsQueue, 1)
    local template = XPayConfigs.GetPayTemplate(payKey)
    if not template then
        self:WebTipsPaySuccess()
        return
    end
    local rewardList = XRewardManager.CreateRewardGoods(XDataCenter.ItemManager.ItemId.HongKa, template.MoneyCard)
    XUiManager.OpenUiObtain({ rewardList }, nil, function()
        self:WebTipsPaySuccess()
    end)
end

-- 检查是否有网页弹框
function XPayAgent:CheckWebTips()
    if not next(WebTipsQueue) then
        return false
    end
    return true
end

-- 显示网页弹框
function XPayAgent:ShowWebTips()
    if CS.XFight.IsRunning then
        return
    end
    if not self:CheckWebTips() then
        return
    end
    -- 采购界面或者采购界面已加载，弹出网页充值成功弹框
    if XLuaUiManager.IsUiShow("UiPurchase") then
        self:WebTipsPaySuccess()
        return
    end
    XEventManager.DispatchEvent(XEventId.EVENT_WEB_RECHARGE_SUCCESS)
end

--==============================--
--desc: 交易成功，处理缓存订单
--@orderList: 游戏订单列表
--==============================--
function XPayAgent:OnDealSuccess(orderList)
    -- XLog.Error("充值结果回调--XPayAgent:OnDealSuccess(orderList)")
    -- XLog.Error(orderList)
    if not orderList or #orderList <= 0 then
        return
    end

    for _, order in pairs(orderList) do
        if order.GameOrder then
            self:RemoveOrder(order.GameOrder)
        end

        if order.OrderNo then
            self:RemoveOrder(order.OrderNo)
        end

        if order.PayType == PayType.Web then
            tableInsert(WebTipsQueue, order.PayKey)
        else
            tableInsert(TipsQueue, order.PayKey)
        end
    end

    -- 测试充值
    -- XLog.Error("充值结果回调--self:TipsPaySuccess()")
    -- XLog.Error(TipsQueue)
    self:TipsPaySuccess()
    self:ShowWebTips()
end
