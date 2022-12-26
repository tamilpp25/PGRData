local XUiRpgMakerGamePanelWinTip = require("XUi/XUiRpgMakerGame/PlayMain/XUiRpgMakerGamePanelWinTip")
local XUiRpgMakerGamePanelLoseTip = require("XUi/XUiRpgMakerGame/PlayMain/XUiRpgMakerGamePanelLoseTip")
local XUiRpgMakerGameUnlockTip = require("XUi/XUiRpgMakerGame/PlayMain/XUiRpgMakerGameUnlockTip")

local MaxStarCount = XRpgMakerGameConfigs.MaxStarCount
local IsNumberValid = XTool.IsNumberValid
local Vector2 = CS.UnityEngine.Vector2
local Vector2Right = Vector2.right
local mathAbs = math.abs
local CSXTextManagerGetText = CS.XTextManager.GetText
local CSUiButtonStateSelect = CS.UiButtonState.Select
local CSUiButtonStateNormal = CS.UiButtonState.Normal

local RandomDialogBoxIntervalSecond = CS.XGame.ClientConfig:GetFloat("RpgMakerGameRandomDialogBoxIntervalSecond")

--关卡玩法主界面
local XUiRpgMakerGamePlayMain = XLuaUiManager.Register(XLuaUi, "UiRpgMakerGamePlayMain")

function XUiRpgMakerGamePlayMain:OnAwake()
    self.RpgMakerGamePlayScene = XDataCenter.RpgMakerGameManager.GetCurrentScene()

    self:InitGuide()
    self:InitUiCameraEffect()
    self:AutoAddListener()
    self:InitTip()

    self.IsGuideing = false     --是否正在功能引导中
    self.IsPlayingBackoffEffect = false     --是否播放后退特效中
    self.IsTriggerDrag = false  --是否触发拖拽
    self.IsWin = false          --是否胜利
    self:SetCurrUseBackCount(0)   --当前使用后退的次数，重置关卡后，计数重置
    self.TxtWord.text = CSXTextManagerGetText("RpgMakerGamePlayMainIsUseHintDesc")
    self:SetContentAddBtn(false)
    self:SetIconChatActive(false)
    self:SetContentActive(false)
end

function XUiRpgMakerGamePlayMain:OnStart()
    self:InitStarCondition()
    self:InitMaxChallengeCountDesc()

    self.RpgMakerGamePlayScene:PlayAnimation()
end

function XUiRpgMakerGamePlayMain:OnEnable()
    if self.RpgMakerGamePlayScene:IsSceneNil() then
        return
    end
    self:Refresh()
end

function XUiRpgMakerGamePlayMain:OnDisable()
    self.IsPlayingAction = false
    self:StopCheckShowHintTimer()
    self:StopRandomDialogBoxDurationTimer()
end

function XUiRpgMakerGamePlayMain:OnDestroy()
    if self.UiCameraEffect and self.UiCameraEffect:Exist() then
        CS.UnityEngine.GameObject.Destroy(self.UiCameraEffect)
        self.UiCameraEffect = nil
    end
    self.RpgMakerGamePlayScene:RemoveScene()
    XDataCenter.RpgMakerGameManager.ClearStageMap()
end

function XUiRpgMakerGamePlayMain:InitUiCameraEffect()
    local camera = CS.XUiManager.Instance.UiCamera
    local cameraEffectPath = CS.XGame.ClientConfig:GetString("RpgMakerPlayScreenUiCameraEffect")
    local resource = CS.XResourceManager.Load(cameraEffectPath)
    if resource == nil or not resource.Asset then
        XLog.Error(string.format("XUiRpgMakerGamePlayMain:InitUiCameraEffect() 加载:%s失败", cameraEffectPath))
        return
    end

    self.UiCameraEffect = CS.UnityEngine.Object.Instantiate(resource.Asset, camera.transform)
    self.UiCameraEffectStart = XUiHelper.TryGetComponent(self.UiCameraEffect.transform, "Start")
    self.UiCameraEffectStart.gameObject:SetActiveEx(false)
