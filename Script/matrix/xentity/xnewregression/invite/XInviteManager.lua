local XINewRegressionChildManager = require("XEntity/XNewRegression/XINewRegressionChildManager")
local XInviteBindedPlayer = require("XEntity/XNewRegression/Invite/XInviteBindedPlayer")
-- local Json = require("XCommon/Json")

--活跃邀请
local XInviteManager = XClass(XINewRegressionChildManager, "XInviteManager")

local Default = {
    _Id = 0,
    _State = 0,              --活动开启状态
    _TotalPoint = 0,         --总积分
    _LastDayTotalPoint = 0,  --每日重置前总积分
    _DailyPoint = 0,         --当日积分
    _DailyConsumeCount = 0,  --当日体力
    _BindedPlayers = {},     --邀请活动关联玩家数据
    _Rewards = {},           --已领奖励
    _Code = "",              --邀请码
}

function XInviteManager:Ctor()
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end

    self.BindCodeRequestMark = false
    self._BindedPlayerIdList = {}    --邀请活动关联玩家Id列表
end

-- data : XRegression2InviteData
function XInviteManager:InitWithServerData(data)
    if not data then
        return
    end
    self._Id = data.Id
    self._State = data.State
    self._TotalPoint = data.TotalPoint
    self._LastDayTotalPoint = data.LastDayTotalPoint
    self._DailyPoint = data.DailyPoint
    self._DailyConsumeCount = data.DailyConsumeCount
    self._Code = data.Code

    local playerIdList = {}
    self._BindedPlayers = {}
    self._BindedPlayerIdList = {}
    for i, playerData in ipairs(data.BindedPlayers) do
        local playerId = playerData.PlayerId
        table.insert(self._BindedPlayerIdList, playerId)

        self._BindedPlayers[playerId] = XInviteBindedPlayer.New()
        self._BindedPlayers[playerId]:UpdateData(data)
        table.insert(playerIdList, playerId)
    end

    --设置绑定的玩家头像和名字
    if not XTool.IsTableEmpty(playerIdList) then
        XDataCenter.SocialManager.GetPlayerInfoListByServer(playerIdList, function(playerInfoList)
            local playerId
            for _, playerInfo in pairs(playerInfoList) do
                playerId = playerInfo.Id
                if self._BindedPlayers[playerId] then
                    self._BindedPlayers[playerId]:UpdatePlayerData(playerInfo)
                end
            end
        end)
    end

    self._Rewards = {}
    for _, rewardId in ipairs(data.Rewards) do
        self._Rewards[rewardId] = true
    end
end

-- data : NotifyRegression2InvitePoint
function XInviteManager:UpdateWithServerData(data)
    self._Id = data.Id
    self._TotalPoint = data.TotalPoint
    self._DailyPoint = data.DailyPoint
    self._Code = data.Code

    --绑定玩家数据, 为null表示不更新
    local playerIdList = {}
    local playerId
    local playerTemplate
    for _, playerData in ipairs(data.BindedPlayers) do
        playerId = playerData.PlayerId
        playerTemplate = self._BindedPlayers[playerId]
        if not playerTemplate then
            playerTemplate = XInviteBindedPlayer.New()
            self._BindedPlayers[playerId] = playerTemplate
            table.insert(self._BindedPlayerIdList, playerId)
            table.insert(playerIdList, playerId)
        end
        playerTemplate:UpdateData(playerData)
    end

    --设置绑定的玩家头像和名字
    if not XTool.IsTableEmpty(playerIdList) then
        XDataCenter.SocialManager.GetPlayerInfoListByServer(playerIdList, function(playerInfoList)
            local playerId
            for _, playerInfo in pairs(playerInfoList) do
                playerId = playerInfo.Id
                if self._BindedPlayers[playerId] then
                    self._BindedPlayers[playerId]:UpdatePlayerData(playerInfo)
                end

                if self:IsShowBindCodeSuccessTips() then
                    XUiManager.TipErrorWithKey("NewRegressBindCodeSuccess", playerInfo.Name)
                    self:SetBindCodeRequestMark(false)
                end
            end
            XEventManager.DispatchEvent(XEventId.EVENT_NEW_REGRESSION_NOTIFY_INVITE_POINT)
        end)
        return
    end

    XEventManager.DispatchEvent(XEventId.EVENT_NEW_REGRESSION_NOTIFY_INVITE_POINT)
end

function XInviteManager:GetId()
    return XTool.IsNumberValid(self._Id) and self._Id or XNewRegressionConfigs.GetDefaultInviteId()
end

function XInviteManager:IsReceiveReward(rewardId)
    return self._Rewards[rewardId]
end

function XInviteManager:GetTotalPoint()
    return self._TotalPoint
end

function XInviteManager:GetDailyPoint()
    return self._DailyPoint
end

function XInviteManager:GetBindedPlayers()
    return self._BindedPlayers
end

