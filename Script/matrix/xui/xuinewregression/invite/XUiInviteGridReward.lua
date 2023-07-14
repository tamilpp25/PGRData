local handler = handler
local mathMin = math.min
local mathFloor = math.floor
local mathMax = math.max

local XUiInviteGridReward = XClass(nil, "XUiInviteGridReward")

function XUiInviteGridReward:Ctor(ui, rootUi, inviteRewardId)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.InviteRewardId = inviteRewardId
    XTool.InitUiObject(self)

    self:Init()
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClick)
end

function XUiInviteGridReward:Init()
    self.GridCommon = XUiGridCommon.New(self.RootUi, self.GridCommon)
    local inviteRewardId = self.InviteRewardId
    local rewardData = XNewRegressionConfigs.GetInviteRewardData(inviteRewardId)
    self.GridCommon:Refresh(rewardData)
    
    local needPoint = XNewRegressionConfigs.GetInviteNeedPoint(inviteRewardId)
    self.TxtPoint.text = needPoint
    self.TxtCurPoint.text = needPoint

    self.CanBtnClickReq = false --是否可以点击
end

function XUiInviteGridReward:UpdatePercent(curTotalPoint, preNeedPoint)
    local manager = XDataCenter.NewRegressionManager.GetInviteManager()
    local inviteRewardId = self.InviteRewardId
    local needPoint = XNewRegressionConfigs.GetInviteNeedPoint(inviteRewardId)
    local totalPoint = curTotalPoint or 0
    totalPoint = mathMax(0, totalPoint - preNeedPoint)
    needPoint = mathMax(0, needPoint - preNeedPoint)
    self.PanelPassedLine.fillAmount = XTool.IsNumberValid(needPoint) and mathMin(1, totalPoint / needPoint) or 0
end

function XUiInviteGridReward:UpdateReceiveState(curTotalPoint)
    local manager = XDataCenter.NewRegressionManager.GetInviteManager()
    local inviteRewardId = self.InviteRewardId

    local isReceive = manager:IsReceiveReward(inviteRewardId)
    self.PanelFinish.gameObject:SetActiveEx(isReceive)

    local totalPoint = curTotalPoint or manager:GetAllPlayerTotalPoint()
    local needPoint = XNewRegressionConfigs.GetInviteNeedPoint(inviteRewardId)
    local isCanReceive = totalPoint >= needPoint
    self.PanelEffect.gameObject:SetActiveEx(isCanReceive and not isReceive)

    self.TxtPoint.gameObject:SetActiveEx(not isCanReceive)
    self.PanelDot.gameObject:SetActiveEx(not isCanReceive)
    self.TxtCurPoint.gameObject:SetActiveEx(isCanReceive)
    self.PanelCurDot.gameObject:SetActiveEx(isCanReceive)
    if self.RootUi then --海外修改父级红点没同步问题
        self.RootUi:RefreshBtnsRedPoint()
    end
end

function XUiInviteGridReward:OnBtnClick()
    local rewardId = self.InviteRewardId
    local manager = XDataCenter.NewRegressionManager.GetInviteManager()

    --已领取奖励不做任何响应
    local isReceive = manager:IsReceiveReward(rewardId)
    if isReceive then
        return
    end

    --不可领取的奖励弹出道具详情
    local totalPoint = manager:GetAllPlayerTotalPoint()
    local needPoint = XNewRegressionConfigs.GetInviteNeedPoint(rewardId)
    if totalPoint < needPoint then
        self.GridCommon:OnBtnClickClick()
        return
    end

    manager:RequestRegression2InviteGetReward(rewardId, handler(self, self.UpdateReceiveState))
end

function XUiInviteGridReward:GetNeedPoint()
    local inviteRewardId = self.InviteRewardId
    return XNewRegressionConfigs.GetInviteNeedPoint(inviteRewardId)
end

function XUiInviteGridReward:GetIsPrimeReward()
    return XNewRegressionConfigs.GetInviteRewardIsPrimeReward(self.InviteRewardId)
end

function XUiInviteGridReward:GetRewardId()
    return self.InviteRewardId
end

return XUiInviteGridReward