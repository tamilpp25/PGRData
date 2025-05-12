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

function XFangKuaiItem:ExecuteLengthReduce(itemIdx, color)
    local blockDatas = self._MainControl:GetBlockMap()
    for blockData, _ in pairs(blockDatas) do
        if blockData:GetColor() == color and not blockData:IsBoss() then
            -- 长度缩减不算整行消除 所以如果整个地图都是一长度的方块 使用道具时也是1combo
            self._MainControl:AddOperate(OperateMode.Wane, { blockData, 1 })
        end
    end
    self._MainControl:PlayUseItemSound()
    self:RemoveItemId(itemIdx)
end

function XFangKuaiItem:ExecuteBecomeOneGrid(itemIdx, color, chapterId)
    local filterDatas = {}
    local blockDatas = self._MainControl:GetBlockMap()
    for blockData, _ in pairs(blockDatas) do
        if blockData:GetColor() == color and not blockData:IsBoss() and blockData:GetLen() > 1 then
            -- 对1长度的方块不生效
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
    for _, data in ipairs(filterDatas) do
        local newBlockData = self._MainControl:CreateCopyBlockData(1, data.Pos, data.BlockData, data.ItemId, chapterId)
        self._MainControl:AddOperate(OperateMode.Create, { newBlockData })
    end
    self._MainControl:PlayUseItemSound()
    self:RemoveItemId(itemIdx)
end

function XFangKuaiItem:ExecuteSingleLineRemove(itemIdx, chooseBlockData)
    local grid = chooseBlockData:GetHeadGrid()
    self._MainControl:AddOperate(OperateMode.Clear, { grid.y })
    self._MainControl:PlayUseItemSound()
    self:RemoveItemId(itemIdx)
end

function XFangKuaiItem:ExecuteTwoLineExChange(itemIdx, blockData1, blockData2)
    local grid1 = blockData1:GetHeadGrid()
    local grid2 = blockData2:GetHeadGrid()
    if grid1.y ~= grid2.y then
        local blockDatas1 = self._MainControl:GetLayerBlocks(grid1.y)
        local blockDatas2 = self._MainControl:GetLayerBlocks(grid2.y)
        for blockData, _ in pairs(blockDatas1) do
            self._MainControl:AddOperate(OperateMode.MoveY, { blockData, grid2.y })
        end
        for blockData, _ in pairs(blockDatas2) do
            self._MainControl:AddOperate(OperateMode.MoveY, { blockData, grid1.y })
        end
        self._MainControl:PlayUseItemSound()
    end
    self:RemoveItemId(itemIdx)
end

function XFangKuaiItem:ExecuteAdjacentExchange(itemIdx, blockData1, blockData2)
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
    self._MainControl:PlayUseItemSound()
    self:RemoveItemId(itemIdx)
end

function XFangKuaiItem:ExecuteAddRound(itemIdx, params)
    if XTool.IsTableEmpty(params) then
        XLog.Error("死线救援道具没有配置增加的回合数.")
        return
    end
    self._MainControl:GetCurStageData():AddExtraRound(tonumber(params[1]))
    self._MainControl:PlayUseItemSound()
    self:RemoveItemId(itemIdx)
end

function XFangKuaiItem:ExecuteFrozen(itemIdx, chapterId)
    self._MainControl:AddFrozenRound(chapterId)
    self._MainControl:PlayUseItemSound()
    self:RemoveItemId(itemIdx)
end

