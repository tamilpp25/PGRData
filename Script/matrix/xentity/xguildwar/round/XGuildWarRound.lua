--============
--公会战轮次控制
--============
local XGuildWarRound = XClass(nil, "XGuildWarRound")
local Manager
--===============
--创建战斗管理器
--===============
local function CreateBattleManager(difficultId)
    local manager = require("XEntity/XGuildWar/Battle/XGWBattleManager")   
    return manager.New(difficultId)
end

function XGuildWarRound:Ctor(roundId)
    if not Manager then
        Manager = XDataCenter.GuildWarManager
    end
    self.RoundId = roundId
    --若完全没登陆，会没有MyRoundData
    self.HaveMyRoundData = false
end

function XGuildWarRound:RefreshRoundData(roundData)
    self.Difficulty = roundData.DifficultyId
    self.IsSkipRound = roundData.SkipRound == 1 --SkipRound为1时表示跳过，为0时可以参与
    self.TotalActivation = roundData.TotalActivation or 0
    self.TotalPoint = roundData.TotalPoint or 0
    if not self.BattleManager then
        self.BattleManager = CreateBattleManager(roundData.DifficultyId)
    end
    self.BattleManager:UpdateCurrentRoundData(roundData)
end

function XGuildWarRound:UpdateMyRoundData(myRoundData)
    self.HaveMyRoundData = true
    if XDataCenter.GuildManager.GetGuildId() ~= myRoundData.GuildId then
        self.ChangeGuild = true
        if myRoundData.SkipRound == 0 then
            self.NoTaskSkipRound = true
            self.OldDifficultyId = myRoundData.DifficultyId
        end
        return
    end
    if self.Difficulty > 0 and XDataCenter.GuildManager.GetGuildId() == myRoundData.GuildId
        and myRoundData.DifficultyId == 0 then
        self.GuildId = myRoundData.GuildId
        self.IsMySkipRound = true
        return
    end
    self.GuildId = myRoundData.GuildId
    self.IsMySkipRound = myRoundData.SkipRound == 1
    --也有玩家在不同工会时保留的数据和最后的公会数据不一致的情况，这时可能导致从RoundData中没有创建BattleManager
    if not self.BattleManager then
        self.BattleManager = CreateBattleManager(myRoundData.DifficultyId)
    end
    self.BattleManager:UpdateMyRoundData(myRoundData)
end

function XGuildWarRound:SetSettleData(settleData)
    self.SettleData = settleData
end

function XGuildWarRound:GetGuildId()
    return self.GuildId or 0
end

function XGuildWarRound:GetIsPass()
    return self.SettleData and self.SettleData.IsPass
end
--===============
--获取现公会选择的轮次难度
--===============
function XGuildWarRound:GetDifficulty()
    return self.Difficulty and self.Difficulty > 0 and self.Difficulty or 1
end
--===============
--获取我参与的轮次难度(可能来源于旧公会)
--===============
function XGuildWarRound:GetMyDifficulty()
    if self.ChangeGuild then
        return self.OldDifficultyId
    else
        local myData = self:GetMyRoundData()
        return myData and myData.DifficultyId
    end
end

function XGuildWarRound:GetBattleManager()
    return self.BattleManager
end
--===============
--获取公会的轮次跳过情况
--===============
function XGuildWarRound:CheckIsSkipRound()
    return self.IsSkipRound
end
--===============
--检查是否有玩家轮次数据(没有表示玩家在此期间没有工会或没有进入过公会战)
--===============
function XGuildWarRound:CheckHaveMyRoundData()
    return self.HaveMyRoundData
end

function XGuildWarRound:CheckIsChangeGuild()
    return self.ChangeGuild
end

function XGuildWarRound:CheckIsTaskNotShow()
    if self.ChangeGuild then
        return not self.NoTaskSkipRound
    else
        --任务显示中的跳过只参照玩家本身跳过情况，不用参考公会跳过情况
        --只有玩家本身非跳过的情况才会显示任务
        return (not self:CheckHaveMyRoundData()) or (self:CheckIsMySkipRound())
    end
end
--===============
--获取我的轮次跳过情况
--===============
function XGuildWarRound:CheckIsMySkipRound()
    --没有轮次数据说明没有参与此轮，也视为跳过
    if self.IsMySkipRound == nil then
        return true
    end
    return self.IsMySkipRound
end
--===============
--获取我的轮次数据
--===============
function XGuildWarRound:GetMyRoundData()
    return self.BattleManager and self.BattleManager:GetCurrentMyRoundData()
end

function XGuildWarRound:GetTotalActivation()
    return self.TotalActivation or 0
end

function XGuildWarRound:GetTotalPoint()
    return self.TotalPoint or 0
end

function XGuildWarRound:UpdateFightRecords(fightRecords)
    if self.BattleManager then
        self.BattleManager:UpdateFightRecords(fightRecords)
    end
end

function XGuildWarRound:UpdateLastActionIdDic(actionIdList)
    if self.BattleManager then
        self.BattleManager:UpdateShowedActionIdDic(actionIdList)
    end
end

return XGuildWarRound