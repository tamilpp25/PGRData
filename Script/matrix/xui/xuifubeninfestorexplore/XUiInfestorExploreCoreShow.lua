local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate
local CSXScheduleManagerScheduleOnce = XScheduleManager.ScheduleOnce
local CSXScheduleManagerUnSchedule = XScheduleManager.UnSchedule
local CLOSE_TIME = XScheduleManager.SECOND * 3

local XUiGridInfestorExploreCore = require("XUi/XUiFubenInfestorExplore/XUiGridInfestorExploreCore")

local XUiInfestorExploreCoreShow = XLuaUiManager.Register(XLuaUi, "UiInfestorExploreCoreShow")

function XUiInfestorExploreCoreShow:OnAwake()
    self.GridWearingCore.gameObject:SetActiveEx(false)
    self:CountDownClose()
end

function XUiInfestorExploreCoreShow:OnStart()
    self.WearingCoreGrids = {}
end

function XUiInfestorExploreCoreShow:OnEnable()
    self:RefreshView()
end

function XUiInfestorExploreCoreShow:OnDestroy()
    self:ClearTimer()
end

function XUiInfestorExploreCoreShow:RefreshView()
    self:UpdateWearingCores()
end

function XUiInfestorExploreCoreShow:UpdateWearingCores()
    local wearingCoreIdDic = XDataCenter.FubenInfestorExploreManager.GetWearingCoreIdDic()
    for pos = 1, XFubenInfestorExploreConfigs.MaxWearingCoreNum do
        local panelNoEquip = self["PanelNoEquip" .. pos]
        local coreId = wearingCoreIdDic[pos]
        local isWearing = coreId and coreId > 0
        local grid = self.WearingCoreGrids[pos]
        if isWearing then
            if not grid then
                local parent = self["PanelPos" .. pos]
                local go = CSUnityEngineObjectInstantiate(self.GridWearingCore, parent)
                go.transform:SetAsFirstSibling()
                grid = XUiGridInfestorExploreCore.New(go, self)
                self.WearingCoreGrids[pos] = grid
            end
            grid:Refresh(coreId)
            grid.GameObject:SetActiveEx(true)
            panelNoEquip.gameObject:SetActiveEx(false)
        else
            if grid then
                grid.GameObject:SetActiveEx(false)
            end
            panelNoEquip.gameObject:SetActiveEx(true)
        end
    end
end

function XUiInfestorExploreCoreShow:CountDownClose()
    if self.TimerId then
        self:ClearTimer()
    end

    self.TimerId = CSXScheduleManagerScheduleOnce(function()
        if not XTool.UObjIsNil(self.UiInfestorExploreCoreShow) then
            self:ClearTimer()
            self:Close()
        end
    end, CLOSE_TIME)
end

function XUiInfestorExploreCoreShow:ClearTimer()
    if self.TimerId then
        CSXScheduleManagerUnSchedule(self.TimerId)
        self.TimerId = nil
    end
end