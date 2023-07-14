XPuzzleActivityManagerCreator = function()
    local ParseToTimestamp = XTime.ParseToTimestamp
    local CSUnityEnginePlayerPrefs = CS.UnityEngine.PlayerPrefs
    local CSGameEventManager = CS.XGameEventManager.Instance
    local XPuzzleActivityData = require("XEntity/XPuzzleActivityData")
    local PuzzleActivityGroupInfos = nil
    local PuzzleActivityPiecesData = {}
    local PiecesFlipRedPointCount = {}
    local IsPuzzleActivityHaveReward = {}
    local ItemIdToActId = {}

    local XPuzzleActivityManager = {}
    local ActRpc = {
        PuzzleActData = "PuzzleActivityDataRequest",                             --获得活动数据
        PuzzleActFlipPiece = "PuzzleActivityFlipPieceRequest",                   --获得碎片翻转数据
        PuzzleActGetReward = "PuzzleActivityGetRewardRequest",                   --请求获得奖励
    }

    function XPuzzleActivityManager.Init()
        XEventManager.AddEventListener(XEventId.EVENT_LOGIN_DATA_LOAD_COMPLETE, function()
            XPuzzleActivityManager.InitPuzzleActivityGroupInfos()
        end)
    end

    --构建拼图活动组
    function XPuzzleActivityManager.InitPuzzleActivityGroupInfos()
        PuzzleActivityGroupInfos = {}
        local activityGroupTemplates = XPuzzleActivityConfigs.GetTemplates()
        for actId, activity in pairs(activityGroupTemplates) do
            PuzzleActivityGroupInfos[actId] = XPuzzleActivityData.New(actId)
            XPuzzleActivityManager.InitEventListener(actId)
        end
    end

    function XPuzzleActivityManager.InitEventListener(actId)
        local activity = PuzzleActivityGroupInfos[actId]
        local id = XDataCenter.ActivityManager.PuzzleActIdToActId(actId)
        if XDataCenter.ActivityManager.IsActivityOpen(id) then
            XPuzzleActivityManager.PuzzleActivityDataRequest(actId)
            for _,piece in pairs(activity.PieceCfgs) do
                ItemIdToActId[piece.ItemId] = actId
                XEventManager.AddEventListener(XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. piece.ItemId, XPuzzleActivityManager.OnEventItemCountChange)
            end
        end
    end

    function XPuzzleActivityManager.OnEventItemCountChange(itemId)
        XPuzzleActivityManager.PuzzleActivityDataRequest(ItemIdToActId[itemId])
    end

    --获取拼图活动服务端状态
    function XPuzzleActivityManager.PuzzleActivityDataRequest(id, cb)
        XNetwork.Call(ActRpc.PuzzleActData, { Id = id }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end          
            XPuzzleActivityManager.HandlePuzzleActivityData(id, res.PieceStates, res.RewardState)
            CSGameEventManager:Notify(XEventId.EVENT_ACTIVITY_INFO_UPDATE, XActivityConfigs.ActivityType.JigsawPuzzle)
            XEventManager.DispatchEvent(XEventId.EVENT_ACTIVITY_INFO_UPDATE)
            if cb then
                cb()
            end
        end)
    end

    function XPuzzleActivityManager.HandlePuzzleActivityData(id, pieceStates, rewardState)
        local condition = XPuzzleActivityConfigs.PuzzleCondition
        local puzzleActData = XPuzzleActivityManager.GetActivityPuzzleTemplateById(id)
        PiecesFlipRedPointCount[id] = 0
        local collectComplete = true
        --for i = 1,#puzzleActData.PieceCfgs do
        for index, template in ipairs(puzzleActData.PieceCfgs) do
            pieceStates[index] = pieceStates[index] or condition.NotCollected
            if pieceStates[index] == condition.NotCollected then
                if XDataCenter.ItemManager.CheckItemCountById(
                    template.ItemId, template.ItemCount) then
                    pieceStates[index] = condition.Inactivated
                    PiecesFlipRedPointCount[id] = PiecesFlipRedPointCount[id] + 1
                end
            end
            if pieceStates[index] ~= condition.Activated then
                collectComplete = false
            end
        end
        if next(pieceStates) then
            PuzzleActivityPiecesData[id] = pieceStates
        end
        if rewardState == XPuzzleActivityConfigs.PuzzleRewardState.Unrewarded and collectComplete then
            rewardState = XPuzzleActivityConfigs.PuzzleRewardState.CanReward
            IsPuzzleActivityHaveReward[id] = true
        end
        puzzleActData:SetRewardState(rewardState)
    end

    function XPuzzleActivityManager.HandlePuzzlePieceData(id, pieceId, state)
        local condition = XPuzzleActivityConfigs.PuzzleCondition
        local puzzleActData = XPuzzleActivityManager.GetActivityPuzzleTemplateById(id)
        if state ~= condition.Activated then
            return
        end
        if pieceId then
            PuzzleActivityPiecesData[id][pieceId] = state
        end
        PiecesFlipRedPointCount[id] = PiecesFlipRedPointCount[id] - 1
        local collectComplete = true
        for k,v in ipairs(PuzzleActivityPiecesData[id])do
            if v ~= condition.Activated then
                collectComplete = false
            end
        end
        if collectComplete then
            puzzleActData:SetRewardState(XPuzzleActivityConfigs.PuzzleRewardState.CanReward)
        end
    end

    function XPuzzleActivityManager.HandlePuzzleRewardData(id, state)
        local puzzleActData = XPuzzleActivityManager.GetActivityPuzzleTemplateById(id)
        puzzleActData:SetRewardState(state)
        if state == XPuzzleActivityConfigs.PuzzleRewardState.Rewarded then
            IsPuzzleActivityHaveReward[id] = false
        end
    end

    --请求翻牌
    function XPuzzleActivityManager.PuzzleActivityFlipPieceRequest(id, pieceId, cb)
        XNetwork.Call(ActRpc.PuzzleActFlipPiece, { Id = id, PieceId = pieceId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XPuzzleActivityManager.HandlePuzzlePieceData(id, res.PieceId, res.State)
            CSGameEventManager:Notify(XEventId.EVENT_ACTIVITY_INFO_UPDATE, XActivityConfigs.ActivityType.JigsawPuzzle)
            XEventManager.DispatchEvent(XEventId.EVENT_ACTIVITY_INFO_UPDATE)
            if cb then
                cb()
            end
        end)
    end

    -- 领取奖励
    function XPuzzleActivityManager.PuzzleActivityGetRewardRequest(id, cb)
        XNetwork.Call(ActRpc.PuzzleActGetReward, { Id = id }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XPuzzleActivityManager.HandlePuzzleRewardData(id, res.RewardState)
            if cb then
                cb(res.RewardGoods)
            end
            CSGameEventManager:Notify(XEventId.EVENT_ACTIVITY_INFO_UPDATE, XActivityConfigs.ActivityType.JigsawPuzzle)
            XEventManager.DispatchEvent(XEventId.EVENT_ACTIVITY_INFO_UPDATE)
        end)
    end

    function XPuzzleActivityManager.GetActivityPuzzleTemplateById(puzzleId)
        return PuzzleActivityGroupInfos[puzzleId]
    end

    function XPuzzleActivityManager.GetPieceAmountById(id)
        return PuzzleActivityGroupInfos[id]:GetPieceAmount()
    end
    
    function XPuzzleActivityManager.GetPieceTemplate(id, index)
        return PuzzleActivityGroupInfos[id].PieceCfgs[index]
    end

    function XPuzzleActivityManager.GetPuzzleActPieceData(id, index)
        return PuzzleActivityPiecesData[id][index]
    end

    function XPuzzleActivityManager.IsHaveRedPointById(id)
        return IsPuzzleActivityHaveReward[id] or (PiecesFlipRedPointCount[id] and PiecesFlipRedPointCount[id] > 0)
    end

    function XPuzzleActivityManager.IsHaveRedPoint()
        for _,v in pairs(IsPuzzleActivityHaveReward) do
            if v == true then
                return true
            end
        end        
        for _,v in pairs(PiecesFlipRedPointCount) do
            if v > 0 then
                return true
            end
        end
    end

    XPuzzleActivityManager.Init()
    return XPuzzleActivityManager
end