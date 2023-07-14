XLottoManagerCreator = function()
    local XLottoGroupEntity = require("XEntity/XLotto/XLottoGroupEntity")
    local XLottoManager = {}
    local GET_LOTTO_DATA_INTERVAL = 10
    local LastGetLottoRewardInfoTimes = 0
    local LottoGroupDataDic = {}
    
    local METHOD_NAME = {
        LottoInfoRequest = "LottoInfoRequest",
        LottoRequest = "LottoRequest",
        LottoBuyTicketRequest = "LottoBuyTicketRequest",
    }
    
    function XLottoManager.Init()
        
    end
    
    function XLottoManager.GetLottoGroupDataList()
        local list = {}
        for _,groupData in pairs(LottoGroupDataDic or {}) do
            table.insert(list,groupData)
        end
        
        table.sort(list, function (a, b)
            return a:GetPriority() < b:GetPriority()
        end)
        
        return list
    end
    
    function XLottoManager.UpdateLottoGroupData(lottoDrawInfoList)
        local tmpInfoList = {}
        LottoGroupDataDic = {}
        for _,drawInfo in pairs(lottoDrawInfoList or {}) do
            local drawCfg = XLottoConfigs.GetLottoCfgById(drawInfo.Id)
            if drawCfg then
                LottoGroupDataDic[drawCfg.LottoGroupId] = LottoGroupDataDic[drawCfg.LottoGroupId] or XLottoGroupEntity.New(drawCfg.LottoGroupId)
                tmpInfoList[drawCfg.LottoGroupId] = tmpInfoList[drawCfg.LottoGroupId] or {}
                table.insert(tmpInfoList[drawCfg.LottoGroupId],drawInfo)
            end
        end
        
        for groupId,infoList in pairs(tmpInfoList or {}) do
            table.sort(infoList, function (a, b)
                return a.Priority < b.Priority
            end)
            LottoGroupDataDic[groupId]:UpdateData({DrawInfoList = infoList})
        end
    end
    
    function XLottoManager.UpdateLottoDrawData(lottoDrawId, data)
        local drawCfg = XLottoConfigs.GetLottoCfgById(lottoDrawId)
        if drawCfg then
            local drawData = LottoGroupDataDic[drawCfg.LottoGroupId]:GetDrawData()
            local rewardList = drawData:GetLottoRewardList()
            table.insert(rewardList, data.LottoRewardId)
            local tmpData = {}
            tmpData.ExtraRewardState = data.ExtraRewardState
            tmpData.LottoRecords = data.LottoRecords
            tmpData.LottoRewards = rewardList
            drawData:UpdateData(tmpData)
        end
    end
    
    function XLottoManager.GetLottoRewardInfoRequest(cb)
        local now = XTime.GetServerNowTimestamp()
        if LastGetLottoRewardInfoTimes and now - LastGetLottoRewardInfoTimes <= GET_LOTTO_DATA_INTERVAL then
            if cb then cb() end
            return
        end
        XNetwork.Call(METHOD_NAME.LottoInfoRequest, {}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    if cb then cb() end
                    return
                end
                XLottoManager.UpdateLottoGroupData(res.LottoInfos)
                LastGetLottoRewardInfoTimes = XTime.GetServerNowTimestamp()
                if cb then cb() end
            end)
    end

    function XLottoManager.DoLotto(lottoId, cb, errorCb)
        XNetwork.Call(METHOD_NAME.LottoRequest, { Id = lottoId }, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    if errorCb then errorCb() end
                    return
                end
                XLottoManager.UpdateLottoDrawData(lottoId, res)
                if cb then cb(res.RewardList, res.ExtraRewardList) end
            end)
    end
    
    function XLottoManager.BuyTicket(lottoId, BuyTicketRuleId, ticketKey, cb)
        XNetwork.Call(METHOD_NAME.LottoBuyTicketRequest, { LottoId = lottoId, TicketId = BuyTicketRuleId, TicketKey = ticketKey}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                local reward = XRewardManager.CreateRewardGoodsByTemplate({ TemplateId = res.ItemId, Count = res.ItemCount })
                if cb then cb({reward}) end
            end)
    end

    XLottoManager.Init()
    return XLottoManager
end