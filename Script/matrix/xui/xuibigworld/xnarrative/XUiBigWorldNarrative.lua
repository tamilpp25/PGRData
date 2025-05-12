---@class XUiBigWorldNarrative : XBigWorldUi
---@field _Control XBigWorldNarrativeControl
---@field TitleText UnityEngine.UI.Text
---@field ContentText UnityEngine.UI.Text
---@field BtnClose XUiComponent.XUiButton
local XUiBigWorldNarrative = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldNarrative")

local OpType = XMVCA.XBigWorldQuest.QuestOpType

function XUiBigWorldNarrative:OnAwake()
    self._currentId = 0
    self._closedCallback = nil
end

function XUiBigWorldNarrative:OnStart()
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
end

function XUiBigWorldNarrative:OnEnable(id, closedCallback)
    self._currentId = id
    self._closedCallback = closedCallback

    self:Refresh()

    -- 通用的ui流程不支持子UI，所以这里需要自己手动调用
    self:ChangePauseFight(true)
    self:ChangeCloseLittleMap(true)
    self:ChangeInput(true)

    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_QUEST_OBJECTIVE_STATE_CHANGED, OpType.PopupBegin)
end

function XUiBigWorldNarrative:OnDisable()
    self._currentId = 0
    self._closedCallback = nil
    self:ChangePauseFight(false)
    self:ChangeCloseLittleMap(false)
    self:ChangeInput(false)
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_QUEST_OBJECTIVE_STATE_CHANGED, OpType.PopupEnd)
end

function XUiBigWorldNarrative:Refresh()
    self.TitleText.text = XMVCA.XBigWorldService:GetNarrativeTitle(self._currentId)
    self.ContentText.text = XMVCA.XBigWorldService:GetNarrativeContent(self._currentId)
end

function XUiBigWorldNarrative:OnBtnCloseClick()
    local cb = self._closedCallback
    self:Close()
    if cb then
        cb()
        cb = nil
    end
end
