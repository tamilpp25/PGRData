local XUiSameColorGameSettlement = XLuaUiManager.Register(XLuaUi, "UiSameColorGameSettlement")
local CSTextManagerGetText = CS.XTextManager.GetText
function XUiSameColorGameSettlement:OnStart(boss, rePlayCb, backCb)
    self.Boss = boss
    self.RePlayCb = rePlayCb
    self.BackCb = backCb
    self.BattleManager = XDataCenter.SameColorActivityManager.GetBattleManager()
    self:SetButtonCallBack()
end

function XUiSameColorGameSettlement:OnEnable()
    self:UpdateSkill()
end

function XUiSameColorGameSettlement:UpdateSkill()
    local damage = self.BattleManager:GetDamageCount()
    local nextRank, needDamage = self.Boss:GetScoreNextGradeNameAndDamageGap(damage)
    
    self.NewRecord.gameObject:SetActiveEx( damage > self.Boss:GetMaxScore())
    
    self.DamageText.text = CSTextManagerGetText("SCWinDamageText", damage)
    
    self.RankText.text = CSTextManagerGetText("SCWinRankText", nextRank, needDamage)
    
    self.RankText.gameObject:SetActiveEx(needDamage > 0)
    
    self.RankIcon:SetRawImage(self.Boss:GetCurGradeIcon(damage))
end

function XUiSameColorGameSettlement:SetButtonCallBack()
    self.BtnRePlay.CallBack = function() self:OnBtnRePlayClick() end
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
end

function XUiSameColorGameSettlement:OnBtnRePlayClick()
    self:Close()
    XScheduleManager.ScheduleOnce(function()
            if self.RePlayCb then self.RePlayCb() end
        end, 1)
    
end

function XUiSameColorGameSettlement:OnBtnBackClick()
    self:Close()
    XScheduleManager.ScheduleOnce(function()
            if self.BackCb then self.BackCb() end
        end, 1)
end