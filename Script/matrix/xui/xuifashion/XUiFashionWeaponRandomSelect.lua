local XUiFashionWeaponRandomSelect = XLuaUiManager.Register(XLuaUi, "UiFashionWeaponRandomSelect")

function XUiFashionWeaponRandomSelect:OnAwake()
    self:InitButton()
    self:InitDynamicTable()
end

function XUiFashionWeaponRandomSelect:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangClose, self.Close)
end

function XUiFashionWeaponRandomSelect:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.WeaponList)
    local grid = require("XUi/XUiFashion/XUiGridFashionWeaponRandomSelect")
    self.DynamicTable:SetProxy(grid, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiFashionWeaponRandomSelect:RefreshDyanamicTable(luaIndex)
    local dataList = XDataCenter.WeaponFashionManager.GetOwnWeaponFashionList(self.CharacterId)
    -- 已选择 > 默认 > id大小
    table.sort(dataList, function (idA, idB)
        local isASele = idA == self.CurBindList[self.CurSelectFashionId]
        local isBSele = idB == self.CurBindList[self.CurSelectFashionId]
        if isASele ~= isBSele then
            return isASele
        end

        local isADefault = idA == XWeaponFashionConfigs.DefaultWeaponFashionId
        local isBDefault = idB == XWeaponFashionConfigs.DefaultWeaponFashionId
        if isADefault ~= isBDefault then
            return isADefault
        end
        
        return idA > idB
    end)

    self.DynamicTable:SetDataSource(dataList)
    self.DynamicTable:ReloadDataSync((luaIndex or 0) - 1)
end

function XUiFashionWeaponRandomSelect:OnStart(characterId, curSelectFashionId, curBindList, closeCb)
    self.CharacterId = characterId
    self.CurSelectFashionId = curSelectFashionId
    self.CurBindList = curBindList
    self.CloseCb = closeCb 
end

function XUiFashionWeaponRandomSelect:OnEnable()
    self:RefreshDyanamicTable()
end

function XUiFashionWeaponRandomSelect:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local weaponFashionId = self.DynamicTable.DataSource[index]
        grid:Refresh(weaponFashionId)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local weaponFashionId = self.DynamicTable.DataSource[index]
        self:DoSelectFashionBindingWeaponFashion(weaponFashionId)
    end
end

function XUiFashionWeaponRandomSelect:DoSelectFashionBindingWeaponFashion(weaponFashionId)
    self.CurSelectWeaponFashionId = weaponFashionId
    self:Close()
end

function XUiFashionWeaponRandomSelect:OnDestroy()
    if self.CloseCb then
        self.CloseCb(self.CurSelectWeaponFashionId)
    end
end

return XUiFashionWeaponRandomSelect