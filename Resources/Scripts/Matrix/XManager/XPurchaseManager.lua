XPurchaseManagerCreator = function()
    local XPurchaseManager = {}
    local PurchaseRequest = {
        PurchaseGetDailyRewardReq = "PurchaseGetDailyRewardRequest",
        GetPurchaseListReq = "GetPurchaseListRequest", -- 采购列表请求
        PurchaseReq = "PurchaseRequest", -- 普通采购请求
    }

    local Next = _G.next
    local PurchaseInfosData = {}
    local PurchaseLbRedUiTypes = {}
    local AccumulatedData = {}
    local LBExpireIdKey = "LBExpireIdKey"
    local LBExpireIdDic = nil
    local IsYKShowConitnueBuy = false
    local PurchaseInfoDataDic = {}
    local MutexPurchaseDic = {}

    function XPurchaseManager.Init()
        XPurchaseManager.CurBuyIds = {}
        XPurchaseManager.GiftValidCb = function(uiTypeList, cb) XDataCenter.PurchaseManager.PurchaseGiftValidTimeCb(uiTypeList, cb) end
    end

    -- 按UiTypes取数据
    function XPurchaseManager.GetDatasByUiTypes(uitypes)
        local data = {}
        for _, uitype in pairs(uitypes) do
            table.insert(data, PurchaseInfosData[uitype] or {})
        end

        return data
    end

    -- 判断是否UiTypes都有数据
    function XPurchaseManager.IsHaveDataByUiTypes(uitypes)
        for _, uitype in pairs(uitypes) do
            if not PurchaseInfosData[uitype] then
                return false
            end
        end

        return true
    end

    -- 按UiType取数据
    function XPurchaseManager.GetDatasByUiType(uitype)
        local payuitypes = XPurchaseConfigs.GetPayUiTypes()
        if payuitypes[uitype] then
            return XPayConfigs.GetPayConfig()
        end
        return PurchaseInfosData[uitype]
    end

    function XPurchaseManager.ClearData()
        local uitypes = XPurchaseConfigs.GetYKUiTypes()
        local yktype = nil
        if uitypes and uitypes[1] then
            yktype = uitypes[1]
        end
        if yktype then
            local d = PurchaseInfosData[yktype]
            PurchaseInfosData = {}
            PurchaseInfosData[yktype] = d
        else
            PurchaseInfosData = {}
        end
    end

    -- RPC
    -- // 失效时间
    -- public int TimeToInvalid;
    -- 采购列表请求
    -- public List<XPurchaseClientInfo> PurchaseInfoList;
    function XPurchaseManager.GetPurchaseListRequest(uiTypeList, cb)
        XNetwork.Call(PurchaseRequest.GetPurchaseListReq, { UiTypeList = uiTypeList }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            XPurchaseManager.HandlePurchaseData(uiTypeList, res.PurchaseInfoList)
            if cb then
                cb()
            end
            XEventManager.DispatchEvent(XEventId.EVENT_PURCAHSE_YKMAINREFRESH)
            local LBDicTmp = XPurchaseConfigs.GetLBUiTypesDic()
            local YKDicTmp = XPurchaseConfigs.GetYKUiTypesDic()
            local isLbData = false
            local isYKData = false
            for _,v in pairs(uiTypeList)do
                if not isLbData and LBDicTmp[v] then
                    XEventManager.DispatchEvent(XEventId.EVENT_LB_UPDATE)
                    XEventManager.DispatchEvent(XEventId.EVENT_PURCAHSE_BUYUSERIYUAN)
                    isLbData = true
                end
                if not isYKData and YKDicTmp[v] then
                    XEventManager.DispatchEvent(XEventId.EVENT_YK_UPDATE)
                    isYKData = true
                end
            end
        end)
    end

    -- 处理返回的数据
    function XPurchaseManager.HandlePurchaseData(uiTypeList, purchaseInfoList)
        if not purchaseInfoList then
            return
        end

        for _, uiType in pairs(uiTypeList) do
            PurchaseInfosData[uiType] = {}
            PurchaseInfoDataDic[uiType] = {}
            MutexPurchaseDic[uiType] = {}
        end

        for _, v in pairs(purchaseInfoList) do
            if v.UiType then
                table.insert(PurchaseInfosData[v.UiType], v)
                PurchaseInfoDataDic[v.UiType][v.Id] = v
                --以下用于处理互斥内容
                if v.MutexPurchaseIds and next(v.MutexPurchaseIds) ~= nil then
                    MutexPurchaseDic[v.UiType][v.Id] = v.MutexPurchaseIds
                end
            end
        end
    end

    -- 普通采购请求
    -- public List<XRewardGoods> RewardList;
    function XPurchaseManager.PurchaseRequest(id, cb, count, discountId, uiTypeList)
        if not discountId then -- 等于 -1 为不使用打折券
            discountId = -1
        end
        if not count then -- 默认数量为1
            count = 1
        end
        if count > 1 and discountId ~= -1 then -- 打折券不能使用批量购买
            XUiManager.TipError(CS.XTextManager.GetText("PurchaseErrorCantMultiplyWithDiscount"))
            return
        end
        if not uiTypeList then
            uiTypeList = {}
        end
        XNetwork.Call(PurchaseRequest.PurchaseReq, { Id = id, Count = count, DiscountId = discountId, UiTypeList = uiTypeList }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            XPurchaseManager.CurBuyIds[id] = id

            if res.RewardList and res.RewardList[1] and Next(res.RewardList[1]) then
                XUiManager.OpenUiObtain(res.RewardList)
            else
                XUiManager.TipText("PurchaseLBBuySuccessTips")
            end

            XPurchaseManager.PurchaseSuccess(id, res.PurchaseInfo, res.NewPurchaseInfoList)
            if cb then
                cb(res.RewardList)
            end

            XEventManager.DispatchEvent(XEventId.EVENT_LB_UPDATE)
            XEventManager.DispatchEvent(XEventId.EVENT_CARD_REFRESH_WELFARE_BTN)
        end)
    end

    -- 采购成功修正数据
    function XPurchaseManager.PurchaseSuccess(id, purchaseInfo, newPurchaseInfoList)
        XPurchaseManager.UpdateSingleData(id, purchaseInfo)
        if newPurchaseInfoList and Next(newPurchaseInfoList) then
            local uiTypeList = {}
            for _, v in pairs(newPurchaseInfoList) do
                if nil == uiTypeList[v.UiType] then
                    uiTypeList[v.UiType] = {} 
                end
                table.insert(uiTypeList[v.UiType], v)
            end

            for uiType,purchaseList in pairs(uiTypeList) do
                PurchaseInfosData[uiType] = purchaseList
            end
        end

        local LbExpireIds = XPurchaseManager.GetLbExpireIds()
        if XPurchaseManager.HaveNewPlayerHint(id) then
            LbExpireIds[id] = nil
            XPurchaseManager.SaveLBExpreIds(LbExpireIds)
        end
    end

    function XPurchaseManager.UpdateSingleData(id, purchaseInfo)
        local f = false
        for _, datas in pairs(PurchaseInfosData) do
            for _, data in pairs(datas) do
                if data.Id == id then
                    if (not purchaseInfo or Next(purchaseInfo) == nil) then
                        data.IsSelloutHide = true
                    elseif data.BuyLimitTimes == data.BuyTimes + 1 then
                        data.BuyTimes = data.BuyLimitTimes
                    else
                        XPurchaseManager.SetData(data, purchaseInfo)
                    end
                    f = true
                    break
                end
            end
            if f then
                break
            end
        end
    end

    function XPurchaseManager.SetData(data, purchaseInfo)
        if not purchaseInfo then
            return
        end

        data.TimeToUnShelve = purchaseInfo.TimeToUnShelve
        data.Tag = purchaseInfo.Tag
        data.Priority = purchaseInfo.Priority
        data.Icon = purchaseInfo.Icon
        data.DailyRewardRemainDay = purchaseInfo.DailyRewardRemainDay
        data.UiType = purchaseInfo.UiType
        data.ConsumeId = purchaseInfo.ConsumeId
        data.TimeToShelve = purchaseInfo.TimeToShelve
        data.BuyTimes = purchaseInfo.BuyTimes
        data.Desc = purchaseInfo.Desc
        data.RewardGoodsList = purchaseInfo.RewardGoodsList
        data.BuyLimitTimes = purchaseInfo.BuyLimitTimes
        data.ConsumeCount = purchaseInfo.ConsumeCount
        data.Name = purchaseInfo.Name
        data.TimeToInvalid = purchaseInfo.TimeToInvalid
        data.IsDailyRewardGet = purchaseInfo.IsDailyRewardGet
        data.Id = purchaseInfo.Id
        data.DailyRewardGoodsList = purchaseInfo.DailyRewardGoodsList
        data.FirstRewardGoods = purchaseInfo.FirstRewardGoods
        data.ExtraRewardGoods = purchaseInfo.ExtraRewardGoods
        data.ClientResetInfo = purchaseInfo.ClientResetInfo
        data.IsUseMail = purchaseInfo.IsUseMail or false
        data.PayKeySuffix = purchaseInfo.PayKeySuffix
        data.MailCount = purchaseInfo.MailCount
    end

    -- 领奖(月卡)
    function XPurchaseManager.PurchaseGetDailyRewardRequest(id, cb, failCb)
        XNetwork.Call(PurchaseRequest.PurchaseGetDailyRewardReq, { Id = id }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                if failCb then
                    failCb()
                end
                return
            end

            XPurchaseManager.GetRewardSuccess(id, res.PurchaseInfo)

            if cb then
                cb(res.RewardList)
            end
            -- 设置月卡信息本地缓存
            XPurchaseManager.SetYKLoaclCache()

            XEventManager.DispatchEvent(XEventId.EVENT_CARD_REFRESH_WELFARE_BTN)
        end)
    end

    -- 领奖成功修正数据
    function XPurchaseManager.GetRewardSuccess(id, purchaseInfo)
        XPurchaseManager.UpdateSingleData(id, purchaseInfo)
    end

    -- 请求礼包数据
    function XPurchaseManager.LBInfoDataReq(cb)
        local uiTypeList = XPurchaseConfigs.GetLBUiTypesList()
        XPurchaseManager.GetPurchaseListRequest(uiTypeList, cb)
    end

    -- 请求月卡数据
    function XPurchaseManager.YKInfoDataReq(cb)
        local uiTypeList = XPurchaseConfigs.GetYKUiTypes()
        XPurchaseManager.GetPurchaseListRequest(uiTypeList, cb)
    end

    --这里用于查询互斥的月卡是否已经被购入过
    function XPurchaseManager.CheckMutexPurchaseYKBuy(uiType, id)
        if MutexPurchaseDic[uiType] and MutexPurchaseDic[uiType][id] then
            local MutexPurList = MutexPurchaseDic[uiType][id]
            for _, kId in pairs(MutexPurList) do
                return XPurchaseManager.IsYkBuyed(uiType, kId)
            end
        end
        return false
    end

    -- Get月卡数据
    function XPurchaseManager.GetYKInfoData(uitype, id)
        if PurchaseInfoDataDic[uitype] and PurchaseInfoDataDic[uitype][id] then
            return PurchaseInfoDataDic[uitype][id]
        end

        return nil
    end

    -- 获取当前已购买非邮件发放月卡数据（只能有一种已购买月卡）
    -- 只能写死UiType类型：2
    function XPurchaseManager.GetCurBoughtYKData()
        if PurchaseInfoDataDic[2] and next(PurchaseInfoDataDic[2]) then
            for id, data in pairs(PurchaseInfoDataDic[2]) do
                if not data.IsUseMail and XPurchaseManager.IsYkBuyed(2, id) then
                    return data
                end
            end
        end

        return nil
    end

    -- 是否已经买过了
    function XPurchaseManager.IsYkBuyed(uitype, id)
        local data = XPurchaseManager.GetYKInfoData(uitype, id)
        if not data then
            return false
        end

        return data.DailyRewardRemainDay > 0
    end

    function XPurchaseManager.FreeLBRed()
        if not XPurchaseManager.CurFreeRewardId or not Next(XPurchaseManager.CurFreeRewardId) then
            return false
        end

        if not XPurchaseManager.CurBuyIds or not Next(XPurchaseManager.CurBuyIds) then
            return true
        end

        for _, id in pairs(XPurchaseManager.CurFreeRewardId) do
            if not XPurchaseManager.CurBuyIds[id] then
                return true
            end
        end
        return false
    end

    -- Notify
    function XPurchaseManager.PurchaseDailyNotify(info)
        XPurchaseManager.CurFreeRewardId = {}
        if info and info.FreeRewardInfoList and Next(info.FreeRewardInfoList) then
            for _, v in pairs(info.FreeRewardInfoList) do
                XPurchaseManager.CurFreeRewardId[v.Id] = v.Id
            end
        end

        if info and info.ExpireInfoList and Next(info.ExpireInfoList) then
            XPurchaseManager:UpdatePurchaseGiftValidTime(info.ExpireInfoList)
        end

        -- 处理月卡红点
        if info and info.DailyRewardInfoList and Next(info.DailyRewardInfoList) then
            for _, v in pairs(info.DailyRewardInfoList) do
                if v.Id == XPurchaseConfigs.PurChaseCardId or v.Id == XPurchaseConfigs.PurChaseCardId1 then
                    XDataCenter.PurchaseManager.YKInfoDataReq(function()
                        XEventManager.DispatchEvent(XEventId.EVENT_CARD_REFRESH_WELFARE_BTN)

                        -- 设置月卡信息本地缓存
                        XDataCenter.PurchaseManager.SetYKLoaclCache()
                        XEventManager.DispatchEvent(XEventId.EVENT_DAYLY_REFESH_RECHARGE_BTN)
                    end)
                end
            end
        end
    end

    function XPurchaseManager:UpdatePurchaseGiftValidTime(expireInfoList)
        local uiTypeList = XPurchaseConfigs.GetLBUiTypesList()
        for _, v in pairs(expireInfoList) do
            if v.Id == XPurchaseConfigs.PurChaseCardId then
                XDataCenter.PurchaseManager.YKInfoDataReq(function()
                        XEventManager.DispatchEvent(XEventId.EVENT_CARD_REFRESH_WELFARE_BTN)

                        -- 设置月卡信息本地缓存
                        XDataCenter.PurchaseManager.SetYKLoaclCache()
                        XEventManager.DispatchEvent(XEventId.EVENT_DAYLY_REFESH_RECHARGE_BTN)
                    end)
            end
        end
        if uiTypeList and Next(uiTypeList) ~= nil then
            XPurchaseManager.GetPurchaseListRequest(uiTypeList, function()
                XDataCenter.PurchaseManager.PurchaseGiftValidTimeCb(uiTypeList, expireInfoList)
            end)
        end
    end

    function XPurchaseManager.PurchaseGiftValidTimeCb(uiTypeList, expireInfoList)
        local datas = XPurchaseManager.GetDatasByUiTypes(uiTypeList)
        -- local f = false--是否有一个礼包重新买了。
        local count = 0
        local LbExpireIds = XPurchaseManager.GetLbExpireIds()
        if datas then
            for _, v0 in pairs(expireInfoList) do
                if XPurchaseConfigs.IsLBByPassID(v0.Id) then
                    for _, data in pairs(datas) do
                        for _, v1 in pairs(data) do
                            if v1.Id == v0.Id then
                                if v1.BuyTimes > 0 and v1.DailyRewardRemainDay > 0 then
                                    if XPurchaseManager.HaveNewPlayerHint(v0.Id) then
                                        LbExpireIds[v0.Id] = nil
                                    end
                                else
                                    if not XPurchaseManager.HaveNewPlayerHint(v0.Id) then
                                        LbExpireIds[v0.Id] = v0.Id
                                        count = count + 1
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        XPurchaseManager.SaveLBExpreIds(LbExpireIds)
        XPurchaseManager.ExpireCount = count

        -- local f = count == 0
        -- if not f then
        --     XEventManager.DispatchEvent(XEventId.EVENT_LB_EXPIRE_NOTIFY,count)
        -- end
    end

    function XPurchaseManager.HaveNewPlayerHint(id)
        if not id then
            return false
        end

        local ids = XPurchaseManager.GetLbExpireIds()
        return ids[id] ~= nil
    end

    function XPurchaseManager.SaveLBExpreIds(ids)
        if XPlayer.Id and ids then
            local idsstr = ""
            for _, v in pairs(ids) do
                if v then
                    idsstr = idsstr .. v .. "_"
                end
            end

            local key = string.format("%s_%s", tostring(XPlayer.Id), LBExpireIdKey)
            CS.UnityEngine.PlayerPrefs.SetString(key, idsstr)
            CS.UnityEngine.PlayerPrefs.Save()
            LBExpireIdDic = nil
        end
    end

    function XPurchaseManager.GetLbExpireIds()
        if LBExpireIdDic then
            return LBExpireIdDic
        end

        if XPlayer.Id then
            LBExpireIdDic = {}
            local key = string.format("%s_%s", tostring(XPlayer.Id), LBExpireIdKey)
            if CS.UnityEngine.PlayerPrefs.HasKey(key) then
                local str = CS.UnityEngine.PlayerPrefs.GetString(key) or ""
                for id in string.gmatch(str, "%d+") do
                    local v = tonumber(id)
                    LBExpireIdDic[v] = v
                end
            end
        end

        return LBExpireIdDic
    end

    -- 红点相关
    function XPurchaseManager.LBRedPoint()
        local uiTypeList = XPurchaseConfigs.GetLBUiTypesList()
        local datas = XPurchaseManager.GetDatasByUiTypes(uiTypeList)
        PurchaseLbRedUiTypes = {}
        if datas then
            local f = false
            for _, data in pairs(datas) do
                for _, v in pairs(data) do
                    if v and v.ConsumeCount == 0 and v.PayKeySuffix == nil then
                        local curtime = XTime.GetServerNowTimestamp()
                        if (v.BuyTimes == 0 or v.BuyTimes < v.BuyLimitTimes) and (v.TimeToShelve == 0 or v.TimeToShelve < curtime)
                        and (v.TimeToUnShelve == 0 or v.TimeToUnShelve > curtime) then
                            f = true
                            PurchaseLbRedUiTypes[v.UiType] = v.UiType
                        end
                    end
                end
            end
            return f
        end

        return false
    end

    function XPurchaseManager.LBRedPointUiTypes()
        return PurchaseLbRedUiTypes
    end

    -- 累计充值相关
    function XPurchaseManager.NotifyAccumulatedPayData(info)
        if not info then
            return
        end
        AccumulatedData.PayId = info.PayId or 0--累计充值id
        AccumulatedData.PayMoney = info.PayMoney or 0--累计充值数量
        AccumulatedData.PayRewardIds = {}--已领取的奖励Id
        if info.PayRewardIds then
            for _, id in pairs(info.PayRewardIds) do
                AccumulatedData.PayRewardIds[id] = id
            end
        end
    end

    function XPurchaseManager.IsAccumulateEnterOpen()
        return AccumulatedData.PayId and AccumulatedData.PayId > 0 and XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.PurchaseAdd)
        and not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.PurchaseAdd)
    end

    function XPurchaseManager.NotifyAccumulatedPayMoney(info)
        if not info then
            return
        end

        AccumulatedData.PayMoney = info.PayMoney
        XEventManager.DispatchEvent(XEventId.EVENT_ACCUMULATED_UPDATE)
    end

    -- 累计充值数量
    function XPurchaseManager.GetAccumulatedPayCount()
        return math.floor(AccumulatedData.PayMoney or 0)
    end

    -- 领取累计充值奖励
    function XPurchaseManager.GetAccumulatePayReq(payid, rewardid, cb)
        if not payid or not rewardid then
            return
        end

        XNetwork.Call("GetAccumulatePayRequest", { PayId = payid, RewardId = rewardid }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            AccumulatedData.PayRewardIds[rewardid] = rewardid
            local rewardGoodsList = res.RewardGoodsList
            if rewardGoodsList and Next(rewardGoodsList) then
                XUiManager.OpenUiObtain(rewardGoodsList)
                if cb then
                    cb(rewardGoodsList)
                end
            end
            --CheckPoint: APPEVENT_TOTAL_PURCHASE
            XAppEventManager.AccumulatePayAppLogEvent(rewardid)
            XEventManager.DispatchEvent(XEventId.EVENT_ACCUMULATED_REWARD)
        end
        )
    end

    -- 奖励是否已经领过
    function XPurchaseManager.AccumulateRewardGeted(id)
        if not id then
            return false
        end

        return AccumulatedData.PayRewardIds[id] ~= nil
    end

    -- 取当前累计充值id
    function XPurchaseManager.GetAccumulatePayId()
        return AccumulatedData.PayId
    end

    -- 累计充值奖励
    function XPurchaseManager.GetAccumulatePayConfig()
        local id = AccumulatedData.PayId
        if not id or id < 0 then
            return
        end

        return XPurchaseConfigs.GetAccumulatePayConfigById(id)
    end

    function XPurchaseManager.GetAccumulatePayTimeStr()
        local id = AccumulatedData.PayId
        if not id or id < 0 then
            return
        end

        local config = XPurchaseConfigs.GetAccumulatePayConfigById(id)
        if config.Type == XPurchaseConfigs.PayAddType.Forever then
            return
        end

        local beginTime, endTime = XFunctionManager.GetTimeByTimeId(config.TimeId)
        return XTime.TimestampToGameDateTimeString(beginTime), XTime.TimestampToGameDateTimeString(endTime)
    end

    -- 累计充值奖励红点
    function XPurchaseManager.AccumulatePayRedPoint()
        local id = AccumulatedData.PayId
        if not id or id < 0 then
            return false
        end

        local payconfig = XPurchaseConfigs.GetAccumulatePayConfigById(id)
        if payconfig then
            local rewardsId = payconfig.PayRewardId
            if rewardsId or Next(rewardsId) then
                for _, tmpId in pairs(rewardsId) do
                    local payrewardconfig = XPurchaseConfigs.GetAccumulateRewardConfigById(tmpId)
                    local count = AccumulatedData.PayMoney
                    if payrewardconfig and payrewardconfig.Money then
                        if payrewardconfig.Money <= count then
                            if not XPurchaseManager.AccumulateRewardGeted(tmpId) then
                                return true
                            end
                        end
                    end
                end
            end
        end
        return false
    end

    function XPurchaseManager.PurchaseResponse(data)
        if data.RewardList and data.RewardList[1] and Next(data.RewardList[1]) then
            XUiManager.OpenUiObtain(data.RewardList)
        else
            XUiManager.TipText("PurchaseLBBuySuccessTips")
        end
        if data.PurchaseInfo and (data.PurchaseInfo.UiType == XPurchaseConfigs.YKType.Month) then
            if data and data.PurchaseInfo and data.PurchaseInfo.DailyRewardGoodsList and #data.PurchaseInfo.DailyRewardGoodsList > 0 then
                XDataCenter.PurchaseManager.PurchaseGetDailyRewardRequest(data.Id, function(rewardItems)
                    XUiManager.OpenUiObtain(rewardItems) --海外定制：自动领取月卡时候弹窗
                end)
            end
        end

        XPurchaseManager.PurchaseSuccess(data.Id, data.PurchaseInfo, data.NewPurchaseInfoList)
        XEventManager.DispatchEvent(XEventId.EVENT_CARD_REFRESH_WELFARE_BTN)
        XEventManager.DispatchEvent(XEventId.EVENT_PURCAHSE_BUYUSERIYUAN)
        XEventManager.DispatchEvent(XEventId.EVENT_LB_UPDATE)
        XDataCenter.PayManager.ClearCurrentPayId(data.Id)
    end

    function XPurchaseManager.PurchaseAddRewardState(id)
        if not id then
            return
        end

        local itemData = XPurchaseConfigs.GetAccumulateRewardConfigById(id)
        if not itemData then
            return
        end

        local money = itemData.Money
        local count = XPurchaseManager.GetAccumulatedPayCount()
        if count >= money then
            if not XPurchaseManager.AccumulateRewardGeted(id) then
                --能领，没有领。
                return XPurchaseConfigs.PurchaseRewardAddState.CanGet
            else
                --已经领
                return XPurchaseConfigs.PurchaseRewardAddState.Geted
            end
        else
            --退款
            if XPurchaseManager.AccumulateRewardGeted(id) then
                --已经领
                return XPurchaseConfigs.PurchaseRewardAddState.Geted
            end
            --不能领，钱不够。
            return XPurchaseConfigs.PurchaseRewardAddState.CanotGet
        end
    end

    -- 月卡继续购买红点相关
    function XPurchaseManager.SetYKLoaclCache()
        local data = XPurchaseManager.GetCurBoughtYKData()
        if not data then
            return
        end

        local key = XPrefs.YKLocalCache .. tostring(XPlayer.Id)
        local count = 0
        if CS.UnityEngine.PlayerPrefs.HasKey(key) then
            count = CS.UnityEngine.PlayerPrefs.GetInt(key)
        else
            CS.UnityEngine.PlayerPrefs.SetInt(key, count)
        end

        if data.DailyRewardRemainDay and count ~= data.DailyRewardRemainDay then
            local continueBuyDays = XPurchaseConfigs.PurYKContinueBuyDays
            if data.DailyRewardRemainDay > continueBuyDays then
                CS.UnityEngine.PlayerPrefs.SetInt(key, data.DailyRewardRemainDay)
            end

            if count > 0 and data.DailyRewardRemainDay <= continueBuyDays then
                IsYKShowConitnueBuy = true
            else
                IsYKShowConitnueBuy = false
            end
        end
    end

    -- 检查是否显示购买月卡红点
    function XPurchaseManager.CheckYKContinueBuy()
        if not IsYKShowConitnueBuy then
            return IsYKShowConitnueBuy
        end

        local key = XPrefs.YKContinueBuy .. tostring(XPlayer.Id)
        if CS.UnityEngine.PlayerPrefs.HasKey(key) then
            local time = CS.UnityEngine.PlayerPrefs.GetString(key)
            local now = XTime.GetServerNowTimestamp()
            local todayFreshTime = XTime.GetSeverTodayFreshTime()
            local yesterdayFreshTime = XTime.GetSeverYesterdayFreshTime()
            local tempTime = now >= todayFreshTime and todayFreshTime or yesterdayFreshTime
            return tostring(tempTime) ~= time
        else
            return true
        end
    end

    -- 设置当日购买月卡红点已读
    function XPurchaseManager.SetYKContinueBuy()
        local key = XPrefs.YKContinueBuy .. tostring(XPlayer.Id)
        local now = XTime.GetServerNowTimestamp()
        local todayFreshTime = XTime.GetSeverTodayFreshTime()
        local yesterdayFreshTime = XTime.GetSeverYesterdayFreshTime()
        local tempTime = now >= todayFreshTime and todayFreshTime or yesterdayFreshTime
        CS.UnityEngine.PlayerPrefs.SetString(key, tostring(tempTime))

        local data = XPurchaseManager.GetCurBoughtYKData()
        if not data then
            return
        end

        local cachaeKey = XPrefs.YKLocalCache .. tostring(XPlayer.Id)
        if data.DailyRewardRemainDay <= 0 then
            CS.UnityEngine.PlayerPrefs.SetInt(cachaeKey, data.DailyRewardRemainDay)
        end
    end

    -- 获取折扣值 0-1 的值
    function XPurchaseManager.GetLBDiscountValue(lbData)
        local buyTimes = lbData.BuyTimes
        local normalDiscounts = lbData.NormalDiscounts
        local disCountValue = 1
        if not normalDiscounts or #normalDiscounts <= 0 then
            disCountValue = 1
        else
            for i = buyTimes, 0, -1 do
                local curTimes = i + 1
                if normalDiscounts[curTimes] then
                    disCountValue = normalDiscounts[curTimes] / 10000
                    break
                end
            end
        end

        return disCountValue
    end

    function XPurchaseManager.GetLBCouponDiscountValue(lbData, index)
        if not lbData.DiscountCouponInfos then
            return nil
        end

        if not lbData.DiscountCouponInfos[index] then
            return nil
        end
        
        return lbData.DiscountCouponInfos[index].Value / 10000
    end

    function XPurchaseManager.RemoveNotInTimeDiscountCoupon(lbData)
        if not lbData.DiscountCouponInfos or #lbData.DiscountCouponInfos <= 0 then
            return
        end

        local nowTime = XTime.GetServerNowTimestamp()
        for i=#lbData.DiscountCouponInfos, 1, -1 do
            local startTime = lbData.DiscountCouponInfos[i].BeginTime
            local endTime = lbData.DiscountCouponInfos[i].EndTime
            if nowTime < startTime or nowTime > endTime then
                table.remove(lbData.DiscountCouponInfos, i)
            end
        end
    end

    function XPurchaseManager.GetPurchaseData(uitype, id)
        local payuitypes = XPurchaseConfigs.GetPayUiTypes()
        local infos
        if payuitypes[uitype] then
            infos = XPayConfigs.GetPayConfig()
            for _, v in pairs(infos or {}) do
                if v.Id == id then
                    return v
                end
            end
        end
        infos = PurchaseInfosData[uitype]
        for _, v in pairs(infos or {}) do
            if v.Id == id then
                return v
            end
        end
    end

    function XPurchaseManager.GetPurchaseMaxBuyCount(purchaseData)
        local buyTimes = purchaseData.BuyTimes
        local maxBuyTimes = nil
        if purchaseData.BuyLimitTimes and purchaseData.BuyLimitTimes > 0 then -- 限购数量
            maxBuyTimes = purchaseData.BuyLimitTimes - buyTimes
        end
        
        if purchaseData.NormalDiscounts then -- 存在打折
            local curTimes = buyTimes + 1
            local lastDiscountAreaTimes = 0 -- 下一个打折区间次数
            for times, _ in pairs(purchaseData.NormalDiscounts) do
                if curTimes < times then
                    if lastDiscountAreaTimes == 0 then
                        lastDiscountAreaTimes = times
                    else
                        if lastDiscountAreaTimes > times then
                            lastDiscountAreaTimes = times
                        end
                    end
                end
            end

            if lastDiscountAreaTimes ~= 0 then
                local canBuyCountByDiscount = lastDiscountAreaTimes - curTimes
                if maxBuyTimes > canBuyCountByDiscount then
                    maxBuyTimes = canBuyCountByDiscount
                end
            end
        end

        return maxBuyTimes
    end

    XPurchaseManager.Init()
    return XPurchaseManager
end

XRpc.PurchaseDailyNotify = function(info)
    XDataCenter.PurchaseManager.PurchaseDailyNotify(info)
end

XRpc.NotifyAccumulatedPayData = function(info)
    XDataCenter.PurchaseManager.NotifyAccumulatedPayData(info)
end

XRpc.NotifyAccumulatedPayMoney = function(info)
    XDataCenter.PurchaseManager.NotifyAccumulatedPayMoney(info)
end

XRpc.PurchaseResponse = function(info)
    XDataCenter.PurchaseManager.PurchaseResponse(info)
end
