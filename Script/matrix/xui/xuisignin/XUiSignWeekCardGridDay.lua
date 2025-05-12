local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiSignWeekCardGridDay = XClass(XUiNode, "XUiSignWeekCardGridDay")

function XUiSignWeekCardGridDay:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.Grid = nil

    XTool.InitUiObject(self)
    self:InitComponent()
    self:InitAddListen()
end

function XUiSignWeekCardGridDay:InitComponent()
    self.PanelNext.gameObject:SetActiveEx(false)
end

function XUiSignWeekCardGridDay:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiSignWeekCardGridDay:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiSignWeekCardGridDay:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiSignWeekCardGridDay:InitAddListen()
    if not self.BtnCard then
        return
    end
    self:RegisterClickEvent(self.BtnCard, self.OnBtnCardClick)
end

function XUiSignWeekCardGridDay:OnBtnCardClick()
    XDataCenter.AutoWindowManager.StopAutoWindow()
    XDataCenter.PurchaseManager.OpenYKPackageBuyUi()
end

function XUiSignWeekCardGridDay:OnEnable()
    self:AnimaStart()
end

function XUiSignWeekCardGridDay:OnDisable()

end

function XUiSignWeekCardGridDay:RefreshByRewardInfo(rewardInfo, index)
    self.PanelHaveGroup.alpha = 0
    self.PanelHaveReceive.gameObject:SetActiveEx(false)
    self:SetEffectActive(false)

    local rewardList = XRewardManager.GetRewardList(rewardInfo)
    self.TxtDay.text = string.format("%02d", index)
    if not self.Grid then
        self.Grid = XUiGridCommon.New(self.RootUi, self.GridCommon)
    end

    --self:SetCardInfo(false)
    self.Grid:Refresh(rewardList[1])
end

function XUiSignWeekCardGridDay:Refresh(weekCardData, roundIndex, index, isShow, forceSetTomorrow)
    self.IsShow = isShow
    self.WeekCardData = weekCardData
    self.RoundIndex = roundIndex
    self.Index = index
    self.RewardId = weekCardData.RewardInfos[index]
    self.IsToday = self.RoundIndex == self.WeekCardData:GetCurRound() and self.Index == self.WeekCardData:GetCurRoundDay()

    self.ForceSetTomorrow = forceSetTomorrow
    self.PanelNext.gameObject:SetActiveEx(false)
    self.TxtDay.text = string.format("%02d", index)
    self:SetTomorrow()

    local isAlreadyGet = self.WeekCardData:CheckIsGotByRoundAndDay(roundIndex, index)
    local isPreviousDay = self.WeekCardData:CheckIsPreviousDay(roundIndex, index)
    self.PanelHaveGroup.alpha = isPreviousDay and 1 or 0
    self.PanelHaveReceive.gameObject:SetActiveEx(isPreviousDay)
    self.PanelCheck.gameObject:SetActiveEx(isAlreadyGet)
    self:SetEffectActive(false)

    local rewardList = XRewardManager.GetRewardList(self.RewardId)
    if not rewardList or #rewardList <= 0 then
        XEventManager.DispatchEvent(XEventId.EVENT_SING_IN_OPEN_BTN, true)
        return
    end

    if not self.Grid then
        self.Grid = XUiGridCommon.New(self.RootUi, self.GridCommon)
    end

    self.Grid:Refresh(rewardList[1])
end

function XUiSignWeekCardGridDay:SetTomorrow()
    local isTomorrow = (self.WeekCardData:GetCurDay() + 1) == ((self.RoundIndex - 1) * self.WeekCardData:GetOneRoundDayCount() + self.Index)
    self.PanelNext.gameObject:SetActiveEx(isTomorrow)
end

function XUiSignWeekCardGridDay:AnimaStart()
    if not self.IsShow then
        return
    end

    local isGot = self.WeekCardData:CheckIsGotByRoundAndDay(self.RoundIndex, self.Index)
    if not self.IsToday then
        return
    end

    if self.IsToday and isGot then
        XEventManager.DispatchEvent(XEventId.EVENT_SING_IN_OPEN_BTN, true, self.Config)
        return
    end

    self:GetWeekCardReward()
end

function XUiSignWeekCardGridDay:SetEffectActive(active)
    self.PanelEffect.gameObject:SetActiveEx(active)
end

function XUiSignWeekCardGridDay:GetWeekCardReward()
    XDataCenter.PurchaseManager.PurchaseGetDailyRewardRequest(self.WeekCardData:GetId(), function(rewards)
        XEventManager.DispatchEvent(XEventId.EVENT_CARD_REFRESH_WELFARE_BTN)
        RunAsyn(function()
            asynWaitSecond(0.7)
            self:HandlerReward(rewards)
            self.WeekCardData:SetWeekCardGotToday()
        end)
    end)
end

function XUiSignWeekCardGridDay:HandlerReward(rewardItems)
    if rewardItems and #rewardItems > 0 then
        self:SetReward(rewardItems)
    else
        self:SetNoReward()
    end
end

function XUiSignWeekCardGridDay:SetReward(rewardItems)
    self.PanelHaveGroup.alpha = 1
    self.PanelHaveReceive.gameObject:SetActiveEx(true)
    self.PanelCheck.gameObject:SetActiveEx(true)
    self.GameObject:PlayTimelineAnimation(function()
        XUiManager.OpenUiObtain(rewardItems)
        self:SetEffectActive(false)
        XEventManager.DispatchEvent(XEventId.EVENT_SING_IN_OPEN_BTN, true, self.Config)
    end, function()
        self:SetEffectActive(true)
    end)
end

function XUiSignWeekCardGridDay:SetNoReward()
    self:SetEffectActive(false)
    XEventManager.DispatchEvent(XEventId.EVENT_SING_IN_OPEN_BTN, true)
end

return XUiSignWeekCardGridDay