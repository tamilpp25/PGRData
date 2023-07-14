local XMovieActionActorDisappear = XClass(XMovieActionBase, "XMovieActionActorDisappear")

function XMovieActionActorDisappear:Ctor(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber

    self.ActorIndexs = {}
    self.Record = {}
    for i = 1, 5 do
        local actorIndex = paramToNumber(params[i])
        if actorIndex ~= 0 then
            self.ActorIndexs[actorIndex] = actorIndex
        end
    end
    self.SkipAnim = paramToNumber(params[6]) ~= 0
end

function XMovieActionActorDisappear:OnInit()
    for actorIndex,_ in pairs(self.ActorIndexs) do
        local actor = self.IsInTip and self.UiRoot:GetTipActor(actorIndex) or self.UiRoot:GetActor(actorIndex)
        self.Record[actorIndex] = {}
        self.Record[actorIndex].ActorId = actor:GetActorId()
        self.Record[actorIndex].FaceId = actor:GetFaceId()
        self.Record[actorIndex].ImgPos = actor:GetImagePos()
    end
end

function XMovieActionActorDisappear:OnRunning()
    for _, actorIndex in pairs(self.ActorIndexs) do
        local actor = self.UiRoot:GetActor(actorIndex)
        actor:PlayAnimDisable(self.SkipAnim)
    end
end

function XMovieActionActorDisappear:OnUndo()
    for _, actorIndex in pairs(self.ActorIndexs) do
        local actor = self.IsInTip and self.UiRoot:GetTipActor(actorIndex) or self.UiRoot:GetActor(actorIndex)
        if self.Record[actorIndex].ActorId ~= 0 then
            actor:UpdateActor(self.Record[actorIndex].ActorId)
        end
        if self.Record[actorIndex].ImgPos then
            actor:SetImagePos(self.Record[actorIndex].ImgPos)
        end
        actor:SetFace(self.Record[actorIndex].FaceId)
        actor:PlayAnimEnable(self.SkipAnim)
    end
end

return XMovieActionActorDisappear