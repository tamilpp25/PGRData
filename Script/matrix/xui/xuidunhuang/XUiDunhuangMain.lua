local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiDunhuangUtil = require("XUi/XUiDunhuang/XUiDunhuangUtil")
local XUiDunhuangRewardGrid = require("XUi/XUiDunhuang/XUiDunhuangRewardGrid")

---@class XUiDunhuangMain : XLuaUi
---@field _Control XDunhuangControl
local XUiDunhuangMain = XLuaUiManager.Register(XLuaUi, "UiDunhuangMain")

function XUiDunhuangMain:Ctor()
    self._Timer = false

    self.UiPaintings = {}
    self._UiReward = {}

end

function XUiDunhuangMain:OnAwake()
    self:BindExitBtns()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.MuralShareCoin)
    self:BindHelpBtn(self.BtnHelp, "DunhuangHelp")

    XUiHelper.RegisterClickEvent(self, self.BtnTask, self.OnClickTask)
    XUiHelper.RegisterClickEvent(self, self.BtnEdit, self.OnClickPainting)
    XUiHelper.RegisterClickEvent(self, self.BtnHandbook, self.OnClickCollect)
    self.ImgMaterial.gameObject:SetActiveEx(false)
    self.GridReward.gameObject:SetActiveEx(false)
    self.RedAfford = self.RedAfford or XUiHelper.TryGetComponent(self.BtnHandbook.transform, "Red", "Transform")
end

function XUiDunhuangMain:OnStart()
    self:UpdateFirstReward()
    self:PlayAnimationSpine()

    if self._Control:GetIsFirstTimeEnter() then
        self._Control:SetIsFirstTimeEnter()
        XUiManager.ShowHelpTip("DunhuangHelp")
    end

    self:StartTimer()
end

function XUiDunhuangMain:OnDestroy()
    self:StopTimer()
end

function XUiDunhuangMain:OnEnable()
    if not self:UpdateTime(true) then
        -- 超时
        return
    end
    self:Update()
    self:UpdateBtnShareRed()
    self:UpdateRedDot()
    XEventManager.AddEventListener(XEventId.EVENT_DUNHUANG_UPDATE_REWARD, self.UpdateReward, self)
end

function XUiDunhuangMain:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_DUNHUANG_UPDATE_REWARD, self.UpdateReward, self)
end

function XUiDunhuangMain:StartTimer()
    if not self._Timer then
        self._Timer = XScheduleManager.ScheduleForever(function()
            self:UpdateTime()
        end, XScheduleManager.SECOND)
    end
end

function XUiDunhuangMain:StopTimer()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
end

function XUiDunhuangMain:UpdateTime(notKickOut)
    local isOpen = self._Control:UpdateTime(notKickOut)
    if isOpen then
        local uiData = self._Control:GetUiData()
        self.TxtTime.text = uiData.Time
    end
    return isOpen
end

function XUiDunhuangMain:Update()
    self._Control:UpdatePaintingUnlockProgress()
    local data = self._Control:GetUiData()

    self.BtnHandbook:SetNameByGroup(0, data.PaintingProgress1)
    self.TxtNum.text = data.PaintingProgress2
    self.ImgBar.FillRangeMax = 1
    self.ImgBar.fillAmount = data.PaintingNumberProgress

    self:UpdateDraw()
    self:UpdateReward()
end

function XUiDunhuangMain:OnClickTask()
    XLuaUiManager.Open("UiDunhuangTask")
end

function XUiDunhuangMain:OnClickPainting()
    XLuaUiManager.Open("UiDunhuangEdit")
end

function XUiDunhuangMain:OnClickCollect()
    XLuaUiManager.Open("UiDunhuangHandbook")
end

function XUiDunhuangMain:UpdateDraw()
    self._Control:UpdateDraw()
    XUiDunhuangUtil.UpdateDraw(self, self._Control)
end

function XUiDunhuangMain:UpdateReward()
    self._Control:UpdateReward()
    local uiData = self._Control:GetUiData()
    local rewardList = uiData.RewardList
    for i = 1, #rewardList do
        local reward = rewardList[i]
        ---@type XUiDunhuangRewardGrid
        local ui = self:GetUiRewardByIndex(i)
        ui:Update(reward)
    end
    for i = #rewardList + 1, #self._UiReward do
        local ui = self._UiReward[i]
        ui.gameObject:SetActiveEx(false)
    end
end

function XUiDunhuangMain:GetUiRewardByIndex(index)
    local uiPainting = self._UiReward[index]
    if not uiPainting then
        local ui = XUiHelper.Instantiate(self.GridReward, self["Reward" .. index])
        ui.gameObject:SetActiveEx(true)
        uiPainting = XUiDunhuangRewardGrid.New(ui, self)
        self._UiReward[#self._UiReward + 1] = uiPainting

        ---@type XUiComponent.XUiButton
        --local button = XUiHelper.TryGetComponent(uiPainting.transform, "", "XUiButton")
        --if button then
        --    XUiHelper.RegisterClickEvent(self, button, function()
        --        local uiData = control:GetUiData()
        --        local paintingToDraw = uiData.PaintingToDraw
        --        local data = paintingToDraw[index]
        --        control:SetSelectedPaintingOnGame(data)
        --    end)
        --end
    end
    return uiPainting
end

function XUiDunhuangMain:UpdateBtnShareRed()
    self.BtnEdit:ShowReddot(self._Control:IsFirstShare())
end

function XUiDunhuangMain:PlayAnimationSpine()
    ---@type Spine.Unity.SkeletonAnimation
    local spineComponent = XUiHelper.TryGetComponent(self.Transform, "FullScreenBackground/PanelSpine/UiDunhuangMainBg(Clone)/Bg", "SkeletonAnimation")
    if spineComponent then
        spineComponent.AnimationState:SetAnimation(0, "Enable", false)
    end
end

function XUiDunhuangMain:UpdateFirstReward()
    if not self.TxtNumFirstShare then
        return
    end
    local reward = self._Control:GetFirstShareReward()
    self.TxtNumFirstShare.text = reward.Count
    local icon = XDataCenter.ItemManager.GetItemIcon(reward.TemplateId)
    self.IconFirstShare:SetRawImage(icon)
end

function XUiDunhuangMain:UpdateRedDot()
    local isTaskCanAchieved = self._Control:IsTaskCanAchieved()
    self.BtnTask:ShowReddot(isTaskCanAchieved)

    local isAfford = self._Control:IsPaintingAfford()
    self.RedAfford.gameObject:SetActiveEx(isAfford)
end

return XUiDunhuangMain