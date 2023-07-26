-- 拆分后的新间章界面
local XUiPrequelMain = XLuaUiManager.Register(XLuaUi, "UiPrequelMain")
local XUiPanelRegional = require("XUi/XUiPrequelMain/Grid/XUiMainPanelRegional")

function XUiPrequelMain:OnAwake()
    self:InitAutoScript()
    self.Regional = XUiPanelRegional.New(self.PanelRegional, self)
    self.CheckReward = XUiPanelCheckReward.New(self.PanelCheckReward, self)
    self.FightDailog = XUiPanelEnterFightDialog.New(self.PanelEnterFightDialog, self)

    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.OnRefreshTimeChanged = function() self:UpdateRefreshTime() end

    XEventManager.AddEventListener(XEventId.EVENT_NOTICE_CHALLENGESTAGES_CHANGE, self.OnRefreshTimeChanged)

    self.IsRegionalAnimBegin = false
    self.IsChallengeAnimBegin = false
end

function XUiPrequelMain:IsRegionalAnimPlaying()
    return self.IsRegionalAnimBegin or false
end

function XUiPrequelMain:IsChallengeAnimPlaying()
    return self.IsChallengeAnimBegin or false
end

function XUiPrequelMain:SetChallengeAnimBegin(isBegin)
    self.IsChallengeAnimBegin = isBegin
end

function XUiPrequelMain:OnStart(chapterCfg)
    self.CurrChapterCfg = chapterCfg
    self:SetPanelAssetActive(true)
end

function XUiPrequelMain:OnEnable()
    self:OnRefresh(self.CurrChapterCfg)
end

function XUiPrequelMain:OnDisable()
end

function XUiPrequelMain:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_NOTICE_CHALLENGESTAGES_CHANGE, self.OnRefreshTimeChanged)
end

function XUiPrequelMain:OnGetEvents()
    return nil
end

function XUiPrequelMain:OnNotify()
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiPrequelMain:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiPrequelMain:AutoInitUi()
    self.RImgBg = self.Transform:Find("FullScreenBackground/RImgBg"):GetComponent("RawImage")
    self.PanelRegional = self.Transform:Find("SafeAreaContentPane/PanelRegional")
    self.PanelChallengeMode = self.Transform:Find("SafeAreaContentPane/PanelChallengeMode")
    self.BtnBack = self.Transform:Find("SafeAreaContentPane/Top/BtnBack"):GetComponent("Button")
    self.BtnMainUi = self.Transform:Find("SafeAreaContentPane/Top/BtnMainUi"):GetComponent("Button")
    self.PanelAsset = self.Transform:Find("SafeAreaContentPane/PanelAsset")
    self.PanelCheckReward = self.Transform:Find("SafeAreaContentPane/PanelCheckReward")
    self.PanelUnlockChallenge = self.Transform:Find("SafeAreaContentPane/PanelUnlockChallenge")
    self.PanelEnterFightDialog = self.Transform:Find("SafeAreaContentPane/PanelEnterFightDialog")
    self.PanelEffect = self.Transform:Find("FullScreenBackground/PanelEffect")
    self.PanelFullScreen = self.Transform:Find("FullScreenBackground/PanelStage/PanelRegional/PanelRegional/PanelPrequelStages")
end

function XUiPrequelMain:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
end
-- auto
function XUiPrequelMain:OnBtnBackClick()
    self.Regional:UpdateCover()
    self:Close()
end

function XUiPrequelMain:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiPrequelMain:OnClosePrequelDetail()
    self:FindChildUiObj("UiPrequelLineDetail"):OnPrequelDetailClose()
    self:SetPanelAssetActive(true)
end

function XUiPrequelMain:SetPanelAssetActive(isActive)
    self.AssetPanel.GameObject:SetActiveEx(isActive)
end

-- [支线剧情]
function XUiPrequelMain:OnRefresh(chapterCfg)
    self:PlayAnimation("AniPrequelRegionalBegin", function()
            self.IsRegionalAnimBegin = false
        end, function()
            self.PanelChallengeMode.gameObject:SetActive(false)
            self.IsRegionalAnimBegin = true
            self.Regional:SetPanelActive(true)
            self.Regional:OnRefresh(chapterCfg)
            self:ResetBgFx(chapterCfg.UiFxPath)
            -- self:ResetBackground(chapterCfg.UiBgPath)
        end)
end

function XUiPrequelMain:RefreshRegionalReward()
    self.Regional:UpdateRewardView()
end

-- [奖励列表:查看某个支线的奖励]
function XUiPrequelMain:Switch2RewardList(chapterId)
    self.CheckReward.GameObject:SetActive(true)
    self.CheckReward:OnEnable()
    self.CheckReward:UpdateRewardList(chapterId)
    self:PlayAnimation("AniPrequelCheckRewardBegin")
end

-- [刷新倒计时]
function XUiPrequelMain:UpdateRefreshTime()
end

-- [切换背景]
function XUiPrequelMain:ResetBackground(rawBg)
    local bgNil = string.IsNilOrEmpty(rawBg)
    if bgNil then
        self.RImgBg:SetRawImage("Assets/Product/Texture/Image/UiFubenMainMapTab/ChapterBg01B.png")
        return
    end
    if self.bgName and self.bgName == rawBg then return end
    self.bgName = rawBg
    self.RImgBg:SetRawImage(rawBg)
end

-- [切换背景特效]
function XUiPrequelMain:ResetBgFx(fxPath)
    local disable = string.IsNilOrEmpty(fxPath)
    self.PanelEffect.gameObject:SetActiveEx(not disable)
    if disable then return end
    if self.fxName and self.fxName == fxPath then return end
    self.fxName = fxPath
    self.PanelEffect.gameObject:LoadUiEffect(fxPath)
end

-- [进入战斗确认框]
function XUiPrequelMain:OnEnterFight(stageId, callback)
    self.FightDailog.GameObject:SetActive(true)
    self:PlayAnimation("AniBeginPanelEnterFightDialog", nil, function()
            self.FightDailog:OnShowFightDialog(stageId, callback)
        end)
end

-- [进入剧情确认框]
function XUiPrequelMain:OnEnterStory(stageId, callback)
    self.FightDailog.GameObject:SetActive(true)
    self:PlayAnimation("AniBeginPanelEnterFightDialog", nil, function()
            self.FightDailog:OnShowStoryDialog(stageId, callback)
        end)
end

function XUiPrequelMain:OnReleaseInst()
    local data = {
            CurrentMode = self.CurrentMode,
            CurIndex = self.Regional.CurrentSelectIdx,
            CurChapterId = self.Regional.CurrentSelectedChapterId
        }
    return data
end

function XUiPrequelMain:OnResume(data)
    self.CurrentMode = data.CurrentMode
    self.ResumeChapterId = data.CurChapterId
    self.ResumeTabIndex = data.CurIndex
end

function XUiPrequelMain:GetResumeChapterId()
    local id = self.ResumeChapterId
    self.ResumeChapterId = nil
    return id
end

function XUiPrequelMain:GetResumeTabIndex()
    local index = self.ResumeTabIndex
    self.ResumeTabIndex = nil
    return index
end