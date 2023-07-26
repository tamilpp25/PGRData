
local XUiHitMousePanelRewardIcon = XClass(nil, "XUiHitMousePanelRewardIcon")

function XUiHitMousePanelRewardIcon:Ctor(uiPrefab)
    XTool.InitUiObjectByUi(self, uiPrefab)
    self:Init()
end

function XUiHitMousePanelRewardIcon:Init()
    self:ResetIcon()
    XUiHelper.RegisterClickEvent(self, self.BtnClick, handler(self, self.OnClick))
end

function XUiHitMousePanelRewardIcon:ResetIcon()
    self:SetIconImage(nil)
    self:SetQualityImage(nil)
    self:SetReceived(false)
    self:SetCanGet(false)
end

function XUiHitMousePanelRewardIcon:Refresh(index, rewardId)
    self.ItemId,self.ItemCount = self:GetFirstRewardItemId(rewardId)
    if self.ItemId == 0 then
        self:ResetIcon()
        return
    end
    self.GoodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(self.ItemId)
    self:SetIconImage(self.GoodsShowParams.Icon)
    self:SetQualityImage(self.GoodsShowParams.Quality)
    self.TxtCount.text = "x" .. self.ItemCount
    local isGet = XDataCenter.HitMouseManager.CheckRewardIsGet(index)
    if not isGet then
        local canGet = XDataCenter.HitMouseManager.CheckRewardCanGet(index)
        self:SetReceived(isGet)
        self:SetCanGet(canGet)
    else
        self:SetReceived(true)
        self:SetCanGet(false)
    end
end

function XUiHitMousePanelRewardIcon:GetFirstRewardItemId(rewardId)
    if rewardId and rewardId > 0 then
        local rewards = XRewardManager.GetRewardList(rewardId)
        if rewards then
            for _, v in pairs(rewards) do
                return v.TemplateId or v.Id, v.Count or 0
            end
        end
    end
    return 0
end

function XUiHitMousePanelRewardIcon:SetIconImage(imagePath)
    self.RImgIcon.gameObject:SetActiveEx(imagePath ~= nil)
    if not imagePath then return end
    self.RImgIcon:SetRawImage(imagePath)
end

function XUiHitMousePanelRewardIcon:SetQualityImage(quality)
    self.ImgQuality.gameObject:SetActiveEx(quality ~= nil)
    if not quality then return end
    XUiHelper.SetQualityIcon(nil, self.ImgQuality, quality)
end

function XUiHitMousePanelRewardIcon:SetReceived(isReceived)
    self.IsReceived = isReceived
    self.ReceivedPanel.gameObject:SetActiveEx(isReceived)
end

function XUiHitMousePanelRewardIcon:SetCanGet(value)
    self.CanGet = value
    self.PanelEffect.gameObject:SetActiveEx(value)
end

function XUiHitMousePanelRewardIcon:OnClick()
    if self.IsReceived then

        return
    end
    if not self.CanGet then
        XLuaUiManager.Open("UiTip", self.ItemId)
        return
    end
    if self.ItemId > 0 and self.CanGet then
        XDataCenter.HitMouseManager.GetRewards()
    end
end

return XUiHitMousePanelRewardIcon