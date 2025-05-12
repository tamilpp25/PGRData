local XDynamicGridTask = require("XUi/XUiTask/XDynamicGridTask")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
--肉鸽玩法二期任务界面
local XUiBiancaTheatreTask = XLuaUiManager.Register(XLuaUi, "UiBiancaTheatreTask")

function XUiBiancaTheatreTask:OnAwake()
    XUiHelper.NewPanelActivityAssetSafe(XDataCenter.BiancaTheatreManager.GetAssetItemIds(), self.PanelSpecialTool, self, nil, handler(self, self.OnBtnClick))
    self:InitDynamicTable()
    self:AddListener()
end

function XUiBiancaTheatreTask:OnStart()
    self.TaskManager = XDataCenter.BiancaTheatreManager.GetTaskManager()
    self:InitLeftTabBtns()
end

function XUiBiancaTheatreTask:OnEnable()
    if self.SelectIndex then
        self.BtnTabGroup:SelectIndex(self.SelectIndex)
    end
end

function XUiBiancaTheatreTask:OnDisable()
end

function XUiBiancaTheatreTask:InitLeftTabBtns()
    self.BtnTask.gameObject:SetActiveEx(false)

    self.TabBtns = {}
    local theatreTaskIdList = XBiancaTheatreConfigs.GetTheatreTaskIdList()
    for index, id in ipairs(theatreTaskIdList) do
        local tabBtn = index == 1 and self.BtnTask or XUiHelper.Instantiate(self.BtnTask, self.BtnContent)
        tabBtn:SetName(XBiancaTheatreConfigs.GetTaskName(id))
        tabBtn.gameObject:SetActiveEx(true)
        table.insert(self.TabBtns, tabBtn)
    end

    self.BtnTabGroup:Init(self.TabBtns, function(index) self:OnSelectedTog(index) end)
    self.SelectIndex = 1
end

function XUiBiancaTheatreTask:OnSelectedTog(index)
    self.SelectIndex = index
    self:PlayAnimation("QieHuan")
    self:UpdateDynamicTable()
    self:UpdateRedPoint()
end

function XUiBiancaTheatreTask:UpdateRedPoint()
    local theatreTaskIdList = XBiancaTheatreConfigs.GetTheatreTaskIdList()
    local isShowRewardRedPoint
    for index, id in ipairs(theatreTaskIdList) do
        isShowRewardRedPoint = XDataCenter.BiancaTheatreManager.CheckTaskCanRewardByTheatreTaskId(id)
        self.TabBtns[index]:ShowReddot(isShowRewardRedPoint)
    end
end

function XUiBiancaTheatreTask:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskStoryList)
    self.DynamicTable:SetProxy(XDynamicGridTask, self, nil, handler(self, self.OnClickTaskGrid))
    self.DynamicTable:SetDelegate(self)
    self.GridTask.gameObject:SetActiveEx(false)
end

function XUiBiancaTheatreTask:UpdateDynamicTable()
    local index = self.SelectIndex
    local theatreTaskIdList = XBiancaTheatreConfigs.GetTheatreTaskIdList()
    local theatreTaskId = theatreTaskIdList[index]
    if not theatreTaskId then
        return
    end

    self.TaskDataList = self.TaskManager:GetTaskDatas(theatreTaskId)
    self.DynamicTable:SetDataSource(self.TaskDataList)
    self.DynamicTable:ReloadDataASync()
    self.PanelNoneStoryTask.gameObject:SetActiveEx(XTool.IsTableEmpty(self.TaskDataList))
end

function XUiBiancaTheatreTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local taskData = self.TaskDataList[index]
        local gridTemp = grid
        gridTemp:ResetData(taskData)
        gridTemp.BtnFinish.CallBack = function() self:OnBtnFinishClick(gridTemp) end
    end
end

function XUiBiancaTheatreTask:OnNotify(evt, ...)
    if evt == XEventId.EVENT_FINISH_TASK then
        self:UpdateDynamicTable()
        self:UpdateRedPoint()
    end
end

function XUiBiancaTheatreTask:OnGetEvents()
    return { XEventId.EVENT_FINISH_TASK }
end

function XUiBiancaTheatreTask:AddListener()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, function() XDataCenter.BiancaTheatreManager.RunMain() end)
end

--货币点击方法
function XUiBiancaTheatreTask:OnBtnClick(index)
    XLuaUiManager.Open("UiBiancaTheatreTips", XBiancaTheatreConfigs.TheatreOutCoin)
end

function XUiBiancaTheatreTask:OnClickTaskGrid(reward)
    XLuaUiManager.Open("UiBiancaTheatreTips", reward)
end

function XUiBiancaTheatreTask:OnBtnFinishClick(taskGrid)
    if taskGrid.BeforeFinishCheckEvent then
        if not taskGrid.BeforeFinishCheckEvent(taskGrid.tableData) then
            return
        end
    end
    local weaponCount = 0
    local chipCount = 0
    local isHaveTheatreExp = false
    local rewards = XRewardManager.GetRewardList(taskGrid.tableData.RewardId)
    for i = 1, #rewards do
        local rewardsId = taskGrid.RewardPanelList[i].TemplateId
        if XMVCA.XEquip:IsClassifyEqualByTemplateId(rewardsId, XEnumConst.EQUIP.CLASSIFY.WEAPON) then
            weaponCount = weaponCount + 1
        elseif XMVCA.XEquip:IsClassifyEqualByTemplateId(rewardsId, XEnumConst.EQUIP.CLASSIFY.AWARENESS) then
            chipCount = chipCount + 1
        end

        if rewards[i].TemplateId == XBiancaTheatreConfigs.TheatreExp then
            isHaveTheatreExp = true
        end
    end
    if weaponCount > 0 and XMVCA.XEquip:CheckBagCount(weaponCount, XEnumConst.EQUIP.CLASSIFY.WEAPON) == false or
            chipCount > 0 and XMVCA.XEquip:CheckBagCount(chipCount, XEnumConst.EQUIP.CLASSIFY.AWARENESS) == false then
        return
    end
    --领取的任务奖励存在经验，且当前的奖励等级满级时二次弹窗确认
    local finishTaskFunc = function()
        XDataCenter.TaskManager.FinishTask(taskGrid.Data.Id, function(rewardGoodsList)
            XLuaUiManager.Open("UiBiancaTheatreTipReward", nil, rewardGoodsList)
        end)
    end
    if XDataCenter.BiancaTheatreManager.GetCurRewardLevel() >= XBiancaTheatreConfigs.GetMaxRewardLevel() and isHaveTheatreExp then
        local title = XUiHelper.GetText("TipTitle")
        local content = XBiancaTheatreConfigs.GetClientConfig("ReceiveExpTipsContent")
        XLuaUiManager.Open("UiBiancaTheatreEndTips", title, content, XUiManager.DialogType.Normal, nil, finishTaskFunc)
    else
        finishTaskFunc()
    end
end