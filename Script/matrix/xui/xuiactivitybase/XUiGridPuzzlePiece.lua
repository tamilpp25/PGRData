local XUiGridPuzzlePiece = XClass(nil, "XUiGridPuzzlePiece")

function XUiGridPuzzlePiece:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self.GameObject:SetActiveEx(true)
    self:SetButtonCallBack()
    self.LastState = XPuzzleActivityConfigs.PuzzleCondition.Activated
    self.EffectHint.gameObject:SetActiveEx(false)
    self.EffectFlip.gameObject:SetActiveEx(false)
end

function XUiGridPuzzlePiece:OnDestroy()
end

function XUiGridPuzzlePiece:RemoveTimer()
    if self.OpenTimer then
        XScheduleManager.UnSchedule(self.OpenTimer)
        self.OpenTimer = nil
    end
    if self.CloseTimer then
        XScheduleManager.UnSchedule(self.CloseTimer)
        self.CloseTimer = nil
    end
end

function XUiGridPuzzlePiece:SetButtonCallBack()
    self.Btn.CallBack = function()
        self:OnBtnActiveClick()
    end
end

function XUiGridPuzzlePiece:OnBtnActiveClick()
    if self.State ~= XPuzzleActivityConfigs.PuzzleRewardState.CanReward then
        if self.State == XPuzzleActivityConfigs.PuzzleRewardState.Unrewarded then
            XUiManager.TipText("ActivityPuzzleNoItem")
        end
        return
    end
    XDataCenter.PuzzleActivityManager.PuzzleActivityFlipPieceRequest(self.PuzzleId, self.Index)
end

function XUiGridPuzzlePiece:Refresh()
    self.State = XDataCenter.PuzzleActivityManager.GetPuzzleActPieceData(self.PuzzleId ,self.Index)
    if self.State ~= self.LastState then
        if self.State == XPuzzleActivityConfigs.PuzzleCondition.NotCollected then
            -- do nothing
        elseif self.State == XPuzzleActivityConfigs.PuzzleCondition.Inactivated then
            self.EffectHint.gameObject:SetActiveEx(true)
        elseif self.State == XPuzzleActivityConfigs.PuzzleCondition.Activated then
            self:ShowFlipEffect()
        end
    end
    if self.State == XPuzzleActivityConfigs.PuzzleCondition.Activated  then
        self.Btn:SetButtonState(CS.UiButtonState.Disable)
    end
    self.LastState = self.State
end

function XUiGridPuzzlePiece:ShowFlipEffect()
    self:RemoveTimer()
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.Common_UiObtain)
    self.OpenTimer = XScheduleManager.ScheduleOnce(function()
        self.EffectFlip.gameObject:SetActiveEx(true)
    end, 20)
    self.CloseTimer = XScheduleManager.ScheduleOnce(function()
        self.EffectFlip.gameObject:SetActiveEx(false)
    end, 1500)
end

function XUiGridPuzzlePiece:Init(puzzleId, index)
    self.PuzzleId = puzzleId
    self.Index = index    
    self.PieceTemplate = XDataCenter.PuzzleActivityManager.GetPieceTemplate(puzzleId, index)
    self.Btn:SetRawImage(self.PieceTemplate.CoverImage)
end

return XUiGridPuzzlePiece