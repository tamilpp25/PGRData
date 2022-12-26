local mathFloor = math.floor
local Lerp = CS.UnityEngine.Mathf.Lerp
local CSXScheduleManagerUnSchedule = XScheduleManager.UnSchedule
local CsXTextManagerGetText = CsXTextManagerGetText

local SCORE_ANIM_DURATION = 1--分数滚动动画时间
local CONDITION_COLOR = {
    [true] = CS.UnityEngine.Color.red,
    [false] = CS.UnityEngine.Color.white,
}
local CONDITION_COLOR_FOR_TEXT = {
    [true] = XUiHelper.Hexcolor2Color("ff3f3f"),
    [false] = XUiHelper.Hexcolor2Color("59f5ff"),
}

local XUiStrongholdMain = XLuaUiManager.Register(XLuaUi, "UiStrongholdMain")

function XUiStrongholdMain:OnAwake()
    self:AutoAddListener()

    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool)
    local itemId = XDataCenter.StrongholdManager.GetMineralItemId()
    XDataCenter.ItemManager.AddCountUpdateListener(itemId, function()
        self.AssetActivityPanel:Refresh({ itemId })
    end, self.AssetActivityPanel)

    self.ImgUpEnergy.gameObject:SetActiveEx(false)
    self.ImgUpMine.gameObject:SetActiveEx(false)
    self.ImgUpPeople.gameObject:SetActiveEx(false)
end

function XUiStrongholdMain:OnStart()
    self:InitView()

    --上期战报
    if XDataCenter.StrongholdManager.CheckShowLastActivityRecord() then
        XLuaUiManager.Open("UiStrongholdActivityResult")
        XDataCenter.StrongholdManager.SetCookieGetCookieLastActivityRecord()
    end

    --在线重置后若重新进入活动，清除Flag
    XDataCenter.StrongholdManager.ClearActivityEnd()
end

function XUiStrongholdMain:OnEnable()
    if self.IsEnd then return end
    
    --当从其他界面返回时检查活动是否被在线重置过
    if XDataCenter.StrongholdManager.OnActivityEnd() then
        self.IsEnd = true
        return
    end

    self.AssetActivityPanel:Refresh({ XDataCenter.StrongholdManager.GetMineralItemId() })
    self:UpdateLeftTime()
    self:UpdateCurDay()
    self:UpdateEndurance()
    self:UpdateActivityStatus()
    self:UpdateMine()
    self:UpdateElectric()
    self:UpdateAssistant()
    self:UpdateProgress()
    self:UpdateRewards()

    XDataCenter.StrongholdManager.CheckCookieAssistantFirstOpen()
end

function XUiStrongholdMain:OnDisable()
    XCountDown.UnBindTimer(self, XCountDown.GTimerName.Stronghold)
    self:DestroyMineTimer()
    self:DestroyElectricTimer()

    self.ImgUpEnergy.gameObject:SetActiveEx(false)
    self.ImgUpMine.gameObject:SetActiveEx(false)
    self.ImgUpPeople.gameObject:SetActiveEx(false)
end

function XUiStrongholdMain:OnGetEvents()
    return {
        XEventId.EVENT_STRONGHOLD_CUR_DAY_CHANGE,
        XEventId.EVENT_STRONGHOLD_ACTIVITY_STATUS_CHANGE,
        XEventId.EVENT_STRONGHOLD_PAUSE_DAY_CHANGE,
        XEventId.EVENT_STRONGHOLD_MINERAL_LEFT_CHANGE,
        XEventId.EVENT_STRONGHOLD_ENDURANCE_CHANGE,
        XEventId.EVENT_STRONGHOLD_MAX_ELECTRIC_CHANGE,
        XEventId.EVENT_STRONGHOLD_TEAMLIST_CHANGE,
        XEventId.EVENT_STRONGHOLD_SHARE_CHARACTER_CHANGE,
        XEventId.EVENT_STRONGHOLD_FINISH_GROUP_CHANGE,
        XEventId.EVENT_STRONGHOLD_FINISH_REWARDS_CHANGE,
        XEventId.EVENT_STRONGHOLD_ACTIVITY_END,
        XEventId.EVENT_STRONGHOLD_ACTIVITY_RESULT_CHANGE,
    }
end

