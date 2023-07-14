local XUiGrid3DMapStage = XClass(nil, "XUiGrid3DMapStage")
local CSTextManagerGetText = CS.XTextManager.GetText
function XUiGrid3DMapStage:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
    self.IsSelect = false
    self.IsFirstShow = true
    self.Effect.gameObject:SetActiveEx(false)
end

function XUiGrid3DMapStage:SetButtonCallBack()
    self.BtnClick.CallBack = function()
        self:OnBtnClick()
    end
end

function XUiGrid3DMapStage:OnBtnClick()
    if not self.STStage:CheckStageIsOpen() then
        XUiManager.TipMsg(self:GetUnLockDesc(true))
        return
    end

    self:DoSelect(true)
    local uiName = self.STStage:CheckIsSingleTeamOneWave() and "UiSuperTowerSingleStageDetail" or "UiSuperTowerMultiStageDetail"
    XLuaUiManager.Open(uiName, self.STStage, self.ThemeIndex, function ()
            self:DoSelect(false)
        end)
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_ST_MAP_THEME_SELECT, self.ThemeIndex, self.StageIndex)
end

function XUiGrid3DMapStage:UpdateGrid(stTheme, stStage, themeIndex, stageIndex, IsCurrent, IsCurrentLock)
    self.STTheme = stTheme
    self.STStage = stStage
    self.ThemeIndex = themeIndex
    self.StageIndex = stageIndex
    self.IsCurrent = IsCurrent
    self.IsCurrentLock = IsCurrentLock
    self:UpdateInfo()
    self:UpdateEffect()
end

function XUiGrid3DMapStage:UpdateInfo()
    self.TxtName.text = self.STStage:GetSimpleName()
    self.TxtProgress.text = CSTextManagerGetText("STStageProgress", self.STStage:GetProgressStr())
    self.TxtLockDesc.text = self:GetUnLockDesc(false)

    self.ImgClear.gameObject:SetActiveEx(self.STStage:CheckIsClear())
    self.TxtLockDesc.gameObject:SetActiveEx(not self.STStage:CheckStageIsOpen() and self.IsCurrentLock)
    
    self.TxtProgress.gameObject:SetActiveEx(self.STStage:CheckIsMultiWave() and 
        not self.STStage:CheckIsClear() 
        and self.STStage:CheckStageIsOpen())
end

function XUiGrid3DMapStage:UpdateEffect()
    local effectPath
    local IsSp = self.StageIndex > 5
    if self.STStage:CheckStageIsOpen() then
        if self.IsSelect then
            effectPath = self.STTheme:GetStageSelectEffect(IsSp)
        else
            if self.IsCurrent then
                effectPath = self.STTheme:GetStageCurrentEffect(IsSp)
            else
                effectPath = self.STTheme:GetStageUnLockEffect(IsSp)
            end
        end
    else
        effectPath = self.STTheme:GetStageLockEffect(IsSp)
    end
    
    self.Effect.gameObject:LoadPrefab(effectPath)
end

function XUiGrid3DMapStage:GetUnLockDesc(IsFullTime)
    if not self.STStage:CheckIsInTime() then
        return CSTextManagerGetText("STThemeUnlock", self.STStage:GetStartTimeStr(IsFullTime))
    end

    if not self.STStage:CheckStagePreCondition() then
        
        if self.STStage:GetPreStageType() == XDataCenter.SuperTowerManager.StageType.SingleTeamMultiWave or
            self.STStage:GetPreStageType() == XDataCenter.SuperTowerManager.StageType.MultiTeamMultiWave then
            return CSTextManagerGetText("STMultiWavePreUnlock", self.STStage:GetPreStageSimpleName(), self.STStage:GetPreStageProgress())
        else
            return CSTextManagerGetText("STSingleWavePreUnlock", self.STStage:GetPreStageSimpleName())
        end

    end
    return ""
end

function XUiGrid3DMapStage:DoSelect(IsSelect)
    self.IsSelect = IsSelect
    self.IsFirstShow = not IsSelect
    self:UpdateEffect()
end

function XUiGrid3DMapStage:ShowEffect(IsShow)  
    if self.IsFirstShow and IsShow then
        self:StopTimer()
        self.Timer = XScheduleManager.ScheduleOnce(function()
                self.Effect.gameObject:SetActiveEx(true)
        end, XScheduleManager.SECOND / 10 * self.StageIndex)
    else
        self.Effect.gameObject:SetActiveEx(IsShow)
    end
end

function XUiGrid3DMapStage:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

return XUiGrid3DMapStage