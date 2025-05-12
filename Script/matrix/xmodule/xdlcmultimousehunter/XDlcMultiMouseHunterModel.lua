local XDlcMutiplayerActivityModel = require("XModule/XDlcMultiplayer/XDlcMultiplayerActivity/XDlcMutiplayerActivityModel")

---@class XDlcMultiMouseHunterModel : XDlcMutiplayerActivityModel
local XDlcMultiMouseHunterModel = XClass(XDlcMutiplayerActivityModel, "XDlcMultiMouseHunterModel")

local XDlcMultiMouseHunterDiscussion = require("XModule/XDlcMultiMouseHunter/XEntity/XDlcMultiMouseHunterDiscussion")

function XDlcMultiMouseHunterModel:OnInit()
    self.Super.OnInit(self)

    -- 初始化内部变量
    -- 这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    self._ActivityId = nil
    self._CurrentChapterId = nil
    self._ChapterInfoList = nil
    self._CurrencyLimit = 0
    self._CurrencyCount = 0
    self._CurrentWearTitleId = 0
    self._UnlockTitleIds = nil
    self._TitleProgress = nil
    self._IsRefreshTitlInfo = false
    self._IsShowShopRedPoint = true
    self._IsRequestShopInfo = false

    self._LocalUnlockTitleIdMap = nil
    ---@type XDlcMultiMouseHunterDiscussion
    self._Discussion = nil              --话题数据
    self._BpLevel = 0                   --BP等级
    self._BpRewardIds = nil             --已经领取过Bp奖励的Lv列表
    self._SkillData = nil               --猫鼠技能
    self._FinishStageCount = 0          --已经对局的场数
end

function XDlcMultiMouseHunterModel:ClearPrivate()
    -- 这里执行内部数据清理
    -- XLog.Error("请对内部数据进行清理")
    self:_SaveLocalUnlockTitleIdMap()
end

function XDlcMultiMouseHunterModel:ResetAll()
    -- 这里执行重登数据清理
    -- XLog.Error("重登数据清理")
    self._IsShowShopRedPoint = true
    self._IsRequestShopInfo = false
    ---@type XDlcMultiMouseHunterDiscussion
    self._Discussion = nil              --话题数据
    self._BpLevel = 0                   --BP等级
    self._BpRewardIds = nil             --已经领取过Bp奖励的Lv列表
    self._SkillData = nil               --猫鼠技能
    self._FinishStageCount = 0          --已经对局的场数
end

function XDlcMultiMouseHunterModel:SetActivityId(activityId)
    self._ActivityId = activityId
end

function XDlcMultiMouseHunterModel:GetActivityId()
    return self._ActivityId
end

function XDlcMultiMouseHunterModel:SetChapterInfoList(value)
    self._ChapterInfoList = value
end

function XDlcMultiMouseHunterModel:GetChapterInfoList()
    return self._ChapterInfoList
end

function XDlcMultiMouseHunterModel:SetCurrentChapterId(chapterId)
    self._CurrentChapterId = chapterId
end

function XDlcMultiMouseHunterModel:GetCurrentChapterId()
    return self._CurrentChapterId
end

function XDlcMultiMouseHunterModel:SetCurrencyCount(count)
    self._CurrencyCount = count
end

function XDlcMultiMouseHunterModel:SetCurrencyLimit(currencyLimit)
    self._CurrencyLimit = currencyLimit
end

function XDlcMultiMouseHunterModel:GetCurrencyLimit()
    return self._CurrencyLimit
end

function XDlcMultiMouseHunterModel:GetCurrencyCount()
    return self._CurrencyCount
end

function XDlcMultiMouseHunterModel:SetCurrentWearTitleId(titleId)
    self._CurrentWearTitleId = titleId
end

function XDlcMultiMouseHunterModel:GetCurrentWearTitleId()
    return self._CurrentWearTitleId
end

function XDlcMultiMouseHunterModel:SetTitleProgress(value)
    self._TitleProgress = value
end

function XDlcMultiMouseHunterModel:GetTitleProgress()
    return self._TitleProgress or {}
end

function XDlcMultiMouseHunterModel:SetUnlockTitleInfos(titleList)
    self._UnlockTitleIds = titleList
    self._IsRefreshTitlInfo = true
end

function XDlcMultiMouseHunterModel:GetUnlockTitleInfos()
    return self._UnlockTitleIds or {}
end

function XDlcMultiMouseHunterModel:GetIsRefreshTitlInfo()
    return self._IsRefreshTitlInfo
end

function XDlcMultiMouseHunterModel:RefreshedTitleInfo()
    self._IsRefreshTitlInfo = false
end

function XDlcMultiMouseHunterModel:GetIsShowShopRedPoint()
    return self._IsShowShopRedPoint
end

function XDlcMultiMouseHunterModel:SetIsShowShopRedPoint(value)
    self._IsShowShopRedPoint = value
end

