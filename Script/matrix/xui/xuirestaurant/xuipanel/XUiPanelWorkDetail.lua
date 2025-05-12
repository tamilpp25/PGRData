local XUiPanelWorkBase = require("XUi/XUiRestaurant/XUiPanel/XUiPanelWorkBase")
local XUiGridConsume = require("XUi/XUiRestaurant/XUiGrid/XUiGridConsume")
local XUiPanelWorkBuff = require("XUi/XUiRestaurant/XUiPanel/XUiPanelWorkBuff")

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
---@field Parent XUiRestaurantWork
local XUiPanelWorkDetail = XClass(XUiPanelWorkBase, "XUiPanelWorkDetail")

function XUiPanelWorkDetail:InitUi()
    self.RefreshMap = {
        [XMVCA.XRestaurant.AreaType.IngredientArea] = handler(self, self.RefreshIngredient),
        [XMVCA.XRestaurant.AreaType.FoodArea] = handler(self, self.RefreshFood),
        [XMVCA.XRestaurant.AreaType.SaleArea] = handler(self, self.RefreshSale),
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
    local benchModel = self._Control:GetWorkbench(self.AreaType, self.Index)
    local productId = benchModel:GetProductId()

    -- Product
    local product = benchModel:GetProduct()
    self.RImgIcon:SetRawImage(product:GetProductIcon())
    local count, limit = product:GetCount(), product:GetLimit()
    self.TxTinventoryNumber.text = product:GetCountDesc(2, true)
    self.ImgProgress.fillAmount = math.min(XUiHelper.GetFillAmountValue(count, limit), 1)
    self.TxtProductName.text = product:GetName()
    
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
    self:RefreshBuff()
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
---@param benchModel XBenchViewModel
--------------------------
function XUiPanelWorkDetail:RefreshIngredient(benchModel)
    self.PanelProductionRate.gameObject:SetActiveEx(true)
    local addition = benchModel:GetAddition()
    local baseCount, add, unit = self._Control:GetAddCountAndUnit(benchModel:GetBaseProduceSpeed(), addition,
            XMVCA.XRestaurant.AreaType.IngredientArea)
    self.TxtReteSu.text = baseCount
    local showAddition = addition ~= 0
    self.TxtRateSuAdd.gameObject:SetActiveEx(showAddition)
    if showAddition then
        self.TxtRateSuAdd.color = benchModel:CheckHasBuff() and ColorEnum.EnableBuff or ColorEnum.DisableBuff
        self.TxtRateSuAdd.text = string.format("%s%s", unit, add)
    end
end

--- 刷新烹饪区
---@param benchModel XBenchViewModel
--------------------------
function XUiPanelWorkDetail:RefreshFood(benchModel)
    self.PanelConsumeSpeed.gameObject:SetActiveEx(true)
    local addition = benchModel:GetAddition()
    local baseCount, add, unit = self._Control:GetAddCountAndUnit(benchModel:GetBaseProduceSpeed(), addition, 
            XMVCA.XRestaurant.AreaType.FoodArea)
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
    local areaType = XMVCA.XRestaurant.AreaType.IngredientArea
    ---@type XRestaurantFoodVM
    local product = benchModel:GetProduct()
    local consumeList = product:GetIngredients()
    for idx, consume in pairs(consumeList) do
        local grid = self.GridNeeds[idx]
        if not grid then
            local ui = idx == 1 and self.GridNeed or XUiHelper.Instantiate(self.GridNeed, self.PanelNeed)
            grid = XUiGridConsume.New(ui, self.Parent)
            self.GridNeeds[idx] = grid
        end
        grid:Refresh(areaType, consume.Id, consume.Count)
    end
end

--- 刷新售卖区
---@param benchModel XBenchViewModel
--------------------------
function XUiPanelWorkDetail:RefreshSale(benchModel)
    self.PanelSell.gameObject:SetActiveEx(true)
    local product = benchModel:GetProduct()
    local price = product:GetSellPrice()
    local addition = benchModel:GetAddition()
    local _, add, unit = self._Control:GetAddCountAndUnit(price, addition, XMVCA.XRestaurant.AreaType.SaleArea)
    self.TxtSellSpeedSu.text = self._Control:GetAroundValue(XMVCA.XRestaurant.TimeUnit.Hour / 
            benchModel:GetBaseProduceSpeed(), XMVCA.XRestaurant.Digital.One)
    local showAddition = addition ~= 0
    self.TxtSellSpeedSuAdd.gameObject:SetActiveEx(false)
    self.TxtSellPriceSuAdd.gameObject:SetActiveEx(showAddition)
    if showAddition then
        self.TxtSellPriceSuAdd.color = benchModel:CheckHasBuff() and ColorEnum.EnableBuff or ColorEnum.DisableBuff
        self.TxtSellPriceSuAdd.text = string.format("%s%s", unit, add)
    end
    self.TxtSellPriceSu.text = price
    self.TxtPriceHour.text = string.format("%s%s", XItemConfigs.GetItemNameById(XMVCA.XRestaurant.ItemId
            .RestaurantUpgradeCoin), self._Control:GetSkillAdditionUnit(self.AreaType))
end

--- 刷新技能
---@param character XRestaurantStaffVM
---@param benchModel XBenchViewModel
---@param targetProductId number
--------------------------
function XUiPanelWorkDetail:RefreshSkill(character, benchModel, targetProductId)
    for _, grid in pairs(self.GridSkills) do
        if grid and not XTool.UObjIsNil(grid.GameObject) then
            grid.GameObject:SetActiveEx(false)
        end
    end
    local index = 1
    local product = self._Control:GetProduct(self.AreaType, targetProductId)
    local baseSpeed = self._Control:IsSaleArea(self.AreaType) and product:GetSellPrice() or product:GetSpeed()
    local timeUnit = self._Control:GetSkillAdditionUnit(self.AreaType)

    local totalAddition = benchModel:GetAddition()
    if totalAddition == 0 then
        totalAddition = 1
    end
    local _, totalAdd, unit = self._Control:GetAddCountAndUnit(baseSpeed, totalAddition, self.AreaType)
    
    local skillIds = character:GetSkillIds()
    for _, skillId in pairs(skillIds) do
        local areaType = character:GetCharacterSkillAreaType(skillId)
        if areaType ~= self.AreaType then
            goto ContinueOutSide
        end
        local additionMap = character:GetCharacterSkillAddition(skillId)
        for productId, addition in pairs(additionMap) do
            if productId ~= targetProductId then
                goto ContinueInSide
            end
            local grid = self:GetGridSkillAddition(index)
            
            local add = self:CalAddition(addition, totalAddition, totalAdd)
            local colorStr = add > 0 and ColorEnum.Up or ColorEnum.Down
            local desc = string.format("<color=#%s>%s</color>%s", colorStr, unit .. add, timeUnit)
            
            grid.Refresh(skillId, desc, false)
            index = index + 1
            
            ::ContinueInSide::
        end
        ::ContinueOutSide::
    end
    
    local buff = self._Control:GetAreaBuff(self.AreaType)
    local buffAddition = benchModel:GetBuffAddition()
    if buffAddition > 0 then
        local grid = self:GetGridSkillAddition(index)
        local add = self:CalAddition(buffAddition, totalAddition, totalAdd)
        local colorStr = add > 0 and ColorEnum.Up or ColorEnum.Down
        local desc = string.format("<color=#%s>%s</color>%s", colorStr, unit .. add, timeUnit)
        grid.Refresh(buff:GetBuffId(), desc, true)
    end
end

function XUiPanelWorkDetail:CalAddition(addition, totalAddition, totalRatio)
    local value = addition / totalAddition * totalRatio
    return self._Control:GetAroundValue(value, XMVCA.XRestaurant.Digital.One)
end

function XUiPanelWorkDetail:GetGridSkillAddition(index)
    local grid = self.GridSkills[index]
    if not grid then
        local ui = index == 1 and self.GridAddition or XUiHelper.Instantiate(self.GridAddition, self.ContentAddition)
        grid = {}
        XTool.InitUiObjectByUi(grid, ui)
        grid.Refresh = function(id, desc, isBuff)
            if isBuff then
                local buff = self._Control:GetBuff(id)
                grid.TxtName.text = buff:GetName()
                grid.TxtAddition.text = desc
                grid.ImgIcon:SetSprite(self._Control:GetAdditionIcon(true))
            else
                grid.TxtName.text = self._Control:GetCharacterSkillName(id)
                grid.TxtAddition.text = desc
                grid.ImgIcon:SetSprite(self._Control:GetAdditionIcon(false))
            end
        end
        self.GridSkills[index] = grid
    end
    grid.GameObject:SetActiveEx(true)
    grid.GameObject.name = "GridAddition"..index
    return grid
end

---@param benchModel XBenchViewModel
function XUiPanelWorkDetail:RefreshButton(benchModel)
    if not benchModel then
        return
    end
    local isRunning = benchModel:IsRunning()
    self.BtnConfirm.gameObject:SetActiveEx(not isRunning)
    self.PanelBtnExpedite.gameObject:SetActiveEx(isRunning)
    

    if isRunning then
        local business = self._Control:GetBusiness()
        self.TxtNeed.text = business:GetAccelerateCount()
        local disable = not benchModel:CheckCanAccelerate()
        self.BtnExpedite:SetDisable(disable, not disable)
        self.BtnExpedite:SetNameByGroup(0, string.format("%s/%s%s",
                business:GetAccelerateUseTimes(),
                business:GetAccelerateUseLimit(), XUiHelper.GetText("TowerTimes")))
        self.RAccelerateIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XMVCA.XRestaurant.ItemId.RestaurantAccelerate))
    end
