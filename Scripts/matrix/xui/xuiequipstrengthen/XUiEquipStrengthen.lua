local CONDITION_COLOR = {
    [true] = CS.UnityEngine.Color.black,
    [false] = CS.UnityEngine.Color.gray
}

local XUiPanelExpBar = require("XUi/XUiSettleWinMainLine/XUiPanelExpBar")
local XUiGridEquipReplaceAttr = require("XUi/XUiEquipReplaceNew/XUiGridEquipReplaceAttr")
local XUiPanelEquipScroll = require("XUi/XUiEquipAwarenessReplace/XUiPanelEquipScroll")
local XUiGridEquipExpItem = require("XUi/XUiEquipStrengthen/XUiGridEquipExpItem")

local mathMax = math.max
local mathFloor = math.floor
local next = next
local CSXTextManagerGetText = CS.XTextManager.GetText

local BtnTabIndex = {
    Equips = 1,
    Items = 2
}

local XUiEquipStrengthen = XLuaUiManager.Register(XLuaUi, "UiEquipStrengthen")

function XUiEquipStrengthen:OnAwake()
    self:AutoAddListener()

    self.GridEquip.gameObject:SetActiveEx(false)
    self.GridEquipReplaceAttr.gameObject:SetActiveEx(false)
    self.GridExpItem.gameObject:SetActiveEx(false)
    self.BtnAllSelect.gameObject:SetActiveEx(
        not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.EquipStrengthenAutoSelect)
    )
    self.BtnQuick.gameObject:SetActiveEx(
        not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.EquipQuick)
    )
    self.PanelTabBtns:Init(
        {
            self.BtnEquips,
            self.BtnItems
        },
        function(tabIndex)
            self:OnClickTabCallBack(tabIndex)
        end
    )
end

function XUiEquipStrengthen:OnStart(equipId, rootUi)
    self.EquipId = equipId
    self.RootUi = rootUi
    self.IsAscendOrder = true --初始升序
    self.SelectedTabIndex =
        XDataCenter.EquipManager.IsStrengthenDefaultUseEquip(equipId) and BtnTabIndex.Equips or BtnTabIndex.Items

    self:InitEquipScroll()
    self:InitItemScroll()
    self:InitEquipAttr()
end

function XUiEquipStrengthen:OnEnable(equipId, rootUi)
    self.EquipId = equipId or self.EquipId
    self.PanelTabBtns:SelectIndex(self.SelectedTabIndex)
    self.BtnQuick:SetDisable(not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.EquipQuick))
    self:UpdateView()
    self:PlayAnimation("PaneCommon")
end

function XUiEquipStrengthen:OnGetEvents()
    return {
        XEventId.EVENT_EQUIP_STRENGTHEN_NOTYFY,
        XEventId.EVENT_EQUIP_BREAKTHROUGH_NOTYFY
    }
end

function XUiEquipStrengthen:OnNotify(evt, ...)
    local args = {...}
    local equipId = args[1]
    if equipId ~= self.EquipId then
        return
    end

    if evt == XEventId.EVENT_EQUIP_STRENGTHEN_NOTYFY then
        if XDataCenter.EquipManager.CanBreakThrough(self.EquipId) then
            return
        end

        if XDataCenter.EquipManager.IsMaxLevel(self.EquipId) then
            return
        end

        self:UpdateView()
    elseif evt == XEventId.EVENT_EQUIP_BREAKTHROUGH_NOTYFY then
        self:Close()
    end
end

function XUiEquipStrengthen:OnClickTabCallBack(tabIndex)
    if tabIndex == self.SelectedTabIndex then
        return
    end
    self.SelectedTabIndex = tabIndex

    self:UpdateView()
end

function XUiEquipStrengthen:UpdateView()
    self:ResetSelectedData()
    self:UpdateViewData()
    self:UpdateScrollView()
    self:UpdateEquipInfo()
    self:UpdateEquipPreView()
end

