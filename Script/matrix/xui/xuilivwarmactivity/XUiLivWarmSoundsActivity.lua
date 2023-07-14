local XUiLivWarmSoundsActivity = XLuaUiManager.Register(XLuaUi, "UiLivWarmSoundsActivity")

local XUiLivWarmSoundsActivityAudioGrid = require("XUi/XUiLivWarmActivity/XUiLivWarmSoundsActivityAudioGrid")
local XUiLivWarmSoundsActivityTaskPanel = require("XUi/XUiLivWarmActivity/XUiLivWarmSoundsActivityTaskPanel")

local GAME_STATE = { --游戏面板状态
    EditorState = 1,
    PlayState = 2,
}

local LONG_CLICK_OFFSET = 1 --长按触发时间
local MAX_AUDIO_PIECES = 5 --最大音频数量
local MAX_TIP_COUNT = 5 --最大提示数量
local PROGRESS_SPEED = CS.XGame.ClientConfig:GetInt("LivWarmSoundsActivityProgressSpeed") --播放进度条速度

function XUiLivWarmSoundsActivity:OnAwake()
    self.AudioOrder = {} --存储调整的音频位置，拖拽的时候更新
    self.AudioPieces = {} --音频片段
    self.PanelSinglePopup = {}--PanelPopup代理传递给audio类控制
    XTool.InitUiObjectByUi(self.PanelSinglePopup, self.PanelPopup)
end

function XUiLivWarmSoundsActivity:OnStart()
    self.PanelAllCd = self.Transform:FindTransform("PanelAllCd")
    self.AudioAreaRectTransform = self.PanelAllCd:GetComponent("RectTransform")
    self.ProgressBar = self.Transform:FindTransform("PanelMode"):FindTransform("ProgressBar")
    self.ImgLan = self.Transform:FindTransform("PanelMode"):FindTransform("Lan")
    self.Bar = self.Transform:FindTransform("PanelMode"):FindTransform("Bar")
    self.Effect = self.Transform:FindTransform("PanelMode"):FindTransform("Effect")
    self.EffectPan = self.Transform:FindTransform("RImgAirvinyl"):FindTransform("Effect")
    self.ImgBlue =  self.Transform:FindTransform("ImgBlue")
    self.RImgQuietWave =  self.Transform:FindTransform("RImgQuietWave")
    self.Camera = CS.XUiManager.Instance.UiCamera
    self.PanelReward = XUiLivWarmSoundsActivityTaskPanel.New(self.PanelCheckReward, self)
    self.ActivityId = XDataCenter.LivWarmSoundsActivityManager.GetActivityId()
    self.TxtWords.text = ""
    self:SetPlayEff(false)
    self:InitTimer()
    self:InitAudioPieces()
    self:AddListener()
    self:InitBtnGroup()
end

function XUiLivWarmSoundsActivity:OnEnable()
    self:CheckActivityEnd()
    self:CheckHitFaceHelp()
    self:RefreshTitle() --标题刷新
    self:RefreshBtnState() --按钮stage状态更新
    self:RefreshTaskProgress() --任务进度
    self.BtnGroupChapter:SelectIndex(XDataCenter.LivWarmSoundsActivityManager.GetTheNewestStage())
end

function XUiLivWarmSoundsActivity:OnGetEvents()
    return {
        XEventId.EVENT_XLIVWARMSOUND_ACTIVITY_STAGE_AUDIO_CHANGE,
        XEventId.EVENT_XLIVWARMSOUND_ACTIVITY_TIP_COUNT_CHANGE,
        XEventId.EVENT_XLIVWARMSOUND_ACTIVITY_STAGE_AUDIO_CLIENT_CHANGE,
        XEventId.EVENT_XLIVWARMSOUND_ACTIVITY_END,
        XEventId.EVENT_TASK_SYNC,
    }
end

