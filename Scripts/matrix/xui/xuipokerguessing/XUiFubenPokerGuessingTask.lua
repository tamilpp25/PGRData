local XUiFubenPokerGuessingTask = XLuaUiManager.Register(XLuaUi, "UiFubenPokerGuessingTask")

function XUiFubenPokerGuessingTask:OnStart()


    self.PanelAsset = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.TxtTime.text = ""
    self:InitDynamicTable()
    self:RegisterButtonClick()
    self:Refresh()

    local endTime = XDataCenter.PokerGuessingManager.GetEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            XDataCenter.PokerGuessingManager.OnActivityEnd()
            return
        end 
    end)
end

function XUiFubenPokerGuessingTask:OnEnable()
    self:Refresh()
end

function XUiFubenPokerGuessingTask:OnGetEvents()
    return {
        XEventId.EVENT_FINISH_TASK,
        XEventId.EVENT_TASK_SYNC
    }
end

function XUiFubenPokerGuessingTask:OnNotify(event, ...)
    if event == XEventId.EVENT_FINISH_TASK or event == XEventId.EVENT_TASK_SYNC then
        self:Refresh()
    end
end

function XUiFubenPokerGuessingTask:RegisterButtonClick()
    self.BtnBack.CallBack = function()
        self:OnClickBackBtn()
    end

    self.BtnMainUi.CallBack = function()
        self:OnClickMainBtn()
    end
end

function XUiFubenPokerGuessingTask:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.SViewTask.gameObject)
    self.DynamicTable:SetProxy(XDynamicGridTask, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiFubenPokerGuessingTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:ResetData(self.TaskList[index])
    end
end

function XUiFubenPokerGuessingTask:Refresh()
    self.TaskList = XDataCenter.TaskManager.GetPokerGuessingTaskList()
    self.DynamicTable:SetDataSource(self.TaskList)
    self.DynamicTable:ReloadDataSync()
end

function XUiFubenPokerGuessingTask:OnClickBackBtn()
    self:Close()
end

function XUiFubenPokerGuessingTask:OnClickMainBtn()
    XLuaUiManager.RunMain()
end


return XUiFubenPokerGuessingTask