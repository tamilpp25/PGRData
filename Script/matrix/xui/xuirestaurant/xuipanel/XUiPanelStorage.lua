local XUiGridStorage = XClass(nil, "XUiGridStorage")

function XUiGridStorage:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
end

function XUiGridStorage:Refresh(product)
    self.RImgIcon:SetRawImage(product:GetProductIcon())
    self.TxtCount.text = product:GetProperty("_Count")
    self.ImgFull.gameObject:SetActiveEx(product:IsFull())
    if not XTool.UObjIsNil(self.ImgQuality) then
        self.ImgQuality:SetSprite(product:GetQualityIcon(true))
    end
end

---@class XUiPanelStorage 仓库
local XUiPanelStorage = XClass(nil, "XUiPanelStorage")

local MoveDuration = 0.5 --移动时间

function XUiPanelStorage:Ctor(ui, rooUi)
    XTool.InitUiObjectByUi(self, ui)
    self.RootUi = rooUi
    self:InitDynamicTable()
    self:InitCb()
end

function XUiPanelStorage:InitDynamicTable()
    if XTool.UObjIsNil(self.PanelList) then
        return
    end
    --XUiHelper.RegisterClickEvent(self, self.PanelList, self.OnPanelListClick)
    ---@type XDynamicTableNormal
    self.DynamicTable = XDynamicTableNormal.New(self.PanelList)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridStorage)
    self.GridItem.gameObject:SetActiveEx(false)
    
    -- 展开动画相关
    if self:CheckNeedExpand() then
        ---@type UnityEngine.RectTransform
        self.Content = self.PanelList.transform:Find("Viewport/PanelContent")
        self.ScrollRect = self.PanelList:GetComponent("ScrollRect")
        self.IsExpand = true
    end
    
end

function XUiPanelStorage:InitCb()
    if self:CheckNeedExpand() then
        self.BtnExpand.CallBack = handler(self, self.OnBtnExpandClick)
    end
end

function XUiPanelStorage:Show(areaType, title, ...)
    self.GameObject:SetActiveEx(true)
    self.Args = { ... }
    self.AreaType = areaType
    self.Title = title
    self:RefreshTitle()
    self:SetupDynamicTable()
    self:BindViews(self.ProductList)
end

function XUiPanelStorage:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiPanelStorage:RefreshTitle()
    if XTool.UObjIsNil(self.TxtTitle) or string.IsNilOrEmpty(self.Title) then
        return
    end
    self.Title.text = self.Title
end

function XUiPanelStorage:SetupDynamicTable()
    if not self.DynamicTable or self.BindView then
        return
    end
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    local list = viewModel:GetSortStorageProductList(self.AreaType)
    self.ProductList = list
    self.DynamicTable:SetDataSource(list)
    self.DynamicTable:ReloadDataSync()
end

function XUiPanelStorage:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.ProductList[index])
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:OnPanelListClick()
    end
end

function XUiPanelStorage:CheckNeedExpand()
    return not XTool.UObjIsNil(self.BtnExpand)
end

--- 绑定数据层
---@param luaUi XLuaUi
---@param viewModel XRestaurantProduct
---@return void
--------------------------
function XUiPanelStorage:BindViewModel(luaUi, viewModel, ...)
    if not luaUi or not viewModel then
        return
    end
    
    luaUi:BindViewModelPropertiesToObj(viewModel, function() 
        self:SetupDynamicTable()
    end, ...)
end

function XUiPanelStorage:BindViews(viewModelList)
    if self.BindView or XTool.IsTableEmpty(viewModelList) then
        return
    end
    self.BindView = true
    local args = table.unpack(self.Args)
    for _, product in pairs(viewModelList or {}) do
        self:BindViewModel(self.RootUi, product, args)
    end
    self.BindView = false
end

function XUiPanelStorage:OnBtnExpandClick()
    if XTool.UObjIsNil(self.PanelList) then
        return
    end
    local contentWidth = self.Content.rect.width
    local width = self.IsExpand and contentWidth or -contentWidth
    local position = self.Content.anchoredPosition
    local posX = position.x
    self:OnBeginExpand()
    XUiHelper.Tween(MoveDuration, function(delta)
        if XTool.UObjIsNil(self.Content) then
            return
        end
        position.x = posX + delta * width
        self.Content.anchoredPosition = position
    end, function()
        self:OnEndExpand()
    end)
end

function XUiPanelStorage:OnBeginExpand()
    if XTool.UObjIsNil(self.PanelList) then
        return
    end
    self.BtnExpand.enabled = false
    self.ScrollRect.enabled = false
    self.DynamicTable:GetImpl().enabled = false
end

function XUiPanelStorage:OnEndExpand()
    self.IsExpand = not self.IsExpand
    if XTool.UObjIsNil(self.BtnExpand) 
            or XTool.UObjIsNil(self.ScrollRect) 
            or not self.DynamicTable then
        return
    end
    self.BtnExpand.enabled = true
    if self.IsExpand then
        self.ScrollRect.enabled = true
        self.DynamicTable:GetImpl().enabled = true
    end
end

function XUiPanelStorage:OnPanelListClick()
    if not self.IsExpand then
        return
    end
    local areaType = XRestaurantConfigs.CheckIsIngredientArea(self.AreaType)
            and XRestaurantConfigs.AreaType.IngredientArea or XRestaurantConfigs.AreaType.FoodArea
    XDataCenter.RestaurantManager.OpenStatistics(areaType)
end


return XUiPanelStorage