
---@class XUiBigWorldTaskObtainDrama : XBigWorldUi
---@field _Control XBigWorldQuestControl
local XUiBigWorldTaskObtainDrama = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldTaskObtainDrama")

local OpType = XMVCA.XBigWorldQuest.QuestOpType

function XUiBigWorldTaskObtainDrama:OnAwake()
    self:InitUi()
    self:InitCb()

    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_QUEST_OBJECTIVE_STATE_CHANGED, OpType.PopupBegin)
end

function XUiBigWorldTaskObtainDrama:OnStart(questId, isFinish)
    self._QuestId = questId
    self._IsFinish = isFinish
    self:InitView()
end

function XUiBigWorldTaskObtainDrama:OnDestroy()
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_QUEST_OBJECTIVE_STATE_CHANGED, OpType.PopupEnd)
    self:SendCmd()
end

function XUiBigWorldTaskObtainDrama:InitUi()
end

function XUiBigWorldTaskObtainDrama:InitCb()
    self.BtnClose.CallBack = function()
        self:Close()
    end
end

function XUiBigWorldTaskObtainDrama:InitView()
    local questId = self._QuestId
    local typeId = self._Control:GetQuestType(questId)
    self.TxtTaskType.text = self._Control:GetQuestTypeName(typeId)

    local isFinish = self._IsFinish
    self.TxtTaskComplete.gameObject:SetActiveEx(isFinish)
    self.TxtTaskStart.gameObject:SetActiveEx(not isFinish)

    self.TxtTaskTitle.text = self._Control:GetQuestName(questId)
end

function XUiBigWorldTaskObtainDrama:SendCmd()
    local questId = self._QuestId
    local state = self._IsFinish and 2 or 1
    XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_QUEST_POPUP_CLOSED, {
        QuestId = questId,
        State = state
    })
end