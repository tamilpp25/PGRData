local XUiLotto = XLuaUiManager.Register(XLuaUi, "UiLotto")
local XUiPanelLottoPreview = require("XUi/XUiLotto/XUiPanelLottoPreview")
local characterRecord = require("XUi/XUiDraw/XUiDrawTools/XUiDrawCharacterRecord")
local CSTextManagerGetText = CS.XTextManager.GetText
---@param groupData XLottoGroupEntity
function XUiLotto:OnStart(groupData, closeCb, backGround)
    self.LottoGroupData = groupData
    self.CloseCb = closeCb
    self.BackGroundPath = backGround
    self.TxtTitle.text = groupData:GetName()
    self.IsCanDraw = true
    self.AssetPanel = XUiHelper.NewPanelActivityAssetSafe({ XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.HongKa }, self.PanelSpecialTool, self)

    XDataCenter.ItemManager.AddCountUpdateListener(XDataCenter.ItemManager.ItemId.PaidGem,function ()
        self.AssetPanel:Refresh({ XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.HongKa })
    end, self.AssetPanel)
    
    self.PanelLottoPreview = XUiPanelLottoPreview.New(self.PanelPreview, self, groupData)
    self:SetBtnCallBack()
    self:InitDrawBackGround(self.BackGroundPath)
    local bannerBg = groupData:GetBanner()
    --self.RImgBg.gameObject:SetActiveEx(not string.IsNilOrEmpty(bannerBg))
    if bannerBg and self.PanelDrawBackGround then
        --self.RImgBg:SetRawImage(bannerBg)
        self.PanelDrawBackGround:LoadPrefab(bannerBg)
    end
end

function XUiLotto:OnDestroy()
    if self.CloseCb then
        self.CloseCb()
    end
end

function XUiLotto:OnEnable()
    self:StartTimer()
    XLuaUiManager.SetMask(true)
    self:PlayAnimation("DrawBegan", function()
        XLuaUiManager.SetMask(false)
        self:ShowExtraReward()
    end)
    self:UpdateAllPanel()
    --self.PlayableDirector = self.BackGround:GetComponent("PlayableDirector")
    --self.PlayableDirector:Stop()
    --self.PlayableDirector:Evaluate()
end

function XUiLotto:OnDisable()
   self:StopTimer()
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
            if cb then cb() end
        end)
        self.ExtraRewardList = nil
    else
        if cb then cb() end
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
            self.IsCanDraw = true
            local isNotifyWeaponFashionTransform = XDataCenter.WeaponFashionManager.GetIsNotifyWeaponFashionTransform()
            if isNotifyWeaponFashionTransform then
                -- self:RefreshRewardList(rewardList)
                XDataCenter.WeaponFashionManager.ResetIsNotifyWeaponFashionTransform()
            end
            XLuaUiManager.Open("UiDrawNew", drawData, rewardList, CS.XGame.ClientConfig:GetString("LottoDrawGround"))
        end, function()
            self.IsCanDraw = true
        end)
    end
end

-- 刷新奖励信息（武器涂装被转化时）
function XUiLotto:RefreshRewardList(rewardList)
    if rewardList and #rewardList > 1 then
        return
    end
    local cacheReward = XDataCenter.LottoManager.GetWeaponFashionCacheReward()
    if XTool.IsTableEmpty(cacheReward) then
        return
    end
    XDataCenter.LottoManager.ClearWeaponFashionCacheReward()
    local convertFrom = rewardList[1].TemplateId
    local itemId = cacheReward.ItemId
    local count = cacheReward.ItemCount
    rewardList[1].ConvertFrom = convertFrom
    rewardList[1].Count = count
    rewardList[1].TemplateId = itemId
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
        end, CS.XGame.ClientConfig:GetString("LottoDrawGround"))
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
    end,XScheduleManager.SECOND,0)
end

function XUiLotto:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end
