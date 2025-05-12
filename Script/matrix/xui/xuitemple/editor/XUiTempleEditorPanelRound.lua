local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiTempleEditorGridRound = require("XUi/XUiTemple/Editor/XUiTempleEditorGridRound")

---@field _Control XTempleControl
---@class XUiTempleEditorPanelRound:XUiNode
local XUiTempleEditorPanelRound = XClass(XUiNode, "XUiTempleEditorPanelRound")

function XUiTempleEditorPanelRound:OnStart()
    ---@type XTempleGameEditorControl
    self._EditorControl = self._Control:GetGameEditorControl()
    XUiHelper.RegisterClickEvent(self, self.ButtonAddOption, self.OnClickAddOption)
    XUiHelper.RegisterClickEvent(self, self.ButtonAddRound, self.OnClickAddRound)
    XUiHelper.RegisterClickEvent(self, self.ButtonDeleteRound, self.OnClickRemoveRound)

    for i = 2, 3 do
        self:SetOptionButtonClick(i)
    end

    ---@type UnityEngine.UI.Toggle
    local toggle = self.Toggle1
    toggle.onValueChanged:AddListener(function(isOn)
        self._EditorControl:SetSkipOption(isOn)
        self:UpdateToggle()
    end)

    self:InitDynamicTable()
end

function XUiTempleEditorPanelRound:OnEnable()
    self:Update()
    XEventManager.AddEventListener(XEventId.EVENT_TEMPLE_UPDATE_GAME, self.Update, self)
end

function XUiTempleEditorPanelRound:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_TEMPLE_UPDATE_GAME, self.Update, self)
end

function XUiTempleEditorPanelRound:UpdateToggle()
    ---@type UnityEngine.UI.Toggle
    local toggle = self.Toggle1
    toggle.isOn = self._EditorControl:IsShowSkip()
end

function XUiTempleEditorPanelRound:UpdateRoundList()
    local roundList = self._EditorControl:GetDataRoundList()
    self.DynamicTable:SetDataSource(roundList)
    self.DynamicTable:ReloadDataSync()
end

function XUiTempleEditorPanelRound:Update()
    self:UpdateRoundList()
    self:UpdateToggle()
    self:UpdateSelected()
    self:UpdateTotalRound()
end

function XUiTempleEditorPanelRound:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.RoundList)
    self.DynamicTable:SetProxy(XUiTempleEditorGridRound, self)
    self.DynamicTable:SetDelegate(self)
    self.GridAction.gameObject:SetActiveEx(false)
end

function XUiTempleEditorPanelRound:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Update(self.DynamicTable:GetData(index))
        local selected = self._EditorControl:GetEditingRound()
        grid:UpdateSelected(selected)
    end
end

function XUiTempleEditorPanelRound:UpdateSelected()
    local selected = self._EditorControl:GetEditingRound()
    local grids = self.DynamicTable:GetGrids()
    for i, grid in pairs(grids) do
        grid:UpdateSelected(selected)
    end
end

function XUiTempleEditorPanelRound:OnClickAddRound()
    self._EditorControl:AddNewRound()
end

function XUiTempleEditorPanelRound:OnClickRemoveRound()
    self._EditorControl:RemoveRound()
end

function XUiTempleEditorPanelRound:OnClickAddOption()
    self._EditorControl:AddNewOption()
end

function XUiTempleEditorPanelRound:SetOptionButtonClick(index)

    local editButton = self["ButtonEditOption" .. index]
    XUiHelper.RegisterClickEvent(self, editButton, function()
        self._EditorControl:SetEditingBlockFromOption(index - 1)
    end)

    local deleteButton = self["ButtonDeleteOption" .. index]
    XUiHelper.RegisterClickEvent(self, deleteButton, function()
        self._EditorControl:RemoveOption(index - 1)
    end)
end

function XUiTempleEditorPanelRound:UpdateTotalRound()
    self.TextRoundAmount.text = self._EditorControl:GetTotalRound()
end

return XUiTempleEditorPanelRound