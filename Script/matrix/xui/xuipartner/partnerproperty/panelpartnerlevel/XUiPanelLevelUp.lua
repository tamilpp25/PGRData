local XUiPanelLevelUp = XClass(nil, "XUiPanelLevelUp")
local XUiPanelExpBar = require("XUi/XUiSettleWinMainLine/XUiPanelExpBar")
local XUiGridPartnerAttrib = require("XUi/XUiPartner/PartnerCommon/XUiGridPartnerAttrib")
local XUiGridEquipExpItem = require("XUi/XUiEquipStrengthen/XUiGridEquipExpItem")
local CONDITION_COLOR = {
    [true] = XUiHelper.Hexcolor2Color("0E70BDFF"),
    [false] = CS.UnityEngine.Color.gray,
}
local CSXTextManagerGetText = CS.XTextManager.GetText
local mathMax = math.max
local mathFloor = math.floor

function XUiPanelLevelUp:Ctor(ui, base, root)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    self.Root = root
    XTool.InitUiObject(self)

    self.PreExp = 0
    self.PreLevel = 0
    self.GridAttrInfoList = {}
    self.AttrGridList = {}
    self.GridPartnerReplaceAttr.gameObject:SetActiveEx(false)
    self.GridExpItem.gameObject:SetActiveEx(false)
    self.PartnerExpBar = XUiPanelExpBar.New(self.PanelExpBar)
    
    self:InitDynamicTable()
    self:SetButtonCallBack()
end

function XUiPanelLevelUp:UpdatePanel(data)---刷新掉这个
    self.Data = data
    self:ResetSelectedData()
    self:SetupDynamicTable()
    self:UpdatePartnerInfo()
    self:UpdatePartnerPreView()
    self.GameObject:SetActiveEx(true)
end

function XUiPanelLevelUp:HidePanel()
    self.GameObject:SetActiveEx(false)
end

function XUiPanelLevelUp:SetButtonCallBack()
    self.BtnStrengthen.CallBack = function()
        self:OnBtnStrengthenClick()
    end
    self.BtnSource.CallBack = function()
        self:OnBtnSourceClick()
    end
    self.BtnAllSelect.CallBack = function()
        self:OnBtnAllSelectClick()
    end
end

function XUiPanelLevelUp:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemScroll)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridEquipExpItem)
end

function XUiPanelLevelUp:SetupDynamicTable()
    self.ItemIdList = XDataCenter.PartnerManager.GetCanEatItemIds()
    self.DynamicTable:SetDataSource(self.ItemIdList)
    self.DynamicTable:ReloadDataSync()
end

function XUiPanelLevelUp:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        local addCountCb = function(itemId, addCount)
            self:OnSelectItem(itemId, addCount)
        end

        local addCountCheckCb = function(doNotTip)
            return self:CheckCanSelect(doNotTip)
        end

        grid:Init(self.Root, addCountCb, addCountCheckCb)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local itemId = self.ItemIdList[index]
        local selectCount = self.SelectItemDic[itemId] or 0
        grid:Refresh(itemId, selectCount)
    end
end

function XUiPanelLevelUp:UpdatePartnerInfo()
    local curLv = self.Data:GetLevel()
    local maxLv = self.Data:GetBreakthroughLevelLimit()
    local curExp = mathFloor(self.Data:GetExp())
    local maxExp = self.Data:GetLevelUpInfoExp()

    self.TxtCurLv.text = CSXTextManagerGetText("EquipStrengthenCurLevel", curLv, maxLv)
    self.PartnerExpBar:PreviewExpBar(curExp, maxExp, self.PreExp)
    self.TxtExp.text = string.format("%d/%d", curExp, maxExp)
    self.TxtPreExp.gameObject:SetActiveEx(false)
    self.PanelNone.gameObject:SetActiveEx(#self.ItemIdList <= 0)
    
    local curAttrMap = self.Data:GetPartnerAttrMap()
    for attrIndex, attrInfo in pairs(curAttrMap) do
        local attrGrid = self.AttrGridList[attrIndex]
        if not attrGrid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridPartnerReplaceAttr)
            attrGrid = XUiGridPartnerAttrib.New(ui, attrInfo.Name, true)
            attrGrid.Transform:SetParent(self.PanelAttrParent, false)
            self.AttrGridList[attrIndex] = attrGrid
        end
        attrGrid.GameObject:SetActive(true)
        attrGrid:UpdateData(attrInfo.Value)
    end

    for i = #curAttrMap + 1, #self.AttrGridList do
        self.AttrGridList[i].GameObject:SetActive(false)
    end
end

