local XUiGridDormBagItem = XClass(nil, "XUiGridDormBagItem")
local XUiGridFurniture = require("XUi/XUiDormBag/XUiGridFurniture")

function XUiGridDormBagItem:Ctor(ui, rootUi)
    XTool.InitUiObjectByUi(self, ui)
    self.UiGridFurniture = XUiGridFurniture.New(rootUi, self.GridFurnitureWork)
    self.UiGridCreate = {}
    XTool.InitUiObjectByUi(self.UiGridCreate, self.GridCreate)
    self.UiGridCreate.BtnClick.onClick:AddListener(function() 
        self:OnBtnCreateClick()
    end)
    
    self.RefreshListCb = handler(rootUi, rootUi.SetupFurnitureDynamicTable)
    self.DelayPlayCb = handler(self, self.DelayPlay)
end

function XUiGridDormBagItem:OnBtnCreateClick()
    if self.FurnitureId ~= 0 then
        return
    end
    
    XLuaUiManager.Open("UiFurnitureCreate", self.TypeId, nil, nil, self.RefreshListCb)
end

function XUiGridDormBagItem:Refresh(furnitureId, typeId)
    self.FurnitureId = furnitureId
    self.TypeId = typeId
    local isValid = XTool.IsNumberValid(furnitureId)
    self.UiGridCreate.GameObject:SetActiveEx(not isValid)
    self.UiGridFurniture.GameObject:SetActiveEx(isValid)
    if isValid then
        self.UiGridFurniture:Refresh(furnitureId)
    end
    
    XScheduleManager.ScheduleOnce(self.DelayPlayCb, 1)
    
end

function XUiGridDormBagItem:RefreshDisable()
    if not XTool.IsNumberValid(self.FurnitureId) then
        return
    end
    self.UiGridFurniture:RefreshDisable()
end

function XUiGridDormBagItem:GetFurnitureId()
    return self.FurnitureId
end

function XUiGridDormBagItem:DelayPlay()
    if not self.Timeline or XTool.UObjIsNil(self.GameObject) then
        return
    end
    self.Timeline:PlayTimelineAnimation()
end

--=========================================类分界线=========================================--

local XUiGridDormChoiceItem = XClass(nil, "XUiGridDormChoiceItem")

function XUiGridDormChoiceItem:Ctor(ui, rootUi)
    XTool.InitUiObjectByUi(self, ui)
    self.RootUi = rootUi
    self.BtnClose.CallBack = function() 
        self:OnBtnCloseClick()
    end
end

function XUiGridDormChoiceItem:Refresh(furnitureId)
    self.FurnitureId = furnitureId
    if not XTool.IsNumberValid(furnitureId) then
        self.GameObject:SetActiveEx(false)
        return
    end
    local furniture = XDataCenter.FurnitureManager.GetFurnitureById(furnitureId)
    local template = XFurnitureConfigs.GetFurnitureTemplateById(furniture:GetConfigId())
    local scoreDesc = XFurnitureConfigs.GetFurnitureTotalAttrLevelDescription(template.TypeId, furniture:GetScore())
    self.TxtSelectScore.text = XUiHelper.GetText("FurnitureRefitScore", scoreDesc)
    self.RImgIcon:SetRawImage(template.Icon)
end

function XUiGridDormChoiceItem:OnBtnCloseClick()
    if not self.RootUi or not XTool.IsNumberValid(self.FurnitureId) then
        self.GameObject:SetActiveEx(false)
        return
    end
    local grid = self.RootUi:GetFurnitureGrid(self.FurnitureId)
    if not grid then
        self.RootUi:RemoveChoose(self.FurnitureId)
        self.RootUi:SetupChoiceDynamicTable()
        return
    end
    local furniture = XDataCenter.FurnitureManager.GetFurnitureById(self.FurnitureId)
    self.RootUi:OnFurnitureGridClick(self.FurnitureId, furniture:GetConfigId(), grid)
end


--=========================================类分界线=========================================--

---@class XUiDormBagChoice : XLuaUi
local XUiDormBagChoice = XLuaUiManager.Register(XLuaUi, "UiDormBagChoice")

