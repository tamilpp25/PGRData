---@class XBigWorldQuestModel : XModel
---@field private _QuestDataDict table<number, XBigWorldQuest>
local XBigWorldQuestModel = XClass(XModel, "XBigWorldQuestModel")

local XBigWorldQuest

local tableSort = table.sort
local pairs = pairs

local CsQuestConfig = CS.StatusSyncFight.XQuestConfig

local TableQuestKey = {
    DlcQuestItem = { CacheType = XConfigUtil.CacheType.Normal },
    DlcQuestType = { DirPath = XConfigUtil.DirectoryType.Client },
    DlcQuestGroup = { },
    DlcQuestChapter = { DirPath = XConfigUtil.DirectoryType.Client },
    DlcQuestArchive = { DirPath = XConfigUtil.DirectoryType.Client },
}

local QuestViewShield = {
    --领取时屏蔽
    ShieldWhenReceive = 1,
    --完成时屏蔽
    ShieldWhenFinish = 2,
}

local PopViewType = {
    --通用
    Small = 1,
    
    --全屏
    FullScreen = 2,
}

local PopViewType2UiName = {
    [PopViewType.Small] = "UiBigWorldTaskObtain",
    [PopViewType.FullScreen] = "UiBigWorldTaskObtainDrama",
}

local QuestViewShieldTypeList = {
    [0] = 0,
    [1] = QuestViewShield.ShieldWhenReceive,
    [2] = QuestViewShield.ShieldWhenFinish,
    [3] = QuestViewShield.ShieldWhenReceive | QuestViewShield.ShieldWhenFinish
}

function XBigWorldQuestModel:OnInit()
    self._QuestDataDict = false
    self._FinishQuest = false
    self._TrackQuestId = 0
    self._ConfigUtil:InitConfigByTableKey("DlcWorld/QuestSystem", TableQuestKey)
end

function XBigWorldQuestModel:ClearPrivate()
    self._TrackQuestId = 0
    self:ClearTemplate()
end

function XBigWorldQuestModel:ResetAll()
    self:ClearTemplate()
end

function XBigWorldQuestModel:ClearTemplate()
    self._TypeIds = nil
    self._Type2GroupIds = nil
    self._QuestId2GroupId = nil
end

function XBigWorldQuestModel:ResetData()
    self._QuestDataDict = false
end

--- 获取任务数据
---@param questId number 任务Id  
---@return XBigWorldQuest
--------------------------
function XBigWorldQuestModel:GetQuestData(questId)
    if not self._QuestDataDict then
        self._QuestDataDict = {}
    end
    if not XBigWorldQuest then
        XBigWorldQuest = require("XModule/XBigWorldQuest/Model/XBigWorldQuest")
    end
    local questData = self._QuestDataDict[questId]
    if not questData then
        questData = XBigWorldQuest.New(questId)
        self._QuestDataDict[questId] = questData
    end

    return questData
end

function XBigWorldQuestModel:UpdateFinishQuest(questIds)
    if not self._FinishQuest then
        self._FinishQuest = {}
    end
    if not XTool.IsTableEmpty(questIds) then
        for _, questId in pairs(questIds) do
            self._FinishQuest[questId] = true
        end
    end
end

function XBigWorldQuestModel:CheckQuestFinish(questId)
    if self._FinishQuest and self._FinishQuest[questId] then
        return true
    end
    local quest = self:GetQuestData(questId)
    return quest:IsFinish()
end

