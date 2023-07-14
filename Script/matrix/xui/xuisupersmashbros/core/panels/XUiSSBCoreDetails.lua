--==============
--超限乱斗核心页签面板
--==============
local XUiSSBCoreDetails = XClass(nil, "XUiSSBCoreDetails")

function XUiSSBCoreDetails:Ctor(uiPrefab)
    XTool.InitUiObjectByUi(self, uiPrefab)
    self:InitPanels()
end

function XUiSSBCoreDetails:InitPanels()
    self:InitPanelCoreDetails()
    self:InitPanelTrain()
end

function XUiSSBCoreDetails:InitPanelCoreDetails()
    local script = require("XUi/XUiSuperSmashBros/Core/Panels/XUiSSBCoreDetailsLeft")
    self.CoreDetails = script.New(self.PanelCoreDetails)
end

function XUiSSBCoreDetails:InitPanelTrain()
    local script = require("XUi/XUiSuperSmashBros/Core/Panels/XUiSSBCoreDetailsRight")
    self.Train = script.New(self.PanelTrain)
end
--============
--选中核心时刷新核心
--============
function XUiSSBCoreDetails:Refresh(core)
    self.Core = core
    self.CoreDetails:Refresh(core)
    self.Train:Refresh(core)
end
--============
--核心数据刷新时刷新页面
--============
function XUiSSBCoreDetails:OnCoreRefresh(isCoreLevelUp)
    self.CoreDetails:Refresh(self.Core)
    self.Train:OnlyRefreshPanel(self.Core, isCoreLevelUp)
    --self.Train:RefreshEvolution()
    --self.Train:RefreshGrowthRate()
end

return XUiSSBCoreDetails