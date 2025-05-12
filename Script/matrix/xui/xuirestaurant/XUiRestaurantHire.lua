local XUiGridCond = require("XUi/XUiSettleWinMainLine/XUiGridCond")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local ColorEnum = {
    Enable = XUiHelper.Hexcolor2Color("5B4040"),
    Disable = XUiHelper.Hexcolor2Color("FF0000"),
    
    Changed = XUiHelper.Hexcolor2Color("70A998"),
    UnChanged = XUiHelper.Hexcolor2Color("313850"),
}


--- 解锁效果
---@field _Control XRestaurantControl
local XUiGridEffect = XClass(XUiNode, "XUiGridEffect")

function XUiGridEffect:Refresh(data)
    local type = data.Type
    local desc = self._Control:GetRestaurantLvUpEffectText(type)
    local count = data.Count
    self.TxtDesc.text = desc
    local countStr = type == XMVCA.XRestaurant.EffectType.HotSaleAddition and count.."%" or count
    self.TxtCount.text = countStr
    self.TxtCount.color = data.SubCount > 0 and ColorEnum.Changed or ColorEnum.UnChanged
end

--- 解锁产品
---@field _Control XRestaurantControl
local XUiGridProduct = XClass(XUiNode, "XUiGridProduct")

function XUiGridProduct:OnStart()
    self.BtnLock.CallBack = function() 
        self:OnBtnLockClick()
    end
end

function XUiGridProduct:Refresh(data)
    self.AreaType, self.ProductId = data.AreaType, data.Id
    local product = self._Control:GetProduct(data.AreaType, data.Id)

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
    self.TxtName.text = product:GetName()
end

function XUiGridProduct:OnBtnLockClick()
    local productId = self.ProductId
    if not XTool.IsNumberValid(productId) then
        return
    end
    local food = self._Control:GetProduct(self.AreaType, productId)
    if food:IsUnlock() then
        return
    end
    local performId = food:GetPerformId()
    local perform = self._Control:GetPerform(performId)
    if perform:IsNotStart() then
        XUiManager.TipMsg(perform:GetUnlockText())
        return
    end
    self._Control:DoClickLockPerform(performId, function()
        self.Parent:Close()
    end)
end

--- 升级条件
---@field _Control XRestaurantControl
local XUiGridCondition = XClass(XUiNode, "XUiGridCondition")


function XUiGridCondition:Refresh(data)
    self.ImgGou.gameObject:SetActiveEx(data.Finish)
    self.TxtContent.text = data.Text
end

local XUiGridRestaurantStory = XClass(XUiNode, "XUiGridRestaurantStory")

function XUiGridRestaurantStory:OnStart()
    self.BtnClick = self.Transform:GetComponent("XUiButton")
    self.BtnClick.CallBack = function() 
        self:OnBtnClick()
    end
end

function XUiGridRestaurantStory:Refresh(data)
    self.PerformId = data
    ---@type XRestaurantControl
    local control = self._Control
    local perform = control:GetPerform(data)
    if not perform then
        self:Close()
        return
    end
    local isUnlock = not perform:IsNotStart()
    self.PanelNormal.gameObject:SetActiveEx(isUnlock)
    self.PanelLock.gameObject:SetActiveEx(not isUnlock)
    if isUnlock then
        self.TxtName.text = perform:GetPerformTitle()
    end
    self.RImgIcon:SetRawImage(perform:GetPerformTypeIcon())
end

function XUiGridRestaurantStory:OnBtnClick()
    self._Control:DoClickLockPerform(self.PerformId, function() 
        self.Parent:Close()
    end)
end

local XUiGridRestaurantReward = XClass(XUiNode, "XUiGridRestaurantReward")

function XUiGridRestaurantReward:OnStart()
    self.Grid = XUiGridCommon.New(self.Parent, self.Transform)
end

function XUiGridRestaurantReward:Refresh(data)
    self.Grid:Refresh(data)
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
    if self.Level <= self.CurLevel and self.Level ~= XMVCA.XRestaurant.RestLevelRange.Max then
        return self._Control:GetRestaurantLvUpConditionText(3)
    elseif self.CurLevel >= XMVCA.XRestaurant.RestLevelRange.Max then
        return self._Control:GetRestaurantLvUpConditionText(4)
    else
        return self._Control:GetRestaurantLvUpConditionText(6)
    end
end


---@class XUiRestaurantHire : XLuaUi
---@field _Control XRestaurantControl
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

function XUiRestaurantHire:OnEnable()
    self:UpdateView()
end

function XUiRestaurantHire:OnDestroy()
    self._Control:GetBusiness():ClearBind(self.GameObject:GetHashCode())
end

