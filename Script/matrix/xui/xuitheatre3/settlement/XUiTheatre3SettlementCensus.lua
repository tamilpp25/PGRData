local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiTheatre3SettlementCensusCell = require("XUi/XUiTheatre3/Settlement/XUiTheatre3SettlementCensusCell")

---@class XUiTheatre3SettlementCensus : XUiNode 数据统计
---@field Parent XUiTheatre3Settlement
---@field _Control XTheatre3Control
local XUiTheatre3SettlementCensus = XClass(XUiNode, "XUiTheatre3SettlementCensus")

function XUiTheatre3SettlementCensus:OnStart()
    ---@type XUiTheatre3SettlementCensusCell[]
    self._Pool = {}
    self:InitComponent()
    self:InitCensusList()
    self:InitReward()
end

function XUiTheatre3SettlementCensus:InitComponent()
    ---@type XUiGridCommon
    self._RewardGrid = XUiGridCommon.New(self.Parent, self.Grid256New)
    self._RewardGrid:SetProxyClickFunc(function()
        XLuaUiManager.Open("UiTheatre3Tips", XEnumConst.THEATRE3.Theatre3OutCoin)
    end)
    self._Data = self._Control:GetSettleData()
end

function XUiTheatre3SettlementCensus:InitCensusList()
    local infos = self._Control:GetSettleFactorInfo()
    for k, v in ipairs(infos) do
        local grid = self._Pool[k]
        if not grid then
            local go = k == 1 and self.Data1 or XUiHelper.Instantiate(self.Data1, self.ListData)
            grid = XUiTheatre3SettlementCensusCell.New(go, self)
            self._Pool[k] = grid
        end
        grid:SetData(v.name, v.count, v.score)
    end
end

function XUiTheatre3SettlementCensus:InitReward()
    local hasReward = self._Data.BPExp > 0

    self.TxtEmpty.gameObject:SetActiveEx(not hasReward)
    self.Grid256New.gameObject:SetActiveEx(hasReward)
    self.PanelDrop.gameObject:SetActiveEx(hasReward)

    if hasReward then
        local reward = XRewardManager.CreateRewardGoods(XEnumConst.THEATRE3.Theatre3OutCoin, self._Data.BPExp)
        local difficultyCfg = self._Control:GetDifficultyById(self._Control:GetAdventureCurDifficultyId())
        self._RewardGrid:Refresh(reward)
        self.TxtDropNum.text = string.format("×%s", difficultyCfg.BPExpRate)
        if self.TxtEndNum then
            self.TxtEndNum.text = string.format("×%s", self._Data.EndFactor)
        end
        if self.TxtCountNum then
            self.TxtCountNum.text = string.format("×%s", self._Data.TotalScore)
        end
    end
end

return XUiTheatre3SettlementCensus