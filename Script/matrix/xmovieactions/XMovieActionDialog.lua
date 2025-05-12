local pairs = pairs
local stringUtf8Len = string.Utf8Len
local SPINE_INDEX_OFFSET = 100 -- spine位置的偏移值

local XMovieActionDialog = XClass(XMovieActionBase, "XMovieActionDialog")

function XMovieActionDialog:Ctor(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber
    self.CvId = paramToNumber(params[18])
    self.SpineActorIndexs = XMVCA.XMovie:SplitParam(params[19], "&",true)
    self.SpineActorKouSpeed = paramToNumber(params[20])
    self.LipAnimFolder = params[21] -- 嘴唇动画的文件夹名称
    self.SkipRoleAnim = paramToNumber(params[1]) ~= 0
    self.RoleName = XUiHelper.ConvertLineBreakSymbol(XDataCenter.MovieManager.ReplacePlayerName(params[2]))
    self.Content = params[3] -- 配置内容
    self.DialogContent = "" -- 对话实际显示内容
    self.SpeakerIndexDic = {}
    self.SpeakerSpineIndexDic = {}

    -- params[4]-params[17]用于配置讲话的立绘/Spine
    for i = 4, 17 do
        local actorIndex = paramToNumber(params[i])
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

    -- 空文本报错提示
    if not self.Content or self.Content == "" then
        XLog.Error("XMovieActionDialog:OnRunning error:DialogContent is empty, actionId is: " .. self.ActionId)
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
    self.DialogContent = self:GetDialogContent()
    self.IsAutoPlay = XDataCenter.MovieManager.IsAutoPlay()
    self.UiRoot:SetBtnNextCallback(function() self:OnClickBtnSkipDialog() end)
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
    if self.CvId ~= 0 and not XDataCenter.MovieManager.IsSpeedUp() then
        if self.AudioInfo then
            self.AudioInfo:Stop()
            self.AudioInfo = nil
        end
        self.IsAudioing = true
        self.AudioInfo = XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.Voice, self.CvId, function()
            self:OnAudioComplete()
            self:StopSpineActorTalk()
        end)
        self:PlaySpineActorTalk()
        self:PlayAudioLipAnim()
    end
    self:PlaySpeakerAnim()
    XDataCenter.MovieManager.PushInReviewDialogList(roleName, dialogContent, self.CvId)
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
    self.UiRoot:RemoveBtnNextCallback()
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
        for _, index in ipairs(self.SpineActorIndexs) do
            local actor = self.UiRoot:GetSpineActor(index)
            actor:PlayLipAnim(self.LipAnimFolder, self.CvId)
        end
    end
end

-- 停止音频嘴型动画
function XMovieActionDialog:StopAudioLipAnim()
    if self.LipAnimFolder and not XDataCenter.MovieManager.IsSpeedUp() then
        for _, index in ipairs(self.SpineActorIndexs) do
            local actor = self.UiRoot:GetSpineActor(index)
            actor:StopLipAnim()
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

-- 播放语音时切换spine讲话动画
function XMovieActionDialog:PlaySpineActorTalk()
    if #self.SpineActorIndexs > 0 and not self.LipAnimFolder then
        for _, index in ipairs(self.SpineActorIndexs) do
            local actor = self.UiRoot:GetSpineActor(index)
            actor:PlayKouTalkAnim(self.SpineActorKouSpeed)
        end
    end
end

-- 停止spine讲话动画，切回之前的动画
function XMovieActionDialog:StopSpineActorTalk()
    if #self.SpineActorIndexs > 0 and not self.LipAnimFolder then
        for _, index in ipairs(self.SpineActorIndexs) do
            local actor = self.UiRoot:GetSpineActor(index)
            actor:PlayKouIdleAnim()
        end
    end
end

-- 获取显示的对话内容
function XMovieActionDialog:GetDialogContent()
    if not self.Content or self.Content == "" then
        return ""
    end
    local content = self.Content
    -- 替换玩家名称
    content = XDataCenter.MovieManager.ReplacePlayerName(content)
    -- 提取指挥官性别文本
    content = XMVCA.XMovie:ExtractGenderContent(content)
    -- 替换十进制特殊符号
    content = XMVCA.XMovie:ReplaceDecimalismCodeToStr(content)
    -- 字符串换行符可用化
    content = XUiHelper.ConvertLineBreakSymbol(content)

    return content
end

return XMovieActionDialog