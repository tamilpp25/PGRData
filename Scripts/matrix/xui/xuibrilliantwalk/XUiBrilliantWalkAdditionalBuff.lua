--显示被动技能的UI
local XUiBrilliantWalkAdditionalBuff = XLuaUiManager.Register(XLuaUi, "UiBrilliantWalkAdditionalBuff")
local XUIBrilliantWalkAdditionalBuffGrid = require("XUi/XUiBrilliantWalk/XUIGrid/XUIBrilliantWalkAdditionalBuffGrid")--grid
function XUiBrilliantWalkAdditionalBuff:OnAwake()
    --被动列表
    self.DynamicTable = XDynamicTableNormal.New(self.PanelChallengeText)
    self.DynamicTable:SetProxy(XUIBrilliantWalkAdditionalBuffGrid)
    self.DynamicTable:SetDelegate(self)
    self.GridBuffDetails.gameObject:SetActiveEx(false) --template
    --按钮
    self.BtnClose.CallBack = function()
        self:OnBtnClose()
    end
end
function XUiBrilliantWalkAdditionalBuff:OnStart()
    self:UpdateView() --执行一次便已足够
end
--刷新模块信息界面
function XUiBrilliantWalkAdditionalBuff:UpdateView()
    self.Configs = XBrilliantWalkConfigs.GetAdditionalBuffConfigs()
    self.DynamicTable:SetDataSource(self.Configs)
    self.DynamicTable:ReloadDataSync(1)
end
--刷新滚动页面
function XUiBrilliantWalkAdditionalBuff:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateView(self.Configs[index])
    end
end
--关闭按钮
function XUiBrilliantWalkAdditionalBuff:OnBtnClose()
    self.ParentUi:CloseMiniSubUI("UiBrilliantWalkAdditionalBuff")
end