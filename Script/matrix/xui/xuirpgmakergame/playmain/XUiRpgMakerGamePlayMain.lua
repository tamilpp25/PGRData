local XUiRpgMakerGamePanelWinTip = require("XUi/XUiRpgMakerGame/PlayMain/XUiRpgMakerGamePanelWinTip")
local XUiRpgMakerGamePanelLoseTip = require("XUi/XUiRpgMakerGame/PlayMain/XUiRpgMakerGamePanelLoseTip")
local XUiRpgMakerGameUnlockTip = require("XUi/XUiRpgMakerGame/PlayMain/XUiRpgMakerGameUnlockTip")
local XUiRpgMakerGamePanelDetailTip = require("XUi/XUiRpgMakerGame/PlayMain/XUiRpgMakerGamePanelDetailTip")
local XUiRpgMakeGamePanelAddBtnTwo = require("XUi/XUiRpgMakerGame/PlayMain/XUiRpgMakeGamePanelAddBtnTwo")
local XUiRpgMakerGameRoleMove = require("XUi/XUiRpgMakerGame/PlayMain/XUiRpgMakerGameRoleMove")

local MaxStarCount = XRpgMakerGameConfigs.MaxStarCount
local IsNumberValid = XTool.IsNumberValid
local Vector3 = CS.UnityEngine.Vector3
local Vector2 = CS.UnityEngine.Vector2
local Vector3Right = Vector3.right
local Vector3Forward = Vector3.forward
local mathAbs = math.abs
local CSXTextManagerGetText = CS.XTextManager.GetText
local CSUiButtonStateSelect = CS.UiButtonState.Select
local CSUiButtonStateNormal = CS.UiButtonState.Normal
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate
local CSUnityEngineObjectDestroy = CS.UnityEngine.Object.Destroy

local RandomDialogBoxIntervalSecond = CS.XGame.ClientConfig:GetFloat("RpgMakerGameRandomDialogBoxIntervalSecond")
local DownHintStayTime = CS.XGame.ClientConfig:GetInt("RpgMakerGamePlayMainDownHintStayTime")
local MoveRoleAngleOffset = CS.XGame.ClientConfig:GetInt("RpgMakerGameMoveRoleAngleOffset")     --移动角色的手势角度偏移
local PLAY_ANIMA_INTERVAL = XRpgMakerGameConfigs.PlayAnimaInterval

--关卡玩法主界面
local XUiRpgMakerGamePlayMain = XLuaUiManager.Register(XLuaUi, "UiRpgMakerGamePlayMain")

function XUiRpgMakerGamePlayMain:OnAwake()
    XUiHelper.NewPanelActivityAsset({XDataCenter.ItemManager.ItemId.RpgMakerGameHintCoin}, self.PanelSpecialTool)
    self.RpgMakerGamePlayScene = XDataCenter.RpgMakerGameManager.GetCurrentScene()

    self:InitGuide()
    self:InitUiCameraEffect()
    self:AutoAddListener()
    self:InitTip()
    self:InitPanelAddBtnTwo()
    self:InitPanelRoleMoveUI()

    self.TextSentryRoandMap = {}    --显示哨戒剩余回合数的文本控件字典
    self.IsGuideing = false     --是否正在功能引导中
    self.IsPlayingBackoffEffect = false     --是否播放后退特效中
    self.IsTriggerDrag = false  --是否触发拖拽
    self.IsWin = false          --是否胜利
    self:SetCurrUseBackCount(0)   --当前使用后退的次数，重置关卡后，计数重置
    self:SetCurrResetCount(0)   --当前累计使用重置的次数
    self:SetCurrLoseCount(0)    --当前累计失败次数，有通关记录则不累计
    self.TxtWord.text = CSXTextManagerGetText("RpgMakerGamePlayMainIsUseHintDesc")
    self:SetContentAddBtn(false)
    self:SetIconChatActive(false)
    self:SetContentActive(false)
end

function XUiRpgMakerGamePlayMain:OnStart()
    XDataCenter.RpgMakerGameManager.SetClickObjectCallback(function(modelKey, modelName) self:ShowObjectTips(modelKey, modelName) end)
    XDataCenter.RpgMakerGameManager.SetPointerDownObjectCallback(function() self.PanelRoleMoveUI:SetIsIgnoreUi(true) end)
    XDataCenter.RpgMakerGameManager.SetPointerUpObjectCallback(function() self.PanelRoleMoveUI:SetIsIgnoreUi(false) end)

    self:InitTextSentryRoandMap()
    self:InitStarCondition()
    self:InitMaxChallengeCountDesc()

    self.RpgMakerGamePlayScene:PlayAnimation()
end

function XUiRpgMakerGamePlayMain:OnEnable()
    if self.RpgMakerGamePlayScene:IsSceneNil() then
        return
    end
    self:Refresh()
    self:StartDownHintTimer()
end

function XUiRpgMakerGamePlayMain:OnDisable()
    self.IsPlayingAction = false
    self:StopCheckShowHintTimer()
    self:StopRandomDialogBoxDurationTimer()
    self:StopDownHintTimer()
    self.DetailTip:Hide()
    self.DetailTip:SetActive(false)
end

