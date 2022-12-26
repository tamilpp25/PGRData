local XUiFurnitureTypeSelect = XLuaUiManager.Register(XLuaUi, "UiFurnitureTypeSelect")
local XUiGridCategory = require("XUi/XUiFurnitureTypeSelect/XUiGridCategory")

local SelectState = {
    SINGLE = 1,
    MULTIP = 2,
}

local PanelState = {
    FURNITURE = 1,
    SUIT = 2,
}

function XUiFurnitureTypeSelect:OnAwake()
    self:AddListener()

    XEventManager.AddEventListener(XEventId.EVENT_CLICKCATEGORY_GRID, self.OnCategoryGridClick, self)
end

function XUiFurnitureTypeSelect:OnStart(selectIds, selectSuitIds, isBuild, comfirmCb)
    self.SelectIds = {}
    self.SelectSuitIds = {}

    if selectIds then
        for _, k in pairs(selectIds) do
            table.insert(self.SelectIds, k)
        end
    end

    if selectSuitIds then
        for _, k in pairs(selectSuitIds) do
            table.insert(self.SelectSuitIds, k)
        end
    end

    self.CategoryGrids = {}
    self.CategorySuitGrids = {}
    self.PageRecord = PanelState.FURNITURE
    self.IsBuild = isBuild

    self.ComfirmCb = comfirmCb
    self.FurnitureTypeAllId = XFurnitureConfigs.FURNITURE_CATEGORY_ALL_ID
    self.FurnitureTypeSuitAllId = XFurnitureConfigs.FURNITURE_SUIT_CATEGORY_ALL_ID
    self:InitTabGroup()
    self:Init()
end

function XUiFurnitureTypeSelect:OnDestroy()
    self.SelectIds = nil
    self.SelectSuitIds = nil
    self.CategoryGrids = nil
    self.CategorySuitGrids = nil
    self.CurSelectState = nil
    self.FurnitureTypeAllId = 0

    XEventManager.RemoveEventListener(XEventId.EVENT_CLICKCATEGORY_GRID, self.OnCategoryGridClick, self)
end

function XUiFurnitureTypeSelect:InitTabGroup()
    self.BtnList = {}
    table.insert(self.BtnList, self.BtnFurnitureType)
    table.insert(self.BtnList, self.BtnFurnitureSuitType)

    self.FurnitureTypeBtnGroup:Init(self.BtnList, function(index)
        self:RefreshSelectedPanel(index)
    end)

    -- 设置默认开启
    self.FurnitureTypeBtnGroup:SelectIndex(self.PageRecord)
end

function XUiFurnitureTypeSelect:RefreshSelectedPanel(index)
    self.PageRecord = index
    self.PanelFurnitureTypeScroll.gameObject:SetActiveEx(self.PageRecord == PanelState.FURNITURE)
    self.PanelFurnitureSuitTypeScroll.gameObject:SetActiveEx(self.PageRecord == PanelState.SUIT)
end

-- 检查是否筛选过Grid
function XUiFurnitureTypeSelect:CheckCategoryGridSelect(id)
    if not self.SelectIds or #self.SelectIds <= 0 then
        return false
    end

    for i = 1, #self.SelectIds do
        if self.SelectIds[i] == id or self.SelectIds[i] == self.FurnitureTypeAllId then
            return true
        end
    end

    return false
end

-- 检查套装是否筛选过Grid
function XUiFurnitureTypeSelect:CheckSuitCategoryGridSelect(id)
    if not self.SelectSuitIds or #self.SelectSuitIds <= 0 then
        return false
    end

    for i = 1, #self.SelectSuitIds do
        if self.SelectSuitIds[i] == id or self.SelectSuitIds[i] == self.FurnitureTypeSuitAllId then
            return true
        end
    end

    return false
end

