---@class XUiLottoLuna:XLuaUi
---@field BtnShield XUiComponent.XUiButton
local XUiLottoLuna = XLuaUiManager.Register(XLuaUi, "UiLottoLuna")

local PANEL_TYPE = {
    SHOW = 1,
    STAGE = 2,
    DRAW = 3,
    FIRST = 4,
}

---@param groupData XLottoGroupEntity
function XUiLottoLuna:OnStart(groupData, closeCb, backGround, initPanelType)
    ---@type XLottoGroupEntity
    self._LottoGroupData = groupData
    self._InitPanelType = initPanelType
    self._IsBackMain = false
    self:SetPanelType(initPanelType)
    if initPanelType == PANEL_TYPE.STAGE then
        -- 入场是Stage则切换回抽卡需要演出
        self._IsExitStagePlayFirst = true
    end

    self:Init()
    self:AddBtnListener()
end

function XUiLottoLuna:OnEnable()
    self:Refresh()
    self:StartAutoCloseTimer()
    self:SetGlobalIllumination(true)

    self:PlayEnableAnim()
    self:AddEventListener()
    self._IsBackMain = false
end

function XUiLottoLuna:OnDisable()
    self:_StopTimer()
    self:CloseAutoCloseTimer()
    self:SetGlobalIllumination(false)

    self.PanelDrawGroup.gameObject:SetActiveEx(self:CheckPanelType(PANEL_TYPE.SHOW))
    self.PanelStory.gameObject:SetActiveEx(self:CheckPanelType(PANEL_TYPE.STAGE))
    self:RemoveEventListener()
    self._IsBackMain = true
end

function XUiLottoLuna:OnDestroy()
    self:RemovePanelAssetListener()
    self:StopDrawCue()
end

function XUiLottoLuna:OnReleaseInst()
    return self._PanelType
end

function XUiLottoLuna:OnResume(value)
    self._CachePanelType = value
end

function XUiLottoLuna:Init()
    self:InitPanelAsset()
    self:InitBtn()
    self:InitReward()
    self:InitStageList()
    self:InitUiAnim()
    self:InitDrawControl()

    self:InitSceneObj()
end

function XUiLottoLuna:Refresh()
    if self:CheckPanelType(PANEL_TYPE.SHOW) then
        self:RefreshReward()
        self:RefreshDrawBtn()
        self:RefreshSkipBtn(XDataCenter.LottoManager.GetSkipAnim(self._LottoGroupData:GetId()))
    elseif self:CheckPanelType(PANEL_TYPE.STAGE) then
        self:RefreshStageList()
    elseif self:CheckPanelType(PANEL_TYPE.DRAW) then

    end
    self:_RefreshPanelType()
end

function XUiLottoLuna:_RefreshPanelType()
    local isShowOrStage = self:CheckPanelType(PANEL_TYPE.SHOW) or self:CheckPanelType(PANEL_TYPE.STAGE)
    self.BtnBack.gameObject:SetActiveEx(isShowOrStage)
    self.BtnMainUi.gameObject:SetActiveEx(isShowOrStage)
    self.PanelSpecialTool.gameObject:SetActiveEx(isShowOrStage)

    self.PanelDrawEffect.gameObject:SetActiveEx(self:CheckPanelType(PANEL_TYPE.DRAW))
    self.BtnDraw.gameObject:SetActiveEx(self:CheckPanelType(PANEL_TYPE.DRAW))
end

--region Data - PanelType
function XUiLottoLuna:SetPanelType(panelType)
    local isFirst = XDataCenter.LottoManager.GetFirstAnim(self._LottoGroupData:GetId())
    local isSkip = XDataCenter.LottoManager.GetSkipAnim(self._LottoGroupData:GetId())
    if XTool.IsNumberValid(self._CachePanelType) then
        self._PanelType = self._CachePanelType
    else
        self._PanelType = XTool.IsNumberValid(panelType) and panelType or PANEL_TYPE.SHOW
    end
    if (isFirst or not isSkip) and self:CheckPanelType(PANEL_TYPE.SHOW) then
        self._PanelType = PANEL_TYPE.FIRST
    end
end

function XUiLottoLuna:CheckPanelType(type)
    return self._PanelType == type
