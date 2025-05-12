local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local TextManager = CS.XTextManager

local XUiSignWeekCardGridDay = require("XUi/XUiSignIn/XUiSignWeekCardGridDay")
local XUiSignWeekRound = XClass(XUiNode, "XUiSignWeekRound")

local NUMBER_TABLE = {
    [1] = "One", [2] = "Two", [3] = "Three", [4] = "Four"
}

function XUiSignWeekRound:Ctor(ui, rootUi, parent, setTomorrow)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.Parent = parent
    self.SetTomorrow = setTomorrow

    self.OnBtnHelpClickCb = function()
        self:OnBtnHelpClick()
    end
    XTool.InitUiObject(self)
    self:InitAddListen()

    self.DaySmallGrids = {}
    self.GridDaySmall.gameObject:SetActiveEx(false)
    --table.insert(self.DaySmallGrids, XUiSignWeekCardGridDay.New(self.GridDaySmall, self.RootUi))
    self.DayBigGrids = {}
    self.GridDayBig.gameObject:SetActiveEx(false)
    --table.insert(self.DayBigGrids, XUiSignWeekCardGridDay.New(self.GridDayBig, self.RootUi))
    self.BtnList = {}
    local panelCabContentTransform = self.PanelTabContent.transform
    for i = 0, panelCabContentTransform.childCount - 1 do
        table.insert(self.BtnList, panelCabContentTransform:GetChild(i).gameObject)
    end
end

function XUiSignWeekRound:InitAddListen()
    self.RootUi:RegisterClickEvent(self.BtnHelp, self.OnBtnHelpClickCb)
end

function XUiSignWeekRound:OnBtnHelpClick()
    local sigInCfg = XSignInConfigs.GetSignInConfig(self.SignId)
    local subRoundCfg = XSignInConfigs.GetSubRoundConfig(sigInCfg.SubRoundId[1])
    XUiManager.UiFubenDialogTip("", subRoundCfg.SubRoundDesc or "")
end

function XUiSignWeekRound:OnEnable()
    for _, rewardGrid in ipairs(self.DaySmallGrids) do
        rewardGrid:Open()
    end
    for _, rewardGrid in ipairs(self.DayBigGrids) do
        rewardGrid:Open()
    end
end

function XUiSignWeekRound:OnGetLuaEvents()
    return {
        XEventId.EVENT_SING_IN_WEEK_CARD_GOT
    }
end

function XUiSignWeekRound:OnNotify(evt, ...)
    if evt == XEventId.EVENT_SING_IN_WEEK_CARD_GOT then
        self:RefreshPanelComplete(true)
    end
end

--- 福利界面打开时'isShow'为false，打脸打开时为true
function XUiSignWeekRound:Refresh(signId, round, isShow, purchaseData)
    self.IsShow = isShow
    self.SignId = signId
    self.Round = round
    self.IsPurchaseEnter = purchaseData ~= nil
    self.PurchaseData = purchaseData

    local timeId = XSignInConfigs.GetSignTimeId(signId)
    local beginTimeStamp, endTimeStamp = XFunctionManager.GetTimeByTimeId(timeId)
    self:SetSignTime(self.BeginTime, beginTimeStamp, "MM/dd")
    self:SetSignTime(self.EndTime1, endTimeStamp, "MM/dd")
    self:SetSignTime(self.EndTime2, endTimeStamp, "HH:mm")

    if self.IsPurchaseEnter then
        self.BetterIndexDic = {}
        if purchaseData and purchaseData.PurchaseSignInInfo then
            local batterIndexStr = purchaseData.PurchaseSignInInfo.BetterIndexStr
            if not string.IsNilOrEmpty(batterIndexStr) then
                local betterIndexList = string.Split(batterIndexStr, "|")
                for _, index in ipairs(betterIndexList) do
                    self.BetterIndexDic[tonumber(index)] = tonumber(index)
                end
            end
        end
        self:RefreshByPurchasePackageData()
    else
        self:RefreshBySignIn()
    end

    self:ChangeRoundState()
end

