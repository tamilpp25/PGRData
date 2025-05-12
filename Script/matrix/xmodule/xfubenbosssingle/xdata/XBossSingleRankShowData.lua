local XBossSingleRankCharacter = require("XModule/XFubenBossSingle/XData/XBossSingleRankCharacter")

---@class XBossSingleRankShowData
local XBossSingleRankShowData = XClass(nil, "XBossSingleRankShowData")

function XBossSingleRankShowData:Ctor(data)
    self:SetData(data)
end

function XBossSingleRankShowData:SetData(data)
    if data then
        self._Id = data.Id
        self._Name = data.Name
        self._HeadPortraitId = data.HeadPortraitId
        self._HeadFrameId = data.HeadFrameId
        self._RankNumber = data.RankNum
        self._Score = data.Score
        ---@type XBossSingleRankCharacter[]
        self._CharacterList = self._CharacterList or {}

        for i, character in pairs(data.CharacterList) do
            local rankCharacter = self._CharacterList[i]

            if rankCharacter then
                rankCharacter:SetData(character)
            else
                self._CharacterList[i] = XBossSingleRankCharacter.New(character)
            end
        end
        for i = #self._CharacterList + 1, #data.CharacterList do
            self._CharacterList[i] = nil
        end
    end
end

function XBossSingleRankShowData:GetId()
    return self._Id
end

function XBossSingleRankShowData:GetName()
    return self._Name
end

function XBossSingleRankShowData:GetHeadPortraitId()
    return self._HeadPortraitId
end

function XBossSingleRankShowData:GetHeadFrameId()
    return self._HeadFrameId
end

function XBossSingleRankShowData:GetRankNumber()
    return self._RankNumber
end

function XBossSingleRankShowData:GetScore()
    return self._Score
end

---@return XBossSingleRankCharacter[]
function XBossSingleRankShowData:GetCharacterList()
    return self._CharacterList
end

---@return XBossSingleRankCharacter
function XBossSingleRankShowData:GetCharacterByIndex(index)
    return self._CharacterList[index]
end

function XBossSingleRankShowData:GetCharacterListCount()
    return #self._CharacterList
end

return XBossSingleRankShowData