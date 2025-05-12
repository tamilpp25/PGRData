local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiGridLinkCraftActivityTarget
---@field private _Control XLinkCraftActivityControl
local XUiGridLinkCraftActivityTarget = XClass(XUiNode, 'XUiGridLinkCraftActivityTarget')

function XUiGridLinkCraftActivityTarget:OnStart(index)
    self._Index = index
end

function XUiGridLinkCraftActivityTarget:Refresh(stageId, rewardId, desc)
    local starCount = self._Control:GetStageStarById(stageId)

    self.PanelActive.gameObject:SetActiveEx(self._Index<=starCount)
    
    self.TxtUnActive.text = desc
    self.TxtActive.text = desc

    if XTool.IsNumberValid(rewardId) then
        local gridCommont = XUiGridCommon.New(self, self.Grid256New)
        gridCommont:Refresh(XRewardManager.GetRewardList(rewardId)[1])
    end
end

function XUiGridLinkCraftActivityTarget:SetUiSprite(imgQuality, spriteName)
    self.Parent:SetUiSprite(imgQuality, spriteName)
end


return XUiGridLinkCraftActivityTarget