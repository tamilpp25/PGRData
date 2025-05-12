local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridStorage = XClass(nil, "XUiGridStorage")

function XUiGridStorage:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
end

--- 刷新产品
---@param product XRestaurantProductVM
--------------------------
function XUiGridStorage:Refresh(product)
    self.RImgIcon:SetRawImage(product:GetProductIcon())
    self.TxtCount.text = product:GetCount()
    self.ImgFull.gameObject:SetActiveEx(product:IsFull())
    if not XTool.UObjIsNil(self.ImgQuality) then
        self.ImgQuality:SetSprite(product:GetQualityIcon(true))
    end
end

---@class XUiPanelStorage : XUiNode 仓库
---@field _Control XRestaurantControl
local XUiPanelStorage = XClass(XUiNode, "XUiPanelStorage")

local MoveDuration = 0.5 --移动时间

function XUiPanelStorage:OnStart()
    self:InitDynamicTable()
    self:InitCb()
    self.Name = self.GameObject.name
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

function XUiPanelStorage:Show(areaType, title)
    self:Open()
    self.AreaType = areaType
    self.Title = title
    self:RefreshTitle()
    self:SetupDynamicTable()
    self:BindViews(self.ProductList)
end

function XUiPanelStorage:Hide()
    self:Close()
end

function XUiPanelStorage:OnDestroy()
    if not XTool.IsTableEmpty(self.ProductList) then
        local hashCode = self:GetHashCode()
        for _, product in ipairs(self.ProductList) do
            product:ClearBind(hashCode)
        end
    end
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
    local list = self._Control:GetUnlockProductList(self.AreaType, true)
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
---@param viewModel XRestaurantProductVM
---@return void
--------------------------
function XUiPanelStorage:BindViewModel(viewModel)
    if not viewModel then
        return
    end
    local properties = { 
        viewModel.Property.Count,
    }
    local hashCode = self:GetHashCode()
    viewModel:BindViewModelPropertiesToObj(hashCode, properties, function()
        self:SetupDynamicTable()
    end)
end

function XUiPanelStorage:GetHashCode()
    if not self.HashCode then
        self.HashCode = self.GameObject:GetHashCode()
    end
    return self.HashCode
end

function XUiPanelStorage:BindViews(viewModelList)
    if self.BindView or XTool.IsTableEmpty(viewModelList) then
        return
    end
    self.BindView = true
    for _, product in pairs(viewModelList or {}) do
        self:BindViewModel(product)
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
    local areaType = self._Control:IsIngredientArea(self.AreaType)
            and XMVCA.XRestaurant.AreaType.IngredientArea or XMVCA.XRestaurant.AreaType.FoodArea
    self._Control:OpenStatistics(areaType)
end


return XUiPanelStorage