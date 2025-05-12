local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiPanelWheelchairManualTask: XUiNode
---@field _Control XWheelchairManualControl
---@field BtnReceive XUiComponent.XUiButton
local XUiPanelWheelchairManualTask = XClass(XUiNode, 'XUiPanelWheelchairManualTask')
local XUiGridWheelchairManualTask = require('XUi/XUiWheelchairManual/UiPanelWheelchairManualTask/XUiGridWheelchairManualTask')

function XUiPanelWheelchairManualTask:OnStart()
    self.DynamicTable = XDynamicTableNormal.New(self.SViewTask)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridWheelchairManualTask, self)
    
    self.BtnReceive.CallBack = handler(self, self.OnRecieveAllClick)
    self.BtnLeft.CallBack = handler(self, self.OnBtnLeftClick)
    self.BtnRight.CallBack = handler(self, self.OnBtnRightClick)

    XMVCA.XWheelchairManual:SetSubActivityIsOld(XEnumConst.WheelchairManual.ReddotKey.StepTaskNew)
end

function XUiPanelWheelchairManualTask:OnEnable()
    self:Refresh()
end

---@param soft boolean @如果为true，则当阶段没有发生改变时，不强制刷新整个列表
function XUiPanelWheelchairManualTask:Refresh(soft)
    self:RefreshLevelProgress()
    
    local hasMaxPlanWithTaskFinishable, planIndex= self._Control:GetMaxPlanWithFinishableTask()
    
    local newShowPlanIndex = hasMaxPlanWithTaskFinishable and planIndex or self._Control:GetCurActivityCurrentPlanIndex()
    
    local isPlanIndexChange = false

    if not XTool.IsNumberValid(self._CurShowPlanIndex) or self._CurShowPlanIndex ~= newShowPlanIndex then
        isPlanIndexChange = true
    end
    
    self._CurShowPlanIndex = newShowPlanIndex

    --- 如果阶段改变了，那么需要刷新新的任务，如果不限定仅阶段改变才强刷的话，也整体刷新一次
    if isPlanIndexChange or not soft then
        self:RefreshTask(self._Control:GetCurActivityPlanIdByIndex(self._CurShowPlanIndex))
    end

        
    self:RefreshPlanSWicthState()
    self:RefreshTabProgress()
end

function XUiPanelWheelchairManualTask:RefreshLevelProgress()
    self.TxtLevel.text = self._Control:GetBpLevel()
    
    local percent = 0
    local progressContent = ''

    if self._Control:CheckCurActivityBpLevelIsMax() then
        percent = 1
        progressContent = XMVCA.XWheelchairManual:GetWheelchairManualConfigString('BpLevelMaxProgressLabel')
    else
        local needExp = self._Control:GetCurBPLevelNeedExp()
        local curExp = XDataCenter.ItemManager.GetCount(XMVCA.XWheelchairManual:GetWheelchairManualConfigNum('WheelchairManualBpExp'))
        percent = XTool.IsNumberValid(needExp) and curExp/needExp or 0
        progressContent = XUiHelper.FormatText(XMVCA.XWheelchairManual:GetWheelchairManualConfigString('CommonProcessLabel'), curExp, needExp)
    end

    
    self.TxtPointNum.text = progressContent
    self.ImgProgress.fillAmount = percent
end

function XUiPanelWheelchairManualTask:RefreshTabProgress()
    local index = XMVCA.XWheelchairManual:GetCurActivityTabIndexByTabType(XEnumConst.WheelchairManual.TabType.StepTask)

    if XTool.IsNumberValid(index) and self.Parent.SetSecondTitle then
        local contentFormat = XMVCA.XWheelchairManual:GetWheelchairManualConfigString('PlanSecondTitle')
        local planId = self._Control:GetCurActivityCurrentPlanId()
        local passCount, allCount = XMVCA.XWheelchairManual:GetPlanProcess(planId)
        self.Parent:SetSecondTitle(XUiHelper.FormatText(contentFormat, self._Control:GetManualPlanName(planId), passCount, allCount), index)
    end