end

---@param benchModel XBenchViewModel
function XUiPanelWorkDetail:RefreshState(benchModel, limit, count)
    local isPause = benchModel:IsPause()
    local isIngredient = false
    self.TxtPredictNo.gameObject:SetActiveEx(isPause)
    self.TxtPredict.gameObject:SetActiveEx(not isPause and isIngredient)
    self.TxtPredictRed.gameObject:SetActiveEx(not isPause and isIngredient)
    if isPause then
        local index
        if benchModel:IsFull() then
            index = self._Control:IsSaleArea(self.AreaType) and 3 or 4
        elseif benchModel:IsInsufficient() then
            index = self._Control:IsSaleArea(self.AreaType) and 2 or 1
        end
        self.TxtPredictNo.text = self._Control:GetWorkPauseReason(index)
    elseif isIngredient then
        local productId = benchModel:GetProductId()
        local increase, tip = self._Control:GetWorkBenchPreviewTip(self.AreaType, productId)
        self.TxtPredict.gameObject:SetActiveEx(increase)
        self.TxtPredictRed.gameObject:SetActiveEx(not increase)
        local textComponent = increase and self.TxtPredict or self.TxtPredictRed
        textComponent.text = tip
    end
end

--切换菜肴
function XUiPanelWorkDetail:OnBtnChangeClick()
    local benchModel = self._Control:GetWorkbench(self.AreaType, self.Index)
    if benchModel:IsRunning() then
        self.Parent:ShowProductPanel(self.AreaType, self.Index)
        return
    end
    benchModel:DelProduct()
