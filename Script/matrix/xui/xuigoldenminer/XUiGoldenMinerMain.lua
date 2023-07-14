local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

--黄金矿工主界面
local XUiGoldenMinerMain = XLuaUiManager.Register(XLuaUi, "UiGoldenMinerMain")

function XUiGoldenMinerMain:OnAwake()
    self.DataDb = XDataCenter.GoldenMinerManager.GetGoldenMinerDataDb()
    self:RegisterButtonEvent()
    self:InitSceneRoot()
    self:HidePanelDialog()
end

function XUiGoldenMinerMain:OnStart()
    self:InitTimes()
    self:SetCameraType(XGoldenMinerConfigs.CameraType.Main)

    if XDataCenter.GoldenMinerManager.GetIsAutoOpenKeepBattleTips() then
        XDataCenter.GoldenMinerManager.SetIsAutoOpenKeepBattleTips(false)
        self:OpenKeepBattleTips()
    end

    --首次自动打开帮助
    local helpKey = XGoldenMinerConfigs.GetHelpKey()
    if XHelpCourseConfig.GetHelpCourseTemplateByFunction(helpKey) and XDataCenter.GoldenMinerManager.CheckFirstOpenHelp() then
        XUiManager.ShowHelpTip(helpKey)
    end
end

function XUiGoldenMinerMain:OnEnable()
    XUiGoldenMinerMain.Super.OnEnable(self)
    self.UseCharacterId = XDataCenter.GoldenMinerManager.GetUseCharacterId()
    XDataCenter.GoldenMinerManager.CatchCurCharacterId(self.UseCharacterId)
    self:Refresh()
    self:CheckShowPanelDialog()
    self:CheckTaskRedPoint()
end

function XUiGoldenMinerMain:RegisterButtonEvent()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    self:BindHelpBtn(self.BtnHelp, XGoldenMinerConfigs.GetHelpKey())
    self:RegisterClickEvent(self.BtnReplace, self.OnBtnReplaceClick)
    self:RegisterClickEvent(self.BtnTask, self.OnBtnTaskClick)
    self:RegisterClickEvent(self.BtnGo, self.OnBtnGoClick)
    self:RegisterClickEvent(self.BtnRanking, self.OnBtnRankingClick)
    --结算弹窗的按钮
    self:RegisterClickEvent(self.BtnConfirm, self.HidePanelDialog)
    self:RegisterClickEvent(self.BtnBg, self.HidePanelDialog)
end

function XUiGoldenMinerMain:InitSceneRoot()
    local root = self.UiModelGo.transform

    self.PanelRoleModel = root:FindTransform("PanelModel")
    self.CameraNear = {
        root:FindTransform("UiCamNearMain"),
        root:FindTransform("UiCamNearChange"),
    }
    self.RoleModelPanel = XUiPanelRoleModel.New(self.PanelRoleModel, self.Name)
end

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

function XUiGoldenMinerMain:UpdateTime()
    local endTime = XDataCenter.GoldenMinerManager.GetActivityEndTime()
    local nowTimeStamp = XTime.GetServerNowTimestamp()
    self.TxtTime.text = XUiHelper.GetTime(endTime - nowTimeStamp, XUiHelper.TimeFormatType.PASSPORT)
end

--检查是否打开继续挑战的提示
function XUiGoldenMinerMain:CheckOpenKeepBattleTips()
    if not XDataCenter.GoldenMinerManager.IsCanKeepBattle() then
        return false
    end
    self:OpenKeepBattleTips()
    return true
end

--打开继续挑战的提示
function XUiGoldenMinerMain:OpenKeepBattleTips()
    local title = XUiHelper.GetText("GoldenMinerStopTipsSureText")
    local desc = XUiHelper.GetText("GoldenMinerKeepBattleTipsDesc")
    local sureCallback = handler(self, self.KeepBattle)
    XLuaUiManager.Open("UiGoldenMinerDialog", title, desc, nil, sureCallback)
end

function XUiGoldenMinerMain:KeepBattle()
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

    if XTool.IsNumberValid(dataDb:GetCurrentPlayStage()) then
        enterBattleFunc()
        return
    end

    XDataCenter.GoldenMinerManager.RequestGoldenMinerEnterStage(curStageId, function()
        if not checkOpenShopFunc() then
            enterBattleFunc()
        end
    end)
end

