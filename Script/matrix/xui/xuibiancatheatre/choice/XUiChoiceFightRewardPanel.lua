local XUiRewardGrid = require("XUi/XUiBiancaTheatre/Common/XUiRewardGrid")

local XUiChoiceFightRewardPanel = XClass(nil, "XUiChoiceFightRewardPanel")

--选择战斗奖励布局
function XUiChoiceFightRewardPanel:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XUiHelper.InitUiClass(self, ui)
end

function XUiChoiceFightRewardPanel:Init()
    self.CurrentAdventureManager = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager()
    self:InitRewardGrids()
    self.GridChallengeBanner.gameObject:SetActiveEx(false)
    self:RewriteRootUiFunc()
    self.GameObject:SetActiveEx(true)
end

function XUiChoiceFightRewardPanel:InitRewardGrids()
    self.RewardGridList = {}
    self.CurStep = self.CurrentAdventureManager and self.CurrentAdventureManager:GetCurrentChapter():GetCurStep()    --XAdventureStep
    self.FightRewards = self.CurStep:GetNotReceivedFightRewards()   --XARewardNode的列表

    self.DynamicTable = XDynamicTableNormal.New(self.Transform:GetComponent(typeof(CS.XDynamicTableNormal)))
    self.DynamicTable:SetProxy(XUiRewardGrid, handler(self, self.OnClickReward))
    self.DynamicTable:SetDelegate(self)
    self.GridChallengeBanner.gameObject:SetActiveEx(false)
end

function XUiChoiceFightRewardPanel:Refresh()
    local isShowPanelNone = true
    local fightRewards = {}
    for _, rewardNode in ipairs(self.FightRewards) do
        if not rewardNode:IsReceived() then
            isShowPanelNone = false
            table.insert(fightRewards, rewardNode)
        end
    end
    self.RootUi:SetPanelNoneActive(isShowPanelNone)

    self.DynamicTable:SetDataSource(fightRewards)
    self.DynamicTable:ReloadDataASync()
end

function XUiChoiceFightRewardPanel:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.DynamicTable:GetData(index))
    end
end

function XUiChoiceFightRewardPanel:OnClickReward(rewardGrid)
    local rewardNode = rewardGrid:GetRewardNode()
    self.CurrentAdventureManager:RequestRecvFightReward(rewardNode:GetUid(), function()
        --除获得代币外，其他奖励类型会外部关闭本界面
        if rewardNode:GetRewardType() == XBiancaTheatreConfigs.AdventureRewardType.Gold then
            self:Refresh()
        end
    end, self.FightRewards)
end

--######################## 重写父UI按钮点击回调 ########################
function XUiChoiceFightRewardPanel:RewriteRootUiFunc()
    XUiHelper.RegisterClickEvent(self, self.RootUi.BtnNextStep, self.OnBtnNextStepClicked)
end

--点击下一步
function XUiChoiceFightRewardPanel:OnBtnNextStepClicked()
    if not XTool.IsTableEmpty(self.DynamicTable:GetGrids()) then
        local title = XUiHelper.GetText("TipTitle")
        local content = XBiancaTheatreConfigs.GetClientConfig("FightRewardEndRecvTipsDesc")
        XLuaUiManager.Open("UiBiancaTheatreEndTips", title, content, XUiManager.DialogType.Normal, nil, handler(self, self.RequestEndRecvFightReward))
        return
    end
    self:RequestEndRecvFightReward()
end

function XUiChoiceFightRewardPanel:RequestEndRecvFightReward()
    self.CurrentAdventureManager:RequestEndRecvFightReward()
end

return XUiChoiceFightRewardPanel