function XUiFurnitureTypeSelect:Init()
    self.GridSuitCategory.gameObject:SetActiveEx(false)
    self.PanelNotEnoughCoin.gameObject:SetActiveEx(false)
    self.PanelMaxEnoughTip.gameObject:SetActiveEx(false)
    self.PanelMinEnoughTip.gameObject:SetActiveEx(false)
    self.PanelTip.gameObject:SetActiveEx(self.IsBuild)

    if self.IsBuild then
        self.CurSelectState = SelectState.MULTIP
        self:InitMultipleSelect()
        self.PanelFurnitureSuitTypeScroll.gameObject:SetActiveEx(false)
        self.BtnFurnitureSuitType.gameObject:SetActiveEx(false)
        self:UpdateCoinTip()
        return
    end

    if self.SelectIds and #self.SelectIds > 0 then
        self.CurSelectState = SelectState.MULTIP
        self:InitMultipleSelect()
        self:InitSuitPart()
        return
    end

    self.CurSelectState = SelectState.SINGLE
    self.PanelFurnitureSuitTypeScroll.gameObject:SetActiveEx(false)
    self.BtnFurnitureSuitType.gameObject:SetActiveEx(false)
    self:InitSingleSelect()
end

-- 初始化套装
function XUiFurnitureTypeSelect:InitSuitPart()
    local suitCfg = XFurnitureConfigs.GetFurnitureSuitTemplates()
    self.GridAllSuitCategory = XUiGridCategory.New(self.GridAllSuitCategory)
    local isSelected = self:CheckSuitCategoryGridSelect(self.FurnitureTypeSuitAllId)
    self.GridAllSuitCategory:RefreshSuit(suitCfg[1], isSelected)

    for i = 2, #suitCfg do
        local grid = CS.UnityEngine.Object.Instantiate(self.GridSuitCategory)
        local gridCategory = XUiGridCategory.New(grid)
        grid.transform:SetParent(self.PanelSuitContent, false)
        local tmpIsSelected = self:CheckSuitCategoryGridSelect(suitCfg[i].Id)
        gridCategory:RefreshSuit(suitCfg[i], tmpIsSelected)
        gridCategory.GameObject:SetActiveEx(true)

        table.insert(self.CategorySuitGrids, gridCategory)
    end
end

-- 单选模式
function XUiFurnitureTypeSelect:InitSingleSelect()
    self.GridCategory.gameObject:SetActiveEx(false)
    self.GridAllCategory.gameObject:SetActiveEx(false)
    self:InitFurniturePart()
end

-- 多选模式
function XUiFurnitureTypeSelect:InitMultipleSelect()
    self.GridCategory.gameObject:SetActiveEx(false)
    self.GridAllCategory.gameObject:SetActiveEx(true)

    self.GridAllCategory = XUiGridCategory.New(self.GridAllCategory)

    -- 全部类型
    local isSelected = self:CheckCategoryGridSelect(self.FurnitureTypeAllId)
    local categoryInfos = {}
    categoryInfos.Id = XFurnitureConfigs.FURNITURE_CATEGORY_ALL_ID
    categoryInfos.CategoryName = CS.XTextManager.GetText("DormAllDesc")
    self.GridAllCategory:Refresh(categoryInfos, isSelected)

    self:InitFurniturePart()
end

function XUiFurnitureTypeSelect:InitFurniturePart()
    self.GridPartSelect.gameObject:SetActiveEx(false)
    local parts = XFurnitureConfigs.GetFurnitureTemplatePartType()
    local setPartInfoFunction = function(categoryInfos, minorName)
        local part = CS.UnityEngine.Object.Instantiate(self.GridPartSelect)
        part.transform:SetParent(self.PanelPartContent, false)

        local content = XUiHelper.TryGetComponent(part, "PanelCategoryContent", "Transform")
        local name = XUiHelper.TryGetComponent(part, "TxtMinorName", "Text")

        name.text = minorName
        part.gameObject:SetActiveEx(true)

        for _, categoryInfo in pairs(categoryInfos) do
            local grid = CS.UnityEngine.Object.Instantiate(self.GridCategory)
            local gridCategory = XUiGridCategory.New(grid)

            local isSelected = self:CheckCategoryGridSelect(categoryInfo.Id)
            gridCategory:Refresh(categoryInfo, isSelected)
            grid.transform:SetParent(content, false)
            gridCategory.GameObject:SetActiveEx(true)

            table.insert(self.CategoryGrids, gridCategory)
        end
    end

    for _, part in pairs(parts) do
        setPartInfoFunction(part.Categorys, part.MinorName)
    end
