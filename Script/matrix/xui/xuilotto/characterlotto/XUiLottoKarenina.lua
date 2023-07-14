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
    if XDataCenter.LottoManager.GetFirstAnim(self._LottoGroupData:GetId()) or not XDataCenter.LottoManager.GetSkipAnim(self._LottoGroupData:GetId()) then
        self._PanelType = PANEL_TYPE.FIRST
    else
        if XTool.IsNumberValid(initPanelType) then
            self._PanelType = initPanelType
        else
            self._PanelType = self._CachePanelType and self._CachePanelType or PANEL_TYPE.SHOW
        end
    end

    self:Init()
    self:AddBtnListener()
end

function XUiLottoKarenina:OnEnable()
    self:Refresh()
    self:StartAutoCloseTimer()
    self:SetGlobalIllumination(true)

    self:PlayStartAnim()
end

function XUiLottoKarenina:OnDisable()
    self:CloseAutoCloseTimer()
    self:SetGlobalIllumination(false)
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
    
    self.PanelDrawGroup.gameObject:SetActiveEx(self:CheckPanelType(PANEL_TYPE.SHOW))
    self.PanelStory.gameObject:SetActiveEx(self:CheckPanelType(PANEL_TYPE.STAGE))
    self.PanelDrawEffect.gameObject:SetActiveEx(self:CheckPanelType(PANEL_TYPE.DRAW))
    self.BtnDraw.gameObject:SetActiveEx(self:CheckPanelType(PANEL_TYPE.DRAW))
    self.BtnStart.gameObject:SetActiveEx(self:CheckPanelType(PANEL_TYPE.FIRST))
end

--region Checker
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
    self._PanelAsset = XUiHelper.NewPanelActivityAsset(itemIds, self.PanelSpecialTool)
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

function XUiLottoKarenina:PlayStartAnim()
    local isFirst = XDataCenter.LottoManager.GetFirstAnim(self._LottoGroupData:GetId())
    local isSkip = XDataCenter.LottoManager.GetSkipAnim(self._LottoGroupData:GetId())
    if isFirst then
        --播放完首次动画后默认跳过动画
        isSkip = true
        self:_PlayStartAnim()
        XDataCenter.LottoManager.SetSkipAnim(self._LottoGroupData:GetId(), isSkip)
    else
        if isSkip then
            self:PlayShortStartAnim()
        else
            self:_PlayStartAnim()
        end
    end
    self:RefreshSkipBtn(isSkip)
end

---首次进入和不跳过进入待点击动画(卡列徘徊)
function XUiLottoKarenina:_PlayStartAnim()
    self.BtnStart.gameObject:SetActiveEx(false)
    self:PlayAnimation("AnimStart1")
    self._CamAnimStart1.gameObject:PlayTimelineAnimation(function()
        self.BtnStart.gameObject:SetActiveEx(true)
    end)
end

---长入场动画(上台唱歌)
function XUiLottoKarenina:_PlayLongStartAnim(time)
    self._UiAnimEnableLong.initialTime = time or 0
    self._UiAnimEnableLong.extrapolationMode = CS.UnityEngine.Playables.DirectorWrapMode.Hold
    self._UiAnimEnableLong:Evaluate()
    self._UiAnimEnableLong:Play()
    
    self._CamAnimEnableLong.initialTime = time or 0
    self._CamAnimEnableLong:Evaluate()
    self._CamAnimEnableLong:Play()
    self._CamAnimStart1:Stop()
    XLuaUiManager.SetMask(true)
    XScheduleManager.ScheduleOnce(function()
        XLuaUiManager.SetMask(false)
    end, self._CamAnimEnableLong.duration * XScheduleManager.SECOND)
end

