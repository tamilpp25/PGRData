local XMovieActionSceneLoad = XClass(XMovieActionBase,"XMovieActionSceneLoad")
function XMovieActionSceneLoad:Ctor(actionData)
    local params        = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber
    local Vector3       = CS.UnityEngine.Vector3
    self.ScenePath      = params[1]
    local pos           = string.Split(params[2], "|")
    local rotation      = string.Split(params[3], "|")
    local scale         = string.Split(params[4], "|")
    self.ScenePos       = Vector3(paramToNumber(pos[1]), paramToNumber(pos[2]), paramToNumber(pos[3]))
    self.SceneRotation  = Vector3(paramToNumber(rotation[1]), paramToNumber(rotation[2]), paramToNumber(rotation[3]))
    self.SceneScale     = Vector3(paramToNumber(scale[1]), paramToNumber(scale[2]), paramToNumber(scale[3]))
end

function XMovieActionSceneLoad:OnInit()
    self.UiRoot:Switch3DMovie()
    local root = self.UiRoot.UiModelGo.transform
    local obj = CS.LoadHelper.InstantiateScene(self.ScenePath)
    obj.transform.parent = root.parent.parent
    obj.transform.localScale = self.SceneScale
    obj.transform.localPosition = self.ScenePos
    obj.transform.localEulerAngles = self.SceneRotation
end


return XMovieActionSceneLoad