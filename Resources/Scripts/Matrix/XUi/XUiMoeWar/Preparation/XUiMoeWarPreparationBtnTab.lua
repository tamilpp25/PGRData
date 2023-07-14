local TAB_BTN_TEXT_GROUP = {
    ["Title"] = 0,
    ["Time"] = 1,
    ["NumText"] = 2,
}

local MatchStatePercent = {
    [XMoeWarConfig.MatchState.NotOpen] = 0,
    [XMoeWarConfig.MatchState.Open] = 0.5,
    [XMoeWarConfig.MatchState.Over] = 1,
}

local XUiMoeWarPreparationBtnTab = XClass(nil, "XUiMoeWarPreparationBtnTab")

function XUiMoeWarPreparationBtnTab:Ctor(ui, matchId)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.BtnFirst = ui
    self.MatchId = matchId
    self:Init()
end

function XUiMoeWarPreparationBtnTab:Init()
    local tabBtnName = XMoeWarConfig.GetPreparationMatchName(self.MatchId)
    local numText = XMoeWarConfig.GetPreparationMatchNumText(self.MatchId)
    self.BtnFirst:SetNameByGroup(TAB_BTN_TEXT_GROUP["Title"], tabBtnName)
    self.BtnFirst:SetNameByGroup(TAB_BTN_TEXT_GROUP["NumText"], numText)
    self.GameObject:SetActiveEx(true)

    XUiHelper.RegisterClickEvent(self, self.BtnFirst, self.OnBtnFirstClick)
end

function XUiMoeWarPreparationBtnTab:Refresh()
    local timeId = XMoeWarConfig.GetPreparationMatchTimeId(self.MatchId)
    local startTime, endTime = XFunctionManager.GetTimeByTimeId(timeId)
    local timeStr = XUiHelper.GetInTimeDesc(startTime, endTime)
    self.BtnFirst:SetNameByGroup(TAB_BTN_TEXT_GROUP["Time"], timeStr)

    local matchState = XDataCenter.MoeWarManager.GetPreparationMatchOpenState(self.MatchId)
    self.Normal.gameObject:SetActiveEx(matchState == XMoeWarConfig.MatchState.Over)
    self.Select.gameObject:SetActiveEx(matchState == XMoeWarConfig.MatchState.Open)
    self.Disable.gameObject:SetActiveEx(matchState == XMoeWarConfig.MatchState.NotOpen)

    if self.ImgBar then
        self.ImgBar.fillAmount = MatchStatePercent[matchState]
    end
end

function XUiMoeWarPreparationBtnTab:OnBtnFirstClick()
    local matchState = XDataCenter.MoeWarManager.GetPreparationMatchOpenState(self.MatchId)
    if matchState == XMoeWarConfig.MatchState.Over then
        local tabBtnName = XMoeWarConfig.GetPreparationMatchName(self.MatchId)
        local timeUpDesc = CS.XTextManager.GetText("TimeUp")
        XUiManager.TipMsg(tabBtnName .. timeUpDesc)
    elseif matchState == XMoeWarConfig.MatchState.NotOpen then
        local timeId = XMoeWarConfig.GetPreparationMatchTimeId(self.MatchId)
        local startTime, endTime = XFunctionManager.GetTimeByTimeId(timeId)
        local timeStr = XUiHelper.GetInTimeDesc(startTime, endTime)
        XUiManager.TipMsg(timeStr)
    end
end

return XUiMoeWarPreparationBtnTab