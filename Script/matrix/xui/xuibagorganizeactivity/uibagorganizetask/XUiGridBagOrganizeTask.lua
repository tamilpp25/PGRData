local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
--- 任务列表的任务项
---@class XUiGridBagOrganizeTask: XUiNode
---@field private _Control XBagOrganizeActivityControl
local XUiGridBagOrganizeTask = XClass(XUiNode, 'XUiGridBagOrganizeTask')

---@param rootUi XLuaUi @当直接父节点不是XLuaUi类型时必传
function XUiGridBagOrganizeTask:OnStart(rootUi)
    self.RootUi = rootUi
    
    self.BtnFinish.CallBack = handler(self, self.OnBtnFinishClick)
    self.BtnSkip.CallBack = handler(self, self.OnBtnSkipClick)
    self.BtnReceiveBlueLight.CallBack = handler(self, self.OnBtnReceiveAllClick)

    self.GridCommon.gameObject:SetActiveEx(false)
    
    self._StartRun = true
end

function XUiGridBagOrganizeTask:OnEnable()
    if self._StartRun then
        self._StartRun = false
        
        self:PlayAnimation('GridTaskEnable')
        return
    end
end

function XUiGridBagOrganizeTask:RefreshTask(taskData)
    if XTool.IsTableEmpty(taskData) then
        XLog.Error('传入空的任务数据')
        return
    end

    if taskData.IsReceiveAllTask then
        self.ReceiveAllTaskData = taskData
        self:RefreshReceiveAllShow()
    else
        self.TaskReceive.gameObject:SetActiveEx(false)
        
        ---@type XTaskData
        self.TaskData = taskData

        self:RefreshTaskBasicShow()
        self:RefreshTaskScheduleShow()
    end
end

--- 刷新基本信息
function XUiGridBagOrganizeTask:RefreshTaskBasicShow()
    if self.Bg then
        self.Bg.gameObject:SetActiveEx(true)
    end

    if self.RImgTaskType then
        self.RImgTaskType.gameObject:SetActiveEx(true)
    end
    
    ---@type XTableTask
    local taskCfg = XTaskConfig.GetTaskCfgById(self.TaskData.Id)

    if taskCfg then
        -- 标题、描述
        self.TxtTaskName.gameObject:SetActiveEx(true)
        self.TxtTaskDescribe.gameObject:SetActiveEx(true)
        
        self.TxtTaskName.text = taskCfg.Title
        self.TxtTaskDescribe.text = taskCfg.Desc

        -- 奖励预览
        if not XTool.IsTableEmpty(self._RewardGridDict) then
            for i, v in pairs(self._RewardGridDict) do
                v.GameObject:SetActiveEx(false)
            end
        end

        if XTool.IsNumberValid(taskCfg.RewardId) then

            if self._RewardGridDict == nil then
                self._RewardGridDict = {}
            end

            local rewardList = XRewardManager.GetRewardList(taskCfg.RewardId)

            XUiHelper.RefreshCustomizedList(self.GridCommon.transform.parent, self.GridCommon, rewardList and #rewardList or 0, function(index, go)
                local grid = self._RewardGridDict[go]

                if not grid then
                    grid = XUiGridCommon.New(self.RootUi or self.Parent, go)
                end

                grid.GameObject:SetActiveEx(true)
                grid:Refresh(rewardList[index])
            end)
        end
    end
end

