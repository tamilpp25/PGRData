local XUiFubenExperimentSkinTrialDetail = XLuaUiManager.Register(XLuaUi, "UiFubenExperimentSkinTrialDetail")

local XUiFubenExperimentGridStar = require("XUi/XUiFubenExperiment/XUiFubenExperimentGridStar")

function XUiFubenExperimentSkinTrialDetail:OnAwake()
    self:AddListener()
end

function XUiFubenExperimentSkinTrialDetail:OnStart(trialLevelInfo, curType)
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset,
    XDataCenter.ItemManager.ItemId.FreeGem,
    XDataCenter.ItemManager.ItemId.ActionPoint,
    XDataCenter.ItemManager.ItemId.Coin)
    self.TrialLevelInfo = trialLevelInfo
    self.RewardPanelList = {}
    XDataCenter.FubenExperimentManager.SetCurExperimentLevelId(self.TrialLevelInfo.Id)

    if self.TrialLevelInfo.Type ~= XDataCenter.FubenExperimentManager.TrialLevelType.Switch then
        self.BtnSingle.gameObject:SetActive(false)
        self.BtnMult.gameObject:SetActive(false)
        if curType == XDataCenter.FubenExperimentManager.TrialLevelType.Mult then
            self.MultStageCfg = XDataCenter.FubenManager.GetStageCfg(self.TrialLevelInfo.MultStageId)
        end
    else
        self.MultStageCfg = XDataCenter.FubenManager.GetStageCfg(self.TrialLevelInfo.MultStageId)
    end
    self.BtnHelp.gameObject:SetActiveEx(self.TrialLevelInfo.HelpCourseId ~= 0)

    if self.TrialLevelInfo.HeadIcon then
        self.RImgNandu:SetRawImage(self.TrialLevelInfo.HeadIcon)
    end

    XEventManager.AddEventListener(XEventId.EVENT_ROOM_CANCEL_MATCH, self.OnCancelMatch, self)
    self.CurType = curType
    self:UpdateInfo()
    self:UpdateMode()
end

function XUiFubenExperimentSkinTrialDetail:OnEnable()
    self:UpdateFirstReward()
    self.BtnQuickMatch:SetDisable(false)
end

function XUiFubenExperimentSkinTrialDetail:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_CANCEL_MATCH, self.OnCancelMatch, self)
end

function XUiFubenExperimentSkinTrialDetail:AddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnSingle, self.OnBtnSingleClick)
    self:RegisterClickEvent(self.BtnSingleEnter, self.OnBtnSingleEnterClick)
    self:RegisterClickEvent(self.BtnMult, self.OnBtnMultClick)
    self:RegisterClickEvent(self.BtnMultCreateRoom, self.OnBtnMultCreateRoomClick)
    self:RegisterClickEvent(self.BtnQuickMatch, self.OnBtnQuickMatchClick)
    self.BtnHelp.CallBack = function()
        self:OnBtnHelpClick()
    end
    self:BindHelpBtnOnly(self.BtnHelp)
end

function XUiFubenExperimentSkinTrialDetail:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiFubenExperimentSkinTrialDetail:OnBtnBackClick()
    local title = CS.XTextManager.GetText("TipTitle")
    local cancelMatchMsg = CS.XTextManager.GetText("OnlineInstanceCancelMatch")
    if XDataCenter.RoomManager.Matching then
        XUiManager.DialogTip(title, cancelMatchMsg, XUiManager.DialogType.Normal, nil, function()
            XDataCenter.RoomManager.CancelMatch(function()
                self:Close()
            end)
        end)
    else
        self:Close()
    end
end

function XUiFubenExperimentSkinTrialDetail:OnBtnSingleClick()
    self:OnSwitchButton()
end

function XUiFubenExperimentSkinTrialDetail:OnBtnSingleEnterClick()
    if self.TrialLevelInfo.TimeId and self.TrialLevelInfo.TimeId ~= 0 then
        if XFunctionManager.CheckInTimeByTimeId(self.TrialLevelInfo.TimeId) then
            XLuaUiManager.Open("UiBattleRoleRoom", self.TrialLevelInfo.SingStageId)
        else
            XUiManager.TipText("ActivityBranchNotOpen")
        end
    else
        XLuaUiManager.Open("UiBattleRoleRoom", self.TrialLevelInfo.SingStageId)
    end
end

function XUiFubenExperimentSkinTrialDetail:OnBtnMultClick()
    self:OnSwitchButton()
end

function XUiFubenExperimentSkinTrialDetail:OnBtnMultCreateRoomClick()
    XDataCenter.FubenManager.RequestCreateRoom(self.MultStageCfg)
end