function XUiStrongholdMain:OnNotify(evt, ...)
    if self.IsEnd then return end

    local args = { ... }
    if evt == XEventId.EVENT_STRONGHOLD_CUR_DAY_CHANGE then
        self:UpdateCurDay()
    elseif evt == XEventId.EVENT_STRONGHOLD_ACTIVITY_STATUS_CHANGE
    or evt == XEventId.EVENT_STRONGHOLD_PAUSE_DAY_CHANGE then
        self.AssetActivityPanel:Refresh({ XDataCenter.StrongholdManager.GetMineralItemId() })
        self:UpdateActivityStatus()
        self:UpdateMine()
        self:UpdateElectric()
        self:UpdateLeftTime()
        self:UpdateAssistant()
        self:UpdateRewards()
        self:UpdateEndurance()
    elseif evt == XEventId.EVENT_STRONGHOLD_MINERAL_LEFT_CHANGE then
        self:UpdateMine()
    elseif evt == XEventId.EVENT_STRONGHOLD_ENDURANCE_CHANGE then
        self:UpdateEndurance()
    elseif evt == XEventId.EVENT_STRONGHOLD_TEAMLIST_CHANGE
    or evt == XEventId.EVENT_STRONGHOLD_MAX_ELECTRIC_CHANGE then
        self:UpdateElectric()
    elseif evt == XEventId.EVENT_STRONGHOLD_SHARE_CHARACTER_CHANGE then
        self:UpdateAssistant()
    elseif evt == XEventId.EVENT_STRONGHOLD_FINISH_GROUP_CHANGE then
        self:UpdateProgress()
    elseif evt == XEventId.EVENT_STRONGHOLD_FINISH_REWARDS_CHANGE then
        self:UpdateRewards()
    elseif evt == XEventId.EVENT_STRONGHOLD_ACTIVITY_END then
        if XDataCenter.StrongholdManager.OnActivityEnd() then
            self.IsEnd = true
            return
        end
    elseif evt == XEventId.EVENT_STRONGHOLD_ACTIVITY_RESULT_CHANGE then
        self:UpdatePanelEnd()
    end
end

function XUiStrongholdMain:InitView()
    local name = XStrongholdConfigs.GetActivityName()
    self.TxtName = name
    self.TxtTitleEnd = name

    local levelId = XDataCenter.StrongholdManager.GetLevelId()

    local levelName = XStrongholdConfigs.GetLevelName(levelId)
    self.TxtLevelName.text = levelName

    local minLevel, maxLevel = XStrongholdConfigs.GetLevelLimit(levelId)
    self.TxtLevel.text = CsXTextManagerGetText("StrongholdLevelLimit", minLevel, maxLevel)

    local levelIcon = XStrongholdConfigs.GetLevelIcon(levelId)
    self:SetUiSprite(self.ImgIconLevel, levelIcon)
end

function XUiStrongholdMain:UpdateLeftTime()
    if XDataCenter.StrongholdManager.IsActivityBegin() then
        self.TxtSection.text = CsXTextManagerGetText("StrongholdSectionOne")
        self.TxtSection.gameObject:SetActiveEx(true)
    elseif XDataCenter.StrongholdManager.IsFightBegin() then
        self.TxtSection.text = CsXTextManagerGetText("StrongholdSectionTwo")
        self.TxtSection.gameObject:SetActiveEx(true)
    else
        self.TxtSection.gameObject:SetActiveEx(false)
    end

    XCountDown.UnBindTimer(self, XCountDown.GTimerName.Stronghold)
    XCountDown.BindTimer(self, XCountDown.GTimerName.Stronghold, function(time)
        time = time > 0 and time or 0
        local timeText = XUiHelper.GetTime(time, XUiHelper.TimeFormatType.STRONGHOLD)
        if XDataCenter.StrongholdManager.IsActivityBegin() then
            self.TxtTime.text = CsXTextManagerGetText("StrongholdActivityTimeActivityBegin", timeText)
        elseif XDataCenter.StrongholdManager.IsFightBegin() then
            self.TxtTime.text = CsXTextManagerGetText("StrongholdActivityTimeFightBegin", timeText)
        elseif XDataCenter.StrongholdManager.IsFightEnd() then
            self.TxtTimeEnd.text = CsXTextManagerGetText("StrongholdActivityTimeFightEndExtra", timeText)
        end
    end)
end