end

function XUiFurnitureTypeSelect:OnCategoryGridClick(furnitureTypeId, grid)
    -- 处理套装
    if self.PageRecord == PanelState.SUIT then
        self:OnCategorySuitGridClick(furnitureTypeId, grid)
        return
    end

    -- 处理单选
    if self.CurSelectState == SelectState.SINGLE then
        if furnitureTypeId == self.SelectId then
            return
        end

        grid:SetSelected(not grid:IsSelected())
        self.SelectId = furnitureTypeId
        if self.FurnitureSelectTypeGrid then
            self.FurnitureSelectTypeGrid:SetSelected(false)
        end
        --记录选择得Grid
        self.FurnitureSelectTypeGrid = grid
        return
    end

    -- 处理已经是再全选状态下再点击全选不能取消全选
    if self.GridAllCategory:IsSelected() and furnitureTypeId == self.FurnitureTypeAllId  then
        for _, categoryGrid in ipairs(self.CategoryGrids) do
            categoryGrid:SetSelected(false)
        end
        self.GridAllCategory:SetSelected(false)
        self.SelectIds = {}
        self:UpdateCoinTip()
        return
    end

    grid:SetSelected(not grid:IsSelected())
    -- 处理全选类型逻辑
    if furnitureTypeId == self.FurnitureTypeAllId then
        for _, categoryGrid in ipairs(self.CategoryGrids) do
            categoryGrid:SetSelected(true)
        end

        self.SelectIds = {}
        local typeList = XFurnitureConfigs.GetFurnitureTemplateTypeList()
        for _, furnitureType in ipairs(typeList) do
            table.insert(self.SelectIds, furnitureType.Id)
        end
        self:UpdateCoinTip()
        return
    end

    -- 处理多选其他类型
    self.GridAllCategory:SetSelected(false)

    -- 移除全选
    for i = 1, #self.SelectIds do
        if self.SelectIds[i] == self.FurnitureTypeAllId then
            table.remove(self.SelectIds, i)
            break
        end
    end

    -- 移除点击过的类型
    for i = 1, #self.SelectIds do
        if self.SelectIds[i] == furnitureTypeId then
            table.remove(self.SelectIds, i)
            self:UpdateCoinTip()
            return
        end
    end

    -- 加入未点击过的类型
    table.insert(self.SelectIds, furnitureTypeId)
    self:UpdateCoinTip()
end

function XUiFurnitureTypeSelect:OnCategorySuitGridClick(furnitureTypeId, grid)
    if self.GridAllSuitCategory:IsSelected() and furnitureTypeId == self.FurnitureTypeSuitAllId then
        for _, categoryGrid in ipairs(self.CategorySuitGrids) do
            categoryGrid:SetSelected(false)
        end
        self.GridAllSuitCategory:SetSelected(false)
        self.SelectSuitIds = {}
        return
    end

    grid:SetSelected(not grid:IsSelected())
    if furnitureTypeId == self.FurnitureTypeSuitAllId then
        for _, categoryGrid in ipairs(self.CategorySuitGrids) do
            categoryGrid:SetSelected(true)
        end

        self.SelectSuitIds = {}
        local suitList = XFurnitureConfigs.GetFurnitureSuitTemplates()
        for _, suit in pairs(suitList) do
            if suit.Id ~= self.FurnitureTypeSuitAllId then
                table.insert(self.SelectSuitIds, suit.Id)
            end
        end
        return
    end

    self.GridAllSuitCategory:SetSelected(false)
    -- 移除全选
    for i = 1, #self.SelectSuitIds do
        if self.SelectSuitIds[i] == self.FurnitureTypeSuitAllId then
            table.remove(self.SelectSuitIds, i)
            break
        end
    end

    -- 移除点击过的类型
    for i = 1, #self.SelectSuitIds do
        if self.SelectSuitIds[i] == furnitureTypeId then
            table.remove(self.SelectSuitIds, i)
            return
        end
    end

    table.insert(self.SelectSuitIds, furnitureTypeId)
