---@class XUiPanelGame2048Map: XUiNode
---@field _Control XGame2048Control
---@field _GameControl XGame2048GameControl
local XUiPanelGame2048Map = XClass(XUiNode, 'XUiPanelGame2048Map')
local XUiGridGame2048BgGrid = require('XUi/XUiGame2048/UiGame2048Game/PanelMap/XUiGridGame2048BgGrid')
local XUiGridGame2048Grid = require('XUi/XUiGame2048/UiGame2048Game/PanelMap/XUiGridGame2048Grid')
local XUiPanelGame2048Option = require('XUi/XUiGame2048/UiGame2048Game/PanelMap/XUiPanelGame2048Option')
local XUiComGame2048MapAction = require('XUi/XUiGame2048/UiGame2048Game/PanelMap/XUiComGame2048MapAction')

function XUiPanelGame2048Map:OnStart()
    self.GridBlock.gameObject:SetActiveEx(false)
    self.GridTransfer.gameObject:SetActiveEx(false)
    self.GridStone.gameObject:SetActiveEx(false)
    self.GridStar.gameObject:SetActiveEx(false)
    self.GridDoubling.gameObject:SetActiveEx(false)
    self.GridICE.gameObject:SetActiveEx(false)
    self.GridFeverAdd.gameObject:SetActiveEx(false)

    self._GameControl = self._Control:GetGameControl()
    self._ShowedGrids = {}
    
    self._PanelOption = XUiPanelGame2048Option.New(self.PanelBoard, self)
    self._ActionCom = XUiComGame2048MapAction.New(self.GameObject, self)

    self:InitBgGrids()
    self:InitGridPools()

    self._GameControl:AddEventListener(XMVCA.XGame2048.EventIds.EVENT_GAME2048_REFRESH_NEW_GRID, self.RefreshNewGrid, self)
    self._GameControl:AddEventListener(XMVCA.XGame2048.EventIds.EVENT_GAME2048_MAPDATA_VERIFICATION, self.VerificationMap, self)
    self._GameControl:AddEventListener(XMVCA.XGame2048.EventIds.EVENT_GAME2048_REFRESH_GRID_SHOW, self.RefreshGridShow, self)

end

function XUiPanelGame2048Map:InitGridPools()
    self._GridRecycleHandle = function(grid)
        grid:Close()
    end
    
    self._GridPools = {}
    
    self._GridPools[XMVCA.XGame2048.EnumConst.GridType.Normal] = XPool.New(function()
        return self:_CreateNewGrid(self.GridBlock, XMVCA.XGame2048.EnumConst.GridType.Normal)
    end, self._GridRecycleHandle, false)

    self._GridPools[XMVCA.XGame2048.EnumConst.GridType.Rock] = XPool.New(function()
        return self:_CreateNewGrid(self.GridStone, XMVCA.XGame2048.EnumConst.GridType.Rock)
    end, self._GridRecycleHandle, false)

    self._GridPools[XMVCA.XGame2048.EnumConst.GridType.Star] = XPool.New(function()
        return self:_CreateNewGrid(self.GridStar, XMVCA.XGame2048.EnumConst.GridType.Star)
    end, self._GridRecycleHandle, false)

    self._GridPools[XMVCA.XGame2048.EnumConst.GridType.Doubling] = XPool.New(function()
        return self:_CreateNewGrid(self.GridDoubling, XMVCA.XGame2048.EnumConst.GridType.Doubling)
    end, self._GridRecycleHandle, false)

    self._GridPools[XMVCA.XGame2048.EnumConst.GridType.ICE] = XPool.New(function()
        return self:_CreateNewGrid(self.GridICE, XMVCA.XGame2048.EnumConst.GridType.ICE)
    end, self._GridRecycleHandle, false)

    self._GridPools[XMVCA.XGame2048.EnumConst.GridType.Transfer] = XPool.New(function()
        return self:_CreateNewGrid(self.GridTransfer, XMVCA.XGame2048.EnumConst.GridType.Transfer)
    end, self._GridRecycleHandle, false)

    self._GridPools[XMVCA.XGame2048.EnumConst.GridType.FeverTurnAdds] = XPool.New(function()
        return self:_CreateNewGrid(self.GridFeverAdd, XMVCA.XGame2048.EnumConst.GridType.FeverTurnAdds)
    end, self._GridRecycleHandle, false)
