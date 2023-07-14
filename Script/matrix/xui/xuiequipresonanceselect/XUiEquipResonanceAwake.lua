local CSXTextManagerGetText = CS.XTextManager.GetText
local DescriptionTitle = CSXTextManagerGetText("EquipResonanceAwakeExplainTitle")
local Description = string.gsub(CSXTextManagerGetText("EquipResonanceAwakeExplain"), "\\n", "\n")
local XUiGridResonanceSkill = require("XUi/XUiEquipResonanceSkill/XUiGridResonanceSkill")

local CONDITION_COLOR = {
    [true] = CS.UnityEngine.Color.black,
    [false] = CS.UnityEngine.Color.gray,
}

local TOG_STATE = {
    NORMAL = 0,
    SELECT = 2,
}

local XUiEquipResonanceAwake = XLuaUiManager.Register(XLuaUi, "UiEquipResonanceAwake")

function XUiEquipResonanceAwake:OnAwake()
    self:AutoAddListener()
end

function XUiEquipResonanceAwake:OnStart(equipId, rootUi)
    self.EquipId = equipId
    self.RootUi = rootUi
end

function XUiEquipResonanceAwake:OnEnable(equipId)
    self.EquipId = equipId or self.EquipId
    self:SetTogRedPoint()
    self:UpdateTogButtonState()
    self:UpdateResonanceSkill()
    self:UpdateConsumeCoin()
    self:UpdateConsumeItem()
end

function XUiEquipResonanceAwake:OnGetEvents()
    return {
        XEventId.EVENT_EQUIP_AWAKE_NOTYFY,
        XEventId.EVENT_ITEM_FAST_TRADING,
    }
end

function XUiEquipResonanceAwake:OnNotify(evt, ...)
    if evt == XEventId.EVENT_EQUIP_AWAKE_NOTYFY then
        local args = { ... }
        local equipId = args[1]
        local pos = args[2]
        if equipId ~= self.EquipId then return end
        if pos ~= self.Pos then return end
        
        self.RootUi:FindChildUiObj("UiEquipResonanceSkill").UiProxy:SetActive(true)
        self.UiProxy:SetActive(false)
        local isAwakeDes = true
        local forceShowBindCharacter = self.RootUi.ForceShowBindCharacter
        XLuaUiManager.Open("UiEquipResonanceSelectAfter", self.EquipId, self.Pos, self.RootUi.CharacterId, isAwakeDes, forceShowBindCharacter)
    elseif evt == XEventId.EVENT_ITEM_FAST_TRADING then
        self:UpdateResonanceSkill()
        self:UpdateConsumeCoin()
        self:UpdateConsumeItem()
    end
end

function XUiEquipResonanceAwake:Refresh(pos)
    self.Pos = pos
end

function XUiEquipResonanceAwake:UpdateResonanceSkill()
    local isawake = true
    self.TxtSlot.text = string.format("%02d", self.Pos)
    self.ResonanceSkillGrid = self.ResonanceSkillGrid or XUiGridResonanceSkill.New(self.GridResonanceSkill, self.EquipId, self.Pos)
    self.ResonanceSkillGrid:SetEquipIdAndPos(self.EquipId, self.Pos, isawake)
    self.ResonanceSkillGrid:Refresh()
    self.ResonanceSkillGrid.GameObject:SetActiveEx(true)
end

--@region 物品消耗列表
function XUiEquipResonanceAwake:GetAwakeConsumeCoin(equipAwakeTabIndex)
    if equipAwakeTabIndex == XEquipConfig.EquipAwakeTabIndex.Material then
        return XDataCenter.EquipManager.GetAwakeConsumeCoin(self.EquipId)
    elseif equipAwakeTabIndex == XEquipConfig.EquipAwakeTabIndex.CrystalMoney then
        return XDataCenter.EquipManager.GetAwakeConsumeCrystalCoin(self.EquipId)
    end
end

function XUiEquipResonanceAwake:GetAwakeConsumeItemList(equipAwakeTabIndex)
    if equipAwakeTabIndex == XEquipConfig.EquipAwakeTabIndex.Material then
        return XDataCenter.EquipManager.GetAwakeConsumeItemList(self.EquipId)
    elseif equipAwakeTabIndex == XEquipConfig.EquipAwakeTabIndex.CrystalMoney then
        return XDataCenter.EquipManager.GetAwakeConsumeItemCrystalList(self.EquipId)
    end
end

function XUiEquipResonanceAwake:UpdateConsumeCoin()
    local equipId = self.EquipId

    local consumeCoin = self:GetAwakeConsumeCoin(XEquipConfig.GetEquipAwakeTabIndex())
    if consumeCoin == 0 then
        self.PanelCostCoin.gameObject:SetActiveEx(false)
    else
        self.TxtCostCoin.text = consumeCoin
        self.PanelCostCoin.gameObject:SetActiveEx(true)
    end

    local ownItemCount = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.Coin)
    local coinEnough = ownItemCount >= consumeCoin
    self.TxtCostCoin.color = CONDITION_COLOR[coinEnough]
end

