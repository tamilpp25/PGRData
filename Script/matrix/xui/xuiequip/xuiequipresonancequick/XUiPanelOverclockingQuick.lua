local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiPanelOverclockingQuick = XClass(XUiNode, "XUiPanelOverclockingQuick")

function XUiPanelOverclockingQuick:OnStart()
    self.GridCostItem.gameObject:SetActiveEx(false)
    self:InitPanelAwareness()
    self:SetButtonCallBack()
    self:AddEventListener()
end

function XUiPanelOverclockingQuick:OnDestroy()
    self:RemoveEventListener()
end

function XUiPanelOverclockingQuick:AddEventListener()
    self.ListenerItemId = {
        XDataCenter.ItemManager.ItemId.Coin,
        XDataCenter.ItemManager.ItemId.EquipAwakeCoin1,
        XDataCenter.ItemManager.ItemId.EquipAwakeCoin2,
    }

    for _, itemId in ipairs(self.ListenerItemId) do
        XEventManager.AddEventListener(XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. itemId, self.RefreshCost, self)
    end
end

function XUiPanelOverclockingQuick:RemoveEventListener()
    for _, itemId in ipairs(self.ListenerItemId) do
        XEventManager.RemoveEventListener(XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. itemId, self.RefreshCost, self)
    end
    self.ListenerItemId = nil
end

function XUiPanelOverclockingQuick:SetButtonCallBack()
    self.Parent:RegisterClickEvent(self.BtnOverclocking, function() self:OnBtnOverclockingClick() end)
    self.Parent:RegisterClickEvent(self.BtnSelectAll, handler(self, self.OnBtnSelectAllClick))
end

function XUiPanelOverclockingQuick:OnBtnOverclockingClick()
    local awakeInfos = {}
    for _, grid in ipairs(self.GridAwarenessList) do
        local selPosList = grid:GetSelectPosList()
        if #selPosList > 0 then
            table.insert(awakeInfos, {EquipId = grid.EquipId, Slots = selPosList})
        end
    end

    -- 未选中超频技能
    if #awakeInfos == 0 then
        XUiManager.TipText("EquipAwakeSelectTips")
        return
    end
    
    -- 材料不够
    if not self.IsCostEnough then
        XUiManager.TipText("EquipAwakeCostTips")
        return
    end

    -- 二次确认框
    local title = XUiHelper.GetText("EquipAwakeTipTitle")
    local name = XMVCA.XCharacter:GetCharacterTradeName(self.CharacterId)
    local content = XUiHelper.GetText("EquipAwakeTipContent", name)
    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, function()
        self:RequestEquipQuickAwake(awakeInfos)
    end)
end

function XUiPanelOverclockingQuick:RequestEquipQuickAwake(awakeInfos)
    XMVCA.XEquip:RequestEquipQuickAwake(awakeInfos, function()
        self:Refresh(self.CharacterId)
    end)
end

function XUiPanelOverclockingQuick:Refresh(characterId)
    self.CharacterId = characterId
    self.SelAwarenessDic = {}
    
    self:RefreshPanelAwareness()
    self:RefreshCost()
end

function XUiPanelOverclockingQuick:InitPanelAwareness()
    self.GridAwarenessList = {}
    local CSInstantiate = CS.UnityEngine.Object.Instantiate
    local XUiGridAwareness = require("XUi/XUiEquip/XUiEquipResonanceQuick/XUiGridOverclockingAwareness")
    for site = 1, XEnumConst.EQUIP.WEAR_AWARENESS_COUNT do
        local go = site == 1 and self.GridAwareness or CSInstantiate(self.GridAwareness.gameObject, self.AwarenessList)
        local grid = XUiGridAwareness.New(go, self, self.Parent)
        table.insert(self.GridAwarenessList, grid)
    end
end

function XUiPanelOverclockingQuick:RefreshPanelAwareness()
    for site, grid in ipairs(self.GridAwarenessList) do
        grid:Refresh(self.CharacterId, site)
    end
end

function XUiPanelOverclockingQuick:RefreshCost()
    self.IsCostEnough = true
    local allItemDic = {}
    local allCoin = 0
    for _, grid in ipairs(self.GridAwarenessList) do
        local itemList, coinCnt = grid:GetCost()
        for _, item in pairs(itemList) do
            if allItemDic[item.ItemId] then
                allItemDic[item.ItemId].Count = allItemDic[item.ItemId].Count + item.Count
            else
                allItemDic[item.ItemId] = item
            end
        end
        allCoin = allCoin + coinCnt
    end
    local allItems = {}
    for _, item in pairs(allItemDic) do
        table.insert(allItems, item)
    end
    table.sort(allItems, function(a, b) 
        return a.ItemId < b.ItemId
    end)

    -- 未选中超频部位，补充0消耗的显示
    if #allItems == 0 then
        table.insert(allItems, { ItemId = XDataCenter.ItemManager.ItemId.EquipAwakeCoin1, Count = 0 })
        table.insert(allItems, { ItemId = XDataCenter.ItemManager.ItemId.EquipAwakeCoin2, Count = 0 })
    end

    -- 螺母
    local ownCnt = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.Coin)
    local isCoinEnough = ownCnt >= allCoin
    self.TxtCostCoin.text = tostring(allCoin)
    self.TxtCostCoin.color = isCoinEnough and CS.UnityEngine.Color.black or CS.UnityEngine.Color.red
    self.IsCostEnough = self.IsCostEnough and isCoinEnough

    -- 道具
    self.CostItems = self.CostItems or {}
    XUiHelper.CreateTemplates(self.Parent, self.CostItems, allItems, XUiGridCommon.New, self.GridCostItem.gameObject, self.PanelCostItem, function(grid, data)
        local consumeItemInfo = {
            TemplateId = data.ItemId,
            Count = XDataCenter.ItemManager.GetCount(data.ItemId),
            CostCount = data.Count,
        }
        grid.GameObject:SetActiveEx(true)
        grid:Refresh(consumeItemInfo)
        self.IsCostEnough = self.IsCostEnough and (consumeItemInfo.Count >= consumeItemInfo.CostCount)
    end)
end

function XUiPanelOverclockingQuick:OnSelectAwarenessChange()
    self:RefreshCost()
end

function XUiPanelOverclockingQuick:OnBtnSelectAllClick()
    if not XTool.IsTableEmpty(self.GridAwarenessList) then
        local anySelectSuccess = false
        for i, grid in pairs(self.GridAwarenessList) do
            if grid:TrySelectAllCanOverclockingPos() then
                anySelectSuccess = true
            end
        end

        if anySelectSuccess then
            self:OnSelectAwarenessChange()
        end
    end
end

return XUiPanelOverclockingQuick