

---@class XUiBigWorldTaskObtain : XBigWorldUi
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field _Control XBigWorldQuestControl
local XUiBigWorldTaskObtain = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldTaskObtain")

local OpType = XMVCA.XBigWorldQuest.QuestOpType

local Duration = 2 * XScheduleManager.SECOND

function XUiBigWorldTaskObtain:OnAwake()
    self:InitUi()
    self:InitCb()

    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_QUEST_OBJECTIVE_STATE_CHANGED, OpType.PopupBegin)
end

function XUiBigWorldTaskObtain:OnStart(questId, isFinish)
    self._QuestId = questId
    self._IsFinish = isFinish
    self:InitView()
    self:StartTimer()
end

function XUiBigWorldTaskObtain:OnDestroy()
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_QUEST_OBJECTIVE_STATE_CHANGED, OpType.PopupEnd)
    self:StopTimer()
    self:SendCmd()
end

function XUiBigWorldTaskObtain:InitUi()
end

function XUiBigWorldTaskObtain:InitCb()
    self.BtnClose.CallBack = function()
        self:Close()
    end
end

function XUiBigWorldTaskObtain:InitView()
    local questId = self._QuestId
    local typeId = self._Control:GetQuestType(questId)
    self.TxtTitle.text = self._Control:GetQuestTypeName(typeId)
    local isFinish = self._IsFinish
    self.TxtDetail.text = self._Control:GetQuestName(questId)
    if self.ImgIcon then
        self.ImgIcon:SetSprite(self._Control:GetQuestIcon(questId))
    end
    self.ImgClear.gameObject:SetActiveEx(isFinish)
    self.ImgReceive.gameObject:SetActiveEx(not isFinish)
end

function XUiBigWorldTaskObtain:StartTimer()
    if self._TimerId then
        self:StopTimer()
    end
    self._TimerId = XScheduleManager.ScheduleOnce(function()
        self:Close()
    end, Duration)
end

function XUiBigWorldTaskObtain:StopTimer()
    if not self._TimerId then
        return
    end
    XScheduleManager.UnSchedule(self._TimerId)
    self._TimerId = nil
end

function XUiBigWorldTaskObtain:SendCmd()
    local questId = self._QuestId
    local state = self._IsFinish and 2 or 1
    XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_QUEST_POPUP_CLOSED, {
        QuestId = questId,
        State = state
    })
end