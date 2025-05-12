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
        local icon = self._Control:GetRewardIcon(data.Type, data.ItemId)
        local name = self._Control:GetRewardName(data.Type, data.ItemId)
        grid:GetObject("RImgIcon"):SetRawImage(icon)
        local txtCount = grid:GetObject("TxtCount")
        txtCount.transform.parent.gameObject:SetActiveEx(data.Num >= 0)
        txtCount.text = string.format("%s%s", "x", data.Num)
        grid:GetObject("TxtName").text = name
    end
end

function XUiRogueSimRewardPopup:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
end

function XUiRogueSimRewardPopup:OnBtnCloseClick()
    self._Control:CheckNeedShowNextPopup(self.Name, true)
end

return XUiRogueSimRewardPopup
