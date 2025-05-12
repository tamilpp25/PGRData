local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiFubenExperimentDetail = XLuaUiManager.Register(XLuaUi, "UiFubenExperimentDetail")

local UiState = {
    Normal = 1,
    SkillExplain = 2,
}

local XUiFubenExperimentGridStar = require("XUi/XUiFubenExperiment/XUiFubenExperimentGridStar")

function XUiFubenExperimentDetail:OnAwake()
    self:AutoSetGameObject()
    self:AddListener()
end

function XUiFubenExperimentDetail:OnStart(trialLevelInfo, curType)
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset,
            XDataCenter.ItemManager.ItemId.FreeGem,
            XDataCenter.ItemManager.ItemId.ActionPoint,
            XDataCenter.ItemManager.ItemId.Coin)
    self.TrialLevelInfo = trialLevelInfo
    XDataCenter.FubenExperimentManager.SetCurExperimentLevelId(self.TrialLevelInfo.Id)
    self.CurType = curType
    --if self.TrialLevelInfo.Type ~= XDataCenter.FubenExperimentManager.TrialLevelType.Switch then
    self.BtnSingle.gameObject:SetActive(false)
    self.BtnMult.gameObject:SetActive(false)
    --if curType == XDataCenter.FubenExperimentManager.TrialLevelType.Mult then
    --    self.MultStageCfg = XDataCenter.FubenManager.GetStageCfg(self.TrialLevelInfo.MultStageId)
    --end
    --else
    --    self.CurType = XDataCenter.FubenExperimentManager.GetRecordMode(self.TrialLevelInfo.MultStageId)
    --    self.MultStageCfg = XDataCenter.FubenManager.GetStageCfg(self.TrialLevelInfo.MultStageId)
    --end
    self.CurUiState = UiState.Normal
    self.BtnHelp.gameObject:SetActiveEx(self.TrialLevelInfo.HelpCourseId ~= 0)
    self.PanelSkillInformation.gameObject:SetActiveEx(false)

    if self.TrialLevelInfo.HeadIcon then
        self.RImgNandu:SetRawImage(self.TrialLevelInfo.HeadIcon)
    end

    --XEventManager.AddEventListener(XEventId.EVENT_ROOM_CANCEL_MATCH, self.OnCancelMatch, self)
    self:UpdateInfo()
    self:UpdateMode()
    self:InitBossSkillInfo()
end

function XUiFubenExperimentDetail:OnEnable()
    self.BtnQuickMatch:SetDisable(false)
    self:UpdatePanelStarReward()
end

--function XUiFubenExperimentDetail:OnDestroy()
--    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_CANCEL_MATCH, self.OnCancelMatch, self)
--end

function XUiFubenExperimentDetail:OnGetEvents()
    return {
        XEventId.EVENT_EXPERIMENT_GET_STAR_REWARD,
    }
end

function XUiFubenExperimentDetail:OnNotify(evt, ...)
    if evt == XEventId.EVENT_EXPERIMENT_GET_STAR_REWARD then
        self:UpdatePanelStarReward()
    end
end

function XUiFubenExperimentDetail:AddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnSingle, self.OnBtnSingleClick)
    self:RegisterClickEvent(self.BtnSingleEnter, self.OnBtnSingleEnterClick)
    --self:RegisterClickEvent(self.BtnMult, self.OnBtnMultClick)
    --self:RegisterClickEvent(self.BtnMultCreateRoom, self.OnBtnMultCreateRoomClick)
    --self:RegisterClickEvent(self.BtnQuickMatch, self.OnBtnQuickMatchClick)
    self.BtnHelp.CallBack = function()
        self:OnBtnHelpClick()
    end
    self:BindHelpBtnOnly(self.BtnHelp)
    self.BtnBossInfo.CallBack = function()
        self:OnBtnBossInfoClick()
    end
    for i = 1, #self.GridStarCommonTable, 1 do
        self.GridStarCommonTable[i].BtnGet.CallBack = function()
            self:OnClickGetBtnStarReward(i)
        end
    end
end

function XUiFubenExperimentDetail:AutoSetGameObject()
    self.GridStageStarTable = {}
    for i = 0, self.PanelTargetList.childCount - 1, 1 do
        table.insert(self.GridStageStarTable, XUiFubenExperimentGridStar.New(self.PanelTargetList:GetChild(i)))
    end

    self.GridStarCommonTable = {}
    for i = 1, 3, 1 do
        local panelGridCommon = self.PanelDrop:Find("PanelGridCommon" .. i)
        table.insert(self.GridStarCommonTable,
                { PanelGridCommon = panelGridCommon,
                  GridCommon = XUiGridCommon.New(self, panelGridCommon:Find("GridCommon")),
                  Effect = panelGridCommon:Find("PanelEffect"),
                  BtnGet = panelGridCommon:Find("BtnGet"):GetComponent("XUiButton") })
    end
