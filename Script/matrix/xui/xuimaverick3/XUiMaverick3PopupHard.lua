---@class XUiMaverick3PopupHard : XLuaUi 孤胆枪手无尽挑战（后面改成界面 不是弹框）
---@field _Control XMaverick3Control
local XUiMaverick3PopupHard = XLuaUiManager.Register(XLuaUi, "UiMaverick3PopupHard")

function XUiMaverick3PopupHard:OnAwake()
    self.BtnClose.CallBack = handler(self, self.Close)
    self.BtnTanchuangClose.CallBack = handler(self, self.Close)
    self.BtnStage1.CallBack = handler(self, self.OnBtnStage1Click)
    self.BtnStage2.CallBack = handler(self, self.OnBtnStage2Click)
end

function XUiMaverick3PopupHard:OnStart()
    local chapter = self._Control:GetInfiniteChapter()
    local stages = self._Control:GetStagesByChapterId(chapter.ChapterId)
    self._Stage1Cfg = stages[1]
    self._Stage2Cfg = stages[2]

    self.TxtTitle1.text = self._Stage1Cfg.Name
    self.TxtTitle2.text = self._Stage2Cfg.Name
    
    local endTime = self._Control:GetActivityGameEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
            return
        end
        self:UpdateStageUnlock()
    end, nil, 0)
    XUiHelper.NewPanelTopControl(self, self.TopControlWhite)
    
    self._Control:CloseChapterRed(chapter.ChapterId)
end

function XUiMaverick3PopupHard:UpdateStageUnlock()
    local timeOfNow = XTime.GetServerNowTimestamp()
    if XFunctionManager.CheckInTimeByTimeId(self._Stage1Cfg.OpenTimeId, true) then
        self.BtnStage1:SetRawImageVisible(false)
        self._Stage1Unlock = true
        self._Stage1Id = self._Stage1Cfg.StageId
        local stage1Score = self._Control:GetInfiniteStageScore(self._Stage1Id)
        if XTool.IsNumberValid(stage1Score) then
            self.TxtNone1.gameObject:SetActiveEx(false)
            self.PanelBest1.gameObject:SetActiveEx(true)
            self.TxtNum1.gameObject:SetActiveEx(true)
            self.TxtNum1.text = stage1Score
        else
            self.TxtNone1.gameObject:SetActiveEx(true)
            self.PanelBest1.gameObject:SetActiveEx(false)
            self.TxtNum1.gameObject:SetActiveEx(false)
        end
    else
        self.TxtNum1.gameObject:SetActiveEx(false)
        self.TxtNone1.gameObject:SetActiveEx(false)
        self.BtnStage1:SetRawImageVisible(true)
        local timeOfStart = XFunctionManager.GetStartTimeByTimeId(self._Stage1Cfg.OpenTimeId)
        self._Stage1TimeDesc = XUiHelper.GetText("Maverick3HardTime", XUiHelper.GetTime(timeOfStart - timeOfNow, XUiHelper.TimeFormatType.ACTIVITY))
        self.BtnStage1:SetNameByGroup(0, self._Stage1TimeDesc)
        self._Stage1Unlock = false
    end
    
    if XFunctionManager.CheckInTimeByTimeId(self._Stage2Cfg.OpenTimeId, true) then
        self.BtnStage2:SetRawImageVisible(false)
        self._Stage2Unlock = true
        self._Stage2Id = self._Stage2Cfg.StageId
        local stage2Score = self._Control:GetInfiniteStageScore(self._Stage2Id)
        if XTool.IsNumberValid(stage2Score) then
            self.TxtNone2.gameObject:SetActiveEx(false)
            self.PanelBest2.gameObject:SetActiveEx(true)
            self.TxtNum2.gameObject:SetActiveEx(true)
            self.TxtNum2.text = stage2Score
        else
            self.TxtNone2.gameObject:SetActiveEx(true)
            self.PanelBest2.gameObject:SetActiveEx(false)
            self.TxtNum2.gameObject:SetActiveEx(false)
        end
    else
        self.TxtNum2.gameObject:SetActiveEx(false)
        self.TxtNone2.gameObject:SetActiveEx(false)
        self.BtnStage2:SetRawImageVisible(true)
        local timeOfStart = XFunctionManager.GetStartTimeByTimeId(self._Stage2Cfg.OpenTimeId)
        self._Stage2TimeDesc = XUiHelper.GetText("Maverick3HardTime", XUiHelper.GetTime(timeOfStart - timeOfNow, XUiHelper.TimeFormatType.ACTIVITY))
        self.BtnStage2:SetNameByGroup(0, self._Stage2TimeDesc)
        self._Stage2Unlock = false
    end
end

function XUiMaverick3PopupHard:OnBtnStage1Click()
    if self._Stage1Unlock then
        XLuaUiManager.Open("UiMaverick3Character", self._Stage1Id)
    else
        XUiManager.TipError(self._Stage1TimeDesc)
    end
end

function XUiMaverick3PopupHard:OnBtnStage2Click()
    if self._Stage2Unlock then
        XLuaUiManager.Open("UiMaverick3Character", self._Stage2Id)
    else
        XUiManager.TipError(self._Stage2TimeDesc)
    end
end

return XUiMaverick3PopupHard