end

function XUiRpgMakerGamePlayMain:InitTip()
    local tipOutCb = handler(self, self.Close)
    local tipNextCb = function()
        local stageId = self:GetStageId()
        local nextStageId = XRpgMakerGameConfigs.GetRpgMakerGameNextStageId(stageId)
        local selectRoleId = self:GetSelectRoleId()
        local cb = function()
            self:SetIsWin(false)
            self:SetCurrUseBackCount(0)
            self:OnStart()
            self:Refresh()
        end
        XDataCenter.RpgMakerGameManager.RequestRpgMakerGameEnterStage(nextStageId, selectRoleId, cb)
    end
    local tipResetCb = handler(self, self.OnBtnResetClick)

    self.WinTip = XUiRpgMakerGamePanelWinTip.New(self.PanelWinTip, tipOutCb, tipNextCb, tipResetCb)
    self.LoseTip = XUiRpgMakerGamePanelLoseTip.New(self.PanelLoseTip, tipOutCb, tipResetCb)
    self.UnlockTip = XUiRpgMakerGameUnlockTip.New(self.PanelUnlockTip)
    self.WinTip:Hide()
    self.LoseTip:Hide()
    self.UnlockTip:Hide()
end

function XUiRpgMakerGamePlayMain:InitMaxChallengeCountDesc()
    local mapId = self:GetMapId()
    if not IsNumberValid(mapId) then
        return
    end
    local desc = XRpgMakerGameConfigs.GetRpgMakerGameMaxRound(mapId)
    self.TextMaxChallenge.text = "/" .. desc
end

function XUiRpgMakerGamePlayMain:InitStarCondition()
    local stageId = self:GetStageId()
    if not IsNumberValid(stageId) then
        return
    end

    local starConditionIdList = XRpgMakerGameConfigs.GetRpgMakerGameStarConditionIdList(stageId)
    local starConditionDesc
    for i, starConditionId in ipairs(starConditionIdList or {}) do
        starConditionDesc = XRpgMakerGameConfigs.GetRpgMakerGameStarConditionDesc(starConditionId)
        self["Task" .. i]:SetName(starConditionDesc)
        self["Task" .. i].gameObject:SetActiveEx(true)
        self["Task" .. i]:SetButtonState(CSUiButtonStateNormal)
    end

    for i = #starConditionIdList + 1, MaxStarCount do
        self["Task" .. i].gameObject:SetActiveEx(false)
    end
end

function XUiRpgMakerGamePlayMain:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnCloseClick)
    self:BindHelpBtn(self.BtnHelp, "RpgMakerGame")
    self:RegisterClickEvent(self.BtnReset, handler(self, self.OnBtnResetClick))
    self:RegisterClickEvent(self.BtnBackoff, handler(self, self.OnBtnBackoffClick))
    self:RegisterClickEvent(self.BtnNo, handler(self, self.OnBtnNoClick))
    self:RegisterClickEvent(self.BtnYes, handler(self, self.OnBtnYesClick))
    self:RegisterClickEvent(self.BtnHead, handler(self, self.OnBtnHeadClick))
    if self.BtnGuideRoleClick then
        self:RegisterClickEvent(self.BtnGuideRoleClick, handler(self, self.OnBtnGuideRoleClick))
    end
    if self.BtnGuideRoadClick then
        self:RegisterClickEvent(self.BtnGuideRoadClick, handler(self, self.OnBtnGuideRoadClick))
    end

    self.GoInputHandler:AddPointerDownListener(function(eventData) self:OnPointerDown(eventData) end)
    self.GoInputHandler:AddDragListener(function(eventData) self:OnDrag(eventData) end)
    self.GoInputHandler:AddPointerUpListener(function(eventData) self:OnPointerUp(eventData) end)
end

