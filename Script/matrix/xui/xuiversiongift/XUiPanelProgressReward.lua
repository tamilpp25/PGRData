--- 历程奖励列表
---@class XUiPanelProgressReward: XUiNode
---@field private _Control XVersionGiftControl
---@field ImgProgress UnityEngine.UI.Image
local XUiPanelProgressReward = XClass(XUiNode, 'XUiPanelProgressReward')
local XUiGridVersionProgressReward = require('XUi/XUiVersionGift/XUiGridVersionProgressReward')

local BarChangeTweenTime = 2 -- 进度条插值动画时长

function XUiPanelProgressReward:Refresh(noTween)
    local passCount, totalCount = self._Control:GetTaskProgress()
    local completeCountMax = self._Control:GetProcessMaxCount()

    self.TxtCurProgress.text = math.min(passCount, completeCountMax)
    self.TxtTotalProgress.text = '/'..tostring(completeCountMax)
    
    local fillAmountValue = completeCountMax == 0 and 0 or passCount/completeCountMax

    if noTween then
        self.ImgProgress.fillAmount = fillAmountValue
    else
        self.ImgProgress:DOFillAmount(fillAmountValue, BarChangeTweenTime)
    end
    
    
    local rewardCount = self._Control:GetProcessRewardICount()
    
    if not XTool.IsTableEmpty(self._RewardGrids) then
        for i, v in pairs(self._RewardGrids) do
            v:Close()
        end
    end
    
    if self._RewardGrids == nil then
        self._RewardGrids = {}
    end
    
    XUiHelper.RefreshCustomizedList(self.PanelNewbieActive.parent.transform, self.PanelNewbieActive, rewardCount, function(index, go)
        local grid = self._RewardGrids[go]

        if not grid then
            grid = XUiGridVersionProgressReward.New(go, self, self.Parent)
            self._RewardGrids[go] = grid
        end
        
        grid:Open()
        grid:SetData(index, completeCountMax, passCount)
    end)
end

function XUiPanelProgressReward:RefreshProcessReward()
    if not XTool.IsTableEmpty(self._RewardGrids) then
        for i, v in pairs(self._RewardGrids) do
            v:Refresh()
        end
    end
end

return XUiPanelProgressReward