function XUiLivWarmSoundsActivity:OnNotify(evt, ...)
    local args = { ... }
    if evt == XEventId.EVENT_XLIVWARMSOUND_ACTIVITY_STAGE_AUDIO_CHANGE then
        self:SwitchToPlayMode()
        self:RefreshBtnState()
    elseif evt == XEventId.EVENT_XLIVWARMSOUND_ACTIVITY_TIP_COUNT_CHANGE then
        local nowTipCount = args[1]
        self:RefreshTips(nowTipCount)
    elseif evt == XEventId.EVENT_XLIVWARMSOUND_ACTIVITY_STAGE_AUDIO_CLIENT_CHANGE then
        self:RefreshAudioInfo()
    elseif evt == XEventId.EVENT_XLIVWARMSOUND_ACTIVITY_END then
        self:CheckActivityEnd()
    elseif evt == XEventId.EVENT_TASK_SYNC then
        self:RefreshTaskProgress()
    end
end

function XUiLivWarmSoundsActivity:OnDisable()
end

function XUiLivWarmSoundsActivity:OnDestroy()
    XCountDown.UnBindTimer(self.PanelTitle, XCountDown.GTimerName.LivWarmSoundsActivity)
    self:OnButtonStop()
    self:DestroyTimerByTimerId(self.PlayTimerId)
    self:DestroyTimerByTimerId(self.ProgressTimerId)
end

function XUiLivWarmSoundsActivity:SetPlayEff(isEff)--处理特效相关的播放表现
    if isEff then
        self.Effect.gameObject:SetActiveEx(true)
        self.RImgQuietWave.gameObject:SetActiveEx(false)
        self.EffectPan.gameObject:SetActiveEx(true)
    else
        self.Effect.gameObject:SetActiveEx(false)
        self.RImgQuietWave.gameObject:SetActiveEx(true)
        self.EffectPan.gameObject:SetActiveEx(false)
    end
end

function XUiLivWarmSoundsActivity:CheckActivityEnd()
    if self.IsEnd then
        return
    end
    if XDataCenter.LivWarmSoundsActivityManager.OnActivityEnd() then
        self.IsEnd = true
        return
    end
end

function XUiLivWarmSoundsActivity:InitTimer()
    local textTime = self.PanelTitle.transform:Find("TxtTime")
    XCountDown.BindTimer(self.PanelTitle, XCountDown.GTimerName.LivWarmSoundsActivity, function(v)
        if not XDataCenter.LivWarmActivityManager.CheckActivityIsOpen() then
            return
        end
        textTime:GetComponent("Text").text = XUiHelper.GetTime(v, XUiHelper.TimeFormatType.ACTIVITY)
    end)
end

function XUiLivWarmSoundsActivity:InitBtnGroup()
    self.DataSource = XDataCenter.LivWarmSoundsActivityManager.GetStages()
    if XTool.IsTableEmpty(self.DataSource) then
        return
    end
    local tabGroup = {}
    for i = 1, #self.DataSource do
        local uiButton
        if i == 1 then
            uiButton = self.BtnStage
        else
            local itemGo = CS.UnityEngine.Object.Instantiate(self.BtnStage.gameObject)
            itemGo.transform:SetParent(self.BtnGroupChapter.transform, false)
            uiButton = itemGo.transform:GetComponent("XUiButton")
        end
        uiButton:SetNameByGroup(0, XLivWarmSoundsActivityConfig.GetStageStageName(self.DataSource[i]))
        table.insert(tabGroup, uiButton)
    end
    self.BtnGroupChapter:Init(tabGroup, function(tabIndex)
        self:BtnStageClick(self.DataSource[tabIndex])
    end)
end

--StageBtn的状态 播放状态下是不可点击的
function XUiLivWarmSoundsActivity:RefreshBtnState()
    if XTool.IsTableEmpty(self.DataSource) or not self.BtnGroupChapter then
        return
    end
    for i, v in pairs(self.DataSource) do
        local uiButton = self.BtnGroupChapter:GetButtonByIndex(i)
        local isPass, desc = XConditionManager.CheckCondition(XLivWarmSoundsActivityConfig.GetStageCondition(v), v)
        if not isPass then
            uiButton:SetDisable(true)
            uiButton:SetNameByGroup(1, desc)
        else
            uiButton:SetDisable(false)
            uiButton:SetNameByGroup(1, "")
        end
    end
end

