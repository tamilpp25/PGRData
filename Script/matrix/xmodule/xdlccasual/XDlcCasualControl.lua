---@class XDlcCasualControl : XControl
---@field private _Model XDlcCasualModel
local XDlcCasualControl = XClass(XControl, "XDlcCasualControl")
local XDlcCasualRank = require("XModule/XDlcCasual/XEntity/XDlcCasualRank")
local XDlcCasualCuteCharacter = require("XModule/XDlcCasual/XEntity/XDlcCasualCuteCharacter")

local StringFormat = string.format
local ToNumber = tonumber

function XDlcCasualControl:OnInit()
    --初始化内部变量
    ---@type XDlcCasualRank[]
    self._RankPool = {}
end

function XDlcCasualControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
    XEventManager.AddEventListener(XEventId.EVENT_DLC_ROOM_INFO_CHANGE, self.OnWorldModeChange, self)
end

function XDlcCasualControl:RemoveAgencyEvent()
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_ROOM_INFO_CHANGE, self.OnWorldModeChange, self)
end

function XDlcCasualControl:OnRelease()
    self._RankPool = nil
end

---@param roomData XDlcRoomData
---@param changeFlags { IsWorldIdChange : boolean, IsAutoMatchChange :boolean, IsAbilityChange : boolean }
function XDlcCasualControl:OnWorldModeChange(roomData, changeFlags)
    if changeFlags.IsWorldIdChange then
        local worldId = roomData:GetWorldId()
        local isDifficulty = self:CheckDifficultyWorld(worldId)

        self:SetDifficultyMode(isDifficulty)
    end
end

function XDlcCasualControl:RefreshRankList()
    local worldId = self:GetCurrentWorld(true):GetWorldId()

    self:DlcCasualCubeGetTeamRankListRequest(worldId)
end

function XDlcCasualControl:GetHelpId()
    local activityId = self._Model:GetActivityId()
    local helpId = self._Model:GetActivityHelpIdById(activityId)

    return helpId
end

function XDlcCasualControl:SetDifficultyMode(value)
    local worldMode = value and XEnumConst.DlcCasualGame.WorldMode.Difficulty or XEnumConst.DlcCasualGame.WorldMode.Easy

    self._Model:SetWorldMode(worldMode)
end

function XDlcCasualControl:GetDifficultyBubbleDesc(index)
    local chapterId = self:_GetChapterIdByType(XEnumConst.DlcCasualGame.WorldMode.Difficulty)

    if not chapterId then
        return ""
    end

    return self._Model:GetChapterWorldDescById(chapterId)[index or 1]
end

--region Loading相关
function XDlcCasualControl:GetLoadingTips()
    local tips = self._Model:GetOtherConfigValuesByKey("LoadingTips")
    local count = #tips
    local data = {}

    for i = 1, count do
        data[i] = tips[i]
    end

    for i = 1, count do
        local index = XTool.Random(1, count)
        local tip = data[index]

        data[index] = data[i]
        data[i] = tip
    end

    return data
end

--endregion

--region 排行榜相关
function XDlcCasualControl:GetMaxRankCount()
    return ToNumber(self:GetOtherConfigValueByKeyAndIndex("RankMaxCount"))
end

function XDlcCasualControl:GetRankTopColor(index)
    return self:GetOtherConfigValueByKeyAndIndex("TopRankColor", index)
end

function XDlcCasualControl:GetRankTopNumberColor()
    return self:_GetRankNumberColor(1)
end

function XDlcCasualControl:GetRankNormalNumberColor()
    return self:_GetRankNumberColor(2)
end

--endregion

--region 匹配相关
function XDlcCasualControl:CreateRoom(worldId)
    if not worldId then
        worldId = self:GetCurrentWorld():GetWorldId()
    end

    local levelId = self:GetLevelIdByWorldId(worldId)

    XMVCA.XDlcRoom:CreateRoom(worldId, levelId, 1, true)
end

---@return XDlcRoomData
function XDlcCasualControl:GetRoomData()
    return XMVCA.XDlcRoom:GetRoomData()
end

function XDlcCasualControl:GetIsAutoMatch()
    local roomData = self:GetRoomData()

    return roomData:IsAutoMatch()
end

function XDlcCasualControl:DialogTipQuitRoom(cb)
    if XMVCA.XDlcRoom:IsTutorialRoom() then
        XMVCA.XDlcRoom:Quit(cb)
        return
    end

    local title = XUiHelper.GetText("TipTitle")
    local cancelMatchMsg = XUiHelper.GetText("OnlineInstanceQuitRoom")

    XUiManager.DialogTip(title, cancelMatchMsg, XUiManager.DialogType.Normal, nil, function()
        XMVCA.XDlcRoom:Quit(cb)
    end)
