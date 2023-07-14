local XPlanetCharacter = require("XEntity/XPlanet/Explore/XPlanetCharacter")

---@class XPlanetResult
local XPlanetResult = XClass(nil, "XPlanetResult")

function XPlanetResult:Ctor()
    self._Data = false
    self._Round = 0
    self._CharacterNew = {}
    self._Reward = {}
    self._IsWin = true
    self._StageId = false
    self._SettleType =XPlanetExploreConfigs.SETTLE_TYPE.Win
    self._IsPlayed = false
    self._IsFirstPass = false
end

function XPlanetResult:SetData(data)
    self._Data = data
    self._Round = XDataCenter.PlanetManager.GetStageData():GetCycle()
    self._CharacterNew = {}
    local characters = data.StageSettleData.UnlockCharacters
    for i = 1, #characters do
        local characterId = characters[i]
        ---@type XPlanetCharacter
        local character = XPlanetCharacter.New(characterId)
        self._CharacterNew[#self._CharacterNew + 1] = character
    end
    self._IsWin = data.IsWin
    self._StageId = data.StageId
    self._SettleType = data.SettleType
    self._Reward = data.StageSettleData.RewardGoodsList
end

function XPlanetResult:SetFirstPass()
    self._IsFirstPass = true
end

function XPlanetResult:GetFirstPass()
    return self._IsFirstPass
end

function XPlanetResult:GetRound()
    return self._Round
end

function XPlanetResult:GetCharacterUnlock()
    return self._CharacterNew
end

function XPlanetResult:GetReward()
    return self._Reward
end

function XPlanetResult:GetSettleType()
    return self._SettleType
end

function XPlanetResult:IsWin()
    return self._IsWin
end

function XPlanetResult:GetStageId()
    return self._StageId
end

function XPlanetResult:IsStageFinish()
    local settleType = self:GetSettleType()
    return settleType == XPlanetExploreConfigs.SETTLE_TYPE.StageFinish
            or settleType == XPlanetExploreConfigs.SETTLE_TYPE.Lose
end

function XPlanetResult:IsPlayed()
    return self._IsPlayed
end

function XPlanetResult:SetPlayed()
    self._IsPlayed = true
end

return XPlanetResult