function XInviteManager:GetBindedPlayer(playerId)
    return self._BindedPlayers[playerId]
end

function XInviteManager:GetBindedPlayerIdList()
    return self._BindedPlayerIdList
end

function XInviteManager:GetCode()
    return self._Code
end

function XInviteManager:GetState()
    return self._State
end

--返回自己和绑定的玩家合计总积分（羁绊总分）
function XInviteManager:GetAllPlayerTotalPoint()
    local totalPoint = self:GetTotalPoint()
    local bindedPlayers = self:GetBindedPlayers()
    for _, playerTemplate in pairs(bindedPlayers) do
        totalPoint = totalPoint + playerTemplate:GetTotalPoint()
    end
    return totalPoint
end

--设置绑定邀请码请求标记
function XInviteManager:SetBindCodeRequestMark(isSetMark)
    self.BindCodeRequestMark = isSetMark
end

function XInviteManager:IsShowBindCodeSuccessTips()
    return self.BindCodeRequestMark
end

function XInviteManager:IsActivityOpen(inviteState)
    local state = self:GetState()
    if (inviteState and state ~= inviteState) or not XTool.IsNumberValid(self._Id) then
        return false
    end

    local inviteId = self:GetId()
    local timeId = XNewRegressionConfigs.GetInviteTimeId(inviteId)
    return XFunctionManager.CheckInTimeByTimeId(timeId)
end

function XInviteManager:GetLeaveTimeStr()
    local endTime = self:GetEndTime()
    return XUiHelper.GetTime(endTime - XTime.GetServerNowTimestamp(), XUiHelper.TimeFormatType.NEW_REGRESSION)
end

function XInviteManager:GetStartTime()
    local inviteId = self:GetId()
    local timeId = XNewRegressionConfigs.GetInviteTimeId(inviteId)
    return XFunctionManager.GetStartTimeByTimeId(timeId)
end

function XInviteManager:GetEndTime()
    local inviteId = self:GetId()
    local timeId = XNewRegressionConfigs.GetInviteTimeId(inviteId)
    return XFunctionManager.GetEndTimeByTimeId(timeId)
end

function XInviteManager:GetShareLink()
    local configShareLink = XNewRegressionConfigs.GetChildActivityConfig("ShareLink")
    -- local jsonData = Json.encode({
    --     roleId = XPlayer.Id,
    --     inviteCode = self:GetCode(),
    -- })
    -- local base64Str = CS.System.Convert.ToBase64String(jsonData)
    return configShareLink .. string.format("%s;%s", XPlayer.Id, self:GetCode())
end

function XInviteManager:GetIsShowCopyButton()
    return XNewRegressionConfigs.GetChildActivityConfig("IsShowTextShare") == "1"
end

--######################## 协议 ########################
--领取邀请活动奖励请求
function XInviteManager:RequestRegression2InviteGetReward(rewardId, cb)
    XNetwork.Call("Regression2InviteGetRewardRequest", { RewardId = rewardId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        self._Rewards[rewardId] = true

        if res.RewardGoods then
            XUiManager.OpenUiObtain(res.RewardGoods)
        end

        if cb then
            cb()
        end
    end)
end

--######################## XINewRegressionChildManager接口 ########################

-- 入口按钮排序权重，越小越前，可以重写自己的权重
function XInviteManager:GetButtonWeight()
    return tonumber(XNewRegressionConfigs.GetChildActivityConfig("InviteButtonWeight"))
end

-- 入口按钮显示名称
function XInviteManager:GetButtonName()
    return XNewRegressionConfigs.GetChildActivityConfig("InviteButtonName")
end

-- 获取面板控制数据
function XInviteManager:GetPanelContrlData()
    return {
        assetPath = XNewRegressionConfigs.GetChildActivityConfig("InvitePrefabAssetPath"),
        proxy = require("XUi/XUiNewRegression/Invite/XUiPanelReturninvitation"),
    }
end

-- 用来显示页签和统一入口的小红点
function XInviteManager:GetIsShowRedPoint(...)
    local totalPoint = self:GetAllPlayerTotalPoint()
    local inviteId = self:GetId()
    local rewardIdList = XNewRegressionConfigs.GetInviteRewardIdList(XNewRegressionConfigs.InviteState.Inviter, inviteId)

    local needPoint
    for _, inviteRewardId in ipairs(rewardIdList) do
        needPoint = XNewRegressionConfigs.GetInviteNeedPoint(inviteRewardId)
        if totalPoint < needPoint then
            return false
        end

        --判断是否已领取
        if not self:IsReceiveReward(inviteRewardId) then
            return true
        end
    end

    return false
end

-- 获取该子活动管理器是否开启
function XInviteManager:GetIsOpen()
    if self:IsActivityOpen(XNewRegressionConfigs.InviteState.Inviter) then
        return XDataCenter.NewRegressionManager.GetIsOpen()
    end
    return false
end

return XInviteManager