function XUiStrongholdMain:UpdateCurDay()
    local curDay = XDataCenter.StrongholdManager.GetCurDay()
    self.TxtDay.text = curDay

    local totalDay = XDataCenter.StrongholdManager.GetTotalDay()
    self.TxtTotalDay.text = "/" .. totalDay
end

function XUiStrongholdMain:UpdateEndurance()
    local curEndurance = XDataCenter.StrongholdManager.GetCurEndurance()
    self.TxtEndurance.text = CsXTextManagerGetText("StrongholdEndurance", curEndurance)

    local maxEndurance = XDataCenter.StrongholdManager.GetMaxEndurance()
    local maxLimitEndurance = XDataCenter.StrongholdManager.GetMaxLimitEndurance()

    if maxEndurance < maxLimitEndurance then
        local isPaused = XDataCenter.StrongholdManager.IsDayPaused()
        if isPaused then
            local countTime = XDataCenter.StrongholdManager.GetDelayCountTimeStr()
            self.TxtEnduranceTime.text = CsXTextManagerGetText("StrongholdEnduranceTimeDelay", countTime)
        else
            local countTime = XDataCenter.StrongholdManager.GetCountTimeStr()
            self.TxtEnduranceTime.text = CsXTextManagerGetText("StrongholdEnduranceTime", countTime)
        end
        self.TxtEnduranceTime.color = CONDITION_COLOR_FOR_TEXT[isPaused]
        self.TxtEnduranceTime.gameObject:SetActiveEx(true)
    else
        self.TxtEnduranceTime.gameObject:SetActiveEx(false)
    end
end

function XUiStrongholdMain:UpdateProgress()
    local finishCount = XDataCenter.StrongholdManager.GetFinishGroupCount()
    local totalCount = XDataCenter.StrongholdManager.GetAllGroupCount()
    self.TxtJd.text = finishCount .. "/" .. totalCount
    self.ImgJd.fillAmount = totalCount ~= 0 and finishCount / totalCount or 0
end

function XUiStrongholdMain:UpdateRewards()
    local isShowRed = XDataCenter.StrongholdManager.IsAnyRewardCanGet()
    self.BtnReward:ShowReddot(isShowRed)
end

function XUiStrongholdMain:UpdateActivityStatus()
    if XDataCenter.StrongholdManager.IsActivityBegin() then

        self.PanelFighting.gameObject:SetActiveEx(true)
        self.PanelEnd.gameObject:SetActiveEx(false)
        self.PanelTime.gameObject:SetActiveEx(false)
        self.PanelEndurance.gameObject:SetActiveEx(false)
        self.BtnFight.gameObject:SetActiveEx(true)
        self.BtnTeam.gameObject:SetActiveEx(true)
        self.BtnReward.gameObject:SetActiveEx(true)
        if self.PanelMineTime then
            self.PanelMineTime.gameObject:SetActiveEx(false)
        end
        self.BtnPower:ShowTag(false)
        self.BtnStop.gameObject:SetActiveEx(false)
    elseif XDataCenter.StrongholdManager.IsFightBegin() then

        self.PanelFighting.gameObject:SetActiveEx(true)
        self.PanelEnd.gameObject:SetActiveEx(false)
        self.PanelTime.gameObject:SetActiveEx(true)
        self.PanelEndurance.gameObject:SetActiveEx(true)
        self.BtnFight.gameObject:SetActiveEx(true)
        self.BtnTeam.gameObject:SetActiveEx(true)
        self.BtnReward.gameObject:SetActiveEx(true)
        if self.PanelMineTime then
            self.PanelMineTime.gameObject:SetActiveEx(true)
        end
        self.BtnPower:ShowTag(true)
        self.BtnStop.gameObject:SetActiveEx(true)
    elseif XDataCenter.StrongholdManager.IsFightEnd() then

        self.PanelFighting.gameObject:SetActiveEx(false)
        self.PanelEnd.gameObject:SetActiveEx(true)
        self.PanelTime.gameObject:SetActiveEx(false)
        self.PanelEndurance.gameObject:SetActiveEx(false)
        self.BtnFight.gameObject:SetActiveEx(false)
        self.BtnTeam.gameObject:SetActiveEx(false)
        self.BtnReward.gameObject:SetActiveEx(false)
        if self.PanelMineTime then
            self.PanelMineTime.gameObject:SetActiveEx(true)
        end
        self.BtnPower:ShowTag(true)
        self.BtnStop.gameObject:SetActiveEx(false)

        self:UpdatePanelEnd()

    end