end

function XUiPanelGame2048Map:_CreateNewGrid(prefab, gridType)
    local go = CS.UnityEngine.GameObject.Instantiate(prefab, prefab.transform.parent)
    local grid = XUiGridGame2048Grid.New(go, self)
    grid:Open()
    grid:SetGridType(gridType)
    grid:Close()
    return grid
end

function XUiPanelGame2048Map:InitBgGrids()
    self._BgGrids = {}
    
    XUiHelper.RefreshCustomizedList(self.ImgGrid1.transform.parent, self.ImgGrid1, 16, function(index, go)
        local grid = XUiGridGame2048BgGrid.New(go, self, index)
        grid:Open()
        self._BgGrids[index] = grid
    end)
end

function XUiPanelGame2048Map:CheckUiGridPoolIsExsistByType(type)
    return self._GridPools[type] and true or false
end

-- 直接刷新棋盘里的格子状态
function XUiPanelGame2048Map:RefreshMap()
    local gridEntities = self._GameControl:GetGridEntities()
    -- 先回收
    if not XTool.IsTableEmpty(self._ShowedGrids) then
        for i, v in pairs(self._ShowedGrids) do
            local type = v:GetGridType()
            if XTool.IsNumberValid(type) and self._GridPools[type] then
                self._GridPools[type]:ReturnItemToPool(v)
            end
        end

        self._ShowedGrids = {}
    end
    -- 再刷新
    ---@param v XGame2048Grid
    for i, v in pairs(gridEntities) do
        -- 忽略非法坐标的方块
        local x = v:GetX()
        local y = v:GetY()

        if x < 1 or x > self._GameControl:GetWidth() or y < 1 or y > self._GameControl:GetHeight() then
            goto CONTINUE
        end
        
        local type = v:GetGridType()
        if XTool.IsNumberValid(type) and self._GridPools[type] then
            local grid = self._GridPools[type]:GetItemFromPool()
            
            if grid == nil then
                goto CONTINUE
            end

            grid:Open()
            grid:SetGridType(type)
            grid:RefreshData(v)
            local posIndex = v:GetX() + (v:GetY() - 1) * self._GameControl:GetWidth()
            local block = self._BgGrids[posIndex]
            if block then
                grid.Transform.position = block.Transform.position
                grid:SetNormalizePos(v:GetX(), v:GetY())
            end
            
            self._ShowedGrids[v.Uid] = grid
        end
        
        ::CONTINUE::
    end
    -- 隐藏雷击瞄准
    self.GridWarning.gameObject:SetActiveEx(false)
    -- 隐藏全局音效
    self._ActionCom:ResetSFXLock()
end

-- 展示新生成的格子
---@param grid XGame2048Grid
function XUiPanelGame2048Map:RefreshNewGrid(grid)
    if not XTool.IsTableEmpty(grid) then
        -- 忽略非法坐标的方块
        local x = grid:GetX()
        local y = grid:GetY()

        if x < 1 or x > self._GameControl:GetWidth() or y < 1 or y > self._GameControl:GetHeight() then
            goto CONTINUE
        end

        local type = grid:GetGridType()
        if XTool.IsNumberValid(type) and self._GridPools[type] then
            local gridUi = self._GridPools[type]:GetItemFromPool()
            
            gridUi:Open()
            gridUi:SetGridType(type)
            gridUi:RefreshData(grid)
            local posIndex = grid:GetX() + (grid:GetY() - 1) * self._GameControl:GetWidth()
            local block = self._BgGrids[posIndex]
            if block then
                gridUi.Transform.position = block.Transform.position
                gridUi:SetNormalizePos(grid:GetX(), grid:GetY())
            end

            self._ShowedGrids[grid.Uid] = gridUi
        else
            XLog.Error("请求生成方块的UI对象池不存在", "类型: "..tostring(type), "数据："..tostring(grid))
        end

        ::CONTINUE::
    else
        XLog.Error('请求生成方块的数据为空')
    end
