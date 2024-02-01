local pairs = pairs
local stringUtf8Len = string.Utf8Len
local MAX_SPEAKER_ACTOR_NUM = 14
local SPINE_INDEX_OFFSET = 100 -- spine位置的偏移值

local XMovieActionDialog = XClass(XMovieActionBase, "XMovieActionDialog")

local DoNextInterval = 0.3
local LastDonextTime = 0

function XMovieActionDialog:Ctor(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber
    self.CueId = paramToNumber(params[18])
    self.SpineActorIndex = paramToNumber(params[19])
    self.SpineActorKouSpeed = paramToNumber(params[20])
    self.LipAnimFolder = params[21] -- 嘴唇动画的文件夹名称
    self.SkipRoleAnim = paramToNumber(params[1]) ~= 0
    self.RoleName = XUiHelper.ConvertLineBreakSymbol(XDataCenter.MovieManager.ReplacePlayerName(params[2]))
    local dialogContent = XDataCenter.MovieManager.ReplacePlayerName(params[3])
    if not dialogContent or dialogContent == "" then
        XLog.Error("XMovieActionDialog:OnRunning error:DialogContent is empty, actionId is: " .. self.ActionId)
    end
    self.DialogContent = XUiHelper.ConvertLineBreakSymbol(dialogContent)
    self.SpeakerIndexDic = {}
    self.SpeakerSpineIndexDic = {}
    for i = 1, MAX_SPEAKER_ACTOR_NUM do
        local actorIndex = paramToNumber(params[i + 3])
        if actorIndex ~= 0 then
            -- 配置1，则为立绘第1个位置，配置(SPINE_INDEX_OFFSET+1)则为spine第1个位置
            if actorIndex < SPINE_INDEX_OFFSET then
                self.SpeakerIndexDic[actorIndex] = true
            else
                actorIndex = actorIndex - SPINE_INDEX_OFFSET
                self.SpeakerSpineIndexDic[actorIndex] = true
            end
        end
    end
end

function XMovieActionDialog:GetEndDelay()
    if self.IsAutoPlay then
        local speed = XDataCenter.MovieManager.GetSpeed()
        local delayTime = XMovieConfigs.AutoPlayDelay + stringUtf8Len(self.DialogContent) * XMovieConfigs.PerWordDelay / speed
        delayTime = math.floor(delayTime)
        return delayTime
    else
        return 0
    end
end

function XMovieActionDialog:IsBlock()
    return true
end

function XMovieActionDialog:OnInit()
    self.IsAutoPlay = XDataCenter.MovieManager.IsAutoPlay()
    self.UiRoot.BtnSkipDialog.CallBack = function() self:OnClickBtnSkipDialog() end
    -- XDataCenter.InputManagerPc.RegisterFunc(CS.XUiPc.XUiPcCustomKeyEnum.UiMovieNext, self.UiRoot.BtnSkipDialog.CallBack, 0);
    XDataCenter.InputManagerPc.RegisterFunc(CS.XUiPc.XUiPcCustomKeyEnum.UiMovieNext, function() 
        local time = CS.UnityEngine.Time.time
        if time - LastDonextTime < DoNextInterval then
            return
        end
        LastDonextTime = CS.UnityEngine.Time.time
        self:OnClickBtnSkipDialog()
    end, 0);
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
    self.UiRoot.TxtName.gameObject:SetActiveEx(roleName ~= "")

    self.IsTyping = true
    local typeWriter = self.UiRoot.DialogTypeWriter
    local speed = XDataCenter.MovieManager.GetSpeed()
    typeWriter.Duration = stringUtf8Len(dialogContent) * XMovieConfigs.TYPE_WRITER_SPEED / speed
    typeWriter:Play()
    -- 加速播放时，不播音效
    if self.CueId ~= 0 and not XDataCenter.MovieManager.IsSpeedUp() then
        if self.AudioInfo then
            self.AudioInfo:Stop()
            self.AudioInfo = nil
        end
        self.IsAudioing = true
        self.AudioInfo = CS.XAudioManager.PlayCv(self.CueId, function()
            self:OnAudioComplete()
            self:StopSpineActorTalk()
        end, true)
        self:PlaySpineActorTalk()
        self:PlayAudioLipAnim()
    end
    self:PlaySpeakerAnim()
    XDataCenter.MovieManager.PushInReviewDialogList(roleName, dialogContent,self.CueId)
end

function XMovieActionDialog:OnDestroy()
    self.IsTyping = nil
    self.IsAutoPlay = nil
    self.IsAudioing = nil
    if self.AudioInfo then
        self.AudioInfo:Stop()
    end
    self:StopSpineActorTalk()
    self:StopAudioLipAnim()
    self:ClearDelayId() -- 清理定时器
    XDataCenter.InputManagerPc.UnregisterFunc(CS.XUiPc.XUiPcCustomKeyEnum.UiMovieNext)
end

function XMovieActionDialog:OnClickBtnSkipDialog()
    if self.IsTyping then
        -- 打字中，直接显示完所有字体
        self.IsTyping = false
        self.UiRoot.DialogTypeWriter:Stop()
    else
        -- 字体完全显示，点击屏幕播放下一个MovieAction
        XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_BREAK_BLOCK, false)
    end
