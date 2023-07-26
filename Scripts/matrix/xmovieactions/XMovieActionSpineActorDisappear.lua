local XMovieActionSpineActorDisappear = XClass(XMovieActionBase, "XMovieActionSpineActorDisappear")

function XMovieActionSpineActorDisappear:Ctor(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber

    self.ActorIndexs = {}
    for i = 1, 5 do
        local actorIndex = paramToNumber(params[i])
        if actorIndex ~= 0 then
            self.ActorIndexs[actorIndex] = actorIndex
        end
    end

    self.SkipAnim = paramToNumber(params[6]) ~= 0
end

function XMovieActionSpineActorDisappear:OnInit()
    for actorIndex, _ in pairs(self.ActorIndexs) do
        local actor = self.UiRoot:GetSpineActor(actorIndex)
        if self.SkipAnim then
            actor:SetShow(false)
        else
            actor:PlayUiAnimation(XMovieConfigs.SpineActorAnim.PanelActorDisable, function()
                actor:SetShow(false)
            end)
        end
    end
end

return XMovieActionSpineActorDisappear