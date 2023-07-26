--虚像地平线主界面
local XUiExpeditionMain = XLuaUiManager.Register(XLuaUi, "UiExpeditionMain")
local XUiGridExpeditionChapter = require("XUi/XUiExpedition/Chapter/XUiGridExpeditionChapter")
function XUiExpeditionMain:OnAwake()
    XTool.InitUiObject(self)
    XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self:AddListener()
    XDataCenter.ExpeditionManager.SetIfBackMain(false)
end

function XUiExpeditionMain:OnStart()
    self:InitPanel()
end

function XUiExpeditionMain:InitPanel()
    self:InitChapter() 
end

function XUiExpeditionMain:OnEnable()
    self:OnRefresh()
    self.BtnRecruit:ShowReddot(XDataCenter.ExpeditionManager.GetCanRecruit())
    XDataCenter.ExpeditionManager.GetMyRankingData()
    self:UpdateCurChapter()
    self:GoToLastPassStage()
    self:RefreshTaskRedPoint()
end

function XUiExpeditionMain:OnDisable()
    self:StopTimer()
    self:OnCloseStageDetail()
    if self.GridExpeditionChapter then
        self.GridExpeditionChapter:OnDisable()
    end
end

function XUiExpeditionMain:OnDestroy()
    self:StopTimer()
end

function XUiExpeditionMain:OnGetEvents()
    return { 
        XEventId.EVENT_EXPEDITION_RECRUITTIME_REFRESH, 
        XEventId.EVENT_ACTIVITY_ON_RESET, 
        XEventId.EVENT_EXPEDITION_RANKING_REFRESH,
        XEventId.EVENT_FINISH_TASK
    }
end

function XUiExpeditionMain:OnNotify(evt, ...)
    local args = { ... }
    if evt == XEventId.EVENT_EXPEDITION_RECRUITTIME_REFRESH then
        self:RefreshRecruitNumber()
    elseif evt == XEventId.EVENT_ACTIVITY_ON_RESET then
        if args[1] ~= XDataCenter.FubenManager.StageType.Expedition then return end
        self:OnActivityReset()
    elseif evt == XEventId.EVENT_EXPEDITION_RANKING_REFRESH then
        self:RefreshRanking()
    elseif evt == XEventId.EVENT_FINISH_TASK then
        self:RefreshTaskRedPoint()
    end
end

function XUiExpeditionMain:OnActivityReset()
    self:StopTimer()
    XLuaUiManager.RunMain()
    XUiManager.TipMsg(CS.XTextManager.GetText("ExpeditionOnClose"))
end

function XUiExpeditionMain:InitChapter()
    local eActivity = XDataCenter.ExpeditionManager.GetEActivity()
    local prefabName = eActivity:GetChapterPrefab()
    local gameObject = self.PanelStageRoot:LoadPrefab(prefabName)
    if gameObject == nil or not gameObject:Exist() then
        return
    end
    self.GridExpeditionChapter = XUiGridExpeditionChapter.New(gameObject, self)
end

function XUiExpeditionMain:AddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnRecruit, self.OnBtnRecruitClick)
    self:RegisterClickEvent(self.BtnTask, self.OnBtnTaskClick)
    self:BindHelpBtn(self.BtnHelp, "ExpeditionMainHelp")
    if self.BtnRanking then
        self.BtnRanking.CallBack = function() self:OnBtnRankingClick() end
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

function XUiExpeditionMain:OnBtnRankingClick()
    XLuaUiManager.Open("UiExpeditionRank")
end

function XUiExpeditionMain:OnBtnTaskClick()
    XLuaUiManager.Open("UiExpeditionTask")
end

function XUiExpeditionMain:OnRefresh()
    self:RefreshRecruitNumber()
    self:SetResetTimer()
    self:RefreshRanking()
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
    local endTimeSecond = XDataCenter.ExpeditionManager.GetEndTime()
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
--刷新排位
--=============
function XUiExpeditionMain:RefreshRanking()
    if self.BtnRanking then self.BtnRanking:SetName(XDataCenter.ExpeditionManager.GetSelfRankStr()) end
end

function XUiExpeditionMain:UpdateCurChapter()
    local data = {
        HideStageCb = handler(self, self.HideStageDetail),
        ShowStageCb = handler(self, self.ShowStageDetail),
    }
    self.GridExpeditionChapter:Refresh(data)
    self.GridExpeditionChapter:Show()
end

function XUiExpeditionMain:ShowStageDetail(stageId)
    self.StageId = stageId
    local eStage = XDataCenter.ExpeditionManager.GetEStageByStageId(stageId)
    XLuaUiManager.Open("UiExpeditionStageDetail", eStage, self, handler(self, self.OnCloseStageDetail))
end

function XUiExpeditionMain:HideStageDetail()
    if not self.Stage then
        return
    end
end

function XUiExpeditionMain:GoToLastPassStage()
    if self.GridExpeditionChapter then
        self.GridExpeditionChapter:GoToNearestStage()
    end
end

function XUiExpeditionMain:OnCloseStageDetail()
    if self.GridExpeditionChapter then
        self.GridExpeditionChapter:CancelSelect()
    end
end

function XUiExpeditionMain:RefreshTaskRedPoint()
    local isShowRed = XDataCenter.ExpeditionManager.CheckExpeditionTaskRedPoint()
    self.BtnTask:ShowReddot(isShowRed)
end