local XUiTempleEditorOperation = require("XUi/XUiTemple/Editor/XUiTempleEditorOperation")
local XUiTempleEditorPanelRuleTipsGrid = require("XUi/XUiTemple/Editor/XUiTempleEditorPanelRuleTipsGrid")

---@field _Control XTempleControl
---@class XUiTempleEditorPanelRuleTips:XUiNode
local XUiTempleEditorPanelRuleTips = XClass(XUiNode, "XUiTempleEditorPanelRuleTips")

function XUiTempleEditorPanelRuleTips:OnStart()
    ---@type XTempleGameEditorControl
    self._GameControl = self._Control:GetGameEditorControl()

    ---@type XUiTempleEditorOperation
    self._Operation = XUiTempleEditorOperation.New(self.PanelOperation, self)
    self._Operation:Open()

    self.DynamicTable = XDynamicTableNormal.New(self.RoundList)
    self.DynamicTable:SetProxy(XUiTempleEditorPanelRuleTipsGrid, self)
    self.DynamicTable:SetDelegate(self)
    self.GridAction.gameObject:SetActiveEx(false)

    local rules = self._GameControl:GetRules()
    self.DynamicTable:SetDataSource(rules)
    self.DynamicTable:ReloadDataSync()
end

function XUiTempleEditorPanelRuleTips:OnEnable()
    if not self._GameControl:IsSetTipsEditingRule() then
        self._GameControl:SetTipsEditingRule(self.DynamicTable:GetData(1))
    end
    self:Update()
    XEventManager.AddEventListener(XEventId.EVENT_TEMPLE_UPDATE_EDITING_RULE_TIPS, self.Update, self)
end

function XUiTempleEditorPanelRuleTips:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_TEMPLE_UPDATE_EDITING_RULE_TIPS, self.Update, self)
end

function XUiTempleEditorPanelRuleTips:Update()
    local data = self._GameControl:GetDataRuleTips()
    self.TextRule.text = data.TextRule
    for _, grid in pairs(self.DynamicTable:GetGrids()) do
        grid:UpdateSelected()
    end

    local block = self._GameControl:GetRuleTipsBlock()
    self._Operation:SetBlock(block)
end

function XUiTempleEditorPanelRuleTips:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Update(self.DynamicTable:GetData(index))
    end
end

return XUiTempleEditorPanelRuleTips
