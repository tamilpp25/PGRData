local XMovieActionPlaySpineAnim = XClass(XMovieActionBase, "XMovieActionPlaySpineAnim")

function XMovieActionPlaySpineAnim:Ctor(actionData)
    self.AnimationName = actionData.Params[1]
    self.IsLoop = XDataCenter.MovieManager.ParamToNumber(actionData.Params[2]) == 1
end

function XMovieActionPlaySpineAnim:OnInit()
    ---@type UnityEngine.RectTransform
    local spineRoot = self.UiRoot.PanelSpine
    ---@type Spine.Unity.SkeletonAnimation
    local spineComponent = spineRoot:GetComponentInChildren(typeof(CS.Spine.Unity.SkeletonAnimation))
    if spineComponent then
        local cb
        cb = function(track)
            spineComponent.AnimationState:SetAnimation(0, self.AnimationName, self.IsLoop)
            spineComponent.AnimationState:Complete('-', cb)
        end
        spineComponent.AnimationState:Complete('+', cb)
    end
end

return XMovieActionPlaySpineAnim
