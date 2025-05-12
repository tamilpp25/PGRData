
---@class XUiPanelBWChapter : XUiNode
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field Parent XUiBigWorldLineChapter
---@field PaneStageList UnityEngine.UI.ScrollRect
---@field _Control XBigWorldQuestControl
local XUiPanelBWChapter = XClass(XUiNode, "XUiPanelBWChapter")

local XUiSGGridArchive = require("XUi/XUiBigWorld/XStory/Grid/XUiGridBWArchive")

local QuestNormal = XMVCA.XBigWorldQuest.QuestType.Normal
local QuestState = XMVCA.XBigWorldQuest.QuestState

local Unrestricted = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted
local Elastic = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic

local ChapterGridMoveMinX = XMVCA.XBigWorldGamePlay:GetCurrentAgency():GetInt("ChapterGridMoveMinX")
local ChapterGridMoveMaxX = XMVCA.XBigWorldGamePlay:GetCurrentAgency():GetInt("ChapterGridMoveMaxX")
local ChapterGridMoveTargetX = XMVCA.XBigWorldGamePlay:GetCurrentAgency():GetInt("ChapterGridMoveTargetX")

function XUiPanelBWChapter:OnStart(chapterId)
    self._ChapterId = chapterId
    self._QuestType2Prefab = {}
    self:InitCb()
    self:InitView()
end

function XUiPanelBWChapter:InitCb()
    self._IsShowDetail = false
end

function XUiPanelBWChapter:InitView()
    local chapterId = self._ChapterId

    local archiveIds = self._Control:GetChapterArchiveIds(chapterId)
    if XTool.IsTableEmpty(archiveIds) then
        self:Close()
        return
    end
    self._GridChapters = {}
    for index, archiveId in ipairs(archiveIds) do
        local stage = self.PanelStageContent:Find("Stage" .. index)
        if not stage then
            break
        end
        local questId = self._Control:GetQuestIdByArchiveId(archiveId)
        local preQuestId = self._Control:GetPreQuestIdByArchiveId(archiveId)
        local preUnlock = true
        if preQuestId and preQuestId > 0 then
            local state = self._Control:GetQuestState(preQuestId)
            preUnlock = state == QuestState.Finished
        end
        local line = self.PanelStageContent:Find("Line" .. index - 1)
        if line then
            line.gameObject:SetActiveEx(preUnlock)
        end
        if preUnlock then
            local questType = self._Control:GetQuestType(questId)
            local url = self:GetQuestPrefabUrl(questType)

            local prefab = stage:LoadPrefab(url)

            local grid = XUiSGGridArchive.New(prefab, self.Parent, self, line, archiveId)

            self._GridChapters[index] = grid
        end
    end
end

function XUiPanelBWChapter:GetQuestPrefabUrl(questType)
    local url = self._QuestType2Prefab[questType]
    if url then
        return url
    end
    if questType == QuestNormal then
        url = XMVCA.XBigWorldResource:GetAssetUrl("QuestGridStage")
    else
        url = XMVCA.XBigWorldResource:GetAssetUrl("QuestGridStage2")
    end

    self._QuestType2Prefab[questType] = url

    return url
end

function XUiPanelBWChapter:OnShowDetail(gridX)
    self.PaneStageList.movementType = Unrestricted
    local localPosition = self.PanelStageContent.transform.localPosition
    self._LastPosX = localPosition.x
    local diffX = gridX + localPosition.x

    if diffX < ChapterGridMoveMinX or diffX > ChapterGridMoveMaxX then
        local tarPosX = ChapterGridMoveTargetX - gridX
        localPosition.x = tarPosX
        XLuaUiManager.SetMask(true)
        self:DoMove(self.PanelStageContent, localPosition, 0.3, XUiHelper.EaseType.Sin, function()
            XLuaUiManager.SetMask(false)
        end)
    end
end

function XUiPanelBWChapter:OnHideDetail(needAnim)
    if needAnim then
        local localPosition = self.PanelStageContent.transform.localPosition
        localPosition.x = self._LastPosX
        XLuaUiManager.SetMask(true)
        self:DoMove(self.PanelStageContent, localPosition, 0.3, XUiHelper.EaseType.Sin, function()
            self.PaneStageList.movementType = Elastic
            XLuaUiManager.SetMask(false)
        end)
    else
        self.PaneStageList.movementType = Elastic
    end
end

return XUiPanelBWChapter