end

function XMovieActionDialog:CanContinue()
    return not self.IsTyping
end

function XMovieActionDialog:OnTypeWriterComplete()
    self.IsTyping = false

    -- 自动播放状态，打字完、语音播放完，播放下一个MovieAction
    if self.IsAutoPlay and not self.IsAudioing then
        XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_BREAK_BLOCK, true)
    end
end

function XMovieActionDialog:OnAudioComplete()
    self.IsAudioing = false

    -- 自动播放状态，打字完、语音播放完，播放下一个MovieAction
    if self.IsAutoPlay and not self.IsTyping then
        XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_BREAK_BLOCK, true)
    end
end

function XMovieActionDialog:OnSwitchAutoPlay(autoPlay)
    self.IsAutoPlay = autoPlay
    self:ClearDelayId() -- 清理定时器
    
    -- self.IsTyping == false 只处理当前dialog打印结束的情况
    -- 发送事件触发MovieManager.DoAction()，执行action的Exit()函数，即开启结束定时器
    if autoPlay and self.IsTyping == false and not self.IsAudioing then
        XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_BREAK_BLOCK, true)
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

    local spineActors = self.UiRoot.SpineActors
    for index, spineActor in pairs(spineActors) do
        if self.SpeakerSpineIndexDic[index] then
            spineActor:PlayAnimFront(skipAnim)
        else
            spineActor:PlayAnimBack(skipAnim)
        end
    end
end

-- 播放音频嘴型动画
function XMovieActionDialog:PlayAudioLipAnim()
    if self.LipAnimFolder and not XDataCenter.MovieManager.IsSpeedUp() then
        local actor = self.UiRoot:GetSpineActor(self.SpineActorIndex)
        actor:PlayLipAnim(self.LipAnimFolder, self.CueId)
    end
end

-- 停止音频嘴型动画
function XMovieActionDialog:StopAudioLipAnim()
    if self.LipAnimFolder and not XDataCenter.MovieManager.IsSpeedUp() then
        local actor = self.UiRoot:GetSpineActor(self.SpineActorIndex)
        actor:StopLipAnim()
    end
end

function XMovieActionDialog:OnUndo()
    self.UiRoot.TxtWords.text = self.Record.DialogContent
    self.UiRoot.PanelDialog.gameObject:SetActiveEx(self.Record.IsActive)
    self.UiRoot.DialogTypeWriter.CompletedHandle = nil
    self:OnDestroy()
    XDataCenter.MovieManager.RemoveFromReviewDialogList(self.ActionId)
end

-- 播放语音时切换spine讲话动画
function XMovieActionDialog:PlaySpineActorTalk()
    if self.SpineActorIndex ~= 0 and not self.LipAnimFolder then
        local actor = self.UiRoot:GetSpineActor(self.SpineActorIndex)
        actor:PlayKouTalkAnim(self.SpineActorKouSpeed)
    end
end

-- 停止spine讲话动画，切回之前的动画
function XMovieActionDialog:StopSpineActorTalk()
    if self.SpineActorIndex ~= 0 and not self.LipAnimFolder then
        local actor = self.UiRoot:GetSpineActor(self.SpineActorIndex)
        actor:PlayKouIdleAnim()
    end
end

return XMovieActionDialog