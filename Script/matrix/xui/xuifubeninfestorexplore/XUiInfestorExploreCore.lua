local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

local XUiGridInfestorExploreCore = require("XUi/XUiFubenInfestorExplore/XUiGridInfestorExploreCore")
local MAX_WEARING_NUM = 6

local XUiInfestorExploreCore = XLuaUiManager.Register(XLuaUi, "UiInfestorExploreCore")

function XUiInfestorExploreCore:OnAwake()
    self:AutoAddListener()
    self.GridCore.gameObject:SetActiveEx(false)
    self.GridWearingCore.gameObject:SetActiveEx(false)
    for i = 1, MAX_WEARING_NUM do
        self["ImgSelect" .. i].gameObject:SetActiveEx(false)
        self["PanelEffect" .. i].gameObject:SetActiveEx(false)
    end
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
end

function XUiInfestorExploreCore:OnStart()
    self.SelectPos = 1
    self.WearingCoreGrids = {}
    self:InitDynamicTable()
end

function XUiInfestorExploreCore:OnEnable()
    self:RefreshView()
end

function XUiInfestorExploreCore:OnGetEvents()
    return { XEventId.EVENT_INFESTOREXPLORE_CORE_PUTON
    , XEventId.EVENT_INFESTOREXPLORE_CORE_TAKEOFF
    , XEventId.EVENT_INFESTOREXPLORE_CORE_DECOMPOESE
    , XEventId.EVENT_INFESTOREXPLORE_RESET
    }
end

function XUiInfestorExploreCore:OnNotify(evt, ...)
    local args = { ... }
    if evt == XEventId.EVENT_INFESTOREXPLORE_CORE_PUTON then
        local pos = args[1]
        local panelEffect = self["PanelEffect" .. pos]
        panelEffect.gameObject:SetActiveEx(false)
        panelEffect.gameObject:SetActiveEx(true)
        self:RefreshView()
    elseif evt == XEventId.EVENT_INFESTOREXPLORE_CORE_TAKEOFF
    or evt == XEventId.EVENT_INFESTOREXPLORE_CORE_DECOMPOESE then
        self:RefreshView()
    elseif evt == XEventId.EVENT_INFESTOREXPLORE_RESET then
        XDataCenter.FubenInfestorExploreManager.Reset()
    end
end

function XUiInfestorExploreCore:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelEquipScroll)
    self.DynamicTable:SetProxy(XUiGridInfestorExploreCore)
    self.DynamicTable:SetDelegate(self)
end

function XUiInfestorExploreCore:RefreshView()
    local isShow = XDataCenter.FubenInfestorExploreManager.IsInSectionOne()
    self.BtnDecomposion.gameObject:SetActiveEx(isShow)

    local coreIds = XDataCenter.FubenInfestorExploreManager.GetCoreIds()
    self.CoreIds = coreIds

    local num = #coreIds
    self.TxtNumber.text = num
    self.PanelNoEquip.gameObject:SetActiveEx(num <= 0)

    self.DynamicTable:SetDataSource(coreIds)
    self.DynamicTable:ReloadDataASync()

    self:UpdateWearingCores()
end

function XUiInfestorExploreCore:UpdateWearingCores()
    local wearingCoreIdDic = XDataCenter.FubenInfestorExploreManager.GetWearingCoreIdDic()
    for pos = XFubenInfestorExploreConfigs.MaxWearingCoreNum, 1, -1 do
        local panelNoEquip = self["PanelNoEquip" .. pos]
        local coreId = wearingCoreIdDic[pos]
        local isWearing = coreId and coreId > 0
        local grid = self.WearingCoreGrids[pos]
        if isWearing then
            if not grid then
                local parent = self["PanelPos" .. pos]
                local go = CSUnityEngineObjectInstantiate(self.GridWearingCore, parent)
                go.transform:SetAsFirstSibling()
                local clickCb = function()
                    self:OnSelectPos(pos)
                end
                grid = XUiGridInfestorExploreCore.New(go, self, clickCb)
                self.WearingCoreGrids[pos] = grid
            end
            grid:Refresh(coreId)
            grid.GameObject:SetActiveEx(true)

            panelNoEquip.gameObject:SetActiveEx(false)
        else
            self.SelectPos = pos
            if grid then
                grid.GameObject:SetActiveEx(false)
            end

            panelNoEquip.gameObject:SetActiveEx(true)
        end
    end

    self:OnSelectPos(self.SelectPos, true)
