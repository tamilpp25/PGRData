local XUiPanelActivityAsset = require("XUi/XUiShop/XUiPanelActivityAsset")
---@class XUiLottoLifu:XLuaUi
---@field BtnShield XUiComponent.XUiButton
local XUiLottoLifu = XLuaUiManager.Register(XLuaUi, "UiLottoLifu")

---@param groupData XLottoGroupEntity
function XUiLottoLifu:OnStart(groupData, closeCb, backGround)
    self._LottoGroupData = groupData
    self._CloseCb = closeCb
    self._IsDrawBack = false
    
    self:InitPanelAsset()
    self:InitPanelReward()
    self:InitDrawControl()
    self:InitSceneRoot()
    
    self:AddBtnListener()
    self:PlayStartAnimation()
end

function XUiLottoLifu:OnEnable()
    CS.XGlobalIllumination.EnableDistortionInUI = true
    self:UpdateAllPanel()

    self:PlayDrawBackEnableAnim()
    self:StartAutoCloseTimer()
    self:AddEventListener()
end

function XUiLottoLifu:OnDisable()
    CS.XGlobalIllumination.EnableDistortionInUI = false
    self:StopAutoCloseTimer()
    self:RemoveEventListener()
end

function XUiLottoLifu:OnDestroy()
    if self._CloseCb then
        self._CloseCb()
    end
end

function XUiLottoLifu:UpdateAllPanel()
    self:UpdatePanelPreview()
    self:UpdatePanelDrawButtons()
    self:UpdatePanelUseItem()
    self:UpdateDrawTitleAndTime()
end

--region Ui - AutoClose
function XUiLottoLifu:StartAutoCloseTimer()
    if self.Timer then
        self:StopAutoCloseTimer()
    end
    self.Timer = XScheduleManager.ScheduleForever(function()
        local now = XTime.GetServerNowTimestamp()
        local drawData = self._LottoGroupData:GetDrawData()
        local timeId = drawData:GetTimeId()
        local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
        if now > endTime then
            XUiManager.TipText("LottoActivityOver")
            XLuaUiManager.RunMain()
        end
    end, XScheduleManager.SECOND, 0)
end

function XUiLottoLifu:StopAutoCloseTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end
--endregion

--region Ui - PanelAsset
function XUiLottoLifu:InitPanelAsset()
    local drawData = self._LottoGroupData:GetDrawData()
    local itemIds = {
        XDataCenter.ItemManager.ItemId.FreeGem,
        XDataCenter.ItemManager.ItemId.HongKa,
        drawData:GetConsumeId()
    }
    ---@type XUiPanelActivityAsset
    self._PanelAsset = XUiHelper.NewPanelActivityAssetSafe(itemIds, self.PanelSpecialTool, self)
end
--endregion

--region Ui - Title
function XUiLottoLifu:UpdateDrawTitleAndTime()
    local drawData = self._LottoGroupData:GetDrawData()
    local timeId = drawData:GetTimeId()
    local startTime = XFunctionManager.GetStartTimeByTimeId(timeId)
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    local startTimeStr = XTime.TimestampToGameDateTimeString(startTime, "MM/dd")
    local endTimeStr = XTime.TimestampToGameDateTimeString(endTime, "MM/dd HH:mm")
    if self.TxtTime then
        self.TxtTime.text = CS.XTextManager.GetText("LottoTimeStr", startTimeStr, endTimeStr)
    end
    self.TxtTitle.text = self._LottoGroupData:GetName()
end
--endregion

--region Ui - PanelReward
function XUiLottoLifu:InitPanelReward()
    local XUiPanelLottoPreview = require("XUi/XUiLotto/XUiPanelLottoPreview")
    ---@type XUiPanelLottoPreview
    self.PanelLottoPreview = XUiPanelLottoPreview.New(self.PanelPreview, self, self._LottoGroupData)
end

function XUiLottoLifu:UpdatePanelPreview()
    self.PanelLottoPreview:UpdatePanel()
end
--endregion