function XUiLivWarmSoundsActivity:AddListener()
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
    self:BindHelpBtn(self.BtnHelp, "LivWarmSoundsActivityHelp")

    self.BtnTestPlay.CallBack = function()
        if self.BtnTestPlay.ButtonState == CS.UiButtonState.Disable then
            return
        end
        XDataCenter.LivWarmSoundsActivityManager.SetStageAnswer(self.StageId, self.AudioOrder)
    end

    self.BtnReplay.CallBack = function()
        self:SwitchToPlayMode(true)
    end

    self.BtnReplayStop.CallBack = function()
        self.IsPlaying = false
    end

    self.BtnStop.CallBack = function()
        self.IsPlaying = false
    end

    self.BtnHint.CallBack = function()
        self:OnButtonHint()
    end

    self.BtnUrl.CallBack = function()
        CS.UnityEngine.Application.OpenURL(XLivWarmSoundsActivityConfig.GetStageFinishUrl(self.StageId))
    end

    self:RegisterClickEvent(self.BtnTreasure, function()
        self:Switch2RewardList()
    end)

    self:InitBtnLongClicks()
end

function XUiLivWarmSoundsActivity:OnButtonStop()
    self:SetPlayEff(false)
    self:StopAudioPlay()
    self:ResetProgress()
    self:SwitchToEditorMode(true)
end

function XUiLivWarmSoundsActivity:OnBtnBackClick()
    self:Close()
end

function XUiLivWarmSoundsActivity:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiLivWarmSoundsActivity:CheckHitFaceHelp()
    local IsShowHelp = XDataCenter.LivWarmSoundsActivityManager.CheckShowHelp()
    if IsShowHelp then
        XUiManager.ShowHelpTip("LivWarmSoundsActivityHelp")
    end
end

function XUiLivWarmSoundsActivity:RefreshTitle()
    self.PanelTitle.transform:Find("RawImage"):GetComponent("RawImage"):SetRawImage(XLivWarmSoundsActivityConfig.GetActivityName(self.ActivityId))
end

function XUiLivWarmSoundsActivity:OnButtonHint()
    XDataCenter.LivWarmSoundsActivityManager.SetTipCount(self.StageId)
end

function XUiLivWarmSoundsActivity:RefreshTips(count)
    self:RefreshTipsBtn()
    local tipCount = XDataCenter.LivWarmSoundsActivityManager.StageTipCount(self.StageId)
    local hints = XLivWarmSoundsActivityConfig.GetStageHint(self.StageId)
    if tipCount then
        if count then
            self["PanelHint" .. count].gameObject:SetActiveEx(true)
            --self:PlayAnimation("PanelHint" .. count .. "Enable")
            self["PanelHint" .. count].transform:Find("Text"):GetComponent("Text").text = hints[count]
        else
            for i = 1, MAX_TIP_COUNT do
                if i <= tipCount then
                    self["PanelHint" .. i].gameObject:SetActiveEx(true)
                    --self:PlayAnimation("PanelHint" .. i .. "Enable")
                    self["PanelHint" .. i].transform:Find("Text"):GetComponent("Text").text = hints[i]
                else
                    self["PanelHint" .. i].gameObject:SetActiveEx(false)
                end
            end
        end
    end

end

function XUiLivWarmSoundsActivity:RefreshTipsBtn()
    --tips按钮刷新
    local isMax = XDataCenter.LivWarmSoundsActivityManager.IsTipCountMax(self.StageId)
    self.BtnHint:SetDisable(isMax, not isMax)
end


--------Audio 相关---------------


-- 初始化长按事件 图片拖拽替换,以及单点播放
function XUiLivWarmSoundsActivity:InitBtnLongClicks()
    for i = 1, MAX_AUDIO_PIECES do
        XUiButtonLongClick.New(self.AudioPieces[i].BtnCd, 10, self, nil, function(pressTime)
            self:LongClick(i, pressTime)
        end, self.OnBtnLongUp, false, nil, false, nil, LONG_CLICK_OFFSET)
    end
end

function XUiLivWarmSoundsActivity:LongClick(changeIndex, pressTime)
    if changeIndex > #self.AudioOrder or (self.GameState ~= GAME_STATE.EditorState and XDataCenter.LivWarmSoundsActivityManager.IsStageFinished(self.StageId)) then
        --音频片段可能会小于changeIndex
        return
    end
    self.ChangeIndex = changeIndex
    self.BtnReplacePanelCd.gameObject:SetActiveEx(true)
    self:ReplaceBtnCd(self.AudioOrder[changeIndex])
    self.BtnReplacePanelCd.transform.localPosition = self:GetPosition()
    self:OnJudgeInsert()
