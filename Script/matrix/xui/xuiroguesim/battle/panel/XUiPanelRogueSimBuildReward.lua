---@class XUiPanelRogueSimBuildReward : XUiNode
---@field private _Control XRogueSimControl
local XUiPanelRogueSimBuildReward = XClass(XUiNode, "XUiPanelRogueSimBuildReward")

function XUiPanelRogueSimBuildReward:OnStart()
    self.GridReward.gameObject:SetActive(false)
    self.Index = 1
    ---@type XUiComponent.XUiButton[]
    self.GridBuildRewardList = {}
end

function XUiPanelRogueSimBuildReward:OnEnable()
    self:PlayAnimationWithMask("BattlePanelRewardEnable")
end

function XUiPanelRogueSimBuildReward:OnBtnClose()
    self:PlayAnimationWithMask("BattlePanelRewardDisable", function()
        self:Close()
    end)
end

function XUiPanelRogueSimBuildReward:Refresh()
    self.Index = 1
    self:RefreshTempCommodity()
    self:RefreshTempRewardDropId()
    for i = self.Index, #self.GridBuildRewardList do
        self.GridBuildRewardList[i].gameObject:SetActive(false)
    end
end

-- 刷新临时货物
function XUiPanelRogueSimBuildReward:RefreshTempCommodity()
    local commodityIds = self._Control.ResourceSubControl:GetTemporaryBagCommodityIds()
    if XTool.IsTableEmpty(commodityIds) then
        return
    end
    for _, id in pairs(commodityIds) do
        local grid = self.GridBuildRewardList[self.Index]
        if not grid then
            grid = XUiHelper.Instantiate(self.GridReward, self.PanelList)
            self.GridBuildRewardList[self.Index] = grid
        end
        grid.gameObject:SetActive(true)
        grid:SetSprite(self._Control.ResourceSubControl:GetCommodityIcon(id))
        grid:SetNameByGroup(0, self._Control.ResourceSubControl:GetTemporaryBagCommodityCountById(id))
        grid.CallBack = function() self:OnBtnTempCommodity() end
        self.Index = self.Index + 1
    end
end

-- 刷新临时RewardDropId
function XUiPanelRogueSimBuildReward:RefreshTempRewardDropId()
    local rewardDropIdCount = self._Control.ResourceSubControl:GetTemporaryBagRewardDropIdCount()
    if rewardDropIdCount <= 0 then
        return
    end
    local grid = self.GridBuildRewardList[self.Index]
    if not grid then
        grid = XUiHelper.Instantiate(self.GridReward, self.PanelList)
        self.GridBuildRewardList[self.Index] = grid
    end
    grid.gameObject:SetActive(true)
    grid:SetSprite(self._Control:GetClientConfig("TemporaryBagRewardDropIcon"))
    grid:SetNameByGroup(0, rewardDropIdCount)
    grid.CallBack = function() self:OnBtnTempRewardDropId() end
    self.Index = self.Index + 1
end

function XUiPanelRogueSimBuildReward:OnBtnTempCommodity()
    local commodityIds = self._Control.ResourceSubControl:GetTemporaryBagCommodityIds()
    if XTool.IsTableEmpty(commodityIds) then
        XUiManager.TipMsg(self._Control:GetClientConfig("TemporaryBagRewardTips", 1))
        return
    end
    -- 是否可领取
    local isCanReceive = false
    for _, id in pairs(commodityIds) do
        local isFull = self._Control.ResourceSubControl:CheckCommodityOwnIsFull(id)
        if not isFull then
            isCanReceive = true
            break
        end
    end
    if not isCanReceive then
        local names = {}
        for _, id in pairs(commodityIds) do
            table.insert(names, self._Control.ResourceSubControl:GetCommodityName(id))
        end
        XUiManager.TipMsg(string.format(self._Control:GetClientConfig("TemporaryBagRewardTips", 2), table.concat(names, ",")))
        return
    end
    self._Control:RogueSimTemporaryBagGetRewardRequest(XEnumConst.RogueSim.BagGetRewardType.Commodity)
end

function XUiPanelRogueSimBuildReward:OnBtnTempRewardDropId()
    local rewardDropIdCount = self._Control.ResourceSubControl:GetTemporaryBagRewardDropIdCount()
    if rewardDropIdCount <= 0 then
        XUiManager.TipMsg(self._Control:GetClientConfig("TemporaryBagRewardTips", 1))
        return
    end
    self._Control:RogueSimTemporaryBagGetRewardRequest(XEnumConst.RogueSim.BagGetRewardType.Prop, function()
        local typeData = {
            NextType = nil,
            ArgType = XEnumConst.RogueSim.PopupType.PropSelect,
        }
        self._Control:CheckNeedShowNextPopup(nil, false, typeData, 0, XEnumConst.RogueSim.SourceType.TemporaryReward)
    end)
end

return XUiPanelRogueSimBuildReward
