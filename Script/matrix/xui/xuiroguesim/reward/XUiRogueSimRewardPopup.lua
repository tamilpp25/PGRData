---@class XUiRogueSimRewardPopup : XLuaUi
---@field private _Control XRogueSimControl
local XUiRogueSimRewardPopup = XLuaUiManager.Register(XLuaUi, "UiRogueSimRewardPopup")

function XUiRogueSimRewardPopup:OnAwake()
    self:RegisterUiEvents()
    self.GridReward.gameObject:SetActiveEx(false)
end

function XUiRogueSimRewardPopup:OnStart(resourceData)
    self.ResourceData = resourceData or {}
    self:RefreshReward()
end

function XUiRogueSimRewardPopup:RefreshReward()
    for _, data in pairs(self.ResourceData) do
        local grid = XUiHelper.Instantiate(self.GridReward, self.PanelRewardList)
        grid.gameObject:SetActiveEx(true)
        local icon
        if data.Type == XEnumConst.RogueSim.RewardType.Resource then
            icon = self._Control.ResourceSubControl:GetResourceIcon(data.ItemId)
        elseif data.Type == XEnumConst.RogueSim.RewardType.Commodity then
            icon = self._Control.ResourceSubControl:GetCommodityIcon(data.ItemId)
        elseif data.Type == XEnumConst.RogueSim.RewardType.Prop then
            icon = self._Control.MapSubControl:GetPropIcon(data.ItemId)
        elseif data.Type == XEnumConst.RogueSim.RewardType.Buff then
            icon = self._Control.BuffSubControl:GetBuffIcon(data.ItemId)
        end
        grid:GetObject("RImgIcon"):SetRawImage(icon)
        grid:GetObject("TxtCount").text = string.format("x%s", data.Num)
    end
end

function XUiRogueSimRewardPopup:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
end

function XUiRogueSimRewardPopup:OnBtnCloseClick()
    local type = self._Control:GetHasPopupDataType()
    if type == XEnumConst.RogueSim.PopupType.None then
        self:Close()
        return
    end
    -- 弹出下一个弹框
    self._Control:ShowNextPopup(self.Name, type)
end

return XUiRogueSimRewardPopup
