---@class XUiPanelRogueSimEventAuction : XUiNode
---@field private _Control XRogueSimControl
---@field Parent XUiRogueSimOutpost
local XUiPanelRogueSimEventAuction = XClass(XUiNode, "XUiPanelRogueSimEventAuction")

---@param eventId number 事件Id
function XUiPanelRogueSimEventAuction:Refresh(eventId, rewardId)
    self.EventId = eventId
    self.RewardId = rewardId
    self:RefreshEventInfo()
end

-- 刷新事件信息
function XUiPanelRogueSimEventAuction:RefreshEventInfo()
    -- 事件标题
    self.TxtTitle.text = self._Control.MapSubControl:GetEventName(self.EventId)
    -- 剩余回合数
    self.Parent:RefreshRemainingDuration(self.TxtContent2)
    -- 事件描述
    self.TxtTips.text = self._Control.MapSubControl:GetEventText(self.EventId)
    -- 事件奖励Id
    if not XTool.IsNumberValid(self.RewardId) then
        return
    end
    local rewardList = self._Control:GetRewardListByConfigId(self.RewardId)
    -- 默认取第一个奖励
    local reward = rewardList[1]
    if not reward then
        return
    end
    -- 奖励图标
    local icon = self._Control:GetRewardIcon(reward.Type, reward.ItemId)
    if icon then
        self.RImgIcon:SetRawImage(icon)
    end
    -- 奖励名称
    self.TxtName.text = self._Control:GetRewardName(reward.Type, reward.ItemId)
    -- 奖励数量
    self.TxtNum.text = reward.Num or 0
    -- 奖励描述
    self.TxtDetail.text = self._Control:GetRewardDesc(reward.Type, reward.ItemId)
end

return XUiPanelRogueSimEventAuction
