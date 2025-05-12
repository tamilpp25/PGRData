local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local CsXTextManagerGetText = CS.XTextManager.GetText
local CsXScheduleManager = XScheduleManager
---@class XUiFubenRepeatchallenge
local XUiFubenRepeatchallenge = XLuaUiManager.Register(XLuaUi, "UiFubenRepeatchallenge")

local XUiPanelRepeatChallengeShowGoods = require('XUi/XUiFubenRepeatchallenge/XUiPanelRepeatChallengeShowGoods')

local PanelState = {
    None = 1, --主界面状态
    ShowDetail = 2 --打开详细页的状态
}
---记录界面状态，该值不随界面销毁而清除，保证状态的还原
--local CurPanelState=PanelState.None

function XUiFubenRepeatchallenge:OnAwake()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    --主面板
    self:RegisterClickEvent(self.BtnBack, self.Close)
    --self:RegisterClickEvent(self.TouMing, self.OnBtnTouMingClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnHelp, self.OnBtnHelpClick)
    self:RegisterClickEvent(self.BtnRewardInfo, self.OnBtnRewardInfo)
    --self:RegisterClickEvent(self.BtnLevel, self.ShowStageDetail)
    --待机面板(显示等级 奖励 商店)
    local panel = self.PanelStandByInfo
    self.PanelStandByInfo = {}
    XTool.InitUiObjectByUi(self.PanelStandByInfo, panel)
    self.PanelStandByInfo.BtnLevelDes.CallBack = function()
        self:OnBtnLevelDesClick()
    end
    self.PanelStandByInfo.BtnShop.CallBack = function()
        self:OnBtnShopClick()
    end

    --关卡面板（显示体力 挑战按钮等）
    local panel = self.PanelStageDetail
    self.PanelStageDetail = {}
    XTool.InitUiObjectByUi(self.PanelStageDetail, panel)
    self.PanelStageDetail.BtnEnter.CallBack = function()
        self:OnBtnEnterClick()
    end
    self.PanelStageDetail.BtnFirstEnter.CallBack = function()
        self:OnBtnFirstEnterClick()
    end
    self.PanelStageDetail.BtnAutoFight.CallBack = function()
        self:OnBtnAutoFightClick()
    end
    self.PanelStageDetail.BtnAddTimes.CallBack = function()
        self:OnBtnAddTimesClick()
    end
    self.PanelStageDetail.BtnMinusTimes.CallBack = function()
        self:OnBtnMinusTimesClick()
    end
    self.PanelStageDetail.BtnMax.CallBack = function()
        self:OBtnMaxClick()
    end
    self.PanelStageDetail.InputFieldCount.onValueChanged:AddListener(function()
        self:OnInputFieldCountChanged()
    end)

    XEventManager.DispatchEvent(XEventId.EVENT_REPEAT_CHALLENGE_ENTER)
end

function XUiFubenRepeatchallenge:OnStart()
    self.ChallengeCount = 1 --复刷关复刷次数
    self.RewardDatas = {} --奖励获取得情况数据
    if XDataCenter.FubenRepeatChallengeManager.IsResetPanelState() then
        --CurPanelState=PanelState.None
        XDataCenter.FubenRepeatChallengeManager.ResetPanelState(false)
    end

    self.CoinRedPointId = XRedPointManager.AddRedPointEvent(self.PanelStandByInfo.BtnShop, function(count)
        self.PanelStandByInfo.BtnShop:ShowReddot(count >= 0)
    end, nil, { XRedPointConditions.Types.CONDITION_REPEAT_CHALLENGE_COIN }, nil, false)

    self._ShowGoodsPanel = XUiPanelRepeatChallengeShowGoods.New(self.PanelReward, self)
    self._ShowGoodsPanel:Open()
end

function XUiFubenRepeatchallenge:OnEnable()
    if not XDataCenter.FubenRepeatChallengeManager.GetIsFirstAutoFightOpen() and XDataCenter.FubenRepeatChallengeManager.IsAutoFightOpen() then
        XDataCenter.FubenRepeatChallengeManager.SetAutoFightOpen()
        XUiManager.TipErrorWithKey("AutoFightUnLock")
    end
    self:Refresh()
end

function XUiFubenRepeatchallenge:OnDisable()
end

function XUiFubenRepeatchallenge:OnDestroy()
    XRedPointManager.RemoveRedPointEvent(self.CoinRedPointId)
end

--刷新主面板界面
function XUiFubenRepeatchallenge:Refresh()
    XRedPointManager.Check(self.CoinRedPointId)
    local activityCfg = XDataCenter.FubenRepeatChallengeManager.GetActivityConfig()
    local chapterCfg = XFubenRepeatChallengeConfigs.GetChapterCfg(activityCfg.NormalChapter[1])
    local rcStageCfg = XFubenRepeatChallengeConfigs.GetStageConfig(chapterCfg.StageId[1])
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(rcStageCfg.Id)
    self.RImgBg:SetRawImage(chapterCfg.Bg)

    self.PanelEffect.gameObject:LoadUiEffect(chapterCfg.EffectPath)
    self.BtnLevel:SetNameByGroup(0, stageCfg.Name)
    --btnLevel根据时间判断是否显示Close图标
    if not XDataCenter.FubenRepeatChallengeManager.IsOpen() then
        if self.RImgClosed then
            self.RImgClosed.gameObject:SetActiveEx(true)
        end
    else
        if self.RImgClosed then
            self.RImgClosed.gameObject:SetActiveEx(false)
        end
    end
    --当期货币
    --local versionItemId = XFubenConfigs.GetMainPanelItemId()
    --self.BtnRewardInfo:SetRawImage(XDataCenter.ItemManager.GetItemIcon(versionItemId))

    self:RefreshPanelStandByInfo()
    self:RefreshPanelStageDetail()
    self:RefreshChallengeTimes()
    --if CurPanelState==PanelState.ShowDetail then
    --    self:ShowStageDetail()
    --else
    --    self:CloseStageDetail()
    --end
    self:SetMaxChallengeTimes()
    self:RefreshPanelStageDetail()
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
    self.TxtDropMult.text = "X" .. self.ChallengeCount
    self.PanelStageDetail.InputFieldCount.text = self.ChallengeCount
    local stageId = XDataCenter.FubenRepeatChallengeManager.GetStageId()
    local actionPoint = XDataCenter.FubenManager.GetRequireActionPoint(stageId)
    local actionPointTotal = actionPoint * self.ChallengeCount
    self.TxtActionPoint.text = actionPointTotal
