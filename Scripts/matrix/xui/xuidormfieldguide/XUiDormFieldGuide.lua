local Object = CS.UnityEngine.Object
local Vector3 = CS.UnityEngine.Vector3
local V3O = Vector3.one
---@class XUiDormFieldGuide : XLuaUi
---@field DrdPart UnityEngine.UI.Dropdown
---@field TogCheck UnityEngine.UI.Toggle
local XUiDormFieldGuide = XLuaUiManager.Register(XLuaUi, "UiDormFieldGuide")
local XUiDormFieldGuideListItem = require("XUi/XUiDormFieldGuide/XUiDormFieldGuideListItem")
local XUiDormFieldGuideTab = require("XUi/XUiDormFieldGuide/XUiDormFieldGuideTab")

local TextManager = CS.XTextManager
local Next = next

function XUiDormFieldGuide:OnAwake()
    XTool.InitUiObject(self)
    self.TabDicIndex = {}
    self.TabObs = {}
    self.TabObs[1] = self.BtnTab1
    self.FilterTypeId = 0
    self.FilterSuitIdMap = {}
    self.CheckHasDrawing = false --是否需要检测有图纸
    self:InitUI()
    self:InitCB()
end

--- 
---@param suitId number 套装Id
---@param isRefit boolean 是否是改装
---@param closeCb function 界面关闭回调
--------------------------
function XUiDormFieldGuide:OnStart(suitId, isRefit, selectId, selectCb)
    self.HaveFurIds = XDataCenter.DormManager.FurnitureUnlockList or {}
    self.FileGuideData = XFurnitureConfigs.GetFieldGuideDatas()
    self.SelectCb = selectCb
    self.IsRefit = isRefit
    self.DefaultSelectId = selectId
    self:InitList()
    self:InitEnterCfg()
    local id = suitId
    if not suitId and self.TabTypeCfg[1] then
        id = self.TabTypeCfg[1].Id
    end
    local index = 1
    if id and self.TabDicIndex[id] then
        index = self.TabDicIndex[id]
    end
    self.Tabgroup:SelectIndex(index)
    self:CenterToGrid(index)
    self.PanelCheck.gameObject:SetActiveEx(isRefit)
    self.PanelCount.gameObject:SetActiveEx(not isRefit)
end

function XUiDormFieldGuide:CenterToGrid(index)
    local normalizedPosition
    local count = self.ScrollView.content.transform.childCount
    if index > count / 2 then
        normalizedPosition = (index + 1) / count
    else
        normalizedPosition = (index - 1) / count
    end

    self.ScrollView.verticalNormalizedPosition = math.max(0, math.min(1, (1 - normalizedPosition)))
end

function XUiDormFieldGuide:InitEnterCfg()
    self.TabTypeCfg = {}

    local cfg = XFurnitureConfigs.GetFurnitureSuitTemplates()
    ---@param template XTable.XTableFurnitureSuit
    local check = function(template)
        if self.IsRefit then
            if template.IsIgnoreWhenCreate == 1 then
                self.FilterSuitIdMap[template.Id] = true
                return false
            elseif template.Id == XFurnitureConfigs.BASE_SUIT_ID then
                return false
            else
                return true
            end
        else
            return self.FileGuideData[template.Id] and true or false
        end
    end
    
    for _, v in pairs(cfg) do
        --改装不显示基础套
        if check(v) then
            table.insert(self.TabTypeCfg, v)
        end
    end
    

    self:CreateTypeItems(self.TabTypeCfg)
end

function XUiDormFieldGuide:CreateTypeItems(tabTypeCfg)
    if self.PanelTab then
        local index = 1
        for k, v in pairs(tabTypeCfg) do
            local obj = self.TabObs[k]
            if not obj then
                obj = Object.Instantiate(self.BtnTab1)
                obj.transform:SetParent(self.PanelTab.transform, false)
                obj.transform.localScale = V3O
                table.insert(self.TabObs, obj)
            end
            self.TabDicIndex[v.Id] = index
            index = index + 1
            obj.gameObject:SetActive(true)

            local uiTab = XUiDormFieldGuideTab.New(obj)
            uiTab:SetName(v.SuitName)
            local suitBgmInfo = (not self.IsRefit) and XDormConfig.GetDormSuitBgmInfo(v.Id) or nil
            uiTab:SetSuitBgm(suitBgmInfo)
        end

        self.Tabgroup = self.PanelTab:GetComponent("XUiButtonGroup")
        self.Tabgroup:Init(self.TabObs, function(tab) self:TabSkip(tab) end)
    end
end

