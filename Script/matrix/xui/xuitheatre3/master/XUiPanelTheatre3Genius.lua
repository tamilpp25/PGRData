---@class XUiPanelTheatre3Genius : XUiNode
---@field _Control XTheatre3Control
---@field GridGenuisSmall UnityEngine.Transform
---@field GridGenuisMiddle UnityEngine.Transform
---@field GridGenuisBig UnityEngine.Transform
---@field Content UnityEngine.Transform
---@field PanelGeniusDrag XDragArea
local XUiPanelTheatre3Genius = XClass(XUiNode, "XUiPanelTheatre3Genius")

local DefaultId = 1
local FocusTime = 0.5

function XUiPanelTheatre3Genius:OnStart(isSecond)
    local geniusMaxCount = self._Control:GetClientConfig("StrengthenTreeMaxCount")
    self._IsSecond = isSecond
    self.GeniusMaxCount = geniusMaxCount and tonumber(geniusMaxCount)
    self.IsFirstEnter = true
    ---@type XUiGridTheatreGenius[]
    self.GridGeniusList = {}
    ---@type UnityEngine.Transform
    self.LineGeniusDir = {}
    ---@type UnityEngine.Transform[]
    self.GridGeniusDir = {
        [XEnumConst.THEATRE3.StrengthenPointType.Small] = self.GridGenuisSmall,
        [XEnumConst.THEATRE3.StrengthenPointType.Middle] = self.GridGenuisMiddle,
        [XEnumConst.THEATRE3.StrengthenPointType.Big] = self.GridGenuisBig,
    }
    for i, tran in ipairs(self.GridGeniusDir) do
        tran.gameObject:SetActiveEx(false)
    end
end

--region Ui - Genius
function XUiPanelTheatre3Genius:Refresh(isIgnoreEqual)
    self:_RefreshGeniusTable()
    self:ClickGeniusGridByIndex(isIgnoreEqual)
end

function XUiPanelTheatre3Genius:_RefreshGeniusTable()
    local XUiGridTheatreGenius = require("XUi/XUiTheatre3/Master/XUiGridTheatreGenius")
    local geniusIdList = self._Control:GetStrengthenTreeIdList(self._IsSecond)
    local geniusParent = self._IsSecond and XUiHelper.TryGetComponent(self.Content.transform, "PanelGenius") or self.Content
    for index, id in pairs(geniusIdList) do
        local grid = self.GridGeniusList[index]
        if not grid then
            local parent = XUiHelper.TryGetComponent(geniusParent or self.Content, "Genius" .. index)
            if not parent then
                XLog.Error("天赋树Id: " .. id .. "找不到对应ui节点")
                break
            end
            parent.gameObject:SetActiveEx(true)
            local go = XUiHelper.Instantiate(self.GridGeniusDir[self._Control:GetStrengthenTreePointTypeById(id)], parent)
            grid = XUiGridTheatreGenius.New(go, self, index, handler(self, self.ClickGeniusGrid))
            self.GridGeniusList[index] = grid
        end
        grid:Open()
        grid:Refresh(id)
        -- 线
        if not self.LineGeniusDir[index] then
            local go = XUiHelper.TryGetComponent(self.Content, "RImgBg/Line" .. index)
            if go then
                self.LineGeniusDir[index] = go
            end
        end
        if self.LineGeniusDir[index] then
            self.LineGeniusDir[index].gameObject:SetActiveEx(self._Control:CheckStrengthTreeUnlock(id))
        end
    end

    for i = 1, self.GeniusMaxCount do
        if not self.GridGeniusList[i] then
            local parent = XUiHelper.TryGetComponent(self.Content, "Genius" .. i)
            if parent then
                parent.gameObject:SetActiveEx(false)
            end
        end
    end
end
---@param grid XUiGridTheatreGenius
function XUiPanelTheatre3Genius:GoToGenius(grid)
    if self.PanelGeniusDrag then
        local scale = (self.PanelGeniusDrag.MinScale + self.PanelGeniusDrag.MaxScale) / 2
        self.PanelGeniusDrag:FocusTarget(grid.Transform, scale, FocusTime, Vector3.zero)
    end
end

-- 模拟点击一个天赋
function XUiPanelTheatre3Genius:ClickGeniusGridByIndex(isIgnoreEqual)
    if not XTool.IsNumberValid(self.CurGeniusIndex) then
        self.CurGeniusIndex = DefaultId
    end
    local grid = self.GridGeniusList[self.CurGeniusIndex]
    if not grid then
        self.CurGeniusIndex = 0
        return
    end
    self:ClickGeniusGrid(grid, isIgnoreEqual)
    -- 第一次打开将选中的自动移到中间位置
    if self.IsFirstEnter then
        self.IsFirstEnter = false
        self:GoToGenius(grid)
    end
end

-- 选中 Grid
---@param grid XUiGridTheatreGenius
function XUiPanelTheatre3Genius:ClickGeniusGrid(grid, isIgnoreEqual)
    local curGrid = self.CurGeniusGrid
    if curGrid and curGrid.GeniusId == grid.GeniusId and not isIgnoreEqual then
        return
    end
    -- 取消上一次选择
    if curGrid then
        curGrid:SetGeniusSelect(false)
    end
    -- 选中当前选择
    grid:SetGeniusSelect(true)

    self.CurGeniusIndex = grid.Index
    self.CurGeniusGrid = grid
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE3_GENIUS_CHANGE_GRID, grid.GeniusId)
end

function XUiPanelTheatre3Genius:CancelGeniusSelect()
    if not self.CurGeniusGrid then
        return
    end
    -- 取消当前选择
    self.CurGeniusGrid:SetGeniusSelect(false)
    self.CurGeniusGrid = nil
end
--endregion

return XUiPanelTheatre3Genius