end

--切换角色
function XUiPanelWorkDetail:OnBtnHeadClick()
    local benchModel = self._Control:GetWorkbench(self.AreaType, self.Index)
    if benchModel:IsRunning() then
        self.Parent:ShowStaffPanel(self.AreaType, self.Index)
        return
    end
    benchModel:DelStaff()
end

--安排工作
function XUiPanelWorkDetail:OnBtnConfirmClick()
    local benchModel = self._Control:GetWorkbench(self.AreaType, self.Index)
    local productId = benchModel:GetProductId()
    local charId = benchModel:GetCharacterId()

    local request = function()
        self._Control:RequestAssignWork(self.AreaType, charId, self.Index, productId, function()
            benchModel:SwitchStaffOrProduct(charId, charId, productId, productId)
            self:RefreshButton(benchModel)
        end)
    end
    
    if benchModel:IsFull() then
        local title, content = benchModel:GetFullTitleAndContent()
        self._Control:OpenPopup(title, content, nil, nil, request)
        return
    elseif benchModel:IsInsufficient() then
        local title, content = benchModel:GetInsufficientTitleAndContent()
        self._Control:OpenPopup(title, content, nil, nil, request)
        return
    end
    request()
end

--统计
function XUiPanelWorkDetail:OnBtnStatisticsClick()
    local areaType = self._Control:IsIngredientArea(self.AreaType)
            and XMVCA.XRestaurant.AreaType.IngredientArea or XMVCA.XRestaurant.AreaType.FoodArea
    local benchModel = self._Control:GetWorkbench(self.AreaType, self.Index)
    XMVCA.XRestaurant:Burying(XMVCA.XRestaurant.BuryingButton.BtnStatistics, "UiRestaurantWork")
    self._Control:OpenStatistics(areaType, benchModel:GetProductId())