end

function XDlcCasualControl:DialogTipCancelMatch(cb)
    local title = XUiHelper.GetText("TipTitle")
    local cancelMatchMsg = XUiHelper.GetText("OnlineInstanceCancelMatch")
    
    XUiManager.DialogTip(title, cancelMatchMsg, XUiManager.DialogType.Normal, nil, function()
        XMVCA.XDlcRoom:CancelMatch(cb)
    end)
end

function XDlcCasualControl:CreateTutorialRoom()
    local activityId = self._Model:GetActivityId()
    local worldId = self._Model:GetActivityTutorialWorldIdById(activityId)
    local levelId = self._Model:GetActivityTutorialLevelIdById(activityId)

    XMVCA.XDlcRoom:CreateRoomTutorial(worldId, levelId)
end

--endregion

--region 角色相关
---@return XDlcCasualCuteCharacter
function XDlcCasualControl:GetCurrentCuteCharacter()
    local characterId = self._Model:GetCurrentCharacterId()

    if not characterId then
        characterId = self:_GetCurrentActivityCharacterList()[1]
        self._Model:SetCurrentCharacterId(characterId)
    end

    return self:GetCharacterCuteById(characterId)
end

---@return XDlcCasualCuteCharacter
function XDlcCasualControl:GetCharacterCuteById(characterId)
    local config = self._Model:GetCharacterConfigById(characterId)

    return XDlcCasualCuteCharacter.New(config)
end

function XDlcCasualControl:FindCharacterIndex(characterId)
    local characterList = self:_GetCurrentActivityCharacterList()

    characterId = characterId or self._Model:GetCurrentCharacterId()
    for i = 1, #characterList do
        if characterList[i] == characterId then
            return i
        end
    end

    return nil
end

---@return XDlcCasualCuteCharacter[]
function XDlcCasualControl:GetCuteCharacterList()
    local characterList = self:_GetCurrentActivityCharacterList()
    local result = {}

    for i = 1, #characterList do
        result[i] = self:GetCharacterCuteById(characterList[i])
    end

    return result
end

function XDlcCasualControl:SetCharacter(characterId, isRequest, callback)
    if isRequest then
        self:DlcCasualCubeSetCharacterIdRequest(characterId, callback)
    else
        self._Model:SetCurrentCharacterId(characterId)
        if callback then
            callback()
        end
    end
end

function XDlcCasualControl:GetCurrentCharacterId()
    return self._Model:GetCurrentCharacterId()
end

--endregion

--region 关卡相关
---@return XDlcWorld
function XDlcCasualControl:GetCurrentWorld(isDifficulty, index)
    if isDifficulty == nil then
        if self._Model:GetWorldMode() == XEnumConst.DlcCasualGame.WorldMode.Difficulty then
            return self:GetDifficultyWorld(index)
        else
            return self:GetEasyWorld(index)
        end
    elseif isDifficulty then
        return self:GetDifficultyWorld(index)
    else
        return self:GetEasyWorld(index)
    end
end

function XDlcCasualControl:GetLevelIdByWorldId(worldId, worldMode)
    worldMode = worldMode or self._Model:GetWorldMode()

    local index = self:FindWorldIdIndex(worldId, worldMode)

    return self:_GetLevelIdByTypeAndIndex(worldMode, index)
end

function XDlcCasualControl:FindWorldIdIndex(worldId, worldMode)
    local worldIds = self:_GetWorldIdListByType(worldMode)

    if not worldIds then
        return 1
    end

    for i = 1, #worldIds do
        if worldId == worldIds[i] then
            return i
        end
    end

    return 1
end

---@return XDlcWorld
function XDlcCasualControl:GetDifficultyWorld(index)
    index = index or 1

    return self:_GetWorldByTypeAndIndex(XEnumConst.DlcCasualGame.WorldMode.Difficulty, index)
end

---@return XDlcWorld
function XDlcCasualControl:GetEasyWorld(index)
    index = index or 1

    return self:_GetWorldByTypeAndIndex(XEnumConst.DlcCasualGame.WorldMode.Easy, index)
end

function XDlcCasualControl:CheckDifficultyUnlocked(isTip)
    local timeId = self:_GetChapterTimeIdByType(XEnumConst.DlcCasualGame.WorldMode.Difficulty)
    
    if not XFunctionManager.CheckInTimeByTimeId(timeId) then
        if isTip then
            XUiManager.TipMsg(XUiHelper.GetText("DlcCasualDifficultyLocked"))
        end

        return false
    end

    return true
end

function XDlcCasualControl:IsSelectHard()
    return self._Model:GetWorldMode() == XEnumConst.DlcCasualGame.WorldMode.Difficulty
end

