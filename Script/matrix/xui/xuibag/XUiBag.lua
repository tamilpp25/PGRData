local XUiPanelBagItem = require("XUi/XUiBag/XUiPanelBagItem")
local XUiPanelSidePopUp = require("XUi/XUiBag/XUiPanelSidePopUp")
local XUiPanelBagRecycle = require("XUi/XUiBag/XUiPanelBagRecycle")
local XUiPanelSelectGift = require("XUi/XUiBag/XUiPanelSelectGift")
local XUiPanelSelectReplicatedGift = require("XUi/XUiBag/XUiPanelSelectReplicatedGift")
local GridTimeAnimation = 10
local DefaultSortTypeIndex = 0
local PartnerPageIndex = 5

local CapacityDesStr = {
    EquipCapacityDes = CS.XTextManager.GetText("EquipCapacityDes"),
    EquipDecomposionCapacityDes = CS.XTextManager.GetText("EquipDecomposionCapacityDes"),
    EquipRecycleCapacityDes = CS.XTextManager.GetText("EquipRecycleCapacityDes"),
    AwarenessCapacityDes = CS.XTextManager.GetText("AwarenessCapacityDes"),
    AwarenessDecomposionCapacityDes = CS.XTextManager.GetText("AwarenessDecomposionCapacityDes"),
    AwarenessRecycleCapacityDes = CS.XTextManager.GetText("AwarenessRecycleCapacityDes"),
    SuitCapacityDes = CS.XTextManager.GetText("SuitCapacityDes"),
    MaterialCapacityDes = CS.XTextManager.GetText("MaterialCapacityDes"),
    FragmentCapacityDes = CS.XTextManager.GetText("FragmentCapacityDes"),
    PartnerCapacityDes = CS.XTextManager.GetText("PartnerCapacityDes"),
    PartnerDecomposionCapacityDes = CS.XTextManager.GetText("PartnerDecomposionCapacityDes"),
}

local XUiBag = XLuaUiManager.Register(XLuaUi, "UiBag")

--背包页签按钮索引组
XUiBag.PageIndexGroup = {
    [1] = XItemConfigs.PageType.Equip, --武器
    [2] = XItemConfigs.PageType.SuitCover, --意识套装封面
    [3] = XItemConfigs.PageType.Material, --材料
    [4] = XItemConfigs.PageType.Fragment, --碎片
    [5] = XItemConfigs.PageType.Partner, --伙伴
}

--背包页签按钮索引组
XUiBag.PageTypeToIndex = {
    [XItemConfigs.PageType.Equip] = 1, --武器
    [XItemConfigs.PageType.SuitCover] = 2, --意识套装封面
    [XItemConfigs.PageType.Material] = 3, --材料
    [XItemConfigs.PageType.Fragment] = 4, --碎片
    [XItemConfigs.PageType.Awareness] = 2, --意识
    [XItemConfigs.PageType.Partner] = 5, --伙伴
}

XUiBag.ItemPageToTypes = {
    [XItemConfigs.PageType.Material] = XItemConfigs.Materials,
    [XItemConfigs.PageType.Fragment] = { XItemConfigs.ItemType.Fragment },
}

--背包操作类型
XUiBag.OperationType = {
    Common = 1, --无操作
    Sell = 2, --出售
    Decomposion = 3, --分解
    Convert = 4, --转化
    Recycle = 5, --回收
    PartnerDecomposion = 6, --伙伴分解
}

--道具页签筛选类型
XUiBag.MaterialType = {
    All = 1, --全部
    Material = 2, --材料
    Consumables = 3, --消耗品
    Others = 4, --其他
}

XUiBag.MaterialTypeToItemTypes = {
    [XUiBag.MaterialType.All] = XItemConfigs.Materials,
    [XUiBag.MaterialType.Material] = {
        XItemConfigs.ItemType.CardExp,
        XItemConfigs.ItemType.EquipExp,
        XItemConfigs.ItemType.Material,
        XItemConfigs.ItemType.EquipResonanace,
    },
    [XUiBag.MaterialType.Consumables] = {
        XItemConfigs.ItemType.Gift,
    },
    [XUiBag.MaterialType.Others] = {
        XItemConfigs.ItemType.ExchangeMoney,
        XItemConfigs.ItemType.SpExchangeMoney,
        XItemConfigs.ItemType.FavorGift,
        XItemConfigs.ItemType.ActiveMoney,
        XItemConfigs.ItemType.PlayingItem,
    },
}

local MaterialTypeCache = XUiBag.MaterialType.All

