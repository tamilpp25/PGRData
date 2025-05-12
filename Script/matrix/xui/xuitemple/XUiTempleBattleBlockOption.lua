local XUiTempleBattleGrid = require("XUi/XUiTemple/XUiTempleBattleGrid")

---@field _Control XTempleControl
---@class XUiTempleBattleBlockOption:XUiNode
local XUiTempleBattleBlockOption = XClass(XUiNode, "XUiTempleBattleBlockOption")

function XUiTempleBattleBlockOption:Ctor()
    self._Rounds = { self.ImgSmallRound }
    self._Grids = {}
    self._Data = nil
end

--function XUiTempleBattleBlockOption:OnStart()
--    XUiHelper.RegisterClickEvent(self, self.Button, self.OnClick)
--end

---@param data XTempleUiDataBlockOption
function XUiTempleBattleBlockOption:Update(data)
    self._Data = data
    self.TxtName.text = data.Name
    if self.TxtNum then
        if data.Score ~= 0 then
            self.TxtNum.text = data.Score
            self.TxtNum.gameObject:SetActiveEx(true)
        else
            self.TxtNum.gameObject:SetActiveEx(false)
        end
    end
    ---@type UnityEngine.UI.GridLayoutGroup
    local groupLayout = self.PanelGrid
    groupLayout.constraintCount = data.ConstraintCount
    if self.ImgSmallRound then
        self:_UpdateDynamicUiObject(self._Rounds, data.Time, self.ImgSmallRound)
    end
    self:_UpdateDynamicItem(self._Grids, data.Grids, self.Grid, XUiTempleBattleGrid)
end

--function XUiTempleBattleBlockOption:OnClick()
--    self._Control:GetGameControl():SetBlockOperationVisible(true)
--end

function XUiTempleBattleBlockOption:_UpdateDynamicUiObject(gridArray, amount, uiObject)
    if #gridArray == 0 then
        uiObject.gameObject:SetActiveEx(false)
    end
    for i = 1, amount do
        local grid = gridArray[i]
        if not grid then
            grid = CS.UnityEngine.Object.Instantiate(uiObject, uiObject.transform.parent)
            gridArray[i] = grid
        end
        grid.gameObject:SetActiveEx(true)
    end
    for i = amount + 1, #gridArray do
        local grid = gridArray[i]
        grid.gameObject:SetActiveEx(false)
    end
end

function XUiTempleBattleBlockOption:_UpdateDynamicItem(gridArray, dataArray, uiObject, class)
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

function XUiTempleBattleBlockOption:UpdateSelected(selectedBlockId)
    if not self._Data then
        self.Selected.gameObject:SetActiveEx(false)
        return
    end
    self.Selected.gameObject:SetActiveEx(self._Data.BlockId == selectedBlockId)
end

return XUiTempleBattleBlockOption
