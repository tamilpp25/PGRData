local XMovieActionBgScale = XClass(XMovieActionBase, "XMovieActionBgScale")
local DefaultBgIndex = 1

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

    local bgIndex = params[3]
    self.BgIndex = bgIndex and paramToNumber(bgIndex) or DefaultBgIndex
end

function XMovieActionBgScale:OnUiRootInit()
    self.RImgBg = self.UiRoot["RImgBg".. tostring(self.BgIndex)] 
    self.RImgAnimBg = self.BgIndex == DefaultBgIndex and self.UiRoot.RImgBg2 or nil
end

function XMovieActionBgScale:OnRunning()
    if self.RImgBg then
        self.RImgBg.transform.localScale = CS.UnityEngine.Vector3.one * self.Scale
        self.RImgBg.transform.localPosition = self.Pos
    end

    if self.RImgAnimBg then
        self.RImgAnimBg.transform.localScale = CS.UnityEngine.Vector3.one * self.Scale
        self.RImgAnimBg.transform.localPosition = self.Pos
    end
end

return XMovieActionBgScale