local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local next = next
local tableInsert = table.insert

local XUiGridInfestorExploreCore = require("XUi/XUiFubenInfestorExplore/XUiGridInfestorExploreCore")

local XUiInfestorExploreCoreDecompose = XLuaUiManager.Register(XLuaUi, "UiInfestorExploreCoreDecompose")

function XUiInfestorExploreCoreDecompose:OnAwake()
    self:AutoAddListener()
    self.GridCore.gameObject:SetActiveEx(false)
end

function XUiInfestorExploreCoreDecompose:OnStart()
    self.RImgItem:SetRawImage(XDataCenter.FubenInfestorExploreManager.GetMoneyIcon())
    self:InitDynamicTable()
end

function XUiInfestorExploreCoreDecompose:OnEnable()
    self:Refresh()
end

function XUiInfestorExploreCoreDecompose:OnGetEvents()
    return { XEventId.EVENT_INFESTOREXPLORE_CORE_DECOMPOESE }
end

function XUiInfestorExploreCoreDecompose:OnNotify(evt, ...)
    if evt == XEventId.EVENT_INFESTOREXPLORE_CORE_DECOMPOESE then
        self:Refresh()
    end
end

function XUiInfestorExploreCoreDecompose:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelEquipScroll)
    self.DynamicTable:SetProxy(XUiGridInfestorExploreCore)
    self.DynamicTable:SetDelegate(self)
end

function XUiInfestorExploreCoreDecompose:Refresh()
    local coreIds = XTool.ReverseList(XDataCenter.FubenInfestorExploreManager.GetCoreIds())
    self.CoreIds = coreIds

    local num = #coreIds
    self.TxtHaveNumber.text = num
    self.PanelNoEquip.gameObject:SetActiveEx(num <= 0)

    self.SelectCoreIdCheckTable = {}
    self.DynamicTable:SetDataSource(coreIds)
    self.DynamicTable:ReloadDataASync()
    self:OnSelectCoreChange()
end

function XUiInfestorExploreCoreDecompose:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:InitRootUi(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local coreId = self.CoreIds[index]
        grid:Refresh(coreId)

        local isSelect = self.SelectCoreIdCheckTable[coreId]
        grid:SetSelect(isSelect)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local coreId = self.CoreIds[index]
        local isSelect = self.SelectCoreIdCheckTable[coreId]

        if not isSelect then
            grid:SetSelect(true)
            self.SelectCoreIdCheckTable[coreId] = coreId
        else
            grid:SetSelect(false)
            self.SelectCoreIdCheckTable[coreId] = nil
        end

        self:OnSelectCoreChange()
    end
end

function XUiInfestorExploreCoreDecompose:OnSelectCoreChange()
    local selectCoreIds = self:GetSelectCoreIdList()

    local selectNum = #selectCoreIds
    self.TxtSelected.text = selectNum

    local rewardMoneyCount = XDataCenter.FubenInfestorExploreManager.GetCoreDecomposeMoney(selectCoreIds)
    self.TxtNumber.text = rewardMoneyCount
end

function XUiInfestorExploreCoreDecompose:AutoAddListener()
    self:RegisterClickEvent(self.BtnClosePopup, self.Close)
    self.BtnTanchuangClose.CallBack = function() self:Close() end
    self.BtnDecompose.CallBack = function() self:OnClickBtnDecompose() end
    self.BtnRImgItem.CallBack = function() self:OnClickRImgCostBack() end
end

function XUiInfestorExploreCoreDecompose:OnClickBtnDecompose()
    local coreIds = self:GetSelectCoreIdList()
    if not next(coreIds) then
        XUiManager.TipText("InfestorExploreCoreDecomposeEmpty")
        return
    end

    XDataCenter.FubenInfestorExploreManager.RequestInfestorExploreDecomposeCore(coreIds)
end

function XUiInfestorExploreCoreDecompose:GetSelectCoreIdList()
    local selectCoreIds = {}
    for id in pairs(self.SelectCoreIdCheckTable) do
        tableInsert(selectCoreIds, id)
    end
    return selectCoreIds
end

function XUiInfestorExploreCoreDecompose:OnClickRImgCostBack()
    local data = {
        Id = XDataCenter.ItemManager.ItemId.InfestorMoney,
        Count = XDataCenter.FubenInfestorExploreManager.GetMoneyCount()
    }
    XLuaUiManager.Open("UiTip", data)
end