function XDlcCasualControl:CheckDifficultyWorld(worldId)
    local worldIds = self:_GetWorldIdListByType(XEnumConst.DlcCasualGame.WorldMode.Difficulty)

    if XTool.IsTableEmpty(worldIds) then
        return false
    end

    for i = 1, #worldIds do
        if worldId == worldIds[i] then
            return true
        end
    end

    return false
end

function XDlcCasualControl:ChangeWorldMode(isEasy)
    self:SetDifficultyMode(not isEasy)

    local world = self:GetCurrentWorld()
    local levelId = self:GetLevelIdByWorldId(world:GetWorldId())

    XMVCA.XDlcRoom:SwitchWorld(world:GetWorldId(), levelId)
end

function XDlcCasualControl:GetChapterNameByWorldId(worldId)
    local isDifficulty = self:CheckDifficultyWorld(worldId)
    local chapterId = nil

    if isDifficulty then
        chapterId = self:_GetChapterIdByType(XEnumConst.DlcCasualGame.WorldMode.Difficulty)
    else    
        chapterId = self:_GetChapterIdByType(XEnumConst.DlcCasualGame.WorldMode.Easy)
    end
    if not chapterId then
        return ""
    end

    return self._Model:GetChapterNameById(chapterId) or ""
end

--endregion

--region 活动时间相关
function XDlcCasualControl:GetActivityEndTime(endCallback)
    local now = XTime.GetServerNowTimestamp()
    local endTime = self:GetEndTime()

    if now > endTime then
        if endCallback then
            endCallback()
        end
        return
    end

    return XUiHelper.GetTime(endTime - now, XUiHelper.TimeFormatType.ACTIVITY)
end

function XDlcCasualControl:GetEndTime()
    local activityId = self._Model:GetActivityId()
    local timeId = self._Model:GetActivityTimeIdById(activityId)

    return XFunctionManager.GetEndTimeByTimeId(timeId)
end

function XDlcCasualControl:AutoCloseHandler()
    XLuaUiManager.RunMain(true)
    XUiManager.TipText("CommonActivityEnd")
end

function XDlcCasualControl:GetDifficultyIsUnlockAndTime()
    local timeId = self:_GetChapterTimeIdByType(XEnumConst.DlcCasualGame.WorldMode.Difficulty)

    if not timeId then
        return false, 0
    end

    local openTime = XFunctionManager.GetStartTimeByTimeId(timeId)
    local remainTime = openTime - XTime.GetServerNowTimestamp()

    if remainTime > 0 then
        return true, XUiHelper.GetTime(remainTime)
    else
        return false, XUiHelper.GetTime(0)
    end
end

--endregion

--region 任务相关
function XDlcCasualControl:GetTaskListByType(taskType)
    local taskGroupId = self:_GetTaskGroupIdByType(taskType)

    return XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(taskGroupId)
end

function XDlcCasualControl:CheckAllTasksAchieved()
    return self:CheckDailyTasksAchieved() or self:CheckAccumulatedTasksAchieved()
end

function XDlcCasualControl:CheckDailyTasksAchieved()
    return self:_CheckTaskAchievedByType(XEnumConst.DlcCasualGame.TaskGroupType.Daily)
end

function XDlcCasualControl:CheckAccumulatedTasksAchieved()
    return self:_CheckTaskAchievedByType(XEnumConst.DlcCasualGame.TaskGroupType.Normal)
end

--endregion

--region 结算分数相关
function XDlcCasualControl:GetScoreJudgeLevel(worldId, score)
    local judgeScore = self._Model:GetScoreJudgeScoreById(worldId)
    local count = #judgeScore

    for i = count, 1, -1 do
        if score >= judgeScore[i] then
            return self:_GetScoreJudgeNameByIndex(worldId, i)
        end
    end

    return self:_GetScoreJudgeNameByIndex(worldId, 1)
end

--endregion

--region 其它配置相关
function XDlcCasualControl:GetOtherConfigValuesByKey(key)
    return self._Model:GetOtherConfigValuesByKey(key)
end

function XDlcCasualControl:GetOtherConfigValueByKeyAndIndex(key, index)
    local values = self:GetOtherConfigValuesByKey(key)

    if not values then
        return nil
    end

    return values[index or 1]
end
--endregion

