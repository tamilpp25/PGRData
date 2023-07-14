XDynamicGridTask = XClass(nil, "XDynamicGridTask")

function XDynamicGridTask:Ctor(ui,rootUi,beforeFinishCheckEvent, clickFunc)
    self.GameObject = ui.gameObject
	self.Transform = ui.transform
	self.RootUi = rootUi
    self.RewardPanelList = {}
    self:InitAutoScript()
    self.GridCommon.gameObject:SetActive(false)
    self.ImgComplete.gameObject:SetActive(false)
    self.PanelAnimation.gameObject:SetActive(true)
	self.BeforeFinishCheckEvent = beforeFinishCheckEvent
    self.ClickFunc = clickFunc  --重写点击道具方法
end

function XDynamicGridTask:PlayAnimation()
    if self.IsAnimation then
        return
    end

    self.IsAnimation = true
    self.GridTaskTimeline:PlayTimelineAnimation()
end

function XDynamicGridTask:ResetData(data)
    if not data then
        self.GameObject:SetActiveEx(false)
        return
    end
    self.GameObject:SetActiveEx(true)
    self.Data = data

    if self.PanelAnimationGroup then    -- 先显示
        self.PanelAnimationGroup.alpha = 1
    end

    if self.TaskReceive then --一键领取栏出现在首位 其他所有任务数据往后移一格
        if data.ReceiveAll then
            --隐藏其他界面
            local childCount = self.PanelAnimation.childCount
            for i = 0, childCount - 1 do
                self.PanelAnimation:GetChild(i).gameObject:SetActiveEx(false)
            end

            self.TaskReceive.gameObject:SetActive(true)
            self.ReceiveAllBtn = self.TaskReceive.transform:Find("BtnReceiveBlueLight"):GetComponent("XUiButton")
            self.ReceiveAllBtn.CallBack = function() self:OnBtnAllReceiveClick() end
            return
        else
            --隐藏一键领取
            local childCount = self.PanelAnimation.childCount
            for i = 0, childCount - 1 do
                self.PanelAnimation:GetChild(i).gameObject:SetActiveEx(true)
            end
            if self.PanelTime then
                self.PanelTime.gameObject:SetActiveEx(false)
            end

            self.TaskReceive.gameObject:SetActive(false)
        end
    end
    self.ImgComplete.gameObject:SetActive(data.State == XDataCenter.TaskManager.TaskState.Finish)
    
    local config = XDataCenter.TaskManager.GetTaskTemplate(self.Data.Id)
    self.tableData = config
    self.TxtTaskName.text = config.Title
    self.TxtTaskDescribe.text = config.Desc
    self.TxtSubTypeTip.text = config.Suffix or ""
    --self.RootUi:SetUiSprite(self.RImgTaskType, config.Icon)
    if self.RImgTaskType then
        self.RImgTaskType:SetRawImage(config.Icon)
    end
    self:UpdateProgress(self.Data)
    local rewards = XRewardManager.GetRewardList(config.RewardId)
    -- reset reward panel
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

-- auto
-- Automatic generation of code, forbid to edit
function XDynamicGridTask:InitAutoScript()
    self:AutoInitUi()
    XTool.InitUiObject(self)
    self.SpecialSoundMap = {}
    self:AutoAddListener()
end

