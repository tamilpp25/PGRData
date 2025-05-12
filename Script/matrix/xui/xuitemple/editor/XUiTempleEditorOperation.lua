local XUiTempleBattleOperation = require("XUi/XUiTemple/XUiTempleBattleOperation")
local XUiTempleBattleGrid = require("XUi/XUiTemple/XUiTempleBattleGrid")
local XUiTempleBattleBlockOption = require("XUi/XUiTemple/XUiTempleBattleBlockOption")

---@class XUiTempleEditorOperation:XUiNode
---@field _Control XTempleControl
local XUiTempleEditorOperation = XClass(XUiNode, "XUiTempleEditorOperation")

function XUiTempleEditorOperation:OnStart()
    self._Grids = {}

    self._Option2InitMap = {}

    ---@type XTempleGameEditorTempControl
    self._GameControl = self._Control:GetGameEditorTempControl()
    self._GameControl:InitGame()

    ---@type XUiTempleBattleOperation
    self._Operation = XUiTempleBattleOperation.New(self.PanelOption, self, self._GameControl)
    self:AddListenerInput()
end

function XUiTempleEditorOperation:OnEnable()
    self:Update()
    XEventManager.AddEventListener(XEventId.EVENT_TEMPLE_UPDATE_OPERATION, self.Update, self)
    XEventManager.AddEventListener(XEventId.EVENT_TEMPLE_UPDATE_GAME, self.Update, self)
    XEventManager.AddEventListener(XEventId.EVENT_TEMPLE_ON_ACTION_CONFIRM, self.OnAction, self)
end

function XUiTempleEditorOperation:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_TEMPLE_UPDATE_OPERATION, self.Update, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TEMPLE_UPDATE_GAME, self.Update, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TEMPLE_ON_ACTION_CONFIRM, self.OnAction, self)
end

function XUiTempleEditorOperation:SetBlock(block)
    self._GameControl:InitByBlock(block)
    self._GameControl:StartTempGame()
    self:Update()
end

function XUiTempleEditorOperation:Update()
    self:UpdateGrids()
    self:UpdateUiOperation()
    self:UpdateGridLayoutConstraintCount()
    self:UpdateEditMapGrid()
end

function XUiTempleEditorOperation:UpdateGridLayoutConstraintCount()
    ---@type UnityEngine.UI.GridLayoutGroup
    local groupLayout = self.PanelGridEditRule
    groupLayout.constraintCount = self._GameControl:GetGridLayoutConstraintCount()
end

function XUiTempleEditorOperation:AddListenerInput()
    ---@type XGoInputHandler
    local goInputHandler = self.PanelDrag
    goInputHandler:AddPointerDownListener(function(...)
        self:OnBeginDrag(...)
    end)
    goInputHandler:AddDragListener(function(...)
        self:OnDrag(...)
    end)
    goInputHandler:AddPointerUpListener(function(...)
        self:OnEndDrag(...)
    end)
end

function XUiTempleEditorOperation:UpdateUiOperation()
    if self._GameControl:IsShowOperation() then
        self._Operation:Open()
        local data = self._GameControl:GetBlockOperation()
        self._Operation:Update(data)
    else
        self._Operation:Close()
    end
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiTempleEditorOperation:GetPosByEventData(eventData)
    ---@type UnityEngine.RectTransform
    local transform = self.PanelDrag.transform
    local hasValue, point = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(transform, eventData.position, CS.XUiManager.Instance.UiCamera)
    if not hasValue then
        return -99999, -99999
    end
    local x, y = point.x, point.y
    --x = x + transform.rect.width / 2
    --y = y - transform.rect.height / 2
    return x, y
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiTempleEditorOperation:OnBeginDrag(eventData)
    local x, y = self:GetPosByEventData(eventData)
    self._GameControl:SetBlockOperationPosition(x, y)
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiTempleEditorOperation:OnDrag(eventData)
    local x, y = self:GetPosByEventData(eventData)
    self._GameControl:SetBlockOperationPosition(x, y)
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiTempleEditorOperation:OnEndDrag(eventData)
    local x, y = self:GetPosByEventData(eventData)
    self._GameControl:SetBlockOperationPosition(x, y)
end

function XUiTempleEditorOperation:UpdateGrids()
    if self._GameControl then
        local dataProvider = self._GameControl:GetGrids()
        self:UpdateDynamicItem(self._Grids, dataProvider, self.GridEditRule, XUiTempleBattleGrid)

        for i = 1, #self._Grids do
            local grid = self._Grids[i]
            grid:RegisterClick()
        end
    end
end

function XUiTempleEditorOperation:UpdateDynamicItem(gridArray, dataArray, uiObject, class)
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

function XUiTempleEditorOperation:UpdateEditMapGrid()
    local options = self._GameControl:GetOption2InitMap()
    self:UpdateDynamicItem(self._Option2InitMap, options, self.BtnOptionEditor, XUiTempleBattleBlockOption)

    for i = 1, #options do
        local option = self._Option2InitMap[i].Button
        XUiHelper.RegisterClickEvent(self, option, function()
            self._GameControl:OnClickBlockOptionEditor(options[i].BlockId)
        end, true)
    end
end

---@param action XTempleAction
function XUiTempleEditorOperation:OnAction()
    self._GameControl:SaveBlock()
end

return XUiTempleEditorOperation