--region 协议请求
function XDlcCasualControl:DlcCasualCubeSetCharacterIdRequest(characterId, callback)
    local protocol = "DlcCasualCubeSetCharacterIdRequest"
    XNetwork.Call(protocol, { CharacterId = characterId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            if callback then
                callback(false)
            end
            return
        end

        local currentCharacterId = self:GetCurrentCharacterId()
        local character = self:GetCharacterCuteById(characterId)

        if character and character:GetCharacterId() ~= currentCharacterId then
            self._Model:SetCurrentCharacterId(characterId)
            XEventManager.DispatchEvent(XEventId.EVENT_DLC_CASUAL_CUTE_CHATACTER_CHANGE, character, false)
        end
        if callback then
            callback(true)
        end
    end)
end

function XDlcCasualControl:DlcCasualCubeGetTeamRankListRequest(worldId)
    local protocol = "DlcCasualCubeGetTeamRankListRequest"
    XNetwork.Call(protocol, { WorldId = worldId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        local teamRank = res.DlcCasualTeamRank
        local rankTeamInfos = teamRank.RankTeamInfos
        local rankList = {}
        local maxCount = self:GetMaxRankCount()
        local count = #rankTeamInfos > maxCount and maxCount or #rankTeamInfos

        for i = 1, count do
            local rankInfo = self._RankPool[i]

            if not rankInfo then
                rankInfo = XDlcCasualRank.New(rankTeamInfos[i])
                self._RankPool[i] = rankInfo
            else
                rankInfo:SetData(rankTeamInfos[i])
            end

            rankList[i] = rankInfo
        end

        XEventManager.DispatchEvent(XEventId.EVENT_DLC_CASUAL_CUBE_RANK_INFO, res.Ranking, res.Score, 
            teamRank.TotalCount, rankList)
    end)
end

--endregion

--region 私有方法
function XDlcCasualControl:_GetChapterIdByType(worldType)
    local activityId = self._Model:GetActivityId()
    local chapterIds = self._Model:GetActivityChapterIdsById(activityId)

    return chapterIds[worldType]
end

function XDlcCasualControl:_GetWorldIdListByType(worldType)
    local chapterId = self:_GetChapterIdByType(worldType)

    if not chapterId then
        return nil
    end

    return self._Model:GetChapterWorldIdsById(chapterId)
end

---@return XDlcWorld
function XDlcCasualControl:_GetWorldByTypeAndIndex(worldType, index)
    local worldIds = self:_GetWorldIdListByType(worldType)
    ---@type XDlcWorldAgency
    local agency = XMVCA:GetAgency(ModuleId.XDlcWorld)

    if not worldIds then
        return nil
    end

    return agency:GetWorldById(worldIds[index])
end

function XDlcCasualControl:_GetLevelIdListByType(worldType)
    local chapterId = self:_GetChapterIdByType(worldType)

    if not chapterId then
        return nil
    end

    return self._Model:GetChapterLevelIdsById(chapterId)
end

function XDlcCasualControl:_GetLevelIdByTypeAndIndex(worldType, index)
    local levelIds = self:_GetLevelIdListByType(worldType)

    if not levelIds then
        return 0
    end

    return levelIds[index] or 0
end

function XDlcCasualControl:_GetChapterTimeIdByType(chapterType)
    local activityId = self._Model:GetActivityId()
    local chapeterIds = self._Model:GetActivityChapterIdsById(activityId)

    if not chapeterIds[chapterType] then
        return nil
    end

    return self._Model:GetChapterTimeIdById(chapeterIds[chapterType])
end

function XDlcCasualControl:_GetScoreJudgeNameByIndex(worldId, index)
    local judgeName = self._Model:GetScoreJudgeNameById(worldId)

    if not judgeName[index] then
        return ""
    end

    return judgeName[index]
end

function XDlcCasualControl:_CheckTaskAchievedByType(taskType)
    local taskGroupId = self:_GetTaskGroupIdByType(taskType)

    return XDataCenter.TaskManager.CheckLimitTaskList(taskGroupId)
end

function XDlcCasualControl:_GetTaskListByType(taskType)
    local taskGroupIds = self:_GetTaskGroupIdByType(taskType)

    return XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(taskGroupIds[taskType])
end

function XDlcCasualControl:_GetTaskGroupIdByType(taskType)
    local activityId = self._Model:GetActivityId()
    local taskGroupIds = self._Model:GetActivityTaskGroupIdsById(activityId)

    return taskGroupIds[taskType]
end

function XDlcCasualControl:_GetCurrentActivityCharacterList()
    local activityId = self._Model:GetActivityId()
    local characterPoolId = self._Model:GetActivityCharacterPoolIdById(activityId)

    return self._Model:GetCharacterPoolListById(characterPoolId)
end

function XDlcCasualControl:_GetRankNumberColor(index)
    return self:GetOtherConfigValueByKeyAndIndex("NumberRankColor", index)
end

function XDlcCasualControl:_GetSaveKey(key, id)
    local activityId = self._Model:GetActivityId()

    id = id or 1
    return StringFormat("DLC_CASUAL_%s_%d_%d_%d", key, activityId, XPlayer.Id, id)
end

--endregion

return XDlcCasualControl
