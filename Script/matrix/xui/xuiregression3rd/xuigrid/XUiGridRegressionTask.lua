local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")

local XUiGridRegressionTask = XClass(nil, "XUiGridRegressionTask")

--- 格子类型
---@field Sign 签到
---@field Task 签到
local GridType = {
    Sign = 1,
    Task = 2
}

function XUiGridRegressionTask:Ctor(ui, uiRegression)
    XTool.InitUiObjectByUi(self, ui)
    self.UiRegression = uiRegression
    self.GridCommon.gameObject:SetActiveEx(false)
    self.GridItems = {}
    self.GridType = GridType.Sign
    self.TaskContent = self.GridCommon.transform.parent
    self.DynamicGrid = self.Transform:GetComponent("DynamicGrid")
    if self.DynamicGrid then
        self.DynamicGrid.PlayOnEnable = true
    end
    self:InitCb()
end

function XUiGridRegressionTask:RefreshSign(signData)
    if not signData then
        self.GameObject:SetActiveEx(false)
        return
    end
    self.Data = signData
    self.PanelTime.gameObject:SetActiveEx(false)
    local signVideModel = XDataCenter.Regression3rdManager.GetViewModel():GetProperty("_SignViewModel")
    
    local finish = signVideModel:CheckIsReceive(signData.Id)
    local achieved = signVideModel:CheckIsSign(signData.Days)
    self.TxtTaskName.text = string.format(XRegression3rdConfigs.GetClientConfigValue("SignDaysDesc", 2), XTool.ParseNumberString(signData.Days))
    
    self:RefreshReward(signData.RewardId)
    self:RefreshButton(finish, achieved, true)
    self.GridType = GridType.Sign
end

function XUiGridRegressionTask:RefreshTask(taskData)
    if not taskData then
        self.GameObject:SetActiveEx(false)
        return
    end
    self.Data = taskData
    local taskViewModel = XDataCenter.Regression3rdManager.GetViewModel():GetProperty("_TaskVideModel")
    
    local finish = taskData.State == XDataCenter.TaskManager.TaskState.Finish
    local achieved = taskData.State == XDataCenter.TaskManager.TaskState.Achieved
    
    local template = XDataCenter.TaskManager.GetTaskTemplate(taskData.Id)
    self.TxtTaskName.text = template.Title
    self.TxtTaskDescribe.text = template.Desc
    if not string.IsNilOrEmpty(template.Icon) then
        self.RImgTaskType:SetRawImage(template.Icon)
    end
    self:RefreshReward(template.RewardId)
    --进度条
    local showProgress = #template.Condition < 2
    self.ImgProgress.gameObject:SetActiveEx(showProgress)
    self.TxtTaskNumQian.gameObject:SetActiveEx(showProgress)
    
    if showProgress then
        local result = template.Result > 0 and template.Result or 1
        XTool.LoopMap(taskData.Schedule, function(_, pair) 
            local value = math.min(result, pair.Value)
            self.ImgProgress.fillAmount = XUiHelper.GetFillAmountValue(value, result)
            self.TxtTaskNumQian.text = value .. "/" .. result
        end)
    end
    local skipId = template.SkipId
    local time = taskViewModel:GetEndTime(taskData.Id)
    local disable = not XTool.IsNumberValid(skipId) or time < 0
    local showTime = time ~= 0 and not finish
    self.PanelTime.gameObject:SetActiveEx(showTime)
    if showTime then
        local tipsIndex = time > 0 and 1 or 2
        local tips = XRegression3rdConfigs.GetClientConfigValue("TaskEndTime", tipsIndex)
        self.TxtTime.text = string.format(tips, XUiHelper.GetTimeAndUnit(math.abs(time), 
                XUiHelper.TimeUnit.Hour, XUiHelper.TimeUnit.Day))
    end
    self.SkipId = skipId
    self:RefreshButton(finish, achieved, disable)
    self.GridType = GridType.Task
