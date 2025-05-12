local XGoldenMinerDialogExData = require("XModule/XGoldenMiner/Data/Game/XGoldenMinerDialogExData")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local XPanelRoleListActionRandom = require("XUi/XUiSpecialTrainBreakthrough/XPanelRoleListActionRandom")

---黄金矿工主界面
---@class XUiGoldenMinerMain : XLuaUi
---@field _Control XGoldenMinerControl
local XUiGoldenMinerMain = XLuaUiManager.Register(XLuaUi, "UiGoldenMinerMain")

function XUiGoldenMinerMain:OnAwake()
    self._DataDb = self._Control:GetMainDb()
    ---@type XPanelRoleListActionRandom
    self._ModelAnimatorRandom = XPanelRoleListActionRandom.New()

    self:AddBtnClickListener()
    self:InitSceneRoot()
    self:HideSettleDialog()
end

function XUiGoldenMinerMain:OnStart()
    self:InitTimes()
    self:SetCameraType(XEnumConst.GOLDEN_MINER.CAMERA_TYPE.MAIN)

    self:CheckAutoOpenContinueGameTip()
    self:CheckAndOpenHelpTip()
end

function XUiGoldenMinerMain:OnEnable()
    XUiGoldenMinerMain.Super.OnEnable(self)
    self.UseCharacterId = self._Control:GetUseCharacterId()
    self._Control:CatchCurCharacterId(self.UseCharacterId)
    self:Refresh()
    self:RefreshRedPoint()
    self:CheckShowSettleDialog()
    self:_PlayRoleAnim()
end

function XUiGoldenMinerMain:OnDisable()
    self:_StopRoleAnim()
end


