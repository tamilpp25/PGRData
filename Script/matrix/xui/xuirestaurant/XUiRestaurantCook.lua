local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local ColorEnum = {
    Enable = XUiHelper.Hexcolor2Color("0D70BC"),
    Disable = XUiHelper.Hexcolor2Color("FF0000"),
    Up = XUiHelper.Hexcolor2Color("356C38"),
    Down = XUiHelper.Hexcolor2Color("CE453B"),
}

---@class XUiGridSkillItem : XUiNode
---@field _Control XRestaurantControl
local XUiGridSkillItem = XClass(XUiNode, "XUiGridSkillItem")

--- 刷新
---@param product XRestaurantProductVM
--------------------------
function XUiGridSkillItem:Refresh(product, skillAreaType, addition, isUrgent)
    self:Open()
    local unlock = product:IsUnlock()
    local isDefault = product:IsDefault()
    local unknown = not unlock and not isDefault
    self.PanelLock.gameObject:SetActiveEx(unknown)
    self.RImgIcon.gameObject:SetActiveEx(not unknown)
    self.ImgUpgrade.gameObject:SetActiveEx(not unknown)
    self.TxtUpgrade.gameObject:SetActiveEx(not unknown)
    if unknown then
        self.TxtName.text = "<B>? ? ?</B>"
        self.PanelUrgent.gameObject:SetActiveEx(false)
        self.PanelHot.gameObject:SetActiveEx(false)
        return
    end
    self.TxtName.text = product:GetName()
    self.RImgIcon:SetRawImage(product:GetProductIcon())
    local icon = self._Control:GetUpOrDownArrowIcon( addition >= 0 and 1 or 2)
    self.ImgUpgrade:SetSprite(icon)
    self.TxtUpgrade.text = self._Control:GetCharacterSkillPercentAddition(addition, skillAreaType, product:GetProductId())
    self.TxtUpgrade.color = addition >= 0 and ColorEnum.Up or ColorEnum.Down
    local isHot = product:IsHotSale()
    self.PanelUrgent.gameObject:SetActiveEx(unlock and isUrgent)
    self.PanelHot.gameObject:SetActiveEx(unlock and isHot and not isUrgent)
end


---@class XUiGridSkillButton : XUiNode
---@field _Control XRestaurantControl
local XUiGridSkillButton = XClass(XUiNode, "XUiGridSkillButton")

function XUiGridSkillButton:OnStart(onClick)
    self.OnClick = onClick

    self.BtnClick = self.Transform:GetComponent("XUiButton")
    self.BtnClick.CallBack = function()
        self:OnBtnClick()
    end
end

function XUiGridSkillButton:Refresh(characterId, skillId)
    self:Open()
    self.SkillId = skillId
    self.BtnClick:SetNameByGroup(0, self._Control:GetCharacter(characterId):GetCharacterSkillName(skillId))
    self:SetSelect(false)
    self.GameObject:SetActiveEx(true)
end

