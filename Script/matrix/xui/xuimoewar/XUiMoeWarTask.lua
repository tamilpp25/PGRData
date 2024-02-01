local XUiMoeWarTask = XLuaUiManager.Register(XLuaUi,"UiMoeWarTask")

function XUiMoeWarTask:OnStart(defaultIndex)
	self.SelectIndex = defaultIndex or 1
	self:InitUi()
end

function XUiMoeWarTask:OnEnable()
	
end

function XUiMoeWarTask:OnGetEvents()
	return {
		XEventId.EVENT_FINISH_TASK,
		XEventId.EVENT_TASK_SYNC,
		XEventId.EVENT_MOE_WAR_ACTIVITY_END,
	}
end

function XUiMoeWarTask:OnNotify(event,...)
	if event == XEventId.EVENT_FINISH_TASK
		or event == XEventId.EVENT_TASK_SYNC then
		self:RefreshTaskPanel()
	elseif event == XEventId.EVENT_MOE_WAR_ACTIVITY_END then
		XUiManager.TipText("MoeWarActivityOver")
		XLuaUiManager.RunMain()
	end
end

function XUiMoeWarTask:RefreshTaskPanel()
	for i = 1,#self.TaskDic do
		self.TaskDic[i] = XDataCenter.MoeWarManager.GetTaskListByType(i, XMoeWarConfig.GetTaskGroupId(i))
	end
	self:SetupDynamicTable()
end

function XUiMoeWarTask:InitUi()
	self.ActInfo = XDataCenter.MoeWarManager.GetActivityInfo()
	self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool, self)
	self.AssetActivityPanel:Refresh(self.ActInfo.CurrencyId)
	for i = 1,#self.ActInfo.CurrencyId do
		XDataCenter.ItemManager.AddCountUpdateListener(self.ActInfo.CurrencyId[i], function()
			self.AssetActivityPanel:Refresh(self.ActInfo.CurrencyId)
		end, self.AssetActivityPanel)
	end
	self:RegisterButtonEvent()
	self:InitDynamicTable()
	self:InitButtonGroup()
end

function XUiMoeWarTask:InitButtonGroup()
	self.TabButtons = {}
	self.TaskDic = {}
	local count = XMoeWarConfig.GetTaskGroupCount()
	for i = 1, count do
		local obj = CS.UnityEngine.Object.Instantiate(self.GridBtn, self.Content)
		local button = obj:GetComponent("XUiButton")
		button:SetName(XMoeWarConfig.GetTaskName(i))
		obj.gameObject:SetActiveEx(true)
		self.TabButtons[i] = button
		self.TaskDic[i] = XDataCenter.MoeWarManager.GetTaskListByType(i,XMoeWarConfig.GetTaskGroupId(i))
		XRedPointManager.AddRedPointEvent(self.TabButtons[i],self.CheckButtonRedPoint,self,{XRedPointConditions.Types.CONDITION_MOEWAR_TASK_TAB},i)
	end
	self.Content.gameObject:SetActiveEx(true)
	self.GridBtn.gameObject:SetActiveEx(false)
	self.ButtonGroup:Init(self.TabButtons,function(index) self:OnSelectToggle(index) end)
	self.ButtonGroup:SelectIndex(self.SelectIndex)
end

function XUiMoeWarTask:InitDynamicTable()
	self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskStoryList)
	self.DynamicTable:SetProxy(XDynamicGridTask,self,handler(self,self.BeforeFinishCheck))
	self.DynamicTable:SetDelegate(self)
end

function XUiMoeWarTask:SetupDynamicTable()
	local list = self.TaskDic[self.SelectIndex]
	if not list then
		XLog.Error("XUiMoeWarTask:SetupDynamicTable 选中的任务列表不存在,index:",self.SelectIndex)
		return
	end
	self.PanelNoneStoryTask.gameObject:SetActiveEx(#list == 0)
	self.DynamicTable:SetTotalCount(#list)
	self.DynamicTable:ReloadDataASync()
end

function XUiMoeWarTask:OnDynamicTableEvent(event, index, grid)
	if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
		grid:ResetData(self.TaskDic[self.SelectIndex][index])
	end
end

function XUiMoeWarTask:RegisterButtonEvent()
	self.BtnBack.CallBack = function()
		XLuaUiManager.Close("UiMoeWarTask")
	end
	self.BtnMainUi.CallBack = function() XLuaUiManager.RunMain()  end
end

function XUiMoeWarTask:OnSelectToggle(index)
	self.SelectIndex = index
	self:PlayAnimation("TaskStoryQieHuan")
	self:SetupDynamicTable()
end

function XUiMoeWarTask:CheckButtonRedPoint(count,index)
	self.TabButtons[index]:ShowReddot(count >= 0)
end

function XUiMoeWarTask:BeforeFinishCheck(taskData)
	local rewards = XRewardManager.GetRewardList(taskData.RewardId)
	if not rewards then return false end
	local needCheck = false
	for i = 1,#rewards do
		if rewards[i].TemplateId == XDataCenter.ItemManager.ItemId.MoeWarRespondItemId then
			needCheck = true
			break
		end
	end
	if not needCheck then return true end
	return not XDataCenter.MoeWarManager.CheckRespondItemIsMax(false)
end

return XUiMoeWarTask