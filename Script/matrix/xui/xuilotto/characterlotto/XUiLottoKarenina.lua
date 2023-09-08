local XUiPanelLottoPreview = require("XUi/XUiLotto/XUiPanelLottoPreview")
local XStageItem = require("XUi/XUiEpicFashionGacha/Grid/XStageItem")
local characterRecord = require("XUi/XUiDraw/XUiDrawTools/XUiDrawCharacterRecord")

---@class XUiLottoKarenina:XLuaUi
---@field BtnShield XUiComponent.XUiButton
local XUiLottoKarenina = XLuaUiManager.Register(XLuaUi, "UiLottoKarenina")

local PANEL_TYPE = {
    SHOW = 1,
    STAGE = 2,
    DRAW = 3,
    FIRST = 4,
}

---@param groupData XLottoGroupEntity
function XUiLottoKarenina:OnStart(groupData, closeCb, backGround, initPanelType)
    ---@type XLottoGroupEntity
    self._LottoGroupData = groupData
    self._InitPanelType = initPanelType
    self:SetPanelType(initPanelType)
    local isFirst = XDataCenter.LottoManager.GetFirstAnim(self._LottoGroupData:GetId())
    if initPanelType == PANEL_TYPE.STAGE then
        -- 入场是Stage则切换回抽卡需要演出
        self._IsExitStagePlayFirst = isFirst
    end

    self:Init()
    self:AddBtnListener()
end

function XUiLottoKarenina:OnEnable()
    self:Refresh()
    self:StartAutoCloseTimer()
    self:SetGlobalIllumination(true)

    self:PlayEnableAnim()
end

function XUiLottoKarenina:OnDisable()
    self:_StopTimer()
    self:CloseAutoCloseTimer()
    self:SetGlobalIllumination(false)

    self.PanelDrawGroup.gameObject:SetActiveEx(self:CheckPanelType(PANEL_TYPE.SHOW))
    self.PanelStory.gameObject:SetActiveEx(self:CheckPanelType(PANEL_TYPE.STAGE))
end

function XUiLottoKarenina:OnDestroy()
    self:RemovePanelAssetListener()
end

function XUiLottoKarenina:OnReleaseInst()
    return self._PanelType
end

function XUiLottoKarenina:OnResume(value)
    self._CachePanelType = value
end

function XUiLottoKarenina:Init()
    self:InitPanelAsset()
    self:InitBtn()
    self:InitReward()
    self:InitStageList()
    self:InitUiAnim()
    
    self:InitSceneObj()
end

function XUiLottoKarenina:Refresh()
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

function XUiLottoKarenina:_RefreshPanelType()
    local isShowOrStage = self:CheckPanelType(PANEL_TYPE.SHOW) or self:CheckPanelType(PANEL_TYPE.STAGE)
    self.BtnBack.gameObject:SetActiveEx(isShowOrStage)
    self.BtnMainUi.gameObject:SetActiveEx(isShowOrStage)
    self.PanelSpecialTool.gameObject:SetActiveEx(isShowOrStage)

    self.PanelDrawEffect.gameObject:SetActiveEx(self:CheckPanelType(PANEL_TYPE.DRAW))
    self.BtnDraw.gameObject:SetActiveEx(self:CheckPanelType(PANEL_TYPE.DRAW))
    self.BtnStart.gameObject:SetActiveEx(self:CheckPanelType(PANEL_TYPE.FIRST))
end

--region Data - PanelType
function XUiLottoKarenina:SetPanelType(panelType)
    local isFirst = XDataCenter.LottoManager.GetFirstAnim(self._LottoGroupData:GetId())
    local isSkip = XDataCenter.LottoManager.GetSkipAnim(self._LottoGroupData:GetId())
    if XTool.IsNumberValid(panelType) then
        self._PanelType = panelType
    else
        self._PanelType = self._CachePanelType and self._CachePanelType or PANEL_TYPE.SHOW
    end
    if (isFirst or not isSkip) and self:CheckPanelType(PANEL_TYPE.SHOW) then
        self._PanelType = PANEL_TYPE.FIRST
    end
end

function XUiLottoKarenina:CheckPanelType(type)
    return self._PanelType == type
end
--endregion