---跳过进入短入场动画(台上Stand)
function XUiLottoKarenina:PlayShortStartAnim()
    if self:CheckPanelType(PANEL_TYPE.SHOW) then
        self:PlayAnimation("AnimEnableShort")
        self._CamAnimEnableShort.initialTime = 0
        self._CamAnimEnableShort:Evaluate()
        self._CamAnimEnableShort:Play()
    elseif self:CheckPanelType(PANEL_TYPE.STAGE) then
        
    end
end

---关卡镜头动画
function XUiLottoKarenina:PlayStageAnim()

end

---抽奖动画
function XUiLottoKarenina:PlayDrawAnim()

end
--endregion

--region Draw
function XUiLottoKarenina:OnDraw()
    local drawData = self._LottoGroupData:GetDrawData()
    characterRecord.Record()
    XDataCenter.LottoManager.DoLotto(drawData:GetId(), function(rewardList, extraRewardList)
        XDataCenter.AntiAddictionManager.BeginDrawCardAction()
        self._ExtraRewardList = extraRewardList
        self._RewardList = rewardList
        self._IsCanDraw = true
        --UiDrawResult
        XLuaUiManager.Open("UiDrawShowNew", drawData, self._RewardList, nil, 1, function()
            self.IsDrawBack = true
            self._PanelType = PANEL_TYPE.SHOW
            self:Refresh()
            self:_ShowExtraReward(function()
                self:_ShowFashionReward()
            end)
        end)
    end, function()
        self._IsCanDraw = true
    end)
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
    local drawData = self._LottoGroupData:GetDrawData()
    local rewardId = drawData:GetCoreRewardTemplateId()
    for _, v in pairs(self._RewardList) do
        if v.TemplateId == rewardId then
            XLuaUiManager.Open("UiEpicFashionGachaQuickWear", rewardId, XUiHelper.GetText("LottoKareninaFashionTip"))
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
    if not self:CheckIsHaveScene() then
        return
    end

    self:InitSceneAnim()
    self:InitCameraAnim()
    ---@class XVideoPlayerScene
    self._SceneVideoPlayer = XUiHelper.TryGetComponent(self.UiSceneInfo.Transform, "Video", "XVideoPlayerScene")
    
    self:_InitSceneVideo()
end

function XUiLottoKarenina:InitSceneAnim()
    
end

function XUiLottoKarenina:InitCameraAnim()
    ---@type UnityEngine.Transform
    local root = self.UiModelGo.transform
    ---@type UnityEngine.Playables.PlayableDirector
    self._CamAnimStart1 = root:FindTransform("AnimStart1"):GetComponent("PlayableDirector")
    ---@type UnityEngine.Playables.PlayableDirector
    self._CamAnimEnableLong = root:FindTransform("AnimEnableLong"):GetComponent("PlayableDirector")
    ---@type UnityEngine.Playables.PlayableDirector
    self._CamAnimEnableShort = root:FindTransform("AnimEnableShort"):GetComponent("PlayableDirector")
    ---@type UnityEngine.Playables.PlayableDirector
    self._CamEffectEnable = root:FindTransform("EffectEnable"):GetComponent("PlayableDirector")
end

function XUiLottoKarenina:CheckIsHaveScene()
    return self.UiSceneInfo
end
--endregion

--region Scene - Video
function XUiLottoKarenina:_InitSceneVideo()
    if not self._SceneVideoPlayer then
        return
    end

    local videoId = XLottoConfigs.GetLottoClientConfigNumber("KalieVideo")
    local url = XVideoConfig.GetMovieUrlById(videoId)
    self._SceneVideoPlayer:SetVideoFromRelateUrl(url)
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
    XUiHelper.RegisterClickEvent(self, self.BtnDraw, self.OnBtnDrawClick)
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
    self._PanelType = PANEL_TYPE.SHOW
    self:Refresh()
end

function XUiLottoKarenina:OnBtnStageClick()
    self._PanelType = PANEL_TYPE.STAGE
    self:Refresh()
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

function XUiLottoKarenina:OnBtnDrawClick()
    self:Close()
end
--endregion