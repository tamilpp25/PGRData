local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiGridBuffButton : XUiNode
---@field _Control XRestaurantControl
local XUiGridBuffButton = XClass(XUiNode, "XUiGridBuffButton")

local ColorEnum = {
    Up = XUiHelper.Hexcolor2Color("356C38"),
    Down = XUiHelper.Hexcolor2Color("CE453B")
}

function XUiGridBuffButton:Refresh(buffId, selectId)
    self.BuffId = buffId
    self:RefreshState(selectId)
end

function XUiGridBuffButton:RefreshState(selectId)
    local buff = self._Control:GetBuff(self.BuffId)
    local select = self.BuffId == selectId
    local unlock = buff:IsReachLevel()
    
    local areaType = buff:GetAreaType()
    local areaBuffId = self._Control:GetAreaBuffId(areaType)
    local isCur = areaBuffId and areaBuffId == self.BuffId or false
    self.BtnClick:ShowTag(isCur)
    if unlock then
        self.BtnClick:SetNameByGroup(0, buff:GetName())
    else
        local desc = string.format(self._Control:GetCommonUnlockText(4), buff:GetUnlockLv())
        self.BtnClick:SetNameByGroup(0, desc)
    end
    
    self.PanelNormal.gameObject:SetActiveEx(unlock and not select)
    self.PanelSelect.gameObject:SetActiveEx(unlock and select)
    self.PanelLock.gameObject:SetActiveEx(not unlock and not select)
    self.PanelLockSelect.gameObject:SetActiveEx(not unlock and select)
    
    self.BtnClick:ShowReddot(self._Control:CheckBuffRedPoint(areaType, self.BuffId))
end

function XUiGridBuffButton:Equal(selectId)
    return self.BuffId == selectId
end

function XUiGridBuffButton:MarkRedPoint()
    self.BtnClick:ShowReddot(false)
    self._Control:MarkBuffRedPoint(self.BuffId)
end

---@class XUiGridBuffFood : XUiNode
---@field _Control XRestaurantControl
local XUiGridBuffFood = XClass(XUiNode, "XUiGridBuffFood")

function XUiGridBuffFood:Refresh(productId, areaType, buffId)
    local product = self._Control:GetProduct(areaType, productId)
    local isUnlock = product:IsUnlock()
    self.PanelNormal.gameObject:SetActiveEx(isUnlock)
    self.PanelLock.gameObject:SetActiveEx(not isUnlock)
    if not isUnlock then
        return
    end
    self.TxtName.text = product:GetName()
    self.RImgIcon:SetRawImage(product:GetProductIcon())
    local buff = self._Control:GetBuff(buffId)
    local addition = buff:GetProductEffectAddition(areaType, productId)
    self.TxtAddition.text = self._Control:GetCharacterSkillPercentAddition(addition, areaType, productId)
    self.TxtAddition.color = addition > 0 and ColorEnum.Up or ColorEnum.Down
    
    local isHot = product:IsHotSale()
    local isFood = not self._Control:IsIngredientArea(areaType)
    self.PanelHot.gameObject:SetActiveEx(isFood and isHot)
end


---@class XUiRestaurantBuffChange : XLuaUi
---@field PanelTab XUiButtonGroup
---@field _Control XRestaurantControl
local XUiRestaurantBuffChange = XLuaUiManager.Register(XLuaUi, "UiRestaurantBuffChange")
--
--local XUiGridBuffInfoDetail = require("XUi/XUiRestaurant/XUiGrid/XUiGridBuffInfoDetail")

local BuffTypeTab = {
    XMVCA.XRestaurant.AreaType.IngredientArea,
    XMVCA.XRestaurant.AreaType.FoodArea,
    XMVCA.XRestaurant.AreaType.SaleArea,
}

function XUiRestaurantBuffChange:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiRestaurantBuffChange:OnStart(buffId)
    self.BuffId = buffId
    self:InitView()
end

function XUiRestaurantBuffChange:InitUi()
    self:InitBuffTypeTab()
    self:InitBuffDynamic()
    self:InitBuffFoodDynamic()
    self:InitStaffDynamic()
    
    self.CanBuyColor = XUiHelper.Hexcolor2Color("5B4040")
    self.NotBuyColor = XUiHelper.Hexcolor2Color("CE453B")

    self.CacheBenchList = {}