function XUiEquipStrengthen:InitEquipAttr()
    self.AttrGridList = {}
    local curAttrMap = XDataCenter.EquipManager.GetEquipAttrMap(self.EquipId)
    for attrIndex, attrInfo in pairs(curAttrMap) do
        local ui = CS.UnityEngine.Object.Instantiate(self.GridEquipReplaceAttr)
        self.AttrGridList[attrIndex] = XUiGridEquipReplaceAttr.New(ui, attrInfo.Name, true)
        self.AttrGridList[attrIndex].Transform:SetParent(self.PanelAttrParent, false)
        self.AttrGridList[attrIndex].GameObject:SetActiveEx(true)
    end
    self.ExpBar = XUiPanelExpBar.New(self.PanelExpBar)
end

function XUiEquipStrengthen:InitEquipScroll()
    local equipTouchCb = function(equipId, isSelect)
        self:OnSelectEquip(equipId, isSelect)
    end

    local gridReloadCb = function()
        self.BtnOrder.enabled = true
    end

    local addCountCheckCb = function()
        return self:CheckCanSelect()
    end

    self.EquipScroll =
        XUiPanelEquipScroll.New(self.PanelEquipScroll, self, equipTouchCb, gridReloadCb, true, addCountCheckCb)
end

function XUiEquipStrengthen:InitItemScroll()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemScroll)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridEquipExpItem)
end

function XUiEquipStrengthen:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        local addCountCb = function(itemId, addCount)
            self:OnSelectItem(itemId, addCount)
        end

        local addCountCheckCb = function(doNotTip)
            return self:CheckCanSelect(doNotTip)
        end

        grid:Init(self, addCountCb, addCountCheckCb)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local itemId = self.ItemIdList[index]
        local selectCount = self.SelectItemDic[itemId] or 0
        grid:Refresh(itemId, selectCount)
    end
end

function XUiEquipStrengthen:UpdateViewData()
    if self:IsEquipView() then
        local equipIdList = XDataCenter.EquipManager.GetCanEatEquipIds(self.EquipId)
        self.EquipIdList = not self.IsAscendOrder and XTool.ReverseList(equipIdList) or equipIdList
    elseif self:IsItemView() then
        self.ItemIdList = XDataCenter.EquipManager.GetCanEatItemIds(self.EquipId)
    end
end

function XUiEquipStrengthen:UpdateScrollView()
    if self:IsEquipView() then
        self.BtnOrder.gameObject:SetActiveEx(true)
        self.EquipScroll:UpdateEquipGridList(self.EquipIdList)
        self.EquipScroll.GameObject:SetActiveEx(true)
        self.PanelItemScroll.gameObject:SetActiveEx(false)
    elseif self:IsItemView() then
        self.BtnOrder.gameObject:SetActiveEx(false)
        self.DynamicTable:SetDataSource(self.ItemIdList)
        self.DynamicTable:ReloadDataSync()
        self.PanelItemScroll.gameObject:SetActiveEx(true)
        self.EquipScroll.GameObject:SetActiveEx(false)
    end
end

function XUiEquipStrengthen:UpdateEquipInfo()
    local equipId = self.EquipId
    local equip = XDataCenter.EquipManager.GetEquip(equipId)
    local maxExp = XDataCenter.EquipManager.GetNextLevelExp(equipId)
    local curLv = equip.Level
    local maxLv = XDataCenter.EquipManager.GetBreakthroughLevelLimit(equipId)

    for _, grid in pairs(self.AttrGridList) do
        grid:UpdateData()
    end

    self.TxtCurLv.text = CSXTextManagerGetText("EquipStrengthenCurLevel", curLv, maxLv)
    self.TxtExp.text = mathFloor(equip.Exp) .. "/" .. maxExp
    self.TxtPreExp.gameObject:SetActiveEx(false)
    self.ImgPlayerExpFill.fillAmount = equip.Exp / maxExp

    local curAttrMap = XDataCenter.EquipManager.GetEquipAttrMap(self.EquipId)
    for attrIndex, attrInfo in pairs(curAttrMap) do
        if self.AttrGridList[attrIndex] then
            self.AttrGridList[attrIndex]:UpdateData(attrInfo.Value, nil, nil, attrInfo.Name)
        end
    end

    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.PanelLevel)
end

