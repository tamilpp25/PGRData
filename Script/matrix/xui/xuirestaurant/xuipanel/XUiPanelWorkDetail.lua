local XUiPanelWorkBase = require("XUi/XUiRestaurant/XUiPanel/XUiPanelWorkBase")
local XUiGridConsume = require("XUi/XUiRestaurant/XUiGrid/XUiGridConsume")

local ColorEnum = {
    Enable = XUiHelper.Hexcolor2Color("33415F"),
    Disable = XUiHelper.Hexcolor2Color("9F9A9A"),
    --策划不做差异化显示，功能先保留
    EnableBuff = XUiHelper.Hexcolor2Color("44841E"),
    DisableBuff = XUiHelper.Hexcolor2Color("44841E"),
    
    Up = "23712e",
    Down = "ff0000",
}

---@class XUiPanelWorkDetail : XUiPanelWorkBase
local XUiPanelWorkDetail = XClass(XUiPanelWorkBase, "XUiPanelWorkDetail")

function XUiPanelWorkDetail:InitUi()
    self.RefreshMap = {
        [XRestaurantConfigs.AreaType.IngredientArea] = handler(self, self.RefreshIngredient),
        [XRestaurantConfigs.AreaType.FoodArea] = handler(self, self.RefreshFood),
        [XRestaurantConfigs.AreaType.SaleArea] = handler(self, self.RefreshSale),
    }
    self.GridNeeds = {}
    self.GridSkills = {}
    self.GridAddition.gameObject:SetActiveEx(false)
end

function XUiPanelWorkDetail:InitCb()
    self.BtnChange.CallBack = function()
        self:OnBtnChangeClick()
    end

    self.BtnHead.CallBack = function()
        self:OnBtnHeadClick()
    end

    self.BtnConfirm.CallBack = function()
        self:OnBtnConfirmClick()
    end

    self.BtnStatistics.CallBack = function()
        self:OnBtnStatisticsClick()
    end

    self.BtnSuspend.CallBack = function()
        self:OnBtnSuspendClick()
    end

    self.BtnExpedite.CallBack = function()
        self:OnBtnExpediteClick()
    end
end

function XUiPanelWorkDetail:RefreshView()
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    local benchModel = viewModel:GetWorkBenchViewModel(self.AreaType, self.Index)
    local productId = benchModel:GetProperty("_ProductId")

    -- Product
    local product = benchModel:GetProduct()
    self.RImgIcon:SetRawImage(product:GetProductIcon())
    local storageDesc = XRestaurantConfigs.GetClientConfig("StorageCountDesc", 2)
    local count, limit = product:GetProperty("_Count"), product:GetProperty("_Limit")
    self.TxTinventoryNumber.text = string.format(storageDesc, count, limit)
    self.ImgProgress.fillAmount = math.min(XUiHelper.GetFillAmountValue(count, limit), 1)
    self.TxtProductName.text = product:GetProperty("_Name")
    
    -- Character
    local character = benchModel:GetCharacter()
    self.TxtName.text = character:GetName()
    self.BtnHead:SetRawImage(character:GetIcon())
    self.TxtModel.gameObject:SetActiveEx(false)
    self.TxtGradeSu.text = character:GetLevelStr()

    self:RefreshAddition(benchModel)
    
    self:RefreshSkill(character, benchModel, productId)
    self:RefreshButton(benchModel)
    self:RefreshState(benchModel, limit, count)
end

function XUiPanelWorkDetail:RefreshAddition(benchModel)
    self.PanelProductionRate.gameObject:SetActiveEx(false)
    self.PanelConsumeSpeed.gameObject:SetActiveEx(false)
    self.PanelSell.gameObject:SetActiveEx(false)
    local refresh = self.RefreshMap[self.AreaType]
    if refresh then
        refresh(benchModel)
    end
end

--- 刷新备菜区
---@param benchModel XRestaurantWorkBench
--------------------------
function XUiPanelWorkDetail:RefreshIngredient(benchModel)
    self.PanelProductionRate.gameObject:SetActiveEx(true)
    local addition = benchModel:GetAddition()
    local baseCount, add, unit = XRestaurantConfigs.GetAddCountAndUnit(benchModel:GetBaseProduceSpeed(), addition, XRestaurantConfigs.AreaType.IngredientArea)
    self.TxtReteSu.text = baseCount
    local showAddition = addition ~= 0
    self.TxtRateSuAdd.gameObject:SetActiveEx(showAddition)
    if showAddition then
        self.TxtRateSuAdd.color = benchModel:CheckHasBuff() and ColorEnum.EnableBuff or ColorEnum.DisableBuff
        self.TxtRateSuAdd.text = string.format("%s%s", unit, add)
    end
end

