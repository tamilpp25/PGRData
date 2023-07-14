local XMovieActionActorAlphaChange = XClass(XMovieActionBase, "XMovieActionActorAlphaChange")
local FRONT_BG_INDEX = 999
function XMovieActionActorAlphaChange:Ctor(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber

    self.Index = paramToNumber(params[1])
    self.BgPath = params[2]
    self.BeginAlpha = paramToNumber(params[3])
    self.EndAlpha = paramToNumber(params[4])
    self.Duration = paramToNumber(params[5])
end

function XMovieActionActorAlphaChange:OnRunning()
    if self.Index ~= FRONT_BG_INDEX then
        local actor = self.UiRoot:GetActor(self.Index)
        actor:PlayFadeAnimation(self.BeginAlpha, self.EndAlpha, self.Duration)
    else
        if not string.IsNilOrEmpty(self.BgPath) then
            self.UiRoot.RImgBg3:SetRawImage(self.BgPath)
        end
        self.UiRoot.RImgBg3.gameObject:SetActiveEx(not string.IsNilOrEmpty(self.BgPath))
        local oldColor = self.UiRoot.RImgBg3.color
        local newColor = CS.UnityEngine.Color(oldColor.r, oldColor.g, oldColor.b, self.BeginAlpha)
        self.UiRoot.RImgBg3.color = newColor
        self.UiRoot.RImgBg3:DOFade(self.EndAlpha, self.Duration)
    end
    
end

return XMovieActionActorAlphaChange