end

--初始化技能介绍
function XUiFubenExperimentDetail:InitBossSkillInfo()
    self.PanelTxtDes.gameObject:SetActiveEx(false)

    if self.TrialLevelInfo.SkillExplainId ~= 0 then
        --是否显示技能按钮
        self.BtnBossInfo.gameObject:SetActiveEx(true)

        self.SkillDescDatas = XFubenExperimentConfigs.GetExperimentSkillExplainById(self.TrialLevelInfo.SkillExplainId)
        if self.SkillDescDatas and self.SkillDescDatas.SkillTitle then
            for i = 1, #self.SkillDescDatas.SkillTitle do
                local go = CS.UnityEngine.Object.Instantiate(self.PanelTxtDes, self.PanelContent)
                local tmpObj = {}
                tmpObj.Transform = go.transform
                tmpObj.GameObject = go.gameObject
                XTool.InitUiObject(tmpObj)
                tmpObj.TxtRuleTittle.text = self.SkillDescDatas.SkillTitle[i]
                tmpObj.TxtRule.text = self.SkillDescDatas.SkillDesc[i]
                tmpObj.GameObject:SetActiveEx(true)
            end
        end
    else
        self.BtnBossInfo.gameObject:SetActiveEx(false)
    end
end

function XUiFubenExperimentDetail:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiFubenExperimentDetail:OnBtnBackClick()
    if self.CurUiState == UiState.SkillExplain then
        self.CurUiState = UiState.Normal
        self.BtnBossInfo.gameObject:SetActiveEx(true)
        self:UpdateMode()
        --播放动画
        XLuaUiManager.SetMask(true)
        self:PlayAnimation("PanelSkillInformationDisable", function()
            self:PlayAnimation("AnimEnable", function()
                XLuaUiManager.SetMask(false)
            end)
        end)
        return
    end
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

function XUiFubenExperimentDetail:OnBtnSingleClick()
    self:OnSwitchButton()
end

function XUiFubenExperimentDetail:OnBtnSingleEnterClick()
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

--function XUiFubenExperimentDetail:OnBtnMultClick()
--    self:OnSwitchButton()
--end
--
--function XUiFubenExperimentDetail:OnBtnMultCreateRoomClick()
--    XDataCenter.FubenManager.RequestCreateRoom(self.MultStageCfg)
--end

--function XUiFubenExperimentDetail:OnBtnQuickMatchClick()
--    if XDataCenter.RoomManager.Matching then
--        return
--    end
--
--    XDataCenter.FubenManager.RequestMatchRoom(self.MultStageCfg, function()
--        --匹配房间
--        self:RefreshMatching()
--        self.BtnQuickMatch:SetDisable(true)
--    end)
--end

--打开图文面板
function XUiFubenExperimentDetail:OnBtnHelpClick()
    local template = XHelpCourseConfig.GetHelpCourseTemplateById(self.TrialLevelInfo.HelpCourseId)
    XUiManager.ShowHelpTip(template.Function)
end

function XUiFubenExperimentDetail:OnBtnBossInfoClick()
    self.CurUiState = UiState.SkillExplain

    self.BtnBossInfo.gameObject:SetActiveEx(false)
    self.PanelSingle.gameObject:SetActive(false)
    self.PanelTeam.gameObject:SetActive(false)
    --播放动画
    XLuaUiManager.SetMask(true)
    self:PlayAnimation("PanelInformationDisable", function()
        self.PanelSkillInformation.gameObject:SetActiveEx(true)
        self:PlayAnimation("PanelSkillInformationEnable", function()
            XLuaUiManager.SetMask(false)
        end)
    end)

end

--function XUiFubenExperimentDetail:OnCancelMatch()
--    self.BtnQuickMatch:SetDisable(false)
--end

--function XUiFubenExperimentDetail:RefreshMatching()
--    if XDataCenter.RoomManager.Matching then
--        XLuaUiManager.Open("UiOnLineMatching", self.MultStageCfg)
--    end
--end

--function XUiFubenExperimentDetail:OnSwitchButton()
--    XDataCenter.RoomManager.CancelMatch() -- 切换模式先取消匹配
--    if self.TrialLevelInfo.Type == XDataCenter.FubenExperimentManager.TrialLevelType.Switch then
--        if self.CurType == XDataCenter.FubenExperimentManager.TrialLevelType.Signle then
--            self.CurType = XDataCenter.FubenExperimentManager.TrialLevelType.Mult
--        else
--            self.CurType = XDataCenter.FubenExperimentManager.TrialLevelType.Signle
--        end
--        XDataCenter.FubenExperimentManager.RecordMode(self.TrialLevelInfo.MultStageId, self.CurType)
--    end
--    self:UpdateMode()
--    self:UpdateDes()
--end

