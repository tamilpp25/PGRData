

---@class XUiGridBWArchive : XUiNode
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field Parent XUiBigWorldLineChapter
---@field _Control XBigWorldQuestControl
---@field _Panel XUiPanelBWChapter
local XUiGridBWArchive = XClass(XUiNode, "XUiGridBWArchive")

local QuestState = XMVCA.XBigWorldQuest.QuestState
local CsNormal = CS.UiButtonState.Normal
local CsSelect = CS.UiButtonState.Select
local CsDisable = CS.UiButtonState.Disable

function XUiGridBWArchive:OnStart(panel, line, archiveId)
    self._Panel = panel
    self._Line = line
    self._ArchiveId = archiveId
    self:InitCb()
    self:InitView()
end

function XUiGridBWArchive:InitCb()
    if self.BtnClick then
        self.BtnClick.CallBack = handler(self, self.OnClick)
    end
    self._OnCloseDetailCb = function() 
        self:SetSelect(false)
        self._Panel:OnHideDetail()
    end
end

function XUiGridBWArchive:InitView()
    local questId = self._Control:GetQuestIdByArchiveId(self._ArchiveId)
    if self.RImg then
        self.BtnClick:SetRawImage(self._Control:GetArchiveIcon(self._ArchiveId))
    end

    local state = self._Control:GetQuestState(questId)
    self._State = state
    self.PanelDone.gameObject:SetActiveEx(state == QuestState.Finished)
    self.PanelReceive.gameObject:SetActiveEx(state == QuestState.Activated)
    if self.BtnClick then
        self.BtnClick:SetNameByGroup(0, self._Control:GetQuestName(questId))
        self.BtnClick:SetDisable(state == QuestState.None)
        self.BtnClick:ShowTag(state == QuestState.Activated or state == QuestState.Undertaken)
    end

    if self.PanelBlur then
        self.PanelBlur.gameObject:SetActiveEx(state == QuestState.Undertaken or state == QuestState.Activated)
    end
end

function XUiGridBWArchive:OnClick()
    if self._State == QuestState.None then
        return
    end
    self._Panel:OnShowDetail(self.Transform.parent.localPosition.x)
    self:SetSelect(true)
    XLuaUiManager.Open("UiBigWorldStoryStageDetail", self._ArchiveId, self._OnCloseDetailCb)
end

function XUiGridBWArchive:SetSelect(value)
    local state = value and CsSelect or (self._State == QuestState.None and CsDisable or CsNormal)
    if self.BtnClick then
        self.BtnClick:SetButtonState(state)
    end
end

return XUiGridBWArchive
