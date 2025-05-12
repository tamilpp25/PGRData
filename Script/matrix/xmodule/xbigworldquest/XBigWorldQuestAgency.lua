---@class XBigWorldQuestAgency : XAgency
---@field private _Model XBigWorldQuestModel
local XBigWorldQuestAgency = XClass(XAgency, "XBigWorldQuestAgency")

local stringFormat = string.format

function XBigWorldQuestAgency:OnInit()
    self:InitEnum()
    self:InitConditionCheck()
    XMVCA.XBigWorldUI:AddFightUiCb("UiBigWorldTaskMain", handler(self, self.OpenQuestMainByFight), handler(self, self.CloseQuestMain))
end

function XBigWorldQuestAgency:InitRpc()
end

function XBigWorldQuestAgency:InitEvent()
end

function XBigWorldQuestAgency:ResetData()
    self._Model:ResetData()
end

-- 条件判断初始化
function XBigWorldQuestAgency:InitConditionCheck()
    XMVCA.XBigWorldService:RegisterConditionFunc(10101001, handler(self, self.ConditionCheckQuestFinish))
    XMVCA.XBigWorldService:RegisterConditionFunc(10101002, handler(self, self.ConditionCheckStepFinish))
end

--- 初始化枚举
--------------------------
function XBigWorldQuestAgency:InitEnum()
    self.QuestType = {
        All = 0,
        Main = 1,
        Side = 2,
        Normal = 3,
    }

    self.QuestState = {
        None = -1,
        --激活
        Activated = CS.EQuestState.Ready:GetHashCode(),
        --接取
        Undertaken = CS.EQuestState.InProgress:GetHashCode(),
        --已经完成
        Finished = CS.EQuestState.Finished:GetHashCode()
    }

    self.StepState = {
        Inactive = CS.EQuestStepState.InActive:GetHashCode(),
        Active = CS.EQuestStepState.InProgress:GetHashCode(),
        Finished = CS.EQuestStepState.Finished:GetHashCode(),
    }
    
    self.QuestOpType = {
        Receive = 1,
        Refresh = 2,
        Complete = 3,
        PopupBegin = 4,
        PopupEnd = 5,
    }

    local CsStatusSync = CS.StatusSyncFight.EQuestObjectiveProgressType
    self.QuestStepObjectiveType = {
        Bool = CsStatusSync.Bool:GetHashCode(),
        Int = CsStatusSync.Int:GetHashCode(),
        Float = CsStatusSync.Float:GetHashCode(),
        Percent = CsStatusSync.Percent:GetHashCode(),
    }
end

-- 检查到达目标的任务是否完成
function XBigWorldQuestAgency:ConditionCheckQuestFinish(template)
    local params = template.Params
    local questId = params[1]
    return self:CheckQuestFinish(questId), template.Desc
end

-- 检查到达目标的任务步骤是否完成
function XBigWorldQuestAgency:ConditionCheckStepFinish(template)
    local params = template.Params
    local stepId = params[1]
    return self:CheckStepFinish(stepId), template.Desc
end

function XBigWorldQuestAgency:IsQuestItem(id)
    if not XTool.IsNumberValid(id) then
        return false
    end
    
    return XArrangeConfigs.GetType(id) == XArrangeConfigs.Types.QuestItem
end

--region Quest Data

function XBigWorldQuestAgency:InitQuest(data)
    if not data then
        return
    end
    local quests = data.ActiveQuests
    for _, quest in pairs(quests) do
        local questData = self._Model:GetQuestData(quest.Id)
        questData:UpdateData(quest)
    end
    self._Model:UpdateFinishQuest(data.FinishedQuestIds)
    local trackId = self._Model:GetTrackQuestId()
    if trackId and trackId > 0 then
        self:NotifyFightTrackQuest(trackId, true)
    end
    
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_QUEST_OBJECTIVE_STATE_CHANGED, self.QuestOpType.Refresh)
end

function XBigWorldQuestAgency:OnQuestActivated(data)
    if not data then
        return
    end
    local questData = self._Model:GetQuestData(data.Id)
    questData:UpdateData(data)

    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_MESSAGE_QUEST_NOTIFY, data.Id)
end

function XBigWorldQuestAgency:OnQuestUndertaken(data)
    if not data then
        return
    end
    local questData = self._Model:GetQuestData(data.Id)
    questData:UpdateData(data)
    self:PopupTaskObtain(data.Id, false)
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_MESSAGE_QUEST_NOTIFY, data.Id)
end

