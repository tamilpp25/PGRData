local BasePanel = require("XUi/XUiSuperTower/Common/XUiSTChildPanel")
--==================
--超级爬塔 爬塔 结算界面分数面板控件
--==================
local XUiStTsScorePanel = XClass(BasePanel, "XUiStTsScorePanel")

function XUiStTsScorePanel:InitPanel()
    self:InitGrids()
end

function XUiStTsScorePanel:InitGrids()
    self.GridScoreItem.gameObject:SetActiveEx(false)
    self.ScoreItems = {}
    local allScoreItemCfg = XSuperTowerConfigs.GetAllTierScoreRatioCfg()
    local itemScript = require("XUi/XUiSuperTower/Stages/Tier/XUiStTsScoreItem")
    for id, _ in pairs(allScoreItemCfg) do
        local newItemGo = CS.UnityEngine.Object.Instantiate(self.GridScoreItem.gameObject, self.GridContent)
        self.ScoreItems[id] = itemScript.New(newItemGo, id)
        self.ScoreItems[id]:Show()
    end
end

function XUiStTsScorePanel:OnShowPanel()
    self.TxtMaxScore.text = self.RootUi.Theme:GetTierMaxScore()
    self.TxtHistoryScore.text = 0
    self:StartTween()
    --self:SetGrids()
    --self:SetTotalScore()
end

function XUiStTsScorePanel:StartTween()
    local time = CS.XGame.ClientConfig:GetFloat("SuperTowerTierSettleAnimeTime")
    local ScoreType = XDataCenter.SuperTowerManager.ScoreType
    self.ScoreValue = {}
    for key, value in pairs(ScoreType) do
        self.ScoreValue[value] = {}
        local count, score = self.RootUi.Theme:GetTierScoreCountByScoreType(value)
        self.ScoreValue[value].Count = count
        self.ScoreValue[value].Score = score
    end
    local totalScore = 0
    for _, data in pairs(self.ScoreValue) do
        totalScore = totalScore + data.Score
    end
    self.AudioInfo = CS.XAudioManager.PlaySound(XSoundManager.UiBasicsMusic.UiSettle_Win_Number)
    XLuaUiManager.SetMask(true)
    self.Timer = XUiHelper.Tween(time, function(f)
            if XTool.UObjIsNil(self.RootUi.Transform) then
                return
            end

            for _, value in pairs(ScoreType) do
                self.ScoreItems[value]:Refresh(self.ScoreValue[value].Count, math.floor(f * self.ScoreValue[value].Score))
            end
            self:SetTotalScore(math.floor(f * totalScore))
        end, function()
            self:StopAudio()
            self.TxtHistoryScore.text = self.RootUi.Theme:GetHistoryTierScore()
            XLuaUiManager.SetMask(false)
            self.RootUi:CheckPluginSyn()
        end)
end

--[[function XUiStTsScorePanel:SetGrids()
    ScoreType = XDataCenter.SuperTowerManager.ScoreType
    for _, value in pairs(ScoreType) do
        self.ScoreItems[value]:Refresh(self.RootUi.Theme:GetTierScoreCountByScoreType(value))
    end
end]]

function XUiStTsScorePanel:SetTotalScore(totalScore)
    self.TxtTotalScore.text = totalScore   
end

function XUiStTsScorePanel:StopAudio()
    if self.AudioInfo then
        self.AudioInfo:Stop()
    end
end

function XUiStTsScorePanel:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiStTsScorePanel:OnDestroy()
    self:StopTimer()
end

return XUiStTsScorePanel