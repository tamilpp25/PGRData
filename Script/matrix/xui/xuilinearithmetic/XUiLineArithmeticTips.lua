local XUiLineArithmeticGameGrid = require("XUi/XUiLineArithmetic/XUiLineArithmeticGameGrid")

---@class XUiLineArithmeticTips : XLuaUi
---@field _Control XLineArithmeticControl
local XUiLineArithmeticTips = XLuaUiManager.Register(XLuaUi, "UiLineArithmeticTips")

function XUiLineArithmeticTips:OnAwake()
    self:BindExitBtns(self.BtnTanchuangCloseBig)
    self._Timer = false

    ---@type XUiLineArithmeticGameGrid[]
    self._UiGrids = {}

    self._UiLines = {}

    self.BtnGrid.gameObject:SetActiveEx(false)
    self.GridLine.gameObject:SetActiveEx(false)
end

function XUiLineArithmeticTips:OnStart()
    self:UpdateEmptyGrid()
end

function XUiLineArithmeticTips:OnEnable()
    self.TxtSpeak.text = XUiHelper.GetText("LineArithmeticHelpText")
    if not self._Timer then
        self._Timer = XScheduleManager.ScheduleForever(function()
            self:Update()
        end, 0)
    end
    self._Control:StartHelpGame()
    self:UpdateMap()
end

function XUiLineArithmeticTips:OnDisable()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
end

function XUiLineArithmeticTips:Update()
    if self._Control:UpdateHelpGame() then
        self:UpdateMap()
    end
end

function XUiLineArithmeticTips:UpdateMap()
    self._Control:UpdateHelpMap()
    local uiData = self._Control:GetUiData()

    -- 画格子
    local map = uiData.HelpMapData
    if not map then
        return
    end
    for i = 1, #map do
        local dataGrid = map[i]
        local uiGrid = self._UiGrids[i]
        if not uiGrid then
            local ui = CS.UnityEngine.Object.Instantiate(self.BtnGrid, self.BtnGrid.transform.parent)
            uiGrid = XUiLineArithmeticGameGrid.New(ui, self)
            self._UiGrids[i] = uiGrid
        end
        uiGrid:Update(dataGrid)
        uiGrid:Open()
    end
    for i = #map + 1, #self._UiGrids do
        local uiGrid = self._UiGrids[i]
        uiGrid:Close()
    end
    self:UpdateLine()
end

function XUiLineArithmeticTips:UpdateLine()
    self._Control:UpdateHelpLine()
    local uiData = self._Control:GetUiData()

    -- 画线
    local line = uiData.HelpLineData
    if not line then
        return
    end
    for i = 1, #line do
        local dataLine = line[i]
        local uiLine = self._UiLines[i]
        if not uiLine then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridLine, self.GridLine.transform.parent)
            uiLine = ui
            self._UiLines[i] = uiLine
        end
        uiLine.gameObject:SetActiveEx(true)
        local x = dataLine.X
        local y = dataLine.Y
        local rotation = dataLine.Rotation
        ---@type UnityEngine.RectTransform
        local rectTransform = uiLine
        rectTransform.localPosition = Vector3(x, y, 0)
        rectTransform.localEulerAngles = Vector3(0, 0, rotation)
    end
    for i = #line + 1, #self._UiLines do
        local uiLine = self._UiLines[i]
        uiLine.gameObject:SetActiveEx(false)
    end
end

function XUiLineArithmeticTips:UpdateEmptyGrid()
    self._Control:UpdateEmptyData()
    local emptyData = self._Control:GetUiData().MapEmptyData
    XUiHelper.RefreshCustomizedList(self.PanelEmpty.transform, self.GridEmpty, #emptyData, function(index, grid)
        local data = emptyData[index]
        grid.transform.localPosition = Vector3(data.X, data.Y, 0)
    end)
end

return XUiLineArithmeticTips