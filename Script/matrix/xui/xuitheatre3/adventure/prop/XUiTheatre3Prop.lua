local XPanelTheatre3ItemProp = require("XUi/XUiTheatre3/Adventure/Prop/XPanelTheatre3ItemProp")
local XPanelTheatre3ItemDetail = require("XUi/XUiTheatre3/Adventure/Prop/XPanelTheatre3ItemDetail")

---@class XUiTheatre3Prop : XLuaUi
---@field _Control XTheatre3Control
local XUiTheatre3Prop = XLuaUiManager.Register(XLuaUi, "UiTheatre3Prop")

function XUiTheatre3Prop:OnAwake()
    self:AddBtnListener()
end

function XUiTheatre3Prop:OnStart()
    self:InitItemDetail()
    self:InitItemList()
end

function XUiTheatre3Prop:OnEnable()
    self:ClickPropGridByIndex(1, 1)
    self:RefreshItemList()
end

--region Ui - ItemList
function XUiTheatre3Prop:InitItemList()
    local itemList = self._Control:GetAdventureCurItemList()
    if not self.TxtTitle then
        self.TxtTitle = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/TxtTitle")
    end
    if XTool.IsTableEmpty(itemList) then
        self:_RefreshItemEmpty()
        return
    end
    self.PanelEmpty.gameObject:SetActiveEx(false)
    self.SViewlList.gameObject:SetActiveEx(true)
    self._PanelItemDetail:Open()

    ---@type number[]
    self._ItemTypeList = {}
    ---@type table<number, XTheatre3Item[]> key = itemType, value = itemList
    self._ItemIdListDir = {}
    ---@type table<number, XPanelTheatre3ItemProp>  key = itemType, value = itemUiGrid
    self._PanelItemDir = {}
    self:_InitItemListData(itemList)
    self:_InitItemPanelList()
end

---@param itemList XTheatre3Item[]
function XUiTheatre3Prop:_InitItemListData(itemList)
    for _, itemData in ipairs(itemList) do
        if self._Control:IsAdventureItemLive(itemData) then
            local itemCfg = self._Control:GetItemConfigById(itemData.ItemId)
            if not table.indexof(self._ItemTypeList, itemCfg.Type) then
                self._ItemTypeList[#self._ItemTypeList + 1] = itemCfg.Type
                self._ItemIdListDir[itemCfg.Type] = {}
            end
            table.insert(self._ItemIdListDir[itemCfg.Type], itemData)
        end
    end
    for _, itemData in pairs(self._ItemIdListDir) do
        table.sort(itemData,function(a, b) 
            local itemCfgA = self._Control:GetItemConfigById(a.ItemId)
            local itemCfgB = self._Control:GetItemConfigById(b.ItemId)
            if itemCfgA.Quality ~= itemCfgB.Quality then
                return itemCfgA.Quality > itemCfgB.Quality
            end
            return a.ItemId < b.ItemId
        end)
    end
    table.sort(self._ItemTypeList,function(a, b)
        return a < b
    end)
end

function XUiTheatre3Prop:_InitItemPanelList()
    ---@type XPanelTheatre3ItemProp[]
    self._PanelPropList = {}
    ---@type table[]
    self._PanelTitleList = {}
    if XTool.IsTableEmpty(self._ItemTypeList) then
        self:_RefreshItemEmpty()
        return
    end
    for i, _ in ipairs(self._ItemTypeList) do
        local title = XUiHelper.Instantiate(self.PanelTitle.gameObject, self.PanelTitle.transform.parent)
        local go = XUiHelper.Instantiate(self.PanelGroup.gameObject, self.PanelGroup.transform.parent)
        self._PanelTitleList[i] = XTool.InitUiObjectByUi({}, title)
        self._PanelPropList[i] = XPanelTheatre3ItemProp.New(go, self)
    end
    self.PanelTitle.gameObject:SetActiveEx(false)
    self.PanelGroup.gameObject:SetActiveEx(false)
end

function XUiTheatre3Prop:RefreshItemList()
    if XTool.IsTableEmpty(self._ItemTypeList) then
        return
    end
    for i, itemType in ipairs(self._ItemTypeList) do
        if not self._PanelPropList[i] then
            local go = XUiHelper.Instantiate(self.PanelGroup.gameObject, self.PanelGroup.transform)
            go.gameObject:SetActiveEx(true)
            self._PanelPropList[i] = XPanelTheatre3ItemProp.New(go, self)
        end
        self._PanelPropList[i]:Refresh(self._ItemIdListDir[itemType], handler(self, self.OnSelectItem))
        if self._PanelTitleList[i].TxtTitle then
            self._PanelTitleList[i].TxtTitle.text = self._Control:GetItemTypeName(itemType)
        end
        if self._DefaultPanelIndex == i then
            self:OnSelectItem(self._PanelPropList[i]:GetItemGrid(self._DefaultItemIndex))
        end
    end
end

function XUiTheatre3Prop:_RefreshItemEmpty()
    self.PanelEmpty.gameObject:SetActiveEx(true)
    self.SViewlList.gameObject:SetActiveEx(false)
    if self.TxtTitle then
        self.TxtTitle.gameObject:SetActiveEx(false)
    end
    self._PanelItemDetail:Close()
end
--endregion

--region Ui - GridProp
function XUiTheatre3Prop:CheckCurTypeIsProp()
    return true
end

function XUiTheatre3Prop:CheckCurTypeIsSet()
    return false
end
--endregion

--region Ui - ItemSelect
---@param grid XUiGridTheatre3Reward
function XUiTheatre3Prop:OnSelectItem(grid)
    if self._CurSelectGrid and self._CurSelectGrid == grid then
        return
    else
        self._CurSelectGrid = grid
    end
    for _, panelGrid in pairs(self._PanelPropList) do
        panelGrid:RefreshSelect(self._CurSelectGrid)
    end
    self:RefreshItemDetail()
    self:PlayAnimationWithMask("QieHuan")
end

function XUiTheatre3Prop:ClickPropGridByIndex(panelIndex, itemIndex)
    self._DefaultPanelIndex = panelIndex
    self._DefaultItemIndex = itemIndex
end
--endregion

--region Ui - ItemDetail
function XUiTheatre3Prop:InitItemDetail()
    ---@type XPanelTheatre3ItemDetail
    self._PanelItemDetail = XPanelTheatre3ItemDetail.New(self.PanelDetail, self)
end

function XUiTheatre3Prop:RefreshItemDetail()
    if not self._CurSelectGrid then
        self._PanelItemDetail:Close()
        return
    end
    self._PanelItemDetail:Open()
    self._PanelItemDetail:Refresh(self._CurSelectGrid:GetItemData())
end
--endregion

--region Ui - BtnListener
function XUiTheatre3Prop:AddBtnListener()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
end

function XUiTheatre3Prop:OnBtnBackClick()
    self:Close()
end
--endregion

return XUiTheatre3Prop