function XUiRpgMakerGamePlayMain:Refresh()
    self.TextChallenge.text = XDataCenter.RpgMakerGameManager.GetCurrentCount()
    self:RefreshHint()
    self:RefreshStarCondition()
    self:CheckActions()
end

function XUiRpgMakerGamePlayMain:RefreshStarCondition()
    local stageId = self:GetStageId()
    if not IsNumberValid(stageId) then
        return
    end

    local currentCount = XDataCenter.RpgMakerGameManager.GetCurrentCount()
    local totalDeathCount, normalMonsterDeathCount, bossDeathCount = XDataCenter.RpgMakerGameManager.GetMonsterDeathCount()
    local starConditionIdList = XRpgMakerGameConfigs.GetRpgMakerGameStarConditionIdList(stageId)
    local stepCount
    local monsterCount
    local monsterBossCount
    local monsterTotalCount
    local btnState
    local playableDirector
    local isWin = self:GetIsWin()

    for i, starConditionId in ipairs(starConditionIdList or {}) do
        stepCount = XRpgMakerGameConfigs.GetRpgMakerGameStarConditionStepCount(starConditionId)
        monsterCount = XRpgMakerGameConfigs.GetRpgMakerGameStarConditionMonsterCount(starConditionId)
        monsterBossCount = XRpgMakerGameConfigs.GetRpgMakerGameStarConditionMonsterBossCount(starConditionId)
        monsterTotalCount = monsterCount + monsterBossCount

        if isWin and currentCount <= stepCount then
            btnState = CSUiButtonStateSelect
        elseif XTool.IsNumberValid(monsterCount) and XTool.IsNumberValid(monsterBossCount) then
            btnState = monsterTotalCount <= totalDeathCount and CSUiButtonStateSelect or CSUiButtonStateNormal
        elseif XTool.IsNumberValid(monsterCount) then
            btnState = monsterCount <= normalMonsterDeathCount and CSUiButtonStateSelect or CSUiButtonStateNormal
        elseif XTool.IsNumberValid(monsterBossCount) then
            btnState = monsterBossCount <= bossDeathCount and CSUiButtonStateSelect or CSUiButtonStateNormal
        else
            btnState = CSUiButtonStateNormal
        end

        --播放动画
        if self["Task" .. i].ButtonState ~= btnState then
            self["Task" .. i]:SetButtonState(btnState)
            if btnState == CS.UiButtonState.Select then
                playableDirector = XUiHelper.TryGetComponent(self["Task" .. i].gameObject.transform, "Animation/SleEnable", "PlayableDirector")
                if playableDirector then
                    playableDirector.gameObject:SetActiveEx(false)
                    playableDirector.gameObject:SetActiveEx(true)
                    playableDirector:Play()
                end
            end
        end
    end
end

function XUiRpgMakerGamePlayMain:RefreshHint()
    local isShowHintDialog = self:IsShowHintDialog()
    self:SetContentAddBtn(false)
    self:SetIconChatActive(isShowHintDialog)
    self:SetContentActive(false)
    self:StartCheckShowHintTimer()
end

