local XMovieActionTheme = XClass(XMovieActionBase, "XMovieActionTheme")

function XMovieActionTheme:Ctor(actionData)
    local params = actionData.Params

    self.Title = params[1]
    self.Content = params[2]
    self.LogoPath = params[3]
end

function XMovieActionTheme:OnInit()
    self.UiRoot.TxtTitle.text = self.Title
    self.UiRoot.TxtContent.text = self.Content
    self.UiRoot:SetUiSprite(self.UiRoot.ImgLogo, self.LogoPath)
    self.UiRoot.PanelTheme.gameObject:SetActiveEx(true)
end

function XMovieActionTheme:OnExit()
    -- self.UiRoot.PanelTheme.gameObject:SetActiveEx(false)
end

return XMovieActionTheme