function XBigWorldQuestAgency:OnQuestFinished(data)
    if not data then
        return
    end
    local lastQuestId = 0
    local trackId = self._Model:GetTrackQuestId()
    local untrack = false
    for _, id in pairs(data) do
        local quest = self:GetQuestData(id)
        quest:SetState(XMVCA.XBigWorldQuest.QuestState.Finished)
        lastQuestId = id
        if not untrack and trackId == id  then
            untrack = true
        end
    end
    self._Model:UpdateFinishQuest(data)
    if lastQuestId > 0 then
        self:PopupTaskObtain(lastQuestId, true)
    end

    if untrack then
        self:UnTrackQuest(trackId)
    end

    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_QUEST_OBJECTIVE_STATE_CHANGED, self.QuestOpType.Complete)
end

function XBigWorldQuestAgency:OnStepChanged(data)
    if not data then
        return
    end
    local questData = self._Model:GetQuestData(data.QuestId)
    local stepData = questData:TryGetStep(data.StepId)
    
    stepData:SetState(data.State)
    local op = self.QuestOpType.Refresh
    if stepData:IsFinish() then
        op = self.QuestOpType.Complete
    elseif stepData:IsActive() then
        op = self.QuestOpType.Receive
    end
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_QUEST_OBJECTIVE_STATE_CHANGED, op)
end

function XBigWorldQuestAgency:OnObjectiveChanged(data)
    if not data then
        return
    end
    local questData = self._Model:GetQuestData(data.QuestId)
    local stepData = questData:TryGetStep(data.StepId)
    local objectiveData = stepData:TryGetObjective(data.ObjectiveId)
    objectiveData:SetProgress(data.Progress)
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_QUEST_OBJECTIVE_STATE_CHANGED, self.QuestOpType.Refresh)
end

---@return XBigWorldQuest
function XBigWorldQuestAgency:GetQuestData(questId)
    return self._Model:GetQuestData(questId)
end

--- 追踪任务
---@param questId number 任务Id  
--------------------------
function XBigWorldQuestAgency:TrackQuest(questId, cb)
    local trackId = self._Model:GetTrackQuestId()
    if trackId == questId then
        if trackId ~= 0 then
            self:NotifyFightTrackQuest(questId, false, nil)
            self:NotifyFightTrackQuest(questId, true, cb)
        end
        return
    end
    
    XNetwork.Call("DlcQuestTraceIdChangeRequest", { ChangeTraceQuestId = questId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Model:SetTrackQuestId(questId)
        self:NotifyFightTrackQuest(questId, true, cb)
        
        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_QUEST_OBJECTIVE_STATE_CHANGED, self.QuestOpType.Receive)
    end)
end

--- 取消追踪
---@param questId number 任务Id    
--------------------------
function XBigWorldQuestAgency:UnTrackQuest(questId, cb)
    local trackId = self._Model:GetTrackQuestId()
    if not trackId or trackId <= 0 then
        return
    end

    XNetwork.Call("DlcQuestTraceIdChangeRequest", { ChangeTraceQuestId = 0 }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        
        self._Model:SetTrackQuestId(0)
        self:NotifyFightTrackQuest(questId, false, cb)
        
        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_QUEST_OBJECTIVE_STATE_CHANGED, self.QuestOpType.Refresh)
    end)
end

function XBigWorldQuestAgency:NotifyFightTrackQuest(questId, enable, cancelCb)
    local data = {
        QuestId = questId,
        Enable = enable,
    }
    local result = XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_QUEST_SET_NAVIGTION_ENABLE, data)
    local cancelId = 0
    if result and result.CanceledQuestId and result.CanceledQuestId > 0 then
        cancelId = result.CanceledQuestId
    elseif not enable then
        cancelId = questId
    end

    if cancelCb then cancelCb(cancelId) end
end

function XBigWorldQuestAgency:UpdateData(trackQuestId)
    self._Model:SetTrackQuestId(trackQuestId or 0)
end

function XBigWorldQuestAgency:CheckQuestFinish(questId)
    return self._Model:CheckQuestFinish(questId)
end

function XBigWorldQuestAgency:CheckStepFinish(stepId)
    local t = self._Model:GetQuestStepTemplate(stepId)
    if not t then
        return false
    end
    local questData = self:GetQuestData(t.QuestId)
    if not questData then
        return false
    end
    --任务已经完成
    if questData:IsFinish() then
        return true
    end
    local state = questData:GetState()
    --任务刚激活，还未领取
    if state == self.QuestState.Activated then
        return false
    end
    local stepData = questData:GetStep(stepId)
    if not stepData then
        return false
    end
    return stepData:IsFinish()
end

--endregion Quest Data

--region Quest Item Config

function XBigWorldQuestAgency:GetQuestItemIcon(templateId)
    local template = self._Model:GetQuestItemTemplate(templateId)
    return template and template.Icon or ""