function XUiDormFieldGuide:TabSkip(tab)
    if tab == self.PreSeleTab then
        return
    end

    self.PreSeleTab = tab
    local cfg = self.TabTypeCfg[tab]
    self:OnClickEnterSetListData(cfg.Id)
    self:PlayAnimation("QieHuan")
    local suitBgmInfo = (not self.IsRefit) and XDormConfig.GetDormSuitBgmInfo(cfg.Id) or nil

    self.MusicText.gameObject:SetActiveEx(suitBgmInfo ~= nil)
    if suitBgmInfo then
        self.MusicText.text = string.format(CS.XGame.ClientConfig:GetString("DormSuitBgmDesc"), suitBgmInfo.SuitNum, ",", suitBgmInfo.Name)
    end
end

function XUiDormFieldGuide:InitList()
    self.PanelItemCommon.gameObject:SetActiveEx(not self.IsRefit)
    self.PanelItemRefit.gameObject:SetActiveEx(self.IsRefit)
    self.PanelBtn.gameObject:SetActiveEx(self.IsRefit)
    local target = self.IsRefit and self.PanelItemRefit or self.PanelItemCommon
    self.DynamicTable = XDynamicTableNormal.New(target)
    self.DynamicTable:SetProxy(XUiDormFieldGuideListItem)
    self.DynamicTable:SetDelegate(self)
    --self.GridItem.gameObject:SetActiveEx(false)
    ---@type XDynamicTableNormal
    local impl = self.DynamicTable:GetImpl()
    if not XTool.UObjIsNil(impl.Grid) then
        impl.Grid.gameObject:SetActiveEx(false)
    end
end

-- [监听动态列表事件]
function XUiDormFieldGuide:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.ListData[index]
        local selectId = self.SelectFurniture and self.SelectFurniture.Id or self.DefaultSelectId
        grid:OnRefresh(data, self.HaveFurIds, self.IsRefit, selectId)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local data = self.ListData[index]
        if self.IsRefit then
            if self.LastGrid then
                self.LastGrid:SetSelect(false)
            end
            local lastId = self.LastGrid and self.LastGrid.Id or -1
            if grid.Id == lastId then
                grid:SetSelect(false)
                self.SelectFurniture = nil
            else
                grid:SetSelect(true)
                self.SelectFurniture = data
            end
            self.LastGrid = grid
        else
            XLuaUiManager.Open("UiDormFieldGuideDes", data)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        local selectId = self.SelectFurniture and self.SelectFurniture.Id or self.DefaultSelectId
        if not XTool.IsNumberValid(selectId) then
            return
        end
        local grids = self.DynamicTable:GetGrids()
        for _, tempGrid in pairs(grids) do
            if tempGrid.Id == selectId then
                self.LastGrid = tempGrid
                break
            end
        end
    end
end

function XUiDormFieldGuide:OnClickEnterSetListData(t)
    if not t then
        return
    end

    self.SelectFurniture = nil
    self.PreSeleId = t
    local data = self.FileGuideData[t] or self:GetAllGuideData()
    data = self:FilterGuideData(data)
    local isEmpty = XTool.IsTableEmpty(data) 
    if not isEmpty then
        if self.IsRefit then
            table.sort(data, self.SortOnRefitCb)
        else
            table.sort(data, self.SortFileGuildCb)
        end
    end
    local showEmpty = self.IsRefit and isEmpty
    self.PanelEmpty.gameObject:SetActiveEx(showEmpty)
    self.PanelEmptyRefit.gameObject:SetActiveEx(showEmpty)
    self:SetMaterials(data)
    self.ListData = data
    local startIndex = 1
    if self.DefaultSelectId then
        for index, temp in pairs(data) do
            if temp.Id == self.DefaultSelectId then
                self.SelectFurniture = temp
                self.DefaultSelectId = nil
                startIndex = index
                break
            end
        end
    end
    self.DynamicTable:SetDataSource(data)
    self.DynamicTable:ReloadDataASync(startIndex)
end

function XUiDormFieldGuide:FilterGuideData(data)
    --正常图鉴不需要剔除
    local list = {}
    data = data or {}
    for _, item in ipairs(data) do
        if self:CheckFurnitureFilter(item) then
            table.insert(list, item)
        end
    end
    
    return list
end

---@param template XTable.XTableFurniture
function XUiDormFieldGuide:CheckFurnitureFilter(template)
    if not template then
        return false
    end

    --筛选家具类型 && 类型不一致
    if self.FilterTypeId ~= 0 and template.TypeId ~= self.FilterTypeId then
        return false
    end

    --仅显示有图纸的家具 && 拥有图纸
    if self.CheckHasDrawing and not self:CheckHasDraw(template.Id) then
        return false
    end

    --改装 && 基础套 && 未拥有
    if self.IsRefit and (template.SuitId == XFurnitureConfigs.BASE_SUIT_ID or self.FilterSuitIdMap[template.SuitId]) then
        return false
    end
    
    return true
end

function XUiDormFieldGuide:GetAllGuideData()
    if self.AllGuideData then
        return self.AllGuideData
    end
    local list = {}
    for _, data in pairs(self.FileGuideData) do
        for _, itemData in ipairs(data) do
            table.insert(list, itemData)
        end
    end
    self.AllGuideData = list
    
    return list
