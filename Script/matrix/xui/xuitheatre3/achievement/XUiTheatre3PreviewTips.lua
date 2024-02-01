---@class XUiTheatre3PreviewTips : XLuaUi
---@field _Control XTheatre3Control
local XUiTheatre3PreviewTips = XLuaUiManager.Register(XLuaUi, "UiTheatre3PreviewTips")

function XUiTheatre3PreviewTips:OnAwake()
    self:AddBtnListener()
end

function XUiTheatre3PreviewTips:OnStart()
    self:InitReward()
end

--region Ui - Reward
function XUiTheatre3PreviewTips:InitReward()
    ---@type XUiTheatre3PreviewGridReward[]
    self._GridRewardList = {}
    local XUiTheatre3PreviewGridReward = require("XUi/XUiTheatre3/Achievement/XUiTheatre3PreviewGridReward")
    local rewardIdList = self._Control:GetCfgAchievementRewardIdList()
    local needCountList = self._Control:GetCfgAchievementNeedCountList()
    for i, rewardId in ipairs(rewardIdList) do
        self._GridRewardList[i] = XUiTheatre3PreviewGridReward.New(XUiHelper.Instantiate(self.GridPreview, self.PanelList), self)
        self._GridRewardList[i]:Refresh(rewardId, needCountList[i])
    end
    self.GridPreview.gameObject:SetActiveEx(false)
end
--endregion

--region Ui - BtnListener
function XUiTheatre3PreviewTips:AddBtnListener()
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangClose, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnOk, self.Close)
end
--endregion

return XUiTheatre3PreviewTips