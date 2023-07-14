local XUiGridBuffButton = XClass(nil, "XUiGridBuffButton")

local ColorEnum = {
    Up = XUiHelper.Hexcolor2Color("356C38"),
    Down = XUiHelper.Hexcolor2Color("CE453B")
}

function XUiGridBuffButton:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
    --self.BtnClick.CallBack = function() 
    --    self:OnBtnClick()
    --end
end

function XUiGridBuffButton:Refresh(buffId, selectId)
    self.BuffId = buffId
    self:RefreshState(selectId)
end

function XUiGridBuffButton:RefreshState(selectId)
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    local buff = viewModel:GetBuff(self.BuffId)
    local select = self.BuffId == selectId
    --local unlock = buff:GetProperty("_Unlock")
    local unlock = buff:IsReachLevel()
    
    local areaType = XRestaurantConfigs.GetBuffAreaType(self.BuffId)
    local areaBuffId = viewModel:GetAreaBuffId(areaType)
    local isCur = areaBuffId and areaBuffId == self.BuffId or false
    self.BtnClick:ShowTag(isCur)
    if unlock then
        self.BtnClick:SetNameByGroup(0, XRestaurantConfigs.GetBuffName(self.BuffId))
    else
        local desc = string.format(XRestaurantConfigs.GetCommonUnlockText(4), XRestaurantConfigs.GetBuffUnlockLv(self.BuffId))
        self.BtnClick:SetNameByGroup(0, desc)
    end
    
    self.PanelNormal.gameObject:SetActiveEx(unlock and not select)
    self.PanelSelect.gameObject:SetActiveEx(unlock and select)
    self.PanelLock.gameObject:SetActiveEx(not unlock and not select)
    self.PanelLockSelect.gameObject:SetActiveEx(not unlock and select)
    
    self.BtnClick:ShowReddot(XDataCenter.RestaurantManager.CheckBuffRedPoint(areaType, self.BuffId))
end

function XUiGridBuffButton:Equal(selectId)
    return self.BuffId == selectId
end

function XUiGridBuffButton:MarkRedPoint()
    self.BtnClick:ShowReddot(false)
    XDataCenter.RestaurantManager.MarkBuffRedPoint(self.BuffId)
end

local XUiGridBuffFood = XClass(nil, "XUiGridBuffFood")

function XUiGridBuffFood:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
end

function XUiGridBuffFood:Refresh(productId, areaType, buffId)
    local product = XDataCenter.RestaurantManager.GetViewModel():GetProduct(areaType, productId)
    self.TxtName.text = product:GetProperty("_Name")
    self.RImgIcon:SetRawImage(product:GetProductIcon())
    local buff = XDataCenter.RestaurantManager.GetViewModel():GetBuff(buffId)
    local addition = buff:GetProductEffectAddition(areaType, productId)
    self.TxtAddition.text = XRestaurantConfigs.GetCharacterSkillPercentAddition(addition, areaType, productId)
    self.TxtAddition.color = addition > 0 and ColorEnum.Up or ColorEnum.Down
end


---@class XUiRestaurantBuffChange : XLuaUi
---@field PanelTab XUiButtonGroup
local XUiRestaurantBuffChange = XLuaUiManager.Register(XLuaUi, "UiRestaurantBuffChange")
--
--local XUiGridBuffInfoDetail = require("XUi/XUiRestaurant/XUiGrid/XUiGridBuffInfoDetail")