function XUiBag:OnAwake()
    local togs = { self.BtnTog0, self.BtnTog1, self.BtnTog2, self.BtnTog3, self.BtnTog4 }
    self.TabBtnGroup:Init(togs, function(index) self:PageSelect(index) end)
    
    local isCanOpenPantnerTog = XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Partner)
    self.BtnTog4.gameObject:SetActiveEx(isCanOpenPantnerTog)
    
    local sorttogs = { self.BtnTogSortStar, self.BtnTogSortBreakthrough, self.BtnTogSortLevel, self.BtnTogSortProceed }
    self.SortBtnGroup = XUiTabBtnGroup.New(sorttogs, function(index) self:SortTypeTurn(index) end)
    
    local partnerSorttogs = { 
        self.PanelPartnerSort:GetObject("BtnPartnerSortStar"), 
        self.PanelPartnerSort:GetObject("BtnPartnerSortBreakthrough"), 
        self.PanelPartnerSort:GetObject("BtnPartnerSortLevel"), 
        }
    self.PartnerSortBtnGroup = XUiTabBtnGroup.New(partnerSorttogs, function(index) self:PartnerSortTypeTurn(index) end)
    
    local materialTypeTogs = { self.TogAll, self.TogStuff, self.TtogConsumables, self.TogOthers }
    self.PanelFilter2:Init(materialTypeTogs, function(index) self:SelectMaterialType(index) end)

    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.SidePopUpPanel = XUiPanelSidePopUp.New(self.PanelSidePopUp, self)
    self.BagRecyclePanel = XUiPanelBagRecycle.New(self, self.PanelBagRecycle)
    self.SelectGiftPanel = XUiPanelSelectGift.New(self, self.PanelSelectGift)
    self.SelectReplicatedGiftPanel = XUiPanelSelectReplicatedGift.New(self, self.PanelSelectReplicatedGift)

    self.DynamicTable = XDynamicTableNormal.New(self.PanelDynamicTable)
    self.DynamicTable:SetProxy(XUiPanelBagItem)
    self.DynamicTable:SetDelegate(self)

    self.PanelBagItem.gameObject:SetActiveEx(false)
    self.GridBagItemRect = self.PanelBagItem.transform:Find("GridEquip"):GetComponent("RectTransform").rect
    self.GridSuitSimpleRect = self.PanelBagItem.transform:Find("GridSuitSimple"):GetComponent("RectTransform").rect

    XRedPointManager.AddRedPointEvent(self.BtnTog2, self.OnCheckBtnItemRed, self, {
        XRedPointConditions.Types.CONDITION_ITEM_COLLECTION_ENTRANCE,
    })

    XRedPointManager.AddRedPointEvent(self.BtnCollection, self.OnCheckBtnCollectRed, self, {
        XRedPointConditions.Types.CONDITION_ITEM_COLLECTION_ENTRANCE,
    })

    self:AutoAddListener()
end

function XUiBag:OnStart(record)
    self.PageRecord = record or XDataCenter.ItemManager.PageRecordCache
    self.MaterailTypeRecord = MaterialTypeCache
    self.IsAscendOrder = false
    self.Operation = XUiBag.OperationType.Common
    self.SortType = XEquipConfig.PriorSortType.Star
    self.PartnerSortType = DefaultSortTypeIndex
    self.StarCheckList = {true, true, true, true, true, true }
    self.IsFirstAnimation = true
    self.SelectList = {}

    --打开背包时如果上次选择是意识那么回到套装封面
    if self.PageRecord == XItemConfigs.PageType.Awareness then
        self.PageRecord = XItemConfigs.PageType.SuitCover
    end

    self.TabBtnGroup:SelectIndex(XUiBag.PageTypeToIndex[self.PageRecord], false)
    self.SortBtnGroup:SelectIndex(self.SortType + 1, false)
    self.PartnerSortBtnGroup:SelectIndex(self.PartnerSortType + 1, false)

    --self:PlayAnimationWithMask("AnimStartEnable")
end

function XUiBag:OnEnable()
    self.GridCount = 1
    self:Refresh(false)
    self.SelectGiftPanel:OnEnable()
    self:PlayAnimationWithMask("AnimStartEnable")
end

function XUiBag:OnDestroy()
    XDataCenter.ItemManager.SetPageRecordCache(self.PageRecord)
    MaterialTypeCache = self.MaterailTypeRecord
end

--注册监听事件
function XUiBag:OnGetEvents()
    return {
        XEventId.EVENT_ITEM_USE,
        XEventId.EVENT_ITEM_RECYCLE,
        XEventId.EVENT_ITEM_MULTIPLY_USE,
        XEventId.EVENT_EQUIP_RECYCLE_NOTIFY,
    }
end

--处理事件监听
function XUiBag:OnNotify(evt)
    if evt == XEventId.EVENT_ITEM_USE
    or evt == XEventId.EVENT_ITEM_RECYCLE
    or evt == XEventId.EVENT_ITEM_MULTIPLY_USE
    then
        self:UpdateDynamicTable()
    elseif evt == XEventId.EVENT_EQUIP_RECYCLE_NOTIFY then
        self:UpdateDynamicTable()
        self:OperationTurn(self.OperationType.Common)
    end