function XUiRpgMakerGamePlayMain:OnDestroy()
    if self.UiCameraEffect and self.UiCameraEffect:Exist() then
        CS.UnityEngine.GameObject.Destroy(self.UiCameraEffect)
        self.UiCameraEffect = nil
    end
    self.RpgMakerGamePlayScene:RemoveScene()
    XDataCenter.RpgMakerGameManager.ClearStageMap()
    self:StopGrassAnimTimer()
    self:StopGrassGrowAnimTimer()

    if self.Resource then
        CS.XResourceManager.Unload(self.Resource)
        self.Resource = nil
    end
end


--#region 对象初始化

function XUiRpgMakerGamePlayMain:InitTextSentryRoandMap()
    for _, textSentryRoand in pairs(self.TextSentryRoandMap) do
        CSUnityEngineObjectDestroy(textSentryRoand)
    end
    self.TextSentryRoandMap = {}
end

function XUiRpgMakerGamePlayMain:InitPanelRoleMoveUI()
    local beginDragCb = function(touchPosition) self:OnPointerDown(touchPosition) end
    local onDragCb = function(touchPosition) self:OnDrag(touchPosition) end
    local endDragCb = function(touchPosition) self:OnPointerUp(touchPosition) end
    self.PanelRoleMoveUI = XUiRpgMakerGameRoleMove.New(self, self.GameObject:GetComponent("RectTransform"), beginDragCb, onDragCb, endDragCb)
end

function XUiRpgMakerGamePlayMain:InitUiCameraEffect()
    local camera = CS.XUiManager.Instance.UiCamera
    local cameraEffectPath = CS.XGame.ClientConfig:GetString("RpgMakerPlayScreenUiCameraEffect")
    self.Resource = self.Resource or CS.XResourceManager.Load(cameraEffectPath)
    if self.Resource == nil or not self.Resource.Asset then
        XLog.Error(string.format("XUiRpgMakerGamePlayMain:InitUiCameraEffect() 加载:%s失败", cameraEffectPath))
        return
    end

    self.UiCameraEffect = CS.UnityEngine.Object.Instantiate(self.Resource.Asset, camera.transform)
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
            self:SetCurrResetCount(0)
            self:SetCurrLoseCount(0)
            self:OnStart()
            self:Refresh()
        end
        XDataCenter.RpgMakerGameManager.RequestRpgMakerGameEnterStage(nextStageId, selectRoleId, cb)
    end
    local tipResetCb = handler(self, self.OnBtnResetClick)

    self.WinTip = XUiRpgMakerGamePanelWinTip.New(self.PanelWinTip, tipOutCb, tipNextCb, tipResetCb)
    self.LoseTip = XUiRpgMakerGamePanelLoseTip.New(self.PanelLoseTip, tipOutCb, tipResetCb)
    self.UnlockTip = XUiRpgMakerGameUnlockTip.New(self.PanelUnlockTip)
    self.DetailTip = XUiRpgMakerGamePanelDetailTip.New(self.PanelDetailTip, self)
    self.WinTip:Hide()
    self.LoseTip:Hide()
    self.UnlockTip:Hide()
    self.DetailTip:SetActive(false)
end

function XUiRpgMakerGamePlayMain:InitPanelAddBtnTwo()
    local closeCb = function()
        self:CheckIconChatActive()
        self:StartCheckShowHintTimer()
    end
    local clickHintCb = function()
        self:SetIconChatActive(false)
        self:ShowHintDialog()
        self:StartRandomDialogBoxDurationTimer()
    end
    self.PanelAddBtnTwo = XUiRpgMakeGamePanelAddBtnTwo.New(self.ContentAddBtnTwo, closeCb, clickHintCb)
    self.PanelAddBtnTwo:Hide(true)
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
    for i, starConditionId in ipairs(starConditionIdList) do
        starConditionDesc = XRpgMakerGameConfigs.GetRpgMakerGameStarConditionDesc(starConditionId)
        self["Task" .. i]:SetName(starConditionDesc)
        self["Task" .. i].gameObject:SetActiveEx(true)
        self["Task" .. i]:SetButtonState(CSUiButtonStateNormal)
    end

    for i = #starConditionIdList + 1, MaxStarCount do
        self["Task" .. i].gameObject:SetActiveEx(false)
    end
end

--#endregion



--#region 按钮相关

function XUiRpgMakerGamePlayMain:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnCloseClick)
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

    local curChapterGroupId = XDataCenter.RpgMakerGameManager.GetCurChapterGroupId()
    self:BindHelpBtn(self.BtnHelp, XRpgMakerGameConfigs.GetChapterGroupHelpKey(curChapterGroupId))
end

---关闭关卡
function XUiRpgMakerGamePlayMain:OnBtnCloseClick()
    local sureCallback = function()
        self:Close()
    end
    XUiManager.DialogTip(CSXTextManagerGetText("TipTitle"), CSXTextManagerGetText("RpgMakerGamePlayMainQuickTipsDesc"), nil, nil, sureCallback)
end

---重置关卡
function XUiRpgMakerGamePlayMain:OnBtnResetClick()
    if not self:IsCanRequest() then
        return false
    end

    local curCount = XDataCenter.RpgMakerGameManager.GetCurrentCount()
    if XTool.IsNumberValid(curCount) then
        self:SetCurrResetCount(self.CurrResetCount + 1)
    end

    local mapId = self:GetMapId()
    local cb = function()
        self.IsPlayingAction = false
        self.RpgMakerGamePlayScene:Reset()
        self:SetIsWin(false)
        self:Refresh()
    end
    XDataCenter.RpgMakerGameManager.RequestRpgMakerGameMapResetGame(mapId, cb)
    return true