--region Ui - PanelDraw
function XUiLottoKarenina:RefreshDraw()
    
end
--endregion

--region Ui - PanelStage
function XUiLottoKarenina:InitStageList()
    local stageActivityId = XLottoConfigs.GetLottoStageActivity(self._LottoGroupData:GetId())
    local festivalActivity = XFestivalActivityConfig.GetFestivalById(stageActivityId)
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

function XUiLottoKarenina:RefreshStageList()
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
            newIndex = index
        else
            if self._StageUiObjDir["Line"..(index - 1)] then
                self._StageUiObjDir["Line"..(index - 1)].gameObject:SetActiveEx(false)
            end
            self._StageGridList[index].GameObject:SetActiveEx(false)
        end
    end
    self:MoveIntoStage(newIndex)
end

function XUiLottoKarenina:UpdateNodesSelect(stageId)
    for gridStageId, index in pairs(self._StageIndexDir) do
        self._StageGridList[index]:SetNodeSelect(gridStageId == stageId)
        if gridStageId == stageId then
            self._LastOpenStage = index
        end
    end
end

function XUiLottoKarenina:OpenStageDetails(stageId)
    XLuaUiManager.Open("UiEpicFashionGachaStageDetail", stageId)
end

function XUiLottoKarenina:MoveIntoStage(stageIndex)
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
function XUiLottoKarenina:StartAutoCloseTimer()
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
    end, XScheduleManager.SECOND, 0)
end

function XUiLottoKarenina:CloseAutoCloseTimer()
    if self._CloseTimer then
        XScheduleManager.UnSchedule(self._CloseTimer)
        self._CloseTimer = nil
    end
end
--endregion

--region Ui - PanelAsset
function XUiLottoKarenina:InitPanelAsset()
    local drawData = self._LottoGroupData:GetDrawData()
    local itemIds = {
        XDataCenter.ItemManager.ItemId.FreeGem, 
        XDataCenter.ItemManager.ItemId.HongKa,
        drawData:GetConsumeId()
    }
    self._PanelAsset = XUiHelper.NewPanelActivityAssetSafe(itemIds, self.PanelSpecialTool, self)
end

function XUiLottoKarenina:RemovePanelAssetListener()
    if self._PanelAsset then
        XDataCenter.ItemManager.RemoveCountUpdateListener(self._PanelAsset)
    end
end
--endregion

--region Ui - Reward
function XUiLottoKarenina:InitReward()
    ---@type XUiPanelLottoPreview
    self._PanelLottoPreview = XUiPanelLottoPreview.New(self.PanelPreview, self, self._LottoGroupData)
end

function XUiLottoKarenina:RefreshReward()
    self._PanelLottoPreview:UpdateKaliePanel()
end
--endregion

--region Ui - Btn
function XUiLottoKarenina:InitBtn()
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

function XUiLottoKarenina:RefreshDrawBtn()
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

function XUiLottoKarenina:RefreshSkipBtn(isSkip)
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
function XUiLottoKarenina:InitUiAnim()
    ---@type UnityEngine.Playables.PlayableDirector
    self._UiAnimEnableLong = self.GameObject:FindTransform("AnimEnableLong"):GetComponent("PlayableDirector")
end

function XUiLottoKarenina:PlayEnableAnim()
    local isFirst = XDataCenter.LottoManager.GetFirstAnim(self._LottoGroupData:GetId())
    local isSkip = XDataCenter.LottoManager.GetSkipAnim(self._LottoGroupData:GetId())
    if isFirst then
        --播放完首次动画后默认跳过动画
        isSkip = true
        XDataCenter.LottoManager.SetSkipAnim(self._LottoGroupData:GetId(), isSkip)
    end
    if self:CheckPanelType(PANEL_TYPE.FIRST) then
        self:_PlayEnableAnim()
    else
        self:PlayShortEnableAnim()
    end
    self:RefreshSkipBtn(isSkip)
end

---首次进入和不跳过进入待点击动画(卡列徘徊)
function XUiLottoKarenina:_PlayEnableAnim()
    -- 这里remove是因为默认剧情关又不跳过演出，会导致模型在舞台下，只有脑袋的影子
    -- 所以需要移除影子
    self:RemoveModelShadow()
    self.BtnStart.gameObject:SetActiveEx(false)
    self:PlayAnimationWithMask("AnimStart1")
    self:PlayTimeLineAnim(self._SceneAnimStart)
    
    self._CamAnimStart1.gameObject:PlayTimelineAnimation(function()
        self.BtnStart.gameObject:SetActiveEx(true)
    end)
    self._Mat1.gameObject:SetActiveEx(true)