function XUiGridSkillButton:SetSelect(select)
    self.IsSelect = select
    self.BtnClick:SetButtonState(select and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

function XUiGridSkillButton:OnBtnClick()
    if self.IsSelect or not XTool.IsNumberValid(self.SkillId) then
        self.BtnClick:SetButtonState(self.IsSelect and CS.UiButtonState.Select or CS.UiButtonState.Normal)
        return
    end
    
    self:SetSelect(true)
    if self.OnClick then self.OnClick(self) end
end


---@class XUiRestaurantCook : XLuaUi
---@field _Control XRestaurantControl
---@field GameObject UnityEngine.GameObject
local XUiRestaurantCook = XLuaUiManager.Register(XLuaUi, "UiRestaurantCook")

local XUiGridRecruitRole = require("XUi/XUiRestaurant/XUiGrid/XUiGridRecruitRole")
local XUiGridLevelButton = require("XUi/XUiRestaurant/XUiGrid/XUiGridLevelButton")



local TabIndex = {
    XMVCA.XRestaurant.AreaType.None, 
    XMVCA.XRestaurant.AreaType.IngredientArea, 
    XMVCA.XRestaurant.AreaType.FoodArea, 
    XMVCA.XRestaurant.AreaType.SaleArea,
}

local DefaultTabIndex = 1

function XUiRestaurantCook:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiRestaurantCook:OnStart()
    self:InitView()
end

function XUiRestaurantCook:InitUi()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelEmploymentList)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridRecruitRole, self, handler(self, self.OnSelectRole))
    self.GridRole.gameObject:SetActiveEx(false)
    self.BtnSkill.gameObject:SetActiveEx(false)
    self.GridSkill.gameObject:SetActiveEx(false)
    self.TxtSkillDesc.text = ""
    ---@type XUiGridLevelButton[]
    self.LevelButton = {}
    
    self.GridAreas = {}
    
    ---@type XUiGridSkillButton[]
    self.SkillButton = {}
    
    self.GridSkills = {}
    
    local tabBtn = {}
    for index, _ in ipairs(TabIndex) do
        local btn = index == 1 and self.BtnTab or XUiHelper.Instantiate(self.BtnTab, self.PanelTabCharacter.transform)
        btn:SetNameByGroup(0, self._Control:GetStaffTabText(index))
        table.insert(tabBtn, btn)
    end
    self.PanelTabCharacter:Init(tabBtn, function(tabIndex) self:OnSelectTab(tabIndex) end)
    
    
    self.PanelLbEx = self.Container.transform.parent.parent:GetComponent("ScrollRect")
end 

function XUiRestaurantCook:InitCb()
    self.BtnClose.CallBack = function() 
        self:Close()
    end
    
    self.BtnWndClose.CallBack = function() 
        self:Close()
    end
    
    self.BtnDetermine.CallBack = function() 
        self:OnBtnDetermineClick()
    end
end 

function XUiRestaurantCook:InitView()
    self:RefreshLimit()
    self.PanelTabCharacter:SelectIndex(DefaultTabIndex)
end 

function XUiRestaurantCook:OnSelectTab(tabIndex)
    if self.TabIndex == tabIndex then
        return
    end
    self.TabIndex = tabIndex
    if self.LastGrid then
        self.LastGrid:SetSelect(false)
    end
    self.SelectRoleId = nil
    self:SetupDynamicTable()
end

function XUiRestaurantCook:RefreshLimit()
    local limit = self._Control:GetCharacterLimit()
    self.TxtCount.text = string.format("%s/%s", self._Control:GetRecruitCharacterCount(), limit)
end

function XUiRestaurantCook:SetupDynamicTable()
    if XTool.UObjIsNil(self.GameObject) then
        return
    end
    self.TabIndex = self.TabIndex or DefaultTabIndex
    local list =  self._Control:GetCharactersWithAreaTypeAddition(TabIndex[self.TabIndex])
    list = self:SortStaffList(list, TabIndex[self.TabIndex])
    self.DataList = list
    self.DynamicTable:SetDataSource(list)
    self.DynamicTable:ReloadDataASync(self:GetSelectIndex())
end

function XUiRestaurantCook:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.DataList[index], self.SelectRoleId)
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        local selectIndex = self:GetSelectIndex()
        if selectIndex > 0 then
            local girds = self.DynamicTable:GetGrids()
            local tmpGrid = girds[selectIndex]
            if tmpGrid then
                tmpGrid:SetSelect(false)
                tmpGrid:OnBtnClick()
            end
        end
    end
end

function XUiRestaurantCook:OnSelectRole(grid)
    if self.LastGrid 
            and self.LastGrid.CharacterId == self.SelectRoleId then
        self.LastGrid:SetSelect(false)
    end
    self:PlayAnimation("QieHuan")
    self.LastGrid = grid
    self.SelectRoleId = grid.CharacterId
    self.LastLevelBtn = nil
    self.LastSkillBtn = nil
    self:RefreshDetails()
    self.PanelLbEx.horizontalNormalizedPosition = 0
end 

function XUiRestaurantCook:GetSelectIndex()
    if not XTool.IsNumberValid(self.SelectRoleId) then
        return 1
    end
    if XTool.IsTableEmpty(self.DataList) then
        return -1
    end

    for idx, staff in ipairs(self.DataList) do
        if staff:GetCharacterId() == self.SelectRoleId then
            return idx
        end
    end
    return 1
