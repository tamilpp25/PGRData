local XUiPrequel = XLuaUiManager.Register(XLuaUi, "UiPrequel")

local MODE_REGIONAL = 1
local MODE_CHALLANGE = 2

function XUiPrequel:OnAwake()
    self:InitAutoScript()
    self.Regional = XUiPanelRegional.New(self.PanelRegional, self)
    self.ChallengeMode = XUiPanelChallengeMode.New(self.PanelChallengeMode, self)
    self.CheckReward = XUiPanelCheckReward.New(self.PanelCheckReward, self)
    self.UnlockChallenge = XUiPanelUnlockChallenge.New(self.PanelUnlockChallenge, self)
    self.FightDailog = XUiPanelEnterFightDialog.New(self.PanelEnterFightDialog, self)

    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.OnRefreshTimeChanged = function() self:UpdateRefreshTime() end
    self.OnUnlockChallengeStageChanged = function() self:UpdateChallengeStage() end
    self.OnPrequelDetailClosed = function() self:OnDetailClosed() end

    XEventManager.AddEventListener(XEventId.EVENT_NOTICE_CHALLENGESTAGES_CHANGE, self.OnRefreshTimeChanged)
    XEventManager.AddEventListener(XEventId.EVENT_NOTICE_REFRESHTIME_CHANGE, self.OnUnlockChallengeStageChanged)
    XEventManager.AddEventListener(XEventId.EVENT_NOTICE_PREQUELDETAIL_CLOSE, self.OnPrequelDetailClosed)


    self.IsRegionalAnimBegin = false
    self.IsChallengeAnimBegin = false
end

function XUiPrequel:IsRegionalAnimPlaying()
    return self.IsRegionalAnimBegin or false
end

function XUiPrequel:IsChallengeAnimPlaying()
    return self.IsChallengeAnimBegin or false
end

function XUiPrequel:SetChallengeAnimBegin(isBegin)
    self.IsChallengeAnimBegin = isBegin
end

function XUiPrequel:OnStart(coverData, currentMode, defaultChapter)
    self.CurrentCover = coverData
    self.DefaultChapter = defaultChapter
    self:SetPanelAssetActive(true)
    if currentMode and currentMode ~= 0 then
        self.CurrentMode = currentMode
    end
end

function XUiPrequel:GetDefaultChapter()
    local chapter = self.DefaultChapter
    self.DefaultChapter = nil
    return chapter
end

function XUiPrequel:OnEnable()
    self:OnRefresh()
end


function XUiPrequel:OnDisable()
    -- 关闭界面也检查计时器是否还没清除
    self.ChallengeMode:RemoveChallengeTimer()
end


function XUiPrequel:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_NOTICE_CHALLENGESTAGES_CHANGE, self.OnRefreshTimeChanged)
    XEventManager.RemoveEventListener(XEventId.EVENT_NOTICE_REFRESHTIME_CHANGE, self.OnUnlockChallengeStageChanged)
    XEventManager.RemoveEventListener(XEventId.EVENT_NOTICE_PREQUELDETAIL_CLOSE, self.OnPrequelDetailClosed)
end


function XUiPrequel:OnGetEvents()
    return nil
end


function XUiPrequel:OnNotify()
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiPrequel:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiPrequel:AutoInitUi()
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

function XUiPrequel:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
end
-- auto
function XUiPrequel:OnBtnBackClick()
    self.Regional:UpdateCover()
    self:Close()
end

function XUiPrequel:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiPrequel:OnRefresh()
    --获取上次保存的数据
    local lastSelectPanelType = 1
    local keyX = string.format("%s%d%d", "PrequelLastSwitchPanelType", XPlayer.Id, self.CurrentCover.CoverId)
    if CS.UnityEngine.PlayerPrefs.HasKey(keyX) then
        lastSelectPanelType = CS.UnityEngine.PlayerPrefs.GetInt(keyX)
    end

    self.CurrentMode = self.CurrentMode or lastSelectPanelType
    if self.CurrentMode == MODE_REGIONAL then
        self:Switch2Regional(self.CurrentCover)
    elseif self.CurrentMode == MODE_CHALLANGE then
        self:Switch2Challenge(self.CurrentCover)
    end
end

function XUiPrequel:OnClosePrequelDetail()
    self:FindChildUiObj("UiPrequelLineDetail"):OnPrequelDetailClose()
    self:SetPanelAssetActive(true)
end

function XUiPrequel:SetPanelAssetActive(isActive)
    self.AssetPanel.GameObject:SetActiveEx(isActive)
end

