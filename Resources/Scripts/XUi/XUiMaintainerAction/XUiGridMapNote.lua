local XUiGridMapNote = XClass(nil, "XUiGridMapNote")
local MapNodeMaxCount = 16

local TweenSpeed ={
    High = 0.3,
    Low = 0.5,
}
local StartAlpha = 0
local EndAlpha = 1

function XUiGridMapNote:Ctor(ui,base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.Base = base
    self.IsPlayerIn = false
    self.CurState = XMaintainerActionConfigs.NodeState.Normal
    self.EventShowAnime.gameObject:SetActiveEx(false)
    
    self:SetButtonCallBack()
end

function XUiGridMapNote:SetButtonCallBack()
    self.BtnIattice.CallBack = function()
        self:OnBtnIatticeClick()
    end
end

function XUiGridMapNote:OnBtnIatticeClick()
    if not self.NoteEntity then
        return
    end
    local player = XDataCenter.MaintainerActionManager.GetPlayerMySelf()
    if self.NoteEntity:GetIsFight() and not player:GetIsNodeTriggered() and
        player:GetPosNodeId() == self.NoteEntity:GetId() then
        self.NoteEntity:DoEvent({})--参数不能为空
    else
        self.NoteEntity:OpenDescTip()
    end
end

function XUiGridMapNote:UpdateNote(entity)
    self.NoteEntity = entity
    if entity then
        self:ShowEvent(entity)
        self:SetEventData(entity)
        self:CheckNodeState()
    end
end

function XUiGridMapNote:CheckNodeState()
    local player = XDataCenter.MaintainerActionManager.GetPlayerMySelf()
    local IsUnKonwn = self.NoteEntity:GetIsUnKonwn()
    local nodeId = self:GetLineId()
    self.NormalEventBg.gameObject:SetActiveEx(false)
    self.RandomEventBg.gameObject:SetActiveEx(false)
    self.OnRouteBg.gameObject:SetActiveEx(false)
    self.TargetBg.gameObject:SetActiveEx(false)
    self.Base.LineList[nodeId].gameObject:SetActiveEx(false)
    if self.CurState == XMaintainerActionConfigs.NodeState.Normal then
        if player:GetPosNodeId() == self.NoteEntity:GetId() then
            self.TargetBg.gameObject:SetActiveEx(true)
        else
            self.NormalEventBg.gameObject:SetActiveEx(not IsUnKonwn)
            self.RandomEventBg.gameObject:SetActiveEx(IsUnKonwn)
        end
    elseif self.CurState == XMaintainerActionConfigs.NodeState.OnRoute then
        self.OnRouteBg.gameObject:SetActiveEx(true)
        self.Base.LineList[nodeId].gameObject:SetActiveEx(true)
    elseif self.CurState == XMaintainerActionConfigs.NodeState.Target then
        self.TargetBg.gameObject:SetActiveEx(true)
    end
end

function XUiGridMapNote:GetLineId()
    local playerDic = XDataCenter.MaintainerActionManager.GetPlayerDic()
    local player = playerDic[XPlayer.Id]
    if not player:GetIsReverse() then
        return self.NoteEntity:GetId() + 1
    else
        local id = self.NoteEntity:GetId()
        return id > 0 and id or (id + MapNodeMaxCount)
    end
end

function XUiGridMapNote:SetNodeState(state)
    self.CurState = state
    self:CheckNodeState()
end

function XUiGridMapNote:SetEventData(entity)
    local icon = entity:GetEventIcon()
    if icon then
        self.EventIcon:SetSprite(icon)
    else
        self.EventText.text = entity:GetName()
    end
    self.EventIcon.gameObject:SetActiveEx(icon)
    self.EventText.gameObject:SetActiveEx(not icon)
end

function XUiGridMapNote:ShowEvent(entity)
    local IsUnKonwn = entity:GetIsUnKonwn()
    local IsNone = entity:GetIsNone()
    self.Event.gameObject:SetActiveEx(not IsUnKonwn and not IsNone)
    self.Unknown.gameObject:SetActiveEx(IsUnKonwn)
end

function XUiGridMapNote:PlayerInShow(IsIn,IsAnime)
    if self.IsPlayerIn ~= IsIn then
        self.IsPlayerIn = IsIn
        if IsAnime then
            self:SetEventAnimeHide(IsIn)
        else
            self:SetEventHide(IsIn)
        end
        
    end
end

function XUiGridMapNote:SetEventAnimeHide(IsIn)
    self:StopTween()
    self.CurEventAlpha = self.EventInfoCanvasGroup.alpha
    if IsIn then
        self.AlphaTimer = XUiHelper.DoAlpha(self.EventInfoCanvasGroup, self.CurEventAlpha, StartAlpha, TweenSpeed.High, XUiHelper.EaseType.Sin, nil)
    else
        self.AlphaTimer = XUiHelper.DoAlpha(self.EventInfoCanvasGroup, self.CurEventAlpha, EndAlpha, TweenSpeed.Low, XUiHelper.EaseType.Sin, nil)
    end
end

function XUiGridMapNote:SetEventHide(IsIn)
    self:StopTween()
    if IsIn then
        self.EventInfoCanvasGroup.alpha = StartAlpha
    else
        self.EventInfoCanvasGroup.alpha = EndAlpha
    end
end

function XUiGridMapNote:StopTween()
    if self.AlphaTimer then
        XScheduleManager.UnSchedule(self.AlphaTimer)
        self.AlphaTimer = nil
    end
end

function XUiGridMapNote:PlayEventAnime()
    self.EventShowAnime.gameObject:SetActiveEx(true)
end

return XUiGridMapNote