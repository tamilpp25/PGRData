local XMovieActionInterrupt = XClass(XMovieActionBase, "XMovieActionInterrupt")

function XMovieActionInterrupt:Ctor(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber

    self.CueId = paramToNumber(params[1])
end

function XMovieActionInterrupt:OnRunning()
    XSoundManager.Stop(self.CueId)
end


return XMovieActionInterrupt