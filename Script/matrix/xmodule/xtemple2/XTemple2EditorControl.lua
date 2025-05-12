local XTemple2Block = require("XModule/XTemple2/Game/XTemple2Block")
local XTemple2Grid = require("XModule/XTemple2/Game/XTemple2Grid")

---@class XTemple2EditorControl : XControl
---@field private _Model XTemple2Model
---@field private _MainControl XTemple2Control
local XTemple2EditorControl = XClass(XControl, "XTemple2EditorControl")

function XTemple2EditorControl:OnInit()
    ---@type XTemple2Game
    self._Game = require("XModule/XTemple2/Game/XTemple2Game").New()

    self._SelectedMapId = 0

    self._UiData = {
        ---@type XTemple2EditorUiDataGrid[]
        StageList = false,
        Map = {
            X = 0,
            Y = 0,
            Grids = {},
        },
        Operation = {
            Grids = {},
            IsRed = false
        },
        ---@type XUiTemple2EditorEditBlockGridData[]
        Blocks = {},
        Bg = {
            Image = false,
            Width = 0,
            Height = 0,
            OffsetX = 0,
            OffsetY = 0,
        }
    }

    --编辑地图时用到的地块
    ---@type XUiTemple2EditorBlockOptionData[]
    self._BlockOptions = false

    ---@type XTemple2Block
    self._Block2EditMap = false

    self._IsDirty = false

    ---@type XTemple2Block
    self._BlockBeingEdited = false

    self._SearchBlockName = ""
end

function XTemple2EditorControl:OnRelease()
    self._Game = false
end

---@return XTemple2Game
function XTemple2EditorControl:GetGame()
    if not self._Game then
        self._Game = require("XModule/XTemple2/Game/XTemple2Game").New()
    end
    return self._Game
end

---@param data XTempleEditorUiDataGrid
function XTemple2EditorControl:SetSelectedStage(data)
    local mapId = data.MapId or data.StageId
    self._SelectedMapId = mapId
    local game = self:GetGame()

    if #game:GetAllBlock() == 0 then
        local allBlockConfigs = self._Model:GetAllBlocks()
        if allBlockConfigs then
            game:InitBlocks(allBlockConfigs, self._Model)
        end
    end

    ---@type XTable.XTableTemple2Stage
    local config = self._Model:GetStageGameConfig(mapId, true)
    if config then
        local mapConfig = self._Model:GetMapConfig(mapId)
        game:InitGame(config, self._Model, mapConfig)
    else
        game:ClearPool()
        self:ResetMap()
    end
end

function XTemple2EditorControl:GetBgData()
    local config = self._Model:GetMapConfig(self._SelectedMapId)
    if config then
        local bgData = self._UiData.Bg
        bgData.Image = config.Bg
        bgData.Width = config.BgWidth
        bgData.Height = config.BgHeight
        bgData.OffsetX = config.BgOffsetX
        bgData.OffsetY = config.BgOffsetY
        return bgData
    end
end

