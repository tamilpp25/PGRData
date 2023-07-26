local XUiDlcHuntTeamRankGrid = require("XUi/XUiDlcHunt/Rank/XUiDlcHuntTeamRankGrid")

---@class XUiDlcHuntTeamRank:XLuaUi
local XUiDlcHuntTeamRank = XLuaUiManager.Register(nil, "UiDlcHuntTeamRank")

function XUiDlcHuntTeamRank:Ctor()
    self._Tab = XDataCenter.DlcHuntManager.GetRankTab()
    self._ChapterId = false
end

function XUiDlcHuntTeamRank:OnAwake()
    self:BindExitBtns()
    -- uiDlcHunt hide panelAsset
    self.PanelAsset.gameObject:SetActiveEx(false)
    self.DynamicTable = XDynamicTableNormal.New(self.SViewRank)
    self.DynamicTable:SetProxy(XUiDlcHuntTeamRankGrid)
    self.DynamicTable:SetDelegate(self)
    ---@type XUiDlcHuntTeamRankGrid
    self._UiGridMine = XUiDlcHuntTeamRankGrid.New(self.PanelArenaSelfTeamRank)
    self.GridArenaTeamRank.gameObject:SetActiveEx(false)
end

function XUiDlcHuntTeamRank:OnStart()
    local tab = self._Tab
    local btnGroup = { }
    for i = 1, #tab do
        local uiObject = CS.UnityEngine.Object.Instantiate(self.BtnDlcTab.transform, self.BtnDlcTab.transform.parent)
        local componentButton = XUiHelper.TryGetComponent(uiObject, "", "XUiButton")
        btnGroup[#btnGroup + 1] = componentButton
        local tabData = tab[i]
        componentButton:SetName(tabData.Name)
    end

    self.PanelTags:Init(btnGroup, function(index)
        self:SetTabIndex(index)
        self:PlayAnimation("QieHuan")
    end)
    self.PanelTags:SelectIndex(1, true)
    self.BtnDlcTab.gameObject:SetActiveEx(false)
end

function XUiDlcHuntTeamRank:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_DLC_HUNT_RANK_UPDATE, self.Update, self)
end

function XUiDlcHuntTeamRank:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_HUNT_RANK_UPDATE, self.Update, self)
end

function XUiDlcHuntTeamRank:Update()
    if not self._ChapterId then
        self.ImgEmpty.gameObject:SetActiveEx(true)
        return
    end
    local rankData = XDataCenter.DlcHuntManager.GetRankData(self._ChapterId)
    if not rankData then
        self.ImgEmpty.gameObject:SetActiveEx(true)
        self._UiGridMine:Update(false)
        return
    end
    local dataProvider = rankData.List
    self.DynamicTable:SetDataSource(dataProvider)
    self.DynamicTable:ReloadDataASync()
    self._UiGridMine:Update(rankData.MyData)
    self.ImgEmpty.gameObject:SetActiveEx(#dataProvider <= 0)
end

function XUiDlcHuntTeamRank:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Update(self.DynamicTable:GetData(index))
    end
end

function XUiDlcHuntTeamRank:SetTabIndex(index)
    local data = self._Tab[index]
    self._ChapterId = data.ChapterId
    self:Update()
    XDataCenter.DlcHuntManager.RequestRank(data.ChapterId)
end

return XUiDlcHuntTeamRank