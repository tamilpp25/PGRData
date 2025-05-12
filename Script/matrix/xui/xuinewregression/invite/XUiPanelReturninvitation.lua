local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiInviteGridReward = require("XUi/XUiNewRegression/Invite/XUiInviteGridReward")

local SINGLE_ANIMA_TIME = 1 --进度条动画时长
local INVITE_MAX_COUNT = 2

--活跃邀请界面
local XUiPanelReturninvitation = XClass(nil, "XUiPanelReturninvitation")

function XUiPanelReturninvitation:Ctor(ui, rootUi)
    XUiHelper.InitUiClass(self, ui)

    self.RootUi = rootUi
    self.GridRewardList = {}
    self.SpecialGridReward = XUiGridCommon.New(self.RootUi, self.GridSpecialCommon)
    self:InitUi()
    self:AutoAddListener()
    XEventManager.AddEventListener(XEventId.EVENT_NEW_REGRESSION_NOTIFY_INVITE_POINT, self.RefreshByEvent, self)
end

function XUiPanelReturninvitation:SetData(manager)
    self.InviteManager = manager
    self:InitReward()
    self:Refresh()
    self:AutoMoveCourseScroll()
end

function XUiPanelReturninvitation:InitUi()
    --活跃玩家面板
    self.PanelActiveObjs = {
        ["Head"] = XUiHelper.TryGetComponent(self.PanelActive.transform, "Head"),
        ["TxtName"] = XUiHelper.TryGetComponent(self.PanelActive.transform, "TxtName", "Text"),
        ["TxtDailyPoint"] = XUiHelper.TryGetComponent(self.PanelActive.transform, "TxtDailyPoint", "Text"),
        ["TxtTotalPoint"] = XUiHelper.TryGetComponent(self.PanelActive.transform, "TxtTotalPoint", "Text")
    }

    --回归玩家面板
    self.PanelReturnObjs = {}
    for i = 1, INVITE_MAX_COUNT do
        local panelReturn = self["PanelReturn" .. i]
        self.PanelReturnObjs[i] = {
            ["Normal"] = XUiHelper.TryGetComponent(panelReturn.transform, "Normal"),
            ["Diseable"] = XUiHelper.TryGetComponent(panelReturn.transform, "Diseable"),
            ["Head"] = XUiHelper.TryGetComponent(panelReturn.transform, "Normal/PanelReturn/Head"),
            ["TxtName"] = XUiHelper.TryGetComponent(panelReturn.transform, "Normal/PanelReturn/TxtName", "Text"),
            ["TxtDailyPoint"] = XUiHelper.TryGetComponent(panelReturn.transform, "Normal/PanelReturn/TxtDailyPoint", "Text"),
            ["TxtTotalPoint"] = XUiHelper.TryGetComponent(panelReturn.transform, "Normal/PanelReturn/TxtTotalPoint", "Text"),
            ["BtnShare"] = XUiHelper.TryGetComponent(panelReturn.transform, "Diseable/BtnShare", "XUiButton")
        }
    end

    self.PanelCourseContainerPoxY = self.PanelCourseContainer.transform.localPosition.y
end

function XUiPanelReturninvitation:InitReward()
    local inviteId = self.InviteManager:GetId()
    local rewardIdList = XNewRegressionConfigs.GetInviteRewardIdList(XNewRegressionConfigs.InviteState.Inviter, inviteId)
    for i, rewardId in ipairs(rewardIdList) do
        if not self.GridRewardList[i] then
            local gridCourse = i == 1 and self.GridCourse or CSObjectInstantiate(self.GridCourse, self.PanelCourseContainer)
            self.GridRewardList[i] = XUiInviteGridReward.New(gridCourse, self.RootUi, rewardId)
        end
    end
end

function XUiPanelReturninvitation:UpdateWithSecond()
    local timeStr = self.InviteManager:GetLeaveTimeStr()
    self.TxtTime.text = CsXTextManagerGetText("NewRegressionSignInTimeTip2", timeStr)
