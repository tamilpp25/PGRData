local XUiArenaContributeTips = XLuaUiManager.Register(XLuaUi, "UiArenaContributeTips")
local XUiArenaContributeTipsGrid = require("XUi/XUiArena/XUiArenaContributeTipsGrid")
local CsXTextManagerGetText = CS.XTextManager.GetText

local TAB_TYPE = {
    EXPLAIN = 1, --说明
    OBTAIN = 2, --列表
}

function XUiArenaContributeTips:OnAwake()
    self:AutoAddListener()
end

--[[
    --@isNow: 
        true:当前竞技场的数据
        false:上一期的数据
    --@tabIndex：
        初始化时候对应要选中的页签：TAB_TYPE
]]
function XUiArenaContributeTips:OnStart(isNow, tabIndex)
    self.IsNow = isNow
    if self.IsNow then
        self.ChallengeCfg = XDataCenter.ArenaManager.GetCurChallengeCfg()
        self.ArenaLevel = XDataCenter.ArenaManager.GetCurArenaLevel()
    else
        self.ChallengeCfg = XDataCenter.ArenaManager.GetLastChallengeCfg()
        self.ArenaLevel = XDataCenter.ArenaManager.GetLastArenaLevel()
    end

    self:InitDynamicTable()
    self:InitTabGroup(tabIndex)
end

--@region 点击事件
function XUiArenaContributeTips:AutoAddListener()
    self:RegisterClickEvent(self.BtnTanchuangClose, self.OnBtnTangchuangCloseClick)
end

function XUiArenaContributeTips:OnBtnTangchuangCloseClick()
    self:Close()
end

function XUiArenaContributeTips:OnTabClick(index)
    self.SelectTabType = index
    self:Refresh()
end
--@endregion

function XUiArenaContributeTips:InitTabGroup(tabIndex)
    self.PanelTab:Init({
        self.BtnTab1,
        self.BtnTab2,
    }, function(index) 
        self:OnTabClick(index) 
    end)

    if tabIndex then
        self.PanelTab:SelectIndex(tabIndex)
    else
        self.PanelTab:SelectIndex(TAB_TYPE.EXPLAIN)
    end
end

function XUiArenaContributeTips:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.SViewContribute)
    self.DynamicTable:SetProxy(XUiArenaContributeTipsGrid)
    self.DynamicTable:SetDelegate(self)
end

function XUiArenaContributeTips:Refresh()
    if self.SelectTabType == TAB_TYPE.EXPLAIN then
        self.PanelExplain.gameObject:SetActiveEx(true)
        self.PanelObtain.gameObject:SetActiveEx(false)
        self:RefreshPanelExplain()
    elseif self.SelectTabType == TAB_TYPE.OBTAIN then
        self.PanelExplain.gameObject:SetActiveEx(false)
        self.PanelObtain.gameObject:SetActiveEx(true)
        self:RefreshPanelObtain()
    end
end

function XUiArenaContributeTips:RefreshPanelExplain()
    self.TxtContentNotice.text = string.gsub(CsXTextManagerGetText("ContributeScoreDesc"), "\\n", "\n")
end

function XUiArenaContributeTips:RefreshPanelObtain()
    local arenaLevelCfg = XArenaConfigs.GetArenaLevelCfgByLevel(self.ArenaLevel)
    self.List = self.ChallengeCfg.ContributeScore
    self.DynamicTable:SetDataSource(self.List)
    self.DynamicTable:ReloadDataSync()
    self.TxtPeople.text = #self.List
    self.TxtArena.text = self.ChallengeCfg.Name
    self.RImgIconArena:SetRawImage(arenaLevelCfg.Icon)
end

function XUiArenaContributeTips:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(index, self.List[index])
    end
end