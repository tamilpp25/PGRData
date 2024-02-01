local BTN_INDEX = {
    First = 1,
    Second = 2,
}
local WEEK_TASK_GROUP_ID = 2 --周期任务组Id

local tableInsert = table.insert

--肉鸽玩法任务界面
local XUiTheatreTask = XLuaUiManager.Register(XLuaUi, "UiTheatreTask")

function XUiTheatreTask:OnAwake()
    XUiHelper.NewPanelActivityAssetSafe(XDataCenter.TheatreManager.GetAssetItemIds(), self.PanelSpecialTool, self)
    self:InitDynamicTable()
    self:AddListener()
end

function XUiTheatreTask:OnStart()
    self.TaskManager = XDataCenter.TheatreManager.GetTaskManager()
    self:UpdateLeftTabBtns()
    self:CheckRedPoint()
end

function XUiTheatreTask:OnEnable()
    if self.SelectIndex then
        self.BtnTabGroup:SelectIndex(self.SelectIndex)
    end
end

function XUiTheatreTask:UpdateLeftTabBtns()
    self.TabIndexDic = {}
    self.TabBtns = {}
    local btnIndex = 0

    --一级标题
    local groupConfigs = XTheatreConfigs.GetTheatreTaskGroup()
    for id, config in pairs(groupConfigs) do
        local theatreTaskIdList = XTheatreConfigs.GetTheatreTaskIdList(id)
        local theatreTaskIdCount = #theatreTaskIdList

        local btnModel = self:GetCertainBtnModel(BTN_INDEX.First, theatreTaskIdCount > 1)
        local btn = XUiHelper.Instantiate(btnModel, self.BtnContent)
        btn.gameObject:SetActiveEx(true)
        btn:SetName(config.Name)

        local uiButton = btn:GetComponent("XUiButton")
        tableInsert(self.TabBtns, uiButton)
        btnIndex = btnIndex + 1

        --二级标题
        local firstIndex = btnIndex
        local onlyOne = theatreTaskIdCount == 1
        local needRedPoint
        for i, theatreTaskId in ipairs(theatreTaskIdList) do
            needRedPoint = XDataCenter.TheatreManager.CheckTaskStartTimeOpenByTheatreTaskId(theatreTaskId)
            if not onlyOne then
                local tmpBtnModel = self:GetCertainBtnModel(BTN_INDEX.Second, nil, i, theatreTaskIdCount)
                local tmpBtn = XUiHelper.Instantiate(tmpBtnModel, self.BtnContent)
                tmpBtn:SetName(XTheatreConfigs.GetTaskName(theatreTaskId))
                tmpBtn.gameObject:SetActiveEx(true)

                local tmpUiButton = tmpBtn:GetComponent("XUiButton")
                tmpUiButton.SubGroupIndex = firstIndex
                tableInsert(self.TabBtns, tmpUiButton)
                btnIndex = btnIndex + 1
            end

            self.TabIndexDic[btnIndex] = theatreTaskId
        end
    end

    self.BtnTabGroup:Init(self.TabBtns, function(index) self:OnSelectedTog(index) end)
    self.SelectIndex = 1
end

function XUiTheatreTask:GetCertainBtnModel(index, hasChild, pos, totalNum)
    if index == BTN_INDEX.First then
        if hasChild then
            return self.BtnFirstHasSnd
        else
            return self.BtnFirst
        end
    elseif index == BTN_INDEX.Second then
        if totalNum == 1 then
            return self.BtnSecondAll
        end

        if pos == 1 then
            return self.BtnSecondTop
        elseif pos == totalNum then
            return self.BtnSecondBottom
        else
            return self.BtnSecond
        end
    end
end

function XUiTheatreTask:OnSelectedTog(index)
    self.SelectIndex = index
    self:UpdateDynamicTable()
    self:UpdateRedPoint()
end

function XUiTheatreTask:UpdateRedPoint()
    local index = self.SelectIndex
    local theatreTaskId = self.TabIndexDic[index]
    if not theatreTaskId then
        return
    end

    local groupId = XTheatreConfigs.GetTaskGroupId(theatreTaskId)

    local uiButton = self.TabBtns[index]
    local isShowRewardRedPoint = XDataCenter.TheatreManager.CheckTaskCanRewardByTheatreTaskId(theatreTaskId)
    uiButton:ShowReddot(isShowRewardRedPoint)

    --判断一级按钮红点
    local subGroupIndex = uiButton.SubGroupIndex
    if subGroupIndex and self.TabBtns[subGroupIndex] then
        local needRed = false
        for _, btn in pairs(self.TabBtns) do
            if btn.SubGroupIndex and btn.SubGroupIndex == subGroupIndex
            and btn.ReddotObj.activeSelf then
                needRed = true
                break
            end
        end
        self.TabBtns[subGroupIndex]:ShowReddot(needRed)
    end

    --缓存一次性红点数据
    local isShowStartTimeRedPoint = XDataCenter.TheatreManager.CheckTaskStartTimeOpenByTheatreTaskId(theatreTaskId)
    local isShowWeeklyTaskRedPoint = groupId == WEEK_TASK_GROUP_ID and XDataCenter.TheatreManager.CheckWeeklyTaskRedPoint()
    if isShowStartTimeRedPoint then
        XDataCenter.TheatreManager.SaveTaskStartTimeOpenCookie(theatreTaskId)
    end
    if isShowWeeklyTaskRedPoint then
        XDataCenter.TheatreManager.SaveWeeklyTaskStartWithMonCookie()
    end
end

function XUiTheatreTask:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskStoryList)
    self.DynamicTable:SetProxy(XDynamicGridTask, self)
    self.DynamicTable:SetDelegate(self)
    self.GridTask.gameObject:SetActiveEx(false)
end

function XUiTheatreTask:UpdateDynamicTable()
    local index = self.SelectIndex
    local theatreTaskId = self.TabIndexDic[index]
    if not theatreTaskId then
        return
    end

    self.TaskDataList = self.TaskManager:GetTaskDatas(theatreTaskId)
    self.DynamicTable:SetDataSource(self.TaskDataList)
    self.DynamicTable:ReloadDataASync()
    self.PanelNoneStoryTask.gameObject:SetActiveEx(XTool.IsTableEmpty(self.TaskDataList))
end

function XUiTheatreTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local taskData = self.TaskDataList[index]
        grid:ResetData(taskData)
    end
end

function XUiTheatreTask:OnNotify(evt, ...)
    if evt == XEventId.EVENT_FINISH_TASK then
        self:UpdateDynamicTable()
        self:UpdateRedPoint()
    end
end

function XUiTheatreTask:OnGetEvents()
    return { XEventId.EVENT_FINISH_TASK }
end

function XUiTheatreTask:AddListener()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, function() XLuaUiManager.RunMain() end)
end

function XUiTheatreTask:CheckRedPoint()
    for i, tabBtn in ipairs(self.TabBtns) do
        tabBtn:ShowReddot(false)
    end

    local taskIdList
    local uiButton
    for btnIndex, theatreTaskId in pairs(self.TabIndexDic) do
        uiButton = self.TabBtns[btnIndex]
        if not uiButton then
            goto continue
        end

        if self.TaskManager:IsShowRedPoint(theatreTaskId) then
            uiButton:ShowReddot(true)

            local subGroupIndex = uiButton.SubGroupIndex 
            if subGroupIndex ~= -1 then
                uiButton = self.TabBtns[subGroupIndex]
                uiButton:ShowReddot(true)
            end
            goto continue
        end

        uiButton:ShowReddot(false)
        :: continue ::
    end
end