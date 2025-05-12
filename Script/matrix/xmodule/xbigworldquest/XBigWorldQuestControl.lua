---@class XBigWorldQuestControl : XControl
---@field private _Model XBigWorldQuestModel
local XBigWorldQuestControl = XClass(XControl, "XBigWorldQuestControl")

local QuestStepObjectiveType = XMVCA.XBigWorldQuest.QuestStepObjectiveType

local stringFormat = string.format
local pairs = pairs

function XBigWorldQuestControl:OnInit()
end

function XBigWorldQuestControl:AddAgencyEvent()
end

function XBigWorldQuestControl:RemoveAgencyEvent()

end

function XBigWorldQuestControl:OnRelease()
end

function XBigWorldQuestControl:GetQuestTypeIds()
    return self._Model:GetQuestTypeIds()
end

function XBigWorldQuestControl:GetQuestTypeIcon(typeId)
    if typeId <= 0 then
        return ""
    end
    local template = self._Model:GetQuestTypeTemplate(typeId)
    return template and template.Icon or ""
end

function XBigWorldQuestControl:GetQuestTypeName(typeId)
    if typeId <= 0 then
        return ""
    end
    local template = self._Model:GetQuestTypeTemplate(typeId)
    return template and template.Name or ""
end

function XBigWorldQuestControl:GetGroupIdsByTypeId(typeId)
    return self._Model:GetGroupIdsByTypeId(typeId)
end

function XBigWorldQuestControl:GetGroupName(groupId)
    return self._Model:GetGroupName(groupId)
end

function XBigWorldQuestControl:GetQuestName(questId)
    local template = self._Model:GetQuestTemplate(questId)
    return template and template.QuestText or ""
end

function XBigWorldQuestControl:GetQuestType(questId)
    local template = self._Model:GetQuestTemplate(questId)
    return template and template.Type or 0
end

function XBigWorldQuestControl:GetQuestDesc(questId)
    local template = self._Model:GetQuestTemplate(questId)
    return template and template.QuestDesc or 0
end

function XBigWorldQuestControl:GetQuestFirstStepId(questId)
    local template = self._Model:GetQuestTemplate(questId)
    return template and template.FirstStepId or 0
end

function XBigWorldQuestControl:GetQuestIcon(questId)
    local template = self._Model:GetQuestTemplate(questId)
    return template and template.QuestIcon or 0
end

function XBigWorldQuestControl:GetQuestState(questId)
    local questData = self._Model:GetQuestData(questId)
    return questData:GetState()
end

function XBigWorldQuestControl:GetGroupIdByQuestId(questId)
    return self._Model:GetGroupIdByQuestId(questId)
end

function XBigWorldQuestControl:GetTrackQuestId()
    return self._Model:GetTrackQuestId()
end

function XBigWorldQuestControl:IsTrackQuest(questId)
    if not questId or questId <= 0 then
        return false
    end
    return self:GetTrackQuestId() == questId
end

---@return XBigWorldQuestStep[]
function XBigWorldQuestControl:GetActiveStepData(questId)
    local questData = self._Model:GetQuestData(questId)
    return questData:GetActiveStepData()
end

function XBigWorldQuestControl:GetReceiveQuestIds()
    return self._Model:GetReceiveQuestIds()
end

function XBigWorldQuestControl:GetQuestIdsByGroupId(groupId, questIds)
    questIds = questIds or self:GetReceiveQuestIds()
    if XTool.IsTableEmpty(questIds) then
        return
    end

    local list
    for _, questId in pairs(questIds) do
        local gId = self:GetGroupIdByQuestId(questId)
        if gId == groupId then
            if not list then
                list = {}
            end
            list[#list + 1] = questId
        end
    end

    return list
end

function XBigWorldQuestControl:GetStepReward(stepId)
    local template = self._Model:GetQuestStepTemplate(stepId)
    return template and template.RewardId or 0
end

function XBigWorldQuestControl:GetStepText(stepId)
    return self._Model:GetQuestStepText(stepId)
end

function XBigWorldQuestControl:GetStepLocation(stepId)
    local template = self._Model:GetQuestStepTemplate(stepId)
    return template and template.LocationText or ""
end

function XBigWorldQuestControl:GetStepData(questId, stepId)
    local questData = self._Model:GetQuestData(questId)
    local stepData = questData:TryGetStep(stepId)
    return stepData
end

function XBigWorldQuestControl:GetObjectiveTitle(objectiveId)
    return self._Model:GetObjectiveTitle(objectiveId)
end

function XBigWorldQuestControl:IsBoolObjectiveType(objectiveId)
    local type = self._Model:GetObjectiveType(objectiveId)
    return type == QuestStepObjectiveType.Bool
end

function XBigWorldQuestControl:GetObjectiveProgressDesc(objectiveId, progress)
    return XMVCA.XBigWorldQuest:GetObjectiveProgressDesc(objectiveId, progress)
end

function XBigWorldQuestControl:IsObjectiveFinish(objectiveId, progress)
    local type = self._Model:GetObjectiveType(objectiveId)
    local max = self._Model:GetObjectiveMaxProgress(objectiveId)
    if type == QuestStepObjectiveType.Bool then
        return progress > 0
    end
    return progress >= max
end

function XBigWorldQuestControl:GetObjectConsume(objectiveId)
    local t = self._Model:GetQuestStepObjectiveTemplate(objectiveId)
    local dict
    local itemGetCount = t.ItemGetCount
    if not itemGetCount or itemGetCount.Count <= 0 then
        return dict
    end
    for i = 0, itemGetCount.Count - 1 do
        local count = itemGetCount[i]
        if count < 0 then
            if not dict then
                dict = {}
            end
            local id = t.QuestItemId[i]
            if dict[id] then
                dict[id] = dict[id] - count
            else
                dict[id] = -count
            end
        end
    end
    return dict
end

function XBigWorldQuestControl:GetChapterId()
    -- 第一期没有章节概念，后续会改成读表
    return 1001
end

function XBigWorldQuestControl:GetChapterUrl(chapterId)
    local template = self._Model:GetChapterTemplate(chapterId)
    return template and template.ChapterUrl or ""
end

function XBigWorldQuestControl:GetChapterFullBg(chapterId)
    local template = self._Model:GetChapterTemplate(chapterId)
    return template and template.FullBg or ""
end

function XBigWorldQuestControl:GetChapterMapName(chapterId)
    local template = self._Model:GetChapterTemplate(chapterId)
    return template and template.MapName or ""
end

function XBigWorldQuestControl:GetChapterName(chapterId)
    local template = self._Model:GetChapterTemplate(chapterId)
    return template and template.ChapterName or ""
end

function XBigWorldQuestControl:GetChapterArchiveIds(chapterId)
    local template = self._Model:GetChapterTemplate(chapterId)
    return template and template.ArchiveIds or nil
end

function XBigWorldQuestControl:GetQuestIdByArchiveId(archiveId)
    local template = self._Model:GetArchiveTemplate(archiveId)
    return template and template.QuestId or 0
end

function XBigWorldQuestControl:GetPreQuestIdByArchiveId(archiveId)
    local template = self._Model:GetArchiveTemplate(archiveId)
    return template and template.PreQuestId or 0
end

function XBigWorldQuestControl:GetArchiveIcon(archiveId)
    local template = self._Model:GetArchiveTemplate(archiveId)
    return template and template.Icon or 0
end

function XBigWorldQuestControl:GetArchiveCompleteText(archiveId)
    local template = self._Model:GetArchiveTemplate(archiveId)
    return template and template.CompleteText or 0
end

return XBigWorldQuestControl