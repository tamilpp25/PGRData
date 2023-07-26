local XMovieActionModelAnimationPlay = XClass(XMovieActionBase,"XMovieActionModelAnimationPlay")

function XMovieActionModelAnimationPlay:Ctor(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber
    self.RoleId = params[1]
    self.BodyAnimation = params[2]
    self.FaceAnimation = params[3]
end

function XMovieActionModelAnimationPlay:OnRunning()
    ---@type Movie.XMovie3DRole
    local actor = self.UiRoot:GetModelActor(self.RoleId)
    if self.FaceAnimation then
        actor:PlayFaceAnimation(self.FaceAnimation)
    end
    if self.BodyAnimation then
        actor:PlayBodyAnimation(self.BodyAnimation)
    end
end

return XMovieActionModelAnimationPlay