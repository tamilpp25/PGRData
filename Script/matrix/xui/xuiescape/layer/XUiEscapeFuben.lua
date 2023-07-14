local XUiEscapeLayerPanel = require("XUi/XUiEscape/Layer/XUiEscapeLayerPanel")
local XUiPanelFeature = require("XUi/XUiEscape/XUiPanelFeature")

--大逃杀区域爬塔界面
local XUiEscapeFuben = XLuaUiManager.Register(XLuaUi, "UiEscapeFuben")

function XUiEscapeFuben:OnAwake()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.LayerPanels = {}
    self:InitButtonCallBack()
    self:InitDynamicTable()
    self.EscapeData = XDataCenter.EscapeManager.GetEscapeData()
    self.FeaturePanel = XUiPanelFeature.New(self.PanelBuffList)
end

function XUiEscapeFuben:OnStart(chapterGroupId)
    self.ChapterGroupId = chapterGroupId
    self.ChapterIdList = XEscapeConfigs.GetEscapeChapterIdListByGroupId(chapterGroupId)
    self:InitCurDifficulty()
    self:InitTimes()
end

function XUiEscapeFuben:OnEnable()
    XUiEscapeFuben.Super.OnEnable(self)
    self:Refresh()
    self:CheckOpenChapterSettle()
end

function XUiEscapeFuben:OnDestroy()
    for _, grid in pairs(self.DynamicTable:GetGrids()) do
        grid:Destroy()
    end
end

function XUiEscapeFuben:OnReleaseInst()
    return self.CurDifficulty
end

function XUiEscapeFuben:OnResume(value)
    self.CurDifficulty = value
end

function XUiEscapeFuben:InitTimes()
    self:SetAutoCloseInfo(XDataCenter.EscapeManager.GetActivityEndTime(), function(isClose)
        if isClose then
            XDataCenter.EscapeManager.HandleActivityEndTime()
        end
    end)
end

function XUiEscapeFuben:InitCurDifficulty()
    if self.CurDifficulty then
        return
    end
    
    local chapterIdList = self.ChapterIdList
    local difficulty
    for _, chapterId in ipairs(chapterIdList) do
        if self.EscapeData:IsInChallengeChapter(chapterId) then
            difficulty = XEscapeConfigs.GetChapterDifficulty(chapterId)
            break
        end
    end
    self.CurDifficulty = difficulty or XEscapeConfigs.Difficulty.Normal
end

function XUiEscapeFuben:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelStageList)
    self.DynamicTable:SetProxy(XUiEscapeLayerPanel)
    self.DynamicTable:SetDelegate(self)
    self.GridStage.gameObject:SetActiveEx(false)
end

function XUiEscapeFuben:Refresh()
    local curDifficulty = self.CurDifficulty
    local chapterId = self.ChapterIdList[curDifficulty]

    self.TxtStageNum.text = XUiHelper.GetText("EscapeChapterEnglishId", chapterId)
    self.TxtTitle.text = XEscapeConfigs.GetChapterName(chapterId)

    self.TxtBuff.text = XUiHelper.ConvertLineBreakSymbol(XEscapeConfigs.GetChapterBuffDesc(chapterId))
    self.FeaturePanel:Refresh(XEscapeConfigs.GetChapterShowFightEventIds(chapterId))

    --未进行挑战则不展示撤退按钮
    local isInChallenge = self.EscapeData:IsInChallengeChapter(chapterId)
    self.BtnExit.gameObject:SetActiveEx(isInChallenge)

    self.BtnHardMod.gameObject:SetActiveEx(curDifficulty == XEscapeConfigs.Difficulty.Hard)
    self.BtnEasyMod.gameObject:SetActiveEx(curDifficulty == XEscapeConfigs.Difficulty.Normal)
    if self.BgHard then
        self.BgHard.gameObject:SetActiveEx(curDifficulty == XEscapeConfigs.Difficulty.Hard)
    end
    if self.BgEasy then
        self.BgEasy.gameObject:SetActiveEx(curDifficulty == XEscapeConfigs.Difficulty.Normal)
    end

    --剩余逃生时间，未进行挑战不显示
    if isInChallenge then
        local remainTime = self.EscapeData:GetRemainTime()
        self.TxtTime.text = XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.ESCAPE_REMAIN_TIME)
    end
    self.PanelTime.gameObject:SetActiveEx(isInChallenge)

    --当前积分和评级
    local score = self.EscapeData:GetScore()
    if self.TxtIntegral then
        self.TxtIntegral.text = XUiHelper.GetText("EscapeCurScore", score)
    end
    if self.RImgIntegral then
        self.RImgIntegral:SetRawImage(XEscapeConfigs.GetChapterSettleRemainTimeGradeImgPath(score))
    end

    self:UpdateLayer(chapterId)
