local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridRewardTip = require("XUi/XUiStronghold/XUiStrongholdReward/XUiGridRewardTip")

local CsXTextManagerGetText = CsXTextManagerGetText

local XUiStrongholdRewardTip = XLuaUiManager.Register(XLuaUi, "UiStrongholdRewardTip")

function XUiStrongholdRewardTip:OnAwake()
    self:AutoAddListener()
    self:InitDynamicTable()

    self.GridTask.gameObject:SetActiveEx(false)
end

function XUiStrongholdRewardTip:OnStart(levelId)
    if XTool.IsNumberValid(levelId) then
        self.LevelId = levelId

        local levelName = XStrongholdConfigs.GetLevelName(levelId)
        self.TxtTitle.text = CsXTextManagerGetText("StrongholdRewardTipTitle", levelName)
    else
        self.TxtTitle.text = CsXTextManagerGetText("StrongholdRewardTipTitleDefault")
    end

    local itemId = XDataCenter.StrongholdManager.GetMineralItemId()
    if not self.AssetPanel then
        self.AssetPanel = XUiHelper.NewPanelActivityAssetSafe({ itemId }, self.PanelSpecialTool, self)
    else
        self.AssetPanel:Refresh({ itemId })
    end
end

function XUiStrongholdRewardTip:OnEnable()
    self:UpdateRewards()
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
    end
end

function XUiStrongholdRewardTip:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.SViewTask)
    self.DynamicTable:SetProxy(XUiGridRewardTip)
    self.DynamicTable:SetDelegate(self)
end

function XUiStrongholdRewardTip:UpdateRewards()
    self.RewardIds = XDataCenter.StrongholdManager.GetAllRewardIds(self.LevelId)
    for _, reward in pairs(self.RewardIds) do
        if XDataCenter.StrongholdManager.IsRewardCanGet(reward) then
            table.insert(self.RewardIds, 1, -1) -- 一键领取标记
            break
        end
    end
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
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, self.OnClickBtnMainUi)
end

function XUiStrongholdRewardTip:OnClickBtnMainUi()
    XLuaUiManager.RunMain()
end