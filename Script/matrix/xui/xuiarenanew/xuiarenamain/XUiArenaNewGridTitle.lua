---@class XUiArenaNewGridTitle : XUiNode
---@field ImgBgUp UnityEngine.UI.Image
---@field ImgBgHold UnityEngine.UI.Image
---@field ImgBgDown UnityEngine.UI.Image
---@field TxtTitle UnityEngine.UI.Text
---@field ImgReward UnityEngine.UI.Image
---@field TxtNum UnityEngine.UI.Text
---@field _Control XArenaControl
local XUiArenaNewGridTitle = XClass(XUiNode, "XUiArenaNewGridTitle")

-- region 生命周期
function XUiArenaNewGridTitle:OnStart(regionType)
    self._RegionType = regionType
end

function XUiArenaNewGridTitle:OnEnable()
    self:_Refresh()
end

-- endregion

function XUiArenaNewGridTitle:Refresh(regionType)
    self._RegionType = regionType
end

-- region 私有方法

function XUiArenaNewGridTitle:_Refresh()
    if self._RegionType then
        local reward = self._Control:GetCurrentChallengeRewardByRegionType(self._RegionType)
        local rewardIcon = reward and XGoodsCommonManager.GetGoodsIcon(reward.TemplateId) or ""
        local rewardCount = reward and reward.Count or 0
        
        self.ImgBgUp.gameObject:SetActiveEx(self._RegionType == XEnumConst.Arena.RegionType.Up)
        self.ImgBgHold.gameObject:SetActiveEx(self._RegionType == XEnumConst.Arena.RegionType.Keep)
        self.ImgBgDown.gameObject:SetActiveEx(self._RegionType == XEnumConst.Arena.RegionType.Down)
        self.TxtTitle.text = self._Control:GetRankRegionText(self._RegionType)
        
        if string.IsNilOrEmpty(rewardIcon) then
            self.ImgReward.gameObject:SetActiveEx(false)
        else
            self.ImgReward:SetSprite(rewardIcon)
        end
        self.TxtNum.text = rewardCount
    else
        self:Close()
    end
end

-- endregion

return XUiArenaNewGridTitle