end

---悔棋
function XUiRpgMakerGamePlayMain:OnBtnBackoffClick()
    if not self:IsCanRequest() then
        return
    end

    self:PlayBackoffEffect()
    
    local mapId = self:GetMapId()
    local cb = function(currentRound)
        self:SetCurrUseBackCount(self.CurrUseBackCount + 1)
        self.RpgMakerGamePlayScene:BackUp(currentRound)
        self.RpgMakerGamePlayScene:CheckGrowActive(currentRound)
        self:Refresh()
    end
    XDataCenter.RpgMakerGameManager.RequestRpgMakerGameMapBackUp(mapId, cb)
end

---确定弹出第二提示窗口
function XUiRpgMakerGamePlayMain:OnBtnYesClick()
    self:SetContentAddBtn(false)
    self.PanelAddBtnTwo:Show(self:GetStageId())
end

---取消使用提示
function XUiRpgMakerGamePlayMain:OnBtnNoClick()
    self:SetContentAddBtn(false)
    self:CheckIconChatActive()
    self:StartCheckShowHintTimer()
end

---过关提示
function XUiRpgMakerGamePlayMain:OnBtnHeadClick()
    self:SetContentAddBtn(true)
    self:SetIconChatActive(false)
    self:SetContentActive(false)

    self:StartCheckShowHintTimer(true)
end

--#endregion



--#region Ui刷新相关

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

    local starConditionIdList = XRpgMakerGameConfigs.GetRpgMakerGameStarConditionIdList(stageId)
    local btnState
    local playableDirector
    local isWin = self:GetIsWin()

    for i, starConditionId in ipairs(starConditionIdList) do
        btnState = XDataCenter.RpgMakerGameManager.IsStarConditionClear(starConditionId, isWin) and CSUiButtonStateSelect or CSUiButtonStateNormal

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
    self.PanelAddBtnTwo:Hide(true)
    self:SetContentAddBtn(false)
    self:CheckIconChatActive()
    self:SetContentActive(false)
    self:StartCheckShowHintTimer()
end

