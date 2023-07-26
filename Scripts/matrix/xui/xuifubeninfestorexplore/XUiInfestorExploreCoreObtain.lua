local XUiGridInfestorExploreCore = require("XUi/XUiFubenInfestorExplore/XUiGridInfestorExploreCore")

local XUiInfestorExploreCoreObtain = XLuaUiManager.Register(XLuaUi, "UiInfestorExploreCoreObtain")

function XUiInfestorExploreCoreObtain:OnAwake()
    self:AutoAddListener()
end

function XUiInfestorExploreCoreObtain:OnStart(coreId, coreLevel, closeCb)
    self.CoreId = coreId
    self.CoreLevel = coreLevel
    self.CloseCb = closeCb
end

function XUiInfestorExploreCoreObtain:OnEnable()
    self.GridCore = self.GridCore or XUiGridInfestorExploreCore.New(self.GridInfestorExploreCore, self)
    self.GridCore:Refresh(self.CoreId, self.CoreLevel, true)
end

function XUiInfestorExploreCoreObtain:OnDestroy()
    if self.CloseCb then self.CloseCb() end
end

function XUiInfestorExploreCoreObtain:AutoAddListener()
    self.BtnClose.CallBack = function() self:Close() end
end