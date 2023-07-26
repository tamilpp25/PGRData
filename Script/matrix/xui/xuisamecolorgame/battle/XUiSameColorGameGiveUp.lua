local XUiSameColorGameGiveUp = XLuaUiManager.Register(XLuaUi, "UiSameColorGameGiveUp")
local CSTextManagerGetText = CS.XTextManager.GetText
function XUiSameColorGameGiveUp:OnStart(boss, rePlayCb, backCb)
    self.Boss = boss
    self.RePlayCb = rePlayCb
    self.BackCb = backCb
    self.BattleManager = XDataCenter.SameColorActivityManager.GetBattleManager()
    self:SetButtonCallBack()
end

function XUiSameColorGameGiveUp:OnEnable()
    self:UpdateSkill()
end

function XUiSameColorGameGiveUp:UpdateSkill()
    local isRoundType = self.Boss:IsRoundType()
    self.TxtStep.gameObject:SetActiveEx(isRoundType)
    if isRoundType then
        local step = self.BattleManager:GetBattleStep(self.Boss)
        self.TxtStep.text = CSTextManagerGetText("SCStepText", step)
    end

    local damage = self.BattleManager:GetDamageCount() or 0
    self.TxtDamage.text = CSTextManagerGetText("SCDamageText", damage)
    self.RankIcon:SetRawImage(self.Boss:GetCurGradeIcon(damage))
end

function XUiSameColorGameGiveUp:SetButtonCallBack()
    self.BtnRePlay.CallBack = function() self:OnBtnRePlayClick() end
    self.BtnExit.CallBack = function() self:OnBtnExitClick() end
    self.BtnClose.CallBack = function() self:Close() end
end

function XUiSameColorGameGiveUp:OnBtnRePlayClick()
    self:Close()
    XScheduleManager.ScheduleOnce(function()
            if self.RePlayCb then self.RePlayCb() end
        end, 1)

end

function XUiSameColorGameGiveUp:OnBtnExitClick()
    self:Close()
    XScheduleManager.ScheduleOnce(function()
            XDataCenter.SameColorActivityManager.RequestGiveUp(self.Boss:GetId())
            if self.BackCb then self.BackCb() end
        end, 1)
end