end

function XUiRestaurantBuffChange:InitCb()
    local close = handler(self, self.Close)

    self.BtnClose.CallBack = close
    self.BtnWndClose.CallBack = close
    
    self.BtnUse.CallBack = function() 
        self:OnBtnUseClick()
    end
    
    self.BtnUnlock.CallBack = function() 
        self:OnBtnUnlockClick()
    end
end

function XUiRestaurantBuffChange:InitView()
    self:RefreshBuffTypeTab()
    local areaType = self._Control:GetBuff(self.BuffId):GetAreaType()
    self.SelectBuffId[areaType] = self.BuffId
    self.PanelTab:SelectIndex(self:GetBuffTabIndex(areaType))
end

function XUiRestaurantBuffChange:OnSelectBuffType(tabIndex)
    if self.BuffIndex == tabIndex then
        return
    end
    local areaType = BuffTypeTab[tabIndex]
    local unlock = self._Control:CheckAreaBuffUnlock(areaType)
    if not unlock then
        XUiManager.TipMsg(self._Control:GetBuffAreaUnlockTip(areaType))
        return
    end
    
    self:PlayAnimation("QieHuan")
    self.BuffIndex = tabIndex
    self.LastBuffBtn = nil
    self:SetupBuffDynamic()
end

function XUiRestaurantBuffChange:RefreshBuffTypeTab()
    for index, btn in ipairs(self.BuffTypeTab) do
        local unlock = self._Control:CheckAreaBuffUnlock(BuffTypeTab[index])
        btn:SetDisable(not unlock)
    end
end

function XUiRestaurantBuffChange:SetupBuffDynamic()
    local areaType = BuffTypeTab[self.BuffIndex]
    local list = self._Control:GetBuffIdList(areaType)
    self.BuffIdList = self:GetSortBuffIds(list)
    local index = self:GetSelectIndex()
    self.DynamicBuff:SetDataSource(self.BuffIdList)
    self.DynamicBuff:ReloadDataSync(index)
end

function XUiRestaurantBuffChange:GetSortBuffIds(buffIds)
    local areaType = BuffTypeTab[self.BuffIndex]
    local areaBuffId = self._Control:GetAreaBuffId(areaType)
    
    table.sort(buffIds, function(a, b) 
        local isCurA = a == areaBuffId
        local isCurB = b == areaBuffId
        if isCurA ~= isCurB then
            return isCurA
        end
        local buffA = self._Control:GetBuff(a)
        local buffB = self._Control:GetBuff(b)
        
        local isUnlockA = buffA:IsUnlock()
        local isUnlockB = buffB:IsUnlock()

        if isUnlockA ~= isUnlockB then
            return isUnlockA
        end
        
        local isReachA = buffA:IsReachLevel()
        local isReachB = buffB:IsReachLevel()

        if isReachA ~= isReachB then
            return isReachA
        end
        
        return a < b
    end)
    
    return buffIds
end

function XUiRestaurantBuffChange:OnBuffDynamicEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local selectId = self.SelectBuffId[BuffTypeTab[self.BuffIndex]] or self.BuffIdList[1]
        grid:Refresh(self.BuffIdList[index], selectId)
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:OnSelectBuffBtn(index, grid)
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        local index = self:GetSelectIndex()
        self:OnSelectBuffBtn(index, self.DynamicBuff:GetGridByIndex(index))
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        self.LastBuffBtn = nil
    end
end

function XUiRestaurantBuffChange:GetSelectIndex()
    local selectId = self.SelectBuffId[BuffTypeTab[self.BuffIndex]]
    local index = 1
    if selectId then
        for i, id in ipairs(self.BuffIdList) do
            if id == selectId then
                index = i
                break
            end
        end
    end
    return index
end

