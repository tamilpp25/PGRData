local XUiPassportUpLevelGrid = require("XUi/XUiPassport/UpLevel/XUiPassportUpLevelGrid")

local XUiPassportUpLevel = XLuaUiManager.Register(XLuaUi, "UiPassportUpLevel")

local MinSelectCount = 1
local CSXTextManagerGetText = CS.XTextManager.GetText
local tableInsert = table.insert
local mathMax = math.max
local mathFloor = math.floor

--购买等级
function XUiPassportUpLevel:OnAwake()
    self.SpendBuyCount = 0  --花费多少
    self.SpendBuyExp = 0    --购买多少经验
    self.LevelAfter = 0     --购买后提升至多少级
    self.CurLevelIdListCount = 0    --当前滑动列表显示的数量
    self.IsShowGridEffect = false   --滑动列表中新出现的格子显示特效
end

function XUiPassportUpLevel:OnStart()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem)
    self:RegisterButtonEvent()
    self:SetSelectCount(1)
    self.PassportBaseInfo = XDataCenter.PassportManager.GetPassportBaseInfo()

    self.MaxLevel = XPassportConfigs.GetPassportMaxLevel()
    self.MaxSelectCount = self.MaxLevel - self.PassportBaseInfo:GetLevel()

    local expItemIcon = XItemConfigs.GetItemIconById(XDataCenter.ItemManager.ItemId.PassportExp)
    self.RImgIconBuy:SetRawImage(expItemIcon)

    self.DynamicTable = XDynamicTableNormal.New(self.PanelRewardList.transform)
    self.DynamicTable:SetProxy(XUiPassportUpLevelGrid)
    self.DynamicTable:SetDelegate(self)
    self.GridStage.gameObject:SetActive(false)
end

function XUiPassportUpLevel:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_NOTIFY_PASSPORT_BASE_INFO, self.Refresh, self)
    self.TxtLevelNow.text = self.PassportBaseInfo:GetLevel()
    self:Refresh()
end

function XUiPassportUpLevel:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_NOTIFY_PASSPORT_BASE_INFO, self.Refresh, self)
end

function XUiPassportUpLevel:RegisterButtonEvent()
    self:RegisterClickEvent(self.BtnCancel, self.Close)
    self:RegisterClickEvent(self.BtnTanchuangClose, self.Close)
    self:RegisterClickEvent(self.BtnConfirm, self.OnBtnConfirmClick)
    self.BtnAddSelect.CallBack = handler(self, self.OnBtnAddClick)
    self.BtnMinusSelect.CallBack = handler(self, self.OnBtnReduceClick)
    self.WidgetBtnMinusLongClick = XUiButtonLongClick.New(self.WidgetBtnMinusSelect, 100, self, nil, self.BtnMinusSelectLongClickCallback, nil, true)
    self.WidgetBtnAddMinusLongClick = XUiButtonLongClick.New(self.WidgetBtnAddSelect, 100, self, nil, self.BtnAddSelectLongClickCallback, nil, true)
    self.TxtSelect.onValueChanged:AddListener(function() self:OnInputFieldTextChanged() end)
end

function XUiPassportUpLevel:Refresh()
    self:UpdateTextSelectCount()
    self:UpdateBtnSelectState()
end

function XUiPassportUpLevel:UpdateBtnSelectState()
    local isDisable = self.SelectCount <= MinSelectCount
    self.BtnMinusSelect:SetDisable(isDisable, not isDisable)

    local maxSelectCount = self:GetMaxSelectCount()
    isDisable = self.SelectCount >= maxSelectCount
    self.BtnAddSelect:SetDisable(isDisable, not isDisable)
end

function XUiPassportUpLevel:UpdateTextSelectCount()
    local selectCount = self:GetSelectCount()
    local currLevel = self.PassportBaseInfo:GetLevel()
    local maxSelectCount = self:GetMaxSelectCount()
    local levelAfter = math.min(self.MaxLevel, currLevel + selectCount)
    self.TxtLevelAfter.text = levelAfter
    self.TxtSelect.text = selectCount

    local spendBuyCount = 0     --花费多少
    local levelId
    local costItemId = XPassportConfigs.GetBuyLevelCostItemId()
    local costItemIcon = XItemConfigs.GetItemIconById(costItemId)
    local costItemCount
    local spendBuyExp = 0       --购买多少经验
    local expCfg
    local levelIdList = {}      --要购买的等级Id列表
    for i = currLevel + 1, levelAfter do
        levelId = XPassportConfigs.GetPassportLevelId(i)
        costItemCount = levelId and XPassportConfigs.GetPassportLevelCostItemCount(levelId) or 0
        spendBuyCount = spendBuyCount + costItemCount

        expCfg = levelId and XPassportConfigs.GetPassportLevelTotalExp(levelId) or 0
        spendBuyExp = spendBuyExp + expCfg

        if levelId then
            tableInsert(levelIdList, levelId)
        end
    end
    self.RImgIconSpend:SetRawImage(costItemIcon)
    self.TxtTips.text = CSXTextManagerGetText("PassportSpendBuyDesc", spendBuyCount)
    self.TxtBuy.text = spendBuyExp
    self.TxtLevel.text = CSXTextManagerGetText("PassportBuyLevelUpDesc", levelAfter)

    self:SetSpendBuyExp(spendBuyExp)
    self:SetSpendBuyCount(spendBuyCount)
    self:SetLevelAfter(levelAfter)

    self:UpdateDynamicTable(levelIdList)
