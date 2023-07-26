local XMovieActionSwitchMixMode = XClass(XMovieActionBase,"XMovieActionSwitchMixMode")

function XMovieActionSwitchMixMode:Ctor(actionData)
    
end

function XMovieActionSwitchMixMode:OnInit()
    self.UiRoot:SwitchMixPanel()
end

return XMovieActionSwitchMixMode