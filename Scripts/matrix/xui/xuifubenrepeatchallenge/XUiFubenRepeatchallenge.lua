local CsXTextManagerGetText = CS.XTextManager.GetText
local CsXScheduleManager = XScheduleManager

local XUiFubenRepeatchallenge = XLuaUiManager.Register(XLuaUi, "UiFubenRepeatchallenge")

local PanelState={
    None=1, --主界面状态
    ShowDetail=2 --打开详细页的状态
}
---记录界面状态，该值不随界面销毁而清除，保证状态的还原
local CurPanelState=PanelState.None

function XUiFubenRepeatchallenge:OnAwake()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    --主面板
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.TouMing, self.OnBtnTouMingClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnHelp, self.OnBtnHelpClick)
    self:RegisterClickEvent(self.BtnRewardInfo, self.OnBtnRewardInfo)
    self:RegisterClickEvent(self.BtnLevel, self.ShowStageDetail)
    --待机面板(显示等级 奖励 商店)
    local panel = self.PanelStandByInfo
    self.PanelStandByInfo = {}
    XTool.InitUiObjectByUi(self.PanelStandByInfo, panel)
    self.PanelStandByInfo.BtnLevelDes.CallBack = function() self:OnBtnLevelDesClick() end
    self.PanelStandByInfo.BtnShop.CallBack = function() self:OnBtnShopClick() end
    for i=1,5 do
        self.PanelStandByInfo["BtnReward" .. i].CallBack = function() self:OnBtnRewardClick(i) end
    end
    --关卡面板（显示体力 挑战按钮等）
    local panel = self.PanelStageDetail
    self.PanelStageDetail = {}
    XTool.InitUiObjectByUi(self.PanelStageDetail, panel)
    self.PanelStageDetail.BtnEnter.CallBack = function() self:OnBtnEnterClick() end
    self.PanelStageDetail.BtnFirstEnter.CallBack = function() self:OnBtnFirstEnterClick() end
    self.PanelStageDetail.BtnAutoFight.CallBack = function() self:OnBtnAutoFightClick() end
    self.PanelStageDetail.BtnAddTimes.CallBack = function() self:OnBtnAddTimesClick() end
    self.PanelStageDetail.BtnMinusTimes.CallBack = function() self:OnBtnMinusTimesClick() end
    self.PanelStageDetail.BtnMax.CallBack = function() self:OBtnMaxClick() end
    self.PanelStageDetail.InputFieldCount.onValueChanged:AddListener(function() self:OnInputFieldCountChanged() end)
end

function XUiFubenRepeatchallenge:OnStart()
    self.ChallengeCount = 1 --复刷关复刷次数
    self.RewardDatas = {} --奖励获取得情况数据
    if XDataCenter.FubenRepeatChallengeManager.IsResetPanelState() then
        CurPanelState=PanelState.None
        XDataCenter.FubenRepeatChallengeManager.ResetPanelState(false)
    end
    
    --self.RedPointId = XRedPointManager.AddRedPointEvent(self.BtnTreasure, self.OnCheckRewards, self, { XRedPointConditions.Types.CONDITION_REPEAT_CHALLENGE_CHAPTER_REWARD }, nil, false)
end

function XUiFubenRepeatchallenge:OnEnable()
    if not XDataCenter.FubenRepeatChallengeManager.GetIsFirstAutoFightOpen() and XDataCenter.FubenRepeatChallengeManager.IsAutoFightOpen() then
        XDataCenter.FubenRepeatChallengeManager.SetAutoFightOpen()
        XUiManager.TipErrorWithKey("AutoFightUnLock")
    end
    self:CreateActivityTimer()
    self:Refresh()
end

function XUiFubenRepeatchallenge:OnDisable()
    self:DestroyActivityTimer()
