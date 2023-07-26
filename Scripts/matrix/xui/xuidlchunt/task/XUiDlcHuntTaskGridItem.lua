---@class XUiDlcHuntTaskGridItem:XUiGridCommon
local XUiDlcHuntTaskGridItem = XClass(XUiGridCommon, "XUiDlcHuntTaskGridItem")

function XUiDlcHuntTaskGridItem:Refresh(data)
    if XTool.UObjIsNil(self.GameObject) then
        return
    end
    self.GameObject:SetActiveEx(data ~= nil)
    if not data then
        return
    end
    local count, costCount
    self.Data = data
    self.TemplateId = (data.TemplateId and data.TemplateId > 0) and data.TemplateId or data.Id
    count = data.Count
    costCount = data.CostCount
    self.GoodsShowParams = self:GetGoodsShowParams()
    if not self.GoodsShowParams then
        XLog.Error("获取道具数据有误，Data :", data)
        return
    end

    local icon = self.GoodsShowParams.Icon
    if icon and #icon > 0 and self.GoodsShowParams.RewardType ~= XRewardManager.XRewardType.Nameplate then
        self.RImgIcon:SetRawImage(icon)
        self:SetUiActive(self.ImgQuality, true)
        self:SetUiActive(self.RImgIcon, true)
    end
    self.ImgQuality.color = XDlcHuntChipConfigs.GetQualityColor(self.GoodsShowParams.Quality)
    self.TxtAmount.text = CS.XTextManager.GetText("ShopGridCommonCount", count)

    --铭牌
    self:RefreshNameplate()
end

-- auto
function XUiDlcHuntTaskGridItem:OnBtnClickClick()
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
    else
        XLuaUiManager.Open("UiDlcHuntTip", self.Data and self.Data or self.TemplateId, self.HideSkipBtn, self.RootUi and self.RootUi.Name, self.LackNum)
    end
end

return XUiDlcHuntTaskGridItem