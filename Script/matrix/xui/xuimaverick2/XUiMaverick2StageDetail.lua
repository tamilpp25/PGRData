local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
-- 异构阵线2.0关卡详情
local XUiMaverick2StageDetail = XLuaUiManager.Register(XLuaUi, "UiMaverick2StageDetail")

function XUiMaverick2StageDetail:OnAwake()
    self.StageId = nil
    self.CloseCb = nil -- 关闭界面回调
    self.GridCommonDic = {}

    self:SetButtonCallBack()
    self:InitTimes()
end

function XUiMaverick2StageDetail:OnStart(stageId, closeCb)
    self.StageId = stageId
    self.CloseCb = closeCb
end

function XUiMaverick2StageDetail:OnEnable()
    self.Super.OnEnable(self)
    self:Refresh()
end

function XUiMaverick2StageDetail:OnDisable()
    self:StopTimer()
end

function XUiMaverick2StageDetail:SetButtonCallBack()
    XUiHelper.RegisterClickEvent(self, self.BtnEnter, self.OnClickBtnEnter)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnClickBtnClose)
end

function XUiMaverick2StageDetail:OnClickBtnEnter()
    self:OnClickBtnClose()

    -- 保存打开过每日关卡
    local stageCfg = XMaverick2Configs.GetMaverick2Stage(self.StageId, true)
    local isDaily = stageCfg.StageType == XMaverick2Configs.StageType.Daily
    if isDaily then
        XDataCenter.Maverick2Manager.SaveOpenDailyStage()
    end

    XLuaUiManager.Open("UiMaverick2Character", self.StageId)
end

function XUiMaverick2StageDetail:OnClickBtnClose()
    if self.CloseCb then
        self.CloseCb()
    end
    
    self:Close()
end

function XUiMaverick2StageDetail:Refresh()
    self:RefreshStageDetail()
end

function XUiMaverick2StageDetail:InitTimes()
    self:SetAutoCloseInfo(XDataCenter.Maverick2Manager.GetActivityEndTime(), function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        end
    end)
end


