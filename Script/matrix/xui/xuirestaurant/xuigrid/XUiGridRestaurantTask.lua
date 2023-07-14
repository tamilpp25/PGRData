-- 任务单元
-- ================================================================================
local XUiGridRestaurantTask = XClass(nil, "XUiGridRestaurantTask")

function XUiGridRestaurantTask:Ctor(ui, rootUi)
    XUiHelper.InitUiClass(self, ui)
	self.RootUi = rootUi
    self.RewardPanelList = {}
    self.TaskDescText = XRestaurantConfigs.GetClientConfig("TaskDescText", 1)

    XUiHelper.RegisterClickEvent(self, self.BtnReceive, self.OnBtnFinishClick)
    XUiHelper.RegisterClickEvent(self, self.HangInTheAir, self.OnHangInTheAirClick)
end

function XUiGridRestaurantTask:ResetData(data, taskType)
    if not data then
        self.GameObject:SetActiveEx(false)
        return
    end
    self.GameObject:SetActiveEx(true)
    self.Data = data
    self.TaskType = taskType
    self.TaskConfig = XDataCenter.TaskManager.GetTaskTemplate(self.Data.Id)

    self:RefreshTxt()       -- 文本
    self:RefreshState()     -- 状态
    self:RefreshReward()    -- 奖励
    self:RefreshProcess()   -- 进度
end

-- Ui刷新相关
--------------------------------------------------------------------------------

function XUiGridRestaurantTask:RefreshTxt()
    self.TxtTaskName.text = self.TaskConfig.Title
    self.TxtTaskDescribe.text = self.TaskConfig.Desc
end

function XUiGridRestaurantTask:RefreshProcess()
    if #self.TaskConfig.Condition < 2 then--显示进度
        self.ImgProgress.transform.parent.gameObject:SetActive(true)
        -- self.TxtTaskNumQian.gameObject:SetActive(true)
        local result = self.TaskConfig.Result > 0 and self.TaskConfig.Result or 1
        XTool.LoopMap(self.Data.Schedule, function(_, pair)
            self.ImgProgress.fillAmount = pair.Value / result
            pair.Value = (pair.Value >= result) and result or pair.Value
            self.TxtTaskNumQian.text = string.format(self.TaskDescText, pair.Value, result)
        end)
    else
        self.ImgProgress.transform.parent.gameObject:SetActive(false)
    end
end

function XUiGridRestaurantTask:RefreshState()
    local isFinish = self.Data.State == XDataCenter.TaskManager.TaskState.Finish
    local isAchieved = self.Data.State == XDataCenter.TaskManager.TaskState.Achieved
    self.Received.gameObject:SetActiveEx(isFinish)
    self.BtnReceive.gameObject:SetActiveEx(isAchieved)
    self.HangInTheAir.gameObject:SetActiveEx(not isAchieved and not isFinish)
    self.BgAvailable.gameObject:SetActiveEx(isFinish or isAchieved)
    self.BgConduct.gameObject:SetActiveEx(not isAchieved and not isFinish)
end

function XUiGridRestaurantTask:RefreshReward()
    local rewards = XRewardManager.GetRewardList(self.TaskConfig.RewardId)
    for i = 1, #self.RewardPanelList do
        self.RewardPanelList[i]:Refresh()
    end
    if not rewards then
        return
    end
    for i = 1, #rewards do
        local panel = self.RewardPanelList[i]
        local reward = rewards[i]
        if not panel then
            if #self.RewardPanelList == 0 then
                panel = XUiGridCommon.New(self.RootUi, self.GridCommon)
            else
                local ui = CS.UnityEngine.Object.Instantiate(self.GridCommon)
                ui.transform:SetParent(self.GridCommon.parent, false)
                panel = XUiGridCommon.New(self.RootUi, ui)
            end

            if self.ClickFunc then
                XUiHelper.RegisterClickEvent(panel, panel.BtnClick, function()
                    self.ClickFunc(reward)
                end)
            end
            table.insert(self.RewardPanelList, panel)
        end
        panel:Refresh(reward)
    end
end

--------------------------------------------------------------------------------

-- 按钮相关
--------------------------------------------------------------------------------

function XUiGridRestaurantTask:OnBtnFinishClick()
    local weaponCount = 0
    local chipCount = 0
    local rewards = XRewardManager.GetRewardList(self.TaskConfig.RewardId)
    for i = 1, #rewards do
        local rewardsId = self.RewardPanelList[i].TemplateId
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
    local taskType = self.TaskType
    XDataCenter.TaskManager.FinishTask(self.Data.Id, function(rewardGoodsList)
        --新食谱解锁
        if taskType == XRestaurantConfigs.TaskType.Recipe then
            local viewModel = XDataCenter.RestaurantManager.GetViewModel()
            viewModel:NotifyMenuRedPointChange()
            XDataCenter.RestaurantManager.OpenUnlockFood(rewardGoodsList)
            return
        end
        XDataCenter.RestaurantManager.OpenCommonObtain(rewardGoodsList)
    end)
end

function XUiGridRestaurantTask:OnHangInTheAirClick()
    XUiManager.TipError(self.TaskConfig.Desc)
end

--------------------------------------------------------------------------------

return XUiGridRestaurantTask