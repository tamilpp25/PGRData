local XMovieActionCameraPlay = XClass(XMovieActionBase, "XMovieActionCameraPlay")

function XMovieActionCameraPlay:Ctor(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber
    self.CameraName = params[1]
    self.BlendTime = paramToNumber(params[2])
end

function XMovieActionCameraPlay:OnRunning()
    self.UiRoot:SwitchCamera(self.CameraName,self.BlendTime)
end

return XMovieActionCameraPlay