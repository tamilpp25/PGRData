---@class XUiPanelBagOrganizeMap:XUiNode
---@field _Control XBagOrganizeActivityControl
---@field _GameControl XBagOrganizeActivityGameControl
local XUiPanelBagOrganizeMap = XClass(XUiNode, 'XUiPanelBagOrganizeMap')

local XUiGridBagOrganizeBlock = require('XUi/XUiBagOrganizeActivity/UiBagOrganizeGame/PanelMap/XUiGridBagOrganizeBlock')
local XUiGridBagOrganizeGoodsTile = require('XUi/XUiBagOrganizeActivity/UiBagOrganizeGame/PanelMap/XUiGridBagOrganizeGoodsTile')

local BagBgSizeDiff = nil

function XUiPanelBagOrganizeMap:OnStart(blockGrid)
    self.BlockGrid = blockGrid
    self._StageId = self._Control:GetCurStageId()
    self.BlockGrid.gameObject:SetActiveEx(false)
    self.GridGoods.gameObject:SetActiveEx(false)
    self._GameControl = self._Control:GetGameControl()
    self._GameControl:AddEventListener(XMVCA.XBagOrganizeActivity.EventIds.EVENT_REFRESH_GOODS_SHOW, self.RefreshGoodsShow, self)
    self._GameControl:AddEventListener(XMVCA.XBagOrganizeActivity.EventIds.EVENT_REFRESH_MAP_SHOW, self.InitMapInBagChanged, self)

    BagBgSizeDiff = self._Control:GetClientConfigNum('BagBgSizeDiff')
end

function XUiPanelBagOrganizeMap:OnDestroy()
    self._GameControl = nil
end

function XUiPanelBagOrganizeMap:InitMap()
    local leftUpBlock = nil
    local rightDownBlock = nil
    
    if self._BlockGrids == nil then
        local gridSize = self._Control:GetClientConfigVector2('GridSize')
        self._GameControl.MapControl:InitBlockSize(gridSize.x, gridSize.y)
        self._BlockGrids = {}
        local index = 1
        for row = 1, self._GameControl.MapControl:GetMapHeight() do
            for column = 1, self._GameControl.MapControl:GetMapWidth() do
                local go = CS.UnityEngine.GameObject.Instantiate(self.BlockGrid, self.BlockGrid.transform.parent)
                local grid = XUiGridBagOrganizeBlock.New(go, self, column, row)
                grid:Open()
                table.insert(self._BlockGrids, grid)

                go.name = tostring(index)..'('..tostring(column)..','..tostring(row)..')'
                index = index + 1

                if grid:GetIsEnabled() then
                    if not leftUpBlock then
                        leftUpBlock = grid
                    end

                    rightDownBlock = grid
                end
            end
        end
    else
        -- 重置格子状态
        if not XTool.IsTableEmpty(self._BlockGrids) then
            for i, block in pairs(self._BlockGrids) do
                if block:Init() then
                    if not leftUpBlock then
                        leftUpBlock = block
                    end

                    rightDownBlock = block
                end
            end
        end
        -- 刷新货物、材料显示
        self:RefreshGoodsShow()
    end

    if leftUpBlock and rightDownBlock then
        -- 计算矩形尺寸
        local bagWidth = rightDownBlock.X - leftUpBlock.X + BagBgSizeDiff
        local bagHeight = rightDownBlock.Y - leftUpBlock.Y + BagBgSizeDiff
        -- 计算左上角离散坐标和右下角离散坐标的中间值
        local centerPosX = (leftUpBlock.X - 1 + rightDownBlock.X) * 0.5
        local centerPosY = - (leftUpBlock.Y - 1 + rightDownBlock.Y) * 0.5
        -- 根据左上角的方块定位背景图片位置
        self.BoxRoot.transform.anchoredPosition = Vector2(centerPosX * self._GameControl.MapControl:GetBlockWidth(), centerPosY * self._GameControl.MapControl:GetBlockHeight())

        -- 更新尺寸大小
        self.BoxRoot.transform.sizeDelta = Vector2(bagWidth * self._GameControl.MapControl:GetBlockWidth(), bagHeight * self._GameControl.MapControl:GetBlockHeight())
    end
    
    -- 非多背包玩法需要手动播放展开动画
    if not self._GameControl:IsMultyBagEnabled() then
        self.Parent.ComAnim:PlayAnimationWithMask('UiBagOrganizeImgBox_star')
    end
end

function XUiPanelBagOrganizeMap:GetBlockGridByIndex(index)
    return self._BlockGrids[index]
end

function XUiPanelBagOrganizeMap:RefreshGoodsShow()
    local entitiesList = self._GameControl.GoodsControl:GetPlacedGoodsEntityList()
    local count = #entitiesList + 1

    if self._GoodsGrid == nil then
        self._GoodsGrid = {}
    end

    local blockWidth = self._GameControl.MapControl:GetBlockWidth()
    local blockHeight = self._GameControl.MapControl:GetBlockHeight()
    XUiHelper.RefreshCustomizedList(self.PanelGoods, self.GridGoods, #entitiesList, function(i, go)
        local grid = self._GoodsGrid[i]
        local entity = entitiesList[i]
        if not grid then
            grid = XUiGridBagOrganizeGoodsTile.New(go, self)
            table.insert(self._GoodsGrid, grid)
        end
        grid:Open()
        -- 刷新基本信息
        grid:RefreshData(entity.Id, entity.Uid)
        -- 刷新坐标
        local leftUpX = entity:GetLeftUpX()
        local leftUpY = entity:GetLeftUpY()

        local centerX = leftUpX + 2
        local centerY = leftUpY + 1
        
        grid.Transform.localPosition = Vector3((centerX - 1) * blockWidth, - centerY * blockHeight)
    end)

    -- 隐藏多余的
    if not XTool.IsTableEmpty(self._GoodsGrid) then
        for i = count, 100 do
            if self._GoodsGrid[i] then
                self._GoodsGrid[i]:Close()
            else
                break
            end
        end
    end
end

function XUiPanelBagOrganizeMap:InitMapInBagChanged()
    self:InitMap()

    if not XTool.IsTableEmpty(self._GoodsGrid) then
        for i, v in pairs(self._GoodsGrid) do
            if v:IsNodeShow() then
                v:RefreshBlockShowOnly()
            end
        end
    end

    self.Parent.ComAnim:PlayAnimationWithMask('UiBagOrganizeImgBox_star')
end

return XUiPanelBagOrganizeMap