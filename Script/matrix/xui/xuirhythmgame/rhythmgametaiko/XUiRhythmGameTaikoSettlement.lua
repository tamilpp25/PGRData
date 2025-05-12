---@field _Control XRhythmGameControl
---@class XUiRhythmGameTaikoSettlement : XLuaUi
local XUiRhythmGameTaikoSettlement = XLuaUiManager.Register(XLuaUi, "UiRhythmGameTaikoSettlement")

function XUiRhythmGameTaikoSettlement:OnAwake()
    self:InitButton()
end

function XUiRhythmGameTaikoSettlement:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnConfirm, self.Close)
end

--- func desc
---@param allFinishXNote XRhythmGameNote[]
function XUiRhythmGameTaikoSettlement:OnStart(mapId, scoreData)
    self.MapId = mapId
    self.MapName = "Map".. self.MapId
    self.ScoreData = scoreData
    self:RefreshUiShow()
end

function XUiRhythmGameTaikoSettlement:RefreshUiShow()
    local mapConfig = self._Control:GetModelRhythmGameTaikoMapConfig(self.MapName)
    self.TxtMapName.text = mapConfig["Title"].Value
    self.TxtRating.text = self.ScoreData.rankString
    self.TxtPerfectCount.text = self.ScoreData.perfectCount
    self.TxtGoodCount.text = self.ScoreData.goodCount
    self.TxtMissCount.text = self.ScoreData.missCount
    self.TxtMaxComboCount.text = self.ScoreData.maxCombo

    -- 埋点
    self._Control:BuryingRhythmScore(self.MapId, self.ScoreData)
end