function XUiRestaurantBuffChange:OnSelectBuffBtn(index, grid)
    local selectId = self.BuffIdList[index]
    local buff = self._Control:GetBuff(selectId)
    if not buff:IsReachLevel() then
        XUiManager.TipMsg(string.format(self._Control:GetCommonUnlockText(2), buff:GetUnlockLv()))
        return
    end
    --选中了同一个
    if self.LastBuffBtn and self.LastBuffBtn:Equal(selectId) then
        return
    end
    if self.LastBuffBtn then
        self.LastBuffBtn:RefreshState(selectId)
    end
    self:PlayAnimation("QieHuan")
    grid:RefreshState(selectId)
    grid:MarkRedPoint()
    self.SelectBuffId[BuffTypeTab[self.BuffIndex]] = selectId
    self.LastBuffBtn = grid
    
    self:RefreshRight()
    
end

function XUiRestaurantBuffChange:RefreshRight()
    self:SetupStaffDynamic()
    self:SetupDetailDynamic()
    
    local areaType = BuffTypeTab[self.BuffIndex]
    local useBuffId = self._Control:GetAreaBuffId(areaType)
    local selectId = self.SelectBuffId[areaType]
    
    local isUse = useBuffId == selectId
    local buff = self._Control:GetBuff(selectId)
    local unlock = buff:IsUnlock()
    
    self.BtnUse.gameObject:SetActiveEx(not isUse and unlock)
    self.BtnUnlock.gameObject:SetActiveEx(not isUse and not unlock)
    self.PanelInUse.gameObject:SetActiveEx(isUse and unlock)
    
    self.TxtBuffName.text = buff:GetName()
    self.TxtBuffDesc.text = buff:GetDescription()
    self.TxtAddDesc.text = self._Control:GetBuffAdditionText(areaType)

    if not isUse and not unlock then
        local costList = buff:GetUnlockCost()
        local validCost = #costList > 0
        self.PanelPrice.gameObject:SetActiveEx(validCost)
        if validCost then
            local cost = costList[1]
            self.RImgCoinIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(cost.Id))
            self.TxtPrice.text = "/" .. cost.Count
            local hasCount = XDataCenter.ItemManager.GetCount(cost.Id)
            self.TxtConsume.text = hasCount
            self.TxtConsume.color = hasCount >= cost.Count and self.CanBuyColor or self.NotBuyColor
        end
    end
end

function XUiRestaurantBuffChange:SetupStaffDynamic()
    local areaType = BuffTypeTab[self.BuffIndex]
    local benchIdList = self:GetAreaWorkBenchIdList(areaType)
    self.BenchIdList = benchIdList
    self.DynamicStaff:SetDataSource(benchIdList)
    self.DynamicStaff:ReloadDataSync()
end

function XUiRestaurantBuffChange:GetAreaWorkBenchIdList(areaType)
    if self.CacheBenchList and self.CacheBenchList[areaType] then
        return self.CacheBenchList[areaType]
    end
    local list = {}
    local count = self._Control:GetWorkbenchCountWithAreaType(XMVCA.XRestaurant.RestLevelRange.Max, areaType)
    for i = 1, count do
        table.insert(list, i)
    end
    self.CacheBenchList[areaType] = list
    
    return list
end

function XUiRestaurantBuffChange:OnStaffDynamicEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local areaType = BuffTypeTab[self.BuffIndex]
        grid:Refresh(self.BenchIdList[index], areaType, self.SelectBuffId[areaType])
    end
end

function XUiRestaurantBuffChange:SetupDetailDynamic()
    local areaType = BuffTypeTab[self.BuffIndex]
    local selectBuffId = self.SelectBuffId[areaType]
    local buff = self._Control:GetBuff(selectBuffId)
    
    local isAll = buff:IsAllApplicable()
    self.ProductIds = buff:GetEffectProductIds(areaType)
    self.CharacterIds = self._Control:GetBuffCharacterIds(selectBuffId)
    
    self.DynamicFood:SetDataSource(self.ProductIds)
    self.DynamicFood:ReloadDataSync()

    self.TxtALLStaff.gameObject:SetActiveEx(isAll)
    self.PanelStaffList.gameObject:SetActiveEx(not isAll)
    if not isAll then
        self:RefreshTemplateGrids(
                self.GridRole,
                self.CharacterIds,
                self.PanelStaffList,
                nil,
                "GridBuffDetail",
                function(grid, id)
                    grid.RImgRole:SetRawImage(XDormConfig.GetCharacterStyleConfigQSIconById(id))
                end)
    end
