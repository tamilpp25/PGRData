local XTemple2Enum = require("XModule/XTemple2/XTemple2Enum")
local XUiTemple2CheckBoardGrid = require("XUi/XUiTemple2/Game/XUiTemple2CheckBoardGrid")

---@class XUiTemple2GameBlockGridOption : XUiNode
---@field _Control XTemple2Control
local XUiTemple2GameBlockGridOption = XClass(XUiNode, "XUiTemple2GameBlockGridOption")

function XUiTemple2GameBlockGridOption:OnStart()
    ---@type XUiTemple2CheckBoardGrid[]
    self._Grids = {}

    --指引下 点击就触发操作地块
    if XDataCenter.GuideManager.CheckIsInGuide() then
        local button = self.Transform:GetComponent("XUiButton")
        if button then
            XUiHelper.RegisterClickEvent(self, button, self.OnClickOnGuide)
        end
    end

    self._Data = false
    self:AddListenerInput()

    self.PanelSelect = self.PanelSelect or XUiHelper.TryGetComponent(self.Transform, "PanelSelect", "RectTransform")
    self.ImgColor0 = self.ImgColor0 or XUiHelper.TryGetComponent(self.Transform, "ImgColor0", "RectTransform")
end

---@param block XTemple2Block
function XUiTemple2GameBlockGridOption:Update(block)
    self._Data = block
    ---@type XUiTemple2CheckBoardGridData[]
    local gridData = {}
    self._Control:GetGameControl():GetDataGrids4BlockOption(gridData, block:GetGrids(), XTemple2Enum.BLOCK_SIZE.X, XTemple2Enum.BLOCK_SIZE.Y)
    -- 限制尺寸
    if #gridData == 1 then
        gridData[1].LimitSize = true
    end
    XTool.UpdateDynamicItem(self._Grids, gridData, self.Grid, XUiTemple2CheckBoardGrid, self)
    for i = 1, #gridData do
        local grid = self._Grids[i]
        grid:SetPivotCenter()
    end

    if self.Mask then
        local effectiveTimes = block:GetEffectiveTimes()
        if effectiveTimes > 0 then
            self.PanelNum.gameObject:SetActiveEx(true)
            if block:IsHasEffectiveTimes() then
                self.Mask.gameObject:SetActiveEx(false)
            else
                self.Mask.gameObject:SetActiveEx(true)
            end
            self.TxtNum.text = block:GetRemainEffectiveTimes()
        else
            self.Mask.gameObject:SetActiveEx(false)
            self.PanelNum.gameObject:SetActiveEx(false)
        end
    end

    if self.ImgColor1 then
        local color = block:GetColor()
        for i = 0, 3 do
            local imgColor = self["ImgColor" .. i]
            if imgColor then
                imgColor.gameObject:SetActiveEx(i == color)
            end
        end
    end

    self:UpdateSelected()
end

function XUiTemple2GameBlockGridOption:SelectSelf()
    if not self._Data:IsHasEffectiveTimes() then
        return false
    end
    self._Control:GetGameControl():SetBlock2EditMap(self._Data)
    return true
end

function XUiTemple2GameBlockGridOption:OnClickOnGuide(eventData, isDrag)
    if XDataCenter.GuideManager.CheckIsInGuide() then
        self:OnClick(eventData, isDrag)
    end
end

function XUiTemple2GameBlockGridOption:OnClick(eventData, isDrag)
    if not self:SelectSelf() then
        return
    end

    local screenPosition
    if isDrag then
        screenPosition = self.Transform.position
    end
    XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE2_UPDATE_OPERATION, screenPosition)
end

function XUiTemple2GameBlockGridOption:AddListenerInput()
    ---@type XGoInputHandler
    local dragInput = self.InputHandler
    dragInput:AddBeginDragListener(function(...)
        if self._Control:GetGameControl():IsSelectBlock() then
            if self._Data:IsHasEffectiveTimes() then
                local isSuccess = self._Control:GetGameControl():ConfirmBlock2EditMap()
                --XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE2_BEGIN_DRAG, ...)
                if isSuccess then
                    self:SelectSelf()
                    XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE2_UPDATE_GAME)
                else
                    XUiManager.TipError(XUiHelper.GetText("TempleFailInsert"))
                end
            end
            return
        end
        self:OnClick(nil, true)
        XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE2_UPDATE_BLOCK_OPTION)
        XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE2_BEGIN_DRAG, ...)
    end)
    dragInput:AddDragListener(function(...)
        if self._Data:IsHasEffectiveTimes() then
            XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE2_ON_DRAG, ...)
        end
    end)
    dragInput:AddEndDragListener(function(...)
        if self._Data:IsHasEffectiveTimes() then
            XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE2_ON_END_DRAG, ...)
        end
    end)
end

function XUiTemple2GameBlockGridOption:UpdateSelected()
    if self.PanelSelect then
        if self._Control:GetGameControl():IsSelectBlock()
                and self._Control:GetGameControl():IsEditingBlock(self._Data)
        then
            self.PanelSelect.gameObject:SetActiveEx(true)
        else
            self.PanelSelect.gameObject:SetActiveEx(false)
        end
    end
end

return XUiTemple2GameBlockGridOption