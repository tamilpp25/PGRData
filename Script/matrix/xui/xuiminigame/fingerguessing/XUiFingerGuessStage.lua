-- 猜拳小游戏关卡组件
---@class XUiFingerGuessStage
---@field BtnStageSelect XUiComponent.XUiButton
local XUiFingerGuessStage = XClass(nil, "XUiFingerGuessStage")

function XUiFingerGuessStage:Ctor(gameObject, stage, rootUi)
    XTool.InitUiObjectByUi(self, gameObject)
    self.RootUi = rootUi
    self:InitPanel(stage)
end

function XUiFingerGuessStage:InitPanel(stage)
    if not stage then return end
    self.Stage = stage
    self.BtnStageSelect:SetSprite(self.Stage:GetRobotPortraits())
    self.BtnStageSelect:SetRawImage(self.Stage:GetStageLockRobotPortraits())
    self.BtnStageSelect:SetNameByGroup(0, self.Stage:GetStageName())
    self.BtnStageSelect:SetNameByGroup(1, self.Stage:GetLockStageName())
    self.BtnStageSelect:ShowTag(self.Stage:GetIsClear())
    local isOpen = self.Stage:GetIsOpen()
    self.BtnStageSelect:SetButtonState(isOpen and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
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