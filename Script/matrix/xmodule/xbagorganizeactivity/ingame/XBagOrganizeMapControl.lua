--- 玩法内背包地块相关逻辑的控制器
---@class XBagOrganizeMapControl: XControl
---@field private _MainControl XBagOrganizeActivityGameControl
---@field private _Model XBagOrganizeActivityModel
local XBagOrganizeMapControl = XClass(XControl, 'XBagOrganizeMapControl')
local XBagOrganizeBlockEntity = require('XModule/XBagOrganizeActivity/InGame/Entity/XBagOrganizeBlockEntity')


function XBagOrganizeMapControl:OnInit()
    
end

function XBagOrganizeMapControl:OnRelease()

end

--- 重置地块, 兼顾首次进入游戏时的初始化和在游戏界面内开始下一关时的初始化
function XBagOrganizeMapControl:ResetMap()
    if self._Blocks == nil then
        self._Blocks = {}
        -- 背包最大尺寸
        local size = self._Model:GetClientConfigVector2('BagSize')
        self.MaxWidth = size.x
        self.MaxHeight = size.y
        
        -- 中心坐标
        self.MapCenterX = XMath.ToMinInt(self.MaxWidth / 2)
        self.MapCenterY = XMath.ToMinInt(self.MaxHeight / 2)
        
        -- 根据尺寸初始化对象
        for row = 0, self.MaxHeight - 1 do
            for column = 1, self.MaxWidth do
                local block = XBagOrganizeBlockEntity.New(column, row + 1)
                table.insert(self._Blocks, block)
            end
        end
    else
        -- 清空之前的遗留数据
        for i, block in pairs(self._Blocks) do
            block:ClearTags()
            block:SetEnabled(false)
        end
    end

    -- 加载对应配置
    -- 单背包才直接加载配置
    if not self._MainControl:IsMultyBagEnabled() then
        local mapCfg, mapId = self._Model:GetSingleMapConfigById(self._MainControl:GetCurStageId())
        self.CurMapId = mapId
        if not XTool.IsTableEmpty(mapCfg) then
            -- 根据对应配置赋值
            for index, cfg in ipairs(mapCfg) do
                for index2, value in ipairs(cfg.Blocks) do
                    local mapIndex = index2 + (index - 1 )* self.MaxWidth
                    local block = self._Blocks[mapIndex]
                    block:SetEnabled(value == 1)
                end
            end
        end
    end
end

function XBagOrganizeMapControl:LoadMapByMapId(mapId)
    if self._MainControl:IsMultyBagEnabled() then
        local mapCfg = self._Model:GetMapConfigById(mapId)

        if not XTool.IsTableEmpty(mapCfg) then
            self.CurMapId = mapId
            -- 根据对应配置赋值
            for index, cfg in ipairs(mapCfg) do
                for index2, value in ipairs(cfg.Blocks) do
                    local mapIndex = index2 + (index - 1 )* self.MaxWidth
                    local block = self._Blocks[mapIndex]
                    block:SetEnabled(value == 1)
                end
            end
        end
    end
end

--region ---------- Configs ---------->>>

function XBagOrganizeMapControl:GetMapWidth()
    return self.MaxWidth or 0
end

function XBagOrganizeMapControl:GetMapHeight()
    return self.MaxHeight or 0
end

function XBagOrganizeMapControl:InitBlockSize(width, height)
    self._BlockWidth = width
    self._BlockHeight = height
end

function XBagOrganizeMapControl:GetBlockWidth()
    return self._BlockWidth or 0
end

function XBagOrganizeMapControl:GetBlockHeight()
    return self._BlockHeight or 0
end

function XBagOrganizeMapControl:GetMinCostInBagList()
    local stageId = self._MainControl:GetCurStageId()

    if XTool.IsNumberValid(stageId) then
        ---@type XTableBagOrganizeStage
        local stageCfg = self._Model:GetBagOrganizeStageCfgById(stageId)

        if stageCfg then
            local minCost = math.maxinteger
            
            for i, mapId in pairs(stageCfg.MapIds) do
                ---@type XTableBagOrganizeBags
                local mapCfg = self._Model:GetBagOrganizeBagCfgById(mapId)

                if mapCfg and minCost > math.abs(mapCfg.Cost) then
                    minCost = mapCfg.Cost
                end
            end
            
            return minCost
        end
    end
    
    return 0
end

--endregion <<<--------------------------

--region ---------- Single Block Check ---------->>>
function XBagOrganizeMapControl:GetBlockIsEnabled(x, y)
    local xOffset = x
    local yOffset = y - 1
    local mapIndex = xOffset + yOffset * self.MaxWidth
    return self:GetBlockIsEnabledByIndex(mapIndex)