--region Ui - PanelDraw
function XUiLottoLifu:UpdatePanelDrawButtons()
    local drawData = self._LottoGroupData:GetDrawData()
    local icon = XDataCenter.ItemManager.GetItemBigIcon(drawData:GetConsumeId())
    self.PanelDrawButtons:GetObject("BtnDraw"):SetDisable(drawData:IsLottoCountFinish())
    if drawData:IsLottoCountFinish() then
        self.PanelDrawButtons:GetObject("ImgUseItemIcon").transform.parent.gameObject:SetActiveEx(false)
    else
        self.PanelDrawButtons:GetObject("ImgUseItemIcon").transform.parent.gameObject:SetActiveEx(true)
        self.PanelDrawButtons:GetObject("ImgUseItemIcon"):SetRawImage(icon)
        self.PanelDrawButtons:GetObject("TxtUseItemCount").text = drawData:GetConsumeCount() > 0 and
                drawData:GetConsumeCount() or XUiHelper.GetText("LottoDrawFreeText")
    end
    
end

function XUiLottoLifu:UpdatePanelUseItem()
    local drawData = self._LottoGroupData:GetDrawData()
    local icon = XDataCenter.ItemManager.GetItemBigIcon(drawData:GetConsumeId())

    self.PanelUseItem:GetObject("ImgUseItemIcon"):SetRawImage(icon)
    self.PanelUseItem:GetObject("TxtUseItemCount").text = XDataCenter.ItemManager.GetItem(drawData:GetConsumeId()).Count
end

function XUiLottoLifu:ShowExtraReward(cb)
    if self.ExtraRewardList and next(self.ExtraRewardList) then
        XUiManager.OpenUiObtain(self.ExtraRewardList, nil, function()
            if cb then
                cb()
            end
        end)
        self.ExtraRewardList = nil
    else
        if cb then
            cb()
        end
    end
end
--endregion

--region Ui - Anim
function XUiLottoLifu:PlayStartAnimation()
    local isFirstIn = XDataCenter.LottoManager.GetFirstAnim(self._LottoGroupData:GetId())
    local isSkipAnim = XDataCenter.LottoManager.GetSkipAnim(self._LottoGroupData:GetId())
    self.BtnStart.gameObject:SetActiveEx(isFirstIn)
    if isFirstIn then
        isSkipAnim = true
        XDataCenter.LottoManager.SetFirstAnim(self._LottoGroupData:GetId(), true)
        XDataCenter.LottoManager.SetSkipAnim(self._LottoGroupData:GetId(), isSkipAnim)
        self:_PlayFirstStartAnimation()
    else
        if isSkipAnim then
            self:_PlayShortEnableAnimation()
        else
            self:_PlayLongEnableAnimation()
        end
    end
    self:RefreshSkipBtn(isSkipAnim)
end

function XUiLottoLifu:_PlayFirstStartAnimation()
    self:PlayAnimation("AnimStart1", function()
        self:ShowExtraReward()
    end)
    --设置循环模式为Loop
    self.AnimationStart1:PlayTimelineAnimation(nil, nil, CS.UnityEngine.Playables.DirectorWrapMode.Loop)
end

function XUiLottoLifu:_PlayLongEnableAnimation(time)
    ---@type UnityEngine.Playables.PlayableDirector
    local uiDirector = self.GameObject:FindTransform("AnimEnableLong"):GetComponent("PlayableDirector")
    uiDirector.initialTime = time or 0
    uiDirector.extrapolationMode = CS.UnityEngine.Playables.DirectorWrapMode.Hold
    uiDirector:Evaluate()
    uiDirector:Play()
    local longDirector = self.AnimEnableLong:GetComponent("PlayableDirector")
    longDirector.initialTime = time or 0
    longDirector:Evaluate()
    longDirector:Play()
    XLuaUiManager.SetMask(true)
    self.AnimationStart1:GetComponent("PlayableDirector"):Stop()
    XScheduleManager.ScheduleOnce(function()
        XLuaUiManager.SetMask(false)
        self:ShowExtraReward()
    end, longDirector.duration * XScheduleManager.SECOND)
end

