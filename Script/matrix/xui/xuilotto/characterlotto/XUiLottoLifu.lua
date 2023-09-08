---@class XUiLotto
---@field BtnShield XUiComponent.XUiButton
local XUiLotto = XLuaUiManager.Register(XLuaUi, "UiLotto")
local XUiPanelLottoPreview = require("XUi/XUiLotto/XUiPanelLottoPreview")
local characterRecord = require("XUi/XUiDraw/XUiDrawTools/XUiDrawCharacterRecord")
local CSTextManagerGetText = CS.XTextManager.GetText
local SkipKey = "UiLottoSkipAnim" .. XPlayer.Id

---@param groupData XLottoGroupEntity
function XUiLotto:OnStart(groupData, closeCb, backGround)
    self.LottoGroupData = groupData
    self.CloseCb = closeCb
    self.BackGroundPath = backGround
    self.TxtTitle.text = groupData:GetName()
    self.IsCanDraw = true
    local drawData = self.LottoGroupData:GetDrawData()
    --self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.HongKa, drawData:GetConsumeId())
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool, self)
    local itemIds = {
        XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.HongKa, drawData:GetConsumeId()
    }
    XDataCenter.ItemManager.AddCountUpdateListener(
            itemIds,
            function()
                self.AssetActivityPanel:Refresh(itemIds)
            end,
            self.AssetActivityPanel
    )
    self.AssetActivityPanel:Refresh(itemIds)
    self.PanelLottoPreview = XUiPanelLottoPreview.New(self.PanelPreview, self, groupData)
    self:SetBtnCallBack()
    self:InitDrawBackGround(self.BackGroundPath)
    self:InitSceneRoot()
    local bannerBg = groupData:GetBanner()
    --self.RImgBg.gameObject:SetActiveEx(not string.IsNilOrEmpty(bannerBg))
    if bannerBg and self.PanelDrawBackGround then
        --self.RImgBg:SetRawImage(bannerBg)
        --临时屏蔽bannerBg
        --self.PanelDrawBackGround:LoadPrefab(bannerBg)
    end
    self:PlayStartAnimation()
end

function XUiLotto:OnDestroy()
    if self.CloseCb then
        self.CloseCb()
    end
end

function XUiLotto:InitSceneRoot()
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

function XUiLotto:OnEnable()
    self:StartTimer()

    --XLuaUiManager.SetMask(true)
    --self:PlayAnimation("DrawBegan", function()
    --    XLuaUiManager.SetMask(false)
    --    self:ShowExtraReward()
    --end)
    self:UpdateAllPanel()
    --self.PlayableDirector = self.BackGround:GetComponent("PlayableDirector")
    --self.PlayableDirector:Stop()
    --self.PlayableDirector:Evaluate()
    if self.IsDrawBack then
        self:PlayAnimation("AnimStart2")
        self.IsDrawBack = false
    end

    CS.XGlobalIllumination.EnableDistortionInUI = true
end

function XUiLotto:PlayStartAnimation()
    local key = "UiLottoLifu" .. XPlayer.Id
    local isFirstIn = XSaveTool.GetData(key)
    local isSkipAnim = XSaveTool.GetData(SkipKey)
    self.BtnStart.gameObject:SetActiveEx(isFirstIn ~= 1)
    if not isFirstIn then
        self:PlayFirstStartAnimation()
        XSaveTool.SaveData(key, 1)
        XSaveTool.SaveData(SkipKey, 2)
        self.BtnShield:SetButtonState(XUiButtonState.Select)
    else
        if isSkipAnim and isSkipAnim > 1 then
            self.BtnShield:SetButtonState(XUiButtonState.Select)
            self:PlayShortEnableAnimation()
        else
            self.BtnShield:SetButtonState(XUiButtonState.Normal)
            self:PlayLongEnableAnimation()
        end
    end
end

function XUiLotto:OnDisable()
    self:StopTimer()
    CS.XGlobalIllumination.EnableDistortionInUI = false
end

