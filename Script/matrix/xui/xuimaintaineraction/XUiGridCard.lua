local XUiGridCard = XClass(nil, "XUiGridCard")

local TweenSpeed = 0.5
local StartAlpha = 0
local EndAlpha = 1
local NewCardPosId = 4
local CardStateCount = 3

function XUiGridCard:Ctor(ui,base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    self.State = XMaintainerActionConfigs.CardState.Normal
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
end

function XUiGridCard:SetButtonCallBack()
    self.BtnCard.CallBack = function()
        self:OnBtnCardClick()
    end
end

function XUiGridCard:OnBtnCardClick()
    if self.State == XMaintainerActionConfigs.CardState.Disable then
        return
    elseif self.State == XMaintainerActionConfigs.CardState.Select then
        self:UseCard()
    else
        self.Base:UnSelectAllCard()
        self:SetCardState(XMaintainerActionConfigs.CardState.Select)
        XEventManager.DispatchEvent(XEventId.EVENT_MAINTAINERACTION_SELECTCARD,self.CurNum)
    end
end

function XUiGridCard:SetCardState(state)
    self.State = state
    if state == XMaintainerActionConfigs.CardState.Disable then
        self.BtnCard:SetButtonState(CS.UiButtonState.Disable)
    elseif state == XMaintainerActionConfigs.CardState.Select then
        self.BtnCard:SetButtonState(CS.UiButtonState.Select)
    elseif state == XMaintainerActionConfigs.CardState.Normal then
        self.BtnCard:SetButtonState(CS.UiButtonState.Normal)
        self.BtnCard.TempState = CS.UiButtonState.Normal
    end
end

function XUiGridCard:SetCardNum(num)
    self.CurNum = num
    self.BtnCard:SetName(num)
end

function XUiGridCard:SetCardPosId(posId)
    self.CurPosId = posId
end

function XUiGridCard:ShowTag(IsShow)
    for i = 1,CardStateCount do
        self.TagGroup:GetObject(string.format("Tag%d",i)).gameObject:SetActiveEx(IsShow)
    end
end

function XUiGridCard:UseCard()
    XLuaUiManager.SetMask(true)
    local IsOver = XDataCenter.MaintainerActionManager.CheckIsActionPointOver()
    if IsOver then
        XUiManager.TipText("MaintainerActionPowerOver")
        XLuaUiManager.SetMask(false)
        return
    end
    
    local gameData = XDataCenter.MaintainerActionManager.GetGameData()
    XDataCenter.MaintainerActionManager.PlayerMoveRequest(self.CurNum, self.CurPosId, function (data)
            local tmpData = {}
            tmpData.UsedActionCount = gameData:GetUsedActionCount() + 1

            gameData:CardChange(self.CurNum,data.NewCard)
            gameData:UpdateData(tmpData)
            
            local tagPos = self.Base.CardPos[NewCardPosId]
            self.Base.UsedCardPosId = self.CurPosId
            self.CurPosId = NewCardPosId
            XLuaUiManager.SetMask(true)
            self.UseCardAlphaTimer = XUiHelper.DoAlpha(self.BtnCardCanvaGroup, EndAlpha, StartAlpha, TweenSpeed, XUiHelper.EaseType.Sin, function ()
                    XLuaUiManager.SetMask(false)
                    self.UseCardAlphaTimer = nil
                    self.Transform.localPosition = tagPos
                    self.BtnCardCanvaGroup.alpha = EndAlpha
                    XEventManager.DispatchEvent(XEventId.EVENT_MAINTAINERACTION_USECARD,data.NodeId)
                    self:SetCardNum(data.NewCard)
                    self:SetCardState(XMaintainerActionConfigs.CardState.Normal)
                end)
    end)
end

function XUiGridCard:Change(newCard, cb)
    local gameData = XDataCenter.MaintainerActionManager.GetGameData()
    gameData:CardChange(self.CurNum,newCard)

    local tagPos = self.Base.CardPos[NewCardPosId]
    self.Base.UsedCardPosId = self.CurPosId
    self.CurPosId = NewCardPosId
    XLuaUiManager.SetMask(true)
    self.ChangeCardAlphaTimer = XUiHelper.DoAlpha(self.BtnCardCanvaGroup, EndAlpha, StartAlpha, TweenSpeed, XUiHelper.EaseType.Sin, function ()
            XLuaUiManager.SetMask(false)
            self.ChangeCardAlphaTimer = nil
            self.Transform.localPosition = tagPos
            self.BtnCardCanvaGroup.alpha = EndAlpha
            self:SetCardNum(newCard)
            self:SetCardState(XMaintainerActionConfigs.CardState.Normal)
            if cb then cb() end
        end)
end

function XUiGridCard:GetCard()
    local posId = self.Base.UsedCardPosId
    if self.CurPosId > posId then
        local tagPos = self.Base.CardPos[self.CurPosId - 1]
        self.CurPosId = self.CurPosId - 1
        XLuaUiManager.SetMask(true)
        self.GetCardMoveTimer = XUiHelper.DoMove(self.Transform, tagPos, TweenSpeed, XUiHelper.EaseType.Sin, function ()
                XLuaUiManager.SetMask(false)
                self.GetCardMoveTimer = nil
            end)
    end
end

function XUiGridCard:StopTween()
    if self.UseCardAlphaTimer then
        XScheduleManager.UnSchedule(self.UseCardAlphaTimer)
        XLuaUiManager.SetMask(false)
        self.UseCardAlphaTimer = nil
    end
    if self.ChangeCardAlphaTimer then
        XScheduleManager.UnSchedule(self.ChangeCardAlphaTimer)
        XLuaUiManager.SetMask(false)
        self.ChangeCardAlphaTimer = nil
    end
    if self.GetCardMoveTimer then
        XScheduleManager.UnSchedule(self.GetCardMoveTimer)
        XLuaUiManager.SetMask(false)
        self.GetCardMoveTimer = nil
    end
end

return XUiGridCard