---
--- 设置签到时间
---@param textComponent userdata 字符串控件
---@param timeStamp number 时间戳
---@param format string 显示的格式
function XUiSignWeekRound:SetSignTime(textComponent, timeStamp, format)
    if not textComponent then
        return
    end

    local timeStr = XTime.TimestampToGameDateTimeString(timeStamp, format)
    if timeStr then
        textComponent.text = timeStr
    else
        XLog.Error("XUiSignWeekRound:SetSignTime函数错误，formatTimeStr为空")
    end
end

function XUiSignWeekRound:RefreshBySignIn()
    self.WeekCardData = XDataCenter.PurchaseManager.GetWeekCardDataBySignInId(self.SignId)
    if not self.WeekCardData then
        return
    end
    self.RoundCount = self.WeekCardData:GetRoundCount()
    if self.RoundCount <= 1 then
        self.TxtTipsBg.gameObject:SetActiveEx(true)
        self.TxtTips.text = self.WeekCardData:GetDesc()
    else
        self.TxtTipsBg.gameObject:SetActiveEx(false)
    end
    self:InitTabGroup()
    self:SetRewardInfos(self.Round)
    self:RefreshPanelComplete()
end

function XUiSignWeekRound:RefreshPanelComplete(isGotReward)
    if self.WeekCardData then
        local isGotToday = self.WeekCardData:GetIsGotToday()
        if isGotToday then
            self.PanelComplete.gameObject:SetActiveEx(true)
            if isGotReward then
                self.PanelCompleteEnable:PlayTimelineAnimation()
            end
        else
            self.PanelComplete.gameObject:SetActiveEx(false)
        end
    else
        self.PanelComplete.gameObject:SetActiveEx(false)
    end
end

function XUiSignWeekRound:RefreshByPurchasePackageData()
    local icon = XDataCenter.ItemManager.GetItemIcon(self.PurchaseData.ConsumeId)
    if icon then
        self.RawImageConsume:SetRawImage(icon)
    end
    self.BtnBuy:SetName(self.PurchaseData.ConsumeCount)
    XUiHelper.RegisterClickEvent(self.RootUi, self.BtnBuy, self.RootUi.OnBtnBuyClick)
    if self.PurchaseData.BuyTimes < self.PurchaseData.BuyLimitTimes then
        self.BtnBuy:SetDisable(false)
    else
        self.BtnBuy:SetDisable(true)
    end

    self:RefreshImmediatelyReward()
    self.RootUi:InitAndRegisterTimer(self.TxtTime) -- 调用礼包购买提示的接口注册到期显示
    self.TxtTips.text = self.PurchaseData.Desc
    self:SetRewardInfos(1)
end

function XUiSignWeekRound:RefreshImmediatelyReward()
    if not self.Grid then
        self.Grid = XUiGridCommon.New(self.RootUi, self.ImmediatelyRewardGridCommon)
    end
    if XTool.IsTableEmpty(self.PurchaseData.RewardGoodsList) then
        self.ImmediatelyReward.gameObject:SetActiveEx(false)
        return
    end

    self.ImmediatelyReward.gameObject:SetActiveEx(true)
    self.Grid:Refresh(self.PurchaseData.RewardGoodsList[1])
end

function XUiSignWeekRound:InitTabGroup()
    for _, v in ipairs(self.BtnList) do
        v.gameObject:SetActiveEx(false)
    end

    if self.RoundCount <= 1 then
        return
    end

    local btnGroupList = {}
    for i = 1, self.RoundCount do
        local grid = self.BtnList[i]
        if not grid then
            grid = CS.UnityEngine.Object.Instantiate(self.BtnTab.gameObject)
            grid.transform:SetParent(self.PanelTabContent.gameObject.transform, false)
            table.insert(self.BtnList, grid)
        end
        local xBtn = grid.transform:GetComponent("XUiButton")
        local rowImg = XUiHelper.TryGetComponent(grid.transform, "RImgIcon", "RawImage")

        table.insert(btnGroupList, xBtn)
        xBtn:SetName(TextManager.GetText("WeekCardRoundName", TextManager.GetText(NUMBER_TABLE[i])))
        --rowImg:SetRawImage(self.SignInInfos[i].Icon)
        xBtn.gameObject:SetActiveEx(true)
    end

    self.PanelTabContent:Init(btnGroupList, function(index)
        self:SelectPanelRound(index)
    end)

    local curRound = self.WeekCardData:GetCurRound()
    if curRound then
        self.PanelTabContent:SelectIndex(curRound, false)
    end
