local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiMainPanelBase = require("XUi/XUiMain/XUiMainPanelBase")

---@class XUiGridCalendar : XUiMainPanelBase
---@field _Control XNewActivityCalendarControl
local XUiGridCalendar = XClass(XUiMainPanelBase, "XUiGridCalendar")

function XUiGridCalendar:OnStart()
    self.Grid256.gameObject:SetActiveEx(false)
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClick)

    self.GridKindList = {}
    self.GridRewardList = {}
    self:InitTheme()
    
    -- 根据MainId获取提示信息的下标
    self.TipIndexByMainId = {
        [1003] = 1,
        [1001] = 2,
    }

    self.ImgTimeCanvas = self.ImgTime.gameObject:GetComponent("CanvasGroup")
    self.GridCalendarEnable = XUiHelper.TryGetComponent(self.Transform, "Animation/GridCalendarEnable")
end

-- id 限时活动是 activityId | 周常活动是 mainId
function XUiGridCalendar:Refresh(id, type)
    self.Id = id
    self.Type = type

    local config = self:GetCalendarConfig(id)
    -- 活动名
    self.TxtWord.text = config.Name
    -- 活动图标
    self.BtnClick:SetRawImage(config.ActivityIcon)
    -- 活动类型
    self:RefreshKind(config.Kind)
    -- 剩余时间
    self:RefreshTimer()
    -- 奖励
    local isShowReward = true
    if self.Type == XEnumConst.NewActivityCalendar.ActivityType.Week then
        -- 周常特殊处理
        local isShowTips = self._Control:CheckWeekIsShowTips(self.Id)
        self.PanelZi.gameObject:SetActiveEx(isShowTips)
        if isShowTips then
            self.Text.text = self._Control:GetClientConfig("CalendarNotRewardTips", self.TipIndexByMainId[self.Id])
        end
        isShowReward = not isShowTips
    end
    self.PanelGift.gameObject:SetActiveEx(isShowReward)
    if isShowReward then
        self:RefreshReward()
    end
end

function XUiGridCalendar:GetCalendarConfig(id)
    if self.Type == XEnumConst.NewActivityCalendar.ActivityType.TimeLimit then
        return self._Control:GetCalendarActivityConfig(id)
    end
    if self.Type == XEnumConst.NewActivityCalendar.ActivityType.Week then
        return self._Control:GetCalendarWeekActivityConfig(id)
    end
end

function XUiGridCalendar:RefreshKind(kindIds)
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
        local kindCfg = self._Control:GetKindConfig(kindIds[i])
        grid.ImgBg.color = XUiHelper.Hexcolor2Color(kindCfg.BgColor)
        grid.TxtName.text = kindCfg.Name
        grid.GameObject:SetActiveEx(true)
    end
    for i = count + 1, #self.GridKindList do
        self.GridKindList[i].GameObject:SetActiveEx(false)
    end
end

function XUiGridCalendar:RefreshTimer()
    local timeDesc
    if self.Type == XEnumConst.NewActivityCalendar.ActivityType.TimeLimit then
        timeDesc = self._Control:GetCalenderRemainingTime(self.Id)
    end
    if self.Type == XEnumConst.NewActivityCalendar.ActivityType.Week then
        timeDesc = self._Control:GetWeekRemainingTimeDesc(self.Id)
    end
    self.TxtTime.text = timeDesc
end

function XUiGridCalendar:GetCalenderRewardItemData()
    if self.Type == XEnumConst.NewActivityCalendar.ActivityType.TimeLimit then
        return self._Control:GetTimeLimitRewardItemData(self.Id)
    end
    if self.Type == XEnumConst.NewActivityCalendar.ActivityType.Week then
        return self._Control:GetWeekRewardItemData(self.Id)
    end
end

-- 检查是否显示领取的数量
function XUiGridCalendar:CheckIsShowReceiveCount()
    if self.Type == XEnumConst.NewActivityCalendar.ActivityType.Week then
        return self._Control:CheckWeekIsShowReceiveCount(self.Id)
    end
    return true
end

function XUiGridCalendar:RefreshReward()
    local isShowReceiveCount = self:CheckIsShowReceiveCount()
    self.GridRewardList = self.GridRewardList or {}
    local rewards = self:GetCalenderRewardItemData()
    local rewardsNum = #rewards
    for i = 1, rewardsNum do
        local grid = self.GridRewardList[i]
        if not grid then
            local go = i == 1 and self.Grid256 or XUiHelper.Instantiate(self.Grid256, self.PanelGift)
            grid = XUiGridCommon.New(self.Parent.Parent, go)
            self.GridRewardList[i] = grid
        end
        grid:Refresh(rewards[i].TemplateId)
        local count = rewards[i].Count
        local receiveCount = rewards[i].ReceiveCount
        if XTool.IsNumberValid(count) then
            if isShowReceiveCount then
                grid:SetReceived(receiveCount >= count)
                receiveCount = receiveCount >= count and count or receiveCount
                local desc = self._Control:GetClientConfig("CalendarRewardCountDesc", 1)
                grid:SetCount(XUiHelper.FormatText(desc, receiveCount, count))
            else
                grid:SetReceived(false)
                grid:SetCount(count)
            end
        end
        grid.GameObject:SetActiveEx(true)
    end
    for i = rewardsNum + 1, #self.GridRewardList do
        self.GridRewardList[i].GameObject:SetActiveEx(false)
    end
end

function XUiGridCalendar:OnBtnClick()
    local skipId = 0
    if self.Type == XEnumConst.NewActivityCalendar.ActivityType.TimeLimit then
        skipId = self._Control:GetCalendarSkipId(self.Id)
    end
    if self.Type == XEnumConst.NewActivityCalendar.ActivityType.Week then
        skipId = self._Control:GetCalendarWeekSkipId(self.Id)
    end
    if XTool.IsNumberValid(skipId) then
        local dict = {}
        dict["ui_first_button"] = XGlobalVar.BtnBuriedSpotTypeLevelOne.BtnUiMainBtnCalendar
        dict["role_level"] = XPlayer.GetLevel()
        dict["ui_second_button"] = self.Id
        CS.XRecord.Record(dict, "200004", "UiOpen")
        XFunctionManager.SkipInterface(skipId)
    end
end

-- 设置透明度 播放动画时使用
function XUiGridCalendar:SetCanvasAlpha(value)
    if self.ImgTimeCanvas then
        self.ImgTimeCanvas.alpha = value
    end
    if self.Mask then
        self.Mask.alpha = value
    end
end

-- 播放动画
function XUiGridCalendar:PlayEnableAnim()
    if self.GridCalendarEnable then
        self.GridCalendarEnable:PlayTimelineAnimation(function()
            self:SetCanvasAlpha(1)
        end)
    else
        self:SetCanvasAlpha(1)
    end
end

return XUiGridCalendar
