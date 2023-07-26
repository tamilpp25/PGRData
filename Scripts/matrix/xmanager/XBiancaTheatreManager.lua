local XExFubenSimulationChallengeManager = require("XEntity/XFuben/XExFubenSimulationChallengeManager")

local XAdventureManager = require("XEntity/XBiancaTheatre/Adventure/XAdventureManager")
local XTheatreTaskManager = require("XEntity/XBiancaTheatre/Task/XTheatreTaskManager")
local XComboList = require("XEntity/XBiancaTheatre/Combo/XTheatreComboList")
local XAdventureEnd = require("XEntity/XBiancaTheatre/Adventure/XAdventureEnd")
local XAdventureDifficulty = require("XEntity/XBiancaTheatre/Adventure/XAdventureDifficulty")

XBiancaTheatreManagerCreator = function()
    ---@class XBiancaTheatreManager
    local XBiancaTheatreManager = XExFubenSimulationChallengeManager.New(XFubenConfigs.ChapterType.BiancaTheatre)
    -- 当前冒险管理 XAdventureManager
    local CurrentAdventureManager = nil
    -- 任务管理
    local TaskManager = XTheatreTaskManager.New()
    -- 完全经过的章节，章节ID
    local _PassChapterIdList = {}
    -- 已经完成的时间步骤
    local _PassEventRecordDic = {}
    -- 已完成的结局数据
    local _EndingIdRecords = {}
    -- 羁绊管理
    local ComboList = XComboList.New()
    -- 缓存当前等级，用于判断等级是否提升
    local CurLevelCache = 0
    -- 缓存当前图鉴数目，用于判断图鉴是否增加
    local UnlockItemCountCache = 0
    -- 对局结束时新增的解锁道具ID，用于道具解锁提示
    local NewUnlockItemIdDic = {}
    -- 正常的队伍人数
    local _TeamCount = 3

    -- 当前活动Id
    local CurActivityId = 0
    -- 当前章节Id
    local CurChapterId = 0
    -- 选择的难度ID
    local DifficultyId = 0
    -- 当前总经验
    local TotalExp = 0
    -- 已经领取的奖励
    local GetRewardIds = {}
    -- 已购买的强化
    local StrengthenDbs = {}
    -- 已解锁物品ID，用于图鉴
    local UnlockItemIdDic = {}
    -- 已解锁队伍ID
    local UnlockTeamId = {}
    -- 解锁难度
    local UnlockDifficultyId = {}
    -- 当前难度数据 XAdventureDifficulty
    local CurrentDifficulty = nil
    -- 历史分队数据
    local TeamRecords = {}
    -- 通关章节
    local PassChapterIdDict = {}
    -- 当局灵视是否开启
    local IsOpenVision = false
    -- 成就奖励领取记录
    local GetAchievementRecords = {}
    -- 新的队伍人数
    local TeamCountEffect = _TeamCount

    -- 累计获得道具总数
    local HistoryTotalItemCount = 0
    -- 累计通过战斗节点数
    local HistoryTotalPassFightNodeCount = 0
    -- 累计获得道具品质，数量
    local HistoryItemObtainRecords = {}
    -- 当前游戏通过战斗节点数
    local GamePassNodeCount = 0
    -- 经历的事件Id key = eventId, value = eventSetpId[]
    local PassedEventRecord = {}
    -- 成就是否开启
    local AchievementContidion = false
    -- 版本更新是否有旧冒险数据进行自动结算
    local NewStage = false

    function XBiancaTheatreManager.InitWithServerData(data)
        CurActivityId = data.CurActivityId
        XDataCenter.BiancaTheatreManager.UpdateTotalExp(data.TotalExp)
        XDataCenter.BiancaTheatreManager.UpdateCurChapterId(data.CurChapterId)
        XDataCenter.BiancaTheatreManager.UpdateGetRewardIds(data.GetRewardIds)
        XDataCenter.BiancaTheatreManager.UpdateDifficultyId(data.DifficultyId)
        XDataCenter.BiancaTheatreManager.UpdateDifficulty(XAdventureDifficulty.New(data.DifficultyId))
        XDataCenter.BiancaTheatreManager.UpdateStrengthenDbs(data.StrengthenDbs)
        XDataCenter.BiancaTheatreManager.UpdateUnlockItemId(data.UnlockItemId)
        XDataCenter.BiancaTheatreManager.UpdateTeamRecords(data.TeamRecords)
        XDataCenter.BiancaTheatreManager.UpdatePassCharacterIdDict(data.PassChapterIds)
        XDataCenter.BiancaTheatreManager.UpdateUnlockDifficultyId(data.UnlockDifficultyId)
        XDataCenter.BiancaTheatreManager.UpdateUnlockTeamId(data.UnlockTeamId)
        XDataCenter.BiancaTheatreManager.UpdateIsOpenVision(data.IsOpenVision)
        XDataCenter.BiancaTheatreManager.UpdateGetAchievementRecords(data.GetAchievementRecords)
        XDataCenter.BiancaTheatreManager.UpdateAchievemenetContidion(XTool.IsNumberValid(data.AchievementCondition))
        XDataCenter.BiancaTheatreManager.UpdateTeamCountEffect(data.TeamCountEffect)

        XDataCenter.BiancaTheatreManager.UpdateHistoryTotalItemCount(data.HistoryTotalItemCount)
        XDataCenter.BiancaTheatreManager.UpdateHistoryTotalPassFightNodeCount(data.HistoryTotalPassFightNodeCount)
        XDataCenter.BiancaTheatreManager.UpdateHistoryItemObtainRecords(data.HistoryItemObtainRecords)
        XDataCenter.BiancaTheatreManager.UpdateGamePassNodeCount(data.GamePassNodeCount)
        XDataCenter.BiancaTheatreManager.UpdatePassedEventRecord(data.PassedEventRecord)
        XDataCenter.BiancaTheatreManager.UpdateNewStage(XTool.IsNumberValid(data.NewStage))

        XDataCenter.BiancaTheatreManager.SetCurLevelCache()
        XDataCenter.BiancaTheatreManager.SetCacheUnlockItemCount()
        -- 初始化数据时清空新增的道具解锁
        XDataCenter.BiancaTheatreManager.ClearNewUnlockItemDic()

        -- 更新当前冒险数据
        if data.CurChapterDb then
            XDataCenter.BiancaTheatreManager.UpdateCurrentAdventureManager(XAdventureManager.New())
            CurrentAdventureManager:InitWithServerData({
                CurChapterDb = data.CurChapterDb,   -- 章节数据
                DifficultyId = data.DifficultyId,   -- 难度
                CurTeamId = data.CurTeamId,   -- 当前分队ID
                CurRoleLv = data.CurRoleLv, -- 冒险等级
                Characters = data.Characters, -- 已招募的角色 TheatreRoleAttr表的roleId
                SingleTeamData = data.SingleTeamData,   -- 单队伍数据
                Items = data.Items, --本局拥有道具
            })
        end
    end
    
    function XBiancaTheatreManager.UpdateTotalExp(totalExp)
        TotalExp = totalExp
        XEventManager.DispatchEvent(XEventId.EVENT_BIANCA_THEATRE_TOTAL_EXP_CHANGE)
    end
    
    --更新主界面外的部分背景
    function XBiancaTheatreManager.UpdateChapterBg(rawImage)
        if XTool.UObjIsNil(rawImage) then
            return
        end
        local chapter = XBiancaTheatreManager.GetCurrentAdventureManager():GetCurrentChapter()
        local chapterId = chapter and chapter:GetCurrentChapterId()
        rawImage:SetRawImage(XBiancaTheatreConfigs.GetChapterOtherBg(chapterId))
    end

    -- 检查物品数量是否满足指定数量
    function XBiancaTheatreManager.CheckItemCountIsEnough(itemId, count, stepItemType)
        if XBiancaTheatreManager.GetItemCount(itemId, stepItemType) < count then
            XUiManager.TipError(XUiHelper.GetText("AssetsBuyConsumeNotEnough", XBiancaTheatreConfigs.GetEventStepItemName(itemId, stepItemType)))
            return false
        end
        return true
    end

    function XBiancaTheatreManager.GetItemCount(itemId, stepItemType)
        if stepItemType == XBiancaTheatreConfigs.XEventStepItemType.OutSideItem then
            return XDataCenter.ItemManager.GetCount(itemId)
        elseif stepItemType == XBiancaTheatreConfigs.XEventStepItemType.ItemBox or stepItemType == XBiancaTheatreConfigs.XEventStepItemType.Ticket then
            return 0
        else
            return XBiancaTheatreManager.GetCurrentAdventureManager():GetTheatreItemCount(itemId)
        end
    end


    ------------- 背景音乐相关 begin -----------
    --检查背景音乐的播放
    function XBiancaTheatreManager.CheckBgmPlay()
        local curChapter = XBiancaTheatreManager.GetCurrentAdventureManager():GetCurrentChapter(true)
        local bgmCueId = XBiancaTheatreConfigs.GetChapterBgmCueId(curChapter:GetId())
        XSoundManager.PlaySoundByType(bgmCueId, XSoundManager.SoundType.BGM)
    end

    function XBiancaTheatreManager.CheckEndBgmPlay(adventureEnd)
        if not adventureEnd or not XTool.IsNumberValid(adventureEnd:GetBgmCueId()) then
            return
        end
        XSoundManager.PlaySoundByType(adventureEnd:GetBgmCueId(), XSoundManager.SoundType.BGM)
    end
    ------------- 背景音乐相关 end -----------


    ------------- 声效滤镜相关 end -----------
    local CurAudioFilterVisionId = nil

    function XBiancaTheatreManager.StartAudioFilter()
        if CurAudioFilterVisionId then
            return
        end
        local visionValue = XBiancaTheatreManager.GetCurrentAdventureManager():GetVisionValue()
        XBiancaTheatreManager.OpenAudioFilter(XBiancaTheatreConfigs.GetVisionIdByValue(visionValue))
    end

    -- 开启滤镜
    function XBiancaTheatreManager.OpenAudioFilter(audioFilterVisionId)
        if not XBiancaTheatreManager.CheckVisionIsOpen() or not XTool.IsNumberValid(audioFilterVisionId) then
            return
        end
        XBiancaTheatreManager.ResetAudioFilter(CurAudioFilterVisionId)
        local cueId = XBiancaTheatreConfigs.GetVisionSoundFilterOpenCueId(audioFilterVisionId)
        if XTool.IsNumberValid(cueId) then
            XSoundManager.PlaySoundByType(cueId, XSoundManager.SoundType.Sound)
            CurAudioFilterVisionId = audioFilterVisionId
            XScheduleManager.Schedule(function ()
                local audioInfo = XSoundManager.CheckHaveCue(cueId)
                if audioInfo and audioInfo.Playing then
                    XSoundManager.ResetSystemAudioVolume()
                end
            end, 0, 60)
        end
    end

    -- 关闭滤镜
    function XBiancaTheatreManager.ResetAudioFilter(audioFilterVisionId)
        local visionId = audioFilterVisionId or CurAudioFilterVisionId
        if XTool.IsNumberValid(visionId) then
            local openCueId = XBiancaTheatreConfigs.GetVisionSoundFilterOpenCueId(visionId)
            -- local closeCueId = XBiancaTheatreConfigs.GetVisionSoundFilterCloseCueId(visionId)
            -- if XTool.IsNumberValid(closeCueId) then
            --     XSoundManager.PlaySoundByType(closeCueId, XSoundManager.SoundType.Sound)
            --     XSoundManager.Stop(closeCueId)
            -- end
            if XTool.IsNumberValid(openCueId) then
                XSoundManager.Stop(openCueId)
            end
            XSoundManager.ResetSystemAudioVolume()
        end
        CurAudioFilterVisionId = nil
    end

    ---初始化音效滤镜
    function XBiancaTheatreManager.InitAudioFilter()
        local configs = XBiancaTheatreConfigs.GetBiancaTheatreVision()
        -- local closeCueId
        for _, config in ipairs(configs) do
            -- if closeCueId ~= config.SoundFilterCloseCueId then
            --     closeCueId = config.SoundFilterCloseCueId
            --     if XTool.IsNumberValid(closeCueId) then
            --         XSoundManager.PlaySoundByType(closeCueId, XSoundManager.SoundType.Sound)
            --         XSoundManager.Stop(closeCueId)
            --     end
            -- end
            local openCueId = config.SoundFilterOpenCueId
            if XTool.IsNumberValid(openCueId) then
                XSoundManager.Stop(openCueId)
            end
        end
        XSoundManager.ResetSystemAudioVolume()
    end

    -- 返回主界面时关闭滤镜
    function XBiancaTheatreManager.RunMain()
        XBiancaTheatreManager.ResetAudioFilter()
        XLuaUiManager.RunMain()
    end

    ---播放奖励音效(1:领取秘藏箱 | 2:领取秘藏品 | 3:领取邀约)
    ---@param nodeRewardType number XNodeRewardType
    ---@param index number
    function XBiancaTheatreManager.PlayGetRewardSound(nodeRewardType, index)
        local targetIndex
        if XTool.IsNumberValid(index) then
            targetIndex = index
        else
            if nodeRewardType == XBiancaTheatreConfigs.XNodeRewardType.ItemBox then
                targetIndex = 1
            elseif nodeRewardType == XBiancaTheatreConfigs.XNodeRewardType.Ticket then
                targetIndex = 3
            end
        end
        local cueId = XBiancaTheatreConfigs.GetCueWhenGetReward(targetIndex)
        if XTool.IsNumberValid(cueId) then
            XSoundManager.PlaySoundByType(cueId, XSoundManager.SoundType.Sound)
        end
    end
    ------------- 声效滤镜相关 end -----------


    ------------- 难度相关 begin -----------
    function XBiancaTheatreManager.GetDifficultyId()
        return DifficultyId
    end

    function XBiancaTheatreManager.UpdateDifficultyId(difficultyId)
        DifficultyId = difficultyId
    end

    function XBiancaTheatreManager.UpdateDifficulty(difficulty)
        CurrentDifficulty = difficulty
    end

    function XBiancaTheatreManager:GetCurrentDifficulty()
        return CurrentDifficulty
    end

    function XBiancaTheatreManager.UpdateUnlockDifficultyId(ids)
        if XTool.IsTableEmpty(ids) then return end

        for _, id in ipairs(ids or {}) do
            UnlockDifficultyId[id] = true
        end
    end

    function XBiancaTheatreManager.CheckDifficultyUnlock(difficultyId)
        return UnlockDifficultyId[difficultyId] and true or false
    end
    ------------- 难度相关 end -----------


    ------------- 分队相关 begin -----------
    ---//历史分队数据
    --    public class XBiancaTheatreChapterTeam
    --    {
    --        //分队ID
    --        public int TeamId;
    --        //已通关结局
    --        public HashSet<int> EndRecords = new HashSet<int>();
    --    }
    function XBiancaTheatreManager.UpdateTeamRecords(teamRecords)
        for _, chapterTeam in ipairs(teamRecords or {}) do
            if not TeamRecords[chapterTeam.TeamId] then
                TeamRecords[chapterTeam.TeamId] = {}
            end
            for _, endingId in pairs(chapterTeam.EndRecords) do
                TeamRecords[chapterTeam.TeamId][endingId] = true
            end
        end
    end

    function XBiancaTheatreManager.GetTeamEndingIsActive(teamId, endingId)
        return TeamRecords[teamId] and TeamRecords[teamId][endingId]
    end
    
    function XBiancaTheatreManager.UpdateUnlockTeamId(ids)
        for _, id in ipairs(ids or {}) do
            UnlockTeamId[id] = true
        end
    end
    
    function XBiancaTheatreManager.CheckTeamUnlock(teamId)
        return UnlockTeamId[teamId] and true or false
    end

    function XBiancaTheatreManager.GetTeamIdList()
        local teamIdList = {}
        local teamIdListCfg = XBiancaTheatreConfigs.GetTeamIdList()
        local timeId
        for _, teamId in ipairs(teamIdListCfg) do
            timeId = XBiancaTheatreConfigs.GetTeamTimeId(teamId)
            if XFunctionManager.CheckInTimeByTimeId(timeId, true) then
                table.insert(teamIdList, teamId)
            end
        end
        return teamIdList
    end
    ------------- 分队相关 end -------------


    ------------- 强化相关 begin -----------
    function XBiancaTheatreManager.UpdateStrengthenDbs(strengthenDbs)
        for _, strengthenId in ipairs(strengthenDbs or {}) do
            StrengthenDbs[strengthenId] = true
        end
    end

    function XBiancaTheatreManager.IsBuyStrengthen(strengthenId)
        return StrengthenDbs[strengthenId] or false
    end

    --是否已购买某个组里的所有强化项目
    function XBiancaTheatreManager.IsStrengthenGroupAllBuy(strengthenGroupId)
        local strengthenIdList = XTool.IsNumberValid(strengthenGroupId) and XBiancaTheatreConfigs.GetStrengthenIdList(strengthenGroupId) or {}
        for _, strengthenId in ipairs(strengthenIdList) do
            if not XBiancaTheatreManager.IsBuyStrengthen(strengthenId) then
                return false
            end
        end
        return true
    end

    --检查技能是否解锁
    function XBiancaTheatreManager.CheckStrengthenUnlock(strengthenId)
        local preIds = XBiancaTheatreConfigs.GetStrengthenPreStrengthenIds(strengthenId)
        if XTool.IsTableEmpty(preIds) then
            return true
        end
        for _, id in ipairs(preIds) do
            local isActive = XBiancaTheatreManager.IsBuyStrengthen(id)
            if not isActive then
                return false
            end
        end
        return true
    end
    ------------- 强化相关 end -----------


    ------------- 奖励等级 begin -----------
    function XBiancaTheatreManager.UpdateGetRewardIds(getRewardIds)
        for _, theatreRewardId in ipairs(getRewardIds or {}) do
            GetRewardIds[theatreRewardId] = true
        end
    end

    function XBiancaTheatreManager.GetTotalExp()
        return TotalExp
    end
    
    function XBiancaTheatreManager.GetCurExpWithLv(level)
        local exp = TotalExp
        for i = 1, level do
            local unlockScore = XBiancaTheatreConfigs.GetLevelRewardUnlockScore(i)
            exp = exp - unlockScore
        end
        return math.max(0, exp)
    end

    --获得当前奖励等级（配置Id必须从1开始累加）
    function XBiancaTheatreManager.GetCurRewardLevel()
        local configs = XBiancaTheatreConfigs.GetBiancaTheatreLevelReward()
        local curLevel = 0
        local curScore = 0
        for id in pairs(configs) do
            curScore = curScore + XBiancaTheatreConfigs.GetLevelRewardUnlockScore(id)
            if TotalExp >= curScore then
                curLevel = id
            else
                break
            end
        end
        return curLevel
    end

    --判断是否提升等级
    function XBiancaTheatreManager.CheckCurLevelIsUpdate()
        if XBiancaTheatreManager.GetCurRewardLevel() > CurLevelCache then
            XBiancaTheatreManager.SetCurLevelCache()
            return true
        else
            return false
        end
    end

    --设置当前等级缓存，用于判断是否提升等级
    function XBiancaTheatreManager.SetCurLevelCache()
        CurLevelCache = XBiancaTheatreManager.GetCurRewardLevel()
    end

    --读取缓存等级用作升级显示
    function XBiancaTheatreManager.GetCurLevelCache()
        return CurLevelCache
    end

    --是否有未领取的奖励
    function XBiancaTheatreManager.IsHaveReward()
        local configs = XBiancaTheatreConfigs.GetBiancaTheatreLevelReward()
        local curLevel = XBiancaTheatreManager.GetCurRewardLevel()
        for id in pairs(configs) do
            if not GetRewardIds[id] and id <= curLevel then
                return true
            end
        end
        return false
    end
    
    --奖励是否已经领取
    function XBiancaTheatreManager.CheckRewardReceived(lvRewardId)
        return GetRewardIds[lvRewardId] and true or false
    end
    
    --奖励是否可以领取
    function XBiancaTheatreManager.CheckRewardAbleToReceive(lvRewardId)
        local isDraw = XDataCenter.BiancaTheatreManager.CheckRewardReceived(lvRewardId)
        local level = XDataCenter.BiancaTheatreManager.GetCurRewardLevel()
        return level >= lvRewardId and not isDraw
    end
    
    function XBiancaTheatreManager.GetCanReceiveLevelRewardIds()
        local configs = XBiancaTheatreConfigs.GetBiancaTheatreLevelReward()
        local list = {}
        for id, _ in pairs(configs) do
            if XBiancaTheatreManager.CheckRewardAbleToReceive(id) then
                table.insert(list, id)
            end
        end
        
        table.sort(list, function(a, b)
            return a < b
        end)
        
        return list
    end
    ------------- 奖励等级 end -----------

    function XBiancaTheatreManager.CheckIsGlobalFinishChapter(chapterId)
        for _, v in pairs(_PassChapterIdList) do
            if v == chapterId then
                return true
            end
        end
        return false
    end

    function XBiancaTheatreManager.CheckIsGlobalFinishEvent(eventId, stepId)
        if not _PassEventRecordDic[eventId] then return false end
        if not _PassEventRecordDic[eventId][stepId] then return false end
        return true
    end

    function XBiancaTheatreManager.CheckIsFinishEnding(id)
        for _, v in pairs(_EndingIdRecords) do
            if v == id then
                return true
            end
        end
        return false
    end

    function XBiancaTheatreManager.UpdateCurChapterId(chapterId)
        CurChapterId = chapterId
    end

    --检查是否开始冒险了
    function XBiancaTheatreManager.CheckHasAdventure()
        return XTool.IsNumberValid(CurChapterId)
    end

    function XBiancaTheatreManager.GetCurrentAdventureManager()
        if not CurrentAdventureManager then
            CurrentAdventureManager = XBiancaTheatreManager.CreateAdventureManager()
        end
        return CurrentAdventureManager
    end

    function XBiancaTheatreManager.CreateAdventureManager()
        return XAdventureManager.New()
    end

    function XBiancaTheatreManager.UpdateCurrentAdventureManager(value)
        if CurrentAdventureManager then 
            CurrentAdventureManager:Release() 
            CurrentAdventureManager = nil
        end
        CurrentAdventureManager = value
    end
    
    function XBiancaTheatreManager.UpdatePassCharacterIdDict(ids)
        if XTool.IsTableEmpty(ids) then return end

        for _, id in ipairs(ids) do
            PassChapterIdDict[id] = true
        end
    end
    
    function XBiancaTheatreManager.CheckChapterPassed(chapterId)
        return PassChapterIdDict[chapterId] and true or false
    end

    function XBiancaTheatreManager.CheckEndPassed(endId)
        for _, records in pairs(TeamRecords) do
            for endingId, value in pairs(records) do
                if endingId == endId and value then
                    return true
                end
            end
        end
        return false
    end


    ------------------道具图鉴 begin---------------------
    function XBiancaTheatreManager.UpdateUnlockItemId(unlockItemId)
        -- 清空结算后新增的解锁道具字典
        XBiancaTheatreManager.ClearNewUnlockItemDic()

        for _, theatreItemId in ipairs(unlockItemId or {}) do
            -- 添加结算后新增的解锁道具
            if not UnlockItemIdDic[theatreItemId] then
                table.insert(NewUnlockItemIdDic, theatreItemId)
            end
            UnlockItemIdDic[theatreItemId] = true
        end
    end

    function XBiancaTheatreManager.AddUnlockItemIds(unlockItemIds)
        for _, theatreItemId in ipairs(unlockItemIds or {}) do
            if not UnlockItemIdDic[theatreItemId.ItemId] then
                UnlockItemIdDic[theatreItemId.ItemId] = true
            end
        end
    end

    function XBiancaTheatreManager.IsUnlockItem(theatreItemId)
        -- 没有Condition默认解锁
        if not XTool.IsNumberValid(XBiancaTheatreConfigs.GetItemUnlockConditionId(theatreItemId)) then
            return true
        end
        return UnlockItemIdDic[theatreItemId] or false
    end

    function XBiancaTheatreManager.GetUnlockItemCount()
        local count = 0
        --遍历解锁的道具
        for _, itemId in pairs(XBiancaTheatreConfigs.GetTheatreItemIdList()) do
            if XBiancaTheatreManager.IsUnlockItem(itemId) then
                count = count + 1
            end
        end
        return count
    end

    -- 判断图鉴是否增加
    function XBiancaTheatreManager.CheckUnlockItemUpdate()
        if XBiancaTheatreManager.GetUnlockItemCount() > UnlockItemCountCache then
            XBiancaTheatreManager.SetCacheUnlockItemCount()
            return true
        else
            return false
        end
    end

    -- 设置图鉴数量缓存，用于判断结算后图鉴是否增加
    function XBiancaTheatreManager.SetCacheUnlockItemCount()
        UnlockItemCountCache = XBiancaTheatreManager.GetUnlockItemCount()
    end

    -- 情况结算后新增的解锁道具字典
    function XBiancaTheatreManager.ClearNewUnlockItemDic()
        NewUnlockItemIdDic = {}
    end

    -- 获取结算后新增的解锁道具字典
    function XBiancaTheatreManager.GetNewUnlockItemDic()
        return NewUnlockItemIdDic
    end
    ------------------道具图鉴 end-----------------------


    function XBiancaTheatreManager.GetHelpKey()
        return XBiancaTheatreConfigs.GetClientConfig("HelpKey")
    end

    function XBiancaTheatreManager.GetReopenHelpKey()
        return XBiancaTheatreConfigs.GetClientConfig("ReopenHelpKey")
    end

    -- 局外显示资源
    function XBiancaTheatreManager.GetAssetItemIds()
        return {XBiancaTheatreConfigs.TheatreOutCoin}
    end

    -- 局内显示资源
    function XBiancaTheatreManager.GetAdventureAssetItemIds()
        return {XBiancaTheatreConfigs.TheatreInnerCoin, XBiancaTheatreConfigs.TheatreActionPoint}
    end

    -- 局内资源点击方法
    function XBiancaTheatreManager.AdventureAssetItemOnBtnClick(func, index)
        local itemId = XBiancaTheatreManager.GetAdventureAssetItemIds()[index]
        XLuaUiManager.Open("UiBiancaTheatreTips", itemId)
    end

    function XBiancaTheatreManager.GetAllCoinItemDatas()
        local result = {}
        local itemManager = XDataCenter.ItemManager
        local coinCount = itemManager:GetCount(XBiancaTheatreConfigs.TheatreInnerCoin)
        if coinCount > 0 then
            table.insert(result, {
                TemplateId = XBiancaTheatreConfigs.TheatreInnerCoin,
                Count = coinCount
            })
        end
        local decorationCoinCount = itemManager:GetCount(XBiancaTheatreConfigs.TheatreOutCoin)
        if decorationCoinCount > 0 then
            table.insert(result, {
                TemplateId = XBiancaTheatreConfigs.TheatreOutCoin,
                Count = decorationCoinCount
            })
        end
        local favorCoinCount = itemManager:GetCount(XBiancaTheatreConfigs.TheatreExp)
        if favorCoinCount > 0 then
            table.insert(result, {
                TemplateId = XBiancaTheatreConfigs.TheatreExp,
                Count = favorCoinCount
            })
        end
        return result
    end

    function XBiancaTheatreManager.GetTaskManager()
        return TaskManager
    end


    ------------------ 副本相关 begin --------------------
    function XBiancaTheatreManager.InitStageInfo()
        -- 关卡池的关卡
        local configs = XBiancaTheatreConfigs.GetBiancaTheatreFightStageTemplate()
        local stageInfo = nil
        for _, config in pairs(configs) do
            stageInfo = XDataCenter.FubenManager.GetStageInfo(config.StageId)
            if stageInfo then
                stageInfo.Type = XDataCenter.FubenManager.StageType.BiancaTheatre
            else
                XLog.Error("肉鸽2.0找不到配置的关卡id：", config.StageId)
            end
        end
    end


    function XBiancaTheatreManager.CallFinishFight()
        local fubenManager = XDataCenter.FubenManager
        local res = fubenManager.FubenSettleResult
        if not res then
            -- 强退
            local XFubenManager = XDataCenter.FubenManager
            XFubenManager.FubenSettling = false
            XFubenManager.FubenSettleResult = nil
            --通知战斗结束，关闭战斗设置页面
            CS.XGameEventManager.Instance:Notify(XEventId.EVENT_FIGHT_FINISH)
            XBiancaTheatreManager.FinishFight({})
            return
        end
        fubenManager.CallFinishFight()
    end

    function XBiancaTheatreManager.FinishFight(settle)
        XBiancaTheatreManager.SetIsAutoOpen(true)
        XBiancaTheatreManager.SetIsAutoOpenSettleWin(true)
        if settle.IsWin then
            XDataCenter.FubenManager.ChallengeWin(settle)
        else
            XBiancaTheatreManager.OpenBlackView()
            XBiancaTheatreManager.RemoveStepView()
            XBiancaTheatreManager.CheckOpenSettleWin()
        end
    end

    function XBiancaTheatreManager.ShowReward(winData, playEndStory)
        winData.OperationQueueType = XBiancaTheatreConfigs.OperationQueueType.BattleSettle
        CurrentAdventureManager:AddNextOperationData(winData, true)

        XBiancaTheatreManager.OpenBlackView()
        XBiancaTheatreManager.SetIsAutoOpen(true)
        if XBiancaTheatreManager.GetIsCatchAdventureEnd() then
            XBiancaTheatreManager.CheckOpenSettleWin()
        else
            XBiancaTheatreManager.CheckOpenView()
            XBiancaTheatreManager.RemoveBlackView()
        end
    end

    function XBiancaTheatreManager.PreFight(stage, teamId, isAssist, challengeCount)
        XBiancaTheatreManager.SetIsAutoOpen(false)
        XBiancaTheatreManager.SetIsAutoOpenSettleWin(false)
        local team = CurrentAdventureManager:GetSingleTeam()
        local cardIds, robotIds = CurrentAdventureManager:GetCardIdsAndRobotIdsFromTeam(team)
        local teamIndex = team and team:GetTeamIndex() or 0
        return {
            StageId = stage.StageId,
            IsHasAssist = isAssist,
            ChallengeCount = challengeCount,
            CaptainPos = team:GetCaptainPos(),
            FirstFightPos = team:GetFirstFightPos(),
            CardIds = cardIds,
            RobotIds = robotIds,
        }
    end

    function XBiancaTheatreManager.OpenBlackView()
        XLuaUiManager.Open("UiBiancaTheatreBlack")
    end

    function XBiancaTheatreManager.RemoveBlackView()
        XLuaUiManager.Remove("UiBiancaTheatreBlack")
    end
    ------------------ 副本相关 end --------------------


    function XBiancaTheatreManager.CheckCondition(conditionKey, isShowTip)
        local conditionId = XBiancaTheatreConfigs.GetTheatreConfig(conditionKey).Value
        conditionId = conditionId and tonumber(conditionId)
        local isUnLock, desc
        if XTool.IsNumberValid(conditionId) then
            isUnLock, desc = XConditionManager.CheckCondition(conditionId)
        else
            isUnLock, desc = true, ""
        end
        if not isUnLock then
            if isShowTip then
                XUiManager.TipError(desc)
            end
            return isUnLock
        end
        return isUnLock
    end


    ------------------step 步骤相关 begin-------------------
    local IsAutoOpen = true --是否检查自动打开界面
    local IsSkipCheckLoading = false    --是否跳过过渡界面的检查
    --根据当前步骤打开相应界面
    function XBiancaTheatreManager.CheckOpenView(isCheckNode, isShowLoading)
        if not IsAutoOpen then
            return
        end
        
        local adventureManager = XBiancaTheatreManager.GetCurrentAdventureManager()
        local curStep = adventureManager:GetCurrentChapter():GetCurStep()
        local stepType = curStep and curStep:GetStepType()
        if not stepType then
            return
        end
        
        local uiName
        if isShowLoading then
            --打开过渡界面
            uiName = "UiBiancaTheatreLoading"
        elseif stepType == XBiancaTheatreConfigs.XStepType.Node then
            local nodeSlotType = isCheckNode and curStep:GetSelectNodeType() or "Default"
            uiName = XBiancaTheatreConfigs.StepTypeToUiName[stepType][nodeSlotType]
        else
            uiName = XBiancaTheatreConfigs.StepTypeToUiName[stepType]
        end
        if not uiName then
            return
        end

        XDataCenter.BiancaTheatreManager.CheckTipOpenList(function ()
            XBiancaTheatreManager.RemoveStepView()
            XLuaUiManager.Open(uiName)
            local isVisionOpen = XBiancaTheatreManager.CheckVisionIsOpen()
            if isVisionOpen then
                XBiancaTheatreManager.StartAudioFilter()
            end
        end)
    end

    --移除所有由步骤通知打开的界面
    function XBiancaTheatreManager.RemoveStepView()
        XLuaUiManager.Remove("UiBiancaTheatreChoice")
        XLuaUiManager.Remove("UiBiancaTheatreRecruit")
        XLuaUiManager.Remove("UiBiancaTheatrePlayMain")
        XLuaUiManager.Remove("UiBiancaTheatreOutpost")
    end

    function XBiancaTheatreManager.SetIsAutoOpen(isAutoOpen)
        IsAutoOpen = isAutoOpen
    end

    function XBiancaTheatreManager.SetIsSkipCheckLoading(isSkipCheckLoading)
        IsSkipCheckLoading = isSkipCheckLoading
    end
    ------------------step 步骤相关 end-------------------



    ------------------灵视系统相关 begin-------------------
    function XBiancaTheatreManager.UpdateIsOpenVision(isOpenVision)
        IsOpenVision = XTool.IsNumberValid(isOpenVision)
    end

    function XBiancaTheatreManager.CheckVisionIsOpen()
        return IsOpenVision
    end

    function XBiancaTheatreManager.OpenVision()
        local visionValue = XBiancaTheatreManager.GetCurrentAdventureManager():GetVisionValue()
        XBiancaTheatreManager.OpenAudioFilter(XBiancaTheatreConfigs.GetVisionIdByValue(visionValue))
        XEventManager.DispatchEvent(XEventId.EVENT_BIANCA_THEATRE_VISION_OPEN)
    end

    function XBiancaTheatreManager.UpdateVisionSystemIsOpen()
        local localSavedKey = string.format("BiancaTheatreData_%s_VisionSystemIsOpen", XPlayer.Id)
        XSaveTool.SaveData(localSavedKey, true)
    end

    -- 灵视系统是否开启
    function XBiancaTheatreManager.CheckVisionSystemIsOpen(isTips)
        local cacheVisionSystemIsOpen = XSaveTool.GetData(string.format("BiancaTheatreData_%s_VisionSystemIsOpen", XPlayer.Id))
        if cacheVisionSystemIsOpen then return cacheVisionSystemIsOpen end
        local conditionId = tonumber(XBiancaTheatreConfigs.GetTheatreConfig("VisionConditionId").Value)
        if XTool.IsNumberValid(conditionId) then
            local unlock, desc = XConditionManager.CheckCondition(conditionId)
            if not unlock and isTips then
                XUiManager.TipMsg(desc)
            end
            return unlock, desc
        end
        return true
    end

    function XBiancaTheatreManager.ChangeVision(visionChangeId)
        if not XBiancaTheatreManager.CheckVisionIsOpen() then
            XBiancaTheatreManager.UpdateIsOpenVision(true)
            XBiancaTheatreManager.OpenVision()
        end
        -- 添加提示弹窗数据
        local visionValue = XBiancaTheatreManager.GetCurrentAdventureManager():GetVisionValue()
        XBiancaTheatreManager.AddTipOpenData("UiBiancaTheatrePsionicVision", nil, false, visionChangeId, visionValue)
    end

    -- 灵视开启本地缓存记录
    function XBiancaTheatreManager.GetVisionOpenTipCache()
        local key = string.format("BiancaTheatreData_%s_VisionOpenTip", XPlayer.Id)
        return XSaveTool.GetData(key)
    end

    function XBiancaTheatreManager.SetVisionOpenTipCache()
        local key = string.format("BiancaTheatreData_%s_VisionOpenTip", XPlayer.Id)
        return XSaveTool.SaveData(key, true)
    end
    ------------------灵视系统相关 end---------------------


    ------------------队伍人数相关 begin-------------------

    function XBiancaTheatreManager.UpdateTeamCountEffect(teamCountEffect)
        if teamCountEffect then
            TeamCountEffect = teamCountEffect
        else
            TeamCountEffect = _TeamCount
        end
    end

    function XBiancaTheatreManager.GetTeamCountEffect()
        return TeamCountEffect
    end

    -- 冒险结束重置
    function XBiancaTheatreManager.ResetTeamCountEffect()
        TeamCountEffect = _TeamCount
    end

    ------------------队伍人数相关 end---------------------


    ------------------成就系统相关 begin-------------------
    -- 数据处理部分详见XEntity/XBiancaTheatre/Task/XTheatreTaskManager

    function XBiancaTheatreManager.UpdateGetAchievementRecords(getAchievementRecords)
        for _, achievementRecord in ipairs(getAchievementRecords or {}) do
            GetAchievementRecords[achievementRecord.NeedCountId] = true
        end
    end

    function XBiancaTheatreManager.UpdateAchievemenetContidion(isOpen)
        AchievementContidion = isOpen or false
    end

    function XBiancaTheatreManager.GetAchievemenetContidion()
        return AchievementContidion
    end

    -- 该成就组任务奖励
    function XBiancaTheatreManager.GetAchievementRewardIds(needCountId)
        local config = XBiancaTheatreConfigs.GetBiancaTheatreActivity(CurActivityId)
        if XTool.IsNumberValid(needCountId) then
            if not XTool.IsTableEmpty(config.RewardIds) then
                return config.RewardIds[needCountId]
            end
        else
            return config.RewardIds
        end
    end

    -- 该成就组任务解锁条件
    function XBiancaTheatreManager.GetAchievementNeedCounts(needCountId)
        local config = XBiancaTheatreConfigs.GetBiancaTheatreActivity(CurActivityId)
        if XTool.IsNumberValid(needCountId) then
            if not XTool.IsTableEmpty(config.NeedCounts) then
                return config.NeedCounts[needCountId]
            end
        else
            return config.NeedCounts
        end
    end

    function XBiancaTheatreManager.CheckAchievementIsOpen(isTips)
        local conditionId = XBiancaTheatreConfigs.GetTheatreConfig("AchievementConditionId").Value
        conditionId = tonumber(conditionId)
        if not XTool.IsNumberValid(conditionId) then
            return true
        end
        local unlock, desc
        local config = XConditionManager.GetConditionTemplate(conditionId)
        -- 17111是单局内有效的condition，成就开启是外部的condition判断
        -- 为符合策划需求后端利用17111这个conditionType进行特殊处理，因此该类型的condition判断由服务端下发的数据进行判断
        if config.Type == 17111 then
            unlock = AchievementContidion
            desc = config.Desc
        else
            unlock, desc = XConditionManager.CheckCondition(conditionId)
        end
        if not unlock and isTips then
            XUiManager.TipMsg(desc)
        end
        return unlock, desc
    end

    function XBiancaTheatreManager.CheckAchievementRecordIsGet(needCountId)
        return GetAchievementRecords[needCountId]
    end

    function XBiancaTheatreManager.SetAchievementGetRecord(needCountId)
        GetAchievementRecords[needCountId] = true
    end

    -- 成就开启本地缓存
    function XBiancaTheatreManager.GetAchievementOpenTipCache()
        local key = string.format("BiancaTheatreData_%s_AchievementOpenTip", XPlayer.Id)
        return XSaveTool.GetData(key)
    end

    function XBiancaTheatreManager.SetAchievementOpenTipCache()
        local key = string.format("BiancaTheatreData_%s_AchievementOpenTip", XPlayer.Id)
        return XSaveTool.SaveData(key, true)
    end
    ------------------成就系统相关 end---------------------


    ------------------进度数据相关 begin-------------------

    function XBiancaTheatreManager.UpdateHistoryTotalItemCount(historyTotalItemCount)
        HistoryTotalItemCount = historyTotalItemCount or 0
    end

    function XBiancaTheatreManager.GetHistoryTotalItemCount()
        return HistoryTotalItemCount
    end

    function XBiancaTheatreManager.UpdateHistoryTotalPassFightNodeCount(historyTotalPassFightNodeCount)
        HistoryTotalPassFightNodeCount = historyTotalPassFightNodeCount or 0
    end

    function XBiancaTheatreManager.GetHistoryTotalPassFightNodeCount()
        return HistoryTotalPassFightNodeCount
    end

    function XBiancaTheatreManager.UpdateHistoryItemObtainRecords(historyItemObtainRecords)
        if historyItemObtainRecords then
            HistoryItemObtainRecords = historyItemObtainRecords
        end
    end

    function XBiancaTheatreManager.GetHistoryItemObtainRecords(quality)
        return HistoryItemObtainRecords[quality] or 0
    end

    function XBiancaTheatreManager.GetConditionProcess(conditionId)
        if not conditionId then return end
        local conditionConfig = XConditionManager.GetConditionTemplate(conditionId)
        if XTool.IsTableEmpty(conditionConfig) then return end

        local allProcess = 0
        local curProcess = 0
        if conditionConfig.Type == 17101 then
            allProcess = conditionConfig.Params[1]
            curProcess = XBiancaTheatreManager.GetHistoryTotalPassFightNodeCount()
        elseif conditionConfig.Type == 17106 then
            allProcess = conditionConfig.Params[1]
        elseif conditionConfig.Type == 17113 then
            local quality = conditionConfig.Params[2]
            allProcess = conditionConfig.Params[1]
            curProcess = quality == 0 and XBiancaTheatreManager.GetHistoryTotalItemCount() or XBiancaTheatreManager.GetHistoryItemObtainRecords(quality)
        end
        return curProcess, allProcess
    end

    ------------------进度数据相关 end---------------------


    ------------------通过的事件步骤相关 begin-------------------

    function XBiancaTheatreManager.UpdatePassedEventRecord(passedEventRecord)
        PassedEventRecord = passedEventRecord or {}
    end

    -- 添加事件
    function XBiancaTheatreManager.AddPassedEventRecord(eventId, stepId)
        if not PassedEventRecord[eventId] then
            PassedEventRecord[eventId] = {}
        end
        for _, eventStepId in ipairs(PassedEventRecord[eventId]) do
            if stepId == eventStepId then
                return
            end
        end
        table.insert(PassedEventRecord[eventId], stepId)
    end

    -- 检查是否存在事件
    function XBiancaTheatreManager.CheckPassedEventRecord(eventStepId)
        for _, eventStepIds in pairs(PassedEventRecord) do
            for _, stepId in ipairs(eventStepIds) do
                if stepId == eventStepId then
                    return true
                end
            end
        end
        return false
    end

    ------------------通过的事件步骤相关 end---------------------


    ------------------冒险通过战斗节点相关 end---------------------

    function XBiancaTheatreManager.UpdateGamePassNodeCount(gamePassNodeCount)
        GamePassNodeCount = gamePassNodeCount or 0
    end

    function XBiancaTheatreManager.GetGamePassNodeCount()
        return GamePassNodeCount
    end

    ------------------冒险通过战斗节点相关 begin-------------------


    ------------------自动播放剧情 begin-------------------
    local GetLocalSavedKey = function(key)
        return string.format("%s%d", key, XPlayer.Id)
    end

    function XBiancaTheatreManager.CheckAutoPlayStory()
        local localSavedKey = GetLocalSavedKey("BiancaTheatreAutoStory")
        local storyId = XBiancaTheatreConfigs.GetFirstStoryId()
        if XSaveTool.GetData(localSavedKey) or not storyId then
            XLuaUiManager.OpenWithCallback("UiBiancaTheatreMain", function ()
                XBiancaTheatreManager.CheckVersionUpdateOldPlaySettleTip()
            end)
            return
        end

        XDataCenter.MovieManager.PlayMovie(storyId, function()
            XLuaUiManager.OpenWithCallback("UiBiancaTheatreMain", function ()
                XBiancaTheatreManager.CheckVersionUpdateOldPlaySettleTip()
            end)
        end, nil, nil, false)
        XSaveTool.SaveData(localSavedKey, true)
    end

    function XBiancaTheatreManager.UpdateNewStage(newStage)
        NewStage = newStage
    end

    -- 检查是否有版本更新旧冒险数据自动结算
    function XBiancaTheatreManager.CheckVersionUpdateOldPlaySettleTip()
        if NewStage then
            XDataCenter.BiancaTheatreManager.RequestNewVersionAutoSettleTip(function ()
                local tipTxt = XBiancaTheatreConfigs.GetVersionUpdateOldPlaySettleTip()
                if not string.IsNilOrEmpty(tipTxt) then
                    XUiManager.TipError(tipTxt)
                end
            end)
            XDataCenter.BiancaTheatreManager.UpdateNewStage(false)
        end
    end
    ------------------自动播放剧情 end---------------------


    ------------------自动弹窗 begin-----------------------

    local TipOpenListIndex = 1
    local TipOpenList = nil
    local IsTipOpening = false
    -- 添加提示弹窗数据
    --【注】弹窗Ui第一个参数需要是方法类型
    function XBiancaTheatreManager.AddTipOpenData(uiTipName, closeCb, openData1, openData2, openData3, openData4, openData5)
        -- if IsTipOpening then
        --     XLog.Error("It is not allowed to add tipOpenData when tip is Opening, please check the code!")
        --     return
        -- end
        if string.IsNilOrEmpty(uiTipName) then
            XLog.Error("Error:XBiancaTheatreManager.AddTipOpenData, uiTipName is null!")
            return
        end
        if closeCb and type(closeCb) ~= "function" then
            XLog.Error("Error:XBiancaTheatreManager.AddTipOpenData, closeCb is not a function!")
            return
        end
        local data = {
            UiName = uiTipName,
            CloseCb = closeCb,
            OpenData1 = openData1,
            OpenData2 = openData2,
            OpenData3 = openData3,
            OpenData4 = openData4,
            OpenData5 = openData5,
        }
        if XTool.IsTableEmpty(TipOpenList) then
            TipOpenList = {}
        end
        table.insert(TipOpenList, data)
        -- 排序优先级(小而优先，弹窗中不进行排序)
        if not IsTipOpening then
            table.sort(TipOpenList, function(itemDataA, itemDataB)
                local orderA = XBiancaTheatreConfigs.TipOrder[itemDataA.UiName]
                local orderB = XBiancaTheatreConfigs.TipOrder[itemDataB.UiName]
                if not orderA then orderA = 0 end
                if not orderB then orderB = 0 end
                return orderA < orderB
            end)
        end
    end

    function XBiancaTheatreManager.GetTipOpenList()
        return TipOpenList
    end

    function XBiancaTheatreManager.ClearTipOpenList()
        TipOpenList = nil
    end

    function XBiancaTheatreManager.SetTipOpenList(tipOpenList)
        TipOpenList = tipOpenList
        TipOpenListIndex = 1
        IsTipOpening = false
    end

    -- 弹窗执行
    function XBiancaTheatreManager.CheckTipOpenList(cb, isCheckCb)
        if IsTipOpening and not isCheckCb then
            return
        end
        if not XTool.IsTableEmpty(TipOpenList) then
            local tipOpenData = TipOpenList[TipOpenListIndex]
            if not XTool.IsTableEmpty(tipOpenData) then
                IsTipOpening = true
                TipOpenListIndex = TipOpenListIndex + 1
                XLuaUiManager.Open(tipOpenData.UiName, function ()
                    if tipOpenData.CloseCb then
                        tipOpenData.CloseCb()
                    end
                    if TipOpenList and XTool.IsTableEmpty(TipOpenList[TipOpenListIndex]) then
                        if cb then cb() end
                    end
                    XBiancaTheatreManager.CheckTipOpenList(cb, true)
                end, tipOpenData.OpenData1, tipOpenData.OpenData2, tipOpenData.OpenData3, tipOpenData.OpenData4, tipOpenData.OpenData5)
            else
                XBiancaTheatreManager.SetTipOpenList(nil)
            end
        else
            if cb then cb() end
        end
    end

    function XBiancaTheatreManager.CheckIsCookie(key, isNotSave)
        local localSavedKey = GetLocalSavedKey(key)
        if XSaveTool.GetData(localSavedKey) then
            return false
        end
        if not isNotSave then
            XSaveTool.SaveData(localSavedKey, true)
        end
        return true
    end

    local TheatreUnlockOwnRoleAutoWindowKey = "TheatreUnlockOwnRoleAutoWindow"
    -- 检查是否打开解锁自用角色弹窗
    function XBiancaTheatreManager.CheckUnlockOwnRole()
        local adventureManager = XBiancaTheatreManager.GetCurrentAdventureManager()
        if not adventureManager then
            return
        end

        local useOwnCharacterFa = XBiancaTheatreConfigs.GetTheatreConfig("UseOwnCharacterFa").Value
        useOwnCharacterFa = useOwnCharacterFa and tonumber(useOwnCharacterFa)
        if not useOwnCharacterFa then
            return
        end

        local power = adventureManager:GeRoleAveragePower()
        if power >= useOwnCharacterFa and XBiancaTheatreManager.CheckIsCookie(TheatreUnlockOwnRoleAutoWindowKey) then
            XLuaUiManager.Open("UiTheatreUnlockTips", {ShowTipsPanel = XBiancaTheatreConfigs.UplockTipsPanel.OwnRole})
        end
    end

    function XBiancaTheatreManager.RemoveOwnRoleCookie()
        XSaveTool.RemoveData(TheatreUnlockOwnRoleAutoWindowKey)
    end
    ------------------自动弹窗 end-----------------------


    ------------------红点相关 begin-----------------------
    --检查是否有任务奖励可领取
    function XBiancaTheatreManager.CheckTaskCanReward()
        local theatreTask = XBiancaTheatreConfigs.GetBiancaTheatreTask()
        for id in pairs(theatreTask) do
            if XBiancaTheatreManager.CheckTaskCanRewardByTheatreTaskId(id) then
                return true
            end
        end
        return false
    end

    function XBiancaTheatreManager.CheckAchievementTaskCanAchieved()
        if not XDataCenter.BiancaTheatreManager.CheckAchievementIsOpen() then
            return false
        end

        local achievementIdList = XBiancaTheatreConfigs.GetAchievementIdList()
        if XTool.IsTableEmpty(achievementIdList) then
            return false
        end
        for _, achievementId in ipairs(achievementIdList) do
            for _, taskId in pairs(XBiancaTheatreConfigs.GetAchievementTaskIds(achievementId)) do
                if XDataCenter.TaskManager.CheckTaskAchieved(taskId) then
                    return true
                end
            end
        end
        return false
    end

    function XBiancaTheatreManager.CheckAchievementTaskIsFinish()
        if not XDataCenter.BiancaTheatreManager.CheckAchievementIsOpen() then
            return false
        end

        local achievementIdList = XBiancaTheatreConfigs.GetAchievementIdList()
        if XTool.IsTableEmpty(achievementIdList) then
            return true
        end
        local achievementFinishCount = 0
        for _, achievementId in ipairs(achievementIdList) do
            for _, taskId in pairs(XBiancaTheatreConfigs.GetAchievementTaskIds(achievementId)) do
                if XDataCenter.TaskManager.CheckTaskFinished(taskId) then
                    achievementFinishCount = achievementFinishCount + 1
                end
            end
        end
        local needCounts = XBiancaTheatreManager.GetAchievementNeedCounts()
        for _, needCount in ipairs(needCounts) do
            if needCount > achievementFinishCount then
                return false
            end
        end
        return true
    end

    function XBiancaTheatreManager.CheckTaskCanRewardByTheatreTaskId(theatreTaskId)
        local taskIdList = XBiancaTheatreConfigs.GetTaskIdList(theatreTaskId)
        for _, taskId in ipairs(taskIdList) do
            if XDataCenter.TaskManager.CheckTaskAchieved(taskId) then
                return true
            end
        end
        return false
    end

    local _TaskStartTimeOpenCookieKey = "TheatreTaskStartTimeOpen_"
    --检查是否有任务过了开启时间
    function XBiancaTheatreManager.CheckTaskStartTimeOpen()
        local taskIdList = XBiancaTheatreConfigs.GetTheatreTaskHaveStartTimeIdList()
        for _, taskId in ipairs(taskIdList) do
            if XBiancaTheatreManager.CheckTaskStartTimeOpenByTaskId(taskId) then
                return true
            end
        end
        return false
    end

    function XBiancaTheatreManager.CheckTaskStartTimeOpenByTaskId(taskId)
        local template = XTaskConfig.GetTaskTemplate()[taskId]
        if not template then
            return false
        end

        local startTime = XTime.ParseToTimestamp(template.StartTime)
        local now = XTime.GetServerNowTimestamp()
        if startTime and startTime <= now and not XBiancaTheatreManager.CheckIsCookie(_TaskStartTimeOpenCookieKey .. taskId, true) then
            return true
        end
        return false
    end

    function XBiancaTheatreManager.CheckTaskStartTimeOpenByTheatreTaskId(theatreTaskId)
        local taskIdList = XBiancaTheatreConfigs.GetTaskIdList(theatreTaskId)
        for _, taskId in ipairs(taskIdList) do
            if XBiancaTheatreManager.CheckTaskStartTimeOpenByTaskId(taskId) then
                return true
            end
        end
        return false
    end

    function XBiancaTheatreManager.SaveTaskStartTimeOpenCookie(theatreTaskId)
        local taskIdList = XBiancaTheatreConfigs.GetTaskIdList(theatreTaskId)
        for _, taskId in ipairs(taskIdList) do
            if XBiancaTheatreManager.CheckTaskStartTimeOpenByTaskId(taskId) then
                XSaveTool.SaveData(GetLocalSavedKey(_TaskStartTimeOpenCookieKey .. taskId), true)
            end 
        end
    end

    --检查是否显示图鉴红点
    function XBiancaTheatreManager.CheckFieldGuideRedPoint()
        for itemId, _ in pairs(UnlockItemIdDic) do
            if XBiancaTheatreManager.CheckFieldGuideGridRedPoint(itemId) then
                return true
            end
        end
        return false
    end

    -- 图鉴单个道具红点
    function XBiancaTheatreManager.CheckFieldGuideGridRedPoint(itemId)
        -- 默认解锁无需红点
        if not XTool.IsNumberValid(XBiancaTheatreConfigs.GetItemUnlockConditionId(itemId)) then
            return false
        end

        if not XBiancaTheatreManager.GetFieldGuideGridRedPointIsClear(itemId) and XBiancaTheatreManager.IsUnlockItem(itemId) then
            return true
        else
            return false
        end
    end

    -- 道具红点缓存键值
    function XBiancaTheatreManager.GetFieldGuideGridRedPointKey(itemId)
        return string.format("BiancaTheatreData_%s_%s_ItemRedDotIsClear", XPlayer.Id, itemId)
    end

    -- 缓存道具红点点击状态
    function XBiancaTheatreManager.SetFieldGuideGridRedPointClear(itemId)
        -- 已解锁未点击、未解锁状态、默认解锁则无需点击
        if XBiancaTheatreManager.GetFieldGuideGridRedPointIsClear(itemId) or not XBiancaTheatreManager.IsUnlockItem(itemId) then
            return
        end
        XSaveTool.SaveData(XBiancaTheatreManager.GetFieldGuideGridRedPointKey(itemId), true)
    end

    -- 读取道具红点点击状态缓存
    function XBiancaTheatreManager.GetFieldGuideGridRedPointIsClear(itemId)
        return XSaveTool.GetData(XBiancaTheatreManager.GetFieldGuideGridRedPointKey(itemId))
    end

    -- 外循环强化解锁缓存键值
    function XBiancaTheatreManager.GetStrengthenUnlockCacheKey()
        return string.format("BiancaTheatreData_%s_StrengthenUnlock", XPlayer.Id)
    end

    -- 读取外循环强化解锁状态缓存
    function XBiancaTheatreManager.GetStrengthenUnlockCache()
        return XSaveTool.GetData(XBiancaTheatreManager.GetStrengthenUnlockCacheKey())
    end

    -- 保存外循环强化解锁状态缓存
    function XBiancaTheatreManager.SetStrengthenUnlockCache()
        return XSaveTool.SaveData(XBiancaTheatreManager.GetStrengthenUnlockCacheKey(), true)
    end

    -- 读取外循环强化解锁提示缓存
    function XBiancaTheatreManager.GetStrengthenUnlockTipsCache()
        local key = string.format("BiancaTheatreData_%s_StrengthenUnlockTip", XPlayer.Id)
        return XSaveTool.GetData(key)
    end

    -- 保存外循环强化解锁提示缓存
    function XBiancaTheatreManager.SetStrengthenUnlockTipsCache()
        local key = string.format("BiancaTheatreData_%s_StrengthenUnlockTip", XPlayer.Id)
        return XSaveTool.SaveData(key, true)
    end

    -- 是否有新等级
    function XBiancaTheatreManager.GetIsReadNewRewardLevel()
        local lastLevelKey = string.format("BiancaTheatreData_%s_LastLevelCount", XPlayer.Id)
        local lastLevelCount = XSaveTool.GetData(lastLevelKey) or 0
        return XBiancaTheatreConfigs.GetMaxRewardLevel() > lastLevelCount
    end

    function XBiancaTheatreManager.SetIsReadNewRewardLevel()
        local lastLevelKey = string.format("BiancaTheatreData_%s_LastLevelCount", XPlayer.Id)
        return XSaveTool.SaveData(lastLevelKey, XBiancaTheatreConfigs.GetMaxRewardLevel())
    end
    ------------------红点相关 end-------------------------


    ------------------羁绊相关 begin-----------------------
    function XBiancaTheatreManager.GetComboList()
        return ComboList
    end
    ------------------羁绊相关 end-------------------------


    ------------------结算相关 begin-----------------------
    ---@type XBiancaTheatreAdventureEnd 
    local CatchAdventureEnd --缓存的结局类
    local IsAutoOpenSettleWin = false   --是否收到通知自动打开结算界面
    local IsInMovie = false --是否在结局剧情
    
    function XBiancaTheatreManager.SetAdventureEnd(settleData)
        CatchAdventureEnd = XAdventureEnd.New(settleData.EndId)
        CatchAdventureEnd:InitWithServerData(settleData)
        XBiancaTheatreManager.UpdatePassCharacterIdDict(settleData.PassChapterIds)
        XBiancaTheatreManager.UpdateUnlockDifficultyId(settleData.UnlockDifficultyId)
        -- 更新道具解锁数据
        XBiancaTheatreManager.UpdateUnlockItemId(settleData.UnlockItemId)
        XBiancaTheatreManager.UpdateUnlockTeamId(settleData.UnlockTeamId)
        XBiancaTheatreManager.UpdateTeamRecords(settleData.TeamRecords)
        -- 更新历史数据:用以调查团进度
        XBiancaTheatreManager.UpdateHistoryTotalItemCount(settleData.HistoryTotalItemCount)
        XBiancaTheatreManager.UpdateHistoryTotalPassFightNodeCount(settleData.HistoryTotalPassFightNodeCount)
        XBiancaTheatreManager.UpdateHistoryItemObtainRecords(settleData.HistoryItemObtainRecords)
    end

    function XBiancaTheatreManager.CheckOpenSettleWin()
        if not CatchAdventureEnd then
            return false
        end

        XBiancaTheatreManager.RemoveStepView()
        local adventureEnd = XTool.Clone(CatchAdventureEnd)
        local storyId = adventureEnd:GetStoryId()
        if XTool.IsNumberValid(storyId) then
            --结局剧情
            XDataCenter.MovieManager.PlayMovie(storyId, function()
                XBiancaTheatreManager.RemoveBlackView()
                XLuaUiManager.Open("UiBiancaTheatreEndLoading", adventureEnd)
            end, nil, nil, false)
            XBiancaTheatreManager.SetInMovieState(true)
        else
            XBiancaTheatreManager.RemoveBlackView()
            XLuaUiManager.Open("UiBiancaTheatreEndLoading", adventureEnd)
        end
        CatchAdventureEnd = nil
        return true
    end

    -- 主界面判断是否剧情结算完用
    function XBiancaTheatreManager.CheckIsInMovie()
        local state = IsInMovie
        if state then
            -- 能进主界面判断代表结束剧情，直接设为false
            XBiancaTheatreManager.SetInMovieState(false)
        end
        return state
    end

    function XBiancaTheatreManager.SetInMovieState(state)
        IsInMovie = state
    end

    --结算初始化数据
    function XBiancaTheatreManager.SettleInitData()
        -- 还原滤镜
        XBiancaTheatreManager.ResetAudioFilter()
        -- 重置队伍人数限制
        XBiancaTheatreManager.UpdateTeamCountEffect(0)
        -- 更新灵视开启
        XBiancaTheatreManager.UpdateIsOpenVision(0)
        -- 清空已通过的事件
        XBiancaTheatreManager.UpdatePassedEventRecord()
        -- 清空局内通过战斗节点
        XBiancaTheatreManager.UpdateGamePassNodeCount(0)
        -- 更新全局通过的章节和事件数据
        XBiancaTheatreManager.UpdateCurChapterId(0)
        XBiancaTheatreManager.UpdateDifficultyId(0)
        -- 清除队伍数据
        XBiancaTheatreManager.GetCurrentAdventureManager():ClearTeam()
    end

    function XBiancaTheatreManager.SetIsAutoOpenSettleWin(isAcitve)
        IsAutoOpenSettleWin = isAcitve
    end

    function XBiancaTheatreManager.GetIsAutoOpenSettleWin()
        return IsAutoOpenSettleWin
    end

    function XBiancaTheatreManager.GetIsCatchAdventureEnd()
        return CatchAdventureEnd ~= nil
    end
    ------------------结算相关 end-----------------------


    ------------------协议 begin--------------------
    --选择分队
    function XBiancaTheatreManager.RequestSelectTeam(teamId, callback)
        local requestBody = {
            TeamId = teamId,    --肉鸽分队Id
        }
        XNetwork.CallWithAutoHandleErrorCode("BiancaTheatreSelectTeamRequest", requestBody, function(res)
            XBiancaTheatreManager.GetCurrentAdventureManager():UpdateCurTeamId(requestBody.TeamId)
            if callback then callback() end
        end)
    end
    
    --强化技能
    function XBiancaTheatreManager.RequestStrengthen(id, callback)
        local requestBody = {
            Id = id,
        }
        XNetwork.CallWithAutoHandleErrorCode("BiancaTheatreStrengthenRequest", requestBody, function(res)
            StrengthenDbs[id] = true
            XEventManager.DispatchEvent(XEventId.EVENT_BIANCA_THEATRE_STRENGTHEN_ACTIVE, id)
            
            local groupId = XBiancaTheatreConfigs.GetStrengthenGroupId(id)
            if XBiancaTheatreManager.IsStrengthenGroupAllBuy(groupId) then
                XEventManager.DispatchEvent(XEventId.EVENT_BIANCA_THEATRE_GROUP_STRENGTHEN_ACTIVE, groupId)
            end

            if callback then callback() end
        end)
    end

    --单独领取
    function XBiancaTheatreManager.RequestGetReward(id, callback)
        --local isAdventure =  XDataCenter.BiancaTheatreManager.CheckHasAdventure()
        --if isAdventure then
        --    XUiManager.TipMsg(XBiancaTheatreConfigs.GetRewardTips(2))
        --    return
        --end
        local requestBody = {
            Id = id,    --领奖id
        }
        XNetwork.CallWithAutoHandleErrorCode("BiancaTheatreGetRewardRequest", requestBody, function(res)
            XLuaUiManager.Open("UiBiancaTheatreTipReward", nil, res.RewardGoodsList)
            GetRewardIds[id] = true

            if callback then callback() end
        end)
    end

    --一键领取
    function XBiancaTheatreManager.RequestGetAllReward(callback)
        XNetwork.CallWithAutoHandleErrorCode("BiancaTheatreGetAllRewardRequest", nil, function(res)
            XLuaUiManager.Open("UiBiancaTheatreTipReward", nil, res.RewardGoodsList)
            XBiancaTheatreManager.UpdateGetRewardIds(res.GetRewardIds)

            if callback then callback() end
        end)
    end

    -- 领取成就奖励
    function XBiancaTheatreManager.RequestAchievementReward(needCountId, callback)
        local requestBody = {
            NeedCountId = needCountId,    --成就完成数id
        }
        XNetwork.CallWithAutoHandleErrorCode("BiancaTheatreGetAchievementRewardRequest", requestBody, function(res)
            if table.nums(res.RewardGoodsList) > 0 then
                XLuaUiManager.Open("UiBiancaTheatreTipReward", callback, res.RewardGoodsList)
                XBiancaTheatreManager.SetAchievementGetRecord(needCountId)
            else
                if callback then callback() end
            end
        end)
    end

    -- 检查是否有版本更新旧冒险数据自动结算
    function XBiancaTheatreManager.RequestNewVersionAutoSettleTip(callback)
        XNetwork.CallWithAutoHandleErrorCode("BiancaTheatreNewStageRequest", nil, function(res)
            XDataCenter.BiancaTheatreManager.UpdateNewStage(false)
            if callback then callback() end
        end)
    end
    ------------------协议 end----------------------


    ------------------副本入口扩展 start-------------------------
    function XBiancaTheatreManager:ExOpenMainUi()
        if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.BiancaTheatre) then
            XBiancaTheatreManager.CheckAutoPlayStory()
        end
    end

    -- 检查是否展示红点
    function XBiancaTheatreManager:ExCheckIsShowRedPoint()
        if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.BiancaTheatre) then
            return false
        end
        return XBiancaTheatreManager.IsHaveReward() or XBiancaTheatreManager.GetIsReadNewRewardLevel()
    end

    function XBiancaTheatreManager:ExGetProgressTip()
        local curLevel = XBiancaTheatreManager.GetCurRewardLevel()
        local maxLevel = curLevel
        local configs = XBiancaTheatreConfigs.GetBiancaTheatreLevelReward()
        for id, _ in pairs(configs or {}) do
            maxLevel = math.max(id, maxLevel)
        end
        local desc = XBiancaTheatreConfigs.GetTheatreClientConfig("BannerProgress").Values[1]
        return string.format(desc, curLevel, maxLevel)
    end

    function XBiancaTheatreManager:ExCheckInTime()
        local config = XBiancaTheatreConfigs.GetBiancaTheatreActivity()
        for i, v in pairs(config) do
            if XFunctionManager.CheckInTimeByTimeId(v.TimeId) then
                return true
            end
        end
        return false
    end

    function XBiancaTheatreManager:ExCheckIsFinished(cb)
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.BiancaTheatre, nil, true) then
            if cb then cb(false) end
            return false
        end

        local curLevel = XBiancaTheatreManager.GetCurRewardLevel()
        local maxLevel = XBiancaTheatreConfigs.GetMaxRewardLevel()
        local isGetAllLvReward = curLevel == maxLevel and XTool.IsTableEmpty(XBiancaTheatreManager.GetCanReceiveLevelRewardIds()) 
        
        --等级奖励全领取 & 成就奖励全领取
        if isGetAllLvReward and XBiancaTheatreManager.CheckAchievementTaskIsFinish() then
            self.IsClear = true
            if cb then cb(true) end
            return true
        end
        self.IsClear = false
        if cb then cb(false) end
        return false
    end
    
    ------------------副本入口扩展 end-------------------------

    XBiancaTheatreManager.InitAudioFilter()

    return XBiancaTheatreManager