function XUiEquipStrengthen:UpdateEquipPreView()
    local equipId = self.EquipId
    local preLevel = self.PreLevel
    local preExp = self.PreExp
    local totalAddExp = self.TotalAddExp

    local maxLv = XDataCenter.EquipManager.GetBreakthroughLevelLimit(equipId)
    self.TxtCurLv.text = CSXTextManagerGetText("EquipStrengthenCurLevel", preLevel, maxLv)

    if preExp == 0 then
        self.ImgPlayerExpFill.gameObject:SetActiveEx(false)
    else
        local equip = XDataCenter.EquipManager.GetEquip(equipId)
        if equip.Level ~= preLevel then
            self.ImgPlayerExpFill.gameObject:SetActiveEx(false)
        else
            self.ImgPlayerExpFill.gameObject:SetActiveEx(true)
        end
    end
    local maxExp = XDataCenter.EquipManager.GetNextLevelExp(equipId, preLevel)
    self.TxtExp.text = mathFloor(preExp) .. "/" .. maxExp
    self.ImgPlayerExpFillAdd.fillAmount = preExp / maxExp

    local addExp = mathFloor(totalAddExp)
    if addExp > 0 then
        self.TxtPreExp.text = "+" .. addExp
        self.TxtPreExp.gameObject:SetActiveEx(true)
    else
        self.TxtPreExp.gameObject:SetActiveEx(false)
    end

    local preAttrMap = XDataCenter.EquipManager.GetEquipAttrMap(equipId, preLevel)
    for attrIndex, attrInfo in pairs(preAttrMap) do
        if self.AttrGridList[attrIndex] then
            self.AttrGridList[attrIndex]:UpdateData(nil, attrInfo.Value, true, attrInfo.Name)
        end
    end

    if self:IsEquipView() then
        local costMoney = XDataCenter.EquipManager.GetEatEquipsCostMoney(self.SelectEquipIds)
        self.TxtCost.text = costMoney
        self.TxtCost.color = CONDITION_COLOR[XDataCenter.ItemManager.GetCoinsNum() >= costMoney]

        local canStrengthen = next(self.SelectEquipIds)
        self.BtnStrengthen:SetDisable(not canStrengthen)
    elseif self:IsItemView() then
        local costMoney = XDataCenter.EquipManager.GetEatItemsCostMoney(self.SelectItemDic)
        self.TxtCost.text = costMoney
        self.TxtCost.color = CONDITION_COLOR[XDataCenter.ItemManager.GetCoinsNum() >= costMoney]

        local canStrengthen = next(self.SelectItemDic)
        self.BtnStrengthen:SetDisable(not canStrengthen)
    end
end

function XUiEquipStrengthen:CheckCanSelect(doNotTip)
    local preLevel = self.PreLevel
    local limitLevel = XDataCenter.EquipManager.GetBreakthroughLevelLimit(self.EquipId)
    if preLevel >= limitLevel then
        if not doNotTip then
            XUiManager.TipMsg(CSXTextManagerGetText("EquipStrengthenMaxLevel"))
        end
        return false
    else
        return true
    end
end

function XUiEquipStrengthen:OnSelectEquip(equipId, isSelect)
    --取消选中直接刷新UI缓存
    local count = 1
    if isSelect then
        self.SelectEquipIds[equipId] = true
    else
        count = -1
        self.SelectEquipIds[equipId] = nil
    end

    local addExp = XDataCenter.EquipManager.GetEquipAddExp(equipId, count)
    self.PreLevel, self.TotalAddExp, self.PreExp = self:GetStrengthenPreData(addExp)
    self:UpdateEquipPreView()
end

function XUiEquipStrengthen:OnSelectItem(itemId, addCount)
    local selectItemDic = self.SelectItemDic
    local oldCount = selectItemDic[itemId] or 0
    local newCount = mathMax(0, oldCount + addCount)
    selectItemDic[itemId] = newCount > 0 and newCount or nil

    local addExp = XDataCenter.ItemManager.GetItemsAddEquipExp(itemId, addCount)
    self.PreLevel, self.TotalAddExp, self.PreExp = self:GetStrengthenPreData(addExp)
    self:UpdateEquipPreView()
end

