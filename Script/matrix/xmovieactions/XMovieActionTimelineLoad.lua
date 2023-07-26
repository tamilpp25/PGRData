local XMovieActionTimelineLoad = XClass(XMovieActionBase,"XMovieActionTimelineLoad")

function XMovieActionTimelineLoad:Ctor(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber
    self.TimelinePath = params[1]
    self.TimelineName = params[2]
    local position = string.Split(params[3],"|")
    local rotation = string.Split(params[4],"|")
    self.Position = CS.UnityEngine.Vector3(paramToNumber(position[1]),paramToNumber(position[2]),paramToNumber(position[3]))
    self.Rotation = CS.UnityEngine.Vector3(paramToNumber(rotation[1]),paramToNumber(rotation[2]),paramToNumber(rotation[3]))
end

function XMovieActionTimelineLoad:OnInit()
    self.UiRoot:AddTimeline(self.TimelinePath,self.TimelineName,self.Position,self.Rotation)
end

return XMovieActionTimelineLoad