end

function XUiPanelWheelchairManualTask:RefreshTask(planId)
    local taskIds = self._Control:GetManualPlanRewardTaskIds(planId)
    local taskDataList = XDataCenter.TaskManager.GetTaskIdListData(taskIds)
    
    self.DynamicTable:SetDataSource(taskDataList)
    self.DynamicTable:ReloadDataASync()
end

function XUiPanelWheelchairManualTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Open()
        grid:RefreshData(self.DynamicTable.DataSource[index])
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:Close()    
    end
end

function XUiPanelWheelchairManualTask:OnRecieveAllClick()
    if self.BtnReceive.ButtonState == CS.UiButtonState.Disable then
        return
    end
   
    local canFinish, taskIds = self._Control:CheckPlanAnyTaskCanFinish()

    if canFinish then
        XDataCenter.TaskManager.FinishMultiTaskRequest(taskIds, function(rewardGoodList)
            self:Refresh()
            XUiManager.OpenUiObtain(rewardGoodList, nil, nil, nil)
            -- 领完奖要刷新下页签红点
            XEventManager.DispatchEvent(XEventId.EVENT_WHEELCHAIRMANUAL_REFRESH_TABS_REDDOT)
        end)
    end
end

function XUiPanelWheelchairManualTask:OnBtnLeftClick()
    if self._CurShowPlanIndex == 1 then
        return
    end
    
    self._CurShowPlanIndex = self._CurShowPlanIndex - 1
    local planId = self._Control:GetCurActivityPlanIdByIndex(self._CurShowPlanIndex)
    self:RefreshTask(planId)
    self:RefreshPlanSWicthState()
end

function XUiPanelWheelchairManualTask:OnBtnRightClick()
    if self._CurShowPlanIndex == self._Control:GetCurActivityPlanCount() then
        return
    elseif self._CurShowPlanIndex == self._Control:GetCurActivityCurrentPlanIndex() then
        XUiManager.TipMsg(XMVCA.XWheelchairManual:GetWheelchairManualConfigString('PlanLockTips'))
        return    
    end
    self._CurShowPlanIndex = self._CurShowPlanIndex + 1
    local planId = self._Control:GetCurActivityPlanIdByIndex(self._CurShowPlanIndex)
    self:RefreshTask(planId)
    self:RefreshPlanSWicthState()
end

function XUiPanelWheelchairManualTask:RefreshPlanSWicthState()
    local isShowLeftBtn = true
    local isShowRightBtn = true
    
    if self._CurShowPlanIndex == 1 then
        isShowLeftBtn = false
        self.BtnLeft:SetButtonState(CS.UiButtonState.Disable)
        self.BtnRight:SetButtonState(self._CurShowPlanIndex >= self._Control:GetCurActivityCurrentPlanIndex() and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
    elseif self._CurShowPlanIndex >= self._Control:GetCurActivityCurrentPlanIndex() then
        self.BtnLeft:SetButtonState(CS.UiButtonState.Normal)
        self.BtnRight:SetButtonState(CS.UiButtonState.Disable)

        if self._CurShowPlanIndex >= self._Control:GetCurActivityPlanCount() then
            isShowRightBtn = false
        end
    else
        self.BtnLeft:SetButtonState(CS.UiButtonState.Normal)
        self.BtnRight:SetButtonState(CS.UiButtonState.Normal)
    end

    self.BtnLeft.gameObject:SetActiveEx(isShowLeftBtn)
    self.BtnRight.gameObject:SetActiveEx(isShowRightBtn)
    
    self.TxtTitle.text = XUiHelper.FormatText(XMVCA.XWheelchairManual:GetWheelchairManualConfigString('PlanTitle'), self._CurShowPlanIndex)

    local canFinish, taskIds = self._Control:CheckPlanAnyTaskCanFinish()
    self.BtnReceive.gameObject:SetActiveEx(canFinish)
end

return XUiPanelWheelchairManualTask