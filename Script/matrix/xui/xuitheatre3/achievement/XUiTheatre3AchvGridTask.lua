---@class XUiTheatre3AchvGridTask : XUiNode
---@field _Control XTheatre3Control
local XUiTheatre3AchvGridTask = XClass(XUiNode, "XUiTheatre3AchvGridTask")

function XUiTheatre3AchvGridTask:OnStart()
    self:AddBtnListener()
end

function XUiTheatre3AchvGridTask:Refresh(data)
    if not data then
        return
    end

    self.Data = data
    self.TaskConfig = XDataCenter.TaskManager.GetTaskTemplate(data.Id)
    self.TxtName.text = self.TaskConfig.Title
    self.TxtDesc.text = self.TaskConfig.Desc
    -- 状态
    self.Effect.gameObject:SetActiveEx(false)
    self.ImgSelect.gameObject:SetActive(data.State == XDataCenter.TaskManager.TaskState.Finish)
    self.Red.gameObject:SetActiveEx(data.State == XDataCenter.TaskManager.TaskState.Achieved)
    --self.Effect.gameObject:SetActiveEx(data.State == XDataCenter.TaskManager.TaskState.Achieved)
    -- 进度
    if #self.TaskConfig.Condition < 2 then
        self.ImgProgress.transform.parent.gameObject:SetActive(true)
        -- self.TxtTaskNumQian.gameObject:SetActive(true)
        local result = self.TaskConfig.Result > 0 and self.TaskConfig.Result or 1
        XTool.LoopMap(data.Schedule, function(_, pair)
            self.ImgProgress.fillAmount = pair.Value / result
            pair.Value = (pair.Value >= result) and result or pair.Value
        end)
    else
        self.ImgProgress.transform.parent.gameObject:SetActive(false)
    end
end

--region Ui - BtnListener
function XUiTheatre3AchvGridTask:AddBtnListener()
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnFinishClick)
end

function XUiTheatre3AchvGridTask:OnBtnFinishClick()
    if self.Data.State ~= XDataCenter.TaskManager.TaskState.Achieved then
        return
    end
    local weaponCount = 0
    local chipCount = 0
    local rewards = XRewardManager.GetRewardList(self.TaskConfig.RewardId)

    if not XTool.IsTableEmpty(rewards) then
        for i = 1, #rewards do
            local rewardsId = rewards[i].TemplateId
            if XDataCenter.EquipManager.IsClassifyEqualByTemplateId(rewardsId, XEquipConfig.Classify.Weapon) then
                weaponCount = weaponCount + 1
            elseif XDataCenter.EquipManager.IsClassifyEqualByTemplateId(rewardsId, XEquipConfig.Classify.Awareness) then
                chipCount = chipCount + 1
            end
        end
        if weaponCount > 0 and XDataCenter.EquipManager.CheckBagCount(weaponCount, XEquipConfig.Classify.Weapon) == false or
                chipCount > 0 and XDataCenter.EquipManager.CheckBagCount(chipCount, XEquipConfig.Classify.Awareness) == false then
            return
        end
    end
    
    XDataCenter.TaskManager.FinishTask(self.Data.Id, function(rewardGoodsList)
        XEventManager.DispatchEvent(XEventId.EVENT_THEATRE3_ACHIEVEMENT_RECV_TASK)
        if XTool.IsTableEmpty(rewardGoodsList) then
            return
        end
        XLuaUiManager.Open("UiBiancaTheatreTipReward", nil, rewardGoodsList, nil)
    end)
end
--endregion

return XUiTheatre3AchvGridTask