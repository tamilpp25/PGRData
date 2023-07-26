---@class XUiGridTheatre3RewardBase : XUiNode
---@field _Control XTheatre3Control
local XUiGridTheatre3RewardBase = XClass(XUiNode, "XUiGridTheatre3RewardBase")

function XUiGridTheatre3RewardBase:GetReward(battlePassId)
    local rewardId = self._Control:GetBattlePassRewardId(battlePassId)
    local rewardList = XRewardManager.GetRewardList(rewardId)
    return rewardList[1] --读取第一个
end

function XUiGridTheatre3RewardBase:SetBtnView(btnGrid, battlePassId)
    local reward = self:GetReward(battlePassId)
    local goodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(reward.TemplateId)
    if not goodsShowParams then
        return
    end
    -- 等级
    btnGrid:SetNameByGroup(0, battlePassId)
    -- 名字
    local name = goodsShowParams.RewardType == XArrangeConfigs.Types.Character and goodsShowParams.TradeName or goodsShowParams.Name
    local count = reward.Count
    btnGrid:SetNameByGroup(1, name)
    -- 描述
    btnGrid:SetNameByGroup(2, "")
    --数量
    btnGrid:SetNameByGroup(3, "x" .. count)
    -- 图标
    local icon = goodsShowParams.BigIcon
    btnGrid:SetRawImage(icon)
end

return XUiGridTheatre3RewardBase