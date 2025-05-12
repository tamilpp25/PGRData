local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiPanelDetailTeamItem = require("XUi/XUiCharacterDetail/XUiPanelDetailTeamItem")
local XUiPanelTeamInfo = XLuaUiManager.Register(XLuaUi, "UiPanelTeamInfo")

function XUiPanelTeamInfo:InitAutoScript()
    self:AutoInitUi()
    XTool.InitUiObject(self)
end

function XUiPanelTeamInfo:AutoInitUi()
    self.PanelDynamicLayout = self.Transform:Find("PanelDynamicLayout")
    self.PanelDetailTeamItem = self.Transform:Find("PanelDynamicLayout/Viewport/PanelDetailTeamItem")
end

function XUiPanelTeamInfo:OnAwake()
    self:InitAutoScript()
end

function XUiPanelTeamInfo:OnStart(CharacterId, rootUi)
    self.RootUi = rootUi
    self.CharacterId = CharacterId
    self.DynamicTable = XDynamicTableNormal.New(self.PanelDynamicLayout)
    self.DynamicTable:SetProxy(XUiPanelDetailTeamItem)
    self.DynamicTable:SetDelegate(self)
    self.PanelDetailTeamItem.gameObject:SetActive(false)
    self:InitTabBtnGroup()

    if not XDataCenter.VoteManager.IsInit() then
        XDataCenter.VoteManager.GetVoteGroupListRequest()
    end
end

function XUiPanelTeamInfo:OnEnable()
    self:SetupDynamicTable()
    XEventManager.AddEventListener(XEventId.EVENT_VOTE_REFRESH, self.SetupDynamicTable, self)
    self.RootUi:PlayAnimation("TeamInfoEnable")
end

function XUiPanelTeamInfo:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_VOTE_REFRESH, self.SetupDynamicTable, self)
    self.DynamicTable:Clear()
end

function XUiPanelTeamInfo:InitTabBtnGroup()
    local tabIdList = XMVCA.XCharacter:GetRecommendTabList(self.CharacterId, XEnumConst.CHARACTER.RecommendType.Character)
    if not tabIdList then
        return
    end

    local tabGroup = {}
    for i = 1, #tabIdList do
        local uiButton
        if i == 1 then
            uiButton = self.BtnTabMatch
        else
            local itemGo = CS.UnityEngine.Object.Instantiate(self.BtnTabMatch.gameObject)
            itemGo.transform:SetParent(self.PanelTagsLayoutRT, false)
            uiButton = itemGo.transform:GetComponent("XUiButton")
        end

        local config = XMVCA.XCharacter:GetRecommendTabTemplate(self.CharacterId, tabIdList[i], XEnumConst.CHARACTER.RecommendType.Character)
        uiButton:SetName(config.TabName)

        table.insert(tabGroup, uiButton)
    end

    self.PanelTagsLayout:Init(tabGroup, function(tabIndex) self:OnClickTabCallBack(tabIndex) end)
    self.PanelTagsLayout:SelectIndex(1)
end

function XUiPanelTeamInfo:OnClickTabCallBack(tabIndex)
    if self.CurTabId and self.CurTabId == tabIndex then
        return
    end
    self.CurTabId = tabIndex
    self.RootUi:PlayAnimation("DynamicLayoutQiehuan")
    self:SetupDynamicTable()
end

function XUiPanelTeamInfo:SetupDynamicTable()
    if not XDataCenter.VoteManager.IsInit() then
        return
    end

    local groupId = XMVCA.XCharacter:GetRecommendGroupId(self.CharacterId, self.CurTabId, XEnumConst.CHARACTER.RecommendType.Character)
    local Ids = XDataCenter.VoteManager.GetVoteIdListByGroupId(groupId)
    self.PageDatas = XMVCA.XCharacter:GetCharacterRecommendListByIds(Ids)

    if not self.PageDatas then
        self.PageDatas = {}
    end

    self.DynamicTable:SetDataSource(self.PageDatas)
    self.DynamicTable:ReloadDataASync()
end

function XUiPanelTeamInfo:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.UiProxy)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateView(self.PageDatas[index], index, self.CharacterId)
    end
end

return XUiPanelTeamInfo