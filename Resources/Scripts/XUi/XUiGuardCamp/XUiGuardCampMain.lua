local CSXTextManagerGetText = CS.XTextManager.GetText
local mathFloor = math.floor
local stringFormat = string.format
local TenThousand = 10000
local Billion = 100000000

local S = 60
local H = 3600
local D = 3600 * 24
local W = 3600 * 24 * 7
local M = 3600 * 24 * 30
local STR_HOUR = CS.XTextManager.GetText("Hour")
local STR_MINUTE = CS.XTextManager.GetText("Minute")

--炸服押注活动
local XUiGuardCampMain = XLuaUiManager.Register(XLuaUi, "UiGuardCampMain")

function XUiGuardCampMain:OnAwake()
    self:CheckAutoOpenHelp()
    XDataCenter.GuardCampManager.CheckUpdateRedPointTimeStamp()
    self:AutoAddListener()
end

function XUiGuardCampMain:OnStart()
    XDataCenter.PurchaseManager.GetPurchaseListRequest(XPurchaseConfigs.GetLBUiTypesList())
    self:InitData()
    self:InitJoinNum()
    self:InitPondAdd()
    self:InitCampName()
    self:InitIcon()
end

function XUiGuardCampMain:OnEnable()
    if self:CheckActivityIsClose() then
        return
    end
    self:RequestGetGuardCampGlobalDataSend()
    self:Refresh()
end

function XUiGuardCampMain:OnDisable()
    self:RemoveTimer()
end

function XUiGuardCampMain:OnDestroy()
    XDataCenter.PurchaseManager.ClearData()
end

function XUiGuardCampMain:CheckAutoOpenHelp()
    local isFirstOpenView = XDataCenter.GuardCampManager.IsFirstOpenView()
    if isFirstOpenView then
        XUiManager.ShowHelpTip("GuardCamp")
    end
end

function XUiGuardCampMain:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:BindHelpBtn(self.BtnHelp, "GuardCamp")
    self:RegisterClickEvent(self.BtnBuyJump2, self.OnBtnBuyJumpClick)
    self:RegisterClickEvent(self.KachiButton, self.OnKachiButtonClick)
    self:RegisterClickEvent(self.PanelBtnJiazhuTudou, self.OnPanelBtnJiazhuTudouClick)
    self:RegisterClickEvent(self.PanelBtnJiazhuSolon, self.OnPanelBtnJiazhuSolonClick)
    self:RegisterClickEvent(self.PanelBtnYingyuanTudou, self.OnPanelBtnYingyuanTudouClick)
    self:RegisterClickEvent(self.PanelBtnYingyuanSolon, self.OnPanelBtnYingyuanSolonClick)
    self:RegisterClickEvent(self.PanelBtnTingzhTudou, self.OnPanelBtnTingzhiClick)
    self:RegisterClickEvent(self.PanelBtnTingzhSolon, self.OnPanelBtnTingzhiClick)
    self:RegisterClickEvent(self.BtnClosePanelTips, self.OnKachiButtonClick)
    self.PanelBtnLingquDetail.CallBack = function() self:OnPanelBtnLingquDetailClick() end
end

function XUiGuardCampMain:InitData()
    self.ActivityId = XGuardCampConfig.GetActivityId()
    self.LeftCampId = XGuardCampConfig.GetCampId(1)
    self.RightCampId = XGuardCampConfig.GetCampId(2)
    self.SupportItemId = XGuardCampConfig.GetActivitySupportItemId(self.ActivityId)
    XDataCenter.ItemManager.AddCountUpdateListener(self.SupportItemId, function()
        self:RefreshSupportItemNum()
    end, self.TxtTool2)
    self.IsOverPlayWinAnima = false
end

function XUiGuardCampMain:InitJoinNum()
    local activityId = XGuardCampConfig.GetActivityId()
    local joinNumList = XGuardCampConfig.GetActivityJoinNumList(activityId)
    local num
    for i, joinNum in ipairs(joinNumList) do
        self["TxtRenshu" .. i].text = self:GetNumConver(joinNum)
    end
end

function XUiGuardCampMain:InitPondAdd()
    local activityId = XGuardCampConfig.GetActivityId()
    local pondAddList = XGuardCampConfig.GetActivityPondAddList(activityId)
    local num
    for i, pondAdd in ipairs(pondAddList) do
        self["PanelJiangliText" .. i].text = self:GetNumConver(pondAdd)
    end
end

