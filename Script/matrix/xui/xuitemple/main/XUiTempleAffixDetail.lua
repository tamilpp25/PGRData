local XUiTempleAffixDetailGrid = require("XUi/XUiTemple/Main/XUiTempleAffixDetailGrid")

---@field _Control XTempleControl
---@class XUiTempleAffixDetail:XLuaUi
local XUiTempleAffixDetail = XLuaUiManager.Register(XLuaUi, "UiTempleAffixDetail")

function XUiTempleAffixDetail:Ctor()
    ---@type XTempleGameControl
    self._GameControl = self._Control:GetGameControl()
end

function XUiTempleAffixDetail:OnStart(stageId)
    if not self._GameControl:IsGameExist() then
        self._GameControl:StartGame(stageId)
    end
end

function XUiTempleAffixDetail:OnAwake()
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self:RegisterClickEvent(self.BtnTanchuangClose, self.Close)
    self.GridRule.gameObject:SetActiveEx(false)
    self:InitDynamicTable()
end

function XUiTempleAffixDetail:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.ListAffix)
    self.DynamicTable:SetProxy(XUiTempleAffixDetailGrid, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiTempleAffixDetail:OnEnable()
    local data = self._GameControl:GetRule(true)
    for i = 1, #data do
        local rule = data[i]
        rule.Text = string.gsub(rule.Text, "FFF000", "f5b63d")
        rule.Text = string.gsub(rule.Text, "00FF09", "3da57f")
        rule.Text = string.gsub(rule.Text, "00ffff", "4e83e6")
    end
    self.DynamicTable:SetDataSource(data)
    self.DynamicTable:ReloadDataSync()
end

--动态列表事件
function XUiTempleAffixDetail:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Update(self.DynamicTable:GetData(index))
    end
end

return XUiTempleAffixDetail
