local ClientConfig = CS.XGame.ClientConfig

local XPurchaseWeekCardData = require("XEntity/XPurchase/XPurchaseWeekCardData")

XPurchaseManagerCreator = function()
    ---@class XPurchaseManager
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
    local IsYKShowContinueBuy = false
    local WeekCardData = {}
    
    local PurchaseSelectionData = nil -- 礼包自选数据，仅UI使用，不长期缓存

    --不显示在研发按钮红点的UiType
    local RejectFreeLBUiType = {
        [13] = true,
    }

    function XPurchaseManager.Init()
        XPurchaseManager.CurBuyIds = {}
        XPurchaseManager.GiftValidCb = function(uiTypeList, cb)
            XDataCenter.PurchaseManager.PurchaseGiftValidTimeCb(uiTypeList, cb)
        end
    end

    function XPurchaseManager.InitPurchaseData(purchaseInfoList)
        if XTool.IsTableEmpty(purchaseInfoList) then
            return
        end

        local uiTypeList = {}
        for _, v in pairs(purchaseInfoList) do
            if v.UiType then
                if not uiTypeList[v.UiType] then
                    uiTypeList[v.UiType] = {}
                end
                table.insert(uiTypeList[v.UiType], v)
            end
        end

        for uiType, purchaseList in pairs(uiTypeList) do
            PurchaseInfosData[uiType] = purchaseList
        end

        -- 设置月卡信息本地缓存
        XDataCenter.PurchaseManager.SetYKLocalCache()
    end

    -- 按UiTypes取数据
    function XPurchaseManager.GetDatasByUiTypes(uiTypes)
        local data = {}
        for _, uiType in pairs(uiTypes) do
            table.insert(data, PurchaseInfosData[uiType] or {})
        end

        return data
    end

    -- 判断是否UiTypes都有数据
    function XPurchaseManager.IsHaveDataByUiTypes(uiTypes)
        for _, uiType in pairs(uiTypes) do
            if XTool.IsTableEmpty(PurchaseInfosData[uiType]) then
                return false
            end
        end

        return true
    end

    -- 按UiType取数据
    -- 可以考虑用GetPurchasePackagesByUiType新接口
    function XPurchaseManager.GetDatasByUiType(uiType)
        local payUiTypes = XPurchaseConfigs.GetPayUiTypes()
        if payUiTypes[uiType] then
            return XPayConfigs.GetPayConfig()
        end
        return PurchaseInfosData[uiType]
    end

    function XPurchaseManager.IsHaveDataByUiType(uiType)
        local datas = XPurchaseManager.GetDatasByUiType(uiType)
        local nowTime = XTime.GetServerNowTimestamp()
        local itemCount = 0

        for _, data in pairs(datas) do
            if data and not data.IsSelloutHide then
                if not (data.TimeToUnShelve > 0 and data.TimeToUnShelve <= nowTime) then--下架了
                    --不显示
                    itemCount = itemCount + 1
                end
            end
        end

        return XTool.IsNumberValid(itemCount)
    end

    function XPurchaseManager.GetPurchaseInfoDataById(id)
        for _, datas in pairs(PurchaseInfosData) do
            for _, data in pairs(datas) do
                if data.Id == id then
                    return data
                end
            end
        end
    end

    function XPurchaseManager.GetPurchasePackageById(id)
        for _, datas in pairs(PurchaseInfosData) do
            for _, data in pairs(datas) do
                if data.Id == id then
                    return XPurchaseManager.CreatePurchasePackage(id, data)
                end
            end
        end
    end

    function XPurchaseManager.GetPurchasePackagesByUiType(uiType)
        local rawDatas = XPurchaseManager.GetDatasByUiType(uiType)
        local results = {}
        local purchasePackage
        for _, data in ipairs(rawDatas) do
            table.insert(results, XPurchaseManager.CreatePurchasePackage(data.Id, data))
        end
        return results
    end

    function XPurchaseManager.ClearData()
        local uiTypes = XPurchaseConfigs.GetYKUiTypes()
        local yktype = nil
        if uiTypes and uiTypes[1] then
            yktype = uiTypes[1]
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
        if XTool.IsTableEmpty(uiTypeList) then
            return
        end
        XNetwork.Call(PurchaseRequest.GetPurchaseListReq, { UiTypeList = uiTypeList }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            XPurchaseManager.HandlePurchaseData(uiTypeList, res.PurchaseInfoList)
            if cb then
                cb()
            end
            local lbcfg = XPurchaseConfigs.GetLBUiTypesDic()
            for _, v in pairs(uiTypeList) do
                if lbcfg[v] then
                    XEventManager.DispatchEvent(XEventId.EVENT_LB_UPDATE)
                    break
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
        end

        for _, v in pairs(purchaseInfoList) do
            if v.UiType then
                table.insert(PurchaseInfosData[v.UiType], v)
            end
        end
    end

    -- 普通采购请求
    -- public List<XRewardGoods> RewardList;
    function XPurchaseManager.PurchaseRequest(id, cb, count, discountId, uiTypeList, randomSelectGoodsIds, selectGroups, selectGroupGoodsIds)
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
        XDataCenter.KickOutManager.Lock(XEnumConst.KICK_OUT.LOCK.RECHARGE)
        
        local reqContent = {
            Id = id, 
            Count = count, 
            DiscountId = discountId, 
            UiTypeList = uiTypeList, 
            RandomSelectGoodsIds = randomSelectGoodsIds,
            SelectGroups = selectGroups,
            SelectGroupGoodsIds = selectGroupGoodsIds,
        }
        
        XNetwork.Call(PurchaseRequest.PurchaseReq, reqContent, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                XDataCenter.KickOutManager.Unlock(XEnumConst.KICK_OUT.LOCK.RECHARGE, true)
                return
            end

            XPurchaseManager.CurBuyIds[id] = id

            XPurchaseManager.PurchaseSuccess(id, res.PurchaseInfo, res.NewPurchaseInfoList)
            
            local commonRewardCount = XTool.GetTableCount(res.RewardList)
            local specialRewardCount = XTool.GetTableCount(res.RewardGoodsListByType)
            
            if commonRewardCount >= 1 or specialRewardCount > 0 then
                -- 福袋道具和其他道具分开两个弹窗
                if not XTool.IsTableEmpty(res.RewardGoodsListByType) then
                    local randomDrawRewardList = {}
                    local otherRewardList = {}
                    local afterSendRewardList = {}

                    for i, v in pairs(res.RewardGoodsListByType) do
                        if v.RewardGoodsType == XPurchaseConfigs.XPurchaseRewardGoodsType.Random then
                            table.insert(randomDrawRewardList, v.RewardGoods)
                            -- 记录福袋奖励重复获得的转换道具
                            if not XTool.IsTableEmpty(v.AfterSendRewardGoods) then
                                for index, afterGoods in pairs(v.AfterSendRewardGoods) do
                                    table.insert(afterSendRewardList, afterGoods)
                                end
                            end
                        else
                            table.insert(otherRewardList, v.RewardGoods)    
                        end
                    end

                    local commonList = XTool.MergeArray(otherRewardList, res.RewardList)
                    
                    local popQueue = {}

                    if not XTool.IsTableEmpty(randomDrawRewardList) then
                        table.insert(popQueue, function()
                            
                            XLuaUiManager.OpenWithCloseCallback("UiPurchaseRandomObtain", function()
                                table.remove(popQueue, 1)
                                if not XTool.IsTableEmpty(popQueue) then
                                    popQueue[1]()
                                end
                            end, randomDrawRewardList, afterSendRewardList)
                            
                        end)
                    end

                    if not XTool.IsTableEmpty(commonList) then
                        table.insert(popQueue, function()
                            XUiManager.OpenUiObtain(commonList, nil, function()
                                XDataCenter.KickOutManager.Unlock(XEnumConst.KICK_OUT.LOCK.RECHARGE, true)
                                XPurchaseManager.OnBuyPurchasePackageCheckSkip(id)
                                table.remove(popQueue, 1)
                                if not XTool.IsTableEmpty(popQueue) then
                                    popQueue[1]()
                                end
                            end, nil, nil, { IsShowGridCommonPanelTag = XPurchaseManager.CheckIsWeekCardInfoData(res.PurchaseInfo)})
                        end)
                    end

                    if not XTool.IsTableEmpty(popQueue) then
                        popQueue[1]()
                    else
                        XDataCenter.KickOutManager.Unlock(XEnumConst.KICK_OUT.LOCK.RECHARGE, true)
                    end
                else
                    XUiManager.OpenUiObtain(res.RewardList, nil, function()
                        XDataCenter.KickOutManager.Unlock(XEnumConst.KICK_OUT.LOCK.RECHARGE, true)
                        XPurchaseManager.OnBuyPurchasePackageCheckSkip(id)
                    end, nil, nil, { IsShowGridCommonPanelTag = XPurchaseManager.CheckIsWeekCardInfoData(res.PurchaseInfo)})
                end
            else
                XUiManager.TipText("PurchaseLBBuySuccessTips")
                XDataCenter.KickOutManager.Unlock(XEnumConst.KICK_OUT.LOCK.RECHARGE, true)
                XPurchaseManager.OnBuyPurchasePackageCheckSkip(id)
            end
            
            
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

            for uiType, purchaseList in pairs(uiTypeList) do
                PurchaseInfosData[uiType] = purchaseList
            end
        end

        local LbExpireIds = XPurchaseManager.GetLbExpireIds()
        if XPurchaseManager.HaveNewPlayerHint(id) then
            LbExpireIds[id] = nil
            XPurchaseManager.SaveLBExpireIds(LbExpireIds)
        end
        if XPurchaseManager.CheckIsWeekCardInfoData(purchaseInfo) then
            XPurchaseManager.SetWeekCardData(purchaseInfo, false)
        end
    end

    function XPurchaseManager.UpdateSingleData(id, purchaseInfo)
        local f = false
        for _, datas in pairs(PurchaseInfosData) do
            for _, data in pairs(datas) do
                if data.Id == id then
                    if (not purchaseInfo or Next(purchaseInfo) == nil) then
                        data.IsSelloutHide = true
                        --elseif data.BuyLimitTimes == data.BuyTimes + 1 then
                        --    data.BuyTimes = data.BuyLimitTimes
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
    end

    -- 领奖(月卡, 周卡)
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

    -- Get月卡数据
    function XPurchaseManager.GetYKInfoData()
        local data = {}
        local uiTypeList = XPurchaseConfigs.GetYKUiTypes()
        if uiTypeList and Next(uiTypeList) then
            for _, uiType in pairs(uiTypeList) do
                table.insert(data, XPurchaseManager.GetDatasByUiType(uiType))
            end
        end

        if not data[1] then
            return nil
        end

        if not data[1][1] then
            return nil
        end

        return data[1][1]
    end

    -- 是否已经买过了
    function XPurchaseManager.IsYkBuyed()
        local data = XPurchaseManager.GetYKInfoData()
        if not data then
            return false
        end

        return data.DailyRewardRemainDay > 0
    end

    function XPurchaseManager.FreeLBRed()
        if not XPurchaseManager.CurFreeRewardId or not Next(XPurchaseManager.CurFreeRewardId) then
            return false
        end

        --if not XPurchaseManager.CurBuyIds or not Next(XPurchaseManager.CurBuyIds) then
        --    return true
        --end

        for _, v in pairs(XPurchaseManager.CurFreeRewardId) do
            if RejectFreeLBUiType[v.UiType] then
                goto continue
            end
            if not XPurchaseManager.CurBuyIds[v.Id] then
                local purchaseData = XPurchaseManager.GetPurchaseData(v.UiType, v.Id)

                if purchaseData and not XPurchaseManager.IsLBLock(purchaseData) then
                    return true
                end
            end
            :: continue ::
        end
        return false
    end

    -- Notify
    function XPurchaseManager.PurchaseDailyNotify(info)
        XPurchaseManager.CurFreeRewardId = {}
        XPurchaseManager.CurBuyIds = {}
        if info and info.FreeRewardInfoList and Next(info.FreeRewardInfoList) then
            for _, v in pairs(info.FreeRewardInfoList) do
                XPurchaseManager.CurFreeRewardId[v.Id] = {
                    Id = v.Id,
                    UiType = v.UiType
                }
            end
        end

        if info and info.ExpireInfoList and Next(info.ExpireInfoList) then
            XPurchaseManager:UpdatePurchaseGiftValidTime(info.ExpireInfoList)
        end

        -- 处理月卡红点
        if info and info.DailyRewardInfoList and Next(info.DailyRewardInfoList) then
            for _, v in pairs(info.DailyRewardInfoList) do
                if v.Id == XPurchaseConfigs.PurChaseCardId then
                    XDataCenter.PurchaseManager.YKInfoDataReq(function()
                        XEventManager.DispatchEvent(XEventId.EVENT_CARD_REFRESH_WELFARE_BTN)

                        -- 设置月卡信息本地缓存
                        XDataCenter.PurchaseManager.SetYKLocalCache()
                    end)
                end
            end
        end

        WeekCardData = {}
        -- 处理周卡数据
        if info and info.PurchaseSignInInfoList and (info.PurchaseSignInInfoList) then
            for _, v in pairs(info.PurchaseSignInInfoList) do
                XDataCenter.PurchaseManager.SetWeekCardData(v, true)
            end
        end

        XEventManager.DispatchEvent(XEventId.EVENT_DAYLY_REFESH_RECHARGE_BTN)
    end

    function XPurchaseManager:UpdatePurchaseGiftValidTime(expireInfoList)
        local uiTypeList = XPurchaseConfigs.GetLBUiTypesList()
        for _, v in pairs(expireInfoList) do
            if v.Id == XPurchaseConfigs.PurChaseCardId then
                XDataCenter.PurchaseManager.YKInfoDataReq(function()
                    XEventManager.DispatchEvent(XEventId.EVENT_CARD_REFRESH_WELFARE_BTN)

                    -- 设置月卡信息本地缓存
                    XDataCenter.PurchaseManager.SetYKLocalCache()
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

        XPurchaseManager.SaveLBExpireIds(LbExpireIds)
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

    function XPurchaseManager.SaveLBExpireIds(ids)
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
                    if v and v.ConsumeCount == 0 then
                        local curtime = XTime.GetServerNowTimestamp()
                        if (v.BuyTimes == 0 or v.BuyTimes < v.BuyLimitTimes) and (v.TimeToShelve == 0 or v.TimeToShelve < curtime) and not XPurchaseManager.IsLBLock(v)
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

    function XPurchaseManager.IsLBHave(lbData)
        if lbData.RewardGoodsList then
            if XRewardManager.CheckRewardGoodsListIsOwnForPackage(lbData.RewardGoodsList) then
                return true
            end

            -- v1.31非折价礼包：拥有涂装之后，ConvertSwitch价格不变/价位变为0元
            local isHaveFashion = XRewardManager.CheckRewardGoodsListIsOwnForPackage({ lbData.RewardGoodsList[1] })
            if isHaveFashion and (lbData.ConvertSwitch == lbData.ConsumeCount or lbData.ConvertSwitch == 0) then
                return true
            end
        end
        return false
    end
    
    --- 礼包是否锁定：prepurchaseId未购买完或condition不通过
    function XPurchaseManager.IsLBLock(lbData)
        if XTool.IsNumberValid(lbData.PrePurchaseId) then
            --- 如果前置礼包数据不存在，则认为是因锁定而未下发（因为客户端无法读配置，依赖服务端，无法判断是否是因为所属UiType未请求）
            local prelbData = XPurchaseManager.GetPurchasePackageById(lbData.PrePurchaseId)
            if not prelbData then
                return true, XUiHelper.GetText('PurchasePrePurchaseEmptyTips')
            elseif prelbData.BuyTimes <= 0 then
                return true, XUiHelper.GetText('PurchasePrePurchaseBuyTips', prelbData.Name)
            end
        end

        if not XTool.IsTableEmpty(lbData.Conditions) then
            for i, v in pairs(lbData.Conditions) do
                if not XConditionManager.CheckCondition(v) then
                    return true, XConditionManager.GetConditionDescById(v)
                end
            end
        end
        
        return false
    end

    -- 累计充值相关
    function XPurchaseManager.NotifyAccumulatedPayData(info)
        if not info then
            return
        end
        AccumulatedData.PayId = info.PayId or 0--累计充值id
        AccumulatedData.PayMoney = info.PayMoney or 0--累计充值数量
        AccumulatedData.PayRewardIds = {}--已领取的奖励Id
        AccumulatedData.ExtraRewardIds = {}
        if info.PayRewardIds then
            for _, id in pairs(info.PayRewardIds) do
                AccumulatedData.PayRewardIds[id] = id
            end
        end
        if info.ExtraPayRewardIds then
            for _, id in pairs(info.ExtraPayRewardIds) do
                AccumulatedData.ExtraRewardIds[id] = id
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
    function XPurchaseManager.GetAccumulatePayReq(payId, rewardId, cb)
        if not payId or not rewardId then
            return
        end

        XNetwork.Call("GetAccumulatePayRequest", { PayId = payId, RewardId = rewardId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local extraRewardId = res.ExtraPayRewardId or 0
            local rewardGoodsList = res.RewardGoodsList

            AccumulatedData.PayRewardIds[rewardId] = rewardId
            AccumulatedData.ExtraRewardIds[extraRewardId] = extraRewardId
            if rewardGoodsList and Next(rewardGoodsList) then
                XUiManager.OpenUiObtain(rewardGoodsList)
                if cb then
                    cb(rewardGoodsList)
                end
            end
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

    function XPurchaseManager.AccumulateExtraRewardGeted(id)
        if not id then
            return false
        end

        return AccumulatedData.ExtraRewardIds[id] ~= nil
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
        if XDataCenter.UiPcManager.IsPc() then
            return false
        end

        local id = AccumulatedData.PayId
        if not id or id < 0 then
            return false
        end

        local payConfig = XPurchaseConfigs.GetAccumulatePayConfigById(id)
        if payConfig then
            local rewardsId = payConfig.PayRewardId
            if rewardsId or Next(rewardsId) then
                for _, tmpId in pairs(rewardsId) do
                    local payRewardConfig = XPurchaseConfigs.GetAccumulateRewardConfigById(tmpId)
                    local extraRewardId = payRewardConfig.ExtraPayRewardId
                    local count = AccumulatedData.PayMoney
                    if payRewardConfig and payRewardConfig.Money then
                        if payRewardConfig.Money <= count then
                            if not XPurchaseManager.AccumulateRewardGeted(tmpId)
                                    or not XPurchaseManager.AccumulateExtraRewardGeted(extraRewardId) then
                                return true
                            end
                        end
                    end
                end
            end
        end
        return false
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

    function XPurchaseManager.PurchaseAddExtraRewardState(id)
        if not id then
            return
        end

        local itemData = XPurchaseConfigs.GetAccumulateRewardConfigById(id)

        if not itemData then
            return
        end

        local extraId = itemData.ExtraPayRewardId
        local money = itemData.Money
        local count = XPurchaseManager.GetAccumulatedPayCount()

        if count >= money then
            if not XPurchaseManager.AccumulateExtraRewardGeted(extraId) then
                --能领，没有领。
                return XPurchaseConfigs.PurchaseRewardAddState.CanGet
            else
                --已经领
                return XPurchaseConfigs.PurchaseRewardAddState.Geted
            end
        else
            --退款
            if XPurchaseManager.AccumulateExtraRewardGeted(extraId) then
                --已经领
                return XPurchaseConfigs.PurchaseRewardAddState.Geted
            end
            --不能领，钱不够。
            return XPurchaseConfigs.PurchaseRewardAddState.CanotGet
        end
    end

    -- 月卡继续购买红点相关
    function XPurchaseManager.SetYKLocalCache()
        local data = XPurchaseManager.GetYKInfoData()
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

        --if data.DailyRewardRemainDay and count ~= data.DailyRewardRemainDay then
        if XTool.IsNumberValid(data.DailyRewardRemainDay) then
            local continueBuyDays = XPurchaseConfigs.PurYKContinueBuyDays
            --if data.DailyRewardRemainDay > continueBuyDays then
            CS.UnityEngine.PlayerPrefs.SetInt(key, data.DailyRewardRemainDay)
            --end

            if count > 0 and data.DailyRewardRemainDay <= continueBuyDays then
                IsYKShowContinueBuy = true
            else
                IsYKShowContinueBuy = false
            end
        end
    end

    -- 检查是否显示购买月卡红点
    function XPurchaseManager.CheckYKContinueBuy()
        if not IsYKShowContinueBuy then
            return IsYKShowContinueBuy
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

        local data = XPurchaseManager.GetYKInfoData()
        if not data then
            return
        end

        local cacheKey = XPrefs.YKLocalCache .. tostring(XPlayer.Id)
        if data.DailyRewardRemainDay <= 0 then
            CS.UnityEngine.PlayerPrefs.SetInt(cacheKey, data.DailyRewardRemainDay)
        end
    end

    --region 周卡
    -- 通过推送初始化周卡数据
    function XPurchaseManager.SetWeekCardData(data, isNotify)
        local weekCardData = WeekCardData[data.Id]
        if not weekCardData then
            weekCardData = XPurchaseWeekCardData.New()
        end
        weekCardData:UpdateData(data, isNotify)
        WeekCardData[data.Id] = weekCardData

        XEventManager.DispatchEvent(XEventId.EVENT_WEEK_CARD_DATA_NOTIFY, weekCardData)
    end

    -- 存在PurchaseSignInInfo字段说明是周卡或n天卡礼包
    function XPurchaseManager.CheckIsWeekCardInfoData(purchasePackageInfo)
        if not purchasePackageInfo then
            return false
        end
        return purchasePackageInfo.PurchaseSignInInfo ~= nil
    end

    function XPurchaseManager.GetWeekCardData(id)
        return WeekCardData[id]
    end

    function XPurchaseManager.GetWeekCardDataBySignInId(signInId)
        for _, data in pairs(WeekCardData) do
            if signInId == data:GetPurchaseSignInId() then
                return data
            end
        end
    end

    function XPurchaseManager.GetWeekCardDatas()
        return WeekCardData
    end

    function XPurchaseManager.SetWeekCardContinueBuyCache()
        local key = XPrefs.WeekCardContinueBuy .. tostring(XPlayer.Id)
        local now = XTime.GetServerNowTimestamp()
        local todayFreshTime = XTime.GetSeverTodayFreshTime()
        local yesterdayFreshTime = XTime.GetSeverYesterdayFreshTime()
        local tempTime = now >= todayFreshTime and todayFreshTime or yesterdayFreshTime
        XSaveTool.SaveData(key, tempTime)
    end

    function XPurchaseManager.CheckWeekCardContinueBuy()
        local isDisposed = false
        local key = XPrefs.WeekCardContinueBuy .. tostring(XPlayer.Id)
        local cacheTime = XSaveTool.GetData(key)
        if cacheTime then
            local now = XTime.GetServerNowTimestamp()
            local todayFreshTime = XTime.GetSeverTodayFreshTime()
            local yesterdayFreshTime = XTime.GetSeverYesterdayFreshTime()
            local tempTime = now >= todayFreshTime and todayFreshTime or yesterdayFreshTime
            isDisposed = tempTime == cacheTime
        else
            isDisposed = false
        end

        if isDisposed then
            -- 判断今天点过一次终端跳转
            return false
        end

        for _, data in pairs(WeekCardData) do
            if XPurchaseManager.CheckWeekCardPurchasePackageCanRenew(data) then
                return true, data
            end
        end

        return false
    end

    -- 检查周卡（n天卡）礼包是否还能继续续费
    function XPurchaseManager.CheckWeekCardPurchasePackageCanRenew(weekCardData)
        local repurchaseRemainDays = ClientConfig:GetInt("WeekCardTipRepurchaseRemainDays")
        -- 当前周卡剩余不足n天
        if weekCardData:GetDailyRewardRemainDay() <= repurchaseRemainDays then
            local purchasePackageId = weekCardData:GetId()
            if not XTool.IsNumberValid(purchasePackageId) then
                return false
            end

            local purchasePackageData = XPurchaseManager.GetPurchaseInfoDataById(purchasePackageId)
            if not purchasePackageData then
                return false
            end

            -- 判断礼包是否还能购买(购买次数,时间)
            if purchasePackageData.BuyTimes < purchasePackageData.BuyLimitTimes and purchasePackageData.TimeToInvalid > XTime.GetServerNowTimestamp() then
                return true
            end
        end
        
        return false
    end
    --endregion

    function XPurchaseManager.OnBuyPurchasePackageCheckSkip(id)
        -- 可能有的礼包买空了数据会移除，考虑后续兼容
        local purchaseInfoData = XPurchaseManager.GetPurchaseInfoDataById(id)
        if not purchaseInfoData then
            return
        end

        if not XTool.IsNumberValid(purchaseInfoData.SkipId) then
            if id == XPurchaseConfigs.YKID and not purchaseInfoData.IsDailyRewardGet then
                XLuaUiManager.Open("UiSignCardPopup")
            end
            return
        end

        if XPurchaseManager.CheckIsWeekCardInfoData(purchaseInfoData) then
            if WeekCardData[id] then
                if not WeekCardData[id]:GetIsGotToday() then
                    XFunctionManager.SkipInterface(purchaseInfoData.SkipId)
                end
            end
        else
            XFunctionManager.SkipInterface(purchaseInfoData.SkipId)
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
        for i = #lbData.DiscountCouponInfos, 1, -1 do
            local startTime = lbData.DiscountCouponInfos[i].BeginTime
            local endTime = lbData.DiscountCouponInfos[i].EndTime
            if nowTime < startTime or nowTime > endTime then
                table.remove(lbData.DiscountCouponInfos, i)
            end
        end
    end

    function XPurchaseManager.GetPurchaseData(uiType, id)
        local payUiTypes = XPurchaseConfigs.GetPayUiTypes()
        local infos
        if payUiTypes[uiType] then
            infos = XPayConfigs.GetPayConfig()
            for _, v in pairs(infos or {}) do
                if v.Id == id then
                    return v
                end
            end
        end
        infos = PurchaseInfosData[uiType]
        for _, v in pairs(infos or {}) do
            if v.Id == id then
                return v
            end
        end
    end

    function XPurchaseManager.GetPayConfigByDifferenceCount(payCount)
        local configs = XPayConfigs.GetPayConfig()
        local maxValue = math.huge
        local result = nil
        local index = 0

        for i = 1, #configs do
            local config = configs[i]
            if payCount <= config.Amount and maxValue > config.Amount then
                maxValue = config.Amount
                result = config
                index = i
            end
        end

        if not result then
            result = configs[#configs]
            for i = 1, #configs - 1 do
                if result.Amount < configs[i].Amount then
                    result = configs[i]
                    index = i
                end
            end

            return result, index
        end

        return result, index
    end

    function XPurchaseManager.GetPurchaseDataById(id)
        local payInfos = XPayConfigs.GetPayConfig()
        for _, v in pairs(payInfos or {}) do
            if v.Id == id then
                return v
            end
        end
        for _, list in pairs(PurchaseInfosData or {}) do
            for _, v in pairs(list or {}) do
                if v.Id == id then
                    return v
                end
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

    function XPurchaseManager.OpenYKPackageBuyUi(notEnoughCb, beforeBuyCb, buyFinishedCb)
        local callback = function()
            local data = XPurchaseManager.GetPurchasePackageById(XPurchaseConfigs.YKID)
            if data:GetCurrentBuyTime() > 0 then
                local clientResetInfo = data:GetClientResetInfo()
                if not (clientResetInfo and clientResetInfo.DayCount >= data:GetDailyRewardRemainDay()
                        and data:GetCurrentBuyTime() < data:GetBuyLimitTime()) then
                    XUiManager.TipText("PurchaseNotBuy")
                    return
                end
            end
            XPurchaseManager.OpenPurchaseBuyUiByPurchasePackage(data, notEnoughCb, beforeBuyCb, buyFinishedCb)
        end
        XPurchaseManager.RequestUpdateDataByTabType(XPurchaseConfigs.TabsConfig.YK, callback)
    end

    ---@param data XPurchasePackage
    function XPurchaseManager.OpenPurchaseBuyUiByPurchasePackage(data, notEnoughCb, beforeBuyCb, buyFinishedCb)
        local templateId, isWeaponFashion = data:CheckIsSingleFashion()
        
        local isSingleScene, sceneId = data:CheckIsSingleScene()
        
        -- 皮肤礼包特殊处理
        if templateId and data:GetUiType() == XPurchaseConfigs.UiType.CoatingLB then
            local buyData = data:GetUiFashionDetailBuyData(buyFinishedCb, notEnoughCb)
            -- v3.1兼容跳转其他界面完成购买后，返回此界面时的刷新
            buyData.PurchaseLBUpdateCb = buyFinishedCb
            -- 从推荐页跳转需要购买冷却
            XLuaUiManager.Open("UiFashionDetail", templateId, isWeaponFashion, buyData, nil, true)
        else
            local mergeBeforeBuyCb = function(successCb)
                data:HandleBeforeBuy(successCb)
                if beforeBuyCb then
                    beforeBuyCb(successCb)
                end
            end
            local mergeBuyFinishedCb = function(rewardList)
                data:HandleBuyFinished(rewardList)
                if buyFinishedCb then
                    buyFinishedCb(rewardList)
                end
                if data:GetId() == XPurchaseConfigs.YKID then
                    XEventManager.DispatchEvent(XEventId.EVENT_VIP_CARD_BUY_SUCCESS)
                end
            end
            local mergeCheckBuy = function(count, disCountCouponIndex)
                return data:CheckCanBuy(count, disCountCouponIndex, notEnoughCb)
            end

            if isSingleScene and XTool.IsNumberValid(sceneId) and data:GetUiType() == XPurchaseConfigs.UiType.Scene then
                XLuaUiManager.Open('UiPurchaseSceneTip', sceneId, nil, data.Data, mergeCheckBuy, mergeBuyFinishedCb, mergeBeforeBuyCb)
            else
                XLuaUiManager.Open("UiPurchaseBuyTips", data:GetRawData(), mergeCheckBuy
                , mergeBuyFinishedCb, mergeBeforeBuyCb, data:GetUiTypes())
            end

               
        end

    end
    
    ---@param data @服务端下发的XPurchaseClientInfo数据
    function XPurchaseManager.OpenPurchaseBuyUiByClientInfo(data, checkCb, finishCb, beforeBuyCb, uiTypes)
        local uiType = data.UiType
        local isSingleGoods = XTool.GetTableCount(data.RewardGoodsList) == 1

        -- 场景礼包单物品特殊界面
        if uiType == XPurchaseConfigs.UiType.Scene then
            if isSingleGoods then
                local templateId = data.RewardGoodsList[1].TemplateId
                XLuaUiManager.Open('UiPurchaseSceneTip', templateId, nil, data, checkCb, finishCb, beforeBuyCb, uiTypes)
                return
            end
        end
        
        -- 通用界面
        XLuaUiManager.Open("UiPurchaseBuyTips", data, checkCb, finishCb, beforeBuyCb, uiTypes)
    end

    function XPurchaseManager.RequestUpdateDataByTabType(tabType, callback)
        local uiTypes = {}
        local configs = XPurchaseConfigs.GetUiTypesByTab(tabType)
        for _, config in pairs(configs) do
            table.insert(uiTypes, config.UiType)
        end
        XPurchaseManager.GetPurchaseListRequest(uiTypes, callback)
    end

    function XPurchaseManager.GetYKTabPurchasePackages()
        local uiTypes = XPurchaseConfigs.GetUiTypesByTab(XPurchaseConfigs.TabsConfig.YK)
        local result = {}
        for _, v in ipairs(uiTypes) do
            result = appendArray(result, XPurchaseManager.GetPurchasePackagesByUiType(v.UiType))
        end
        return result
    end

    local PurchasePackageId2Class = {
        [XPurchaseConfigs.YKID] = require("XEntity/XPurchase/XYKPurchasePackage")
    }
    function XPurchaseManager.CreatePurchasePackage(id, data)
        local result = nil
        local class = PurchasePackageId2Class[id]
        if class == nil then
            class = require("XEntity/XPurchase/XPurchasePackage")
        end
        result = class.New(id)
        result:InitWithServerData(data)
        return result
    end

    ---@return XPurchaseRecommendManager
    function XPurchaseManager.GetRecommendManager()
        if XPurchaseManager.__RecommendManager == nil then
            local class = require("XEntity/XPurchase/XPurchaseRecommendManager")
            XPurchaseManager.__RecommendManager = class.New()
        end
        return XPurchaseManager.__RecommendManager
    end
    
    --region 3.0新增自选礼包
    
    --- 自选、福袋礼包选择情况界面临时缓存
    function XPurchaseManager.InitPurchaseSelectionData()
        PurchaseSelectionData = require('XEntity/XPurchase/XPurchaseSelectionData').New()
    end
    
    function XPurchaseManager.GetPurchaseSelectionData()
        return PurchaseSelectionData
    end

    function XPurchaseManager.SetRandomChoice(templateId, isJoin)
        if PurchaseSelectionData then
            PurchaseSelectionData:SetRandomChoice(templateId, isJoin)
        end
    end

    function XPurchaseManager.SetSelfChoice(groupId, templateId)
        if PurchaseSelectionData then
            PurchaseSelectionData:SetSelfChoice(groupId, templateId)
        end
    end

    function XPurchaseManager.CheckRandomChoiceIsSelect(templateId)
        if PurchaseSelectionData then
            return PurchaseSelectionData:CheckRandomChoiceIsSelect(templateId)
        end
        return false
    end

    function XPurchaseManager.CheckSelfChoiceIsSelect(groupId, templateId)
        if PurchaseSelectionData then
            return PurchaseSelectionData:CheckSelfChoiceIsSelect(groupId, templateId)
        end
        return false
    end
    
    function XPurchaseManager.ClearRandomBoxChoices()
        if PurchaseSelectionData then
            PurchaseSelectionData:ClearRandomBoxChoices()
        end
    end
    
    function XPurchaseManager.ClearPurchaseSelectionData()
        if PurchaseSelectionData then
            PurchaseSelectionData = nil
        end
    end
    
    function XPurchaseManager.CheckNeedForcePopTips()
        -- 每个版本只提示一次
        if XSaveTool.GetData('LastPurchaseRandomTipsForcePop') == CS.XRemoteConfig.ApplicationVersion then
            return false
        end
        
        XSaveTool.SaveData('LastPurchaseRandomTipsForcePop', CS.XRemoteConfig.ApplicationVersion)
        
        return true
    end
    --endregion

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

XRpc.NotifyPurchaseRecommendConfig = function(data)
    local purchaseRecommendManager = XDataCenter.PurchaseManager.GetRecommendManager()
    purchaseRecommendManager:AddOrModifyRecommendConfigs(data.Data.AddOrModifyConfigs)
    purchaseRecommendManager:DeleteRecommendConfigs(data.Data.RemoveIds)
    XEventManager.DispatchEvent(XEventId.EVENT_DAYLY_REFESH_RECHARGE_BTN)
end