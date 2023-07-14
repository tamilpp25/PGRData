local XUiCoupletAward = XLuaUiManager.Register(XLuaUi, "UiCoupletAward")

local XUiGridCoupletTask = require("XUi/XUiCoupletGame/XUiGridCoupletTask")

function XUiCoupletAward:OnAwake()

end

function XUiCoupletAward:OnStart()
    self:AutoRegisterBtn()
    self:InitDynamicTable()
end

function XUiCoupletAward:OnEnable()
    self:UpdateDynamicTable()
end

function XUiCoupletAward:OnDisable()
    
end

function XUiCoupletAward:OnDestroy()
    
end

function XUiCoupletAward:OnGetEvents()
    return {
        XEventId.EVENT_COUPLET_GAME_FINISH_TASK
    }
end

function XUiCoupletAward:OnNotify(evt, ...)
   if evt == XEventId.EVENT_COUPLET_GAME_FINISH_TASK then
        self:UpdateDynamicTable()
   end
end

function XUiCoupletAward:AutoRegisterBtn()
    self.BtnTanchuangClose.CallBack = function() self:Close() end
    self.BtnTreasureBg.CallBack = function() self:Close() end
end

function XUiCoupletAward:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTreasureGrade)
    self.DynamicTable:SetProxy(XUiGridCoupletTask)
    self.DynamicTable:SetDelegate(self)
end

function XUiCoupletAward:UpdateDynamicTable()
    self.TaskList = XDataCenter.CoupletGameManager.GetRewardTaskDatas()
    self.DynamicTable:SetDataSource(self.TaskList)
    self.DynamicTable:ReloadDataSync()
end

function XUiCoupletAward:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateGrid(self.TaskList[index])
    end
end