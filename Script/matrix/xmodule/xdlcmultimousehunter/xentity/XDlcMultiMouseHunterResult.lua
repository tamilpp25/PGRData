local XDlcMultiMouseHunterCampResult = require("XModule/XDlcMultiMouseHunter/XEntity/XDlcMultiMouseHunterCampResult")

---@class XDlcMultiMouseHunterResult
local XDlcMultiMouseHunterResult = XClass(nil, "XDlcMultiMouseHunterResult")

local Camp = {
    Cat = 1,
    Mouse = 2,
}

function XDlcMultiMouseHunterResult:Ctor(resultData, isEarly, worldId, levelId)
    self:SetData(resultData, isEarly, worldId, levelId)
end

function XDlcMultiMouseHunterResult:SetData(resultData, isEarly, worldId, levelId)
    if resultData then
        local catCampList = resultData.OffensiveCampRank
        local mouseCampList = resultData.DefendCampRank

        self._Camp = resultData.Camp
        self._IsWin = resultData.IsWin
        self._IsMvp = resultData.IsMvp
        self._Score = resultData.Score
        self._EliminatePlayers = self:IsCatCamp() and resultData.Param or 0
        self._SurvivalTime = self:IsMouseCamp() and resultData.Param or 0
        self._CurrencyReward = resultData.CurrencyReward
        self._CurrentCurrencyReward = resultData.CurrentCurrencyReward or 0
        self._TitleReward = resultData.TitleReward
        self._WinCamp = resultData.WinCamp
        self._IsEarlySettlement = isEarly
        self._WorldId = worldId
        self._LevelId = levelId
        ---@type XDlcMultiMouseHunterCampResult[]
        self._CatCampResultList = {}
        ---@type XDlcMultiMouseHunterCampResult[]
        self._MouseCampResultList = {}

        if not XTool.IsTableEmpty(catCampList) then
            for i, catData in ipairs(catCampList) do
                self._CatCampResultList[i] = XDlcMultiMouseHunterCampResult.New(catData)
            end
        end
        if not XTool.IsTableEmpty(mouseCampList) then
            for i, mouseData in ipairs(mouseCampList) do
                self._MouseCampResultList[i] = XDlcMultiMouseHunterCampResult.New(nil, mouseData)
            end
        end
        table.sort(self._CatCampResultList, function(catA, catB)
            if catA:GetRank() == 0 then
                return false
            elseif catB:GetRank() == 0 then
                return true
            end

            return catA:GetRank() < catB:GetRank()
        end)
        table.sort(self._MouseCampResultList, function(mouseA, mouseB)
            if mouseA:GetRank() == 0 then
                return false
            elseif mouseB:GetRank() == 0 then
                return true
            end

            return mouseA:GetRank() < mouseB:GetRank()
        end)
    end
end

function XDlcMultiMouseHunterResult:GetEliminatePlayerCount()
    return self._EliminatePlayers
end

function XDlcMultiMouseHunterResult:GetScore()
    return self._Score
end

function XDlcMultiMouseHunterResult:GetTitleRewards()
    return self._TitleReward
end

function XDlcMultiMouseHunterResult:GetCurrencyReward()
    return self._CurrencyReward
end

function XDlcMultiMouseHunterResult:GetCurrentCurrencyReward()
    return self._CurrentCurrencyReward
end

function XDlcMultiMouseHunterResult:GetIsMvp()
    return self._IsMvp
end

---@return XDlcMultiMouseHunterCampResult[]
function XDlcMultiMouseHunterResult:GetCatCampResultList()
    return self._CatCampResultList
end

---@return XDlcMultiMouseHunterCampResult[]
function XDlcMultiMouseHunterResult:GetMouseCampResultList()
    return self._MouseCampResultList
end

function XDlcMultiMouseHunterResult:IsCatCamp()
    return self._Camp == Camp.Cat
end

function XDlcMultiMouseHunterResult:IsMouseCamp()
    return self._Camp == Camp.Mouse
end

function XDlcMultiMouseHunterResult:GetIsWin()
    return self._IsWin
end

function XDlcMultiMouseHunterResult:GetIsEarlySettlement()
    return self._IsEarlySettlement
end

function XDlcMultiMouseHunterResult:GetCamp()
    return self._Camp
end

function XDlcMultiMouseHunterResult:GetSurvivalTime()
    return self._SurvivalTime
end

function XDlcMultiMouseHunterResult:GetWorldId()
    return self._WorldId
end

function XDlcMultiMouseHunterResult:GetLevelId()
    return self._LevelId
end

function XDlcMultiMouseHunterResult:GetIsCatCampWin()
    return self._WinCamp == Camp.Cat
end

function XDlcMultiMouseHunterResult:GetIsMouseCampWin()
    return self._WinCamp == Camp.Mouse
end

function XDlcMultiMouseHunterResult:GetIsSelfCampWin()
    return self._Camp == self._WinCamp
end

return XDlcMultiMouseHunterResult