--检查播放行动动画
function XUiRpgMakerGamePlayMain:CheckActions()
    if self.IsPlayingAction then
        return
    end

    if XDataCenter.RpgMakerGameManager.IsActionsEmpty() then
        self:UpdateSentrySign()
        self:CheckMonsertViewAreaAndLine()
        self:CheckWaterState()

        -- 结束结算清空草丛计时器
        self:StopGrassAnimTimer()
        self:StopGrassGrowAnimTimer()
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
    local shadowObj = XDataCenter.RpgMakerGameManager.GetShadowObj(action.ShadowId)
    local entityObj = XDataCenter.RpgMakerGameManager.GetEntityObj(action.EntityId)

    local gameOverCb = function()
        self:GameOver(actionType)
        cb()
    end

    local monsterDeathCb = function()
        self:HideSentrySignText(action.MonsterId)
        cb()
    end

    if actionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionPlayerMove then
        --角色和影子同时移动
        local moveEndCount = 0
        local moveEndCb = function()
            moveEndCount = moveEndCount + 1
            if moveEndCount >= 2 then
                cb()
            end
        end

        local burnActions = XDataCenter.RpgMakerGameManager.GetActions(XRpgMakerGameConfigs.RpgMakerGameActionType.ActionBurnGrass)
        local growActions = XDataCenter.RpgMakerGameManager.GetActions(XRpgMakerGameConfigs.RpgMakerGameActionType.ActionGrowGrass)

        self:CheckActionShadowMove(function()
            -- 4.0:把草丛燃烧改成本体或影子各自移动结束各自处理吧
            -- 移动结束后回调两层：一层燃烧一层生长
            self:CheckGrassAnimInEndMove(function()
                self:CheckGrassAnimInEndMove(moveEndCb, growActions, false, false)
            end, burnActions, false, true)
        end)
        if playerObj then
            playerObj:PlayMoveAction(action, function()
                self:CheckGrassAnimInEndMove(function()
                    self:CheckGrassAnimInEndMove(moveEndCb, growActions, true, false)
                end, burnActions, true, true)
            end, self:GetMapId())
            return
        end
    end

    if actionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionKillMonster then
        if playerObj then
            playerObj:PlayKillMonsterAction(action, monsterDeathCb)
            return
        end
    end

    if actionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionStageWin then
        local stageId = self:GetStageId()
        self.WinTip:Show(stageId)
        self:PlayAnimation("PanelWinTipEnable")
        self:SetIsWin(true)
        XDataCenter.RpgMakerGameManager.SetCurrClearButtonGroupIndex()
    end

    if actionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionEndPointOpen then
        if endPointObj then
            endPointObj:PlayEndPointStatusChangeAction(action, cb)
            return
        end
    end

    if actionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionMonsterRunAway or actionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionMonsterPatrol then
        if monsterObj then
            monsterObj:RemoveViewAreaAndLine()
            local moveEndCb = function()
                monsterObj:SetViewAreaAndLine()
                monsterObj:CheckRemoveSentry()
                self:UpdateSentrySign(action.MonsterId)
                cb()
            end
            monsterObj:PlayMoveAction(action, moveEndCb, self:GetMapId())
        end
        return
    end

    if actionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionMonsterChangeDirection then
        if monsterObj then
            monsterObj:RemoveViewAreaAndLine()
            local endCb = function()
                monsterObj:SetViewAreaAndLine()
                monsterObj:CheckRemoveSentry()
                self:UpdateSentrySign(action.MonsterId)
                cb()
            end
            monsterObj:ChangeDirectionAction(action, endCb)
            return
        end
    end

    if actionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionMonsterKillPlayer then
        if monsterObj then
            monsterObj:PlayKillPlayerAction(action, gameOverCb)
        end
        return
    end

    if actionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionTriggerStatusChange then
        if triggerObj then
            triggerObj:PlayTriggerStatusChangeAction(action, cb)
            return
        end
    end

    if actionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionUnlockRole then
        local roleId = action.RoleId
        if IsNumberValid(roleId) then
            self.UnlockTip:Show(roleId)
            self:PlayAnimation("PanelUnlockTipEnable")
        end
    end

    if actionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionMonsterPatrolLine then
        if monsterObj then
            monsterObj:SetMoveLine(action)
        end
    end

    if actionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionShadowDieByTrap then
        if shadowObj then
            shadowObj:PlayDieByTrapAnima(cb)
            return
        end
    end

    if actionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionPlayerDieByTrap then
        if playerObj then
            playerObj:PlayDieByTrapAnima(gameOverCb)
            return
        end
    end

    if actionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionMonsterDieByTrap then
        if monsterObj then
            monsterObj:PlayDieByTrapAnima(monsterDeathCb)
            return
        end
    end

    if actionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionElectricStatusChange then
        local electricFenceObjDic = XDataCenter.RpgMakerGameManager.GetElectricFenceObjDic()
        for _, obj in pairs(electricFenceObjDic) do
            obj:PlayElectricFenceStatusChangeAction()
        end
    end

    if actionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionPlayerKillByElectricFence then
        if playerObj then
            playerObj:PlayKillByElectricFenceAnima(gameOverCb)
            return
        end
    end

    if actionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionMonsterKillByElectricFence then
        if monsterObj then
            monsterObj:PlayKillByElectricFenceAnima(monsterDeathCb)
            return
        end
    end

    if actionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionHumanKill then
        if monsterObj then
            monsterObj:PlayBeAtkAction(gameOverCb)
            return
        end
    end

    if actionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionPlayerTransfer then
        local nextAction = XDataCenter.RpgMakerGameManager.GetNextAction(true)
        local endPosX = nextAction and nextAction.StartPosition.PositionX or action.EndPosition.PositionX
        local endPosY = nextAction and nextAction.StartPosition.PositionY or action.EndPosition.PositionY
        playerObj:PlayTransfer(action.StartPosition.PositionX, 
                action.StartPosition.PositionY,
                endPosX,
                endPosY,
                cb)
        return
    end

    -- if actionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionBurnGrass then
    --     self:GrassBurn(action, cb)
    --     return
    -- end

    -- if actionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionGrowGrass then
    --     self:GrassGrow(action, cb)
    --     return
    -- end

    if actionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionPlayerDrown then
        playerObj:DieByDrown(self:GetMapId(), playerObj:GetPositionX(), playerObj:GetPositionY())
        playerObj:PlayDrownAnima(gameOverCb)
        return
    end

    if actionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionMonsterDrown then
        if monsterObj then
            monsterObj:DieByDrown(self:GetMapId(), monsterObj:GetPositionX(), monsterObj:GetPositionY())
            monsterObj:PlayDrownAnima(monsterDeathCb, true)
            return
        end
    end

    if actionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionSteelBrokenToTrap
        or actionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionSteelBrokenToFlat then
        entityObj = XDataCenter.RpgMakerGameManager.GetSteelObj(action.EntityId)
        if entityObj and entityObj.CheckPlayFlat then
            entityObj:CheckPlayFlat()
        end
    end

    if actionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionMonsterTransfer then
        local nextAction = XDataCenter.RpgMakerGameManager.GetNextAction(true)
        local endPosX = nextAction and nextAction.StartPosition.PositionX or action.EndPosition.PositionX
        local endPosY = nextAction and nextAction.StartPosition.PositionY or action.EndPosition.PositionY
        if monsterObj then
            monsterObj:PlayTransfer(action.StartPosition.PositionX, 
                action.StartPosition.PositionY,
                endPosX,
                endPosY,
                cb)
            return
        end
        return
    end

    if actionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionShadowKillByElectricFence then
        if shadowObj then
            shadowObj:PlayKillByElectricFenceAnima(cb)
            return
        end
        return
    end

    if actionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionMonsterKillShadow then
        if monsterObj then
            monsterObj:PlayKillShadowAction(action, cb)
        end
        return
    end

    if actionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionShadowDrown then
        if shadowObj then
            shadowObj:DieByDrown(self:GetMapId(), shadowObj:GetPositionX(), shadowObj:GetPositionY())
            shadowObj:PlayDrownAnima(cb)
        else
            if cb then cb() end
        end
        return
    end

    if actionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionBubbleBroken then
        local bubbleId = action.EntityId
        local bubbleObj = XDataCenter.RpgMakerGameManager.GetBubbleObj(bubbleId)
        if bubbleObj then
            bubbleObj:SetIsBroken(true)
            bubbleObj:PlayBubbleBrokenEffect()
        end
        if shadowObj then
            shadowObj:PlayAtkAction(cb)
            return
        end
        if playerObj then
            playerObj:PlayAtkAction(cb)
            return
        end
    end

    if actionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionBubbleMove then
        local bubbleId = action.EntityId
        local bubbleObj = XDataCenter.RpgMakerGameManager.GetBubbleObj(bubbleId)
        if bubbleObj then
            bubbleObj:PlayMoveAction(action, nil, self:GetMapId())
        end
        if shadowObj then
            local callBack = function()
                local endCube = shadowObj:GetCubeObj(action.StartPosition.PositionY, action.StartPosition.PositionX)
                local endCubePosition = endCube:GetGameObjUpCenterPosition()
                shadowObj:SetGameObjectPosition(endCubePosition)
                if cb then cb() end
            end
            shadowObj:PlayPushBubbleAnim(callBack)
            return
        end
        if playerObj then
            local callBack = function()
                local endCube = playerObj:GetCubeObj(action.StartPosition.PositionY, action.StartPosition.PositionX)
                local endCubePosition = endCube:GetGameObjUpCenterPosition()
                playerObj:SetGameObjectPosition(endCubePosition)
                if cb then cb() end
            end
            playerObj:PlayPushBubbleAnim(callBack)
            return
        end
    end

    if actionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionShadowPickupDrop then
        local callBack  = function()
            local entityId = action.EntityId
            local dropObj = XDataCenter.RpgMakerGameManager.GetDropObj(entityId)
            dropObj:SetPickUp(true)
            if cb then cb() end
        end
        if shadowObj then
            shadowObj:PlayPickUpAnim(callBack)
        end
        return
    end

    if actionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionPlayerPickupDrop then
        if playerObj then
            playerObj:PlayPickUpAnim(cb)
        end
        local entityId = action.EntityId
        local dropObj = XDataCenter.RpgMakerGameManager.GetDropObj(entityId)
        dropObj:SetPickUp(true)
        return
    end

    if actionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionMagicTrigger then
        if shadowObj then
            shadowObj:PlayMagicTransferAnim(
                action.ShadowNewPosition.PositionX,
                action.ShadowNewPosition.PositionY)
        end
        if playerObj then
            playerObj:PlayMagicTransferAnim(
                action.PlayerNewPosition.PositionX,
                action.PlayerNewPosition.PositionY,
                cb)
        end
        return
    end

    if actionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionShadowKillMonster then
        if shadowObj then
            shadowObj:PlayKillMonsterAction(action, monsterDeathCb)
            return
        end
    end

    cb()