--检查播放行动动画
function XUiRpgMakerGamePlayMain:CheckActions()
    if self.IsPlayingAction then
        return
    end

    if XDataCenter.RpgMakerGameManager.IsActionsEmpty() then
        return
    end

    self.IsPlayingAction = true

    local action = XDataCenter.RpgMakerGameManager.GetNextAction()
    local actionType = action.ActionType
    local cb = handler(self, self.PlayActionEndCallback)
    local playerObj = XDataCenter.RpgMakerGameManager.GetPlayerObj()
    local endPointObj = XDataCenter.RpgMakerGameManager.GetEndPointObj()
    local monsterObj = XDataCenter.RpgMakerGameManager.GetMonsterObj(action.MonsterId)
    local triggerObj = XDataCenter.RpgMakerGameManager.GetTriggerObj(action.TriggerId)

    if actionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionPlayerMove then
        if playerObj then
            playerObj:PlayMoveAction(action, cb)
        end
        return
    end

    if actionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionKillMonster then
        if playerObj then
            playerObj:PlayKillMonsterAction(action, cb)
        end
        return
    end

    if actionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionStageWin then
        local stageId = self:GetStageId()
        self.WinTip:Show(stageId)
        self:PlayAnimation("PanelWinTipEnable")
        self:SetIsWin(true)
        XDataCenter.RpgMakerGameManager.SetCurrClearButtonGroupIndex()
        cb()
        return
    end

    if actionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionEndPointOpen then
        if endPointObj then
            endPointObj:PlayEndPointStatusChangeAction(action, cb)
        end
        return
    end

    if actionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionMonsterRunAway or actionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionMonsterPatrol then
        if monsterObj then
            monsterObj:RemovePatrolLineObjs()
            monsterObj:RemoveViewAreaModels()
            local moveEndCb = function()
                monsterObj:SetGameObjectViewArea()
                cb()
            end
            monsterObj:PlayMoveAction(action, moveEndCb)
        end
        return
    end

    if actionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionMonsterChangeDirection then
        if monsterObj then
            monsterObj:ChangeDirectionAction(action, cb)
        end
        return
    end

    if actionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionMonsterKillPlayer then
        if monsterObj then
            local killPlayerCb = function()
                local stageId = self:GetStageId()
                self.LoseTip:Show(stageId)
                self:PlayAnimation("PanelLoseTipEnable")
                cb()
            end
            monsterObj:PlayKillPlayerAction(action, killPlayerCb)
        end
        return
    end

    if actionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionTriggerStatusChange then
        if triggerObj then
            triggerObj:PlayTriggerStatusChangeAction(action, cb)
        end
        return
    end

    if actionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionUnlockRole then
        local roleId = action.RoleId
        if IsNumberValid(roleId) then
            self.UnlockTip:Show(roleId)
            self:PlayAnimation("PanelUnlockTipEnable")
        end
        cb()
        return
    end

    if actionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionMonsterPatrolLine then
        if monsterObj then
            monsterObj:SetMoveLine(action)
        end
        cb()
        return
    end

    cb()
end

function XUiRpgMakerGamePlayMain:PlayActionEndCallback()
    self.IsPlayingAction = false
    self:Refresh()
end

--手指按下
function XUiRpgMakerGamePlayMain:OnPointerDown(eventData)
    self.StartDir = eventData.position
end

--拖拽
function XUiRpgMakerGamePlayMain:OnDrag(eventData)
    if not self:IsCanRequest() then
        return
    end

    local playerObj = XDataCenter.RpgMakerGameManager.GetPlayerObj()
    if not playerObj then
        return
    end

    self.IsTriggerDrag = true

    local endDir = eventData.position - self.StartDir
    local angle = Vector2.SignedAngle(Vector2Right, endDir)     --向量转角度，范围：-180度 ~ 180度
    local direction = self:GetDirectionByAngle(angle)
    playerObj:ChangeDirectionAction({Direction = direction})
    playerObj:SetMoveDirectionEffectActive(true)
end

--手指松开
function XUiRpgMakerGamePlayMain:OnPointerUp(eventData)
    local playerObj = XDataCenter.RpgMakerGameManager.GetPlayerObj()
    if playerObj then
        playerObj:SetMoveDirectionEffectActive(false)
    end

    if not self:IsCanRequest() or not self.IsTriggerDrag then
        return
    end

    self.IsTriggerDrag = false

    local endDir = eventData.position - self.StartDir
    local angle = Vector2.SignedAngle(Vector2Right, endDir)     --向量转角度，范围：-180度 ~ 180度
    local mapId = self:GetMapId()
    local direction = self:GetDirectionByAngle(angle)
    XDataCenter.RpgMakerGameManager.RequestRpgMakerGameMapMove(mapId, direction, handler(self, self.Refresh))
end

