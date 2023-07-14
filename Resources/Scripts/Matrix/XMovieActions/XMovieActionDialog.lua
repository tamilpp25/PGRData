local pairs = pairs
local stringUtf8Len = string.Utf8Len

local XMovieActionDialog = XClass(XMovieActionBase, "XMovieActionDialog")

function XMovieActionDialog:Ctor(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber

    self.SkipRoleAnim = paramToNumber(params[1]) ~= 0
    self.RoleName = XDataCenter.MovieManager.ReplacePlayerName(params[2])
    local dialogContent = XDataCenter.MovieManager.ReplacePlayerName(params[3])
    if not dialogContent or dialogContent == "" then
        XLog.Error("XMovieActionDialog:OnRunning error:DialogContent is empty, actionId is: " .. self.ActionId)
        return
    end
    self.DialogContent = dialogContent
    self.SpeakerIndexDic = {}
    for i = 1, XMovieConfigs.MAX_ACTOR_ROLE_NUM do
        local actorIndex = paramToNumber(params[i + 3])
        if actorIndex ~= 0 then
            self.SpeakerIndexDic[actorIndex] = true
        end
    end
end

function XMovieActionDialog:GetEndDelay()
    return self.IsAutoPlay and XMovieConfigs.AutoPlayDelay or 0
end

function XMovieActionDialog:IsBlock()
    return true
end

function XMovieActionDialog:OnInit()
    self.IsAutoPlay = XDataCenter.MovieManager.IsAutoPlay()
    self.UiRoot.BtnSkipDialog.CallBack = function() self:OnClickBtnSkipDialog() end
    self.UiRoot.DialogTypeWriter.CompletedHandle = function() self:OnTypeWriterComplete() end
    self.UiRoot.PanelDialog.gameObject:SetActiveEx(true)
    self.Record = {
        DialogContent = self.UiRoot.TxtWords.text,
        IsActive = self.UiRoot.PanelDialog.gameObject.activeSelf
    }
    local roleName = self.RoleName
    local dialogContent = self.DialogContent
    self.UiRoot.TxtName.text = roleName
    self.UiRoot.TxtWords.text = dialogContent

    self.IsTyping = true
    local typeWriter = self.UiRoot.DialogTypeWriter
    typeWriter.Duration = stringUtf8Len(dialogContent) * XMovieConfigs.TYPE_WRITER_SPEED
    typeWriter:Play()

    self:PlaySpeakerAnim()
    XDataCenter.MovieManager.PushInReviewDialogList(roleName, dialogContent)
end

function XMovieActionDialog:OnDestroy()
    self.IsTyping = nil
    self.Skipped = nil
    self.IsAutoPlay = nil
end

function XMovieActionDialog:OnClickBtnSkipDialog()
    if self.IsTyping then
        self.IsTyping = false
        self.Skipped = true
        self.UiRoot.DialogTypeWriter:Stop()
    else
        self.Skipped = true
        self:OnTypeWriterComplete()
    end
end

function XMovieActionDialog:CanContinue()
    return not self.IsTyping
end

function XMovieActionDialog:OnTypeWriterComplete()
    self.IsTyping = false
    if self.IsAutoPlay or self.Skipped then
        self.Skipped = nil
        local ignoreLock = self.IsAutoPlay
        XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_BREAK_BLOCK, ignoreLock)
    end
end

function XMovieActionDialog:OnSwitchAutoPlay(autoPlay)
    self.IsAutoPlay = autoPlay
    if autoPlay and self.IsTyping == false then
        XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_BREAK_BLOCK)
    end
end

function XMovieActionDialog:PlaySpeakerAnim()
    local skipAnim = self.SkipRoleAnim

    local speakerIndexDic = self.SpeakerIndexDic
    local actors = self.UiRoot.Actors
    for index, actor in pairs(actors) do
        if not speakerIndexDic[index] then
            actor:PlayAnimBack(skipAnim)
        else
            actor:PlayAnimFront(skipAnim)
        end
    end
end


function XMovieActionDialog:OnUndo()
    self.UiRoot.TxtWords.text = self.Record.DialogContent
    self.UiRoot.PanelDialog.gameObject:SetActiveEx(self.Record.IsActive)
    self.UiRoot.DialogTypeWriter.CompletedHandle = nil
    self:OnDestroy()
    XDataCenter.MovieManager.RemoveFromReviewDialogList(self.ActionId)
end

return XMovieActionDialog