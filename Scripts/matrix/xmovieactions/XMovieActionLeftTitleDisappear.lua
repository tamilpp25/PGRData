local XMovieActionLeftTitleAppear = XClass(XMovieActionBase, "XMovieActionLeftTitleAppear")

function XMovieActionLeftTitleAppear:Ctor(actionData)
    local params = actionData.Params
end

function XMovieActionLeftTitleAppear:OnRunning()
    local uiObj = self.UiRoot.PanelLocationTip
    uiObj:GetObject("AnimDisable").gameObject:PlayTimelineAnimation(function()
        self.UiRoot.PanelLeftTitle.gameObject:SetActiveEx(false)
    end)
end

return XMovieActionLeftTitleAppear