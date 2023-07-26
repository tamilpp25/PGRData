local XMovieActionSetActorTransform = XClass(XMovieActionBase,"XMovieActionSetActorTransform")

function XMovieActionSetActorTransform:Ctor(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber
    self.RoleId = params[1]
    if params[2] then
        local pos = string.Split(params[2], "|")
        self.Position = CS.UnityEngine.Vector3(paramToNumber(pos[1]), paramToNumber(pos[2]), paramToNumber(pos[3]))
    end
    if params[3] then
        local rotation = string.Split(params[3],"|")
        self.Rotation = CS.UnityEngine.Vector3(paramToNumber(rotation[1]),paramToNumber(rotation[2]),paramToNumber(rotation[3]))
    end
end

function XMovieActionSetActorTransform:OnInit()
    ---@type Movie.XMovie3DRole
    local actor = self.UiRoot:GetModelActor(self.RoleId)
    if not actor then
        return
    end
    if self.Position then
        actor.transform.position = self.Position
    end
    if self.Rotation then
        actor.transform.localEulerAngles = self.Rotation
    end
end

return XMovieActionSetActorTransform