-- [支线剧情]
function XUiPrequel:Switch2Regional(coverData)

    self:PlayAnimation("AniPrequelRegionalBegin", function()
            self.IsRegionalAnimBegin = false
        end, function()
            self.IsRegionalAnimBegin = true
            self.Regional:SetPanelActive(true)
            self.PanelChallengeMode.gameObject:SetActive(false)
            self.Regional:OnRefresh(coverData)
            self.CurrentMode = MODE_REGIONAL
            local coverDatas = XPrequelConfigs.GetPrequelCoverInfoById(coverData.CoverId)
            self:ResetBackground(coverDatas.CoverBg)
        end)
end

function XUiPrequel:RefreshRegional()
    if self.CurrentMode and self.CurrentMode == MODE_REGIONAL then
        self.Regional:UpdateCurrentTab()
    end
end

function XUiPrequel:RefreshRegionalReward()
    self.Regional:UpdateRewardView()
end

-- [挑战]
function XUiPrequel:Switch2Challenge(coverData)
    if not coverData.CoverVal.ChallengeStage or #coverData.CoverVal.ChallengeStage == 0 then return end
    self.Regional:SetPanelActive(false)
    self.PanelChallengeMode.gameObject:SetActive(true)
    self.ChallengeMode:OnRefresh(coverData)
    self.CurrentMode = MODE_CHALLANGE
    local coverDatas = XPrequelConfigs.GetPrequelCoverInfoById(coverData.CoverId)
    self:ResetBgFx(coverData.CoverVal.ChallengeFx)
    self:ResetBackground(coverDatas.ChallengeBg)
end

-- [刷新挑战界面]
function XUiPrequel:RefreshChallenge()
    if self.CurrentCover then
        self.ChallengeMode:OnRefresh(self.CurrentCover)
    end
end

-- [解锁挑战关卡]
function XUiPrequel:Switch2UnlockChallengeStage(challengeStage)
    self.UnlockChallenge.GameObject:SetActive(true)
    self.UnlockChallenge:RefreshWithAnim(challengeStage)
end

-- [奖励列表:查看某个支线的奖励]
function XUiPrequel:Switch2RewardList(chapterId)
    self.CheckReward.GameObject:SetActive(true)
    self.CheckReward:UpdateRewardList(chapterId)
    self:PlayAnimation("AniPrequelCheckRewardBegin")
end

-- [刷新倒计时]
function XUiPrequel:UpdateRefreshTime()
    if self.CurrentMode and self.CurrentMode == MODE_CHALLANGE then
        self.ChallengeMode:UpdateTimer()
    end
end

-- [详情界面关闭，后续处理]
function XUiPrequel:OnDetailClosed()
    self.ChallengeMode:OnDetailClosed()
end

-- [刷新挑战关卡]
function XUiPrequel:UpdateChallengeStage()
    if self.CurrentMode and self.CurrentMode == MODE_CHALLANGE then
        self.ChallengeMode:UpdateChallengeStages()
    end
end

-- [进入剧情确认框]
function XUiPrequel:OnEnterStory(stageId, callback)
    self.FightDailog.GameObject:SetActive(true)
    self:PlayAnimation("AniBeginPanelEnterFightDialog", nil, function()
            self.FightDailog:OnShowStoryDialog(stageId, callback)
        end)
end

-- [进入战斗确认框]
function XUiPrequel:OnEnterFight(stageId, callback)
    self.FightDailog.GameObject:SetActive(true)
    self:PlayAnimation("AniBeginPanelEnterFightDialog", nil, function()
            self.FightDailog:OnShowFightDialog(stageId, callback)
        end)
end

-- [切换背景]
function XUiPrequel:ResetBackground(rawBg)
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
function XUiPrequel:ResetBgFx(fxPath)
    local disable = string.IsNilOrEmpty(fxPath)
    self.PanelEffect.gameObject:SetActiveEx(not disable)
    if disable then return end
    if self.fxName and self.fxName == fxPath then return end
    self.fxName = fxPath
    self.PanelEffect.gameObject:LoadUiEffect(fxPath)
end

function XUiPrequel:OnReleaseInst()
    local data = {
            CurrentMode = self.CurrentMode,
            CurIndex = self.Regional.CurrentSelectIdx,
            CurChapterId = self.Regional.CurrentSelectedChapterId
        }
    return data
end

function XUiPrequel:OnResume(data)
    self.CurrentMode = data.CurrentMode
    self.ResumeChapterId = data.CurChapterId
    self.ResumeTabIndex = data.CurIndex
end

function XUiPrequel:GetResumeChapterId()
    local id = self.ResumeChapterId
    self.ResumeChapterId = nil
    return id
end

function XUiPrequel:GetResumeTabIndex()
    local index = self.ResumeTabIndex
    self.ResumeTabIndex = nil
    return index
end