end

function XUiPassportUpLevel:UpdateDynamicTable(levelIdList)
    self.IsShowGridEffect = #levelIdList > self.CurLevelIdListCount
    self.CurLevelIdListCount = #levelIdList
    self.LevelIdList = XTool.ReverseList(levelIdList)
    self.DynamicTable:SetDataSource(levelIdList)
    self.DynamicTable:ReloadDataSync(1)
end

function XUiPassportUpLevel:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local levelId = self.LevelIdList[index]
        grid:Refresh(levelId)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        if not self.IsShowGridEffect then
            return
        end

        local grid = self.DynamicTable:GetGridByIndex(1)
        if grid then
            grid:ShowEffect()
        end
    end
end

function XUiPassportUpLevel:OnBtnReduceClick()
    self:SetSelectCount(self.SelectCount - 1)
    self:Refresh()
end

function XUiPassportUpLevel:OnBtnAddClick()
    self:SetSelectCount(self.SelectCount + 1)
    self:Refresh()
end

function XUiPassportUpLevel:BtnMinusSelectLongClickCallback(time)
    if self.SelectCount == MinSelectCount then
        return
    end

    local delta = mathMax(0, mathFloor(time / 150))
    local count = self.SelectCount - delta
    if count <= MinSelectCount then
        count = MinSelectCount
    end
    self:SetSelectCount(count)
    self:Refresh()
end

function XUiPassportUpLevel:BtnAddSelectLongClickCallback(time)
    local maxCount = self:GetMaxSelectCount()
    if maxCount and self.SelectCount >= maxCount then
        return
    end
    local delta = mathMax(0, mathFloor(time / 150))
    local count = self.SelectCount + delta
    if maxCount and count >= maxCount then
        count = maxCount
    end

    self:SetSelectCount(count)
    self:Refresh()
end

function XUiPassportUpLevel:OnBtnConfirmClick()
    local costItemId = XPassportConfigs.GetBuyLevelCostItemId()
    local haveItemCount = XDataCenter.ItemManager.GetCount(costItemId)
    local spendBuyCount = self:GetSpendBuyCount()
    
    local costItemName = XItemConfigs.GetItemNameById(costItemId)
    local spendBuyExp = self:GetSpendBuyExp()
    local spendBuyExpName = XItemConfigs.GetItemNameById(XDataCenter.ItemManager.ItemId.PassportExp)
    local levelAfter = self:GetLevelAfter()
    local title = CSXTextManagerGetText("BuyConfirmTipsTitle")
    local desc = CSXTextManagerGetText("PassportBuyLevelTipsDesc", spendBuyCount, costItemName, spendBuyExp, spendBuyExpName, levelAfter)

    local sureCallback = function()
        if haveItemCount < spendBuyCount then
            XUiManager.TipText("ShopItemPaidGemNotEnough")
            XLuaUiManager.Open("UiPurchase", XPurchaseConfigs.TabsConfig.HK)
            return
        end
        XDataCenter.PassportManager.RequestPassportBuyExp(levelAfter, function() self:Close() end)
    end

    XUiManager.DialogTip(title, desc, nil, nil, sureCallback)
end

function XUiPassportUpLevel:OnInputFieldTextChanged()
    local selectCount = tonumber(self.TxtSelect.text) or 0
    if selectCount == self.SelectCount then
        return
    end

    local maxCount = self:GetMaxSelectCount()
    selectCount = math.max(MinSelectCount, selectCount)
    selectCount = math.min(maxCount, selectCount)

    self:SetSelectCount(selectCount)
    self:Refresh()
end

function XUiPassportUpLevel:SetLevelAfter(levelAfter)
    self.LevelAfter = levelAfter
end

function XUiPassportUpLevel:GetLevelAfter()
    return self.LevelAfter
end

function XUiPassportUpLevel:SetSpendBuyExp(spendBuyExp)
    self.SpendBuyExp = spendBuyExp
end

function XUiPassportUpLevel:GetSpendBuyExp()
    return self.SpendBuyExp
end

function XUiPassportUpLevel:SetSpendBuyCount(spendBuyCount)
    self.SpendBuyCount = spendBuyCount
end

function XUiPassportUpLevel:GetSpendBuyCount()
    return self.SpendBuyCount
end

function XUiPassportUpLevel:SetSelectCount(selectCount)
    self.SelectCount = selectCount
end

function XUiPassportUpLevel:GetSelectCount()
    return self.SelectCount
end

function XUiPassportUpLevel:GetMaxSelectCount()
    return self.MaxSelectCount
end