--- 刷新烹饪区
---@param benchModel XRestaurantWorkBench
--------------------------
function XUiPanelWorkDetail:RefreshFood(benchModel)
    self.PanelConsumeSpeed.gameObject:SetActiveEx(true)
    local addition = benchModel:GetAddition()
    local baseCount, add, unit = XRestaurantConfigs.GetAddCountAndUnit(benchModel:GetBaseProduceSpeed(), addition, XRestaurantConfigs.AreaType.FoodArea)
    self.TxtSpeedSu.text = baseCount
    local showAddition = addition ~= 0
    self.TxtSpeedSuAdd.gameObject:SetActiveEx(showAddition)
    if showAddition then
        self.TxtSpeedSuAdd.color = benchModel:CheckHasBuff() and ColorEnum.EnableBuff or ColorEnum.DisableBuff
        self.TxtSpeedSuAdd.text = string.format("%s%s", unit, add)
    end
    for _, grid in pairs(self.GridNeeds) do
        if grid and not XTool.UObjIsNil(grid.GameObject) then
            grid.GameObject:SetActiveEx(false)
        end
    end
    local areaType = XRestaurantConfigs.AreaType.IngredientArea
    local product = benchModel:GetProduct()
    local consumeList = product:GetProperty("_Ingredients") or {}
    for idx, consume in pairs(consumeList or {}) do
        local grid = self.GridNeeds[idx]
        if not grid then
            local ui = idx == 1 and self.GridNeed or XUiHelper.Instantiate(self.GridNeed, self.PanelNeed)
            grid = XUiGridConsume.New(ui)
            self.GridNeeds[idx] = grid
        end
        grid:Refresh(areaType, consume:GetId(), consume:GetCount())
    end
end

--- 刷新售卖区
---@param benchModel XRestaurantWorkBench
--------------------------
function XUiPanelWorkDetail:RefreshSale(benchModel)
    self.PanelSell.gameObject:SetActiveEx(true)
    local product = benchModel:GetProduct()
    local price = product:GetFinalPrice()
    local addition = benchModel:GetAddition()
    local _, add, unit = XRestaurantConfigs.GetAddCountAndUnit(price, addition, XRestaurantConfigs.AreaType.SaleArea)
    self.TxtSellSpeedSu.text = XRestaurantConfigs.GetAroundValue(XRestaurantConfigs.TimeUnit.Hour / benchModel:GetBaseProduceSpeed(), XRestaurantConfigs.Digital.One)
    local showAddition = addition ~= 0
    self.TxtSellSpeedSuAdd.gameObject:SetActiveEx(false)
    self.TxtSellPriceSuAdd.gameObject:SetActiveEx(showAddition)
    if showAddition then
        self.TxtSellPriceSuAdd.color = benchModel:CheckHasBuff() and ColorEnum.EnableBuff or ColorEnum.DisableBuff
        self.TxtSellPriceSuAdd.text = string.format("%s%s", unit, add)
    end
    self.TxtSellPriceSu.text = price
    self.TxtPriceHour.text = string.format("%s%s", XItemConfigs.GetItemNameById(XRestaurantConfigs.ItemId.RestaurantUpgradeCoin), XRestaurantConfigs.GetSkillAdditionUnit(self.AreaType))
end

function XUiPanelWorkDetail:RefreshSkill(character, benchModel, targetProductId)
    for _, grid in pairs(self.GridSkills) do
        if grid and not XTool.UObjIsNil(grid.GameObject) then
            grid.GameObject:SetActiveEx(false)
        end
    end
    local index = 1
    --local isAddition = character:IsAddition(self.AreaType, targetProductId)
    --if not isAddition then
    --    local grid = self:GetGridSkillAddition(index)
    --    local desc = string.format(XRestaurantConfigs.GetSkillNoAdditionDesc(), "", benchModel:GetProductName())
    --    grid.TxtSkill.text = desc
    --    return
    --end
    
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    local product = viewModel:GetProduct(self.AreaType, targetProductId)
    local baseSpeed = XRestaurantConfigs.CheckIsSaleArea(self.AreaType) and product:GetProperty("_SellPrice")
            or product:GetProperty("_Speed")
    local timeUnit = XRestaurantConfigs.GetSkillAdditionUnit(self.AreaType)

    local totalAddition = benchModel:GetAddition()
    if totalAddition == 0 then
        totalAddition = 1
    end
    local _, totalAdd, unit = XRestaurantConfigs.GetAddCountAndUnit(baseSpeed, totalAddition, self.AreaType)
    
    local skillIds = character:GetProperty("_SkillIds")
    for _, skillId in pairs(skillIds or {}) do
        local areaType = XRestaurantConfigs.GetCharacterSkillAreaType(skillId)
        if areaType ~= self.AreaType then
            goto ContinueOutSide
        end
        local additionMap = XRestaurantConfigs.GetCharacterSkillAddition(skillId)
        --local skillDesc = XRestaurantConfigs.GetSkillAdditionDesc(areaType)
        
        for productId, addition in pairs(additionMap) do
            if productId ~= targetProductId then
                goto ContinueInSide
            end
            local grid = self:GetGridSkillAddition(index)
            
            --local _, add, unit = XRestaurantConfigs.GetAddCountAndUnit(baseSpeed, addition, areaType)
            local add = self:CalAddition(addition, totalAddition, totalAdd)
            --local desc = string.format("%s%s%s%s", product:GetProperty("_Name"), skillDesc, unit .. add, timeUnit)
            local colorStr = add > 0 and ColorEnum.Up or ColorEnum.Down
            local desc = string.format("<color=#%s>%s</color>%s", colorStr, unit .. add, timeUnit)
            
            grid.Refresh(skillId, desc, false)
            index = index + 1
            
            ::ContinueInSide::
        end
        ::ContinueOutSide::
    end
    
    local buff = viewModel:GetAreaBuff(self.AreaType)
    local buffAddition = benchModel:GetBuffAddition()
    if buffAddition > 0 then
        local grid = self:GetGridSkillAddition(index)
        local add = self:CalAddition(buffAddition, totalAddition, totalAdd)
        local colorStr = add > 0 and ColorEnum.Up or ColorEnum.Down
        local desc = string.format("<color=#%s>%s</color>%s", colorStr, unit .. add, timeUnit)
        grid.Refresh(buff:GetProperty("_Id"), desc, true)
    end
