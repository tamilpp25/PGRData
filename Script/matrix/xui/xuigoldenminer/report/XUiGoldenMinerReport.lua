local XUiReportGrid = require("XUi/XUiGoldenMiner/Report/XUiReportGrid")

--黄金矿工结算界面
local XUiGoldenMinerReport = XLuaUiManager.Register(XLuaUi, "UiGoldenMinerReport")

function XUiGoldenMinerReport:OnAwake()
    self.DataDb = XDataCenter.GoldenMinerManager.GetGoldenMinerDataDb()
    self:RegisterButtonEvent()
    self.PanelReport.gameObject:SetActiveEx(false)
    self.TotalReportGrid.gameObject:SetActiveEx(false)
end

function XUiGoldenMinerReport:OnStart(data, closeCb, isCloseFunc)
    self.CloseCb = closeCb
    self.IsCloseFunc = isCloseFunc
    local curStageId = data.CurStageId          --GoldenMinerStage表的Id
    local curMapId = data.CurMapId              --GoldenMinerMap表的Id
    local curStageIndex = data.CurStageIndex    --第几关
    local goldenMinerObjectList = data.GoldenMinerObjectList  --当前地图拉回物品列表
    local beforeScore = data.BeforeScore        --进地图前的积分
    local curMapScore = data.CurMapScore        --当前积分
    local differScore = curMapScore - beforeScore --积分插值
    local targetScore = data.TargetScore        --目标积分

    local reportObjDic = {}
    for i, goldenMinerObj in ipairs(goldenMinerObjectList) do
        local stoneType = goldenMinerObj:GetType()
        if not reportObjDic[stoneType] then
            reportObjDic[stoneType] = {}
            reportObjDic[stoneType].Count = 0
            reportObjDic[stoneType].Score = 0
        end
        reportObjDic[stoneType].Count = reportObjDic[stoneType].Count + 1
        reportObjDic[stoneType].Score = reportObjDic[stoneType].Score + goldenMinerObj:GetScore()
    end

    --拉回物品汇总
    self.TxtRound.text = XUiHelper.GetText("GoldenMinerCurStage", curStageIndex)
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

    --总计分数
    local totalReportGrid = XUiReportGrid.New(self.TotalReportGrid)
    totalReportGrid:Refresh({
        Icon = XGoldenMinerConfigs.GetScoreIcon(),
        TxtScore = XUiHelper.GetText("GoldenMinerReqportTotalScore", differScore)
    })

    self.TxtScore.text = XUiHelper.GetText("GoldenMinerReqportScore", curMapScore, targetScore, differScore)
    self.ImgScoreProgress.fillAmount = curMapScore / targetScore

    --是否通关
    local isClear = curMapScore >= targetScore
    self.ImgVictory.gameObject:SetActiveEx(isClear)
    self.ImgFail.gameObject:SetActiveEx(not isClear)
    self:PlayAnimation("PanelReportEnable")
end

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