end

---长入场动画(上台唱歌)
function XUiLottoKarenina:_PlayLongStartAnim(time)
    self._CamAnimStart1:Stop()
    self:PlayAnimation("AnimEnableLong")
    self:PlayTimeLineAnim(self._SceneAnimEnableLong)
    self:PlayTimeLineAnim(self._CamAnimEnableLong, time)
    self:PlayTimeLineAnim(self._CamAnimEnableLongEffect)
    
    self:_StopTimer()
    -- 因为要提前加影子保证最后效果一直，长动画需要检测卡列的动作加影子
    self._LongAnimTimer = XScheduleManager.ScheduleForever(function()
        if not XTool.UObjIsNil(self._ModelAnimator) and self._ModelAnimator:GetCurrentAnimatorStateInfo(0):IsName("LottoStand01loop") then
            self:AddModelShadow()
            self:_StopTimer()
        end
    end, 0, 0)
end

function XUiLottoKarenina:_StopTimer()
    if self._LongAnimTimer then
        XScheduleManager.UnSchedule(self._LongAnimTimer)
    end
end

---跳过进入短入场动画(台上Stand)
function XUiLottoKarenina:PlayShortEnableAnim()
    if self:CheckPanelType(PANEL_TYPE.SHOW) then
        self:PlayAnimationWithMask("AnimEnableShort", function()
            -- 额外奖励和皮肤弹窗摆这里是因为结果回来会播该动画
            -- 弹窗会截图背景做模糊处理，显得过渡不自然
            self:_ShowExtraReward(function()
                self:_ShowFashionReward()
            end)
        end)
        self:PlayTimeLineAnim(self._CamAnimEnableShort)
    elseif self:CheckPanelType(PANEL_TYPE.STAGE) then
        self:PlayStageAnim(true)
    end
    self:AddModelShadow()
end

---关卡镜头动画
function XUiLottoKarenina:PlayStageAnim(isDisableTop)
    if self._InitPanelType == PANEL_TYPE.STAGE or isDisableTop then
        self._InitPanelType = nil
        self:PlayAnimationWithMask("AnimStart2")
    else
        self:PlayAnimationWithMask("AnimEnableStory")
    end
    self:PlayTimeLineAnim(self._CamAnimEnableStory)
end

---关卡镜头动画
function XUiLottoKarenina:PlayStageDisableAnim()
    self:PlayAnimationWithMask("AnimDisableStory")
    self:PlayTimeLineAnim(self._CamAnimDisableStory)
end

---@param anim UnityEngine.Playables.PlayableDirector
---@param directorWrapMode number UnityEngine.Playables.DirectorWrapMode
function XUiLottoKarenina:PlayTimeLineAnim(anim, time, directorWrapMode)
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
function XUiLottoKarenina:PauseTimeLineAnim(anim)
    if not anim then
        return
    end
    anim:Pause()
end

---@param anim UnityEngine.Playables.PlayableDirector
function XUiLottoKarenina:ResumeTimeLineAnim(anim)
    if not anim then
        return
    end
    anim:Play()
end

---@param anim UnityEngine.Playables.PlayableDirector
function XUiLottoKarenina:StopTimeLineAnim(anim)
    if not anim then
        return
    end
    anim:Stop()
end
--endregion

--region Draw
function XUiLottoKarenina:OnDraw()
    local drawData = self._LottoGroupData:GetDrawData()
    characterRecord.Record()
    XDataCenter.LottoManager.DoLotto(drawData:GetId(), function(rewardList, extraRewardList)
        self._PanelType = PANEL_TYPE.SHOW
        XDataCenter.AntiAddictionManager.BeginDrawCardAction()
        self._ExtraRewardList = extraRewardList
        self._RewardList = self:HandleDrawShowReward(rewardList)
        self._IsCanDraw = true
        self:EnableDrawAnim(handler(self, self.AfterDrawAnim))
    end, function()
        self._IsCanDraw = true
    end)