end

function XUiPanelWorkDetail:CalAddition(addition, totalAddition, totalRatio)
    local value = addition / totalAddition * totalRatio
    return XRestaurantConfigs.GetAroundValue(value, XRestaurantConfigs.Digital.One)
end

function XUiPanelWorkDetail:GetGridSkillAddition(index)
    local grid = self.GridSkills[index]
    if not grid then
        local ui = index == 1 and self.GridAddition or XUiHelper.Instantiate(self.GridAddition, self.ContentAddition)
        grid = {}
        XTool.InitUiObjectByUi(grid, ui)
        grid.Refresh = function(id, desc, isBuff)
            if isBuff then
                grid.TxtName.text = XRestaurantConfigs.GetBuffName(id)
                grid.TxtAddition.text = desc
                grid.ImgIcon:SetSprite(XRestaurantConfigs.GetBuffAdditionIcon())
            else
                grid.TxtName.text = XRestaurantConfigs.GetCharacterSkillName(id)
                grid.TxtAddition.text = desc
                grid.ImgIcon:SetSprite(XRestaurantConfigs.GetSkillAdditionIcon())
            end
        end
        self.GridSkills[index] = grid
    end
    grid.GameObject:SetActiveEx(true)
    grid.GameObject.name = "GridAddition"..index
    return grid
end

function XUiPanelWorkDetail:RefreshButton(benchModel)
    if not benchModel then
        return
    end
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    local isRunning = benchModel:IsRunning()
    self.BtnConfirm.gameObject:SetActiveEx(not isRunning)
    self.PanelBtnExpedite.gameObject:SetActiveEx(isRunning)
    
    self.BtnHead:SetDisable(isRunning, not isRunning)
    self.BtnChange:SetDisable(isRunning, not isRunning)
    
    if isRunning then
        self.TxtNeed.text = viewModel:GetAccelerateCount()
        local disable = not benchModel:CheckCanAccelerate()
        self.BtnExpedite:SetDisable(disable, not disable)
        self.BtnExpedite:SetNameByGroup(0, string.format("%s/%s%s",
                viewModel:GetProperty("_AccelerateUseTimes"),
                viewModel:GetAccelerateUseLimit(), XUiHelper.GetText("TowerTimes")))
        self.RAccelerateIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XRestaurantConfigs.ItemId.RestaurantAccelerate))
    end
end

---@param benchModel XRestaurantWorkBench
function XUiPanelWorkDetail:RefreshState(benchModel, limit, count)
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    local isPause = benchModel:IsPause()
    --local isIngredient = XRestaurantConfigs.CheckIsIngredientArea(self.AreaType)
    local isIngredient = false
    self.TxtPredictNo.gameObject:SetActiveEx(isPause)
    self.TxtPredict.gameObject:SetActiveEx(not isPause and isIngredient)
    self.TxtPredictRed.gameObject:SetActiveEx(not isPause and isIngredient)
    if isPause then
        local index
        if benchModel:IsFull() then
            index = XRestaurantConfigs.CheckIsSaleArea(self.AreaType) and 3 or 4
        elseif benchModel:IsInsufficient() then
            index = XRestaurantConfigs.CheckIsSaleArea(self.AreaType) and 2 or 1
        end
        self.TxtPredictNo.text = XRestaurantConfigs.GetWorkPauseReason(index)
    elseif isIngredient then
        local productId = benchModel:GetProperty("_ProductId")
        local increase, tip = viewModel:GetWorkBenchPreviewTip(self.AreaType, productId)
        self.TxtPredict.gameObject:SetActiveEx(increase)
        self.TxtPredictRed.gameObject:SetActiveEx(not increase)
        local textComponent = increase and self.TxtPredict or self.TxtPredictRed
        textComponent.text = tip
    end