end

function XUiLivWarmSoundsActivity:OnBtnLongUp()
    self.TargetIndex = self:OnJudgeInsert(true)
    self:ChangeAudioOrder(self.ChangeIndex, self.TargetIndex)
    self:ResetLongClick()
end

function XUiLivWarmSoundsActivity:OnJudgeInsert(isUp) --判断音频将要插入的位置,isUp标识抬手动作
    if not XTool.IsNumberValid(self.ChangeIndex) then
        return
    end
    local replaceAnchoredPosition = self.BtnReplacePanelCd.transform.anchoredPosition
    local dragPlayArea = self.DragPlayArea.transform.anchoredPosition;
    local dragPlayX = { minX = dragPlayArea.x - self.DragPlayArea.transform.rect.width / 2, maxX = dragPlayArea.x + self.DragPlayArea.transform.rect.width / 2 }
    local dragPlayY = { minY = dragPlayArea.y - self.DragPlayArea.transform.rect.height / 2, maxY = dragPlayArea.y + self.DragPlayArea.transform.rect.height / 2 }
    if replaceAnchoredPosition.x >= dragPlayX.minX and replaceAnchoredPosition.x <= dragPlayX.maxX and replaceAnchoredPosition.y >= dragPlayY.minY and replaceAnchoredPosition.y <= dragPlayY.maxY then
        if isUp then
            self.AudioPieces[self.ChangeIndex]:PlaySound(true)
            self:ResetLongClick()
        else
            self:OnSetBtnSelect()
        end
        return
    end
    local replaceAnchoredPosition = self.BtnReplacePanelCd.transform.anchoredPosition
    local targetIndex = self.ChangeIndex
    if self.AudioPieces[self.ChangeIndex].Transform.anchoredPosition.x < replaceAnchoredPosition.x then --往右边拖动
        for i = self.ChangeIndex + 1, MAX_AUDIO_PIECES do
            if self.AudioPieces[i].Transform.anchoredPosition.x < replaceAnchoredPosition.x then
                targetIndex = i
            end
        end
    else
        for i = self.ChangeIndex - 1, 1,-1 do
            if self.AudioPieces[i].Transform.anchoredPosition.x >= replaceAnchoredPosition.x then
                targetIndex = i
            end
        end
    end
    self:OnSetBtnSelect(targetIndex)
    return targetIndex
end

function XUiLivWarmSoundsActivity:OnSetBtnSelect(selectIndex)
    for i = 1, MAX_AUDIO_PIECES do
        if i == selectIndex then
            self.AudioPieces[i].BtnCd:SetButtonState(CS.UiButtonState.Select)
        else
            self.AudioPieces[i].BtnCd:SetButtonState(CS.UiButtonState.Normal)
        end
    end
end

function XUiLivWarmSoundsActivity:ResetLongClick()
    self:OnSetBtnSelect()
    self.BtnReplacePanelCd.gameObject:SetActiveEx(false)
    self.ChangeIndex = 0
    self.TargetIndex = 0
end

function XUiLivWarmSoundsActivity:ReplaceBtnCd(soundIndex)
    self.BtnReplacePanelCd:SetRawImage(XLivWarmSoundsActivityConfig.GetSoundAttachedImgUrl(soundIndex))
    self.BtnReplacePanelCd:SetName(XLivWarmSoundsActivityConfig.GetSoundRankNumber(soundIndex))
end

function XUiLivWarmSoundsActivity:GetPosition()
    local screenPoint
    if CS.UnityEngine.Application.platform == CS.UnityEngine.RuntimePlatform.WindowsEditor or CS.UnityEngine.Application.platform == CS.UnityEngine.RuntimePlatform.WindowsPlayer then
        screenPoint = CS.UnityEngine.Vector2(CS.UnityEngine.Input.mousePosition.x, CS.UnityEngine.Input.mousePosition.y)
    else
        screenPoint = CS.UnityEngine.Input.GetTouch(0).position
    end

    -- 设置拖拽
    local hasValue, v2 = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(self.AudioAreaRectTransform, screenPoint, self.Camera)
    if hasValue then
        return CS.UnityEngine.Vector3(v2.x, v2.y, 0)
    else
        return CS.UnityEngine.Vector3.zero
    end
