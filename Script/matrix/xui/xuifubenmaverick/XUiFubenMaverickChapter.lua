local XUiFubenMaverickChapter = XLuaUiManager.Register(XLuaUi, "UiFubenMaverickChapter")
local XUiFubenMaverickStagePanel = require("XUi/XUiFubenMaverick/XUiScrollView/XUiFubenMaverickStagePanel")

function XUiFubenMaverickChapter:OnAwake()
    self:InitButtons()
    self:InitPanelAssets()
end

function XUiFubenMaverickChapter:OnStart(patternId)
    self.PatternId = patternId
    --初始化模式名
    self.TxtTitle.text = XDataCenter.MaverickManager.GetPatternName(self.PatternId)
    --初始化关卡面板
    self.StagePanel = XUiFubenMaverickStagePanel.New(self, self.PanelChapter, self.PatternId)
    --排行榜按钮设置状态
    self.BtnRank.gameObject:SetActiveEx(XDataCenter.MaverickManager.ContainRankStage(self.PatternId))
    
    local activityEndTime = XDataCenter.MaverickManager.GetEndTime()
    local patternEndTime = XDataCenter.MaverickManager.GetPatternEndTime(self.PatternId)
    if patternEndTime < activityEndTime then
        self:SetAutoCloseInfo(patternEndTime, function(isClose)
            if isClose then
                XDataCenter.MaverickManager.EndPattern(self.PatternId)
            end
        end, nil , 0)
    else
        self:SetAutoCloseInfo(activityEndTime, function(isClose)
            if isClose then
                XDataCenter.MaverickManager.EndActivity()
            end
        end, nil , 0)
    end
    
    if not XDataCenter.MaverickManager.GetPatternEnterFlag(patternId) then
        XDataCenter.MaverickManager.SetPatternEnterFlag(patternId)
    end
end

function XUiFubenMaverickChapter:OnEnable()
    self.Super.OnEnable(self)
    
    self:UpdateProcess()
    self.StagePanel:Refresh()
end

function XUiFubenMaverickChapter:InitButtons()
    self:BindHelpBtn(self.BtnHelp, "MaverickHelp")
    self.BtnBack.CallBack = function() self:Close() end
    self.BtnMainUi.CallBack = function() XLuaUiManager.RunMain() end
    self.BtnRank.CallBack = function() XLuaUiManager.Open("UiFubenMaverickRank") end
end

function XUiFubenMaverickChapter:InitPanelAssets()
    XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem,
            XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
end

function XUiFubenMaverickChapter:UpdateProcess()
    local current, max = XDataCenter.MaverickManager.GetPatternProgress(self.PatternId)
    self.TxtProcess.text = current
    self.TxtProcessMax.text = "/" .. max
end