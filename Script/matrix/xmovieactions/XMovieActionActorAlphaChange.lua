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
    if self.Index < FRONT_BG_INDEX then
        local actor = self.UiRoot:GetActor(self.Index)
        actor:PlayFadeAnimation(self.BeginAlpha, self.EndAlpha, self.Duration)
    else
        local bgIndex = self.Index == FRONT_BG_INDEX and 3 or self.Index % 1000
        local rImgBg = self.UiRoot["RImgBg" .. bgIndex]
        if not string.IsNilOrEmpty(self.BgPath) then
            rImgBg:SetRawImage(self.BgPath)
        end
        rImgBg.gameObject:SetActiveEx(not string.IsNilOrEmpty(self.BgPath))
        local oldColor = rImgBg.color
        local newColor = CS.UnityEngine.Color(oldColor.r, oldColor.g, oldColor.b, self.BeginAlpha)
        rImgBg.color = newColor
        rImgBg:DOFade(self.EndAlpha, self.Duration)
    end
end

return XMovieActionActorAlphaChange