local XMovieActionBgScale = XClass(XMovieActionBase, "XMovieActionBgScale")

function XMovieActionBgScale:Ctor(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber
    self.Scale = paramToNumber(params[1])
    local strPos = params[2]
    if strPos then
        self.Pos = XTool.ConvertStringToVector3(strPos)
    else
        self.Pos = CS.UnityEngine.Vector3.zero
    end
end

function XMovieActionBgScale:OnRunning()
    ---@type UnityEngine.UI.RawImage
    local bg1 = self.UiRoot.RImgBg1
    ---@type UnityEngine.UI.RawImage
    local bg2 = self.UiRoot.RImgBg2
    
    bg1.transform.localScale = CS.UnityEngine.Vector3.one * self.Scale
    bg1.transform.localPosition = self.Pos
    bg2.transform.localScale = CS.UnityEngine.Vector3.one * self.Scale
    bg2.transform.localPosition = self.Pos
end

return XMovieActionBgScale