function XUiFubenExperimentSkinTrialDetail:OnBtnQuickMatchClick()
    if XDataCenter.RoomManager.Matching then
        return
    end

    XDataCenter.FubenManager.RequestMatchRoom(self.MultStageCfg, function()--匹配房间
        self:RefreshMatching()
        self.BtnQuickMatch:SetDisable(true)
    end)
end

--打开图文面板
function XUiFubenExperimentSkinTrialDetail:OnBtnHelpClick()
    local template = XHelpCourseConfig.GetHelpCourseTemplateById(self.TrialLevelInfo.HelpCourseId)
    XUiManager.ShowHelpTip(template.Function)
end

function XUiFubenExperimentSkinTrialDetail:OnCancelMatch()
    self.BtnQuickMatch:SetDisable(false)
end

function XUiFubenExperimentSkinTrialDetail:RefreshMatching()
    if XDataCenter.RoomManager.Matching then
        XLuaUiManager.Open("UiOnLineMatching", self.MultStageCfg)
    end
end

function XUiFubenExperimentSkinTrialDetail:OnSwitchButton()
    if self.TrialLevelInfo.Type == XDataCenter.FubenExperimentManager.TrialLevelType.Switch then
        if self.CurType == XDataCenter.FubenExperimentManager.TrialLevelType.Signle then
            self.CurType = XDataCenter.FubenExperimentManager.TrialLevelType.Mult
        else
            self.CurType = XDataCenter.FubenExperimentManager.TrialLevelType.Signle
        end
    end
    self:UpdateMode()
    self:UpdateDes()
end

function XUiFubenExperimentSkinTrialDetail:UpdateMode()
    if self.CurType == XDataCenter.FubenExperimentManager.TrialLevelType.Signle or self.CurType == XDataCenter.FubenExperimentManager.TrialLevelType.SkinTrial then
        self.PanelSingle.gameObject:SetActive(true)
        self.PanelTeam.gameObject:SetActive(false)
    else
        self.PanelSingle.gameObject:SetActive(false)
        self.PanelTeam.gameObject:SetActive(true)
    end
end

function XUiFubenExperimentSkinTrialDetail:UpdateInfo()
    self.TxtTitle.text = self.TrialLevelInfo.Name
    self.TxtRecommendLevel.text = self.TrialLevelInfo.RecommendLevel
    if self.TrialLevelInfo.SpinePath and self.PanelSpine then
        self.PanelSpine.gameObject:LoadSpinePrefab(self.TrialLevelInfo.SpinePath)
    else
        self.ImgFullScreen.gameObject:SetActiveEx(true)
        if self.TrialLevelInfo.DetailBackGroundIco then
            self.ImgFullScreen:SetRawImage(self.TrialLevelInfo.DetailBackGroundIco)
        end
    end
    if self.TrialLevelInfo.StarReward and self.TrialLevelInfo.StarReward > 0 then -- 带有目标奖励的试玩关
        self.PanelNor.gameObject:SetActiveEx(false)
    else
        self.PanelNor.gameObject:SetActiveEx(true)
    end
    self:UpdateDes()
end

function XUiFubenExperimentSkinTrialDetail:UpdateDes()
    if self.CurType == XDataCenter.FubenExperimentManager.TrialLevelType.Signle or self.CurType == XDataCenter.FubenExperimentManager.TrialLevelType.SkinTrial then
        self.TxtDes.text = string.gsub(self.TrialLevelInfo.SingleDescription, "\\n", "\n")
    else
        self.TxtDes.text = string.gsub(self.TrialLevelInfo.MultDescription, "\\n", "\n")
    end
end

function XUiFubenExperimentSkinTrialDetail:UpdateFirstReward()
    local stage = XDataCenter.FubenManager.GetStageCfg(self.TrialLevelInfo.SingStageId)
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.TrialLevelInfo.SingStageId)
    local rewardId = 0
    local IsFirst = false
    for i = 1, #self.RewardPanelList do
        self.RewardPanelList[i]:Refresh()
    end
    rewardId = stage.FirstRewardShow
    if not stageInfo.Passed then
        IsFirst = true
    end

    if not rewardId or rewardId == 0 then
        return
    end

    local rewardsList = XRewardManager.GetRewardList(rewardId)
    if not rewardsList then return end

    for i = 1, #rewardsList do
        local panel = self.RewardPanelList[i]
        if not panel then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridCommon)
            ui.transform:SetParent(self.PanelDropContent, false)
            panel = XUiGridCommon.New(self, ui)
            table.insert(self.RewardPanelList, panel)
        end
        local temp = {
            ShowReceived = not IsFirst
        }
        panel:Refresh(rewardsList[i], temp)
    end
end