end

function XUiBag:Refresh(bReload)
    self:UpdateDynamicTable(bReload)
    self:UpdatePanels()
end

--设置动态列表
function XUiBag:UpdateDynamicTable(bReload)
    --刷新数据
    self.PageDatas = self:GetDataByPage()
    local gridSize
    if self.PageRecord == XItemConfigs.PageType.SuitCover then
        --套装的格子比较大
        gridSize = CS.UnityEngine.Vector2(self.GridSuitSimpleRect.width, self.GridSuitSimpleRect.height)
    else
        gridSize = CS.UnityEngine.Vector2(self.GridBagItemRect.width, self.GridBagItemRect.height)
    end
    
    self.DynamicTable:SetGridSize(gridSize)
    self.DynamicTable:SetDataSource(self.PageDatas)
    self.DynamicTable:ReloadDataASync(bReload and 1 or -1)

    --刷新容量文本
    local curPageCount = #self.PageDatas
    local maxCount
    local capacityDes = ""

    if self.PageRecord == XItemConfigs.PageType.Equip then
        maxCount = XEquipConfig.GetMaxWeaponCount()
        if self.Operation == XUiBag.OperationType.Decomposion then
            capacityDes = CapacityDesStr.EquipDecomposionCapacityDes
        elseif self.Operation == XUiBag.OperationType.Recycle then
            capacityDes = CapacityDesStr.EquipRecycleCapacityDes
        else
            capacityDes = CapacityDesStr.EquipCapacityDes
        end
    elseif self.PageRecord == XItemConfigs.PageType.Awareness then
        maxCount = XEquipConfig.GetMaxAwarenessCount()
        if self.Operation == XUiBag.OperationType.Decomposion then
            capacityDes = CapacityDesStr.AwarenessDecomposionCapacityDes
        elseif self.Operation == XUiBag.OperationType.Recycle then
            capacityDes = CapacityDesStr.AwarenessRecycleCapacityDes
        else
            capacityDes = CapacityDesStr.AwarenessCapacityDes
        end
    elseif self.PageRecord == XItemConfigs.PageType.SuitCover then
        curPageCount = curPageCount - XEquipConfig.GetDefaultSuitIdCount() --去掉默认全部套装特殊Id
        maxCount = XDataCenter.EquipManager.GetMaxSuitCount()
        capacityDes = CapacityDesStr.SuitCapacityDes
    elseif self.PageRecord == XItemConfigs.PageType.Material then
        capacityDes = CapacityDesStr.MaterialCapacityDes
    elseif self.PageRecord == XItemConfigs.PageType.Fragment then
        capacityDes = CapacityDesStr.FragmentCapacityDes
    elseif self.PageRecord == XItemConfigs.PageType.Partner then
        maxCount = XDataCenter.PartnerManager.GetMaxPartnerCount()
        if self.Operation == XUiBag.OperationType.PartnerDecomposion then
            capacityDes = CapacityDesStr.PartnerDecomposionCapacityDes
        else
            capacityDes = CapacityDesStr.PartnerCapacityDes
        end
    end

    self.TxtCapacityDes.text = capacityDes
    if maxCount then
        self.TxtNowCapacity.text = curPageCount
        self.TxtMaxCapacity.text = "/" .. maxCount
    end

    --刷新消耗品道具剩余时间文本
    if self.PageRecord == XItemConfigs.PageType.Material then
        self:CalLeftTime(XUiBag.MaterialTypeToItemTypes[XUiBag.MaterialType.Consumables], self.TxtTimeConsumables)
        self:CalLeftTime(XUiBag.MaterialTypeToItemTypes[XUiBag.MaterialType.Others], self.TxtTimeOthers)
    end
end

function XUiBag:CalLeftTime(types, txtGo)
    local originData = XDataCenter.ItemManager.GetItemsByTypes(types)
    local minLeftTime = XDataCenter.ItemManager.GetBagItemListMinLeftTime(originData)
    if minLeftTime > 0 then
        local timeStr = XUiHelper.GetBagTimeLimitTimeStrAndBg(minLeftTime)
        txtGo.text = timeStr
        txtGo.gameObject:SetActiveEx(true)
    else
        txtGo.gameObject:SetActiveEx(false)
    end
end

