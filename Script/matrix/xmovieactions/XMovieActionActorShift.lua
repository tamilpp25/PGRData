local mathMax = math.max
local vector = CS.UnityEngine.Vector3
local LineAnimCurve = CS.UnityEngine.AnimationCurve.Linear(0, 0, 1, 1)

local XMovieActionActorShift = XClass(XMovieActionBase, "XMovieActionActorShift")

function XMovieActionActorShift:Ctor(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber

    local actorIndex = paramToNumber(params[1])
    if actorIndex == 0 or actorIndex > XMovieConfigs.MAX_ACTOR_NUM then
        XLog.Error("XMovieActionActorShift:Ctor error:ActorIndex is not match, actionId is " .. self.ActionId)
        return
    end
    self.ActorIndex = actorIndex

    self.Duration = paramToNumber(params[2])

    local posX = paramToNumber(params[3])
    local posY = paramToNumber(params[4])
    local posZ = paramToNumber(params[5])
    self.TargetPos = vector(XDataCenter.MovieManager.Fit(posX), posY, posZ)
end

function XMovieActionActorShift:OnRunning()
    local actor = self.UiRoot:GetActor(self.ActorIndex)
    local startPos = actor:GetImagePos()
    self.Record = {
        OriginPos = startPos
    }
    local targetPos = self.TargetPos
    local transPos = targetPos - startPos
    local duration = mathMax(0, self.Duration)
    XUiHelper.Tween(duration, function(t)
        actor:SetImagePos(startPos + transPos * LineAnimCurve:Evaluate(t))
    end)
end

function XMovieActionActorShift:OnUndo()
    local actor = self.UiRoot:GetActor(self.ActorIndex)
    actor:SetImagePos(self.Record.OriginPos)
end

return XMovieActionActorShift