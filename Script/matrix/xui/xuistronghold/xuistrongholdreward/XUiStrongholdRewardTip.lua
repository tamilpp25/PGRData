local XUiGridRewardTip = require("XUi/XUiStronghold/XUiStrongholdReward/XUiGridRewardTip")

local CsXTextManagerGetText = CsXTextManagerGetText

local XUiStrongholdRewardTip = XLuaUiManager.Register(XLuaUi, "UiStrongholdRewardTip")

function XUiStrongholdRewardTip:OnAwake()
    self:AutoAddListener()
    self:InitRewardGroup()
    self:InitDynamicTable()

    self.GridPrequelCheckPointReward.gameObject:SetActiveEx(false)
end

function XUiStrongholdRewardTip:OnStart(levelId)
    if XTool.IsNumberValid(levelId) then
        self.LevelId = levelId

        local levelName = XStrongholdConfigs.GetLevelName(levelId)
        self.TxtTitle.text = CsXTextManagerGetText("StrongholdRewardTipTitle", levelName)
    else
        self.TxtTitle.text = CsXTextManagerGetText("StrongholdRewardTipTitleDefault")
    end

    self:DefaultSelectTab()
end

function XUiStrongholdRewardTip:OnEnable()

    self:UpdateRewards()
    self:UpdateRedPoint()
end

function XUiStrongholdRewardTip:OnDisable()

end

function XUiStrongholdRewardTip:OnGetEvents()
    return {
        XEventId.EVENT_STRONGHOLD_FINISH_REWARDS_CHANGE,
    }
end

function XUiStrongholdRewardTip:OnNotify(evt, ...)
    if evt == XEventId.EVENT_STRONGHOLD_FINISH_REWARDS_CHANGE then
        self:UpdateRewards()
        self:UpdateRedPoint()
    end
end

function XUiStrongholdRewardTip:DefaultSelectTab()
    local rewardGroupList = XStrongholdConfigs.GetRewardGroupList()
    local index
    for i, rewardType in ipairs(rewardGroupList) do
        if XDataCenter.StrongholdManager.IsAnyRewardCanGet(rewardType) then
            index = i
            break
        end
    end
    self.PanelTab:SelectIndex(index or 1)
end

function XUiStrongholdRewardTip:InitRewardGroup()
    self.BtnGroupList = {}
    local rewardGroupList = XStrongholdConfigs.GetRewardGroupList()
    for i, rewardType in ipairs(rewardGroupList) do
        local gridTab = i == 1 and self.GridTab or XUiHelper.Instantiate(self.GridTab, self.PanelTab.transform)
        gridTab:SetName(XStrongholdConfigs.GetRewardGroupName(rewardType))
        table.insert(self.BtnGroupList, gridTab)
    end

    self.PanelTab:Init(self.BtnGroupList, function(index) self:OnSelectedTag(index) end)
    self.RewardGroupList = rewardGroupList
end

function XUiStrongholdRewardTip:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.SViewRewardList)
    self.DynamicTable:SetProxy(XUiGridRewardTip)
    self.DynamicTable:SetDelegate(self)
end

function XUiStrongholdRewardTip:UpdateRewards()
    local rewardType = self.CurrSelectTagIndex and self.RewardGroupList[self.CurrSelectTagIndex]
    self.RewardIds = XDataCenter.StrongholdManager.GetAllRewardIds(self.LevelId, rewardType)
    self.DynamicTable:SetDataSource(self.RewardIds)
    self.DynamicTable:ReloadDataASync()
end

function XUiStrongholdRewardTip:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:InitRootUi(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local rewardId = self.RewardIds[index]
        grid:Refresh(rewardId, self.LevelId)
    end
end

function XUiStrongholdRewardTip:AutoAddListener()
    self.BtnTanchuangClose.CallBack = function() self:Close() end
end

function XUiStrongholdRewardTip:OnSelectedTag(index)
    if self.CurrSelectTagIndex == index then
        return
    end

    self.CurrSelectTagIndex = index
    self:UpdateRewards()
end

function XUiStrongholdRewardTip:UpdateRedPoint()
    local rewardGroupList = XStrongholdConfigs.GetRewardGroupList()
    local isShow
    for i, rewardType in ipairs(rewardGroupList) do
        isShow = XDataCenter.StrongholdManager.IsAnyRewardCanGet(rewardType)
        self.BtnGroupList[i]:ShowReddot(isShow)
    end
end