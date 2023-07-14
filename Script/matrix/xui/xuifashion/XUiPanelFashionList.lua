local XUiPanelFashionList = XClass(nil, "XUiPanelFashionList")

XUiPanelFashionList.GridType = {
    FashionCharacter = 1,--成员涂装
    FashionWeapon = 2,--武器涂装
    HeadPortrait = 3,--头像
}

XUiPanelFashionList.ClassGrids = {
    [XUiPanelFashionList.GridType.FashionCharacter] = require("XUi/XUiFashion/XUiGridFashion"),
    [XUiPanelFashionList.GridType.FashionWeapon] = require("XUi/XUiFashion/XUiGridWeaponFashion"),
    [XUiPanelFashionList.GridType.HeadPortrait] = require("XUi/XUiFashion/XUiGridHeadPortrait"),
}

function XUiPanelFashionList:Ctor(type, ui, gridTouchCb, rootUi)
    self.Type = type
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.GridTouchCb = gridTouchCb
    self.RootUi = rootUi
    self:InitDynamicTable()
end

function XUiPanelFashionList:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.GameObject)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiPanelFashionList.ClassGrids[self.Type])
end

function XUiPanelFashionList:UpdateViewList(fashionList, defualtSelectId, characterId)
    self.CharacterId = characterId
    self.FashionList = fashionList
    self.LastSelectId = defualtSelectId or self.LastSelectId
    self.GridTouchCb(self.LastSelectId)
    self.DynamicTable:SetDataSource(fashionList)
    self.DynamicTable:ReloadDataSync()
end

function XUiPanelFashionList:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:PlayAnimation()
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local fashionId = self.FashionList[index]
        grid:Refresh(fashionId, self.CharacterId, self.RootUi)
        grid:PlayAnimation()
        if fashionId == self.LastSelectId then
            grid:SetSelect(true)
            self.LastSelectGrid = grid
        else
            grid:SetSelect(false)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local fashionId = self.FashionList[index]

        self.LastSelectId = fashionId
        if self.LastSelectGrid then
            self.LastSelectGrid:SetSelect(false)
        end
        self.LastSelectGrid = grid
        self.LastSelectGrid:SetSelect(true)

        self.GridTouchCb(fashionId)
    end
end

return XUiPanelFashionList