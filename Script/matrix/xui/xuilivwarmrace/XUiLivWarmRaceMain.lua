local CSXTextManagerGetText = CS.XTextManager.GetText
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

local StageNotOpenEffectPath = CS.XGame.ClientConfig:GetString("LivWarmRaceLastStageNotOpenModelEffectPath")
local HelpKey = "LivWarmRace"

--二周年预热-赛跑小游戏 主界面
local XUiLivWarmRaceMain = XLuaUiManager.Register(XLuaUi, "UiLivWarmRaceMain")

function XUiLivWarmRaceMain:OnAwake()
    self:InitSceneRoot()
    self:AutoAddListener()
    self:InitAssetActivityPanel()
    self:InitRedPoint()

    self.TxtName.text = XLivWarmRaceConfigs.GetActivityName()
end

function XUiLivWarmRaceMain:OnStart()
    if not XDataCenter.LivWarmRaceManager.IsCookieFirstOpen() then
        XUiManager.ShowHelpTip(HelpKey)
        XDataCenter.LivWarmRaceManager.SetCookieFirstOpen()
    end
end

function XUiLivWarmRaceMain:OnEnable()
    self:Refresh()
    self:StartTimer()
    self:AddEventListener()
end

function XUiLivWarmRaceMain:OnDisable()
    self:RemoveTimer()
    self:RemoveEventListener()
end

function XUiLivWarmRaceMain:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_LIV_WARM_RACE_REWARD, self.UpdateProgress, self)
end

function XUiLivWarmRaceMain:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_LIV_WARM_RACE_REWARD, self.UpdateProgress, self)
end

function XUiLivWarmRaceMain:InitRedPoint()
    XRedPointManager.AddRedPointEvent(self.ImgRedPoint, nil, self, { XRedPointConditions.Types.CONDITION_LIV_WARM_RACE_REWARD })
end

function XUiLivWarmRaceMain:InitAssetActivityPanel()
    local itemIds = { XLivWarmRaceConfigs.GetActivityConsumeId() }
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool, self)
    XDataCenter.ItemManager.AddCountUpdateListener(itemIds, function()
        self.AssetActivityPanel:Refresh(itemIds)
    end, self.AssetActivityPanel)
    self.AssetActivityPanel:Refresh(itemIds)
end

function XUiLivWarmRaceMain:InitSceneRoot()
    local panelModel = XUiHelper.TryGetComponent(self.UiModel.UiNearRoot, "PanelModel")
    self.UiPanelRoleModel = XUiPanelRoleModel.New(panelModel, self.Name)

    local root = self.UiModelGo.transform
    self.Scene3DRoot = {}
    self.Scene3DRoot.Transform = XUiHelper.TryGetComponent(root, "Ui3DUiRoot").transform
    XTool.InitUiObject(self.Scene3DRoot)
end

function XUiLivWarmRaceMain:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    self:BindHelpBtn(self.BtnHelp, HelpKey)
    self:RegisterClickEvent(self.BtnTreasure, self.OnBtnTreasureClick)
    self:RegisterClickEvent(self.Scene3DRoot.BtnEnterFinalStage, self.OnBtnEnterFinalStageClick)

    local groupIds = XLivWarmRaceConfigs.GetActivityGroupIds()
    for i, groupId in ipairs(groupIds) do
        if self.Scene3DRoot["BtnEnterStage" .. i] then
            self:RegisterClickEvent(self.Scene3DRoot["BtnEnterStage" .. i], function()
                self:OnBtnEnterStageClick(groupId)
            end)
        end
    end
end

function XUiLivWarmRaceMain:OnBtnTreasureClick()
    XLuaUiManager.Open("UiLivWarmRaceReward")
end

function XUiLivWarmRaceMain:OnBtnEnterFinalStageClick()
    local stageId = XLivWarmRaceConfigs.GetActivityFinalStageId()
    local isOpen, lockPreStageId = XDataCenter.LivWarmRaceManager.IsStageOpen(stageId)
    if not isOpen then
        local stageName = XFubenConfigs.GetStageName(lockPreStageId)
        local msg = CS.XTextManager.GetText("LivWarmRaceStageUnlockCondition", stageName)
        XUiManager.TipMsg(msg)
        return
    end

    XLuaUiManager.Open("UiNewRoomSingle", stageId)
end

function XUiLivWarmRaceMain:OnBtnEnterStageClick(groupId)
    local isOpen, lockPreStageId = XDataCenter.LivWarmRaceManager.IsStageGroupOpen(groupId)
    if not isOpen then
        local stageName = XFubenConfigs.GetStageName(lockPreStageId)
        local msg = CS.XTextManager.GetText("LivWarmRaceStageUnlockCondition", stageName)
        XUiManager.TipMsg(msg)
        return
    end
    XLuaUiManager.Open("UiLivWarmRaceFightMain", groupId)
