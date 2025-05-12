local XUiLineArithmeticMainStarGrid = require("XUi/XUiLineArithmetic/XUiLineArithmeticMainStarGrid")

---@class XUiLineArithmeticMainStageGrid : XUiNode
---@field _Control XLineArithmeticControl
local XUiLineArithmeticMainStageGrid = XClass(XUiNode, "XUiLineArithmeticMainStageGrid")

function XUiLineArithmeticMainStageGrid:OnStart()
    ---@type XUiLineArithmeticMainStarGrid[]
    self._GridStar = {}
    self._Data = false
    self.GridStar.gameObject:SetActiveEx(false)
    local buttonComponent = XUiHelper.TryGetComponent(self.Transform, "", "XUiButton")
    XUiHelper.RegisterClickEvent(self, buttonComponent, self.OnClick)
    --XUiHelper.RegisterClickEvent(self, self.BtnAbandon, self.OnClickAbandon)

    for i = 1, 4 do
        local ui = self["GridStar" .. i]
        local grid = XUiLineArithmeticMainStarGrid.New(ui, self)
        self._GridStar[i] = grid
    end
end

---@param data XLineArithmeticControlStageData
function XUiLineArithmeticMainStageGrid:Update(data)
    self._Data = data
    for i = 1, data.MaxStarAmount do
        local grid = self._GridStar[i]
        if not grid then
            local ui = self["GridStar" .. i]
            grid = XUiLineArithmeticMainStarGrid.New(ui, self)
            self._GridStar[i] = grid
        end
        grid:Open()
        grid:Update(i <= data.StarAmount)
    end
    for i = data.MaxStarAmount + 1, #self._GridStar do
        local grid = self._GridStar[i]
        grid:Close()
    end
    self.TxtTitle.text = data.Name
    --self.ImgBg
    self.PanelLock.gameObject:SetActiveEx(data.IsLock)
    --self.PanelOngoing.gameObject:SetActiveEx(data.IsRunning)
    self.ImgClear.gameObject:SetActiveEx(data.StarAmount == data.MaxStarAmount)
end

function XUiLineArithmeticMainStageGrid:OnClick()
    if self._Data.IsLock then
        XUiManager.TipText("LineArithmeticStageLock")
        --XUiManager.DialogTip(XUiHelper.GetText("TipTitle"), XUiHelper.GetText("LineArithmeticGoOnStage"))
        return
    end
    self._Control:OpenStageUi(self._Data.StageId)
end

--function XUiLineArithmeticMainStageGrid:OnClickAbandon()
--    self._Control:AbandonCurrentGameData()
--end

return XUiLineArithmeticMainStageGrid