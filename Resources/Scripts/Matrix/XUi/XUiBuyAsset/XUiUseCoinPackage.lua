local XUiCoinPackage = require("XUi/XUiBuyAsset/XUiCoinPackage")
local XUiUseCoinPackage = XLuaUiManager.Register(XLuaUi, "UiUseCoinPackage")
local NOT_SELECT_TIP = CS.XTextManager.GetText("UseNutPackage")
local OVER_MAX_COUNT_TIP = CS.XTextManager.GetText("NutOverMaxCount")

function XUiUseCoinPackage:OnAwake()
    -- 重新注册下名字
    self.ItemScrollView = self.ElectricPackageScroll
    self.TxtCount = self.TxtCurrentElectric
    self.TxtGetCount = self.TxtElectricNumPackage
    self.BtnExchange = self.BtnElectricExchange
    -- 隐藏/显示关联的对象
    --self.TxtElectricNumPackage.gameObject:SetActiveEx(false)
    --self.PanelCurrentElectricItem.gameObject:SetActiveEx(false)
    --self.TxtCoinGetCount.gameObject:SetActiveEx(true)
    --self.PanelCurrentCoinItem.gameObject:SetActiveEx(true)
    -- 其他变量
    self.Items = {}
    --[[
        {
            [index] = {
                SelectCount,
                EffectNum,
            }
        }
    ]]
    self.CurrentSelectItemInfo = {}
    self.ItemId = nil
    self.GridCommonPopUp.gameObject:SetActiveEx(false)
    self:RegisterUiEvents()
    -- 初始化动态列表
    self.DynamicTable = XDynamicTableNormal.New(self.ItemScrollView)
    self.DynamicTable:SetProxy(XUiCoinPackage)
    self.DynamicTable:SetDelegate(self)
end

function XUiUseCoinPackage:OnEnable()
    self.ItemId = XDataCenter.ItemManager.ItemId.Coin 
    self:RefreshCurrentCount()
    self:RefreshDynamicTable()
    self.TxtGetCount.text = 0
end

function XUiUseCoinPackage:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:DynamicSetData(self.Items[index], index, self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        self:SetDefaultSeleteItem()
    end
end

-- 缓存选择的item的数量
function XUiUseCoinPackage:CacheSelectItemCount(index, count, effectNum)
    self.CurrentSelectItemInfo[index] = self.CurrentSelectItemInfo[index] or {}
    -- 做一个总获取数量的计算
    local diffCount = count - (self.CurrentSelectItemInfo[index].SelectCount or 0)
    self.TxtGetCount.text = tonumber(self.TxtGetCount.text) + diffCount * effectNum
    if count <= 0 then
        self.CurrentSelectItemInfo[index] = nil
    else
        self.CurrentSelectItemInfo[index].SelectCount = count
        self.CurrentSelectItemInfo[index].EffectNum = effectNum 
    end
end

function XUiUseCoinPackage:GetSelectItemCount(index)
    return self.CurrentSelectItemInfo[index] and self.CurrentSelectItemInfo[index].SelectCount or 0
end

--######################## 私有方法 ########################

function XUiUseCoinPackage:RegisterUiEvents()
    self.BtnCancel.CallBack = function ()
       self:Close() 
    end
    self.BtnTanchuangClose.CallBack = function ()
        self:Close()
    end
    self.BtnConfirm.CallBack = function() self:OnBtnConfirmClicked() end
    self.BtnExchange.CallBack = function() self:OnBtnExchangeClicked() end
end

function XUiUseCoinPackage:RefreshDynamicTable()
    self.Items = XDataCenter.ItemManager.GetCoinPackages()
    self.ImgEmpty.gameObject:SetActiveEx(#self.Items <= 0)
    self.DynamicTable:SetDataSource(self.Items)
    self.DynamicTable:ReloadDataSync(1)
end

function XUiUseCoinPackage:SetDefaultSeleteItem()
    local firstGrid = self.DynamicTable:GetGridByIndex(1)
    if firstGrid then
        firstGrid:OnSelfClicked()
    end
end

function XUiUseCoinPackage:OnBtnConfirmClicked()
    -- 检查是否有选择要使用的物品
    if not next(self.CurrentSelectItemInfo) then
        XUiManager.TipError(NOT_SELECT_TIP)
        return
    end
    if XDataCenter.ItemManager.GetCount(self.ItemId) >= XDataCenter.ItemManager.GetMaxCount(self.ItemId) then
        XUiManager.TipError(OVER_MAX_COUNT_TIP)
        return
    end
    local totalRewardGoodList = {}
    local lastUseIndex = nil
    local useItemFunction = function(useIndex, count, callback)
        local useItem = self.Items[useIndex]
        if not useItem then return end
        local recycleTime = useItem.RecycleBatch and useItem.RecycleBatch.RecycleTime
        XDataCenter.ItemManager.Use(useItem.Data.Id, recycleTime, count, callback)
    end
    local addRewardGoodCallback = function(rewardGoodList)
        if rewardGoodList and rewardGoodList[1] then
            table.insert(totalRewardGoodList, rewardGoodList[1])
        end
    end
    for index, selectedItemInfo in pairs(self.CurrentSelectItemInfo) do
        if selectedItemInfo.SelectCount > 0 then
            if lastUseIndex then
                useItemFunction(lastUseIndex, self.CurrentSelectItemInfo[lastUseIndex].SelectCount, addRewardGoodCallback)
            end
            lastUseIndex = index
        end
    end
    local finishedCallback = function(rewardGoodList)
        if rewardGoodList and rewardGoodList[1] then
            table.insert(totalRewardGoodList, rewardGoodList[1])
        end
        -- 刷新最新资源数据
        self.TxtGetCount.text = 0
        self.CurrentSelectItemInfo = {}
        self:RefreshCurrentCount()
        -- 刷新列表
        self:RefreshDynamicTable()
        XUiManager.OpenUiObtain(totalRewardGoodList)
    end
    useItemFunction(lastUseIndex, self.CurrentSelectItemInfo[lastUseIndex].SelectCount, finishedCallback)
end

function XUiUseCoinPackage:OnBtnExchangeClicked()
    self:Close()
    XLuaUiManager.Open("UiBuyAsset", self.ItemId)
end

function XUiUseCoinPackage:RefreshCurrentCount()
    self.TxtCount.text = XDataCenter.ItemManager.GetCount(self.ItemId)
    self.TxtCurrentDes.text = CS.XTextManager.GetText("BuyAssetCurNutCaseTxtDesc")--获得螺母
    self.TxtCurItemName.text = CS.XTextManager.GetText("BuyAssetCurNutCaseNameDesc")--现在的螺母
    self.ImgIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(self.ItemId))
    self.CurrencyText1.gameObject:SetActive(false)
end

return XUiUseCoinPackage