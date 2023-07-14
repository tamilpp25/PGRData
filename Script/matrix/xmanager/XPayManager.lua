XPayManagerCreator = function()
    local Application = CS.UnityEngine.Application
    local Platform = Application.platform
    local RuntimePlatform = CS.UnityEngine.RuntimePlatform
    local PayAgent = nil

    local XPayManager = {}
    local IsGetFirstRechargeReward  -- 是否领取首充奖励
    local IsFirstRecharge           -- 是否首充

    local METHOD_NAME = {
        Initiated = "PayInitiatedRequest",
        CheckResult = "PayCheckResultRequest",
        GetFirstPayReward = "GetFirstPayRewardRequest", -- 获取首充奖励
    }

    local NearPayId = nil
    local CurrentPayIds = {}
    local PurchasePayLockGoodsTime = CS.XGame.ClientConfig:GetFloat("PurchasePayLockGoodsTime")

    local function IsSupportPay()
        return Application.isMobilePlatform or
        (Platform == RuntimePlatform.WindowsPlayer or Platform == RuntimePlatform.WindowsEditor)
    end

    local function InitAgent()
        if Platform == RuntimePlatform.Android then
            PayAgent = XPayHeroAgent.New(XPlayer.Id)
        elseif Platform == RuntimePlatform.IPhonePlayer then
            PayAgent = XPayHeroAgent.New(XPlayer.Id)
        elseif Platform == RuntimePlatform.WindowsPlayer or Platform == RuntimePlatform.WindowsEditor then
            PayAgent = XPayHeroAgent.New(XPlayer.Id)
        else
            PayAgent = XPayAgent.New(XPlayer.Id)
        end
    end

    local function DoInit()
        XEventManager.AddEventListener(XEventId.EVENT_LOGIN_SUCCESS, function()
            InitAgent()
        end)
        CurrentPayIds = {}
        XEventManager.AddEventListener(XEventId.EVENT_PURCHASEBUY_PAYCANCELORFAIL, function()
                XPayManager.ClearCurrentPayId()
            end)
    end

    local DoPay = function(productKey, cpOrderId, goodsId)
        PayAgent:Pay(productKey, cpOrderId, goodsId)
    end

    function XPayManager.PurchasePayLock(id)
        --XLog.Error("当前锁住的id是" .. tostring(id))
        CurrentPayIds[id] = XTime.GetServerNowTimestamp()
    end

    function XPayManager.SetNearPayId(id)
        NearPayId = id
    end

    function XPayManager.GetCurrentPayIds()
        return CurrentPayIds
    end

    function XPayManager.ClearCurrentPayId(id)
        local currentId = id and id or NearPayId
        if not currentId then
            return
        end
        --XLog.Error("清空缓存id是：" .. tostring(id))
        CurrentPayIds[currentId] = nil
        --XLog.Error("清空缓存此时的缓存数据是：")
        for k, _ in pairs(CurrentPayIds) do
            XLog.Error(tostring(k))
        end
        --XLog.Error("--------------------------------------------")
    end

    function XPayManager.CheckCanBuy(id)
        local now = XTime.GetServerNowTimestamp()
        local lastBuyTime = CurrentPayIds[id]
        if not lastBuyTime then
            return true
        end

        if now - lastBuyTime > PurchasePayLockGoodsTime then
            CurrentPayIds[id] = nil
            return true
        else
            XUiManager.TipText("PurchaseCurrentPayTips")
            return false
        end
    end

    function XPayManager.Pay(productKey, ptype, params, id, callback)
        if XUserManager.HasLoginError() then -- 临时兼容sdk会回调多次登陆成功的问题
            XUiManager.SystemDialogTip(CS.XTextManager.GetText("TipTitle"), "账号信息过期，请重新登陆", XUiManager.DialogType.OnlySure, nil, function()
                XUserManager.ClearLoginData()
            end)
            return
        end

        if not IsSupportPay() or not PayAgent then
            return
        end

        local template = XPayConfigs.GetPayTemplate(productKey)
        if not template then
            return
        end

        local TargetParam = {}
        TargetParam.TargetType = ptype
        TargetParam.Params = params
        --锁住当前购买id等待支付失败解锁，服务端成功解锁 以及超时解锁
        if ptype then
            XPayManager.SetNearPayId(id)
            XPayManager.PurchasePayLock(id)
        end
        --CheckPoint: APPEVENT_REDEEMED_AND_MONTHCARD
        XAppEventManager.PurchasePayAppLogEvent(template.PayId)

        XNetwork.Call(METHOD_NAME.Initiated, {Key = productKey, TargetParam = TargetParam}, function (res) 
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                if ptype then
                    XPayManager.ClearCurrentPayId(id)
                end
                return
            end

            --BDC
            CS.XHeroBdcAgent.BdcCreateOrder(tostring(template.PayId), template.Type, XTime.GetServerNowTimestamp(), res.GameOrder)
            
            DoPay(productKey, res.GameOrder, template.GoodsId)   
            if callback then
                callback()
            end
        end)
    end

    function XPayManager.PayOfAutoTemplate(payKeySuffix, type, params, callback)
        local productKey = XPayConfigs.GetProductKey(payKeySuffix)
        if not string.IsNilOrEmpty(productKey) then
            local payTemplate = XPayConfigs.GetPayTemplate(productKey)
            if payTemplate then
                if XDataCenter.PayManager.CheckCanBuy(payTemplate.PayId) then --防止重复购买
                    XDataCenter.PayManager.Pay(productKey, type, params, payTemplate.PayId, callback)
                end
            else
                XLog.Error("XPayManager.PayOfAutoTemplate \'payTemplate\' is nil")
            end
        else
            XLog.Error("XPayManager.PayOfAutoTemplate param \'payKeySuffix\' is nil")
        end
    end

    -- 领取首充奖励请求
    function XPayManager.GetFirstPayRewardReq(cb)
        XNetwork.Call(METHOD_NAME.GetFirstPayReward, nil, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            IsGetFirstRechargeReward = true
            if cb then
                cb()
            end
            XUiManager.OpenUiObtain(res.RewardList)
            XEventManager.DispatchEvent(XEventId.EVENT_CARD_REFRESH_WELFARE_BTN)
        end)
    end

    function XPayManager.GetFirstRecharge()
        return IsFirstRecharge
    end

    function XPayManager.GetFirstRechargeReward()
        return IsGetFirstRechargeReward
    end

    -- 是否首充奖励领取
    function XPayManager.IsGotFirstReCharge()
        local isRecharge = XPayManager.GetFirstRecharge()
        if not isRecharge then
            return true
        end

        local isGot = XPayManager.GetFirstRechargeReward()
        return isGot
    end

    -- 是否月卡奖励领取
    function XPayManager.IsGotCard(uiType, id)
        local isBuy = XDataCenter.PurchaseManager.IsYkBuyed(uiType, id)
        if not isBuy then
            return true
        end

        local data = XDataCenter.PurchaseManager.GetYKInfoData(uiType, id)
        return data.IsDailyRewardGet
    end

    function XPayManager.NotifyPayResult(data)
        if not data then return end

        IsFirstRecharge = XPayConfigs.CheckFirstPay(data.TotalPayMoney)
        local orderList = data.DealGameOrderList
        -- 测试充值
        if not orderList or #orderList == 0 then
            return
        end

        PayAgent:OnDealSuccess(orderList)
        XEventManager.DispatchEvent(XEventId.EVENT_CARD_REFRESH_WELFARE_BTN)
    end

    function XPayManager.NotifyPayInfo(data)
        if not data then return end

        IsGetFirstRechargeReward = data.IsGetFirstPayReward
        IsFirstRecharge = XPayConfigs.CheckFirstPay(data.TotalPayMoney)
        XPayManager.TotalPayMoney = data.TotalPayMoney or 0
    end

    DoInit()

    return XPayManager
end

XRpc.NotifyPayResult = function(data)
    -- 测试充值
    -- XLog.Error("充值结果回调--data--Begin")
    -- XLog.Error(data)
    -- XLog.Error("充值结果回调--data--End")
    if not data then return end

    if data.TotalPayMoney and data.TotalPayMoney > 0 then
        if XDataCenter.PayManager.LastTotalPayMoney == nil then
            XDataCenter.PayManager.LastTotalPayMoney = XDataCenter.PayManager.TotalPayMoney
            if XDataCenter.PayManager.LastTotalPayMoney == 0 then
                --CheckPoint: APPEVENT_FIRST_BUY
                XAppEventManager.AppLogEvent(XAppEventManager.CommonEventNameConfig.First_buy)
            end
        end
        --CheckPoint: APPEVENT_PURCHASED
        XAppEventManager.PayAppLogEvent(data.TotalPayMoney - XDataCenter.PayManager.LastTotalPayMoney)
        XDataCenter.PayManager.LastTotalPayMoney = data.TotalPayMoney
    end
    XDataCenter.PayManager.NotifyPayResult(data)
end

XRpc.NotifyPayInfo = function(data)
    XDataCenter.PayManager.NotifyPayInfo(data)
end