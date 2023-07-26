-- Rpg玩法队伍结算界面经验面板控件
local XUiRpgTowerSettleWinExpBar = XClass(nil, "XUiRpgTowerSettleWinExpBar")
local FILL_SPEED = 1
local CSTime = CS.UnityEngine.Time
local MathfLerp = CS.UnityEngine.Mathf.Lerp

function XUiRpgTowerSettleWinExpBar:Ctor(uiGameObject, rootUi)
    XTool.InitUiObjectByUi(self, uiGameObject)
    self.RootUi = rootUi
end

function XUiRpgTowerSettleWinExpBar:StartRun(expChangeData)
    self:SetChangeData(expChangeData)
end

function XUiRpgTowerSettleWinExpBar:StartFillExp()
    self.StartFillTime = 0
    self.ImgPlayerExpFillAdd.fillAmount = 0
    self.TimeId = XScheduleManager.ScheduleForever(function()
                if XTool.UObjIsNil(self.Transform) then
                    self:StopTimer()
                    return
                end
                self:LerpExp()
            end, 0)
end

function XUiRpgTowerSettleWinExpBar:SetChangeData(changeData)
    local TeamExpNewChange = changeData.TeamExpNewChange
    local PreTeamExp = changeData.PreTeamExp
    local PreTeamLevel = changeData.PreTeamLevel
    local preLevelCfg = XRpgTowerConfig.GetTeamLevelCfgByLevel(PreTeamLevel)
    local TeamExp = changeData.TeamExp
    local TeamLevel = changeData.TeamLevel
    local curLevelCfg = XRpgTowerConfig.GetTeamLevelCfgByLevel(TeamLevel)
    local ChangeExp = changeData.ChangeExp
    local maxLevel = XDataCenter.RpgTowerManager.GetMaxLevel()

    if TeamExpNewChange and PreTeamLevel ~= maxLevel then
        self.PlayLevelUpCount = TeamLevel - PreTeamLevel
        self.BeginFillAmount = PreTeamExp / preLevelCfg.Exp
        self.TargetFillAmount = TeamExp / curLevelCfg.Exp
        self.ToMaxLevel = TeamLevel == maxLevel
        self.TxtPlayerLevel.text = tostring(PreTeamLevel)
        self.CurrentLevel = PreTeamLevel
        self.TxtPlayerExp.text = "+ " .. tostring(ChangeExp)
        self.DoingLevelUp = self.PlayLevelUpCount > 0
        self:StartFillExp()
    else
        if TeamLevel == maxLevel then
            self.ImgPlayerExpFill.fillAmount = 1
            self.TxtPlayerLevel.text = "MAX"
        else
            self.ImgPlayerExpFill.fillAmount = TeamExp / curLevelCfg.Exp
            self.TxtPlayerLevel.text = TeamLevel
        end
        self.ImgPlayerExpFillAdd.fillAmount = 0
        self.TxtPlayerExp.text = "+ 0"
    end

end

function XUiRpgTowerSettleWinExpBar:LerpExp()
    local lerpPercent = self.StartFillTime * FILL_SPEED
    self.StartFillTime = self.StartFillTime + CSTime.deltaTime
    if lerpPercent >= 1 then lerpPercent = 1 end
    if self.PlayLevelUpCount > 0 then
        self.ImgPlayerExpFill.fillAmount = MathfLerp(self.BeginFillAmount, 1, lerpPercent)
        if lerpPercent >= 1 then
            self.PlayLevelUpCount = self.PlayLevelUpCount - 1
            self.StartFillTime = 0
            self.BeginFillAmount = 0
            self.TxtPlayerLevel.text = self.CurrentLevel + 1
            self.CurrentLevel = self.CurrentLevel + 1
            if self.PlayLevelUpCount == 0 then
                self.ImgPlayerExpFillAdd.fillAmount = self.TargetFillAmount
            end
        end
    else
        if not self.ToMaxLevel then
            self.ImgPlayerExpFill.fillAmount = MathfLerp(self.BeginFillAmount, self.TargetFillAmount, lerpPercent)
            if lerpPercent >= 1 then
                self:StopTimer()
                if self.DoingLevelUp then
                    self.DoingLevelUp = false
                    self:ShowLevelUpTips()
                end
            end
        else
            self.ImgPlayerExpFill.fillAmount = 1
            self.ImgPlayerExpFillAdd.fillAmount = 0
            self.TxtPlayerLevel.text = "MAX"
            self:StopTimer()
        end
    end
end

function XUiRpgTowerSettleWinExpBar:StopTimer()
    if not self.TimerId then return end
    XScheduleManager.UnSchedule(self.TimerId)
    self.TimerId = nil
end

function XUiRpgTowerSettleWinExpBar:ShowLevelUpTips()
    XLuaUiManager.Open("UiRpgTowerLevelUp")
end

return XUiRpgTowerSettleWinExpBar