end

--#endregion


---移动结束后检查草丛动画
function XUiRpgMakerGamePlayMain:CheckGrassAnimInEndMove(cb, actions, isPlayer, isBurn)
    local endCb = cb
    if XTool.IsTableEmpty(actions) then
        endCb()
        return
    end

    local actionCount = #actions
    local onceActionEndCb = function()
        actionCount = actionCount - 1
        if actionCount <= 0 then
            endCb()
        end
    end

    for _, action in ipairs(actions) do
        local isShaodow = XTool.IsNumberValid(action.ShadowId)
        if (isPlayer and not isShaodow) or (not isPlayer and isShaodow) then
            if isBurn then
                self:GrassBurn(action, onceActionEndCb)
            else
                self:GrassGrow(action, onceActionEndCb)
            end
        else
            endCb()
            return
        end
    end
end

---草丛生长
function XUiRpgMakerGamePlayMain:GrassGrow(action, cb)
    local grassObj
    local GrassFunc = function(grass)
        if not grass then
            return
        end
        grassObj = XDataCenter.RpgMakerGameManager.GetEntityObjByPosition(grass.PositionX, grass.PositionY, XRpgMakerGameConfigs.XRpgMakeBlockMetaType.Grass)
        if grassObj then
            grassObj:SetActive(true)
        else
            self.RpgMakerGamePlayScene:GrowGrass(grass.PositionX, grass.PositionY)
        end
    end

    local grass = table.remove(action.Grass, 1)
    GrassFunc(grass)
    local loop = #action.Grass
    if loop <= 0 then
        cb()
        return
    end

    --间隔一段时间生长
    local timer = XScheduleManager.Schedule(function()
        grass = table.remove(action.Grass, 1)
        GrassFunc(grass)
        --等最后一个播完再继续
        if XTool.IsTableEmpty(action.Grass) then
            XScheduleManager.ScheduleOnce(function()
                if XTool.UObjIsNil(self.GameObject) then
                    return
                end
                cb()
            end, CS.XGame.ClientConfig:GetInt("RpgMakerGameDieByTrapTime"))
        end
    end, PLAY_ANIMA_INTERVAL, loop)
    table.insert(self.GrassGrowAnimTimer, timer)
end