end

function XUiRestaurantBuffChange:OnFoodDynamicEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local areaType = BuffTypeTab[self.BuffIndex]
        local buffId = self.SelectBuffId[areaType]
        grid:Refresh(self.ProductIds[index], areaType, buffId)
    end
end

--region   ------------------初始化组件 start-------------------

function XUiRestaurantBuffChange:InitBuffTypeTab()
    local tab = {}

    for idx, areaType in ipairs(BuffTypeTab) do
        local btn = idx == 1 and self.BtnArea or XUiHelper.Instantiate(self.BtnArea, self.PanelTab.transform)
        btn.name = "BtnArea" .. areaType
        table.insert(tab, btn)
        btn:SetNameByGroup(0, self._Control:GetAreaTypeName(areaType))
    end
    
    self.PanelTab:Init(tab, function(tabIndex) self:OnSelectBuffType(tabIndex) end)
    self.BuffTypeTab = tab
end

function XUiRestaurantBuffChange:GetBuffTabIndex(areaType)
    for index, type in ipairs(BuffTypeTab) do
        if type == areaType then
            return index
        end
    end
    return 1
end

-- buff列表
function XUiRestaurantBuffChange:InitBuffDynamic()
    self.DynamicBuff = XDynamicTableNormal.New(self.PanelBuffList)
    self.DynamicBuff:SetProxy(XUiGridBuffButton, self)
    self.DynamicBuff:SetDelegate(self)
    self.DynamicBuff:SetDynamicEventDelegate(handler(self, self.OnBuffDynamicEvent))
    
    self.BtnBuff.gameObject:SetActiveEx(false)
    
    self.SelectBuffId = {}
end

-- 预览列表
function XUiRestaurantBuffChange:InitStaffDynamic()
    self.DynamicStaff = XDynamicTableNormal.New(self.PanelPreviewList)
    self.DynamicStaff:SetProxy(require("XUi/XUiRestaurant/XUiGrid/XUiGridBuffInfoRole"), self)
    self.DynamicStaff:SetDelegate(self)
    self.DynamicStaff:SetDynamicEventDelegate(handler(self, self.OnStaffDynamicEvent))
    
    self.GridPreview.gameObject:SetActiveEx(false)
end

-- 加成产品列表
function XUiRestaurantBuffChange:InitBuffFoodDynamic()
    self.DynamicFood = XDynamicTableNormal.New(self.PanelFoodList)
    self.DynamicFood:SetProxy(XUiGridBuffFood, self)
    self.DynamicFood:SetDelegate(self)
    self.DynamicFood:SetDynamicEventDelegate(handler(self, self.OnFoodDynamicEvent))
    
    self.GridItem.gameObject:SetActiveEx(false)
end

--endregion------------------初始化组件 finish------------------

function XUiRestaurantBuffChange:OnBtnUnlockClick()
    local areaType = BuffTypeTab[self.BuffIndex]
    local selectId = self.SelectBuffId[areaType]
    
    local buff = self._Control:GetBuff(selectId)
    if not buff:IsReachLevel() then
        XUiManager.TipMsg(self._Control:GetBuffUnlockLvTip(selectId))
        return
    end
    
    local costList = buff:GetUnlockCost()
    local enough = true
    for _, cost in ipairs(costList) do
        local id = cost.Id
        if cost.Count > XDataCenter.ItemManager.GetCount(id) then
            enough = false
            break
        end
    end

    if not enough then
        XUiManager.TipText("CommonCoinNotEnough")
        return
    end
    
    self.BtnUnlock.gameObject:SetActiveEx(false)
    self._Control:RequestUnlockBuff(selectId, function()
        XUiManager.TipMsg(self._Control:GetBuffUnlockedTip(selectId))
        self:SetupBuffDynamic()
    end)
end

function XUiRestaurantBuffChange:OnBtnUseClick()
    local areaType = BuffTypeTab[self.BuffIndex]
    local selectId = self.SelectBuffId[areaType]
    
    self._Control:RequestSwitchBuff(areaType, selectId, function()
        XUiManager.TipMsg(self._Control:GetBuffSwitchTip(areaType, selectId))
        self:SetupBuffDynamic()
    end)
end