end
--region 活动倒计时显示
function XUiFubenRepeatchallenge:CreateActivityTimer()
    self:DestroyActivityTimer()

    local time = XTime.GetServerNowTimestamp()
    local fightEndTime = XDataCenter.FubenRepeatChallengeManager.GetFightEndTime()
    local activityEndTime = XDataCenter.FubenRepeatChallengeManager.GetActivityEndTime()
    local shopStr = CsXTextManagerGetText("ActivityBranchShopLeftTime")
    local fightStr = CsXTextManagerGetText("ActivityBranchFightLeftTime")

    if XDataCenter.FubenRepeatChallengeManager.IsStatusEqualFightEnd() then
        self.TxtResetDesc.text = shopStr
        self.TxtLeftTime.text = XUiHelper.GetTime(activityEndTime - time, XUiHelper.TimeFormatType.ACTIVITY)
    else
        self.TxtResetDesc.text = fightStr
        self.TxtLeftTime.text = XUiHelper.GetTime(fightEndTime - time, XUiHelper.TimeFormatType.ACTIVITY)
    end

    self.ActivityTimer = CsXScheduleManager.ScheduleForever(function()
        if XTool.UObjIsNil(self.TxtLeftTime) then
            self:DestroyActivityTimer()
            return
        end

        time = time + 1

        if time >= activityEndTime then
            self:DestroyActivityTimer()
            XDataCenter.FubenRepeatChallengeManager.OnActivityEnd()
        elseif fightEndTime <= time then
            local leftTime = activityEndTime - time
            if leftTime > 0 then
                self.TxtResetDesc.text = shopStr
                self.TxtLeftTime.text = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
            end
        else
            local leftTime = fightEndTime - time
            if leftTime > 0 then
                self.TxtResetDesc.text = fightStr
                self.TxtLeftTime.text = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
            else
                self:DestroyActivityTimer()
                self:CreateActivityTimer()
            end
        end
    end, CsXScheduleManager.SECOND, 0)
end
function XUiFubenRepeatchallenge:DestroyActivityTimer()
    if self.ActivityTimer then
        CsXScheduleManager.UnSchedule(self.ActivityTimer)
        self.ActivityTimer = nil
    end
end
--endregion
--刷新主面板界面
function XUiFubenRepeatchallenge:Refresh()
    self:CreateActivityTimer()
    local activityCfg = XDataCenter.FubenRepeatChallengeManager.GetActivityConfig()
    local chapterCfg = XFubenRepeatChallengeConfigs.GetChapterCfg(activityCfg.NormalChapter[1])
    local rcStageCfg = XFubenRepeatChallengeConfigs.GetStageConfig(chapterCfg.StageId[1])
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(rcStageCfg.Id)
    self.RImgBg:SetRawImage(chapterCfg.Bg)
    local characterName = XCharacterConfigs.GetCharacterLogName(activityCfg.SpecialCharacters[1])
    local limitLevel = activityCfg.ExtraBuffLevel
    self.TxtTitle.text = CsXTextManagerGetText("ActivityRepeatChallengeDesc", characterName , limitLevel)
    self.PanelEffect.gameObject:LoadUiEffect(chapterCfg.EffectPath)
    self.BtnLevel:SetNameByGroup(0, stageCfg.Name)
    --btnLevel根据时间判断是否显示Close图标
    if XDataCenter.FubenRepeatChallengeManager.IsStatusEqualFightEnd() then
        if self.RImgClosed then
            self.RImgClosed.gameObject:SetActiveEx(true)
        end
    else
        if self.RImgClosed then
            self.RImgClosed.gameObject:SetActiveEx(false)
        end
    end
    --当期货币
    local versionItemId = XFubenConfigs.GetMainPanelItemId()
    self.BtnRewardInfo:SetRawImage(XDataCenter.ItemManager.GetItemIcon(versionItemId))
    
    self:RefreshPanelStandByInfo()
    self:RefreshPanelStageDetail()
    self:RefreshChallengeTimes()
    if CurPanelState==PanelState.ShowDetail then
        self:ShowStageDetail()
    else
        self:CloseStageDetail()
    end
