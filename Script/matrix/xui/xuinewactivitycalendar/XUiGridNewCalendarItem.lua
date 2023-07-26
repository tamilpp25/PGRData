local XUiMainPanelBase = require("XUi/XUiMain/XUiMainPanelBase")
---@class XUiGridNewCalendarItem : XUiMainPanelBase
---@field BtnClick XUiComponent.XUiButton
---@field GridTaskEnable UnityEngine.RectTransform
local XUiGridNewCalendarItem = XClass(XUiMainPanelBase, "XUiGridNewCalendarItem")

function XUiGridNewCalendarItem:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClick)
    self.ImgTime.gameObject:SetActiveEx(false)
    self.ImgTimeNoOpen.gameObject:SetActiveEx(false)
    self.Grid256.gameObject:SetActiveEx(false)
    self.GridKindList = {}
    self.GridRewardList = {}
    self.IsHasPlayAnim = false

    self:InitTheme()
end

---@param activityInfo XNewActivityCalendarActivityEntity
function XUiGridNewCalendarItem:Refresh(activityInfo, index, currUseMinIndex)
    if not activityInfo then
        return
    end
    -- 播放动画
    currUseMinIndex = currUseMinIndex or 1
    self:PlayEnableAnime(index - (currUseMinIndex - 1))

    self.ActivityEntity = activityInfo
    -- 活动名
    self.TxtName.text = self.ActivityEntity:GetName()
    -- 活动图标
    self.BtnClick:SetRawImage(self.ActivityEntity:GetActivityIcon())
    -- 活动类型
    self:RefreshKind(self.ActivityEntity:GetKind())
    -- 未开启
    local isNotOpen = self.ActivityEntity:CheckActivityNotOpen()
    self.ImgTimeNoOpen.gameObject:SetActiveEx(isNotOpen)
    if isNotOpen then
        self.TxtTimeNoOpen.text = XUiHelper.GetText("UiNewActivityCalendarOpenTime", XTime.TimestampToGameDateTimeString(self.ActivityEntity:GetStartTime(), "MM-dd HH:mm"))
    end
    -- 剩余时间
    local isInTime = self.ActivityEntity:CheckInActivity()
    self.ImgTime.gameObject:SetActiveEx(isInTime)
    if isInTime then
        self.TxtTime.text = XUiHelper.GetTime(self.ActivityEntity:GetRemainingTime(), XUiHelper.TimeFormatType.ACTIVITY)
    end
    -- 奖励
    self:RefreshReward()
end

function XUiGridNewCalendarItem:RefreshKind(kindIds)
    if XTool.IsTableEmpty(kindIds) then
        self.GridKind.gameObject:SetActiveEx(false)
        return
    end
    local count = #kindIds
    for i = 1, count do
        local grid = self.GridKindList[i]
        if not grid then
            local go = i == 1 and self.GridKind or XUiHelper.Instantiate(self.GridKind, self.PanelKind)
            grid = XTool.InitUiObjectByUi({}, go)
            self.GridKindList[i] = grid
        end
        local kindCfg = XNewActivityCalendarConfigs.GetKindConfig(kindIds[i])
        grid.ImgBg.color = XUiHelper.Hexcolor2Color(kindCfg.BgColor)
        grid.TxtName.text = kindCfg.Name
        grid.GameObject:SetActiveEx(true)
    end
    for i = count + 1, #self.GridKindList do
        self.GridKindList[i].GameObject:SetActiveEx(false)
    end
end

function XUiGridNewCalendarItem:RefreshReward()
    self.GridRewardList = self.GridRewardList or {}
    local rewards = XDataCenter.NewActivityCalendarManager.GetRewardItemData(self.ActivityEntity:GetActivityId())
    local rewardsNum = #rewards
    for i = 1, rewardsNum do
        local grid = self.GridRewardList[i]
        if not grid then
            local go = i == 1 and self.Grid256 or XUiHelper.Instantiate(self.Grid256, self.PanelGift)
            grid = XUiGridCommon.New(self.RootUi, go)
            self.GridRewardList[i] = grid
        end
        grid:Refresh(rewards[i].TemplateId)
        local count = rewards[i].Count
        local receiveCount = rewards[i].ReceiveCount
        if XTool.IsNumberValid(count) then
            local inActivity = self.ActivityEntity:CheckInActivity()
            grid:SetReceived(inActivity and receiveCount >= count)
            receiveCount = receiveCount >= count and count or receiveCount
            local desc = inActivity and XUiHelper.GetText("UiNewActivityCalendarRewardCountDesc", receiveCount, count) or count
            grid:SetCount(desc)
        end
        grid.GameObject:SetActiveEx(true)
    end
    for i = rewardsNum + 1, #self.GridRewardList do
        self.GridRewardList[i].GameObject:SetActiveEx(false)
    end
end

function XUiGridNewCalendarItem:RefreshTimer()
    local isInTime = self.ActivityEntity:CheckInActivity()
    if isInTime then
        self.TxtTime.text = XUiHelper.GetTime(self.ActivityEntity:GetRemainingTime(), XUiHelper.TimeFormatType.ACTIVITY)
    end
end

function XUiGridNewCalendarItem:PlayEnableAnime(index)
    if self.IsHasPlayAnim then
        return
    end
    if XDataCenter.GuideManager.CheckIsInGuide() then
        return
    end
    self:SetCanvasAlpha(0)
    XScheduleManager.ScheduleOnce(function()
        if not XTool.UObjIsNil(self.GameObject) and self.GameObject.activeInHierarchy then
            self.GridTaskEnable:PlayTimelineAnimation(function()
                self:SetCanvasAlpha(1)
            end)
            self.IsHasPlayAnim = true
        end
    end, (index - 1) * 95)
end

function XUiGridNewCalendarItem:SetCanvasAlpha(value)
    for i = 1, 3 do
        local canvas = self["Canvas" .. i]
        if canvas then
            canvas.alpha = value
        end
    end
end

function XUiGridNewCalendarItem:SetHasPlay(value)
    self.IsHasPlayAnim = value
end

function XUiGridNewCalendarItem:OnBtnClick()
    if self.ActivityEntity:CheckActivityNotOpen() then
        XUiManager.TipText("CommonActivityNotStart")
        return
    end
    if self.ActivityEntity:CheckActivityEnd() then
        XUiManager.TipText("CommonActivityEnd")
        return
    end
    XLuaUiManager.Open("UiNewCalendarTip", self.ActivityEntity:GetActivityId())
end

return XUiGridNewCalendarItem