local XGoldenMinerDialogExData = require("XEntity/XGoldenMiner/XGoldenMinerDialogExData")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local XSpecialTrainActionRandom = require("XUi/XUiSpecialTrainBreakthrough/XSpecialTrainActionRandom")

---黄金矿工主界面
---@class XUiGoldenMinerMain : XLuaUi
local XUiGoldenMinerMain = XLuaUiManager.Register(XLuaUi, "UiGoldenMinerMain")

function XUiGoldenMinerMain:OnAwake()
    self._DataDb = XDataCenter.GoldenMinerManager.GetGoldenMinerDataDb()
    ---@type XSpecialTrainActionRandom
    self._ModelAnimatorRandom = XSpecialTrainActionRandom.New()
    
    self:AddBtnClickListener()
    self:InitSceneRoot()
    self:HideSettleDialog()
end

function XUiGoldenMinerMain:OnStart()
    self:InitTimes()
    self:SetCameraType(XGoldenMinerConfigs.CameraType.Main)

    self:CheckAutoOpenContinueGameTip()
    self:CheckAndOpenHelpTip()
end

function XUiGoldenMinerMain:OnEnable()
    XUiGoldenMinerMain.Super.OnEnable(self)
    self.UseCharacterId = XDataCenter.GoldenMinerManager.GetUseCharacterId()
    XDataCenter.GoldenMinerManager.CatchCurCharacterId(self.UseCharacterId)
    self:Refresh()
    self:RefreshRedPoint()
    self:CheckShowSettleDialog()
    self._ModelAnimatorRandom:Play()
end

function XUiGoldenMinerMain:OnDisable()
    self._ModelAnimatorRandom:Stop()
end


--region Activity - AutoClose
function XUiGoldenMinerMain:InitTimes()
    -- 设置自动关闭和倒计时
    self:SetAutoCloseInfo(XDataCenter.GoldenMinerManager.GetActivityEndTime(), function(isClose)
        if isClose then
            XDataCenter.GoldenMinerManager.HandleActivityEndTime()
            return
        end
        self:UpdateTime()
    end, nil, 0)
end
--endregion


--region Ui - Refresh
function XUiGoldenMinerMain:Refresh()
    self:UpdateBtn()
    self:UpdateRoleInfo()
    self:UpdateMaxScore()
    self:UpdateCurGameInfo()

    self:UpdateModel()
end
--endregion


--region Ui - Time
function XUiGoldenMinerMain:UpdateTime()
    local endTime = XDataCenter.GoldenMinerManager.GetActivityEndTime()
    local nowTimeStamp = XTime.GetServerNowTimestamp()
    self.TxtTime.text = XUiHelper.GetTime(endTime - nowTimeStamp, XUiHelper.TimeFormatType.ACTIVITY)
end
--endregion


--region Ui - RoleInfo
function XUiGoldenMinerMain:UpdateRoleInfo()
    local useCharacterId = self:GetUseCharacterId()
    self.TxtRoleName.text = XGoldenMinerConfigs.GetCharacterName(useCharacterId)
    self.TxtSkillName.text = XGoldenMinerConfigs.GetCharacterSkillName(useCharacterId) .. "："
    self.TxtSkillDesc.text = XUiHelper.ConvertLineBreakSymbol(XGoldenMinerConfigs.GetCharacterSkillDesc(useCharacterId))
    if self.TxtEnName then
        self.TxtEnName.text = XGoldenMinerConfigs.GetCharacterEnName(useCharacterId)
    end
    if self.BtnReplace then
        self.BtnReplace.gameObject:SetActiveEx(not XDataCenter.GoldenMinerManager.IsCanKeepBattle())
    end
end
--endregion


--region Ui - MaxScore & CurGameInfo
function XUiGoldenMinerMain:UpdateMaxScore()
    if XDataCenter.GoldenMinerManager.IsCanKeepBattle() then
        self.PanelSz.gameObject:SetActiveEx(false)
        return
    end
    self.PanelSz.gameObject:SetActiveEx(true)
    self.TxtFraction.text = self._DataDb:GetTotalMaxScores()
