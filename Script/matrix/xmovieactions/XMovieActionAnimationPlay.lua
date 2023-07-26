local XMovieActionAnimationPlay = XClass(XMovieActionBase, "XMovieActionAnimationPlay")

function XMovieActionAnimationPlay:Ctor(actionData)
    local params = actionData.Params
    self.AnimName = params[1]
end

function XMovieActionAnimationPlay:OnRunning()
    local animName = self.AnimName
    local anim = self.UiRoot[animName]
    if not anim then
        XLog.Error("XMovieActionAnimationPlay:OnRunning error: Animation not Exist, animName is: " .. animName)
        return
    end
    
    self:StopAnimtion(anim)
    anim.gameObject:SetActiveEx(true)
    anim:PlayTimelineAnimation(function()
        anim.gameObject:SetActiveEx(false)
    end)
end

function XMovieActionAnimationPlay:StopAnimtion(anim)
    local timelineAnimation = anim.transform:GetComponent(typeof(CS.XUiPlayTimelineAnimation))
    if timelineAnimation then
        timelineAnimation:Stop(false)
    end
end

return XMovieActionAnimationPlay