end
--打开关卡详情
--function XUiFubenRepeatchallenge:ShowStageDetail()
--    self._ShowGoodsPanel:Close()
--    --判断是否在战斗时间内
--    local isFightTime= XDataCenter.FubenRepeatChallengeManager.IsOpen()
--    if isFightTime then
--        CurPanelState=PanelState.ShowDetail
--        self.PanelStandByInfo.GameObject:SetActiveEx(false)
--        self.PanelStageDetail.GameObject:SetActiveEx(true)
--        self.BtnLevel:SetDisable(true,false)
--        self:SetMaxChallengeTimes()
--        self:RefreshPanelStageDetail()
--    else
--        XUiManager.TipText('FubenRepeatchallengeEndFightTime')
--    end
--end
--关闭关卡详情
--function XUiFubenRepeatchallenge:CloseStageDetail()
--    CurPanelState=PanelState.None
--    self.PanelStandByInfo.GameObject:SetActiveEx(true)
--    self.PanelStageDetail.GameObject:SetActiveEx(false)
--    self.BtnLevel:SetDisable(false)
--    self:RefreshPanelStandByInfo()
--    self._ShowGoodsPanel:Open()
--end
--后退按钮
function XUiFubenRepeatchallenge:Close()
    --if CurPanelState==PanelState.ShowDetail then
    --    self:CloseStageDetail()
    --    return
    --end
    self.Super.Close(self)
end
-- 大透明后退按钮(点开关卡后后退使用)
--function XUiFubenRepeatchallenge:OnBtnTouMingClick()
--    if CurPanelState==PanelState.ShowDetail then
--        self:CloseStageDetail()
--    end
--end
--主界面按钮
function XUiFubenRepeatchallenge:OnBtnMainUiClick()
    --CurPanelState=PanelState.None
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
    XFunctionManager.SkipInterface(skipId, true)
end

--点击进入关卡
function XUiFubenRepeatchallenge:OnBtnEnterClick()
    --CurPanelState=PanelState.ShowDetail
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.Main_huge)
    local isFightTime = XDataCenter.FubenRepeatChallengeManager.IsOpen()
    if not isFightTime then
        XUiManager.TipText('FubenRepeatchallengeEndFightTime')
    end
    local stageId = XDataCenter.FubenRepeatChallengeManager.GetStageId()
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
    if XDataCenter.FubenManager.CheckPreFight(stageCfg, self.ChallengeCount) then
        XLuaUiManager.Open("UiBattleRoleRoom", stageId, nil, {
            EnterFight = function(proxy, team, stageId, challengeCount, isAssist)
                XDataCenter.FubenDailyManager.SetFubenDailyRecord(stageId)
                proxy.Super.EnterFight(proxy, team, stageId, challengeCount, isAssist)
            end
        }, self.ChallengeCount)
    end
end
--点击扫荡
function XUiFubenRepeatchallenge:OnBtnAutoFightClick()
    if not XDataCenter.FubenRepeatChallengeManager.IsOpen() then
        XUiManager.TipText("ActivityRepeatChallengeOver")
        return false
    end

    if not XDataCenter.FubenRepeatChallengeManager.IsOpen() then
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
    if maxChallengeCount < 1 then
        maxChallengeCount = 1
    end
    local text = self.PanelStageDetail.InputFieldCount.text
    local num = tonumber(text)
    if num then
        --not (num == nil) then
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
    if maxChallengeCount < 1 then
        maxChallengeCount = 1
    end
    if self.ChallengeCount >= maxChallengeCount then
        return
    end
    self.ChallengeCount = self.ChallengeCount + 1
    self:RefreshChallengeTimes()
end
--点击减少复刷次数
function XUiFubenRepeatchallenge:OnBtnMinusTimesClick()
    if self.ChallengeCount <= 1 then
        return
    end
    self.ChallengeCount = self.ChallengeCount - 1
    self:RefreshChallengeTimes()
end
--点击最大复刷次数
function XUiFubenRepeatchallenge:OBtnMaxClick()
    self:SetMaxChallengeTimes()
end

function XUiFubenRepeatchallenge:SetMaxChallengeTimes()
    local maxChallengeCount = XDataCenter.FubenManager.GetStageMaxChallengeCount(XDataCenter.FubenRepeatChallengeManager.GetStageId())
    if maxChallengeCount < 1 then
        maxChallengeCount = 1
    end
    self.ChallengeCount = maxChallengeCount
    self:RefreshChallengeTimes()
end 