--根据角度返回对应的方向
function XUiRpgMakerGamePlayMain:GetDirectionByAngle(angle)
    local direction
    if angle >= -45 and angle < 45 then
        direction = XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveRight
    elseif angle >= 45 and angle < 135 then
        direction = XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveUp
    elseif angle >= 135 or angle < -135 then
        direction = XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveLeft
    elseif angle >= -135 and angle < -45 then
        direction = XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveDown
    end
    return direction
end

function XUiRpgMakerGamePlayMain:OnBtnResetClick()
    if not self:IsCanRequest() then
        return false
    end

    local mapId = self:GetMapId()
    local cb = function()
        self.IsPlayingAction = false
        self.RpgMakerGamePlayScene:Reset()
        self:SetIsWin(false)
        self:SetCurrUseBackCount(0)
        self:Refresh()
    end
    XDataCenter.RpgMakerGameManager.RequestRpgMakerGameMapResetGame(mapId, cb)
    return true
end

function XUiRpgMakerGamePlayMain:OnBtnBackoffClick()
    if not self:IsCanRequest() then
        return
    end

    self:PlayBackoffEffect()
    
    local mapId = self:GetMapId()
    local cb = function(currentRound)
        self:SetCurrUseBackCount(self.CurrUseBackCount + 1)
        self.RpgMakerGamePlayScene:BackUp(currentRound)
        self:Refresh()
    end
    XDataCenter.RpgMakerGameManager.RequestRpgMakerGameMapBackUp(mapId, cb)
end

function XUiRpgMakerGamePlayMain:OnBtnCloseClick()
    local sureCallback = function()
        self:Close()
    end
    XUiManager.DialogTip(CSXTextManagerGetText("TipTitle"), CSXTextManagerGetText("RpgMakerGamePlayMainQuickTipsDesc"), nil, nil, sureCallback)
end

--所有动作播完才能发协议
function XUiRpgMakerGamePlayMain:IsCanRequest()
    if not XDataCenter.RpgMakerGameManager.IsActionsEmpty() or self.IsPlayingAction or self.IsPlayingBackoffEffect or self.IsGuideing then
        return false
    end
    return true
end

--------------------------提示相关 begin---------------------------
--确定使用提示
function XUiRpgMakerGamePlayMain:OnBtnYesClick()
    self:OnBtnNoClick()
    local mapId = self:GetMapId()
    XLuaUiManager.Open("UiRpgMakerGameMapTip", mapId)
end

--取消使用提示
function XUiRpgMakerGamePlayMain:OnBtnNoClick()
    self:SetContentAddBtn(false)
    self:SetIconChatActive(true)
end

function XUiRpgMakerGamePlayMain:OnBtnHeadClick()
    if self:IsShowHintDialog() then
        self:SetContentAddBtn(true)
        self:SetIconChatActive(false)
    else
        local stageId = self:GetStageId()
        self.TextHint.text = XRpgMakerGameConfigs.GetRpgMakerGameHintDialogBoxText(stageId)
        self:SetContentActive(true)
    end

    self:StartCheckShowHintTimer()
end

--延迟一段时间显示随机提示语
function XUiRpgMakerGamePlayMain:StartCheckShowHintTimer()
    self:StopCheckShowHintTimer()
    self:StopRandomDialogBoxDurationTimer()
    if self:IsShowHintDialog() then
        return
    end

    local duration = RandomDialogBoxIntervalSecond
    self.CheckShowHintTimer = XScheduleManager.ScheduleForever(function()
        duration = duration - 1
        if duration <= 0 then
            self:StopCheckShowHintTimer()
            self:ShowRandomHintDialog()
        end
    end, XScheduleManager.SECOND)
end

function XUiRpgMakerGamePlayMain:StopCheckShowHintTimer()
    if self.CheckShowHintTimer then
        XScheduleManager.UnSchedule(self.CheckShowHintTimer)
        self.CheckShowHintTimer = nil
    end