end
--endregion

--region Ui - PanelStage
function XUiLottoLuna:InitStageList()
    local stageActivityId = XLottoConfigs.GetLottoStageActivity(self._LottoGroupData:GetId())
    local festivalActivity = XFestivalActivityConfig.GetFestivalById(stageActivityId)
    local XStageItem = require("XUi/XUiEpicFashionGacha/Grid/XStageItem")
    self._StageUiObjDir = {}
    XTool.InitUiObjectByInstance(self.PanelStory, self._StageUiObjDir)
    ---@type XStageItem[]
    self._StageGridList = {}
    self._StageIndexDir = {}

    for i, stageId in pairs(festivalActivity.StageId) do
        if self._StageUiObjDir["Stage"..i] then
            self._StageGridList[i] = XStageItem.New(self, self._StageUiObjDir["Stage"..i])
            self._StageIndexDir[stageId] = i
        end
    end
end

function XUiLottoLuna:RefreshStageList()
    local newIndex = 0
    for stageId, index in pairs(self._StageIndexDir) do
        local activityId = XLottoConfigs.GetLottoStageActivity(self._LottoGroupData:GetId())
        local fStage = XDataCenter.FubenFestivalActivityManager.GetFestivalStageByFestivalIdAndStageId(activityId, stageId)
        local isOpen, _ = fStage:GetCanOpen()
        if isOpen then
            if self._StageUiObjDir["Line"..(index - 1)] then
                self._StageUiObjDir["Line"..(index - 1)].gameObject:SetActiveEx(true)
            end
            self._StageGridList[index].GameObject:SetActiveEx(true)
            self._StageGridList[index]:UpdateNode(activityId, stageId)
            newIndex = math.max(newIndex, index)
        else
            if self._StageUiObjDir["Line"..(index - 1)] then
                self._StageUiObjDir["Line"..(index - 1)].gameObject:SetActiveEx(false)
            end
            self._StageGridList[index].GameObject:SetActiveEx(false)
        end
    end
    self:MoveIntoStage(newIndex)
end

function XUiLottoLuna:UpdateNodesSelect(stageId)
    for gridStageId, index in pairs(self._StageIndexDir) do
        self._StageGridList[index]:SetNodeSelect(gridStageId == stageId)
        if gridStageId == stageId then
            self._LastOpenStage = index
        end
    end
end

function XUiLottoLuna:OpenStageDetails(stageId)
    XLuaUiManager.Open("UiEpicFashionGachaStageDetail", stageId)
end

function XUiLottoLuna:MoveIntoStage(stageIndex)
    if not self._StageGridList[stageIndex] then
        return
    end
    local gridRect = self._StageGridList[stageIndex].Transform
    local diffX = gridRect.localPosition.x + self.PanelStageContent.localPosition.x
    local left = 100

    if diffX > CS.XResolutionManager.OriginWidth / 2 - left then
        local tarPosX = (CS.XResolutionManager.OriginWidth / 4) - gridRect.localPosition.x - left
        local tarPos = self.PanelStageContent.localPosition
        tarPos.x = tarPosX
        XLuaUiManager.SetMask(true)
        if self.PanelStageList then
            self.PanelStageList.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted
        end
        XUiHelper.DoMove(self.PanelStageContent, tarPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
            XLuaUiManager.SetMask(false)

            if self.PanelStageList then
                self.PanelStageList.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
            end
        end)
    end
end
--endregion

--region Ui - AutoClose
function XUiLottoLuna:StartAutoCloseTimer()
    if self._CloseTimer then
        self:CloseAutoCloseTimer()
    end
    local drawData = self._LottoGroupData:GetDrawData()
    local timeId = drawData:GetTimeId()
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    self._CloseTimer = XScheduleManager.ScheduleForever(function()
        if XTool.UObjIsNil(self.Transform) then
            self:CloseAutoCloseTimer()
        end
        if XTime.GetServerNowTimestamp() > endTime then
            XDataCenter.LottoManager.OnActivityEnd()
        end
        local time = XFunctionManager.GetEndTimeByTimeId(timeId) - XTime.GetServerNowTimestamp()
        self.TxtDay.text = XUiHelper.GetText("GachaAlphaTime", XUiHelper.GetTime(time, XUiHelper.TimeFormatType.CHATEMOJITIMER))
    end, XScheduleManager.SECOND, 0)
