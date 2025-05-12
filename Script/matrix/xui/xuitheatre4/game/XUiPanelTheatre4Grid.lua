---@class XUiPanelTheatre4Grid : XUiNode
---@field private _Control XTheatre4Control
---@field Parent XUiPanelTheatre4Map
local XUiPanelTheatre4Grid = XClass(XUiNode, "XUiPanelTheatre4Grid")
local CSVector2 = CS.UnityEngine.Vector2

function XUiPanelTheatre4Grid:OnStart()
    self.GridGo = {
        [XEnumConst.Theatre4.GridType.Empty] = self.PanelEmptyGrid,
        [XEnumConst.Theatre4.GridType.Hurdle] = self.PanelObstacleGrid,
        [XEnumConst.Theatre4.GridType.Shop] = self.PanelEventGrid,
        [XEnumConst.Theatre4.GridType.Box] = self.PanelEventGrid,
        [XEnumConst.Theatre4.GridType.Monster] = self.PanelEventGrid,
        [XEnumConst.Theatre4.GridType.Boss] = self.PanelBossGrid,
        [XEnumConst.Theatre4.GridType.Event] = self.PanelEventGrid,
        [XEnumConst.Theatre4.GridType.Start] = self.PanelStartGrid,
        [XEnumConst.Theatre4.GridType.Blank] = self.PaneBlankGrid,
        [XEnumConst.Theatre4.GridType.Building] = self.PanelBuildingGrid,
    }
    self.GridProxy = {
        [XEnumConst.Theatre4.GridType.Empty] = require("XUi/XUiTheatre4/Game/Grid/XUiPanelTheatre4EmptyGrid"),
        [XEnumConst.Theatre4.GridType.Hurdle] = require("XUi/XUiTheatre4/Game/Grid/XUiPanelTheatre4ObstacleGrid"),
        [XEnumConst.Theatre4.GridType.Shop] = require("XUi/XUiTheatre4/Game/Grid/XUiPanelTheatre4EventGrid"),
        [XEnumConst.Theatre4.GridType.Box] = require("XUi/XUiTheatre4/Game/Grid/XUiPanelTheatre4EventGrid"),
        [XEnumConst.Theatre4.GridType.Monster] = require("XUi/XUiTheatre4/Game/Grid/XUiPanelTheatre4EventGrid"),
        [XEnumConst.Theatre4.GridType.Boss] = require("XUi/XUiTheatre4/Game/Grid/XUiPanelTheatre4BossGrid"),
        [XEnumConst.Theatre4.GridType.Event] = require("XUi/XUiTheatre4/Game/Grid/XUiPanelTheatre4EventGrid"),
        [XEnumConst.Theatre4.GridType.Start] = require("XUi/XUiTheatre4/Game/Grid/XUiPanelTheatre4StartGrid"),
        [XEnumConst.Theatre4.GridType.Blank] = require("XUi/XUiTheatre4/Game/Grid/XUiPanelTheatre4BlankGrid"),
        [XEnumConst.Theatre4.GridType.Building] = require("XUi/XUiTheatre4/Game/Grid/XUiPanelTheatre4BuildingGrid"),
    }
    -- 当前格子类型
    self.CurGridType = XEnumConst.Theatre4.GridType.Nothing
    self.CurGridGo = nil
    ---@type XUiPanelTheatre4BaseGrid
    self.CurGridProxy = nil
    self.GridId = 0
    -- 当前是第几层
    self.CurrentFloor = 0
end

function XUiPanelTheatre4Grid:SetGridId(gridId)
    self.GridId = gridId
end

-- 初始化格子大小和位置
function XUiPanelTheatre4Grid:InitGridSizeAndPos(offsetX, offsetY)
    local gridData = self._Control.MapSubControl:GetMapGridData(self.Parent.MapId, self.GridId)
    if not gridData then
        XLog.Error("InitGridSizeAndPos error: gridData is nil")
        return
    end
    -- 格子的长度和宽度
    local sizeX, sizeY = gridData:GetGridSize()
    local length = sizeX * XEnumConst.Theatre4.MapGridSizeX
    local width = sizeY * XEnumConst.Theatre4.MapGridSizeY
    self.PanelMapGrid.sizeDelta = CSVector2(length, width)
    -- 格子的位置
    local posX, posY = gridData:GetGridPos()
    local x = posX * XEnumConst.Theatre4.MapGridSizeX + offsetX
    local y = posY * XEnumConst.Theatre4.MapGridSizeY + offsetY
    self.PanelMapGrid.anchoredPosition = CSVector2(x, y)
    -- 格子名字
    self.GameObject.name = string.format("Grid_%d", self.GridId)
end

