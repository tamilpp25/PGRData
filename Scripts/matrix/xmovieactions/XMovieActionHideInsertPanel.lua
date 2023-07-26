local XMovieActionHideInsertPanel = XClass(XMovieActionBase,"XMovieActionHideInsertPanel")

function XMovieActionHideInsertPanel:Ctor(actionData)
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber
    self.Direction = paramToNumber(actionData.Params[1])
    self.BgPath = actionData.Params[2]
end

function XMovieActionHideInsertPanel:OnRunning()
    if self.BgPath then
        self.UiRoot:SetInsertPanelBg(self.BgPath,self.Direction)
    end
    self.UiRoot:PlayInsertPanelDisableAnimation(self.Direction)
end

function XMovieActionHideInsertPanel:OnUndo()
    self.UiRoot:PlayInsertPanelEnableAnimation(self.Direction)
end

return XMovieActionHideInsertPanel