function XUiMaverick2StageDetail:RefreshStageDetail()
    local stageId = self.StageId
    local stageCfg = XMaverick2Configs.GetMaverick2Stage(stageId, true)
    local stageData = XDataCenter.Maverick2Manager.GetStageData(stageId)

    self.TxtTitle.text = stageCfg.Name
    self.TxtStory.text = stageCfg.Desc
    local stageTypeCfg = XMaverick2Configs.GetMaverick2StageType(stageCfg.StageType, true)
    self.RImgTitleBg:SetRawImage(stageTypeCfg.DetailBg)
    self.ImageStageType.color = XUiHelper.Hexcolor2Color(stageTypeCfg.NameBgColor)
    self.TextStageType.text = stageTypeCfg.Name

    -- 关卡目标
    local isBoss = stageCfg.StageType == XMaverick2Configs.StageType.MainLineBoss
    local starDescs = XFubenConfigs.GetStarDesc(stageId)
    local isShowCondition = isBoss and starDescs and #starDescs > 0 
    self.PanelCondition.gameObject:SetActiveEx(isShowCondition)
    if isShowCondition then
        local cnt = #starDescs
        for i, desc in ipairs(starDescs) do
            local isActive = stageData.StarCount >= (cnt - i + 1)
            self["PanelActive"..i].gameObject:SetActiveEx(isActive)
            self["PanelUnActive"..i].gameObject:SetActiveEx(not isActive)
            if isActive then
                self["TxtActive"..i].text = desc
            else
                self["TxtUnActive"..i].text = desc
            end
        end
    end

    -- 积分关
    local isScore = stageCfg.StageType == XMaverick2Configs.StageType.Score
    self.PanelScore.gameObject:SetActiveEx(isScore)
    if isScore then
        local record = XDataCenter.Maverick2Manager.GetScoreStageRecord()
        self.TxtScore.text = record.Score and tostring(record.Score) or "0"
    end

    -- 每日关卡
    local isDaily = stageCfg.StageType == XMaverick2Configs.StageType.Daily
    self.TextTime.gameObject:SetActiveEx(isDaily)
    if isDaily then
        self:StartTimer()
    end

    -- 奖励1：首通奖励
    local gridIndex = 1
    local gridCommond = self.GridCommon
    local parent = self.PanelDropContent
    for i = 1, parent.childCount do
        parent.transform:GetChild(i - 1).gameObject:SetActiveEx(false)
    end
    local rewardList = XRewardManager.GetRewardList(stageCfg.FirstRewardId) or {}
    for i, reward in ipairs(rewardList) do
        local grid = self:GetRewardGridCommon(gridIndex)
        gridIndex = gridIndex + 1

        grid:Refresh(reward)
        XUiHelper.TryGetComponent(grid.Transform, "ImgFirst").gameObject:SetActiveEx(true)
    end

    -- 奖励2：解锁机器人
    local robotCfgs = XMaverick2Configs.GetMaverick2Robot()
    for i, robotCfg in pairs(robotCfgs) do
        local params = XConditionManager.GetConditionParams(robotCfg.Condition)
        local unlockStageId = params

        if unlockStageId == stageId then
            local grid = self:GetRewardGridCommon(gridIndex)
            gridIndex = gridIndex + 1

            XUiHelper.TryGetComponent(grid.Transform, "RImgIcon", "RawImage"):SetRawImage(robotCfg.Icon)
            XUiHelper.TryGetComponent(grid.Transform, "ImgFirst").gameObject:SetActiveEx(true)
            grid:SetProxyClickFunc(function() 
                local tempItemData = {
                    IsTempItemData = true,
                    Name = robotCfg.Name,
                    Icon = robotCfg.Icon,
                    Description = robotCfg.Desc,
                }
                XLuaUiManager.Open("UiTip", tempItemData)
            end)
        end
    end

    -- 奖励3：复刷奖励
    if stageCfg.RewardUnit > 0 then
        local grid = self:GetRewardGridCommon(gridIndex)
        gridIndex = gridIndex + 1

        local reward = {TemplateId = XDataCenter.ItemManager.ItemId.Maverick2Unit, Count = stageCfg.RewardUnit}
        grid:Refresh(reward)
    end

    -- 图标+文字 奖励
    local showParamReward = stageCfg.RewardParam ~= nil and #stageCfg.RewardParam > 0
    if showParamReward then
        local grid = self:GetRewardGridCommon(gridIndex)
        gridIndex = gridIndex + 1

        local iconPath = stageCfg.RewardParam[1]
        local rewardDesc = stageCfg.RewardParam[2]
        XUiHelper.TryGetComponent(grid.Transform, "RImgIcon", "RawImage"):SetRawImage(iconPath)
        XUiHelper.TryGetComponent(grid.Transform, "ImgLevel").gameObject:SetActiveEx(true)
        XUiHelper.TryGetComponent(grid.Transform, "ImgLevel/TxtLevel", "Text").text = rewardDesc
        grid:SetProxyClickFunc(function() end)
    end
end

function XUiMaverick2StageDetail:GetRewardGridCommon(index)
    local gridCommond = self.GridCommon
    local parent = self.PanelDropContent

    local go = nil
    if parent.childCount > index then
        go = parent.transform:GetChild(index)
    else
        go = CS.UnityEngine.Object.Instantiate(gridCommond, parent)
    end
    go.gameObject:SetActiveEx(true)
    XUiHelper.TryGetComponent(go, "ImgFirst").gameObject:SetActiveEx(false)
    XUiHelper.TryGetComponent(go, "ImgLevel").gameObject:SetActiveEx(false)
    XUiHelper.TryGetComponent(go, "PanelSite").gameObject:SetActiveEx(false)
    XUiHelper.TryGetComponent(go, "ImgQuality").gameObject:SetActiveEx(false)
    XUiHelper.TryGetComponent(go, "TxtCount", "Text").text = ""

    local instanceID = go:GetInstanceID()
    local grid = self.GridCommonDic[instanceID]
    if grid == nil then
        grid = XUiGridCommon.New(go)
        self.GridCommonDic[instanceID] = grid
    end

    return grid
end

function XUiMaverick2StageDetail:StartTimer()
    if self.Timer then return end

    self:RefreshDailyCountDown()
    self:StopTimer()
    self.Timer = XScheduleManager.ScheduleForever(function()
        self:RefreshDailyCountDown()
    end, XScheduleManager.SECOND, 0)
end

function XUiMaverick2StageDetail:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

-- 刷新每日关卡文本的倒计时
function XUiMaverick2StageDetail:RefreshDailyCountDown()
    local refreshTime = XTime.GetSeverNextRefreshTime()
    local nowTime = XTime.GetServerNowTimestamp()
    local showTime = XUiHelper.GetTime(refreshTime - nowTime, XUiHelper.TimeFormatType.ACTIVITY)
    self.TextTime.text = XUiHelper.GetText("DrawFreeTicketCoolDown", showTime)   
end
