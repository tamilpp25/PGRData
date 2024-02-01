local type = type
local pairs = pairs
local EXAMINE_STATUS = XTRPGConfigs.ExmaineStatus

local Default = {
    __Id = 0,
    __ActionId = 0,
    __PunishId = 0,
    __Round = 0,
    __MaxRound = 0,
    __TotalScore = 0,
    __ReqScore = 0,
    __RoleScoreDic = {},
    __Status = EXAMINE_STATUS.Dead,
    __MovieId = "",
}

--不同结果对应剧情结局
local MOVIEINDEX = {
    [EXAMINE_STATUS.Suc] = 1,
    [EXAMINE_STATUS.Fail] = 2,
}

local XTRPGExamine = XClass(nil, "XTRPGExamine")

function XTRPGExamine:Ctor()
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
end

function XTRPGExamine:Start(examineId, actionId)
    if not self:CheckStatus(EXAMINE_STATUS.Dead) then
        XLog.Error("XTRPGExamine:Start error:跑团玩法尚有未处理完的检定数据, examineId: " .. self.__Id .. ", examineStatus: " .. self.__Status)
    end

    self:Clear()

    self.__Id = examineId
    self.__ActionId = actionId
    self.__Round = 1
    self.__MaxRound = XTRPGConfigs.GetExamineActionRound(actionId)

    if XTRPGConfigs.CheckExamineActionType(actionId, XTRPGConfigs.TRPGExamineActionType.ConsumeItem) then
        --道具检定直接通过
        self.__Status = EXAMINE_STATUS.Suc
    else
        self.__Status = EXAMINE_STATUS.Normal
    end

    local roleIds = XDataCenter.TRPGManager.GetOwnRoleIds()
    for _, roleId in pairs(roleIds) do
        self.__RoleScoreDic[roleId] = 0
    end
    self.__TotalScore = 0
    self.__ReqScore = XTRPGConfigs.GetExamineActionNeedValue(actionId)
    self.__MovieId = XTRPGConfigs.GetExamineStartMovieId(examineId)
end

function XTRPGExamine:Clear()
    --恢复被挂起的剧情
    local movieId = self.__MovieId
    if not string.IsNilOrEmpty(movieId) then
        if XDataCenter.MovieManager.IsMovieYield() then
            local index = MOVIEINDEX[self.__Status]
            XDataCenter.MovieManager.ResumeMovie(index)
        end
    end

    self.__Status = EXAMINE_STATUS.Dead
    self.__PunishId = 0
    self.__Round = 0
    self.__RoleScoreDic = {}
    self.__TotalScore = 0
    self.__ReqScore = 0
    self.__MovieId = ""
end

function XTRPGExamine:EnterPunish()
    local punishId = self.__PunishId
    if punishId == 0 then return end

    if XTRPGConfigs.CheckPunishType(punishId, XTRPGConfigs.PunishType.Fight) then
        local params = XTRPGConfigs.GetPunishParams(punishId)
        local stageId = params[1]
        XLuaUiManager.Open("UiBattleRoleRoom", stageId)
    elseif XTRPGConfigs.CheckPunishType(punishId, XTRPGConfigs.PunishType.GoToOrigin) then
        XDataCenter.TRPGManager.ReqMazeRestart()
    end

    self.__PunishId = 0
end

function XTRPGExamine:EnterNextRound()
    self.__Round = self.__Round + 1
    for roleId in pairs(self.__RoleScoreDic) do
        self.__RoleScoreDic[roleId] = 0
    end
end

function XTRPGExamine:UpdateResult(data)
    if XTool.IsTableEmpty(data) then return end

    self.__Id = data.Id
    self.__Status = data.Success and EXAMINE_STATUS.Suc or EXAMINE_STATUS.Fail
    self.__PunishId = data.PunishId or 0
end

function XTRPGExamine:UpdateScore(data)
    if XTool.IsTableEmpty(data) then return end

    local roleId = data.RoleId
    local score = data.Score
    local oldScore = self.__RoleScoreDic[roleId]
    if oldScore then
        self.__RoleScoreDic[roleId] = score
    else
        XLog.Error("XTRPGExamine:UpdateScore error:跑团玩法检定角色不存在, examineId: " .. self.__Id .. ", data: " .. data)
    end

    self.__TotalScore = self.__TotalScore + score - oldScore
end

function XTRPGExamine:IsCanEnternNextRound()
    for _, score in pairs(self.__RoleScoreDic) do
        if score == 0 then
            return false
        end
    end
    return true
end

function XTRPGExamine:IsRoleAlreadyRolled(roleId)
    local score = self:GetRoleScore(roleId)
    return score ~= 0
end

function XTRPGExamine:IsLastRound()
    return self.__Round == self.__MaxRound
end

function XTRPGExamine:GetId()
    return self.__Id
end

function XTRPGExamine:GetActionId()
    return self.__ActionId
end

function XTRPGExamine:GetPunishId()
    return self.__PunishId
end

function XTRPGExamine:GetRoleScore(roleId)
    return self.__RoleScoreDic[roleId] or 0
end

function XTRPGExamine:GetTotalScore()
    return self.__TotalScore
end

function XTRPGExamine:GetCurRound()
    return self.__Round
end

function XTRPGExamine:GetScores()
    return self.__TotalScore, self.__ReqScore
end

function XTRPGExamine:IsPassed()
    return self.__TotalScore >= self.__ReqScore
end

function XTRPGExamine:CheckStatus(examineStatus)
    return self.__Status == examineStatus
end

return XTRPGExamine