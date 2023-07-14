local XUiGridInfestorShopReward = require("XUi/XUiFubenInfestorExplore/XUiGridInfestorShopReward")

local CSXTextManagerGetText = CS.XTextManager.GetText

local DialogTitle = CSXTextManagerGetText("InfestorExploreRewardNodeCloseTipTitle")
local DialogContent = CSXTextManagerGetText("InfestorExploreRewardNodeCloseTipContent")

local XUiInfestorExploreStageDetailRewardGive = XLuaUiManager.Register(XLuaUi, "UiInfestorExploreStageDetailRewardGive")

function XUiInfestorExploreStageDetailRewardGive:OnAwake()
    self:AutoAddListener()
    self.GridInfestorShopReward.gameObject:SetActiveEx(false)
end

function XUiInfestorExploreStageDetailRewardGive:OnStart(rewardIdList, chapterId, nodeId)
    self.RewardIdList = rewardIdList
    self.ChapterId = chapterId
    self.NodeId = nodeId

    self:InitDynamicTable()
    self.DynamicTable:SetDataSource(rewardIdList)
    self.DynamicTable:ReloadDataASync()
end

function XUiInfestorExploreStageDetailRewardGive:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelSelectList)
    self.DynamicTable:SetProxy(XUiGridInfestorShopReward)
    self.DynamicTable:SetDelegate(self)
end

function XUiInfestorExploreStageDetailRewardGive:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:InitRootUi(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local rewardId = self.RewardIdList[index]
        local chapterId = self.ChapterId
        local nodeId = self.NodeId
        grid:Refresh(rewardId, chapterId, nodeId)

        local isSelect = self.SelectRewardId and rewardId == self.SelectRewardId
        grid:SetSelect(isSelect)
        if isSelect then
            self.LastSelectGrid = grid
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        if self.LastSelectGrid then
            self.LastSelectGrid:SetSelect(false)
        end
        self.LastSelectGrid = grid

        local rewardId = self.RewardIdList[index]
        self.SelectRewardId = rewardId

        grid:SetSelect(true)
    end
end

function XUiInfestorExploreStageDetailRewardGive:AutoAddListener()
    self.BtnClose.CallBack = function() self:OnClickBtnClose() end
    self.BtnTanchuangClose.CallBack = function() self:OnClickBtnClose() end
    self.BtnConfirm.CallBack = function() self:OnClickBtnConfirm() end
end

function XUiInfestorExploreStageDetailRewardGive:OnClickBtnClose()
    local sureCallBack = function()
        XDataCenter.FubenInfestorExploreManager.RequestFinishAction(function()
            self:Close()
        end)
    end
    XUiManager.DialogTip(DialogTitle, DialogContent, XUiManager.DialogType.Normal, nil, sureCallBack)
end

function XUiInfestorExploreStageDetailRewardGive:OnClickBtnConfirm()
    local rewardId = self.SelectRewardId
    if not rewardId then
        XUiManager.TipText("InfestorExploreRewardNodeNotSelectReward")
        return
    end

    local msg = self.InputFiedMsg.text
    local callBack = function()
        XUiManager.TipText("InfestorExploreRewardNodeSelectRewardSuc")
        self:Close()
    end
    XDataCenter.FubenInfestorExploreManager.RequestSetSelectReward(rewardId, msg, callBack)
end