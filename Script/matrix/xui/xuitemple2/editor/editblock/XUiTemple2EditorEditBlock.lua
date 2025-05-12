local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiTemple2EditorEditBlockGrid = require("XUi/XUiTemple2/Editor/EditBlock/XUiTemple2EditorEditBlockGrid")
local XUiTemple2EditorEditBlockDetail = require("XUi/XUiTemple2/Editor/EditBlock/XUiTemple2EditorEditBlockDetail")

---@class XUiTemple2EditorEditBlock : XUiNode
---@field _Control XTemple2Control
local XUiTemple2EditorEditBlock = XClass(XUiNode, "XUiTemple2EditorEditBlock")

function XUiTemple2EditorEditBlock:OnStart()
    ---@type XUiTemple2EditorEditBlockDetail
    self._PanelEdit = XUiTemple2EditorEditBlockDetail.New(self.PanelEdit, self)
    self._PanelEdit:Close()

    self.DynamicTable = XDynamicTableNormal.New(self.ScrollView)
    self.DynamicTable:SetProxy(XUiTemple2EditorEditBlockGrid, self)
    self.DynamicTable:SetDelegate(self)
    self.BtnOptionEditor.gameObject:SetActiveEx(false)

    XUiHelper.RegisterClickEvent(self, self.ButtonAddBlock, self.OnClickAdd)
    XUiHelper.RegisterClickEvent(self, self.ButtonDeleteBlock, self.OnClickDelete)
    XUiHelper.RegisterClickEvent(self, self.ButtonEditBlock, self.OnClickEdit)

    self:InitSearch()
end

function XUiTemple2EditorEditBlock:OnEnable()
    ---@type UnityEngine.UI.InputField
    local inputFiled = self.InputField
    inputFiled.text = self._Control:GetEditorControl():GetSearchBlockName()
    self:Update()
    XEventManager.AddEventListener(XEventId.EVENT_TEMPLE2_UPDATE_EDIT_BLOCK, self.Update, self)
end

function XUiTemple2EditorEditBlock:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_TEMPLE2_UPDATE_EDIT_BLOCK, self.Update, self)
end

function XUiTemple2EditorEditBlock:Update()
    self:UpdateBlocks()
end

function XUiTemple2EditorEditBlock:UpdateBlocks()
    local dataSource = self._Control:GetEditorControl():GetUiDataBlocks()
    self.DynamicTable:SetDataSource(dataSource)
    local index = self._Control:GetEditorControl():GetIndexOfBlockBeingEdited()
    self.DynamicTable:ReloadDataSync(index)
end

function XUiTemple2EditorEditBlock:OnClickAdd()
    self._Control:GetEditorControl():AddBlock()
    self:Update()
    self.DynamicTable:ReloadDataSync(#self.DynamicTable.DataSource)
end

function XUiTemple2EditorEditBlock:OnClickDelete()
    local isSuccess, index = self._Control:GetEditorControl():DeleteBlock()
    if isSuccess then
        self:Update()
        if self.DynamicTable.DataSource[index] then
            self.DynamicTable:ReloadDataSync(index)
        else
            self.DynamicTable:ReloadDataSync(#self.DynamicTable.DataSource)
        end
    end
end

---@param grid XUiTemple2EditorEditBlockGrid
function XUiTemple2EditorEditBlock:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Update(self.DynamicTable:GetData(index))
        grid:UpdateSelected(self._Control:GetEditorControl():GetBlockBeingEdited())

    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local blockData = self.DynamicTable:GetData(index)
        self._Control:GetEditorControl():SetBlockBeingEdited(blockData.Block)
        self:UpdateSelected(self._Control:GetEditorControl():GetBlockBeingEdited())
    end
end

function XUiTemple2EditorEditBlock:UpdateSelected(selectedBlock)
    ---@type XUiTemple2EditorEditBlockGrid[]
    local grids = self.DynamicTable:GetGrids()
    for _, grid in pairs(grids) do
        grid:UpdateSelected(selectedBlock)
    end
end

function XUiTemple2EditorEditBlock:OnClickEdit()
    if self._Control:GetEditorControl():GetBlockBeingEdited() then
        self._PanelEdit:Open()
    end
end

function XUiTemple2EditorEditBlock:InitSearch()
    ---@type UnityEngine.UI.InputField
    local inputFiled = self.InputField
    inputFiled.onValueChanged:AddListener(function(value)
        self._Control:GetEditorControl():SetSearchBlockName(value)
        self:Update()
    end)

    self._SearchItems = {}
end

function XUiTemple2EditorEditBlock:UpdateSearchItem()
    local data = self._GameControl:GetSearchItems()
    
    local XUiTempleEditorSearchItem = require("XUi/XUiTemple/Editor/XUiTempleEditorSearchItem")
    self:_UpdateDynamicItem(self._SearchItems, data, self.SearchItem, XUiTempleEditorSearchItem)
    for i = 1, #self._SearchItems do
        local item = self._SearchItems[i]
        XUiHelper.RegisterClickEvent(item, item.Button, function()
            local name = data[i]
            self.InputField.text = name
        end)
    end
end

return XUiTemple2EditorEditBlock