function XUiLottoLifu:_PlayShortEnableAnimation()
    XLuaUiManager.SetMask(true)
    self:PlayAnimation("AnimEnableShort", function()
        XLuaUiManager.SetMask(false)
        self:ShowExtraReward()
    end)
    self.AnimEnableShort:PlayTimelineAnimation(nil, nil, CS.UnityEngine.Playables.DirectorWrapMode.None)
end

function XUiLottoLifu:PlayBeDrawAnimation()
    XLuaUiManager.SetMask(true)
    local antiAliasing = CS.UnityEngine.QualitySettings.antiAliasing
    CS.UnityEngine.QualitySettings.antiAliasing = 0
    self:PlayAnimation("UiDisable")
    self:PlayAnimation("CanvasEnable")
    self.EffectEnable:PlayTimelineAnimation(function()
        self.BtnDraw.gameObject:SetActiveEx(true)
        XLuaUiManager.SetMask(false)
        CS.UnityEngine.QualitySettings.antiAliasing = antiAliasing
    end, nil, CS.UnityEngine.Playables.DirectorWrapMode.None)
end

function XUiLottoLifu:PlayDrawBackEnableAnim()
    if self._IsDrawBack then
        self:PlayAnimation("AnimStart2", function()
            -- 原因参考XUiLottoKarenina:PlayShortEnableAnim()
            self:ShowRewardDialog()
        end)
        self._IsDrawBack = false
    end
end
--endregion

--region Ui - BtnUpdate
function XUiLottoLifu:RefreshSkipBtn(isSkip)
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

--region Ui - BtnListener
function XUiLottoLifu:AddBtnListener()
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
    self.PanelUseItem:GetObject("BtnUseItem").CallBack = function()
        self:OnBtnUseItemClick()
    end
    self.BtnDrawRule.CallBack = function()
        self:OnBtnDrawRuleClick()
    end
    self.PanelDrawButtons:GetObject("BtnDraw").CallBack = function()
        self:OnBtnDrawClick()
    end
    self.BtnShield.CallBack = function()
        local state = self.BtnShield:GetToggleState()
        XDataCenter.LottoManager.SetSkipAnim(self._LottoGroupData:GetId(), state)
    end
    self.BtnStart.CallBack = function()
        self.BtnStart.gameObject:SetActiveEx(false)
        self:_PlayLongEnableAnimation(self.AnimationStart1:GetComponent("PlayableDirector").time)
        self.AnimationStart1:GetComponent("PlayableDirector"):Pause()
    end

    self.BtnDraw.CallBack = function()
        self:FinishDrawAnim()
    end
    self.BtnXiangqing.CallBack = function() self:OnBtnShowRewardClick() end
    self.BtnStory.CallBack = function() self:OnBtnSkip2StoryClick() end
    self.BtnVoice.CallBack = function() self:OnBtnVoiceClick() end
end

function XUiLottoLifu:OnBtnBackClick()
    self:Close()
end

function XUiLottoLifu:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiLottoLifu:OnBtnUseItemClick()
    local drawData = self._LottoGroupData:GetDrawData()
    local data = XDataCenter.ItemManager.GetItem(drawData:GetConsumeId())
    XLuaUiManager.Open("UiTip", data)
end

function XUiLottoLifu:OnBtnDrawRuleClick()
    XLuaUiManager.Open("UiLottoLog", self._LottoGroupData, 2, XEnumConst.Lotto.Lifu)
end

function XUiLottoLifu:OnBtnShowRewardClick()
    XLuaUiManager.Open("UiLottoLog", self._LottoGroupData, 1, XEnumConst.Lotto.Lifu)
end

function XUiLottoLifu:OnBtnSkip2StoryClick()
    if XLuaUiManager.IsUiLoad("UiFubenChristmasMainLineChapter") then
        self:Close()
        return
    end
    local activityId = XLottoConfigs.GetLottoStageActivity(self._LottoGroupData:GetId())
    if not XTool.IsNumberValid(activityId) then
        return
    end
    local festivalCfg = XFestivalActivityConfig.GetFestivalById(activityId)
    XFunctionManager.SkipInterface(festivalCfg.SkipId[1])
end

function XUiLottoLifu:OnBtnVoiceClick()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Setting) then
        return
    end
    XLuaUiManager.Open("UiSet", false)