---草丛燃烧
function XUiRpgMakerGamePlayMain:GrassBurn(action, cb)
    local grassObj
    local mapId = self:GetMapId()

    local BurnFunc = function(grass)
        if not grass then
            return
        end
        grassObj = XDataCenter.RpgMakerGameManager.GetEntityObjByPosition(grass.PositionX, grass.PositionY, XRpgMakerGameConfigs.XRpgMakeBlockMetaType.Grass)
        if grassObj and grassObj.Burn then
            grassObj:Burn()
        else
            self.RpgMakerGamePlayScene:BurnGrass(grass.PositionX, grass.PositionY)
        end
    end

    local grass = table.remove(action.Grass, 1)
    BurnFunc(grass)
    local loop = #action.Grass
    if loop <= 0 then
        self.RpgMakerGamePlayScene:UpdateTriggeObjStatus(mapId)
        cb()
        return
    end

    --间隔一段时间燃烧
    local timer = XScheduleManager.Schedule(function()
        grass = table.remove(action.Grass, 1)
        BurnFunc(grass)
        --等最后一个播完再继续
        if XTool.IsTableEmpty(action.Grass) then
            XScheduleManager.ScheduleOnce(function()
                if XTool.UObjIsNil(self.GameObject) then
                    return
                end
                self.RpgMakerGamePlayScene:UpdateTriggeObjStatus(mapId)
                cb()
            end, CS.XGame.ClientConfig:GetInt("RpgMakerGameDieByTrapTime"))
        end
    end, PLAY_ANIMA_INTERVAL, loop)
    table.insert(self.GrassAnimTimer, timer)
end

---停止草地燃烧动画计时
function XUiRpgMakerGamePlayMain:StopGrassAnimTimer()
    if not XTool.IsTableEmpty(self.GrassAnimTimer) then
        for _, timer in pairs(self.GrassAnimTimer) do
            XScheduleManager.UnSchedule(timer)
        end
    end
    self.GrassAnimTimer = { }
end

---停止草地生长动画计时
function XUiRpgMakerGamePlayMain:StopGrassGrowAnimTimer()
    if not XTool.IsTableEmpty(self.GrassGrowAnimTimer) then
        for _, timer in pairs(self.GrassGrowAnimTimer) do
            XScheduleManager.UnSchedule(timer)
        end
    end
    self.GrassGrowAnimTimer = { }
end

---检查水对象的状态，把融化状态设为水
function XUiRpgMakerGamePlayMain:CheckWaterState()
    local waterObjDic = XDataCenter.RpgMakerGameManager.GetWaterObjDic()
    for _, waterObj in pairs(waterObjDic) do
        if waterObj:GetStatus() == XRpgMakerGameConfigs.XRpgMakerGameWaterType.Melt then
            waterObj:SetStatus(XRpgMakerGameConfigs.XRpgMakerGameWaterType.Water)
        end
    end
end

---检查所有怪物的攻击范围和警戒线
function XUiRpgMakerGamePlayMain:CheckMonsertViewAreaAndLine()
    local monsterObjDic = XDataCenter.RpgMakerGameManager.GetMonsterObjDic()
    for _, monsertObj in pairs(monsterObjDic) do
        monsertObj:SetViewAreaAndLine()
    end
end

---刷新哨戒停留剩余回合
function XUiRpgMakerGamePlayMain:UpdateSentrySign(monsterId)
    if self:UpdateSentrySignText(monsterId) then
        return
    end

    local monsterObjDic = XDataCenter.RpgMakerGameManager.GetMonsterObjDic()
    for monsterId in pairs(monsterObjDic or {}) do
        self:UpdateSentrySignText(monsterId)
    end
end

function XUiRpgMakerGamePlayMain:UpdateSentrySignText(monsterId)
    local monsterObj = XDataCenter.RpgMakerGameManager.GetMonsterObj(monsterId)
    if not monsterObj then
        return false
    end

    monsterObj:LoadSentrySign()
    
    local textSentryRoand = self.TextSentryRoandMap[monsterId]
    if monsterObj:IsSentryShowLastStopRound() and not monsterObj:IsDeath() then
        if not textSentryRoand then
            textSentryRoand = CSUnityEngineObjectInstantiate(self.TextSentryRoand, self.PanelInfo.transform)
            self.TextSentryRoandMap[monsterId] = textSentryRoand
        end
        textSentryRoand.text = monsterObj:GetSentryLastStopRound()
        local objPosition = monsterObj:GetSentryRoandGameObjPosition()
        textSentryRoand.transform.localPosition = self:WorldToUILocaPosition(objPosition)
        textSentryRoand.gameObject:SetActiveEx(true)
    elseif textSentryRoand then
        textSentryRoand.gameObject:SetActiveEx(false)
    end

    return true
end

function XUiRpgMakerGamePlayMain:HideSentrySignText(monsterId)
    if not self.TextSentryRoandMap[monsterId] then
        return
    end
    self.TextSentryRoandMap[monsterId].gameObject:SetActiveEx(false)
end

function XUiRpgMakerGamePlayMain:CheckActionShadowMove(moveEndCb)
    local actions = XDataCenter.RpgMakerGameManager.GetActions(XRpgMakerGameConfigs.RpgMakerGameActionType.ActionShadowMove)
    local moveEndCb = moveEndCb
    if XTool.IsTableEmpty(actions) then
        moveEndCb()
        return
    end

    local actionCount = #actions
    local onceShadowMoveEndCb = function()
        actionCount = actionCount - 1
        if actionCount <= 0 then
            moveEndCb()
        end
    end

    for _, action in ipairs(actions) do
        local shadowObj = XDataCenter.RpgMakerGameManager.GetShadowObj(action.ShadowId)
        if not shadowObj then
            moveEndCb()
            return
        end
        shadowObj:PlayMoveAction(action, onceShadowMoveEndCb, self:GetMapId(), self:GetStageId())
    end
end

function XUiRpgMakerGamePlayMain:PlayActionEndCallback()
    self.IsPlayingAction = false
    self:Refresh()
end

