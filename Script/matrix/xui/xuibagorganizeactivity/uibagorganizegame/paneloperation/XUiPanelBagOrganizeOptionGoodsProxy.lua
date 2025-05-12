---@class XUiPanelBagOrganizeOptionGoodsProxy: XUiNode
---@field _Control XBagOrganizeActivityControl
---@field _GameControl XBagOrganizeActivityGameControl
local XUiPanelBagOrganizeOptionGoodsProxy = XClass(XUiNode, 'XUiPanelBagOrganizeOptionGoodsProxy')

--- 冲突方块的颜色
local ConflictColor = nil
--- 选择时的普通方块的颜色
local SelectedColor = nil
--- 透明色
local EmptyColor = CS.UnityEngine.Color(1, 1, 1, 0)

function XUiPanelBagOrganizeOptionGoodsProxy:OnStart()
    self._GameControl = self._Control:GetGameControl()
    self._PriceGridList = {}
    self._LastFocusBlocks = {}

    local hexcolorConflict = string.gsub(self._Control:GetClientConfigText('ConflictColor'), '#', '')
    ConflictColor = XUiHelper.Hexcolor2Color(hexcolorConflict)
end

function XUiPanelBagOrganizeOptionGoodsProxy:OnEnable()
    self._GoodsId = self._GameControl:GetPreItemId()
    self:InitSelectedColor()
    self:RefreshPrices()
    self._GameControl:AddEventListener(XMVCA.XBagOrganizeActivity.EventIds.EVENT_REFRESH_OPTION_SHOW, self.RefreshShow, self)
    self._GameControl:AddEventListener(XMVCA.XBagOrganizeActivity.EventIds.EVENT_RANDOMEVENT_EFFECT_VALID, self.RefreshPrices, self)

end

function XUiPanelBagOrganizeOptionGoodsProxy:OnDisable()
    self._GoodsId = nil
    self:BackAllPriceGrids()
    self._GameControl:RemoveEventListener(XMVCA.XBagOrganizeActivity.EventIds.EVENT_REFRESH_OPTION_SHOW, self.RefreshShow, self)
    self._GameControl:RemoveEventListener(XMVCA.XBagOrganizeActivity.EventIds.EVENT_RANDOMEVENT_EFFECT_VALID, self.RefreshPrices, self)
    self:ClearLastFocusBlocksShow()
    self._LastLeftUpX = nil
    self._LastLeftUpY = nil
end

function XUiPanelBagOrganizeOptionGoodsProxy:OnDestroy()
    self._GameControl = nil
end

function XUiPanelBagOrganizeOptionGoodsProxy:OnAddEvent()
    if not self._IsConflict and self._GameControl:PlaceGoods() then
        self._GameControl:DispatchEvent(XMVCA.XBagOrganizeActivity.EventIds.EVENT_REFRESH_GOODS_SHOW)
        self._GameControl:DispatchEvent(XMVCA.XBagOrganizeActivity.EventIds.EVENT_CANCEL_ADD_GOODS)
        return true
    else
        XUiManager.TipMsg(self._Control:GetClientConfigText('ConflictTipsBeforePlace'))
        return false
    end
end

function XUiPanelBagOrganizeOptionGoodsProxy:DeleteByHand()
    self._GameControl:CancelPlaceGoods()
    return true
end

function XUiPanelBagOrganizeOptionGoodsProxy:OnDeleteEvent()
    self._GameControl:CancelPlaceGoods()
    self._GameControl:DispatchEvent(XMVCA.XBagOrganizeActivity.EventIds.EVENT_CANCEL_ADD_GOODS)
    return true
end

function XUiPanelBagOrganizeOptionGoodsProxy:AfterChangeEvent()
    self:RefreshShow()
end

-- 货物尺寸是4x4，旋转会越界一半
function XUiPanelBagOrganizeOptionGoodsProxy:GetFixSize()
    return 2
end

function XUiPanelBagOrganizeOptionGoodsProxy:GetIsConflict()
    return self._IsConflict
end

function XUiPanelBagOrganizeOptionGoodsProxy:RefreshNewItem()
    if XTool.IsNumberValid(self._GameControl:GetPreItemId()) then
        -- 修正位置
        local x, y = self._GameControl.MapControl.MapCenterX, self._GameControl.MapControl.MapCenterY
        local index = x + (y - 1) * self._GameControl.MapControl.MaxWidth
        local block = self.Parent:GetBlockGridByIndex(index)

        self.Parent:SetPosition(block, x - 2, y - 1)
        self:RefreshShow()
    end
end