function XDynamicGridTask:AutoInitUi()
    self.PanelAnimation = XUiHelper.TryGetComponent(self.Transform, "PanelAnimation", nil)
    self.PanelTime = XUiHelper.TryGetComponent(self.Transform, "PanelAnimation/PanelTime", nil)
    self.RImgTaskType = XUiHelper.TryGetComponent(self.Transform, "PanelAnimation/RImgTaskType", "RawImage")
    self.ImgProgress = XUiHelper.TryGetComponent(self.Transform, "PanelAnimation/ProgressBg/ImgProgress", "Image")
    self.GridCommon = XUiHelper.TryGetComponent(self.Transform, "PanelAnimation/TaskGridList/Viewport/Content/GridCommon", nil)
    self.ImgIcon = XUiHelper.TryGetComponent(self.Transform, "PanelAnimation/TaskGridList/Viewport/Content/GridCommon/ImgIcon", "Image")
    self.ImgQuality = XUiHelper.TryGetComponent(self.Transform, "PanelAnimation/TaskGridList/Viewport/Content/GridCommon/ImgQuality", "Image")
    self.BtnClick = XUiHelper.TryGetComponent(self.Transform, "PanelAnimation/TaskGridList/Viewport/Content/GridCommon/BtnClick", "Button")
    self.TxtCount = XUiHelper.TryGetComponent(self.Transform, "PanelAnimation/TaskGridList/Viewport/Content/GridCommon/TxtCount", "Text")
    self.BtnFinish = XUiHelper.TryGetComponent(self.Transform, "PanelAnimation/BtnFinish", "Button")
    self.BtnSkip = XUiHelper.TryGetComponent(self.Transform, "PanelAnimation/BtnSkip", "Button")
    self.TxtTaskName = XUiHelper.TryGetComponent(self.Transform, "PanelAnimation/TxtTaskName", "Text")
    self.TxtTaskDescribe = XUiHelper.TryGetComponent(self.Transform, "PanelAnimation/TxtTaskDescribe", "Text")
    self.TxtTaskNumQian = XUiHelper.TryGetComponent(self.Transform, "PanelAnimation/TxtTaskNumQian", "Text")
    self.TxtSubTypeTip = XUiHelper.TryGetComponent(self.Transform, "PanelAnimation/TxtSubTypeTip", "Text")
    self.ImgComplete = XUiHelper.TryGetComponent(self.Transform, "PanelAnimation/ImgComplete", "Image") or XUiHelper.TryGetComponent(self.Transform, "PanelAnimation/ImgComplete", "RawImage")
    self.TaskReceive = XUiHelper.TryGetComponent(self.Transform, "PanelAnimation/TaskReceive", nil) -- 一键领取面板
end

function XDynamicGridTask:GetAutoKey(uiNode, eventName)
    if not uiNode then return end
    return eventName .. uiNode:GetHashCode()
end

function XDynamicGridTask:RegisterListener(uiNode, eventName, func)
    local key = self:GetAutoKey(uiNode, eventName)
    if not key then return end
    local listener = self.AutoCreateListeners[key]
    if listener ~= nil then
        uiNode[eventName]:RemoveListener(listener)
    end

    if func ~= nil then
        if type(func) ~= "function" then
            XLog.Error("XUiGridTask:RegisterListener函数错误, 参数func需要是function类型, func的类型是" .. type(func))
        end

        listener = function(...)
            XSoundManager.PlayBtnMusic(self.SpecialSoundMap[key], eventName)
            func(self, ...)
        end

        uiNode[eventName]:AddListener(listener)
        self.AutoCreateListeners[key] = listener
    end
end

function XDynamicGridTask:AutoAddListener()
    self.AutoCreateListeners = {}

    local clickXUiBtn = self.BtnClick:GetComponent("XUiButton")
    if not clickXUiBtn then
        XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClickClick)
    else
        self.BtnClick = clickXUiBtn
        self.BtnClick.CallBack = function() self:OnBtnClickClick() end
    end

    local finishXUiBtn = self.BtnFinish:GetComponent("XUiButton")
    if not finishXUiBtn then
        XUiHelper.RegisterClickEvent(self, self.BtnFinish, self.OnBtnFinishClick)
    else
        self.BtnFinish = finishXUiBtn
        self.BtnFinish.CallBack = function() self:OnBtnFinishClick() end
    end

    local skipXUiBtn = self.BtnSkip:GetComponent("XUiButton")
    if not skipXUiBtn then
        XUiHelper.RegisterClickEvent(self, self.BtnSkip, self.OnBtnSkipClick)
    else
        self.BtnSkip = skipXUiBtn
        self.BtnSkip.CallBack = function() self:OnBtnSkipClick() end
    end
end
-- auto
function XDynamicGridTask:OnBtnClickClick()

end

function XDynamicGridTask:OnBtnAllReceiveClick()
    local weaponCount = 0
    local chipCount = 0
    
    for key, taskId in pairs(self.Data.AllAchieveTaskDatas) do --装备上限判断
        local tableData = XDataCenter.TaskManager.GetTaskTemplate(taskId)
        local rewards = XRewardManager.GetRewardList(tableData.RewardId)
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

    --批量领取任务奖励
    if self.Data.ReceiveCb then
        self.Data.ReceiveCb()
    else
        local taskIds = self.Data.AllAchieveTaskDatas
        XDataCenter.TaskManager.FinishMultiTaskRequest(taskIds, function(rewardGoodsList)
            local horizontalNormalizedPosition = 0
            self:OpenUiObtain(rewardGoodsList, nil, nil, nil, horizontalNormalizedPosition)
        end)
    end
