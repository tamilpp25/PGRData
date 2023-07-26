local CSXTextManagerGetText = CS.XTextManager.GetText
local DescriptionTitle = CSXTextManagerGetText("EquipResonanceAwakeExplainTitle")
local Description = string.gsub(CSXTextManagerGetText("EquipResonanceAwakeExplain"), "\\n", "\n")
local XUiGridResonanceSkill = require("XUi/XUiEquipResonanceSkill/XUiGridResonanceSkill")

local CONDITION_COLOR = {
    [true] = CS.UnityEngine.Color.black,
    [false] = CS.UnityEngine.Color.gray,
}

local XUiEquipResonanceAwakeV2P6 = XLuaUiManager.Register(XLuaUi, "UiEquipResonanceAwakeV2P6")

function XUiEquipResonanceAwakeV2P6:OnAwake()
    self:SetButtonCallBack()
end

function XUiEquipResonanceAwakeV2P6:OnStart(parent, characterId, forceShowBindCharacter)
    self.Parent = parent
    self.CharacterId = characterId
    self.ForceShowBindCharacter = forceShowBindCharacter
end

function XUiEquipResonanceAwakeV2P6:OnGetEvents()
    return {
        XEventId.EVENT_EQUIP_AWAKE_NOTYFY,
        XEventId.EVENT_ITEM_FAST_TRADING,
    }
end

function XUiEquipResonanceAwakeV2P6:OnNotify(evt, ...)
    if evt == XEventId.EVENT_EQUIP_AWAKE_NOTYFY then
        local args = { ... }
        local equipId = args[1]
        local pos = args[2]
        if equipId ~= self.EquipId then return end
        if pos ~= self.Pos then return end
        
        XLuaUiManager.Open("UiEquipResonanceSelectAfter", self.EquipId, self.Pos, self.CharacterId, true, self.ForceShowBindCharacter, function()
            self.Parent:OnOverClockingSuccess(self.Pos, true)
        end)
    elseif evt == XEventId.EVENT_ITEM_FAST_TRADING then
        self:UpdateView()
    end
end

function XUiEquipResonanceAwakeV2P6:SetPos(equipId, pos)
    self.EquipId = equipId
    self.Pos = pos
    self.TemplateId = XDataCenter.EquipManager.GetEquipTemplateId(equipId)
    self:UpdateView()
end

function XUiEquipResonanceAwakeV2P6:UpdateView()
    self:UpdateResonanceSkill()
    self:UpdateConsumeCoin()
    self:UpdateConsumeItem()
end

function XUiEquipResonanceAwakeV2P6:UpdateResonanceSkill()
    local isawake = true
    self.TxtSlot.text = string.format("%02d", self.Pos)
    if not self.ResonanceSkillGrid then
        self.ResonanceSkillGrid = XUiGridResonanceSkill.New(self.GridResonanceSkill, self.EquipId, self.Pos)
    end
    self.ResonanceSkillGrid:SetEquipIdAndPos(self.EquipId, self.Pos, isawake)
    self.ResonanceSkillGrid:Refresh()

    -- 刷新意识套装的图
    local charId = XDataCenter.EquipManager.GetResonanceBindCharacterId(self.EquipId, self.Pos)
    local halfBodyImage = XDataCenter.CharacterManager.GetCharHalfBodyImage(charId)
    self.GridResonanceSkill:GetObject("RImgAwareness"):SetRawImage(halfBodyImage)
end

--@region 物品消耗列表
function XUiEquipResonanceAwakeV2P6:GetAwakeConsumeCoin()
    return XDataCenter.EquipManager.GetAwakeConsumeCrystalCoin(self.EquipId)
end

function XUiEquipResonanceAwakeV2P6:GetAwakeConsumeItemList()
    return XDataCenter.EquipManager.GetAwakeConsumeItemCrystalList(self.EquipId)
end

function XUiEquipResonanceAwakeV2P6:UpdateConsumeCoin()
    local equipId = self.EquipId

    local consumeCoin = self:GetAwakeConsumeCoin()
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

function XUiEquipResonanceAwakeV2P6:UpdateConsumeItem()
    local equipId = self.EquipId
    local itemList = self:GetAwakeConsumeItemList()

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
end
--@endregion


--@region 点击事件
function XUiEquipResonanceAwakeV2P6:SetButtonCallBack()
    self:RegisterClickEvent(self.BtnHelp, self.OnBtnHelpClick)
    self:RegisterClickEvent(self.BtnAwake, self.OnBtnAwakeClick)
end

function XUiEquipResonanceAwakeV2P6:OnBtnAwakeClick()
    local equipId = self.EquipId
    local pos = self.Pos
    local coinEnough, itemEnough, consumeCoin = self:CheckIsEnough()
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
        XMVCA:GetAgency(ModuleId.XEquip):Awake(equipId, pos, XEnumConst.EQUIP.AWAKE_CRYSTAL_MONEY)
    end)
end

function XUiEquipResonanceAwakeV2P6:OnBtnHelpClick()
    XUiManager.UiFubenDialogTip(DescriptionTitle, Description)
end
--@endregion


function XUiEquipResonanceAwakeV2P6:CheckIsEnough()
    local itemEnough = true
    local itemList = self:GetAwakeConsumeItemList()
    local consumeCoin = self:GetAwakeConsumeCoin()
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

return XUiEquipResonanceAwakeV2P6