end

function XUiGridRegressionTask:RefreshReward(rewardId)
    self.RewardId = rewardId
    self:HideAllReward()
    local rewardList = XRewardManager.GetRewardList(rewardId)
    if XTool.IsTableEmpty(rewardList) then
        return
    end

    for idx, reward in ipairs(rewardList) do
        local grid = self.GridItems[idx]
        if not grid then
            local ui = idx == 1 and self.GridCommon or XUiHelper.Instantiate(self.GridCommon, self.TaskContent)
            grid = XUiGridCommon.New(self.UiRegression, ui)
            self.GridItems[idx] = grid
        end
        grid:Refresh(reward)
        grid.GameObject:SetActiveEx(true)
    end
end

function XUiGridRegressionTask:HideAllReward()
    for _, grid in pairs(self.GridItems) do
        grid.GameObject:SetActiveEx(false)
    end
end

--- 刷新按钮状态
---@param finish 已完成且领取
---@param achieved 已完成未领取
---@param disableBtnSkip 禁用跳转按钮
---@return nil
--------------------------
function XUiGridRegressionTask:RefreshButton(finish, achieved, disableBtnSkip)
    self.BtnSkip.gameObject:SetActiveEx(not finish and not achieved)
    self.BtnFinish.gameObject:SetActiveEx(not finish and achieved)
    self.ImgComplete.gameObject:SetActiveEx(finish)

    self.BtnSkip:SetDisable(disableBtnSkip, not disableBtnSkip)
end

function XUiGridRegressionTask:InitCb()
    self.BtnSkip.CallBack = function() 
        self:OnBtnSkipClick()
    end
    
    self.BtnFinish.CallBack = function() 
        self:OnBtnFinishClick()
    end
end


function XUiGridRegressionTask:OnBtnSkipClick()
    if not XTool.IsNumberValid(self.SkipId) then
        return
    end
    XFunctionManager.SkipInterface(self.SkipId)
end

function XUiGridRegressionTask:OnBtnFinishClick()
    if not self:OnBeforeFinishCheck() then
        return
    end
    local data = self.Data
    if GridType.Sign == self.GridType then
        XDataCenter.Regression3rdManager.RequestSignIn(data.Id, function() 
            self:RefreshSign(data)
        end)
    else
        XDataCenter.TaskManager.FinishTask(data.Id, function(rewardGoodsList)
            XUiManager.OpenUiObtain(rewardGoodsList)
            local taskViewModel = XDataCenter.Regression3rdManager.GetViewModel():GetProperty("_TaskVideModel")
            taskViewModel:UpdateFinishCount()
            XEventManager.DispatchEvent(XEventId.EVENT_REGRESSION3_TASK_STATUS_CHANGE)
        end)
    end
end

function XUiGridRegressionTask:OnBeforeFinishCheck()
    if not XTool.IsNumberValid(self.RewardId) then
        return false
    end
    local rewards = XRewardManager.GetRewardList(self.RewardId)
    local weaponCount, chipCount = 0, 0
    for i = 1, #rewards do
        local templateId = self.GridItems[i].TemplateId
        if XMVCA.XEquip:IsClassifyEqualByTemplateId(templateId, XEnumConst.EQUIP.CLASSIFY.WEAPON) then
            weaponCount = weaponCount + 1
        elseif XMVCA.XEquip:IsClassifyEqualByTemplateId(templateId, XEnumConst.EQUIP.CLASSIFY.AWARENESS) then
            chipCount = chipCount + 1
        end
    end
    if (weaponCount > 0 and XMVCA.XEquip:CheckBagCount(weaponCount, XEnumConst.EQUIP.CLASSIFY.WEAPON) == false) 
            or (chipCount > 0 and XMVCA.XEquip:CheckBagCount(chipCount, XEnumConst.EQUIP.CLASSIFY.AWARENESS) == false ) 
    then
        return false
    end
    return true
end


return XUiGridRegressionTask