--兵法蓝图选关主界面
local XUiRpgTowerNewMain = XLuaUiManager.Register(XLuaUi, "UiRpgTowerNewMain")
local XUiRpgMainTagGrid = require("XUi/XUiRpgTower/MainPage/PanelTag/XUiRpgMainTagGrid")

function XUiRpgTowerNewMain:OnAwake()
    self.MaxLevel = XDataCenter.RpgTowerManager.GetMaxLevel()
    self.BtnDic = {}
    self.RedEvents = {}
    self:InitButtons()
    self:InitTagGroup()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)

    XEventManager.AddEventListener(XEventId.EVENT_RPGTOWER_TEAM_LV_REFRESH, self.RefreshTeamLevel, self)
end


function XUiRpgTowerNewMain:InitButtons()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    XUiHelper.RegisterClickEvent(self, self.BtnTask, function() XLuaUiManager.Open("UiRpgTowerTask") end)
    XUiHelper.RegisterClickEvent(self, self.BtnGift, self.OnBtnGiftClick)
    XUiHelper.RegisterClickEvent(self, self.BtnTeam, self.OnTeamClick)

    self:BindHelpBtn(self.BtnHelp, "RpgTowerHelp")
end

function XUiRpgTowerNewMain:InitTagGroup()
    -- 入口标签组初始化
    for i = 1, self.PanelGroup.childCount do
        local tagGrid = self.BtnDic[i]
        if not tagGrid then
            local tagGo = self.PanelGroup:Find("Btn"..i)
            tagGrid = XUiRpgMainTagGrid.New(tagGo)
            self.BtnDic[i] = tagGrid
        end
    end
end

function XUiRpgTowerNewMain:OnEnable()
    self:RefreshGrids()
    self:RefreshReward()
    self:InitTeamLevel()
    self:AddRedPointEvents()

    self:SetTimer()
end

function XUiRpgTowerNewMain:RefreshGrids()
    -- 刷新
    self.AllConfigs = XRpgTowerConfig.GetRTagConfigs()
    for i, tagGrid in pairs(self.BtnDic) do
        tagGrid:Refresh(self.AllConfigs[i])
    end
end

--加载队伍经验条
function XUiRpgTowerNewMain:InitTeamLevel(showEffect)
    self.CurrLv = XDataCenter.RpgTowerManager.GetCurrentLevel()
    self.Exp = XDataCenter.RpgTowerManager.GetCurrentExp()
    local isMaxLv = self.MaxLevel == self.CurrLv
    if isMaxLv then
        self.Exp = CS.XTextManager.GetText("RpgTowerMaxLevel")
    end
    
    local cfg = XRpgTowerConfig.GetTeamLevelCfgByLevel(self.CurrLv)
    self.NextExp = cfg and cfg.Exp or self.Exp -- 满级 self.Exp / self.NextExp就等于 1
    self.TxtTeamLv.text = self.CurrLv
    -- local bgLv = (self.CurrLv < 10) and "0"..self.CurrLv or self.CurrLv -- 大的数字要两位数，不足补0
    -- self.TxtLvBig.text = bgLv
    self.EffectLevel.gameObject:SetActiveEx(showEffect) -- 升级特效
    self.TxtExp.text = isMaxLv and CS.XTextManager.GetText("RpgTowerMaxLevel") or CS.XTextManager.GetText("CommonSlashStr", self.Exp, self.NextExp)
    self.ImgExp.fillAmount = isMaxLv and 1 or self.Exp / self.NextExp
end

-- 刷新队伍经验（在当前面板升级）播放升级进度条动画
function XUiRpgTowerNewMain:RefreshTeamLevel(newLv, newExp)
    if newLv < self.CurrLv or newLv == self.MaxLevel then
        return
    end
    self.EffectLevel.gameObject:SetActiveEx(false)

    local round = newLv - self.CurrLv --进度条转的圈数
    local currExp = self.Exp
    local addTotalExp = XRpgTowerConfig.GetTeamLevelCfgByLevel(self.CurrLv).Exp - currExp
    if round > 0 then
        if round > 1 then
            for i = self.CurrLv + 1, newLv - 1, 1 do
                addTotalExp = addTotalExp + XRpgTowerConfig.GetTeamLevelCfgByLevel(i).Exp
            end
        end
        addTotalExp = addTotalExp + newExp
    end
    local addSpeed = addTotalExp / 60
    
    if self.AnimTimer then
        XScheduleManager.UnSchedule(self.AnimTimer)   
        self.AnimTimer = nil
    end
    self.AnimTimer = XUiHelper.Tween(1, function ()
        -- 先转圈
        local cfg = XRpgTowerConfig.GetTeamLevelCfgByLevel(newLv - round)
        local nextExp = cfg and cfg.Exp or self.Exp --.Exp字段是升到下级需要达到的exp
        if round > 0 then
            currExp = currExp + addSpeed
            self.ImgExp.fillAmount = currExp / nextExp --不用在意这个速度

            if currExp / nextExp >= 1 then -- 转完一圈 减round
                round = round - 1
                currExp = 0
            end
        elseif round == 0 then
            -- 转完了，没有圈数了 停留在经验值的当前值
            currExp = currExp + addSpeed
            self.ImgExp.fillAmount = currExp / nextExp

            if currExp >= newExp then -- 
                round = -1 --将圈数置负，不再进入判断
                self.ImgExp.fillAmount = newExp / nextExp
            end
        end

    end, function ()
        local showEffect = newLv - self.CurrLv > 0
        self:InitTeamLevel(showEffect)
    end)
