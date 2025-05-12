local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiAccumulateDrawRewardGrid : XUiNode
---@field TxtNum UnityEngine.UI.Text
---@field RImgItem UnityEngine.UI.RawImage
---@field PanelReward UnityEngine.RectTransform
---@field GridReward UnityEngine.RectTransform
---@field _Control XAccumulateExpendControl
local XUiAccumulateDrawRewardGrid = XClass(XUiNode, "XUiAccumulateDrawRewardGrid")

function XUiAccumulateDrawRewardGrid:OnStart(rootUi)
    ---@type XUiGridCommon[]
    self._RewardGridList = {}
    self._RootUi = rootUi
    self.GridReward.gameObject:SetActiveEx(false)
end

---@param reward XAccumulateExpendReward
function XUiAccumulateDrawRewardGrid:Refresh(reward)
    self.TxtNum.text = reward:GetItemCount()
    self.RImgItem:SetRawImage(self._Control:GetItemIcon())
    self:_RefreshRewardList(reward:GetRewardList())
end

function XUiAccumulateDrawRewardGrid:_RefreshRewardList(rewardList)
    for i, reward in pairs(rewardList) do
        ---@type XUiGridCommon
        local grid = self._RewardGridList[i]

        if grid then
            grid:Refresh(reward)
            grid:SetUiActive(grid.TxtName, false)
        else
            local gridUi = XUiHelper.Instantiate(self.GridReward, self.PanelReward)

            grid = XUiGridCommon.New(self._RootUi, gridUi)
            grid.GameObject:SetActiveEx(true)
            grid:Refresh(reward)
            grid:SetUiActive(grid.TxtName, false)
            self._RewardGridList[i] = grid
        end
    end
    for i = #rewardList + 1, #self._RewardGridList do
        self._RewardGridList[i].GameObject:SetActiveEx(false)
    end
end

return XUiAccumulateDrawRewardGrid