--动态列表事件
function XUiBag:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        if self.IsFirstAnimation then
            grid:Init(self, self.PageRecord, true)
        else
            grid:Init(self, self.PageRecord, false)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local gridSize = self.DynamicTable:GetGridSize()
        local data = self.PageDatas[index]
        if self.PageRecord == XItemConfigs.PageType.Equip or self.PageRecord == XItemConfigs.PageType.Awareness then
            grid:SetupEquip(data, gridSize)
            grid:SetSelectedEquip(self.SelectList[data])
        elseif self.PageRecord == XItemConfigs.PageType.SuitCover then
            grid:SetupSuit(data, self.PageDatas, gridSize)
        elseif self.PageRecord == XItemConfigs.PageType.Partner then --zhang
            grid:SetupPartner(data, gridSize, self.PartnerDataInPrefab[data:GetId()])
            grid:SetSelectedPartner(self.SelectList[data])
        elseif self.PageRecord == XItemConfigs.PageType.Fragment then
            grid:SetupCommon(data, self.PageRecord, self.Operation, gridSize)
            grid:SetSelectedCommon(self.SelectList[data.Data.Id])
        else
            grid:SetupCommon(data, self.PageRecord, self.Operation, gridSize)
            grid:SetSelectedCommon(self.SelectList[data.GridIndex] and self.SelectList[data.GridIndex] == data.Data.Id)
        end
        self.GridCount = self.GridCount + 1
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        local grids = self.DynamicTable:GetGrids()

        self.GridIndex = 1
        local item = grids[self.GridIndex]
        if not item or not item.IsFirstAnimation then
            return
        end

        XLuaUiManager.SetMask(true)
        self.CurAnimationTimerId = XScheduleManager.Schedule(function()
            item = grids[self.GridIndex]
            if item then
                item:PlayAnimation()
            end
            self.GridIndex = self.GridIndex + 1
        end, GridTimeAnimation, self.GridCount, 0)

        XScheduleManager.ScheduleOnce(function()
            XLuaUiManager.SetMask(false)
        end, XScheduleManager.SECOND * 0.8)
    end
end

function XUiBag:OnDisable()
    self.IsFirstAnimation = nil
    if self.CurAnimationTimerId then
        XScheduleManager.UnSchedule(self.CurAnimationTimerId)
        self.CurAnimationTimerId = nil
    end
end

--刷新面板状态
function XUiBag:UpdatePanels()
    local isEmpty = #self.PageDatas <= 0
    self.PanelTag.gameObject:SetActiveEx(self.Operation == XUiBag.OperationType.Common)
    self.PanelSort.gameObject:SetActiveEx(self.PageRecord == XItemConfigs.PageType.Equip or self.PageRecord == XItemConfigs.PageType.Awareness)
    self.PanelPartnerSort.gameObject:SetActiveEx(self.PageRecord == XItemConfigs.PageType.Partner)
    self.PanelFilter.gameObject:SetActiveEx(self.PageRecord == XItemConfigs.PageType.SuitCover)
    self.PanelFilter2.gameObject:SetActiveEx(self.PageRecord == XItemConfigs.PageType.Material)
    self.PanelEmpty.gameObject:SetActiveEx(isEmpty)
    self.TxtNowCapacity.gameObject:SetActiveEx(self.PageRecord == XItemConfigs.PageType.Equip or self.PageRecord == XItemConfigs.PageType.Awareness or self.PageRecord == XItemConfigs.PageType.SuitCover or self.PageRecord == XItemConfigs.PageType.Partner)
    self.TxtMaxCapacity.gameObject:SetActiveEx(self.PageRecord == XItemConfigs.PageType.Equip or (self.PageRecord == XItemConfigs.PageType.Awareness and self.SelectSuitId == XEquipConfig.DEFAULT_SUIT_ID) or self.PageRecord == XItemConfigs.PageType.SuitCover or self.PageRecord == XItemConfigs.PageType.Partner)
    self.BtnHelp.gameObject:SetActiveEx(self.Operation == XUiBag.OperationType.Recycle)
    self.SidePopUpPanel:Refresh()
    --操作按钮
    if self.PageRecord == XItemConfigs.PageType.Equip or self.PageRecord == XItemConfigs.PageType.Awareness or self.PageRecord == XItemConfigs.PageType.Partner then--zhang
        self.PanelDecomposionBtn.gameObject:SetActiveEx(true)
        self.PanelRecycleBtn.gameObject:SetActiveEx(self.PageRecord == XItemConfigs.PageType.Awareness)--装备回收暂时屏蔽武器
        self.BtnDecomposion.gameObject:SetActiveEx(not isEmpty)
        self.ImgCantDecomposion.gameObject:SetActiveEx(isEmpty)
    else
        self.PanelDecomposionBtn.gameObject:SetActiveEx(false)
        self.PanelRecycleBtn.gameObject:SetActiveEx(false)
    end

    if self.PageRecord == XItemConfigs.PageType.Material then
        self.PanelFilter2:SelectIndex(self.MaterailTypeRecord, false)
        self.PanelSellBtn.gameObject:SetActiveEx(true)
        self.BtnSell.gameObject:SetActiveEx(not isEmpty)
        self.ImgCantSell.gameObject:SetActiveEx(isEmpty)
    else
        self.PanelSellBtn.gameObject:SetActiveEx(false)
    end

    if self.PageRecord == XItemConfigs.PageType.Fragment then
        self.PanelConvertBtn.gameObject:SetActiveEx(true)
        self.BtnConvert.gameObject:SetActiveEx(not isEmpty)
        self.ImgCantConvert.gameObject:SetActiveEx(isEmpty)
    else
        self.PanelConvertBtn.gameObject:SetActiveEx(false)
    end
