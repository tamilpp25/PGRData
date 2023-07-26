
local XUiHitMouseExitTips = XLuaUiManager.Register(XLuaUi, "UiHitMouseExitTips")

function XUiHitMouseExitTips:OnStart(isEndGame, currentScore, historyScore, onConfirmCb, onCancelCb)
    self.IsEndGame = isEndGame
    self.OnConfirmCb = onConfirmCb
    self.OnCancelCb = onCancelCb
    self.CurrentScore = currentScore
    self.HistoryScore = historyScore
    self:InitBaseBtns()
    self:InitPanels()
    self:AddListeners()
end

function XUiHitMouseExitTips:InitBaseBtns()
    self.BtnClose.CallBack = function() self:OnClickBtnClose() end
    self.BtnEndAgain.CallBack = function() self:OnClickEndAgain() end
    self.BtnEndConfirm.CallBack = function() self:OnClickEndConfirm() end
    self.BtnReturnCancel.CallBack = function() self:OnClickReturnCancel() end
    self.BtnReturnConfirm.CallBack = function() self:OnClickReturnConfirm() end
end

function XUiHitMouseExitTips:InitPanels()
    self.PanelReturn.gameObject:SetActiveEx(not self.IsEndGame)
    self.PanelEnd.gameObject:SetActiveEx(self.IsEndGame)
    if self.IsEndGame then
        self.TxtEndCurrentScore.text = self.CurrentScore
        self.TxtEndHistoryScore.text = self.HistoryScore
        self.TxtEndNewRecord.gameObject:SetActiveEx(self.CurrentScore > self.HistoryScore)
    else
        self.TxtReturnCurrentScore.text = self.CurrentScore
        self.TxtReturnHistoryScore.text = self.HistoryScore
        self.TxtReturnNewRecord.gameObject:SetActiveEx(self.CurrentScore > self.HistoryScore)
    end
end

function XUiHitMouseExitTips:OnClickBtnClose()
    
end

function XUiHitMouseExitTips:OnClickEndAgain()
    self:Close()
    if self.OnCancelCb then
        self.OnCancelCb()
    end
end

function XUiHitMouseExitTips:OnClickEndConfirm()
    self:Close()
    if self.OnConfirmCb then
        self.OnConfirmCb()
    end
end

function XUiHitMouseExitTips:OnClickReturnCancel()
    self:Close()
    if self.OnCancelCb then
        self.OnCancelCb()
    end
end

function XUiHitMouseExitTips:OnClickReturnConfirm()
    self:Close()
    if self.OnConfirmCb then
        self.OnConfirmCb()
    end
end

function XUiHitMouseExitTips:OnDestroy()
    self:RemoveListeners()
end

function XUiHitMouseExitTips:OnActivityEnd()
    XDataCenter.HitMouseManager.OnActivityEndHandler()
end

--==============
--添加UI事件监听
--==============
function XUiHitMouseExitTips:AddListeners()
    XEventManager.AddEventListener(XEventId.EVENT_HIT_MOUSE_ACTIVITY_END, self.OnActivityEnd, self)
end
--==============
--移除UI事件监听
--==============
function XUiHitMouseExitTips:RemoveListeners()
    XEventManager.RemoveEventListener(XEventId.EVENT_HIT_MOUSE_ACTIVITY_END, self.OnActivityEnd, self)
end