function XUiEquipStrengthen:AutoAddListener()
    self:RegisterClickEvent(self.BtnOrder, self.OnBtnOrderClick)
    self:RegisterClickEvent(self.BtnStrengthen, self.OnBtnStrengthenClick)
    self:RegisterClickEvent(self.BtnSource, self.OnBtnSourceClick)
    self:RegisterClickEvent(self.BtnAllSelect, self.OnBtnAllSelectClick)
    self.BtnQuick.CallBack = handler(self, self.OnClickBtnQuick)
end

function XUiEquipStrengthen:OnClickBtnQuick()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.EquipQuick) then
        return
    end

    XLuaUiManager.Open("UiEquipCulture", self.EquipId)
end

function XUiEquipStrengthen:OnBtnOrderClick()
    self.IsAscendOrder = not self.IsAscendOrder
    XTool.ReverseList(self.EquipIdList)

    self.BtnOrder.enabled = false
    self.ImgAscend.gameObject:SetActiveEx(self.IsAscendOrder)
    self.ImgDescend.gameObject:SetActiveEx(not self.IsAscendOrder)

    self:ResetSelectedData()
    self:UpdateEquipPreView()
    self:UpdateScrollView()
end

function XUiEquipStrengthen:OnBtnStrengthenClick()
    local equipId = self.EquipId
    local equip = XDataCenter.EquipManager.GetEquip(equipId)

    local lastLevel = equip.Level
    local lastExp = equip.Exp
    local lastMaxExp = XDataCenter.EquipManager.GetNextLevelExp(equipId, lastLevel)
    local curLevel = self.PreLevel
    local curExp = self.PreExp
    local curMaxExp = XDataCenter.EquipManager.GetNextLevelExp(equipId, curLevel)
    XMVCA:GetAgency(ModuleId.XEquip):LevelUp(
        self.EquipId,
        self.SelectEquipIds,
        self.SelectItemDic,
        function()
            self.ExpBar:SkipRoll(lastLevel, lastExp, lastMaxExp, curLevel, curExp, curMaxExp)
        end
    )
end

function XUiEquipStrengthen:OnBtnSourceClick()
    local eatType = self:IsEquipView() and XEquipConfig.EatType.Equip or XEquipConfig.EatType.Item
    local skipIds = XDataCenter.EquipManager.GetEquipEatSkipIds(eatType, self.EquipId)
    XLuaUiManager.Open("UiEquipStrengthenSkip", skipIds)
end

function XUiEquipStrengthen:OnBtnAllSelectClick()
    if self:IsEquipView() then
        self:AutoSelectEquips()
    elseif self:IsItemView() then
        self:AutoSelectItems()
    end
end

function XUiEquipStrengthen:IsEquipView()
    return self.SelectedTabIndex == BtnTabIndex.Equips
end

function XUiEquipStrengthen:IsItemView()
    return self.SelectedTabIndex == BtnTabIndex.Items
end

function XUiEquipStrengthen:ResetSelectedData()
    local equip = XDataCenter.EquipManager.GetEquip(self.EquipId)
    self.PreLevel = equip.Level
    self.TotalAddExp = 0
    self.PreExp = equip.Exp
    self.SelectEquipIds = {}
    self.SelectItemDic = {}
end

function XUiEquipStrengthen:GetStrengthenPreData(addExp)
    local equipId = self.EquipId
    local equip = XDataCenter.EquipManager.GetEquip(equipId)

    local preLevel = equip.Level
    local totalAddExp = self.TotalAddExp + addExp
    local preExp = totalAddExp + equip.Exp

    local limitLevel = XDataCenter.EquipManager.GetBreakthroughLevelLimit(equipId)
    while true do
        local nextExp = XDataCenter.EquipManager.GetNextLevelExp(equipId, preLevel)
        if preExp < nextExp then
            break
        end

        preExp = preExp - nextExp
        preLevel = preLevel + 1

        --超出需要吃的装备个数范围检测
        if preLevel >= limitLevel then
            preLevel = limitLevel
            preExp = 0
            return preLevel, totalAddExp, preExp
        end
    end

    return preLevel, totalAddExp, preExp
end

