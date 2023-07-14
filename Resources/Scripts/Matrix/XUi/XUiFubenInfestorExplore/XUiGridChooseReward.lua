local XUiGridInfestorExploreCore = require("XUi/XUiFubenInfestorExplore/XUiGridInfestorExploreCore")

local CONDITION_COLOR = {
    [true] = CS.UnityEngine.Color.black,
    [false] = CS.UnityEngine.Color.red,
}

local XUiGridChooseReward = XClass(nil, "XUiGridChooseReward")

function XUiGridChooseReward:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    local icon = XDataCenter.FubenInfestorExploreManager.GetMoneyIcon()
    self.RImgCost:SetRawImage(icon)

    self.PanelRewards.gameObject:SetActiveEx(false)

    self.IsFirstPlayFanpai = true
end

function XUiGridChooseReward:InitRootUi(rootUi)
    self.RootUi = rootUi
end

function XUiGridChooseReward:Refresh(rewardId)
    self.GridCore = self.GridCore or XUiGridInfestorExploreCore.New(self.GridInfestorExploreCore, self.RootUi)
    local coreId = XFubenInfestorExploreConfigs.GetRewardCoreId(rewardId)
    local coreLevel = XFubenInfestorExploreConfigs.GetRewardCoreLevel(rewardId)
    self.GridCore:Refresh(coreId, coreLevel)

    local buyTimes = XDataCenter.FubenInfestorExploreManager.GetFightRewadBuyTimes()
    if buyTimes > 0 then
        local isRewardBuy = XDataCenter.FubenInfestorExploreManager.IsFightRewadBuy(rewardId)
        if isRewardBuy then
            self.TxtSpend.gameObject:SetActiveEx(false)
            self.TxtSellOut.gameObject:SetActiveEx(true)
        else
            local cost = XFubenInfestorExploreConfigs.GetFightRewardCost(buyTimes + 1)
            self.TxtSpend.text = cost
            self.TxtSpend.color = CONDITION_COLOR[XDataCenter.FubenInfestorExploreManager.CheckMoneyEnough(cost)]

            self.TxtSpend.gameObject:SetActiveEx(true)
            self.TxtSellOut.gameObject:SetActiveEx(false)
        end
        --获得品质
        local quality = XFubenInfestorExploreConfigs.GetCoreQuality(coreId)
        --1 金色 2 紫色
        if self.IsFirstPlayFanpai then
            self.IsFirstPlayFanpai = false
            if XFubenInfestorExploreConfigs.IsPrecious(quality) then
                XScheduleManager.ScheduleOnce(function()
                    self.UiFanpai1:Play()
                end, 0)
            else
                XScheduleManager.ScheduleOnce(function()
                    self.UiFanpai2:Play()
                end, 0)
            end
        end
        self.PanelLock.gameObject:SetActiveEx(false)
    else
        self.PanelLock.gameObject:SetActiveEx(true)
    end
end

return XUiGridChooseReward