end

--登陆下发
XRpc.NotifyBiancaTheatreActivityData = function(data)
    XDataCenter.BiancaTheatreManager.InitWithServerData(data)
end

-- 新的步骤
XRpc.NotifyBiancaTheatreAddStep = function(data)
    local adventureManager = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager()
    local currentChapter = adventureManager:GetCurrentChapter(false)
    local chapterId = data.ChapterId
    local isNewChapter = currentChapter and currentChapter:GetCurrentChapterId() ~= chapterId

    if currentChapter == nil or isNewChapter then
        currentChapter = adventureManager:CreatreChapterById(chapterId)
    end

    if #currentChapter:GetCurrentNodes() > 0 
        and not currentChapter:CheckHasMovieNode()
        and data.Step.StepType == XBiancaTheatreConfigs.XStepType.Node then
        currentChapter:AddPassNodeCount(1)
    end
    if #currentChapter:GetCurrentNodes() > 0 then
        for _, node in ipairs(currentChapter:GetCurrentNodes()) do
            -- 选中且是事件节点
            if node:GetIsSelected() and node.EventConfig then
                XDataCenter.BiancaTheatreManager.AddPassedEventRecord(node.EventConfig.EventId, node.EventConfig.StepId)
            end
        end
    end

    currentChapter:AddStep(data.Step)

    --步骤是招募角色或腐化，刷新角色字典
    if data.Step.StepType == XBiancaTheatreConfigs.XStepType.RecruitCharacter or
        data.Step.StepType == XBiancaTheatreConfigs.XStepType.DecayRecruitCharacter then
        currentChapter:UpdateRecruitRoleDic()
    end

    XDataCenter.BiancaTheatreManager.CheckOpenView(nil, isNewChapter)
    if isNewChapter then
        XDataCenter.BiancaTheatreManager.SetIsAutoOpen(false)
    end