end
--刷新待机面板界面(显示等级 奖励 商店)
function XUiFubenRepeatchallenge:RefreshPanelStandByInfo()
    local panel = self.PanelStandByInfo
    --refresh level
    local level = XDataCenter.FubenRepeatChallengeManager.GetLevel()
    local exp = XDataCenter.FubenRepeatChallengeManager.GetExp()
    local levelConfig = XFubenRepeatChallengeConfigs.GetLevelConfig(level)
    local curLevelMaxExp = levelConfig.UpExp
    local isMaxLv = level == XFubenRepeatChallengeConfigs.GetMaxLevel()

    panel.ImgExp.fillAmount = isMaxLv and 1 or (exp / curLevelMaxExp)
    panel.TxtBuffDes.gameObject:SetActiveEx(not isMaxLv)
    panel.TxtLevel.text = CsXTextManagerGetText("ActivityRepeatChallengeLevel", level)
    local nextShowLevel = XDataCenter.FubenRepeatChallengeManager.GetNextShowLevel()
    if nextShowLevel then
        local nextLvCfg = XFubenRepeatChallengeConfigs.GetLevelConfig(nextShowLevel)
        panel.TxtBuffDes.text = nextLvCfg.SimpleDesc
        panel.TxtExp.text = CsXTextManagerGetText("ActivityRepeatChallengeNextLevelDesc", nextShowLevel)
    else
        panel.TxtBuffDes.gameObject:SetActiveEx(false)
        panel.TxtExp.transform.position = CS.UnityEngine.Vector3.Lerp(panel.TxtExp.transform.position, panel.TxtBuffDes.transform.position, 0.5)
        if isMaxLv then
            panel.TxtExp.text = CsXTextManagerGetText("ActivityRepeatChallengeMaxLevelTip")
        else
            panel.TxtExp.text = CsXTextManagerGetText("ActivityRepeatChallengeExp", exp, curLevelMaxExp)
        end
    end
    -- TxtExpMax -> "(已达每日上限)"
    panel.TxtExpMax.gameObject:SetActiveEx(false)

    --refresh reward
    self.RewardDatas = XDataCenter.FubenRepeatChallengeManager.GetRewardsData()
    for i=1,5 do
        local button = panel["BtnReward" .. i]
        local buttonUiObject = {}
        XTool.InitUiObjectByUi(buttonUiObject, button)
        local data = self.RewardDatas[i]
        if not data then
            button.gameObject:SetActiveEx(false)
            goto CONTINUE
        end
        button.gameObject:SetActiveEx(true)
        -- 获取条件描述
        button:SetNameByGroup(0, data.Desc) 
        -- 按钮状态
        button:ShowReddot(false)
        if not data.canObtain then --未能领取
            button:SetDisable(true)
            buttonUiObject.Disable2.gameObject:SetActiveEx(true)
            buttonUiObject.Disable1.gameObject:SetActiveEx(false)
        elseif data.Obtained then --已经领取
            button:SetDisable(true)
            buttonUiObject.Disable1.gameObject:SetActiveEx(true)
            buttonUiObject.Disable2.gameObject:SetActiveEx(false)
        elseif (not data.Obtained) and data.canObtain then --可以 但还没领取
            button:ShowReddot(true)
            button:SetDisable(false)
        end
        :: CONTINUE ::
    end
end
--刷新关卡面板界面（显示体力 挑战按钮等）
function XUiFubenRepeatchallenge:RefreshPanelStageDetail()
    local panel = self.PanelStageDetail
    --自动战斗按钮
    panel.BtnAutoFight.gameObject:SetActiveEx(XDataCenter.FubenRepeatChallengeManager.IsAutoFightOpen())
    --panel.ImgCostActionPoint
end
--刷新行动点数显示
function XUiFubenRepeatchallenge:RefreshChallengeTimes()
    self.BtnLevel:SetNameByGroup(1,"X"..self.ChallengeCount)
    self.PanelStageDetail.InputFieldCount.text = self.ChallengeCount
    local stageId = XDataCenter.FubenRepeatChallengeManager.GetStageId()
    local actionPoint = XDataCenter.FubenManager.GetRequireActionPoint(stageId)
    self.PanelStageDetail.TxtActionPoint.text = actionPoint * self.ChallengeCount
