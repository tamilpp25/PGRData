local XMovieActionDelaySkip = XClass(XMovieActionBase, "XMovieActionDelaySkip")

function XMovieActionDelaySkip:Ctor(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber

    self.DelaySelectKey = paramToNumber(params[1])
end

function XMovieActionDelaySkip:GetDelaySelectActionId()
    return XDataCenter.MovieManager.GetDelaySelectActionId(self.DelaySelectKey)
end

return XMovieActionDelaySkip