end

function XUiLivWarmSoundsActivity:ChangeAudioOrder(changeIndex, targetIndex)
    if XTool.IsTableEmpty(self.AudioOrder) or not XTool.IsNumberValid(targetIndex) or changeIndex == targetIndex  then
        return
    end
    local answer = XTool.Clone(self.AudioOrder)
    local changeId = answer[changeIndex]
    table.remove(answer, changeIndex)
    table.insert(answer, targetIndex, changeId)
    XDataCenter.LivWarmSoundsActivityManager.SetClientStageAnswer(self.StageId, answer)
    self:RefreshTestBtnState(self.StageId, answer)
end
--拖拽结束--------------
--关卡点击
function XUiLivWarmSoundsActivity:BtnStageClick(stageId)
    local isPass, desc = XConditionManager.CheckCondition(XLivWarmSoundsActivityConfig.GetStageCondition(stageId), stageId)
    if not isPass then
        XUiManager.TipMsg(desc)
        return
    end

    if self.GameState == GAME_STATE.PlayState then
        return
    end
    self:PlayAnimation("QieHuan")
    self:RefreshAudioInfo(stageId)
    self:RefreshTips()
    self:SwitchToEditorMode()
end

--audio初始化
function XUiLivWarmSoundsActivity:InitAudioPieces()
    for i = 1, MAX_AUDIO_PIECES do
        if not self.AudioPieces[i] then
            local audioObj
            if i == 1 then
                audioObj = self.BtnCd
            else
                audioObj = CS.UnityEngine.Object.Instantiate(self.BtnCd, self.PanelAllCd)
            end
            local audio = XUiLivWarmSoundsActivityAudioGrid.New(audioObj, self)
            table.insert(self.AudioPieces, audio)
        end
    end
    self.BtnReplacePanelCd.transform:SetAsLastSibling()
end

--audio信息刷新
function XUiLivWarmSoundsActivity:RefreshAudioInfo(stageId)
    if stageId then
        self.StageId = stageId
    end
    if not XTool.IsNumberValid(self.StageId) then
        return
    end
    self.AudioOrder = XDataCenter.LivWarmSoundsActivityManager.GetStageAnswer(self.StageId)
    self:RefreshAudioPieces()
    self:RefreshTestBtnState(self.StageId, self.AudioOrder)
end

function XUiLivWarmSoundsActivity:RefreshTestBtnState(stageId,audioOrder) --海外修改：根据是否排列正确刷新按钮状态
    local flag = XDataCenter.LivWarmSoundsActivityManager.CheckStageAnswer(stageId, audioOrder)
    if flag then
        self.BtnTestPlay:SetButtonState(CS.UiButtonState.Normal)
    else
        self.BtnTestPlay:SetButtonState(CS.UiButtonState.Disable)
    end
end

function XUiLivWarmSoundsActivity:RefreshAudioPieces()
    self:ResetAudioPieces()
    for i, audioIndex in ipairs(self.AudioOrder) do
        self.AudioPieces[i]:RefreshData(audioIndex, self.PanelSinglePopup, function(isSingleTouch)
            --区分单点以及播放方法
            if not isSingleTouch then
                if self.AudioPieces[i + 1] then
                    self.AudioPieces[i + 1]:PlaySound()
                end
            end
        end)
    end
end

function XUiLivWarmSoundsActivity:ResetAudioPieces()
    if not XTool.IsTableEmpty(self.AudioPieces) then
        for i, v in pairs(self.AudioPieces) do
            v.GameObject:SetActiveEx(false)
        end
    end
end

function XUiLivWarmSoundsActivity:StopAudioPlay()
    if not XTool.IsTableEmpty(self.AudioPieces) then
        for i, v in pairs(self.AudioPieces) do
            v:StopPlaySound()
        end
    end
end

----------------Audio End----------------------