function XUiPanelTheatre4Grid:Refresh()
    local gridData = self._Control.MapSubControl:GetMapGridData(self.Parent.MapId, self.GridId)
    if not gridData then
        XLog.Error("Refresh error: gridData is nil")
        return
    end
    local gridType = gridData:GetGridType()
    if gridData:IsGridTypeNothing() or self.Parent:CheckGridIsHidden(gridData:GetGridPos()) then
        if self.CurGridProxy then
            self.CurGridProxy:Close()
            self.CurGridProxy = nil
        end
        return
    end
    if not self.GridGo[gridType] then
        if XEnumConst.Theatre4.IsDebug then
            XLog.Warning(string.format("<color=#F1D116>Theatre4:</color> 没有对应的格子类型,gridType:%d", gridType))
        end
        return
    end
    -- 如果当前格子类型和要刷新的格子类型一样，直接刷新
    if self.CurGridType == gridType then
        self.CurGridProxy:Refresh()
        self.CurGridProxy:PlayGridAnim()
        return
    end
    -- 如果当前格子类型和要刷新的格子类型不一样，关闭当前格子，打开新的格子
    if self.CurGridProxy then
        self.CurGridProxy:Close()
        self.CurGridProxy = nil
    end
    self.CurGridType = gridType
    self.CurGridGo = self.GridGo[gridType]
    self.CurGridProxy = self.GridProxy[gridType].New(self.CurGridGo, self)
    self.CurGridProxy:Open()
    self.CurGridProxy:SetGridData(self.Parent.MapId, gridData, self.CurrentFloor)
    self.CurGridProxy:Refresh()
    self.CurGridProxy:PlayGridAnim()
    -- 时间回溯后, 隐藏建筑特效
    self.CurGridProxy:HideBuildingEffect()
end

-- 获取格子的RectTransform
---@return number, UnityEngine.RectTransform 格子Id, 格子RectTransform
function XUiPanelTheatre4Grid:GetGridRectTransform()
    return self.GridId, self.PanelMapGrid
end

-- 处理层级动画
function XUiPanelTheatre4Grid:HandleFloorAnim(lastFloor, curFloor, isLastFrame)
    if self.CurGridProxy then
        self.CurGridProxy:HandleFloorAnim(lastFloor, curFloor, isLastFrame)
    end
end

-- 设置层级
function XUiPanelTheatre4Grid:SetFloor(floor)
    self.CurrentFloor = floor
    if self.CurGridProxy then
        self.CurGridProxy:SetFloor(floor)
    end
end

-- 播放被打断的格子动画
function XUiPanelTheatre4Grid:PlayInterruptGridAnim()
    if self.CurGridProxy then
        self.CurGridProxy:PlayInterruptGridAnim()
    end
end

--region 主动触发

-- 主动触发格子点击
function XUiPanelTheatre4Grid:TriggerGridClick()
    if self.CurGridProxy and self.CurGridProxy.OnBtnGridClick then
        self.CurGridProxy:OnBtnGridClick()
    end
end

--endregion

--region 格子数据

-- 获取格子世界坐标
---@return number, number X坐标, Y坐标
function XUiPanelTheatre4Grid:GetGridWorldPos()
    if self.CurGridProxy then
        return self.CurGridProxy:GetGridWorldPos()
    end
end

--endregion

--region 建造相关

-- 显示建造可选的特效
function XUiPanelTheatre4Grid:ShowBuildOptionalEffect()
    if self.CurGridProxy then
        self.CurGridProxy:SetSelected(true)
    end
end

-- 隐藏建造可选的特效
function XUiPanelTheatre4Grid:HideBuildOptionalEffect()
    if self.CurGridProxy then
        self.CurGridProxy:SetSelected(false)
    end
end

-- 显示建造特效
function XUiPanelTheatre4Grid:ShowBuildEffect()
    if self.CurGridProxy then
        local selectGridId = self._Control.MapSubControl:GetMapBuildGridId()
        self.CurGridProxy:ShowBuildingEffect(selectGridId)
    end
end

-- 隐藏建造特效
function XUiPanelTheatre4Grid:HideBuildEffect()
    if self.CurGridProxy then
        self.CurGridProxy:HideBuildingEffect()
        
        -- 时间回溯后, 部分建筑, 可能变成空格子, 需要隐藏它的建筑特效
        ---@type XUiPanelTheatre4EmptyGrid
        local emptyGrid = self.GridProxy[XEnumConst.Theatre4.GridType.Empty]
        if emptyGrid then
            emptyGrid:HideBuildingEffect()
        end
    end
end

-- 显示建筑详情特效
function XUiPanelTheatre4Grid:ShowBuildDetailEffect()
    if self.CurGridProxy then
        self.CurGridProxy:ShowBuildingEffect(0)
    end
end

-- 隐藏建筑详情特效
function XUiPanelTheatre4Grid:HideBuildDetailEffect()
    if self.CurGridProxy then
        self.CurGridProxy:HideBuildingEffect()
    end
end

--endregion

--region 特效相关

-- 播放格子特效
function XUiPanelTheatre4Grid:PlayGridEffect()
    if self.CurGridProxy then
        self.CurGridProxy:PlayGridEffect()
    end
end

-- 隐藏格子特效
function XUiPanelTheatre4Grid:HideGridEffect()
    if self.CurGridProxy then
        self.CurGridProxy:HideGridEffect()
    end
end

--endregion

return XUiPanelTheatre4Grid
