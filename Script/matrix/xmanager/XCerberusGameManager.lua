local XCerberusGameStoryPoint = require("XEntity/XCerberusGame/XCerberusGameStoryPoint")
local XCerberusGameStage = require("XEntity/XCerberusGame/XCerberusGameStage")

-- 关系图
-- 剧情模式路线 → (复数个)XStoryPoint → (1个)XStage 
-- 挑战模式 → (复数个)Boss → (复数个)XStage
-- *XStage耦合XTeam，每个Stage单独记录一个队伍
XCerberusGameManagerCreator = function()
    ---@class XCerberusGameManager
    local XCerberusGameManager = {}

    local ActivityId = nil
    --------- 数据字典
    -- 剧情模式节点字典
    ---@type table<number, XCerberusGameStoryPoint>
    local StoryPointDic = {}
    ---@type table<number, XCerberusGameStage>
    local StageIdDataDic = {}
    local StageTeamInfoByServer = {}
    local AllStoryStageIdDic = {}
    local AllChallengeStageIdDic = {}
    --------- 临时变量
    ---@type XCerberusGameStoryPoint
    local LastSelectXStoryPoint = nil
    local LastSelectStoryLineDifficulty = nil

    function XCerberusGameManager.Init()
    end
    
    --战斗相关接口
    --region
    function XCerberusGameManager.InitStageInfo()
        -- 剧情关stage
        local allConfigsStory = XCerberusGameConfig.GetAllConfigs(XCerberusGameConfig.TableKey.CerberusGameStoryPoint)
        for k, config in pairs(allConfigsStory) do
            if config.StoryPointType == XCerberusGameConfig.StoryPointType.Battle or config.Type == XCerberusGameConfig.StoryPointType.Story then
                local stageId = tonumber(config.StoryPointTypeParams[1])
                local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId) -- 1号位就是stageId
                stageInfo.Type = XDataCenter.FubenManager.StageType.CerberusGame
                AllStoryStageIdDic[stageId] = stageId
            end
        end

        -- 挑战关stage
        local allConfigsChallenge = XCerberusGameConfig.GetAllConfigs(XCerberusGameConfig.TableKey.CerberusGameChallenge)
        for stageId, v in pairs(allConfigsChallenge) do
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
            stageInfo.Type = XDataCenter.FubenManager.StageType.CerberusGame
            AllChallengeStageIdDic[stageId] = stageId
        end
    end

    function XCerberusGameManager.CheckPassedByStageId(stageId)
        return XCerberusGameManager.GetXStageById(stageId):GetIsPassed()
    end

    function XCerberusGameManager.SetLastSelectXStoryPoint(xStoryPoint)
        LastSelectXStoryPoint = xStoryPoint
    end

    function XCerberusGameManager.GetLastSelectXStoryPoint()
        return LastSelectXStoryPoint
    end

    function XCerberusGameManager.SetLastSelectStoryLineDifficulty(difficulty)
        LastSelectStoryLineDifficulty = difficulty
    end

    function XCerberusGameManager.GetLastSelectStoryLineDifficulty()
        return LastSelectStoryLineDifficulty
    end

    function XCerberusGameManager.PreFight(stage, xTeam, isAssist, challengeCount)
        local xStage = XCerberusGameManager.GetXStageById(stage.StageId)
        local preFight = {}
        preFight.CardIds = xTeam:GetCharacterIdsOrder()
        preFight.RobotIds = xTeam:GetRobotIdsOrder()
        preFight.CaptainPos = xTeam:GetCaptainPos()
        preFight.FirstFightPos = xTeam:GetFirstFightPos()
        preFight.StageId = stage.StageId
        preFight.IsHasAssist = isAssist and true or false
        preFight.ChallengeCount = challengeCount or 1

        -- 检查extraRobotId
        local extraRobotId = nil
        local xStoryPoint = xStage:GetXStoryPoint()
        if xStoryPoint then
            extraRobotId = xStoryPoint:GetConfig().ExtraRobotId
        end
        local pos = nil
        for k, v in pairs(xTeam:GetEntityIds()) do
            if not XTool.IsNumberValid(v) then
                pos = k
                break
            end
        end
        if extraRobotId and pos then
            preFight.RobotIds[pos] = extraRobotId
        end

        return preFight
    end

    function XCerberusGameManager.ShowReward(winData)
        local settleData = winData.SettleData
        local stageId = settleData.StageId
        local xStage = XCerberusGameManager.GetXStageById(stageId)
        xStage:SetPassed(true)
        local xStoryPoint = xStage:GetXStoryPoint()
        if xStoryPoint then
            xStoryPoint:SetPassed(true)
        end

        XLuaUiManager.Open("UiSettleWinMainLine", winData)
        -- XDataCenter.FubenManager.ShowReward(winData)
    end
    --endregion

    function XCerberusGameManager.CheckIsActivityOpen()
        if not XTool.IsNumberValid(ActivityId) then
            return false
        end

        local config = XCerberusGameConfig.GetAllConfigs(XCerberusGameConfig.TableKey.CerberusGameActivity)[ActivityId]
        if not config then
            return false
        end

        local timeId = config.TimeId
        if not XFunctionManager.CheckInTimeByTimeId(timeId) then
            return
        end

        return true
    end

    function XCerberusGameManager.GetActivityConfig()
        if not XCerberusGameManager.CheckIsActivityOpen() then
            return {}
        end

        return XCerberusGameConfig.GetAllConfigs(XCerberusGameConfig.TableKey.CerberusGameActivity)[ActivityId]
    end

    function XCerberusGameManager.GetStortyChapterConfig()
        local challengeChapterId = XDataCenter.CerberusGameManager.GetChapterIdList()[XCerberusGameConfig.ChapterIdIndex.Story]
        if not challengeChapterId then
            return {}
        end
        return XCerberusGameConfig.GetAllConfigs(XCerberusGameConfig.TableKey.CerberusGameChapter)[challengeChapterId]
    end

    function XCerberusGameManager.GetChallengeChapterConfig()
        local challengeChapterId = XDataCenter.CerberusGameManager.GetChapterIdList()[XCerberusGameConfig.ChapterIdIndex.Challenge]
        if not challengeChapterId then
            return {}
        end
        return XCerberusGameConfig.GetAllConfigs(XCerberusGameConfig.TableKey.CerberusGameChapter)[challengeChapterId]
    end

    function XCerberusGameManager.GetBassRoleIdListForStoryMode(characterType, difficulty)
        if characterType == XCharacterConfigs.CharacterType.Isomer then
            return {}
        end

        local allRoleIds = {}
        local allEnableRoleId = XCerberusGameConfig.GetAllConfigs(XCerberusGameConfig.TableKey.CerberusGameRole)
        for k, v in pairs(allEnableRoleId) do
            if difficulty == v.Difficulty and XRobotManager.CheckIsRobotId(v.RoleId) then
                table.insert(allRoleIds, XRobotManager.GetRobotById(v.RoleId))

                local charId = XRobotManager.GetCharacterId(v.RoleId)
                if XDataCenter.CharacterManager.IsOwnCharacter(charId) then
                    table.insert(allRoleIds, XDataCenter.CharacterManager.GetCharacter(charId))
                end
            end
        end

        return allRoleIds
    end

    -- 获取挑战能选择的角色列表
    function XCerberusGameManager.GetCanSelectRoleListForChallengeMode(stageId)
        local xConfig = XCerberusGameConfig.CheckIsChallengeStage(stageId)
        if not xConfig then
            return {}
        end

        if xConfig then
            local ids = {}
            ids = appendArray(ids, xConfig.CharacterIds)
            ids = appendArray(ids, xConfig.RobotIds)
            local res = {}
            for k, id in pairs(ids) do
                if XRobotManager.CheckIsRobotId(id) then
                    table.insert(res, XRobotManager.GetRobotById(id))
                else
                    local charId = XRobotManager.GetCharacterId(id)
                    if XDataCenter.CharacterManager.IsOwnCharacter(charId) then
                        table.insert(res, XDataCenter.CharacterManager.GetCharacter(charId))
                    end
                end
            end
            return res
        end
        return {}
    end

    -- 获取剧情能选择的角色列表
    function XCerberusGameManager.GetCanSelectRoleListForStoryMode(characterType)
        local xStoryPoint = XCerberusGameManager.GetLastSelectXStoryPoint()
        local baseRoleList = XCerberusGameManager.GetBassRoleIdListForStoryMode(characterType, XCerberusGameManager.GetLastSelectStoryLineDifficulty())
        local showEnableCharList = xStoryPoint:GetTargetCharacterList()
        -- 剔除不在StoryPointTypeParams的角色
        local res = {}
        for k, v in pairs(baseRoleList) do
            local checkId = v:GetId()
            if XRobotManager.CheckIsRobotId(checkId) then
                checkId = XRobotManager.GetCharacterId(checkId)
            end
            if table.contains(showEnableCharList, checkId) then
                table.insert(res, v)
            end
        end
        
        return res
    end

    -- 重置检查队伍逻辑
    -- 1.如果队伍为空先检查自己或其他队伍是否有数据
    -- 2.如果自己队伍有服务器数据则用自己的，否则用最近1个的关卡的队伍数据
    -- 3.如果其他关卡队伍也没数据则用默认的队伍数据
    -- 4.最后使用队伍数据赋值前，根据每个stage的情况剔除不能用的角色
    -- 5.如果上阵了队伍还为空，则在1号为上阵1个战力最高的角色
    function XCerberusGameManager.ReInitXTeam(curStageIndex, stageId, canSeleRoleList, chapterId, currDifficulty)
        curStageIndex = curStageIndex or 1
        local xStage = XCerberusGameManager.GetXStageById(stageId)

        local serverXTeamInfo = XCerberusGameManager.CheckStageHasSaveTeamByServer(xStage.StageId)
        -- 查找最近的其他队伍
        if not serverXTeamInfo then
            local allCanUseTeamInfo = {}
            if XCerberusGameConfig.CheckIsChallengeStage(stageId) then
                local storyIdList = XCerberusGameConfig.GetChallegeIdListByDifficulty(currDifficulty)
                for k, stageId in pairs(storyIdList) do
                    local teamInfo = XCerberusGameManager.CheckStageHasSaveTeamByServer(stageId)
                    if teamInfo then -- 如果是这个章节的stage
                        table.insert(allCanUseTeamInfo, {Index = k, StageId = stageId, TeamInfo = teamInfo})
                    end
                end
            else
                local storyLineCfg = XCerberusGameManager.GetStoryLineCfgByChapterAndDifficulty(chapterId, currDifficulty)
                -- 如果是剧情模式就查剧情的
                for k, storyPointId in pairs(storyLineCfg.StoryPointIds) do
                    local xStoryPoint = XCerberusGameManager.GetXStoryPointById(storyPointId)
                    local teamInfo = xStoryPoint.StageId and XCerberusGameManager.CheckStageHasSaveTeamByServer(xStoryPoint.StageId)
                    if xStoryPoint.StageId and teamInfo then -- 如果是这个章节的stage
                        table.insert(allCanUseTeamInfo, {Index = k, StageId = xStoryPoint.StageId, TeamInfo = teamInfo})
                    end
                end
            end

            -- 用距离当前节点最近的队伍数据
            table.sort(allCanUseTeamInfo, function (a, b)
                local absA = math.abs(a.Index - curStageIndex)
                local absB = math.abs(b.Index - curStageIndex)
                return absA < absB
            end)
            serverXTeamInfo = allCanUseTeamInfo[1] and allCanUseTeamInfo[1].TeamInfo
        end

        local tempRes = {CharacterIdList = {}, RobotIdList = {}}
        if serverXTeamInfo then
            -- 服务器队伍信息剔除
            for k, id in pairs(serverXTeamInfo.CharacterIdList) do
                if table.containsKey(canSeleRoleList, "Id",  id) then
                    tempRes.CharacterIdList[k] = id
                else
                    tempRes.CharacterIdList[k] = 0
                end
            end

            for k, id in pairs(serverXTeamInfo.RobotIdList) do
                if table.containsKey(canSeleRoleList, "Id",  id) then
                    tempRes.RobotIdList[k] = id
                else
                    tempRes.RobotIdList[k] = 0
                end
            end
            serverXTeamInfo.CharacterIdList = tempRes.CharacterIdList
            serverXTeamInfo.RobotIdList = tempRes.RobotIdList
            xStage:SetXTeamByServer(serverXTeamInfo)
            local xTeam = xStage:GetXTeam()
            if xTeam:GetIsEmpty() then
                local maxAblityRole = nil
                local maxAbility = 0
                for k, v in pairs(canSeleRoleList) do
                    if v.Ability and (v.Ability > maxAbility) then
                        maxAbility = v.Ability
                        maxAblityRole = v
                    end
                end
                if maxAblityRole then
                    xTeam:UpdateEntityTeamPos(maxAblityRole.Id, 1, true)
                end
            end
            return    
        end

        tempRes = {}
        local defaultTeamList = XCerberusGameManager.GetDefaultTeamCharListByChapterAndDifficulty(chapterId, currDifficulty)
        for k, id in pairs(defaultTeamList) do
            -- 默认队伍剔除
            if table.containsKey(canSeleRoleList, "Id", id) then
                tempRes[k] = id
            else
                tempRes[k] = 0
            end
        end

        defaultTeamList = tempRes
        if not XTool.IsTableEmpty(defaultTeamList) then
            xStage:GetXTeam():UpdateEntityIds(defaultTeamList)
        end
    end

    function XCerberusGameManager.GetXStoryPointById(id)
        if not id then
            XLog.Error("GetXStoryPointById id 不能为空", id)
            return
        end

        local xStoryPoint = StoryPointDic[id]
        if not xStoryPoint then
            local config = XCerberusGameConfig.GetAllConfigs(XCerberusGameConfig.TableKey.CerberusGameStoryPoint)[id]
            if not config then
                XLog.Error("GetXStoryPointById ， 表CerberusGameStoryPoint 找不到Id", id)
                return
            end
            xStoryPoint = XCerberusGameStoryPoint.New(config)
            StoryPointDic[id] = xStoryPoint
        end
        return xStoryPoint
    end

    function XCerberusGameManager.GetXStageById(stageId)
        if not stageId then
            XLog.Error("GetXStageById stageId 不能为空", stageId)
            return
        end

        local xStage = StageIdDataDic[stageId]
        if not xStage then
            xStage = XCerberusGameStage.New(stageId)
            StageIdDataDic[stageId] = xStage
        end
        return xStage
    end

    function XCerberusGameManager.GetStoryLineCfgByChapterAndDifficulty(chapterId, difficulty)
        for k, v in pairs(XCerberusGameConfig.GetAllConfigs(XCerberusGameConfig.TableKey.CerberusGameStoryLine)) do
            if chapterId == v.ChapterId and v.Difficulty == difficulty then
                return v
            end
        end
    end

    -- 获得路线的总星数
    function XCerberusGameManager.GetAllStoryStarsCountByDifficulty(chapter, difficulty)
        local configs = XCerberusGameManager.GetStoryLineCfgByChapterAndDifficulty(chapter, difficulty)
        local count = 0
        for k, storyPointId in pairs(configs.StoryPointIds) do
            local xStoryPoint = XCerberusGameManager.GetXStoryPointById(storyPointId)
            if xStoryPoint.StageId then
                local stageCfg = XDataCenter.FubenManager.GetStageCfg(xStoryPoint.StageId)
                count = count + #stageCfg.StarDesc
            end
        end
        return count
    end
    
    -- 获得路线的已达成星数
    function XCerberusGameManager.GetStoryActiveStarsCountByDifficulty(chapter, difficulty)
        local configs = XCerberusGameManager.GetStoryLineCfgByChapterAndDifficulty(chapter, difficulty)
        local count = 0
        for k, storyPointId in pairs(configs.StoryPointIds) do
            local xStoryPoint = XCerberusGameManager.GetXStoryPointById(storyPointId)
            if xStoryPoint.StageId then
                count = count + xStoryPoint:GetXStage():GetStarsCount()
            end
        end
        return count
    end

    -- 获取挑战模式的总星数
    function XCerberusGameManager.GetAllChallengeStarsCount()
        local count = 0
        local allConfigs = XCerberusGameConfig.GetAllConfigs(XCerberusGameConfig.TableKey.CerberusGameChallenge)
        for stageId, v in pairs(allConfigs) do
            local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
            count = count + #stageCfg.StarDesc
        end
        return count
    end

    -- 获得挑战模式的已达成星数
    function XCerberusGameManager.GetChallengeActiveStarsCount()
        local count = 0
        local allConfigs = XCerberusGameConfig.GetAllConfigs(XCerberusGameConfig.TableKey.CerberusGameChallenge)
        for stageId, v in pairs(allConfigs) do
            local xStage = XCerberusGameManager.GetXStageById(stageId)
            count = count + xStage:GetStarsCount()
        end
        return count
    end

    function XCerberusGameManager.GetStoryPointIdsByDifficulty(difficulty)
        for k, v in pairs(XCerberusGameConfig.GetAllConfigs(XCerberusGameConfig.TableKey.CerberusGameStoryLine)) do
            if v.Difficulty == difficulty then
                return v.StoryPointIds
            end
        end
    end

    function XCerberusGameManager.GetPassStoryIdsByDifficulty(difficulty)
        local ids = XCerberusGameManager.GetStoryPointIdsByDifficulty(difficulty)
        local count = 0
        for k, storyPointId in pairs(ids) do
            local xStoryPoint = XCerberusGameManager.GetXStoryPointById(storyPointId)
            if xStoryPoint:GetIsPassed() then
                count = count + 1
            end
        end
        return count
    end

    -- 挑战模式boss表
    function XCerberusGameManager.GetStageListByBossId(id)
        local allConfig = XCerberusGameConfig.GetAllConfigs(XCerberusGameConfig.TableKey.CerberusGameBoss)
        local stageList = allConfig[id].StageId
        return stageList
    end

    function XCerberusGameManager.GetChapterIdList()
        local allConfig = XCerberusGameConfig.GetAllConfigs(XCerberusGameConfig.TableKey.CerberusGameChapter)
        local res = {}
        for chapterId, v in pairs(allConfig) do
            table.insert(res, chapterId)
        end
        table.sort(res, function (a,b)
            return a < b
        end)
        return res
    end

    -- 获取默认队伍成员，返回3个charId组成的顺序table
    function XCerberusGameManager.GetDefaultTeamCharListByChapterAndDifficulty(chapterId, difficulty)
        if not chapterId or not difficulty then
            return
        end
        local cfgString = XCerberusGameConfig.GetAllConfigs(XCerberusGameConfig.TableKey.CerberusGameChapter)[chapterId].DefaultTeam[difficulty]
        local teamList = string.Split(cfgString, '|')
        for k, v in pairs(teamList) do
            teamList[k] = tonumber(v)
        end
        return teamList
    end

    function XCerberusGameManager.GetProgressTips()
        -- 1.剧情模式未通关
        local storyChapterId = XCerberusGameManager.GetChapterIdList()[1]
        local allStartCount1 = XCerberusGameManager.GetAllStoryStarsCountByDifficulty(storyChapterId, XCerberusGameConfig.StageDifficulty.Normal)
        local allStartCount2 = XCerberusGameManager.GetAllStoryStarsCountByDifficulty(storyChapterId, XCerberusGameConfig.StageDifficulty.Hard)
        local avtiveStarCount1 = XCerberusGameManager.GetStoryActiveStarsCountByDifficulty(storyChapterId, XCerberusGameConfig.StageDifficulty.Normal)
        local avtiveStarCount2 = XCerberusGameManager.GetStoryActiveStarsCountByDifficulty(storyChapterId, XCerberusGameConfig.StageDifficulty.Hard)
        if (avtiveStarCount1 + avtiveStarCount2) < (allStartCount1 + allStartCount2) then
            local prog = (avtiveStarCount1 + avtiveStarCount2) / (allStartCount1 + allStartCount2)
            prog = string.format("%.0f%%", prog * 100)  -- 将小数转换为百分比字符串
            return CS.XTextManager.GetText("CerbrusGameStoryProgress", prog)
        end

        -- 2.挑战模式未通关
        local allStartCount = XCerberusGameManager.GetAllChallengeStarsCount()
        local activeStartCount = XCerberusGameManager.GetChallengeActiveStarsCount()
        if allStartCount < activeStartCount then
            local prog = allStartCount/activeStartCount
            prog = string.format("%.0f%%", prog * 100)
            return CS.XTextManager.GetText("CerbrusGameStoryProgress", prog)
        end

        return CS.XTextManager.GetText("SuperSmashFinish")
    end

    -- 检查该Stage是否被服务端存储过队伍数据
    function XCerberusGameManager.CheckStageHasSaveTeamByServer(stageId)
        local info = XTool.Clone(StageTeamInfoByServer[stageId])
        return info
    end

    function XCerberusGameManager.RefreshStoryPointDataByLoginServer(data)
        ActivityId = data.ActivityId
        for _, v in pairs(data.ChapterInfos) do
            for _, value in pairs(v.StoryLineInfos) do
                for _, id in pairs(value.PassStoryPoints) do
                    local xStoryPoint = XCerberusGameManager.GetXStoryPointById(id)
                    xStoryPoint:SetPassed(true)
                end
            end
        end
    end

    function XCerberusGameManager.RefreshStageDataByLoginServer(stageInfos)
        for k, v in pairs(stageInfos) do
            local xStage = XCerberusGameManager.GetXStageById(v.StageId)
            xStage:SetServerData(v)
            StageTeamInfoByServer[v.StageId] = v.TeamInfo
        end
    end

    -- 开始请求通讯节点
    function XCerberusGameManager.StartCommunication(storyPointId)
        local xStoryPoint = XCerberusGameManager.GetXStoryPointById(storyPointId)
        if xStoryPoint:GetType() ~= XCerberusGameConfig.StoryPointType.Communicate then
            return
        end

        local commId = xStoryPoint:GetCommunicationId()
        local cfg = XCerberusGameConfig.GetAllConfigs(XCerberusGameConfig.TableKey.CerberusGameCommunication)[commId]
        if xStoryPoint:GetIsPassed() then
            XLuaUiManager.Open("UiFunctionalOpen", cfg, false, false)
            return
        end

        -- 首次通过要请求协议
        XCerberusGameManager.CerberusGamePassStoryPointRequest(storyPointId, function ()
            XLuaUiManager.Open("UiFunctionalOpen", cfg, false, false)
        end)
    end

    -- 手动请求通过的节点只有剧情和通讯，且只在剧情模式的普通难度有
    function XCerberusGameManager.CerberusGamePassStoryPointRequest(storyPointId, cb)
        local xStoryPoint = XCerberusGameManager.GetXStoryPointById(storyPointId)
        local storyLineId = xStoryPoint:GetStoryLineId()
        local storyCfg = XCerberusGameConfig.GetAllConfigs(XCerberusGameConfig.TableKey.CerberusGameStoryLine)[storyLineId]
        local chapterId = storyCfg.ChapterId
        local difficulty = storyCfg.Difficulty
        XNetwork.Call("CerberusGamePassStoryPointRequest", {ChapterId = chapterId, StoryPointId = storyPointId, StoryLineId = difficulty}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local xStoryPoint = XCerberusGameManager.GetXStoryPointById(storyPointId)
            xStoryPoint:SetPassed(true)

            XEventManager.DispatchEvent(XEventId.EVENT_CERBERUS_GAME_PASS_STORY_POINT)
            
            if cb then
                cb()
            end
        end)
    end

    ---@param xCerberusTeam XCerberusGameTeam
    function XCerberusGameManager.CerberusGameSetTeamRequest(stageId, xCerberusTeam, cb)
        local teamInfo = {}
        teamInfo.CharacterIdList = xCerberusTeam:GetCharacterIdsOrder()
        teamInfo.RobotIdList = xCerberusTeam:GetRobotIdsOrder()
        teamInfo.CaptainPos = xCerberusTeam:GetCaptainPos()
        teamInfo.FirstFightPos = xCerberusTeam:GetFirstFightPos()

        XNetwork.Call("CerberusGameSetTeamRequest", {StageId = stageId, TeamInfo = teamInfo}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            -- 刷新一遍队伍
            StageTeamInfoByServer[stageId] = teamInfo
            local xStage = XCerberusGameManager.GetXStageById(stageId)
            xStage:SetXTeamByServer(teamInfo)
           
            if cb then
                cb()
            end
        end)
    end

    --- 活动本地缓存
    function XCerberusGameManager.GetCacheKey(keyName)
        return keyName.."CerberusGame"
    end

    -- 上一次选择的难度缓存
    function XCerberusGameManager.GetLastDifficultyCacheKey(chapterId)
        return XCerberusGameManager.GetCacheKey("GetLastDifficultyCacheKey")..chapterId..XPlayer.Id
    end

    function XCerberusGameManager.GetLastDifficulty(chapterId)
        return XSaveTool.GetData(XCerberusGameManager.GetLastDifficultyCacheKey(chapterId))
    end
    
    function XCerberusGameManager.SetLastDifficulty(chapterId, value)
        return XSaveTool.SaveData(XCerberusGameManager.GetLastDifficultyCacheKey(chapterId), value)
    end

    XCerberusGameManager.Init()
    return XCerberusGameManager
end

XRpc.NotifyCerberusGameData = function(data)
    local data = data.CerberusGameData
    XDataCenter.CerberusGameManager.RefreshStoryPointDataByLoginServer(data)
    XDataCenter.CerberusGameManager.RefreshStageDataByLoginServer(data.StageInfos)
    XDataCenter.CerberusGameManager.SetLastSelectStoryLineDifficulty(nil) -- 每次下发，重置选择难度缓存
end

XRpc.NotifyCerberusGameStageInfo = function(data)
    XDataCenter.CerberusGameManager.RefreshStageDataByLoginServer({data.CerberusGameStageInfo})
end