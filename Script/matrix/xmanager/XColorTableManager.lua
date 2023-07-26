local XExFubenActivityManager = require("XEntity/XFuben/XExFubenActivityManager")
local RankUpdateInterval = 300 -- 排行榜数据更新间隔

XColorTableManagerCreator = function()
	local XColorTableManager = XExFubenActivityManager.New(XFubenConfigs.ChapterType.ColorTable, "ColorTableManager")

    -- 自定义数据
    local TeamData = nil -- 队伍数据
    local FightStageId = nil -- 战斗关卡id

    -- 服务器下发确认的数据
    local ActivityId = 1 
    local CurStageId = 0 -- 当前在玩的关卡
    local UnlockHandbookDic = {} -- 已解锁的图鉴id列表
    local PassedStageIdDic = {} -- 已通关关卡id列表
    local ObtainCoinCnt = 0 -- 累积获得代币数量
    local DifficultyRewardIdDic = {} -- 已领取难度奖励id列表
    local RankDataDic = {} -- 排行榜数据
    local WinData = nil -- 战斗结算数据
    local GameManager = nil     -- 地图玩法业务管理

	function XColorTableManager.Init()
        XColorTableManager.InitGameManager()
	end

    function XColorTableManager.GetActivityId()
        return ActivityId
    end

    function XColorTableManager.IsOpen()
        if not XTool.IsNumberValid(ActivityId) or ActivityId == 0 then return false end
        local timeId = XColorTableConfigs.GetActivityTimeId(ActivityId)
        return XFunctionManager.CheckInTimeByTimeId(timeId)
    end

    function XColorTableManager.GetActivityEndTime()
        local config = XColorTableConfigs.GetColorTableActivity(ActivityId)
        if config then
            return XFunctionManager.GetEndTimeByTimeId(config.TimeId)
        else
            return 0
        end
    end

    function XColorTableManager.GetObtainCoinCnt()
        return ObtainCoinCnt
    end

    function XColorTableManager.GetActivitySaveKey()
        return string.format("ColorTableManager_GetActivitySaveKey_XPlayer.Id:%s_ActivityId:%s", XPlayer.Id, ActivityId)
    end

    -- 先播放剧情再开界面以防止系统引导开在剧情界面上
    function XColorTableManager.CheckMoviePlay(key, movieId, openUiCb)
        if not key or not movieId then
            if openUiCb then openUiCb() end
            return
        end
        if not XSaveTool.GetData(key) then
            -- 播放剧情不Release资源防止剧情结束恢复时重载资源卡顿
            XDataCenter.MovieManager.PlayMovie(movieId, openUiCb, nil, nil, false)
            XSaveTool.SaveData(key, true)
        else
            if openUiCb then openUiCb() end
        end
    end

------------------------------------------------ 地图玩法 begin ------------------------------------------------

    function XColorTableManager.InitGameManager()
        local script = require("XEntity/XColorTable/Game/XCTGameManager")
        GameManager = script.New()
    end

    -- 获取玩法管理器
    function XColorTableManager.GetGameManager()
        return GameManager
    end

    function XColorTableManager.EnterStageGame(stageId, captainId)
        GameManager:Init()

        if XTool.IsNumberValid(XColorTableManager.GetCurStageId()) then
            GameManager:RequestContinueGame(function()
                XLuaUiManager.Open("UiColorTableStageMain")
            end)
        else
            GameManager:RequestStartFight(stageId, captainId, function()
                XColorTableManager.SetCurStageId(stageId)
                XColorTableManager.CheckMoviePlay(
                    XColorTableManager.GetStageMovieKey(stageId),
                    XColorTableConfigs.GetStageMovieId(stageId),
                    function ()
                        XLuaUiManager.OpenWithCallback("UiColorTableStageMain" , function()
                            XLuaUiManager.Remove("UiColorTableStay")
                            XLuaUiManager.Remove("UiColorTableChoicePlay")
                            XDataCenter.GuideManager.CheckGuideOpen()	-- 触发引导
                        end)
                    end)
            end)
        end
    end

    function XColorTableManager.GetStageMovieKey(stageId)
        return XColorTableManager.GetActivitySaveKey() .. string.format("_UiColorTableStageMain_PlayMovie_stageId:%s", stageId)
    end

    function XColorTableManager.IsStageMoviePlayed(stageId)
        local key = XColorTableManager.GetStageMovieKey(stageId)
        return XSaveTool.GetData(key) == true    
    end

    function XColorTableManager.GiveUpGame(callBack)
        GameManager:RequestGiveUp(function(res)

            -- 打开结算界面
            XDataCenter.ColorTableManager.OpenUiSettleWin(res.LoseAction, CurStageId)

            -- 重置当前挑战关卡
            XColorTableManager.ClearCurStageId()

            if callBack then
                callBack()
            end
        end)
    end

    -- 获取当前地图玩法里领队id
    function XColorTableManager.GetGameCaptainId()
        local captainId = XColorTableConfigs.GetStageCaptainId(CurStageId)
        if captainId ~= 0 then
            return captainId
        end

        return GameManager:GetGameData():GetCaptainId()
    end