function XUiGoldenMinerMain:Refresh()
    local useCharacterId = self:GetUseCharacterId()
    self.TxtRoleName.text = XGoldenMinerConfigs.GetCharacterName(useCharacterId)
    self.TxtSkillName.text = XGoldenMinerConfigs.GetCharacterSkillName(useCharacterId) .. "："
    self.TxtSkillDesc.text = XUiHelper.ConvertLineBreakSymbol(XGoldenMinerConfigs.GetCharacterSkillDesc(useCharacterId))
    if self.TxtEnName then
        self.TxtEnName.text = XGoldenMinerConfigs.GetCharacterEnName(useCharacterId)
    end

    self.TxtFraction.text = self.DataDb:GetTotalMaxScores()
    self:UpdateModel()
end

function XUiGoldenMinerMain:UpdateUseCharacter(characterId)
    XDataCenter.GoldenMinerManager.CatchCurCharacterId(characterId)
    self.UseCharacterId = characterId
    self:UpdateModel()
end

function XUiGoldenMinerMain:UpdateModel()
    local modelName = XGoldenMinerConfigs.GetCharacterModelId(self:GetUseCharacterId())
    self.RoleModelPanel:UpdateRoleModelWithAutoConfig(modelName, XModelManager.MODEL_UINAME.XUiGoldenMinerMain3D)
    self.RoleModelPanel:ShowRoleModel()
end

function XUiGoldenMinerMain:SetCameraType(type)
    for k, _ in pairs(self.CameraNear) do
        self.CameraNear[k].gameObject:SetActiveEx(k == type)
    end
end

function XUiGoldenMinerMain:OnBtnRankingClick()
    XDataCenter.GoldenMinerManager.RequestGoldenMinerRanking(function()
        XLuaUiManager.Open("UiGoldenMinerRank")
    end)
end

function XUiGoldenMinerMain:OnBtnGoClick()
    if self:CheckOpenKeepBattleTips() then
        return
    end

    XDataCenter.GoldenMinerManager.RequestGoldenMinerEnterGame(self:GetUseCharacterId(), function()
        local stageId = self.DataDb:GetCurStageId()
        XDataCenter.GoldenMinerManager.RequestGoldenMinerEnterStage(stageId, function()
            XLuaUiManager.PopThenOpen("UiGoldenMinerBattle")
        end)
    end)
end

function XUiGoldenMinerMain:OnBtnTaskClick()
    XLuaUiManager.Open("UiGoldenMinerTask")
end

--换角色
function XUiGoldenMinerMain:OnBtnReplaceClick()
    if self:CheckOpenKeepBattleTips() then
        return
    end

    local updateUseCharacterFunc = handler(self, self.UpdateUseCharacter)

    local closeCb = function()
        self:Refresh()
        self:SetCameraType(XGoldenMinerConfigs.CameraType.Main)
        self.SafeAreaContentPanel.gameObject:SetActiveEx(true)
    end
    self.SafeAreaContentPanel.gameObject:SetActiveEx(false)
    self:OpenOneChildUi("UiGoldenMinerChange", closeCb, updateUseCharacterFunc)
    self:SetCameraType(XGoldenMinerConfigs.CameraType.Change)
end

function XUiGoldenMinerMain:GetUseCharacterId()
    return self.UseCharacterId
end

function XUiGoldenMinerMain:CheckTaskRedPoint()
    local isCanReward = XDataCenter.GoldenMinerManager.CheckTaskCanReward()
    self.BtnTask:ShowReddot(isCanReward)
end

-----------------本次结算总结 begin------------------
function XUiGoldenMinerMain:CheckShowPanelDialog()
    local curClearData = self.DataDb:GetCurClearData()
    if not curClearData.IsShow then
        return
    end

    if self.TxtClearStageCount then
        self.TxtClearStageCount.text = curClearData.ClearStageCount
    end
    if self.TxtScore then
        self.TxtScore.text = curClearData.TotalScore
    end
    if self.RImgNew then
        self.RImgNew.gameObject:SetActiveEx(curClearData.IsNew)
    end
    if self.PanelDialog then
        self.PanelDialog.gameObject:SetActiveEx(true)
        self:PlayAnimation("PanelrDialogEnable")
        self:PlayAnimation("RImgNewEnable")
    end
    self.DataDb:ResetCurClearData()
end

function XUiGoldenMinerMain:HidePanelDialog()
    if self.PanelDialog then
        self.PanelDialog.gameObject:SetActiveEx(false)
    end
end
-----------------本次结算总结 end--------------------