local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiInviteGridReward = require("XUi/XUiNewRegression/Invite/XUiInviteGridReward")

local SINGLE_ANIMA_TIME = 1 --进度条动画时长

--回归邀请界面
local XUiPanelFetters = XClass(nil, "XUiPanelFetters")

function XUiPanelFetters:Ctor(ui, rootUi)
    XUiHelper.InitUiClass(self, ui)

    self.RootUi = rootUi
    self.GridRewardList = {}
    self:AutoAddListener()
    XEventManager.AddEventListener(XEventId.EVENT_NEW_REGRESSION_NOTIFY_INVITE_POINT, self.RefreshByEvent, self)
    self.PanelCourseContainerPoxY = self.PanelCourseContainer.transform.localPosition.y
    self.SpecialGridReward = XUiGridCommon.New(self.RootUi, self.GridSpecialCommon)
end

function XUiPanelFetters:SetData(manager)
    self.FettersManager = manager
    self.InviteManager = XDataCenter.NewRegressionManager.GetInviteManager()
    self:InitReward()
    self:Refresh()
    self:AutoMoveCourseScroll()
end

function XUiPanelFetters:InitReward()
    local inviteId = self.InviteManager:GetId()
    local rewardIdList = XNewRegressionConfigs.GetInviteRewardIdList(XNewRegressionConfigs.InviteState.Invitee, inviteId)
    for i, rewardId in ipairs(rewardIdList) do
        if not self.GridRewardList[i] then
            local gridCourse = i == 1 and self.GridCourse or CSObjectInstantiate(self.GridCourse, self.PanelCourseContainer)
            self.GridRewardList[i] = XUiInviteGridReward.New(gridCourse, self.RootUi, rewardId)
        end
    end
end

function XUiPanelFetters:UpdateWithSecond()
    local timeStr = self.InviteManager:GetLeaveTimeStr()
    self.TxtActiveTime.text = CsXTextManagerGetText("NewRegressFettersTime", timeStr)
    self.TxtTime.text = CsXTextManagerGetText("NewRegressionSignInTimeTip2", timeStr)
end

--自动滑动进度奖励，把玩家的积分对应的下一档奖励，放在中间位置
function XUiPanelFetters:AutoMoveCourseScroll()
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

function XUiPanelFetters:RefreshByEvent()
    self:Refresh(true)
end

function XUiPanelFetters:Refresh(isPlayPercentAnim)
    if (XTool.UObjIsNil(self.GameObject)) or not self.GameObject.activeSelf then
        return
    end

    self:RefreshReward(isPlayPercentAnim)
    self:RefreshPanelActive()
    self:RefreshPanelReturn()
end

--刷新活跃玩家（其他人）的面板
function XUiPanelFetters:RefreshPanelActive()
    local inviteId = self.InviteManager:GetId()
    local dailyPointMax = XNewRegressionConfigs.GetInviteDailyPointMax(inviteId)
    local bindedPlayers = self.InviteManager:GetBindedPlayers()
    local curDailyPoint

    for _, bindedPlayer in pairs(bindedPlayers) do
        self.Normal.gameObject:SetActiveEx(true)
        self.Diseable.gameObject:SetActiveEx(false)

        self.TxtNameByActive.text = bindedPlayer:GetName()
        XUiPlayerHead.InitPortrait(bindedPlayer:GetHeadPortraitId(), bindedPlayer:GetHeadFrameId(), self.HeadByActive)

        curDailyPoint = bindedPlayer:GetDailyPoint()
        self.TxtDailyPointByActive.text = string.format("%s/%s", curDailyPoint, dailyPointMax)
        self.TxtTotalPointByActive.text = bindedPlayer:GetTotalPoint()

        if self.EffectsArrow then
            self.EffectsArrow.gameObject:SetActiveEx(true)
        end
        return
    end

    self.Normal.gameObject:SetActiveEx(false)
    self.Diseable.gameObject:SetActiveEx(true)
    if self.EffectsArrow then
        self.EffectsArrow.gameObject:SetActiveEx(false)
    end
end

--刷新回归玩家（自己）的面板
function XUiPanelFetters:RefreshPanelReturn()
    local inviteId = self.InviteManager:GetId()

    XUiPlayerHead.InitPortrait(XPlayer.CurrHeadPortraitId, XPlayer.CurrHeadFrameId, self.HeadByReturn)
    self.TxtNameByReturn.text = XPlayer.Name

    local curDailyPoint = self.InviteManager:GetDailyPoint()
    local dailyPointMax = XNewRegressionConfigs.GetInviteDailyPointMax(inviteId)
    self.TxtDailyPointByReturn.text = string.format("%s/%s", curDailyPoint, dailyPointMax)

    self.TxtTotalPointByReturn.text = self.InviteManager:GetTotalPoint()
end

function XUiPanelFetters:RefreshReward(isPlayPercentAnim)
    self:StopRewardAnimaTimer()

    local inviteId = self.InviteManager:GetId()
    local rewardIdList = XNewRegressionConfigs.GetInviteRewardIdList(XNewRegressionConfigs.InviteState.Invitee, inviteId)
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

function XUiPanelFetters:StopRewardAnimaTimer()
    if self.RewardAnimaTimer then
        XScheduleManager.UnSchedule(self.RewardAnimaTimer)
        self.RewardAnimaTimer = nil
    end

    self.SViewCourse.onValueChanged:AddListener(function(value)
        self:OnRewardListDrag(value)
    end)
end

function XUiPanelFetters:AutoAddListener()
    XUiHelper.RegisterClickEvent(self, self.BtnBind, self.OnBtnBindClick)
    self.RootUi:BindHelpBtn(self.BtnHelp, "NewRegressionInvite")
end

function XUiPanelFetters:OnBtnBindClick()
    local code = self.CodeInput.text or ""
    self.FettersManager:RequestRegression2InviteBindCode(code)
end

function XUiPanelFetters:OnRewardListDrag(eventData)
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

return XUiPanelFetters