end

function XUiSignWeekRound:SelectPanelRound(index)
    self.Parent:RefreshPanel(index)
end

function XUiSignWeekRound:SetRewardInfos(roundIndex)
    local rewardInfos = self.IsPurchaseEnter and self.PurchaseData.PurchaseSignInInfo.PurchaseSignInRewardInfos or self.WeekCardData:GetRewardInfos()
    local checkIsBetterFunc = self.IsPurchaseEnter and function(index)
        return self.BetterIndexDic[index] ~= nil
    end or function(index)
        return self.WeekCardData:CheckIsBetterRewardByIndex(index)
    end
    
    for _, v in ipairs(self.DaySmallGrids) do
        v:Close()
    end
    for _, v in ipairs(self.DayBigGrids) do
        v:Close()
    end

    local smallIndex = 1
    local bigIndex = 1

    for index, rewardInfo in ipairs(rewardInfos) do
        if checkIsBetterFunc(index) then
            -- 设置大奖励
            local dayGrid = self.DayBigGrids[bigIndex]
            if not dayGrid then
                local grid = CS.UnityEngine.GameObject.Instantiate(self.GridDayBig)
                grid.transform:SetParent(self.PanelDayContent, false)
                dayGrid = XUiSignWeekCardGridDay.New(grid, self.RootUi)
                table.insert(self.DayBigGrids, dayGrid)
            end

            if self.IsPurchaseEnter then
                dayGrid:RefreshByRewardInfo(rewardInfo, index)
            else
                dayGrid:Refresh(self.WeekCardData, roundIndex, index, self.IsShow, self.SetTomorrow)
            end
            dayGrid.Transform:SetAsLastSibling()
            bigIndex = bigIndex + 1
        else
            -- 设置小奖励
            local dayGrid = self.DaySmallGrids[smallIndex]
            if not dayGrid then
                local grid = CS.UnityEngine.GameObject.Instantiate(self.GridDaySmall)
                grid.transform:SetParent(self.PanelDayContent, false)
                dayGrid = XUiSignWeekCardGridDay.New(grid, self.RootUi)
                table.insert(self.DaySmallGrids, dayGrid)
            end

            if self.IsPurchaseEnter then
                dayGrid:RefreshByRewardInfo(rewardInfo, index)
            else
                dayGrid:Refresh(self.WeekCardData, roundIndex, index, self.IsShow, self.SetTomorrow)
            end
            dayGrid.Transform:SetAsLastSibling()
            smallIndex = smallIndex + 1
        end
    end
end

function XUiSignWeekRound:SetBtnReceiveDisable()
    if self.BtnReceive then
        self.BtnReceive:SetButtonState(XUiButtonState.Disable)
    end
end

function XUiSignWeekRound:SetSignActive(active, round)
    if active and self:IsNodeShow() then
        return
    end

    if not active and not self:IsNodeShow() then
        return
    end

    if not self.IsPurchaseEnter then
        if self.RoundCount > 1 then
            self.PanelTabContent:SelectIndex(round, false)
        end
    end

    if active then
        self:Open()
        self:RefreshPanelComplete()
    else
        self:Close()
    end
end

function XUiSignWeekRound:ChangeRoundState()
    self.PanelBuy.gameObject:SetActiveEx(false)
    self.PanelSign.gameObject:SetActiveEx(false)
    if self.IsPurchaseEnter then
        self.PanelBuy.gameObject:SetActiveEx(true)
    else
        self.PanelSign.gameObject:SetActiveEx(true)
    end
end

return XUiSignWeekRound