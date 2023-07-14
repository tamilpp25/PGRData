--虚像地平线主界面
local XUiExpeditionMain = XLuaUiManager.Register(XLuaUi, "UiExpeditionMain")
local XUiExpeditionChapter = require("XUi/XUiExpedition/MainPage/XUiExpeditionChapter")
local XUiGlobalComboIcon = require("XUi/XUiExpedition/MainPage/ChapterBuff/XUiGlobalComboIcon")
function XUiExpeditionMain:OnAwake()
    XTool.InitUiObject(self)
    XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.GridBuffIcon.gameObject:SetActiveEx(false)
    self:AddListener()
    XDataCenter.ExpeditionManager.SetIfBackMain(false)
end

function XUiExpeditionMain:OnStart()
    self:InitPanel()
    XDataCenter.ExpeditionManager.GetMyRankingData()
end

function XUiExpeditionMain:InitPanel()
    self:InitChapter() 
    self:InitGlobalCombo()
end

function XUiExpeditionMain:OnEnable()
    self:OnRefresh()
    self.BtnRecruit:ShowReddot(XDataCenter.ExpeditionManager.GetCanRecruit())
    XDataCenter.ExpeditionManager.GetMyRankingData()
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_STAGE_SYNC, self.OnSyncStage, self)
end

function XUiExpeditionMain:OnDisable()
    self:StopTimer()
    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_STAGE_SYNC, self.OnSyncStage, self)
end

function XUiExpeditionMain:OnDestroy()
    self:StopTimer()
    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_STAGE_SYNC, self.OnSyncStage, self)
end

function XUiExpeditionMain:OnGetEvents()
    return { XEventId.EVENT_EXPEDITION_RECRUITTIME_REFRESH, XEventId.EVENT_EXPEDITION_ON_GET_CHAPTER_REWARD, XEventId.EVENT_ACTIVITY_ON_RESET, XEventId.EVENT_EXPEDITION_RANKING_REFRESH }
end

function XUiExpeditionMain:OnNotify(evt, ...)
    local args = { ... }
    if evt == XEventId.EVENT_EXPEDITION_RECRUITTIME_REFRESH then
        self:RefreshRecruitNumber()
    elseif evt == XEventId.EVENT_EXPEDITION_ON_GET_CHAPTER_REWARD then
        self:OnGetTreasure(args[1], args[2])
        self:RefreshProgress()
    elseif evt == XEventId.EVENT_ACTIVITY_ON_RESET then
        if args[1] ~= XDataCenter.FubenManager.StageType.Expedition then return end
        self:OnActivityReset()
    elseif evt == XEventId.EVENT_EXPEDITION_RANKING_REFRESH then
        self:RefreshRanking()
    end
end

function XUiExpeditionMain:OnActivityReset()
    self:StopTimer()
    XLuaUiManager.RunMain()
    XUiManager.TipMsg(CS.XTextManager.GetText("ExpeditionOnClose"))
end

function XUiExpeditionMain:InitChapter()
    self.ChapterComponent = XUiExpeditionChapter.New(self)
    self:SwitchDifficulty(XDataCenter.ExpeditionManager.StageDifficulty.Normal)
end

function XUiExpeditionMain:AddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnList, self.OnBtnListClick)
    self:RegisterClickEvent(self.BtnRecruit, self.OnBtnRecruitClick)
    self:BindHelpBtn(self.BtnHelp, "ExpeditionMainHelp")
    self:RegisterClickEvent(self.BtnTreasure, self.OnBtnTreasureClick)
    self.BtnBuff.CallBack = function() self:OnBtnBuffClick() end
    if self.BtnNightmareStage then
        self.BtnNightmareStage.CallBack = function() self:OnBtnNightMareClick() end
    end
    if self.BtnNormalStage then
        self.BtnNormalStage.CallBack = function() self:OnBtnNormalClick() end
    end
    if self.BtnRanking then
        self.BtnRanking.CallBack = function() self:OnBtnRankingClick() end
    end