end

function XUiDormFieldGuide:SetMaterials(data)
    local total = 0
    local count = 0
    local f = false
    for _, v in pairs(data) do
        total = total + 1
        if not f and self.HaveFurIds[v.Id] then
            count = count + 1
        else
            f = true
        end
    end

    if count ~= self.CurHaveCount or total ~= self.CurTotalCount then
        self.CurHaveCount = count
        self.CurTotalCount = total
        self.TxtMaterials.text = TextManager.GetText("DormFieldGuildeCountText", count, total)
    end

end

function XUiDormFieldGuide:Fielguildsortfun(a, b)
    if self.HaveFurIds[a.Id] and not self.HaveFurIds[b.Id] then
        return true
    end

    if not self.HaveFurIds[a.Id] and self.HaveFurIds[b.Id] then
        return false
    end

    return a.Id > b.Id
end

function XUiDormFieldGuide:SortOnRefit(a, b)
    local ownA = self.HaveFurIds[a.Id] and true or false
    local ownB = self.HaveFurIds[b.Id] and true or false
    if ownA ~= ownB then
        return ownA 
    end

    if a.TypeId ~= b.TypeId then
        local typeA = XFurnitureConfigs.GetFurnitureTypeById(a.TypeId)
        local typeB = XFurnitureConfigs.GetFurnitureTypeById(b.TypeId)
        return typeA.Priority < typeB.Priority
    end
    
    return a.Id < b.Id
end

function XUiDormFieldGuide:InitUI()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.DormCoin, XDataCenter.ItemManager.ItemId.FurnitureCoin)
    self.SortOnRefitCb = handler(self, self.SortOnRefit)
    self.SortFileGuildCb = handler(self, self.Fielguildsortfun)
    self.TogCheck.isOn = self.CheckHasDrawing
    self:InitDropDown()
    self:AddListener()
    
    self.PanelEmptyRefit = self.PanelItemRefit.transform:Find("Viewport/PanelEmpty")
end

function XUiDormFieldGuide:InitCB()
    self.BtnConfirm.CallBack = function() 
        self:OnBtnConfirmClick()
    end
end

function XUiDormFieldGuide:InitDropDown()
    
    self.DrdPart:ClearOptions()
    local op = CS.UnityEngine.UI.Dropdown.OptionData()
    op.text = XUiHelper.GetText("FurnitureAllTypeText")
    self.DrdPart.options:Add(op)
    local index = 0
    self.Index2TypeId = {
        [index] = 0
    }
    local list = XFurnitureConfigs.GetFurnitureTemplateTypeList()
    for _, template in ipairs(list) do
        index = index + 1
        self.Index2TypeId[index] = template.Id
        op = CS.UnityEngine.UI.Dropdown.OptionData()
        op.text = template.CategoryName
        self.DrdPart.options:Add(op)
    end
    self.DrdPart.value = 0
    self.DrdPart.onValueChanged:AddListener(function() 
        self:OnChooseFurnType()
    end)
end

function XUiDormFieldGuide:AddListener()
    self.OnBtnMainUIClickCb = function() self:OnBtnMainUIClick() end
    self.OnBtnReturnClickCb = function() self:OnBtnReturnClick() end
    self.OnBtnHelpClickCb = function() self:OnBtnHelpClick() end
    
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUIClickCb)
    self:RegisterClickEvent(self.BtnBack, self.OnBtnReturnClickCb)
    
    self.TogCheck.onValueChanged:AddListener(function() 
        self:OnToggleCheckDrawing()
    end)
end

function XUiDormFieldGuide:OnBtnMainUIClick()
    XLuaUiManager.RunMain()
end

function XUiDormFieldGuide:OnBtnReturnClick()
    self:Close()
end

function XUiDormFieldGuide:OnChooseFurnType()
    self.FilterTypeId = self.Index2TypeId[self.DrdPart.value]
    local cfg = self.TabTypeCfg[self.PreSeleTab]
    self:OnClickEnterSetListData(cfg.Id)
end 

function XUiDormFieldGuide:OnToggleCheckDrawing()
    self.CheckHasDrawing = self.TogCheck.isOn
    local cfg = self.TabTypeCfg[self.PreSeleTab]
    self:OnClickEnterSetListData(cfg.Id)
end 

function XUiDormFieldGuide:CheckHasDraw(furnitureId)
    local template = XFurnitureConfigs.GetFurnitureTemplateById(furnitureId)
    if not template then
        return false
    end
    local picId = template.PicId
    --无需图纸
    if not XTool.IsNumberValid(picId) then
        return true
    end
    return XDataCenter.ItemManager.GetCount(picId) > 0
end 

function XUiDormFieldGuide:OnBtnConfirmClick()
    self:Close()
    if self.SelectCb then
        self.SelectCb(self.TabTypeCfg[self.PreSeleTab], self.SelectFurniture)
    end
end