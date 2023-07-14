---@class XUiDlcRwlTipItemGrid:XUiGridCommon
local XUiDlcRwlTipItemGrid = XClass(XUiGridCommon, "XUiDlcRwlTipItemGrid")

-- auto
function XUiDlcRwlTipItemGrid:OnBtnClickClick()
    if self.Disable or self.BtnNotClick then
        return
    end
    -- 匹配中
    if XDataCenter.FubenUnionKillRoomManager.IsMatching() then
        return
    end

    if self.ProxyClickFunc then
        self.ProxyClickFunc()
        return
    end
    if self.GoodsShowParams.RewardType == XRewardManager.XRewardType.Nameplate then
        XLuaUiManager.Open("UiNameplateTip", self.TemplateId, true, true, true)
        return
    end
    XLuaUiManager.Open("UiDlcHuntTip", self.Data and self.Data or self.TemplateId, self.HideSkipBtn, self.RootUi and self.RootUi.Name, self.LackNum)
end

return XUiDlcRwlTipItemGrid