end

function XBagOrganizeMapControl:GetBlockIsEnabledByIndex(index)
    local block = self._Blocks[index]
    if block then
        return block.Enabled
    end
end

function XBagOrganizeMapControl:CheckBlockIsUseByGoods(x, y)
    local xOffset = x
    local yOffset = y - 1
    local mapIndex = xOffset + (yOffset - 1) * self.MaxWidth
    return self:CheckBlockIsUseByIndex(mapIndex, XMVCA.XBagOrganizeActivity.EnumConst.EntityType.Goods)
end

function XBagOrganizeMapControl:CheckBlockIsUseByIndex(index, tag)
    ---@type XBagOrganizeBlockEntity
    local block = self._Blocks[index]
    if block then
        return block:CheckHasTag(tag)
    end
    return false
end
--endregion <<<---------------------------------------

--- 根据传入的货物，移除所处位置周围方块的占据标记(占据标记手动设置和清除，不走Buff机制）
function XBagOrganizeMapControl:ClearPlacedGoodsTagInBlock(placedGoods)
    -- 确认占用格子是否可用且未被占用
    local leftUpX = placedGoods:GetLeftUpX()
    local leftUpY = placedGoods:GetLeftUpY()

    local xOffset = leftUpX
    local yOffset = leftUpY - 1
    
    for i, v in ipairs(placedGoods:GetBlocks()) do
        if XTool.IsNumberValid(v) then
            local locXOffset = (i - 1) % 4
            local locYOffset = XMath.ToMinInt((i - 1) / 4)
            local fixedIndex = xOffset + locXOffset + (yOffset + locYOffset) * self.MaxWidth

            local block = self._Blocks[fixedIndex]

            if block then
                -- 移除表示有货物占据的标签
                block:RemoveTag(XMVCA.XBagOrganizeActivity.EnumConst.EntityType.Goods, true)

                -- 移除具体占据格子类型的标签
                block:RemoveTag(v, true)
            end

        end
    end
end

--- 根据传入的货物，设置所处位置周围方块的占据标记(占据标记手动设置和清除，不走Buff机制）
function XBagOrganizeMapControl:AddPlacedGoodsTagInBlock(placedGoods)
    -- 确认占用格子是否可用且未被占用
    local leftUpX = placedGoods:GetLeftUpX()
    local leftUpY = placedGoods:GetLeftUpY()

    local xOffset = leftUpX
    local yOffset = leftUpY - 1
    
    for i, v in ipairs(placedGoods:GetBlocks()) do
        if XTool.IsNumberValid(v) then
            local locXOffset = (i - 1) % 4
            local locYOffset = XMath.ToMinInt((i - 1) / 4)
            local fixedIndex = xOffset + locXOffset + (yOffset + locYOffset) * self.MaxWidth

            local block = self._Blocks[fixedIndex]

            if block then
                -- 添加表示有货物占据的标签
                block:AddTag(XMVCA.XBagOrganizeActivity.EnumConst.EntityType.Goods)

                -- 添加具体占据格子类型的标签
                block:AddTag(v)
            end

        end
    end
end

--- 刷新所有已放置的背包，再次检查它们的有效性，如果无效需要标红（用于多背包玩法)
function XBagOrganizeMapControl:RecheckAllPlacedGoodsIsValid()
    local goodsList = self._MainControl.GoodsControl:GetPlacedGoodsEntities()

    if not XTool.IsTableEmpty(goodsList) then
        ---@param entity XBagOrganizeGoodsEntity
        for i, entity in pairs(goodsList) do
            -- 编辑中的货物不需要检查
            if entity == self._MainControl._PrePlaceItemEntity then
                goto CONTINUE
            end
            
            -- 确认占用格子是否可用且未被占用
            local leftUpX = entity:GetLeftUpX()
            local leftUpY = entity:GetLeftUpY()

            local xOffset = leftUpX
            local yOffset = leftUpY - 1

            entity:SetIsValid(true)
            
            for i, v in ipairs(entity:GetBlocks()) do
                if XTool.IsNumberValid(v) then
                    local locXOffset = (i - 1) % 4
                    local locYOffset = XMath.ToMinInt((i - 1) / 4)
                    local fixedIndex = xOffset + locXOffset + (yOffset + locYOffset) * self.MaxWidth

                    local block = self._Blocks[fixedIndex]

                    if not block or not block.Enabled then
                        entity:SetIsValid(false)
                        break
                    end
                    
                end
            end
            
            :: CONTINUE ::
        end
    end
end

return XBagOrganizeMapControl