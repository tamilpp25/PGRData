local XUiSkyGardenShoppingStreetInsideBuildGridMaterial = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetInsideBuildGridMaterial")
---@class XUiSkyGardenShoppingStreetInsideBuildDessert : XUiNode
---@field GridMaterial UnityEngine.RectTransform
---@field BtnMinus XUiComponent.XUiButton
---@field TxtNum UnityEngine.UI.Text
---@field BtnAdd XUiComponent.XUiButton
local XUiSkyGardenShoppingStreetInsideBuildDessert = XClass(XUiNode, "XUiSkyGardenShoppingStreetInsideBuildDessert")

function XUiSkyGardenShoppingStreetInsideBuildDessert:OnStart()
    ---@type XUiSkyGardenShoppingStreetInsideBuildGridMaterial
    self._GridMaterialsUi = {}
    self:_RegisterButtonClicks()
    -- self.DragUpdate = handler(self, self._DragUpdate)
end

function XUiSkyGardenShoppingStreetInsideBuildDessert:SetBuilding(pos, isInside)
    self._BuildPos = pos
    self._IsInside = isInside

    local shopAreaData = self._Control:GetShopAreaByUiPos(self._BuildPos, self._IsInside)
    local buildingId = shopAreaData:GetShopId()
    self._DessertCfg = self._Control:GetShopDessertConfigsByShopId(buildingId)
    self._DessertCount = #self._DessertCfg.Goods
    self._MinNum = self._DessertCfg.GoldMin
    self._MaxNum = self._DessertCfg.GoldMax

    self._TempSort = {}
    local dessertData = shopAreaData:GetDessertData()
    local goodsIdList, gold
    if dessertData then
        goodsIdList = dessertData.GoodsIdList
        gold = dessertData.Gold
    else
        goodsIdList = {1, 2, 3, 4}
        gold = XMath.Clamp(self._DessertCfg.InitGold, self._MinNum, self._MaxNum)
    end
    for i = 1, self._DessertCount do
        self._TempSort[i] = goodsIdList[self._DessertCount - i + 1]
    end
    self._Price = gold

    self:_UpdateGrid()
    self:_UpdatePrice()

    ---@type XUiSkyGardenShoppingStreetInsideBuildGridMaterial
    self.GridMaterialUi = XUiSkyGardenShoppingStreetInsideBuildGridMaterial.New(self.DragGridMaterial, self)
    self.GridMaterialUi:Close()
end

function XUiSkyGardenShoppingStreetInsideBuildDessert:MoveGrid(from, to)
    if not from or not to then return end
    -- if from > to then
    --     table.insert(self._TempSort, to, table.remove(self._TempSort, from))
    -- else
    --     table.insert(self._TempSort, from, table.remove(self._TempSort, to))
    -- end
    self._TempSort[from], self._TempSort[to] = self._TempSort[to], self._TempSort[from]
    self:_UpdateGrid()
end