end
--打开关卡详情
function XUiFubenRepeatchallenge:ShowStageDetail()
    
    --判断是否在战斗时间内
    local isFightTime=not XDataCenter.FubenRepeatChallengeManager.IsStatusEqualFightEnd()
    if isFightTime then
        CurPanelState=PanelState.ShowDetail
        self.PanelStandByInfo.GameObject:SetActiveEx(false)
        self.PanelStageDetail.GameObject:SetActiveEx(true)
        self.BtnLevel:SetDisable(true,false)
        self:SetMaxChallengeTimes()
        self:RefreshPanelStageDetail()
    else
        XUiManager.TipText('FubenRepeatchallengeEndFightTime')
    end
end
--关闭关卡详情
function XUiFubenRepeatchallenge:CloseStageDetail()
    CurPanelState=PanelState.None
    self.PanelStandByInfo.GameObject:SetActiveEx(true)
    self.PanelStageDetail.GameObject:SetActiveEx(false)
    self.BtnLevel:SetDisable(false)
    self:RefreshPanelStandByInfo()
end
--后退按钮
function XUiFubenRepeatchallenge:Close()
    if CurPanelState==PanelState.ShowDetail then
        self:CloseStageDetail()
        return
    end
    self.Super.Close(self)
end
-- 大透明后退按钮(点开关卡后后退使用)
function XUiFubenRepeatchallenge:OnBtnTouMingClick()
    if CurPanelState==PanelState.ShowDetail then
        self:CloseStageDetail()
    end
end
--主界面按钮
function XUiFubenRepeatchallenge:OnBtnMainUiClick()
    CurPanelState=PanelState.None
    XLuaUiManager.RunMain()
end
--帮助按钮（感叹号）
function XUiFubenRepeatchallenge:OnBtnHelpClick()
    XUiManager.UiFubenDialogTip("", XDataCenter.FubenRepeatChallengeManager.GetActDescription())
end
--点击关卡奖励预览 显示奖励货币的道具详情
function XUiFubenRepeatchallenge:OnBtnRewardInfo()
    --local stageId = XDataCenter.FubenRepeatChallengeManager.GetStageId()
    --local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
    --local itemList = XRewardManager.GetRewardList(stageCfg.FinishRewardShow)
    --XUiManager.OpenUiTipReward(itemList)
    local itemID = XFubenConfigs.GetMainPanelItemId()
    XLuaUiManager.Open("UiTip", itemID)
end
--点击等级详情按钮
function XUiFubenRepeatchallenge:OnBtnLevelDesClick()
    XLuaUiManager.Open("UiFubenRepeatchallengeLevelDes")
end
--点击商店按钮
function XUiFubenRepeatchallenge:OnBtnShopClick()
    local skipId = XDataCenter.FubenRepeatChallengeManager.GetActivityConfig().ShopSkipId
    XFunctionManager.SkipInterface(skipId)
end
--点击奖励按钮
function XUiFubenRepeatchallenge:OnBtnRewardClick(tabIndex)
    local rewardData = self.RewardDatas[tabIndex]
    if rewardData.canObtain  and (not rewardData.Obtained) then
        --能领取
        XDataCenter.FubenRepeatChallengeManager.RequesetGetReward(rewardData.RewardId, function()
            self:RefreshPanelStandByInfo()
        end)
    else
        --其余情况显示道具详情
        local itemList = XRewardManager.GetRewardList(rewardData.RewardItemListId)
        XUiManager.OpenUiTipReward(itemList)
    end