end

function XUiRestaurantCook:RefreshDetails()
    if not XTool.IsNumberValid(self.SelectRoleId) then
        return
    end
    local character = self._Control:GetCharacter(self.SelectRoleId)
    local isRecruit = character:IsRecruit()
    local level = character:GetLevel()
    self.TxtName.text = character:GetName()
    self.RImgHead:SetRawImage(character:GetIcon())
    self.TxtCode.text = character:GetAffiliated()--XMVCA.XRestaurant:GetCharacterCodeStr(self.SelectRoleId)
    local levelList = {}
    local btnIndex = 1
    self:HideAllGrids(self.LevelButton)
    self.LastLevelBtn = nil
    local hasSelect = false
    local tabAreaType = TabIndex[self.TabIndex]
    for lv = level, XMVCA.XRestaurant.StaffLevelRange.Max do
        table.insert(levelList, lv)
        local grid = self.LevelButton[btnIndex]
        local isSelect = character:IsAdditionByAreaTypeWithLevel(tabAreaType, lv)
        if not grid then 
            local btn = btnIndex == 1 and self.BtnLevel or XUiHelper.Instantiate(self.BtnLevel, self.PanelTab.transform)
            grid = XUiGridLevelButton.New(btn, self, handler(self, self.OnSelectLevel))
            table.insert(self.LevelButton, grid)
        end
        grid:Refresh(lv, level, isRecruit, level ~= lv or not isRecruit, character:GetLevelStr(lv), nil)
        if not hasSelect and isSelect then
            grid:OnBtnLevelClick()
            hasSelect = true
        end
        btnIndex = btnIndex + 1
    end
    self.LevelList = levelList
    self.IsRecruit = isRecruit
end

function XUiRestaurantCook:OnSelectLevel(levelBtn)
    if self.LastLevelBtn then
        self.LastLevelBtn:SetSelect(false)
    end
    self.LastSkillBtn = nil
    self:HideAllGrids(self.GridAreas)
    self:HideAllGrids(self.SkillButton)

    self:PlayAnimation("QieHuan")
    self.LastLevelBtn = levelBtn
    local level, curLevel, isRecruit = levelBtn.Level, levelBtn.CurLevel, levelBtn.IsUnlock
    local character = self._Control:GetCharacter(self.SelectRoleId)
    local skillIds = character:GetSkillIdsInPreview(level)
    local labelIndex = 1
    local tabAreaType = TabIndex[self.TabIndex]
    local hasSelect = false
    for idx, skillId in pairs(skillIds or {}) do
        local additionMap = character:GetCharacterSkillAddition(skillId)
        local showLabel = true
        for _, addition in pairs(additionMap or {}) do
            --策划需求：有技能加成小于0，则不显示推荐工作
            if addition <= 0 then
                showLabel = false
                break
            end
        end
        local areaType = character:GetCharacterSkillAreaType(skillId)
        
        if showLabel then
            local grid = self.GridAreas[labelIndex]
            if not grid then
                local ui = labelIndex == 1 and self.GridArea or XUiHelper.Instantiate(self.GridArea, self.PanelArea)
                grid = {}
                XTool.InitUiObjectByUi(grid, ui)
                self.GridAreas[labelIndex] = grid
            end
            grid.TxtName.text = character:GetCharacterSkillTypeName(areaType)
            grid.ImgBg:SetSprite(character:GetCharacterSkillLabelIcon(areaType))
            grid.GameObject:SetActiveEx(true)
            labelIndex = labelIndex + 1
        end
        local isSelect = tabAreaType == 0 and idx == 1 or tabAreaType == areaType
        local btn = self.SkillButton[idx]
        if not btn then
            local ui = idx == 1 and self.BtnSkill or XUiHelper.Instantiate(self.BtnSkill, self.PanelSkillGroup.transform)
            btn = XUiGridSkillButton.New(ui, self, handler(self, self.OnSelectSkill))
            self.SkillButton[idx] = btn
        end
        btn:Refresh(self.SelectRoleId, skillId)
        if not hasSelect and isSelect then
            btn:SetSelect(false)
            btn:OnBtnClick()
            hasSelect = true
        end
    end
    if not hasSelect and not XTool.IsTableEmpty(self.SkillButton) then
        local btn = self.SkillButton[1]
        btn:SetSelect(false)
        btn:OnBtnClick()
    end
    local coinId = XMVCA.XRestaurant.ItemId.RestaurantUpgradeCoin
    local isMax = isRecruit and curLevel == XMVCA.XRestaurant.StaffLevelRange.Max
    local subLevel = level - curLevel
    self.BtnDetermine.gameObject:SetActiveEx(false)
    if not isMax then
        self.RImgCoinIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(coinId))
        local btnText
        local consumeData
        local consume, price = 0, 0
        local disable
        if isRecruit then
            btnText = self._Control:GetStaffStateBtnText(1)
            consumeData = character:GetCharacterLevelUpConsume(math.min(level, XMVCA.XRestaurant.StaffLevelRange.Max))
            disable = subLevel > 1
        else
            btnText = self._Control:GetStaffStateBtnText(2)
            consumeData = character:GetCharacterEmployConsume()
        end
        self.BtnDetermine:SetNameByGroup(0, btnText)
        for _, data in pairs(consumeData or {}) do
            if data.ItemId == coinId then
                price = price + data.Count
            end
        end
        consume = XDataCenter.ItemManager.GetCount(coinId)
        self.TxtConsume.text = consume
        self.TxtConsume.color = consume >= price and ColorEnum.Enable or ColorEnum.Disable
        self.TxtPrice.text = "/" .. price
        disable = disable or consume < price
        self.BtnDetermine:SetDisable(disable, not disable)
        self.BtnDetermine.gameObject:SetActiveEx(level == curLevel or not isRecruit)
    end