function XUiPanelLevelUp:UpdatePartnerPreView()
    local curLv = self.Data:GetLevel()
    local maxLv = self.Data:GetBreakthroughLevelLimit()
    local curExp = mathFloor(self.Data:GetExp())
    
    local preLevel = self.PreLevel
    local preExp = mathFloor(self.PreExp)
    local maxExp = self.Data:GetLevelUpInfoExp(nil, preLevel)
    
    local totalAddExp = self.TotalAddExp

    self.TxtCurLv.text = CSXTextManagerGetText("EquipStrengthenCurLevel", preLevel, maxLv)
    self.TxtExp.text = string.format("%d/%d", preExp, maxExp)

    if preExp == 0 then
        self.PartnerExpBar:PreviewExpBar(0, maxExp, preExp)
    else
        if curLv ~= preLevel then
            self.PartnerExpBar:PreviewExpBar(0, maxExp, preExp)
        else
            self.PartnerExpBar:PreviewExpBar(curExp, maxExp, preExp)
        end
    end

    local addExp = mathFloor(totalAddExp)
    if addExp > 0 then
        self.TxtPreExp.text = string.format("+%d", addExp)
        self.TxtPreExp.gameObject:SetActiveEx(true)
    else
        self.TxtPreExp.gameObject:SetActiveEx(false)
    end

    local preAttrMap = self.Data:GetPartnerAttrMap(preLevel)
    local curAttrMap = self.Data:GetPartnerAttrMap()
    for attrIndex, attrInfo in pairs(curAttrMap) do
        local preAttrInfo = preAttrMap[attrIndex]
        local attrGrid = self.AttrGridList[attrIndex]
        if not attrGrid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridPartnerReplaceAttr)
            attrGrid = XUiGridPartnerAttrib.New(ui, attrInfo.Name, true)
            attrGrid.Transform:SetParent(self.PanelAttrParent, false)
            self.AttrGridList[attrIndex] = attrGrid
        end
        attrGrid.GameObject:SetActive(true)
        attrGrid:UpdateData(attrInfo.Value, preAttrInfo.Value, true)
    end

    for i = #curAttrMap + 1, #self.AttrGridList do
        self.AttrGridList[i].GameObject:SetActive(false)
    end

    local costMoney = XDataCenter.PartnerManager.GetEatItemsCostMoney(self.SelectItemDic)
    self.TxtCost.text = costMoney
    self.TxtCost.color = CONDITION_COLOR[XDataCenter.ItemManager.GetCoinsNum() >= costMoney]

    local canStrengthen = next(self.SelectItemDic)
    self.BtnStrengthen:SetDisable(not canStrengthen)
end

function XUiPanelLevelUp:CheckCanSelect(doNotTip)
    local preLevel = self.PreLevel
    local limitLevel = self.Data:GetBreakthroughLevelLimit()
    if preLevel >= limitLevel then
        if not doNotTip then
            XUiManager.TipMsg(CSXTextManagerGetText("EquipStrengthenMaxLevel"))
        end
        return false
    else
        return true
    end
end

function XUiPanelLevelUp:OnSelectItem(itemId, addCount)
    local selectItemDic = self.SelectItemDic
    local oldCount = selectItemDic[itemId] or 0
    local newCount = mathMax(0, oldCount + addCount)
    selectItemDic[itemId] = newCount > 0 and newCount or nil

    local addExp = XDataCenter.ItemManager.GetItemsAddEquipExp(itemId, addCount)
    self.PreLevel, self.TotalAddExp, self.PreExp = self:GetStrengthenPreData(addExp)
    self:UpdatePartnerPreView()
end

function XUiPanelLevelUp:OnBtnStrengthenClick()
    XDataCenter.PartnerManager.PartnerLevelUpRequest(self.Data:GetId(), self.SelectItemDic, function()
            if not self.Data:GetIsMaxBreakthrough() and self.Data:GetIsLevelMax() then
                self:ShowHint(CSXTextManagerGetText("PartnerCanBreakthroughHint"))
            else
                self:ShowHint(CSXTextManagerGetText("PartnerUpLevelHint"))
            end
        end)
end

function XUiPanelLevelUp:ShowHint(hintText)
    XLuaUiManager.SetMask(true)
    XLuaUiManager.Open("UiPartnerPopupTip", hintText, function ()
            XLuaUiManager.SetMask(false)
            if not XTool.UObjIsNil(self.Base.Transform) then
                self.Base:UpdatePanel(self.Data)
            end
    end)
end

function XUiPanelLevelUp:OnBtnSourceClick()
    local skipIds = self.Data:GetLevelUpSkipIdList()
    XLuaUiManager.Open("UiPartnerStrengthenSkip", skipIds)
end

function XUiPanelLevelUp:OnBtnAllSelectClick()
    self:AutoSelectItems()
end

function XUiPanelLevelUp:ResetSelectedData()
    self.PreLevel = self.Data:GetLevel()
    self.TotalAddExp = 0
    self.PreExp = mathFloor(self.Data:GetExp())
    self.SelectItemDic = {}
end

function XUiPanelLevelUp:GetStrengthenPreData(addExp)
    local totalAddExp = self.TotalAddExp + addExp
    local preExp = totalAddExp + self.Data:GetExp()
    local preLevel = self.Data:GetLevel()

    local limitLevel = self.Data:GetBreakthroughLevelLimit()
    while true do
        local nextExp = self.Data:GetLevelUpInfoExp(nil ,preLevel)
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

function XUiPanelLevelUp:AutoSelectItems()
    local recommendEatItemIds = self.ItemIdList
    if not next(recommendEatItemIds) then
        XUiManager.TipText("PartnerStrengthenAutoSelectEmpty")
        return
    end

    self:ResetSelectedData()

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

    local limitLevel = self.Data:GetBreakthroughLevelLimit()
    local totalNeedExp = self.Data:GetPartnerLevelTotalNeedExp(limitLevel)
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

    self:UpdatePartnerPreView()
    self:SetupDynamicTable()
end

return XUiPanelLevelUp