end

function XUiRpgMakerGamePlayMain:ShowRandomHintDialog()
    local id = XDataCenter.RpgMakerGameManager.GetRandomDialogBoxId()
    local text = XRpgMakerGameConfigs.GetRpgMakerGameRandomDialogBoxText(id)
    self.TextHint.text = text
    self:SetContentActive(true)
    self:StartRandomDialogBoxDurationTimer(id)
end

function XUiRpgMakerGamePlayMain:SetContentAddBtn(isActive)
    self.ContentAddBtn.gameObject:SetActiveEx(isActive)
end

function XUiRpgMakerGamePlayMain:SetContentActive(isActive)
    self.Content.gameObject:SetActiveEx(isActive)
    if isActive then
        self.ContentDynamicGrid:SetAllLayoutDirty()
    end
end

function XUiRpgMakerGamePlayMain:SetIconChatActive(isActive)
    self.IconChat.gameObject:SetActiveEx(isActive)
end

--显示一段时间的随机提示语
function XUiRpgMakerGamePlayMain:StartRandomDialogBoxDurationTimer(randomdialogBoxId)
    self:StopRandomDialogBoxDurationTimer()

    local duration = XRpgMakerGameConfigs.GetRpgMakerGameRandomDialogBoxDuration(randomdialogBoxId)
    self.RandomDialogBoxDurationTimer = XScheduleManager.ScheduleForever(function()
        duration = duration - 1
        if duration <= 0 then
            self:SetContentActive(false)
            self:StartCheckShowHintTimer()
        end
    end, XScheduleManager.SECOND)
end

function XUiRpgMakerGamePlayMain:StopRandomDialogBoxDurationTimer()
    if self.RandomDialogBoxDurationTimer then
        XScheduleManager.UnSchedule(self.RandomDialogBoxDurationTimer)
        self.RandomDialogBoxDurationTimer = nil
    end
end

--是否停止随机对话，显示通关路线对话
function XUiRpgMakerGamePlayMain:IsShowHintDialog()
    local currUseBackCount = self:GetCurrUseBackCount()
    local stageId = self:GetStageId()
    local backCount = XRpgMakerGameConfigs.GetRpgMakerGameHintDialogBoxBackCount(stageId)
    return currUseBackCount >= backCount
end

function XUiRpgMakerGamePlayMain:SetCurrUseBackCount(currUseBackCount)
    self.CurrUseBackCount = currUseBackCount
end
--------------------------提示相关 end---------------------------

function XUiRpgMakerGamePlayMain:GetStageId()
    local enterStageDb = XDataCenter.RpgMakerGameManager:GetRpgMakerGameEnterStageDb()
    return enterStageDb:GetStageId()
end

function XUiRpgMakerGamePlayMain:GetSelectRoleId()
    local enterStageDb = XDataCenter.RpgMakerGameManager:GetRpgMakerGameEnterStageDb()
    return enterStageDb:GetSelectRoleId()
end

function XUiRpgMakerGamePlayMain:GetMapId()
    local enterStageDb = XDataCenter.RpgMakerGameManager:GetRpgMakerGameEnterStageDb()
    return enterStageDb:GetMapId()
end

function XUiRpgMakerGamePlayMain:GetCurrUseBackCount()
    return self.CurrUseBackCount
end

function XUiRpgMakerGamePlayMain:SetIsWin(isWin)
    self.IsWin = isWin
end

function XUiRpgMakerGamePlayMain:GetIsWin()
    return self.IsWin
end

function XUiRpgMakerGamePlayMain:PlayBackoffEffect()
    if XTool.UObjIsNil(self.UiCameraEffectStart) then
        return
    end

    self.IsPlayingBackoffEffect = true
    self.UiCameraEffectStart.gameObject:SetActiveEx(false)
    self.UiCameraEffectStart.gameObject:SetActiveEx(true)

    local time = CS.XGame.ClientConfig:GetInt("RpgMakerPlayScreenPlayUiCameraEffectTime")
    XScheduleManager.ScheduleOnce(function()
        if XTool.UObjIsNil(self.UiCameraEffectStart) then
            self.UiCameraEffectStart.gameObject:SetActiveEx(false)
            return
        end
        self.IsPlayingBackoffEffect = false
    end, time)