function XUiGuardCampMain:GetNumConver(num)
    if num % Billion == 0 then
        return stringFormat("%d%s", num / Billion, CSXTextManagerGetText("AHundredMillion"))
    end
    if num % TenThousand == 0 then
        return stringFormat("%d%s", num / TenThousand, CSXTextManagerGetText("TenThousand"))
    end

    local numTemp = num / TenThousand
    return stringFormat("%.1f%s", numTemp, CSXTextManagerGetText("TenThousand"))
end

function XUiGuardCampMain:InitIcon()
    local supportItemId = XGuardCampConfig.GetActivitySupportItemId(self.ActivityId)
    local supportItemIcon = XDataCenter.ItemManager.GetItemIcon(supportItemId)
    self.RImgTool2:SetRawImage(supportItemIcon)
    self.TudouYingyuanRawImage:SetRawImage(supportItemIcon)
    self.SolonYingyuanRawImage:SetRawImage(supportItemIcon)
    
    local joinNumList = XGuardCampConfig.GetActivityJoinNumList(self.ActivityId)
    for i in ipairs(joinNumList) do
        self["PanelJiangliRawImage" .. i]:SetRawImage(supportItemIcon)
    end
    self.KachiRawImage:SetRawImage(supportItemIcon)
end

function XUiGuardCampMain:InitCampName()
    self.TudouTitleText.text = XGuardCampConfig.GetCampName(self.LeftCampId)
    self.SolonTitleText.text = XGuardCampConfig.GetCampName(self.RightCampId)
end

function XUiGuardCampMain:RequestGetGuardCampGlobalDataSend()
    XDataCenter.GuardCampManager.RequestGetGuardCampGlobalDataSend(self.ActivityId, function() self:Refresh() end)
end

function XUiGuardCampMain:Refresh()
    if self:CheckActivityIsClose() then
        return
    end
    local state, timeStr, title, endTimestamp = XDataCenter.GuardCampManager.GetActivityState(self.ActivityId)
    local selectCampId = XDataCenter.GuardCampManager.GetSelectCampIdByActivityId(self.ActivityId)
    local isSelectCamp = selectCampId ~= XGuardCampConfig.NotGuardId
    local isGetReward = XDataCenter.GuardCampManager.IsGetReward(self.ActivityId)
    if self.MyZhenyingTudou then
        self.MyZhenyingTudou.gameObject:SetActiveEx(selectCampId == self.LeftCampId)
    end
    if self.MyZhenyingSolon then
        self.MyZhenyingSolon.gameObject:SetActiveEx(selectCampId == self.RightCampId)
    end
    self.PanelBtnYingyuanDetail.gameObject:SetActiveEx(not isSelectCamp and (state == XGuardCampConfig.ActivityState.UnOpen or state == XGuardCampConfig.ActivityState.SupportOpen))
    self.PanelBtnJiazhuDetail.gameObject:SetActiveEx(isSelectCamp and state == XGuardCampConfig.ActivityState.SupportOpen)
    self.PanelBtnTingzhiDetail.gameObject:SetActiveEx(state == XGuardCampConfig.ActivityState.SupportClose)
    self.TxtWeikaishi.gameObject:SetActiveEx(state == XGuardCampConfig.ActivityState.UnOpen)
    self.PanelKachiDtail.gameObject:SetActiveEx(state ~= XGuardCampConfig.ActivityState.UnOpen)
    self.PaneJiesuoJindu.gameObject:SetActiveEx(state ~= XGuardCampConfig.ActivityState.DrawLottery)
    self.PanelYingyuanCountTudouDetail.gameObject:SetActiveEx(state ~= XGuardCampConfig.ActivityState.UnOpen)
    self.PaneTudouZhenying.gameObject:SetActiveEx(state ~= XGuardCampConfig.ActivityState.UnOpen)
    self.PanelYingyuanCountSolonDetail.gameObject:SetActiveEx(state ~= XGuardCampConfig.ActivityState.UnOpen)
    self.PaneSolonZhenying.gameObject:SetActiveEx(state ~= XGuardCampConfig.ActivityState.UnOpen)

    self.PanelBtnLingquDetail.gameObject:SetActiveEx(isSelectCamp and state == XGuardCampConfig.ActivityState.DrawLottery)
    self.PanelBtnLingquDetail:SetDisable(isGetReward, not isGetReward)

    self:RefreshSupportCount(selectCampId)
    self:RefreshJoinCount()
    self:RefreshJoinPercent()
    self:RefreshSupportItemNum()
    self:RefreshWinImg(state)

    self.KachiText.text = XDataCenter.GuardCampManager.GetPondCountByActivityId(self.ActivityId)
    self.PanelTipsText.text = XGuardCampConfig.GetCaption(state)

    self:RefreshTimer(timeStr, title, endTimestamp)