end

function XUiLottoLuna:CloseAutoCloseTimer()
    if self._CloseTimer then
        XScheduleManager.UnSchedule(self._CloseTimer)
        self._CloseTimer = nil
    end
end
--endregion

--region Ui - PanelAsset
function XUiLottoLuna:InitPanelAsset()
    local drawData = self._LottoGroupData:GetDrawData()
    local itemIds = {
        XDataCenter.ItemManager.ItemId.FreeGem,
        XDataCenter.ItemManager.ItemId.HongKa,
        drawData:GetConsumeId()
    }
    self._PanelAsset = XUiHelper.NewPanelActivityAssetSafe(itemIds, self.PanelSpecialTool, self)
end

function XUiLottoLuna:RemovePanelAssetListener()
    if self._PanelAsset then
        XDataCenter.ItemManager.RemoveCountUpdateListener(self._PanelAsset)
    end
end
--endregion

--region Ui - Reward
function XUiLottoLuna:InitReward()
    local XUiPanelLottoPreview = require("XUi/XUiLotto/XUiPanelLottoPreview")
    ---@type XUiPanelLottoPreview
    self._PanelLottoPreview = XUiPanelLottoPreview.New(self.PanelPreview, self, self._LottoGroupData)
end

function XUiLottoLuna:RefreshReward()
    self._PanelLottoPreview:UpdateTwoLevelPanel(XEnumConst.Lotto.Luna)
end
--endregion

--region Ui - Btn
function XUiLottoLuna:InitBtn()
    if not self.BtnSkip then
        ---@type XUiComponent.XUiButton
        self.BtnSkip = XUiHelper.TryGetComponent(self.PanelDrawGroup.transform, "TopControlSpe/BtnSkip", "XUiButton")
    end
    if self.BtnSkip then
        self.BtnSkip.gameObject:SetActiveEx(false)
    end
    if self.TopControlSpe then
        self.TopControlSpe.gameObject:SetActiveEx(false)
    end
end

function XUiLottoLuna:RefreshDrawBtn()
    local drawData = self._LottoGroupData:GetDrawData()
    local icon = XDataCenter.ItemManager.GetItemBigIcon(drawData:GetConsumeId())
    self.BtnGo:SetDisable(drawData:IsLottoCountFinish())
    if drawData:IsLottoCountFinish() then
        self.PanelDrawButtons:GetObject("ImgUseItemIcon").gameObject:SetActiveEx(false)
        self.PanelDrawButtons:GetObject("TxtUseItemCount").gameObject:SetActiveEx(false)
    else
        self.PanelDrawButtons:GetObject("ImgUseItemIcon"):SetRawImage(icon)
        self.PanelDrawButtons:GetObject("TxtUseItemCount").text = drawData:GetConsumeCount() > 0 and
                "x" .. drawData:GetConsumeCount() or XUiHelper.GetText("LottoDrawFreeText")
    end
end

function XUiLottoLuna:RefreshSkipBtn(isSkip)
    if not self.BtnShield then
        return
    end
    if isSkip then
        self.BtnShield:SetButtonState(XUiButtonState.Select)
    else
        self.BtnShield:SetButtonState(XUiButtonState.Normal)
    end
end
--endregion

--region Anim
function XUiLottoLuna:InitUiAnim()
    ---@type UnityEngine.Playables.PlayableDirector
    self._UiAnimEnableLong = self.GameObject:FindTransform("AnimEnableLong"):GetComponent("PlayableDirector")
end

function XUiLottoLuna:PlayEnableAnim()
    local isFirst = XDataCenter.LottoManager.GetFirstAnim(self._LottoGroupData:GetId())
    local isSkip = XDataCenter.LottoManager.GetSkipAnim(self._LottoGroupData:GetId())
    if self:CheckPanelType(PANEL_TYPE.FIRST) then
        if isFirst then
            --播放完首次动画后默认跳过动画
            isSkip = true
            XDataCenter.LottoManager.SetSkipAnim(self._LottoGroupData:GetId(), isSkip)
        end
        self:_PlayEnableAnim()
    else
        self:PlayShortEnableAnim()
    end
    self:RefreshSkipBtn(isSkip)