end

--自动滑动进度奖励，把玩家的积分对应的下一档奖励，放在中间位置
function XUiPanelReturninvitation:AutoMoveCourseScroll()
    XScheduleManager.ScheduleOnce(function()
        local posX = 0
        for _, gridReward in ipairs(self.GridRewardList) do
            posX = gridReward.Transform.localPosition.x
            if self.InviteManager:GetAllPlayerTotalPoint() < gridReward:GetNeedPoint() then
                break
            end
        end
        self.PanelCourseContainer.transform.localPosition = CS.UnityEngine.Vector3(-posX, self.PanelCourseContainerPoxY, 0)
    end, 0)
end

function XUiPanelReturninvitation:RefreshByEvent()
    self:Refresh(true)
end

function XUiPanelReturninvitation:Refresh(isPlayPercentAnim)
    if (XTool.UObjIsNil(self.GameObject)) or not self.GameObject.activeSelf then
        return
    end

    self:RefreshReward(isPlayPercentAnim)
    self:RefreshPanelActive()
    self:RefreshPanelReturn()
end

--刷新回归玩家（其他人）的面板
function XUiPanelReturninvitation:RefreshPanelReturn()
    local inviteId = self.InviteManager:GetId()
    local dailyPointMax = XNewRegressionConfigs.GetInviteDailyPointMax(inviteId)
    local curDailyPoint
    local bindedPlayerIdList = self.InviteManager:GetBindedPlayerIdList()

    for index, bindedPlayerId in ipairs(bindedPlayerIdList) do
        local panelReturnObj = self.PanelReturnObjs[index]
        if not panelReturnObj then
            goto continue
        end

        local bindedPlayer = self.InviteManager:GetBindedPlayer(bindedPlayerId)
        panelReturnObj.Normal.gameObject:SetActiveEx(true)
        panelReturnObj.Diseable.gameObject:SetActiveEx(false)

        panelReturnObj.TxtName.text = bindedPlayer:GetName()
        XUiPlayerHead.InitPortrait(bindedPlayer:GetHeadPortraitId(), bindedPlayer:GetHeadFrameId(), panelReturnObj.Head)

        curDailyPoint = bindedPlayer:GetDailyPoint()
        panelReturnObj.TxtDailyPoint.text = string.format("%s/%s", curDailyPoint, dailyPointMax)
        panelReturnObj.TxtTotalPoint.text = bindedPlayer:GetTotalPoint()

        if self["EffectsLink" .. index] then
            self["EffectsLink" .. index].gameObject:SetActiveEx(true)
        end

        :: continue ::
    end

    local inviteCountMax = XNewRegressionConfigs.GetInviteCountMax(inviteId)
    for i = #bindedPlayerIdList + 1, INVITE_MAX_COUNT do
        local panelReturnObj = self.PanelReturnObjs[i]
        if panelReturnObj then
            panelReturnObj.Normal.gameObject:SetActiveEx(false)
            panelReturnObj.Diseable.gameObject:SetActiveEx(true)
        end

        if self["EffectsLink" .. i] then
            self["EffectsLink" .. i].gameObject:SetActiveEx(false)
        end
    end
end

--刷新活跃玩家（自己）的面板
function XUiPanelReturninvitation:RefreshPanelActive()
    local inviteId = self.InviteManager:GetId()

    XUiPlayerHead.InitPortrait(XPlayer.CurrHeadPortraitId, XPlayer.CurrHeadFrameId, self.PanelActiveObjs.Head)
    self.PanelActiveObjs.TxtName.text = XPlayer.Name

    local curDailyPoint = self.InviteManager:GetDailyPoint()
    local dailyPointMax = XNewRegressionConfigs.GetInviteDailyPointMax(inviteId)
    self.PanelActiveObjs.TxtDailyPoint.text = string.format("%s/%s", curDailyPoint, dailyPointMax)

    self.PanelActiveObjs.TxtTotalPoint.text = self.InviteManager:GetTotalPoint()