end

--矿场相关
function XUiStrongholdMain:UpdateMine()
    local isPaused = XDataCenter.StrongholdManager.IsDayPaused()
    if isPaused then
        local countTime = XDataCenter.StrongholdManager.GetDelayCountTimeStr()
        self.TxtMineTime.text = CsXTextManagerGetText("StrongholdMineTimeDelay", countTime)
    else
        local countTime = XDataCenter.StrongholdManager.GetCountTimeStr()
        self.TxtMineTime.text = CsXTextManagerGetText("StrongholdMineTime", countTime)
    end
    self.TxtMineTime.color = CONDITION_COLOR_FOR_TEXT[isPaused]

    local oldMinerCount = XDataCenter.StrongholdManager.GetCookieMinerCount()
    local minerCount = XDataCenter.StrongholdManager.GetMinerCount()
    local changeCount = oldMinerCount > 0 and minerCount - oldMinerCount or 0
    if changeCount > 0 then
        self:PlayMineUpAnim(oldMinerCount, minerCount)
    else
        local mineralCount = XDataCenter.StrongholdManager.GetMineralOutput(minerCount)
        self.TxtPeople.text = minerCount
        self.TxtMine.text = mineralCount
    end

    XDataCenter.StrongholdManager.SetCookieMinerCount(minerCount)

    local isShow = XRedPointConditionStrongholdMineralLeft.Check()
    self.BtnMine:ShowReddot(isShow)
end

--电厂相关
function XUiStrongholdMain:UpdateElectric()
    local isPaused = XDataCenter.StrongholdManager.IsDayPaused()
    if isPaused then
        local countTime = XDataCenter.StrongholdManager.GetDelayCountTimeStr()
        self.TxtElectricTime.text = CsXTextManagerGetText("StrongholdElectricTimeDelay", countTime)
    else
        local countTime = XDataCenter.StrongholdManager.GetCountTimeStr()
        self.TxtElectricTime.text = CsXTextManagerGetText("StrongholdElectricTime", countTime)
    end
    self.TxtElectricTime.color = CONDITION_COLOR_FOR_TEXT[isPaused]

    local oldCount = XDataCenter.StrongholdManager.GetCookieElectricEnergy()
    local curCount = XDataCenter.StrongholdManager.GetTotalElectricEnergy()
    local changeCount = oldCount > 0 and curCount - oldCount or 0
    if changeCount > 0 then
        self:PlayElectricUpAnim(oldCount, curCount)
    else
        self.TxtEnergyLimit.text = curCount
    end

    XDataCenter.StrongholdManager.SetCookieElectricEnergy(curCount)

    local useElectric = XDataCenter.StrongholdManager.GetTotalUseElectricEnergy()
    self.TxtEnergyUse.text = useElectric
    self.TxtEnergyUse.color = CONDITION_COLOR[useElectric > curCount]
end

--支援角色
function XUiStrongholdMain:UpdateAssistant()
    if not XDataCenter.StrongholdManager.CheckAssistantOpen() then
        self.BtnAssistance.gameObject:SetActiveEx(false)
        return
    end
    self.BtnAssistance.gameObject:SetActiveEx(true)

    if XDataCenter.StrongholdManager.IsHaveAssistantCharacter() then
        local characterId = XDataCenter.StrongholdManager.GetAssistantCharacterId()
        local icon = XDataCenter.CharacterManager.GetCharBigRoundnessNotItemHeadIcon(characterId)
        self.RImgAssistantRole:SetRawImage(icon)
        self.RImgAssistantRole.gameObject:SetActiveEx(true)
    else
        self.RImgAssistantRole.gameObject:SetActiveEx(false)
    end
end

--活动战报
function XUiStrongholdMain:UpdatePanelEnd()
    local finishCount = XDataCenter.StrongholdManager.GetLastFinishCount()
    local totalCount = XDataCenter.StrongholdManager.GetAllGroupCount()
    self.TxtEndProgress.text = finishCount .. "/" .. totalCount

    local minerCount = XDataCenter.StrongholdManager.GetLastMinerCount()
    self.TxtEndPeople.text = minerCount

    local totalMineral = XDataCenter.StrongholdManager.GetLastMineralCount()
    self.TxtEndMineral.text = totalMineral

    local assistNum = XDataCenter.StrongholdManager.GetLastAssistCount()
    self.TxtEndAssist.text = assistNum