end

function XUiLottoLuna:_PlayEnableAnim()
    -- 这里remove是因为默认剧情关又不跳过演出，会导致模型在舞台下，只有脑袋的影子
    -- 所以需要移除影子
    self:RemoveModelShadow()
    XDataCenter.LottoManager.SetFirstAnim(self._LottoGroupData:GetId(), true)
    self._PanelType = PANEL_TYPE.SHOW
    self:Refresh()
    self:_PlayLongStartAnim()
    self._IsExitStagePlayFirst = false
end

---长入场动画
function XUiLottoLuna:_PlayLongStartAnim(time)
    self._CamAnimStart1:Stop()
    self:PlayAnimation("AnimEnableLong")
    self:PlayTimeLineAnim(self._CamAnimEnableLong, time)

    self:_StopTimer()
    -- 因为要提前加影子保证最后效果一直，长动画需要检测卡列的动作加影子
    self._LongAnimTimer = XScheduleManager.ScheduleForever(function()
        if not XTool.UObjIsNil(self._ModelAnimator) and self._ModelAnimator:GetCurrentAnimatorStateInfo(0):IsName("LottoStand01loop") then
            self:AddModelShadow()
            self:_StopTimer()
        end
    end, 0, 0)
end

function XUiLottoLuna:_StopTimer()
    if self._LongAnimTimer then
        XScheduleManager.UnSchedule(self._LongAnimTimer)
    end
end

---跳过进入短入场动画(台上Stand)
function XUiLottoLuna:PlayShortEnableAnim()
    if self:CheckPanelType(PANEL_TYPE.SHOW) then
        -- 入场短动画
        if self._IsBackMain then
            self:PlayAnimationWithMask("AnimStart1", function()
                -- 额外奖励和皮肤弹窗摆这里是因为结果回来会播该动画
                -- 弹窗会截图背景做模糊处理，显得过渡不自然
                self:ShowRewardDialog()
            end)
            self:PlayTimeLineAnim(self._CamAnimStart1)
        else
            self:PlayAnimationWithMask("AnimEnableShort", function()
                -- 额外奖励和皮肤弹窗摆这里是因为结果回来会播该动画
                -- 弹窗会截图背景做模糊处理，显得过渡不自然
                self:ShowRewardDialog()
            end)
            self:PlayTimeLineAnim(self._CamAnimEnableShort)
        end
        self._IsExitStagePlayFirst = false
    elseif self:CheckPanelType(PANEL_TYPE.STAGE) then
        self:PlayStageAnim(true)
    end
    self:AddModelShadow()
end

---关卡镜头动画
function XUiLottoLuna:PlayStageAnim(isDisableTop)
    if self._InitPanelType == PANEL_TYPE.STAGE or isDisableTop then
        self._InitPanelType = nil
        self:PlayAnimationWithMask("AnimStart2")
    else
        self:PlayAnimationWithMask("AnimEnableStory")
    end
    self:StopTimeLineAnim(self._CamAnimDisableStory)
    self:PlayTimeLineAnim(self._CamAnimEnableStory)
end

---关卡镜头动画
function XUiLottoLuna:PlayStageDisableAnim()
    self:PlayAnimationWithMask("AnimDisableStory")
    self:StopTimeLineAnim(self._CamAnimEnableStory)
    self:PlayTimeLineAnim(self._CamAnimDisableStory)
end

---@param anim UnityEngine.Playables.PlayableDirector
---@param directorWrapMode number UnityEngine.Playables.DirectorWrapMode
function XUiLottoLuna:PlayTimeLineAnim(anim, time, directorWrapMode)
    if not anim then
        return
    end
    anim.initialTime = time or 0
    if directorWrapMode then
        anim.extrapolationMode = directorWrapMode
    end
    anim:Evaluate()
    anim:Play()
end

---@param anim UnityEngine.Playables.PlayableDirector
function XUiLottoLuna:PauseTimeLineAnim(anim)
    if not anim then
        return
    end
    anim:Pause()
end

