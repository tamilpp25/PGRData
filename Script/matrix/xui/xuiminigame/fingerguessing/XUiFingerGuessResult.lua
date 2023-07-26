-- 猜拳小游戏得分结算界面
local XUiFingerGuessResult = XLuaUiManager.Register(XLuaUi, "UiFingerGuessingResult")
local SCORE_TYPE = {
    Hero = "Hero",
    Enemy = "Enemy",
}
function XUiFingerGuessResult:OnAwake()
    XTool.InitUiObject(self)
    self.GameController = XDataCenter.FingerGuessingManager.GetGameController()
end

function XUiFingerGuessResult:OnStart(stage, onCloseCallBack)
    self.Stage = stage
    self.CallBack = onCloseCallBack
    self:InitPanel()
end

function XUiFingerGuessResult:InitPanel()
    self.BtnClose.CallBack = function() self:OnClickBtnClose() end
    self:SetScore(self.Stage:GetHeroScore(), SCORE_TYPE.Hero)
    self:SetScore(self.Stage:GetEnemyScore(), SCORE_TYPE.Enemy)
    self.Result = self.Stage:GetHeroScore() >= self.Stage:GetEnemyScore()
    if self.TxtResultTalk then self.TxtResultTalk.text = self.Result and self.Stage:GetWinTalk() or self.Stage:GetLoseTalk() end

    self.ImgHeadframeWin.gameObject:SetActiveEx(self.Result)
    self.ImgHeadframeLose.gameObject:SetActiveEx(not self.Result)
    self.RImgBgWin.gameObject:SetActiveEx(self.Result)
    self.RImgBgLose.gameObject:SetActiveEx(not self.Result)
    self.RImgTxtWin.gameObject:SetActiveEx(self.Result)
    self.RImgTxtLose.gameObject:SetActiveEx(not self.Result)

    local roleIcon = self.Result and self.GameController:GetPlayerPortraits() or self.Stage:GetRobotPortraits()
    self.ImgRoleWin:SetSprite(roleIcon)
    self.ImgRoleLose:SetSprite(roleIcon)
end
--================
--设置分数
--================
function XUiFingerGuessResult:SetScore(score, setType)
    local name = "Txt" .. tostring(setType) .. "Score"
    local component = self[name]
    if component then
        component.text = string.format("%02d", score)
    end
end
--================
--点击关闭按钮
--================
function XUiFingerGuessResult:OnClickBtnClose()
    self:Close()
    if self.CallBack then
        local callBack = self.CallBack
        self.CallBack = nil
        callBack(self.Result)
    end
end