end

-- 刷新奖励
function XUiRpgTowerNewMain:RefreshReward()
    local count = 0
    local dayPass = XDataCenter.RpgTowerManager.GetDayCount()
    local allDailyRewards = XDataCenter.RpgTowerManager.GetDailyRewards()
    local rewardId = allDailyRewards[dayPass]
    if rewardId then
        local reward = XRewardManager.GetRewardList(rewardId)
        count = reward[1].Count -- 策划说奖励只会配1个
    end
    local isShow = (count > 0) and XDataCenter.RpgTowerManager.GetCanReceiveSupply()
    -- self.BtnGift:SetNameByGroup(0, count)
    self.BtnGift.transform:Find("ImgReceived").gameObject:SetActiveEx(not isShow)
    self.BtnGift:ShowReddot(isShow)
end

-- 领取奖励
function XUiRpgTowerNewMain:OnBtnGiftClick()
    if XDataCenter.RpgTowerManager.GetCanReceiveSupply() then
        XDataCenter.RpgTowerManager.ReceiveSupply()
    else
        XUiManager.TipMsg(CS.XTextManager.GetText("RpgTowerCantGetSupply"))
    end
end

function XUiRpgTowerNewMain:SetTimer()
    self:StopTimer()
    self:SetResetTime()
    self.Timer = XScheduleManager.ScheduleForever(function()
            self:SetResetTime()
        end, XScheduleManager.SECOND, 0)
end

--显示倒计时与处理倒计时完成时事件
function XUiRpgTowerNewMain:SetResetTime()
    local endTimeSecond = XDataCenter.RpgTowerManager.GetEndTime()
    local now = XTime.GetServerNowTimestamp()
    local leftTime = endTimeSecond - now
    local remainTime = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.STRONGHOLD)
    self.TxtRemainTime.text = CS.XTextManager.GetText("ShopActivityItemCount", remainTime)
    if leftTime <= 0 then
        self:OnActivityReset()
    end
end

--停止界面计时器
function XUiRpgTowerNewMain:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

--活动周期结束时弹回主界面
function XUiRpgTowerNewMain:OnActivityReset()
    if self.IsReseting then return end
    self.IsReseting = true
    self:StopTimer()
    XLuaUiManager.RunMain()
    XUiManager.TipMsg(CS.XTextManager.GetText("RpgTowerFinished"))
end

function XUiRpgTowerNewMain:OnTeamClick()
    XLuaUiManager.Open("UiRpgTowerRoleList")
end

function XUiRpgTowerNewMain:OnGetEvents()
    return { XEventId.EVENT_RPGTOWER_RESET, XEventId.EVENT_RPGTOWER_REFRESH_DAILYREWARD }
end

function XUiRpgTowerNewMain:OnNotify(evt, ...)
    local args = { ... }
    if evt == XEventId.EVENT_RPGTOWER_RESET then
        self:OnActivityReset()
    elseif evt == XEventId.EVENT_RPGTOWER_REFRESH_DAILYREWARD then
        self:RefreshReward()
    end
end

function XUiRpgTowerNewMain:OnDisable()
    self:StopTimer()
    self:RemoveRedPointEvents()

    if self.AnimTimer then
        XScheduleManager.UnSchedule(self.AnimTimer)   
        self.AnimTimer = nil
    end
end

function XUiRpgTowerNewMain:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_RPGTOWER_TEAM_LV_REFRESH, self.RefreshTeamLevel, self)
end

function XUiRpgTowerNewMain:AddRedPointEvents()
    if self.AlreadyAddRed then return end
    self.AlreadyAddRed = true
    table.insert(self.RedEvents, XRedPointManager.AddRedPointEvent(self.BtnTask, self.OnCheckBtnTaskRedPoint, self, { XRedPointConditions.Types.CONDITION_RPGTOWER_TASK_RED }))
    table.insert(self.RedEvents, XRedPointManager.AddRedPointEvent(self.BtnTeam, self.OnCheckBtnTeamRedPoint, self, { XRedPointConditions.Types.CONDITION_RPGTOWER_TEAM_RED }))
end

function XUiRpgTowerNewMain:RemoveRedPointEvents()
    if not self.AlreadyAddRed then return end
    for _, eventId in pairs(self.RedEvents) do
        XRedPointManager.RemoveRedPointEvent(eventId)
    end
    self.RedEvents = {}
    self.AlreadyAddRed = false
end

function XUiRpgTowerNewMain:OnCheckBtnTaskRedPoint(count)
    self.BtnTask:ShowReddot(count >= 0)
end

function XUiRpgTowerNewMain:OnCheckBtnTeamRedPoint(count)
    self.BtnTeam:ShowReddot(count >= 0)
end

return XUiRpgTowerNewMain