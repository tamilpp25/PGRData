local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiSkyGardenCafeLibrary : XLuaUi
---@field _Control XSkyGardenCafeControl
local XUiSkyGardenCafeLibrary = XLuaUiManager.Register(XLuaUi, "UiSkyGardenCafeLibrary")

local XUiGridSGCardItem = require("XUi/XUiSkyGarden/XCafe/Grid/XUiGridSGCardItem")

function XUiSkyGardenCafeLibrary:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiSkyGardenCafeLibrary:OnStart(isAbandon)
    self._IsAbandon = isAbandon
    self:InitView()
end

function XUiSkyGardenCafeLibrary:InitUi()
    self._DynamicTable = XDynamicTableNormal.New(self.ListCard)
    self._DynamicTable:SetDelegate(self)
    self._DynamicTable:SetProxy(XUiGridSGCardItem, self)
end

function XUiSkyGardenCafeLibrary:InitCb()
    self.BtnClose.CallBack = function() 
        self:Close()
    end
end

function XUiSkyGardenCafeLibrary:InitView()
    self:SetupDynamicTable()
end

function XUiSkyGardenCafeLibrary:SetupDynamicTable()
    local dataList
    if self._IsAbandon then
        dataList = self._Control:GetBattle():GetBattleInfo():GetAbandonCards()
    else
        dataList = self._Control:GetBattle():GetRoundEntity():GetLibCardIds()
    end
    if self.TxtCount then
        self.TxtCount.text = string.format("(%d)", dataList and #dataList or 0)
    end
    self._DataList = self:SortList(dataList)
    self._DynamicTable:SetDataSource(dataList)
    self._DynamicTable:ReloadDataSync()
end

function XUiSkyGardenCafeLibrary:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:RefreshLibrary(self._DataList[index])
    end
end

function XUiSkyGardenCafeLibrary:SortList(list)
    if XTool.IsTableEmpty(list) then
        return list
    end
    table.sort(list, function(idA, idB)
        local isZeroA = idA <= 0
        local isZeroB = idB <= 0
        if isZeroA ~= isZeroB then
            return isZeroB
        end
        local pA = self._Control:GetCustomerQuality(idA)
        local pB = self._Control:GetCustomerQuality(idB)
        if pA ~= pB then
            return pA > pB
        end
        local qA = self._Control:GetCustomerPriority(idA)
        local qB = self._Control:GetCustomerPriority(idB)
        if qA ~= qB then
            return qA < qB
        end
        return idA < idB
    end)
    
    return list
end