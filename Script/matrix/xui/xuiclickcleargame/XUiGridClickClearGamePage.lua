local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local textManager = CS.XTextManager
local tableInsert = table.insert

local XUiGridClickClearGameHead = require("XUi/XUiClickClearGame/XUiGridClickClearGameHead")

local XUiGridClickClearGamePage = XClass(nil, "XUiGridClickClearGamePage")

function XUiGridClickClearGamePage:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiGridClickClearGamePage:Init(rootUi)
    self.rootUi = rootUi
    self:InitDynamicTable()
end

function XUiGridClickClearGamePage:Refresh(index)
    self.RealIndex = XDataCenter.XClickClearGameManager.CalcRealIndex(index)
    local gameInfo = XDataCenter.XClickClearGameManager.GetGameInfo()
    self.HeadList = gameInfo.HeadInfoPageList[self.RealIndex]
    self.DynamicTable:SetDataSource(self.HeadList)
    self.DynamicTable:ReloadDataASync()
end

function XUiGridClickClearGamePage:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.GameObject)
    self.DynamicTable:SetProxy(XUiGridClickClearGameHead)
    self.DynamicTable:SetDelegate(self)
end

function XUiGridClickClearGamePage:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.HeadList[index]
        local realIndex = self.RealIndex
        grid:Refresh(data, realIndex, index)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        grid:OnClick(index)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:OnRecycle()
    end
end

return XUiGridClickClearGamePage