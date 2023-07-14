local XMovieActionPlayCV = XClass(XMovieActionBase,"XMovieActionPlayCV")

function XMovieActionPlayCV:Ctor(actionData)
    local params = actionData.Params
    self.RoleId = params[1]
    self.CueId = XDataCenter.MovieManager.ParamToNumber(params[2])
end

function XMovieActionPlayCV:OnInit()
    local role = self.UiRoot:GetModelActor(self.RoleId)
    self.AudioInfo = role:PlayCV(self.CueId)
end

function XMovieActionPlayCV:OnDestroy()
    if self.AudioInfo then
        self.AudioInfo:Stop()
        self.AudioInfo = nil
    end
end

return XMovieActionPlayCV