

---@class XUiGridFavorabilityStoryReward: XUiNode
---@field _Control XFavorabilityControl
local XUiGridFavorabilityStoryReward = XClass(XUiNode, 'XUiGridFavorabilityStoryReward')

function XUiGridFavorabilityStoryReward:OnStart(index, taskId, totalCount)
    self._Index = index
    self._TaskId = taskId
    self._PosPercent = XTool.IsNumberValid(totalCount) and index / totalCount or 0
    self.TxtValue.text = self._Index
    self.BtnClick.CallBack = handler(self, self.OnBtnClick)
    
    self:InitRewardShow()
end

function XUiGridFavorabilityStoryReward:AutoSetPosition(parentWidth)
    self.Transform.anchoredPosition = Vector2(parentWidth * self._PosPercent, self.Transform.anchoredPosition.y)
end

function XUiGridFavorabilityStoryReward:InitRewardShow()
    local rewardId = XTaskConfig.GetTaskRewardId(self._TaskId)
    local rewardGoodsList = XRewardManager.GetRewardList(rewardId)

    if not XTool.IsTableEmpty(rewardGoodsList) then
        local rewardGoods = rewardGoodsList[1]
        local templateId = rewardGoods.TemplateId
        self.ItemTxtNum.text = rewardGoods.Count
        local icon = XItemConfigs.GetItemIconById(templateId)        
        self.ImgIcon:SetRawImage(icon)
        self.PanelEffect.gameObject:SetActiveEx(false)
        self.GetTag.gameObject:SetActiveEx(false)
        -- 判断任务是否可领取
        if XDataCenter.TaskManager.CheckTaskAchieved(self._TaskId) then
            self.PanelEffect.gameObject:SetActiveEx(true)
        elseif XDataCenter.TaskManager.CheckTaskFinished(self._TaskId) then
            self.GetTag.gameObject:SetActiveEx(true)    
        end
    else
        XLog.Error('奖励列表为空，奖励Id: '..tostring(rewardId))
    end
end

function XUiGridFavorabilityStoryReward:OnBtnClick()
    if XDataCenter.TaskManager.CheckTaskAchieved(self._TaskId) then
        -- 领取
        XDataCenter.TaskManager.FinishTask(self._TaskId, function(rewardGoodsList)
            self.GetTag.gameObject:SetActiveEx(true)
            self.PanelEffect.gameObject:SetActiveEx(false)
            
            XUiManager.OpenUiObtain(rewardGoodsList, nil, nil, nil)
        end)
    else
        -- 弹详情
        local rewardId = XTaskConfig.GetTaskRewardId(self._TaskId)
        local rewardGoodsList = XRewardManager.GetRewardList(rewardId)

        if not XTool.IsTableEmpty(rewardGoodsList) then
            local rewardGoods = rewardGoodsList[1]

            XLuaUiManager.Open("UiTip", rewardGoods)
        end
    end
end

return XUiGridFavorabilityStoryReward