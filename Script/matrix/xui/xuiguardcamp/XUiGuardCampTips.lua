local CSXTextManagerGetText = CS.XTextManager.GetText
local stringGsub = string.gsub
local MinSupportCount = 1
local CAN_SUPPORT_COLOR = {
    [true] = XUiHelper.Hexcolor2Color("0f70bcff"),
    [false] = CS.UnityEngine.Color.red,
}

local XUiGuardCampTips = XLuaUiManager.Register(XLuaUi, "UiGuardCampTips")

function XUiGuardCampTips:OnAwake()
    self.BtnClose.gameObject:SetActiveEx(false)
    local btnName = CSXTextManagerGetText("GuardCampSupportTipsBtnName")
    self.BtnTongBlack:SetName(btnName)
    self:AutoAddListener()
end

function XUiGuardCampTips:OnStart(activityId, campId, cb)
    self.ActivityId = activityId
    self.CampId = campId
    self.Cb = cb
    self:InitData()
    self:Refresh()
end

function XUiGuardCampTips:InitData()
    self.PerSupportNumCfg = XGuardCampConfig.GetActivityPerSupportNum(self.ActivityId)
    self.MaxSupportCount = XDataCenter.GuardCampManager.GetMaxSupportCount(self.ActivityId)
    self.SelectSupportCount = 1

    local itemId = XGuardCampConfig.GetActivitySupportItemId(self.ActivityId)
    local iconPath = XDataCenter.ItemManager.GetItemIcon(itemId)
    self.RawImage:SetRawImage(iconPath)
end

function XUiGuardCampTips:AutoAddListener()
    self:RegisterClickEvent(self.BtnTanchuangClose, self.Close)
    self:RegisterClickEvent(self.BtnReduce, self.OnBtnReduceClick)
    self:RegisterClickEvent(self.BtnAdd, self.OnBtnAddClick)
    self:RegisterClickEvent(self.BtnTongBlack, self.OnBtnTongBlackClick)
end

function XUiGuardCampTips:Refresh()
    local campName = XGuardCampConfig.GetCampName(self.CampId)
    local tipsDesc = CSXTextManagerGetText("GuardCampSupportTipsDesc", campName)
    self.Text.text = stringGsub(tipsDesc, "\\n", "\n")

    local supportItemId = XGuardCampConfig.GetActivitySupportItemId(self.ActivityId)
    local itemCount = XDataCenter.ItemManager.GetCount(supportItemId)
    self.Count.text = itemCount

    self:RefreshTextSelectCount(itemCount)
end

function XUiGuardCampTips:RefreshTextSelectCount(itemCount)
    local supportNum = self.SelectSupportCount * self.PerSupportNumCfg
    local isCanSupport = itemCount >= supportNum
    self.TextSelectCount.text = supportNum
    self.TextSelectCount.color = CAN_SUPPORT_COLOR[isCanSupport]
end

function XUiGuardCampTips:OnBtnReduceClick()
    local supportItemId = XGuardCampConfig.GetActivitySupportItemId(self.ActivityId)
    if self.SelectSupportCount - 1 < MinSupportCount then
        local itemName = XDataCenter.ItemManager.GetItemName(supportItemId)
        local tipsDesc = CSXTextManagerGetText("GuardCampMinSupport", MinSupportCount * self.PerSupportNumCfg, itemName)
        XUiManager.TipError(tipsDesc)
        return
    end
    self.SelectSupportCount = self.SelectSupportCount - 1
    local itemCount = XDataCenter.ItemManager.GetCount(supportItemId)
    self:RefreshTextSelectCount(itemCount)
end

function XUiGuardCampTips:OnBtnAddClick()
    local supportItemId = XGuardCampConfig.GetActivitySupportItemId(self.ActivityId)
    if self.SelectSupportCount + 1 > self.MaxSupportCount then
        local totalSupportCountCfg = XGuardCampConfig.GetActivityTotalSupportCount(self.ActivityId)
        local itemName = XDataCenter.ItemManager.GetItemName(supportItemId)
        local tipsDesc = CSXTextManagerGetText("GuardCampMaxSupport", totalSupportCountCfg * self.PerSupportNumCfg, itemName)
        XUiManager.TipError(tipsDesc)
        return
    end
    self.SelectSupportCount = self.SelectSupportCount + 1
    local itemCount = XDataCenter.ItemManager.GetCount(supportItemId)
    self:RefreshTextSelectCount(itemCount)
end

function XUiGuardCampTips:OnBtnTongBlackClick()
    local supportItemId = XGuardCampConfig.GetActivitySupportItemId(self.ActivityId)
    local itemCount = XDataCenter.ItemManager.GetCount(supportItemId)
    local supportNum = self.SelectSupportCount * self.PerSupportNumCfg
    local isCanSupport = itemCount >= supportNum
    if not isCanSupport then
        XUiManager.TipText("GuardCampSupportInsufficientQuantity")
        return
    end

    XDataCenter.GuardCampManager.RequestSupportGuardCampSend(self.ActivityId, self.CampId, self.SelectSupportCount, self.Cb)
    self:Close()
end