-----------布局刷新--------
function XUiLivWarmSoundsActivity:SwitchToEditorMode(noAnim)
    self.GameState = GAME_STATE.EditorState
    self:RefreshStateInfo(noAnim)
end
--客户端调试播放需要服务端验证后播放，重播不需要，重播使用isReplay标识
function XUiLivWarmSoundsActivity:SwitchToPlayMode(isReplay)
    self.GameState = GAME_STATE.PlayState
    --[[if XTool.IsNumberValid(self.StageId) then
        if XDataCenter.LivWarmSoundsActivityManager.IsStageFinished(self.StageId) and not isReplay then
            --重播不需要播放转场动画
            -- self:PlayAnimationWithMask("AnimEnable2", function()
            self:PlayBehaviour()
            -- end)
        else
            self:PlayBehaviour()
        end
    end--]]
    self:RefreshStateInfo(true)
    self:PlayAllText()
end

function XUiLivWarmSoundsActivity:PlayBehaviour()
    --播放音频
    if not XTool.IsTableEmpty(self.AudioPieces) then
        self:StopAudioPlay()
        self.IsPlaying = true
        self:PlayAnimation("PlayMusic")
        self:StartPlayTimer()
        self.AudioPieces[1]:PlaySound() --播放音频从头开始
    end
end

function XUiLivWarmSoundsActivity:PlayAllText() --海外修改：显示CG完整文字
    self.PanelPlayMask.gameObject:SetActiveEx(true)
    self.TxtTypeWriterL.CompletedHandle = function()
        self.PanelPlayMask.gameObject:SetActiveEx(false)
        self.GameState = GAME_STATE.EditorState
    end
    self.TxtTypeWriterL:Play()
end

--一共两种大状态，播放状态以及编辑状态，每个大状下都有两个小状态，通关以及未通关状态
function XUiLivWarmSoundsActivity:RefreshStateInfo(noPlayEnableAnim)
    if not self.isReplaceBgImg and XDataCenter.LivWarmSoundsActivityManager.IsAllStageFinished() then
        self.isReplaceBgImg = true
        self.RImgBg:SetRawImage(XLivWarmSoundsActivityConfig.GetActivityClearBgImg(self.ActivityId))
    end
    local isStageFinish = XDataCenter.LivWarmSoundsActivityManager.IsStageFinished(self.StageId)
    if isStageFinish then
        --if not noPlayEnableAnim then
            self:PlayAnimation("AnimEnable")
        --end
        self.Transform:FindTransform("PanelPlay").gameObject:SetActiveEx(true)
        self.Transform:FindTransform("PanelVinylRecord").gameObject:SetActiveEx(false)
        self.TextFinishTip.text = XUiHelper.ConvertLineBreakSymbol(XLivWarmSoundsActivityConfig.GetStageFinishText(self.StageId))
        self.RImgFinish:SetRawImage(XLivWarmSoundsActivityConfig.GetStageFinishImg(self.StageId))
        self.BtnUrl.gameObject:SetActiveEx(XLivWarmSoundsActivityConfig.GetStageFinishUrl(self.StageId) ~= "" and true or false)
    else
        self.Transform:FindTransform("PanelPlay").gameObject:SetActiveEx(false)
        self.Transform:FindTransform("PanelVinylRecord").gameObject:SetActiveEx(true)
    end
end

--播放进度条处理
function XUiLivWarmSoundsActivity:RefreshProgress(count)
    local BroadTestTime = XLivWarmSoundsActivityConfig.GetStageBroadTestTime(self.StageId)
    local maxCount = (XScheduleManager.SECOND/PROGRESS_SPEED)*BroadTestTime --需要动画的总次数
    if XDataCenter.LivWarmSoundsActivityManager.IsStageFinished(self.StageId) then
        self.ImgBlue:GetComponent("Image").fillAmount = count / maxCount
    else
        local deltaWidth = (self.Bar.rect.width - self.ProgressBar.rect.width) / ((XScheduleManager.SECOND/PROGRESS_SPEED)*BroadTestTime) --进度条本身有宽度需要处理
        self.ProgressBar.anchoredPosition = CS.UnityEngine.Vector2((self.ProgressBar.rect.width / 2 + deltaWidth * count), self.ProgressBar.anchoredPosition.y)
        self.ImgLan:GetComponent("Image").fillAmount = count / maxCount
    end
