local XINewRegressionChildManager = require("XEntity/XNewRegression/XINewRegressionChildManager")

--回归邀请
local XFettersManager = XClass(XINewRegressionChildManager, "XFettersManager")

--######################## 协议 ########################
--绑定邀请码请求
function XFettersManager:RequestRegression2InviteBindCode(inviteCode)
    local inviteManager = XDataCenter.NewRegressionManager.GetInviteManager()
    inviteManager:SetBindCodeRequestMark(true)

    XNetwork.Call("Regression2InviteBindCodeRequest", { InviteCode = inviteCode }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            inviteManager:SetBindCodeRequestMark(false)
            return
        end
    end)
end

--######################## XINewRegressionChildManager接口 ########################

-- 入口按钮排序权重，越小越前，可以重写自己的权重
function XFettersManager:GetButtonWeight()
    return tonumber(XNewRegressionConfigs.GetChildActivityConfig("FettersButtonWeight"))
end

-- 入口按钮显示名称
function XFettersManager:GetButtonName()
    return XNewRegressionConfigs.GetChildActivityConfig("FettersButtonName")
end

-- 获取面板控制数据
function XFettersManager:GetPanelContrlData()
    return {
        assetPath = XNewRegressionConfigs.GetChildActivityConfig("FettersPrefabAssetPath"),
        proxy = require("XUi/XUiNewRegression/Invite/XUiPanelFetters"),
    }
end

-- 用来显示页签和统一入口的小红点
-- 有未领取的奖励时，显示红点
function XFettersManager:GetIsShowRedPoint(...)
    local inviteManager = XDataCenter.NewRegressionManager.GetInviteManager()
    local totalPoint = inviteManager:GetAllPlayerTotalPoint()
    local inviteId = inviteManager:GetId()
    local rewardIdList = XNewRegressionConfigs.GetInviteRewardIdList(XNewRegressionConfigs.InviteState.Invitee, inviteId)

    local needPoint
    for _, inviteRewardId in ipairs(rewardIdList) do
        needPoint = XNewRegressionConfigs.GetInviteNeedPoint(inviteRewardId)
        if totalPoint < needPoint then
            return false
        end

        --判断是否已领取
        if not inviteManager:IsReceiveReward(inviteRewardId) then
            return true
        end
    end

    return false
end

-- 获取该子活动管理器是否开启
function XFettersManager:GetIsOpen()
    local inviteManager = XDataCenter.NewRegressionManager.GetInviteManager()
    if inviteManager:IsActivityOpen(XNewRegressionConfigs.InviteState.Invitee) then
        return XDataCenter.NewRegressionManager.GetIsOpen()
    end
    return false
end

return XFettersManager