end

function XBigWorldQuestAgency:GetQuestItemName(templateId)
    local template = self._Model:GetQuestItemTemplate(templateId)
    return template and template.Name or ""
end

function XBigWorldQuestAgency:GetQuestItemPriority(templateId)
    local template = self._Model:GetQuestItemTemplate(templateId)
    return template and template.Priority or ""
end

function XBigWorldQuestAgency:GetQuestItemQuality(templateId)
    local template = self._Model:GetQuestItemTemplate(templateId)
    return template and template.Quality or ""
end

function XBigWorldQuestAgency:GetQuestItemDescription(templateId)
    local template = self._Model:GetQuestItemTemplate(templateId)
    return template and template.Description or ""
end

function XBigWorldQuestAgency:GetQuestItemWorldDescription(templateId)
    local template = self._Model:GetQuestItemTemplate(templateId)
    return template and template.WorldDescription or ""
end

--endregion Quest Item Config

function XBigWorldQuestAgency:GetQuestDisplayProgress(questId)
    local questData = self._Model:GetQuestData(questId)
    local stepList = questData:GetActiveStepData()
    if XTool.IsTableEmpty(stepList) then
        return
    end
    local step = stepList[1]
    local objectiveList = step:GetObjectiveList()
    local list = {}
    for _, objective in pairs(objectiveList) do
        local id = objective:GetId()
        local title = self._Model:GetObjectiveTitle(id)
        local progress = self:GetObjectiveProgressDesc(id, objective:GetProgress())
        list[#list + 1] = {
            Title = title,
            Progress = progress
        }
    end
    return list
end

function XBigWorldQuestAgency:GetObjectiveProgressDesc(objectiveId, progress)
    local type = self._Model:GetObjectiveType(objectiveId)
    local max = self._Model:GetObjectiveMaxProgress(objectiveId)
    if type == self.QuestStepObjectiveType.Int then
        return stringFormat("%d/%d", progress, max)
    elseif type == self.QuestStepObjectiveType.Float then
        return stringFormat("%0.1f/%0.1f", progress / 10000, max / 10000)
    elseif type == self.QuestStepObjectiveType.Percent then
        return stringFormat("%0.1f%%", 100 * progress / max)
    elseif type == self.QuestStepObjectiveType.Bool then
        return stringFormat("%d/%d", progress > 0 and 0 or 1, 1)
    end
end

function XBigWorldQuestAgency:GetQuestStepText(questId)
    local questData = self._Model:GetQuestData(questId)
    local stepList = questData:GetActiveStepData()
    if XTool.IsTableEmpty(stepList) then
        return
    end
    local step = stepList[1]
    return self._Model:GetQuestStepText(step:GetId())
end

-- region Quest Config

function XBigWorldQuestAgency:GetQuestIcon(questId)
    local t = self._Model:GetQuestTemplate(questId)

    return t and t.QuestIcon or ""
end

function XBigWorldQuestAgency:GetQuestText(questId)
    local t = self._Model:GetQuestTemplate(questId)

    return t and t.QuestText or ""
end

function XBigWorldQuestAgency:GetQuestDesc(questId)
    local t = self._Model:GetQuestTemplate(questId)

    return t and t.QuestDesc or ""
end

function XBigWorldQuestAgency:GetQuestRewardId(questId)
    local t = self._Model:GetQuestTemplate(questId)

    return t and t.RewardId or 0
end

-- endregion

--region Ui Open

function XBigWorldQuestAgency:PopupTaskObtain(questId, isFinish)
    self._Model:PopupTaskObtain(questId, isFinish)
end

function XBigWorldQuestAgency:OpenPopupDelivery(luaTable)
    if not luaTable then
        XLog.Error("打开交付界面异常, 参数为空")
        return
    end
    XLuaUiManager.Open("UiBigWorldPopupDelivery", luaTable.ObjectiveId)
end

function XBigWorldQuestAgency:OpenQuestMain(index, questId)
    if self:IsTemporaryShield(questId) then
        return
    end
    XMVCA.XBigWorldUI:Open("UiBigWorldTaskMain", index, questId)
end

function XBigWorldQuestAgency:CloseQuestMain()
    XMVCA.XBigWorldUI:Close("UiBigWorldTaskMain")
end

function XBigWorldQuestAgency:OpenQuestMainByFight(data)
    self:OpenQuestMain(nil, nil)
end

local TemporaryQuestIdDict = {
    [3001] = true,
    [3002] = true,
    [3003] = true,
}
function XBigWorldQuestAgency:IsTemporaryShield(questId)
    return TemporaryQuestIdDict[questId] ~= nil
end

--endregion Ui Open

return XBigWorldQuestAgency