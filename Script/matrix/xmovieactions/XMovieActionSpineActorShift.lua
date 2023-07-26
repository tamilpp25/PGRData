local mathMax = math.max
local vector = CS.UnityEngine.Vector3
local LineAnimCurve = CS.UnityEngine.AnimationCurve.Linear(0, 0, 1, 1)

local XMovieActionSpineActorShift = XClass(XMovieActionBase, "XMovieActionSpineActorShift")

function XMovieActionSpineActorShift:Ctor(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber

    local actorIndex = paramToNumber(params[1])
    if actorIndex == 0 or actorIndex > XMovieConfigs.MAX_SPINE_ACTOR_NUM then
        XLog.Error("XMovieActionSpineActorShift:Ctor error:ActorIndex is not match, actionId is " .. self.ActionId)
        return
    end
    self.ActorIndex = actorIndex

    self.Duration = paramToNumber(params[2])

    local posX = paramToNumber(params[3])
    local posY = paramToNumber(params[4])
    local posZ = paramToNumber(params[5])
    self.TargetPos = vector(XDataCenter.MovieManager.Fit(posX), posY, posZ)
end

function XMovieActionSpineActorShift:OnRunning()
    local actor = self.UiRoot:GetSpineActor(self.ActorIndex)
    local startPos = actor:GetPos()
    local transPos = self.TargetPos - startPos
    local duration = mathMax(0, self.Duration)
    XUiHelper.Tween(duration, function(t)
        actor:SetPos(startPos + transPos * LineAnimCurve:Evaluate(t))
    end)
end

return XMovieActionSpineActorShift