local XMovieActionLeftTitleAppear = XClass(XMovieActionBase, "XMovieActionLeftTitleAppear")

function XMovieActionLeftTitleAppear:Ctor(actionData)
    local params = actionData.Params

    self.Title = params[1] or ""
    self.Subtitle = params[2] or ""
    self.TitleEn = params[3] or ""
end

function XMovieActionLeftTitleAppear:OnRunning()
    self.UiRoot.PanelLeftTitle.gameObject:SetActiveEx(true)
    local uiObj = self.UiRoot.PanelLocationTip
    uiObj:GetObject("TxtTitle").text = self.Title
    uiObj:GetObject("TxtDesc").text = self.Subtitle
    uiObj:GetObject("TxtSecondDesc").text = self.TitleEn
    uiObj:GetObject("AnimEnable").gameObject:PlayTimelineAnimation()
end

return XMovieActionLeftTitleAppear