function XUiPanelBagOrganizeOptionGoodsProxy:RefreshShow()
    local goodsId = self._GameControl:GetPreItemId()

    if self._GoodsId ~= goodsId then
        self._GoodsId = goodsId
        self:InitSelectedColor()
    end

    if not XTool.IsNumberValid(self._GoodsId) then
        return
    end

    ---@type XTableBagOrganizeGoods
    local cfg = self._Control:GetGoodsCfgById(self._GoodsId)
    
    if cfg then
        -- 基本信息
        self.ImgGoods.gameObject:SetActiveEx(true)
        self.ImgGoods:SetRawImage(cfg.IconAddress)
        -- 格子
        local blocks = self._GameControl:GetPreItemBlocks()

        if not XTool.IsTableEmpty(blocks) then
            local blockDefaultIconAddress = self._Control:GetClientConfigText('BlockDefaultIconAddress')
            
            local uiBlocks = self.Parent:GetUIBlocks()
            self._IsConflict = false
            for i, v in ipairs(blocks) do
                local img = uiBlocks[i]
                img:SetSprite(blockDefaultIconAddress)
                if v == XMVCA.XBagOrganizeActivity.EnumConst.GoodsBlockType.Normal then
                    img.color = SelectedColor
                elseif v == XMVCA.XBagOrganizeActivity.EnumConst.GoodsBlockType.Empty then
                    img.color = EmptyColor
                end

                if XTool.IsNumberValid(v) then
                    -- 判断对应格子有没有占位
                    if not self._GameControl:CheckPreGoodsBlockIsValidByIndex(i, v) then
                        img.color = ConflictColor
                        self._IsConflict = true
                    end
                end
            end
        end

        -- 图片旋转
        local rotateTimes = self._GameControl.GoodsControl:GetPlacedGoodsRotateTimes(self._GameControl:GetPreItemUid())
        local eulerAngle = rotateTimes * 90 % 360
        self.ImgGoods.transform.rotation = CS.UnityEngine.Quaternion.Euler(0, 0, - eulerAngle)
    end
    
    -- 刷新地块聚焦
    self:RefreshBlockFocusShow()
    
    -- 刷新确认按钮显示状态
    self.Parent:RefreshBtnYesState()
end

function XUiPanelBagOrganizeOptionGoodsProxy:ResetPosition()
    if XTool.IsNumberValid(self._GameControl:GetPreItemId()) then
        -- 重定位
        local leftUpX, leftUpY = self._GameControl:GetPreItemLeftUp()
        local centerX = leftUpX + 2
        local index = centerX + leftUpY * self._GameControl.MapControl.MaxWidth
        local block = self.Parent:GetBlockGridByIndex(index)

        self.Parent:SetPosition(block, leftUpX, leftUpY)
    end
end

function XUiPanelBagOrganizeOptionGoodsProxy:InitSelectedColor()
    ---@type XTableBagOrganizeGoods
    local cfg = self._Control:GetGoodsCfgById(self._GoodsId)

    if cfg then
        local hexcolor = string.gsub(cfg.SelectedColor, '#', '')
        SelectedColor = XUiHelper.Hexcolor2Color(hexcolor)
    end
end

function XUiPanelBagOrganizeOptionGoodsProxy:OnDragPositionUpdate(aimleftUpX, aimleftUpY, ignoreOutBoardCheck)
    -- 先直接判断目标点是否可放下
    local isOutBorad

    if ignoreOutBoardCheck then
        isOutBorad = false
    else
        isOutBorad = self._GameControl:CheckPreGoodsPositionIsOutBoard(aimleftUpX, aimleftUpY)
    end

    if not isOutBorad then
        -- 如果可以，那么就更新位置
        self.Parent:SetPositionEx(aimleftUpX, aimleftUpY, aimleftUpX + 2, aimleftUpY + 1, true)
        self:RefreshShow()
    else
        -- 无论是否越界都需要刷新聚焦显示
        self:RefreshBlockFocusShow()
    end
end

function XUiPanelBagOrganizeOptionGoodsProxy:CheckPreItemPositionIsOutBoard(leftUpX, leftUpY)
    return self._GameControl:CheckPreGoodsPositionIsOutBoard(leftUpX, leftUpY)
end

function XUiPanelBagOrganizeOptionGoodsProxy:RefreshPositionAfterFindWay(newleftUpX, newleftUpY)
    local xoffset = newleftUpX + 2
    local yoffset = newleftUpY
    self.Parent:SetPositionEx(newleftUpX, newleftUpY, newleftUpX + 2, newleftUpY + 1)
    self:RefreshShow()
end

