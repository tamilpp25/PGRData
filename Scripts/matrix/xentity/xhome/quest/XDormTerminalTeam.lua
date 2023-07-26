local tableInsert = table.insert
local pairs = pairs
local tableSort = table.sort

---@class XDormTerminalTeam
local XDormTerminalTeam = XClass(nil, "XDormTerminalTeam")

function XDormTerminalTeam:Ctor()
    self.TeamQuest = {}
    self.TeamLimitCount = 0
    self.DispatchCharacter = {} --已派遣成员
end

-- 设置终端队伍最大数量值
function XDormTerminalTeam:InitTeamLimit(teamCount)
    self.TeamLimitCount = teamCount
end

-- 已接取委托 （会有相同的委托被接取，保存下标信息）
function XDormTerminalTeam:UpdateTeamData(questAccepts)
    for _, quest in pairs(questAccepts) do
        if not quest:IsAward() and self:CheckHaveNewPos() then
            tableInsert(self.TeamQuest, quest)
            local teamCharacters = quest:GetTeamCharacter()
            for _, characterId in pairs(teamCharacters or {}) do
                self.DispatchCharacter[characterId] = characterId
            end
        end
    end
end

-- 检查有没有空格子
function XDormTerminalTeam:CheckHaveNewPos()
    local curLevelTeamCount = self:GetCurLevelTeamCount()
    return curLevelTeamCount - #self.TeamQuest > 0
end

-- 获取空闲栏位数量
function XDormTerminalTeam:GetFreeTeamPosCount()
    local curLevelTeamCount = self:GetCurLevelTeamCount()
    local count = curLevelTeamCount - #self.TeamQuest
    if count < 0 then
        count = 0
    end
    return count
end

-- 检查是否是派遣中成员
function XDormTerminalTeam:CheckDispatchCharacter(characterId)
    return self.DispatchCharacter[characterId] and true or false
end

function XDormTerminalTeam:ClearTeamData()
    self.TeamQuest = {}
    self.DispatchCharacter = {}
end

-- 获取终端队伍列表
function XDormTerminalTeam:GetTerminalTeamList()
    local teamList = {}
    -- 已领取的委托
    for _, data in pairs(self.TeamQuest) do
        tableInsert(teamList, { QuestAccept = data })
    end
    -- 队伍排序  可领取 > 派遣中  同状态下按照委托等级顺序进行排序
    tableSort(teamList, function(a, b)
        local stateA = XDataCenter.DormQuestManager.GetQuestAcceptTeamState(a.QuestAccept)
        local stateB = XDataCenter.DormQuestManager.GetQuestAcceptTeamState(b.QuestAccept)
        local qualityA = self:GetDormQuestQuality(a.QuestAccept)
        local qualityB = self:GetDormQuestQuality(b.QuestAccept)
        if stateA ~= stateB then
            return stateA < stateB
        end
        if qualityA ~= qualityB then
            return qualityA > qualityB
        end
        return a.QuestAccept:GetQuestId() < b.QuestAccept:GetQuestId()
    end)
    -- 空闲数据
    local curLevelTeamCount = self:GetCurLevelTeamCount()
    for _ = #self.TeamQuest + 1, curLevelTeamCount do
        tableInsert(teamList, { State = XDormQuestConfigs.TerminalTeamState.Empty })
    end
    -- Lock数据
    for _ = curLevelTeamCount + 1, self.TeamLimitCount do
        tableInsert(teamList, { State = XDormQuestConfigs.TerminalTeamState.Lock })
    end

    return teamList
end

-- 获取当前终端等级队伍栏位数
function XDormTerminalTeam:GetCurLevelTeamCount()
    ---@type XDormQuestTerminal
    local terminalViewModel = XDataCenter.DormQuestManager.GetCurLevelTerminalViewModel()
    return terminalViewModel:GetQuestTerminalTeamCount()
end

-- 获取委托等级
---@param questAccept XDormQuestAcceptInfo
function XDormTerminalTeam:GetDormQuestQuality(questAccept)
    ---@type XDormQuest
    local dormQuestViewModel = XDataCenter.DormQuestManager.GetDormQuestViewModel(questAccept:GetQuestId())
    return dormQuestViewModel:GetQuestQuality()
end

return XDormTerminalTeam