end

function XUiInfestorExploreCore:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:InitRootUi(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local coreId = self.CoreIds[index]
        grid:Refresh(coreId)

        local isSelect = coreId == self.SelectCoreId
        grid:SetSelect(isSelect)
        if isSelect then
            self.LastSelectGrid = grid
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        if self.LastSelectGrid then
            self.LastSelectGrid:SetSelect(false)
        end
        self.LastSelectGrid = grid

        local coreId = self.CoreIds[index]
        self.SelectCoreId = coreId

        grid:SetSelect(true)

        self:OnSelectCorePopUp(coreId)
    end
end

function XUiInfestorExploreCore:OnSelectCorePopUp(coreId)
    local selectPos = self.SelectPos
    if not XLuaUiManager.IsUiShow("UiInfestorExploreCorePopup") then
        self.BtnClosePopup.gameObject:SetActiveEx(true)
        local closeCb = function()
            self.BtnClosePopup.gameObject:SetActiveEx(false)
        end
        XLuaUiManager.Open("UiInfestorExploreCorePopup", coreId, selectPos, closeCb)
    else
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_INFESTOREXPLORE_SELECT_CORE, coreId, selectPos)
    end
end

function XUiInfestorExploreCore:OnSelectPos(pos, isInit)
    self.SelectPos = pos

    if self.LastSelectPosGo then
        self.LastSelectPosGo.gameObject:SetActiveEx(false)
    end
    local imgSelect = self["ImgSelect" .. pos]
    imgSelect.gameObject:SetActiveEx(true)
    self.LastSelectPosGo = imgSelect

    local wearingCoreIdDic = XDataCenter.FubenInfestorExploreManager.GetWearingCoreIdDic()
    local coreId = wearingCoreIdDic[pos]
    local isWearing = coreId and coreId > 0
    if isWearing then
        if not isInit then
            self:OnSelectCorePopUp(coreId)
        end
    else
        self:OnClickBtnClosePopup()
    end
end

function XUiInfestorExploreCore:AutoAddListener()
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self.BtnDecomposion.CallBack = function() self:OnClickBtnDecomposion() end
    self.BtnClosePopup.CallBack = function() self:OnClickBtnClosePopup() end
    for index = 1, MAX_WEARING_NUM do
        self["BtnPos" .. index].CallBack = function()
            self:OnSelectPos(index)
        end
    end
    self:RegisterClickEvent(self.PanelEquipScroll, self.OnPanelEquipScrollClick)
end

function XUiInfestorExploreCore:OnBtnBackClick()
    self:OnClickBtnClosePopup()
    self:Close()
end

function XUiInfestorExploreCore:OnPanelEquipScrollClick()
    self:OnClickBtnClosePopup()
end

function XUiInfestorExploreCore:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiInfestorExploreCore:OnClickBtnClosePopup()
    if not XLuaUiManager.IsUiShow("UiInfestorExploreCorePopup") then
        return
    end

    if self.LastSelectGrid then
        self.LastSelectGrid:SetSelect(false)
        self.LastSelectGrid = nil
    end
    self.SelectCoreId = nil

    XLuaUiManager.Close("UiInfestorExploreCorePopup")
end

function XUiInfestorExploreCore:OnClickBtnDecomposion()
    self:OnClickBtnClosePopup()
    self:OpenChildUi("UiInfestorExploreCoreDecompose")
end