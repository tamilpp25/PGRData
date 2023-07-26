local XMovieActionActorLoad = XClass(XMovieActionBase,"XMovieActionActorLoad")
local Vector3 = CS.UnityEngine.Vector3
function XMovieActionActorLoad:Ctor(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber
    self.RoleId = params[1]
    local pos = string.Split(params[2], "|")
    local rotation = string.Split(params[3], "|")
    local scale = string.Split(params[4], "|")
    self.IsShow = params[4]
    self.Transform =  {
    Position = Vector3(paramToNumber(pos[1]), paramToNumber(pos[2]), paramToNumber(pos[3])),
    Rotation = Vector3(paramToNumber(rotation[1]), paramToNumber(rotation[2]), paramToNumber(rotation[3])),
    Scale = Vector3(paramToNumber(scale[1]), paramToNumber(scale[2]), paramToNumber(scale[3]))
    }
end

function XMovieActionActorLoad:OnRunning()
    self.UiRoot:AddModelActor(self.RoleId, self.Transform, self.IsShow)
end


return XMovieActionActorLoad