--- 获取所有接取的任务Id
---@return number[]
--------------------------
function XBigWorldQuestModel:GetReceiveQuestIds()
    if not self._QuestDataDict then
        return
    end
    local list = {}
    for id, data in pairs(self._QuestDataDict) do
        if data:IsShowInList() then
            list[#list + 1] = id
        end
    end

    return list
end

--- 当前正在追踪的任务
---@return number
--------------------------
function XBigWorldQuestModel:GetTrackQuestId()
    return self._TrackQuestId
end

function XBigWorldQuestModel:SetTrackQuestId(value)
    self._TrackQuestId = value
end

function XBigWorldQuestModel:CheckPopViewOpenWhenQuestReceive(questId)
    local t = self:GetQuestTemplate(questId)
    if not t then
        return false
    end
    local shieldViewType = t.ShieldPopViewType
    local value = QuestViewShieldTypeList[shieldViewType]
    return (value & QuestViewShield.ShieldWhenReceive) ~= 0
end

function XBigWorldQuestModel:CheckPopViewOpenWhenQuestFinish(questId)
    local t = self:GetQuestTemplate(questId)
    if not t then
        return false
    end
    local shieldViewType = t.ShieldPopViewType
    local value = QuestViewShieldTypeList[shieldViewType]
    return (value & QuestViewShield.ShieldWhenFinish) ~= 0
end

--region Config
---@return XTableDlcQuestItem
function XBigWorldQuestModel:GetQuestItemTemplate(templateId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableQuestKey.DlcQuestItem, templateId)
end

--- 获取任务配置
---@param questId number
---@return XTableDlcQuest
--------------------------
function XBigWorldQuestModel:GetQuestTemplate(questId)
    local template = CsQuestConfig.GetQuestTemplate(questId)
    if not template then
        XLog.Error(string.format("QuestId：%s不存在或CS.StatusSyncFight.XQuestConfig未初始化!", questId))
        return {}
    end
    return template
end

--- 获取任务步骤配置
---@param stepId number
---@return XTableDlcQuestStep
--------------------------
function XBigWorldQuestModel:GetQuestStepTemplate(stepId)
    local template = CsQuestConfig.GetQuestStepTemplate(stepId)
    if not template then
        XLog.Error(string.format("StepId：%s不存在或CS.StatusSyncFight.XQuestConfig未初始化!", stepId))
        return {}
    end
    return template
end

function XBigWorldQuestModel:GetQuestStepText(stepId)
    local template = self:GetQuestStepTemplate(stepId)
    return template and template.StepText
end

--- 获取步骤流程配置
---@param objectiveId number
---@return XTableDlcQuestStepObjective
--------------------------
function XBigWorldQuestModel:GetQuestStepObjectiveTemplate(objectiveId)
    local template = CsQuestConfig.GetQuestStepObjectiveTemplate(objectiveId)
    if not template then
        XLog.Error(string.format("ProcessId：%s不存在或CS.StatusSyncFight.XQuestConfig未初始化!", objectiveId))
        return {}
    end
    return template
end

function XBigWorldQuestModel:GetObjectiveType(objectiveId)
    local template = self:GetQuestStepObjectiveTemplate(objectiveId)
    return template and template.Type or 0
end

function XBigWorldQuestModel:GetObjectiveMaxProgress(objectiveId)
    local template = self:GetQuestStepObjectiveTemplate(objectiveId)
    return template and template.MaxProgress or 0
end

function XBigWorldQuestModel:GetObjectiveTitle(objectiveId)
    local template = self:GetQuestStepObjectiveTemplate(objectiveId)
    return template and template.Title or ""
end

--- 获取任务步骤列表, 从C#获取内容，只能在初始化调用，后续需要获取通过XSGQuest
---@param questId number
---@return number[]
--------------------------
function XBigWorldQuestModel:GetQuestStepIdsByQuestId(questId)
    local csList = CsQuestConfig.GetQuestStepIdsByQuestId(questId)
    if not csList or csList.Count <= 0 then
        return {}
    end
    local list = {}

    for i = 0, csList.Count - 1 do
        list[#list + 1] = csList[i]
    end
    return list
end

--- 获取任务步骤流程列表,从C#获取内容，只能在初始化调用，后续需要获取通过XSGStep
---@param stepId number
---@return number[]
--------------------------
function XBigWorldQuestModel:GetStepObjectiveIdsByStepId(stepId)
    local csList = CsQuestConfig.GetStepObjectiveIdsByStepId(stepId)
    local list = {}

    for i = 0, csList.Count - 1 do
        list[#list + 1] = csList[i]
    end
    return list
end

--region Quest Group

---@return XTableDlcQuestGroup
function XBigWorldQuestModel:GetGroupTemplate(groupId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableQuestKey.DlcQuestGroup, groupId)
end

function XBigWorldQuestModel:GetGroupType(groupId)
    local template = self:GetGroupTemplate(groupId)
    return template and template.Type or 0
end

function XBigWorldQuestModel:GetGroupName(groupId)
    local template = self:GetGroupTemplate(groupId)
    return template and template.Name or ""
end

function XBigWorldQuestModel:GetGroupPriority(groupId)
    local template = self:GetGroupTemplate(groupId)
    return template and template.Priority or 0
end

function XBigWorldQuestModel:GetGroupIncompleteText(groupId)
    local template = self:GetGroupTemplate(groupId)
    return template and template.IncompleteText or ""
end

function XBigWorldQuestModel:GetGroupQuestIds(groupId)
    local template = self:GetGroupTemplate(groupId)
    return template and template.Quest or {}
end

function XBigWorldQuestModel:GetGroupIdsByTypeId(typeId)
    if self._Type2GroupIds and self._Type2GroupIds[typeId] then
        return self._Type2GroupIds[typeId]
    end
    if not self._Type2GroupIds then
        self._Type2GroupIds = {}
    end
    local list = {}
    local isAll = typeId == XMVCA.XBigWorldQuest.QuestType.All
    ---@type table<number, XTableDlcQuestGroup>
    local templates = self._ConfigUtil:GetByTableKey(TableQuestKey.DlcQuestGroup)
    for id, template in pairs(templates) do
        if isAll or template.Type == typeId then
            list[#list + 1] = id
        end
    end

    tableSort(list, function(a, b)
        local pA = self:GetGroupPriority(a)
        local pB = self:GetGroupPriority(b)
        if pA ~= pB then
            return pA < pB
        end

        return a < b
    end)
    self._Type2GroupIds[typeId] = list

    return list
end

function XBigWorldQuestModel:GetGroupIdByQuestId(questId)
    if self._QuestId2GroupId and self._QuestId2GroupId[questId] then
        return self._QuestId2GroupId[questId]
    end

    if not self._QuestId2GroupId then
        self._QuestId2GroupId = {}
    end
    local dict = {}
    ---@type table<number, XTableDlcQuestGroup>
    local templates = self._ConfigUtil:GetByTableKey(TableQuestKey.DlcQuestGroup)
    for id, template in pairs(templates) do
        local questIds = template.Quest
        if not XTool.IsTableEmpty(questIds) then
            for _, qId in ipairs(questIds) do
                dict[qId] = id
            end
        end
    end
    self._QuestId2GroupId = dict
    if dict[questId] then
        return dict[questId]
    end
    XLog.Error("不存在任务组, QuestId = " .. questId)
    return 0
end

---@return XTableDlcQuestChapter
function XBigWorldQuestModel:GetChapterTemplate(chapterId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableQuestKey.DlcQuestChapter, chapterId)
end

---@return XTableDlcQuestArchive
function XBigWorldQuestModel:GetArchiveTemplate(archiveId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableQuestKey.DlcQuestArchive, archiveId)
end

--endregion Quest Group

function XBigWorldQuestModel:GetQuestTypeIds()
    if self._TypeIds then
        return self._TypeIds
    end
    local list = {}
    ---@type table<number, XTableDlcQuestType>
    local templates = self._ConfigUtil:GetByTableKey(TableQuestKey.DlcQuestType)
    for id, _ in pairs(templates) do
        list[#list + 1] = id
    end

    tableSort(list, function(a, b)
        local templateA = self:GetQuestTypeTemplate(a)
        local templateB = self:GetQuestTypeTemplate(b)
        local pA = templateA and templateA.Priority or 0
        local pB = templateB and templateB.Priority or 0
        if pA ~= pB then
            return pA < pB
        end

        return a < b
    end)

    self._TypeIds = list

    return self._TypeIds
end

---@return XTableDlcQuestType
function XBigWorldQuestModel:GetQuestTypeTemplate(typeId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableQuestKey.DlcQuestType, typeId)
end

function XBigWorldQuestModel:PopupTaskObtain(questId, isFinish)
    local isShield = isFinish and self:CheckPopViewOpenWhenQuestFinish(questId)
            or self:CheckPopViewOpenWhenQuestReceive(questId) 
    if isShield then
        return
    end
    local t = self:GetQuestTemplate(questId)
    local popViewType = t and t.PopViewType or PopViewType.Small
    local uiName = PopViewType2UiName[popViewType]
    if string.IsNilOrEmpty(uiName) then
        XLog.Error(string.format("任务:%s, 弹窗类型:%s, 不存在对应弹窗类型", questId, popViewType))
        return
    end
    XMVCA.XBigWorldUI:Open(uiName, questId, isFinish)
end

--endregion Config

--region 数据表定义

---@class XTableDlcQuest
---@field Id number
---@field Type number
---@field QuestIcon string
---@field QuestText string
---@field QuestDesc string
---@field Condition number
---@field ScriptId number
---@field RewardId number
---@field Desc string
---@field FirstStepId number
---@field ShieldPopViewType number
---@field PopViewType number


---@class XTableDlcQuestStep
---@field Id number
---@field QuestId number
---@field PreStep number[]
---@field IsEndStep boolean
---@field StepText string
---@field LocationText string
---@field RewardId number
---@field Desc string
---@field FirstObjectiveId number


---@class XTableDlcQuestStepObjective
---@field Id number
---@field StepId number
---@field Type number
---@field MaxProgress number
---@field Title string
---@field QuestItemId number[]
---@field ItemGetType number[]
---@field ItemGetUnit number[]
---@field ItemGetCount number[]
---@field Desc string

--endregion 数据表定义

return XBigWorldQuestModel