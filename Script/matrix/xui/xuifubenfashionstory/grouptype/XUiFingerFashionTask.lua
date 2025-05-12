local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiFingerFashionTask=XLuaUiManager.Register(XLuaUi,"UiFingerFashionTask")
local XUiGridFashionStoryTask=require('XUi/XUiFubenFashionStory/GroupType/XUiGridFashionStoryTask')
--region 生命周期
function XUiFingerFashionTask:OnAwake()
    self:Init()
end

function XUiFingerFashionTask:OnStart()
    self:RefreshTasks()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    local _, endTime = XDataCenter.FashionStoryManager.GetActivityTime(XDataCenter.FashionStoryManager.GetCurrentActivityId())
    self:SetAutoCloseInfo(endTime, function(isClose) self:UpdateLeftTime(isClose) end)
end

function XUiFingerFashionTask:OnEnable()
    self:UpdateLeftTime(XDataCenter.FashionStoryManager.GetLeftTimeStamp(XDataCenter.FashionStoryManager.GetCurrentActivityId())<=0)
end
--endregion

--region 初始化

function XUiFingerFashionTask:Init()
    self.BtnBack.CallBack=function() self:Close()  end
    self.BtnMainUi.CallBack=function() XLuaUiManager.RunMain() end

    self.DynamicTable=XDynamicTableNormal.New(self.SViewTask)
    self.DynamicTable:SetProxy(XUiGridFashionStoryTask)
    self.DynamicTable:SetDelegate(self)
    
    self.GridTask.gameObject:SetActiveEx(false)
end

--endregion

--region 数据更新
function XUiFingerFashionTask:RefreshTasks()
    --获取剧情关的任务列表
    local tasks= XDataCenter.FashionStoryManager.GetCurrentAllTask(XDataCenter.FashionStoryManager.GetCurrentActivityId())
    self.Tasks=tasks
    self.DynamicTable:SetDataSource(self.Tasks)
    self.DynamicTable:ReloadDataASync()
end

function XUiFingerFashionTask:UpdateLeftTime(isClose)
    if isClose then
        XUiManager.TipText("FashionStoryActivityEnd")
        XLuaUiManager.RunMain()
    end
end
--endregion

--region 事件处理

function XUiFingerFashionTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.Tasks[index]
        grid.RootUi = self
        grid:ResetData(data)
    end
end
--endregion

return XUiFingerFashionTask