function XUiEquipResonanceAwake:UpdateConsumeItem()
    local equipId = self.EquipId
    local itemList = self:GetAwakeConsumeItemList(XEquipConfig.GetEquipAwakeTabIndex())

    if next(itemList) then
        self.ConsumeItem = self.ConsumeItem or {}
        local length = #self.ConsumeItem > #itemList and #self.ConsumeItem or #itemList
        for index=1,length do
            local itemInfo = itemList[index]
            if itemInfo then
                local itemId = itemInfo.ItemId
                local needCount = itemInfo.Count
                local haveCount = XDataCenter.ItemManager.GetCount(itemId)
                local consumeItemInfo = {
                    TemplateId = itemId,
                    Count = haveCount,
                    CostCount = needCount,
                }

                self.ConsumeItem[index] = self.ConsumeItem[index] or XUiGridCommon.New(self, CS.UnityEngine.Object.Instantiate(self.GridCostItem))
                self.ConsumeItem[index].Transform:SetParent(self.PanelCostItem, false)
                self.ConsumeItem[index]:Refresh(consumeItemInfo)
                self.ConsumeItem[index].GameObject:SetActiveEx(true)
            else
                if self.ConsumeItem[index] then
                    self.ConsumeItem[index].GameObject:SetActiveEx(false)
                end
            end
        end

        self.PanelCostItem.gameObject:SetActiveEx(true)
    else
        self.PanelCostItem.gameObject:SetActiveEx(false)
    end

    self.GridCostItem.gameObject:SetActiveEx(false)

    local imageRedPoint = self:GetImgRedPoint(XEquipConfig.GetEquipAwakeTabIndex())
    imageRedPoint.gameObject:SetActiveEx(false)
end
--@endregion


--@region 点击事件
function XUiEquipResonanceAwake:AutoAddListener()
    self:RegisterClickEvent(self.BtnHelp, self.OnBtnHelpClick)
    self.BtnAwake.CallBack = function() self:OnBtnAwakeClick() end
    self.TogConsumeType.CallBack = function(value) self:OnTogConsumeTypeClick(value, true) end
end

function XUiEquipResonanceAwake:OnBtnAwakeClick()
    local equipId = self.EquipId
    local pos = self.Pos
    local coinEnough, itemEnough, consumeCoin = self:CheckIsEnough(XEquipConfig.GetEquipAwakeTabIndex())

    if not coinEnough then
        local closeCb = function ()
            self:UpdateConsumeCoin()
            self:OnBtnAwakeClick()
        end
        if not XDataCenter.ItemManager.DoNotEnoughBuyAsset(XDataCenter.ItemManager.ItemId.Coin, consumeCoin, 1, closeCb, "EquipAwakenCoinNotEnough") then
            return
        end
    end

    if not itemEnough then
        XUiManager.TipText("EquipAwakenItemNotEnough")
        return
    end

    local title = CSXTextManagerGetText("EquipAwakeTipTitle")
    local bindCharacterId = XDataCenter.EquipManager.GetResonanceBindCharacterId(equipId, pos)
    local name = XCharacterConfigs.GetCharacterTradeName(bindCharacterId)
    local content = CSXTextManagerGetText("EquipAwakeTipContent", name)
    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, function()
        XDataCenter.EquipManager.Awake(equipId, pos, XEquipConfig.GetEquipAwakeTabIndex())
    end)
end

function XUiEquipResonanceAwake:OnBtnHelpClick()
    XUiManager.UiFubenDialogTip(DescriptionTitle, Description)
end

function XUiEquipResonanceAwake:OnTogConsumeTypeClick(value, doTip)
    XEquipConfig.SetEquipAwakeTabIndex(value == 0 and XEquipConfig.EquipAwakeTabIndex.Material or XEquipConfig.EquipAwakeTabIndex.CrystalMoney)

    self:UpdateConsumeCoin()
    self:UpdateConsumeItem()
end
--@endregion

function XUiEquipResonanceAwake:UpdateTogButtonState()
    if XEquipConfig.GetEquipAwakeTabIndex() == XEquipConfig.EquipAwakeTabIndex.Material then
        self.TogConsumeType:SetButtonState(TOG_STATE.NORMAL)
    else
        self.TogConsumeType:SetButtonState(TOG_STATE.SELECT)
    end
end

function XUiEquipResonanceAwake:UpdateTogButtonState()
    if XEquipConfig.GetEquipAwakeTabIndex() == XEquipConfig.EquipAwakeTabIndex.Material then
        self.TogConsumeType:SetButtonState(TOG_STATE.NORMAL)
    else
        self.TogConsumeType:SetButtonState(TOG_STATE.SELECT)
    end
end

function XUiEquipResonanceAwake:SetTogRedPoint()
    local coinEnough, itemEnough, consumeCoin = self:CheckIsEnough(XEquipConfig.EquipAwakeTabIndex.CrystalMoney)
    self.ImgRedPointCrystal.gameObject:SetActiveEx(coinEnough and itemEnough)
    
    local coinEnough, itemEnough, consumeCoin = self:CheckIsEnough(XEquipConfig.EquipAwakeTabIndex.Material)
    self.ImgRedPointMaterials.gameObject:SetActiveEx(coinEnough and itemEnough)
end

function XUiEquipResonanceAwake:GetImgRedPoint(equipAwakeTabIndex)
    if equipAwakeTabIndex == XEquipConfig.EquipAwakeTabIndex.Material then
        return self.ImgRedPointMaterials
    else
        return self.ImgRedPointCrystal
    end
end

function XUiEquipResonanceAwake:CheckIsEnough(equipAwakeTabIndex)
    local itemEnough = true
    local itemList = self:GetAwakeConsumeItemList(equipAwakeTabIndex)
    local consumeCoin = self:GetAwakeConsumeCoin(equipAwakeTabIndex)
    local ownItemCount = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.Coin)
    local coinEnough = ownItemCount >= consumeCoin

    for index=1,#itemList do
        local itemInfo = itemList[index]
        local itemId = itemInfo.ItemId
        local needCount = itemInfo.Count
        local haveCount = XDataCenter.ItemManager.GetCount(itemId)
        if haveCount < needCount then
            itemEnough = false
            break
        end
    end

    return itemEnough, coinEnough, consumeCoin
end