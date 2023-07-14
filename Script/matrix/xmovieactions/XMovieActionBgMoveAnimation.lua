local XMovieActionBgMoveAnimation = XClass(XMovieActionBase,"XMovieActionBgMoveAnimation")

function XMovieActionBgMoveAnimation:Ctor(actionData)
    local params = actionData.Params
    local strPos = params[1]
    if strPos then
        self.Pos = XTool.ConvertStringToVector3(strPos)
    else
        self.Pos = CS.UnityEngine.Vector3.zero
    end
    self.Duration = tonumber(params[2])
    self.IsPanelSpine = tonumber(params[3]) == 1
end

function XMovieActionBgMoveAnimation:OnRunning()
    if self.IsPanelSpine then
        self.UiRoot.PanelSpine.transform:DOLocalMove(self.Pos, self.Duration)
        return
    end

    ---@type UnityEngine.UI.RawImage
    local bg1 = self.UiRoot.RImgBg1
    ---@type UnityEngine.UI.RawImage
    local bg2 = self.UiRoot.RImgBg2

    bg1.transform:DOLocalMove(self.Pos, self.Duration)
    bg2.transform:DOLocalMove(self.Pos, self.Duration)
end

return XMovieActionBgMoveAnimation