end

function XUiBag:CheckDecomposeRewardNotOverLimit(equipId, deSelect)
    --屏蔽分解拦截
        do return true end

    --if self.Operation == XUiBag.OperationType.Decomposion then return true end
    -- local deSelectSymbol = deSelect and -1 or 1
    -- self.CurDecomposeRewardWeaponCount = self.CurDecomposeRewardWeaponCount or XDataCenter.EquipManager.GetWeaponCount()
    -- self.CurDecomposeRewardAwarenessCount = self.CurDecomposeRewardAwarenessCount or XDataCenter.EquipManager.GetAwarenessCount()
    -- local maxWeaponCount = XEquipConfig.GetMaxWeaponCount()
    -- local maxAwarenessCount = XEquipConfig.GetMaxAwarenessCount()
    -- local curWeaponCount = self.CurDecomposeRewardWeaponCount
    -- local curAwarenessCount = self.CurDecomposeRewardAwarenessCount
    -- local tryAddWeaponCount, tryAddAwarenessCount = XDataCenter.EquipManager.GetDecomposeRewardEquipCount(equipId)
    -- tryAddWeaponCount = tryAddWeaponCount * deSelectSymbol
    -- tryAddAwarenessCount = tryAddAwarenessCount * deSelectSymbol
    -- curWeaponCount = curWeaponCount + tryAddWeaponCount
    -- if not deSelect and curWeaponCount > maxWeaponCount then
    --     XUiManager.TipMsg(XEquipConfig.DecomposeRewardOverLimitTip[XEquipConfig.Classify.Weapon])
    --     return false
    -- end
    -- self.CurDecomposeRewardWeaponCount = curWeaponCount
    -- curAwarenessCount = curAwarenessCount + tryAddAwarenessCount
    -- if not deSelect and curAwarenessCount > maxAwarenessCount then
    --     XUiManager.TipMsg(XEquipConfig.DecomposeRewardOverLimitTip[XEquipConfig.Classify.Awareness])
    --     return false
    -- end
    -- self.CurDecomposeRewardAwarenessCount = curAwarenessCount
    -- return true
end

--获取数据
function XUiBag:GetDataByPage()
    --武器
    if self.PageRecord == XItemConfigs.PageType.Equip then
        local equipIds

        if self.Operation == XUiBag.OperationType.Decomposion then
            equipIds = XDataCenter.EquipManager.GetCanDecomposeWeaponIds()
        elseif self.Operation == XUiBag.OperationType.Recycle then
            equipIds = XDataCenter.EquipManager.GetCanRecycleWeaponIds()
        else
            equipIds = XDataCenter.EquipManager.GetWeaponIds()
        end

        XDataCenter.EquipManager.SortEquipIdListByPriorType(equipIds, self.SortType)
        if self.IsAscendOrder then
            XTool.ReverseList(equipIds)
        end

        return equipIds
    end

    --套装
    if self.PageRecord == XItemConfigs.PageType.SuitCover then
        local suitIds = XDataCenter.EquipManager.GetSuitIdsByStars(self.StarCheckList)
        return suitIds
    end

    --意识
    if self.PageRecord == XItemConfigs.PageType.Awareness then
        local awarenessIds

        if self.Operation == XUiBag.OperationType.Decomposion then
            awarenessIds = XDataCenter.EquipManager.GetCanDecomposeAwarenessIdsBySuitId(self.SelectSuitId)
        elseif self.Operation == XUiBag.OperationType.Recycle then
            awarenessIds = XDataCenter.EquipManager.GetCanRecycleAwarenessIdsBySuitId(self.SelectSuitId)
        else
            awarenessIds = XDataCenter.EquipManager.GetEquipIdsBySuitId(self.SelectSuitId)
        end

        XDataCenter.EquipManager.SortEquipIdListByPriorType(awarenessIds, self.SortType)
        if self.IsAscendOrder then
            XTool.ReverseList(awarenessIds)
        end

        return awarenessIds
    end

    --材料
    if self.PageRecord == XItemConfigs.PageType.Material then
        local types = XUiBag.MaterialTypeToItemTypes[self.MaterailTypeRecord]
        local useConsumableSort = self.MaterailTypeRecord ~= XUiBag.MaterialType.All
        local originData
        if self.Operation == XUiBag.OperationType.Sell then
            originData = XDataCenter.ItemManager.GetCanSellItemsByTypes(types, useConsumableSort)
        else
            originData = XDataCenter.ItemManager.GetItemsByTypes(types, useConsumableSort)
        end
        return originData
    end

    --碎片
    if self.PageRecord == XItemConfigs.PageType.Fragment then
        local types = XUiBag.ItemPageToTypes[self.PageRecord]
        local originData
        if self.Operation == XUiBag.OperationType.Convert then
            originData = XDataCenter.ItemManager.GetCanConvertItemsByTypes(types)
        else
            originData = XDataCenter.ItemManager.GetItemsByTypes(types)
        end
        return originData
    end
    
    --伙伴
    if self.PageRecord == XItemConfigs.PageType.Partner then--zhang
        --预设的辅助机数据
        self.PartnerDataInPrefab = XDataCenter.PartnerManager.GetPartnerDictInPrefab()
        local originData
        if self.Operation == XUiBag.OperationType.PartnerDecomposion then
            originData = XDataCenter.PartnerManager.GetPartnerDecomposionList()
            
            local firstType = XPartnerConfigs.BagSortType[self.PartnerSortType]
            XPartnerSort.BagShowSortFunction(originData, firstType, not self.IsAscendOrder)
        else
            originData = XDataCenter.PartnerManager.GetPartnerOverviewDataList(nil, nil, false)
            
            local firstType = XPartnerConfigs.BagSortType[self.PartnerSortType]
            XPartnerSort.BagShowSortFunction(originData, firstType, not self.IsAscendOrder)
        end
        return originData
    end