---@param anim UnityEngine.Playables.PlayableDirector
function XUiLottoLuna:ResumeTimeLineAnim(anim)
    if not anim then
        return
    end
    anim:Play()
end

---@param anim UnityEngine.Playables.PlayableDirector
function XUiLottoLuna:StopTimeLineAnim(anim)
    if not anim then
        return
    end
    anim:Stop()
end
--endregion

--region Draw
function XUiLottoLuna:InitDrawControl()
    local XUiLottoDrawControl = require("XUi/XUiLotto/Draw/XUiLottoDrawControl")
    ---@type XUiLottoDrawControl
    self._DrawControl = XUiLottoDrawControl.New(self.Transform, self, self._LottoGroupData)
end

function XUiLottoLuna:ShowRewardDialog()
    self._DrawControl:ShowRewardDialog(XEnumConst.Lotto.Luna)
end

function XUiLottoLuna:FinishDrawAnim()
    self:DisableDrawAnim()
    XEventManager.DispatchEvent(XEventId.EVENT_LOTTO_DRAW_ON_FINISH)
end

function XUiLottoLuna:ShowDrawResult()
    self._DrawControl:ShowDrawResult()
end

function XUiLottoLuna:EnableDrawAnim(drawAnimName)
    self._PanelType = PANEL_TYPE.SHOW
    if self.BtnSkip then
        self.BtnSkip.gameObject:SetActiveEx(true)
    end
    if self.TopControlSpe then
        self.TopControlSpe.gameObject:SetActiveEx(true)
    end
    self:_SetSceneDrawCam(true)
    if not drawAnimName or not self._CamAnimDrawDir[drawAnimName] then
        self:FinishDrawAnim()
        return
    end
    self:PlayAnimationWithMask("UiDisable")
    if not self._CamAnimDrawDir[drawAnimName].gameObject.activeSelf then
        self._CamAnimDrawDir[drawAnimName].gameObject:SetActiveEx(true)
    end
    self._CamAnimDrawDir[drawAnimName].gameObject:PlayTimelineAnimation(function()
        self:FinishDrawAnim()
    end)
    -- 手动播放音频 在直接绑在特效上的话 会有播放2次的问题 原因暂时不明
    self:StopDrawCue()
    self._CurDrawCueId = XLottoConfigs.GetLottoClientConfigNumber(string.format("Luna%sBgmId", drawAnimName))
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, self._CurDrawCueId)
end

function XUiLottoLuna:DisableDrawAnim()
    if self.BtnSkip then
        self.BtnSkip.gameObject:SetActiveEx(false)
    end
    self:_SetSceneDrawCam(false)
    ---@type UnityEngine.Transform
    local root = self.UiModelGo.transform
    local effectRoot = XUiHelper.TryGetComponent(root, "UiEffectRoot/Effect")
    for i = 0, effectRoot.childCount - 1 do
        effectRoot:GetChild(i).gameObject:SetActiveEx(false)
    end
    self:StopDrawCue()
end

function XUiLottoLuna:StopDrawCue()
    if XTool.IsNumberValid(self._CurDrawCueId) then
        XLuaAudioManager.StopAudioByCueId(self._CurDrawCueId)
        self._CurDrawCueId = nil
    end
end

function XUiLottoLuna:_SetSceneDrawCam(active)
    if not XTool.IsTableEmpty(self._SceneCamDrawList) then
        for _, cam in ipairs(self._SceneCamDrawList) do
            cam.gameObject:SetActiveEx(active)
        end
    end
end
--endregion

--region Scene - GlobalIllumination
---设置全局光照,作用暂时不明
function XUiLottoLuna:SetGlobalIllumination(enable)
    CS.XGlobalIllumination.EnableDistortionInUI = enable
end
--endregion

--region Scene - Obj
function XUiLottoLuna:InitSceneObj()
    if not self.UiSceneInfo then
        return
    end

    self:InitSceneCam()
    self:InitSceneAnim()
    self:InitCameraAnim()
    self:InitSceneVideo()
    self:InitSceneModel()
end