end

function XUiLottoKarenina:AfterDrawAnim()
    local drawData = self._LottoGroupData:GetDrawData()
    local openResult = function()
        --UiDrawResult
        XLuaUiManager.Open("UiDrawShowNew", drawData, self._RewardList, nil, 1, function()
            self.IsDrawBack = true
            self:Refresh()
            self:DisableDrawAnim()
        end)
    end
    ---todo 优化 
    -- XUiPlayTimelineAnimation没加XLuaGen,Lua调不了Stop接口
    -- Disable里不能关闭父节点,因此如果跳过的时候延后一帧再回调
    if self._IsSkipDrawAnim then
        self._IsSkipDrawAnim = false
        XScheduleManager.ScheduleOnce(openResult, 0)
    else
        openResult()
    end
end

function XUiLottoKarenina:HandleDrawShowReward(rewardList)
    if XTool.IsTableEmpty(rewardList) then
        return {}
    end
    for _, reward in ipairs(rewardList) do
        local quality = XDataCenter.LottoManager.GetTemplateQuality(reward.TemplateId)
        reward.SpecialDrawEffectGroupId = XLottoConfigs.GetLottoKalieDrawEffectGroupId(reward.TemplateId, quality)
    end
    return rewardList
end

function XUiLottoKarenina:EnableDrawAnim(cb)
    if self.BtnSkip then
        self.BtnSkip.gameObject:SetActiveEx(true)
    end
    if self.TopControlSpe then
        self.TopControlSpe.gameObject:SetActiveEx(true)
    end
    self:_SetSceneDrawCam(true)
    if XTool.IsTableEmpty(self._RewardList) then
        cb()
        return
    end
    self._DrawTimeLine = "ChoukaVioletEnable"
    for _, reward in ipairs(self._RewardList) do
        local quality = XDataCenter.LottoManager.GetTemplateQuality(reward.TemplateId)
        self._DrawTimeLine = XLottoConfigs.GetLottoKalieDrawTimeLine(reward.TemplateId, quality)
    end
    self:PlayAnimationWithMask("UiDisable")
    if not self._CamAnimDrawDir[self._DrawTimeLine].gameObject.activeSelf then
        self._CamAnimDrawDir[self._DrawTimeLine].gameObject:SetActiveEx(true)
    end
    self._CamAnimDrawDir[self._DrawTimeLine].gameObject:PlayTimelineAnimation(cb)
end

function XUiLottoKarenina:DisableDrawAnim()
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
end

function XUiLottoKarenina:_SetSceneDrawCam(active)
    if not XTool.IsTableEmpty(self._SceneCamDrawList) then
        for _, cam in ipairs(self._SceneCamDrawList) do
            cam.gameObject:SetActiveEx(active)
        end
    end
end

function XUiLottoKarenina:_ShowExtraReward(cb)
    if self._ExtraRewardList and next(self._ExtraRewardList) then
        XUiManager.OpenUiObtain(self._ExtraRewardList, nil, cb)
        self._ExtraRewardList = nil
    else
        if cb then
            cb()
        end
    end
end

--- 检测是否抽到时装
function XUiLottoKarenina:_ShowFashionReward()
    if XTool.IsTableEmpty(self._RewardList) then
        return
    end
    local drawData = self._LottoGroupData:GetDrawData()
    local rewardId = drawData:GetCoreRewardTemplateId()
    for _, v in pairs(self._RewardList) do
        if v.TemplateId == rewardId then
            XLuaUiManager.Open("UiEpicFashionGachaQuickWear", rewardId, XUiHelper.GetText("LottoKareninaFashionTip"))
            self._RewardList = nil
        end
    end
end
--endregion

--region Scene - GlobalIllumination
---设置全局光照,作用暂时不明
function XUiLottoKarenina:SetGlobalIllumination(enable)
    CS.XGlobalIllumination.EnableDistortionInUI = enable
end
--endregion

--region Scene - Obj
function XUiLottoKarenina:InitSceneObj()
    if not self.UiSceneInfo then
        return
    end

    self:InitSceneCam()
    self:InitSceneAnim()
    self:InitCameraAnim()
    self:InitSceneVideo()
    self:InitSceneModel()