end

function XUiGuardCampMain:RefreshTimer(timeStr, title, endTimestamp)
    local serverTimestamp = XTime.GetServerNowTimestamp()
    self.EndTimestamp = endTimestamp
    self.Title = title
    self.TimeStr = timeStr
    if not self.Timer then
        self.Timer = XScheduleManager.ScheduleForever(function()
            serverTimestamp = XTime.GetServerNowTimestamp()
            if self.EndTimestamp <= serverTimestamp then
                self:Refresh()
            else
                self:RequestGetGuardCampGlobalDataSend()
                self:RefreshTimeStr(self.TimeStr, self.Title, self.EndTimestamp - serverTimestamp)
            end
        end, XScheduleManager.SECOND)
    end
    self:RefreshTimeStr(timeStr, title, endTimestamp - serverTimestamp)
end

function XUiGuardCampMain:RefreshTimeStr(timeStr, title, endLastTimestamp)
    local hours = mathFloor(endLastTimestamp / H)
    local minutes = mathFloor((endLastTimestamp % H) / S)
    minutes = minutes > 0 and minutes or 1  --小于1分钟显示1分钟
    self.TxtTitle.text = title
    self.TxtTime.text = timeStr ~= "" and timeStr or stringFormat("%d%s%d%s", hours, STR_HOUR, minutes, STR_MINUTE)
end

function XUiGuardCampMain:RemoveTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiGuardCampMain:RefreshSupportItemNum()
    self.TxtTool2.text = XDataCenter.ItemManager.GetCount(self.SupportItemId)
end

function XUiGuardCampMain:RefreshJoinPercent()
    local percent = XDataCenter.GuardCampManager.GetJoinPercent(self.ActivityId)
    self.ImgPercent.fillAmount = percent

    local joinNumList = XGuardCampConfig.GetActivityJoinNumList(self.ActivityId)
    local totalNum = XDataCenter.GuardCampManager.GetJoinTotalNum(self.ActivityId)
    for i, joinNum in ipairs(joinNumList) do
        self["ZhuangtaidianRawImage" .. i].gameObject:SetActiveEx(totalNum >= joinNum)
    end
end

function XUiGuardCampMain:RefreshSupportCount(selectCampId)
    local perSupportNum = XGuardCampConfig.GetActivityPerSupportNum(self.ActivityId)
    local supporNum = XDataCenter.GuardCampManager.GetSupportCount(self.ActivityId, self.LeftCampId)
    local selectCampNeedCount = XGuardCampConfig.GetActivitySelectCampNeedCount(self.ActivityId)
    local addSelectCampNeedCount = selectCampId == self.LeftCampId and selectCampNeedCount or 0
    self.TudouYingyuanCount.text = supporNum * perSupportNum + addSelectCampNeedCount
    addSelectCampNeedCount = selectCampId == self.RightCampId and selectCampNeedCount or 0
    supporNum = XDataCenter.GuardCampManager.GetSupportCount(self.ActivityId, self.RightCampId)
    self.SolonYingyuanCount.text = supporNum * perSupportNum + addSelectCampNeedCount
end

function XUiGuardCampMain:RefreshJoinCount()
    self.TudouZhenyingText.text = XDataCenter.GuardCampManager.GetJoinNum(self.ActivityId, self.LeftCampId)
    self.SolonZhenyingText.text = XDataCenter.GuardCampManager.GetJoinNum(self.ActivityId, self.RightCampId)
end

function XUiGuardCampMain:RefreshWinImg(state)
    local winCampId = XDataCenter.GuardCampManager.GetWinCampIdByActivityId(self.ActivityId)
    local tudouLose = state == XGuardCampConfig.ActivityState.DrawLottery and winCampId ~= 0 and self.LeftCampId ~= winCampId
    local solonLose = state == XGuardCampConfig.ActivityState.DrawLottery and winCampId ~= 0 and self.RightCampId ~= winCampId
    self.ImgTudouLose.gameObject:SetActiveEx(tudouLose)
    self.ImgSolonLose.gameObject:SetActiveEx(solonLose)
    self.ImgWin.gameObject:SetActiveEx(state == XGuardCampConfig.ActivityState.DrawLottery and winCampId ~= 0)
    
    if not self.IsOverPlayWinAnima then
        if tudouLose then
            self:PlayAnimation("SolonWin")
            self.IsOverPlayWinAnima = true
        elseif solonLose then
            self:PlayAnimation("TuDouWin")
            self.IsOverPlayWinAnima = true
        end
    end