end

function XUiGoldenMinerMain:UpdateCurGameInfo()
    if not XDataCenter.GoldenMinerManager.IsCanKeepBattle() then
        self.PanelSz2.gameObject:SetActiveEx(false)
        return
    end
    local stageIndex = self._DataDb:GetCurShowStageIndex()
    self.PanelSz2.gameObject:SetActiveEx(true)
    self.TxtCurScore.text = self._DataDb:GetStageScores()
    self.TxtCurStageCount.text = stageIndex
end
--endregion


--region Ui - BtnState
function XUiGoldenMinerMain:UpdateBtn()
    local isBattle = XDataCenter.GoldenMinerManager.IsCanKeepBattle()
    self.BtnGo.gameObject:SetActiveEx(not isBattle)
    self.BtnGo2.gameObject:SetActiveEx(isBattle)
    self.BtnGiveUp.gameObject:SetActiveEx(isBattle)
end

function XUiGoldenMinerMain:_PlayBtnReplaceAnim()
    self:PlayAnimation("BtnReplaceEnable")
end
--endregion


--region Ui - RedPoint
function XUiGoldenMinerMain:RefreshRedPoint()
    self:CheckTaskRedPoint()
    self:CheckRoleRedPoint()
end

function XUiGoldenMinerMain:CheckTaskRedPoint()
    local isCanReward = XDataCenter.GoldenMinerManager.CheckTaskCanReward()
    self.BtnTask:ShowReddot(isCanReward)
end

function XUiGoldenMinerMain:CheckRoleRedPoint()
    local isHaveNewRole = XDataCenter.GoldenMinerManager.CheckHaveNewRole()
    self.BtnReplace:ShowReddot(isHaveNewRole)
end
--endregion


--region Ui - Help Tip
---首次自动打开帮助
function XUiGoldenMinerMain:CheckAndOpenHelpTip()
    local helpKey = XGoldenMinerConfigs.GetHelpKey()
    if XHelpCourseConfig.GetHelpCourseTemplateByFunction(helpKey) and XDataCenter.GoldenMinerManager.CheckFirstOpenHelp() then
        XUiManager.ShowHelpTip(helpKey)
    end
end
--endregion


--region Ui - ContinueGame Tip
---每次登录首次进活动检查是否存在已有对局
function XUiGoldenMinerMain:CheckAutoOpenContinueGameTip()
    if XDataCenter.GoldenMinerManager.GetIsAutoOpenKeepBattleTips() then
        self:OpenContinueGameTip()
    end
    XDataCenter.GoldenMinerManager.SetIsAutoOpenKeepBattleTips(false)
end

---进入游戏前检查是否存在已有对局
function XUiGoldenMinerMain:CheckOpenKeepContinueGameTip()
    if not XDataCenter.GoldenMinerManager.IsCanKeepBattle() then
        return false
    end
    self:OpenContinueGameTip()
    return true
end

--打开继续挑战的提示
function XUiGoldenMinerMain:OpenContinueGameTip()
    local title = XUiHelper.GetText("GoldenMinerQuickTipsTitle")
    local desc = XUiHelper.GetText("GoldenMinerKeepBattleTipsDesc")
    ---@type XGoldenMinerDialogExData
    local data = XGoldenMinerDialogExData.New()
    data.IsCanShowClose = false
    XLuaUiManager.Open("UiGoldenMinerDialog", title, desc, nil, nil, data)
end

function XUiGoldenMinerMain:ContinueGame()
    local dataDb = XDataCenter.GoldenMinerManager.GetGoldenMinerDataDb()
    local curStageId = dataDb:GetCurStageId()
    local currentPlayStageId = dataDb:GetCurrentPlayStage()

    local checkOpenShopFunc = function()
        if not XTool.IsTableEmpty(dataDb:GetMinerShopDbs()) then
            XLuaUiManager.PopThenOpen("UiGoldenMinerShop")
            return true
        end
        return false
    end

    self._DataDb:CoverItemColums()
    local enterBattleFunc = function()
        XLuaUiManager.PopThenOpen("UiGoldenMinerBattle")
    end

    if XTool.IsNumberValid(currentPlayStageId) then
        enterBattleFunc()
        return
    end

    if checkOpenShopFunc() then
        return
    end
    
    XDataCenter.GoldenMinerManager.RequestGoldenMinerEnterStage(curStageId, function()
        if not checkOpenShopFunc() then
            enterBattleFunc()
        end
    end)
