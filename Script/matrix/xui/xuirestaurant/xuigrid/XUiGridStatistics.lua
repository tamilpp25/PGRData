local XUiGridChange = XClass(nil, "XUiGridChange")

local Inaccurate = XMVCA.XRestaurant.Inaccurate

function XUiGridChange:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
end

function XUiGridChange:Refresh(title, speed, unit)
    self.TxtTitle.text = title
    if speed <= Inaccurate and speed >= -Inaccurate then
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


---@class XUiGridStatistics : XUiNode
---@field _Control XRestaurantControl
local XUiGridStatistics = XClass(XUiNode, "XUiGridStatistics")

function XUiGridStatistics:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
    self.GridProduce = XUiGridChange.New(self.PanelCook)
    self.GridConsume = XUiGridChange.New(self.PanelSell)
    self.GridChange  = XUiGridChange.New(self.PanelChange)
end

---@param product XRestaurantProductVM
---@param areaType number
function XUiGridStatistics:Refresh(product, areaType)
    if not product then
        self.GameObject:SetActiveEx(false)
        return
    end
    self.RImgIcon:SetRawImage(product:GetProductIcon())
    self.TxtName.text = product:GetName()
    self.EffectFlash.gameObject:SetActiveEx(false)
    
    local productId = product:GetProductId()
    local produceSpeed = self._Control:GetProduceTotalSpeed(areaType, productId)
    local consumeSpeed = self._Control:GetConsumeTotalSpeed(areaType, productId)
    local subSpeed = self._Control:GetAroundValue((produceSpeed - consumeSpeed + Inaccurate), 
            XMVCA.XRestaurant.Digital.One)
    local unit = self._Control:GetStatisticsUnit(1)
    self.GridProduce:Refresh(self._Control:GetStatisticsTip(areaType, 1), produceSpeed, unit)
    self.GridConsume:Refresh(self._Control:GetStatisticsTip(areaType, 2), -1 * consumeSpeed, unit)
    self.GridChange:Refresh(self._Control:GetStatisticsTip(areaType, 3), subSpeed, unit)

    local count = product:GetCount()
    self.PanelCount.gameObject:SetActiveEx(true)
    self.TxtCount.text = count
    self.TxtInventory.gameObject:SetActiveEx(false)
end

function XUiGridStatistics:ShowEffect()
    self.EffectFlash.gameObject:SetActiveEx(true)
end

return XUiGridStatistics