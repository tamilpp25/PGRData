XGachaManagerCreator = function()
    local GET_GACHA_DATA_INTERVAL = 15
    local XGachaManager = {}
    local GachaRewardInfos = {}
    local GachaProbShows = {}
    local GachaLogList = {}
    local LastGetGachaRewardInfoTimes = {}
    local CurCountOfAll = 0
    local MaxCountOfAll = 0
    local IsInfinite = false
    local ParseToTimestamp = XTime.ParseToTimestamp 

    -- 卡池组状态
    -- Key:number OrganizeId
    -- Value:Table { gachaId = XGachaConfigs.OrganizeGachaStatus }
    local GachaOrganizeStatus = {}

    local METHOD_NAME = {
        GetGachaInfo = "GetGachaInfoRequest",
        Gacha = "GachaRequest",
        GetGachaOrganizeInfo = "GetGachaOrganizeInfoRequest",
    }

    function XGachaManager.Init()
        XGachaManager.SetGachaRewardInfo()
        XGachaManager.SetGachaProbShowInfo()
    end

    function XGachaManager.GetGachaRewardInfoById(gaChaId)
        local gachaCfg = XGachaConfigs.GetGachas()
        MaxCountOfAll = 0
        CurCountOfAll = 0
        IsInfinite = false
        local groupIdList = {}
        for _, groupId in pairs(gachaCfg[gaChaId].GroupId) do
            table.insert(groupIdList, groupId)
        end

        local list = {}
        for _, v in pairs(GachaRewardInfos) do
            for _, groupId in pairs(groupIdList) do
                if v.GroupId == groupId then
                    table.insert(list, v)
                    break
                end
            end

        end
        for _, v in pairs(list) do
            if v.RewardType == XGachaConfigs.RewardType.NotCount then
                IsInfinite = true
            end
            MaxCountOfAll = MaxCountOfAll + v.UsableTimes
            CurCountOfAll = CurCountOfAll + (v.UsableTimes - v.CurCount)
        end

        table.sort(list, function(a, b)
            if a.Priority == b.Priority then
                return a.Id < b.Id
            else
                return a.Priority > b.Priority
            end
        end)
        return list
    end
    
    function XGachaManager.GetGachaProbShowById(gaChaId)
        local gachaProbShowInfo = GachaProbShows[gaChaId]
        if gachaProbShowInfo then
            table.sort(gachaProbShowInfo, function(a, b)
                    if a.IsRare == b.IsRare then
                        return a.Id < b.Id
                    else
                        return a.IsRare == XGachaConfigs.RareType.Rare
                    end
                end)
        else
            XLog.Error("ProbShows's Data Is Null By GachaId :"..gaChaId)
        end
        
        return gachaProbShowInfo
    end

    function XGachaManager.GetCurCountOfAll()
        return CurCountOfAll
    end

    function XGachaManager.GetMaxCountOfAll()
        return MaxCountOfAll
    end
    
    function XGachaManager.GetIsInfinite()
        return IsInfinite
    end

    function XGachaManager.GetGachaLogById(gachaId)
        return GachaLogList[gachaId] or {}
    end

    ---
    ---@param notCheckDraw boolean 是否检测活动研发功能开启，true:不检测，false:检测
    function XGachaManager.CheckGachaIsOpenById(id, IsShowText, notCheckDraw)
        if IsShowText then
            if not notCheckDraw and not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ActivityDrawCard) then
                return false
            end
        else
            if not notCheckDraw and not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.ActivityDrawCard) then
                return false
            end
        end

        local gachaCfg = XGachaConfigs.GetGachas()
        
        if not gachaCfg[id] then
            XLog.Error("GachaId Is Not Exist :"..id)
           return false
        end
        
        local nowTime = XTime.GetServerNowTimestamp()
        local startTime = ParseToTimestamp(gachaCfg[id].StartTimeStr)
        local endTime = ParseToTimestamp(gachaCfg[id].EndTimeStr)
        local IsClose = nowTime > endTime
        local IsNotOpen = startTime > nowTime
        if IsShowText and IsNotOpen then
            local str = CS.XTextManager.GetText("GachaIsNotOpen", gachaCfg[id].StartTimeStr, gachaCfg[id].EndTimeStr)
            XUiManager.TipMsg(str)
        end
        if IsShowText and IsClose then
            XUiManager.TipText("GachaIsClose")
        end
        return (not IsClose) and (not IsNotOpen)
    end

    ---
    --- 检测扭蛋组是否开启
    function XGachaManager.CheckGachaOrganizeIsOpen(organizeId, isShowText)
        local startTimeStr, endTimeStr = XGachaConfigs.GetOrganizeTime(organizeId)
        if not startTimeStr or not endTimeStr then
            return false
        end

        local nowTime = XTime.GetServerNowTimestamp()
        local startTime = ParseToTimestamp(startTimeStr)
        local endTime = ParseToTimestamp(endTimeStr)

        local IsNotOpen = startTime > nowTime
        if isShowText and IsNotOpen then
            local str = CS.XTextManager.GetText("GachaIsNotOpen", startTimeStr, endTimeStr)
            XUiManager.TipMsg(str)
        end

        local IsClose = nowTime > endTime
        if isShowText and IsClose then
            XUiManager.TipText("GachaIsClose")
        end

        return (not IsClose) and (not IsNotOpen)
    end

    function XGachaManager.UpdateGachaRewardInfo(gridInfoList)
        for _, v in pairs(gridInfoList or {}) do
            if GachaRewardInfos[v.Id] then
                GachaRewardInfos[v.Id].CurCount = GachaRewardInfos[v.Id].UsableTimes - v.Times
            end
        end
    end
    
    function XGachaManager.UpdateGachaLog(gachaId, logList)
        GachaLogList = GachaLogList or {}
        GachaLogList[gachaId] = logList
    end

    function XGachaManager.SetGachaRewardInfo()
        local gachaRewardCfg = XGachaConfigs.GetGachaReward()
        for id, reward in pairs(gachaRewardCfg) do
            GachaRewardInfos[id] = {}
            for k, v in pairs(reward) do
                GachaRewardInfos[id][k] = v
            end
            GachaRewardInfos[id].CurCount = GachaRewardInfos[id].UsableTimes
        end
    end

    function XGachaManager.SetGachaProbShowInfo()
        local gachaProbShowCfg = XGachaConfigs.GetGachaProbShows()
        for _, probShow in pairs(gachaProbShowCfg) do
            GachaProbShows[probShow.GachaId] = GachaProbShows[probShow.GachaId] or {}
            table.insert(GachaProbShows[probShow.GachaId],probShow)
        end
    end
    
    function XGachaManager.GetGachaRewardInfoRequest(gaChaId, cb)
        local now = XTime.GetServerNowTimestamp()
        if LastGetGachaRewardInfoTimes[gaChaId] and now - LastGetGachaRewardInfoTimes[gaChaId] <= GET_GACHA_DATA_INTERVAL then
            cb()
            return
        end
        XNetwork.Call(METHOD_NAME.GetGachaInfo, { Id = gaChaId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XGachaManager.UpdateGachaRewardInfo(res.GridInfoList)
            XGachaManager.UpdateGachaLog(gaChaId, res.GachaRecordList)
            LastGetGachaRewardInfoTimes[gaChaId] = XTime.GetServerNowTimestamp()
            cb()
        end)
    end


    function XGachaManager.DoGacha(gaChaId, count, cb, errorCb, organizeId)
        XNetwork.Call(METHOD_NAME.Gacha, { Id = gaChaId, Times = count }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                if errorCb then
                    errorCb()
                end
                return
            end
            XGachaManager.UpdateGachaRewardInfo(res.GridInfoList)
            XGachaManager.UpdateGachaLog(gaChaId, res.GachaRecordList)

            local newUnlockGachaId
            if organizeId then
                newUnlockGachaId = XGachaManager.DrawUpdateOrganizeStatus(organizeId, gaChaId)
            end

            if cb then
                cb(res.RewardList, newUnlockGachaId)
            end
        end)
    end

    ---
    --- 在进入界面的时候请求'organizeId'卡池组里的已售罄池子，以及最新解锁的池子的奖励信息
    function XGachaManager.GetGachaOrganizeInfoRequest(organizeId, cb)
        XNetwork.Call(METHOD_NAME.GetGachaOrganizeInfo, { OrganizeId = organizeId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            XGachaManager.UpdateGachaRewardInfo(res.GridInfoList)
            XGachaManager.UpdateGachaLog(res.CurrentId, res.GachaRecordList)
            XGachaManager.OpenUpdateOrganizeStatus(organizeId, res.CurrentId, res.OutOfStockIdList)
            if cb then
                cb(res.CurrentId)
            end
        end)
    end


    --------------------------------------------Organize卡池状态相关------------------------------------------------------

    ---
    --- 进入界面时更新卡池组的卡池状态
    ---
    --- 'newestGachaId'为最新解锁的卡池Id，它前面的卡池状态为正常或售罄，后面的卡池状态为锁定
    --- 'outSoldList'为已售罄卡池Id数组，这样就不用发送所有卡池的奖励信息，就能知道所有卡池的状态
    function XGachaManager.OpenUpdateOrganizeStatus(organizeId, newestGachaId, outSoldList)
        if not GachaOrganizeStatus[organizeId] then
            GachaOrganizeStatus[organizeId] = {}
        end

        -- 设置已售罄卡池
        for _, gachaId in ipairs(outSoldList) do
            if not GachaOrganizeStatus[organizeId][gachaId] then
                GachaOrganizeStatus[organizeId][gachaId] = XGachaConfigs.OrganizeGachaStatus.SoldOut
            end

            -- 进入界面时，客户端缓存的售馨卡池与服务器下发的售罄卡池不同步
            if GachaOrganizeStatus[organizeId][gachaId] ~= XGachaConfigs.OrganizeGachaStatus.SoldOut then
                XLog.Error(string.format("XGachaManager.UpdateOrganizeGachaStatus函数错误，服务器下发的最新卡池Id为%s，卡池组%s的卡池%s状态与服务器不同步，客户端的为未售罄状态",
                        tostring(newestGachaId), tostring(organizeId), tostring(gachaId)))
                GachaOrganizeStatus[organizeId][gachaId] = XGachaConfigs.OrganizeGachaStatus.SoldOut
            end
        end

        local organizeGachaIdList = XGachaConfigs.GetOrganizeGahcaIdList(organizeId)                -- organizeId组的所有gachaId数组，已根据Sort排序
        local newestGachaIndex = XGachaConfigs.GetOrganizeIndex(organizeId, newestGachaId)          -- 最新解锁卡池在organizeGachaIdList数组里的序号
        if not newestGachaIndex then
            return
        end
        -- 最新解锁卡池前面的卡池为已解锁或售罄，后面的为锁定
        for index, gachaId in ipairs(organizeGachaIdList) do
            if index <= newestGachaIndex then
                if not GachaOrganizeStatus[organizeId][gachaId] then
                    GachaOrganizeStatus[organizeId][gachaId] = XGachaConfigs.OrganizeGachaStatus.Normal
                end

                -- 进入界面时，客户端缓存的 newestGachaId卡池前面的卡池的状态 为锁定，说明状态与服务器不同步
                if GachaOrganizeStatus[organizeId][gachaId] == XGachaConfigs.OrganizeGachaStatus.Lock then
                    XLog.Error(string.format("XGachaManager.UpdateOrganizeGachaStatus函数错误，服务器下发的最新卡池Id为%s，卡池组%s的卡池%s状态与服务器不同步，客户端的为上锁状态",
                            tostring(newestGachaId), tostring(organizeId), tostring(gachaId)))
                    GachaOrganizeStatus[organizeId][gachaId] = XGachaConfigs.OrganizeGachaStatus.Normal
                end
            else
                if not GachaOrganizeStatus[organizeId][gachaId] then
                    GachaOrganizeStatus[organizeId][gachaId] = XGachaConfigs.OrganizeGachaStatus.Lock
                end

                -- 进入界面时，客户端缓存的 newestGachaId卡池后面的卡池的状态为正常，说明状态与服务器不同步
                if GachaOrganizeStatus[organizeId][gachaId] == XGachaConfigs.OrganizeGachaStatus.Normal then
                    XLog.Error(string.format("XGachaManager.UpdateOrganizeGachaStatus函数错误，服务器下发的最新卡池Id为%s，卡池组%s的卡池%s状态与服务器不同步，客户端的为正常状态",
                            tostring(newestGachaId), tostring(organizeId), tostring(gachaId)))
                    GachaOrganizeStatus[organizeId][gachaId] = XGachaConfigs.OrganizeGachaStatus.Lock
                end
            end
        end
    end

    --- 抽卡后更新卡池组的卡池状态
    --- 如果解锁了新卡池则返回该卡池Id
    ---@return number
    function XGachaManager.DrawUpdateOrganizeStatus(organizeId, DrawingGachaId)
        if not GachaOrganizeStatus[organizeId] then
            XLog.Error(string.format("XGachaManager.DrawUpdateOrganizeStatus函数错误，卡池组%s的状态数据为空",
                    tostring(organizeId)))
            GachaOrganizeStatus[organizeId] = {}
        end

        local isSoldOutRare = true  -- 特殊奖励是否售罄
        local isSoldOut = true      -- 全部奖励是否售罄
        local groupIdList = {}

        -- 是否无限次数
        if IsInfinite then
            isSoldOut = false
        else
            -- 找出DrawingGachaId的奖励
            local gachaCfg = XGachaConfigs.GetGachas()
            for _, groupId in pairs(gachaCfg[DrawingGachaId].GroupId) do
                table.insert(groupIdList, groupId)
            end

            for _, v in pairs(GachaRewardInfos) do
                -- 是否属于DrawingGachaId的奖励组
                for _, groupId in pairs(groupIdList) do
                    if v.GroupId == groupId and v.CurCount ~= 0 then
                        isSoldOut = false
                        if v.Rare then
                            isSoldOutRare = false
                        end
                        break
                    end
                end
            end
        end

        if isSoldOut then
            GachaOrganizeStatus[organizeId][DrawingGachaId] = XGachaConfigs.OrganizeGachaStatus.SoldOut
        end

        local isUnlockNext
        if isSoldOutRare then
            -- 是否解锁了新的卡池62504
            local nextGachaStatus, nextGachaId = XGachaManager.GetOrganizeNextGachaStatus(organizeId, DrawingGachaId)
            if nextGachaStatus and nextGachaId then
                if nextGachaStatus == XGachaConfigs.OrganizeGachaStatus.Lock then
                    GachaOrganizeStatus[organizeId][nextGachaId] = XGachaConfigs.OrganizeGachaStatus.Normal
                    isUnlockNext = nextGachaId
                end
            end
        end
        return isUnlockNext
    end

    ---
    --- 获取''organizeId'卡池组内'gachaId'卡池的状态
    function XGachaManager.GetOrganizeGachaStatus(organizeId, gachaId)
        if not gachaId or gachaId == 0 then
            return
        end
        if GachaOrganizeStatus[organizeId] then
            if GachaOrganizeStatus[organizeId][gachaId] then
                return GachaOrganizeStatus[organizeId][gachaId]
            else
                XLog.Error(string.format("XGachaManager.GetOrganizeGachaStatus函数错误，卡池%s的状态数据为空", gachaId))
            end
        else
            XLog.Error(string.format("XGachaManager.GetOrganizeGachaStatus函数错误，卡池组%s的状态数据为空", organizeId))
        end
        return XGachaConfigs.OrganizeGachaStatus.Lock
    end

    ---
    --- 获取''organizeId'卡池组内'gachaId'前一个卡池的状态与Id
    ---
    --- 如果'gachaId'是第一个卡池，则返回nil
    function XGachaManager.GetOrganizePreGachaStatus(organizeId, gachaId)
        local preGachaId = XGachaConfigs.GetOrganizePreGachaId(organizeId, gachaId)
        local status = XGachaManager.GetOrganizeGachaStatus(organizeId, preGachaId)
        if status then
            return status, preGachaId
        end
    end

    ---
    --- 获取''organizeId'卡池组内'gachaId'后一个卡池的状态与Id
    ---
    --- 如果'gachaId'是最后一个卡池，则返回nil
    function XGachaManager.GetOrganizeNextGachaStatus(organizeId, gachaId)
        local nextGachaId = XGachaConfigs.GetOrganizeNextGachaId(organizeId, gachaId)
        local status =  XGachaManager.GetOrganizeGachaStatus(organizeId, nextGachaId)
        if status then
            return status, nextGachaId
        end
    end
    --------------------------------------------------------------------------------------------------------------------


    XGachaManager.Init()
    return XGachaManager
end