local XUiGridTactics = require("XUi/XUiEscape/Tactics/XUiGridTactics")

---@class XUiPanelTactics
local XUiPanelTactics = XClass(nil, "XUiPanelTactics")

function XUiPanelTactics:Ctor(ui, escapeData)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XUiHelper.InitUiClass(self, ui)
    
    ---@type XUiGridTactics[]
    self._GridTacticsList = {}
    
    -- 因为结算的escapeData是Copy的
    if escapeData then
        self._EscapeData = escapeData
    else
        self._EscapeData = XDataCenter.EscapeManager.GetEscapeData()
    end
    self.Grid100.gameObject:SetActiveEx(false)
end

function XUiPanelTactics:Refresh()
    local tacticsList = self._EscapeData:GetCurSelectTactics()
    self:UpdateTactics(tacticsList)
    self:UpdateTacticsGrid(tacticsList)
end

---@param tacticsList XUiGridTactics[]
function XUiPanelTactics:UpdateTactics(tacticsList)
    if XTool.IsTableEmpty(tacticsList) then
        return
    end
    for i, tactics in ipairs(tacticsList) do
        if not self._GridTacticsList[i] then
            self._GridTacticsList[i] = XUiGridTactics.New(XUiHelper.Instantiate(self.Grid100.gameObject, self.PanelTacticsList.transform))
        end
        self._GridTacticsList[i]:Refresh(tactics)
        self._GridTacticsList[i]:SetActive(true)
    end
end

---@param tacticsList XUiGridTactics[]
function XUiPanelTactics:UpdateTacticsGrid(tacticsList)
    for i = #tacticsList+1, #self._GridTacticsList do
        self._GridTacticsList[i]:SetActive(false)
    end
end

return XUiPanelTactics