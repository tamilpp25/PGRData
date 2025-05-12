local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiBossInshotTip:XLuaUi
---@field private _Control XBossInshotControl
local XUiBossInshotTip = XLuaUiManager.Register(XLuaUi, "UiBossInshotTip")
local XUiGridScore = XClass(XUiNode, "XUiGridScore")

function XUiBossInshotTip:OnAwake()
    self.GridScore.gameObject:SetActiveEx(false)
    self:RegisterUiEvents()
    self:InitDynamicTable()
end

function XUiBossInshotTip:OnStart(fightIntToIntRecord)
    self.FightIntToIntRecord = fightIntToIntRecord
end

function XUiBossInshotTip:OnEnable()
    self:Refresh()
end

function XUiBossInshotTip:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnClose, self.Close)
end

function XUiBossInshotTip:Refresh()
    self.ScoreInfos = self:GetScoreInfos()
    self.DynamicTable:SetDataSource(self.ScoreInfos)
    self.DynamicTable:ReloadDataSync()
end

function XUiBossInshotTip:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.ScoreList)
    self.DynamicTable:SetProxy(XUiGridScore, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiBossInshotTip:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local info = self.ScoreInfos[index]
        grid:Refresh(info)
    end
end

-- 获取得分列表
function XUiBossInshotTip:GetScoreInfos()
    local scoreInfos = {}
    local scoreCfgs = self._Control:GetConfigBossInshotScore()
    for _, scoreCfg in pairs(scoreCfgs) do
        if scoreCfg.TipsDesc and scoreCfg.TipsScore then
            local value = self.FightIntToIntRecord[scoreCfg.Id] or 0
            local scoreInfo = { Id = scoreCfg.Id, Desc = scoreCfg.Desc, TipsDesc = scoreCfg.TipsDesc, TipsScore = scoreCfg.TipsScore, Order = scoreCfg.Order, Type = scoreCfg.Type, 
                    Value = value, Score = scoreCfg.Score }
            table.insert(scoreInfos, scoreInfo)
        end
    end

    -- 按照Order排序
    table.sort(scoreInfos, function(a, b)
        local isAGet = a.Value > 0 
        local isBGet = b.Value > 0
        if isAGet ~= isBGet then
            return isAGet
        end

        return a.Order < b.Order
    end)

    return scoreInfos
end

---------------------------------------- #region XUiGridScore ----------------------------------------
function XUiGridScore:Refresh(scoreInfo)
    local isGet = scoreInfo.Value > 0
    self.PanelGet.gameObject:SetActiveEx(isGet)
    self.PanelUnGet.gameObject:SetActiveEx(not isGet)
    if isGet then
        self.TxtTitle2.text = string.gsub(scoreInfo.Desc, "{0}", XUiHelper.GetLargeIntNumText(scoreInfo.Value))
        if scoreInfo.Type == XEnumConst.BOSSINSHOT.SCORE_TYPE.Add then
            local score = scoreInfo.Score * scoreInfo.Value / 10
            score = math.ceil(score)
            self.TxtScoreNum2.text = "+" .. tostring(score)

        elseif scoreInfo.Type == XEnumConst.BOSSINSHOT.SCORE_TYPE.MULTIPLY then
            local score = math.floor(scoreInfo.Score * scoreInfo.Value / 100) -- 小数点后最多保留2位小数
            self.TxtScoreNum2.text = "+"  .. tostring(score) .. "%"
        end
    else
        self.TxtTitle1.text = scoreInfo.TipsDesc
        self.TxtScoreNum1.text = scoreInfo.TipsScore
    end
end
---------------------------------------- #endregion XUiGridScore ----------------------------------------

return XUiBossInshotTip