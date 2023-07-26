local XUiFubenMaverickPatternGrid = XClass(nil, "XUiFubenMaverickPatternGrid")

function XUiFubenMaverickPatternGrid:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
end

function XUiFubenMaverickPatternGrid:Refresh(patternId)
    self.PatternId = patternId or self.PatternId
    self.PatternName = XDataCenter.MaverickManager.GetPatternName(self.PatternId)
    local isEnd, isNotStart, remainStartTime = XDataCenter.MaverickManager.IsPatternEnd(self.PatternId)
    self.RemainStartTime = remainStartTime
    if isNotStart then
        self.IsLocked = true
        self.IsNotStart = true
        self.LeftStartTime = 
        self.GridChapter:SetDisable(true)
        self.RemainStartTime = XUiHelper.GetTime(self.RemainStartTime, XUiHelper.TimeFormatType.ACTIVITY)
        self.TxtCondition.text = CsXTextManagerGetText("MaverickPatternTimeCondition", self.RemainStartTime)
    elseif isEnd then
        self.IsLocked = true
        self.IsNotStart = false
        self.GridChapter:SetDisable(true)
        self.TxtCondition.text = CsXTextManagerGetText("MaverickPatternEnd", self.PatternName)
    else
        self.IsLocked = false
        self.IsNotStart = false
        self.GridChapter:SetDisable(false)
        self.GridChapter:SetNameByGroup(0, self.PatternName)
        self.GridChapter:SetNameByGroup(1, XDataCenter.MaverickManager.GetPatternProgressStr(self.PatternId))
        self.GridChapter:SetRawImage(XDataCenter.MaverickManager.GetPatternImagePath(self.PatternId))
    end

    XRedPointManager.CheckOnce(self.OnCheckRedDot, self, { XRedPointConditions.Types.CONDITION_MAVERICK_PATTERN }, self.PatternId)
end

function XUiFubenMaverickPatternGrid:OnCheckRedDot(count)
    self.GridChapter:ShowReddot(count >= 0)
end

return XUiFubenMaverickPatternGrid