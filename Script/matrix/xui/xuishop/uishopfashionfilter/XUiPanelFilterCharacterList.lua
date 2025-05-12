local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
--- 涂装筛选界面角色列表
---@class XUiPanelFilterCharacterList: XUiNode
local XUiPanelFilterCharacterList = XClass(XUiNode, 'XUiPanelFilterCharacterList')

local XUiGridFilterCharacter = require('XUi/XUiShop/UiShopFashionFilter/XUiGridFilterCharacter')

function XUiPanelFilterCharacterList:OnStart(defaultSelectCharacterId)
    self.GridCharacterV2P6.gameObject:SetActiveEx(false)
    self._SelectedCharacterId = defaultSelectCharacterId
    
    self.DynamicTable = XDynamicTableNormal.New(self.GameObject)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridFilterCharacter, self)
    
end

function XUiPanelFilterCharacterList:RefreshList(characterIds)
    --- 刷新时，如果之前有选择，新的列表要判断还有没有，有就照常选中，没有需要清空角色选择
    local hasOriginSelectedCharacter = false
    if not XTool.IsTableEmpty(characterIds) then
        for i, v in pairs(characterIds) do
            if self._SelectedCharacterId == v then
                hasOriginSelectedCharacter = true
                break
            end
        end
    end

    if not hasOriginSelectedCharacter then
        self._SelectedCharacterId = nil
    end
    
    self.DynamicTable:RecycleAllTableGrid()
    self.DynamicTable:SetDataSource(characterIds)
    -- 异步刷新, 会出现格子显隐状态错误的问题, 但是具体原因还没查明
    --self.DynamicTable:ReloadDataASync()
    self.DynamicTable:ReloadDataSync()
end

function XUiPanelFilterCharacterList:GetCurSelectedCharacterId()
    return self._SelectedCharacterId
end

function XUiPanelFilterCharacterList:SetAllGridRefreshSelect()
    -- 刷新格子状态
    for i = 1, self.DynamicTable.Imp.TotalCount do
        local grid = self.DynamicTable:GetGridByIndex(i)
        if grid then
            grid:RefreshSelectedState()
        end
    end
end

function XUiPanelFilterCharacterList:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Close()
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:RefreshData(self.DynamicTable.DataSource[index])
        grid:RefreshSelectedState()
        grid:Open()
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        if self._SelectedCharacterId ~= grid.Id then
            self._SelectedCharacterId = grid.Id
        else
            self._SelectedCharacterId = nil
        end
        self:SetAllGridRefreshSelect()
        self.Parent:RefreshSubmitBtnState()
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:Close()
    end
end

return XUiPanelFilterCharacterList