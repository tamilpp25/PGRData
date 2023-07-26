local XUiGridDressingOverview = XClass(nil, "XUiGridDressingOverview")

function XUiGridDressingOverview:Ctor(ui, parentUi)
    XTool.InitUiObjectByUi(self, ui)
    self.ParentUi = parentUi
    self.PanelTemplateNone.gameObject:SetActiveEx(false)
    self.BtnClick.CallBack = function() 
        self:OnBtnClick()
    end
end

---@param template XTable.XTableFurnitureSuit
function XUiGridDressingOverview:Refresh(template, selectId)
    if not template then
        self.GameObject:SetActiveEx(false)
        return
    end
    
    self.Template = template
    if string.IsNilOrEmpty(template.SuitBigIcon) then
        self.RImgIcon:SetRawImage(template.SuitIcon)
    else
        self.RImgIcon:SetRawImage(template.SuitBigIcon)
    end
    
    self.TxtName.text = template.SuitName
    self.TxtCount.text = self.ParentUi:GetFurnitureNumsBySuitId(self:GetSelectId())
    self:SetSelect(selectId == template.Id)
end

function XUiGridDressingOverview:SetSelect(select)
    self.IsSelect = select
    self.PanelSelect.gameObject:SetActiveEx(select)
end

function XUiGridDressingOverview:GetSelectId()
    return self.Template and self.Template.Id or -1
end

function XUiGridDressingOverview:OnBtnClick()
    if self.IsSelect then
        return
    end
    self:SetSelect(true)
    self.ParentUi:OnClickGrid(self)
end


local XUiDormDressingOverview = XLuaUiManager.Register(XLuaUi, "UiDormDressingOverview")

function XUiDormDressingOverview:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiDormDressingOverview:OnStart(suitId, roomType, furnitureCache, selectCb)
    self.SuitId = suitId
    self.SelectCb = selectCb
    self.FurnitureCache = furnitureCache or {}
    if not furnitureCache then
        self:RestoreCache()
    end
    self.IsOwnRoom = roomType == XDormConfig.DormDataType.Self
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.DormCoin, 
            XDataCenter.ItemManager.ItemId.FurnitureCoin, XDataCenter.ItemManager.ItemId.DormEnterIcon)
    
    self:SetupDynamicTable()
end

function XUiDormDressingOverview:InitUi()
    self.BtnMainUi.gameObject:SetActiveEx(false)
    self.BtnHelp.gameObject:SetActiveEx(false)
    self.GridDormTemplate.gameObject:SetActiveEx(false)
    
    self.DynamicTable = XDynamicTableNormal.New(self.PanelDynamicTable)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridDressingOverview, self)
end

function XUiDormDressingOverview:InitCb()
    self:BindExitBtns()
    
    self.BtnSelect.CallBack = function() 
        self:OnBtnSelectClick()
    end
    
    self.BtnCancel.CallBack = function() 
        self:OnBtnCancelClick()
    end
end

function XUiDormDressingOverview:SetupDynamicTable()
    local dataList = XFurnitureConfigs.GetFurnitureSuitTemplatesList()
    self.DataList = dataList
    self.PanelNoneTemplate.gameObject:SetActiveEx(XTool.IsTableEmpty(dataList))
    self.DynamicTable:SetDataSource(dataList)
    self.DynamicTable:ReloadDataSync()
end

function XUiDormDressingOverview:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.DataList[index])
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        
    end
end

function XUiDormDressingOverview:OnClickGrid(grid)
    if self.LastGrid then
        self.LastGrid:SetSelect(false)
    end
    self.SuitId = grid:GetSelectId()
    self.LastGrid = grid
end

function XUiDormDressingOverview:GetFurnitureNumsBySuitId(suitId)
    if self.IsOwnRoom then
        return XDataCenter.FurnitureManager.GetFurnitureCountBySuitId(self.FurnitureCache, suitId)
    end
    return XFurnitureConfigs.GetSuitCount(suitId)
end

function XUiDormDressingOverview:OnBtnSelectClick()
    self:Close()
    if self.SelectCb then self.SelectCb(self.SuitId) end
end

function XUiDormDressingOverview:OnBtnCancelClick()
    self:Close()
end

function XUiDormDressingOverview:RestoreCache()
    local allTypeTemplate = XFurnitureConfigs.GetAllFurnitureTypes()
    for _, data in pairs(allTypeTemplate) do
        local cacheKey = XDataCenter.FurnitureManager.GenerateCacheKey(data.MinorType, data.Category)
        self.FurnitureCache[cacheKey] = XDataCenter.FurnitureManager.FilterAndMergeDisplayFurnitureList(
                XFurnitureConfigs.FURNITURE_SUIT_CATEGORY_ALL_ID, data.MinorType, data.Category)
    end
end