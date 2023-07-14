local tableInsert = table.insert
local tableSort = table.sort
local tableRemove = table.remove

XFubenActivityPuzzleManagerCreator = function ()
    local XFubenActivityPuzzleManager = {}
    local ActivityInfo = nil
    local PuzzleTemplates = {}
    local PuzzleInfos = {}
    local PieceTables = {} -- 碎片表{puzzleId = {}}
    local PuzzlePieceTables = {} -- 拼图方块表 {puzzleId = {}}
    local GotRewardIdxTables = {} -- 获取的区域奖励Idx表 {puzzleId={}}
    local GotCompleteStateTables = {} -- 全部拼图完成奖励获取表 {puzzleId = 0 or 1 or nil}
    local PuzzleCompleteStateTable = {} -- 拼图完成表
    local SwitchRedPointDic = {} -- 转化按钮红点字典(0:无红点，1:有红点)
    local DecryptionPasswordData = {} -- 解密密码表

    local ACTIVITY_PUZZLE_PROTO = {
        DragPuzzleActivityDataRequest = "DragPuzzleActivityDataRequest",
        DragPuzzleActivityExchangePieceRequest = "DragPuzzleActivityExchangePieceRequest",
        DragPuzzleActivityMovePieceRequest = "DragPuzzleActivityMovePieceRequest",
        DragPuzzleActivityGetRewardRequest = "DragPuzzleActivityGetRewardRequest",
        DragPuzzleActivityExchangePasswordRequest = "DragPuzzleActivityExchangePasswordRequest",
    }

    function XFubenActivityPuzzleManager.Init()
        XEventManager.AddEventListener(XEventId.EVENT_LOGIN_DATA_LOAD_COMPLETE, function()
            local activityTemplates = XFubenActivityPuzzleConfigs.GetActivityTemplates()
            local nowTime = XTime.GetServerNowTimestamp()
            for _, template in ipairs(activityTemplates) do
                local TimeId = template.TimeId
                local startTime, endTime = XFunctionManager.GetTimeByTimeId(TimeId)
                if nowTime > startTime and nowTime < endTime then
                    if not ActivityInfo then
                        ActivityInfo = XFubenActivityPuzzleConfigs.GetActivityTemplateById(template.Id)
                    end
                    if not PuzzleTemplates or #PuzzleTemplates <= 0 then
                        PuzzleTemplates = XFubenActivityPuzzleConfigs.GetPuzzleTemplatesByActId(template.Id)
                    end
                    if not PuzzleInfos or not next(PuzzleInfos) then
                        XNetwork.Call(ACTIVITY_PUZZLE_PROTO.DragPuzzleActivityDataRequest, {ActId = template.Id}, function (res)
                            if res.Code ~= XCode.Success then
                                XUiManager.TipCode(res.Code)
                                return
                            end
                            XFubenActivityPuzzleManager.HandlePuzzles(res.Puzzles)
                        end)
                    end
                    break
                end
            end
        end)
    end

    function XFubenActivityPuzzleManager.OpenPuzzleGame(actId)
        if not ActivityInfo then
            ActivityInfo = XFubenActivityPuzzleConfigs.GetActivityTemplateById(actId)
        end

        if not PuzzleTemplates or #PuzzleTemplates <= 0 then
            PuzzleTemplates = XFubenActivityPuzzleConfigs.GetPuzzleTemplatesByActId(actId)
        end

        if not DecryptionPasswordData or not next(DecryptionPasswordData) then
            XFubenActivityPuzzleManager.InitDecryptionPasswordData()
        end
        
        XLuaUiManager.Open("UiFubenActivityPuzzle")
    end

    function XFubenActivityPuzzleManager.HandlePuzzles(puzzles)
        XFubenActivityPuzzleManager.InitDecryptionPasswordData() -- 根据配置初始化密码默认数据
        for _, puzzleInfo in pairs(puzzles) do
            PuzzleInfos[puzzleInfo.Id] = puzzleInfo

            if not puzzleInfo.GotRewardIdxs then
                GotRewardIdxTables[puzzleInfo.Id] = {}
            else
                GotRewardIdxTables[puzzleInfo.Id] = puzzleInfo.GotRewardIdxs
            end

            PuzzleCompleteStateTable[puzzleInfo.Id] = puzzleInfo.State
            GotCompleteStateTables[puzzleInfo.Id] = puzzleInfo.CompleteRewardState

            PieceTables[puzzleInfo.Id] = {}
            PuzzlePieceTables[puzzleInfo.Id] = {}

            local pieces = puzzleInfo.Pieces
            for _, pieceInfo in pairs(pieces) do
                if pieceInfo.Idx > 0 then -- 大于0是已经拼上的碎片
                    PuzzlePieceTables[puzzleInfo.Id][pieceInfo.Idx] = pieceInfo.Id
                else -- 小于等于零是已经兑换没有拼的碎片
                    tableInsert(PieceTables[puzzleInfo.Id], pieceInfo)
                end
            end

            tableSort(PieceTables[puzzleInfo.Id], function(pieceA, pieceB)
                return pieceA.Idx > pieceB.Idx
            end)

            -- DecryptionPasswordData[puzzleInfo.Id] = nil
            if puzzleInfo.CurrentPassword and next(puzzleInfo.CurrentPassword) then -- 初始化密码数据
                DecryptionPasswordData[puzzleInfo.Id] = puzzleInfo.CurrentPassword
            end
        end
    end

    function XFubenActivityPuzzleManager.InitDecryptionPasswordData()
        local puzzleTemplates = XFubenActivityPuzzleManager.GetPuzzleTemplates()
        if puzzleTemplates and next(puzzleTemplates) then
            DecryptionPasswordData = {}
            for _, puzzleTemplate in pairs(puzzleTemplates) do
                if puzzleTemplate.PuzzleType == XFubenActivityPuzzleConfigs.PuzzleType.Decryption then
                    local passwordLength = XFubenActivityPuzzleConfigs.GetPuzzlePasswordLengthById(puzzleTemplate.Id)
                    DecryptionPasswordData[puzzleTemplate.Id] = {}
                    for i = 1, passwordLength do
                        tableInsert(DecryptionPasswordData[puzzleTemplate.Id], 0)
                    end
                end
            end
        end
    end

    function XFubenActivityPuzzleManager.GetPuzzleTemplates()
        return PuzzleTemplates
    end

    function XFubenActivityPuzzleManager.GetPuzzleTemplateByIndex(index) -- index 代表当前活动的第index个拼图
        if not PuzzleTemplates then
            return nil
        end

        return PuzzleTemplates[index]
    end

    function XFubenActivityPuzzleManager.GetPuzzleInfos()
        return PuzzleInfos
    end

    function XFubenActivityPuzzleManager.GetPuzzleInfoById(id)
        if not PuzzleInfos then
            return {}
        end

        return PuzzleInfos[id]
    end

    function XFubenActivityPuzzleManager.GetActivityInfo()
        return ActivityInfo
    end

    function XFubenActivityPuzzleManager.GetPieceTabelById(puzzleId)
        if not PieceTables[puzzleId] then
            PieceTables[puzzleId] = {}
        end

        return PieceTables[puzzleId]
    end

    function XFubenActivityPuzzleManager.GetPuzzlePieceTabelById(puzzleId)
        if not PuzzlePieceTables[puzzleId] then
            PuzzlePieceTables[puzzleId] = {}
        end

        return PuzzlePieceTables[puzzleId]
    end

    function XFubenActivityPuzzleManager.GetGotRewardIdxTableById(puzzleId)
        if not GotRewardIdxTables[puzzleId] then
            GotRewardIdxTables[puzzleId] = {}
        end

        return GotRewardIdxTables[puzzleId]
    end

    function XFubenActivityPuzzleManager.GetPuzzleStateById(puzzleId)
        if not PuzzleCompleteStateTable[puzzleId] then
            return XFubenActivityPuzzleConfigs.PuzzleState.Incomplete
        end

        return PuzzleCompleteStateTable[puzzleId]
    end

    function XFubenActivityPuzzleManager.CheckCompleteRewardIsGot(puzzleId)
        if not GotCompleteStateTables[puzzleId] then
            return XFubenActivityPuzzleConfigs.CompleteRewardState.Unrewarded
        end

        return GotCompleteStateTables[puzzleId]
    end

    function XFubenActivityPuzzleManager.GetPuzzlePieceByIndex(puzzleId, index)
        local puzzlePieceTable = XFubenActivityPuzzleManager.GetPuzzlePieceTabelById(puzzleId)
        return puzzlePieceTable[index]
    end

    function XFubenActivityPuzzleManager.ExchangePiece(puzzleId)
        if not ActivityInfo then
            return
        end

        local puzzleTemplate = XFubenActivityPuzzleConfigs.GetPuzzleTemplateById(puzzleId)
        if not puzzleTemplate then
            return
        end

        if XFubenActivityPuzzleManager.CheckIsSwitchOutPiece(puzzleTemplate) then -- 检查是否已经把全部碎片换完了
            XUiManager.TipText("DragPuzzleActivityAllPieceTaked")
            return
        end

        local itemId = ActivityInfo.ItemId
        if not XDataCenter.ItemManager.CheckItemCountById(itemId, puzzleTemplate.PieceItemCount) then -- 检查兑换碎片的道具是否充足
            XUiManager.TipText("DragPuzzleActivityItemNotEnough")
            return
        end

        XNetwork.Call(ACTIVITY_PUZZLE_PROTO.DragPuzzleActivityExchangePieceRequest, {PuzzleId = puzzleTemplate.Id}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            if not PieceTables[res.PuzzleId] then
                PieceTables[res.PuzzleId] = {}
            end
            
            if PieceTables[res.PuzzleId] then -- 校验是否发送了相同碎片
                for _, pieceInfo in pairs(PieceTables[res.PuzzleId]) do
                    if pieceInfo.Id == res.NewPiece.Id then
                        XLog.Error("CurrentPieceTable:", PieceTables[res.PuzzleId], "ServerResponse:", res)
                        XUiManager.TipError(CS.XTextManager.GetText("DragPuzzleActivityExchangePieceError"))
                        return
                    end
                end
            end

            tableInsert(PieceTables[res.PuzzleId], res.NewPiece)
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_DRAG_PUZZLE_GAME_GET_PIECE, res.PuzzleId)
            XEventManager.DispatchEvent(XEventId.EVENT_DRAG_PUZZLE_GAME_GET_PIECE)
        end)
    end

    function XFubenActivityPuzzleManager.CheckIsSwitchOutPiece(puzzleTemplate)
        if PieceTables[puzzleTemplate.Id] and PuzzlePieceTables[puzzleTemplate.Id] then
            local pieceCount = XTool.GetTableCount(PieceTables[puzzleTemplate.Id])
            local puzzlePieceCount = XTool.GetTableCount(PuzzlePieceTables[puzzleTemplate.Id])
            if (pieceCount + puzzlePieceCount) >= (puzzleTemplate.RowSize * puzzleTemplate.ColSize) then -- 检查是否已经把全部碎片换完了
                return true
            end
        end
    end

    function XFubenActivityPuzzleManager.CheckAreaRewardCanTake(puzzleId, index) -- 奖励的index
        local needBlockStr = XFubenActivityPuzzleConfigs.GetPuzzleTemplateById(puzzleId).RewardPiecesStr[index]
        local needBlockArr = string.ToIntArray(needBlockStr)
        for _, pieceIndex in pairs(needBlockArr) do
            if not XFubenActivityPuzzleManager.CheckPieceIsCorrect(puzzleId, pieceIndex) then
                return false
            end
        end

        return true
    end

    function XFubenActivityPuzzleManager.CheckPieceIsCorrect(puzzleId, index) -- 位置的index 1-15
        local puzzlePieceTable = XFubenActivityPuzzleManager.GetPuzzlePieceTabelById(puzzleId)
        local curIndexPieceId = puzzlePieceTable[index]
        if not curIndexPieceId then
            return false
        else
            local correctIdx = XFubenActivityPuzzleConfigs.GetPieceCorrectIdxById(curIndexPieceId)
            if correctIdx ~= index then
                return false
            else
                return true
            end
        end
    end

    function XFubenActivityPuzzleManager.GetPuzzlePieceSuccessCount(puzzleId)
        local puzzlePieceTable = XFubenActivityPuzzleManager.GetPuzzlePieceTabelById(puzzleId)
        local count = 0
        for index, info in pairs(puzzlePieceTable) do
            if XFubenActivityPuzzleManager.CheckPieceIsCorrect(puzzleId, index) then
                count = count + 1
            end
        end
        return count
    end

    function XFubenActivityPuzzleManager.CheckPuzzleIsOpen(index)
        if not PuzzleInfos or not next(PuzzleInfos) then
            return index == 1
        else
            if index == 1 then
                return true
            else
                local lastPuzzleState = XFubenActivityPuzzleManager.GetPuzzleStateById(PuzzleTemplates[index-1].Id)
                return (lastPuzzleState == XFubenActivityPuzzleConfigs.PuzzleState.Complete)
            end
        end
    end

    function XFubenActivityPuzzleManager.MovePiece(puzzleId, pieceId, targetIndex, cb)
        XNetwork.Call(ACTIVITY_PUZZLE_PROTO.DragPuzzleActivityMovePieceRequest,{PuzzleId = puzzleId, PieceId = pieceId, TargetIdx = targetIndex}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                CsXGameEventManager.Instance:Notify(XEventId.EVENT_DRAG_PUZZLE_GAME_PUZZLE_CHANGED, puzzleId) -- 报错根据数据还原界面
                return
            end

            if cb then
                cb(res)
            end
        end)
    end

    function XFubenActivityPuzzleManager.GetFirstPiece(puzzleId)
        if not PieceTables[puzzleId] or #PieceTables[puzzleId] <= 0 then
            return false, nil
        end

        return true, PieceTables[puzzleId][#PieceTables[puzzleId]]
    end

    function XFubenActivityPuzzleManager.MovePieceFormPieceTable(puzzleId, targetIndex)
        if not PieceTables[puzzleId] or #PieceTables[puzzleId] <= 0 then -- 检查待拼的碎片列表是否有碎片
            return
        end

        if not PuzzlePieceTables[puzzleId] then
            PuzzlePieceTables[puzzleId] = {}
            return
        end

        if PuzzlePieceTables[puzzleId][targetIndex] then -- 检查即将下落的拼图格子是否有碎片（从碎片列表拿出的只能放在空格子）
            XUiManager.TipText("DragPuzzleActivityTheBlockHasPiece")
            return
        end

        local pieceInfo = PieceTables[puzzleId][#PieceTables[puzzleId]]

        XFubenActivityPuzzleManager.MovePiece(puzzleId, pieceInfo.Id, targetIndex, function(res)
            local changedPieces = res.ChangedPieces
            for _, pieceInfo in pairs(changedPieces) do
                PuzzlePieceTables[res.PuzzleId][pieceInfo.Idx] = pieceInfo.Id
            end
            tableRemove(PieceTables[res.PuzzleId])
            if not PuzzleInfos[res.PuzzleId] then
                PuzzleInfos[res.PuzzleId] = {}
            end
            PuzzleCompleteStateTable[res.PuzzleId] = res.PuzzleState
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_DRAG_PUZZLE_GAME_PUZZLE_CHANGED, res.PuzzleId, targetIndex)
            XEventManager.DispatchEvent(XEventId.EVENT_DRAG_PUZZLE_GAME_PUZZLE_CHANGED)
            if res.PuzzleState == XFubenActivityPuzzleConfigs.PuzzleState.Complete then
                CsXGameEventManager.Instance:Notify(XEventId.EVENT_DRAG_PUZZLE_GAME_PUZZLE_COMPLETE, res.PuzzleId)
                XEventManager.DispatchEvent(XEventId.EVENT_DRAG_PUZZLE_GAME_PUZZLE_COMPLETE)
            elseif res.PuzzleState == XFubenActivityPuzzleConfigs.PuzzleState.PuzzleCompleteButNotDecryption then
                CsXGameEventManager.Instance:Notify(XEventId.EVENT_DRAG_PUZZLE_GAME_PUZZLE_DECRYPTION, res.PuzzleId)
            end
        end)
    end

    function XFubenActivityPuzzleManager.MovePieceFormPuzzle(puzzleId, pieceId, pieceIndex, targetIndex)
        if pieceIndex == targetIndex then -- 放入的位置是原来的位置
            return
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_DRAG_PUZZLE_GAME_PUZZLE_CHANGED, puzzleId, targetIndex)
        end

        if XFubenActivityPuzzleManager.CheckPieceIsCorrect(puzzleId, targetIndex) then -- 检查该碎片是否是正确的(正确的不能被拿起)
            return
        end

        if PuzzlePieceTables[puzzleId][targetIndex] and XFubenActivityPuzzleManager.CheckPieceIsCorrect(puzzleId, targetIndex) then -- 检查交换的位置是否已经放入正确的碎片
            XUiManager.TipText("DragPuzzleActivityTheBlockHasCorrectPiece")
            return
        end

        XFubenActivityPuzzleManager.MovePiece(puzzleId, pieceId, targetIndex, function(res)
            local changedPieces = res.ChangedPieces
            PuzzlePieceTables[res.PuzzleId][pieceIndex] = nil
            for _, pieceInfo in pairs(changedPieces) do
                PuzzlePieceTables[res.PuzzleId][pieceInfo.Idx] = pieceInfo.Id
            end
            
            if not PuzzleInfos[res.PuzzleId] then
                PuzzleInfos[res.PuzzleId] = {}
            end
            PuzzleCompleteStateTable[res.PuzzleId] = res.PuzzleState
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_DRAG_PUZZLE_GAME_PUZZLE_CHANGED, res.PuzzleId, targetIndex)
            XEventManager.DispatchEvent(XEventId.EVENT_DRAG_PUZZLE_GAME_PUZZLE_CHANGED)
            if res.PuzzleState == XFubenActivityPuzzleConfigs.PuzzleState.Complete then
                CsXGameEventManager.Instance:Notify(XEventId.EVENT_DRAG_PUZZLE_GAME_PUZZLE_COMPLETE, res.PuzzleId)
                XEventManager.DispatchEvent(XEventId.EVENT_DRAG_PUZZLE_GAME_PUZZLE_COMPLETE)
            elseif res.PuzzleState == XFubenActivityPuzzleConfigs.PuzzleState.PuzzleCompleteButNotDecryption then
                CsXGameEventManager.Instance:Notify(XEventId.EVENT_DRAG_PUZZLE_GAME_PUZZLE_DECRYPTION, res.PuzzleId)
            end
        end)
    end

    function XFubenActivityPuzzleManager.GetReward(puzzleId, index)
        if not XFubenActivityPuzzleManager.CheckAreaRewardCanTake(puzzleId ,index) then
            XUiManager.TipText("DragPuzzleActivityCanTakeReward")
            return 
        end

        if XFubenActivityPuzzleManager.IsRewardHasTaked(puzzleId, index) then
            return
        end

        XNetwork.Call(ACTIVITY_PUZZLE_PROTO.DragPuzzleActivityGetRewardRequest,{PuzzleId = puzzleId, RewardIdx = index}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local gotRewardIdxs = res.GotRewardIdxs
            for _, rewardIdx in pairs(gotRewardIdxs) do
                tableInsert(GotRewardIdxTables[res.PuzzleId], rewardIdx)
            end

            GotCompleteStateTables[res.PuzzleId] = res.CompleteRewardState

            local rewardGoods = res.RewardGoods
            XUiManager.OpenUiObtain(rewardGoods, CS.XTextManager.GetText("Award"))
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_DRAG_PUZZLE_GAME_GOT_REWARD, res.PuzzleId)
            XEventManager.DispatchEvent(XEventId.EVENT_DRAG_PUZZLE_GAME_GOT_REWARD, res.puzzleId)
        end)
    end

    function XFubenActivityPuzzleManager.IsRewardHasTaked(puzzleId, index)
        local gotRewardIdxTable = XFubenActivityPuzzleManager.GetGotRewardIdxTableById(puzzleId)
        for _, idx in pairs(gotRewardIdxTable) do
            if idx == index then
                return true
            end
        end

        return false
    end

    function XFubenActivityPuzzleManager.FindDefaultSelectTabIndex()
        for index, template in ipairs(PuzzleTemplates) do
            if not GotCompleteStateTables[template.Id] or GotCompleteStateTables[template.Id] == XFubenActivityPuzzleConfigs.CompleteRewardState.Unrewarded then
                return index
            end
        end

        return #PuzzleTemplates
    end

    function XFubenActivityPuzzleManager.CheckSwitchRedPoint()
        local hasRed = false
        SwitchRedPointDic = {}
        for index, template in pairs(PuzzleTemplates) do
            if XFubenActivityPuzzleManager.CheckPuzzleIsOpen(index)
            and XFubenActivityPuzzleManager.GetPuzzleStateById(template.Id) == XFubenActivityPuzzleConfigs.PuzzleState.Incomplete
            and not XFubenActivityPuzzleManager.CheckIsSwitchOutPiece(template)
            and XDataCenter.ItemManager.CheckItemCountById(ActivityInfo.ItemId, template.PieceItemCount) then
                SwitchRedPointDic[template.Id] = 1
                hasRed = true
            else
                SwitchRedPointDic[template.Id] = 0
            end
        end
        return hasRed
    end

    function XFubenActivityPuzzleManager.CheckHasSwitchRedPointById(puzzleId)
        local puzzleTemplate = XFubenActivityPuzzleConfigs.GetPuzzleTemplateById(puzzleId)
        if not puzzleTemplate then
            return false
        end

        if not XFubenActivityPuzzleManager.CheckIsSwitchOutPiece(puzzleTemplate) and
        XDataCenter.ItemManager.CheckItemCountById(ActivityInfo.ItemId, puzzleTemplate.PieceItemCount) then
            return true
        end

        return false
    end

    function XFubenActivityPuzzleManager.CheckAwardRedPoint()
        for index, template in pairs(PuzzleTemplates) do
            if XFubenActivityPuzzleManager.CheckPuzzleIsOpen(index) then
                if XFubenActivityPuzzleManager.GetPuzzleStateById(template.Id) == XFubenActivityPuzzleConfigs.PuzzleState.Incomplete then
                    local rewardIds = template.RewardId
                    for index, _ in ipairs(rewardIds) do
                        if XFubenActivityPuzzleManager.CheckAreaRewardCanTake(template.Id, index) and not XFubenActivityPuzzleManager.IsRewardHasTaked(template.Id, index) then
                            return true
                        end
                    end
                elseif XFubenActivityPuzzleManager.GetPuzzleStateById(template.Id) == XFubenActivityPuzzleConfigs.PuzzleState.Complete then
                    if XFubenActivityPuzzleManager.CheckCompleteRewardIsGot(template.Id) == XPuzzleActivityConfigs.PuzzleRewardState.Unrewarded then
                        return true
                    end
                end
            end
        end
    end

    function XFubenActivityPuzzleManager.CheckTabRedPointByIndex(index)
        local puzzleTmp = XFubenActivityPuzzleManager.GetPuzzleTemplateByIndex(index)
        if not XFubenActivityPuzzleManager.CheckPuzzleIsOpen(index) then
            return false
        end

        if XFubenActivityPuzzleManager.GetPuzzleStateById(puzzleTmp.Id) == XFubenActivityPuzzleConfigs.PuzzleState.Incomplete then -- 检测奖励
            local rewardIds = puzzleTmp.RewardId
            for index, _ in ipairs(rewardIds) do
                if XFubenActivityPuzzleManager.CheckAreaRewardCanTake(puzzleTmp.Id, index) and not XFubenActivityPuzzleManager.IsRewardHasTaked(puzzleTmp.Id, index) then
                    return true
                end
            end
        elseif XFubenActivityPuzzleManager.GetPuzzleStateById(puzzleTmp.Id) == XFubenActivityPuzzleConfigs.PuzzleState.Complete then
            if XFubenActivityPuzzleManager.CheckCompleteRewardIsGot(puzzleTmp.Id) == XPuzzleActivityConfigs.PuzzleRewardState.Unrewarded then
                return true
            end
        end

        if XFubenActivityPuzzleManager.CheckHasSwitchRedPointById(puzzleTmp.Id) then -- 检测兑换按钮
            return true
        end

        if XFubenActivityPuzzleManager.CheckVideoRedPoint(puzzleTmp.Id) then -- 检测剧情
            return true
        end

        if XFubenActivityPuzzleManager.CheckDecryptionRedPoint(puzzleTmp.Id) then -- 检测是否可以解密
            return true
        end

        return false
    end

    function XFubenActivityPuzzleManager.CheckVideoRedPoint(puzzleId)
        local puzzleTemplate = XFubenActivityPuzzleConfigs.GetPuzzleTemplateById(puzzleId)
        if not puzzleTemplate.CompleteStoryId or puzzleTemplate.CompleteStoryId == "" then
            return false
        end

        if XFubenActivityPuzzleManager.CheckCompleteRewardIsGot(puzzleId) == XPuzzleActivityConfigs.PuzzleRewardState.Unrewarded then
            return false
        end

        local isPlayedVideo = XSaveTool.GetData(string.format("%s%s%s", XPlayer.Id, XFubenActivityPuzzleConfigs.PLAY_VIDEO_STATE_KEY ,puzzleId))
        if isPlayedVideo and isPlayedVideo == XFubenActivityPuzzleConfigs.PlayVideoState.Played then
            return false
        end

        return true
    end

    function XFubenActivityPuzzleManager.CheckAllVideoRedPoint()
        for _, template in pairs(PuzzleTemplates) do
            if XFubenActivityPuzzleManager.CheckVideoRedPoint(template.Id) then
                return true
            end
        end

        return false
    end

    function XFubenActivityPuzzleManager.CheckDecryptionRedPoint(puzzleId)
        if not puzzleId then
            return false
        end

        if XFubenActivityPuzzleManager.GetPuzzleStateById(puzzleId) == XFubenActivityPuzzleConfigs.PuzzleState.PuzzleCompleteButNotDecryption then
            return true
        end

        return false
    end

    function XFubenActivityPuzzleManager.CheckAllPuzzleDecryptionRedPoint()
        for _, template in pairs(PuzzleTemplates) do
            if XFubenActivityPuzzleManager.CheckDecryptionRedPoint(template.Id) then
                return true
            end
        end

        return false
    end

    function XFubenActivityPuzzleManager.GetPasswordByPuzzleId(puzzleId)
        if not puzzleId then
            XLog.Error("PuzzleId or Index Can't Be Nil")
            return nil
        end

        if not DecryptionPasswordData[puzzleId] then
            XLog.Error("Can't Find Data DecryptionPasswordData By PuzzleId:"..puzzleId)
            return nil
        end

        return DecryptionPasswordData[puzzleId]
    end

    function XFubenActivityPuzzleManager.SetPasswordByPuzzleId(puzzleId, password)
        if not puzzleId then
            XLog.Error("PuzzleId Can't Be Nil")
            return
        end

        if not DecryptionPasswordData[puzzleId] then
            XLog.Error("Can't Find Data DecryptionPasswordData By PuzzleId:"..puzzleId)
            return
        end

        DecryptionPasswordData[puzzleId] = password
    end

    function XFubenActivityPuzzleManager.ExchangePassword(puzzleId, password)
        if not puzzleId then
            XLog.Error("PuzzleId Can't Be nil")
            return
        end

        if not password or not next(password) then
            XLog.Error("Password is Nil or Empty Table")
            return
        end
        XNetwork.Call(ACTIVITY_PUZZLE_PROTO.DragPuzzleActivityExchangePasswordRequest, {PuzzleId = puzzleId, Password = password}, function (res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            XFubenActivityPuzzleManager.SetPasswordByPuzzleId(puzzleId, password)
            PuzzleCompleteStateTable[puzzleId] = res.PuzzleState

            if PuzzleCompleteStateTable[puzzleId] == XFubenActivityPuzzleConfigs.PuzzleState.PuzzleCompleteButNotDecryption then
                CsXGameEventManager.Instance:Notify(XEventId.EVENT_DRAG_PUZZLE_GAME_PUZZLE_CHECK_WORD_ERROR, puzzleId)
            elseif PuzzleCompleteStateTable[puzzleId] == XFubenActivityPuzzleConfigs.PuzzleState.Complete then
                CsXGameEventManager.Instance:Notify(XEventId.EVENT_DRAG_PUZZLE_GAME_PUZZLE_COMPLETE, puzzleId)
                XEventManager.DispatchEvent(XEventId.EVENT_DRAG_PUZZLE_GAME_PUZZLE_COMPLETE)
            end
        end)
    end

    function XFubenActivityPuzzleManager.HitPasswordMessage(puzzleId)
        local hitCount = XSaveTool.GetData(string.format("%s%s%s", XFubenActivityPuzzleConfigs.PASSWORD_HIT_MESSAGE_COUNT, XPlayer.Id, puzzleId)) or 0
        hitCount = hitCount + 1
        local messageList = XFubenActivityBossSingleConfigs.GetPuzzlePasswordHintMessage(puzzleId)
        if messageList and next(messageList) then
            if messageList[hitCount] then
                XUiManager.TipError(messageList[hitCount])
            else
                XUiManager.TipError(messageList[#messageList])
            end
            XSaveTool.SaveData(string.format("%s%s%s", XFubenActivityPuzzleConfigs.PASSWORD_HIT_MESSAGE_COUNT, XPlayer.Id, puzzleId), hitCount)
        end
    end

    XFubenActivityPuzzleManager.Init()
    return XFubenActivityPuzzleManager
end