end

function XUiRestaurantCook:OnSelectSkill(skillBtn)
    if self.LastSkillBtn then
        self.LastSkillBtn:SetSelect(false)
    end
    self:HideAllGrids(self.GridSkills)
    self.LastSkillBtn = skillBtn
    local skillId = skillBtn.SkillId
    local character = self._Control:GetCharacter(self.SelectRoleId)
    self.TxtSkillDesc.text = character:GetCharacterSkillDesc(skillId)
    local skillList = self:_SortSkillProduct(character:GetCharacterSkillAdditionList(skillId))
    local areaType = character:GetCharacterSkillAreaType(skillId)
    local gridIndex = 1
    for _, data in pairs(skillList or {}) do
        local productId, addition = data.Id, data.Addition
        local grid = self.GridSkills[gridIndex]
        if not grid then
            local ui = gridIndex == 1 and self.GridSkill or XUiHelper.Instantiate(self.GridSkill, self.Container)
            grid = XUiGridSkillItem.New(ui, self)
            self.GridSkills[gridIndex] = grid
        end
        local product = self._Control:GetProduct(areaType, productId)
        grid:Refresh(product, areaType, addition, self._Control:IsUrgentProduct(areaType, productId))
        gridIndex = gridIndex + 1
    end
end

function XUiRestaurantCook:OnBtnDetermineClick()
    if not self.IsRecruit then
        self._Control:RequestEmployStaff(self.SelectRoleId, function()
            self:RefreshLimit()
            --self:SetupDynamicTable()
            local role = self:GetCharacter(self.SelectRoleId)
            if self.LastGrid and role then
                self.LastGrid:Refresh(role, self.SelectRoleId)
            end

            self:RefreshDetails()
        end)
    else
        self._Control:RequestLevelUpStaff(self.SelectRoleId, function()
            local role = self:GetCharacter(self.SelectRoleId)
            if self.LastGrid and role then
                self.LastGrid:Refresh(role, self.SelectRoleId)
            end

            self:RefreshDetails()
        end)
    end
end

function XUiRestaurantCook:GetCharacter(roleId)
    for _, role in pairs(self.DataList) do
        if role:GetCharacterId() == roleId then
            return role
        end
    end
end