function XUiRestaurantHire:InitUi()
    ---@type XUiPanelRestaurantLevelUp
    self.PanelEffectLevelUp = XUiPanelRestaurantLevelUp.New(self.PanelFunction, self, XUiGridEffect)
    ---@type XUiPanelRestaurantLevelUp
    self.PanelFoodLevelUp = XUiPanelRestaurantLevelUp.New(self.PanelFood, self, XUiGridProduct)
    ---@type XUiPanelCondition
    self.PanelConditionLevelUp = XUiPanelCondition.New(self.PanelCondition, self, XUiGridCondition)
    ---@type XUiPanelRestaurantLevelUp
    self.PanelStoryLevelUp = XUiPanelRestaurantLevelUp.New(self.PanelStory, self, XUiGridRestaurantStory)
    ---@type XUiPanelRestaurantLevelUp
    self.PanelRewardLevelUp = XUiPanelRestaurantLevelUp.New(self.PanelReward, self, XUiGridRestaurantReward)
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
    
    self.Level = self._Control:GetRestaurantLv()
    self:InitLevelButton()
end 

function XUiRestaurantHire:UpdateView()
    self:SetupDynamicTable()
end

function XUiRestaurantHire:InitLevelButton()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTabGroup)
    self.DynamicTable:SetProxy(XUiGridLevelButton, self, handler(self, self.OnSelectLevel))
    self.DynamicTable:SetDelegate(self)
    self.GridLevel.gameObject:SetActiveEx(false)
end 

function XUiRestaurantHire:SetupDynamicTable()
    local list = {}
    local startIndex = self.Level
    local previewLevel = math.min(XMVCA.XRestaurant.RestLevelRange.Max, self.Level + PreviewLevel)
    for lv = XMVCA.XRestaurant.RestLevelRange.Min, previewLevel do
        table.insert(list, lv)
    end
    self.DataList = list
    
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataSync(startIndex)
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
    self.ImgRenovation:SetRawImage(self._Control:GetRestaurantDecorationIcon(self.SelectLevel))
    if self.ImgTitle then
        self.ImgTitle:SetSprite(self._Control:GetRestaurantTitleIcon(self.SelectLevel))
    elseif self.TxtLevel then
        self.TxtLevel.text = string.format("LV%s", self.SelectLevel)
    end
    local levelUpgrade = self._Control:GetUpgradeCondition(self.SelectLevel - 1)
    local conditionList = {}
    local effectList = self._Control:GetRestaurantUnlockEffectList(self.SelectLevel)
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
        conditionList = self._Control:GetRestaurantUnlockConditionList(levelUpgrade)
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
    
    self.PanelFoodLevelUp:Refresh(self:GetUnlockFoodIds(self.SelectLevel))
    
    self.PanelConditionLevelUp:Refresh(conditionList, self.SelectLevel, self.Level)
    
    local rewardId = self._Control:GetLvUpRewardId(self.SelectLevel)
    if rewardId > 0 then
        self.PanelRewardLevelUp:Open()
        self.PanelRewardLevelUp:Refresh(XRewardManager.GetRewardList(rewardId))
    else
        self.PanelRewardLevelUp:Close()
    end
   
    local performIds = self._Control:GetLvUpPerformIds(self.SelectLevel)
    self.PanelStoryLevelUp:Refresh(performIds)
end

function XUiRestaurantHire:OnBtnDetermineClick()
    if not self.AbleLevelUp then
        XUiManager.TipMsg(self._Control:GetRestaurantLvUpConditionText(5))
        return
    end
    local title, content = self._Control:GetRestaurantLvUpPopupTip()
    content = XUiHelper.ReplaceTextNewLine(string.format(content, self.Level, self.Level + 1))

    self._Control:OpenPopup(title, content, nil, nil, function()
        self._Control:RequestLevelUpRestaurant()
    end)
end 

function XUiRestaurantHire:GetUnlockFoodIds(level)
    local areaType = XMVCA.XRestaurant.AreaType.FoodArea
    local ids = self._Control:GetUnlockProductIdsByLevel(areaType, level)
    local list = {}
    for _, productId in ipairs(ids) do
        table.insert(list, {
            AreaType = areaType,
            Id = productId
        })
    end
    return list
end

function XUiRestaurantHire:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local selectLevel = self.DataList[index]
        local isUnlock = selectLevel <= self.Level
        grid:Refresh(selectLevel, self.Level, isUnlock, not isUnlock, 
                string.format("LV%s", selectLevel), self.SelectLevel)
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        local selectIndex = 1
        for idx, level in ipairs(self.DataList) do
            if level == self.Level then
                selectIndex = idx
                break
            end
        end
        local grids = self.DynamicTable:GetGrids()
        local gridLevel = grids[selectIndex]
        if gridLevel then
            gridLevel:OnBtnLevelClick()
        end
    end
end