end

function XUiLivWarmRaceMain:Refresh()
    self:UpdateRoleModel()
    self:UpdateStage()
    self:UpdateProgress()
end

--更新奖励进度
function XUiLivWarmRaceMain:UpdateProgress()
    local ownStarCount = XDataCenter.LivWarmRaceManager.GetOwnTotalStarCount()
    local totalStarCount = XLivWarmRaceConfigs.GetChallengeTargetTotalStarCount()
    local progress = XTool.IsNumberValid(totalStarCount) and math.min(1, ownStarCount / totalStarCount) or 0
    self.TxtProgress.text = math.floor(progress * 100) .. "%"
    self.ImgProgress.fillAmount = progress

    local isRewardAll = XDataCenter.LivWarmRaceManager.IsRewardAllHadToken()
    self.ImgComplete.gameObject:SetActiveEx(isRewardAll)
end

--更新模型
function XUiLivWarmRaceMain:UpdateRoleModel()
    local roleName = XLivWarmRaceConfigs.GetActivityFinalStageModel()
    self.UiPanelRoleModel:UpdateRoleModel(roleName, nil, XModelManager.MODEL_UINAME.XUiCharacter, function()
        self:UpdateRoleModelEfeect()
    end, nil, true, true)
end

--更新模型特效
function XUiLivWarmRaceMain:UpdateRoleModelEfeect()
    local finalStageId = XLivWarmRaceConfigs.GetActivityFinalStageId()
    local isUnlockFinals = XDataCenter.LivWarmRaceManager.IsStageOpen(finalStageId)
    if isUnlockFinals then
        self.UiPanelRoleModel:HideEffectByParentName()
    else
        self.UiPanelRoleModel:LoadEffect(StageNotOpenEffectPath, "ShadowEffect", true, true)
    end
end

--更新关卡信息
function XUiLivWarmRaceMain:UpdateStage()
    --是否解锁决赛入口
    local finalStageId = XLivWarmRaceConfigs.GetActivityFinalStageId()
    local isUnlockFinals = XDataCenter.LivWarmRaceManager.IsStageOpen(finalStageId)
    self.Scene3DRoot.ImgLockPanel.gameObject:SetActiveEx(not isUnlockFinals)
    self:UpdateRoleModelEfeect()

    --关卡信息
    local isStageClear
    local isStageUnLock
    local clearStarCount, totalStarCount
    local groupIds = XLivWarmRaceConfigs.GetActivityGroupIds()
    for i, groupId in ipairs(groupIds) do
        isStageClear = XDataCenter.LivWarmRaceManager.IsStageGroupClear(groupId)
        isStageUnLock = XDataCenter.LivWarmRaceManager.IsStageGroupOpen(groupId)

        self.Scene3DRoot["TxtLock" .. i].gameObject:SetActiveEx(not isStageUnLock)
        self.Scene3DRoot["PanelRole" .. i].gameObject:SetActiveEx(isStageUnLock and isStageClear)
        self.Scene3DRoot["PanelIconWenhao" .. i].gameObject:SetActiveEx(not isStageUnLock or not isStageClear)
        self.Scene3DRoot["TxtProgress" .. i].gameObject:SetActiveEx(isStageUnLock)

        if isStageUnLock then
            clearStarCount, totalStarCount = XDataCenter.LivWarmRaceManager.GetStarCount(groupId)
            self.Scene3DRoot["TxtProgress" .. i].text = CSXTextManagerGetText("LivWarmRaceStageProgress", clearStarCount, totalStarCount)
        end

        if isStageClear then
            local roleHead = XLivWarmRaceConfigs.GetGroupRoleHead(groupId)
            self.Scene3DRoot["IconRole" .. i]:SetRawImage(roleHead)
        end
    end

end

function XUiLivWarmRaceMain:StartTimer()
    self:RemoveTimer()
    self:RefreshActivityTime()
    self.Timer = XScheduleManager.ScheduleForever(function()
        if not XDataCenter.LivWarmRaceManager.CheckActivityIsOpen() then
            return
        end
        self:RefreshActivityTime()
    end, XScheduleManager.SECOND)
end

function XUiLivWarmRaceMain:RefreshActivityTime()
    local timeId = XLivWarmRaceConfigs.GetActivityTimeId()
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    local now = XTime.GetServerNowTimestamp()
    local offset = endTime - now
    self.TxtTime.text = XUiHelper.GetTime(offset, XUiHelper.TimeFormatType.ACTIVITY)
end

function XUiLivWarmRaceMain:RemoveTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end