function XUiSkyGardenShoppingStreetInsideBuildDessert:_UpdateGrid()
    self._GoodsId = {}
    for i = 1, #self._TempSort do
        local index = self._TempSort[i]
        if index and index <= self._DessertCount then
            local dessertId = self._DessertCfg.Goods[index]
            self._GoodsId[#self._GoodsId + 1] = dessertId
        end
    end
    XTool.UpdateDynamicItem(self._GridMaterialsUi, self._GoodsId, self.GridMaterial, XUiSkyGardenShoppingStreetInsideBuildGridMaterial, self)
end

function XUiSkyGardenShoppingStreetInsideBuildDessert:_UpdatePrice()
    self.TxtNum.text = self._Price
end

-- function XUiSkyGardenShoppingStreetInsideBuildDessert:OnGridMaterialClickDown(index, eventData)
--     if not index then return end
--     local grid = self._GridMaterialsUi[index]
--     local canvasGCom = grid.Transform.gameObject:GetComponent(typeof(CS.UnityEngine.CanvasGroup))
--     if XTool.UObjIsNil(canvasGCom) then
--         canvasGCom = grid.Transform.gameObject:AddComponent(typeof(CS.UnityEngine.CanvasGroup))
--     end
--     canvasGCom.alpha = 0
--     -- self.ListMaterial.alpha = 0.8
--     self._MousePos = eventData.position
--     self.GridMaterialUi:Open()
--     self.GridMaterialUi.Transform.position = grid.Transform.position
--     self.GridMaterialUi:Update(self._GoodsId[index])
--     self._CacheLocalPos = self.GridMaterialUi.Transform.localPosition
--     self._IsDragging = true
--     self._lastIndex = index
--     self._selectIndex = index
-- end

-- function XUiSkyGardenShoppingStreetInsideBuildDessert:OnGridMaterialClickUp(index, eventData)
--     self.ListMaterial.alpha = 1
--     self.GridMaterialUi:Close()
--     -- for i = 1, #self._GridMaterialsUi do
--     --     local grid = self._GridMaterialsUi[i]
--     --     local isUI = CS.UnityEngine.RectTransformUtility.RectangleContainsScreenPoint(grid.Transform, eventData.position, CS.XUiManager.Instance.UiCamera)
--     --     if isUI then
--     --         if index ~= i then
--     --             self:MoveGrid(index, i)
--     --         end
--     --         break
--     --     end
--     -- end
--     local grid = self._GridMaterialsUi[self._lastIndex]
--     local canvasGCom = grid.Transform.gameObject:GetComponent(typeof(CS.UnityEngine.CanvasGroup))
--     canvasGCom.alpha = 1
--     self._IsDragging = false
-- end

-- function XUiSkyGardenShoppingStreetInsideBuildDessert:OnGridMaterialClickDrag(index, eventData)
--     local gap = eventData.position - self._MousePos
--     self.GridMaterialUi.Transform.localPosition = CS.UnityEngine.Vector3(self._CacheLocalPos.x + gap.x, self._CacheLocalPos.y + gap.y, self._CacheLocalPos.z)
-- end

-- function XUiSkyGardenShoppingStreetInsideBuildDessert:OnEnable()
--     if not self._TimerId then
--         self._TimerId = XScheduleManager.ScheduleForever(self.DragUpdate, 1)
--     end
-- end

-- function XUiSkyGardenShoppingStreetInsideBuildDessert:OnDisable()
--     XScheduleManager.UnSchedule(self._TimerId)
--     self._TimerId = false
-- end

-- function XUiSkyGardenShoppingStreetInsideBuildDessert:_DragUpdate()
--     if not self._IsDragging then return end
--     local localPos = self.GridMaterialUi.Transform.localPosition
--     local eventDataPosition = CS.UnityEngine.Vector2(localPos.x - self._CacheLocalPos.x, localPos.y - self._CacheLocalPos.y) + self._MousePos
--     local foundIndex = 0
--     for i = 1, #self._GridMaterialsUi do
--         local grid = self._GridMaterialsUi[i]
--         local isUI = CS.UnityEngine.RectTransformUtility.RectangleContainsScreenPoint(grid.Transform, eventDataPosition, CS.XUiManager.Instance.UiCamera)
--         if isUI then
--             foundIndex = i
--             break
--         end
--     end
--     if foundIndex ~= 0 and foundIndex ~= self._lastIndex then
--         self:MoveGrid(self._lastIndex, foundIndex)
--         local grid = self._GridMaterialsUi[self._lastIndex]
--         local canvasGCom = grid.Transform.gameObject:GetComponent(typeof(CS.UnityEngine.CanvasGroup))
--         if XTool.UObjIsNil(canvasGCom) then
--             canvasGCom = grid.Transform.gameObject:AddComponent(typeof(CS.UnityEngine.CanvasGroup))
--         end
--         canvasGCom.alpha = 1
--         grid = self._GridMaterialsUi[foundIndex]
--         canvasGCom = grid.Transform.gameObject:GetComponent(typeof(CS.UnityEngine.CanvasGroup))
--         if XTool.UObjIsNil(canvasGCom) then
--             canvasGCom = grid.Transform.gameObject:AddComponent(typeof(CS.UnityEngine.CanvasGroup))
--         end
--         canvasGCom.alpha = 0
--         self._lastIndex = foundIndex
--     end
-- end

function XUiSkyGardenShoppingStreetInsideBuildDessert:OnBtnUpClick(index)
    self:MoveGrid(index, index + 1)
end

--region 按钮事件
function XUiSkyGardenShoppingStreetInsideBuildDessert:OnBtnMinusClick()
    local newPrice = XMath.Clamp(self._Price - 1, self._MinNum, self._MaxNum)
    if self._Price == newPrice then return end
    
    self._Price = newPrice
    self:_UpdatePrice()
end

function XUiSkyGardenShoppingStreetInsideBuildDessert:OnBtnAddClick()
    local newPrice = XMath.Clamp(self._Price + 1, self._MinNum, self._MaxNum)
    if self._Price == newPrice then return end
    
    self._Price = newPrice
    self:_UpdatePrice()
end

--endregion
function XUiSkyGardenShoppingStreetInsideBuildDessert:OnBtnSaveClick()
    local shopAreaData = self._Control:GetShopAreaByUiPos(self._BuildPos, self._IsInside)
    local sendData = {}
    for i = 1, self._DessertCount do
        sendData[i] = self._TempSort[self._DessertCount - i + 1]
    end
    self._Control:SgStreetShopSetupDessertRequest(
        shopAreaData:GetShopId(),
        sendData,
        self._Price
    )
end

--region 私有方法
function XUiSkyGardenShoppingStreetInsideBuildDessert:_RegisterButtonClicks()
    self.BtnMinus.CallBack = function() self:OnBtnMinusClick() end
    self.BtnAdd.CallBack = function() self:OnBtnAddClick() end
end
--endregion

return XUiSkyGardenShoppingStreetInsideBuildDessert