function XUiEquipStrengthen:AutoSelectEquips()
    local recommendEatEquipIds = XDataCenter.EquipManager.GetRecomendEatEquipIds(self.EquipId)
    if not next(recommendEatEquipIds) then
        XUiManager.TipText("EquipStrengthenAutoSelectEmpty")
        return
    end

    local equipScroll = self.EquipScroll
    equipScroll:ResetSelectGrids()
    self:ResetSelectedData()

    local equipId = self.EquipId
    local equipIds = {}
    local preLevel, totalAddExp, preExp
    local doNotTip = true
    for _, costEquipId in ipairs(recommendEatEquipIds) do
        local addExp = XDataCenter.EquipManager.GetEquipAddExp(costEquipId)
        preLevel, totalAddExp, preExp = self:GetStrengthenPreData(addExp)
        if not self:CheckCanSelect(doNotTip) then
            break
        end

        self.PreLevel, self.TotalAddExp, self.PreExp = preLevel, totalAddExp, preExp
        equipIds[costEquipId] = true
        self.SelectEquipIds[costEquipId] = true
    end

    local limitLevel = XDataCenter.EquipManager.GetBreakthroughLevelLimit(equipId)
    local totalNeedExp = XDataCenter.EquipManager.GetEquipLevelTotalNeedExp(equipId, limitLevel)
    totalAddExp = self.TotalAddExp
    for _, costEquipId in ipairs(recommendEatEquipIds) do
        local addExp = XDataCenter.EquipManager.GetEquipAddExp(costEquipId)
        addExp = -addExp
        if totalAddExp + addExp < totalNeedExp then
            break
        end
        preLevel, totalAddExp, preExp = self:GetStrengthenPreData(addExp)

        self.PreLevel, self.TotalAddExp, self.PreExp = preLevel, totalAddExp, preExp
        equipIds[costEquipId] = nil
        self.SelectEquipIds[costEquipId] = nil
    end

    equipScroll:SelectGrids(equipIds)
    self:UpdateEquipPreView()
end

function XUiEquipStrengthen:AutoSelectItems()
    local recommendEatItemIds = self.ItemIdList
    if not next(recommendEatItemIds) then
        XUiManager.TipText("EquipStrengthenAutoSelectEmpty")
        return
    end

    self:ResetSelectedData()

    local equipId = self.EquipId
    local costItemCount
    local preLevel, totalAddExp, preExp, addExp
    local doNotTip = true
    for _, costItemId in ipairs(recommendEatItemIds) do
        costItemCount = XDataCenter.ItemManager.GetCount(costItemId)
        for costCount = 1, costItemCount do
            addExp = XDataCenter.ItemManager.GetItemsAddEquipExp(costItemId, 1)
            preLevel, totalAddExp, preExp = self:GetStrengthenPreData(addExp)
            if not self:CheckCanSelect(doNotTip) then
                break
            end

            self.PreLevel, self.TotalAddExp, self.PreExp = preLevel, totalAddExp, preExp
            self.SelectItemDic[costItemId] = costCount > 0 and costCount or nil
        end
    end

    local limitLevel = XDataCenter.EquipManager.GetBreakthroughLevelLimit(equipId)
    local totalNeedExp = XDataCenter.EquipManager.GetEquipLevelTotalNeedExp(equipId, limitLevel)
    local selectCount
    totalAddExp = self.TotalAddExp
    for _, costItemId in ipairs(recommendEatItemIds) do
        costItemCount = XDataCenter.ItemManager.GetCount(costItemId)
        for _ = 1, costItemCount do
            addExp = XDataCenter.ItemManager.GetItemsAddEquipExp(costItemId, -1)
            if totalAddExp + addExp < totalNeedExp then
                break
            end
            preLevel, totalAddExp, preExp = self:GetStrengthenPreData(addExp)

            self.PreLevel, self.TotalAddExp, self.PreExp = preLevel, totalAddExp, preExp
            selectCount = self.SelectItemDic[costItemId] or 0
            selectCount = selectCount - 1
            self.SelectItemDic[costItemId] = selectCount > 0 and selectCount or nil
        end
    end

    self:UpdateEquipPreView()
    self:UpdateScrollView()
end