end

--切换菜肴
function XUiPanelWorkDetail:OnBtnChangeClick()
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    local benchModel = viewModel:GetWorkBenchViewModel(self.AreaType, self.Index)
    if benchModel:IsRunning() then
        return
    end
    benchModel:DelProduct()
end

--切换角色
function XUiPanelWorkDetail:OnBtnHeadClick()
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    local benchModel = viewModel:GetWorkBenchViewModel(self.AreaType, self.Index)
    if benchModel:IsRunning() then
        return
    end
    benchModel:DelStaff()
end

--安排工作
function XUiPanelWorkDetail:OnBtnConfirmClick()
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    local benchModel = viewModel:GetWorkBenchViewModel(self.AreaType, self.Index)
    local productId = benchModel:GetProperty("_ProductId")

    local request = function()
        XDataCenter.RestaurantManager.RequestAssignWork(self.AreaType, benchModel:GetProperty("_CharacterId"),
                self.Index, productId, function()
                    benchModel:TryWorking()
                    self:RefreshButton(benchModel)
                    local desc = XRestaurantConfigs.GetClientConfig("ProduceDesc", self.AreaType)
                    desc = string.format(desc, benchModel:GetStaffName(), benchModel:GetProductName())
                    XEventManager.DispatchEvent(XEventId.EVENT_RESTAURANT_SHOW_ASSIGN_WORK, desc)
                end)
    end
    
    if benchModel:IsFull() then
        local title, content = benchModel:GetFullTitleAndContent()
        XDataCenter.RestaurantManager.OpenPopup(title, content, nil, nil, request)
        return
    elseif benchModel:IsInsufficient() then
        local title, content = benchModel:GetInsufficientTitleAndContent()
        XDataCenter.RestaurantManager.OpenPopup(title, content, nil, nil, request)
        return
    end
    request()
end

--统计
function XUiPanelWorkDetail:OnBtnStatisticsClick()
    local areaType = XRestaurantConfigs.AreaType.IngredientArea == self.AreaType
            and XRestaurantConfigs.AreaType.IngredientArea or XRestaurantConfigs.AreaType.FoodArea
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    local benchModel = viewModel:GetWorkBenchViewModel(self.AreaType, self.Index)
    XRestaurantConfigs.Burying(XRestaurantConfigs.BuryingButton.BtnStatistics, "UiRestaurantWork")
    XDataCenter.RestaurantManager.OpenStatistics(areaType, benchModel:GetProperty("_ProductId"))
end

--终止工作
function XUiPanelWorkDetail:OnBtnSuspendClick()
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    local benchModel = viewModel:GetWorkBenchViewModel(self.AreaType, self.Index)

    --local request = function()
    --    XDataCenter.RestaurantManager.RequestAssignWork(self.AreaType, 0, self.Index, 0, function()
    --        benchModel:Stop()
    --        self:RefreshButton(benchModel)
    --    end)
    --end
    
    --XDataCenter.RestaurantManager.OpenPopup(title, content, nil, nil, request)

    XDataCenter.RestaurantManager.RequestAssignWork(self.AreaType, 0, self.Index, 0, function() 
        local _, content = benchModel:GetStopTipTitleAndContent()
        XUiManager.TipMsg(content)
        benchModel:Stop()
        self:RefreshButton(benchModel)
    end)
end

--加速
function XUiPanelWorkDetail:OnBtnExpediteClick()
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    local count = viewModel:GetAccelerateCount()
    if count <= 0 then
        return
    end
    if viewModel:IsAccelerateUpperLimit() then
        return
    end

    local benchModel = viewModel:GetWorkBenchViewModel(self.AreaType, self.Index)
    if not benchModel:IsRunning() then
        return
    end
    
    local request = function()
        XDataCenter.RestaurantManager.RequestAccelerate(self.AreaType, self.Index, 1, function()
            self:RefreshView()
        end)
    end
    local title = XRestaurantConfigs.GetClientConfig("AccelerateTip", 1)
    local time = viewModel:GetAccelerateTime()
    local content, itemData = benchModel:GetAccelerateContentAndItemData(time)
    XDataCenter.RestaurantManager.OpenPopup(title, content, itemData, nil, request)
end

return XUiPanelWorkDetail