function XTemple2EditorControl:GetUiDataStage()
    if self._UiData.StageList then
        for i = 1, #self._UiData.StageList do
            local stage = self._UiData.StageList[i]
            stage.IsSelected = self._SelectedMapId == stage.MapId
        end
        return self._UiData.StageList
    end
    local mapConfigs = self._Model:GetMapConfigList()
    ---@type XTemple2EditorUiDataGrid[]
    local mapList = {}
    for mapId, map in pairs(mapConfigs) do
        ---@class XTemple2EditorUiDataGrid
        local data = {
            Name = map.Name,
            MapId = mapId,
            IsSelected = false,
            Seed = false,
        }
        mapList[#mapList + 1] = data
    end
    table.sort(mapList, function(a, b)
        return a.MapId < b.MapId
    end)
    self._UiData.StageList = mapList
    if self._SelectedMapId == 0 and #mapList > 0 then
        self:SetSelectedStage(mapList[1])
        mapList[1].IsSelected = true
    end
    return mapList
end

function XTemple2EditorControl:GetUiDataMap()
    local grids = self._Game:GetGrids()
    local maxX, maxY = self._Game:GetMap():GetSize()

    ---@class XUiTemple2CheckBoardData
    local map = self._UiData.Map
    map.X = maxX
    map.Y = maxY
    map.StageId = self._SelectedMapId
    ---@type XUiTemple2CheckBoardGridData[]
    local gridData = map.Grids
    self:GetDataGrids(gridData, grids, maxX, maxY)
    local path = self:GetGame():GetPath()
    if path then
        local dict = {}
        for i = 2, #path - 1 do
            local pos = path[i]
            dict[pos.x] = dict[pos.x] or {}
            if dict[pos.x][pos.y] then
                XLog.Error("[XTemple2EditorControl] 重复的格子!!  " .. pos.x .. "/" .. pos.y)
            end
            dict[pos.x][pos.y] = i
        end
        for i = 1, #gridData do
            local data = gridData[i]
            if dict[data.X] and dict[data.X][data.Y] then
                data.Path = i
            else
                data.Path = false
            end
        end
    else
        for i = 1, #gridData do
            local data = gridData[i]
            data.Path = false
        end
    end
    return map
end

function XTemple2EditorControl:GetDataGrids(gridData, grids, maxX, maxY)
    gridData = gridData or {}
    local index = maxX * maxY + 1
    for y = 1, maxY do
        for x = 1, maxX do
            index = index - 1

            ---@type XTemple2Grid
            local grid = grids[x][y]

            gridData[index] = gridData[index] or {}

            local data = gridData[index]
            gridData[index] = self:GetUiGridData(data, grid, x, y)
        end
    end
    if #gridData ~= maxX * maxY then
        XLog.Warning("[XTemple2EditorControl] 清空超出的格子")
        for i = maxX * maxY + 1, #gridData do
            gridData[i] = nil
        end
    end
    return gridData
end

---@param grid XTemple2Grid
function XTemple2EditorControl:GetUiGridData(dataO, grid, x, y)
    ---@class XUiTemple2CheckBoardGridData
    local data = dataO or {}
    data.X = x
    data.Y = y
    if grid then
        if grid:IsEmpty() then
            data.IsEmpty = true
            data.IsExit = false
            data.MaskExit = false
        else
            local icon = grid:GetIcon()
            data.Id = grid:GetId()
            data.IsEmpty = false
            data.Icon = icon
            data.Rotation = 0
            data.IsExit = grid:IsEndPoint()
            data.MaskExit = false
        end
    else
        data.IsEmpty = true
        data.IsExit = false
        data.MaskExit = false
        XLog.Error("[XTemple2EditorControl] 棋盘存在空格")
    end
    return data
end

function XTemple2EditorControl:GetUiDataBlockOptions()
    if self._BlockOptions then
        return self._BlockOptions
    end

    self._BlockOptions = {}
    local gridConfigs = self._Model:GetGrids()
    for id, config in pairs(gridConfigs) do
        ---@type XTemple2Grid
        local grid = XTemple2Grid.New()
        grid:SetConfig(config)
        local grids = { { grid } }

        ----@type XTemple2Block
        local block = XTemple2Block.New()
        block:SetId("GridBlock" .. id)
        block:SetName(config.Name)
        block:SetGrids(grids)

        ---@class XUiTemple2EditorBlockOptionData
        local data = {
            GridId = grid:GetId(),
            Block = block,
            Name = block:GetName(),
            Grid = self:GetUiGridData(nil, grid, 1, 1)
        }
        self._BlockOptions[#self._BlockOptions + 1] = data
    end
    return self._BlockOptions
end

function XTemple2EditorControl:SetBlock2EditMap(block)
    self._Block2EditMap = block
end

function XTemple2EditorControl:GetUiDataBlock2EditMap()
    local block = self._Block2EditMap
    if not block then
        return false
    end

    local grids = block:GetGrids()
    local maxX, maxY = block:GetColumnAmount(), block:GetRowAmount()
    local gridData = {}
    self:GetDataGrids(gridData, grids, maxX, maxY)

    local data = {
        Grids = gridData,
        Position = block:GetPosition()
    }
    return data
end

function XTemple2EditorControl:ConfirmBlock2EditMap(position)
    local block = self._Block2EditMap
    if not block then
        XLog.Error("[XTemple2EditorControl] 确认地块失败")
        return
    end
    local game = self:GetGame()
    block:SetPosition(position)
    local isSuccess = game:InsertBlock(block)
    if isSuccess then
        self._Block2EditMap = false
        self:SetEditingDirty()
    end
    return isSuccess
end

function XTemple2EditorControl:RemoveBlock2EditMap()
    self._Block2EditMap = false
end

function XTemple2EditorControl:SetEditingDirty()
    self._IsDirty = true
end

function XTemple2EditorControl:Save()
    self._IsDirty = false
    self:SaveGameConfig()
end

function XTemple2EditorControl:OnClickGrid(x, y)
    if self._Block2EditMap then
        return false
    end
    local map = self:GetGame():GetMap()
    local grid = map:GetGrid(x, y)
    if not grid then
        XLog.Warning("[XTemple2EditorControl] 点击无效区域")
        return false
    end
    if grid:IsEmpty() then
        return false
    end
    ---@type XTemple2Block
    local block
    for i = 1, #self._BlockOptions do
        local blockOption = self._BlockOptions[i]
        if blockOption.GridId == grid:GetId() then
            block = blockOption.Block
        end
    end
    if block then
        self:SetBlock2EditMap(block)
        block:SetPositionXY(x, y)
        map:RemoveGrid(x, y)
        return true, block:GetPosition()
    end
    return false
end

function XTemple2EditorControl:GetUiDataBlocks()
    local game = self:GetGame()
    local blocks = game:GetAllBlock()
    local dataList = self._UiData.Blocks
    local amount = 0
    for i = 1, #blocks do
        local block = blocks[i]

        local isInsert = true
        if self._SearchBlockName ~= "" then
            isInsert = string.find(block:GetName(), self._SearchBlockName)
        end
        if isInsert then
            amount = amount + 1
            dataList[i] = dataList[i] or {}
            ---@class XUiTemple2EditorEditBlockGridData
            local dataBlock = dataList[i]
            dataBlock.Block = block
            dataBlock.Grids = self:GetDataGrids(dataBlock.Grids, block:GetGrids(), block:GetColumnAmount(), block:GetRowAmount())
            dataBlock.Name = block:GetName()
            dataBlock.IsSelected = block:Equals(self._BlockBeingEdited)
        else
            if block:Equals(self._BlockBeingEdited) then
                self:SetBlockBeingEdited(false)
            end
        end
    end
    for i = amount + 1, #dataList do
        dataList[i] = nil
    end
    return dataList
end

function XTemple2EditorControl:GetUiDataBlockPool()
    local dataList = self:GetUiDataBlocks()
    local game = self:GetGame()
    for i = 1, #dataList do
        local data = dataList[i]
        local isCheckMark = game:IsOnPool(data.Block)
        data.IsCheckMark = isCheckMark
    end
    return dataList
end

function XTemple2EditorControl:GetUiDataBlockRandomPool()
    local dataList = self:GetUiDataBlocks()
    local game = self:GetGame()
    for i = 1, #dataList do
        local data = dataList[i]
        local isCheckMark = game:IsOnRandomPool(data.Block)
        data.IsCheckMark = isCheckMark
    end
    return dataList
end

function XTemple2EditorControl:AddBlock()
    local game = self:GetGame()

    ---@type XTemple2Block
    local block = XTemple2Block.New()
    local blocks = game:GetAllBlock()
    local maxId = 0
    for i = 1, #blocks do
        local blockExist = blocks[i]
        local idExist = blockExist:GetId()
        if idExist > maxId then
            maxId = idExist
        end
    end
    local blockId = maxId + 1
    block:SetId(blockId)
    block:SetName(self._SearchBlockName or "")
    game:Add2AllBlock(block)
    self._BlockBeingEdited = block

    self:SetEditingDirty()
end

function XTemple2EditorControl:DeleteBlock()
    local block2Delete = self._BlockBeingEdited
    if not block2Delete then
        return false
    end
    local game = self:GetGame()
    local blocks = game:GetAllBlock()
    for i = 1, #blocks do
        local block = blocks[i]
        if block:Equals(block2Delete) then
            table.remove(blocks, i)
            self._BlockBeingEdited = false
            self:SetEditingDirty()
            return true, i
        end
    end
    XLog.Error("[XTemple2EditorControl] 找不到要删除的地块, 一定有问题")
    return false
end

function XTemple2EditorControl:GetIndexOfBlockBeingEdited()
    local block2Delete = self._BlockBeingEdited
    if not block2Delete then
        return 1
    end

    local game = self:GetGame()
    local blocks = game:GetAllBlock()
    for i = 1, #blocks do
        local block = blocks[i]
        if block:Equals(block2Delete) then
            return i
        end
    end
    return 1
end

function XTemple2EditorControl:GetBlockBeingEdited()
    return self._BlockBeingEdited
end

function XTemple2EditorControl:SetBlockBeingEdited(block)
    self._BlockBeingEdited = block
end

function XTemple2EditorControl:SetNameOfBlockBeingEdited(name)
    if self._BlockBeingEdited then
        if self._BlockBeingEdited:GetName() ~= name then
            self._BlockBeingEdited:SetName(name)
            self:SetEditingDirty()
        end
    end
end

function XTemple2EditorControl:SetEffectiveTimesOfBlockBeingEdited(value)
    if self._BlockBeingEdited then
        if self._BlockBeingEdited:GetEffectiveTimes() ~= value then
            self._BlockBeingEdited:SetEffectiveTimes(value)
            self:SetEditingDirty()
        end
    end
end

function XTemple2EditorControl:SetTypeNameOfBlockBeingEdited(typeName)
    if self._BlockBeingEdited then
        if self._BlockBeingEdited:GetTypeName() ~= typeName then
            self._BlockBeingEdited:SetTypeName(typeName)
            self:SetEditingDirty()
        end
    end
end

function XTemple2EditorControl:SetBlockSelected4Pool(isOn)
    if self._BlockBeingEdited then
        local game = self:GetGame()
        local isSuccess
        if isOn then
            isSuccess = game:Add2BlockPool(self._BlockBeingEdited)
        else
            isSuccess = game:RemoveFromPool(self._BlockBeingEdited)
        end
        if isSuccess then
            self:SetEditingDirty()
        end
        return isSuccess
    end
    return false
end

function XTemple2EditorControl:SetBlockSelected4RandomPool(isOn)
    if self._BlockBeingEdited then
        local game = self:GetGame()
        local isSuccess
        if isOn then
            isSuccess = game:Add2BlockRandomPool(self._BlockBeingEdited)
        else
            isSuccess = game:RemoveFromRandomPool(self._BlockBeingEdited)
        end
        if isSuccess then
            self:SetEditingDirty()
        end
        return isSuccess
    end
    return false
end

function XTemple2EditorControl:IsBlockSelectedOnPool()
    return self:GetGame():IsOnPool(self._BlockBeingEdited)
end

function XTemple2EditorControl:IsBlockSelectedOnRandomPool()
    return self:GetGame():IsOnRandomPool(self._BlockBeingEdited)
end

function XTemple2EditorControl:SetSearchBlockName(name)
    if self._SearchBlockName == name then
        return
    end
    self._SearchBlockName = name
end

function XTemple2EditorControl:GetSearchBlockName()
    return self._SearchBlockName
end

function XTemple2EditorControl:GetSearchItems()
    local data = {}
    local grids = self._Model:GetGrids()
    for i, grid in pairs(grids) do
        data[#data + 1] = grid.Name
    end
    return data
end

function XTemple2EditorControl:SetMapSize(x, y)
    local map = self._Game:GetMap()
    map:SetSize(x, y)
    self:SetEditingDirty()
end

function XTemple2EditorControl:ResetMap()
    self._Game:GetMap():Clear()
    -- 默认10 * 10
    self:SetMapSize(10, 10)
end

function XTemple2EditorControl:TrySave(callback)
    if not self._IsDirty then
        if callback then
            callback()
        end
        return
    end
    XUiManager.DialogTip(XUiHelper.GetText("TipTitle"), XUiHelper.GetText("SettingCheckSave"), XUiManager.DialogType.Normal, nil,
            function()
                self:Save()
                if callback then
                    callback()
                end
            end, nil,
            function()
                if callback then
                    callback()
                end
            end)
end

function XTemple2EditorControl:SaveGameConfig()
    self:SaveMap()
    self:SaveBlocks()
end

function XTemple2EditorControl:SaveMap()
    local game = self:GetGame()
    local toSave = {}

    -- map 
    local map = game:GetMap()
    local column = map:GetColumnAmount()
    local row = map:GetRowAmount()
    for y = 1, row do
        for x = 1, column do
            local grid = map:GetGrid(x, y)
            local encodeInfo = grid:GetEncodeInfo()
            local i = x
            local j = row - y + 1
            toSave[j] = toSave[j] or {}
            toSave[j].Map = toSave[j].Map or {}
            toSave[j].Map[i] = encodeInfo
        end
    end

    -- block pool
    toSave[1] = toSave[1] or {}
    local configBlockPool = {}
    local blockPool = game:GetBlockPool()
    for i = 1, #blockPool do
        local block = blockPool[i]
        local blockId = block:GetId()
        configBlockPool[#configBlockPool + 1] = blockId
    end
    toSave[1].BlockPool = configBlockPool

    local configBlockRandomPool = {}
    local blockRandomPool = game:GetBlockRandomPool()
    for i = 1, #blockRandomPool do
        local block = blockRandomPool[i]
        local blockId = block:GetId()
        configBlockRandomPool[#configBlockRandomPool + 1] = blockId
    end
    toSave[1].RandomBlockPool = configBlockRandomPool
    toSave[1].RandomPoolAmount = game:GetRandomPoolAmount()

    for i = 1, #toSave do
        toSave[i].Id = i
    end

    local path = self._Model:GetStageGamePath(self._SelectedMapId, true)
    local headTable = {
        "Id", "Map", "BlockPool", "RandomBlockPool", "RandomPoolAmount"
    }
    local isTable = {
        Map = true,
        BlockPool = true,
        RandomBlockPool = true
    }
    XTool.SaveConfig(path, toSave, headTable, isTable)
end

function XTemple2EditorControl:SaveBlocks()
    local headTable = {
        "Id", "Name", "TypeName", "Grid1", "Grid2", "Grid3", "EffectiveTimes", "NoRotate"
    }
    local isTable = {
        Grid1 = true,
        Grid2 = true,
        Grid3 = true,
    }
    local toSave = {}

    -- block
    ---@type XTemple2Block[]
    local blocks = self._Game:GetAllBlock()
    for _, block in pairs(blocks) do
        local blockId = block:GetId()
        toSave[blockId] = toSave[blockId] or {}
        local config = toSave[blockId]
        config.Id = blockId
        config.Name = block:GetName()
        config.TypeName = block:GetTypeName()
        config.EffectiveTimes = block:GetEffectiveTimes()
        config.NoRotate = block:GetNoRotate()

        if config.TypeName == "" then
            XUiManager.TipMsg("[XTemple2EditorControl] 忘记填地块类型名了，填一下")
        end

        for y = block:GetRowAmount(), 1, -1 do
            for x = 1, block:GetColumnAmount() do
                local grid = block:GetGrid(x, y)
                local gridType = grid and grid:GetEncodeInfo() or 0
                local key = "Grid" .. y
                config[key] = config[key] or {}
                config[key][x] = gridType
            end
        end
    end

    local path = self._Model:EditorGetBlockPath()
    XTool.SaveConfig(path, toSave, headTable, isTable)
end

function XTemple2EditorControl:GetMapSize()
    return self:GetGame():GetMap():GetSize()
end

function XTemple2EditorControl:PrintPath()
    local path = self:GetGame():PrintPath()
    if path then
        self:GetGame():StartWalk(path)
    end
end

function XTemple2EditorControl:UpdateGame(ui)
    self:GetGame():Update(ui)
end

function XTemple2EditorControl:OpenGameUi()
    XLuaUiManager.Open("UiTemple2Main")
end

function XTemple2EditorControl:RotateBlock2EditMap()
    local block = self._Block2EditMap
    block:Rotate90()
end

function XTemple2EditorControl:SetPositionOfBlock2EditMap(x, y)
    local block = self._Block2EditMap
    if block then
        block:SetPositionXY(x, y)
    end
end

function XTemple2EditorControl:GetRandomAmount()
    return self:GetGame():GetRandomPoolAmount()
end

function XTemple2EditorControl:SetRandomAmount(value)
    if self:GetGame():GetRandomPoolAmount() ~= value then
        self:GetGame():SetRandomPoolAmount(value)
        self:SetEditingDirty()
    end
end

function XTemple2EditorControl:ClampBlockPosition(x, y)
    local block = self._Block2EditMap
    if not block then
        return x, y
    end
    return self:GetGame():ClampBlockPosition(block, x, y)
end

function XTemple2EditorControl:IsShowRotationIcon()
    return true
end

return XTemple2EditorControl