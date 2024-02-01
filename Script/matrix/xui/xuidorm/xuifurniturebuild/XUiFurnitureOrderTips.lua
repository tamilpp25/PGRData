--region   ------------------XUiGridReformInfo start-------------------

local XUiGridReformInfo = XClass(nil, "XUiGridReformInfo")

function XUiGridReformInfo:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
end

function XUiGridReformInfo:RefreshPreView(previewId, count)
    self.TxtNum.text = count
    self.TxtName.text = XFurnitureConfigs.GetFurnitureTemplateById(previewId).Name
    self.GameObject:SetActiveEx(true)
end

function XUiGridReformInfo:RefreshDrawing(drawId, count)
    if XTool.IsNumberValid(drawId) and drawId > 0 then
        self.GameObject:SetActiveEx(true)
        self.TxtNum.text = count
        self.TxtName.text = XDataCenter.ItemManager.GetItemName(drawId)
    else
        self.GameObject:SetActiveEx(false)
    end
end

function XUiGridReformInfo:RefreshFurniture(id, count, isReform)
    self.TxtNum.text = count
    if isReform then
        local furniture = XDataCenter.FurnitureManager.GetFurnitureById(id)
        self.TxtName.text = XFurnitureConfigs.GetFurnitureTemplateById(furniture:GetConfigId()).Name
        self.TxtLevel = XFurnitureConfigs.FurnitureAttrLevel[furniture:GetFurnitureTotalAttrLevel()]
    else
        local template = XFurnitureConfigs.GetFurnitureTypeById(id)
        self.TxtName.text = template.CategoryName
        
    end
    self.GameObject:SetActiveEx(true)
end


--endregion------------------XUiGridReformInfo finish------------------


--region   ------------------XUiPanelOrderReformInfo start-------------------

local XUiPanelOrderReformInfo = XClass(nil, "XUiPanelOrderReformInfo")
local GridType = {
    Preview     = 1,
    Furniture   = 2,
    Drawing     = 3
}

function XUiPanelOrderReformInfo:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
    self.GirdPreviewFurniture.gameObject:SetActiveEx(false)
    self.GirdDrawing.gameObject:SetActiveEx(false)
    self.GirdFurniture.gameObject:SetActiveEx(false)
end

function XUiPanelOrderReformInfo:RefreshInfo(reformData, isReform)
    for _, data in ipairs(reformData) do
        local gridPreview = XUiGridReformInfo.New(self:GetUiGrid(GridType.Preview))
        gridPreview:RefreshPreView(data.TargetId, data.Count)
        for drawId, count in pairs(data.Draw or {}) do
            local grid = XUiGridReformInfo.New(self:GetUiGrid(GridType.Drawing))
            grid:RefreshDrawing(drawId, count)
        end

        for id, furniture in pairs(data.Furniture or {}) do
            if type(furniture) == "number" then
                local grid = XUiGridReformInfo.New(self:GetUiGrid(GridType.Furniture))
                grid:RefreshFurniture(id, furniture, isReform)
            elseif type(furniture) == "table" then
                for _, fId in ipairs(furniture) do
                    local grid = XUiGridReformInfo.New(self:GetUiGrid(GridType.Furniture))
                    grid:RefreshFurniture(fId, 1, isReform)
                end
            end
            
        end
    end
end

function XUiPanelOrderReformInfo:GetUiGrid(type)
    if type == GridType.Preview then
        return XUiHelper.Instantiate(self.GirdPreviewFurniture, self.ContentNews)
    elseif type == GridType.Furniture then
        return XUiHelper.Instantiate(self.GirdFurniture, self.ContentNews)
    else
        return XUiHelper.Instantiate(self.GirdDrawing, self.ContentNews)
    end
end

--endregion------------------XUiPanelOrderReformInfo finish------------------


--region   ------------------XUiPanelOrderReform start-------------------

local XUiPanelOrderReform = XClass(nil, "XUiFurnitureOrderTips")

function XUiPanelOrderReform:Ctor(ui, refitCb)
    XTool.InitUiObjectByUi(self, ui)
    self.PanelReformInfo = XUiPanelOrderReformInfo.New(self.PanelReform)
    if self.PanelUnReform then
        self.PanelUnReformInfo = XUiPanelOrderReformInfo.New(self.PanelUnReform)
    end
    self.RefitCb = refitCb
    
    self.BtnRefit.CallBack = function() 
        self:OnBtnRefitClick()
    end
    self.BtnRefit:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XDataCenter.ItemManager.ItemId.FurnitureCoin))
end

function XUiPanelOrderReform:Refresh(reformData, unReformData, cost)
    self.GameObject:SetActiveEx(true)
    self.PanelReformInfo:RefreshInfo(reformData, true)
    if self.PanelUnReformInfo then
        self.PanelUnReformInfo:RefreshInfo(unReformData, false)
    end
    local unBuild, build = 0, 0
    local remouldMap = {}
    for _, reform in pairs(reformData) do
        build = build + reform.Count
        local furnitureIds = {}
        for _, ids in pairs(reform.Furniture or {}) do
            for _, id in ipairs(ids) do
                table.insert(furnitureIds, id)
            end
        end 
        local drawId
        for id, _ in pairs(reform.Draw) do
            drawId = id
            break
        end
        remouldMap[drawId] = furnitureIds
    end

    for _, unReform in pairs(unReformData) do
        unBuild = unBuild + unReform.Count
    end
    self.TxtCount.text = string.format("%d/%d", build, build + unBuild)
    local txtCount = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.FurnitureCoin) >= cost 
            and XUiHelper.GetText("DormBuildEnoughCountWhite", cost) or XUiHelper.GetText("DormBuildNoEnoughCount", cost)
    self.BtnRefit:SetNameByGroup(1, txtCount)
    self.RemouldMap = remouldMap
    self.Cost = cost
end

function XUiPanelOrderReform:OnBtnRefitClick()
    if XTool.IsTableEmpty(self.RemouldMap) then
        return
    end
    if XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.FurnitureCoin) 
            < self.Cost then
        XUiManager.TipText("FurnitureZeroCoin")
        return
    end
    XDataCenter.FurnitureManager.RemouldFurniture(self.RemouldMap, self.RefitCb, nil, true, true)
end

--endregion------------------XUiPanelOrderReform finish------------------


--region   ------------------XUiFurnitureOrderTips start-------------------


local XUiFurnitureOrderTips = XLuaUiManager.Register(XLuaUi, "UiFurnitureOrderTips")

function XUiFurnitureOrderTips:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiFurnitureOrderTips:OnStart(reformData, unReformData, costCount, refitCb)
    local newCb = function()
        self:Close()
        if refitCb then refitCb() end
    end
    if XTool.IsTableEmpty(unReformData) then
        self.PanelOrderReform = XUiPanelOrderReform.New(self.PanelReformOnly, newCb)
    else
        self.PanelOrderReform = XUiPanelOrderReform.New(self.PanelReformAndUnReform, newCb)
    end
    
    self.PanelOrderReform:Refresh(reformData, unReformData, costCount)
end

function XUiFurnitureOrderTips:InitUi()
    self.PanelReformOnly.gameObject:SetActiveEx(false)
    self.PanelReformAndUnReform.gameObject:SetActiveEx(false)
end

function XUiFurnitureOrderTips:InitCb()
    self.BtnClose.CallBack = function() self:Close() end
end

--endregion------------------XUiFurnitureOrderTips finish------------------