function XDlcMultiMouseHunterModel:GetLocalUnlockTitleIdMap()
    if not self._LocalUnlockTitleIdMap then
        self:_InitLocalUnlockTitleIdMap()
    end

    return self._LocalUnlockTitleIdMap
end

function XDlcMultiMouseHunterModel:SetLocalUnlockTitleId(titleId)
    if not self._LocalUnlockTitleIdMap then
        self:_InitLocalUnlockTitleIdMap()
    end

    self._LocalUnlockTitleIdMap[titleId] = true
end

function XDlcMultiMouseHunterModel:SetFinishStageCount(count)
    self._FinishStageCount = count
end

function XDlcMultiMouseHunterModel:GetFinishStageCount()
    return self._FinishStageCount
end

function XDlcMultiMouseHunterModel:CheckNeedSyncShopInfo()
    return not self._IsRequestShopInfo
end

function XDlcMultiMouseHunterModel:RefreshSyncShopInfo()
    self._IsRequestShopInfo = true
end

function XDlcMultiMouseHunterModel:_GetFirstUnlockTitleSaveKey()
    local activityId = self:GetActivityId() or 0

    return "DLC_MULTI_MOUSE_HUNTER_TITLE_" .. XPlayer.Id .. activityId
end

function XDlcMultiMouseHunterModel:_SaveLocalUnlockTitleIdMap()
    if not self._LocalUnlockTitleIdMap then
        self:_InitLocalUnlockTitleIdMap()
    end

    local value = {}
    for titleId, _ in pairs(self._LocalUnlockTitleIdMap) do
        table.insert(value, tostring(titleId))
        table.insert(value, "|")
    end

    self._LocalUnlockTitleIdMap = nil
    if not XTool.IsTableEmpty(value) then
        table.remove(value, #value)
        XSaveTool.SaveData(self:_GetFirstUnlockTitleSaveKey(), table.concat(value))
    end
end

function XDlcMultiMouseHunterModel:_InitLocalUnlockTitleIdMap()
    local localStr = XSaveTool.GetData(self:_GetFirstUnlockTitleSaveKey())

    self._LocalUnlockTitleIdMap = {}
    if not string.IsNilOrEmpty(localStr) then
        local titleIds = string.Split(localStr, "|")

        if not XTool.IsTableEmpty(titleIds) then
            for _, titleId in pairs(titleIds) do
                self._LocalUnlockTitleIdMap[tonumber(titleId)] = true
            end
        end
    end
end

function XDlcMultiMouseHunterModel:GetDlcMultiplayerActivityConfig()
    return XMVCA.XDlcMultiplayer:GetDlcMultiplayerActivityConfigById(self._ActivityId)
end

function XDlcMultiMouseHunterModel:SetDiscussionData(data)
    if not self._Discussion then
        self._Discussion = XDlcMultiMouseHunterDiscussion.New()
    end

    self._Discussion:SetData(data)
end

function XDlcMultiMouseHunterModel:SetDiscussionInfo(info)
    if not self._Discussion then
        self._Discussion = XDlcMultiMouseHunterDiscussion.New()
    end

    self._Discussion:SetInfo(info)
end

function XDlcMultiMouseHunterModel:GetDiscussion()
    if not self._Discussion then
        self._Discussion = XDlcMultiMouseHunterDiscussion.New()
    end

    return self._Discussion
end

function XDlcMultiMouseHunterModel:SetBpLevel(bpLevel)
    self._BpLevel = bpLevel
end

function XDlcMultiMouseHunterModel:GetBpLevel()
    return self._BpLevel
end

function XDlcMultiMouseHunterModel:SetBpRewardIds(bpRewardIds)
    if not self._BpRewardIds then
        self._BpRewardIds = {}
    end
    for _, v in pairs(bpRewardIds) do
        self._BpRewardIds[v] = true
    end
end

function XDlcMultiMouseHunterModel:GetBpRewardIds()
    return self._BpRewardIds
end

function XDlcMultiMouseHunterModel:SetSkillData(skillData)
    if not self._SkillData then
        self._SkillData = {
            UnlockSkills = {}
        }
    end

    local data = self._SkillData
    for _, v in pairs(skillData.CatSkills) do
        data.UnlockSkills[v] = true
        if skillData.IsNew then
            self:SaveNewSkill(v)
        end
    end
    for _, v in pairs(skillData.MouseSkills) do
        data.UnlockSkills[v] = true
        if skillData.IsNew then
            self:SaveNewSkill(v)
        end
    end
end

function XDlcMultiMouseHunterModel:CheckHasNewSkill(skillId)
    return XSaveTool.GetData(self:GetSaveNewSkillKey(skillId))
end

function XDlcMultiMouseHunterModel:SaveNewSkill(skillId)
    XSaveTool.SaveData(self:GetSaveNewSkillKey(skillId), true)
end

function XDlcMultiMouseHunterModel:RemoveNewSkill(skillId)
    if self:CheckHasNewSkill(skillId) then
        XSaveTool.RemoveData(self:GetSaveNewSkillKey(skillId))
        XEventManager.DispatchEvent(XEventId.EVENT_DLC_MOUSE_HUNTER_REFRESH_SKILL_DATA)
    end
end

function XDlcMultiMouseHunterModel:GetSaveNewSkillKey(skillId)
    return string.format("MouseHunterNewSkill_%d_%d_%d", XPlayer.Id, self:GetActivityId() or 0, skillId)
end

function XDlcMultiMouseHunterModel:SaveDiscussionRedPoint()
    local discussion = self:GetDiscussion()
    if not discussion:HasDiscussionData() then 
        return
    end
    XSaveTool.SaveData(self:GetSaveDiscussionRedPointKey(), discussion:GetId())
end

function XDlcMultiMouseHunterModel:RemoveDiscussionRedPoint()
    XSaveTool.RemoveData(self:GetSaveDiscussionRedPointKey())
end

function XDlcMultiMouseHunterModel:CheckDiscussionRedPoint()
    local discussion = self:GetDiscussion()
    if not discussion:HasDiscussionData() then 
        return false
    end
    return XSaveTool.GetData(self:GetSaveDiscussionRedPointKey()) ~= discussion:GetId()
end

function XDlcMultiMouseHunterModel:GetSaveDiscussionRedPointKey()
    return string.format("MouseHunterDiscussionRedPoint_%d_%d", XPlayer.Id, self:GetActivityId() or 0)
end

function XDlcMultiMouseHunterModel:SetSelectSkillData(catSkillId, mouseSkillId)
    if not self._SkillData then
        self._SkillData = {
            UnlockSkills = {}
        }
    end

    self._SkillData.SelectCatSkillId = catSkillId
    self._SkillData.SelectMouseSkillId = mouseSkillId
end

function XDlcMultiMouseHunterModel:TryGetSkillData()
    return self._SkillData ~= nil, self._SkillData
end

function XDlcMultiMouseHunterModel:GetDlcMultiplayerSkillConfigById(id)
    return XMVCA.XDlcMultiplayer:GetDlcMultiplayerSkillConfigById(id)
end

function XDlcMultiMouseHunterModel:CheckBpRedPoint()
    local TaskEnum = XMVCA.XDlcMultiMouseHunter.DlcMouseHunterTaskType
    return self:CheckBpRewardRedPoint() or self:CheckBpTaskRedPoint(TaskEnum.Daily) or self:CheckBpTaskRedPoint(TaskEnum.Challenge)
end

function XDlcMultiMouseHunterModel:CheckBpTaskRedPoint(taskType)
    local bpTasks = self:GetBpTaskList(taskType, false)

    for _, v in pairs(bpTasks) do
        if v.State ~= XDataCenter.TaskManager.TaskState.InActive and XDataCenter.TaskManager.CheckTaskAchieved(v.Id) then
            return true
        end
    end
    
    return false
end

function XDlcMultiMouseHunterModel:CheckBpRewardRedPoint()
    local curLv = self:GetBpLevel()

    for i = curLv, 1, -1 do
        if not self:CheckReceiveBpReawrd(i) then
            return true
        end
    end

    return false
end

function XDlcMultiMouseHunterModel:GetBpTaskList(taskType, isSort)
    local TaskTypeEnum = XMVCA.XDlcMultiMouseHunter.DlcMouseHunterTaskType
    local activityId = self:GetActivityId()
    if not activityId then
        return {}
    end
    local activityTable = XMVCA.XDlcMultiplayer:GetDlcMultiplayerActivityConfigById(activityId)

    local taskTimeLimitIds
    if taskType == TaskTypeEnum.Daily then
        taskTimeLimitIds = activityTable.BpDailyTask
    elseif taskType == TaskTypeEnum.Challenge then
        taskTimeLimitIds = activityTable.BpForeverTask
    end

    local taskDatas = {}
    for _, taskTimeLimitId in ipairs(taskTimeLimitIds) do
        XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(taskTimeLimitId, false, false, taskDatas)
    end
    if isSort then
        XDataCenter.TaskManager.SortTaskDatas(taskDatas) 
    end
    
    --未开启任务(数据只做显示用)
    if taskType == TaskTypeEnum.Challenge then
        local checkData = {}
        local schedule = { { Value = 0 } }
        for _, v in ipairs(taskDatas) do
            checkData[v.Id] = true
        end

        for _, taskTimeLimitId in ipairs(taskTimeLimitIds) do
            local taskTimeConfig = XTaskConfig.GetTimeLimitTaskCfg(taskTimeLimitId)
            for _, v in ipairs(taskTimeConfig.TaskId) do
                if not checkData[v] then
                    table.insert(taskDatas, {
                        Id = v,
                        State = XDataCenter.TaskManager.TaskState.InActive,
                        Schedule = schedule
                    })
                end
            end
        end
    end

    return taskDatas
end

function XDlcMultiMouseHunterModel:CheckReceiveBpReawrd(lv)
    local rewards = self:GetBpRewardIds()
    return rewards[lv] == true
end


return XDlcMultiMouseHunterModel