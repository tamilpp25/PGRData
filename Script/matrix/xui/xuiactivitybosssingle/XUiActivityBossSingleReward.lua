local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiBossSingleTreasureGrid = require("XUi/XUiActivityBossSingle/XUiBossSingleTreasureGrid")
local XUiActivityBossSingleReward = XLuaUiManager.Register(XLuaUi, "UiActivityBossSingleReward")

function XUiActivityBossSingleReward:OnStart(sectionId, cb)
    self.CallBack = cb
    self.SectionId = sectionId
    self.StarRewardIds = XFubenActivityBossSingleConfigs.GetBossSectionRewardIds(sectionId)
    self:InitDynamicList()
    self:AutoAddListener()
    self:Refresh()
    self:PlayAnimation("AnimEnable")
end

function XUiActivityBossSingleReward:InitDynamicList()
    self.DynamicTable = XDynamicTableNormal.New(self.SViewRewardList)
    self.DynamicTable:SetProxy(XUiBossSingleTreasureGrid)
    self.DynamicTable:SetDelegate(self)
end

function XUiActivityBossSingleReward:AutoAddListener()
    self.BtnClose.CallBack = function()
        self:OnBtnCloseClick()
    end
end

function XUiActivityBossSingleReward:Refresh()
    self.DynamicTable:SetDataSource(self.StarRewardIds)
    self.DynamicTable:ReloadDataASync()
end

function XUiActivityBossSingleReward:OnBtnCloseClick()
    self:Close()
    if self.CallBack ~= nil then
        self.CallBack()
    end
end

function XUiActivityBossSingleReward:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Refresh(self, self.StarRewardIds[index])
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self, self.StarRewardIds[index])
    end
end