---@class XFangKuaiStageData 大方块关卡数据
---@field Blocks XFangKuaiBlock[] 保持当前生成的方块数据（完整的方块数据在XFangKuaiGame里）
---@field DropBlockTimes number 方块从顶部掉落的次数（关卡环境）
---@field TopPreviewBlock XFangKuaiBlock 顶部预览方块
local XFangKuaiStageData = XClass(nil, "XFangKuaiStageData")

function XFangKuaiStageData:Ctor()
    self:ResetData()
end

function XFangKuaiStageData:InitStageData(stageId, characterId)
    self.StageId = stageId
    self.CharacterId = characterId
end

function XFangKuaiStageData:UpdateStageData(data)
    if not data then
        return
    end
    self.StageId = data.StageId
    self.Point = data.Point
    self.RecordRound = data.Round
    self.FrozenRound = data.FrozenRoundCount
    self.DropBlockTimes = data.FallingBlockCount
    self.DropBlockCd = data.FallingBlockCd
    self.Round = self.RecordRound
    self.ExtraRound = data.ExtraRound or 0
    self.HistoryItemIds = data.HistoryItemIds
    self.HistoryUsedItemIds = data.HistoryUsedItemIds
    self.HistoryDiscardItemIds = data.HistoryDiscardItemIds
    self.HistoryMaxCombo = data.Combo or 1
    self.ItemIds = {}
    if not XTool.IsTableEmpty(data.ItemIds) then
        for i, itemId in ipairs(data.ItemIds) do
            if XTool.IsNumberValid(itemId) then
                self.ItemIds[i] = itemId
            end
        end
    end
    self:UpdateBlocks(data.Blocks, data.PreviewBlocks)
end

function XFangKuaiStageData:UpdateBlocks(blocks, previewBlocks)
    self.LastLineNo = 0
    self.LastBlockId = 0
    self:ClearBlock()
    if blocks then
        for _, data in pairs(blocks) do
            local blockData = self:CreateBlockDataByServer(data)
            self:AddBlock(blockData)
        end
    end
    if previewBlocks then
        for _, data in pairs(previewBlocks) do
            if data.Y > 0 then
                -- 顶部预览方块
                local previewBlock = self:CreateBlockDataByServer(data)
                self:SetTopPreviewBlock(previewBlock)
            else
                -- 底部预览方块
                local blockData = self:CreateBlockDataByServer(data)
                self:AddBlock(blockData)
            end
        end
    end
end

function XFangKuaiStageData:CreateBlockDataByServer(data)
    ---@type XFangKuaiBlock
    local blockData = require("XUi/XUiFangKuai/XEntity/XFangKuaiBlock").New()
    blockData:InitDataByServer(self.StageId, data)
    self.LastBlockId = math.max(self.LastBlockId, data.Id)
    self.LastLineNo = math.max(self.LastLineNo, data.Y)
    return blockData
end

function XFangKuaiStageData:SetDropBlockCd(cd)
    self.DropBlockCd = cd
end

function XFangKuaiStageData:SetTopPreviewBlock(blockData)
    if blockData then
        self.TopPreviewBlock = blockData
    elseif self.TopPreviewBlock then
        self.TopPreviewBlock = nil
    end
end

function XFangKuaiStageData:AddRound()
    self.Round = self.Round + 1
end

function XFangKuaiStageData:AddExtraRound(num)
    self.ExtraRound = self.ExtraRound + num
end

function XFangKuaiStageData:AddPoint(score, combo, comboCount)
    -- 提前÷1000再相乘的话会有精度的问题 230会变成229！
    self.Point = self.Point + math.floor(score * combo / 10000)

    table.insert(self.ComboScoreList, {
        BaseScore = score, ComboCount = comboCount
    })
end

function XFangKuaiStageData:AddCombo(num)
    num = num or 1
    self.Combo = self.Combo + num
    self.HistoryMaxCombo = math.max(self.HistoryMaxCombo, self.Combo)
end

---@param block XFangKuaiBlock
function XFangKuaiStageData:AddBlock(block)
    table.insert(self.Blocks, block)
end

-- 道具被使用后不再重新排序
function XFangKuaiStageData:AddItem(itemId)
    if not XTool.IsNumberValid(itemId) then
        return
    end
    for i = 1, 4 do
        if not XTool.IsNumberValid(self.ItemIds[i]) then
            self.ItemIds[i] = itemId
            table.insert(self.CurRoundNewItems, {
                OperatorType = XEnumConst.FangKuai.ItemOperate.Get, Index = i, Id = itemId
            })
            return i
        end
    end
end

function XFangKuaiStageData:AddFrozenRound()
    self.FrozenRound = self.FrozenRound + 1
end

