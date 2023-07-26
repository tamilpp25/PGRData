local ColorEnum = {
    Enable = XUiHelper.Hexcolor2Color("5B4040"),
    Disable = XUiHelper.Hexcolor2Color("FF0000"),
    
    Changed = XUiHelper.Hexcolor2Color("0D70BC"),
    UnChanged = XUiHelper.Hexcolor2Color("313850"),
}


--- 解锁效果
local XUiGridEffect = XClass(nil, "XUiGridEffect")

function XUiGridEffect:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
end

function XUiGridEffect:Refresh(data)
    local type = data.Type
    local desc = XRestaurantConfigs.GetClientConfig("RestaurantLvUpEffectText", type)
    local count = data.Count
    self.TxtDesc.text = desc
    local countStr = type == XRestaurantConfigs.EffectType.HotSaleAddition and count.."%" or count
    self.TxtCount.text = countStr
    self.TxtCount.color = data.SubCount > 0 and ColorEnum.Changed or ColorEnum.UnChanged
    self.GameObject:SetActiveEx(true)
end

--- 解锁产品
local XUiGridProduct = XClass(nil, "XUiGridProduct")

function XUiGridProduct:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
end

function XUiGridProduct:Refresh(data)
    self.GameObject:SetActiveEx(true)
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    local product = viewModel:GetProduct(data.AreaType, data.Id)

    local unlock = product:IsUnlock()
    local isDefault = product:IsDefault()
    local unknown = not unlock and not isDefault
    if self.PanelLock then
        self.PanelLock.gameObject:SetActiveEx(unknown)
    end
    if self.PanelNormal then
        self.PanelNormal.gameObject:SetActiveEx(not unknown)
    end
    if unknown then
        return
    end
    self.RImgIcon:SetRawImage(product:GetProductIcon())
    self.TxtName.text = product:GetProperty("_Name")
end

--- 升级条件
local XUiGridCondition = XClass(nil, "XUiGridCondition")

function XUiGridCondition:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
end

function XUiGridCondition:Refresh(data)
    self.GameObject:SetActiveEx(true)
    self.ImgGou.gameObject:SetActiveEx(data.Finish)
    self.TxtContent.text = data.Text
end

local XUiPanelRestaurantLevelUp = require("XUi/XUiRestaurant/XUiPanel/XUiPanelRestaurantLevelUp")

---@class XUiPanelCondition : XUiPanelRestaurantLevelUp
local XUiPanelCondition = XClass(XUiPanelRestaurantLevelUp, "XUiPanelCondition")

function XUiPanelCondition:Refresh(list, level, curLevel)
    self.Level = level
    self.CurLevel = curLevel
    local filter = {}
    for _, data in ipairs(list or {}) do
        if data.Type == 1 then
            table.insert(filter, data)
        end
    end
    self.Super.Refresh(self, filter)
end

function XUiPanelCondition:GetTxtEmpty()
    if self.Level <= self.CurLevel and self.Level ~= XRestaurantConfigs.LevelRange.Max then
        return XRestaurantConfigs.GetClientConfig("RestaurantLvUpConditionText", 3)
    elseif self.Level >= XRestaurantConfigs.LevelRange.Max then
        return XRestaurantConfigs.GetClientConfig("RestaurantLvUpConditionText", 4)
    end
end


---@class XUiRestaurantHire : XLuaUi
local XUiRestaurantHire = XLuaUiManager.Register(XLuaUi, "UiRestaurantHire")
local XUiGridLevelButton = require("XUi/XUiRestaurant/XUiGrid/XUiGridLevelButton")


local PreviewLevel = 1

function XUiRestaurantHire:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiRestaurantHire:OnStart()
    
    self:InitView()
end

function XUiRestaurantHire:InitUi()
    
    ---@type XUiGridLevelButton[]
    self.LevelButton = {}
    
    ---@type XUiPanelRestaurantLevelUp
    self.PanelEffectLevelUp = XUiPanelRestaurantLevelUp.New(self.PanelFunction, XUiGridEffect)
    ---@type XUiPanelRestaurantLevelUp
    self.PanelFoodLevelUp = XUiPanelRestaurantLevelUp.New(self.PanelFood, XUiGridProduct)
    ---@type XUiPanelCondition
    self.PanelConditionLevelUp = XUiPanelCondition.New(self.PanelCondition, XUiGridCondition)
end 

function XUiRestaurantHire:InitCb()
    
    self.BtnWndClose.CallBack = function() 
        self:Close()
    end

    self.BtnClose.CallBack = function()
        self:Close()
    end
    
    self.BtnDetermine.CallBack = function() 
        self:OnBtnDetermineClick()
    end
end 