------------------------------------------------- 地图玩法 end -------------------------------------------------



-------------------------------------------------- 战斗 begin --------------------------------------------------

    function XColorTableManager.InitStageInfo()
        local configs = XColorTableConfigs.GetColorTableStage()
        for k, config in pairs(configs) do
            local normalStageInfo = XDataCenter.FubenManager.GetStageInfo(config.NormalStageId)
            normalStageInfo.Type = XDataCenter.FubenManager.StageType.ColorTable
            local specialStageInfo = XDataCenter.FubenManager.GetStageInfo(config.SpecialStageId)
            specialStageInfo.Type = XDataCenter.FubenManager.StageType.ColorTable
        end
    end

    function XColorTableManager.GetTeamData()
        if TeamData == nil then
            local teamId = XPlayer.Id .. "_XColorTableManager_TeamId"
            local XTeam = require("XEntity/XTeam/XTeam")
            TeamData = XTeam.New(teamId)
        end
        return TeamData
    end

    function XColorTableManager.OpenUiBattleRoleRoom(fightStageId)
        -- 去掉本关不支持的机器人
        local team = XColorTableManager.GetTeamData()
        local robotIds = XColorTableConfigs.GetStageRobotIds(CurStageId)
        for pos, entityId in ipairs(team:GetEntityIds()) do
            if XEntityHelper.GetIsRobot(entityId) then
                local isIn = table.contains(robotIds, entityId)
                if not isIn then
                    team:UpdateEntityTeamPos(entityId)
                end
            end
        end

        XLuaUiManager.Open("UiBattleRoleRoom", fightStageId, team
            , require("XUi/XUiColorTable/Grid/XUiColorTableBattleRoomProxy"))
    end

    function XColorTableManager.EnterFight(team, fightStageId)
        FightStageId = fightStageId
        XDataCenter.FubenManager.EnterColorTableFight(team, fightStageId)
    end

    -- 保存数据，在通用战斗回调里处理结算
    function XColorTableManager.SaveStageWinData(winData)
        WinData = winData
    end

    -- XFubenManager战斗结束后回调，处理结算
    function XColorTableManager.ShowReward(fightData)
        XColorTableManager.DealStageWinData(WinData)
    end

    -- 处理结算
    function XColorTableManager.DealStageWinData(data)
        local isFirstPass = not XDataCenter.ColorTableManager.IsStagePassed(data.CurStageId)

        -- 刷新通关关卡
        XDataCenter.ColorTableManager.SetPassedStageId(data.PassedStageId)
        XDataCenter.ColorTableManager.SavePassWinType(data.CurStageId, data.WinAction.WinConditionId)

        -- 打开结算界面
        XDataCenter.ColorTableManager.OpenUiSettleWin(data.WinAction, data.CurStageId, isFirstPass)

        if XLuaUiManager.IsUiLoad("UiColorTableStageMain") then
            XLuaUiManager.Remove("UiColorTableStageMain")
        end

        -- 重置当前挑战关卡
        XDataCenter.ColorTableManager.ClearCurStageId()
    end

    -- 打开结算界面
    function XColorTableManager.OpenUiSettleWin(data, curStageId, isFirstPass)
        local captainId = XColorTableManager.GetGameCaptainId()
        XLuaUiManager.OpenWithCallback("UiColorTableSettleWin", function()
            XLuaUiManager.Remove("UiColorTableStageMain")
        end, data, curStageId, captainId, isFirstPass)
    end

    -- 获取结算类型
    function XColorTableManager.GetWinType(winConditionId, stageId)
        if winConditionId and winConditionId ~= 0 then
            local config = XColorTableConfigs.GetColorTableStage(stageId)
            if config.NormalWinConditionId == winConditionId then
                return XColorTableConfigs.WinType.NormalWin
            elseif config.SpecialWinConditionId == winConditionId then
                return XColorTableConfigs.WinType.SpecialWin
            end
        end
        return XColorTableConfigs.WinType.Break
    end

    -- 保存胜利类型
    function XColorTableManager.SavePassWinType(stageId, winConditionId)
        local winType = XColorTableManager.GetWinType(winConditionId, stageId)
        if winType ~= XColorTableConfigs.WinType.Break then
            local key = XColorTableManager.GetPassWinTypeKey(stageId, winType)
            XSaveTool.SaveData(key, true)
        end
    end

    -- 是否通关过此胜利类型
    function XColorTableManager.IsPassWinType(stageId, winType)
        local key = XColorTableManager.GetPassWinTypeKey(stageId, winType)
        if XSaveTool.GetData(key) then
            return true
        end

        local winCond = XColorTableConfigs.GetStageSpecialWinConditionId(stageId)
        if XColorTableManager.IsStagePassed(stageId) and (winCond == nil or winCond == 0) then
            return true
        end

        return false
    end

    function XColorTableManager.GetPassWinTypeKey(stageId, winType)
        return XDataCenter.ColorTableManager.GetActivitySaveKey() .. tostring(stageId) .. "_" .. tostring(winType)
    end