end

function XUiLottoKarenina:InitSceneCam()
    ---@type UnityEngine.Transform
    local root = self.UiModelGo.transform
    ---@type UnityEngine.Transform[]
    self._SceneCamDrawList = {
        XUiHelper.TryGetComponent(root, "UiFarRoot/UiFarCamQuan"),
        XUiHelper.TryGetComponent(root, "UiNearRoot/UiNearCamQuan")
    }
end

function XUiLottoKarenina:InitSceneAnim()
    ---@type UnityEngine.RectTransform
    self._SceneAnimRoot = XUiHelper.TryGetComponent(self.UiSceneInfo.Transform, "Animations")
    ---@type UnityEngine.Playables.PlayableDirector
    self._SceneAnimStart = XUiHelper.TryGetComponent(self._SceneAnimRoot, "Timeline_B", "PlayableDirector")
    ---@type UnityEngine.Playables.PlayableDirector
    self._SceneAnimEnableLong = XUiHelper.TryGetComponent(self._SceneAnimRoot, "Timeline_C", "PlayableDirector")
end

function XUiLottoKarenina:InitCameraAnim()
    ---@type UnityEngine.Transform
    local root = self.UiModelGo.transform
    ---@type UnityEngine.Playables.PlayableDirector
    self._CamAnimStart1 = root:FindTransform("AnimStart1"):GetComponent("PlayableDirector")
    self._Mat1 = root:FindTransform("FxUiLottoKareninaMat01")

    ---@type UnityEngine.Playables.PlayableDirector
    self._CamAnimEnableLong = root:FindTransform("AnimEnableLong"):GetComponent("PlayableDirector")
    ---@type UnityEngine.Playables.PlayableDirector
    self._CamAnimEnableShort = root:FindTransform("AnimEnableShort"):GetComponent("PlayableDirector")
    ---@type UnityEngine.Playables.PlayableDirector
    self._CamAnimEnableStory = root:FindTransform("AnimEnableStory"):GetComponent("PlayableDirector")
    ---@type UnityEngine.Playables.PlayableDirector
    self._CamAnimDisableStory = root:FindTransform("AnimDisableStory"):GetComponent("PlayableDirector")
    ---@type UnityEngine.Playables.PlayableDirector
    self._CamAnimEnableLongEffect = root:FindTransform("AnimEnableLongEffect"):GetComponent("PlayableDirector")

    ---@type UnityEngine.Transform[]
    self._CamAnimDrawDir = {}
    self._CamAnimDrawDir.ChoukaVioletEnable = root:FindTransform("ChoukaVioletEnable")
    self._CamAnimDrawDir.ChoukaYellowEnable = root:FindTransform("ChoukaYellowEnable")
    self._CamAnimDrawDir.ChoukaRedEnable = root:FindTransform("ChoukaRedEnable")
end

function XUiLottoKarenina:InitSceneVideo()
    ---@type XVideoPlayerScene
    self._SceneVideoPlayer = XUiHelper.TryGetComponent(self.UiSceneInfo.Transform, "Video", "XVideoPlayerScene")
    if not self._SceneVideoPlayer then
        return
    end

    local videoId = XLottoConfigs.GetLottoClientConfigNumber("KalieVideo")
    local url = XVideoConfig.GetMovieUrlById(videoId)
    self._SceneVideoPlayer:SetVideoFromRelateUrl(url)
end

function XUiLottoKarenina:InitSceneModel()
    ---@type UnityEngine.Transform
    local root = self.UiModelGo.transform
    local modelParent = XUiHelper.TryGetComponent(root, "UiNearRoot/UiModelParent")
    if modelParent then
        self._Model = modelParent:GetChild(0)
    end
    ---@type UnityEngine.Animator
    self._ModelAnimator = self._Model.gameObject:GetComponent("Animator")
end

function XUiLottoKarenina:AddModelShadow()
    if XTool.UObjIsNil(self._Model) then
        return
    end
    CS.XShadowHelper.AddShadow(self._Model.gameObject, true)
end

function XUiLottoKarenina:RemoveModelShadow()
    if XTool.UObjIsNil(self._Model) then
        return
    end
    CS.XShadowHelper.RemoveShadow(self._Model.gameObject, true)
end
--endregion