function XUiLottoLuna:InitSceneCam()
    ---@type UnityEngine.Transform
    local root = self.UiModelGo.transform
    ---@type UnityEngine.Transform[]
    self._SceneCamDrawList = {
        XUiHelper.TryGetComponent(root, "UiFarRoot/UiFarCamQuan"),
        XUiHelper.TryGetComponent(root, "UiNearRoot/UiNearCamQuan")
    }
end

function XUiLottoLuna:InitSceneAnim()
    ---@type UnityEngine.RectTransform
    self._SceneAnimRoot = XUiHelper.TryGetComponent(self.UiSceneInfo.Transform, "Animations")
    ---@type UnityEngine.Playables.PlayableDirector
    --self._SceneAnimStart = XUiHelper.TryGetComponent(self._SceneAnimRoot, "Timeline_B", "PlayableDirector")
    ---@type UnityEngine.Playables.PlayableDirector
    --self._SceneAnimEnableLong = XUiHelper.TryGetComponent(self._SceneAnimRoot, "Timeline_C", "PlayableDirector")
end

function XUiLottoLuna:InitCameraAnim()
    ---@type UnityEngine.Transform
    local root = self.UiModelGo.transform
    ---@type UnityEngine.Playables.PlayableDirector
    self._CamAnimStart1 = root:FindTransform("AnimStart1"):GetComponent("PlayableDirector")
    ---@type UnityEngine.Playables.PlayableDirector
    self._CamAnimEnableLong = root:FindTransform("AnimEnableLong"):GetComponent("PlayableDirector")
    ---@type UnityEngine.Playables.PlayableDirector
    self._CamAnimEnableShort = root:FindTransform("AnimEnableShort"):GetComponent("PlayableDirector")
    ---@type UnityEngine.Playables.PlayableDirector
    self._CamAnimEnableStory = root:FindTransform("AnimEnableStory"):GetComponent("PlayableDirector")
    ---@type UnityEngine.Playables.PlayableDirector
    self._CamAnimDisableStory = root:FindTransform("AnimDisableStory"):GetComponent("PlayableDirector")
    ---@type UnityEngine.Playables.PlayableDirector

    ---@type UnityEngine.Transform[]
    self._CamAnimDrawDir = {}
    self._CamAnimDrawDir.ChoukaVioletEnable = root:FindTransform("ChoukaVioletEnable")
    self._CamAnimDrawDir.ChoukaYellowEnable = root:FindTransform("ChoukaYellowEnable")
    self._CamAnimDrawDir.ChoukaRedEnable = root:FindTransform("ChoukaRedEnable")
end

function XUiLottoLuna:InitSceneVideo()
    ---@type XVideoPlayerScene
    self._SceneVideoPlayer = XUiHelper.TryGetComponent(self.UiSceneInfo.Transform, "Video", "XVideoPlayerScene")
    if not self._SceneVideoPlayer then
        return
    end

    local videoId = XLottoConfigs.GetAllConfigs(XLottoConfigs.TableKey.LottoSceneVideo)[self._DrawControl:GetLottoId()].VideoConfigId
    self._SceneVideoPlayer:SetInfoByVideoId(videoId)
end

function XUiLottoLuna:InitSceneModel()
    ---@type UnityEngine.Transform
    local root = self.UiModelGo.transform
    local modelParent = XUiHelper.TryGetComponent(root, "UiNearRoot/UiModelParent")
    if modelParent then
        self._Model = modelParent:GetChild(0)
    end
    ---@type UnityEngine.Animator
    self._ModelAnimator = self._Model.gameObject:GetComponent("Animator")
end

function XUiLottoLuna:AddModelShadow()
    if XTool.UObjIsNil(self._Model) then
        return
    end
    CS.XShadowHelper.AddShadow(self._Model.gameObject, true)
end

function XUiLottoLuna:RemoveModelShadow()
    if XTool.UObjIsNil(self._Model) then
        return
    end
    CS.XShadowHelper.RemoveShadow(self._Model.gameObject, true)
end
--endregion