end

function XUiStrongholdMain:AutoAddListener()
    self.BtnBack.CallBack = function() self:OnClickBtnBack() end
    self.BtnMainUi.CallBack = function() self:OnClickBtnMainUi() end
    self:BindHelpBtn(self.BtnHelp, "StrongholdMain")
    self.BtnShop.CallBack = function() self:OnClickBtnShop() end
    self.BtnReward.CallBack = function() self:OnClickBtnReward() end
    self.BtnMine.CallBack = function() self:OnClickBtnMine() end
    self.BtnPower.CallBack = function() self:OnClickBtnPower() end
    self.BtnTeam.CallBack = function() self:OnClickBtnTeam() end
    self.BtnAssistance.CallBack = function() self:OnClickBtnAssistance() end
    self.BtnFight.CallBack = function() self:OnClickBtnFight() end
    self.BtnStop.CallBack = function() self:OnClickBtnStop() end
end

function XUiStrongholdMain:OnClickBtnBack()
    self:Close()
end

function XUiStrongholdMain:OnClickBtnMainUi()
    XLuaUiManager.RunMain()
end

function XUiStrongholdMain:OnClickBtnShop()
    if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon)
    or XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopActive) then
        local skipId = XStrongholdConfigs.GetCommonConfig("ShopSkipId")
        XFunctionManager.SkipInterface(skipId)
    end
end

function XUiStrongholdMain:OnClickBtnReward()
    XLuaUiManager.Open("UiStrongholdRewardTip")
end

function XUiStrongholdMain:OnClickBtnMine()
    if XDataCenter.StrongholdManager.HasMineralLeft() then
        local cb = function(mineralCount)
            if mineralCount <= 0 then return end
            local msg = CsXTextManagerGetText("StrongholdGetMianralLeft", mineralCount)
            XUiManager.TipMsg(msg)
        end
        XDataCenter.StrongholdManager.GetStrongholdMineralRequest(cb)
    else
        XDataCenter.StrongholdManager.EnterUiMine()
    end
end

function XUiStrongholdMain:OnClickBtnPower()
    XLuaUiManager.Open("UiStrongholdPower")
end

function XUiStrongholdMain:OnClickBtnFight()
    local fightingGroupId = XDataCenter.StrongholdManager.CheckAnyGroupHasFinishedStage()
    if XTool.IsNumberValid(fightingGroupId) then
        XDataCenter.StrongholdManager.SetCurrentSelectGroupId(fightingGroupId)
        XLuaUiManager.Open("UiStrongholdDeploy", fightingGroupId)
    else
        XLuaUiManager.Open("UiStrongholdMainLineBanner")
    end
end

function XUiStrongholdMain:OnClickBtnTeam()
    local groupId = XDataCenter.StrongholdManager.CheckAnyGroupHasFinishedStage()
    if groupId then
        local callFunc = function()
            local cb = function()
                XLuaUiManager.Open("UiStrongholdDeploy")
            end
            XDataCenter.StrongholdManager.ResetStrongholdGroupRequest(groupId, cb)
        end
        local title = CSXTextManagerGetText("StrongholdTeamRestartConfirmTitle")
        local content = CSXTextManagerGetText("StrongholdTeamRestartConfirmContent")
        XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, callFunc)
    else
        XLuaUiManager.Open("UiStrongholdDeploy")
    end
end

function XUiStrongholdMain:OnClickBtnAssistance()
    XDataCenter.StrongholdManager.EnterUiAssistant()
end

function XUiStrongholdMain:OnClickBtnStop()
    if not XDataCenter.StrongholdManager.CheckPauseTimeAfterFightBegin() then
        XUiManager.TipText("StrongholdPauseTimeAfterFightBegin")
        return
    end

    if not XDataCenter.StrongholdManager.CheckPauseTimeBeforeFightEnd() then
        XUiManager.TipText("StrongholdPauseTimeBeforeFightEnd")
        return
    end

    local callFunc = function()
        if not XDataCenter.StrongholdManager.CheckSetStrongholdStayRequestCD() then return end
        XDataCenter.StrongholdManager.SetStrongholdStayRequest()
    end
    local title = CSXTextManagerGetText("StrongholdPauseConfirmTitle")
    local content = CSXTextManagerGetText("StrongholdPauseConfirmContent")
    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, callFunc)