end

function XUiEscapeFuben:UpdateLayer(chapterId)
    self.LayerIdList = XEscapeConfigs.GetChapterLayerIds(chapterId)
    self.DynamicTable:SetDataSource(self.LayerIdList)
    self.DynamicTable:ReloadDataSync()
end

function XUiEscapeFuben:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local layerId = self.LayerIdList[index]
        local chapterId = self.ChapterIdList[self.CurDifficulty]
        grid.RootUi = self.RootUi
        grid:Refresh(layerId, index, chapterId)
    end
end

function XUiEscapeFuben:InitButtonCallBack()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    self:BindHelpBtn(self.BtnHelp, XEscapeConfigs.GetHelpKey())
    self:RegisterClickEvent(self.BtnExit, self.OnBtnExitClick)  --撤出战场
    self:RegisterClickEvent(self.BtnEasyMod, self.OnBtnSwitchModelClick)  --切换难度
    self:RegisterClickEvent(self.BtnHardMod, self.OnBtnSwitchModelClick)  --切换难度
end

function XUiEscapeFuben:OnBtnSwitchModelClick()
    local curDifficulty = self.CurDifficulty
    local chapterIdList = self.ChapterIdList
    if self.EscapeData:IsInChallengeChapter(chapterIdList[curDifficulty]) then
        XUiManager.TipErrorWithKey("EscapeInChallengeMode", XEscapeConfigs.GetDifficultyName(curDifficulty))
        return
    end

    local difficulty = curDifficulty == XEscapeConfigs.Difficulty.Normal and XEscapeConfigs.Difficulty.Hard or XEscapeConfigs.Difficulty.Normal
    local chapterId = chapterIdList[difficulty]
    if not chapterId then
        return
    end

    if not XDataCenter.EscapeManager.IsChapterOpen(chapterId, true) then
        return
    end

    self.CurDifficulty = difficulty

    self:PlayAnimation("QieHuan")
    self:Refresh()
end

function XUiEscapeFuben:OnBtnExitClick()
    local title = XUiHelper.GetText("EscapeGiveUpTipsTitle")
    local content = XUiHelper.GetText("EscapeGiveUpTipsDesc")
    local sureCallback = function()
        XDataCenter.EscapeManager.RequestEscapeSettleChapter(function()
            self:OpenUiEscapeSettle(false)
        end)
    end
    XUiManager.DialogTip(title, content, nil, nil, sureCallback, nil)
end

function XUiEscapeFuben:CheckOpenChapterSettle()
    if XDataCenter.EscapeManager.GetIsOpenChapterSettle() then
        XDataCenter.EscapeManager.SetOpenChapterSettle(false)
        self:OpenUiEscapeSettle(true)
    end
end

function XUiEscapeFuben:OpenUiEscapeSettle(isWin)
    XLuaUiManager.Remove("UiEscapeFuben")
    XLuaUiManager.Open("UiEscapeSettle", XEscapeConfigs.ShowSettlePanel.AllWinInfo, isWin)
end

function XUiEscapeFuben:OnGetEvents()
    return {XEventId.EVENT_ESCAPE_DATA_NOTIFY}
end

function XUiEscapeFuben:OnNotify(evt, ...)
    if evt == XEventId.EVENT_ESCAPE_DATA_NOTIFY then
        self:Refresh()
        self:CheckOpenChapterSettle()
    end
end