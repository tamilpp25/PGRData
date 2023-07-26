local XMovieActionModelMove = XClass(XMovieActionBase,"XMovieActionModelMove")

function XMovieActionModelMove:Ctor(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber
    self.RoleId = params[1]
    self.Animation = params[2]
    local pos = string.Split(params[3], "|")
    self.Speed = paramToNumber(params[4])
    self.TargetPosition = CS.UnityEngine.Vector3(paramToNumber(pos[1]), paramToNumber(pos[2]), paramToNumber(pos[3]))
end

function XMovieActionModelMove:IsBlock()
    return true
end

function XMovieActionModelMove:OnRunning()
    ---@type Movie.XMovie3DRole
    local actor = self.UiRoot:GetModelActor(self.RoleId)
    actor:MoveTo(self.TargetPosition,self.Speed,self.Animation,function() self:OnMoveEnd() end)
end

function XMovieActionModelMove:OnMoveEnd()
    --todo aafasou 支持多人移动
    XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_BREAK_BLOCK)

end

return XMovieActionModelMove