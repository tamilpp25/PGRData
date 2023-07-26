local XMovieActionSpineActorAnimationPlay = XClass(XMovieActionBase, "XMovieActionSpineActorAnimationPlay")

function XMovieActionSpineActorAnimationPlay:Ctor(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber

    local actorIndex = paramToNumber(params[1])
    if actorIndex == 0 or actorIndex > XMovieConfigs.MAX_SPINE_ACTOR_NUM then
        XLog.Error("XMovieActionSpineActorAnimationPlay:Ctor error:ActorIndex is not match, actionId is " .. self.ActionId)
        return
    end
    self.ActorIndex = actorIndex
    self.AnimName = params[2]
end

function XMovieActionSpineActorAnimationPlay:OnRunning()
    local actor = self.UiRoot:GetSpineActor(self.ActorIndex)
    actor:PlayUiAnimation(self.AnimName)
end

return XMovieActionSpineActorAnimationPlay