function XUiRpgMakerGamePlayMain:GameOver(actionType)
    local stageId = self:GetStageId()
    self.LoseTip:Show(stageId, actionType)
    self:PlayAnimation("PanelLoseTipEnable")
    if not XDataCenter.RpgMakerGameManager.IsStageClear(stageId) then
        self:SetCurrLoseCount(self.CurrLoseCount + 1)
    end
end



--#region 手指交互

---手指按下
function XUiRpgMakerGamePlayMain:OnPointerDown(position)
    self.StartDownPosition = position
end

---拖拽
function XUiRpgMakerGamePlayMain:OnDrag(position)
    if not self:IsCanRequest() then
        return
    end

    local playerObj = XDataCenter.RpgMakerGameManager.GetPlayerObj()
    if not playerObj then
        return
    end

    local endDir = position - self.StartDownPosition
    if endDir == Vector3.zero then
        return
    end

    self.IsTriggerDrag = true

    local angle = self:GetAngle(endDir)
    local direction = self:GetDirectionByAngle(angle)
    playerObj:ChangeDirectionAction({Direction = direction})
    playerObj:SetMoveDirectionEffectActive(true)
end

---手指松开
function XUiRpgMakerGamePlayMain:OnPointerUp(position)
    if not self:IsCanRequest() or not self.IsTriggerDrag then
        return
    end

    local playerObj = XDataCenter.RpgMakerGameManager.GetPlayerObj()
    if playerObj then
        playerObj:SetMoveDirectionEffectActive(false)
    end

    self.IsTriggerDrag = false

    local endDir = position - self.StartDownPosition
    local angle = self:GetAngle(endDir)
    local mapId = self:GetMapId()
    local direction = self:GetDirectionByAngle(angle)
    XDataCenter.RpgMakerGameManager.RequestRpgMakerGameMapMove(mapId, direction, handler(self, self.Refresh))
end

---计算手指拖拽向量转角度
function XUiRpgMakerGamePlayMain:GetAngle(endDir)
    local angle = Vector3.SignedAngle(Vector3Right, endDir, Vector3Forward)     --向量转角度，范围：-180度 ~ 180度
    angle = angle < 0 and 360 + angle or angle  --角度范围转换成0~360度
    return (angle + MoveRoleAngleOffset) % 360
end

---根据角度返回对应的方向
function XUiRpgMakerGamePlayMain:GetDirectionByAngle(angle)
    local direction
    if angle >= 315 or angle < 45 then
        direction = XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveRight
    elseif angle >= 45 and angle < 135 then
        direction = XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveUp
    elseif angle >= 135 and angle < 225 then
        direction = XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveLeft
    elseif angle >= 225 and angle < 315 then
        direction = XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveDown
    end
    return direction
end

--#endregion



---所有动作播完才能发协议
function XUiRpgMakerGamePlayMain:IsCanRequest()
    if not XDataCenter.RpgMakerGameManager.IsActionsEmpty() or self.IsPlayingAction or self.IsPlayingBackoffEffect or self.IsGuideing then
        return false
    end
    return true
end



--#region 右下角提示相关

--延迟一段时间显示随机提示语
function XUiRpgMakerGamePlayMain:StartCheckShowHintTimer(isStopShowRandomHint)
    self:StopCheckShowHintTimer()
    self:StopRandomDialogBoxDurationTimer()
    if isStopShowRandomHint or self:IsShowHintDialog() then
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
    if XTool.UObjIsNil(self.GameObject) then
        return
    end
    local id = XDataCenter.RpgMakerGameManager.GetRandomDialogBoxId()
    local text = XRpgMakerGameConfigs.GetRpgMakerGameRandomDialogBoxText(id)
    self.TextHint.text = text
    self:SetContentActive(true)
    self:StartRandomDialogBoxDurationTimer(id)
end

