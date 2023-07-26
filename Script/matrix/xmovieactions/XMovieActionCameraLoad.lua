local XMovieActionCameraLoad = XClass(XMovieActionBase,"XMovieActionCameraLoad")

function XMovieActionCameraLoad:Ctor(actionData)
    self.Params = actionData.Params
end

function XMovieActionCameraLoad:OnInit()
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber
    for i = 1, #self.Params do
        local info = string.Split(self.Params[i],"|")
        if info and info[1] and info[2] then
            local transformParam = {
                Position = CS.UnityEngine.Vector3(paramToNumber(info[3]), paramToNumber(info[4]), paramToNumber(info[5])),
                Rotation = CS.UnityEngine.Vector3(paramToNumber(info[6]), paramToNumber(info[7]), paramToNumber(info[8]))
            }
            self.UiRoot:AddCamera(info[1], info[2],transformParam)
        else
            XLog.Error("XMovieActionCameraLoad 相机加载配置错误 请检查对应节点")
        end
    end
end


return XMovieActionCameraLoad