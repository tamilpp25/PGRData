local XMovieActionActorChangeFace = XClass(XMovieActionBase, "XMovieActionActorChangeFace")

function XMovieActionActorChangeFace:Ctor(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber

    local actorIndex = paramToNumber(params[1])
    if actorIndex == 0 or actorIndex > XMovieConfigs.MAX_ACTOR_NUM then
        XLog.Error("XMovieActionActorChangeFace:Ctor error:ActorIndex is not match, actionId is " .. self.ActionId)
        return
    end
    self.ActorIndex = actorIndex

    self.FaceId = paramToNumber(params[2])
end

function XMovieActionActorChangeFace:OnRunning()
    local actor = self.UiRoot:GetActor(self.ActorIndex)
    actor:SetFace(self.FaceId)
end

function XMovieActionActorChangeFace:OnSkip()
    self:OnRunning()
end

return XMovieActionActorChangeFace