end

-- 校验棋盘数据层和显示层是否一致
function XUiPanelGame2048Map:VerificationMap()
    self._ActionCom:ResetSFXLock()
    
    local gridEntities = self._GameControl:GetGridEntities()
    
    if not XTool.IsTableEmpty(gridEntities) and not XTool.IsTableEmpty(self._ShowedGrids) then
        local isValid = true
        -- 简单检查数目一致性
        local dataCount = XTool.GetTableCount(gridEntities)
        local showCount = XTool.GetTableCount(self._ShowedGrids)

        if dataCount ~= showCount then
            isValid = false
            XLog.Error("数据长度不一致","数据层方块数:"..tostring(XTool.GetTableCount(gridEntities)), "显示层方块数"..tostring(XTool.GetTableCount(self._ShowedGrids)))
        end

        if isValid then
            -- 检查每个坐标的格子是否一致
            local posEqualsCount = 0 -- 两边坐标一一对上的数量
            -- 获取数据层坐标-数据映射
            local pos2Data = {}
            for i1, gridData in pairs(gridEntities) do
                pos2Data[gridData:GetX() * 100 + gridData:GetY()] = gridData
            end
           
            for i2, gridShow in pairs(self._ShowedGrids) do
                local index = gridShow.X * 100 + gridShow.Y
                
                local data = pos2Data[index]
                if data then
                    if data.Id ~= gridShow.Id then
                        XLog.Error("对应位置上的方块类型不一样", "坐标："..tostring(gridShow.X)..","..tostring(gridShow.Y), data)
                        isValid = false
                    elseif gridShow.GameObject.activeInHierarchy == false then
                        XLog.Error("对应位置上的方块UI是隐藏的", "坐标："..tostring(gridShow.X)..","..tostring(gridShow.Y), data)
                        isValid = false
                    end
                    posEqualsCount = posEqualsCount + 1
                    pos2Data[index] = nil
                else
                    XLog.Error("显示层的方块在数据对应位置中找不到", "坐标："..tostring(gridShow.X)..","..tostring(gridShow.Y), data)
                    isValid = false
                end
            end
            
            if posEqualsCount ~= dataCount then
                XLog.Error("存在数据层方块的位置不与显示层的位置重合")
                isValid = false
            end
        end
        
        -- 不一致时强制同步
        if not isValid then
            XLog.Error('显示层和数据层数据不一致，尝试同步')
            self:RefreshMap()
        end
    else
        XLog.Error("存在空数据","数据层方块数:"..tostring(XTool.GetTableCount(gridEntities)), "显示层方块数"..tostring(XTool.GetTableCount(self._ShowedGrids)))
    end
end

--- 刷新已有方块的显示
---@param gridData XGame2048Grid
function XUiPanelGame2048Map:RefreshGridShow(gridData)
    if not gridData then
        return
    end
    
    local gridUi = self._ShowedGrids[gridData.Uid]

    if gridUi then
        gridUi:RefreshData(gridData)
    end
end

--region get/set

--- 回收方块
---@param uiGrid XUiGridGame2048Grid
function XUiPanelGame2048Map:ReturnUiGridToPool(uiGrid)
    local type = uiGrid:GetGridType()

    -- 首先从显示列表中移除
    self._ShowedGrids[uiGrid.Uid] = nil

    -- 接着回收到对应对象池中
    if XTool.IsNumberValid(type) and self:CheckUiGridPoolIsExsistByType(type) then
        self._GridPools[type]:ReturnItemToPool(uiGrid)
    else
        XLog.Error('类型为：'..tostring(type)..' 的对象池不存在')
    end
end

--- 根据uid获取当前展示的方块UI节点
function XUiPanelGame2048Map:GetShowedUiGridByUid(uid)
    return self._ShowedGrids[uid]
end

--- 根据连续索引获取指定位置的地块UI节点
--- 连续索引：二维坐标转一维后的索引
function XUiPanelGame2048Map:GetShowedUiGridByIndex(index)
    return self._BgGrids[index]
end

--endregion


return XUiPanelGame2048Map