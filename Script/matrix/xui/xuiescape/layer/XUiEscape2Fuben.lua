local XUiGridFightEventBuff = require("XUi/XUiEscape/Layer/XUiGridFightEventBuff")
local XUiEscapeLayerPanel = require("XUi/XUiEscape/Layer/XUiEscapeLayerPanel")
local XUiPanelTactics = require("XUi/XUiEscape/Tactics/XUiPanelTactics")

--大逃杀玩法策略
local XUiEscape2Fuben = XLuaUiManager.Register(XLuaUi, "UiEscapeFuben")

function XUiEscape2Fuben:OnAwake()
    self:InitExitBtn()
    self:AddBtnClickListener()
end

function XUiEscape2Fuben:OnStart(chapterId)
    self:InitData(chapterId)
    self:InitText()
    self:InitBuff()
    self:InitTime()
    self:InitStageDynamicTable()
    self:InitTactics()
    self:InitTimes()
end

function XUiEscape2Fuben:OnEnable()
    XUiEscape2Fuben.Super.OnEnable(self)
    self:Refresh()
end

function XUiEscape2Fuben:OnDisable()
    XUiEscape2Fuben.Super.OnDisable(self)
end

function XUiEscape2Fuben:OnDestroy()
end

function XUiEscape2Fuben:OnGetEvents()
    return {XEventId.EVENT_ESCAPE_DATA_NOTIFY}
end

function XUiEscape2Fuben:OnNotify(evt, ...)
    if evt == XEventId.EVENT_ESCAPE_DATA_NOTIFY then
        self:Refresh()
    end
end

--region AutoClose
function XUiEscape2Fuben:InitTimes()
    -- 设置自动关闭和倒计时
    self:SetAutoCloseInfo(XDataCenter.EscapeManager.GetActivityEndTime(), function(isClose)
        if isClose then
            XDataCenter.EscapeManager.HandleActivityEndTime()
            return
        end
        self:UpdateTime()
    end, nil, 0)
end
--endregion

--region AutoSettle
function XUiEscape2Fuben:CheckChapterAutoSettle()
    if XDataCenter.EscapeManager.GetIsOpenChapterSettle() then
        XDataCenter.EscapeManager.SetOpenChapterSettle(false)
        XDataCenter.EscapeManager.OpenUiEscapeSettle(true)
    end
end
--endregion

--region UiRefresh
function XUiEscape2Fuben:Refresh()
    self:UpdateTime()
    self:UpdateStage()
    self:UpdateExitBtn()
    self:UpdateTactics()
    self:CheckChapterAutoSettle()
    self:SelectStageLayer()
end
--endregion

--region Data
function XUiEscape2Fuben:InitData(chapterId)
    self._ChapterId = chapterId
    self._EscapeData = XDataCenter.EscapeManager.GetEscapeData()
    self._CurLayerId = self._EscapeData:GetCurLayer()
end
--endregion

--region Text
function XUiEscape2Fuben:InitText()
    self.TxtTitle.text = XEscapeConfigs.GetChapterName(self._ChapterId)
    self.TxtDifficultyModel.text = XEscapeConfigs.GetDifficultyName(XEscapeConfigs.GetChapterDifficulty(self._ChapterId))
    self.TxtBuff.text = XUiHelper.ConvertLineBreakSymbol(XEscapeConfigs.GetChapterBuffDesc(self._ChapterId))
end

function XUiEscape2Fuben:InitBuff()
    self._GridFightEventDir = {}
    for index, fightEventId in ipairs(XEscapeConfigs.GetChapterShowFightEventIds(self._ChapterId)) do
        local go = XUiHelper.Instantiate(self.GridBuff.gameObject, self.PanelArchiveMonsterContent.transform)
        self._GridFightEventDir[index] = XUiGridFightEventBuff.New(go)
        self._GridFightEventDir[index]:Refresh(fightEventId)
    end
    self.GridBuff.gameObject:SetActiveEx(false)
end

function XUiEscape2Fuben:InitTime()
    -- 未挑战不显示时间
    self.PanelTime.gameObject:SetActiveEx(false)
end

