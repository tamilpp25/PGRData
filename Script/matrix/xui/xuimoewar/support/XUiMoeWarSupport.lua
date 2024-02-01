local XUiMoeWarSupportGrid = require("XUi/XUiMoeWar/Support/XUiMoeWarSupportGrid")

--场外应援
local XUiMoeWarSupport = XLuaUiManager.Register(XLuaUi, "UiMoeWarSupport")

function XUiMoeWarSupport:OnAwake()
    self:AutoAddListener()
    self:InitAssetPanel()
    self:InitDynamicTable()
    self.TxtName.text = CS.XTextManager.GetText("MoeWarSupportViewTitle")
    self.GridReward.gameObject:SetActiveEx(false)
end

function XUiMoeWarSupport:OnEnable()
    self:Refresh()
    XDataCenter.MoeWarManager.JudgeGotoMainWhenFightOver()
end

function XUiMoeWarSupport:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    self:BindHelpBtn(self.BtnHelpCourse, "MoeWar")
end

function XUiMoeWarSupport:InitAssetPanel()
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool, self, true)
end

function XUiMoeWarSupport:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.SViewRewardList)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiMoeWarSupportGrid)

    self.EffectIdList = XMoeWarConfig.GetPreparationAssistanceEffectIdList(true)
    self.DynamicTable:SetDataSource(self.EffectIdList)
end

function XUiMoeWarSupport:Refresh()
    self.DynamicTable:ReloadDataSync()
    local allDifferVoteItemId = XMoeWarConfig.GetPreparationAssistanceAllDifferVoteItemId()
    self.AssetActivityPanel:Refresh(allDifferVoteItemId)
end

function XUiMoeWarSupport:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local effectId = self.EffectIdList[index]
        grid:Refresh(effectId)
    end
end