--region Ui - BtnListener
function XUiLottoKarenina:AddBtnListener()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)

    XUiHelper.RegisterClickEvent(self, self.BtnDrawRule, self.OnBtnDrawRuleClick)
    XUiHelper.RegisterClickEvent(self, self.BtnXiangqing, self.OnBtnRewardDetailClick)
    XUiHelper.RegisterClickEvent(self, self.BtnShield, self.OnBtnSkipAnimClick)
    XUiHelper.RegisterClickEvent(self, self.BtnVoice, self.OnBtnSetClick)
    XUiHelper.RegisterClickEvent(self, self.BtnVoiceStage, self.OnBtnSetClick)
    
    XUiHelper.RegisterClickEvent(self, self.BtnDrawShow, self.OnBtnDrawShowClick)
    XUiHelper.RegisterClickEvent(self, self.BtnStory, self.OnBtnStageClick)
    XUiHelper.RegisterClickEvent(self, self.BtnGo, self.OnBtnBeDrawClick)

    XUiHelper.RegisterClickEvent(self, self.BtnStart, self.OnBtnStartClick)
    if self.BtnSkip then
        XUiHelper.RegisterClickEvent(self, self.BtnSkip, self.OnBtnSkipDrawClick)
    end
end

function XUiLottoKarenina:OnBtnBackClick()
    self:Close()
end

function XUiLottoKarenina:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiLottoKarenina:OnBtnRewardDetailClick()
    XLuaUiManager.Open("UiLottoLog", self._LottoGroupData, 1)
end

function XUiLottoKarenina:OnBtnDrawRuleClick()
    XLuaUiManager.Open("UiLottoLog", self._LottoGroupData)
end

function XUiLottoKarenina:OnBtnSkipAnimClick()
    local state = self.BtnShield:GetToggleState()
    XDataCenter.LottoManager.SetSkipAnim(self._LottoGroupData:GetId(), state)
end

---声音设置
function XUiLottoKarenina:OnBtnSetClick()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Setting) then
        return
    end
    XUiHelper.RecordBuriedSpotTypeLevelOne(XGlobalVar.BtnBuriedSpotTypeLevelOne.BtnUiMainBtnSet)
    XLuaUiManager.Open("UiSet", false)
end

function XUiLottoKarenina:OnBtnDrawShowClick()
    self._PanelType = self._IsExitStagePlayFirst and PANEL_TYPE.FIRST or PANEL_TYPE.SHOW
    self:Refresh()
    if self._IsExitStagePlayFirst then
        self._IsExitStagePlayFirst = false
        self:PlayEnableAnim()
    else
        self:PlayStageDisableAnim()
    end
end

function XUiLottoKarenina:OnBtnStageClick()
    self._PanelType = PANEL_TYPE.STAGE
    self:Refresh()
    self:PlayStageAnim()
end

function XUiLottoKarenina:OnBtnBeDrawClick()
    if XDataCenter.EquipManager.CheckBoxOverLimitOfDraw() then
        return
    end
    local drawData = self._LottoGroupData:GetDrawData()
    if drawData:IsLottoCountFinish() then
        return
    end
    local curItemCount = XDataCenter.ItemManager.GetItem(drawData:GetConsumeId()).Count
    local needItemCount = drawData:GetConsumeCount()
    if needItemCount > curItemCount then
        --XUiManager.TipErrorWithKey("DrawNotEnoughSkipText")
        XLuaUiManager.Open("UiLottoTanchuang", drawData, function()
            self:Refresh()
        end)
        return
    end

    self._PanelType = PANEL_TYPE.DRAW
    self:OnDraw()
end

function XUiLottoKarenina:OnBtnStartClick()
    XDataCenter.LottoManager.SetFirstAnim(self._LottoGroupData:GetId(), true)
    self._PanelType = PANEL_TYPE.SHOW
    self:Refresh()
    self:_PlayLongStartAnim()
end

function XUiLottoKarenina:OnBtnSkipDrawClick()
    self._IsSkipDrawAnim = true
    self._CamAnimDrawDir[self._DrawTimeLine].gameObject:SetActiveEx(false)
    self._CamAnimDrawDir[self._DrawTimeLine].gameObject:SetActiveEx(true)
end
--endregion