end

function XUiGuardCampMain:CheckActivityIsClose()
    if XDataCenter.GuardCampManager.IsActivityClose() then
        XUiManager.TipText("ActivityAlreadyOver")
        self:Close()
        return true
    end
end

function XUiGuardCampMain:OnPanelBtnJiazhuTudouClick()
    self:OnJiaZhuClick(self.LeftCampId)
end

function XUiGuardCampMain:OnPanelBtnJiazhuSolonClick()
    self:OnJiaZhuClick(self.RightCampId)
end

function XUiGuardCampMain:OnJiaZhuClick(selectCampId)
    local maxSupportCount = XDataCenter.GuardCampManager.GetMaxSupportCount(self.ActivityId)
    if maxSupportCount == 0 then
        XUiManager.TipText("GuardCampSupportCampMax")
        return
    end

    local perSupportNum = XGuardCampConfig.GetActivityPerSupportNum(self.ActivityId)
    local itemCount = XDataCenter.ItemManager.GetCount(self.SupportItemId)
    if itemCount < perSupportNum then
        self:OnBtnBuyJumpClick()
        return
    end

    XLuaUiManager.Open("UiGuardCampTips", self.ActivityId, selectCampId)
end

function XUiGuardCampMain:OnPanelBtnYingyuanTudouClick()
    self:OnYingyuan(self.LeftCampId)
end

function XUiGuardCampMain:OnPanelBtnYingyuanSolonClick()
    self:OnYingyuan(self.RightCampId)
end

function XUiGuardCampMain:OnYingyuan(selectCampId)
    local state, timeStr = XDataCenter.GuardCampManager.GetActivityState(self.ActivityId)
    if state == XGuardCampConfig.ActivityState.UnOpen then
        local errorDesc = CS.XTextManager.GetText("GuardCampUnopenTipDesc", timeStr)
        XUiManager.TipError(errorDesc)
        return
    end

    local selectCampNeedCount = XGuardCampConfig.GetActivitySelectCampNeedCount(self.ActivityId)
    local itemCount = XDataCenter.ItemManager.GetCount(self.SupportItemId)
    if itemCount < selectCampNeedCount then
        self:OnBtnBuyJumpClick()
        return
    end

    local itemId = XGuardCampConfig.GetActivitySupportItemId(self.ActivityId)
    local itemName = XDataCenter.ItemManager.GetItemName(itemId)
    local campName = XGuardCampConfig.GetCampName(selectCampId)
    local content = CS.XTextManager.GetText("GuardCampSelectCampTipDesc", selectCampNeedCount, itemName, campName)
    XUiManager.DialogTip("", content, XUiManager.DialogType.Normal, nil, function()
        XDataCenter.GuardCampManager.RequestSelectGuardCampSend(self.ActivityId, selectCampId)
    end)
end

function XUiGuardCampMain:OnPanelBtnLingquDetailClick()
    local selectCampId = XDataCenter.GuardCampManager.GetSelectCampIdByActivityId(self.ActivityId)
    XDataCenter.GuardCampManager.RequestGetGuardCampRewardSend(self.ActivityId, function() self:Refresh() end)
end

function XUiGuardCampMain:OnBtnBuyJumpClick()
    local data = XDataCenter.GuardCampManager.GetActivityPurchasePackageData(self.ActivityId)
    if not data or data.IsSelloutHide then
        XUiManager.TipText("NotPurchaseData")
        return
    end
    XLuaUiManager.Open("UiChongzhiTanchuang", data)
end

--奖池说明弹窗
function XUiGuardCampMain:OnKachiButtonClick()
    local activeSelf = self.PanelTipsDetail.gameObject.activeSelf
    self.PanelTipsDetail.gameObject:SetActiveEx(not activeSelf)
end

function XUiGuardCampMain:OnPanelBtnTingzhiClick()
    XUiManager.TipText("GuardCampSupportCloseTipDesc")
end

function XUiGuardCampMain:OnBtnBackClick()
    self:Close()
end

function XUiGuardCampMain:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiGuardCampMain:OnGetEvents()
    return {XEventId.EVENT_GUARD_CAMP_ACTIVITY_DATA_CHANGE}
end

function XUiGuardCampMain:OnNotify(evt, ...)
    if evt == XEventId.EVENT_GUARD_CAMP_ACTIVITY_DATA_CHANGE then
        self:Refresh()
    end
end