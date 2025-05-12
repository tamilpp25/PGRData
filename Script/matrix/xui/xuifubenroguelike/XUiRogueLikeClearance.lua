local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiRogueLikeClearance = XLuaUiManager.Register(XLuaUi, "UiRogueLikeClearance")
local XUiRogueLikeClearanceScoreItem = require("XUi/XUiFubenRogueLike/XUiRogueLikeClearanceScoreItem")
function XUiRogueLikeClearance:OnAwake()
    
    self.BtnClose.CallBack = function() self:Close() end
    self.BtnTanchuangClose.CallBack = function() self:Close() end

    self.DynamicTable = XDynamicTableNormal.New(self.PanelDynamicTable)
    self.DynamicTable:SetProxy(XUiRogueLikeClearanceScoreItem)
    self.DynamicTable:SetDelegate(self)
    
    self.ScoreItem.gameObject:SetActiveEx(false)
end

function XUiRogueLikeClearance:OnStart(rootUi)
    self.RootUi = rootUi
    
end

function XUiRogueLikeClearance:OnEnable()
    XDataCenter.FubenRogueLikeManager.SetNeedShowTrialPointView(false)
    self:InitDynamicTable()
end

function XUiRogueLikeClearance:InitDynamicTable()
    self.ScoreDatas = XDataCenter.FubenRogueLikeManager.GetRogueLikeTrialPointDatas()
    local scoreTatol = 0
    for _, data in ipairs(self.ScoreDatas) do
        scoreTatol = scoreTatol + data.Point
    end
    self.TextFraction.text = scoreTatol
    self.DynamicTable:SetDataSource(self.ScoreDatas)
    self.DynamicTable:ReloadDataASync(-1)
end

--动态列表事件
function XUiRogueLikeClearance:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init()
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.ScoreDatas[index]
        grid:UpdateViewByData(data)
    end
end