-------------------------------------------------- 战斗 end --------------------------------------------------


-------------------------------------------------- 关卡 begin --------------------------------------------------

    function XColorTableManager.SetPassedStageId(passedStageId)
        for _, id in ipairs(passedStageId) do
            PassedStageIdDic[id] = true
        end
        -- 引导检测
        XDataCenter.GuideManager.CheckGuideOpen()
    end

    function XColorTableManager.IsStagePassed(stageId)
        return PassedStageIdDic[stageId] == true
    end

    function XColorTableManager.IsStageUnlock(stageId)
        local preStageId = XColorTableConfigs.GetStagePreStageId(stageId)
        local isUnlock = preStageId == 0 or XColorTableManager.IsStagePassed(preStageId)
        local desc = ""
        if not isUnlock then
            local preStageName = XColorTableConfigs.GetStageName(preStageId)
            desc = XUiHelper.GetText("CopyToOpen", preStageName)
        end
        return isUnlock, desc
    end

    function XColorTableManager.SetCurStageId(curStageId)
        CurStageId = curStageId
    end

    function XColorTableManager.GetCurStageId()
        return CurStageId
    end

    -- 是否在挑战中
    function XColorTableManager.IsChallenging()
        return CurStageId ~= 0
    end

    function XColorTableManager.ClearCurStageId()
        CurStageId = 0
    end

    function XColorTableManager.SetDifficultyRewardId(difficultyRewardId)
        for _, rewardId in ipairs(difficultyRewardId) do
            DifficultyRewardIdDic[rewardId] = true
        end
    end

    -- 是否已领取进度奖励
    function XColorTableManager.IsGetDifficultyReward(chapterId, difficultyType)
        local config = XColorTableConfigs.GetDifficultyRewardConfig(chapterId, difficultyType)
        return DifficultyRewardIdDic[config.Id]
    end

    function XColorTableManager.GetStageProgress(chapterId, difficultyType)
        local stageList = XColorTableConfigs.GetStageList(chapterId, difficultyType)
        local allCount = #stageList
        local passCount = 0
        for _, stage in ipairs(stageList) do
            local isPass = XColorTableManager.IsStagePassed(stage.Id)
            if isPass then   
                passCount = passCount + 1
            end
        end
        return passCount, allCount
    end

    function XColorTableManager.RequestRecvDifficultyReward(chapterId, difficultyType, cb)
        local config = XColorTableConfigs.GetDifficultyRewardConfig(chapterId, difficultyType)
        local request = { DifficultyRewardId = config.Id }
        XNetwork.Call("ColorTableRecvDifficultyRewardRequest", request, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            
            -- 弹窗奖励
            XUiManager.OpenUiObtain(res.RewardList)
            -- 设置奖励领取
            XColorTableManager.SetDifficultyRewardId({config.Id})
            -- 回调
            if cb then
                cb()
            end
        end)
    end

    function XColorTableManager.IsCaptainRole(entityId)
        local captainId = XColorTableManager.GetGameCaptainId()
        local captainCharIdList = XColorTableConfigs.GetCaptainCharacterIds(captainId) -- 领队加成的角色id列表
        for _, charId in ipairs(captainCharIdList or {}) do
            if charId == entityId then
                return true
            end
        end
        return false
    end

    function XColorTableManager.IsSpecialRole(entityId)
        local configs = XColorTableConfigs.GetColorTableSpecialRole()
        for _, config in pairs(configs) do
            if config.Id == entityId then
                return true
            end
        end

        return false
    end

    -- 获取关卡建议战力
    function XColorTableManager.GetStageAbilityTips(fightStageId)
        local config = XColorTableConfigs.GetColorTableStage(CurStageId)
        if fightStageId == config.NormalStageId then
            return config.NormalStageAbility
        elseif fightStageId == config.SpecialStageId then
            return config.SpecialStageAbility
        end

        return 0
    end

    -- 获取章节、难度的进度奖励红点
    function XColorTableManager.IsShowProgressRed(chapterId, difficultyType)
        local isGet = XColorTableManager.IsGetDifficultyReward(chapterId, difficultyType)
        if isGet then 
            return false 
        end

        local config = XColorTableConfigs.GetDifficultyRewardConfig(chapterId, difficultyType)
        if config == nil or config.RewardId == 0 then 
            return false
        end

        local passCount, allCount = XColorTableManager.GetStageProgress(chapterId, difficultyType)
        return passCount >= allCount
    end

    -- 检查所有章节是否有难度进度奖励可领取
    function XColorTableManager.CheckProgressRed()
        local configs = XColorTableConfigs.GetColorTableDifficultyReward()
        for _, config in ipairs(configs) do
            if XColorTableManager.IsShowProgressRed(config.ChapterId, config.DifficultyId) then
                return true
            end
        end
        return false
    end

