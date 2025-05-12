local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiFubenMaintaineractionRecording = XLuaUiManager.Register(XLuaUi, "UiFubenMaintaineractionRecording")
local XUiGridRecord = require("XUi/XUiMaintainerAction/XUiGridRecord")
local CSTextManagerGetText = CS.XTextManager.GetText

function XUiFubenMaintaineractionRecording:OnStart()
    self:InitDynamicTable()
    self:SetButtonCallBack()
end

function XUiFubenMaintaineractionRecording:OnEnable()
    self:SetupDynamicTable()
end

function XUiFubenMaintaineractionRecording:SetButtonCallBack()
    self.BtnClose.CallBack = function()
        self:Close()
    end
end

function XUiFubenMaintaineractionRecording:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelRecordingScroll)
    self.DynamicTable:SetProxy(XUiGridRecord)
    self.GridRecording.gameObject:SetActiveEx(false)
    self.DynamicTable:SetDelegate(self)
end

function XUiFubenMaintaineractionRecording:SetupDynamicTable()
    self.PageDatas = XDataCenter.MaintainerActionManager.GetRecordData()
    self.DynamicTable:SetDataSource(self.PageDatas)
    self.DynamicTable:ReloadDataSync(#self.PageDatas)
end

function XUiFubenMaintaineractionRecording:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateGrid(self.PageDatas[index], self)
    end
end