end

--终止工作
function XUiPanelWorkDetail:OnBtnSuspendClick()
    local benchModel = self._Control:GetWorkbench(self.AreaType, self.Index)
    self._Control:RequestAssignWork(self.AreaType, 0, self.Index, 0, function()
        benchModel:Stop()
        self:RefreshButton(benchModel)
    end)
end

--加速
function XUiPanelWorkDetail:OnBtnExpediteClick()
    local business = self._Control:GetBusiness()
    local count = business:GetAccelerateCount()
    if count <= 0 then
        return
    end
    if business:IsAccelerateUpperLimit() then
        return
    end

    local benchModel = self._Control:GetWorkbench(self.AreaType, self.Index)
    if not benchModel:IsRunning() then
        return
    end
    
    local request = function()
        local isSaleArea = self._Control:IsSaleArea(self.AreaType)
        local before, index, name
        if isSaleArea then
            before = self._Control:GetCashier():GetCount()
            name = ""
            index = 5
        else
            local product = benchModel:GetProduct()
            before = product:GetCount()
            name = product:GetName()
            index = 4
        end
        self._Control:RequestAccelerate(self.AreaType, self.Index, 1, function()
            local after = isSaleArea and self._Control:GetCashier():GetCount() or benchModel:GetProduct():GetCount()
            local subCont = math.max(0, after - before)
            local tip
            if subCont <= 0 then
                index = 6
                tip = self._Control:GetAccelerateTip(index)
            else
                tip = self._Control:GetAccelerateTip(index)
                tip = string.format(tip, after - before, benchModel:GetProductName())
            end
            XUiManager.TipMsg(tip)
            self:RefreshView()
        end)
    end
    local title = self._Control:GetAccelerateTip(1)
    local time = business:GetAccelerateTime()
    local content, itemData = benchModel:GetAccelerateContentAndItemData(time)
    self._Control:OpenPopup(title, content, itemData, nil, request)
end

function XUiPanelWorkDetail:RefreshBuff()
    if not self.UiRestaurantBtnBuff then
        return
    end
    
    if not self.PanelWorkBuff then
        self.PanelWorkBuff = XUiPanelWorkBuff.New(self.UiRestaurantBtnBuff, self.Parent, self.AreaType, false)
    end
    if self._Control:CheckAreaBuffUnlock(self.AreaType) then
        self.PanelWorkBuff:Open()
    else
        self.PanelWorkBuff:Close()
    end
end

return XUiPanelWorkDetail