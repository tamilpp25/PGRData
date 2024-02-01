local ColorEnum = {
    Enable = XUiHelper.Hexcolor2Color("0D70BC"),
    Disable = XUiHelper.Hexcolor2Color("FF0000"),
    Up = XUiHelper.Hexcolor2Color("356C38"),
    Down = XUiHelper.Hexcolor2Color("CE453B"),
}

local XUiGridSkillItem = XClass(nil, "XUiGridSkillItem")

function XUiGridSkillItem:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
end

function XUiGridSkillItem:Refresh(product, skillAreaType, addition, isUrgent)
    self.GameObject:SetActiveEx(true)
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
    self.TxtName.text = product:GetProperty("_Name")
    self.RImgIcon:SetRawImage(product:GetProductIcon())
    local icon = XRestaurantConfigs.GetUpOrDownArrowIcon( addition >= 0 and 1 or 2)
    self.ImgUpgrade:SetSprite(icon)
    self.TxtUpgrade.text = XRestaurantConfigs.GetCharacterSkillPercentAddition(addition, skillAreaType, product:GetProperty("_Id"))
    self.TxtUpgrade.color = addition >= 0 and ColorEnum.Up or ColorEnum.Down
    local isHot = product:GetProperty("_HotSale")
    self.PanelUrgent.gameObject:SetActiveEx(unlock and isUrgent)
    self.PanelHot.gameObject:SetActiveEx(unlock and isHot and not isUrgent)
end


---@class XUiGridSkillButton
local XUiGridSkillButton = XClass(nil, "XUiGridSkillButton")

function XUiGridSkillButton:Ctor(ui, onClick)
    XTool.InitUiObjectByUi(self, ui)
    self.OnClick = onClick
    
    self.BtnClick = self.Transform:GetComponent("XUiButton")
    self.BtnClick.CallBack = function() 
        self:OnBtnClick()
    end
end

function XUiGridSkillButton:Refresh(skillId)
    self.SkillId = skillId
    self.BtnClick:SetNameByGroup(0, XRestaurantConfigs.GetCharacterSkillName(skillId))
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
local XUiRestaurantCook = XLuaUiManager.Register(XLuaUi, "UiRestaurantCook")

local XUiGridRecruitRole = require("XUi/XUiRestaurant/XUiGrid/XUiGridRecruitRole")
local XUiGridLevelButton = require("XUi/XUiRestaurant/XUiGrid/XUiGridLevelButton")



