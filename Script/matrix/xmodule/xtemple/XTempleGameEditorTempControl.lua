local XTempleGameControl = require("XModule/XTemple/XTempleGameControl")
local XTempleEnumConst = require("XEntity/XTemple/XTempleEnumConst")
local XTempleAction = require("XEntity/XTemple/Action/XTempleAction")
local GRID = XTempleEnumConst.GRID
local GRID_TYPE_EDITOR = XTempleEnumConst.GRID_TYPE_EDITOR
local ACTION = XTempleEnumConst.ACTION

---@class XTempleGameEditorTempControl:XTempleGameControl
---@field private _Model XTempleModel
---@field private _MainControl XTempleControl
local XTempleGameEditorTempControl = XClass(XTempleGameControl, "XTempleGameEditorTempControl")

function XTempleGameEditorTempControl:Ctor()
    self._EditingBlock = nil

    self._Round = 1
end

function XTempleGameEditorTempControl:OnInit()
    XTempleGameControl.OnInit(self)
    XEventManager.AddEventListener(XEventId.EVENT_TEMPLE_ON_CLICK_GRID, self.OnClickGrid, self)
end

function XTempleGameEditorTempControl:OnRelease()
    XTempleGameControl.OnRelease(self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TEMPLE_ON_CLICK_GRID, self.OnClickGrid, self)
end

---@param block XTempleBlock
function XTempleGameEditorTempControl:InitByBlock(block)
    self._EditingBlock = block
    if not block then
        return
    end
    local size = XTempleEnumConst.BLOCK_GRID_AMOUNT
    self._Game:SetMapSize(size)
    local mapConfig = {}
    for j = 1, size do
        for i = 1, size do
            local grid = block:GetGrid(i, j)
            mapConfig[i] = mapConfig[i] or {}
            if grid then
                mapConfig[j][i] = grid:GetEncodeInfo()
            else
                mapConfig[j][i] = 0
            end
        end
    end
    local grids = self:GenerateGrids(mapConfig)
    local map = self._Game:GetMap()
    map:ClearGrids()
    map:SetGrids(grids)
end

--todo by zlb repeat with XTempleGameEditorControl
function XTempleGameEditorTempControl:InitBlocks4InitMap()
    local grids = self._Model:GetGrids()
    for i, config in pairs(grids) do
        local id = config.Id
        if id ~= GRID.EMPTY then
            local blockId = GRID_TYPE_EDITOR | id
            if not self._Game:GetMap():GetBlockById(blockId) then
                ---@type XTempleBlock
                local block = self._Game:AddBlock()
                block:SetId(blockId)
                block:SetName(config.Name)

                -- 用单个grid生成block
                ---@type XTempleGrid
                local grid = self._Game:AddGrid()
                local x, y = 1, 1
                grid:SetPosition(x, y)
                grid:SetId(id)

                block:SetGrids({ [x] = { [y] = grid } })
                self._Game:GetMap():Add2Block(block)
            end
        end
    end
end

function XTempleGameEditorTempControl:GetOption2InitMap()
    self:InitBlocks4InitMap()
    local result = {}
    local grids = self._Model:GetGrids()
    for i, config in pairs(grids) do
        --for type = 1, self._Model:GetMaxGrid() do
        local type = config.Id
        local blockId = GRID_TYPE_EDITOR | type
        local block = self._Game:GetMap():GetBlockById(blockId)
        if block then
            local data = self:GetBlock4UiOption(block)
            result[#result + 1] = data
        end
    end
    return result
end

function XTempleGameEditorTempControl:OnClickBlockOptionEditor(blockId)
    local block = self._Game:GetMap():GetBlockById(blockId)
    self:SelectBlockOption(block)
end

function XTempleGameEditorTempControl:GetGridLayoutConstraintCount()
    return self._Game:GetMapSize()
end

function XTempleGameEditorTempControl:StartTempGame()
    self._Game:Start()
    self._Game:SetEndlessTime4Edit()
end

function XTempleGameEditorTempControl:SaveBlock()
    local block = self._EditingBlock
    if block then
        block:SetGridsFromMap(self._Game:GetMap())
        XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_SAVE_EDIT_BLOCK)
    end
end

---@param data XTempleUiDataGrid
function XTempleGameEditorTempControl:OnClickGrid(data)
    local x = data.X
    local y = data.Y
    local grid = self._Game:GetMap():GetGrid(x, y)
    if grid then
        if grid:IsEmpty() then
            return
        end
        self:InsertDragAction(grid, x, y)
        grid:SetId(GRID.EMPTY)
        XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_UPDATE_GAME)
    end
end

---@param grid XTempleGrid
function XTempleGameEditorTempControl:InsertDragAction(grid, x, y)
    ---@type XTempleAction
    local actionPutDown = XTempleAction.New()
    actionPutDown:SetData({
        Type = ACTION.PUT_DOWN,
        BlockId = GRID_TYPE_EDITOR | grid:GetId(),
    })
    self._Game:EnqueueAction(actionPutDown)

    ---@type XTempleAction
    local actionDrag = XTempleAction.New()
    actionDrag:SetData({
        Type = ACTION.DRAG,
        Position = XLuaVector2.New(x, y)
    })
    self._Game:EnqueueAction(actionDrag)
end

function XTempleGameEditorTempControl:InitGame()
    XTempleGameControl.InitGame(self)
    self._Game:SetEditor()
end

return XTempleGameEditorTempControl