end

function XUiPanelReturninvitation:RefreshReward(isPlayPercentAnim)
    self:StopRewardAnimaTimer()

    local inviteId = self.InviteManager:GetId()
    local rewardIdList = XNewRegressionConfigs.GetInviteRewardIdList(XNewRegressionConfigs.InviteState.Inviter, inviteId)
    local totalPoint = self.InviteManager:GetAllPlayerTotalPoint()
    local preNeedPoint  --上一个奖励领取所需积分
    local isSetPercentZero
    local curTotalPoint
    local needPoint --当前奖励领取所需积分
    local animaTime = isPlayPercentAnim and SINGLE_ANIMA_TIME or 0.01
    local curShowTotalPoint = tonumber(self.TxtTotalPoint.text) or 0    --当前显示的羁绊总分
    local addPoint = totalPoint - curShowTotalPoint
    local curTimeTotalPoint --当前动画时间段的羁绊总分

    self.RewardAnimaTimer = XUiHelper.Tween(animaTime, function(f)
        if XTool.UObjIsNil(self.GameObject) then
            return
        end

        preNeedPoint = 0
        isSetPercentZero = false
        curTimeTotalPoint = curShowTotalPoint + addPoint * f
        for i, rewardId in ipairs(rewardIdList) do
            needPoint = XNewRegressionConfigs.GetInviteNeedPoint(rewardId)
            curTotalPoint = isSetPercentZero and 0 or curTimeTotalPoint
            if self.GridRewardList[i] then
                self.GridRewardList[i]:UpdatePercent(curTotalPoint, preNeedPoint)
                self.GridRewardList[i]:UpdateReceiveState(curTotalPoint)
            end

            isSetPercentZero = totalPoint < needPoint
            preNeedPoint = needPoint
        end
        self.TxtTotalPoint.text = math.floor(curTimeTotalPoint)
    end)
end

function XUiPanelReturninvitation:StopRewardAnimaTimer()
    if self.RewardAnimaTimer then
        XScheduleManager.UnSchedule(self.RewardAnimaTimer)
        self.RewardAnimaTimer = nil
    end
end

function XUiPanelReturninvitation:AutoAddListener()
    for i = 1, INVITE_MAX_COUNT do
        local btnShare = self.PanelReturnObjs[i].BtnShare
        XUiHelper.RegisterClickEvent(self, btnShare, self.OnBtnShareClick)
    end
    self.RootUi:BindHelpBtn(self.BtnHelp, "NewRegressionInvite")

    self.SViewCourse.onValueChanged:AddListener(function(value)
        self:OnRewardListDrag(value)
    end)
end

function XUiPanelReturninvitation:OnBtnShareClick()
    local code = self.InviteManager:GetCode()
    XLuaUiManager.Open("UiNewRegressionForwardScreenShot", code)
end

function XUiPanelReturninvitation:OnRewardListDrag(eventData)
    local gridReward
    local lastSpecialRewardId
    for i = #self.GridRewardList, 1, -1 do
        -- 获取当前最右边的能够显示出来的奖励格子
        gridReward = self.GridRewardList[i]
        if self.PanelCourseContainer.parent.transform:Overlaps(gridReward.GridCommon.Transform) then
            break
        end
        if gridReward:GetIsPrimeReward() then
            lastSpecialRewardId = gridReward:GetRewardId()
        end
    end
    -- 找到比右边大的积分配置格子，如果没有直接拿最后默认的
    if lastSpecialRewardId == nil then
        lastSpecialRewardId = self.GridRewardList[#self.GridRewardList]:GetRewardId()
    end
    self.SpecialGridReward:Refresh(XNewRegressionConfigs.GetInviteRewardData(lastSpecialRewardId))
    self.TxtSpecialPoint.text = XNewRegressionConfigs.GetInviteNeedPoint(lastSpecialRewardId)
end

return XUiPanelReturninvitation