end

function XUiStrongholdMain:PlayMineUpAnim(startNum, targetNum)
    local asynPlayAnim = asynTask(self.PlayAnimation, self)
    local asynLetMineRoll = asynTask(self.LetMineRoll, self)

    RunAsyn(function()
        local startMinerCount = startNum or 0
        local targetMinerCount = targetNum or 0
        local startMine = XDataCenter.StrongholdManager.GetMineralOutput(startMinerCount)
        local targetMine = XDataCenter.StrongholdManager.GetMineralOutput(targetMinerCount)

        local deltaHp = targetMinerCount - startMinerCount
        self.TxtUpPeople.text = "+" .. deltaHp
        local deltaAttack = targetMine - startMine
        self.TxtUpMine.text = "+" .. deltaAttack

        self.ImgUpMine.gameObject:SetActiveEx(true)
        self.ImgUpPeople.gameObject:SetActiveEx(true)
        self:PlayAnimation("ImgUpPeopleEnable")
        self:PlayAnimation("ImgUpMineEnable")
        asynLetMineRoll(startMinerCount, targetMinerCount, startMine, targetMine)
        self:PlayAnimation("ImgUpPeopleDisable")
        self:PlayAnimation("ImgUpMineDisable")
        self.ImgUpMine.gameObject:SetActiveEx(false)
        self.ImgUpPeople.gameObject:SetActiveEx(false)
    end)
end

function XUiStrongholdMain:LetMineRoll(startMinerCount, targetMinerCount, startMine, targetMine, finishCb)
    if not targetMinerCount then return end
    if not targetMine then return end
    local onRefreshFunc = function(time)
        if XTool.UObjIsNil(self.TxtPeople)
        or XTool.UObjIsNil(self.TxtMine)
        then
            self:DestroyMineTimer()
            return true
        end
        if startMinerCount == targetMinerCount
        and startMine == targetMine
        then
            return true
        end
        self.TxtPeople.text = mathFloor(Lerp(startMinerCount, targetMinerCount, time))
        self.TxtMine.text = mathFloor(Lerp(startMine, targetMine, time))
    end
    self:DestroyMineTimer()
    self.MineTimer = XUiHelper.Tween(SCORE_ANIM_DURATION, onRefreshFunc, finishCb)
end

function XUiStrongholdMain:DestroyMineTimer()
    if self.MineTimer then
        CSXScheduleManagerUnSchedule(self.MineTimer)
        self.MineTimer = nil
    end
end

function XUiStrongholdMain:PlayElectricUpAnim(startNum, targetNum)
    local asynPlayAnim = asynTask(self.PlayAnimation, self)
    local asynLetElectricRoll = asynTask(self.LetElectricRoll, self)

    RunAsyn(function()
        local startElectric = startNum or 0
        local targetElectric = targetNum or 0
        local deltaHp = targetElectric - startElectric

        self.TxtUpEnergy.text = "+" .. deltaHp

        self.ImgUpEnergy.gameObject:SetActiveEx(true)
        self:PlayAnimation("ImgUpEnergyEnable")
        asynLetElectricRoll(startElectric, targetElectric)
        self:PlayAnimation("ImgUpEnergyDisable")
        self.ImgUpEnergy.gameObject:SetActiveEx(false)
    end)
end

function XUiStrongholdMain:LetElectricRoll(startElectric, targetElectric, finishCb)
    if not targetElectric then return end
    if not startElectric then return end
    local onRefreshFunc = function(time)
        if XTool.UObjIsNil(self.TxtEnergyLimit)
        then
            self:DestroyElectricTimer()
            return true
        end
        if startElectric == targetElectric
        then
            return true
        end
        self.TxtEnergyLimit.text = mathFloor(Lerp(startElectric, targetElectric, time))
    end
    self:DestroyElectricTimer()
    self.ElectricTimer = XUiHelper.Tween(SCORE_ANIM_DURATION, onRefreshFunc, finishCb)
end

function XUiStrongholdMain:DestroyElectricTimer()
    if self.ElectricTimer then
        CSXScheduleManagerUnSchedule(self.ElectricTimer)
        self.ElectricTimer = nil
    end
end