-------------------------------------------------- 关卡 begin --------------------------------------------------


-------------------------------------------------- 任务 begin --------------------------------------------------

    function XColorTableManager.GetTaskGroupIdList()
        local config = XColorTableConfigs.GetColorTableActivity()
        return config[ActivityId].TaskGroupId
    end

    -- 检查所有任务是否有奖励可领取
    function XColorTableManager.CheckTaskCanReward()
        if not XColorTableManager.IsOpen() then
            return false
        end
        local groupIdList = XColorTableManager.GetTaskGroupIdList()
        for _, groupId in pairs(groupIdList) do
            if XDataCenter.TaskManager.CheckLimitTaskList(groupId) then
                return true
            end
        end
        return false
    end
    -------------------------------------------------- 任务 end --------------------------------------------------

    -------------------------------------------------- 排行榜 begin --------------------------------------------------

    function XColorTableManager.RequestRankInfo(stageId, cb)
        -- 有排行榜数据时检测是否失效，排行榜数据有效时间为：RankUpdateInterval
        if RankDataDic[stageId] then 
            local nowTime = XTime.GetServerNowTimestamp()
            if nowTime < (RankDataDic[stageId].RecordTime + RankUpdateInterval) then
                if cb then cb() end
                return
            end
        end

        -- 请求数据
        local request = { StageId = stageId }
        XNetwork.Call("ColorTableOpenRankRequest", request, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            res.RecordTime = XTime.GetServerNowTimestamp()
            RankDataDic[stageId] = res
            if cb then cb() end
        end)
    end

    function XColorTableManager.GetRankList(stageId)
        return RankDataDic[stageId].RankData.RankInfos
    end

    function XColorTableManager.GetMyRankInfo(stageId)
        local rankData = RankDataDic[stageId]
        local myRankInfo = XTool.Clone(rankData.PlayerRank)
        local minRankCnt = 5000 -- 排行榜人数，少于5000人按5000人计算
        local rankCnt = rankData.RankData.RankCount
        local percentRank = 100 -- 100名以上显示百分比
        rankCnt = rankCnt < minRankCnt and minRankCnt or rankCnt
        if myRankInfo.Rank > percentRank then
            myRankInfo.Rank = math.floor(myRankInfo.Rank * 100 / rankCnt) .. "%"
        end
        return myRankInfo
    end

    function XColorTableManager.GetRankSpecialIcon(rank)
        if type(rank) ~= "number" or rank < 1 or rank > 3 then return end
        local icon = CS.XGame.ClientConfig:GetString("BabelTowerRankIcon"..rank) 
        return icon
    end

    -------------------------------------------------- 排行榜 end --------------------------------------------------

    -------------------------------------------------- 遭遇图鉴 begin --------------------------------------------------

    function XColorTableManager.SetUnlockHandbooks(unlockHandbooks)
        for _, id in ipairs(unlockHandbooks) do
            UnlockHandbookDic[id] = true
        end
    end

    function XColorTableManager.IsHandbookUnlock(id)
        return UnlockHandbookDic[id] == true
    end

    function XColorTableManager.IsDramaUnlock(dramaId)
        local handBookId = XColorTableConfigs.GetHandBookIdByDramaId(dramaId)
        return XColorTableManager.IsHandbookUnlock(handBookId)
    end

    function XColorTableManager.SetDramaPlayed(dramaId)
        local key = XColorTableManager.GetDramaPlayedSaveKey(dramaId)
        XSaveTool.SaveData(key, true)
    end

    function XColorTableManager.IsDramaPlayed(dramaId)
        local key = XColorTableManager.GetDramaPlayedSaveKey(dramaId)
        return XSaveTool.GetData(key) == true
    end

    function XColorTableManager.GetDramaPlayedSaveKey(dramaId)
        return XColorTableManager.GetActivitySaveKey() .. string.format("_ColorTableManager_GetDramaPlayedSaveKey_dramaId:%s", dramaId)
    end

    function XColorTableManager.IsStoryRed()
        for id, _ in pairs(UnlockHandbookDic) do
            local handBookConfig = XColorTableConfigs.GetColorTableHandbook(id)
            if handBookConfig.Type == XColorTableConfigs.HandBookType.Drama then
                local isPlayed = XColorTableManager.IsDramaPlayed(handBookConfig.DramaId)
                if not isPlayed then 
                    return true
                end
            end
        end

        return false
    end

    -------------------------------------------------- 遭遇图鉴 end --------------------------------------------------

    -------------------------------------------------- 商店 begin --------------------------------------------------

    function XColorTableManager.SetObtainCoinCnt(obtainCoinCnt)
        ObtainCoinCnt = obtainCoinCnt or 0
    end

    function XColorTableManager.GetActivityShopIds()
        local shopIds = {}
        local configs = XColorTableConfigs.GetColorTableShop()
        for _, config in ipairs(configs) do
            table.insert(shopIds, config.ShopId)
        end
        return shopIds
    end

    function XColorTableManager.OpenUiShop()
        if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon) 
            or XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopActive) then
            
            local shopIds = XColorTableManager.GetActivityShopIds()
            XShopManager.GetShopInfoList(shopIds, function()
                XLuaUiManager.Open("UiColorTableShop")
            end, XShopManager.ActivityShopType.ColortableShop)
        end
    end

    function XColorTableManager.CheckShopUnlockTipsUi()
        local configs = XColorTableConfigs.GetColorTableShop()
        for _, config in ipairs(configs) do
            local conditionIdList = XShopManager.GetShopConditionIdList(config.ShopId)
            if config.UnlockTips and conditionIdList and #conditionIdList > 0 then
                local isOpen = XConditionManager.CheckCondition(conditionIdList[1])
                local saveKey = XColorTableManager.GetShopUnlockKey(config.ShopId)
                if isOpen and not XSaveTool.GetData(saveKey) then
                    XLuaUiManager.Open("UiColorTableShopTips", config.UnlockTips)
                    XSaveTool.SaveData(saveKey, true)
                end
            end
        end
    end

    function XColorTableManager.GetShopUnlockKey(shopId)
        return XColorTableManager.GetActivitySaveKey() .. string.format("_ShopUnlockKey_shopId:%s", shopId)
    end
    -------------------------------------------------- 商店 end --------------------------------------------------


    -------------------------------------------------- 副本入口扩展 begin --------------------------------------------------
    function XColorTableManager.ExOpenMainUi()
        --功能没开启
        if not XFunctionManager.DetectionFunction(XColorTableManager.ExGetFunctionNameType()) then
            return
        end
        --活动没开放
        if not XColorTableManager.IsOpen() then
            XUiManager.TipText("CommonActivityNotStart")
            return
        end
        XColorTableManager.CheckMoviePlay(
            XDataCenter.ColorTableManager.GetActivitySaveKey() .. "_UiColorTableMain_PlayMovie",
            XColorTableConfigs.GetActivityMovieId(ActivityId),
            function ()
                XLuaUiManager.Open("UiColorTableMain")
            end
        )
    end

    function XColorTableManager.ExGetProgressTip()
        if XColorTableManager.IsChallenging() then
            return XUiHelper.GetText("InChallenge")
        else
            local allPassCount = 0
            local allCount = 0
            local chapterConfigs = XColorTableConfigs.GetColorTableChapter()
            for chapterId, _ in ipairs(chapterConfigs) do
                local norPass, norAll = XColorTableManager.GetStageProgress(chapterId, XColorTableConfigs.StageDifficultyType.Normal)
                allPassCount = allPassCount + norPass
                allCount = allCount + norAll

                local difPass, difAll = XColorTableManager.GetStageProgress(chapterId, XColorTableConfigs.StageDifficultyType.Difficult)
                allPassCount = allPassCount + difPass
                allCount = allCount + difAll
            end
            return XUiHelper.GetText("ActivityBossSingleProcess", allPassCount, allCount)
        end
    end

    function XColorTableManager.ExGetFunctionNameType()
        return XFunctionManager.FunctionName.ColorTable
    end
    -------------------------------------------------- 副本入口扩展 end --------------------------------------------------


    -- 服务器刷新
    function XColorTableManager.RefreshDataByServer(data)
        ActivityId = data.ActivityId
        -- 当前在玩的关卡id
        XColorTableManager.SetCurStageId(data.CurStageId)
        -- 解锁图鉴
        XColorTableManager.SetUnlockHandbooks(data.Handbooks)
        -- 通关关卡
        XColorTableManager.SetPassedStageId(data.PassedStageId)
        -- 累积获得代币数量
        XColorTableManager.SetObtainCoinCnt(data.ObtainCoinCount)
        -- 已领取难度奖励id
        XColorTableManager.SetDifficultyRewardId(data.DifficultyRewardId)
    end


	XColorTableManager.Init()
	return XColorTableManager
end


-- =========网络=========
XRpc.NotifyColorTableActivityData = function(data)
    XDataCenter.ColorTableManager.RefreshDataByServer(data)
end

XRpc.NotifyColorTableAddHandbook = function(data)
    XDataCenter.ColorTableManager.SetUnlockHandbooks({data.HandbookId})
end

XRpc.NotifyObtainCoinChange = function(data)
    XDataCenter.ColorTableManager.SetObtainCoinCnt(data.ObtainCoinCount)
end

XRpc.NotifyColorTableStageWin = function(data)
    XDataCenter.ColorTableManager.SaveStageWinData(data)
end