function XUiRpgMakerGamePlayMain:ShowHintDialog()
    local stageId = self:GetStageId()
    local text = XRpgMakerGameConfigs.GetRpgMakerGameHintDialogBoxText(stageId)
    self.TextHint.text = text
    self:SetContentActive(true)
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

    local duration = randomdialogBoxId and XRpgMakerGameConfigs.GetRpgMakerGameRandomDialogBoxDuration(randomdialogBoxId) or RandomDialogBoxIntervalSecond
    self.RandomDialogBoxDurationTimer = XScheduleManager.ScheduleForever(function()
        duration = duration - 1
        if duration <= 0 then
            self:CheckIconChatActive()
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
    local stageId = self:GetStageId()

    --使用后退达到指定次数
    local currUseBackCount = self:GetCurrUseBackCount()
    local backCount = XRpgMakerGameConfigs.GetRpgMakerGameHintDialogBoxBackCount(stageId)
    if currUseBackCount >= backCount then
        return true
    end

    --使用重置达到指定次数
    local currResetCount = self:GetCurrResetCount()
    local resetCount = XRpgMakerGameConfigs.GetRpgMakerGameHintDialogBoxResetCount(stageId)
    if currResetCount >= resetCount then
        return true
    end

    --累计失败达到指定次数
    local currLoseCount = self:GetCurrLoseCount()
    local totalLoseCount = XRpgMakerGameConfigs.GetRpgMakerGameHintDialogBoxTotalLoseCount(stageId)
    if currLoseCount >= totalLoseCount then
        return true
    end

    return false
end

function XUiRpgMakerGamePlayMain:SetCurrUseBackCount(currUseBackCount)
    self.CurrUseBackCount = currUseBackCount
end

function XUiRpgMakerGamePlayMain:GetCurrUseBackCount()
    return self.CurrUseBackCount
end

function XUiRpgMakerGamePlayMain:CheckIconChatActive()
    local isShowHintDialog = self:IsShowHintDialog()
    self:SetIconChatActive(isShowHintDialog)
end

function XUiRpgMakerGamePlayMain:SetCurrResetCount(currResetCount)
    self.CurrResetCount = currResetCount
end

function XUiRpgMakerGamePlayMain:GetCurrResetCount()
    return self.CurrResetCount
end

function XUiRpgMakerGamePlayMain:SetCurrLoseCount(currLoseCount)
    self.CurrLoseCount = currLoseCount
end

function XUiRpgMakerGamePlayMain:GetCurrLoseCount()
    return self.CurrLoseCount
end

--定时切换下方提示语
function XUiRpgMakerGamePlayMain:StartDownHintTimer()
    self:StopDownHintTimer()

    local duration = DownHintStayTime
    local maxCount = XRpgMakerGameConfigs.GetRpgMakerGamePlayMainDownHintConfigMaxCount()
    local curId = 1
    local desc = XRpgMakerGameConfigs.GetRpgMakerGamePlayMainDownHintText(curId)
    self.TipText.text = desc

    self.DownHintTimer = XScheduleManager.ScheduleForever(function()
        duration = duration - 1
        if duration <= 0 then
            duration = DownHintStayTime
            desc = XRpgMakerGameConfigs.GetRpgMakerGamePlayMainDownHintText(curId)
            curId = curId + 1 > maxCount and 1 or curId + 1
            self.TipText.text = desc
        end
    end, XScheduleManager.SECOND)
end

function XUiRpgMakerGamePlayMain:StopDownHintTimer()
    if self.DownHintTimer then
        XScheduleManager.UnSchedule(self.DownHintTimer)
        self.DownHintTimer = nil
    end
end

--点击场景对象显示介绍提示窗
function XUiRpgMakerGamePlayMain:ShowObjectTips(modelKey, modelName)
    self.DetailTip:Show(modelKey, modelName)
end

--#endregion



--#region 基础数据相关

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

function XUiRpgMakerGamePlayMain:SetIsWin(isWin)
    self.IsWin = isWin
end

function XUiRpgMakerGamePlayMain:GetIsWin()
    return self.IsWin
end

--#endregion



---悔棋屏幕特效
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



--#region 引导相关

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
        self.BtnGuideRoadClick.transform.localPosition = localPosition + Vector3(120, 50, 0)
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
    local monsterIdList = XRpgMakerGameConfigs.GetMixBlockDataListByType(mapId, XRpgMakerGameConfigs.XRpgMakeBlockMetaType.Moster)
    local monsterId = monsterIdList[1]:GetParams()[1]
    local monsterObj = XDataCenter.RpgMakerGameManager.GetMonsterObj(monsterId)
    modelPosotion = monsterObj and monsterObj:GetGameObjPosition()
    localPosition = modelPosotion and self:WorldToUILocaPosition(modelPosotion)
    if localPosition then
        localPosition.y = localPosition.y + offsetY
    end
    if self.BtnGuideMonsterClick and localPosition then
        self.BtnGuideMonsterClick.transform.localPosition = localPosition
    end

    --设置按钮到怪物所在的位置
    local shadowList = XRpgMakerGameConfigs.GetMixBlockDataListByType(mapId, XRpgMakerGameConfigs.XRpgMakeBlockMetaType.Shadow)
    local shadowId = shadowList[1]:GetParams()[1]
    local shadowObj = XDataCenter.RpgMakerGameManager.GetShadowObj(shadowId)
    modelPosotion = monsterObj and shadowObj:GetGameObjPosition()
    localPosition = modelPosotion and self:WorldToUILocaPosition(modelPosotion)
    if localPosition then
        localPosition.y = localPosition.y + offsetY
    end
    --4期处理这个的时候临近发布最终补丁，暂由程序生成，合理应该ui加资源
    if not self.BtnGuideShadowClick then
        self.BtnGuideShadowClick = XUiHelper.Instantiate(self.BtnGuideMonsterClick.gameObject, self.BtnGuideMonsterClick.transform.parent)
        self.BtnGuideShadowClick.name = "BtnGuideShadowClick"
    end
    if self.BtnGuideShadowClick and localPosition then
        self.BtnGuideShadowClick.transform.localPosition = localPosition
    end
end

function XUiRpgMakerGamePlayMain:OnBtnGuideRoleClick()
    self.IsGuideing = true
    local playerObj = XDataCenter.RpgMakerGameManager.GetPlayerObj()
    if not playerObj then
        return
    end

    playerObj:ChangeDirectionAction({Direction = XRpgMakerGameConfigs.GetActivityGuideMoveDirection()})
    playerObj:SetMoveDirectionEffectActive(true)
end

function XUiRpgMakerGamePlayMain:OnBtnGuideRoadClick()
    self.IsGuideing = false
    local playerObj = XDataCenter.RpgMakerGameManager.GetPlayerObj()
    if playerObj then
        playerObj:SetMoveDirectionEffectActive(false)
    end

    local mapId = self:GetMapId()
    local direction = XRpgMakerGameConfigs.GetActivityGuideMoveDirection()
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

--#endregion