end

function XUiFurnitureTypeSelect:AddListener()
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnCancel, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnSelcet, self.OnBtnSelcetClick)
end

function XUiFurnitureTypeSelect:OnBtnCloseClick()
    self:Close()
end

function XUiFurnitureTypeSelect:OnBtnSelcetClick()
    if self.ComfirmCb then
        local data
        if self.CurSelectState == SelectState.SINGLE then
            data = self.SelectId
        else
            data = self.SelectIds
        end

        if not data then
            XUiManager.TipMsg(CS.XTextManager.GetText("DormFurnitureSelectNull"))
            return
        end

        if type(data) == "table" and #data <= 0 then
            XUiManager.TipMsg(CS.XTextManager.GetText("DormFurnitureSelectNull"))
            return
        end

        if not self:CheckBuildCoin() then
            XUiManager.TipMsg(CS.XTextManager.GetText("FurnitureZeroCoin"))
            return
        end
        data = self:SetBulidAllType(data)

        if not self.IsBuild and #self.SelectSuitIds <= 0 then
            XUiManager.TipMsg(CS.XTextManager.GetText("DormFurnitureSelectSuitNull"))
            return
        end

        self.ComfirmCb(data, self.SelectSuitIds)
    end
    self:Close()
end

-- 获得当前消耗家具币数量
function XUiFurnitureTypeSelect:GetCostFurnitureCoin()
    local minConsume, maxConsume = XFurnitureConfigs.GetFurnitureCreateMinAndMax()

    local typeCount = self.SelectIds and #self.SelectIds or 0
    for _, selectId in ipairs(self.SelectIds) do
        if selectId == self.FurnitureTypeAllId then
            typeCount = XFurnitureConfigs.GetFurnitureTemplateTypeCount()
            break
        end
    end

    local maxCostCount = maxConsume * typeCount
    local minCostCount = minConsume * typeCount
    local currentOwn = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.FurnitureCoin)
    local isMaxEnough = currentOwn >= maxCostCount
    local isMinEnough = currentOwn >= minCostCount
    return isMaxEnough, isMinEnough
end

function XUiFurnitureTypeSelect:UpdateCoinTip()
    if not self.IsBuild then
        self.PanelMaxEnoughTip.gameObject:SetActiveEx(false)
        self.PanelMinEnoughTip.gameObject:SetActiveEx(false)
        return
    end

    local _, isMinEnough = self:GetCostFurnitureCoin()
    self.PanelMaxEnoughTip.gameObject:SetActiveEx(false)
    self.PanelMinEnoughTip.gameObject:SetActiveEx(not isMinEnough)
end

function XUiFurnitureTypeSelect:CheckBuildCoin()
    if not self.IsBuild then
        return true
    end

    local _, isMinEnough = self:GetCostFurnitureCoin()
    return isMinEnough
end

function XUiFurnitureTypeSelect:SetBulidAllType(datas)
    if not self.IsBuild then
        return datas
    end

    local isAll = false
    for _, id in ipairs(datas) do
        if id == self.FurnitureTypeAllId then
            isAll = true
            break
        end
    end

    if isAll then
        local list = {}
        local typeList = XFurnitureConfigs.GetFurnitureTemplateTypeList()
        for _, furnitureType in ipairs(typeList) do
            table.insert(list, furnitureType.Id)
        end
        return list
    end

    return datas
end

return XUiFurnitureTypeSelect