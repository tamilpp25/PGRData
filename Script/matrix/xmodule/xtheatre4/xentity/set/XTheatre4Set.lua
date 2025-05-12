local XTheatre4Character = require("XModule/XTheatre4/XEntity/Set/XTheatre4Character")

---@class XTheatre4Set
local XTheatre4Set = XClass(nil, "XTheatre4Set")

function XTheatre4Set:Ctor()
    ---@type XTheatre4Difficulty
    self._Difficulty = false

    ---@type XTheatre4Difficulty[]
    self._AllDifficulty = false

    ---@type XTheatre4Affix[]
    self._AllAffix = false

    ---@type XTheatre4Character[]
    self._Character = {}

    ---@type XTheatre4Character[]
    self._HireCharacterList = {}
end

function XTheatre4Set:InitAllDifficulty(allDifficulty)
    self._AllDifficulty = allDifficulty
end

function XTheatre4Set:InitAllAffix(affix)
    self._AllAffix = affix
end

function XTheatre4Set:SetDifficulty(difficulty)
    self._Difficulty = difficulty
end

function XTheatre4Set:Start()
    if not self._Difficulty then
        XLog.Error("[XTheatre4Set] 未选择难度")
        return
    end
end

---@param collection XTheatre4Collection
function XTheatre4Set:SelectCollection(collection)

end

function XTheatre4Set:NextStep()

end

function XTheatre4Set:SetCurrentDifficulty(difficulty)
    self._Difficulty = difficulty
end

function XTheatre4Set:GetCurrentDifficulty()
    return self._Difficulty
end

function XTheatre4Set:GetAllDifficulty()
    return self._AllDifficulty
end

function XTheatre4Set:GetDifficultyByIndex(index)
    return self._AllDifficulty[index]
end

function XTheatre4Set:GetAllAffix()
    return self._AllAffix
end

---@param model XTheatre4Model
function XTheatre4Set:GetCharacter(memberId, model)
    if not self._Character[memberId] then
        local config = model:GetCharacterConfigById(memberId)
        if config then
            ---@type XTheatre4Character
            local character = XTheatre4Character.New()
            character:SetFromConfig(config)
            self._Character[memberId] = character
        end
    end
    return self._Character[memberId]
end

---@param character XTheatre4Character
function XTheatre4Set:FireCharacter(character)
    for i = 1, #self._HireCharacterList do
        local selectedCharacter = self._HireCharacterList[i]
        if selectedCharacter:Equals(character) then
            table.remove(self._HireCharacterList, i)
            return
        end
    end
end

---@param character XTheatre4Character
function XTheatre4Set:HireCharacter(character)
    if not character then
        XLog.Error("[XTheatre4Set] 雇佣空气")
        return
    end
    for i = 1, #self._HireCharacterList do
        local selectedCharacter = self._HireCharacterList[i]
        if selectedCharacter:Equals(character) then
            XLog.Error("[XTheatre4Set] 重复雇佣角色", character:GetId())
            return
        end
    end

    if #self._HireCharacterList >= XEnumConst.FuBen.PlayerAmount then
        XLog.Error("[XTheatre4Set] 雇佣角色达到数量上限", #self._HireCharacterList)
        return
    end

    table.insert(self._HireCharacterList, character)
end

function XTheatre4Set:GetHireCharacterList()
    return self._HireCharacterList
end

---@param model XTheatre4Model
function XTheatre4Set:GetMaxSelectNum(ticketId, model)
    local selectNum = model:GetRecruitTicketSelectNumById(ticketId)
    if not selectNum then
        return 0
    end
    return selectNum
end

return XTheatre4Set

--难度界面 08;
--开局效果 09;
--招募成员 10;
--藏品继承 11;

--天赋界面 18;
--线路总览 19;