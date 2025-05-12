local XLivWarmActivity = require("XEntity/XLivWarmActivity/XLivWarmActivity")

XLivWarmActivityManagerCreator = function()
    local LivWarmActivityEntity = XLivWarmActivity.New()

    ---------------------本地接口 begin------------------
    local function GetFirstOpenCookie()
        return XSaveTool.GetData("LivWarmActivityFirstOpen_" .. XPlayer.Id) or 0
    end
    ---------------------本地接口 end--------------------
    local XLivWarmActivityManager = {}

    ---------------------红点 begin---------------------
    function XLivWarmActivityManager.CheckRewardRedPoint()
        local stageIdList = XLivWarmActivityConfigs.GetLivWarmStageIdList()
        for i, stageId in ipairs(stageIdList) do
            if XLivWarmActivityManager.CheckRewardRedPointByStageId(stageId) then
                return true
            end
        end
        return false
    end

    function XLivWarmActivityManager.CheckRewardRedPointByStageId(stageId)
        if not XLivWarmActivityManager.IsUnlockStage(stageId) then
            return false
        end

        local stageDb = XLivWarmActivityManager.GetStageDb(stageId)
        local dismisCount = stageDb:GetDismisCount()
        local takeRewardProgressIndex = stageDb:GetTakeRewardProgressIndex()
        local rewardProgressList = XLivWarmActivityConfigs.GetLivWarmActivityStageRewardProgress(stageId)
        local isAlreadyReceive  --是否已领取
        local isCanReceive      --是否可领取
        for index, rewardProgress in ipairs(rewardProgressList) do
            isAlreadyReceive = index <= takeRewardProgressIndex
            isCanReceive = rewardProgress <= dismisCount
            if not isAlreadyReceive and isCanReceive then
                return true
            end
        end
        return false
    end

    function XLivWarmActivityManager.CheckCanChallengeRedPoint()
        local stageIdList = XLivWarmActivityConfigs.GetLivWarmStageIdList()
        local stageDb
        local isHaveNotClearStage = false   --是否有未通关的关卡
        local isUnlock
        for i, stageId in ipairs(stageIdList) do
            isUnlock = XLivWarmActivityManager.IsUnlockStage(stageId)
            if isUnlock then
                stageDb = XLivWarmActivityManager.GetStageDb(stageId)
                if not stageDb:IsWin() then
                    isHaveNotClearStage = true
                    break
                end
            end
        end

        if not isHaveNotClearStage then
            return false
        end

        return XLivWarmActivityManager.IsItemFillCount()
    end
    ---------------------红点 end-----------------------

    ---------------------活动入口 begin---------------------
    --活动是否开启中
    function XLivWarmActivityManager.IsActivityOpen()
        local timeId = XLivWarmActivityConfigs.GetLivWarmActivityTimeId()
        return XFunctionManager.CheckInTimeByTimeId(timeId)
    end

    --检查活动没开回主界面
    function XLivWarmActivityManager.CheckActivityIsOpen()
        if not XLivWarmActivityManager.IsActivityOpen() then
            if CS.XFight.IsRunning or XLuaUiManager.IsUiLoad("UiLoading") then
                return false
            end

            XUiManager.TipText("ActivityMainLineEnd")
            XLuaUiManager.RunMain()
            return false
        end
        return true
    end
    ---------------------活动入口 end-----------------------

    ---------------------主界面 begin---------------------
    function XLivWarmActivityManager.GetGridData(stageId)
        local stageDb = LivWarmActivityEntity:GetStageDb(stageId)
        local gridData = stageDb:GetGridData()
        if XTool.IsTableEmpty(gridData) then
            local headIdList = XLivWarmActivityConfigs.GetLivWarmHeadIdList(stageId)
            local columnIndexes
            for row, headId in ipairs(headIdList) do
                gridData[row] = {}
                columnIndexes = XLivWarmActivityConfigs.GetLivWarmActivityHeadColumnIndexes(headId)
                for col, headType in ipairs(columnIndexes) do
                    gridData[row][col] = headType
                end
            end
        end
        return gridData
    end

    function XLivWarmActivityManager.GetStageDb(stageId)
        return LivWarmActivityEntity:GetStageDb(stageId)
    end

    function XLivWarmActivityManager.IsUnlockStage(stageId)
        local requireStageId = XLivWarmActivityConfigs.GetLivWarmActivityStageRequireStageId(stageId)
        if not XTool.IsNumberValid(requireStageId) then
            return true
        end

        local stageDb = XLivWarmActivityManager.GetStageDb(requireStageId)
        return stageDb:IsWin()
    end

    function XLivWarmActivityManager.IsStageWin(stageId)
        local stageDb = XLivWarmActivityManager.GetStageDb(stageId)
        return stageDb:IsWin()
    end


    --是否满足活动道具消耗数量
    function XLivWarmActivityManager.IsItemFillCount()
        local itemId = XLivWarmActivityConfigs.GetLivWarmActivityItemId()
        local hasItemCount = XDataCenter.ItemManager.GetCount(itemId)
        local useItemCount = XLivWarmActivityConfigs.GetLivWarmActivityUseItemCount()
        return hasItemCount >= useItemCount
    end

    --关卡是否满足不消耗道具即可移动格子的条件
    function XLivWarmActivityManager.IsFillUseMaxItemCount(stageId)
        if not XTool.IsNumberValid(stageId) then
            return false
        end

        local maxItemCount = XLivWarmActivityConfigs.GetLivWarmActivityStageMaxItemCount(stageId)
        local stageDb = XLivWarmActivityManager.GetStageDb(stageId)
        local curUseItemCount = stageDb:GetChangeCount()
        return curUseItemCount >= maxItemCount
    end

    function XLivWarmActivityManager.IsFirstOpenView()
        local firstOpenTimeStamp = GetFirstOpenCookie()
        if XTool.IsNumberValid(firstOpenTimeStamp) then
            return false
        end
        return true
    end

    function XLivWarmActivityManager.SetFirstOpenViewCookie()
        if XLivWarmActivityManager.IsFirstOpenView() then
            XSaveTool.SaveData("LivWarmActivityFirstOpen_" .. XPlayer.Id, XTime.GetServerNowTimestamp())
        end
    end
    ---------------------主界面 end-----------------------
    
    ---------------------protocol begin------------------
    --进入消消乐关卡请求
    function XLivWarmActivityManager.RequestLivWarmActivityChangeStage(stageId, dismisCount, isWin, gridData, cb)
        local req = {
            StageId = stageId,              --关卡id
            DismisCount = dismisCount,      --单次消除数量
            IsWin = isWin,                  --是否胜利
            GridData = gridData             --格子的数据（二维数组）
        }

        XNetwork.Call("LivWarmActivityChangeStageRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local stageDb = XLivWarmActivityManager.GetStageDb(stageId)
            local totalDismisCount = stageDb:GetDismisCount()
            req.DismisCount = totalDismisCount + req.DismisCount
            LivWarmActivityEntity:UpdateStageDb(stageId, req)

            stageDb:AddOnceChangeCount()

            if cb then
                cb()
            end
        end)
    end

    --领取奖励
    function XLivWarmActivityManager.RequestLivWarmActivityTakeReward(stageId, cb)
        XNetwork.Call("LivWarmActivityTakeRewardRequest", {StageId = stageId}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            XUiManager.OpenUiObtain(res.RewardGoodsList)

            local stageDb = XLivWarmActivityManager.GetStageDb(stageId)
            local totalDismisCount = stageDb:GetDismisCount()
            local stageRewardProgressList = XLivWarmActivityConfigs.GetLivWarmActivityStageRewardProgress(stageId)
            local takeRewardProgressIndex
            for i, stageRewardProgress in ipairs(stageRewardProgressList) do
                if totalDismisCount < stageRewardProgress then
                    break
                end
                takeRewardProgressIndex = i
            end

            stageDb:SetTakeRewardProgressIndex(takeRewardProgressIndex)
            
            if cb then
                cb()
            end
        end)
    end

    --更新推送
    function XLivWarmActivityManager.NotifyLivWarmActivityOnChange(data)
        LivWarmActivityEntity:UpdateData(data.ActivityDb)
        XLivWarmActivityConfigs.SetDefaultActivityId(data.ActivityDb.ActivityId)
        XEventManager.DispatchEvent(XEventId.EVENT_NOTIFY_LIV_WARM_ACTIVITY_ON_CHANGE)
    end
    ---------------------protocol end------------------
    return XLivWarmActivityManager
end

---------------------(服务器推送)begin------------------
XRpc.NotifyLivWarmActivityOnChange = function(data)
    XDataCenter.LivWarmActivityManager.NotifyLivWarmActivityOnChange(data)
end
---------------------(服务器推送)end--------------------