end

function XUiBag:OnGridClick(data, grid)
    if self.Operation == XUiBag.OperationType.Common then
        self:OpenDetailUi(data, grid)
    else
        self:SelectGrid(data, grid)
    end
end

function XUiBag:OpenDetailUi(data, grid)
    
    if self.PageRecord == XItemConfigs.PageType.Equip or self.PageRecord == XItemConfigs.PageType.Awareness then
        local equipId = data
        local forceShowBindCharacter = true
        XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipDetail(equipId, nil, nil, forceShowBindCharacter)
    elseif self.PageRecord == XItemConfigs.PageType.SuitCover then
        self.SelectSuitId = data
        self:PageTurn(XItemConfigs.PageType.Awareness)
    elseif self.PageRecord == XItemConfigs.PageType.Material or self.PageRecord == XItemConfigs.PageType.Fragment then
        local itemId = data.Data.Id
        if XDataCenter.ItemManager.IsSelectGift(itemId) then
            local canSelectRewardCount = XDataCenter.ItemManager.GetItem(itemId).Template.SelectCount
            local ownItemCount = grid.GetGridCount and grid:GetGridCount() or 1
            if ownItemCount and ownItemCount > 1 and canSelectRewardCount == 1 then
                self.SelectReplicatedGiftPanel:Open(itemId, ownItemCount * canSelectRewardCount)
            else
                self.SelectGiftPanel:Refresh(itemId)
            end
        else
            XLuaUiManager.Open("UiBagItemInfoPanel", data)
        end
    elseif self.PageRecord == XItemConfigs.PageType.Partner then
        XLuaUiManager.Open("UiPartnerMain", XPartnerConfigs.MainUiState.Overview, data, false, true)
    end
end

--选中Grid
function XUiBag:SelectGrid(data, grid)
    if self.Operation == XUiBag.OperationType.Decomposion then
        local equipId = data
        local cancelStar

        if self.SelectList[equipId] then
            self:CheckDecomposeRewardNotOverLimit(equipId, true)

            self.SelectList[equipId] = nil
            grid:SetSelected(false)

            if not XDataCenter.EquipManager.IsEquipResonanced(equipId) then--分解时不选中已共鸣过的装备，反选星级也不需要
                local equip = XDataCenter.EquipManager.GetEquip(equipId)
                cancelStar = XDataCenter.EquipManager.GetEquipStar(equip.TemplateId)
            end
        else
            if not self:CheckDecomposeRewardNotOverLimit(equipId) then
                return
            end

            self.SelectList[equipId] = equipId
            grid:SetSelected(true)
        end
        self.SidePopUpPanel:RefreshDecomposionPreView(self.SelectList, cancelStar)
        
    elseif self.Operation == XUiBag.OperationType.PartnerDecomposion then--zhang
        local Partner = data
        if self.SelectList[Partner] then
            self.SelectList[Partner] = nil
            grid:SetSelected(false)
        else
            self.SelectList[Partner] = Partner
            grid:SetSelected(true)
        end
        self.SidePopUpPanel:RefreshPartnerDecomposionPreView(self.SelectList)
    elseif self.Operation == XUiBag.OperationType.Recycle then

        local equipId = data
        local cancelStar

        if self.SelectList[equipId] then

            self.SelectList[equipId] = nil
            grid:SetSelected(false)

            local equip = XDataCenter.EquipManager.GetEquip(equipId)
            cancelStar = XDataCenter.EquipManager.GetEquipStar(equip.TemplateId)
        else

            self.SelectList[equipId] = equipId
            grid:SetSelected(true)

        end
        self.SidePopUpPanel:RefreshRecyclePreView(self.SelectList, cancelStar)

    elseif self.Operation == XUiBag.OperationType.Sell then
        if self.SelectList[data.GridIndex] and self.SelectList[data.GridIndex] == data.Data.Id then return end

        self.SelectList = {}    --单选
        self.SelectList[data.GridIndex] = data.Data.Id

        if self.LastSelectCommonGrid then
            self.LastSelectCommonGrid:SetSelectState(false)
        end
        self.LastSelectCommonGrid = grid
        self.LastSelectCommonGrid:SetSelectState(true)

        self.SidePopUpPanel:RefreshSellPreView(self.SelectList[data.GridIndex], 1, grid)

    elseif self.Operation == XUiBag.OperationType.Convert then
        local fragmentId = data.Data.Id
        local count = data.Data.Count
        if self.SelectList[fragmentId] then
            self.SelectList[fragmentId] = nil
            count = count * -1
            grid:SetSelectState(false)
        else
            self.SelectList[fragmentId] = count
            grid:SetSelectState(true)
        end
        self.SidePopUpPanel:RefreshConvertPreView(self.SelectList, count)
    end
