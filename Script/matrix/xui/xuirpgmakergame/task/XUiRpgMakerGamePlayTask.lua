local XUiRpgMakerGamePlayTask = XLuaUiManager.Register(XLuaUi, "UiRpgMakerGamePlayTask")

function XUiRpgMakerGamePlayTask:OnAwake()
    self:AutoAddListener()
end

function XUiRpgMakerGamePlayTask:OnStart()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)

    self.GridTask.gameObject:SetActive(false)

    self.DynamicTable = XDynamicTableNormal.New(self.SViewTask.transform)
    self.DynamicTable:SetProxy(XDynamicGridTask)
    self.DynamicTable:SetDelegate(self)
end

function XUiRpgMakerGamePlayTask:OnEnable()
    self:Refresh()
end

function XUiRpgMakerGamePlayTask:OnGetEvents()
    return {
        XEventId.EVENT_FINISH_TASK,
        XEventId.EVENT_TASK_SYNC,
        XEventId.EVENT_RPG_MAKER_GAME_ACTIVITY_END,
    }
end

function XUiRpgMakerGamePlayTask:OnNotify(event)
    if event == XEventId.EVENT_FINISH_TASK
        or event == XEventId.EVENT_TASK_SYNC then
        self:Refresh()
    elseif event == XEventId.EVENT_RPG_MAKER_GAME_ACTIVITY_END then
        XUiManager.TipText("ActivityAlreadyOver")
        XLuaUiManager.RunMain()
    end
end

function XUiRpgMakerGamePlayTask:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
end

function XUiRpgMakerGamePlayTask:OnBtnBackClick()
    self:Close()
end

function XUiRpgMakerGamePlayTask:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

--动态列表事件
function XUiRpgMakerGamePlayTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.Tasks[index]
        grid.RootUi = self
        grid:ResetData(data)
    end
end

function XUiRpgMakerGamePlayTask:Refresh()
    if not self.GameObject:Exist() then
        return
    end

    self.Tasks = XDataCenter.RpgMakerGameManager.GetTimeLimitTask()
    self.DynamicTable:SetDataSource(self.Tasks)
    self.DynamicTable:ReloadDataASync()
end