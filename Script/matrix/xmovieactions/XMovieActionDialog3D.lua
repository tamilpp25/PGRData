local XMovieActionDialog3D = XClass(XMovieActionBase, "XMovieActionDialog3D")

function XMovieActionDialog3D:Ctor(actionData)
    local params = actionData.Params
    local toNumber = XDataCenter.MovieManager.ParamToNumber
    self.RoleId = params[1]
    self.Content = XUiHelper.ConvertLineBreakSymbol(params[2])
    self.FaceImg = params[3]
    self.CueId = toNumber(params[4])
    self.BodyAnimation = params[5]
    self.FaceAnimation = params[6]
    self.IsModel = toNumber(params[7])
end

function XMovieActionDialog3D:OnInit()
    local panel3D = self.UiRoot.Panel3D
    ---@type XTable.XTableMovie3DRole
    local roleConfig = CS.Movie.XMovie3DManager.GetRoleConfig(self.RoleId)
    XDataCenter.MovieManager.PushInReviewDialogList(roleConfig.Name, self.Content)
    self.IsTyping = true
    panel3D:SetDialogActive(true)
    panel3D:RegisterBtnSkipDialog(handler(self, self.OnClickBtnSkipDialog))
    local actor = self.UiRoot:GetModelActor(self.RoleId)
    if self.CueId and self.CueId ~= 0 then
        if self.IsModel and self.IsModel == 1 then
            self.AudioInfo = XSoundManager.PlaySoundByType(self.CueId,XSoundManager.SoundType.CV)
        else
            self.AudioInfo = actor:PlayCV(self.CueId)
        end
    end
    panel3D:PlayTypeWriter(roleConfig.Name, self.Content, self.FaceImg, nil, handler(self, self.OnTypeWriterComplete))
    if self.BodyAnimation then
        actor:PlayBodyAnimation(self.BodyAnimation)
    end
    if self.FaceAnimation then
        actor:PlayFaceAnimation(self.FaceAnimation)
    end
end

function XMovieActionDialog3D:OnDestroy()
    self.IsTyping = nil
    self.Skipped = nil
    if self.AudioInfo then
        self.AudioInfo:Stop()
        self.AudioInfo = nil
    end
end

function XMovieActionDialog3D:IsBlock()
    return true
end

function XMovieActionDialog3D:OnClickBtnSkipDialog()
    if self.IsTyping then
        self.IsTyping = false
        self.Skipped = true
        self.UiRoot.Panel3D.TxtTypeWriter:Stop()
    else
        self.Skipped = true
        self:OnTypeWriterComplete()
    end
end

function XMovieActionDialog3D:OnTypeWriterComplete()
    self.IsTyping = false
    if self.Skipped then
        self.UiRoot.Panel3D:SetDialogActive(false)
        XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_BREAK_BLOCK)
    end
end

return XMovieActionDialog3D