end
--endregion


--region Ui - GiveUpGame Tip
---打开放弃挑战的提示
function XUiGoldenMinerMain:OpenGiveUpGameTip()
    local title = XUiHelper.GetText("GoldenMinerGiveUpGameTitle")
    local desc = XUiHelper.GetText("GoldenMinerGiveUpGameContent")
    local sureCallback = handler(self, self.GiveUpGame)
    XLuaUiManager.Open("UiGoldenMinerDialog", title, desc, nil, sureCallback)
end

function XUiGoldenMinerMain:GiveUpGame()
    XDataCenter.GoldenMinerManager.RequestGoldenMinerExitGame(0, function()
        self:Refresh()
        self:RefreshRedPoint()
        self:CheckShowSettleDialog()
    end, nil, self._DataDb:GetStageScores(), self._DataDb:GetStageScores())
end
--endregion


--region Ui - Settle Dialog
function XUiGoldenMinerMain:CheckShowSettleDialog()
    local curClearData = self._DataDb:GetCurClearData()
    if not curClearData.IsShow then
        return
    end
    local newMaxScoreIcon = XGoldenMinerConfigs.GetNewMaxScoreSettleEmoji()

    if self.TxtClearStageCount then
        self.TxtClearStageCount.text = curClearData.ClearStageCount
    end
    if self.TxtScore then
        self.TxtScore.text = curClearData.TotalScore
        if curClearData.IsNew then
            self.TxtScore.color = XGoldenMinerConfigs.GetNewMaxScoreColor()
        end
    end
    if self.RImgNew then
        self.RImgNew.gameObject:SetActiveEx(curClearData.IsNew)
    end
    if curClearData.IsNew and not string.IsNilOrEmpty(newMaxScoreIcon) and self.RImgNewEmoji then
        self.RImgNewEmoji:SetRawImage(newMaxScoreIcon)
    end
    if curClearData.IsNew and not string.IsNilOrEmpty(XGoldenMinerConfigs.GetEffectCreateRecord()) then
        self.PanelDialog.gameObject:LoadPrefab(XGoldenMinerConfigs.GetEffectCreateRecord())
    end
    if self.PanelDialog then
        self.PanelDialog.gameObject:SetActiveEx(true)
        self:PlayAnimation("PanelrDialogEnable")
        self:PlayAnimation("RImgNewEnable")
    end

    self.BtnReplace.gameObject:SetActiveEx(false)
    self._DataDb:ResetCurClearData()
end

function XUiGoldenMinerMain:HideSettleDialog()
    if self.PanelDialog then
        self.PanelDialog.gameObject:SetActiveEx(false)
    end
    self.BtnReplace.gameObject:SetActiveEx(true)
    self:_PlayBtnReplaceAnim()
end
--endregion


--region Ui - BtnListener
function XUiGoldenMinerMain:AddBtnClickListener()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    self:BindHelpBtn(self.BtnHelp, XGoldenMinerConfigs.GetHelpKey())
    
    self:RegisterClickEvent(self.BtnReplace, self.OnBtnChangeRoleClick)
    self:RegisterClickEvent(self.BtnTask, self.OnBtnTaskClick)
    self:RegisterClickEvent(self.BtnRanking, self.OnBtnRankingClick)
    self:RegisterClickEvent(self.BtnGo, self.OnBtnGoClick)
    self:RegisterClickEvent(self.BtnGo2, self.ContinueGame)
    self:RegisterClickEvent(self.BtnGiveUp, self.OpenGiveUpGameTip)
    
    --结算弹窗的按钮
    self:RegisterClickEvent(self.BtnConfirm, self.HideSettleDialog)
    self:RegisterClickEvent(self.BtnBg, self.HideSettleDialog)
