local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridChooseReward = require("XUi/XUiFubenInfestorExplore/XUiGridChooseReward")

local CSXTextManagerGetText = CS.XTextManager.GetText

local XUiInfestorExploreChoose = XLuaUiManager.Register(XLuaUi, "UiInfestorExploreChoose")

function XUiInfestorExploreChoose:OnAwake()
    self:AutoAddListener()
    self.GridChooseReward.gameObject:SetActiveEx(false)
end

function XUiInfestorExploreChoose:OnStart(closeCb)
    self.CloseCb = closeCb

    self:InitDynamicTable()
    self:UpdateView()
end

function XUiInfestorExploreChoose:OnDestroy()
    if self.CloseCb then self.CloseCb() end
end

function XUiInfestorExploreChoose:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelReward)
    self.DynamicTable:SetProxy(XUiGridChooseReward)
    self.DynamicTable:SetDelegate(self)
end

function XUiInfestorExploreChoose:UpdateView()
    local fightRewardIds = XDataCenter.FubenInfestorExploreManager.GetFightRewardIds()
    self.FightRewardIds = fightRewardIds

    local buyTimes = XDataCenter.FubenInfestorExploreManager.GetFightRewadBuyTimes()
    local hasBuy = buyTimes > 0
    self.BtnBack.gameObject:SetActiveEx(hasBuy)

    self.DynamicTable:SetDataSource(fightRewardIds)
    self.DynamicTable:ReloadDataASync()
    self:UpdateMoney()
end

function XUiInfestorExploreChoose:UpdateMoney()
    local count = XDataCenter.FubenInfestorExploreManager.GetMoneyCount()
    self.TxtCost.text = "x" .. count
end

function XUiInfestorExploreChoose:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:InitRootUi(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local rewardId = self.FightRewardIds[index]
        grid:Refresh(rewardId)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local rewardId = self.FightRewardIds[index]

        local isRewardBuy = XDataCenter.FubenInfestorExploreManager.IsFightRewadBuy(rewardId)
        if isRewardBuy then return end

        local buyTimes = XDataCenter.FubenInfestorExploreManager.GetFightRewadBuyTimes()
        local cost = XFubenInfestorExploreConfigs.GetFightRewardCost(buyTimes + 1)
        local moneyName = XDataCenter.FubenInfestorExploreManager.GetMoneyName()
        if not XDataCenter.FubenInfestorExploreManager.CheckMoneyEnough(cost) then
            XUiManager.TipMsg(CSXTextManagerGetText("InfestorExploreFightRewardMoneyLack", moneyName))
        else
            local buyFunc = function()
                local callBack = function()
                    self:UpdateView()
                end
                XDataCenter.FubenInfestorExploreManager.RequestInfestorExploreBuyFightReward(rewardId, callBack)
            end

            if cost > 0 then
                local title = CSXTextManagerGetText("InfestorExploreFightRewardConfirmTitle")
                local coreId = XFubenInfestorExploreConfigs.GetRewardCoreId(rewardId)
                local coreName = XFubenInfestorExploreConfigs.GetCoreName(coreId)
                local content = CSXTextManagerGetText("InfestorExploreFightRewardConfirmContent", cost, moneyName, coreName)
                local sureCallback = function()
                    buyFunc()
                end
                XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, sureCallback)
            else
                XDataCenter.FubenInfestorExploreManager.SetOpenInfestorExploreCoreDelay(1000)
                buyFunc()
            end
        end
    end
end

function XUiInfestorExploreChoose:AutoAddListener()
    self.BtnBack.CallBack = function() self:OnClickBtnBack() end
    self.BtnRImgCost.CallBack = function() self:OnClickRImgCostBack() end
end

function XUiInfestorExploreChoose:OnClickBtnBack()
    local callBack = function()
        XDataCenter.FubenInfestorExploreManager.ClearFightRewards()
    end
    XDataCenter.FubenInfestorExploreManager.RequestFinishAction(callBack)

    self:Close()
end

function XUiInfestorExploreChoose:OnClickRImgCostBack()
    local data = {
        Id = XDataCenter.ItemManager.ItemId.InfestorMoney,
        Count = XDataCenter.FubenInfestorExploreManager.GetMoneyCount()
    }
    XLuaUiManager.Open("UiTip", data)
end