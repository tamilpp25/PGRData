local XUiReportGrid = require("XUi/XUiGoldenMiner/Report/XUiReportGrid")
local XUiReportHideTaskGrid = require("XUi/XUiGoldenMiner/Report/XUiReportHideTaskGrid")

---黄金矿工结算界面
---@class XUiGoldenMinerReport : XLuaUi
local XUiGoldenMinerReport = XLuaUiManager.Register(XLuaUi, "UiGoldenMinerReport")

function XUiGoldenMinerReport:OnAwake()
    self:RegisterButtonEvent()
    self.PanelReport.gameObject:SetActiveEx(false)
    self.TotalReportGrid.gameObject:SetActiveEx(false)

    self:InitHideTask()
    self.TxtFail = XUiHelper.TryGetComponent(self.PanelAsset.parent, "TxtFail")
end

---@param data XGoldenMinerReportInfo
function XUiGoldenMinerReport:OnStart(data, closeCb, isCloseFunc)
    self.CloseCb = closeCb
    self.IsCloseFunc = isCloseFunc
    self._ReportData = data
    
    self:UpdateGrabbedShow()
    self:UpdateTimeScore()
    self:UpdateAllScore()
    self:UpdateHideTask()
    self:UpdateWinStatus()
end

--region Ui - GrabbedShow
---展示拉回物品汇总
function XUiGoldenMinerReport:UpdateGrabbedShow()
    local reportObjDic = {}
    self.TxtRound.text = XUiHelper.GetText("GoldenMinerCurStage", self._ReportData:GetStageIndex())
    if XTool.IsTableEmpty(self._ReportData:GetGrabObjList()) then
        self.PanelAsset.gameObject:SetActiveEx(false)
        if self.TxtFail then
            self.TxtFail.gameObject:SetActiveEx(true)
        end
        return
    end
    self.PanelAsset.gameObject:SetActiveEx(true)
    if self.TxtFail then
        self.TxtFail.gameObject:SetActiveEx(false)
    end
    for _, stoneEntity in ipairs(self._ReportData:GetGrabObjList()) do
        local stoneType = stoneEntity.Data:GetType()
        if stoneType == XGoldenMinerConfigs.StoneType.Mussel and stoneEntity.CarryStone then
            stoneType = stoneEntity.CarryStone.Data:GetType()
        end
        if stoneType ~= XGoldenMinerConfigs.StoneType.AddTimeStone
                and stoneType ~= XGoldenMinerConfigs.StoneType.ItemStone
        then
            if not reportObjDic[stoneType] then
                reportObjDic[stoneType] = {}
                reportObjDic[stoneType].Count = 0
                reportObjDic[stoneType].Score = 0
            end
            reportObjDic[stoneType].Count = reportObjDic[stoneType].Count + 1
            reportObjDic[stoneType].Score = math.floor(self._ReportData:GetGrabObjScoreDir()[stoneType])
        end
    end
    
    local index = 0
    for type, reportObj in pairs(reportObjDic) do
        index = index + 1
        local panelReport = index == 1 and self.PanelReport or XUiHelper.Instantiate(self.PanelReport, self.PanelAsset)
        local reportGrid = XUiReportGrid.New(panelReport)
        reportGrid:Refresh({
            Icon = XGoldenMinerConfigs.GetStoneTypeIcon(type),
            TxtScore = XUiHelper.GetText("GoldenMinerReqportObjScore", reportObj.Count, reportObj.Score)
        })
    end
end
--endregion

--region Ui - Time
---展示剩余时间结算
function XUiGoldenMinerReport:UpdateTimeScore()
    local timeTxt = string.format("%02d:%02d", math.floor(self._ReportData:GetLastTime() / 60), self._ReportData:GetLastTime() % 60)
    --（3.0移除时间分数）
    --self.TxtTimeScore.text = XUiHelper.GetText("GoldenMinerReqportObjScore", timeTxt, self._ReportData:GetLastTimeScore())
    self.TxtTimeScore.text = timeTxt
end
--endregion

--region Ui - AllScore
---展示总计分数
function XUiGoldenMinerReport:UpdateAllScore()
    ---@type XUiReportGrid
    local totalReportGrid = XUiReportGrid.New(self.TotalReportGrid)
    totalReportGrid:Refresh({
        Icon = XGoldenMinerConfigs.GetScoreIcon(),
        TxtScore = XUiHelper.GetText("GoldenMinerReqportTotalScore", self._ReportData:GetMapAddScore())
    })

    self.TxtScore.text = XUiHelper.GetText("GoldenMinerReqportScore",
            self._ReportData:GetMapScore(),
            self._ReportData:GetTargetScore(),
            self._ReportData:GetMapAddScore())
    self.ImgScoreProgress.fillAmount = self._ReportData:GetMapScore() / self._ReportData:GetTargetScore()
end
--endregion

--region Ui - WinStatus
function XUiGoldenMinerReport:UpdateWinStatus()
    --是否通关
    self.ImgVictory.gameObject:SetActiveEx(self._ReportData:IsWin())
    self.ImgFail.gameObject:SetActiveEx(not self._ReportData:IsWin())
    --结算赛利卡表情包
    local settleEmoji = XGoldenMinerConfigs.GetSettleEmoji(self._ReportData:IsWin())
    if not string.IsNilOrEmpty(settleEmoji) and self.RImg03 then
        self.RImg03:SetRawImage(settleEmoji)
    end
    self:PlayAnimation("PanelReportEnable")
end
--endregion

--region Ui - HideTask
function XUiGoldenMinerReport:InitHideTask()
    ---@type XUiReportHideTaskGrid[]
    self.HideTaskObjDir = {}
    local hideTaskUiObjCount = XGoldenMinerConfigs.GetReportShowHideTaskCount()
    
    for i = 1, hideTaskUiObjCount do
        local grid = XUiHelper.Instantiate(self.ImgZhua01.gameObject, self.ImgZhua01.transform.parent)
        self.HideTaskObjDir[i] = XUiReportHideTaskGrid.New(grid)
    end
    self.ImgZhua01.gameObject:SetActiveEx(false)
end

function XUiGoldenMinerReport:UpdateHideTask()
    local dataDb = XDataCenter.GoldenMinerManager.GetGoldenMinerDataDb()
    local hideTaskCount = dataDb:GetFinishHideTaskCount()
    if hideTaskCount <= 0 or not self._ReportData:IsWin() then
        for _, grid in ipairs(self.HideTaskObjDir) do
            grid.GameObject:SetActiveEx(false)
        end
        return
    end
    for i, grid in ipairs(self.HideTaskObjDir) do
        grid:Refresh(hideTaskCount >= i)
    end
end
--endregion

--region Ui - BtnListener
function XUiGoldenMinerReport:RegisterButtonEvent()
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnEnter, self.OnBtnCloseClick)
end

function XUiGoldenMinerReport:OnBtnCloseClick()
    if not self.IsCloseFunc or self.IsCloseFunc() then
        self:Close()
        self.CloseCb()
    end
end
--endregion