---@class XUiFangKuaiChapterDetail : XLuaUi 大方块关卡详情
---@field _Control XFangKuaiControl
local XUiFangKuaiChapterDetail = XLuaUiManager.Register(XLuaUi, "UiFangKuaiChapterDetail")

function XUiFangKuaiChapterDetail:OnAwake()
    self:RegisterClickEvent(self.BtnChange, self.OnClickChange)
    self:RegisterClickEvent(self.BtnTongBlack, self.OnClickTongBlack)
    self:RegisterClickEvent(self.BtnExchangeEmpty, self.OnClickExchangeEmpty)
    self:RegisterClickEvent(self.BtnCloseExchange, self.OnClickExchangeEmpty)
    self:BindHelpBtn(self.BtnHelp, self._Control:GetHelpId())
end

function XUiFangKuaiChapterDetail:OnStart(stageGroupId, tabIndex)
    self._StageGroup = self._Control:GetStageGroupConfig(stageGroupId)
    self._CurNpcId = self._Control:GetCurShowNpcId()
    self._SimpleColor = self._Control:GetClientConfig("SimpleStageScoreColor")
    self._DiffcultColor = self._Control:GetClientConfig("DiffcultStageScoreColor")
    self._IsSingleStage = not XTool.IsNumberValid(self._StageGroup.SimpleStageId) or not XTool.IsNumberValid(self._StageGroup.DiffcultStageId)

    self:InitTab()
    self:InitSceneRoot()
    self:InitCompnent()
    self:InitSelectNpc()
    self:UpdatePlayer()
    self:HideOrShowExchange(false)
    self.PanelTab:SelectIndex(tabIndex or self._Control:GetStageGroupTabIdx(stageGroupId))
    self._Control:SaveEnterStageGroupRecord(stageGroupId)

    self.EndTime = self._Control:GetActivityGameEndTime()
    self:SetAutoCloseInfo(self.EndTime, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end)
end

function XUiFangKuaiChapterDetail:InitCompnent()
    self._TopController = XUiHelper.NewPanelTopControl(self, self.TopControlWhite)
    self.PanelTab:Init({ self.BtnSimple, self.BtnDifficult }, function(index)
        if XTool.IsNumberValid(self._StageId) then
            self:PlayAnimation("QiehuanEnable01")
        end
        self:OnSelectTab(index)
    end)
end

function XUiFangKuaiChapterDetail:SelectDifficult()
    self:InitTab()
    self.PanelTab:SelectIndex(XEnumConst.FangKuai.DifficultTab)
end

function XUiFangKuaiChapterDetail:OnSelectTab(index)
    if index == XEnumConst.FangKuai.DifficultTab and not self._Control:IsStageUnlock(self._StageGroup.DiffcultStageId) then
        XUiManager.TipError(XUiHelper.GetText("FangKuaiDifficultLockTip"))
        return
    end
    self._IsNormal = index == XEnumConst.FangKuai.SimpleTab
    self._StageId = self._IsNormal and self._StageGroup.SimpleStageId or self._StageGroup.DiffcultStageId
    self._StageConfig = self._Control:GetStageConfig(self._StageId)
    self:UpdateEnemy()
    self._Control:RecordStageGroupTabIdx(self._StageGroup.Id, index)
end

function XUiFangKuaiChapterDetail:InitSelectNpc()
    local btns = {}
    local curSelect = 1
    self._NpcList = self._Control:GetAllPlayerNpc()
    XUiHelper.RefreshCustomizedList(self.Content.transform, self.GridCharacterNew, #self._NpcList, function(index, grid)
        local npc = self._NpcList[index]
        local favorabilityLv = self._Control:GetFavorLevelColor(npc.CharacterId, npc.FavorLv)
        local isSelected = npc.Config.Id == self._CurNpcId
        local uiObject = {}
        XUiHelper.InitUiClass(uiObject, grid)
        uiObject.RImgHeadIcon:SetRawImage(npc.Config.HeadIcon)
        uiObject.RImgSelectHeadIcon:SetRawImage(npc.Config.HeadIcon)
        uiObject.TxtRobotName.text = npc.Config.Name
        uiObject.TxtSelectRobotName.text = npc.Config.Name
        uiObject.TxtRobotTradeName.text = npc.Config.TradeName
        uiObject.TxtSelectRobotTradeName.text = npc.Config.TradeName
        uiObject.TxtLv.text = npc.FavorLv
        uiObject.TxtFavorabilityLv.text = favorabilityLv
        uiObject.TxtSelectFavorabilityLv.text = favorabilityLv
        uiObject.PanelSelected.gameObject:SetActiveEx(isSelected)
        uiObject.PanelNormal.gameObject:SetActiveEx(not isSelected)
        self:SetUiSprite(uiObject.ImgHeart, self._Control:GetFavorLevelIcon(npc.FavorLv))
        table.insert(btns, uiObject.GridCharacterNew)
        if isSelected then
            curSelect = index
        end
    end)
    self.Content:Init(btns, function(index)
        self:OnTabsClick(index)
        self:PlayAnimation("QiehuanEnable02")
    end)
    self.Content:SelectIndex(curSelect)
end

function XUiFangKuaiChapterDetail:InitSceneRoot()
    local panelModel = self.UiModelGo.transform:FindTransform("PanelModel")
    self._UiCamNearMain = self.UiModelGo.transform:FindTransform("UiCamNearMain")
    self._UiCamNearChange = self.UiModelGo.transform:FindTransform("UiCamNearPanelExchange")
    self._UiCamFarPanelExchange = self.UiModelGo.transform:FindTransform("UiCamFarPanelExchange")
    ---@type XUiPanelRoleModel
    self._RoleModelPanel = require("XUi/XUiCharacter/XUiPanelRoleModel").New(panelModel, self.Name, nil, true, nil, true)