end

function XUiExpeditionMain:OnBtnNormalClick()
    self:SwitchDifficulty(XDataCenter.ExpeditionManager.StageDifficulty.Normal)
end

function XUiExpeditionMain:OnBtnNightMareClick()
    self:SwitchDifficulty(XDataCenter.ExpeditionManager.StageDifficulty.NightMare)
end

function XUiExpeditionMain:OnBtnTreasureClick()
    if XDataCenter.ExpeditionManager.GetIsChapterClear(self.Difficult or XDataCenter.ExpeditionManager.StageDifficulty.Normal) then
        local isGet = XDataCenter.ExpeditionManager.GetIsReceivedReward(self.Difficult or XDataCenter.ExpeditionManager.StageDifficulty.Normal)
        if not isGet then
            XDataCenter.ExpeditionManager.GetChapterReward(self.Difficult)
            return
        end
    end
    local rewardId = XDataCenter.ExpeditionManager.GetChapterRewardIdByDifficulty(self.Difficult)
    local data = XRewardManager.GetRewardList(rewardId)
    if not data then return end
    XUiManager.OpenUiTipReward(data)
end

function XUiExpeditionMain:OnGetTreasure(goodsList)
    if goodsList then
        XUiManager.OpenUiTipReward(goodsList)
    else
        local rewardId = XDataCenter.ExpeditionManager.GetChapterRewardIdByDifficulty(self.Difficult)
        local data = XRewardManager.GetRewardList(rewardId)
        if not data then return end
        XUiManager.OpenUiTipReward(data)
    end
end

function XUiExpeditionMain:OnBtnBackClick()
    self:Close()
end

function XUiExpeditionMain:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiExpeditionMain:OnBtnRecruitClick()
    XLuaUiManager.Open("UiExpeditionRecruit")
end

function XUiExpeditionMain:OnBtnListClick()
    if not XDataCenter.ExpeditionManager.CheckHaveMember() then
        XUiManager.TipMsg(CS.XTextManager.GetText("ExpeditionNeedRecruitMember"))
        return
    end
    XLuaUiManager.Open("UiExpeditionRoleList")
end

function XUiExpeditionMain:OnBtnBuffClick()
    local BuffTipsType = XDataCenter.ExpeditionManager.BuffTipsType.GlobalBuff
    XLuaUiManager.Open("UiExpeditionBuffTips", BuffTipsType, self.GlobalCfgs)
end

function XUiExpeditionMain:OnBtnRankingClick()
    XLuaUiManager.Open("UiExpeditionRank")
end

function XUiExpeditionMain:OnRefresh()
    self:RefreshRecruitNumber()
    self:SetResetTimer()
    self:RefreshRanking()
    self:SwitchDifficulty(self.Difficult or XDataCenter.ExpeditionManager.StageDifficulty.Normal)
end

function XUiExpeditionMain:RefreshRecruitNumber()
    self.TxtNumber.text = XDataCenter.ExpeditionManager.GetRecruitNumInfoString()
end

function XUiExpeditionMain:SetResetTimer()
    self:StopTimer()
    self:SetResetTime()
    self.Timer = XScheduleManager.ScheduleForever(function()
            self:SetResetTime()
        end, XScheduleManager.SECOND, 0)
end

function XUiExpeditionMain:SetResetTime()
    local endTimeSecond = XDataCenter.ExpeditionManager.GetResetTime()
    local now = XTime.GetServerNowTimestamp()
    local leftTime = endTimeSecond - now
    self.TxtTime.text = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
    if leftTime <= 0 then
        self:OnActivityReset()
    end
end

function XUiExpeditionMain:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiExpeditionMain:OnSyncStage()
    self.ChapterComponent:Show(self.Difficult)
    self:RefreshProgress()
end