local TabIndex = {
    0, XRestaurantConfigs.AreaType.IngredientArea, XRestaurantConfigs.AreaType.FoodArea, XRestaurantConfigs.AreaType.SaleArea,
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
    self.DynamicTable:SetProxy(XUiGridRecruitRole, handler(self, self.OnSelectRole))
    self.GridRole.gameObject:SetActiveEx(false)

    ---@type XUiGridLevelButton[]
    self.LevelButton = {}
    
    self.GridAreas = {}
    
    ---@type XUiGridSkillButton[]
    self.SkillButton = {}
    
    self.GridSkills = {}
    
    local tabBtn = {}
    for index, _ in ipairs(TabIndex) do
        local btn = index == 1 and self.BtnTab or XUiHelper.Instantiate(self.BtnTab, self.PanelTabCharacter.transform)
        btn:SetNameByGroup(0, XRestaurantConfigs.GetStaffTabText(index))
        table.insert(tabBtn, btn)
    end
    self.PanelTabCharacter:Init(tabBtn, function(tabIndex) self:OnSelectTab(tabIndex) end)
    
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
    
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    
    self:BindViewModelPropertyToObj(viewModel, function(level)
        self:RefreshLimit()
    end, "_Level")
    
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
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    local level = viewModel:GetProperty("_Level")
    local limit = XRestaurantConfigs.GetCharacterLimit(level)
    local list = viewModel:GetRecruitStaffList()
    self.TxtCount.text = string.format("%s/%s", #list, limit)
end

function XUiRestaurantCook:SetupDynamicTable()
    if XTool.UObjIsNil(self.GameObject) then
        return
    end
    self.TabIndex = self.TabIndex or DefaultTabIndex
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    
    local list = viewModel:GetStaffList(TabIndex[self.TabIndex])
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
end 

function XUiRestaurantCook:GetSelectIndex()
    if not XTool.IsNumberValid(self.SelectRoleId) then
        return 1
    end
    if XTool.IsTableEmpty(self.DataList) then
        return -1
    end

    for idx, staff in ipairs(self.DataList) do
        if staff:GetProperty("_Id") == self.SelectRoleId then
            return idx
        end
    end
    return 1
end

function XUiRestaurantCook:RefreshDetails()
    if not XTool.IsNumberValid(self.SelectRoleId) then
        return
    end
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    local character = viewModel:GetStaffViewModel(self.SelectRoleId)
    local isRecruit = character:GetProperty("_IsRecruit")
    local level = character:GetProperty("_Level")
    self.TxtName.text = character:GetName()
    self.RImgHead:SetRawImage(character:GetIcon())
    self.TxtCode.text = XMVCA.XCharacter:GetCharacterCodeStr(self.SelectRoleId)
    local levelList = {}
    local btnIndex = 1
    self:HideAllGrids(self.LevelButton)
    self.LastLevelBtn = nil
    local hasSelect = false
    local tabAreaType = TabIndex[self.TabIndex]
    for lv = level, XRestaurantConfigs.StaffLevel.Max do
        table.insert(levelList, lv)
        local grid = self.LevelButton[btnIndex]
        local isSelect = character:IsAdditionByAreaTypeWithLevel(tabAreaType, lv)
        if not grid then 
            local btn = btnIndex == 1 and self.BtnLevel or XUiHelper.Instantiate(self.BtnLevel, self.PanelTab.transform)
            grid = XUiGridLevelButton.New(btn, handler(self, self.OnSelectLevel))
            table.insert(self.LevelButton, grid)
        end
        grid:Refresh(lv, level, isRecruit, level ~= lv or not isRecruit, XRestaurantConfigs.GetCharacterLevelStr(lv))
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
    local skillIds = XRestaurantConfigs.GetCharacterSkillIds(self.SelectRoleId, level)
    local labelIndex = 1
    local tabAreaType = TabIndex[self.TabIndex]
    local hasSelect = false
    for idx, skillId in pairs(skillIds or {}) do
        local additionMap = XRestaurantConfigs.GetCharacterSkillAddition(skillId)
        local showLabel = true
        for _, addition in pairs(additionMap or {}) do
            --策划需求：有技能加成小于0，则不显示推荐工作
            if addition <= 0 then
                showLabel = false
                break
            end
        end
        local areaType = XRestaurantConfigs.GetCharacterSkillAreaType(skillId)
        
        if showLabel then
            local grid = self.GridAreas[labelIndex]
            if not grid then
                local ui = labelIndex == 1 and self.GridArea or XUiHelper.Instantiate(self.GridArea, self.PanelArea)
                grid = {}
                XTool.InitUiObjectByUi(grid, ui)
                self.GridAreas[labelIndex] = grid
            end
            grid.TxtName.text = XRestaurantConfigs.GetCharacterSkillTypeName(areaType)
            grid.ImgBg:SetSprite(XRestaurantConfigs.GetCharacterSkillLabelIcon(areaType))
            grid.GameObject:SetActiveEx(true)
            labelIndex = labelIndex + 1
        end
        local isSelect = tabAreaType == 0 and idx == 1 or tabAreaType == areaType
        local btn = self.SkillButton[idx]
        if not btn then
            local ui = idx == 1 and self.BtnSkill or XUiHelper.Instantiate(self.BtnSkill, self.PanelSkillGroup.transform)
            btn = XUiGridSkillButton.New(ui, handler(self, self.OnSelectSkill))
            self.SkillButton[idx] = btn
        end
        btn:Refresh(skillId)
        if not hasSelect and isSelect then
            btn:SetSelect(false)
            btn:OnBtnClick()
            hasSelect = true
        end
    end
    if not hasSelect then
        local btn = self.SkillButton[1]
        btn:SetSelect(false)
        btn:OnBtnClick()
    end
    local coinId = XRestaurantConfigs.ItemId.RestaurantUpgradeCoin
    local isMax = isRecruit and curLevel == XRestaurantConfigs.StaffLevel.Max
    local subLevel = level - curLevel
    self.BtnDetermine.gameObject:SetActiveEx(false)
    if not isMax then
        self.RImgCoinIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(coinId))
        local btnText
        ---@type XConsumeData[]
        local consumeData
        local consume, price = 0, 0
        local disable
        if isRecruit then
            btnText = XRestaurantConfigs.GetClientConfig("StaffStateBtnText", 1)
            consumeData = XRestaurantConfigs.GetCharacterLevelUpConsume(self.SelectRoleId, math.min(level, XRestaurantConfigs.StaffLevel.Max))
            disable = subLevel > 1
        else
            btnText = XRestaurantConfigs.GetClientConfig("StaffStateBtnText", 2)
            consumeData = XRestaurantConfigs.GetCharacterEmployConsume(self.SelectRoleId)
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
    self.TxtSkillDesc.text = XRestaurantConfigs.GetCharacterSkillDesc(skillId)
    local skillList = self:_SortSkillProduct(XRestaurantConfigs.GetCharacterSkillAdditionList(skillId))
    local areaType = XRestaurantConfigs.GetCharacterSkillAreaType(skillId)
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    local gridIndex = 1
    for _, data in pairs(skillList or {}) do
        local productId, addition = data.Id, data.Addition
        local grid = self.GridSkills[gridIndex]
        if not grid then
            local ui = gridIndex == 1 and self.GridSkill or XUiHelper.Instantiate(self.GridSkill, self.Container)
            grid = XUiGridSkillItem.New(ui)
            self.GridSkills[gridIndex] = grid
        end
        local product = viewModel:GetProduct(areaType, productId)
        grid:Refresh(product, areaType, addition, viewModel:IsUrgentProduct(areaType, productId))
        gridIndex = gridIndex + 1
    end
end

function XUiRestaurantCook:OnBtnDetermineClick()
    if not self.IsRecruit then
        XDataCenter.RestaurantManager.RequestEmployStaff(self.SelectRoleId, function() 
            self:RefreshLimit()
            self:SetupDynamicTable()
        end)
    else
        XDataCenter.RestaurantManager.RequestLevelUpStaff(self.SelectRoleId, function(character)
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
        if role:GetProperty("_Id") == roleId then
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
            grid.GameObject:SetActiveEx(false)
        end
    end
end

function XUiRestaurantCook:SortStaffList(list, type)
    if type == 0 then
        return self:_SortAll(list)
    end
    return self:_SortTab(list, type)
end 

function XUiRestaurantCook:_SortAll(list)
    list = list or {}
    table.sort(list, function(a, b)
        local recruitA = a:GetProperty("_IsRecruit")
        local recruitB = b:GetProperty("_IsRecruit")

        if recruitA ~= recruitB then
            return recruitA
        end

        local levelA = a:GetProperty("_Level")
        local levelB = b:GetProperty("_Level")

        if levelA ~= levelB then
            return levelA > levelB
        end

        --local additionUnlockA = a:IsAdditionOnUnlockProduct()
        --local additionUnlockB = b:IsAdditionOnUnlockProduct()
        --
        --if additionUnlockA ~= additionUnlockB then
        --    return additionUnlockA
        --end

        local idA = a:GetProperty("_Id")
        local idB = b:GetProperty("_Id")

        local pA = XRestaurantConfigs.GetCharacterPriority(idA)
        local pB = XRestaurantConfigs.GetCharacterPriority(idB)
        if pA ~= pB then
            return pA < pB
        end

        return idA < idB
    end)
    
    return list
end

function XUiRestaurantCook:_SortTab(list, areaType)
    list = list or {}
    table.sort(list, function(a, b)
        local recruitA = a:GetProperty("_IsRecruit")
        local recruitB = b:GetProperty("_IsRecruit")

        if recruitA ~= recruitB then
            return recruitA
        end

        --已招募时，对比是否有加成效果
        if recruitA then
            local isAdditionA = a:IsAdditionByAreaType(areaType)
            local isAdditionB = b:IsAdditionByAreaType(areaType)

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

        local levelA = a:GetProperty("_Level")
        local levelB = b:GetProperty("_Level")

        if levelA ~= levelB then
            return levelA > levelB
        end

        local idA = a:GetProperty("_Id")
        local idB = b:GetProperty("_Id")

        local pA = XRestaurantConfigs.GetCharacterPriority(idA)
        local pB = XRestaurantConfigs.GetCharacterPriority(idB)
        if pA ~= pB then
            return pA < pB
        end

        return idA < idB
    
    end)
    
    return list
end

function XUiRestaurantCook:_SortSkillProduct(skillList)
    skillList = skillList or {}
    
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    table.sort(skillList, function(a, b) 
        local productA = viewModel:GetProduct(a.AreaType, a.Id)
        local productB = viewModel:GetProduct(b.AreaType, b.Id)
        
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
        
        local isUrgentA = viewModel:IsUrgentProduct(a.AreaType, a.Id)
        local isUrgentB = viewModel:IsUrgentProduct(b.AreaType, b.Id)

        if isUrgentA ~= isUrgentB then
            return isUrgentA
        end
        
        local isHotA = productA:GetProperty("_HotSale")
        local isHotB = productB:GetProperty("_HotSale")

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