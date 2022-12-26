local XUiInvertGameCardItem = XClass(nil, "XUiInvertGameCardItem")
local RotateDuringTime = 0.2 -- 卡牌翻转时间
local MoveCenterDuringTime = 0.25 -- 卡牌移动到中心的时间
local ClearEffectDuriation = 850 -- 卡牌消失特效时间(毫秒)
local Vector3 = CS.UnityEngine.Vector3
local Vector2 = CS.UnityEngine.Vector2

function XUiInvertGameCardItem:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RectTransform = ui
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self:Init()
end

function XUiInvertGameCardItem:Init()
    self.BtnCard.CallBack = function () self:OnClickBtnCard() end
    self.AsynRotate = asynTask(self.DORotate, self)
end

function XUiInvertGameCardItem:OnCreat(data, parent)
    self.Data = data
    self.Parent = parent
    self:Refresh()
end

function XUiInvertGameCardItem:Refresh()
    if self.Data then
        local baseIcon = XInvertCardGameConfig.GetCardBaseIconById(self.Data.CardId)
        if baseIcon and baseIcon ~= "" then
            self.RImgPeople:SetRawImage(baseIcon)
        end

        if self.Data.IsBack then
            self:SetCardState(XInvertCardGameConfig.InvertCardGameCardState.Back)
        else
            self:SetCardState(XDataCenter.InvertCardGameManager.CheckCardState(self.Data.StageId, self.Data.Index))
        end
    end
end

function XUiInvertGameCardItem:OnClickBtnCard()
    if self.Data then
        XDataCenter.InvertCardGameManager.InvertCardRequest(self.Data.StageId, self.Data.Index)
    end
end

function XUiInvertGameCardItem:SetActiveEx(bool)
    self.GameObject:SetActiveEx(bool)
end

function XUiInvertGameCardItem:SetFinish(bool)
    self.GridDraw.gameObject:SetActiveEx(not bool)
end

function XUiInvertGameCardItem:SetCardState(cardState)
    if cardState == XInvertCardGameConfig.InvertCardGameCardState.Back then
        self.GridDraw.gameObject:SetActiveEx(true)
        self.RImg.gameObject:SetActiveEx(true)
        self.RImgPeople.gameObject:SetActiveEx(false)
    elseif cardState == XInvertCardGameConfig.InvertCardGameCardState.Front then
        self.GridDraw.gameObject:SetActiveEx(true)
        self.RImg.gameObject:SetActiveEx(false)
        self.RImgPeople.gameObject:SetActiveEx(true)
    elseif cardState == XInvertCardGameConfig.InvertCardGameCardState.Finish then
        self.GridDraw.gameObject:SetActiveEx(false)
    end
end

function XUiInvertGameCardItem:DORotate(turningCb, cb)
    self.GridDraw.transform:DOScaleX(0, RotateDuringTime):OnComplete(function ()
        if turningCb then turningCb() end
        self.GridDraw.transform:DOScaleX(1, RotateDuringTime):OnComplete(function ()
            if cb then cb() end
        end)
    end)
end

function XUiInvertGameCardItem:DOMoveToCenter(cb)
    self.OldAnchoredPos = self.RectTransform.anchoredPosition
    self.RectTransform:DOAnchorPos(Vector2(self.Parent.HalfGamePanelWidth, -self.Parent.HalfGamePanelHeight), MoveCenterDuringTime):OnComplete(function ()
        if cb then cb() end
    end)
end

function XUiInvertGameCardItem:DOMoveFromCenter(cb)
    self.RectTransform:DOAnchorPos(self.OldAnchoredPos, MoveCenterDuringTime):OnComplete(function ()
        if cb then cb() end
    end)
end

function XUiInvertGameCardItem:PlayClearEffectAnimation(cb)
    self.ClearEffect.gameObject:SetActiveEx(true)
    XScheduleManager.ScheduleOnce(function ()
        self.ClearEffect.gameObject:SetActiveEx(false)
        if cb then cb() end
    end, ClearEffectDuriation)
end

return XUiInvertGameCardItem