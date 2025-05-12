local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiGridBagOrganizeTarget:XUiNode
---@field _Control XBagOrganizeActivityControl
local XUiGridBagOrganizeTarget = XClass(XUiNode, 'XUiGridBagOrganizeTarget')

---@param cfg XTableBagOrganizeStage
function XUiGridBagOrganizeTarget:Refresh(desc, isAchieve)
    self.TargetOff.gameObject:SetActiveEx(not isAchieve)
    self.TargetOn.gameObject:SetActiveEx(isAchieve)

    if isAchieve then
        self.TxtTargetOn.text = desc
    else
        self.TxtTargetOff.text = desc
    end
end

function XUiGridBagOrganizeTarget:RefreshWithReward(desc, isAchieve, rewardCount)
   self:Refresh(desc, isAchieve)
    
    if self.Grid256New and XTool.IsNumberValid(rewardCount) then
        if self._RewardGrid == nil then
            ---@type XUiGridCommon
            self._RewardGrid = XUiGridCommon.New(nil, self.Grid256New)
        end
        
        local rewardCoinTemplate = self._Control:GetClientConfigNum('BagOrganizeItemId')
        
        if XTool.IsNumberValid(rewardCoinTemplate) then
            self._RewardGrid.GameObject:SetActiveEx(true)
            self._RewardGrid:Refresh(rewardCoinTemplate)
            self._RewardGrid:SetCount(rewardCount)
            self._RewardGrid:SetReceived(isAchieve)
        else
            self._RewardGrid.GameObject:SetActiveEx(false)
        end
        
    end
end

return XUiGridBagOrganizeTarget