function XFangKuaiStageData:AddDropBlockTimes()
    self.DropBlockTimes = self.DropBlockTimes + 1
end

function XFangKuaiStageData:RemoveItem(index, isGiveUp)
    local operate = isGiveUp and XEnumConst.FangKuai.ItemOperate.Discard or XEnumConst.FangKuai.ItemOperate.Use
    table.insert(self.CurRoundNewItems, {
        OperatorType = operate, Index = index, Id = self.ItemIds[index]
    })
    self.ItemIds[index] = nil
end

function XFangKuaiStageData:ReduceFrozenRound()
    if self:IsRoundFrozen() then
        self.FrozenRound = self.FrozenRound - 1
    end
end

function XFangKuaiStageData:ReduceDropBlockCd()
    if self.DropBlockCd > 0 then
        self.DropBlockCd = self.DropBlockCd - 1
    end
end

function XFangKuaiStageData:IsRoundFrozen()
    return self.FrozenRound > 0
end

function XFangKuaiStageData:IsBlockDrop()
    return self.DropBlockCd <= 0
end

function XFangKuaiStageData:IsCreatePreviewTopBlock()
    return self.DropBlockCd == 1 and not self.TopPreviewBlock
end

-- 如果当前回合数等于服务端记录的回合数 说明数据已经同步过了 不需要再发同步协议了
function XFangKuaiStageData:IsNeedSendInitBlockData()
    return self.Round == 0 and not self.RecordRound
end

function XFangKuaiStageData:GetStageId()
    return self.StageId
end

function XFangKuaiStageData:GetPoint()
    return self.Point
end

function XFangKuaiStageData:GetCombo()
    return self.Combo
end

function XFangKuaiStageData:GetItems()
    return self.ItemIds
end

function XFangKuaiStageData:GetItemCount()
    return XTool.GetTableCount(self.ItemIds)
end

function XFangKuaiStageData:GetRound()
    return self.Round
end

function XFangKuaiStageData:GetExtraRound()
    return self.ExtraRound
end

function XFangKuaiStageData:GetFrozenRound()
    return self.FrozenRound
end

function XFangKuaiStageData:GetBlocks()
    return self.Blocks
end

function XFangKuaiStageData:GetDropBlockTimes()
    return self.DropBlockTimes
end

function XFangKuaiStageData:GetTopPreviewBlock()
    return self.TopPreviewBlock
end

function XFangKuaiStageData:GetCurRoundItems()
    return self.CurRoundNewItems
end

function XFangKuaiStageData:GetComboScoreList()
    return self.ComboScoreList
end

function XFangKuaiStageData:GetDropBlockCd()
    return self.DropBlockCd
end

function XFangKuaiStageData:GetHistoryMaxCombo()
    return self.HistoryMaxCombo
end

-- v1.0方块数据保存在服务端 每次开始对局时请求即可 v2.0改为了“单机” 要手动保存下方块数据
---@param blockMap table<XFangKuaiBlock,table>
---@param previewBlockMap table<number,XFangKuaiBlock[]>
function XFangKuaiStageData:SaveStageBlockData(blockMap, previewBlockMap)
    self:ClearBlock()
    -- 保存场上的方块数据
    for blockData, _ in pairs(blockMap) do
        self:AddBlock(blockData)
    end
    -- 保存预览的方块数据
    for i, blockDatas in ipairs(previewBlockMap) do
        for _, blockData in pairs(blockDatas) do
            blockData:SetGrid(blockData:GetHeadGrid().x, -i)
            self:AddBlock(blockData)
        end
    end
end

function XFangKuaiStageData:ClearBlock()
    self.Blocks = {}
end

function XFangKuaiStageData:ClearRoundItemData()
    self.CurRoundNewItems = {}
end

function XFangKuaiStageData:ClearComboScoreList()
    self.ComboScoreList = {}
end

function XFangKuaiStageData:ClearCombo()
    self.Combo = 1
end

function XFangKuaiStageData:ResetData()
    self.Blocks = {}
    self.StageId = 0
    self.LastLineNo = 0
    self.LastBlockId = 0
    self.NextItemLineNo = 0
    self.Point = 0
    self.Round = 0
    self.ExtraRound = 0
    self.ItemIds = {}
    self.HistoryItemIds = {}
    self.HistoryUsedItemIds = {}
    self.HistoryDiscardItemIds = {}
    self.FrozenRound = 0
    self.DropBlockTimes = 0
    self.DropBlockCd = 0
    self.HistoryMaxCombo = 1
    self:ClearBlock()
    self:ClearRoundItemData()
    self:ClearComboScoreList()
    self:ClearCombo()
    self:SetTopPreviewBlock(nil)
end

return XFangKuaiStageData