function XUiPanelBagOrganizeOptionGoodsProxy:RefreshPrices()
    if XTool.IsNumberValid(self._GoodsId) then
        ---@type XTableBagOrganizeGoods
        local cfg = self._Control:GetGoodsCfgById(self._GoodsId)
        if cfg then
            self.PanelTotal.gameObject:SetActiveEx(true)
            local uid = self._GameControl:GetPreItemUid()
            local totalValue = self._GameControl.GoodsControl:GetGoodsTotalValue(uid)
            -- 显示基础价值
            self:BackAllPriceGrids()
            local grid = self.Parent:GetPriceGrid()
            grid:Open()
            grid:SetAddShow(self._Control:GetClientConfigText('BaseValueLabel'), cfg.Value)
            table.insert(self._PriceGridList, grid)
            -- 显示同色加成
            if self._GameControl.GoodsControl:IsGoodsSameColorCombo(uid) then
                local grid = self.Parent:GetPriceGrid()
                grid:Open()
                grid:SetAddShow(self._Control:GetClientConfigText('ComboLabel'), math.ceil(self._GameControl.GoodsControl:GetGoodsComboValue(uid)))
                table.insert(self._PriceGridList, grid)
            end
            -- 显示事件加成
            if self._GameControl.GoodsControl:IsGoodsEventBuff(uid) then
                local grid = self.Parent:GetPriceGrid()
                grid:Open()
                grid:SetAddShow(self._Control:GetClientConfigText('EventBuffLabel'), math.ceil(self._GameControl.GoodsControl:GetEventBuffValue(uid)))
                table.insert(self._PriceGridList, grid)
            end
            -- 显示总价值
            self.TxtNumTotalAdd.text = XUiHelper.FormatText(self._Control:GetClientConfigText('GoodsValueShowLabel'), totalValue)
        end
        
        -- 显示文本
        self.TxtNumTotalName.text = self._Control:GetClientConfigText('EditTotalName', 1)
    end
end

function XUiPanelBagOrganizeOptionGoodsProxy:BackAllPriceGrids()
    if not XTool.IsTableEmpty(self._PriceGridList) then
        for i = #self._PriceGridList, 1, -1 do
            self.Parent:BackPriceGrid(self._PriceGridList[i])
            table.remove(self._PriceGridList, i)
        end
    end
end

function XUiPanelBagOrganizeOptionGoodsProxy:AfterPositionChanged()

end

function XUiPanelBagOrganizeOptionGoodsProxy:RefreshBlockFocusShow()
    local leftUpX, leftUpY = self._GameControl:GetPreItemLeftUp()

    if not self.Parent.IsDragging then
        self:ClearLastFocusBlocksShow()
        return
    end
    
    -- 有上次的值，且没有变化，则不刷新
    if (self._LastLeftUpX and self._LastLeftUpY) and (self._LastLeftUpX == leftUpX and self._LastLeftUpY == leftUpY) then
        return
    end

    local blocks = self._GameControl:GetPreItemBlocks()
    
    if not XTool.IsTableEmpty(blocks) then
        self:ClearLastFocusBlocksShow()
        
        for i, v in ipairs(blocks) do
            if XTool.IsNumberValid(v) then
                local locXOffset = (i - 1) % 4
                local locYOffset = XMath.ToMinInt((i - 1) / 4)

                -- 判断二维坐标是否超出范围
                local blockX = leftUpX + locXOffset
                local blockY = leftUpY + locYOffset

                if not (blockX <= 0 or blockX > self._GameControl.MapControl.MaxWidth or blockY <= 0 or blockY > self._GameControl.MapControl.MaxHeight) then
                    -- 转换对应格子在地图中的索引
                    local yOffset = leftUpY - 1
                    local fixedIndex = leftUpX + locXOffset + (yOffset + locYOffset) * self._GameControl.MapControl.MaxWidth
                    -- 根据索引获取地块控制对象
                    local block = self.Parent:GetBlockGridByIndex(fixedIndex)

                    if block then
                        block:SetFocusState(true)
                        table.insert(self._LastFocusBlocks, block)
                    end
                end
            end
        end
    end

    if (not self._LastLeftUpX or not self._LastLeftUpY) or (self._LastLeftUpX ~= leftUpX or self._LastLeftUpY ~= leftUpY) then
        self._LastLeftUpX = leftUpX
        self._LastLeftUpY = leftUpY
    end
end

function XUiPanelBagOrganizeOptionGoodsProxy:ClearLastFocusBlocksShow()
    if not XTool.IsTableEmpty(self._LastFocusBlocks) then
        for i = #self._LastFocusBlocks, 1, -1 do
            self._LastFocusBlocks[i]:SetFocusState(false)
            table.remove(self._LastFocusBlocks, i)
        end
    end
end

return XUiPanelBagOrganizeOptionGoodsProxy