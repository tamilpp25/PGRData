local XGoldenMinerRankData = require("XEntity/XGoldenMiner/XGoldenMinerRankData")
local XGoldenMinerDataDb = require("XEntity/XGoldenMiner/XGoldenMinerDataDb")
local XTeam = require("XEntity/XTeam/XTeam")

XGoldenMinerManagerCreator = function()
    local XGoldenMinerManager = {}
    local _GoldenMinerDataDb = XGoldenMinerDataDb.New()
    local _GoldenMinerRankData = XGoldenMinerRankData.New()
    local _Team
    local _CurActivityId
    local _UseItemCd = 0
    local _CurCharacterId

    local GetCookiesKey = function(key)
        return "XGoldenMinerManager_" .. XPlayer.Id .. "_" .. _CurActivityId or "" .. "_" .. key
    end

    local GetFirstOpenHelpKey = function()
        return GetCookiesKey("FirstOpenHelp")
    end

    --检测首次自动打开帮助
    function XGoldenMinerManager.CheckFirstOpenHelp()
        local key = GetFirstOpenHelpKey()
        local data = XSaveTool.GetData(key)
        if not data then
            XSaveTool.SaveData(key, true)
            return true
        end
        return false
    end

    function XGoldenMinerManager.GetGoldenMinerDataDb()
        return _GoldenMinerDataDb
    end

    function XGoldenMinerManager.GetGoldenMinerRankData()
        return _GoldenMinerRankData
    end

    function XGoldenMinerManager.GetDefaultActivityId()
        local configs = XGoldenMinerConfigs.GetGoldenMinerActivity()
        local defaultId
        for id, v in pairs(configs) do
            if XFunctionManager.CheckInTimeByTimeId(v.TimeId) then
                return id
            end
            if XTool.IsNumberValid(v.TimeId) then
                defaultId = id
            end
        end
        return defaultId
    end

    function XGoldenMinerManager.CatchCurCharacterId(characterId)
        _CurCharacterId = characterId
    end

    function XGoldenMinerManager.GetUseCharacterId()
        local characterId = XGoldenMinerManager.GetGoldenMinerDataDb():GetCharacterId()
        local dataDb = XGoldenMinerManager.GetGoldenMinerDataDb()
        if XTool.IsNumberValid(characterId) and XGoldenMinerManager.IsCharacterUnLock(characterId) then
            return characterId
        end

        characterId = _CurCharacterId
        if XTool.IsNumberValid(characterId) and XGoldenMinerManager.IsCharacterUnLock(characterId) then
            return characterId
        end

        local pos = 1
        local team = XGoldenMinerManager.GetTeam()
        local characterConfig = XGoldenMinerConfigs.GetGoldenMinerCharacter()
        local condition
        for id, v in pairs(characterConfig) do
            if XGoldenMinerManager.IsCharacterUnLock(id) then
                characterId = id
                break
            end
        end
        team:UpdateEntityTeamPos(characterId, pos, true)

        return team:GetEntityIdByTeamPos(pos)
    end

    function XGoldenMinerManager.GetTeam()
        if not _Team then
            _Team = XTeam.New("GoldenMiner")
        end
        return _Team
    end

    function XGoldenMinerManager.IsOpen()
        if not XTool.IsNumberValid(_CurActivityId) then return false end
        local timeId = XGoldenMinerConfigs.GetActivityTimeId(_CurActivityId)
        return XFunctionManager.CheckInTimeByTimeId(timeId)
    end

    function XGoldenMinerManager.GetActivityStartTime()
        if not XTool.IsNumberValid(_CurActivityId) then return 0 end
        local timeId = XGoldenMinerConfigs.GetActivityTimeId(_CurActivityId)
        return XFunctionManager.GetStartTimeByTimeId(timeId)
    end

    function XGoldenMinerManager.GetActivityEndTime()
        if not XTool.IsNumberValid(_CurActivityId) then return 0 end
        local timeId = XGoldenMinerConfigs.GetActivityTimeId(_CurActivityId)
        return XFunctionManager.GetEndTimeByTimeId(timeId)
    end

    function XGoldenMinerManager.GetCurActivityId()
        return _CurActivityId
    end

    function XGoldenMinerManager.HandleActivityEndTime()
        XLuaUiManager.RunMain()
        XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
    end

    function XGoldenMinerManager.OnOpenMain()
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.GoldenMiner) then
            return
        end
        if not XGoldenMinerManager.IsOpen() then
            XUiManager.TipText("CommonActivityNotStart")
            return
        end

        XLuaUiManager.Open("UiGoldenMinerMain")
    end

    --当检测到玩家有因为游戏进程退出，导致未完成的游玩挑战时，再次打开主界面会弹出提示框（每次登录只会主动弹出一次）
    local _IsCheckAutoOpenKeepBattleTips = true
    function XGoldenMinerManager.GetIsAutoOpenKeepBattleTips()
        if not _IsCheckAutoOpenKeepBattleTips then
            return false
        end
        return XGoldenMinerManager.IsCanKeepBattle()
    end

    function XGoldenMinerManager.SetIsAutoOpenKeepBattleTips(isCheck)
        _IsCheckAutoOpenKeepBattleTips = isCheck
    end

    function XGoldenMinerManager.IsCanKeepBattle()
        local dataDb = XGoldenMinerManager.GetGoldenMinerDataDb()
        local curStageId = dataDb:GetCurStageId()
        return XTool.IsNumberValid(curStageId)
    end

    function XGoldenMinerManager.GetTaskDataList(taskGroupId)
        local taskIdList = XGoldenMinerConfigs.GetTaskIdList(taskGroupId)
        local taskList = {}
        local tastData
        for _, taskId in pairs(taskIdList) do
            tastData = XDataCenter.TaskManager.GetTaskDataById(taskId)
            if tastData then
                table.insert(taskList, tastData)
            end
        end

        local achieved = XDataCenter.TaskManager.TaskState.Achieved
        local finish = XDataCenter.TaskManager.TaskState.Finish
        table.sort(taskList, function(a, b)
            if a.State ~= b.State then
                if a.State == achieved then
                    return true
                end
                if b.State == achieved then
                    return false
                end
                if a.State == finish then
                    return false
                end
                if b.State == finish then
                    return true
                end
            end

            local templatesTaskA = XDataCenter.TaskManager.GetTaskTemplate(a.Id)
            local templatesTaskB = XDataCenter.TaskManager.GetTaskTemplate(b.Id)
            return templatesTaskA.Priority > templatesTaskB.Priority
        end)

        return taskList
    end

    function XGoldenMinerManager.IsUseItem(itemIndex)
        if _UseItemCd > XTime.GetServerNowTimestamp() then
            XUiManager.TipErrorWithKey("GoldenMinerUseItemCd")
            return false
        end

        local dataDb = XGoldenMinerManager.GetGoldenMinerDataDb()
        if not dataDb:IsUseItem(itemIndex) then
            return false
        end

        _UseItemCd = XTime.GetServerNowTimestamp() + XGoldenMinerConfigs.GetUseItemCd()
        return true
    end

    --获得当前拥有的所有buffId
    --isGetNotIcon：是否包含没配置图标的
    function XGoldenMinerManager.GetOwnBuffIdList(isGetNotIcon)
        local ownBuffIdList = {}
        local dataDb = XGoldenMinerManager.GetGoldenMinerDataDb()
        local upgradeList = dataDb:GetAllUpgradeStrengthenList()
        local buffIdList
        local buffId
        local buffIcon

        local insertFunc = function(buffId)
            buffIcon = XTool.IsNumberValid(buffId) and XGoldenMinerConfigs.GetBuffIcon(buffId)
            if not string.IsNilOrEmpty(buffIcon) then
                table.insert(ownBuffIdList, buffId)
            end
        end

        --强化升级项
        for _, strengthenDb in ipairs(upgradeList) do
            buffId = strengthenDb:GetBuffId()
            insertFunc(buffId)
        end

        --角色自带buff
        local curSelectCharacterId = dataDb:GetCharacterId()
        if XTool.IsNumberValid(curSelectCharacterId) then
            buffIdList = XGoldenMinerConfigs.GetCharacterBuffIds(curSelectCharacterId)
            for _, buffId in ipairs(buffIdList) do
                insertFunc(buffId)
            end
        end

        --购买的道具类型为2的buff
        local buffColumns = dataDb:GetBuffColumns()
        for _, buffColumn in pairs(buffColumns) do
            insertFunc(buffColumn:GetBuffId())
        end

        return ownBuffIdList
    end

    --获得当前拥有的所有buff，叠加相同类型的buff
    function XGoldenMinerManager.GetOwnBuffDic()
        local ownBuffDic = {}
        local dataDb = XGoldenMinerManager.GetGoldenMinerDataDb()
        local upgradeList = dataDb:GetAllUpgradeStrengthenList()
        local buffIdList
        local buffId
        local buffType
        local params

        --强化升级项
        for _, strengthenDb in ipairs(upgradeList) do
            buffId = strengthenDb:GetBuffId()
            XGoldenMinerManager.AddBuff(ownBuffDic, buffId)
        end

        --角色自带buff
        local curSelectCharacterId = dataDb:GetCharacterId()
        if XTool.IsNumberValid(curSelectCharacterId) then
            buffIdList = XGoldenMinerConfigs.GetCharacterBuffIds(curSelectCharacterId)
            for _, buffId in ipairs(buffIdList) do
                XGoldenMinerManager.AddBuff(ownBuffDic, buffId)
            end
        end

        --购买的道具类型为2的buff
        local buffColumns = dataDb:GetBuffColumns()
        for _, buffColumn in pairs(buffColumns) do
            XGoldenMinerManager.AddBuff(ownBuffDic, buffColumn:GetBuffId())
        end

        return ownBuffDic
    end

    function XGoldenMinerManager.AddBuff(ownBuffDic, buffId)
        if not XTool.IsNumberValid(buffId) then
            return
        end

        local buffType = XGoldenMinerConfigs.GetBuffType(buffId)
        if buffType == XGoldenMinerConfigs.BuffType.GoldenMinerInitItem or
            buffType == XGoldenMinerConfigs.BuffType.GoldenMinerInitScores then
            return
        end

        local paramsTemp = {}
        local params = XGoldenMinerConfigs.GetBuffParams(buffId)
        --不同类型的抓取物分数提升叠加buff
        if buffType == XGoldenMinerConfigs.BuffType.GoldenMinerStoneScore then
            if not ownBuffDic[buffType] then
                ownBuffDic[buffType] = {}
            end

            local goldenMinerStoneType = params[1]
            if not ownBuffDic[buffType][goldenMinerStoneType] then
                ownBuffDic[buffType][goldenMinerStoneType] = params
                return
            end
            
            for i, param in ipairs(ownBuffDic[buffType][goldenMinerStoneType]) do
                --参数1是GoldenMinerStoneType
                if i ~= 1 then
                    paramsTemp[i] = param + (params[i] or 0)
                end
            end
            ownBuffDic[buffType][goldenMinerStoneType] = paramsTemp
            return
        end

        if not ownBuffDic[buffType] then
            ownBuffDic[buffType] = params
            return
        end
        for i, param in ipairs(ownBuffDic[buffType]) do
            paramsTemp[i] = param + (params[i] or 0)
        end
        ownBuffDic[buffType] = paramsTemp
    end

    function XGoldenMinerManager.GetActivityChapters()
        local chapters = {}
        if XGoldenMinerManager.IsOpen() then
            local temp = {}
            local activityId = XGoldenMinerManager.GetCurActivityId()
            temp.Id = activityId
            temp.Name = XGoldenMinerConfigs.GetActivityName(activityId)
            temp.BannerBg = XGoldenMinerConfigs.GetActivityBannerBg(activityId)
            temp.Type = XDataCenter.FubenManager.ChapterType.GoldenMiner
            table.insert(chapters, temp)
        end
        return chapters
    end

    --角色是否解锁
    function XGoldenMinerManager.IsCharacterUnLock(characterId)
        local condition = XGoldenMinerConfigs.GetCharacterCondition(characterId)
        return not XTool.IsNumberValid(condition) or XGoldenMinerManager.GetGoldenMinerDataDb():IsCharacterActive(characterId)
    end

    function XGoldenMinerManager.GetCharacterIdList()
        local useCharacterId = XGoldenMinerManager.GetUseCharacterId()
        local characterIdList = XGoldenMinerConfigs.GetCharacterIdList()
        table.sort(characterIdList, function(idA, idB)
            --当前选择的角色Id
            if idA == useCharacterId then
                return true
            end
            if idB == useCharacterId then
                return false
            end

            --已解锁
            local isUnlockA = XGoldenMinerManager.IsCharacterUnLock(idA)
            local isUnlockB = XGoldenMinerManager.IsCharacterUnLock(idB)
            if isUnlockA ~= isUnlockB then
                return isUnlockA
            end

            return idA < idB
        end)

        return characterIdList
    end

    ------------------红点相关 begin-----------------------
    --检查是否有任务奖励可领取
    function XGoldenMinerManager.CheckTaskCanReward()
        local configs = XGoldenMinerConfigs.GetGoldenMinerTask()
        for id in pairs(configs) do
            if XGoldenMinerManager.CheckTaskCanRewardByGoldenMinerTaskId(id) then
                return true
            end
        end
        return false
    end

    function XGoldenMinerManager.CheckTaskCanRewardByGoldenMinerTaskId(goldenMinerTaskId)
        local taskIdList = XGoldenMinerConfigs.GetTaskIdList(goldenMinerTaskId)
        for _, taskId in ipairs(taskIdList) do
            if XDataCenter.TaskManager.CheckTaskAchieved(taskId) then
                return true
            end
        end
        return false
    end
    ------------------红点相关 end------------------------

    ---------------------protocol begin------------------
    --完成关卡
    function XGoldenMinerManager.RequestGoldenMinerFinishStage(id, settlementInfo, curMapScore, cb, isWin)
        local stageScore = settlementInfo:GetScores()
        local req = {
            Id = id,    --关卡id
            SettlementInfo = settlementInfo:GetReqServerData() --结算后的数据
        }

        XNetwork.Call("GoldenMinerFinishStageRequest", req, function(res)
            local dataDb = XGoldenMinerManager.GetGoldenMinerDataDb()
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)

                --超过限定分数
                if res.Code == XCode.GoldenMinerStageScoresIsMax then
                    dataDb:UpdateCurrentPlayStage(0)
                    dataDb:CoverItemColums()
                    if dataDb:GetCurStageIsFirst() then
                        dataDb:ResetData()
                    end
                end

                if cb then
                    cb(false)
                end
                return
            end

            dataDb:UpdateCurrentPlayStage(res.MinerDataDb.CurrentPlayStage)
            dataDb:UpdateStageScores(stageScore)
            local nextStageId = dataDb:GetCurrentPlayStage()
            if not XTool.IsNumberValid(nextStageId) then
                dataDb:UpdateCurClearData(curMapScore, isWin)
            end

            dataDb:UpdateData(res.MinerDataDb)

            if cb then
                cb(true)
            end
        end)
    end

    --选择角色进入游戏
    function XGoldenMinerManager.RequestGoldenMinerEnterGame(useCharacter, cb)
        local req = {
            UseCharacter = useCharacter,
        }
        XNetwork.CallWithAutoHandleErrorCode("GoldenMinerEnterGameRequest", req, function(res)
            XGoldenMinerManager.GetGoldenMinerDataDb():UpdateData(res.MinerDataDb)
            if cb then
                cb()
            end
        end)
    end

    --飞船升级
    function XGoldenMinerManager.RequestGoldenMinerShipUpgrade(id, levelIndex, cb)
        local req = {
            Id = id,    --技能id
            LevelIndex = levelIndex, --等级下标（从0开始）
        }
        XNetwork.CallWithAutoHandleErrorCode("GoldenMinerShipUpgradeRequest", req, function(res)
            local dataDb = XGoldenMinerManager.GetGoldenMinerDataDb()
            dataDb:UpdateStageScores(res.Scores)    --剩余的积分
            dataDb:UpdateUpgradeStrengthenLevel(id, levelIndex)
            if cb then
                cb()
            end
            XUiManager.TipText("UpLevelSuccess")
        end)
    end

    --商店购买
    function XGoldenMinerManager.RequestGoldenMinerShopBuy(shopIndex, itemIndex, cb)
        local req = {
            ShopIndex = shopIndex - 1, --MinerShopDbs的下标
            ItemIndex = itemIndex, --放置的道具栏下标
        }
        XNetwork.CallWithAutoHandleErrorCode("GoldenMinerShopBuyRequest", req, function(res)
            local dataDb = XGoldenMinerManager.GetGoldenMinerDataDb()
            dataDb:UpdateStageScores(res.Scores)    --剩余的积分

            local goldenMinerCommodityDb = dataDb:GetMinerShopDbByIndex(shopIndex)
            local itemId = goldenMinerCommodityDb:GetGoldItemId()
            if itemIndex then
                dataDb:UpdateItemColumn(itemId, itemIndex)
            else
                dataDb:UpdateBuffColumn(itemId)
            end
            goldenMinerCommodityDb:UpdateBuyStatus(1)

            if cb then
                cb()
            end
            XUiManager.TipText("BuySuccess")
        end)
    end

    --请求排行榜数据
    function XGoldenMinerManager.RequestGoldenMinerRanking(cb)
        XNetwork.CallWithAutoHandleErrorCode("GoldenMinerRankingRequest", nil, function(res)
            _GoldenMinerRankData:UpdateData(res)
            if cb then
                cb()
            end
        end)
    end

    --退出关卡
    function XGoldenMinerManager.RequestGoldenMinerExitGame(stageId, cb, settlementInfo, curMapScore, beforeScore)
        local req = {
            StageId = stageId,   --退出的关卡id
            SettlementInfo = settlementInfo:GetReqServerData() --结算后的数据
        }
        local score = curMapScore
        XNetwork.Call("GoldenMinerExitGameRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                score = beforeScore
            end

            local dataDb = XGoldenMinerManager.GetGoldenMinerDataDb()
            dataDb:UpdateCurClearData(score)
            dataDb:ResetData()
            dataDb:UpdateTotalMaxScores(res.TotalMaxScores)
            if cb then
                cb()
            end
        end)
    end

    --进入关卡
    function XGoldenMinerManager.RequestGoldenMinerEnterStage(stageId, cb)
        local req = {
            StageId = stageId   --进入的关卡id
        }
        XNetwork.CallWithAutoHandleErrorCode("GoldenMinerEnterStageRequest", req, function(res)
            local dataDb = XGoldenMinerManager.GetGoldenMinerDataDb()
            dataDb:BackupsItemColums()
            if cb then
                cb()
            end
        end)
    end

    --更新新解锁的角色卡
    function XGoldenMinerManager.NotifyGoldenMinerCharacterProgress(data)
        local dataDb = XGoldenMinerManager.GetGoldenMinerDataDb()
        dataDb:UpdateNewCharacter(data.UnlockCharacter)
        dataDb:UpdateRedEnvelopeProgress(data.RedEnvelopeProgress)
    end

    --通知当前游戏流程数据
    function XGoldenMinerManager.NotifyGoldenMinerGameInfo(data)
        _CurActivityId = data.StageDataDb.ActivityId
        local dataDb = XGoldenMinerManager.GetGoldenMinerDataDb()
        dataDb:UpdateData(data.StageDataDb)
        dataDb:BackupsItemColums()
    end
    ---------------------protocol end--------------------

    _CurActivityId = XGoldenMinerManager.GetDefaultActivityId()
    return XGoldenMinerManager
end

---------------------(服务器推送)begin------------------
XRpc.NotifyGoldenMinerCharacterProgress = function(data)
    XDataCenter.GoldenMinerManager.NotifyGoldenMinerCharacterProgress(data)
end

XRpc.NotifyGoldenMinerGameInfo = function(data)
    XDataCenter.GoldenMinerManager.NotifyGoldenMinerGameInfo(data)
end
---------------------(服务器推送)end--------------------