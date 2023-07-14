local XUiGridChange = XClass(nil, "XUiGridChange")

function XUiGridChange:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
end

function XUiGridChange:Refresh(title, speed, unit)
    self.TxtTitle.text = title
    if speed <= XRestaurantConfigs.Inaccurate and speed >= -XRestaurantConfigs.Inaccurate then
        speed = 0
    end
    local isAdd = speed > 0
    if isAdd then
        self.TxtMinus.gameObject:SetActiveEx(false)
        self.TxtAdd.gameObject:SetActiveEx(true)
        self.TxtAdd.text = "+" .. speed .. unit
    else
        self.TxtMinus.gameObject:SetActiveEx(true)
        self.TxtAdd.gameObject:SetActiveEx(false)
        self.TxtMinus.text = speed .. unit
    end
end

local XUiGridStatistics = XClass(nil, "XUiGridStatistics")

function XUiGridStatistics:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
    self.GridProduce = XUiGridChange.New(self.PanelCook)
    self.GridConsume = XUiGridChange.New(self.PanelSell)
    self.GridChange  = XUiGridChange.New(self.PanelChange)
end

---@param product XRestaurantProduct
---@param areaType number
function XUiGridStatistics:Refresh(product, areaType)
    if not product then
        self.GameObject:SetActiveEx(false)
        return
    end
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    self.RImgIcon:SetRawImage(product:GetProductIcon())
    self.TxtName.text = product:GetProperty("_Name")
    self.EffectFlash.gameObject:SetActiveEx(false)
    
    local productId = product:GetProperty("_Id")
    local produceSpeed = viewModel:GetProduceTotalSpeed(areaType, productId)
    local consumeSpeed = viewModel:GetConsumeTotalSpeed(areaType, productId)
    local subSpeed = XRestaurantConfigs.GetAroundValue((produceSpeed - consumeSpeed + XRestaurantConfigs.Inaccurate), XRestaurantConfigs.Digital.One)
    local unit = XRestaurantConfigs.GetClientConfig("StatisticsUnit", 1)
    self.GridProduce:Refresh(XRestaurantConfigs.GetStatisticsTip(areaType, 1), produceSpeed, unit)
    self.GridConsume:Refresh(XRestaurantConfigs.GetStatisticsTip(areaType, 2), -1 * consumeSpeed, unit)
    self.GridChange:Refresh(XRestaurantConfigs.GetStatisticsTip(areaType, 3), subSpeed, unit)

    local count = product:GetProperty("_Count")
    self.PanelCount.gameObject:SetActiveEx(true)
    self.TxtCount.text = count
    --if XRestaurantConfigs.CheckIsIngredientArea(areaType) then
    --    self.TxtInventory.gameObject:SetActiveEx(true)
    --    --local freeCount = subSpeed < 0 and count or product:GetProperty("_Limit") - count
    --    --local desc = XRestaurantConfigs.GetStoragePreviewTip(produceSpeed, consumeSpeed, freeCount)
    --    local isUp, desc = viewModel:GetWorkBenchPreviewTip(areaType, productId)
    --    self.TxtInventory.text = desc
    --else
        self.TxtInventory.gameObject:SetActiveEx(false)
    --end
    --self.TxtInventory.gameObject:SetActiveEx(true)
    --local isUp, desc = viewModel:GetWorkBenchPreviewTip(areaType, productId)
    --self.TxtInventory.text = desc
end

function XUiGridStatistics:ShowEffect()
    self.EffectFlash.gameObject:SetActiveEx(true)
end

return XUiGridStatistics