end

--战斗结束，事件进行到下一步
XRpc.NotifyBiancaTheatreNodeNextStep = function(data)
    if data.NextStepId <= 0 then -- 事件战斗结束后没有下一步了
        return
    end

    local chapter = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager():GetCurrentChapter()
    local curStep = chapter:GetCurStep()
    local eventNode = chapter:GetEventNode(data.EventId)
    if not eventNode then
        XLog.Error("NotifyBiancaTheatreNodeNextStep找不到事件节点, data：", data, curStep)
        return
    end
    eventNode:UpdateNextStepEvent(data.NextStepId, nil, curStep)
end

--获得物品，加入到已获得道具列表
XRpc.NotifyBiancaTheatreAddItem = function(data)
    local adventureManager = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager()
    if adventureManager then
        for _, itemData in pairs(data.BiancaTheatreItems) do
            adventureManager:UpdateItemData(itemData)
        end
    end
end

--通知结算，可能会登录下发
XRpc.NotifyBiancaTheatreAdventureSettle = function(data)
    local manager = XDataCenter.BiancaTheatreManager
    manager.SettleInitData()
    manager.SetAdventureEnd(data.SettleData)
    manager.ResetTeamCountEffect()
    if XDataCenter.BiancaTheatreManager.GetIsAutoOpenSettleWin() then
        manager.RemoveStepView()
        manager.CheckOpenSettleWin()
    end
