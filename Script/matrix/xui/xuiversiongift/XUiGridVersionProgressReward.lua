local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiGridVersionProgressReward: XUiNode
---@field private _Control XVersionGiftControl
local XUiGridVersionProgressReward = XClass(XUiNode, 'XUiGridVersionProgressReward')

---@param rootUi XLuaUi
function XUiGridVersionProgressReward:OnStart(rootUi)
    self.RootUi = rootUi
    self.BtnActive.CallBack = handler(self, self.OnBtnRecieveClick)
end

function XUiGridVersionProgressReward:SetData(index, tasktotalCount, taskFinishCount)
    self._Index = index
    self._TaskTotalCount = tasktotalCount
    self._TaskFinishCount = taskFinishCount
    self:Refresh()
end

function XUiGridVersionProgressReward:Refresh()
    -- 刷新奖励展示
    local rewardId = self._Control:GetProcessRewardIdByIndex(self._Index)

    if XTool.IsNumberValid(rewardId) then
        if not self._GridReward then
            self._GridReward = XUiGridCommon.New(self.RootUi, self.Grid128)
        end
        
        local rewardList = XRewardManager.GetRewardList(rewardId)
        
        self._GridReward:Refresh(rewardList[1])
    end
    
    -- 刷新进度展示
    local completeCount = self._Control:GetProcessTaskCompleteCountByIndex(self._Index) or 0
    
    self.TxtValue.text = completeCount
    
    local percent = self._TaskTotalCount == 0 and 0 or completeCount / self._TaskTotalCount
    local width = self.Transform.parent.rect.width
    
    self.Transform.anchoredPosition = Vector2(width * percent, self.Transform.anchoredPosition.y)
    
    -- 刷新可领奖状态
    local isGot = self._Control:GetIsProcessRewardGotByIndex(self._Index)
    local isCanGet = self._TaskFinishCount >= completeCount and not isGot
    self.CanRecieveEffect.gameObject:SetActiveEx(isCanGet)
    self.BtnActive.gameObject:SetActiveEx(isCanGet)
    
    self.ImgRe.gameObject:SetActiveEx(isGot)
end

function XUiGridVersionProgressReward:OnBtnRecieveClick()
    self._Control:SetTickoutLock(true)
    XMVCA.XVersionGift:DoVersionGiftGetProgressRewardRequest(XEnumConst.VersionGift.RewardType.ProgressReward, function(rewardList)
        self.Parent:RefreshProcessReward()
        XUiManager.OpenUiObtain(rewardList, nil, function()
            if self._Control then
                self._Control:SetTickoutLock(false)
            end
        end)
    end)
end

return XUiGridVersionProgressReward