local XUiPanelTheatre3Prop = require("XUi/XUiTheatre3/Handbook/XUiPanelTheatre3Prop")
local XUiPanelTheatre3PropDetail = require("XUi/XUiTheatre3/Handbook/XUiPanelTheatre3PropDetail")

---@class XUiTheatre3Handbook : XLuaUi
---@field _Control XTheatre3Control
local XUiTheatre3Handbook = XLuaUiManager.Register(XLuaUi, "UiTheatre3Handbook")

local HandbookType = {
    Set = 1, -- 套装
    Prop = 2, -- 藏品
}

function XUiTheatre3Handbook:OnAwake()
    self:RegisterUiEvents()
    self.PanelProp.gameObject:SetActiveEx(false)
    ---@type XUiPanelTheatre3Prop[]
    self.PropGroupList = {}
    ---@type XUiGridTheatre3Prop[]
    self.GridPropDict = {}
    ---@type XUiGridTheatre3Prop[]
    self.GridPropSetDict = {}

    if self.TextDescPercent then
        self.TextDescPercent.gameObject:SetActiveEx(false)
    end
end

function XUiTheatre3Handbook:OnStart()
    ---@type XUiPanelTheatre3PropDetail
    self.PanelPropDetail = XUiPanelTheatre3PropDetail.New(self.PanelDetail, self)
    self:InitLeftTabBtns()
end

function XUiTheatre3Handbook:OnEnable()
    self.PanelTab:SelectIndex(self.SelectIndex or 1)
    self:RefreshPropRedPoint()
    self:RefreshSuitRedPoint()
end

function XUiTheatre3Handbook:OnDisable()
    self:CancelPropSelect()
end

function XUiTheatre3Handbook:InitLeftTabBtns()
    self.TabBtns = {
        self.BtnSet,
        self.BtnProp,
    }
    self.PanelTab:Init(self.TabBtns, function(index) self:OnSelectBtnTag(index) end)
    self.SelectIndex = 1
end

function XUiTheatre3Handbook:OnSelectBtnTag(index)
    self.SelectIndex = index
    -- 取消上一个选择
    self:CancelPropSelect()
    -- 刷新列表
    self:RefreshPropGridList()
    -- 默认选择
    self:ClickPropGridByIndex(1)
    -- 刷新解锁进度
    self:RefreshUnlockProgress()
    -- 刷新介绍
    self:RefreshDescPercent()
    -- 切换时从第一个进行显示
    if self.PropScrollRect then
        self.PropScrollRect.verticalNormalizedPosition = 1
    end
end

function XUiTheatre3Handbook:RefreshUnlockProgress()
    local txtProgress = XUiHelper.ReplaceTextNewLine(self._Control:GetClientConfig("HandbookPropUnlockPercent", 1))
    local curCount, totalCount = self:GetUnlockProgress()
    self.TxtPercent.text = string.format(txtProgress, curCount, totalCount)
end

function XUiTheatre3Handbook:RefreshDescPercent()
    if self.TextDescPercent2 then
        self.TextDescPercent2.gameObject:SetActiveEx(self.SelectIndex ~= 1)
    end
end

function XUiTheatre3Handbook:GetTypeIdList()
    local dataList = {}
    if self:CheckCurTypeIsSet() then
        dataList = self._Control:GetEquipSuitTypeIdList()
    elseif self:CheckCurTypeIsProp() then
        dataList = self._Control:GetItemTypeIdList()
    end
    -- 默认按照id排序
    XTool.SortIdTable(dataList)
    return dataList
end

function XUiTheatre3Handbook:GetIdListByTypeId(typeId)
    local idList = {}
    if self:CheckCurTypeIsProp() then
        idList = self._Control:GetItemIdListByTypeId(typeId)
    elseif self:CheckCurTypeIsSet() then
        idList = self._Control:GetEquipSuitIdListByTypeId(typeId)
    end
    -- 默认按照Id排序
    XTool.SortIdTable(idList)
    return idList
end

function XUiTheatre3Handbook:GetTypeName(typeId)
    local name = ""
    if self:CheckCurTypeIsProp() then
        name = self._Control:GetItemTypeName(typeId)
    elseif self:CheckCurTypeIsSet() then
        name = self._Control:GetEquipSuitTypeName(typeId)
    end
    return name
end

function XUiTheatre3Handbook:GetUnlockProgress()
    local curCount, totalCount
    if self:CheckCurTypeIsProp() then
        curCount, totalCount = self._Control:GetItemUnlockProgress()
    end
    if self:CheckCurTypeIsSet() then
        curCount, totalCount = self._Control:GetEquipSuitUnlockProgress()
    end
    return curCount, totalCount