local BuffTypeTab = {
    XRestaurantConfigs.AreaType.IngredientArea,
    XRestaurantConfigs.AreaType.FoodArea,
    XRestaurantConfigs.AreaType.SaleArea,
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
    local areaType = XRestaurantConfigs.GetBuffAreaType(self.BuffId)
    self.SelectBuffId[areaType] = self.BuffId
    self.PanelTab:SelectIndex(self:GetBuffTabIndex(areaType))
end

function XUiRestaurantBuffChange:OnSelectBuffType(tabIndex)
    if self.BuffIndex == tabIndex then
        return
    end
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    local areaType = BuffTypeTab[tabIndex]
    local unlock = viewModel:CheckAreaBuffUnlock(areaType)
    if not unlock then
        XUiManager.TipMsg(XRestaurantConfigs.GetBuffAreaUnlockTip(areaType))
        return
    end
    
    self.BuffIndex = tabIndex
    self.LastBuffBtn = nil
    self:SetupBuffDynamic()
end

function XUiRestaurantBuffChange:RefreshBuffTypeTab()
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    for index, btn in ipairs(self.BuffTypeTab) do
        local unlock = viewModel:CheckAreaBuffUnlock(BuffTypeTab[index])
        btn:SetDisable(not unlock)
    end
end

function XUiRestaurantBuffChange:SetupBuffDynamic()
    local areaType = BuffTypeTab[self.BuffIndex]
    local list = XRestaurantConfigs.GetBuffIdList(areaType)
    self.BuffIdList = self:GetSortBuffIds(list)
    self.DynamicBuff:SetDataSource(self.BuffIdList)
    self.DynamicBuff:ReloadDataSync()
end

function XUiRestaurantBuffChange:GetSortBuffIds(buffIds)
    local areaType = BuffTypeTab[self.BuffIndex]
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    local areaBuffId = viewModel:GetAreaBuffId(areaType)
    
    table.sort(buffIds, function(a, b) 
        local isCurA = a == areaBuffId
        local isCurB = b == areaBuffId
        if isCurA ~= isCurB then
            return isCurA
        end
        local buffA = viewModel:GetBuff(a)
        local buffB = viewModel:GetBuff(b)
        
        local isUnlockA = buffA:GetProperty("_Unlock")
        local isUnlockB = buffB:GetProperty("_Unlock")

        if isUnlockA ~= isUnlockB then
            return isUnlockA
        end
        
        --local isRedPointA = XDataCenter.RestaurantManager.CheckBuffRedPoint(areaType, a)
        --local isRedPointB = XDataCenter.RestaurantManager.CheckBuffRedPoint(areaType, b)
        --
        --if isRedPointA ~= isRedPointB then
        --    return isRedPointA
        --end
        
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
        self:OnSelectBuffBtn(index, self.DynamicBuff:GetGridByIndex(index))
    end
end

function XUiRestaurantBuffChange:OnSelectBuffBtn(index, grid)
    local selectId = self.BuffIdList[index]
    local buff = XDataCenter.RestaurantManager.GetViewModel():GetBuff(selectId)
    if not buff:IsReachLevel() then
        XUiManager.TipMsg(string.format(XRestaurantConfigs.GetCommonUnlockText(2), XRestaurantConfigs.GetBuffUnlockLv(selectId)))
        return
    end
    --选中了同一个
    if self.LastBuffBtn and self.LastBuffBtn:Equal(selectId) then
        return
    end
    if self.LastBuffBtn then
        self.LastBuffBtn:RefreshState(selectId)
    end
    grid:RefreshState(selectId)
    grid:MarkRedPoint()
    self.SelectBuffId[BuffTypeTab[self.BuffIndex]] = selectId
    self.LastBuffBtn = grid
    
    self:RefreshRight()
    
end

function XUiRestaurantBuffChange:RefreshRight()
    self:SetupStaffDynamic()
    self:SetupDetailDynamic()
    
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    local areaType = BuffTypeTab[self.BuffIndex]
    local useBuffId = viewModel:GetAreaBuffId(areaType)
    local selectId = self.SelectBuffId[areaType]
    
    local isUse = useBuffId == selectId
    local buff = viewModel:GetBuff(selectId)
    local unlock = buff:GetProperty("_Unlock")
    
    self.BtnUse.gameObject:SetActiveEx(not isUse and unlock)
    self.BtnUnlock.gameObject:SetActiveEx(not isUse and not unlock)
    self.PanelInUse.gameObject:SetActiveEx(isUse and unlock)
    
    self.TxtBuffName.text = buff:GetProperty("_Name")
    self.TxtBuffDesc.text = buff:GetProperty("_Desc")
    self.TxtAddDesc.text = XRestaurantConfigs.GetBuffAdditionText(areaType)

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
    --local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    --
    ----local staffList = viewModel:GetWorkingStaff(areaType)
    --
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
    local count = XRestaurantConfigs.GetCounterNumByAreaType(areaType, XRestaurantConfigs.LevelRange.Max)
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
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    local buff = viewModel:GetBuff(selectBuffId)
    
    self.DetailList = 1
    local isAll = buff:IsAllStaff()
    self.ProductIds = buff:GetEffectProductIds(areaType)
    self.CharacterIds = XRestaurantConfigs.GetBuffCharacterIds(selectBuffId)
    
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

function XUiRestaurantBuffChange:OnDetailDynamicEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local areaType = BuffTypeTab[self.BuffIndex]
        local buffId = self.SelectBuffId[areaType]
        grid:Refresh(areaType, self.DetailList[index], buffId, self.IsAllStaff)
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
        btn:SetNameByGroup(0, XRestaurantConfigs.GetCameraAuxiliaryAreaName(areaType))
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
    self.DynamicBuff:SetProxy(XUiGridBuffButton)
    self.DynamicBuff:SetDelegate(self)
    self.DynamicBuff:SetDynamicEventDelegate(handler(self, self.OnBuffDynamicEvent))
    
    self.BtnBuff.gameObject:SetActiveEx(false)
    
    self.SelectBuffId = {}
end

-- 预览列表
function XUiRestaurantBuffChange:InitStaffDynamic()
    self.DynamicStaff = XDynamicTableNormal.New(self.PanelPreviewList)
    self.DynamicStaff:SetProxy(require("XUi/XUiRestaurant/XUiGrid/XUiGridBuffInfoRole"))
    self.DynamicStaff:SetDelegate(self)
    self.DynamicStaff:SetDynamicEventDelegate(handler(self, self.OnStaffDynamicEvent))
    
    self.GridPreview.gameObject:SetActiveEx(false)
end

-- 加成产品列表
function XUiRestaurantBuffChange:InitBuffFoodDynamic()
    self.DynamicFood = XDynamicTableNormal.New(self.PanelFoodList)
    self.DynamicFood:SetProxy(XUiGridBuffFood)
    self.DynamicFood:SetDelegate(self)
    self.DynamicFood:SetDynamicEventDelegate(handler(self, self.OnFoodDynamicEvent))
    
    self.GridItem.gameObject:SetActiveEx(false)
end

--endregion------------------初始化组件 finish------------------

function XUiRestaurantBuffChange:OnBtnUnlockClick()
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    local areaType = BuffTypeTab[self.BuffIndex]
    local selectId = self.SelectBuffId[areaType]
    
    local buff = viewModel:GetBuff(selectId)
    if not buff:IsReachLevel() then
        XUiManager.TipMsg(XRestaurantConfigs.GetBuffUnlockLvTip(selectId))
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
    XDataCenter.RestaurantManager.RequestUnlockBuff(selectId, function()
        XUiManager.TipMsg(XRestaurantConfigs.GetBuffUnlockedTip(selectId))
        self:SetupBuffDynamic()
    end)
end

function XUiRestaurantBuffChange:OnBtnUseClick()
    local areaType = BuffTypeTab[self.BuffIndex]
    local selectId = self.SelectBuffId[areaType]
    
    XDataCenter.RestaurantManager.RequestSwitchBuff(areaType, selectId, function()
        XUiManager.TipMsg(XRestaurantConfigs.GetBuffSwitchTip(areaType, selectId))
        self:SetupBuffDynamic()
    end)
end