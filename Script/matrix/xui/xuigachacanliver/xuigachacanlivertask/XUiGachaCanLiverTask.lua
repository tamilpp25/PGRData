local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiGachaCanLiverTask: XLuaUi
---@field _Control XGachaCanLiverControl
local XUiGachaCanLiverTask = XLuaUiManager.Register(XLuaUi, 'UiGachaCanLiverTask')

function XUiGachaCanLiverTask:OnAwake()
    self.BtnBack.CallBack = handler(self, self.Close)
    if self.BtnMainUi then
        self.BtnMainUi.CallBack = XLuaUiManager.RunMain
    end

    self.ReceiveAllBtn.CallBack = handler(self, self.OnBtnRecieveAllClick)
end

function XUiGachaCanLiverTask:OnStart()
    self:InitPanelAssets()
    self:InitDynamicTable()
    XMVCA.XGachaCanLiver:SetReddotHideByKey(XEnumConst.GachaCanLiver.ReddotKey.TaskNoEnter)
end

function XUiGachaCanLiverTask:OnEnable()
    self:Refresh()
    self:CheckAndRefreshFreeItemCanGet()
end

function XUiGachaCanLiverTask:InitPanelAssets()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, table.unpack(self._Control:GetConfigPanelAssetItemIds(XMVCA.XGachaCanLiver:GetCurActivityId())))
    self.ImgIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(self._Control:GetCurActivityFreeItemId()))
end

function XUiGachaCanLiverTask:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.SViewTask)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(require('XUi/XUiGachaCanLiver/XUiGachaCanLiverTask/XUiGridGachaCanLiverTask'), self, self, nil, nil, handler(self, self.Refresh))
end

function XUiGachaCanLiverTask:Refresh()
    --- 刷新列表
    local taskDataList = self._Control:GetCurActivityTaskIds()
    
    table.sort(taskDataList, function(a, b)
        return self:CompareState(a, b)
    end)

    if XTool.IsTableEmpty(taskDataList) then
        self.DynamicTable:RecycleAllTableGrid()
        self.ImgEmpty.gameObject:SetActiveEx(true)
    else
        self.ImgEmpty.gameObject:SetActiveEx(false)
        self.DynamicTable:SetDataSource(taskDataList)
        self.DynamicTable:ReloadDataASync()
    end
    
    -- 一键领取
    local allAchieveTaskIds = {}
    
    for _, taskData in pairs(taskDataList) do
        if taskData.State == XDataCenter.TaskManager.TaskState.Achieved then
            table.insert(allAchieveTaskIds, taskData.Id)
        end
    end

    self.ReceiveAllBtn:SetButtonState(XTool.IsTableEmpty(allAchieveTaskIds) and CS.UiButtonState.Disable or CS.UiButtonState.Normal)

    if not XTool.IsTableEmpty(allAchieveTaskIds) then
        self._AllAchieveTaskIds = allAchieveTaskIds
    end
end

function XUiGachaCanLiverTask:CheckAndRefreshFreeItemCanGet(ignoreTickOut)
    --- 刷新道具
    local leftCanGetCount = self._Control:GetLeftCanGetFreeItemCount()
    self.TxtNum.text = (leftCanGetCount <= 0) and 0 or leftCanGetCount

    if leftCanGetCount <= 0 and not ignoreTickOut then
        self:Close()
        XUiManager.TipMsg(XGachaConfigs.GetClientConfig('NoFreeItemCanGetTips'))
    end
end

function XUiGachaCanLiverTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local taskData = self.DynamicTable.DataSource[index]
        grid:Open()
        grid:ResetData(taskData)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:Close()
    end
end

function XUiGachaCanLiverTask:State2Num(taskData)
    if taskData.State == XDataCenter.TaskManager.TaskState.Achieved then
        return 4
    end
    if taskData.State == XDataCenter.TaskManager.TaskState.Finish then
        return 1
    end
    local skipId = XDataCenter.TaskManager.GetTaskTemplate(taskData.Id).SkipId

    if XTool.IsNumberValid(skipId) then
        return 3
    else
        return 2    
    end
end

function XUiGachaCanLiverTask:CompareState(taskDataA, taskDataB)
    local a = self:State2Num(taskDataA)
    local b = self:State2Num(taskDataB)

    if a == b then
        local pa, pb = XTaskConfig.GetTaskPriority(taskDataA.Id), XTaskConfig.GetTaskPriority(taskDataB.Id)

        if pa ~= pb then
            return pa > pb
        else
            return taskDataA.Id > taskDataB.Id
        end
    end
    
    return a > b
end

function XUiGachaCanLiverTask:OnBtnRecieveAllClick()
    if not XTool.IsTableEmpty(self._AllAchieveTaskIds) then
        self._Control:SetLockTickout(true)
        XDataCenter.TaskManager.FinishMultiTaskRequest(self._AllAchieveTaskIds, function(rewardGoodsList)
            self:Refresh()
            self:CheckAndRefreshFreeItemCanGet(true)
            if not XTool.IsTableEmpty(rewardGoodsList) then
                XUiManager.OpenUiObtain(rewardGoodsList, nil, function()
                    self._Control:SetLockTickout(false)
                    self:CheckAndRefreshFreeItemCanGet()
                end)
            else
                self._Control:SetLockTickout(false)    
            end
        end)
    end
end

return XUiGachaCanLiverTask