local XUiGridExpeditionStage = XClass(nil, "XUiGridExpeditionStage")

function XUiGridExpeditionStage:Ctor(ui, rootUi, cb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.ClickCb = cb
    XTool.InitUiObject(self)
    
    self:SetStageSelect(false)
    self:RegisterUiEvents()
end

function XUiGridExpeditionStage:Refresh(stageId)
    self.StageId = stageId
    -- 刷新基本信息
    self:RefreshStageData(stageId)
    -- 刷新关卡状态
    self:RefreshStageState(stageId)
end

function XUiGridExpeditionStage:RefreshStageData(stageId)
    local eStage = XDataCenter.ExpeditionManager.GetEStageByStageId(stageId)
    local stageCfg = eStage:GetStageCfg()
    -- 关卡名称
    if self.TxtNameNor then
        local name = eStage:GetIsInfinity() and CSXTextManagerGetText("ExpeditionNormalNameFontColor", stageCfg.Name) or stageCfg.Name
        self.TxtNameNor.text = name
    end
    if self.TxtNameLock then
        self.TxtNameLock.text = stageCfg.Name
    end
    -- 关卡简述
    if self.TxtDifficulty then
        self.TxtDifficulty.text = eStage:GetStageDes()
    end
    -- 图标
    if self.ImgStage then
        self.ImgStage:SetRawImage(stageCfg.Icon)
    end
    -- 通关标志
    if self.CommonFuBenClear then
        self.CommonFuBenClear.gameObject:SetActiveEx(eStage:GetIsPass())
    end
    -- boss图标
    if self.ImgBoss then
        self.ImgBoss:SetRawImage(eStage:GetStageCover())
    end
    -- 无尽关积分
    if self.TxtWave then
        local wave = XDataCenter.ExpeditionManager.GetWave(stageId)
        self.TxtWave.text = eStage:GetIsInfinity() and CSXTextManagerGetText("ExpeditionNormalTierFontColor", wave) or wave
    end
    -- 关卡警告等级
    if eStage:GetStageType() == XExpeditionConfig.StageType.Battle then
        local warning = eStage:GetStageIsDanger()
        self.IconYellow.gameObject:SetActiveEx(warning == XDataCenter.ExpeditionManager.StageWarning.Warning)
        self.IconRed.gameObject:SetActiveEx(warning == XDataCenter.ExpeditionManager.StageWarning.Danger)
    else
        self.IconYellow.gameObject:SetActiveEx(false)
        self.IconRed.gameObject:SetActiveEx(false)
    end
end

function XUiGridExpeditionStage:RefreshStageState(stageId)
    -- 是否在开启时间内
    local eActivity = XDataCenter.ExpeditionManager.GetEActivity()
    local chapter = eActivity:GetEChapterByStageId(stageId)
    self.TimeId = chapter:GetChapterTimeId()
    local isInTime = XFunctionManager.CheckInTimeByTimeId(self.TimeId)
    self:ActiveStageState(isInTime)
    if not isInTime then
        self:StartTime() -- 开始倒计时
    end
end

function XUiGridExpeditionStage:ActiveStageState(isActive)
    if self.PanelNor then
        self.PanelNor.gameObject:SetActiveEx(isActive)
    end
    if self.PanelLock then
        self.PanelLock.gameObject:SetActiveEx(not isActive)
    end
end

function XUiGridExpeditionStage:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnStage, self.OnBtnStage)
end

function XUiGridExpeditionStage:OnBtnStage()
    if not XFunctionManager.CheckInTimeByTimeId(self.TimeId) then
        XUiManager.TipText("ExpeditionStageNotOpenTip")
        return
    end
    
    if self.ClickCb then
        self.ClickCb(self)
    end
end

--- 是否显示选中框
function XUiGridExpeditionStage:SetStageSelect(isSelect)
    if self.ImgSelect then
        self.ImgSelect.gameObject:SetActiveEx(isSelect)
    end
end

function XUiGridExpeditionStage:OnDisable()
    self:StopTime()
end

--region 剩余时间

function XUiGridExpeditionStage:StartTime()
    if self.Timer then
        self:StopTime()
    end

    self:UpdateTime()
    self.Timer = XScheduleManager.ScheduleForever(function()
        self:UpdateTime()
    end, XScheduleManager.SECOND)
end

function XUiGridExpeditionStage:UpdateTime()
    if XTool.UObjIsNil(self.TxtTime) then
        self:StopTime()
        return
    end

    local startTime = XFunctionManager.GetStartTimeByTimeId(self.TimeId)
    local now = XTime.GetServerNowTimestamp()
    if now >= startTime then
        self:StopTime()
        self:ActiveStageState(true)
        return
    end

    local timeText = XUiHelper.GetTime(startTime - now, XUiHelper.TimeFormatType.DAY_HOUR)
    self.TxtTime.text = timeText
end

function XUiGridExpeditionStage:StopTime()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

--endregion

return XUiGridExpeditionStage