end
--点击进入关卡
function XUiFubenRepeatchallenge:OnBtnEnterClick()
    CurPanelState=PanelState.ShowDetail
    CS.XAudioManager.PlaySound(XSoundManager.UiBasicsMusic.Main_huge)
    local stageId = XDataCenter.FubenRepeatChallengeManager.GetStageId()
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
    if XDataCenter.FubenManager.CheckPreFight(stageCfg, self.ChallengeCount) then
        if XTool.USENEWBATTLEROOM then
            XLuaUiManager.Open("UiBattleRoleRoom", stageId, nil, {
                EnterFight = function(proxy, team, stageId, challengeCount, isAssist)
                    XDataCenter.FubenDailyManager.SetFubenDailyRecord(stageId)
                    proxy.Super.EnterFight(proxy, team, stageId, challengeCount, isAssist)
                end
            }, self.ChallengeCount)
        else
            local data = {ChallengeCount = self.ChallengeCount}
            XLuaUiManager.Open("UiNewRoomSingle", stageId, data)
        end
    end
end
--点击扫荡
function XUiFubenRepeatchallenge:OnBtnAutoFightClick()
    if not XDataCenter.FubenRepeatChallengeManager.IsOpen() then
        XUiManager.TipText("ActivityRepeatChallengeOver")
        return false
    end

    if XDataCenter.FubenRepeatChallengeManager.IsStatusEqualFightEnd() then
        XUiManager.TipText("ActivityRepeatChallengeOver")
        return false
    end
    if not XDataCenter.FubenRepeatChallengeManager.IsAutoFightOpen() then
        XUiManager.TipErrorWithKey("FubenRepeatChallengeAutoFightOpenTip")
        return false
    end
    local stageId = XDataCenter.FubenRepeatChallengeManager.GetStageId()
    local stageData = XDataCenter.FubenManager.GetStageData(stageId)
    XDataCenter.AutoFightManager.RecordFightBeginData(stageId, self.ChallengeCount, stageData.LastCardIds)
    XDataCenter.AutoFightManager.StartNewAutoFight(stageId, self.ChallengeCount, function(res)
        if res.Code == XCode.Success then
            XLuaUiManager.Open("UiNewAutoFightSettleWin", XDataCenter.AutoFightManager.GetAutoFightBeginData(), res)
        end
    end)
    return true
end
--编辑复刷次数
function XUiFubenRepeatchallenge:OnInputFieldCountChanged()
    local maxChallengeCount = XDataCenter.FubenManager.GetStageMaxChallengeCount(XDataCenter.FubenRepeatChallengeManager.GetStageId())
    if maxChallengeCount < 1 then maxChallengeCount = 1 end
    local text = self.PanelStageDetail.InputFieldCount.text
    local num = tonumber(text)
    if num then --not (num == nil) then
        if num > maxChallengeCount then
            num = maxChallengeCount
        elseif num < 1 then
            num = 1
        end
        self.ChallengeCount = num
    end
    self:RefreshChallengeTimes()
end
--点击添加复刷次数
function XUiFubenRepeatchallenge:OnBtnAddTimesClick()
    local maxChallengeCount = XDataCenter.FubenManager.GetStageMaxChallengeCount(XDataCenter.FubenRepeatChallengeManager.GetStageId())
    if maxChallengeCount < 1 then maxChallengeCount = 1 end
    if self.ChallengeCount >= maxChallengeCount then return end
    self.ChallengeCount = self.ChallengeCount + 1
    self:RefreshChallengeTimes()
end
--点击减少复刷次数
function XUiFubenRepeatchallenge:OnBtnMinusTimesClick()
    if self.ChallengeCount <= 1 then return end
    self.ChallengeCount = self.ChallengeCount - 1
    self:RefreshChallengeTimes()
end
--点击最大复刷次数
function XUiFubenRepeatchallenge:OBtnMaxClick()
    self:SetMaxChallengeTimes()
end

function XUiFubenRepeatchallenge:SetMaxChallengeTimes()
    local maxChallengeCount = XDataCenter.FubenManager.GetStageMaxChallengeCount(XDataCenter.FubenRepeatChallengeManager.GetStageId())
    if maxChallengeCount < 1 then maxChallengeCount = 1 end
    self.ChallengeCount = maxChallengeCount
    self:RefreshChallengeTimes()
end 