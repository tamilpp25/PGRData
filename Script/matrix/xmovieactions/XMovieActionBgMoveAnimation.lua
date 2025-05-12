local XMovieActionBgMoveAnimation = XClass(XMovieActionBase,"XMovieActionBgMoveAnimation")
local DefaultBgIndex = 1

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

    local bgIndex = params[4]
    self.BgIndex = bgIndex and tonumber(bgIndex) or DefaultBgIndex
end

function XMovieActionBgMoveAnimation:OnUiRootInit()
    self.RImgBg = self.UiRoot["RImgBg".. tostring(self.BgIndex)] 
    self.RImgAnimBg = self.BgIndex == DefaultBgIndex and self.UiRoot.RImgBg2 or nil
end

function XMovieActionBgMoveAnimation:OnRunning()
    if self.IsPanelSpine then
        self.UiRoot.PanelSpine.transform:DOKill()
        self.UiRoot.PanelSpine.transform:DOLocalMove(self.Pos, self.Duration)
        return
    end

    if self.RImgBg then
        self.RImgBg.transform:DOKill()
        self.RImgBg.transform:DOLocalMove(self.Pos, self.Duration)
    end
    if self.RImgAnimBg then
        self.RImgAnimBg.transform:DOKill()
        self.RImgAnimBg.transform:DOLocalMove(self.Pos, self.Duration)
    end
end

return XMovieActionBgMoveAnimation