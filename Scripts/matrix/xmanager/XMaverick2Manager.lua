local CSXAudioManager = CS.XAudioManager
local XExFubenActivityManager = require("XEntity/XFuben/XExFubenActivityManager")

XMaverick2ManagerCreator = function()
	local XMaverick2Manager = XExFubenActivityManager.New(XFubenConfigs.ChapterType.Maverick2, "Maverick2Manager")

    -- 自定义数据
    local LastPassStageId = nil -- 上一次通关关卡id，登陆游戏后未打是为nil
    local ReFightData = {} -- 保存战斗的请求数据，可以在结算界面重新战斗
    local IsRequestShopInfo = false -- 是否请求过商店

    -- 服务器下发的数据
    local ActivityId = 0
    local ChapterDataDic = {} -- 章节数据  key为章节id
    local CharacterDataDic = {} -- 机器人数据  key为机器人id
    local StageDic = {} -- 关卡数据  key为关卡id
    local DailyStageDic = {} -- 每日关卡列表
    local ScoreStageRecord = {} -- 积分关记录(最后一关为积分关，只有一关)
    local RankData = {} -- 排行榜数据
    local MentalLevel = 0 -- 心智天赋等级
    local AssistTalentLvDic = {} -- 支援技能等级，key为支援技能的TalentId

	function XMaverick2Manager.Init()
	end

    function XMaverick2Manager.GetActivityId()
        return ActivityId
    end

    function XMaverick2Manager.IsOpen()
        if not XTool.IsNumberValid(ActivityId) or ActivityId == 0 then return false end
        local config = XMaverick2Configs.GetMaverick2Activity(ActivityId, true)
        return XFunctionManager.CheckInTimeByTimeId(config.TimeId)
    end

    function XMaverick2Manager.GetActivityStartTime()
        local config = XMaverick2Configs.GetMaverick2Activity(ActivityId, true)
        return XFunctionManager.GetStartTimeByTimeId(config.TimeId)
    end

    function XMaverick2Manager.GetActivityEndTime()
        local config = XMaverick2Configs.GetMaverick2Activity(ActivityId, true)
        return XFunctionManager.GetEndTimeByTimeId(config.TimeId)
    end

    function XMaverick2Manager.GetActivitySaveKey()
        return string.format("Maverick2Manager_GetActivitySaveKey_XPlayer.Id:%s_ActivityId:%s_", XPlayer.Id, ActivityId)
    end

    -------------------------------------------------- 章节关卡 begin --------------------------------------------------
    -- 设置章节数据
    function XMaverick2Manager.SetChapterDatas(chapterDatas)
        ChapterDataDic = {}
        StageDic = {}
        for i, chapter in ipairs(chapterDatas) do
            ChapterDataDic[chapter.ChapterId] = chapter
            for j, stage in ipairs(chapter.PassStageDatas) do
                XMaverick2Manager.SetStageData(stage)
            end
        end
    end

    -- 获取章节数据
    function XMaverick2Manager.GetChapterData(chapterId)
        return ChapterDataDic[chapterId]
    end

    -- 章节是否解锁
    function XMaverick2Manager.IsChapterUnlock(chapterId)
        local chapterCfg = XMaverick2Configs.GetMaverick2Chapter(chapterId, true)
        local isUnlock = chapterCfg.PreStageId == 0 or XMaverick2Manager.IsStagePassed(chapterCfg.PreStageId)
        return isUnlock
    end

    -- 获取章节距离时间开启
    function XMaverick2Manager.GetChapterOpenTime(chapterId)
        local chapterCfg = XMaverick2Configs.GetMaverick2Chapter(chapterId, true)
        local openTime = XMaverick2Manager.GetActivityStartTime() + chapterCfg.OpenTime
        local curTime = XTime.GetServerNowTimestamp()
        if openTime > curTime then
            return openTime - curTime
        end

        return 0
    end

    -- 章节是否到了开启时间
    function XMaverick2Manager.IsChapterOpenTime(chapterId)
        local chapterCfg = XMaverick2Configs.GetMaverick2Chapter(chapterId, true)
        local openTime = XMaverick2Manager.GetActivityStartTime() + chapterCfg.OpenTime
        local curTime = XTime.GetServerNowTimestamp()
        local isOpen = curTime >= openTime
        return isOpen
    end

    -- 获取最后解锁的章节id
    function XMaverick2Manager.GetLastUnlockChapterId()
        local chapterId = 1
        local chapterCfgs = XMaverick2Configs.GetMaverick2Chapter()
        for _, chapter in ipairs(chapterCfgs) do
            local isUnlock = chapter.PreStageId == 0 or XMaverick2Manager.IsStagePassed(chapter.PreStageId)
            local isOpen = XMaverick2Manager.IsChapterOpenTime(chapter.ChapterId)
            if isUnlock and isOpen then
                chapterId = chapter.ChapterId
            end
        end
        return chapterId
    end

    -- 获取章节进度
    function XMaverick2Manager.GetChapterProgress(chapterId)
        local allStageCnt = 0
        local passStageCnt = 0

        local stageCfgs = XMaverick2Configs.GetChapterStages(chapterId)
        for _, stageCfg in pairs(stageCfgs) do
            -- 忽略每日关卡
            if stageCfg.StageType ~= XMaverick2Configs.StageType.Daily then
                allStageCnt = allStageCnt + 1
                local isPass = XMaverick2Manager.IsStagePassed(stageCfg.StageId)
                if isPass then
                    passStageCnt = passStageCnt + 1
                end
            end
        end

        return passStageCnt, allStageCnt
    end

    -- 章节是否显示红点
    function XMaverick2Manager.IsChapterShowRed(chapterId)
        local key = XMaverick2Manager.GetChapterRedSaveKey(chapterId)
        local isRemove = XSaveTool.GetData(key) == true
        return not isRemove
    end

    -- 移除章节红点
    function XMaverick2Manager.RemveChapterRed(chapterId)
        local key = XMaverick2Manager.GetChapterRedSaveKey(chapterId)
        XSaveTool.SaveData(key, true)
    end

    -- 章节红点key
    function XMaverick2Manager.GetChapterRedSaveKey(chapterId)
        return XDataCenter.Maverick2Manager.GetActivitySaveKey() .. "XMaverick2Manager_GetChapterRedSaveKey_chapterId:" .. tostring(chapterId)
    end

    -- 获取下个挑战关卡，解锁且未通关
    function XMaverick2Manager.GetNextStageId()
        local stageId = nil
        local chapterId = XMaverick2Manager.GetLastUnlockChapterId()
        local stageCfgs = XMaverick2Configs.GetChapterStages(chapterId)
        for _, stageCfg in ipairs(stageCfgs) do
            -- 忽略每日关卡
            if stageCfg.StageType ~= XMaverick2Configs.StageType.Daily then
                local isPass = XMaverick2Manager.IsStagePassed(stageCfg.StageId)
                local isUnlock = XMaverick2Manager.IsStageUnlock(stageCfg.StageId)
                if isUnlock and not isPass then
                    stageId = stageCfg.StageId
                end
            end
        end
        return stageId
    end

    -- 获取已通关卡数据
    function XMaverick2Manager.GetStageData(stageId)
        local stageData = StageDic[stageId]
        if stageData then
            return stageData
        else
            return {
                StageId = stageId,
                GotFirstReward = false,
                StarCount = 0,
            }
        end
    end

    -- 设置关卡数据
    function XMaverick2Manager.SetStageData(stageData)
        StageDic[stageData.StageId] = stageData
    end

    -- 获取关卡是否通关
    function XMaverick2Manager.IsStagePassed(stageId)
        local stageCfg = XMaverick2Configs.GetMaverick2Stage(stageId, true)
        if stageCfg.StageType == XMaverick2Configs.StageType.Daily then
            return false -- 过滤每日关卡
        end

        return StageDic[stageId] ~= nil
    end

    -- 获取关卡是否解锁
    function XMaverick2Manager.IsStageUnlock(stageId)
        local stageCfg = XMaverick2Configs.GetMaverick2Stage(stageId, true)
        if stageCfg.StageType == XMaverick2Configs.StageType.Daily then
            return false -- 过滤每日关卡
        end

        local isChapterUnlock = XMaverick2Manager.IsChapterUnlock(stageCfg.ChapterId)
        if not isChapterUnlock then 
            return false
        end

        local isUnlock = stageCfg.PreStageId == 0 or XMaverick2Manager.IsStagePassed(stageCfg.PreStageId)
        return isUnlock
    end

    -- 关卡是否播解锁动画
    function XMaverick2Manager.IsStagePlayUnlockAnim(stageId)
        local stageCfg = XMaverick2Configs.GetMaverick2Stage(stageId, true)
        local lastStageUnlock = stageCfg.PreStageId ~= 0 and stageCfg.PreStageId == LastPassStageId
        if not lastStageUnlock then
            return false
        end

        local saveKey = XMaverick2Manager.GetUnlockAnimSaveKey(stageId)
        local isPlayed = XSaveTool.GetData(saveKey) == true
        return not isPlayed
    end

    -- 设置关卡已播解锁动画
    function XMaverick2Manager.SetStagePlayUnlockAnim(stageId)
        local saveKey = XMaverick2Manager.GetUnlockAnimSaveKey(stageId)
        XSaveTool.SaveData(saveKey, true)
    end

    function XMaverick2Manager.GetUnlockAnimSaveKey(stageId)
        return XDataCenter.Maverick2Manager.GetActivitySaveKey() .. "XMaverick2Manager_GetUnlockAnimSaveKey_stageId:" .. tostring(stageId)
    end

    -- 上一次通关的关卡id
    function XMaverick2Manager.GetLastPassStageId()
        return LastPassStageId
    end

    -- 获取每日关卡
    function XMaverick2Manager.GetDailyStage()
        return DailyStageDic
    end

    -- 是否显示每日关卡
    function XMaverick2Manager.IsShowDailyStage(stageId)
        return DailyStageDic[stageId] == true
    end

    -- 是否解锁困难章节列表
    function XMaverick2Manager.IsUnlockDifficultChapterList()
        local configs = XMaverick2Configs.GetMaverick2Chapter()
        for _, config in ipairs(configs) do
            local isUnlock = config.PreStageId == 0 or XMaverick2Manager.IsStagePassed(config.PreStageId)
            if isUnlock and config.IfFlag == 1 then
                return true
            end
        end
        return false
    end

    -- 获取积分关卡记录
    function XMaverick2Manager.GetScoreStageRecord()
        return ScoreStageRecord
    end

    -- 播放BGM
    function XMaverick2Manager.PlayBGM()
        local chapterId = XDataCenter.Maverick2Manager.GetLastUnlockChapterId()
        local chapterCfg = XMaverick2Configs.GetMaverick2Chapter(chapterId, true)
        local cueId = chapterCfg.Bgm

        -- 通用结算界面挂了组件在destroy时播放203音效，这里延迟一帧播放
        XScheduleManager.ScheduleOnce(function()
            CSXAudioManager.StopAll()
            CSXAudioManager.PlayMusicWithAnalyzer(cueId)
        end, 100)
    end

    -- 播放章节动画
    function XMaverick2Manager.PlayChapterMovie(chapterId, cb)
        local key = XMaverick2Manager.GetActivitySaveKey() .. "XMaverick2Manager_PlayChapterMovie_" .. tostring(chapterId)
        local movieId = XMaverick2Configs.GetChapterOpenMovieId(chapterId)
        if not XSaveTool.GetData(key) and movieId then
            XDataCenter.MovieManager.PlayMovie(movieId, cb, nil, nil, false)
            XSaveTool.SaveData(key, true)
        else
            if cb then
                cb()
            end
        end
    end

    -- 优先打开本地记录的上次所选章节，没有本地记录则打开最新章节
    function XMaverick2Manager.GetLastSelChapterId()
        local key = XMaverick2Manager.GetLastSelChapterSaveKey()
        local chapterId =  XSaveTool.GetData(key)
        if chapterId then
            return chapterId
        else
            return XMaverick2Manager.GetLastUnlockChapterId()
        end
    end

    -- 保存最后选中的章节记录
    function XMaverick2Manager.SaveLastSelChapterId(chapterId)
        local key = XMaverick2Manager.GetLastSelChapterSaveKey()
        XSaveTool.SaveData(key, chapterId)
    end

    function XMaverick2Manager.GetLastSelChapterSaveKey()
        return XMaverick2Manager.GetActivitySaveKey() .. "XUiMaverick2Explore_GetLastSelChapterKey"
    end

    -- 是否打开过每日关卡
    function XMaverick2Manager.IsOpenedDailyStage()
        local key = XMaverick2Manager.GetOpenDailyStageSaveKey()
        return XSaveTool.GetData(key) == true
    end

    -- 保存打开过每日关卡
    function XMaverick2Manager.SaveOpenDailyStage()
        local key = XMaverick2Manager.GetOpenDailyStageSaveKey()
        XSaveTool.SaveData(key, true)
    end

    function XMaverick2Manager.GetOpenDailyStageSaveKey()
        return XMaverick2Manager.GetActivitySaveKey() .. "XUiMaverick2Explore_GetOpenDailyStageSaveKey"
    end

    -------------------------------------------------- 章节关卡 end --------------------------------------------------


    -------------------------------------------------- 心智天赋 begin --------------------------------------------------

    -- 获取心智单元数量
    function XMaverick2Manager.GetUnitCount()
        return XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.Maverick2Unit)
    end

    -- 获取心智天赋等级
    function XMaverick2Manager.GetMentalLv()
        return MentalLevel
    end

    -- 获取心智天赋最高等级
    function XMaverick2Manager.GetMentalMaxLv()
        local configs = XMaverick2Configs.GetMaverick2Mental()
        return #configs
    end

    -- 检测心智天赋升级
    function XMaverick2Manager.CheckMentalLvUp(callback)
        -- 计算等级
        local ownUnitCnt = XMaverick2Manager.GetUnitCount() -- 当前已拥有的单元数量
        local configs = XMaverick2Configs.GetMaverick2Mental()
        local lastLv = MentalLevel
        local lv = MentalLevel
        for _, config in ipairs(configs) do
            if ownUnitCnt >= config.NeedUnit then
                lv = config.Level
            end
        end

        -- 请求协议
        if lv > MentalLevel then
            local request = { MentalLevel = lv }
            XNetwork.Call("Maverick2UpgradeMentalLevelRequest", request, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                MentalLevel = lv
                
                if callback then
                    callback()
                end

                -- 打开升级成功界面，从0升到1级不弹界面
                if lv ~= 1 then
                    XLuaUiManager.Open("UiMaverick2LevelUp", lastLv, lv)
                end
            end)
        end
    end

    -- 获取解锁的天赋组id列表
    local GetTalentUnlockGroupIds = function(robotId)
        local unlockGroupIds = {}
        local treeCfgs = XMaverick2Configs.GetRobotTalentCfg(robotId)
        local mentalLv = XDataCenter.Maverick2Manager.GetMentalLv()
        for _, treeCfg in ipairs(treeCfgs) do
            local isUnlock = mentalLv >= treeCfg.NeedMentalLv
            if isUnlock then
                table.insert(unlockGroupIds, treeCfg.TalentGroupId)
            end
        end

        return unlockGroupIds
    end

    -- 是否显示心智天赋的红点
    function XMaverick2Manager.IsShowTalentRed(robotId)
        local unlockGroupIds = GetTalentUnlockGroupIds(robotId)
        local lastUnlockGroupIds = XMaverick2Manager.GetTalentRedUnlockGroupIds(robotId)
        return #unlockGroupIds > #lastUnlockGroupIds and #unlockGroupIds > 1
    end

    -- 获取本地保存的解锁天赋组id列表
    function XMaverick2Manager.GetTalentRedUnlockGroupIds(robotId)
        local key = XMaverick2Manager.GetTalentRedSaveKey(robotId)
        return XSaveTool.GetData(key) or {}
    end

    -- 刷新本地保存的解锁天赋组id列表
    function XMaverick2Manager.RefreshTalentRedUnlockGroupIds(robotId)
        local groupIds = GetTalentUnlockGroupIds(robotId)
        local key = XMaverick2Manager.GetTalentRedSaveKey(robotId)
        XSaveTool.SaveData(key, groupIds)
    end

    function XMaverick2Manager.GetTalentRedSaveKey(robotId)
        return XMaverick2Manager.GetActivitySaveKey() .. "XMaverick2Manager_GetTalentRedSaveKey_robotId:" .. tostring(robotId)
    end

    -------------------------------------------------- 心智天赋 end --------------------------------------------------


    -------------------------------------------------- 机器人 begin --------------------------------------------------
    -- 设置机器人数据
    function XMaverick2Manager.SetCharacterDatas(characterDatas)
        CharacterDataDic = {}
        for _, charData in ipairs(characterDatas) do
            local robotId = charData.RobotId
            local newCharData = {} -- 这里把TalentGroupDatas和TalentDatas从list转成dic保存，方便读取
            newCharData.RobotId = robotId
            newCharData.TalentGroupDatas = {}
            for _, groupData in ipairs(charData.TalentGroupDatas) do
                local groupId = groupData.TalentGroupId
                local newGroupData = {}
                newGroupData.TalentGroupId = groupId
                newGroupData.TalentDatas = {}
                for _, talentData in ipairs(groupData.TalentDatas) do
                    newGroupData.TalentDatas[talentData.TalentId] = talentData
                end

                newCharData.TalentGroupDatas[groupId] = newGroupData
            end

            CharacterDataDic[robotId] = newCharData
            newCharData.AssignUnit = charData.AssignUnit
            newCharData.AssignActiveUnit = XMaverick2Manager.CalcAssignActiveUnitCnt(robotId)
        end
    end

    -- 获取机器人数据
    function XMaverick2Manager.GetCharacterData(robotId)
        return CharacterDataDic[robotId]
    end

    -- 新增一个刚解锁的机器人
    function XMaverick2Manager.AddCharacterData(robotId)
        if not CharacterDataDic[robotId] then
            local charData = {}
            CharacterDataDic[robotId] = charData
            charData.RobotId = robotId
            charData.AssignUnit = 0
            charData.AssignActiveUnit = 0
            charData.TalentGroupDatas = {}
        end
    end

    -- 是否有机器人数据
    function XMaverick2Manager.HaveCharacterData()
        for _, charData in pairs(CharacterDataDic) do
            if charData then
                return true
            end
        end

        return false
    end

    -- 获取机器人的天赋等级
    function XMaverick2Manager.GetTalentLv(robotId, groupId, talentId)
        local robotData = CharacterDataDic[robotId]
        if robotData then
            local groupData = robotData.TalentGroupDatas[groupId]
            if groupData then
                local talentData = groupData.TalentDatas[talentId]
                if talentData then
                    return talentData.Level
                end
            end
        end

        return 0
    end

    -- 获取机器人当前天赋等级对应的配置表列表
    function XMaverick2Manager.GetRobotTalentCfgs(robotId)
        local talentCfgList = {}
        local robotData = CharacterDataDic[robotId]
        if robotData then
            for _, groupData in pairs(robotData.TalentGroupDatas) do
                for _, talentData in pairs(groupData.TalentDatas) do
                    if talentData.Level > 0 then
                        local config = XMaverick2Configs.GetTalentLvConfig(talentData.TalentId, talentData.Level)
                        if config then
                            table.insert(talentCfgList, config)
                        end
                    end
                end
            end
        end

        return talentCfgList
    end

    -- 获取机器人当前天赋汇总
    function XMaverick2Manager.GetRobotSummaryInfos(robotId, summaryTab)
        local talenInfos = {}
        local robotData = CharacterDataDic[robotId]
        if robotData then
            for _, groupData in pairs(robotData.TalentGroupDatas) do
                for _, talentData in pairs(groupData.TalentDatas) do
                    local talentInfo = XMaverick2Configs.GetTalentInfo(talentData.TalentId)
                    local isShow = talentData.Level > 0 and talentInfo.SummaryTab == summaryTab and XMaverick2Manager.IsTalentGroupUnlock(robotId, groupData.TalentGroupId)
                    if isShow then
                        local config = XMaverick2Configs.GetTalentLvConfig(talentData.TalentId, talentData.Level)
                        local info = {TalentId = talentData.TalentId, Name = talentInfo.Name, Desc = config.Desc, Icon = config.Icon, Level = talentData.Level}
                        table.insert(talenInfos, info)
                    end
                end
            end
        end

        table.sort(talenInfos, function(a, b)
            return a.TalentId < b.TalentId
        end)

        return talenInfos
    end

    -- 获取机器人累计分配的心智单元
    function XMaverick2Manager.GetAssignUnitCnt(robotId)
        local robotData = CharacterDataDic[robotId]
        if robotData then
            return robotData.AssignUnit
        end
        return 0
    end

    function XMaverick2Manager.CalcAssignUnitCnt(robotId)
        local robotData = CharacterDataDic[robotId]
        if robotData then
            local assignUnit = 0
            for _, gData in pairs(robotData.TalentGroupDatas) do
                for _, tData in pairs(gData.TalentDatas) do
                    assignUnit = assignUnit + XMaverick2Configs.GetTalentLvCostUnit(tData.TalentId, tData.Level)
                end
            end
            return assignUnit
        end
        return 0
    end

    -- 获取机器人累计分配且激活的心智单元
    function XMaverick2Manager.GetAssignActiveUnitCnt(robotId)
        local robotData = CharacterDataDic[robotId]
        if robotData then
            return robotData.AssignActiveUnit
        end
        return 0
    end

    function XMaverick2Manager.CalcAssignActiveUnitCnt(robotId)
        local robotData = CharacterDataDic[robotId]
        if robotData then
            local assignActiveUnit = 0
            local treeCfgs = XMaverick2Configs.GetRobotTalentCfg(robotId)
            for _, treeCfg in ipairs(treeCfgs) do
                if assignActiveUnit >= treeCfg.NeedUnit then
                    local groupData = robotData.TalentGroupDatas[treeCfg.TalentGroupId]
                    if groupData then
                        for _, tData in pairs(groupData.TalentDatas) do
                            assignActiveUnit = assignActiveUnit + XMaverick2Configs.GetTalentLvCostUnit(tData.TalentId, tData.Level)
                        end
                    end
                end
            end
            return assignActiveUnit
        end
        return 0
    end

    -- 获取机器人剩余可分配的心智单元
    function XMaverick2Manager.GetRemainUnitCnt(robotId)
        local allCnt = XMaverick2Manager.GetUnitCount()
        local assignCnt = XMaverick2Manager.GetAssignUnitCnt(robotId)
        return allCnt - assignCnt
    end

    -- 请求升级天赋
    function XMaverick2Manager.RequestUpgradeTalent(robotId, groupId, talentId, cb)
        local request = { RobotId = robotId, GroupId = groupId, TalentId = talentId }
        XNetwork.Call("Maverick2UpgradeTalentRequest", request, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            -- 更新数据
            local curLv = XMaverick2Manager.GetTalentLv(robotId, groupId, talentId)
            XMaverick2Manager.UpdateRobotTalentLv(robotId, groupId, talentId, curLv + 1)

            if cb then
                cb()
            end
        end)
    end

    -- 请求重置单个天赋
    function XMaverick2Manager.RequestResetSingleTalent(robotId, groupId, talentId, cb)
        local request = { RobotId = robotId, GroupId = groupId, TalentId = talentId }
        XNetwork.Call("Maverick2ResetSingleTalentRequest", request, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            -- 更新数据
            XMaverick2Manager.UpdateRobotTalentLv(robotId, groupId, talentId, 0)

            if cb then
                cb()
            end
        end)
    end

    -- 更新机器人天赋等级
    function XMaverick2Manager.UpdateRobotTalentLv(robotId, groupId, talentId, lv)
        -- 创建/更新天赋等级
        local robotData = CharacterDataDic[robotId]
        local groupData = robotData.TalentGroupDatas[groupId]
        if not groupData then
            groupData = {}
            groupData.TalentGroupId = groupId
            groupData.TalentDatas = {}
            robotData.TalentGroupDatas[groupId] = groupData
        end

        local talentData = groupData.TalentDatas[talentId]
        if not talentData then
            talentData = {}
            talentData.TalentId = talentId
            groupData.TalentDatas[talentId] = talentData
        end
        talentData.Level = lv

        robotData.AssignUnit = XMaverick2Manager.CalcAssignUnitCnt(robotId)
        robotData.AssignActiveUnit = XMaverick2Manager.CalcAssignActiveUnitCnt(robotId)
    end

    -- 重置机器人的所有天赋
    function XMaverick2Manager.RequestResetRobotAllTalent(robotId, cb)
        local robotData = CharacterDataDic[robotId]
        if robotData == nil or robotData.AssignUnit == 0 then
            return
        end

        local request = { RobotId = robotId }
        XNetwork.Call("Maverick2ResetAllTalentRequest", request, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            -- 重置机器人所有天赋数据
            XMaverick2Manager.ResetRobotAllTalent(robotId)

            if cb then
                cb()
            end
        end)
    end

    -- 重置机器人所有天赋数据
    function XMaverick2Manager.ResetRobotAllTalent(robotId)
        local robotData = CharacterDataDic[robotId]
        for _, groupData in pairs(robotData.TalentGroupDatas) do
            for _, talentData in pairs(groupData.TalentDatas) do
                talentData.Level = 0
            end
        end
        robotData.AssignUnit = 0
        robotData.AssignActiveUnit = 0
    end

    -- 获取机器人天赋组是否解锁
    function XMaverick2Manager.IsTalentGroupUnlock(robotId, talentGroupId)
        local treeCfg = XMaverick2Configs.GetTalentTreeConfig(robotId, talentGroupId)
        local assignUnit = XDataCenter.Maverick2Manager.GetAssignActiveUnitCnt(robotId)
        local mentalLv = XDataCenter.Maverick2Manager.GetMentalLv()
        local isLock = mentalLv < treeCfg.NeedMentalLv or assignUnit < treeCfg.NeedUnit
        return not isLock
    end

    -- 根据关卡获取机器人列表
    function XMaverick2Manager.GetRobotCfgList(stageId, isFilterLock)
        local list = {}
        local robotCfgs = XMaverick2Configs.GetMaverick2Robot()
        for _, robotCfg in pairs(robotCfgs) do
            if isFilterLock then 
                local isUnlock = XMaverick2Manager.IsRobotUnlock(robotCfg.RobotId)
                if isUnlock then 
                    table.insert(list, robotCfg)
                end
            else
                table.insert(list, robotCfg)
            end
        end

        -- 禁止机器人id列表
        local forbidIds = {}
        if stageId then
            local stageCfg = XMaverick2Configs.GetMaverick2Stage(stageId, true)
            for _, forbidId in ipairs(stageCfg.ForbidRobot) do
                forbidIds[forbidId] = true
            end
        end

        -- 排序
        table.sort(list, function(a, b)
            local isUnlockA = XMaverick2Manager.IsRobotUnlock(a.RobotId) and 1 or 0
            local isUnlockB = XMaverick2Manager.IsRobotUnlock(b.RobotId) and 1 or 0
            if isUnlockA ~= isUnlockB then
                return isUnlockA > isUnlockB
            else
                local isUnForbidA = forbidIds[a.RobotId] and 0 or 1
                local isUnForbidB = forbidIds[b.RobotId] and 0 or 1
                if isUnForbidA ~= isUnForbidB then
                    return isUnForbidA > isUnForbidB
                else
                    return a.RobotId < b.RobotId
                end
            end
        end)

        return list
    end

    -- 判断机器人是否被禁用
    function XMaverick2Manager.IsRobotForbid(robotId, stageId)
        if not stageId then 
            return false
        end

        local stageCfg = XMaverick2Configs.GetMaverick2Stage(stageId, true)
        for _, forbidId in ipairs(stageCfg.ForbidRobot) do
            if forbidId == robotId then
                return true
            end
        end

        return false
    end

    -- 机器人是否解锁
    function XMaverick2Manager.IsRobotUnlock(robotId)
        local isUnlock = XMaverick2Manager.GetCharacterData(robotId) ~= nil
        return isUnlock
    end

    -- 机器人是否达到解锁条件
    function XMaverick2Manager.IsRobotUnlockCondition(robotId)
        local robotCfg = XMaverick2Configs.GetMaverick2Robot(robotId, true)
        local isUnlock = true
        if robotCfg.Condition ~= 0 then
            isUnlock = XConditionManager.CheckCondition(robotCfg.Condition)
        end
        return isUnlock
    end

    -- 保存最后选中的机器人记录
    function XMaverick2Manager.SaveLastSelRobotId(robotId)
        local key = XMaverick2Manager.GetLastSelRobotSaveKey()
        XSaveTool.SaveData(key, robotId)
    end

    -- 获取上次所选机器人，没有则返回第一个
    function XMaverick2Manager.GetLastSelRobotId()
        local key = XMaverick2Manager.GetLastSelRobotSaveKey()
        local robotId =  XSaveTool.GetData(key)
        if robotId then
            return robotId
        else
            local robotCfgs = XMaverick2Configs.GetMaverick2Robot()
            for _, robotCfg in pairs(robotCfgs) do
                local isUnlock = XMaverick2Manager.IsRobotUnlock(robotCfg.RobotId)
                if isUnlock then
                    return robotCfg.RobotId
                end
            end
        end
    end

    function XMaverick2Manager.GetLastSelRobotSaveKey()
        return XDataCenter.Maverick2Manager.GetActivitySaveKey() .. "XUiMaverick2Explore_GetLastSelRobotSaveKey"
    end

    -- 保存机器人选中的支援技能
    function XMaverick2Manager.SaveRobotSelHelpSkill(robotId, talentId)
        local key = XMaverick2Manager.GetRobotSelHelpSkillSaveKey(robotId)
        XSaveTool.SaveData(key, talentId)
    end

    -- 获取上次机器人选中的支援技能
    function XMaverick2Manager.GetRobotSelHelpSkill(robotId)
        local key = XMaverick2Manager.GetRobotSelHelpSkillSaveKey(robotId)
        local talentId =  XSaveTool.GetData(key)
        return talentId
    end

    function XMaverick2Manager.GetRobotSelHelpSkillSaveKey(robotId)
        return XDataCenter.Maverick2Manager.GetActivitySaveKey() .. "XUiMaverick2Explore_GetRobotSelHelpSkillSaveKey_robotId:" .. robotId
    end

    -- 获取机器人的所有属性
    function XMaverick2Manager.GetRobotPropertyList(robotId)
        local allAttr = {}

        -- 角色基础
        local robotCfg = XMaverick2Configs.GetMaverick2Robot(robotId, true)
        for i, attrId in ipairs(robotCfg.AttrId) do
            local attr = {AttrId = attrId, AttrValue = robotCfg.AttrValue[i] }
            table.insert(allAttr, attr)
        end

        -- 心智等级
        local mentalLv = XDataCenter.Maverick2Manager.GetMentalLv()
        if mentalLv ~= 0 then
            local mentalCfg = XMaverick2Configs.GetMaverick2Mental(mentalLv, true)
            for i, attrId in ipairs(mentalCfg.AttrId) do
                local attr = {AttrId = attrId, AttrValue = mentalCfg.AttrValue[i] }
                table.insert(allAttr, attr)
            end
        end

        -- 天赋加成
        local talentCfgs = XDataCenter.Maverick2Manager.GetRobotTalentCfgs(robotId)
        for _, talentCfg in ipairs(talentCfgs) do
            if talentCfg.AttrId ~= 0 then 
                local attr = {AttrId = talentCfg.AttrId, AttrValue = talentCfg.AttrValue }
                table.insert(allAttr, attr)
            end
        end

        -- 整合数据
        local attDic = {}
        for _, attr in ipairs(allAttr) do
            if attDic[attr.AttrId] then
                attDic[attr.AttrId] = attDic[attr.AttrId] + attr.AttrValue
            else
                attDic[attr.AttrId] = attr.AttrValue
            end
        end
        local attrList = {}
        for attrId, attrValue in pairs(attDic) do
            local attr = {AttrId = attrId, AttrValue = attrValue}
            table.insert(attrList, attr)
        end
        table.sort(attrList, function(a, b)
            local configA = XMaverick2Configs.GetMaverick2Attribute(a.AttrId, true)
            local configB = XMaverick2Configs.GetMaverick2Attribute(b.AttrId, true)
            return configA.Order < configB.Order
        end)

        return attrList
    end

    -- 检测是否有机器人解锁
    function XMaverick2Manager.CheckRobotUnlock()
        local robotCfgs = XMaverick2Configs.GetMaverick2Robot()
        for _, robotCfg in pairs(robotCfgs) do
            local robotId = robotCfg.RobotId
            local robotData = XDataCenter.Maverick2Manager.GetCharacterData(robotId)
            local isUnlock = XDataCenter.Maverick2Manager.IsRobotUnlockCondition(robotId)
            if not robotData and isUnlock then
                local request = { RobotId = robotId }
                XNetwork.Call("Maverick2UnlockCharacterRequest", request, function(res)
                    if res.Code ~= XCode.Success then
                        XUiManager.TipCode(res.Code)
                        return
                    end
                    XDataCenter.Maverick2Manager.AddCharacterData(robotId)
                    
                    -- 打开解锁界面
                    if robotCfg.Condition ~= 0 then
                        local data = {}
                        data.Title = XUiHelper.GetText("Maverick2RobotlUnlock")
                        data.Name = robotCfg.Name
                        data.Desc = robotCfg.UnLockDesc
                        data.Icon = robotCfg.Icon
                        XLuaUiManager.Open("UiMaverick2Unlock", data)
                    end
                end)
            end
        end
    end

    -- 机器人是否显示红点
    function XMaverick2Manager.IsRobotRed(robotId)
        local isUnlock = XMaverick2Manager.IsRobotUnlock(robotId)
        if not isUnlock then
            return false
        end

        local saveKey = XMaverick2Manager.GetRobotSaveKey(robotId)
        local isRemove = XSaveTool.GetData(saveKey) == true
        return not isRemove
    end

    -- 移除机器人红点
    function XMaverick2Manager.RemoveRobotRed(robotId)
        local saveKey = XMaverick2Manager.GetRobotSaveKey(robotId)
        XSaveTool.SaveData(saveKey, true)
    end

    function XMaverick2Manager.GetRobotSaveKey(robotId)
        return XMaverick2Manager.GetActivitySaveKey() .. "XMaverick2Manager_GetRobotSaveKey_robotId:" .. tostring(robotId)
    end

    -------------------------------------------------- 机器人 end --------------------------------------------------


    -------------------------------------------------- 支援技 begin --------------------------------------------------
    -- 设置支援技
    function XMaverick2Manager.SetAssistTalentDatas(assistTalentDatas)
        AssistTalentLvDic = {}
        for _, groupData in ipairs(assistTalentDatas) do
            for _, talentData in ipairs(groupData.TalentDatas) do
                XMaverick2Manager.UpdateAssistTalentLv(talentData.TalentId, talentData.Level)
            end
        end
    end

    -- 获取支援技等级
    function XMaverick2Manager.GetAssistTalentLv(talentId)
        local lv = AssistTalentLvDic[talentId]
        return lv and lv or 0
    end

    -- 获取支援技是否解锁
    function XMaverick2Manager.IsAssistTalentUnlock(talentId)
        local lv = XMaverick2Manager.GetAssistTalentLv(talentId)
        return lv > 0
    end

    -- 更新支援技等级
    function XMaverick2Manager.UpdateAssistTalentLv(talentId, lv)
        AssistTalentLvDic[talentId] = lv
    end

    -- 检测支援技升级
    function XMaverick2Manager.CheckAssistTalentLvUp()
        local configs = XMaverick2Configs.GetRobotAssistSkillConfigs()
        for _, config in ipairs(configs) do
            local groupId = config.TalentGroupId
            local talentId = config.TalentId
            local lvConfigs = XMaverick2Configs.GetTalentLvConfigs(talentId)
            local lv = XMaverick2Manager.GetAssistTalentLv(talentId)
            local nextLv = lv + 1
            local nextLvCfg = lvConfigs[nextLv]
            if nextLvCfg then
                local isUnlock = true
                if nextLvCfg.Condition ~= 0 then
                    isUnlock = XConditionManager.CheckCondition(nextLvCfg.Condition)
                end
                if isUnlock then
                    local request = { GroupId = groupId, TalentId = talentId }
                    XNetwork.Call("Maverick2UpgradeAssistTalentRequest", request, function(res)
                        if res.Code ~= XCode.Success then
                            XUiManager.TipCode(res.Code)
                            return
                        end

                        XMaverick2Manager.UpdateAssistTalentLv(talentId, nextLv)
                        
                        -- 打开解锁界面
                        if nextLvCfg.Condition then
                            local data = {}
                            data.Title = XUiHelper.GetText("Maverick2HelpSkillUnlock")
                            data.Name = nextLvCfg.UnlockName
                            data.Desc = nextLvCfg.UnlockDesc
                            data.Icon = nextLvCfg.Icon
                            data.IsSkill = true
                            XLuaUiManager.Open("UiMaverick2Unlock", data)
                        end
                    end)
                end
            end
        end
    end
    -------------------------------------------------- 支援技 end --------------------------------------------------



    

    -------------------------------------------------- 任务 begin --------------------------------------------------

    -- 检查所有任务是否有奖励可领取
    function XMaverick2Manager.CheckTaskCanReward()
        if not XMaverick2Manager.IsOpen() then
            return false
        end
        local groupIdList = XMaverick2Configs.GetTaskGroupIds()
        for _, groupId in pairs(groupIdList) do
            if XDataCenter.TaskManager.CheckLimitTaskList(groupId) then
                return true
            end
        end
        return false
    end
    -------------------------------------------------- 任务 end --------------------------------------------------


    -------------------------------------------------- 商店 begin --------------------------------------------------
    -- 请求商店数据
    function XMaverick2Manager.RequestShopInfoList(cb)
        local shopIds = XMaverick2Configs.GetShopIds()
        XShopManager.GetShopInfoList(shopIds, function()
            if cb then
                cb()
            end
        end, XShopManager.ActivityShopType.Maverick2)
    end

    -- 打开商店界面
    function XMaverick2Manager.OpenUiShop()
        if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon) 
            or XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopActive) then
            
            XMaverick2Manager.RequestShopInfoList(function()
                local shopIds = XMaverick2Configs.GetShopIds()
                XLuaUiManager.Open("UiMaverick2Shop", shopIds)
            end)
        end
    end

    -- 获取商店解锁的商品id列表
    local GetShopUnlockGoodIds = function(shopIds)
        local goodIdList = {}
        for _, shopId in ipairs(shopIds) do
            local shopGoods = XShopManager.GetShopGoodsList(shopId)
            for _, good in ipairs(shopGoods) do
                local isUnlock = true
                local conditionIds = good.ConditionIds
                if conditionIds and #conditionIds > 0 then
                    for _, id in pairs(conditionIds) do
                        local ret, desc = XConditionManager.CheckCondition(id)
                        isUnlock = isUnlock and ret
                    end
                end
                if isUnlock then
                    table.insert(goodIdList, good.Id)
                end
            end
        end

        return goodIdList
    end

    function XMaverick2Manager.IsShowShopRed()
        local isRed = false
        if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon, nil, true) 
            or XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopActive, nil, true) then
            
            local shopIds = XMaverick2Configs.GetShopIds()
            local unlockGoodIds = IsRequestShopInfo and GetShopUnlockGoodIds(shopIds) or {}
            local lastGoodIds = XMaverick2Manager.GetShopLocalUnlockGoodIds()
            isRed = #unlockGoodIds > #lastGoodIds

            -- 未请求商店数据时，请求商店数据后发送事件刷新
            if not IsRequestShopInfo then
                IsRequestShopInfo = true
                XMaverick2Manager.RequestShopInfoList(function()
                    CsXGameEventManager.Instance:Notify(XEventId.EVENT_ACTIVITY_CHAPTER_REFRESH_RED)
                end)
            end
        end

        return isRed
    end

    -- 获取本地保存的解锁商品id列表
    function XMaverick2Manager.GetShopLocalUnlockGoodIds()
        local key = XMaverick2Manager.GetShopGoodUnlockSaveKey()
        return XSaveTool.GetData(key) or {}
    end

    -- 刷新本地保存的解锁商品id列表
    function XMaverick2Manager.RefreshShopLocalUnlockGoodIds()
        local shopIds = XMaverick2Configs.GetShopIds()
        local goodIds = IsRequestShopInfo and GetShopUnlockGoodIds(shopIds) or {}
        local key = XMaverick2Manager.GetShopGoodUnlockSaveKey()
        XSaveTool.SaveData(key, goodIds)
    end

    function XMaverick2Manager.GetShopGoodUnlockSaveKey()
        return XMaverick2Manager.GetActivitySaveKey() .. "XMaverick2Manager_GetShopGoodUnlockSaveKey"
    end
    -------------------------------------------------- 商店 end --------------------------------------------------


    -------------------------------------------------- 排行榜 begin --------------------------------------------------

    function XMaverick2Manager.OpenUiRank()
        local request = { ActivityId = ActivityId }
        XNetwork.Call("Maverick2GetRankRequest", request, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            RankData = res
            
            XLuaUiManager.Open("UiMaverick2Rank")
        end)
    end

    function XMaverick2Manager.GetRankingList()
        return RankData.RankPlayerInfos
    end

    function XMaverick2Manager.GetMyRankInfo()
        local myRank = {}
        local percentRank = 100 -- 101名及以上显示百分比
        local rank = RankData.Rank
        if RankData.Rank > percentRank then
            rank = math.floor(RankData.Rank * 100 / RankData.TotalCount) .. "%"
        elseif RankData.Rank == 0 then
            rank = XUiHelper.GetText("ExpeditionNoRanking")
        end
        myRank["Rank"] = rank
        myRank["Id"] = XPlayer.Id
        myRank["Name"] = XPlayer.Name
        myRank["HeadPortraitId"] = XPlayer.CurrHeadPortraitId
        myRank["HeadFrameId"] = XPlayer.CurrHeadFrameId
        myRank["Score"] = RankData.Score
        myRank["RobotIds"] = RankData.RobotIds
        return myRank
    end

    function XMaverick2Manager.GetRankingSpecialIcon(rank)
        if type(rank) ~= "number" or rank < 1 or rank > 3 then return end
        local icon = CS.XGame.ClientConfig:GetString("BabelTowerRankIcon"..rank) 
        return icon
    end
    -------------------------------------------------- 排行榜 end --------------------------------------------------


    -------------------------------------------------- 战斗 begin --------------------------------------------------

    -- 进入战斗
    function XMaverick2Manager.EnterFight(stageId, robotId, talentGroupId, talentId)
        ReFightData = {StageId = stageId, RobotId = robotId, TalentGroupId = talentGroupId, TalentId = talentId}
        XDataCenter.FubenManager.EnterMaverick2Fight(stageId, robotId, talentGroupId, talentId)
    end

    function XMaverick2Manager.ReEnterFight()
        local isOpen = XMaverick2Manager.IsOpen()
        if isOpen then
            XDataCenter.FubenManager.EnterMaverick2Fight(ReFightData.StageId, ReFightData.RobotId, ReFightData.TalentGroupId, ReFightData.TalentId)
        else
            -- 活动结束弹出主界面
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        end
    end
    -------------------------------------------------- 战斗 end --------------------------------------------------


    -------------------------------------------------- manager接口重写 begin --------------------------------------------------
    function XMaverick2Manager.ExOpenMainUi()
        --功能没开启
        if not XFunctionManager.DetectionFunction(XMaverick2Manager.ExGetFunctionNameType()) then
            return
        end
        --活动没开放
        if not XMaverick2Manager.IsOpen() then
            XUiManager.TipText("CommonActivityNotStart")
            return
        end
        XLuaUiManager.Open("UiMaverick2Main")
    end

    function XMaverick2Manager.ExGetFunctionNameType()
        return XFunctionManager.FunctionName.Maverick2
    end

    function XMaverick2Manager.InitStageInfo()
        local cfgs = XMaverick2Configs.GetMaverick2Stage()
        for k, cfg in pairs(cfgs) do
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(cfg.StageId)
            stageInfo.Type = XDataCenter.FubenManager.StageType.Maverick2
        end
    end

    function XMaverick2Manager.CallFinishFight()
        local res = XDataCenter.FubenManager.FubenSettleResult
        XDataCenter.FubenManager.FubenSettling = false
        XDataCenter.FubenManager.FubenSettleResult = nil

        --通知战斗结束，关闭战斗设置页面
        CS.XGameEventManager.Instance:Notify(XEventId.EVENT_FIGHT_FINISH)

        if not res then
            -- 强退
            XMaverick2Manager.ChallengeLose()
            return
        end

        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            XMaverick2Manager.ChallengeLose()
            CS.XGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_SETTLE_FAIL, res.Code)
            return
        end

        local stageId = res.Settle.StageId
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_FIGHT_RESULT, res.Settle)

        XSoundManager.StopCurrentBGM()
        XMaverick2Manager.FinishFight(res.Settle)
    end

    -- 战斗结束回调
    function XMaverick2Manager.FinishFight(settle)
        if settle.IsWin then
            XMaverick2Manager.ChallengeWin(settle)
        else
            XMaverick2Manager.ChallengeLose()
        end
    end

    -- 战斗胜利回调
    function XMaverick2Manager.ChallengeWin(settleData)
        local beginData = XDataCenter.FubenManager.GetFightBeginData()
        local winData = XDataCenter.FubenManager.GetChallengeWinData(beginData, settleData)
        local stage = XDataCenter.FubenManager.GetStageCfg(settleData.StageId)
        local isKeepPlayingStory = stage and XFubenConfigs.IsKeepPlayingStory(stage.StageId) and (stage.EndStoryId)
        local isNotPass = stage and stage.EndStoryId and not beginData.LastPassed

        if isKeepPlayingStory or isNotPass then
            -- 播放剧情
            CsXUiManager.Instance:SetRevertAndReleaseLock(true)
            XDataCenter.MovieManager.PlayMovie(stage.EndStoryId, function()
                -- 弹出结算
                CsXUiManager.Instance:SetRevertAndReleaseLock(false)
                -- 防止带着bgm离开战斗
                XSoundManager.StopCurrentBGM()

                XMaverick2Manager.ShowReward(winData)
            end)
        else
            -- 弹出结算
            XMaverick2Manager.ShowReward(winData)
        end

        XEventManager.DispatchEvent(XEventId.EVENT_FIGHT_RESULT_WIN)
    end

    local GetStarsCount = function(starsMark)
        local count = (starsMark & 1) + (starsMark & 2 > 0 and 1 or 0) + (starsMark & 4 > 0 and 1 or 0)
        local map = {(starsMark & 1) > 0, (starsMark & 2) > 0, (starsMark & 4) > 0 }
        return count, map
    end

    -- 打开奖励结算界面
    function XMaverick2Manager.ShowReward(settleResult)
        local settle = settleResult.SettleData
        local stageId = settle.StageId
        local stageCfg = XMaverick2Configs.GetMaverick2Stage(stageId, true)

        -- 更新关卡数据
        LastPassStageId = stageId
        local starCnt, starsMap
        if stageCfg.StageType == XMaverick2Configs.StageType.Daily then
            DailyStageDic[stageId] = nil
        else
            local stageData = XMaverick2Manager.GetStageData(stageId)
            starCnt, starsMap = GetStarsCount(settle.StarsMark)
            if starCnt > stageData.StarCount then
                stageData.StarCount = starCnt
            end
            XMaverick2Manager.SetStageData(stageData)
        end

        -- 更新积分数据
        local oldScore = ScoreStageRecord.Score
        local newScore = 0
        if stageCfg.StageType == XMaverick2Configs.StageType.Score then
            if settle.Maverick2SettleResult and settle.Maverick2SettleResult.Score > ScoreStageRecord.Score then
                ScoreStageRecord.Score = settle.Maverick2SettleResult.Score
                ScoreStageRecord.RobotIds = { ReFightData.RobotId }
                newScore = settle.Maverick2SettleResult.Score
            end
        end

        -- 打开结算界面
        XLuaUiManager.Remove("UiMaverick2Character")
        if stageCfg.StageType == XMaverick2Configs.StageType.Score then
            XLuaUiManager.Open("UiMaverick2ScoreResult", settle, oldScore, newScore)
        else
            local beginData = XDataCenter.FubenManager.GetFightBeginData()
            local winData = XDataCenter.FubenManager.GetChallengeWinData(beginData, settle)
            winData.StarsMap = starsMap

            local isBoss = stageCfg.StageType == XMaverick2Configs.StageType.MainLineBoss
            local starDescs = XFubenConfigs.GetStarDesc(stageId)
            local isShowCondition = isBoss and starDescs and #starDescs > 0 
            if isShowCondition then
                XLuaUiManager.Open("UiSettleWinMainLine", winData)
            else
                XLuaUiManager.Open("UiSettleWin", winData, nil, nil, true)
            end
        end
    end

    -- XFubenManager战斗失败回调
    function XMaverick2Manager.ChallengeLose()
        XLuaUiManager.Open("UiMaverick2Lose", XMaverick2Manager.ReEnterFight)
    end
    
    -------------------------------------------------- manager接口重写 end --------------------------------------------------

    -- 活动数据刷新
    function XMaverick2Manager.RefreshDataByServer(data)
        ActivityId = data.ActivityId
        -- 章节信息
        XMaverick2Manager.SetChapterDatas(data.ChapterDatas)
        -- 机器人数据
        XMaverick2Manager.SetCharacterDatas(data.CharacterDatas)
        -- 支援技
        XMaverick2Manager.SetAssistTalentDatas(data.AssistTalentDatas)
        -- 积分关
        ScoreStageRecord = data.StagePassRecordForRank
        -- 心智天赋
        MentalLevel = data.MentalLevel
        -- 每日关卡
        XMaverick2Manager.RefreshDailyStageIds(data.DailyStageIds)

        -- 重置自定义数据
        LastPassStageId = nil
    end

    -- 每日关卡重置
    function XMaverick2Manager.RefreshDailyStageIds(dailyStageIds)
        DailyStageDic = {}
        for _, stageId in ipairs(dailyStageIds) do
            DailyStageDic[stageId] = true
        end

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_MAVERICK2_UPDATE_DAILY)
    end

	XMaverick2Manager.Init()
	return XMaverick2Manager
end


-- =========网络=========

-- 通知活动数据
XRpc.NotifyMaverick2Data = function(data)
    XDataCenter.Maverick2Manager.RefreshDataByServer(data.Maverick2Data)
end

-- 通知每日关卡重置
XRpc.NotifyMaverick2DailyReset = function(data)
    XDataCenter.Maverick2Manager.RefreshDailyStageIds(data.DailyStageIds)
end