--region Ui - BtnListener
function XUiLottoLuna:AddBtnListener()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)

    XUiHelper.RegisterClickEvent(self, self.BtnDrawRule, self.OnBtnDrawRuleClick)
    XUiHelper.RegisterClickEvent(self, self.BtnXiangqing, self.OnBtnRewardDetailClick)
    XUiHelper.RegisterClickEvent(self, self.BtnShield, self.OnBtnSkipAnimClick)
    XUiHelper.RegisterClickEvent(self, self.BtnVoice, self.OnBtnSetClick)
    XUiHelper.RegisterClickEvent(self, self.BtnVoiceStage, self.OnBtnSetClick)

    XUiHelper.RegisterClickEvent(self, self.BtnDrawShow, self.OnBtnDrawShowClick)
    XUiHelper.RegisterClickEvent(self, self.BtnStory, self.OnBtnStageClick)
    XUiHelper.RegisterClickEvent(self, self.BtnGo, self.OnBtnBeDrawClick, nil, true)
    
    if self.BtnSkip then
        XUiHelper.RegisterClickEvent(self, self.BtnSkip, self.OnBtnSkipDrawClick)
    end
end

function XUiLottoLuna:OnBtnBackClick()
    self:Close()
end

function XUiLottoLuna:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiLottoLuna:OnBtnRewardDetailClick()
    XLuaUiManager.Open("UiLottoLog", self._LottoGroupData, 1, XEnumConst.Lotto.Luna)
end

function XUiLottoLuna:OnBtnDrawRuleClick()
    XLuaUiManager.Open("UiLottoLog", self._LottoGroupData, 2, XEnumConst.Lotto.Luna)
end

function XUiLottoLuna:OnBtnSkipAnimClick()
    local state = self.BtnShield:GetToggleState()
    XDataCenter.LottoManager.SetSkipAnim(self._LottoGroupData:GetId(), state)
end

---声音设置
function XUiLottoLuna:OnBtnSetClick()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Setting) then
        return
    end
    XUiHelper.RecordBuriedSpotTypeLevelOne(XGlobalVar.BtnBuriedSpotTypeLevelOne.BtnUiMainBtnSet)
    XLuaUiManager.Open("UiSet", false)
end

function XUiLottoLuna:OnBtnDrawShowClick()
    local isSkip = XDataCenter.LottoManager.GetSkipAnim(self._LottoGroupData:GetId())
    self._PanelType = (self._IsExitStagePlayFirst and not isSkip) and PANEL_TYPE.FIRST or PANEL_TYPE.SHOW
    self:Refresh()
    if self._PanelType == PANEL_TYPE.FIRST then
        self:StopTimeLineAnim(self._CamAnimEnableStory)
        self:PlayEnableAnim()
    else
        self:PlayStageDisableAnim()
    end
end

function XUiLottoLuna:OnBtnStageClick()
    self._PanelType = PANEL_TYPE.STAGE
    self:Refresh()
    self:PlayStageAnim()
end

function XUiLottoLuna:OnBtnBeDrawClick()
    local isDraw = self._DrawControl:OnBtnDrawClick()
    if isDraw then
        self._PanelType = PANEL_TYPE.DRAW
    end
end

function XUiLottoLuna:OnBtnSkipDrawClick()
    self:FinishDrawAnim()
    --self._IsSkipDrawAnim = true
    --self._CamAnimDrawDir[self._DrawTimeLine].gameObject:SetActiveEx(false)
    --self._CamAnimDrawDir[self._DrawTimeLine].gameObject:SetActiveEx(true)
end
--endregion

--region Event
function XUiLottoLuna:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_LOTTO_AFTER_BUY_DRAW_SKIP_TICKET, self.Refresh, self)
    XEventManager.AddEventListener(XEventId.EVENT_LOTTO_AFTER_DRAW_RESULT_SHOW, self.Refresh, self)
    XEventManager.AddEventListener(XEventId.EVENT_LOTTO_DRAW_ON_START, self.EnableDrawAnim, self)
    XEventManager.AddEventListener(XEventId.EVENT_LOTTO_DRAW_ON_FINISH, self.ShowDrawResult, self)
end

function XUiLottoLuna:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_LOTTO_AFTER_BUY_DRAW_SKIP_TICKET, self.Refresh, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_LOTTO_AFTER_DRAW_RESULT_SHOW, self.Refresh, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_LOTTO_DRAW_ON_START, self.EnableDrawAnim, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_LOTTO_DRAW_ON_FINISH, self.ShowDrawResult, self)
end
--endregion