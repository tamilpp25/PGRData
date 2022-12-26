local XGuardCampActivityInfo = require("XEntity/XGuardCamp/XGuardCampActivityInfo")
local XGuardActivityNotifyData = require("XEntity/XGuardCamp/XGuardActivityNotifyData")

XGuardCampManagerCreator = function()
    local CSTextManagerGetText = CS.XTextManager.GetText
    local mathMax = math.max
    local mathMin = math.min

    local GuardActivityInfos = {}
    local GlobalData = {}
    local LoginTime = -1            --登录时间
    local LastLoginTime = -1        --上次登录时间
    local ActivityOpenStateTimer
    local CurrGetGuardCampGlobalDataRequestTimastame = 0
    local GetGuardCampGlobalDataRequestInterval = 10    --获取活动全局数据时间间隔
    local PercentPointList = {
        0.26,
        0.5,
        0.73,
        0.96,
        1
    }

    ---------------------本地接口 begin------------------
    local function UpdateCurrGetGuardCampGlobalDataRequestTimastame()
        local serverTimestamp = XTime.GetServerNowTimestamp()
        CurrGetGuardCampGlobalDataRequestTimastame = serverTimestamp + GetGuardCampGlobalDataRequestInterval
    end

    local function UpdateGlobalData(data)
        if not data then return end
        if not GlobalData[data.Id] then
            GlobalData[data.Id] = XGuardActivityNotifyData.New(data.Id)
        end
        GlobalData[data.Id]:UpdateData(data)
        UpdateCurrGetGuardCampGlobalDataRequestTimastame()
    end

    local function UpdateGuardActivityInfo(data)
        if not GuardActivityInfos[data.Id] then
            GuardActivityInfos[data.Id] = XGuardCampActivityInfo.New(data.Id)
        end
        GuardActivityInfos[data.Id]:UpdateData(data)
    end

    local function UpdateGuardActivityInfos(data)
        if not data then return end
        for _, v in pairs(data) do
            UpdateGuardActivityInfo(v)
        end
    end

    local function UpdateGuardActivityIsGetReward(activityId, isGetReward)
        if GuardActivityInfos[activityId] then
            GuardActivityInfos[activityId]:SetIsGetReward(isGetReward)
        end
    end

    local function StopActivityOpenTimer()
        if ActivityOpenStateTimer then
            XScheduleManager.UnSchedule(ActivityOpenStateTimer)
        end
    end

    local function CheckActivityOpenTimer()
        StopActivityOpenTimer()
        local activityId = XGuardCampConfig.GetActivityId()
        local serverTimestamp = XTime.GetServerNowTimestamp()
        local _, endActivityTime = XGuardCampConfig.GetActivityTime(activityId)
        if endActivityTime > serverTimestamp then
            ActivityOpenStateTimer = XScheduleManager.ScheduleForever(function()
                serverTimestamp = XTime.GetServerNowTimestamp()
                if serverTimestamp >= endActivityTime then
                    XEventManager.DispatchEvent(XEventId.EVENT_GUARD_CAMP_ACTIVITY_OPEN_STATE_CHANGE)
                    StopActivityOpenTimer()
                end
            end, XScheduleManager.SECOND, 0)
        end
    end

    local function GetFirstOpenActivityRedPointTimestamp()
        return XSaveTool.GetData("GuardCampFirstOpenActivityRedPointTimestamp_" .. XPlayer.Id) or 0
    end

    local function CheckUpdateFirstOpenActivityRedPointTimestamp()
        local firstOpenActivityRedPointTimestamp = GetFirstOpenActivityRedPointTimestamp()
        local activityId = XGuardCampConfig.GetActivityId()
        local _, endActivityTime = XGuardCampConfig.GetActivityTime(activityId)
        if firstOpenActivityRedPointTimestamp < endActivityTime then 
            XSaveTool.SaveData("GuardCampFirstOpenActivityRedPointTimestamp_" .. XPlayer.Id, endActivityTime)
        end
    end

    local function GetSupportTomorrowRedPointTimestamp()
        return XSaveTool.GetData("GuardCampSupportTomorrowRedPointTimeStamp_" .. XPlayer.Id) or 0
    end

    local function CheckUpdateSupportTomorrowRedPointTimestamp()
        local activityId = XGuardCampConfig.GetActivityId()
        local state = XDataCenter.GuardCampManager.GetActivityState(activityId)
        if state ~= XGuardCampConfig.ActivityState.SupportOpen then return end

        local supportTomorrowRedPointTimeStamp = GetSupportTomorrowRedPointTimestamp()
        local serverTimestamp = XTime.GetServerNowTimestamp()
        if serverTimestamp > supportTomorrowRedPointTimeStamp then
            XSaveTool.SaveData("GuardCampSupportTomorrowRedPointTimeStamp_" .. XPlayer.Id, XTime.GetSeverTomorrowFreshTime())
        end
    end

    local function IsGetGuardCampGlobalDataRequest()
        if XDataCenter.GuardCampManager.IsActivityClose() then
            return false
        end
        local serverTimestamp = XTime.GetServerNowTimestamp()
        if CurrGetGuardCampGlobalDataRequestTimastame < serverTimestamp then
            return true
        end
        return false
    end
    ---------------------本地接口 end------------------

    local XGuardCampManager = {}

    function XGuardCampManager.Init()
        XEventManager.AddEventListener(XEventId.EVENT_LOGIN_SUCCESS, function()
            if XDataCenter.GuardCampManager.IsActivityClose() then
                return
            end
            local activityId = XGuardCampConfig.GetActivityId()
            XGuardCampManager.RequestGetGuardCampGlobalDataSend(activityId, function()
                XEventManager.DispatchEvent(XEventId.EVENT_GUARD_CAMP_ACTIVITY_OPEN_STATE_CHANGE)
            end)
        end)
        
        XEventManager.AddEventListener(XEventId.EVENT_USER_LOGOUT, function()
            StopActivityOpenTimer()
        end)
        CheckActivityOpenTimer()
    end

    function XGuardCampManager.GetSelectCampIdByActivityId(activityId)
        local data = GuardActivityInfos[activityId]
        return data and data:GetSelectCampId() or 0
    end

    function XGuardCampManager.GetSupportCount(activityId, campId)
        local data = GuardActivityInfos[activityId]
        return data and data:GetSupportCountByCampId(campId) or 0
    end

    function XGuardCampManager.IsGetReward(activityId)
        local data = GuardActivityInfos[activityId]
        return data and data:IsGetReward() or false
    end

    function XGuardCampManager.GetMaxSupportCount(activityId)
        local totalSupportCountCfg = XGuardCampConfig.GetActivityTotalSupportCount(activityId)
        local campIdList = XGuardCampConfig.GetCampIdList()
        local totalSupportCountInfo = 0
        local campSupportCount
        for _, campId in ipairs(campIdList) do
            campSupportCount = XGuardCampManager.GetSupportCount(activityId, campId)
            totalSupportCountInfo = totalSupportCountInfo + campSupportCount
        end
        return mathMax(totalSupportCountCfg - totalSupportCountInfo, 0)
    end

    function XGuardCampManager.GetPondCountByActivityId(activityId)
        local data = GlobalData[activityId]
        return data and data:GetPondCount() or 0
    end

    function XGuardCampManager.GetWinCampIdByActivityId(activityId)
        local data = GlobalData[activityId]
        return data and data:GetWinCampId() or 0
    end

    function XGuardCampManager.GetJoinTotalNum(activityId)
        local data = GlobalData[activityId]
        return data and data:GetJoinTotalNum() or 0
    end

    function XGuardCampManager.GetJoinPercent(activityId)
        local joinTotalNum = XGuardCampManager.GetJoinTotalNum(activityId)
        if joinTotalNum == 0 then 
            return 0
        end

        local joinNumList = XGuardCampConfig.GetActivityJoinNumList(activityId)
        local totalJoinNum = #joinNumList
        if totalJoinNum == 0 then
            return 0
        end

        local supportIndex = #PercentPointList
        local currjoinNumCfg = joinNumList[totalJoinNum]
        for i = totalJoinNum, 1, -1 do
            if joinTotalNum <= joinNumList[i] then
                supportIndex = i
                currjoinNumCfg = joinNumList[i]
            else
                break
            end
        end

        local curPercentPoint = PercentPointList[supportIndex] or 0
        if currjoinNumCfg == 0 then
            return curPercentPoint
        end

        local preJoinNumCfg = joinNumList[supportIndex - 1] or 0
        local prePercentPoint = PercentPointList[supportIndex - 1] or 0
        local adjacentPercentDiffer = curPercentPoint - prePercentPoint
        local joinPercent = (joinTotalNum - preJoinNumCfg) / (currjoinNumCfg - preJoinNumCfg) * adjacentPercentDiffer + prePercentPoint
        return joinTotalNum > 0 and mathMin(joinPercent, 1) or 0
    end

    function XGuardCampManager.GetSupportNum(activityId, campId)
        local data = GlobalData[activityId]
        if not data then
            return 0
        end
        return data:GetSupportNumByCampId(campId)
    end

    function XGuardCampManager.GetJoinNum(activityId, campId)
        local data = GlobalData[activityId]
        if not data then
            return 0
        end
        return data:GetJoinNumByCampId(campId)
    end

    function XGuardCampManager.CheckRedPoint()
        local serverTimestamp = XTime.GetServerNowTimestamp()
        if XGuardCampManager.IsFirstOpenView() then
            return true
        end

        local activityId = XGuardCampConfig.GetActivityId()
        local selectCampId = XGuardCampManager.GetSelectCampIdByActivityId(activityId)
        local state = XGuardCampManager.GetActivityState(activityId)
        local supportTomorrowRedPointTimeStamp = GetSupportTomorrowRedPointTimestamp()
        --开启投注期间没有选择阵营，每日红点提醒
        if selectCampId == 0 and state == XGuardCampConfig.ActivityState.SupportOpen and serverTimestamp > supportTomorrowRedPointTimeStamp then
            return true
        end

        if selectCampId > 0 then
            local isGetReward = XGuardCampManager.IsGetReward(activityId)
            if state == XGuardCampConfig.ActivityState.DrawLottery and not isGetReward then
                return true
            end
        end
        return false
    end

    function XGuardCampManager.CheckUpdateRedPointTimeStamp()
        CheckUpdateFirstOpenActivityRedPointTimestamp()
        CheckUpdateSupportTomorrowRedPointTimestamp()
    end

    function XGuardCampManager.IsFirstOpenView()
        local serverTimestamp = XTime.GetServerNowTimestamp()
        local firstOpenActivityRedPointTimestamp = GetFirstOpenActivityRedPointTimestamp()
        return serverTimestamp > firstOpenActivityRedPointTimestamp
    end

    --返回当前的开启状态，时间描述，标题，当前状态的时间戳
    function XGuardCampManager.GetActivityState(activityId)
        local serverTimestamp = XTime.GetServerNowTimestamp()
        local startActivityTime, endActivityTime = XGuardCampConfig.GetActivityTime(activityId)
        local startSupporLastTime, endSupporLastTime = XGuardCampConfig.GetActivitySupportLastTime(activityId)
        local winCampId = XGuardCampManager.GetWinCampIdByActivityId(activityId)

        local title
        if startActivityTime > serverTimestamp or startSupporLastTime > serverTimestamp then
            return XGuardCampConfig.ActivityState.UnOpen, XGuardCampConfig.GetSupportOpenTimeStr(activityId), CSTextManagerGetText("GuardCampUnOpenTitle"), startSupporLastTime
        end
        if startSupporLastTime <= serverTimestamp and endSupporLastTime > serverTimestamp then
            return XGuardCampConfig.ActivityState.SupportOpen, "", CSTextManagerGetText("GuardCampSupportOpenTitle"), endSupporLastTime
        end
        if endSupporLastTime <= serverTimestamp and winCampId == 0 then
            return XGuardCampConfig.ActivityState.SupportClose, XGuardCampConfig.GetActivityShowDrawLotteryTime(activityId), CSTextManagerGetText("GuardCampSupportCloseTitle"), endActivityTime
        end
        if winCampId ~= 0 and endActivityTime > serverTimestamp then
            return XGuardCampConfig.ActivityState.DrawLottery, XGuardCampConfig.GetActivityCloseTimeStr(activityId), CSTextManagerGetText("GuardCampCloseTitle"), endActivityTime
        end

        return XGuardCampConfig.ActivityState.Close, "", "", 0
    end

    function XGuardCampManager.IsActivityClose()
        local activityId = XGuardCampConfig.GetActivityId()
        local serverTimestamp = XTime.GetServerNowTimestamp()
        local startActivityTime, endActivityTime = XGuardCampConfig.GetActivityTime(activityId)
        return serverTimestamp < startActivityTime or serverTimestamp >= endActivityTime
    end

    function XGuardCampManager.GetActivityPurchasePackageData(activityId)
        local purchasePackageUiType, purchasePackageId = XGuardCampConfig.GetActivityJoinCampPurchasePackage(activityId)
        local purchaseData = XDataCenter.PurchaseManager.GetPurchaseData(purchasePackageUiType, purchasePackageId)
        if not purchaseData or purchaseData.IsSelloutHide then
            purchasePackageUiType, purchasePackageId = XGuardCampConfig.GetActivitySupportCampPurchasePackage(activityId)
            purchaseData = XDataCenter.PurchaseManager.GetPurchaseData(purchasePackageUiType, purchasePackageId)
        end
        return purchaseData
    end
    ---------------------protocol begin------------------
    --选择守护阵营
    function XGuardCampManager.RequestSelectGuardCampSend(id, campId)
        local req = {Id = id, CampId = campId}
        XNetwork.Call("SelectGuardCampRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XUiManager.TipText("GuardCampSelectCampSuccess")
        end)
    end

    --支援阵营
    function XGuardCampManager.RequestSupportGuardCampSend(id, campId, count)
        local req = {Id = id, CampId = campId, Count = count}
        XNetwork.Call("SupportGuardCampRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XUiManager.TipText("GuardCampSupportCampSuccess")
        end)
    end

    --领取奖励
    function XGuardCampManager.RequestGetGuardCampRewardSend(id, cb)
        local req = {Id = id}
        XNetwork.Call("GetGuardCampRewardRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XUiManager.OpenUiObtain(res.RewardList)
            UpdateGuardActivityIsGetReward(id, true)
            if cb then
                cb()
            end
        end)
    end

    --活动全局数据
    function XGuardCampManager.RequestGetGuardCampGlobalDataSend(id, cb)
        if not IsGetGuardCampGlobalDataRequest() then return end
        local req = {Id = id}
        XNetwork.Call("GetGuardCampGlobalDataRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            UpdateGlobalData(res.GlobalData)
            if cb then
                cb()
            end
        end)
    end

    function XGuardCampManager.NotifyGuardCampLoginData(data)
        UpdateGuardActivityInfos(data.GuardActivityInfos)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_GUARD_CAMP_ACTIVITY_DATA_CHANGE)
    end

    function XGuardCampManager.NotifyGuardCampActivityInfo(data)
        UpdateGuardActivityInfo(data.ActivityInfo)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_GUARD_CAMP_ACTIVITY_DATA_CHANGE)
    end
    ---------------------protocol end------------------

    XGuardCampManager.Init()
    return XGuardCampManager
end

---------------------(服务器推送)begin------------------
XRpc.NotifyGuardCampLoginData = function(data)
    XDataCenter.GuardCampManager.NotifyGuardCampLoginData(data)
end

--选择阵营和应援时通知
XRpc.NotifyGuardCampActivityInfo = function(data)
    XDataCenter.GuardCampManager.NotifyGuardCampActivityInfo(data)
end
---------------------(服务器推送)end--------------------