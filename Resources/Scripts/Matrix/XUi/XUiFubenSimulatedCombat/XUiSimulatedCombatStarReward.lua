local XUiSimulatedCombatStarReward = XLuaUiManager.Register(XLuaUi, "UiSimulatedCombatStarReward")

local XUiGridStarReward = require("XUi/XUiFubenSimulatedCombat/ChildItem/XUiGridStarReward")
function XUiSimulatedCombatStarReward:OnAwake()

    self.GridTreasureGrade.gameObject:SetActive(false)

    self.DynamicTable = XDynamicTableNormal.New(self.PanelTreasureGrade)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridStarReward)

    CsXUiHelper.RegisterClickEvent(self.BtnTreasureBg, handler(self, self.Close))
    self.BtnTanchuangCloseBig.CallBack = function() self:Close() end
end

function XUiSimulatedCombatStarReward:OnEnable()
    self:SetupStarReward(true)
end

function XUiSimulatedCombatStarReward:OnStart(rootUi)
    self.RootUi = rootUi
end

function XUiSimulatedCombatStarReward:OnGetEvents()
    return { XEventId.EVENT_FUBEN_SIMUCOMBAT_UPDATE }
end
function XUiSimulatedCombatStarReward:OnNotify(evt, ...)
    if evt == XEventId.EVENT_FUBEN_SIMUCOMBAT_UPDATE then
        self:SetupStarReward(...)
    end
end

function XUiSimulatedCombatStarReward:SetupStarReward(isFullReload)
    local starRewardList, _, startIndex = XDataCenter.FubenSimulatedCombatManager.GetStarRewardList()

    self.StarRewardList = starRewardList
 
    self.DynamicTable:SetDataSource(self.StarRewardList)
    if isFullReload then
        self.DynamicTable:ReloadDataSync(startIndex)
    end
end

function XUiSimulatedCombatStarReward:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid.RootUi = self
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.StarRewardList[index]
        if not data then return end
        grid:Refresh(data)
    end
end