end

function XDynamicGridTask:OpenUiObtain(...)
    XUiManager.OpenUiObtain(...)
end

function XDynamicGridTask:OnBtnFinishClick()
	if self.BeforeFinishCheckEvent then
		if not self.BeforeFinishCheckEvent(self.tableData) then
			return 
		end
	end
    local weaponCount = 0
    local chipCount = 0
    local rewards = XRewardManager.GetRewardList(self.tableData.RewardId)
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
    XDataCenter.TaskManager.FinishTask(self.Data.Id, function(rewardGoodsList)
        for i = 1, #rewards do
            if rewards[i].RewardType == XRewardManager.XRewardType.Nameplate then
                return
            end
        end
        self:OpenUiObtain(rewardGoodsList)
    end)
end

function XDynamicGridTask:OnBtnSkipClick()
    if XDataCenter.RoomManager.RoomData ~= nil then
        local title = CS.XTextManager.GetText("TipTitle")
        local cancelMatchMsg = CS.XTextManager.GetText("OnlineInstanceQuitRoom")
        XUiManager.DialogTip(title, cancelMatchMsg, XUiManager.DialogType.Normal, nil, function()
            XLuaUiManager.RunMain()
            local skipId = XDataCenter.TaskManager.GetTaskTemplate(self.Data.Id).SkipId
            XFunctionManager.SkipInterface(skipId)
        end)
    else
        local skipId = XDataCenter.TaskManager.GetTaskTemplate(self.Data.Id).SkipId
        XFunctionManager.SkipInterface(skipId)
    end
end

function XDynamicGridTask:UpdateProgress(data)
    self.Data = data
    local config = XDataCenter.TaskManager.GetTaskTemplate(data.Id)
    if #config.Condition < 2 then--显示进度
        self.ImgProgress.transform.parent.gameObject:SetActive(true)
        if self.TxtTaskNumQian then
            self.TxtTaskNumQian.gameObject:SetActive(true)
        end
        local result = config.Result > 0 and config.Result or 1
        XTool.LoopMap(self.Data.Schedule, function(_, pair)
            self.ImgProgress.fillAmount = pair.Value / result
            pair.Value = (pair.Value >= result) and result or pair.Value
            if self.TxtTaskNumQian then
                self.TxtTaskNumQian.text = pair.Value .. "/" .. result
            end
        end)
    else
        self.ImgProgress.transform.parent.gameObject:SetActive(false)
        if self.TxtTaskNumQian then
            self.TxtTaskNumQian.gameObject:SetActive(false)
        end
    end

    if not self:IsHasButton() then
        return
    end
    self.BtnFinish.gameObject:SetActive(false)
    self.BtnSkip.gameObject:SetActive(false)
    if self.BtnReceiveHave then
        self.BtnReceiveHave.gameObject:SetActive(false)
    end
    if self.Data.State == XDataCenter.TaskManager.TaskState.Achieved then
        self.BtnFinish.gameObject:SetActive(true)
    elseif self.Data.State ~= XDataCenter.TaskManager.TaskState.Achieved and self.Data.State ~= XDataCenter.TaskManager.TaskState.Finish then
        self.BtnSkip.gameObject:SetActive(true)

        if self.BtnSkip["SetButtonState"] then
            local skipId = XDataCenter.TaskManager.GetTaskTemplate(self.Data.Id).SkipId
            if skipId == nil or skipId == 0 then
                self.BtnSkip:SetButtonState(CS.UiButtonState.Disable)
            else
                self.BtnSkip:SetButtonState(CS.UiButtonState.Normal)
            end
        end
    elseif self.Data.State == XDataCenter.TaskManager.TaskState.Finish then
        if self.BtnReceiveHave then
            self.BtnReceiveHave.gameObject:SetActive(true)
        end
    end
end

function XDynamicGridTask:IsHasButton()
    return true
end 