end

function XUiTheatre3Handbook:CheckCurTypeIsProp()
    return self.SelectIndex == HandbookType.Prop
end

function XUiTheatre3Handbook:CheckCurTypeIsSet()
    return self.SelectIndex == HandbookType.Set
end

function XUiTheatre3Handbook:RefreshPropGridList()
    self.GridPropIndex = 0
    self.GridPropSetIndex = 0
    self.GridPropDict = self.GridPropDict or {}
    self.GridPropSetDict = self.GridPropSetDict or {}
    local typeIdList = self:GetTypeIdList()
    for index, typeId in ipairs(typeIdList) do
        local propGroup = self.PropGroupList[index]
        if not propGroup then
            local go = XUiHelper.Instantiate(self.PanelProp, self.Content)
            propGroup = XUiPanelTheatre3Prop.New(go, self, handler(self, self.ClickPropGrid))
            self.PropGroupList[index] = propGroup
        end
        propGroup:Open()
        propGroup:Refresh(typeId)
    end
    -- 隐藏格子
    if self:CheckCurTypeIsSet() then
        for i = 1, #self.GridPropDict do
            self.GridPropDict[i]:Close()
        end
    elseif self:CheckCurTypeIsProp() then
        for i = 1, #self.GridPropSetDict do
            self.GridPropSetDict[i]:Close()
        end
    end
    -- 隐藏Panel
    for i = #typeIdList + 1, #self.PropGroupList do
        self.PropGroupList[i]:Close()
    end
end

function XUiTheatre3Handbook:GetGridProp()
    if self:CheckCurTypeIsProp() then
        self.GridPropIndex = self.GridPropIndex + 1
        return self.GridPropDict[self.GridPropIndex]
    elseif self:CheckCurTypeIsSet() then
        self.GridPropSetIndex = self.GridPropSetIndex + 1
        return self.GridPropSetDict[self.GridPropSetIndex]
    else
        return nil
    end
end

function XUiTheatre3Handbook:AddGridProp(grid)
    if self:CheckCurTypeIsProp() then
        self.GridPropDict[self.GridPropIndex] = grid
    elseif self:CheckCurTypeIsSet() then
        self.GridPropSetDict[self.GridPropSetIndex] = grid
    end
end

-- 模拟点击
function XUiTheatre3Handbook:ClickPropGridByIndex(index)
    ---@type XUiGridTheatre3Prop
    local grid
    if self:CheckCurTypeIsProp() then
        grid = self.GridPropDict[index]
    elseif self:CheckCurTypeIsSet() then
        grid = self.GridPropSetDict[index]
    end
    if not grid then
        return
    end
    -- 刷新红点(藏品默认选择就相当于点击，需要刷新红点)
    grid:ClickPropRefreshRedPoint()
    self:ClickPropGrid(grid)
end

-- 选中 Grid
---@param grid XUiGridTheatre3Prop
function XUiTheatre3Handbook:ClickPropGrid(grid)
    local curGrid = self.CurPropGrid
    if curGrid and curGrid.Id == grid.Id then
        return
    end
    -- 取消上一次选择
    if curGrid then
        curGrid:SetPropSelect(false)
    end
    -- 选中当前选择
    grid:SetPropSelect(true)
    -- 刷新详情面板
    self.PanelPropDetail:Open()
    self.PanelPropDetail:Refresh(grid.Id)
    self.CurPropGrid = grid
end

function XUiTheatre3Handbook:CancelPropSelect()
    if not self.CurPropGrid then
        return
    end
    -- 取消当前选择
    self.CurPropGrid:SetPropSelect(false)
    self.CurPropGrid = nil
    -- 关闭详情面板
    self.PanelPropDetail:Close()
end

function XUiTheatre3Handbook:RefreshSuitGridRedPoint()
    if not self.CurPropGrid then
        return
    end
    self.CurPropGrid:RefreshRedPoint()
    self:RefreshSuitRedPoint()
end

function XUiTheatre3Handbook:RefreshPropRedPoint()
    local isPropTagRedPoint = self._Control:CheckAllItemRedPoint()
    self.BtnProp:ShowReddot(isPropTagRedPoint)
end

function XUiTheatre3Handbook:RefreshSuitRedPoint()
    local isSuitRedPoint = self._Control:CheckAllEquipSuitRedPoint()
    self.BtnSet:ShowReddot(isSuitRedPoint)
end

function XUiTheatre3Handbook:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
end

function XUiTheatre3Handbook:OnBtnBackClick()
    self:Close()
end

function XUiTheatre3Handbook:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

return XUiTheatre3Handbook