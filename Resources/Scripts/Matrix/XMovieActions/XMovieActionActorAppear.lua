local vector = CS.UnityEngine.Vector3

local XMovieActionActorAppear = XClass(XMovieActionBase, "XMovieActionActorAppear")

function XMovieActionActorAppear:Ctor(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber

    local actorIndex = paramToNumber(params[1])
    if actorIndex == 0 or actorIndex > XMovieConfigs.MAX_ACTOR_NUM then
        XLog.Error("XMovieActionActorAppear:Ctor error:ActorIndex is not match, actionId is " .. self.ActionId)
        return
    end
    self.ActorIndex = actorIndex

    self.ActorId = paramToNumber(params[2])
    self.FaceId = paramToNumber(params[3])

    local posX = paramToNumber(params[4])
    local posY = paramToNumber(params[5])
    local posZ = paramToNumber(params[6])
    self.FixPos = vector(XDataCenter.MovieManager.Fit(posX), posY, posZ)

    self.SkipRoleAnim = paramToNumber(params[7]) ~= 0
end

function XMovieActionActorAppear:OnInit()
    local actor = self.UiRoot:GetActor(self.ActorIndex)
    self.Record = {
        ActorId = actor:GetActorId(),
        FaceId = actor:GetFaceId(),
        ImagePos = actor:GetImagePos(),
        IsHide = actor:IsHide()
    }
    actor:UpdateActor(self.ActorId)
    actor:SetImagePos(self.FixPos)
    actor:SetFace(self.FaceId)
end

function XMovieActionActorAppear:OnRunning()
    local actor = self.UiRoot:GetActor(self.ActorIndex)
    actor:PlayAnimEnable(self.SkipRoleAnim)
end

function XMovieActionActorAppear:OnUndo()
    local actor = self.UiRoot:GetActor(self.ActorIndex)
    if self.Record.IsHide then
        actor:PlayAnimDisable(self.SkipRoleAnim)
    else
        if self.Record.ActorId ~= 0 then
            actor:UpdateActor(self.Record.ActorId)
        end
        actor:SetFace(self.Record.FaceId)
        if self.Record.ImagePos then
            actor:SetImagePos(self.Record.ImagePos)
        end
    end

end

return XMovieActionActorAppear