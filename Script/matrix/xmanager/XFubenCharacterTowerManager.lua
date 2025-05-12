local XExFubenCharacterTowerManager = require("XEntity/XFuben/XExFubenCharacterTowerManager")
local XCharacterTowerChapter = require("XEntity/XCharacterTower/XCharacterTowerChapter")
local XCharacterTowerRelation = require("XEntity/XCharacterTower/XCharacterTowerRelation")
local XCharacterTowerChapterInfo = require("XEntity/XCharacterTower/XCharacterTowerChapterInfo")
local XCharacterTowerRelationInfo = require("XEntity/XCharacterTower/XCharacterTowerRelationInfo")

XFubenCharacterTowerManagerCreator = function()
    ---@class XFubenCharacterTowerManager
    local XFubenCharacterTowerManager = XExFubenCharacterTowerManager.New(XFubenConfigs.ChapterType.CharacterTower)
    
    local RequestProto = {
        CharacterTowerGetChapterRewardRequest = "CharacterTowerGetChapterRewardRequest", -- 领取章节奖励请求
        CharacterTowerGetStageRewardRequest = "CharacterTowerGetStageRewardRequest", -- 领取关卡奖励请求
        CharacterTowerGetStarRewardRequest = "CharacterTowerGetStarRewardRequest", -- 领取星级奖励请求
        CharacterTowerActivateFightEventIdRequest = "CharacterTowerActivateFightEventIdRequest", -- 激活羁绊加成请求
        CharacterTowerSaveVideoStageIdRequest = "CharacterTowerSaveVideoStageIdRequest", -- 保存通关播放动画请求
        CharacterTowerSaveStoryIdRequest = "CharacterTowerSaveStoryIdRequest", -- 保存播放剧情请求
        CharacterTowerSaveTriggerConditionIdRequest = "CharacterTowerSaveTriggerConditionIdRequest", -- 保存触发条件请求
    }
    -- 活动中章节Id
    local ActivityChapters = {}
    -- 章节信息
    local _CharacterTowerChapterInfos = {}
    -- 羁绊信息
    local _CharacterTowerRelationInfos = {}
    -- 章节
    local _CharacterTowerChapters = {}
    -- 羁绊
    local _CharacterTowerRelations = {}
    
    local function UpdateActivityChapters(data)
        if XTool.IsTableEmpty(data) then
            return
        end
        ActivityChapters = {}
        for _, chapterId in pairs(data or {}) do
            ActivityChapters[chapterId] = chapterId
        end
    end

    -- 检测当前章节是否在活动中
    function XFubenCharacterTowerManager.CheckActivityChapterId(chapterId)
        return ActivityChapters[chapterId] and true or false
    end

    ---@return XCharacterTowerRelationInfo
    local function GetRelationInfo(relationId)
        if not XTool.IsNumberValid(relationId) then
            XLog.Error("XFubenCharacterTowerManager GetRelationInfo error: 羁绊Id错误, relationId: " .. relationId)
            return
        end

        local relationInfo = _CharacterTowerRelationInfos[relationId]
        if not relationInfo then
            relationInfo = XCharacterTowerRelationInfo.New(relationId)
            _CharacterTowerRelationInfos[relationId] = relationInfo
        end
        return relationInfo
    end

    local function UpdateRelationInfo(data)
        local relationId = data.RelationId
        GetRelationInfo(relationId):UpdateData(data)
    end

    local function UpdateRelationInfos(data)
        for _, info in pairs(data) do
            UpdateRelationInfo(info)
        end
    end
    
    ---@return XCharacterTowerChapterInfo
    local function GetChapterInfo(chapterId)
        if not XTool.IsNumberValid(chapterId) then
            XLog.Error("XFubenCharacterTowerManager GetChapterInfo error: 章节Id错误, chapterId: " .. chapterId)
            return
        end
        
        local chapterInfo = _CharacterTowerChapterInfos[chapterId]
        if not chapterInfo then
            chapterInfo = XCharacterTowerChapterInfo.New(chapterId)
            _CharacterTowerChapterInfos[chapterId] = chapterInfo
        end
        return chapterInfo
    end

    local function UpdateChapterInfo(data)
        local chapterId = data.ChapterId
        GetChapterInfo(chapterId):UpdateData(data)
        UpdateRelationInfos(data.RelationInfos)
    end

    local function UpdateChapterInfos(data)
        for _, info in pairs(data) do
            UpdateChapterInfo(info)
        end
    end
    
    function XFubenCharacterTowerManager.GetCharacterTowerChapterInfo(chapterId)
        return GetChapterInfo(chapterId)    
    end

    function XFubenCharacterTowerManager.GetCharacterTowerRelationInfo(relationId)
        return GetRelationInfo(relationId)
    end

    ---@return XCharacterTowerChapter
    local function GetChapterViewModel(chapterId)
        if not XTool.IsNumberValid(chapterId) then
            XLog.Error("XFubenCharacterTowerManager GetChapterViewModel error: 章节Id错误, chapterId: " .. chapterId)
            return
        end

        local chapter = _CharacterTowerChapters[chapterId]
        if not chapter then
            chapter = XCharacterTowerChapter.New(chapterId)
            _CharacterTowerChapters[chapterId] = chapter
        end
        return chapter
    end

    function XFubenCharacterTowerManager.GetCharacterTowerChapter(chapterId)
        return GetChapterViewModel(chapterId)
    end

    ---@return XCharacterTowerRelation
    local function GetRelationViewModel(relationId)
        if not XTool.IsNumberValid(relationId) then
            XLog.Error("XFubenCharacterTowerManager GetRelationViewModel error: 羁绊Id错误, relationId: " .. relationId)
            return
        end
        
        local relation = _CharacterTowerRelations[relationId]
        if not relation then
            relation = XCharacterTowerRelation.New(relationId)
            _CharacterTowerRelations[relationId] = relation
        end
        return relation
    end
    
    function XFubenCharacterTowerManager.GetCharacterTowerRelation(relationId)
        return GetRelationViewModel(relationId)    
    end
    
    --region 副本相关
    
    --function XFubenCharacterTowerManager.InitStageInfo()
    --    local characterTowerCfg = XFubenCharacterTowerConfigs.GetAllCharacterTowerCfg()
    --    for _, characterTower in pairs(characterTowerCfg or {}) do
    --        for _, chapterId in pairs(characterTower.ChapterIds or {}) do
    --            local stageIds = XFubenCharacterTowerConfigs.GetStageIdsByChapterId(chapterId)
    --            for _, stageId in pairs(stageIds) do
    --                local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
    --                stageInfo.Type = XDataCenter.FubenManager.StageType.CharacterTower
    --                stageInfo.ChapterId = chapterId
    --            end
    --        end
    --    end
    --end
    
    function XFubenCharacterTowerManager.GetChapterId(stageId)
        local characterTowerCfg = XFubenCharacterTowerConfigs.GetAllCharacterTowerCfg()
        for _, characterTower in pairs(characterTowerCfg or {}) do
            for _, chapterId in pairs(characterTower.ChapterIds or {}) do
                local stageIds = XFubenCharacterTowerConfigs.GetStageIdsByChapterId(chapterId)
                for _, stageIdOnConfig in pairs(stageIds) do
                    if stageIdOnConfig == stageId then
                        return chapterId
                    end
                end
            end
        end
    end

    -- 胜利 & 奖励界面
    function XFubenCharacterTowerManager.ShowReward(winData)
        XLuaUiManager.Open("UiSettleWinMainLine", winData)
    end

    --endregion
    
    -- 检查红点 未领取的奖励/未激活的羁绊
    function XFubenCharacterTowerManager.CheckRedPointByChapterId(chapterId)
        local chapterViewModel = GetChapterViewModel(chapterId)
        local isOpen = chapterViewModel:CheckChapterCondition()
        if not isOpen then
            return false
        end
        local rewardAchieved = chapterViewModel:CheckChapterRewardAchieved()
        if rewardAchieved then
            return true
        end
        local relationGroupId = chapterViewModel:GetChapterRelationGroupId()
        if not XTool.IsNumberValid(relationGroupId) then
            return false
        end
        local relationViewModel = GetRelationViewModel(relationGroupId)
        local characterId = chapterViewModel:GetChapterCharacterId()
        local notActive = relationViewModel:CheckRelationNotActive(characterId)
        if notActive then
            return true
        end
        return false
    end
    
    -- 判断是否在活动中
    function XFubenCharacterTowerManager.CheckInActivity(chapterIds)
        local tempChapterIds = {}
        for _, chapterId in pairs(chapterIds or {}) do
            local chapterViewModel = GetChapterViewModel(chapterId)
            if chapterViewModel:CheckChapterInActivity() then
                table.insert(tempChapterIds, chapterId)
            end
        end
        return #tempChapterIds > 0
    end

    -- 判断是否在开启时间内
    function XFubenCharacterTowerManager.CheckInOpenTime(openTimeId)
        local inOpenTime = XFunctionManager.CheckInTimeByTimeId(openTimeId)
        if not inOpenTime then
            local startTime = XFunctionManager.GetStartTimeByTimeId(openTimeId)
            local startTimeStr = XTime.TimestampToGameDateTimeString(startTime, "MM-dd HH:mm")
            return false, XUiHelper.GetText("CharacterTowerOpenTimeDesc", startTimeStr)
        end
        return true, ""
    end

    function XFubenCharacterTowerManager.CheckCondition(conditionId)
        if XTool.IsNumberValid(conditionId) then
            return XConditionManager.CheckCondition(conditionId)
        end
        return true, ""
    end

    -- 是否解锁
    function XFubenCharacterTowerManager.IsUnlock(characterTowerId)
        local characterTowerConfig = XFubenCharacterTowerConfigs.GetCharacterTowerById(characterTowerId)
        local inOpenTime, desc = XFubenCharacterTowerManager.CheckInOpenTime(characterTowerConfig.OpenTimeId)
        if not inOpenTime then
            return false, desc
        end
        if XFubenCharacterTowerManager.CheckInActivity(characterTowerConfig.ChapterIds) then
            return true, ""
        end
        return XFubenCharacterTowerManager.CheckCondition(characterTowerConfig.ConditionId)
    end
    
    -- 打开章节UI
    function XFubenCharacterTowerManager.OpenChapterUi(chapterId, isCloseLastUi)
        if not XTool.IsNumberValid(chapterId) then
            return
        end
        local chapterViewModel = GetChapterViewModel(chapterId)
        local uiName = chapterViewModel:GetOpenChapterUiName()
        local ret, desc = chapterViewModel:CheckChapterCondition()
        if ret then
            XFubenCharacterTowerManager.SaveCharacterTowerChapterClick(chapterId)
            if XLuaUiManager.IsUiLoad(uiName) then
                XLuaUiManager.Remove(uiName)
            end
            if isCloseLastUi then
                XLuaUiManager.PopThenOpen(uiName, chapterId)
            else
                XLuaUiManager.Open(uiName, chapterId)
            end
        else
            XUiManager.TipError(desc)
        end
    end
    
    -- 检查是否有新章节开启
    function XFubenCharacterTowerManager.CheckNewCharacterTowerChapterOpen()
        local characterTowerCfg = XFubenCharacterTowerConfigs.GetAllCharacterTowerCfg()
        for _, config in pairs(characterTowerCfg or {}) do
            for _, chapterId in pairs(config.ChapterIds or {}) do
                local chapterViewModel = GetChapterViewModel(chapterId)
                local isInActivity = chapterViewModel:CheckChapterInActivity()
                local isClick = XFubenCharacterTowerManager.CheckCharacterTowerChapterClick(chapterId)
                if isInActivity and not isClick then
                    return true
                end
            end
        end
        return false
    end
    
    function XFubenCharacterTowerManager.GetCharacterTowerChapterClickKey(chapterId)
        if XPlayer.Id and chapterId then
            return string.format("CharacterTowerChapterClickKey_%s_%s", tostring(XPlayer.Id), tostring(chapterId))
        end
    end
    
    function XFubenCharacterTowerManager.CheckCharacterTowerChapterClick(chapterId)
        local key = XFubenCharacterTowerManager.GetCharacterTowerChapterClickKey(chapterId)
        local isClick = XSaveTool.GetData(key) or false
        return isClick
    end
    
    function XFubenCharacterTowerManager.SaveCharacterTowerChapterClick(chapterId)
        local isClick = XFubenCharacterTowerManager.CheckCharacterTowerChapterClick(chapterId)
        if isClick then
            return
        end
        local key = XFubenCharacterTowerManager.GetCharacterTowerChapterClickKey(chapterId)
        XSaveTool.SaveData(key, true)
    end
    
    function XFubenCharacterTowerManager.GetCharacterTowerRelationTaskKey(conditionId)
        if XPlayer.Id and conditionId then
            return string.format("CharacterTowerRelationTaskAnim_%s_%s", tostring(XPlayer.Id), tostring(conditionId))
        end    
    end
    
    function XFubenCharacterTowerManager.CheckRelationTaskPlayAnim(conditionId)
        local key = XFubenCharacterTowerManager.GetCharacterTowerRelationTaskKey(conditionId)
        local isPlay = XSaveTool.GetData(key) or false
        return isPlay
    end
    
    function XFubenCharacterTowerManager.SaveRelationTaskPlayAnim(conditionId)
        local isPlay = XFubenCharacterTowerManager.CheckRelationTaskPlayAnim(conditionId)
        if isPlay then
            return
        end
        local key = XFubenCharacterTowerManager.GetCharacterTowerRelationTaskKey(conditionId)
        XSaveTool.SaveData(key, true)
    end
    
    --region 网络数据
    
    -- 登录下发
    function XFubenCharacterTowerManager.NotifyLoginCharacterTowerData(data)
        --[[
        public class NotifyLoginCharacterTowerData
        {
            public XCharacterTowerDataDb CharacterTowerDataDb;
        }
        ]]
        local dataDb = data.CharacterTowerDataDb
        UpdateChapterInfos(dataDb.ChapterInfos)
        UpdateActivityChapters(data.ActivityChapters)
    end
    
    -- 更新活动章节信息
    function XFubenCharacterTowerManager.NotifyActivityCharacterTowerData(data)
      --[[  
        public class NotifyActivityCharacterTowerData
        {
            public List<int> ActivityChapters;
        }
        ]]
        UpdateActivityChapters(data.ActivityChapters)
    end
    
    -- 领取章节奖励请求
    function XFubenCharacterTowerManager.CharacterTowerGetChapterRewardRequest(chapterId, cb)
        local req = { ChapterId = chapterId }

        XNetwork.Call(RequestProto.CharacterTowerGetChapterRewardRequest, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            -- 刷新领取状态
            GetChapterInfo(chapterId):RecordChapterRewardData(chapterId)
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_CHARACTER_TOWER_RECEIVE_REWARD)

            if cb then
                cb(res.Rewards)
            end
        end)
    end
    
    -- 领取关卡奖励请求
    function XFubenCharacterTowerManager.CharacterTowerGetStageRewardRequest(chapterId, stageId, cb)
        local req = { StageId = stageId }
        
        XNetwork.Call(RequestProto.CharacterTowerGetStageRewardRequest, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            -- 刷新领取状态
            GetChapterInfo(chapterId):RecordStageRewardData(stageId)
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_CHARACTER_TOWER_RECEIVE_REWARD)

            if cb then
                cb(res.Rewards)
            end
        end)
    end
    
    -- 领取星级奖励请求
    function XFubenCharacterTowerManager.CharacterTowerGetStarRewardRequest(chapterId, treasureId, cb)
        local req = { TreasureId = treasureId }

        XNetwork.Call(RequestProto.CharacterTowerGetStarRewardRequest, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            -- 刷新领取状态
            GetChapterInfo(chapterId):RecordTreasureData(treasureId)
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_CHARACTER_TOWER_RECEIVE_REWARD)
            
            if cb then
                cb(res.Rewards)
            end
        end)
    end

    -- 激活羁绊加成请求
    function XFubenCharacterTowerManager.CharacterTowerActivateFightEventIdRequest(relationId, fightEventId, cb)
        local req = { RelationId = relationId, FightEventId = fightEventId }

        XNetwork.Call(RequestProto.CharacterTowerActivateFightEventIdRequest, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            
            -- 刷新羁绊状态
            GetRelationInfo(relationId):RecordFightEventId(fightEventId)
            -- 刷新已完成解锁条件
            for _, conditionId in pairs(res.FinishConditions or {}) do
                GetRelationInfo(relationId):RecordFinishCondition(conditionId)
            end
            
            if cb then
                cb()
            end
        end)
    end

    -- 保存通关播放动画请求
    function XFubenCharacterTowerManager.CharacterTowerSaveVideoStageIdRequest(chapterId, stageId, cb)
        local req = { StageId = stageId }

        XNetwork.Call(RequestProto.CharacterTowerSaveVideoStageIdRequest, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            -- 刷新播放状态
            GetChapterInfo(chapterId):RecordVideoedId(stageId)

            if cb then
                cb()
            end
        end)
    end

    -- 保存播放剧情请求
    function XFubenCharacterTowerManager.CharacterTowerSaveStoryIdRequest(relationId, storyId, cb)
        local req = { RelationId = relationId, StoryId = storyId }

        XNetwork.Call(RequestProto.CharacterTowerSaveStoryIdRequest, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            -- 刷新播放状态
            GetRelationInfo(relationId):RecordStoryId(storyId)
            -- 刷新已完成解锁条件
            for _, conditionId in pairs(res.FinishConditions or {}) do
                GetRelationInfo(relationId):RecordFinishCondition(conditionId)
            end

            if cb then
                cb()
            end
        end)
    end
    
    -- 保存触发条件请求
    function XFubenCharacterTowerManager.CharacterTowerSaveTriggerConditionIdRequest(chapterId, conditionId, cb)
        local req = { ChapterId = chapterId, ConditionId = conditionId }
        
        XNetwork.Call(RequestProto.CharacterTowerSaveTriggerConditionIdRequest, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            -- 刷新条件状态
            GetChapterInfo(chapterId):RecordTriggerCondition(conditionId)
            
            if cb then
                cb()
            end
        end)
    end
    
    --endregion
    
    -- 重写限时活动界面里基类的方法 在FubenManagerEx.Init()里使用
    function XFubenCharacterTowerManager:ExOverrideBaseMethod()
        return {
            ExGetProgressTip = function(proxy)
                if not XTool.IsNumberValid(proxy:ExGetConfig().SkipId) then
                    return ""
                end
                local list = XFunctionConfig.GetSkipFuncCfg(proxy:ExGetConfig().SkipId)
                local chapterId = list.CustomParams[2]
                if XTool.IsNumberValid(chapterId) then
                    local chapterViewModel = GetChapterViewModel(chapterId)
                    local finishCount, totalCount = chapterViewModel:GetChapterProgress()
                    return XUiHelper.GetText("CharacterTowerChapterProgressDesc", finishCount, totalCount)
                end
                return ""
            end,
            ExCheckIsShowRedPoint = function(proxy)
                if not XTool.IsNumberValid(proxy:ExGetConfig().SkipId) then
                    return proxy.Super.ExCheckIsShowRedPoint(proxy)
                end
                local list = XFunctionConfig.GetSkipFuncCfg(proxy:ExGetConfig().SkipId)
                local chapterId = list.CustomParams[2]
                if XTool.IsNumberValid(chapterId) then
                    local hasRedPoint = XFubenCharacterTowerManager.CheckRedPointByChapterId(chapterId)
                    if hasRedPoint then
                        return true
                    end
                end
                return false
            end,
            ExGetRunningTimeStr = function(proxy)
                -- 隐藏活动剩余时间
                return ""
            end,
        }
    end

    -- 添加监听消息
    function XFubenCharacterTowerManager.InitEventListener()
        XEventManager.AddEventListener(XEventId.EVENT_CHARACTER_TOWER_CONDITION_LISTENING, XFubenCharacterTowerManager.ConditionListening)
    end

    -- Condition监听
    function XFubenCharacterTowerManager.ConditionListening(listeningType, args)
        if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.CharacterTower) then
            return
        end
        
        local infoDic = XFubenCharacterTowerConfigs.GetInfoDicByListeningType(listeningType)
        if listeningType == XFubenCharacterTowerConfigs.ListeningType.Character or listeningType == XFubenCharacterTowerConfigs.ListeningType.Favorability then
            local characterId = args.CharacterId
            if not XTool.IsNumberValid(characterId) then
                return
            end
            for _, info in pairs(infoDic) do
                if info.CharacterId == characterId then
                    if XFubenCharacterTowerManager.CheckListeningCondition(info, false) then
                        break
                    end
                end
            end
        elseif listeningType == XFubenCharacterTowerConfigs.ListeningType.Stage then
            local stageId = args.StageId
            if not XTool.IsNumberValid(stageId) then
                return
            end
            for _, info in pairs(infoDic) do
                local template = XConditionManager.GetConditionTemplate(info.ConditionId)
                local isContain = table.contains(template.Params or {}, stageId)
                if isContain then
                    if XFubenCharacterTowerManager.CheckListeningCondition(info, true) then
                        break
                    end
                end
            end
        end
    end

    function XFubenCharacterTowerManager.CheckListeningCondition(info, isCloseLastUi)
        if XTool.IsTableEmpty(info) then
            return false
        end
        local isTrigger = GetChapterInfo(info.ChapterId):CheckTriggerCondition(info.ConditionId)
        local relationGroupId = GetChapterViewModel(info.ChapterId):GetChapterRelationGroupId()
        local isFinish = GetRelationInfo(relationGroupId):CheckFinishCondition(info.ConditionId)
        local isCheck = XConditionManager.CheckCondition(info.ConditionId, info.CharacterId)
        if not isTrigger and not isFinish and isCheck then
            XFubenCharacterTowerManager.CharacterTowerSaveTriggerConditionIdRequest(info.ChapterId, info.ConditionId, function()
                XLuaUiManager.Open("UiCharacterTowerLeftTip", info.ChapterId, info.ConditionId, isCloseLastUi)
            end)
            return true
        end
        return false
    end
    
    function XFubenCharacterTowerManager.Init()
        XFubenCharacterTowerManager.InitEventListener()
    end

    XFubenCharacterTowerManager.Init()
    return XFubenCharacterTowerManager
end

XRpc.NotifyLoginCharacterTowerData = function(data) 
    XDataCenter.CharacterTowerManager.NotifyLoginCharacterTowerData(data)
end

XRpc.NotifyActivityCharacterTowerData = function(data)
    XDataCenter.CharacterTowerManager.NotifyActivityCharacterTowerData(data)
end