local OnlyBaseFilter = true

local HandleType = {
    QuickSelect = -1,
    Filter = 0
}

function XUiDormBagChoice:OnAwake()
    self:InitUi()
    self:InitCb()
end

--- 
---@param selectIds number[]
---@param furnitureTypeId number
---@param maxSelectCount number
---@param selectCb function
---@param filterMap table<number,any> 过滤Id
---@param filterSuitIdMap table<number,any> 过滤套装Id
--------------------------
function XUiDormBagChoice:OnStart(selectIds, furnitureTypeId, maxSelectCount, selectCb, filterMap, filterSuitIdMap)
    self.SelectIds = XTool.Clone(selectIds)
    self.FilterIdMap = filterMap --注意引用类型
    self.FilterSuitIdMap = filterSuitIdMap
    self.SelectTypeIds = { furnitureTypeId }
    self.MaxSelectCount = maxSelectCount or HandleType.QuickSelect
    self.SelectCb = selectCb
    
    self:InitByIsLimit()
    --初始化选中套装
    self:InitSelectSuitIds()
    self.AssetPanel = XUiPanelAsset.New(self, self.DormPanelAsset, XDataCenter.ItemManager.ItemId.DormCoin, 
            XDataCenter.ItemManager.ItemId.FurnitureCoin)
    self:UpdateSelectMap()
    self:SetupChoiceDynamicTable()
    self:SetupFurnitureDynamicTable()
    self:AddEventListener()
end

function XUiDormBagChoice:OnDestroy()
    self:DelEventListener()
end

function XUiDormBagChoice:OnGetEvents()
    return {
        XEventId.EVENT_FURNITURE_ON_MODIFY,
    }
end

function XUiDormBagChoice:OnNotify(evt, ...)
    if XEventId.EVENT_FURNITURE_ON_MODIFY == evt then
        self:SetupFurnitureDynamicTable()
    end
end

function XUiDormBagChoice:InitUi()
    --家具动态列表
    self.DynamicFurniture = XDynamicTableNormal.New(self.PanelDynamicTable)
    self.DynamicFurniture:SetProxy(XUiGridDormBagItem, self)
    self.DynamicFurniture:SetDelegate(self)
    self.DynamicFurniture:SetDynamicEventDelegate(handler(self, self.OnDynamicFurnitureEvent))
    self.PanelDormBagItem.gameObject:SetActiveEx(false)
    --选中家具动态列表
    self.DynamicChoice = XDynamicTableNormal.New(self.PanelSelectList)
    self.DynamicChoice:SetProxy(XUiGridDormChoiceItem, self)
    self.DynamicChoice:SetDelegate(self)
    self.DynamicChoice:SetDynamicEventDelegate(handler(self, self.OnDynamicChoiceEvent))
    self.GridSelect.gameObject:SetActiveEx(false)
    
    self.SelectIds = {}
    self.SelectSuitIds = {}
    self.AllSuitIds = {}
    
    local suitList = XFurnitureConfigs.GetFurnitureSuitTemplates()
    for _, suit in pairs(suitList) do
        if suit.Id ~= XFurnitureConfigs.FURNITURE_SUIT_CATEGORY_ALL_ID then
            table.insert(self.AllSuitIds, suit.Id)
        end
    end
    
    self.TogBase:SetButtonState(OnlyBaseFilter and CS.UiButtonState.Select or CS.UiButtonState.Normal)
    self.TogBase.CallBack = function() 
        self:OnToggleBaseClick()
    end
    
    self.OnFilterSuitCb = handler(self, self.OnFilterSuit)
    self.OnSortFurnitureCb = handler(self, self.OnSortFurniture)
    self.OnSortQuickSelectFurnitureCb = handler(self, self.OnSortQuickSelectFurniture)
    
end 

function XUiDormBagChoice:InitCb()
    self:BindExitBtns()
    self.BtnScreen.CallBack = function() 
        self:OnBtnScreenClick()
    end
    
    self.BtnSelect.CallBack = function() 
        self:OnBtnSelectClick()
    end
