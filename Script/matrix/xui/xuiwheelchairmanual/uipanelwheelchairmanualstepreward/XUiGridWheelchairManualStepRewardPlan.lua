local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiGridWheelchairManualStepRewardPlan: XUiNode
---@field _Control XWheelchairManualControl
local XUiGridWheelchairManualStepRewardPlan = XClass(XUiNode, 'XUiGridWheelchairManualStepRewardPlan')

---@param rootUi XLuaUi
function XUiGridWheelchairManualStepRewardPlan:OnStart(rootUi)
    self.Grid256New.gameObject:SetActiveEx(false)
    self.BtnClick.CallBack = handler(self, self.OnClickEvent)
    
    self.RootUi = rootUi
end

function XUiGridWheelchairManualStepRewardPlan:RefreshData(planId, index)
    self.PlanId = planId
    self.Index= index
    local isSpecial = self._Control:GetManualPlanIsSpecial(self.PlanId)
    local isCurrent = self.PlanId == self._Control:GetCurActivityCurrentPlanId()
    self.ImgBg.gameObject:SetActiveEx(not isSpecial)
    self.ImgSpecialBg.gameObject:SetActiveEx(isSpecial)

    -- 判断当前进度
    local passCount, allCount = XMVCA.XWheelchairManual:GetPlanProcess(self.PlanId)
    local isProcessValid = XTool.IsNumberValid(allCount)
    
    
    -- 奖励领取情况
    local isFinish = true
    local isAchieved = false
    if isProcessValid then
        isFinish = passCount == allCount
        isAchieved = self._Control:CheckPlanIsGetReward(self.PlanId)
    end

    self.PanelReceive.gameObject:SetActiveEx(isAchieved)
    self.BtnClick:ShowReddot(isFinish and not isAchieved)
    self.Collect.gameObject:SetActiveEx(isFinish and not isAchieved)

    -- 进度显示控制
    if isCurrent and not isAchieved then
        if isProcessValid then
            self.TxtProcess.text = XUiHelper.FormatText(XMVCA.XWheelchairManual:GetWheelchairManualConfigString('CommonProcessLabel'), passCount, allCount)
        end
    end
    self.TxtProcess.gameObject:SetActiveEx(isProcessValid and isCurrent and not isAchieved)
    self.PanelOngoing.gameObject:SetActiveEx(isCurrent and not isFinish)
    self.Normal.gameObject:SetActiveEx(not isCurrent or isFinish)
    -- 刷新奖励道具
    self:RefreshRewardGrids()
    
    self.BtnClick:SetNameByGroup(0, XUiHelper.FormatText(XMVCA.XWheelchairManual:GetWheelchairManualConfigString('PlanTitle'), self.Index))
    self.BtnClick:SetRawImage(self._Control:GetManualPlanTitleIcon(self.PlanId))
end

function XUiGridWheelchairManualStepRewardPlan:RefreshRewardGrids()
    if self._RewardGrids == nil then
        self._RewardGrids = {}
    end

    if not XTool.IsTableEmpty(self._RewardGrids) then
        -- 回收
        for i, v in pairs(self._RewardGrids) do
            v.GameObject:SetActiveEx(false)
        end
    end
    
    local rewardId = self._Control:GetManualPlanRewardId(self.PlanId)

    if XTool.IsNumberValid(rewardId) then
        local rewardGoodsList = XRewardManager.GetRewardList(rewardId)
        -- 显示奖励
        if not XTool.IsTableEmpty(rewardGoodsList) then
            for i, v in ipairs(rewardGoodsList) do
                ---@type XUiGridCommon
                local grid = self._RewardGrids[i]

                if not grid then
                    local go = CS.UnityEngine.GameObject.Instantiate(self.Grid256New, self.Grid256New.transform.parent)
                    grid = XUiGridCommon.New(self.RootUi, go)
                    table.insert(self._RewardGrids, grid)
                end
                
                grid.GameObject:SetActiveEx(true)
                grid:Refresh(v)
            end
        end
    end
end

function XUiGridWheelchairManualStepRewardPlan:OnClickEvent()
    if self._Control:CheckAnyPlanCanGetReward() then
        XMVCA.XWheelchairManual:RequestWheelchairManualGetPlanReward(function(success, rewardList)
            if success then
                self.Parent:RefreshPlanShow()
                self._Control:ShowRewardList(rewardList)
            end
        end)
    end
end

return XUiGridWheelchairManualStepRewardPlan