function XUiRestaurantCook:HideAllGrids(container)
    if XTool.IsTableEmpty(container) then
        return
    end

    for _, grid in pairs(container or {}) do
        if grid and not XTool.UObjIsNil(grid.GameObject) then
            if grid.Close then
                grid:Close()
            else
                grid.GameObject:SetActiveEx(false)
            end
        end
    end
end

function XUiRestaurantCook:SortStaffList(list, type)
    if type == 0 then
        return self:_SortAll(list)
    end
    return self:_SortTab(list, type)
end 

---@param list XRestaurantStaffVM[]
function XUiRestaurantCook:_SortAll(list)
    list = list or {}
    table.sort(list, function(a, b)
        local recruitA = a:IsRecruit()
        local recruitB = b:IsRecruit()

        if recruitA ~= recruitB then
            return recruitA
        end

        local levelA = a:GetLevel()
        local levelB = b:GetLevel()

        if levelA ~= levelB then
            return levelA > levelB
        end

        --local additionUnlockA = a:IsAdditionOnUnlockProduct()
        --local additionUnlockB = b:IsAdditionOnUnlockProduct()
        --
        --if additionUnlockA ~= additionUnlockB then
        --    return additionUnlockA
        --end

        local pA = a:GetPriority()
        local pB = b:GetPriority()
        
        if pA ~= pB then
            return pA < pB
        end

        return a:GetCharacterId() < b:GetCharacterId()
    end)
    
    return list
end

---@param list XRestaurantStaffVM[]
function XUiRestaurantCook:_SortTab(list, areaType)
    list = list or {}
    table.sort(list, function(a, b)
        local recruitA = a:IsRecruit()
        local recruitB = b:IsRecruit()

        if recruitA ~= recruitB then
            return recruitA
        end

        --已招募时，对比是否有加成效果
        if recruitA then
            local isAdditionA = a:IsAdditionByAreaTypeWithLevel(areaType)
            local isAdditionB = b:IsAdditionByAreaTypeWithLevel(areaType)

            if isAdditionA ~= isAdditionB then
                return isAdditionA
            end
        else --未招募时，对比初级是否有加成效果
            local isAdditionA = a:IsAdditionByAreaTypeWithLowLevel(areaType)
            local isAdditionB = b:IsAdditionByAreaTypeWithLowLevel(areaType)

            if isAdditionA ~= isAdditionB then
                return isAdditionA
            end
        end

        local levelA = a:GetLevel()
        local levelB = b:GetLevel()

        if levelA ~= levelB then
            return levelA > levelB
        end

        local pA = a:GetPriority()
        local pB = b:GetPriority()

        if pA ~= pB then
            return pA < pB
        end

        return a:GetCharacterId() < b:GetCharacterId()
    
    end)
    
    return list
end

function XUiRestaurantCook:_SortSkillProduct(skillList)
    if XTool.IsTableEmpty(skillList) then
        return {}
    end
    local control = self._Control
    table.sort(skillList, function(a, b) 
        local productA = control:GetProduct(a.AreaType, a.Id)
        local productB = control:GetProduct(b.AreaType, b.Id)
        
        local isUnlockA = productA:IsUnlock()
        local isUnlockB = productB:IsUnlock()

        if isUnlockA ~= isUnlockB then
            return isUnlockA
        end

        local isDefaultA = productA:IsDefault()
        local isDefaultB = productB:IsDefault()

        if isDefaultA ~= isDefaultB then
            return isDefaultA
        end
        
        local isUrgentA = control:IsUrgentProduct(a.AreaType, a.Id)
        local isUrgentB = control:IsUrgentProduct(b.AreaType, b.Id)

        if isUrgentA ~= isUrgentB then
            return isUrgentA
        end
        
        local isHotA = productA:IsHotSale()
        local isHotB = productB:IsHotSale()

        if isHotA ~= isHotB then
            return isHotA
        end
        
        local priorityA = productA:GetPriority()
        local priorityB = productB:GetPriority()

        if priorityA ~= priorityB then
            return priorityA < priorityB
        end
        
        return a.Id < b.Id
    end)
    
    return skillList
end