function XUiRestaurantHire:InitView()
    
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    
    self.Level = viewModel:GetProperty("_Level")
    self:InitLevelButton(self.Level)
    self:BindViewModelPropertyToObj(viewModel, function(isLevelUp)
        if not isLevelUp then
            return
        end
        self:Close()
    end, "_IsLevelUp")
end 

function XUiRestaurantHire:InitLevelButton(level)
    for _, grid in pairs(self.LevelButton) do
        if grid and not XTool.UObjIsNil(grid.GameObject) then
            grid.GameObject:SetActiveEx(false)
        end
    end
    local previewLevel = math.min(XRestaurantConfigs.LevelRange.Max, level + PreviewLevel)

    local gridIndex = 1
    for lv = XRestaurantConfigs.LevelRange.Min, previewLevel do
        local grid = self.LevelButton[gridIndex]
        if not grid then
            local ui =  gridIndex == 1 and self.GridLevel or XUiHelper.Instantiate(self.GridLevel, self.PanelTabGroup)
            grid = XUiGridLevelButton.New(ui, handler(self, self.OnSelectLevel))
            self.LevelButton[gridIndex] = grid
        end
        local isUnlock = lv <= level
        grid:Refresh(lv, level, isUnlock, not isUnlock, "LV" .. lv)
        if lv == level then
            grid:OnBtnLevelClick()
        end
        gridIndex = gridIndex + 1
    end
end 

---@param levelBtn XUiGridLevelButton
function XUiRestaurantHire:OnSelectLevel(levelBtn)
    if self.LastLevelBtn then
        self.LastLevelBtn:SetSelect(false)
    end
    self:PlayAnimation("QieHuan")
    self.LastLevelBtn = levelBtn
    self.SelectLevel = levelBtn.Level
    self:RefreshDetail()
end 

function XUiRestaurantHire:RefreshDetail()
    local isUnlock = self.Level >= self.SelectLevel
    self.BtnDetermine.gameObject:SetActiveEx(not isUnlock)
    self.ImgRenovation:SetRawImage(XRestaurantConfigs.GetRestaurantDecorationIcon(self.SelectLevel))
    self.ImgTitle:SetSprite(XRestaurantConfigs.GetRestaurantTitleIcon(self.SelectLevel))
    local levelUpgrade = XRestaurantConfigs.GetUpgradeCondition(self.SelectLevel - 1)
    local conditionList = {}
    local effectList = XRestaurantConfigs.GetRestaurantUnlockEffectList(self.SelectLevel)
    self.AbleLevelUp = not isUnlock
    if not isUnlock then
        local consumeList = levelUpgrade.ConsumeData
        for _, consume in pairs(consumeList or {}) do
            local id = consume.ItemId
            local need = consume.Count
            local count = XDataCenter.ItemManager.GetCount(id)
            local icon = XDataCenter.ItemManager.GetItemIcon(id)
            self.RImgCoinIcon:SetRawImage(icon)
            self.TxtConsume.text = count
            self.TxtPrice.text = "/" .. need
            local enough = count >= need
            self.TxtConsume.color = enough and ColorEnum.Enable or ColorEnum.Disable
            self.AbleLevelUp = enough
            break
        end
        conditionList = XRestaurantConfigs.GetRestaurantUnlockConditionList(levelUpgrade)
        for _, condition in pairs(conditionList or {}) do
            if not condition.Finish then
                self.AbleLevelUp = false
                break
            end
        end

        self.BtnDetermine:SetDisable(not self.AbleLevelUp)
        self.BtnDetermine:ShowReddot(self.AbleLevelUp)
    end
    self.PanelEffectLevelUp:Refresh(effectList)
    
    self.PanelFoodLevelUp:Refresh(XRestaurantConfigs.GetRestaurantUnlockProductList(
            XRestaurantConfigs.AreaType.FoodArea, XRestaurantConfigs.GetUnlockFood(self.SelectLevel)))
    
    self.PanelConditionLevelUp:Refresh(conditionList, self.SelectLevel, self.Level)
    
end

function XUiRestaurantHire:OnBtnDetermineClick()
    if not self.AbleLevelUp then
        local tip = XRestaurantConfigs.GetClientConfig("RestaurantLvUpConditionText", 5)
        XUiManager.TipMsg(tip)
        return
    end
    
    local title = XRestaurantConfigs.GetClientConfig("RestaurantLvUpPopupTip", 1)
    local content = XRestaurantConfigs.GetClientConfig("RestaurantLvUpPopupTip", 2)
    content = XUiHelper.ReplaceTextNewLine(string.format(content, self.Level, self.Level + 1))
    
    XDataCenter.RestaurantManager.OpenPopup(title, content, nil, nil, function()
        self:Close()
        XDataCenter.RestaurantManager.RequestLevelUpRestaurant()
    end)
end 