end

--选中一个品质
---@param:isForDecomposion:操作类型为分解/回收
function XUiBag:SelectByStar(starCheckDic, state, isForDecomposion)
    if self.Operation ~= XUiBag.OperationType.Decomposion
    and self.Operation ~= XUiBag.OperationType.Recycle
    then return end

    for index, equipId in ipairs(self.PageDatas) do
        local equip = XDataCenter.EquipManager.GetEquip(equipId)
        local equipStar = XDataCenter.EquipManager.GetEquipStar(equip.TemplateId)
        local tmpState = state

        if starCheckDic[equipStar] and
        (not isForDecomposion or not XDataCenter.EquipManager.IsEquipResonanced(equipId))--分解时不选中已共鸣过的装备
        then
            if tmpState then
                if not self.SelectList[equipId] then
                    if not self:CheckDecomposeRewardNotOverLimit(equipId) then
                        break
                    end

                    self.SelectList[equipId] = equipId
                end
            else
                if self.SelectList[equipId] then
                    self:CheckDecomposeRewardNotOverLimit(equipId, true)
                    self.SelectList[equipId] = nil
                end
            end

            local grid = self.DynamicTable:GetGridByIndex(index)
            if grid then
                grid:SetSelectedEquip(tmpState)
            end
        end

    end

    if self.Operation == XUiBag.OperationType.Decomposion then
        self.SidePopUpPanel:RefreshDecomposionPreView(self.SelectList)
    elseif self.Operation == XUiBag.OperationType.Recycle then
        self.SidePopUpPanel:RefreshRecyclePreView(self.SelectList)
    end
end

function XUiBag:AutoAddListener()
    self:RegisterClickEvent(self.BtnSell, self.OnBtnSellClick)
    self:RegisterClickEvent(self.BtnOrder, self.OnBtnOrderClick)
    self:RegisterClickEvent(self.TogStar6, self.OnTogStar6Click)
    self:RegisterClickEvent(self.TogStar5, self.OnTogStar5Click)
    self:RegisterClickEvent(self.TogStar4, self.OnTogStar4Click)
    self:RegisterClickEvent(self.TogStar3, self.OnTogStar3Click)
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnDecomposion, self.OnBtnDecomposionClick)
    self:RegisterClickEvent(self.BtnRecycleOpen, self.OnBtnRecycleOpenClick)
    self:RegisterClickEvent(self.BtnConvert, self.OnBtnConvertClick)
    self:BindHelpBtn(self.BtnHelp, "UiBagHelp")
    
    self.PanelPartnerSort:GetObject("BtnPartnerOrder").CallBack = function()
        self:OnBtnOrderClick()
    end
    
    self.BtnCollection.CallBack = function() 
        self:OnBtnCollectionClick()
    end
end

function XUiBag:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiBag:OnBtnBackClick()
    if self.Operation ~= XUiBag.OperationType.Common then
        self:OperationTurn(XUiBag.OperationType.Common)
    elseif self.PageRecord == XItemConfigs.PageType.Awareness then
        self:PageTurn(XItemConfigs.PageType.SuitCover)
    else
        self:Close()
    end
end

function XUiBag:OnBtnSellClick()
    self:OperationTurn(XUiBag.OperationType.Sell)
end

