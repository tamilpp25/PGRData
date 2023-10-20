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
            PayAgent = XPayAgent.New(XPlayer.Id)
            -- else

        end
    end

    local function DoInit()
        XEventManager.AddEventListener(XEventId.EVENT_LOGIN_SUCCESS, function()
            InitAgent()
        end)
    end

    local DoPay = function(productKey, cpOrderId, goodsId)
        PayAgent:Pay(productKey, cpOrderId, goodsId)
    end

    function XPayManager.Pay(productKey)
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

        XDataCenter.KickOutManager.Lock(XEnumConst.KICK_OUT.LOCK.RECHARGE)
        XNetwork.Call(METHOD_NAME.Initiated, { Key = productKey }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                XDataCenter.KickOutManager.Unlock(XEnumConst.KICK_OUT.LOCK.RECHARGE, true)
                return
            end
            --BDC
            CS.XHeroBdcAgent.BdcCreateOrder(template.GoodsId, productKey, XTime.GetServerNowTimestamp(), res.GameOrder)
            DoPay(productKey, res.GameOrder, template.GoodsId)
        end)
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
    function XPayManager.IsGotCard()
        local isBuy = XDataCenter.PurchaseManager.IsYkBuyed()
        if not isBuy then
            return true
        end

        local data = XDataCenter.PurchaseManager.GetYKInfoData()
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
    end

    DoInit()

    return XPayManager
end

XRpc.NotifyPayResult = function(data)
    -- 测试充值
    XDataCenter.PayManager.NotifyPayResult(data)
end

XRpc.NotifyPayInfo = function(data)
    XDataCenter.PayManager.NotifyPayInfo(data)
end