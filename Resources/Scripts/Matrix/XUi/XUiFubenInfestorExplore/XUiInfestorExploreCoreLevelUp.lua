local XUiGridInfestorExploreCore = require("XUi/XUiFubenInfestorExplore/XUiGridInfestorExploreCore")

local XUiInfestorExploreCoreLevelUp = XLuaUiManager.Register(XLuaUi, "UiInfestorExploreCoreLevelUp")

function XUiInfestorExploreCoreLevelUp:OnAwake()
    self:AutoAddListener()
end

function XUiInfestorExploreCoreLevelUp:OnStart(coreId, oldLevel, newLevel, closeCb)
    self.CoreId = coreId
    self.CloseCb = closeCb
    self.OldLevel = oldLevel
    self.NewLevel = newLevel
end

function XUiInfestorExploreCoreLevelUp:OnEnable()
    self.GridCore = self.GridCore or XUiGridInfestorExploreCore.New(self.GridInfestorExploreCore, self)
    self.GridCore:Refresh(self.CoreId, nil, true)

    local oldLevel = self.OldLevel
    local newLevel = self.NewLevel
    for index = oldLevel + 1, newLevel do
        self["Timeline" .. index]:PlayTimelineAnimation()
    end
end

function XUiInfestorExploreCoreLevelUp:OnDestroy()
    if self.CloseCb then self.CloseCb() end
end

function XUiInfestorExploreCoreLevelUp:AutoAddListener()
    self.BtnClose.CallBack = function() self:Close() end
end