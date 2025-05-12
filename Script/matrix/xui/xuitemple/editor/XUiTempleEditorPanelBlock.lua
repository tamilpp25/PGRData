local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiTempleBattleBlockOption = require("XUi/XUiTemple/XUiTempleBattleBlockOption")
local XUiTempleEditorPanelEditBlock = require("XUi/XUiTemple/Editor/XUiTempleEditorPanelEditBlock")
local XUiTempleEditorSearchItem = require("XUi/XUiTemple/Editor/XUiTempleEditorSearchItem")

---@field _Control XTempleControl
---@class XUiTempleEditorPanelBlock:XUiNode
local XUiTempleEditorPanelBlock = XClass(XUiNode, "XUiTempleEditorPanelBlock")

function XUiTempleEditorPanelBlock:OnStart()
    ---@type XTempleGameEditorControl
    self._GameControl = self._Control:GetGameEditorControl()

    ---@type XUiTempleEditorPanelEditBlock
    self._PaneEdit = XUiTempleEditorPanelEditBlock.New(self.PanelEdit, self)

    self._Blocks = {}

    --self.PanelEdit
    XUiHelper.RegisterClickEvent(self, self.ButtonAddBlock, self.OnClickAdd)
    XUiHelper.RegisterClickEvent(self, self.ButtonDeleteBlock, self.OnClickDelete)
    XUiHelper.RegisterClickEvent(self, self.ButtonEditBlock, self.OnClickEdit)
    XUiHelper.RegisterClickEvent(self, self.ButtonClose, self.CloseEditBlock)
    XUiHelper.RegisterClickEvent(self, self.ButtonConfirm, self.OnClickConfirm)

    self.PanelOptionScore.gameObject:SetActiveEx(false)

    ---@type XUiComponent.XUiDropdown
    local uiDropdownScore = self.DropdownScore1
    uiDropdownScore:AddOptionsText({ 0, 1 })
    uiDropdownScore.onValueChanged:AddListener(function(score)
        self._GameControl:SetEditingOptionScore(score)
    end)

    ---@type XUiComponent.XUiDropdown
    local uiDropdownSpend = self.DropdownSpend
    uiDropdownSpend:AddOptionsText({ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 })
    uiDropdownSpend.onValueChanged:AddListener(function(spend)
        self._GameControl:SetEditingOptionSpend(spend)
    end)

    self:InitDynamicTable()

    ---@type UnityEngine.UI.InputField
    local inputFiled = self.InputField
    inputFiled.onValueChanged:AddListener(function(value)
        self._GameControl:SetSearchBlockName(value)
        self:Update()
    end)

    self._SearchItems = {}
end

function XUiTempleEditorPanelBlock:OnEnable()
    self:Update()
    self:UpdateSearchItem()
end

function XUiTempleEditorPanelBlock:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.ScrollView)
    self.DynamicTable:SetProxy(XUiTempleBattleBlockOption, self)
    self.DynamicTable:SetDelegate(self)
    self.BtnOptionEditor.gameObject:SetActiveEx(false)
end

function XUiTempleEditorPanelBlock:Update()
    local allBlocks = self._GameControl:GetDataOfAllBlocks()
    self.DynamicTable:SetDataSource(allBlocks)
    self.DynamicTable:ReloadDataSync()

    local data = self._GameControl:GetUiStateData()
    if data.IsEditRound then
        self.PanelOptionScore.gameObject:SetActiveEx(true)

        local option = self._GameControl:GetEditingOption()
        if option then
            ---@type XUiComponent.XUiDropdown
            local uiDropdownScore = self.DropdownScore1
            uiDropdownScore.value = option:GetIsExtraScoreValue()
            uiDropdownScore:RefreshShownValue()

            ---@type XUiComponent.XUiDropdown
            local uiDropdownSpend = self.DropdownSpend
            uiDropdownSpend.value = option:GetSpend()
            uiDropdownSpend:RefreshShownValue()
        end
    else
        self.PanelOptionScore.gameObject:SetActiveEx(false)
    end

    self.InputField.text = self._GameControl:GetSearchBlockName()
end

function XUiTempleEditorPanelBlock:UpdateSelected(selectedBlockId)
    local grids = self.DynamicTable:GetGrids()
    for _, grid in pairs(grids) do
        grid:UpdateSelected(selectedBlockId)
    end
end

function XUiTempleEditorPanelBlock:_UpdateDynamicItem(gridArray, dataArray, uiObject, class)
    if #gridArray == 0 then
        uiObject.gameObject:SetActiveEx(false)
    end
    for i = 1, #dataArray do
        local grid = gridArray[i]
        if not grid then
            local uiObject = CS.UnityEngine.Object.Instantiate(uiObject, uiObject.transform.parent)
            grid = class.New(uiObject, self)
            gridArray[i] = grid
        end
        grid:Open()
        grid:Update(dataArray[i], i)
    end
    for i = #dataArray + 1, #gridArray do
        local grid = gridArray[i]
        grid:Close()
    end
end

function XUiTempleEditorPanelBlock:CloseEditBlock()
    self._PaneEdit:Close()
    self:Update()
end

function XUiTempleEditorPanelBlock:OnClickAdd()
    self._GameControl:AddNewBlock()
    self:Update()
    self.DynamicTable:ReloadDataSync(#self.DynamicTable.DataSource)
end

function XUiTempleEditorPanelBlock:OnClickDelete()
    local index = self._GameControl:RemoveEditingBlock()
    self:Update()
    if self.DynamicTable.DataSource[index] then
        self.DynamicTable:ReloadDataSync(index)
    else
        self.DynamicTable:ReloadDataSync(#self.DynamicTable.DataSource)
    end
end

function XUiTempleEditorPanelBlock:OnClickEdit()
    if self._GameControl:GetEditingBlock() then
        self._PaneEdit:Open()
    end
end

function XUiTempleEditorPanelBlock:OnClickConfirm()
    self._GameControl:SetBlock2RoundOption()
end

function XUiTempleEditorPanelBlock:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Update(self.DynamicTable:GetData(index))
        grid:UpdateSelected(self._GameControl:GetEditingBlockId())

    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local blockData = self.DynamicTable:GetData(index)
        self._GameControl:SetSelectedEditingBlock(blockData)
        self:UpdateSelected(self._GameControl:GetEditingBlockId())
    end
end

function XUiTempleEditorPanelBlock:UpdateSearchItem()
    local data = self._GameControl:GetSearchItems()
    self:_UpdateDynamicItem(self._SearchItems, data, self.SearchItem, XUiTempleEditorSearchItem)
    for i = 1, #self._SearchItems do
        local item = self._SearchItems[i]
        XUiHelper.RegisterClickEvent(item, item.Button, function()
            local name = data[i]
            self.InputField.text = name
        end)
    end
end

function XUiTempleEditorPanelBlock:_UpdateDynamicItem(gridArray, dataArray, uiObject, class)
    if #gridArray == 0 then
        uiObject.gameObject:SetActiveEx(false)
    end
    for i = 1, #dataArray do
        local grid = gridArray[i]
        if not grid then
            local uiObject = CS.UnityEngine.Object.Instantiate(uiObject, uiObject.transform.parent)
            grid = class.New(uiObject, self)
            gridArray[i] = grid
        end
        grid:Open()
        grid:Update(dataArray[i], i)
    end
    for i = #dataArray + 1, #gridArray do
        local grid = gridArray[i]
        grid:Close()
    end
end

return XUiTempleEditorPanelBlock