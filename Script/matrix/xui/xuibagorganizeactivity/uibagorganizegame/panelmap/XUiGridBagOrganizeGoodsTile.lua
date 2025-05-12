---@class XUiGridBagOrganizeGoodsTile:XUiNode
---@field _Control XBagOrganizeActivityControl
---@field _GameControl XBagOrganizeActivityGameControl
local XUiGridBagOrganizeGoodsTile = XClass(XUiNode, 'XUiGridBagOrganizeGoodsTile')

local EmptyColor = CS.UnityEngine.Color(1, 1, 1, 0)

function XUiGridBagOrganizeGoodsTile:OnStart()
    self:InitBlock()
    self._GameControl = self._Control:GetGameControl()
    self.GridBtn.CallBack = handler(self, self.OnClickEvent)

    self.DragHandle:AddBeginDragListener(handler(self, self.OnBeginDragEvent))
    self.DragHandle:AddDragListener(handler(self, self.OnDragEvent))
    self.DragHandle:AddEndDragListener(handler(self, self.OnEndDragEvent))
end

function XUiGridBagOrganizeGoodsTile:InitBlock()
    -- 固定4x4尺寸
    self._Blocks = {}
    XUiHelper.RefreshCustomizedList(self.GridBlock.transform.parent, self.GridBlock, 16, function(index, go)
        local img = go:GetComponent(typeof(CS.UnityEngine.UI.Image))
        if img then
            table.insert(self._Blocks, img)
        else
            XLog.Error('货物格子缺少Image组件')
        end
    end)
end

function XUiGridBagOrganizeGoodsTile:RefreshData(goodsId, uid)
    self._GoodsId = goodsId
    self._GoodsUid = uid
    ---@type XTableBagOrganizeGoods
    local cfg = self._Control:GetGoodsCfgById(self._GoodsId)
    
    if cfg then
        local hexcolor = string.gsub(cfg.BlockColor, '#', '')
        local blockColor = XUiHelper.Hexcolor2Color(hexcolor)
        
        -- 基本信息
        self.ImgLand:SetRawImage(cfg.IconAddress)
        -- 格子
        local blocks = self._GameControl.GoodsControl:GetPlacedGoodsBlocks(self._GoodsUid)
        if not XTool.IsTableEmpty(blocks) then
            for i, v in ipairs(blocks) do
                ---@type UnityEngine.UI.Image
                local img = self._Blocks[i]
                img.raycastTarget = true

                if v == XMVCA.XBagOrganizeActivity.EnumConst.GoodsBlockType.Normal then
                    img.color = blockColor
                elseif v == XMVCA.XBagOrganizeActivity.EnumConst.GoodsBlockType.Empty then
                    img.color = EmptyColor
                    img.raycastTarget = false
                end
            end
        end
        -- 图片旋转
        local rotateTimes = self._GameControl.GoodsControl:GetPlacedGoodsRotateTimes(self._GoodsUid)
        local eulerAngle = rotateTimes * 90 % 360
        self.ImgLand.transform.rotation = CS.UnityEngine.Quaternion.Euler(0, 0, - eulerAngle)
        
        self:RefreshBlockShowOnly()
    end
end

--- 在已经显示且放置的情况下，刷新每个格子的显示，用于多背包切换
function XUiGridBagOrganizeGoodsTile:RefreshBlockShowOnly()
    ---@type XBagOrganizeGoodsEntity
    local entity = self._GameControl:GetScopeEntityById(self._GoodsUid)
    local needValidShow = entity and not entity:GetIsValid()

    if needValidShow then
        ---@type XTableBagOrganizeGoods
        local cfg = self._Control:GetGoodsCfgById(self._GoodsId)

        local hexcolorConflict = string.gsub(self._Control:GetClientConfigText('ConflictColor'), '#', '')
        hexcolorConflict = XUiHelper.Hexcolor2Color(hexcolorConflict)
        local leftUpX = entity:GetLeftUpX()
        local leftUpY = entity:GetLeftUpY()

        local xOffset = leftUpX
        local yOffset = leftUpY - 1

        if cfg then
            -- 格子
            local blocks = self._GameControl.GoodsControl:GetPlacedGoodsBlocks(self._GoodsUid)
            if not XTool.IsTableEmpty(blocks) then
                for i, v in ipairs(blocks) do
                    if v ~= XMVCA.XBagOrganizeActivity.EnumConst.GoodsBlockType.Empty then
                        ---@type UnityEngine.UI.Image
                        local img = self._Blocks[i]

                        local locXOffset = (i - 1) % 4
                        local locYOffset = XMath.ToMinInt((i - 1) / 4)
                        local fixedIndex = xOffset + locXOffset + (yOffset + locYOffset) * self._GameControl.MapControl:GetMapWidth()

                        if not self._GameControl.MapControl:GetBlockIsEnabledByIndex(fixedIndex) then
                            img.color = hexcolorConflict
                        end
                    end
                end
            end
        end
    end
end

function XUiGridBagOrganizeGoodsTile:RefreshPosition(blockGrid)
    self.Transform.position = blockGrid.Transform.position
end

function XUiGridBagOrganizeGoodsTile:OnClickEvent()
    self._GameControl:SetGoodsToPrePlace(self._GoodsUid, self.Transform.position)
end

--region 拖拽接口
function XUiGridBagOrganizeGoodsTile:OnBeginDragEvent(eventData)
    -- 唤起编辑面板
    self:OnClickEvent()
    -- 定位
    self._GameControl:DispatchEvent(XMVCA.XBagOrganizeActivity.EventIds.EVENT_GOODSINLIST_CALL_OPTIONPOSITION_INIT, eventData, true)
    self._GameControl:DispatchEvent(XMVCA.XBagOrganizeActivity.EventIds.EVENT_GOODSINLIST_CALL_OPTION_BEGINDRAG, eventData)
end

function XUiGridBagOrganizeGoodsTile:OnDragEvent(eventData)
    self._GameControl:DispatchEvent(XMVCA.XBagOrganizeActivity.EventIds.EVENT_GOODSINLIST_CALL_OPTION_DRAGGING, eventData)
end

function XUiGridBagOrganizeGoodsTile:OnEndDragEvent(eventData)
    self._GameControl:DispatchEvent(XMVCA.XBagOrganizeActivity.EventIds.EVENT_GOODSINLIST_CALL_OPTION_ENDDRAG, eventData)
end
--endregion

return XUiGridBagOrganizeGoodsTile