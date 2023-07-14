
local XUiSuperSmashBrosBalanceTips =XLuaUiManager.Register(XLuaUi, "UiSuperSmashBrosBalanceTips")

function XUiSuperSmashBrosBalanceTips:OnStart(data)
    self:InitDynamicTable()
    self:InitPanel()
end

function XUiSuperSmashBrosBalanceTips:InitPanel()
    self:InitBtns()
end

function XUiSuperSmashBrosBalanceTips:InitBtns()
    self.BtnTanchuangClose.CallBack = function() self:OnClickClose() end
    self.BtnClose.CallBack = function() self:OnClickClose() end
end

function XUiSuperSmashBrosBalanceTips:OnClickClose()
    self:Close()
end
--================
--初始化动态列表
--================
function XUiSuperSmashBrosBalanceTips:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.DTableWords)
    local gridProxy = require("XUi/XUiSuperSmashBros/Pick/Grids/XUiSSBBalanceTipsGrid")
    self.DynamicTable:SetProxy(gridProxy)
    self.DynamicTable:SetDelegate(self)
    if self.GridWords then self.GridWords.gameObject:SetActiveEx(false) end
end
--================
--动态列表事件
--================
function XUiSuperSmashBrosBalanceTips:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(grid.DynamicGrid.gameObject)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self.DataList and self.DataList[index] then
            grid:Refresh(self.DataList[index])
        end
    end
end

function XUiSuperSmashBrosBalanceTips:OnEnable()
    self:RefreshDTableBalanceTips()
end

function XUiSuperSmashBrosBalanceTips:RefreshDTableBalanceTips()
    self.DataList = XSuperSmashBrosConfig.GetAllConfigs(XSuperSmashBrosConfig.TableKey.BalanceTipsConfig)
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync(1)
end