function XUiLotto:SetBtnCallBack()
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
        if state then
            XSaveTool.SaveData(SkipKey, 2)
        else
            XSaveTool.SaveData(SkipKey, 1)
        end
    end
    self.BtnStart.CallBack = function()
        self.BtnStart.gameObject:SetActiveEx(false)
        self:PlayLongEnableAnimation(self.AnimationStart1:GetComponent("PlayableDirector").time)
        self.AnimationStart1:GetComponent("PlayableDirector"):Pause()
    end

    self.BtnDraw.CallBack = function()
        self:PlayDrawSecondAnimation()
    end
end

function XUiLotto:OnBtnBackClick()
    self:Close()
end

function XUiLotto:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiLotto:OnBtnUseItemClick()
    local drawData = self.LottoGroupData:GetDrawData()
    local data = XDataCenter.ItemManager.GetItem(drawData:GetConsumeId())
    XLuaUiManager.Open("UiTip", data)
end

function XUiLotto:OnBtnDrawRuleClick()
    XLuaUiManager.Open("UiLottoLog", self.LottoGroupData)
end

function XUiLotto:OnBtnDrawClick()
    self:OnDraw()
end

function XUiLotto:InitDrawBackGround(backgroundName)
    --local root = self.UiSceneInfo.Transform
    --self.BackGround = root:FindTransform("GroupBase"):LoadPrefab(backgroundName)
    --CS.XShadowHelper.AddShadow(self.BackGround:FindTransform("BoxModeParent").gameObject)
end

function XUiLotto:UpdateAllPanel()
    self:UpdatePanelPreview()
    self:UpdatePanelDrawButtons()
    self:UpdatePanelUseItem()
    self:UpdateDrawTime()
end

function XUiLotto:UpdatePanelPreview()
    self.PanelLottoPreview:UpdatePanel()
end

function XUiLotto:UpdatePanelDrawButtons()
    local drawData = self.LottoGroupData:GetDrawData()
    local icon = XDataCenter.ItemManager.GetItemBigIcon(drawData:GetConsumeId())
    self.PanelDrawButtons:GetObject("BtnDraw").gameObject:SetActiveEx(not drawData:IsLottoCountFinish())
    self.PanelDrawButtons:GetObject("ImgUseItemIcon"):SetRawImage(icon)
    self.PanelDrawButtons:GetObject("TxtUseItemCount").text = drawData:GetConsumeCount() > 0 and
            drawData:GetConsumeCount() or CSTextManagerGetText("LottoDrawFreeText")
end

function XUiLotto:UpdatePanelUseItem()
    local drawData = self.LottoGroupData:GetDrawData()
    local icon = XDataCenter.ItemManager.GetItemBigIcon(drawData:GetConsumeId())

    self.PanelUseItem:GetObject("ImgUseItemIcon"):SetRawImage(icon)
    self.PanelUseItem:GetObject("TxtUseItemCount").text = XDataCenter.ItemManager.GetItem(drawData:GetConsumeId()).Count
end

function XUiLotto:UpdateDrawTime()
    local drawData = self.LottoGroupData:GetDrawData()
    local timeId = drawData:GetTimeId()
    local startTime = XFunctionManager.GetStartTimeByTimeId(timeId)
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    local startTimeStr = XTime.TimestampToGameDateTimeString(startTime, "MM/dd")
    local endTimeStr = XTime.TimestampToGameDateTimeString(endTime, "MM/dd HH:mm")
    if self.TxtTime then
        self.TxtTime.text = CS.XTextManager.GetText("LottoTimeStr", startTimeStr, endTimeStr)
    end
end

function XUiLotto:ShowExtraReward(cb)
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