function XFangKuaiItem:ExecuteAlignment(itemIdx, gridY, direction, maxCount)
    ---@type XFangKuaiBlock[]
    local blocks = {}
    for block, _ in pairs(self._MainControl:GetLayerBlocks(gridY)) do
        table.insert(blocks, block)
    end
    if #blocks > 0 then
        local isDirLeft = direction == 0
        table.sort(blocks, function(a, b)
            if isDirLeft then
                return a:GetHeadGrid().x < b:GetHeadGrid().x
            else
                return a:GetHeadGrid().x > b:GetHeadGrid().x
            end
        end)
        local curX = isDirLeft and 1 or maxCount
        for _, block in ipairs(blocks) do
            if not isDirLeft then
                curX = curX - block:GetLen() + 1
            end
            self._MainControl:AddOperate(OperateMode.MoveX, { block, curX })
            if isDirLeft then
                curX = curX + block:GetLen()
            else
                curX = curX - 1
            end
        end
    end
    self._MainControl:PlayUseItemSound()
    self:RemoveItemId(itemIdx)
end

function XFangKuaiItem:ExecuteConvertion(itemIdx, stageId)
    ---@type XFangKuaiBlock[]
    local bossBlocks = {}
    for k, _ in pairs(self._MainControl:GetBlockMap()) do
        if k:IsBoss() then
            table.insert(bossBlocks, k)
        end
    end
    if #bossBlocks == 0 then
        return nil
    end
    local blockData = bossBlocks[XTool.Random(1, #bossBlocks)]
    local blockTemplates = self._Model:GetBlockTemplates()
    local blocks = blockTemplates[stageId][blockData:GetLen()]
    local colorIds = {}
    local colorToIdMap = {}
    for _, v in pairs(blocks) do
        if v.Type == 1 and not XTool.IsTableEmpty(v.Colors) and not table.indexof(colorIds, v.Colors[1]) then
            colorToIdMap[v.Colors[1]] = v.Id
            table.insert(colorIds, v.Colors[1])
        end
    end
    if XTool.IsTableEmpty(colorIds) then
        XLog.Error(string.format("使用净化道具失败 关卡%s没有长度为%s的普通方块", stageId, blockData:GetLen()))
        return
    end
    local randomColorId = colorIds[XTool.Random(1, #colorIds)]
    local randomId = colorToIdMap[randomColorId]
    blockData:SetBlockId(randomId)
    blockData:SetColor(randomColorId)
    blockData:SetBlockType(XEnumConst.FangKuai.BlockType.Normal)
    blockData:SetScore()
    blockData:SetHitTimes()
    self._MainControl:PlayUseItemSound()
    self:RemoveItemId(itemIdx)
    return blockData
end

function XFangKuaiItem:ExecuteBorn(itemIdx, color, maxX, maxY, chapterId)
    local pos = {}
    local temp = {}
    for y = 1, maxY do
        ---@type XFangKuaiBlock[]
        local blockMap = {}
        local isCheck = false
        local blocks = self._MainControl:GetLayerBlocks(y)
        for blockData, _ in pairs(blocks) do
            for x = blockData:GetHeadGrid().x, blockData:GetTailGrid().x do
                blockMap[x] = blockData
            end
            if not blockData:IsBoss() and blockData:GetColor() == color then
                isCheck = true
            end
        end
        if not isCheck then
            goto CONTINUE
        end
        for x = 1, maxX do
            if not blockMap[x] then
                temp = {}
                local lastBlock = blockMap[x - 1]
                local nextBlock
                local isBorn = lastBlock and self:IsNoBossAndSameColor(lastBlock, color)
                for i = x, maxX do
                    nextBlock = blockMap[i + 1]
                    if nextBlock then
                        if isBorn or self:IsNoBossAndSameColor(nextBlock, color) then
                            table.insert(temp, i)
                        else
                            -- 左右都是BOSS或者非同色方块 无需生成
                            temp = {}
                        end
                        break
                    else
                        if i == maxX and not isBorn then
                            -- 左边是BOSS或者非同色方块 右边没有任何方块 无需生成
                            temp = {}
                        else
                            table.insert(temp, i)
                        end
                    end
                end
                for _, gridX in pairs(temp) do
                    pos = { x = gridX, y = y }
                    local newBlockData = self._MainControl:CreateCopyBlockData(1, pos, isBorn and lastBlock or nextBlock, 0, chapterId)
                    self._MainControl:AddOperate(OperateMode.Create, { newBlockData })
                    blockMap[gridX] = newBlockData
                end
            end
        end
        :: CONTINUE ::
    end
    self._MainControl:PlayUseItemSound()
    self:RemoveItemId(itemIdx)
end

function XFangKuaiItem:ExecuteGrow(itemIdx, color, params, maxX, maxY)
    local growCount = tonumber(params[1])
    for y = 1, maxY do
        ---@type XFangKuaiBlock[]
        local blockMap = {}
        ---@type XFangKuaiBlock[]
        local growBlockMap = {}
        local blocks = self._MainControl:GetLayerBlocks(y)
        for blockData, _ in pairs(blocks) do
            if not blockData:IsBoss() and blockData:GetColor() == color then
                table.insert(growBlockMap, blockData)
            end
            for x = blockData:GetHeadGrid().x, blockData:GetTailGrid().x do
                blockMap[x] = blockData
            end
        end
        for _, blockData in pairs(growBlockMap) do
            local headGridX = blockData:GetHeadGrid().x
            local tailGridX = blockData:GetTailGrid().x
            local isLeft = blockData:IsFacingLeft()
            local startX = isLeft and headGridX - 1 or tailGridX + 1
            local endX = isLeft and math.max(1, headGridX - growCount) or math.min(maxX, tailGridX + growCount)
            if startX < 1 or startX > maxY then
                goto CONTINUE
            end

            ---@type table<XFangKuaiBlock,number>
            local shorts = {}
            local finalGrowCount = 0
            local num = isLeft and -1 or 1
            for x = startX, endX, num do
                local dimBlock = blockMap[x]
                if dimBlock then
                    if dimBlock:GetColor() == color or dimBlock:IsBoss() then
                        break
                    end
                    if shorts[dimBlock] then
                        shorts[dimBlock] = shorts[dimBlock] + 1
                    else
                        shorts[dimBlock] = 1
                    end
                end
                blockMap[x] = blockData
                finalGrowCount = finalGrowCount + 1
            end
            if finalGrowCount > 0 then
                self._MainControl:AddOperate(OperateMode.Grow, { blockData, finalGrowCount })
                for data, len in pairs(shorts) do
                    if data:GetLen() <= len then
                        self._MainControl:AddOperate(OperateMode.Remove, { data, true })
                    else
                        self._MainControl:AddOperate(OperateMode.Wane, { data, len })
                    end
                end
            end
            :: CONTINUE ::
        end
    end
    self._MainControl:PlayUseItemSound()
    self:RemoveItemId(itemIdx)
end

---@param blockData XFangKuaiBlock
function XFangKuaiItem:IsNoBossAndSameColor(blockData, dimColorId)
    return blockData and not blockData:IsBoss() and blockData:GetColor() == dimColorId
end

--region 关卡道具

---活动道具
function XFangKuaiItem:AddItemId(itemId)
    local stageData = self._MainControl:GetCurStageData()

    if not XTool.IsNumberValid(itemId) then
        return
    end

    local diffCount = self._MainControl:GetMaxItemCount() - stageData:GetItemCount()
    if diffCount <= 0 then
        return
    end

    if self._MainControl:GetItemConfig(itemId) then
        -- 当前道具
        return stageData:AddItem(itemId)
        -- 记录历史 目前好像没啥用
        --table.insert(stageData.HistoryItemIds, itemId)
    else
        XLog.Error(string.format("AddItemIds error. Invalid item id:%s", itemId))
    end
end

---使用道具
function XFangKuaiItem:RemoveItemId(itemIdx, isGiveUp)
    local stageData = self._MainControl:GetCurStageData()
    stageData:RemoveItem(itemIdx, isGiveUp)
    XEventManager.DispatchEvent(XEventId.EVENT_FANGKUAI_REMOVEITEM)
end

--endregion

return XFangKuaiItem