function XUiExpeditionMain:RefreshProgress()
    local progress = XDataCenter.ExpeditionManager.GetStageCompletePercent(self.Difficult)
    self.TxtProgress.text = string.format("%d%s", math.floor(progress * 100), "%")
    local IsReceivedReward = XDataCenter.ExpeditionManager.GetIsReceivedReward(self.Difficult)
    self.ImgComplete.gameObject:SetActiveEx(IsReceivedReward)
    self.ImgProgress.fillAmount = progress
    self.ImgRedPoint.gameObject:SetActiveEx(progress == 1 and not IsReceivedReward)
end

function XUiExpeditionMain:InitGlobalCombo()
    local comboIdList = XDataCenter.ExpeditionManager.GetCurrentChapterGlobalCombos()
    if not self.GlobalIcons then self.GlobalIcons = {} end
    self.GlobalCfgs = {}
    local count = 0
    for _, comboId in pairs(comboIdList) do
        local comboCfg = XExpeditionConfig.GetGlobalConfigById(comboId)
        if comboCfg.IsVisible == 1 then
            count = count + 1
            if not self.GlobalIcons[count] then
                local prefab = CS.UnityEngine.Object.Instantiate(self.GridBuffIcon.gameObject)
                prefab.transform:SetParent(self.PanelBuffIcon.transform, false)
                local icon = XUiGlobalComboIcon.New(prefab, self)
                table.insert(self.GlobalIcons, icon)
            end
            self.GlobalIcons[count]:RefreshData(comboCfg)
            self.GlobalIcons[count].GameObject:SetActiveEx(true)
            table.insert(self.GlobalCfgs, comboCfg)
        end
    end
    for i = count + 1, #self.GlobalIcons do
        self.GlobalIcons[i].gameObject:SetActiveEx(false)
    end
end
--=============
--切换难度
--@param difficulty:难度
--=============
function XUiExpeditionMain:SwitchDifficulty(difficulty)
    self.ChapterComponent:Show(difficulty)
    self.Difficult = difficulty
    local isNightmare = self.Difficult == XDataCenter.ExpeditionManager.StageDifficulty.NightMare
    local isNormal = self.Difficult == XDataCenter.ExpeditionManager.StageDifficulty.Normal
    if self.BtnNormalStage then self.BtnNormalStage.gameObject:SetActiveEx(isNightmare) end
    if self.BtnNightmareStage then
        local isShowNightmare = isNormal and XDataCenter.ExpeditionManager.GetIsNormalClear()
        if self.NightmareStatus == nil then self.NightmareStatus = isShowNightmare end
        self.BtnNightmareStage.gameObject:SetActiveEx(isShowNightmare)
        if self.FirstRefresh and isShowNightmare and self.NightmareStatus == false then
            self.NightmareStatus = true
            XUiManager.TipMsg(CS.XTextManager.GetText("ExpeditionNightmareOpen"))
        end
    end
    if self.NightmarBg then self.NightmarBg.gameObject:SetActiveEx(isNightmare) end
    self:RefreshProgress()
    if not self.FirstRefresh then self.FirstRefresh = true end
end
--=============
--更改背景图
--@param path:图片路径
--=============
function XUiExpeditionMain:ChangeBg(path)
    if self.Bg then self.Bg:SetRawImage(path) end
end
--=============
--更改背景特效
--@param path:特效路径
--=============
function XUiExpeditionMain:ChangeBgFx(path)
    if not self.BgEffect then return end
    local disable = string.IsNilOrEmpty(path)
    self.BgEffect.gameObject:SetActiveEx(not disable)
    if disable then return end
    if self.fxName and self.fxName == path then return end
    self.fxName = path
    self.BgEffect.gameObject:LoadUiEffect(path)
end
--=============
--更改通关奖励图标
--@param path:特效路径
--=============
function XUiExpeditionMain:ChangeRewardIcon(path)
    if not path then return end
    if self.RImgBgIcon then self.RImgBgIcon:SetRawImage(path) end
end
--=============
--刷新排位
--=============
function XUiExpeditionMain:RefreshRanking()
    if self.BtnRanking then self.BtnRanking:SetName(XDataCenter.ExpeditionManager.GetSelfRankStr()) end
end