end

function XUiFangKuaiChapterDetail:UpdateEnemy()
    local stageConfig = self._Control:GetStageConfig(self._StageId)
    self.RImgBoss:SetRawImage(stageConfig.HeadIcon)
    self.TxtNum.text = self._StageConfig.MaxRound
    self.TxtDetail.text = self._StageConfig.Desc
    self.TxtNoLimit.gameObject:SetActiveEx(false)
    self.TxtTitle.text = stageConfig.Name
    self.TxtName.text = stageConfig.BossName
    self.TxtName2.text = stageConfig.BossName

    local items = self._Control:GetStageShowItems(self._StageId)
    XUiHelper.RefreshCustomizedList(self.ListFangKuai, self.GridFangKuai, #items, function(index, grid)
        local uiObject = {}
        XUiHelper.InitUiClass(uiObject, grid)
        uiObject.RImgIcon:SetRawImage(items[index].Icon)
        XUiHelper.RegisterClickEvent(uiObject, uiObject.RImgIcon.transform, function()
            self:OnClickItem(items[index].Id)
        end)
    end)

    if self._Control:IsStagePass(self._StageId) then
        local score = self._Control:GetMaxScore(self._StageId)
        local gradeIcon = self._Control:GetStageRankIcon(self._StageId, score)
        self.PanelScore.gameObject:SetActiveEx(score > 0)
        self.RImgRankA:SetRawImage(gradeIcon)
        self.TxtScore.text = string.format("<color=%s>%s</color>", self._IsNormal and self._SimpleColor or self._DiffcultColor, score)
        self.TxtRound.text = self._Control:GetMaxRound(self._StageId)
    else
        self.PanelScore.gameObject:SetActiveEx(false)
    end

    local isNormal = self._StageId == self._StageGroup.SimpleStageId
    local isDifficlity = self._StageId == self._StageGroup.DiffcultStageId
    self.RImgNormalBg.gameObject:SetActiveEx(isNormal)
    self.PanelNormal.gameObject:SetActiveEx(isNormal)
    self.RImgHardBg.gameObject:SetActiveEx(isDifficlity)
    self.PanelDifficulty.gameObject:SetActiveEx(isDifficlity)
end

function XUiFangKuaiChapterDetail:InitTab()
    if self._IsSingleStage then
        self.PanelTab.gameObject:SetActiveEx(false)
    else
        self.PanelTab.gameObject:SetActiveEx(true)
        self.ImgLock1.gameObject:SetActiveEx(not self._Control:IsStageUnlock(self._StageGroup.SimpleStageId))
        self.ImgComplete1.gameObject:SetActiveEx(self._Control:IsStagePass(self._StageGroup.SimpleStageId))
        self.ImgComplete2.gameObject:SetActiveEx(self._Control:IsStagePass(self._StageGroup.DiffcultStageId))
        self.ImgRed1.gameObject:SetActiveEx(false)
        self.ImgRed2.gameObject:SetActiveEx(self._Control:CheckStageRedPoint(self._StageGroup.DiffcultStageId))

        local isUnlock = self._Control:IsStageUnlock(self._StageGroup.DiffcultStageId)
        self.ImgLock2.gameObject:SetActiveEx(not isUnlock)
        self.BtnDifficult:SetButtonState(isUnlock and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
    end
end

function XUiFangKuaiChapterDetail:UpdatePlayer()
    local npcAction = self._Control:GetNpcActionConfig(self._CurNpcId)
    self._RoleModelPanel:UpdateCuteModelByModelName(nil, nil, nil, nil, nil, npcAction.Model, nil, true, nil, nil, true)
end

function XUiFangKuaiChapterDetail:HideOrShowExchange(isShow)
    self.PaneExchange.gameObject:SetActiveEx(isShow)
    self.PanelChapterDetail.gameObject:SetActiveEx(not isShow)
    self.BtnTongBlack.gameObject:SetActiveEx(not isShow)
    self._UiCamNearMain.gameObject:SetActiveEx(not isShow)
    self._UiCamNearChange.gameObject:SetActiveEx(isShow)
    self._UiCamFarPanelExchange.gameObject:SetActiveEx(isShow)
    self.BtnChange.gameObject:SetActiveEx(not isShow)
    if isShow then
        self.PanelScore.gameObject:SetActiveEx(false)
    elseif self._Control:IsStagePass(self._StageId) then
        local score = self._Control:GetMaxScore(self._StageId)
        self.PanelScore.gameObject:SetActiveEx(score > 0)
    end
end

function XUiFangKuaiChapterDetail:OnTabsClick(index)
    self._CurNpc = self._NpcList[index]
    self._CurNpcId = self._CurNpc.Config.Id
    self:UpdatePlayer()

    local key = string.format("FangKuaiNpcId_%s_%s", XPlayer.Id, self._Control:GetActivityId())
    XSaveTool.SaveData(key, self._CurNpcId)
end

function XUiFangKuaiChapterDetail:OnClickChange()
    self:HideOrShowExchange(true)
end

function XUiFangKuaiChapterDetail:OnClickExchangeEmpty()
    self:HideOrShowExchange(false)
end

function XUiFangKuaiChapterDetail:OnClickTongBlack()
    self._Control:FangKuaiStageStartRequest(self._StageId, function()
        self:OpenFightPanel()
    end)
end

function XUiFangKuaiChapterDetail:OpenFightPanel()
    self._Control:EnterGame(self._StageId, true)
end

function XUiFangKuaiChapterDetail:OnClickItem(itemId)
    XLuaUiManager.Open("UiFangKuaiPropDetail", itemId)
end

return XUiFangKuaiChapterDetail