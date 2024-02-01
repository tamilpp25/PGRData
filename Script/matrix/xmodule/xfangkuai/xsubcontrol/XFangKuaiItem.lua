---@class XFangKuaiItem : XControl 大方块道具
---@field _MainControl XFangKuaiControl
---@field _Model XFangKuaiModel
local XFangKuaiItem = XClass(XControl, "XFangKuaiItem")

local OperateMode = XEnumConst.FangKuai.OperateMode
local Floor = math.floor

function XFangKuaiItem:OnInit()

end

function XFangKuaiItem:AddAgencyEvent()

end

function XFangKuaiItem:RemoveAgencyEvent()

end

function XFangKuaiItem:OnRelease()

end

function XFangKuaiItem:ExecuteLengthReduce(itemIdx, color, chapterId)
    local blockDatas = self._MainControl:GetBlockMap()
    for blockData, _ in pairs(blockDatas) do
        if blockData:GetColor() == color and not blockData:IsBoss() then
            -- 长度缩减不算整行消除 所以如果整个地图都是一长度的方块 使用道具时也是1combo
            self._MainControl:AddOperate(OperateMode.Wane, { blockData, 1 })
        end
    end
    self._MainControl:FangKuaiItemUseRequest(chapterId, itemIdx, { color })
end

function XFangKuaiItem:ExecuteBecomeOneGrid(itemId, color, chapterId)
    local filterDatas = {}
    local blockDatas = self._MainControl:GetBlockMap()
    for blockData, _ in pairs(blockDatas) do
        if blockData:GetColor() == color and not blockData:IsBoss() and blockData:GetLen() > 1 then -- 对1长度的方块不生效
            self._MainControl:AddOperate(OperateMode.Remove, { blockData, true })
            local startX = blockData:GetHeadGrid().x
            local endX = blockData:GetTailGrid().x
            local itemId = blockData:GetItemId()
            local isLeft = blockData:IsFacingLeft()
            for i = startX, endX do
                local grid = blockData:GetHeadGrid()
                local pos = CS.UnityEngine.Vector2(i, grid.y)
                local data = {}
                data.Pos = pos
                -- 道具转移到第一个生成的小方块上
                if isLeft and i == startX then
                    data.ItemId = itemId
                elseif not isLeft and i == endX then
                    data.ItemId = itemId
                else
                    data.ItemId = 0
                end
                data.BlockData = blockData
                table.insert(filterDatas, data)
            end
        end
    end
    -- 排序 保证和服务端顺序一致
    table.sort(filterDatas, function(a, b)
        if a.Pos.y ~= b.Pos.y then
            return a.Pos.y < b.Pos.y
        end
        return a.Pos.x < b.Pos.x
    end)
    -- 创建新方块
    for i, data in ipairs(filterDatas) do
        local newBlockData = self._MainControl:CreateCopyBlockData(i, 1, data.Pos, data.BlockData, data.ItemId, chapterId)
        self._MainControl:AddOperate(OperateMode.Create, { newBlockData })
    end
    self._MainControl:FangKuaiItemUseRequest(chapterId, itemId, { color })
end

function XFangKuaiItem:ExecuteSingleLineRemove(itemIdx, chooseBlockData, chapterId)
    local grid = chooseBlockData:GetHeadGrid()
    self._MainControl:AddOperate(OperateMode.Clear, { grid.y })
    self._MainControl:FangKuaiItemUseRequest(chapterId, itemIdx, { Floor(grid.y - 1) })
end

function XFangKuaiItem:ExecuteTwoLineExChange(itemIdx, blockData1, blockData2, chapterId)
    local grid1 = blockData1:GetHeadGrid()
    local grid2 = blockData2:GetHeadGrid()
    local blockDatas1 = self._MainControl:GetLayerBlocks(grid1.y)
    local blockDatas2 = self._MainControl:GetLayerBlocks(grid2.y)
    for blockData, _ in pairs(blockDatas1) do
        self._MainControl:AddOperate(OperateMode.MoveY, { blockData, grid2.y })
    end
    for blockData, _ in pairs(blockDatas2) do
        self._MainControl:AddOperate(OperateMode.MoveY, { blockData, grid1.y })
    end
    self._MainControl:FangKuaiItemUseRequest(chapterId, itemIdx, { Floor(grid1.y - 1), Floor(grid2.y - 1) })
end

function XFangKuaiItem:ExecuteAdjacentExchange(itemIdx, blockData1, blockData2, chapterId)
    local grid1 = blockData1:GetHeadGrid()
    local grid2 = blockData2:GetHeadGrid()
    if grid1.x < grid2.x then
        local grid2Len = blockData2:GetLen()
        self._MainControl:AddOperate(OperateMode.MoveX, { blockData1, grid1.x + grid2Len })
        self._MainControl:AddOperate(OperateMode.MoveX, { blockData2, grid1.x })
    else
        local grid1Len = blockData1:GetLen()
        self._MainControl:AddOperate(OperateMode.MoveX, { blockData1, grid2.x })
        self._MainControl:AddOperate(OperateMode.MoveX, { blockData2, grid2.x + grid1Len })
    end
    self._MainControl:FangKuaiItemUseRequest(chapterId, itemIdx, { blockData1:GetId(), blockData2:GetId() })
end

function XFangKuaiItem:ExecuteAddRound(itemIdx, chapterId)
    self._MainControl:FangKuaiItemUseRequest(chapterId, itemIdx)
end

return XFangKuaiItem