--- 刷新任务进度
function XUiGridBagOrganizeTask:RefreshTaskScheduleShow()
    ---@type XTableTask
    local taskCfg = XTaskConfig.GetTaskCfgById(self.TaskData.Id)
    
    -- 进度条展示

    if XTool.GetTableCount(taskCfg.Condition) > 1 then
        -- 复合条件任务不显示进度条( 遵循旧逻辑 ） 
        self.ImgProgress.transform.parent.gameObject:SetActive(false)
        if self.TxtTaskNumQian then
            self.TxtTaskNumQian.gameObject:SetActive(false)
        end
    else
        self.ImgProgress.transform.parent.gameObject:SetActive(true)
        if self.TxtTaskNumQian then
            self.TxtTaskNumQian.gameObject:SetActive(true)
        end
        
        -- 任务目标进度
        local aimProgress = taskCfg.Result > 0 and taskCfg.Result or 1
        
        -- 任务当前进度（列表，默认读最后一个即可）
        local curPorgress = 0

        if not XTool.IsTableEmpty(self.TaskData.Schedule) then
            curPorgress = self.TaskData.Schedule[#self.TaskData.Schedule].Value

            curPorgress = curPorgress > aimProgress and aimProgress or curPorgress
        end

        self.ImgProgress.fillAmount = curPorgress / aimProgress

        if self.TxtTaskNumQian then
            self.TxtTaskNumQian.text = tostring(curPorgress)..'/'..tostring(aimProgress)
        end
    end
    
    -- 领取状态
    self.BtnFinish.gameObject:SetActiveEx(false)
    self.BtnSkip.gameObject:SetActiveEx(false)
    self.BtnReceiveHave.gameObject:SetActiveEx(false)
    self.BtnUnComplete.gameObject:SetActiveEx(false)

    if self.TaskData.State == XDataCenter.TaskManager.TaskState.Finish then
        -- 已领取奖励
        self.BtnReceiveHave.gameObject:SetActiveEx(true)
    elseif self.TaskData.State == XDataCenter.TaskManager.TaskState.Achieved then
        -- 完成任务，奖励待领取
        self.BtnFinish.gameObject:SetActiveEx(true)
    else
        if XTool.IsNumberValid(taskCfg.SkipId) then
            -- 显示“前往”
            self.BtnSkip.gameObject:SetActiveEx(true)
        else
            -- 显示未完成
            self.BtnUnComplete.gameObject:SetActiveEx(true)
        end
    end
end

--- 显示一键领取
function XUiGridBagOrganizeTask:RefreshReceiveAllShow()
    -- 隐藏其他无关UI
    self.TxtTaskName.gameObject:SetActiveEx(false)
    self.TxtTaskDescribe.gameObject:SetActiveEx(false)

    if self.Bg then
        self.Bg.gameObject:SetActiveEx(false)
    end

    if self.RImgTaskType then
        self.RImgTaskType.gameObject:SetActiveEx(false)
    end

    if not XTool.IsTableEmpty(self._RewardGridDict) then
        for i, v in pairs(self._RewardGridDict) do
            v.GameObject:SetActiveEx(false)
        end
    end
    
    self.TxtTaskName.gameObject:SetActiveEx(false)
    self.TxtTaskName.gameObject:SetActiveEx(false)

    self.ImgProgress.transform.parent.gameObject:SetActive(false)
    if self.TxtTaskNumQian then
        self.TxtTaskNumQian.gameObject:SetActive(false)
    end

    self.BtnFinish.gameObject:SetActiveEx(false)
    self.BtnSkip.gameObject:SetActiveEx(false)
    self.BtnReceiveHave.gameObject:SetActiveEx(false)
    self.BtnUnComplete.gameObject:SetActiveEx(false)
    
    -- 显示自身
    self.TaskReceive.gameObject:SetActiveEx(true)
end

--region 事件回调

function XUiGridBagOrganizeTask:OnBtnFinishClick()
    XDataCenter.TaskManager.FinishTask(self.TaskData.Id, function(rewardGoodsList)
        if not XTool.IsTableEmpty(rewardGoodsList) then
            XUiManager.OpenUiObtain(rewardGoodsList)
        end
        
        self.Parent:RefreshTaskShow()
    end)
end

function XUiGridBagOrganizeTask:OnBtnSkipClick()
    ---@type XTableTask
    local taskCfg = XTaskConfig.GetTaskCfgById(self.TaskData.Id)

    if XTool.IsNumberValid(taskCfg.SkipId) then
        if XFunctionManager.IsCanSkip(taskCfg.SkipId) then
            XFunctionManager.SkipInterface(taskCfg.SkipId)
        else
            ---@type XTableSkipFunctional
            local skipCfg = XFunctionConfig.GetSkipFuncCfg(taskCfg.SkipId)

            if skipCfg and XTool.IsNumberValid(skipCfg.FunctionalId) then
                local desc = XFunctionManager.GetFunctionOpenCondition(skipCfg.FunctionalId)
                XUiManager.TipMsg(desc)
            end
        end
    end
end

function XUiGridBagOrganizeTask:OnBtnReceiveAllClick()
    XDataCenter.TaskManager.FinishMultiTaskRequest(self.ReceiveAllTaskData.TaskIds, function(rewardGoodsList)
        if not XTool.IsTableEmpty(rewardGoodsList) then
            XUiManager.OpenUiObtain(rewardGoodsList)
        end

        self.Parent:RefreshTaskShow()
    end)
end

--endregion

return XUiGridBagOrganizeTask