local XMovieActionSpineActorChangeAnim = XClass(XMovieActionBase, "XMovieActionSpineActorChangeAnim")

function XMovieActionSpineActorChangeAnim:Ctor(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber

    local actorIndex = paramToNumber(params[1])
    if actorIndex == 0 or actorIndex > XMovieConfigs.MAX_SPINE_ACTOR_NUM then
        XLog.Error("XMovieActionSpineActorChangeAnim:Ctor error:ActorIndex is not match, actionId is " .. self.ActionId)
        return
    end
    self.ActorIndex = actorIndex

    self.AnimId = paramToNumber(params[2])
    self.TransitionAnimId = paramToNumber(params[3])
end

function XMovieActionSpineActorChangeAnim:OnRunning()
    local actor = self.UiRoot:GetSpineActor(self.ActorIndex)
    actor:PlayAnim(self.AnimId, self.TransitionAnimId)
end

return XMovieActionSpineActorChangeAnim