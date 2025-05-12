local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridColorTableCaptain = require("XUi/XUiColorTable/Grid/XUiGridColorTableCaptain")

-- 调色战争选择领队界面
local XUiColorTableManagerChoose = XLuaUiManager.Register(XLuaUi, "UiColorTableManagerChoose")

function XUiColorTableManagerChoose:OnAwake()
    self.SelCaptainId = nil -- 当前选中的领队id

    self:SetButtonCallBack()
    self:InitTimes()
    self:InitDynamicTable()
end

function XUiColorTableManagerChoose:OnStart(captainId, cb)
    self.SelCaptainId = captainId
    self.Cb = cb
end

function XUiColorTableManagerChoose:OnEnable()
    self.Super.OnEnable(self)
    self:Refresh()
end

function XUiColorTableManagerChoose:OnDisable()
    self.Super.OnDisable(self)
end

function XUiColorTableManagerChoose:SetButtonCallBack()
    XUiHelper.RegisterClickEvent(self, self.BtnBgClose, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
end

function XUiColorTableManagerChoose:Refresh()
    self:RefreshDynamicTable()
end

function XUiColorTableManagerChoose:InitTimes()
    self:SetAutoCloseInfo(XDataCenter.ColorTableManager.GetActivityEndTime(), function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        end
    end)
end

function XUiColorTableManagerChoose:InitDynamicTable()
    self.GridCaptain.gameObject:SetActiveEx(false)
    self.DynamicTable = XDynamicTableNormal.New(self.PanelCaptainList)
    self.DynamicTable:SetProxy(XUiGridColorTableCaptain)
    self.DynamicTable:SetDelegate(self)
end

function XUiColorTableManagerChoose:RefreshDynamicTable()
    self.DataList = {}
    local config = XColorTableConfigs.GetColorTableCaptain()
    for _, cfg in ipairs(config) do
        if cfg.CanChoose == 1 then
            table.insert(self.DataList, cfg)
        end
    end
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync(1)
end

function XUiColorTableManagerChoose:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local captainCfg = self.DataList[index]
        grid:Refresh(self, captainCfg)
        grid:ShowSelected(self.SelCaptainId == captainCfg.Id)
    end
end

function XUiColorTableManagerChoose:OnBtnCaptainSelect(captainId)
    self.Cb(captainId)
    self:Close()
end