--region Activity - AutoClose
function XUiGoldenMinerMain:InitTimes()
    -- 设置自动关闭和倒计时
    self:SetAutoCloseInfo(self._Control:GetCurActivityEndTime(), function(isClose)
        if isClose then
            self._Control:HandleActivityEndTime()
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

function XUiGoldenMinerMain:_SetRectSize()
    local areaPanel = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPanel")
    self._Control:SetRectSize(areaPanel:GetComponent("RectTransform").rect.size)
end
--endregion

--region Ui - Time
function XUiGoldenMinerMain:UpdateTime()
    local endTime = self._Control:GetCurActivityEndTime()
    local nowTimeStamp = XTime.GetServerNowTimestamp()
    local timeTxt = XUiHelper.GetTime(endTime - nowTimeStamp, XUiHelper.TimeFormatType.ACTIVITY)
    self.TxtTime.text = XUiHelper.GetText("GoldenMinerMainTimeTitle", timeTxt)
end
--endregion

--region Ui - RoleInfo
function XUiGoldenMinerMain:UpdateRoleInfo()
    local useCharacterId = self:GetUseCharacterId()
    self.TxtRoleName.text = self._Control:GetCfgCharacterName(useCharacterId)
    self.TxtSkillName.text = self._Control:GetCfgCharacterSkillName(useCharacterId) .. "："
    self.TxtSkillDesc.text = XUiHelper.ConvertLineBreakSymbol(self._Control:GetCfgCharacterSkillDesc(useCharacterId))
    self.TxtEnName.text = self._Control:GetCfgCharacterEnName(useCharacterId)
    self:RefreshBtnReplace(not self._Control:CheckIsHaveGameStage())
end
--endregion

--region Ui - MaxScore & CurGameInfo
function XUiGoldenMinerMain:UpdateMaxScore()
    if self._Control:CheckIsHaveGameStage() then
        return
    end
    self.PanelSz2.gameObject:SetActiveEx(false)
    self.ImgJian.gameObject:SetActiveEx(false)
    self.ImgJian02.gameObject:SetActiveEx(true)
    self.PanelSz.gameObject:SetActiveEx(true)
    self.TxtTitle.text = XUiHelper.GetText("GoldenMinerMainTitle1")
    self.TxtFraction.text = self._DataDb:GetTotalMaxScores()
end

function XUiGoldenMinerMain:UpdateCurGameInfo()
    if not self._Control:CheckIsHaveGameStage() then
        return
    end
    self.PanelSz2.gameObject:SetActiveEx(false)
    self.ImgJian.gameObject:SetActiveEx(true)
    self.ImgJian02.gameObject:SetActiveEx(false)
    local stageIndex = self._DataDb:GetCurShowStageIndex()
    self.TxtTitle.text = XUiHelper.GetText("GoldenMinerMainTitle2")
    self.Txt2.text = stageIndex
    self.TxtFraction.text = self._DataDb:GetStageScores()
    --self.TxtCurScore.text = self._DataDb:GetStageScores()
    --self.TxtCurStageCount.text = stageIndex
end
--endregion

--region Ui - BtnState
function XUiGoldenMinerMain:UpdateBtn()
    local isBattle = self._Control:CheckIsHaveGameStage()
    self.BtnGo.gameObject:SetActiveEx(not isBattle)
    self.BtnGo2.gameObject:SetActiveEx(isBattle)
    self.BtnGiveUp:SetDisable(not isBattle)
    self:RefreshBtnReplace(false)
end

function XUiGoldenMinerMain:_PlayBtnReplaceAnim()
    self:PlayAnimation("BtnReplaceEnable")
end

function XUiGoldenMinerMain:RefreshBtnReplace(isShow)
    isShow = false
    self.BtnReplace.gameObject:SetActiveEx(isShow)
    if isShow then
        self:_PlayBtnReplaceAnim()
    end
end
--endregion

--region Ui - RedPoint
function XUiGoldenMinerMain:RefreshRedPoint()
    self:CheckTaskRedPoint()
    -- 4期不用
    --self:CheckRoleRedPoint()
end

function XUiGoldenMinerMain:CheckTaskRedPoint()
    local isCanReward = self._Control:CheckHaveTaskCanRecv()
    self.BtnTask:ShowReddot(isCanReward)
end

function XUiGoldenMinerMain:CheckRoleRedPoint()
    local isHaveNewRole = self._Control:CheckHaveNewRole()
    self.BtnReplace:ShowReddot(isHaveNewRole)
end
--endregion

--region Ui - Help Tip
---首次自动打开帮助
function XUiGoldenMinerMain:CheckAndOpenHelpTip()
    local helpKey = self._Control:GetClientHelpKey()
    if string.IsNilOrEmpty(helpKey) then
        return
    end

    if XHelpCourseConfig.GetHelpCourseTemplateByFunction(helpKey) and self._Control:CheckFirstOpenHelp() then
        XUiManager.ShowHelpTip(helpKey)
    end
end
--endregion

--region Ui - ContinueGame Tip
---每次登录首次进活动检查是否存在已有对局
function XUiGoldenMinerMain:CheckAutoOpenContinueGameTip()
    if self._Control:CheckIsAutoInGameTips() then
        self:OpenContinueGameTip()
    end
    self._Control:SetIsAutoInGameTips(false)
end

---进入游戏前检查是否存在已有对局
function XUiGoldenMinerMain:CheckOpenKeepContinueGameTip()
    if not self._Control:CheckIsHaveGameStage() then
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
    self:_SetRectSize()
    self._Control:ContinueGame()
end
--endregion

--region Ui - GiveUpGame Tip
---打开放弃挑战的提示
function XUiGoldenMinerMain:OpenGiveUpGameTip()
    if not self._Control:CheckIsHaveGameStage() then
        return
    end
    local title = XUiHelper.GetText("GoldenMinerGiveUpGameTitle")
    local desc = XUiHelper.GetText("GoldenMinerGiveUpGameContent")
    local sureCallback = handler(self, self.GiveUpGame)
    XLuaUiManager.Open("UiGoldenMinerDialog", title, desc, nil, sureCallback)
end

function XUiGoldenMinerMain:GiveUpGame()
    self._Control:RequestGoldenMinerExitGame(0, function()
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
    local newMaxScoreIcon = self._Control:GetClientNewMaxScoreSettleEmoji()

    if self.TxtClearStageCount then
        self.TxtClearStageCount.text = curClearData.ClearStageCount
    end
    if self.TxtScore then
        self.TxtScore.text = curClearData.TotalScore
        if curClearData.IsNew then
            self.TxtScore.color = self._Control:GetClientNewMaxScoreColor()
        end
    end
    if self.RImgNew then
        self.RImgNew.gameObject:SetActiveEx(curClearData.IsNew)
    end
    if curClearData.IsNew and not string.IsNilOrEmpty(newMaxScoreIcon) and self.RImgNewEmoji then
        self.RImgNewEmoji:SetRawImage(newMaxScoreIcon)
    end
    local createRecordEffectIcon = self._Control:GetClientEffectCreateRecord()
    if curClearData.IsNew and not string.IsNilOrEmpty(createRecordEffectIcon) then
        self.PanelDialog.gameObject:LoadPrefab(createRecordEffectIcon)
    end
    local settleBgIcon = self._Control:GetClientNewMaxScoreSettleBg(1)
    if not curClearData.IsNew and not string.IsNilOrEmpty(settleBgIcon) then
        self.SettleBg:SetRawImage(settleBgIcon)
        self.SettleTitleBg1:SetSprite(self._Control:GetClientNewMaxScoreSettleBg(2))
        self.SettleTitleBg2:SetSprite(self._Control:GetClientNewMaxScoreSettleBg(2))
    end

    if self.PanelDialog then
        self.PanelDialog.gameObject:SetActiveEx(true)
        self:PlayAnimation("PanelrDialogEnable")
        self:PlayAnimation("RImgNewEnable")
    end

    self:RefreshBtnReplace(false)
    self._DataDb:ResetCurClearData()
end

function XUiGoldenMinerMain:HideSettleDialog()
    if self.PanelDialog then
        self.PanelDialog.gameObject:SetActiveEx(false)
    end
    self:RefreshBtnReplace(true)
end
--endregion

--region Ui - BtnListener
function XUiGoldenMinerMain:AddBtnClickListener()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, function()
        XLuaUiManager.RunMain()
    end)
    local helpKey = self._Control:GetClientHelpKey()
    if not string.IsNilOrEmpty(helpKey) then
        self:BindHelpBtn(self.BtnHelp, self._Control:GetClientHelpKey())
        self.BtnHelp.gameObject:SetActiveEx(true)
    else
        self.BtnHelp.gameObject:SetActiveEx(false)
    end

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
    self._Control:RequestGoldenMinerRanking(function()
        XLuaUiManager.Open("UiGoldenMinerRank")
    end)
end

function XUiGoldenMinerMain:OnBtnGoClick()
    if self:CheckOpenKeepContinueGameTip() then
        return
    end

    self._Control:RequestGoldenMinerEnterGame(self:GetUseCharacterId(), function()
        self:_SetRectSize()
        self._Control:OpenGameUi()
    end)
end

function XUiGoldenMinerMain:OnBtnTaskClick()
    XLuaUiManager.Open("UiGoldenMinerTask")
end

function XUiGoldenMinerMain:OnBtnChangeRoleClick()
    if self._Control:CheckIsHaveGameStage() then
        XUiManager.TipErrorWithKey("GoldenMinerCantChangeRole")
        return
    end

    local updateUseCharacterFunc = handler(self, self.UpdateUseCharacter)

    local closeCb = function()
        self:Refresh()
        self:SetCameraType(XEnumConst.GOLDEN_MINER.CAMERA_TYPE.MAIN)
        self.SafeAreaContentPanel.gameObject:SetActiveEx(true)
        self:PlayAnimationWithMask("UiEnable")
    end
    self.SafeAreaContentPanel.gameObject:SetActiveEx(false)
    self:OpenOneChildUi("UiGoldenMinerChange", closeCb, updateUseCharacterFunc)
    self:SetCameraType(XEnumConst.GOLDEN_MINER.CAMERA_TYPE.CHANGE)
    self:PlayAnimationWithMask("UiDisable")
end
--endregion

--region Scene
function XUiGoldenMinerMain:InitSceneRoot()
    local root = self.UiModelGo.transform

    self.PanelRoleModel = root:FindTransform("PanelModel"):FindTransform("PanelRoleModel")
    self.PanelRoleModelLeft = root:FindTransform("PanelModel"):FindTransform("PanelRoleModelLeft")
    self.PanelRoleModelRight = root:FindTransform("PanelModel"):FindTransform("PanelRoleModelRight")
    self.CameraFar = {
        root:FindTransform("FarCamera0"),
        root:FindTransform("FarCamera1"),
    }
    self.CameraNear = {
        root:FindTransform("NearCamera0"),
        root:FindTransform("NearCamera1"),
    }
    ---@type XUiPanelRoleModel[]
    self._RoleModelPanelList = {
        XUiPanelRoleModel.New(self.PanelRoleModel, self.Name, nil, true),
        XUiPanelRoleModel.New(self.PanelRoleModelLeft, self.Name, nil, true),
        XUiPanelRoleModel.New(self.PanelRoleModelRight, self.Name, nil, true),
    }
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
    self:_StopRoleAnim()
    self._Control:CatchCurCharacterId(characterId)
    self.UseCharacterId = characterId
    self:UpdateModel()
end

function XUiGoldenMinerMain:UpdateModel()
    for i, roleModelPanel in ipairs(self._RoleModelPanelList) do
        local modelName = self._Control:GetCfgCharacterModelId(self._Control:GetClientMainShowCharByIndex(i))
        roleModelPanel:UpdateCuteModelByModelName(nil, nil, nil, nil, nil,
                modelName, nil, true)
        roleModelPanel:ShowRoleModel()
    end
    self._ModelAnimatorRandom:SetAnimatorByPanelRoleModelList(self._RoleModelPanelList[1]:GetAnimator(), { }, self._RoleModelPanelList)
    self._ModelAnimatorRandom:Play()
end

function XUiGoldenMinerMain:_PlayRoleAnim()
    self._ModelAnimatorRandom:Play()
end

function XUiGoldenMinerMain:_StopRoleAnim()
    self._ModelAnimatorRandom:Stop()
end

function XUiGoldenMinerMain:GetUseCharacterId()
    return self.UseCharacterId
end
--endregion