end

function XUiLottoLifu:OnBtnDrawClick()
    self._DrawControl:OnBtnDrawClick()
end
--endregion

--region Draw
function XUiLottoLifu:InitDrawControl()
    local XUiLottoDrawControl = require("XUi/XUiLotto/Draw/XUiLottoDrawControl")
    ---@type XUiLottoDrawControl
    self._DrawControl = XUiLottoDrawControl.New(self.Transform, self, self._LottoGroupData)
end

function XUiLottoLifu:ShowRewardDialog()
    self._DrawControl:ShowRewardDialog(XEnumConst.Lotto.Lifu)
end

function XUiLottoLifu:FinishDrawAnim()
    XEventManager.DispatchEvent(XEventId.EVENT_LOTTO_DRAW_ON_FINISH)
end

function XUiLottoLifu:ShowDrawResult()
    self.BtnDraw.gameObject:SetActiveEx(false)
    XLuaUiManager.SetMask(true)
    self.CardDrawing:PlayTimelineAnimation(function()
        XLuaUiManager.SetMask(false)
        if self.ShowEffect then
            self.ShowEffect.gameObject:SetActiveEx(false)
        end
        self._DrawControl:ShowDrawResult()
        self._IsDrawBack = true
    end, function()
        local lottoRewardId = self._DrawControl:GetShowResultLottoRewardId()
        local lottoRewardEntity = self._LottoGroupData:GetDrawData():GetRewardDataById(lottoRewardId)
        local anim = lottoRewardEntity:GetShowTimeLineName()
        if not string.IsNilOrEmpty(anim) then
            self[anim]:PlayTimelineAnimation(nil, nil, CS.UnityEngine.Playables.DirectorWrapMode.None)
        end
    end, CS.UnityEngine.Playables.DirectorWrapMode.None)
end
--endregion

--region Scene
function XUiLottoLifu:InitSceneRoot()
    ---@type UnityEngine.Transform
    local root = self.UiModelGo.transform
    ---@type UnityEngine.Transform
    self.AnimationStart1 = root:FindTransform("AnimStart1")
    ---@type UnityEngine.Transform
    self.AnimEnableLong = root:FindTransform("AnimEnableLong")
    ---@type UnityEngine.Transform
    self.AnimEnableShort = root:FindTransform("AnimEnableShort")
    ---@type UnityEngine.Transform
    self.EffectEnable = root:FindTransform("EffectEnable")
    ---@type UnityEngine.Transform
    self.CardDrawing = root:FindTransform("CardDrawing")
    ---@type UnityEngine.Transform
    self.EffectParent = root:Find("UiEffectRoot/Animation")
    ---@type UnityEngine.Transform
    self.TxDaoju01Enable = root:FindTransform("TxDaoju01Enable")
    ---@type UnityEngine.Transform
    self.TxDaoju02Enable = root:FindTransform("TxDaoju02Enable")
    ---@type UnityEngine.Transform
    self.TxDaoju03Enable = root:FindTransform("TxDaoju03Enable")
end
--endregion

--region Event
function XUiLottoLifu:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_LOTTO_AFTER_BUY_DRAW_SKIP_TICKET, self.UpdateAllPanel, self)
    XEventManager.AddEventListener(XEventId.EVENT_LOTTO_AFTER_DRAW_RESULT_SHOW, self.UpdateAllPanel, self)
    XEventManager.AddEventListener(XEventId.EVENT_LOTTO_DRAW_ON_START, self.PlayBeDrawAnimation, self)
    XEventManager.AddEventListener(XEventId.EVENT_LOTTO_DRAW_ON_FINISH, self.ShowDrawResult, self)
end

function XUiLottoLifu:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_LOTTO_AFTER_BUY_DRAW_SKIP_TICKET, self.UpdateAllPanel, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_LOTTO_AFTER_DRAW_RESULT_SHOW, self.UpdateAllPanel, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_LOTTO_DRAW_ON_START, self.PlayBeDrawAnimation, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_LOTTO_DRAW_ON_FINISH, self.ShowDrawResult, self)
end
--endregion