end

XRpc.NotifyBiancaTheatreTotalExp = function(data) 
    XDataCenter.BiancaTheatreManager.UpdateTotalExp(data.TotalExp)
end

XRpc.NotifyBiancaTheatreAbnormalExit = function()
end

-- 灵视系统开启
XRpc.NotifyBiancaTheatreVisionCondition = function()
    XDataCenter.BiancaTheatreManager.UpdateVisionSystemIsOpen()
end

-- 灵视变化(选择奖励、获得某些道具、腐化事件下发)
XRpc.NotifyBiancaTheatreVisionChange = function(data)
    XDataCenter.BiancaTheatreManager.ChangeVision(data.VisionId)
end

-- 通知获得队伍人数改变效果(获得时效果时、登录下发)(中止冒险重置)
XRpc.NotifyBiancaTheatreFightTeamEffect = function(data)
    XDataCenter.BiancaTheatreManager.UpdateTeamCountEffect(data.TeamCountEffect)
end

-- 通知成就解锁
XRpc.NotifyBiancaTheatreAchievementCondition = function()
    XDataCenter.BiancaTheatreManager.UpdateAchievemenetContidion(true)
end

-- 通知战斗节点次数改变(结算，登陆，改变时下发)
XRpc.NotifyBiancaTheatreFightNodeCountChange = function(data)
    XDataCenter.BiancaTheatreManager.UpdateGamePassNodeCount(data.FightNodeCount)
end