function XUiEscape2Fuben:UpdateTime()
    self.PanelTime.gameObject:SetActiveEx(self:_IsChallenge())
    if not self:_IsChallenge() then
        return
    end
    local remainTime = self._EscapeData:GetRemainTime()
    self.TxtTime.text = XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.ESCAPE_REMAIN_TIME)
    if self.TxtUpperLimit then
        local maxTime = self._EscapeData:GetMaxRemainTime()
        if not XTool.IsNumberValid(maxTime) then
            maxTime = XEscapeConfigs.GetChapterMaxTime(self._ChapterId)
        end
        self.TxtUpperLimitTime.text = XUiHelper.GetTime(maxTime, XUiHelper.TimeFormatType.ESCAPE_REMAIN_TIME)
    end
end
--endregion

--region Stage
function XUiEscape2Fuben:InitStageDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelStageList)
    self.DynamicTable:SetProxy(XUiEscapeLayerPanel)
    self.DynamicTable:SetDelegate(self)
    
    self._LayerIdList = XEscapeConfigs.GetChapterLayerIds(self._ChapterId)
    self.DynamicTable:SetDataSource(self._LayerIdList)
    self.DynamicTable:ReloadDataSync(self:_GetLayerIndex(self._CurLayerId))

    self.GridStage.gameObject:SetActiveEx(false)
end

---@param grid XUiEscapeLayerPanel
function XUiEscape2Fuben:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local layerId = self._LayerIdList[index]
        grid.RootUi = self.RootUi
        grid:Refresh(layerId, index, self._ChapterId)
    end
end

function XUiEscape2Fuben:_GetLayerIndex(layerId)
    return table.indexof(self._LayerIdList, layerId)
end

function XUiEscape2Fuben:SelectStageLayer()
    local newLayerId = self._EscapeData:GetCurLayer()
    if not newLayerId or not self._CurLayerId and newLayerId == self._CurLayerId then
        return
    end
    if XTool.IsTableEmpty(self.DynamicTable:GetGrids()) then
        return
    end
    self._CurLayerId = newLayerId
    local layerIndex = self:_GetLayerIndex(newLayerId)
    
    self:UpdateStage()
    self.DynamicTable:ScrollToIndex(layerIndex, 0.5, function()
        XLuaUiManager.SetMask(true)
    end, function()
        XLuaUiManager.SetMask(false)
    end)
end

function XUiEscape2Fuben:UpdateStage()
    for index, grid in pairs(self.DynamicTable:GetGrids()) do
        local layerId = self.DynamicTable:GetData(index)
        grid:Refresh(layerId, index, self._ChapterId)
    end
end

function XUiEscape2Fuben:InitExitBtn()
    -- 未挑战不显示撤退
    self.BtnExit.gameObject:SetActiveEx(false)
end

function XUiEscape2Fuben:UpdateExitBtn()
    self.BtnExit.gameObject:SetActiveEx(self:_IsChallenge())
end
--endregion

--region Tactics
function XUiEscape2Fuben:InitTactics()
    -- 未挑战不显示策略
    self.PanelTactics.gameObject:SetActiveEx(false)
    ---@type XUiPanelTactics
    self._PanelTactics = XUiPanelTactics.New(self.PanelTactics)
end

function XUiEscape2Fuben:UpdateTactics()
    self.PanelTactics.gameObject:SetActiveEx(self:_IsChallenge())
    if not self:_IsChallenge() then
        return
    end
    self._PanelTactics:Refresh()
end
--endregion

--region Check
function XUiEscape2Fuben:_IsChallenge()
    return self._EscapeData and XTool.IsNumberValid(self._EscapeData:IsInChallengeChapter(self._ChapterId))
end
--endregion

--region BtnListener
function XUiEscape2Fuben:AddBtnClickListener()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    self:BindHelpBtn(self.BtnHelp, XEscapeConfigs.GetHelpKey())
    
    self:RegisterClickEvent(self.BtnExit, self.OnBtnExitClick)
end

function XUiEscape2Fuben:OnBtnExitClick()
    local title = XUiHelper.GetText("EscapeGiveUpTipsTitle")
    local content = XUiHelper.GetText("EscapeGiveUpTipsDesc")
    local sureCallback = function()
        XDataCenter.EscapeManager.RequestEscapeSettleChapter(function()
            XDataCenter.EscapeManager.OpenUiEscapeSettle(false)
        end)
    end
    XUiManager.DialogTip(title, content, nil, nil, sureCallback, nil)
end
--endregion