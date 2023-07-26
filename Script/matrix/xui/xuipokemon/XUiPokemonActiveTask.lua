local XUiPokemonActiveTask = XLuaUiManager.Register(XLuaUi, "UiPokemonActiveTask")

function XUiPokemonActiveTask:OnStart()


    self.PanelAsset = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)

    self:InitDynamicTable()
    self:RegisterButtonClick()
    self:Refresh()
end

function XUiPokemonActiveTask:OnEnable()
    self:Refresh()
end

function XUiPokemonActiveTask:OnGetEvents()
    return {
        XEventId.EVENT_FINISH_TASK,
    }
end

function XUiPokemonActiveTask:OnNotify(event, ...)
    if event == XEventId.EVENT_FINISH_TASK then
        self:Refresh()
    end
end

function XUiPokemonActiveTask:RegisterButtonClick()
    self.BtnBack.CallBack = function()
        self:OnClickBackBtn()
    end

    self.BtnMainUi.CallBack = function()
        self:OnClickMainBtn()
    end
end

function XUiPokemonActiveTask:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.SViewTask.gameObject)
    self.DynamicTable:SetProxy(XDynamicGridTask, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiPokemonActiveTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:ResetData(self.TaskList[index])
    end
end

function XUiPokemonActiveTask:Refresh()
    self.TaskList = XDataCenter.PokemonManager.GetPokemonTimeLimitTask()
    self.DynamicTable:SetDataSource(self.TaskList)
    self.DynamicTable:ReloadDataSync()
end

function XUiPokemonActiveTask:OnClickBackBtn()
    XLuaUiManager.Close("UiPokemonActiveTask")
end

function XUiPokemonActiveTask:OnClickMainBtn()
    XLuaUiManager.RunMain()
end


return XUiPokemonActiveTask