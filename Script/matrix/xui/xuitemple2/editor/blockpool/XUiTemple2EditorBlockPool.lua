local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiTemple2EditorEditBlockGrid = require("XUi/XUiTemple2/Editor/EditBlock/XUiTemple2EditorEditBlockGrid")

---@class XUiTemple2EditorBlockPool : XUiNode
---@field _Control XTemple2Control
local XUiTemple2EditorBlockPool = XClass(XUiNode, "XUiTemple2EditorBlockPool")

function XUiTemple2EditorBlockPool:OnStart()
    self.DynamicTable = XDynamicTableNormal.New(self.ScrollView)
    self.DynamicTable:SetProxy(XUiTemple2EditorEditBlockGrid, self)
    self.DynamicTable:SetDelegate(self)
    self.BtnOptionEditor.gameObject:SetActiveEx(false)

    ---@type UnityEngine.UI.Toggle
    local toggle = self.Toggle
    toggle.onValueChanged:AddListener(function(isOn)
        local isSuccess = self._Control:GetEditorControl():SetBlockSelected4Pool(isOn)
        if isSuccess then
            self:UpdateCheckMark()
        end
    end)

    self:InitSearch()
end

function XUiTemple2EditorBlockPool:OnEnable()
    ---@type UnityEngine.UI.InputField
    local inputFiled = self.InputField
    inputFiled.text = self._Control:GetEditorControl():GetSearchBlockName()
    self:Update()
end

function XUiTemple2EditorBlockPool:Update(data)
    self:UpdateBlocks()
    self:UpdateToggle()
end

function XUiTemple2EditorBlockPool:UpdateBlocks()
    local dataSource = self._Control:GetEditorControl():GetUiDataBlockPool()
    self.DynamicTable:SetDataSource(dataSource)
    local index = self._Control:GetEditorControl():GetIndexOfBlockBeingEdited()
    self.DynamicTable:ReloadDataSync(index)
end

---@param grid XUiTemple2EditorEditBlockGrid
function XUiTemple2EditorBlockPool:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Update(self.DynamicTable:GetData(index))
        grid:UpdateSelected(self._Control:GetEditorControl():GetBlockBeingEdited())

    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local blockData = self.DynamicTable:GetData(index)
        self._Control:GetEditorControl():SetBlockBeingEdited(blockData.Block)
        self:UpdateSelected(self._Control:GetEditorControl():GetBlockBeingEdited())
        self:UpdateToggle()
    end
end

function XUiTemple2EditorBlockPool:UpdateSelected(selectedBlock)
    ---@type XUiTemple2EditorEditBlockGrid[]
    local grids = self.DynamicTable:GetGrids()
    for _, grid in pairs(grids) do
        grid:UpdateSelected(selectedBlock)
    end
end

function XUiTemple2EditorBlockPool:UpdateCheckMark()
    self._Control:GetEditorControl():GetUiDataBlockPool()

    ---@type XUiTemple2EditorEditBlockGrid[]
    local grids = self.DynamicTable:GetGrids()
    for _, grid in pairs(grids) do
        grid:UpdateToggle()
    end
end

function XUiTemple2EditorBlockPool:UpdateToggle()
    self.Toggle.isOn = self._Control:GetEditorControl():IsBlockSelectedOnPool()
end

function XUiTemple2EditorBlockPool:InitSearch()
    ---@type UnityEngine.UI.InputField
    local inputFiled = self.InputField
    inputFiled.onValueChanged:AddListener(function(value)
        self._Control:GetEditorControl():SetSearchBlockName(value)
        self:Update()
    end)

    self._SearchItems = {}
end

function XUiTemple2EditorBlockPool:UpdateSearchItem()
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

return XUiTemple2EditorBlockPool