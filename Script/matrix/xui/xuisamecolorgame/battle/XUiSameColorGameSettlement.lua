---@class XUiSameColorGameSettlement:XLuaUi
local XUiSameColorGameSettlement = XLuaUiManager.Register(XLuaUi, "UiSameColorGameSettlement")
function XUiSameColorGameSettlement:OnStart(boss, rePlayCb, backCb)
    self.Boss = boss
    self.RePlayCb = rePlayCb
    self.BackCb = backCb
    self.BattleManager = XDataCenter.SameColorActivityManager.GetBattleManager()
    self:SetButtonCallBack()
end

function XUiSameColorGameSettlement:OnEnable()
    self:UpdatePanel()
end

function XUiSameColorGameSettlement:UpdatePanel()
    local damage = self.BattleManager:GetDamageCount()
    self.DamageText.text = XUiHelper.GetText("SCWinDamageText", damage)
    self.NewRecord.gameObject:SetActiveEx( damage > self.Boss:GetMaxScore())
    
    local maxComboCount = self.BattleManager:GetMaxComboCount()
    self.ComboText.text = XUiHelper.GetText("SCWinComboText", maxComboCount)
    self.NewRecord2.gameObject:SetActiveEx(maxComboCount > self.Boss:GetMaxCombo())

    self.RankIcon:SetRawImage(self.Boss:GetCurGradeIcon(damage))
end

function XUiSameColorGameSettlement:SetButtonCallBack()
    self.BtnRePlay.CallBack = function() self:OnBtnRePlayClick() end
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnClose.CallBack = function() self:OnBtnBackClick() end
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