end

function XUiGoldenMinerMain:OnBtnRankingClick()
    XDataCenter.GoldenMinerManager.RequestGoldenMinerRanking(function()
        XLuaUiManager.Open("UiGoldenMinerRank")
    end)
end

function XUiGoldenMinerMain:OnBtnGoClick()
    if self:CheckOpenKeepContinueGameTip() then
        return
    end

    XDataCenter.GoldenMinerManager.RequestGoldenMinerEnterGame(self:GetUseCharacterId(), function()
        local stageId = self._DataDb:GetCurStageId()
        XDataCenter.GoldenMinerManager.RequestGoldenMinerEnterStage(stageId, function()
            XLuaUiManager.PopThenOpen("UiGoldenMinerBattle")
        end)
    end)
end

function XUiGoldenMinerMain:OnBtnTaskClick()
    XLuaUiManager.Open("UiGoldenMinerTask")
end

function XUiGoldenMinerMain:OnBtnChangeRoleClick()
    if XDataCenter.GoldenMinerManager.IsCanKeepBattle() then
        XUiManager.TipErrorWithKey("GoldenMinerCantChangeRole")
        return
    end

    local updateUseCharacterFunc = handler(self, self.UpdateUseCharacter)

    local closeCb = function()
        self:Refresh()
        self:SetCameraType(XGoldenMinerConfigs.CameraType.Main)
        self.SafeAreaContentPanel.gameObject:SetActiveEx(true)
        self:PlayAnimationWithMask("UiEnable")
    end
    self.SafeAreaContentPanel.gameObject:SetActiveEx(false)
    self:OpenOneChildUi("UiGoldenMinerChange", closeCb, updateUseCharacterFunc)
    self:SetCameraType(XGoldenMinerConfigs.CameraType.Change)
    self:PlayAnimationWithMask("UiDisable")
end
--endregion


--region Scene
function XUiGoldenMinerMain:InitSceneRoot()
    local root = self.UiModelGo.transform

    self.PanelRoleModel = root:FindTransform("PanelModel"):FindTransform("PanelRoleModel")
    self.CameraFar = {
        root:FindTransform("FarCamera0"),
        root:FindTransform("FarCamera1"),
    }
    self.CameraNear = {
        root:FindTransform("NearCamera0"),
        root:FindTransform("NearCamera1"),
    }
    ---@type XUiPanelRoleModel
    self._RoleModelPanel = XUiPanelRoleModel.New(self.PanelRoleModel, self.Name)
end
--endregion


--region Scene - Camera
function XUiGoldenMinerMain:SetCameraType(type)
    for k, _ in pairs(self.CameraNear) do
        self.CameraNear[k].gameObject:SetActiveEx(k == type)
    end
    for k, _ in pairs(self.CameraFar) do
        self.CameraFar[k].gameObject:SetActiveEx(k == type)
    end
end
--endregion


--region Scene - Model
function XUiGoldenMinerMain:UpdateUseCharacter(characterId)
    self._ModelAnimatorRandom:Stop()
    XDataCenter.GoldenMinerManager.CatchCurCharacterId(characterId)
    self.UseCharacterId = characterId
    self:UpdateModel()
end

function XUiGoldenMinerMain:UpdateModel()
    local modelName = XGoldenMinerConfigs.GetCharacterModelId(self:GetUseCharacterId())
    self._RoleModelPanel:UpdateCuteModelByModelName(nil, nil, nil, nil, nil,
            modelName, function (model) CS.XShadowHelper.AddShadow(model) end, true)
    self._RoleModelPanel:ShowRoleModel()
    self._ModelAnimatorRandom:SetAnimator(self._RoleModelPanel:GetAnimator(), { }, self._RoleModelPanel)
    self._ModelAnimatorRandom:Play()
end

function XUiGoldenMinerMain:GetUseCharacterId()
    return self.UseCharacterId
end
--endregion