function XUiBag:OnBtnDecomposionClick()
    if self.PageRecord == XItemConfigs.PageType.Partner then
        self:OperationTurn(XUiBag.OperationType.PartnerDecomposion)
    else
        self:OperationTurn(XUiBag.OperationType.Decomposion)
    end
end

function XUiBag:OnBtnRecycleOpenClick()
    self:OperationTurn(XUiBag.OperationType.Recycle)
end

function XUiBag:OnBtnConvertClick()
    local types = XUiBag.ItemPageToTypes[XUiBag.OperationType.Convert]
    local originData = XDataCenter.ItemManager.GetCanConvertItemsByTypes(types)
    if not originData or #originData == 0 then
        XUiManager.TipText("BagNoOverFragment")
        return
    end
    self:OperationTurn(XUiBag.OperationType.Convert)
end

function XUiBag:OnBtnOrderClick()
    self:OrderTypeTurn(not self.IsAscendOrder)
end

function XUiBag:OnTogStar6Click()
    self:StarToggleStateChange(6, self.TogStar6.isOn)
end

function XUiBag:OnTogStar5Click()
    self:StarToggleStateChange(5, self.TogStar5.isOn)
end

function XUiBag:OnTogStar4Click()
    self:StarToggleStateChange(4, self.TogStar4.isOn)
end

function XUiBag:OnTogStar3Click()
    self:StarToggleStateChange(3, self.TogStar3.isOn)
    self:StarToggleStateChange(2, self.TogStar3.isOn)
    self:StarToggleStateChange(1, self.TogStar3.isOn)
end

function XUiBag:OnBtnCollectionClick()
    XLuaUiManager.Open("UiItemCollectionMain")
end

--切换页签
function XUiBag:PageSelect(index)
    self:PageTurn(XUiBag.PageIndexGroup[index])
end

function XUiBag:PageTurn(page)
    if self.PageRecord == page then
        return
    end

    if self.CurAnimationTimerId then
        XScheduleManager.UnSchedule(self.CurAnimationTimerId)
        self.CurAnimationTimerId = nil
    end

    self.IsFirstAnimation = false
    self.PageRecord = page
    self:Refresh(true)
    if not self.SidePopUpPanel.CurState and not self.IsFirstAnimation then
        self:PlayAnimationWithMask("AnimNeiRongEnable")
    end
end

--切换操作
function XUiBag:OperationTurn(operation)
    self.Operation = operation
    self.SelectList = {}
    self.CurDecomposeRewardWeaponCount = nil
    self.CurDecomposeRewardAwarenessCount = nil

    self.SidePopUpPanel:ClearData()

    local isAscendOrder = self.Operation ~= XUiBag.OperationType.Common
    self:OrderTypeTurn(isAscendOrder)

    self:UpdatePanels()
end

--切换排序
function XUiBag:SortTypeTurn(index)
    self.SortType = index - 1
    self:UpdateDynamicTable(true)
    if not self.SidePopUpPanel.CurState and not self.IsFirstAnimation then
        self:PlayAnimationWithMask("AnimNeiRongEnable")
    end
end

--伙伴切换排序
function XUiBag:PartnerSortTypeTurn(index)
    self.PartnerSortType = index - 1
    self:UpdateDynamicTable(true)
end

--切换顺序
function XUiBag:OrderTypeTurn(isAscendOrder)
    self.IsAscendOrder = isAscendOrder
    self.ImgAscend.gameObject:SetActiveEx(self.IsAscendOrder)
    self.ImgDescend.gameObject:SetActiveEx(not self.IsAscendOrder)
    self.PanelPartnerSort:GetObject("ImgAscend").gameObject:SetActiveEx(self.IsAscendOrder)
    self.PanelPartnerSort:GetObject("ImgDescend").gameObject:SetActiveEx(not self.IsAscendOrder)
    self:UpdateDynamicTable(true)
    if not self.SidePopUpPanel.CurState and not self.IsFirstAnimation then
        self:PlayAnimationWithMask("AnimNeiRongEnable")
    end
end

--筛选同星级套装
function XUiBag:StarToggleStateChange(star, state)
    self.StarCheckList[star] = state
    self:UpdateDynamicTable(true)
    if not self.SidePopUpPanel.CurState and not self.IsFirstAnimation then
        self:PlayAnimationWithMask("AnimNeiRongEnable")
    end
end

--筛选材料类型
function XUiBag:SelectMaterialType(index)
    self.MaterailTypeRecord = index
    self:Refresh(true)
    if not self.SidePopUpPanel.CurState and not self.IsFirstAnimation then
        self:PlayAnimationWithMask("AnimNeiRongEnable")
    end
end

function XUiBag:OnCheckBtnItemRed(count)
    self.BtnTog2:ShowReddot(count >= 0)
end

function XUiBag:OnCheckBtnCollectRed(count)
    self.BtnCollection:ShowReddot(count >= 0)
end