function XUiFubenExperimentDetail:UpdateMode()
    --if self.CurType == XDataCenter.FubenExperimentManager.TrialLevelType.Signle or self.CurType == XDataCenter.FubenExperimentManager.TrialLevelType.SkinTrial then
    self.PanelSingle.gameObject:SetActive(true)
    --    self.PanelTeam.gameObject:SetActive(false)
    --else
    --    self.PanelSingle.gameObject:SetActive(false)
    --    self.PanelTeam.gameObject:SetActive(true)
    --end
end

function XUiFubenExperimentDetail:UpdateInfo()
    self.TxtTitle.text = self.TrialLevelInfo.Name
    self.TxtRecommendLevel.text = self.TrialLevelInfo.RecommendLevel
    self.ImgFullScreen:SetRawImage(self.TrialLevelInfo.DetailBackGroundIco)
    if self.TrialLevelInfo.StarReward and self.TrialLevelInfo.StarReward > 0 then
        -- 带有目标奖励的试玩关
        self.PanelJindu.gameObject:SetActiveEx(true)
        self.PanelNor.gameObject:SetActiveEx(false)

        self:UpdatePanelStarReward()
    else
        self.PanelJindu.gameObject:SetActiveEx(false)
        self.PanelNor.gameObject:SetActiveEx(true)
    end
    self:UpdateDes()
end

function XUiFubenExperimentDetail:UpdateDes()
    --if self.CurType == XDataCenter.FubenExperimentManager.TrialLevelType.Signle or self.CurType == XDataCenter.FubenExperimentManager.TrialLevelType.SkinTrial then
    self.TxtDes.text = string.gsub(self.TrialLevelInfo.SingleDescription, "\\n", "\n")
    --else
    --    self.TxtDes.text = string.gsub(self.TrialLevelInfo.MultDescription, "\\n", "\n")
    --end
end

function XUiFubenExperimentDetail:UpdatePanelStarReward()
    if not self.TrialLevelInfo.StarReward or self.TrialLevelInfo.StarReward <= 0 then
        return
    end

    local StarDescList = self.TrialLevelInfo.StarDesc
    for i, gridStageStar in ipairs(self.GridStageStarTable) do
        if StarDescList[i] then
            gridStageStar.GameObject:SetActiveEx(true)
            gridStageStar:SetDesc(StarDescList[i])
            gridStageStar:SetActiveEx(XDataCenter.FubenExperimentManager.CheckTargetComplete(self.TrialLevelInfo.Id, i))
        else
            gridStageStar.GameObject:SetActiveEx(false)
        end
    end

    local curStarNum, maxStarNum = XDataCenter.FubenExperimentManager.GetExperimentStarProgressById(self.TrialLevelInfo.Id)
    self.ImgProgress.fillAmount = curStarNum / maxStarNum
    local trialRewardCfg = XFubenExperimentConfigs.GetTrialStarRewardCfgById(self.TrialLevelInfo.StarReward)
    local rewardIdList = trialRewardCfg.RewardId
    for i, PanelStarCommon in ipairs(self.GridStarCommonTable) do
        if rewardIdList[i] then
            PanelStarCommon.PanelGridCommon.gameObject:SetActiveEx(true)
            local rewardItemId = XRewardManager.GetRewardList(rewardIdList[i])[1]
            PanelStarCommon.GridCommon:Refresh(rewardItemId)
            local isResived = XDataCenter.FubenExperimentManager.CheckExperimentRewardIsTaked(self.TrialLevelInfo.Id, i)
            if isResived then
                -- 已领取
                PanelStarCommon.GridCommon:SetReceived(true)
                PanelStarCommon.Effect.gameObject:SetActiveEx(false)
                PanelStarCommon.BtnGet.gameObject:SetActiveEx(true)
            else
                local isCanResive = XDataCenter.FubenExperimentManager.CheckExperimentRewardIsCanTake(self.TrialLevelInfo.Id, i)
                if isCanResive then
                    PanelStarCommon.GridCommon:SetReceived(false)
                    PanelStarCommon.Effect.gameObject:SetActiveEx(true)
                    PanelStarCommon.BtnGet.gameObject:SetActiveEx(true)
                else
                    PanelStarCommon.GridCommon:SetReceived(false)
                    PanelStarCommon.Effect.gameObject:SetActiveEx(false)
                    PanelStarCommon.BtnGet.gameObject:SetActiveEx(false)
                end
            end
        else
            PanelStarCommon.PanelGridCommon.gameObject:SetActiveEx(false)
        end
    end
end

function XUiFubenExperimentDetail:OnClickGetBtnStarReward(index)
    XDataCenter.FubenExperimentManager.GetStarReward(self.TrialLevelInfo.Id, index)
end