end

----------------------引导相关 begin-----------------------
function XUiRpgMakerGamePlayMain:InitGuide()
    local offsetY = 50

    local playerObj = XDataCenter.RpgMakerGameManager.GetPlayerObj()
    local modelPosotion = playerObj and playerObj:GetGameObjPosition()
    local localPosition = modelPosotion and self:WorldToUILocaPosition(modelPosotion)
    if localPosition then
        localPosition.y = localPosition.y + offsetY
    end

    --设置按钮到角色模型所在的位置
    if self.BtnGuideRoleClick and localPosition then
        self.BtnGuideRoleClick.transform.localPosition = localPosition
    end
    if self.BtnGuideRoadClick and localPosition then
        local height = self.BtnGuideRoadClick.transform.rect.height
        localPosition. y = height / 2
        self.BtnGuideRoadClick.transform.localPosition = localPosition
    end

    --设置按钮到终点所在的位置
    local endPointObj = XDataCenter.RpgMakerGameManager.GetEndPointObj()
    modelPosotion = endPointObj and endPointObj:GetGameObjPosition()
    localPosition = modelPosotion and self:WorldToUILocaPosition(modelPosotion)
    if self.BtnGuideEndPointClick and localPosition then
        self.BtnGuideEndPointClick.transform.localPosition = localPosition
    end

    --设置按钮到怪物所在的位置
    local mapId = self:GetMapId()
    local monsterIdList = XRpgMakerGameConfigs.GetRpgMakerGameMapIdToMonsterIdList(mapId)
    local monsterId = monsterIdList[1]
    local monsterObj = XDataCenter.RpgMakerGameManager.GetMonsterObj(monsterId)
    modelPosotion = monsterObj and monsterObj:GetGameObjPosition()
    localPosition = modelPosotion and self:WorldToUILocaPosition(modelPosotion)
    if localPosition then
        localPosition.y = localPosition.y + offsetY
    end
    if self.BtnGuideMonsterClick and localPosition then
        self.BtnGuideMonsterClick.transform.localPosition = localPosition
    end
end

function XUiRpgMakerGamePlayMain:OnBtnGuideRoleClick()
    self.IsGuideing = true
    local playerObj = XDataCenter.RpgMakerGameManager.GetPlayerObj()
    if not playerObj then
        return
    end

    playerObj:ChangeDirectionAction({Direction = XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveDown})
    playerObj:SetMoveDirectionEffectActive(true)
end

function XUiRpgMakerGamePlayMain:OnBtnGuideRoadClick()
    self.IsGuideing = false
    local playerObj = XDataCenter.RpgMakerGameManager.GetPlayerObj()
    if playerObj then
        playerObj:SetMoveDirectionEffectActive(false)
    end

    local mapId = self:GetMapId()
    local direction = XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveDown
    XDataCenter.RpgMakerGameManager.RequestRpgMakerGameMapMove(mapId, direction, handler(self, self.Refresh))
end

--世界坐标-> UGUI坐标
function XUiRpgMakerGamePlayMain:WorldToUILocaPosition(modelPosotion)
    local sceneCamera = self.RpgMakerGamePlayScene:GetSceneCamera()
    local viewportPos = sceneCamera:WorldToViewportPoint(modelPosotion)
    local realScreenWidth = CsXUiManager.RealScreenWidth
    local realScreenHeight = CsXUiManager.RealScreenHeight

    return CS.UnityEngine.Vector3((viewportPos.x - 0.5) * realScreenWidth, (viewportPos.y - 0.5) * realScreenHeight, 0)
end
----------------------引导相关 end-----------------------