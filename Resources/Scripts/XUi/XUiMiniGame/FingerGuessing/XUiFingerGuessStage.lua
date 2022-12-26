-- 猜拳小游戏关卡组件
local XUiFingerGuessStage = XClass(nil, "XUiFingerGuessStage")

function XUiFingerGuessStage:Ctor(gameObject, stage, rootUi)
    XTool.InitUiObjectByUi(self, gameObject)
    self.RootUi = rootUi
    self:InitPanel(stage)
end

function XUiFingerGuessStage:InitPanel(stage)
    if not stage then return end
    self.Stage = stage
    local isOpen = self.Stage:GetIsOpen()
    self.PanelLock.gameObject:SetActiveEx(not isOpen)
    self.PanelUnLock.gameObject:SetActiveEx(isOpen)
    self.ImgEnemyIcon:SetSprite(self.Stage:GetRobotPortraits())
    self.ObjWinIcon.gameObject:SetActiveEx(self.Stage:GetIsClear())
    self.TxtEnemyName.text = self.Stage:GetStageName()
    self.TxtLockEnemyName.text = self.Stage:GetLockStageName()
    self.RImgLockEnemyIcon:SetRawImage(self.Stage:GetStageLockRobotPortraits())
    self.BtnStageSelect.CallBack = function() self:OnClickStageSelect() end
end

function XUiFingerGuessStage:OnClickStageSelect()
    if not self.Stage:GetIsOpen() then
        XUiManager.TipMsg(CS.XTextManager.GetText("FingerGuessingStageNotOpen"))
        return
    end
    self.BtnStageSelect:SetButtonState(CS.UiButtonState.Select)
    self.RootUi:OnStageSelected(self, self.Stage)
end

function XUiFingerGuessStage:OnOtherStageSelect()
    self.BtnStageSelect:SetButtonState(CS.UiButtonState.Normal)
end

return XUiFingerGuessStage