end 

function XUiDormBagChoice:RefreshCount()
    local showProgress = self:CheckIsLimit() and not self:CheckIsFilter()
    self.PanelOrder.gameObject:SetActiveEx(showProgress)
    self.TxtSelectNum.gameObject:SetActiveEx(not showProgress)
    if showProgress then
        self.TxtSelectNumOrderLeft.text = #self.SelectIds
        self.TxtSelectNumOrderRight.text = self.MaxSelectCount
    else
        self.TxtSelectNum.text = #self.SelectIds
    end
    
    self.BtnSelect:SetDisable(#self.SelectIds <= 0)
end

function XUiDormBagChoice:SetupFurnitureDynamicTable()
    self.FurnitureData = self:GetFurnitureData()
    self.DynamicFurniture:SetDataSource(self.FurnitureData)
    self.DynamicFurniture:ReloadDataSync()
end

function XUiDormBagChoice:SetupChoiceDynamicTable()
    self.DynamicChoice:SetDataSource(self.SelectIds)
    self.DynamicChoice:ReloadDataSync()
    
    self:RefreshCount()
end

function XUiDormBagChoice:OnDynamicFurnitureEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local furnitureId = self.FurnitureData[index]
        grid:Refresh(furnitureId, self.SelectTypeIds[1])
    end
end

function XUiDormBagChoice:OnDynamicChoiceEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX  then
        grid:Refresh(self.SelectIds[index])
    end
end

function XUiDormBagChoice:GetGridSelected(furnitureId)
    if XTool.IsTableEmpty(self.SelectIds) then
        return false
    end

    for _, selectId in ipairs(self.SelectIds) do
        if selectId == furnitureId then
            return true
        end
    end
    
    return false
end

function XUiDormBagChoice:CheckCanSelect(furnitureId)
    if not self:CheckIsLimit() then
        return true
    end
    
    return #self.SelectIds < self.MaxSelectCount or self:CheckIsFilter()
end

--选择是否有数量限制
function XUiDormBagChoice:CheckIsLimit()
    return self.MaxSelectCount >= 0
end

--为0时，不限制数量，但可以筛选
function XUiDormBagChoice:CheckIsFilter()
    return self.MaxSelectCount == HandleType.Filter
end

function XUiDormBagChoice:OnFurnitureGridClick(furnitureId, furnitureConfigId, grid)
    if grid:IsSelected() then
        self:RemoveChoose(furnitureId)
        grid:SetSelected(false)
    else
        if self:CheckCanSelect() then
            table.insert(self.SelectIds, furnitureId)
            grid:SetSelected(true) 
        else
            XUiManager.TipText("FurnitureOverMaxCount")
        end
    end

    --刷新显示Grid的状态
    local grids = self.DynamicFurniture:GetGrids()
    for _, viewGrid in pairs(grids) do
        viewGrid:RefreshDisable(viewGrid:GetFurnitureId())
    end
    
    self:SetupChoiceDynamicTable()
end

function XUiDormBagChoice:RemoveChoose(furnitureId)
    local pos
    for i, id in ipairs(self.SelectIds) do
        if id == furnitureId then
            pos = i
        end
    end
    if pos then
        table.remove(self.SelectIds, pos)
    end
end

function XUiDormBagChoice:AddEventListener()
    
    
end

function XUiDormBagChoice:DelEventListener()
    
end

function XUiDormBagChoice:GetFurnitureData()
    local levelCheckMap = (self:CheckIsLimit() or self:CheckIsFilter()) and self.LevelFilterMap or nil
    local furnitureIds = XDataCenter.FurnitureManager.GetFurnitureCategoryIdsNoSort(self.SelectTypeIds, 
            self.SelectSuitIds, levelCheckMap, true, false, true, OnlyBaseFilter, self.FilterIdMap)
    local isEmpty = XTool.IsTableEmpty(furnitureIds)
    if not isEmpty then
        table.sort(furnitureIds, self.OnSortFurnitureCb)
    end

    --末尾添加一个空
    table.insert(furnitureIds, 0)
    
    return furnitureIds
end 

function XUiDormBagChoice:GetFurnitureGrid(furnitureId)
    local grids = self.DynamicFurniture:GetGrids()
    for _, grid in pairs(grids) do
        if grid:GetFurnitureId() == furnitureId then
            return grid.UiGridFurniture
        end
    end
end

function XUiDormBagChoice:OnFilterSuit(selectTypeIds, selectSuitIds)
    self.SelectSuitIds = self:FilterSuitIdIds(selectSuitIds)
    local containBase = false
    for _, suitId in pairs(self.SelectSuitIds or {}) do
        containBase = containBase or suitId == XFurnitureConfigs.BASE_SUIT_ID
    end
    OnlyBaseFilter = #self.SelectSuitIds == 1 and containBase
    self.TogBase:SetButtonState(OnlyBaseFilter and CS.UiButtonState.Select or CS.UiButtonState.Normal)
    self:SetupFurnitureDynamicTable()
end

function XUiDormBagChoice:FilterSuitIdIds(suitIds)
    local checkFilter = not XTool.IsTableEmpty(self.FilterSuitIdMap)
    if not checkFilter then
        return suitIds
    end
    local ids = {}
    for _, suitId in pairs(suitIds) do
        if not self.FilterSuitIdMap[suitId] then
            table.insert(ids, suitId)
        end
    end
    return ids
end

function XUiDormBagChoice:OnSortFurniture(furnitureIdA, furnitureIdB)
    local isSelectA = self.SelectMap[furnitureIdA]
    local isSelectB = self.SelectMap[furnitureIdB]
    if isSelectA ~= isSelectB then
        return isSelectA
    end
    
    local furnitureA = XDataCenter.FurnitureManager.GetFurnitureById(furnitureIdA)
    local furnitureB = XDataCenter.FurnitureManager.GetFurnitureById(furnitureIdB)
    
    local scoreA = furnitureA and furnitureA:GetScore() or 0
    local scoreB = furnitureB and furnitureB:GetScore() or 0

    if scoreA ~= scoreB then
        return scoreA > scoreB
    end
    local suitIdA = furnitureA and furnitureA:GetSuitId() or XFurnitureConfigs.BASE_SUIT_ID
    local suitIdB = furnitureB and furnitureB:GetSuitId() or XFurnitureConfigs.BASE_SUIT_ID

    if suitIdA ~= suitIdB then
        return suitIdA < suitIdB
    end
    
    return furnitureIdA < furnitureIdB
end

function XUiDormBagChoice:OnSortQuickSelectFurniture(furnitureIdA, furnitureIdB)
    local furnitureA = XDataCenter.FurnitureManager.GetFurnitureById(furnitureIdA)
    local furnitureB = XDataCenter.FurnitureManager.GetFurnitureById(furnitureIdB)

    local scoreA = furnitureA and furnitureA:GetScore() or 0
    local scoreB = furnitureB and furnitureB:GetScore() or 0

    if scoreA ~= scoreB then
        return scoreA > scoreB
    end
    local suitIdA = furnitureA and furnitureA:GetSuitId() or XFurnitureConfigs.BASE_SUIT_ID
    local suitIdB = furnitureB and furnitureB:GetSuitId() or XFurnitureConfigs.BASE_SUIT_ID

    if suitIdA ~= suitIdB then
        return suitIdA < suitIdB
    end

    return furnitureIdA < furnitureIdB
end

--region   ------------------UI事件 start-------------------
function XUiDormBagChoice:OnBtnScreenClick()
    XLuaUiManager.Open("UiFurnitureTypeSelect", self.SelectTypeIds, self.SelectSuitIds, false, self.OnFilterSuitCb, true, self.FilterSuitIdMap)
end

function XUiDormBagChoice:OnToggleClick(level)
    self.LevelFilterMap[level] = not self.LevelFilterMap[level] 
    self:SetupFurnitureDynamicTable()
end

function XUiDormBagChoice:OnToggleSelect(level)
    self.LevelFilterMap[level] = not self.LevelFilterMap[level]
    self.SelectIds = {}
    self.FurnitureData = self:GetFurnitureData()
    for _, furnitureId in pairs(self.FurnitureData) do
        if XTool.IsNumberValid(furnitureId) then
            local furniture = XDataCenter.FurnitureManager.GetFurnitureById(furnitureId)
            local attrLevel = furniture:GetFurnitureTotalAttrLevel()
            if self.LevelFilterMap[attrLevel] then
                table.insert(self.SelectIds, furnitureId)
            end
        end
    end
    
    local count = #self.SelectIds
    if count > XFurnitureConfigs.MaxRemakeCount then
        table.sort(self.SelectIds, self.OnSortQuickSelectFurnitureCb)
        self.SelectIds = table.range(self.SelectIds, 1, XFurnitureConfigs.MaxRemakeCount)
    end
    self:UpdateSelectMap()

    self:SetupChoiceDynamicTable()

    self.DynamicFurniture:SetDataSource(self.FurnitureData)
    self.DynamicFurniture:ReloadDataSync()
end

function XUiDormBagChoice:OnToggleBaseClick()
    OnlyBaseFilter = not OnlyBaseFilter
    self:InitSelectSuitIds()
    self:SetupFurnitureDynamicTable()
end

function XUiDormBagChoice:OnBtnSelectClick()
    if XTool.IsTableEmpty(self.SelectIds) then
        XUiManager.TipText("FurnitureAtLeastSelectOne")
        return
    end

    self:Close()
    if self.SelectCb then self.SelectCb(self.SelectIds) end
end
--endregion------------------UI事件 finish------------------


--region   ------------------初始化数据 start-------------------

function XUiDormBagChoice:InitSelectSuitIds()
    if OnlyBaseFilter then
        self.SelectSuitIds = { XFurnitureConfigs.BASE_SUIT_ID }
    else
        self.SelectSuitIds = self:FilterSuitIdIds(self.AllSuitIds)
    end
end

function XUiDormBagChoice:InitByIsLimit()
    local isLimit = self:CheckIsLimit()
    self.TogBase.gameObject:SetActiveEx(isLimit)
    self.BtnTabGroupFilter.gameObject:SetActiveEx(isLimit)
    self.PanelSelectConsume.gameObject:SetActiveEx(not isLimit)
    if not isLimit then --选择模式
        OnlyBaseFilter = false

        self.LevelFilterMap = {
            [XFurnitureConfigs.FurnitureAttrLevelId.LevelS] = false,
            [XFurnitureConfigs.FurnitureAttrLevelId.LevelA] = false,
            [XFurnitureConfigs.FurnitureAttrLevelId.LevelB] = false,
            [XFurnitureConfigs.FurnitureAttrLevelId.LevelC] = false
        }

        for level, state in pairs(self.LevelFilterMap) do
            ---@type UnityEngine.UI.Toggle
            local toggle = self["TgQuality"..level]
            toggle.isOn = state
            local tempLevel = level
            toggle.onValueChanged:AddListener(function() 
                self:OnToggleSelect(tempLevel)
            end)
        end
        
    else --过滤模式
        self.LevelFilterMap = {
            [XFurnitureConfigs.FurnitureAttrLevelId.LevelS] = false,
            [XFurnitureConfigs.FurnitureAttrLevelId.LevelA] = true,
            [XFurnitureConfigs.FurnitureAttrLevelId.LevelB] = true,
            [XFurnitureConfigs.FurnitureAttrLevelId.LevelC] = true
        }

        for level, state in pairs(self.LevelFilterMap) do
            local toggle = self["Tog"..level]
            toggle:SetButtonState(state and CS.UiButtonState.Select or CS.UiButtonState.Normal)
            local tempLevel = level
            toggle.CallBack = function()
                self:OnToggleClick(tempLevel)
            end
        end
    end

    
end

--endregion------------------初始化数据 finish------------------

function XUiDormBagChoice:UpdateSelectMap()
    self.SelectMap = {}
    for _, id in pairs(self.SelectIds) do
        self.SelectMap[id] = true
    end
end