end

function XUiLivWarmSoundsActivity:ResetProgress()
    if XDataCenter.LivWarmSoundsActivityManager.IsStageFinished(self.StageId) then
        self.ImgBlue:GetComponent("Image").fillAmount = 0
    else
        self.ProgressBar.anchoredPosition = CS.UnityEngine.Vector2((self.ProgressBar.rect.width / 2), self.ProgressBar.anchoredPosition.y)
        self.ImgLan:GetComponent("Image").fillAmount = 0
    end
end

--------布局刷新 End-----------
--任务进程
function XUiLivWarmSoundsActivity:RefreshTaskProgress()
    local taskList = XDataCenter.TaskManager.GetLivWarmSoundsActivityFullTaskList()
    local passCount, allCount = XDataCenter.TaskManager.GetTaskProgressByTaskList(taskList)
    self.ImgJindu.fillAmount = passCount / allCount
    self.TxtTaskProgress.text = CS.XTextManager.GetText("LivWarmTaskProgress", passCount, allCount)
    self.ImgLingqu.gameObject:SetActiveEx(passCount == allCount)
    self.ImgTaskRed.gameObject:SetActiveEx(XDataCenter.TaskManager.GetIsRewardForEx(TaskType.LivWarmSoundsActivity))
    if self.PanelReward.GameObject.activeSelf then
        self.PanelReward:UpdateRewardList()
    end
end

function XUiLivWarmSoundsActivity:Switch2RewardList()
    self.PanelReward.GameObject:SetActiveEx(true)
    self:PlayAnimation("PanelCheckRewardEnable")
    self.PanelReward:UpdateRewardList()
end

-------------------------------------------------------计时器------------------------------------------------------------
function XUiLivWarmSoundsActivity:DestroyTimerByTimerId(id)
    if XTool.IsNumberValid(id) then
        XScheduleManager.UnSchedule(id)
    end
end

function XUiLivWarmSoundsActivity:StartPlayTimer()
    self:DestroyTimerByTimerId(self.PlayTimerId)
    self:DestroyTimerByTimerId(self.ProgressTimerId)
    self.PlayTimerId = nil
    self.ProgressTimerId = nil
    self.BtnReplayStop.gameObject:SetActiveEx(true)
    self.PanelPlayMask.gameObject:SetActiveEx(true)
    self:SetPlayEff(true)
    local loopCount = XLivWarmSoundsActivityConfig.GetStageBroadTestTime(self.StageId)
    local progressCount = 0
    self.ProgressTimerId = XScheduleManager.ScheduleForever(function()
        progressCount = progressCount + 1
        self:RefreshProgress(progressCount)
    end, PROGRESS_SPEED, 0)
    self.PlayTimerId = XScheduleManager.Schedule(function()
        loopCount = loopCount - 1
        self:PlayFun(loopCount)
    end, XScheduleManager.SECOND, XLivWarmSoundsActivityConfig.GetStageBroadTestTime(self.StageId), 0)
end


function XUiLivWarmSoundsActivity:PlayFun(loopCount)
    if loopCount <= 0 or not self.IsPlaying then
        self:PlayAnimation("StopMusic")
        self.PanelPlayMask.gameObject:SetActiveEx(false)
        self.BtnReplayStop.gameObject:SetActiveEx(false)
        XSoundManager.ResumeMusic()
        self:OnButtonStop()  --播放结束或打断播放需要切换状态
        self:DestroyTimerByTimerId(self.PlayTimerId)
        self:DestroyTimerByTimerId(self.ProgressTimerId)
    end
end

function XUiLivWarmSoundsActivity:PlayTypeWriter(content)
    self.TxtWords.text = content
    self.Mask1.gameObject:SetActiveEx(true)
    self.TxtTypeWriter.CompletedHandle = function()
        self.Mask1.gameObject:SetActiveEx(false)
    end
    --self.TxtTypeWriter.Duration = string.Utf8Len(content) * XMovieConfigs.TYPE_WRITER_SPEED
    self.TxtTypeWriter:Play()
end