function XUiLotto:OnDraw()
    if XDataCenter.EquipManager.CheckBoxOverLimitOfDraw() then
        return
    end
    local drawData = self.LottoGroupData:GetDrawData()
    local curItemCount = XDataCenter.ItemManager.GetItem(drawData:GetConsumeId()).Count
    local needItemCount = drawData:GetConsumeCount()
    if needItemCount > curItemCount then
        XUiManager.TipMsg(CSTextManagerGetText("DrawNotEnoughSkipText"))
        XLuaUiManager.Open("UiLottoTanchuang", drawData, function()
            self:UpdateAllPanel()
        end)
        return
    end

    if self.IsCanDraw then
        self.IsCanDraw = false
        characterRecord.Record()
        local drawData = self.LottoGroupData:GetDrawData()
        XDataCenter.LottoManager.DoLotto(drawData:GetId(), function(rewardList, extraRewardList)
            XDataCenter.AntiAddictionManager.BeginDrawCardAction()
            self.ExtraRewardList = extraRewardList
            self.RewardList = rewardList
            self.IsCanDraw = true
            self:PlayDrawFirstAnimation()
        end, function()
            self.IsCanDraw = true
        end)
    end
end

function XUiLotto:HideUiView(rewardList)
    self.OpenSound = CS.XAudioManager.PlaySound(XSoundManager.UiBasicsMusic.UiDrawCard_BoxOpen)
    XLuaUiManager.SetMask(true)
    self:PlayAnimation("DrawRetract", function()
        if rewardList and next(rewardList) then
            self.IsCanDraw = true
            self:PushShow(rewardList)
        end
        XLuaUiManager.SetMask(false)
    end)
end

function XUiLotto:PushShow(rewardList)
    self:OpenChildUi("UiLottoShow")
    self:FindChildUiObj("UiLottoShow"):SetData(rewardList, function()
        if self.OpenSound then
            self.OpenSound:Stop()
        end
        XLuaUiManager.Open("UiDrawResult", nil, rewardList, function()
        end)
    end, self.BackGround)
end

function XUiLotto:StartTimer()
    if self.Timer then
        self:StopTimer()
    end
    self.Timer = XScheduleManager.ScheduleForever(function()
        local now = XTime.GetServerNowTimestamp()
        local drawData = self.LottoGroupData:GetDrawData()
        local timeId = drawData:GetTimeId()
        local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
        if now > endTime then
            XUiManager.TipText("LottoActivityOver")
            XLuaUiManager.RunMain()
        end
    end, XScheduleManager.SECOND, 0)
end

function XUiLotto:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiLotto:PlayFirstStartAnimation()
    self:PlayAnimation("AnimStart1", function()
        self:ShowExtraReward()
    end)
    --设置循环模式为Loop
    self.AnimationStart1:PlayTimelineAnimation(nil, nil, CS.UnityEngine.Playables.DirectorWrapMode.Loop)
end

function XUiLotto:PlayLongEnableAnimation(time)
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

function XUiLotto:PlayShortEnableAnimation()
    XLuaUiManager.SetMask(true)
    self:PlayAnimation("AnimEnableShort", function()
        XLuaUiManager.SetMask(false)
        self:ShowExtraReward()
    end)
    self.AnimEnableShort:PlayTimelineAnimation(nil, nil, CS.UnityEngine.Playables.DirectorWrapMode.None)
end

function XUiLotto:PlayDrawFirstAnimation()
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

function XUiLotto:PlayDrawSecondAnimation()
    XLuaUiManager.SetMask(true)
    self.BtnDraw.gameObject:SetActiveEx(false)

    self.CardDrawing:PlayTimelineAnimation(function()
        XLuaUiManager.SetMask(false)
        if self.ShowEffect then
            self.ShowEffect.gameObject:SetActiveEx(false)
        end
        XLuaUiManager.Open("UiDrawShow", self.LottoGroupData:GetDrawData(), self.RewardList, function()
            XLuaUiManager.Open("UiDrawResult", self.LottoGroupData:GetDrawData(), self.RewardList, function()
                self.IsDrawBack = true
            end, CS.XGame.ClientConfig:GetString("LottoDrawGround"))
        end)
    end, function()
        local anim = XLottoConfigs.GetLottoRewardAnimationName(self.RewardList[1].TemplateId)
        if not string.IsNilOrEmpty(anim) then
            self[anim]:PlayTimelineAnimation(nil, nil, CS.UnityEngine.Playables.DirectorWrapMode.None)
        end
    end, CS.UnityEngine.Playables.DirectorWrapMode.None)
end
