local XLuckyTenantEnum = require("XModule/XLuckyTenant/Game/XLuckyTenantEnum")
local SkillType = XLuckyTenantEnum.Skill
local Quality = XLuckyTenantEnum.Quality
local PieceType = XLuckyTenantEnum.PieceType
local Tag = XLuckyTenantEnum.Tag

---@type function[]
local _UpdateDict = {}

---@type function[]
local _OnStartDict = {}

---@type function[]
local _OnDestroyDict = {}

-- 显示用
local _IsEffectEveryNTurns = {
    [SkillType.Type8] = true,
    [SkillType.Type9] = true,
    [SkillType.Type21] = true,
    [SkillType.Type48] = true,
    [SkillType.Type54] = true,
    [SkillType.Type4] = true,
    [SkillType.Type10] = true,
    [SkillType.Type26] = true,
    [SkillType.Type45] = true,
}

---@class XLuckyTenantChessSkill
local XLuckyTenantChessSkill = XClass(nil, "XLuckyTenantChessSkill")

function XLuckyTenantChessSkill:Ctor()
    self._Id = 0
    self._Type = 0
    self._Name = ""
    self._Desc = ""
    self._Params = false
    self._Score = 0
    self._Priority = 0
    ---@type XLuckyTenantPiece
    self._Piece = false
    self._IsPassive = false
    self._IsEffectUponJoining = false
    self._EffectJustOnFirstRound = false

    -- 各技能自定义使用的变量
    self._EffectTurns = -1
    self._LastDeletedAmount = 0
    self._IsDestroy = false
    self._ExtraPercent = 0
    self._SelfSpace = false
end

---@param model XLuckyTenantModel
function XLuckyTenantChessSkill:Set(piece, skillId, model)
    ---@type XTable.XTableLuckyTenantChessSkill
    local config = model:GetLuckyTenantChessSkillConfigById(skillId)
    self._Name = config.Name
    self._Desc = config.Desc
    self._Type = config.Type
    self._IsEffectUponJoining = config.IsEffectUponJoining
    self._Params = config.Params
    self._Priority = config.Priority
    self._Score = config.Score
    self._IsPassive = config.IsPassive
    self._Piece = piece
    self._Id = skillId
    self._EffectJustOnFirstRound = config.EffectJustOnFirstRound
end

function XLuckyTenantChessSkill:ClearPiece()
    self._Piece = false
end

function XLuckyTenantChessSkill:SetPassiveSkill(skillId, model)
    self:Set(nil, skillId, model)
end

---@param proxy XLuckyTenantOperationProxy
function XLuckyTenantChessSkill:Update(proxy)
    local func = _UpdateDict[self._Type]
    if func then
        func(proxy)
    else
        XLog.Error("[XLuckyTenantChessSkill] 未实现的技能类型" .. tostring(self._Type))
    end
end

---@param proxy XLuckyTenantOperationProxy
function XLuckyTenantChessSkill:OnDestroy(proxy)
    if proxy:IsToDelete(self:GetPiece()) then
        return
    end
    local func = _OnDestroyDict[self._Type]
    if func then
        func(self, proxy)
    end
    self._IsDestroy = true
end

function XLuckyTenantChessSkill:IsDestroy()
    return self._IsDestroy
end

---@param game XLuckyTenantGame
function XLuckyTenantChessSkill:OnStart(model, game)
    local func = _OnStartDict[self._Type]
    if func then
        func(self, game)
    end
    if self._IsPassive then
        game:AddPassiveSkill(self)
    end
end

function XLuckyTenantChessSkill:IsPassive()
    return self._IsPassive
end

function XLuckyTenantChessSkill:GetPriority()
    return self._Priority
end

function XLuckyTenantChessSkill:GetParams()
    return self._Params
end

function XLuckyTenantChessSkill:GetScore()
    return self._Score
end

function XLuckyTenantChessSkill:GetPiece()
    return self._Piece
end

function XLuckyTenantChessSkill:GetId()
    return self._Id
end

function XLuckyTenantChessSkill:GetName()
    return self._Name
end

function XLuckyTenantChessSkill:GetType()
    return self._Type
end

function XLuckyTenantChessSkill:GetDesc()
    return self._Desc
end

function XLuckyTenantChessSkill:Equals(skill)
    return self == skill
end

function XLuckyTenantChessSkill:SetEffectTurns(value)
    self._EffectTurns = value
end

function XLuckyTenantChessSkill:GetEffectTurns()
    return self._EffectTurns
end

function XLuckyTenantChessSkill:SetExtraPercent(percent)
    self._ExtraPercent = percent
end

function XLuckyTenantChessSkill:GetExtraPercent()
    return self._ExtraPercent
end

function XLuckyTenantChessSkill:GetLastDeletedAmount()
    return self._LastDeletedAmount
end

function XLuckyTenantChessSkill:SetLastDeletedAmount(value)
    self._LastDeletedAmount = value
end

-- 与【1类型】相邻自己会被消除，被消除后立即获得【score】分数，同时【1类型】棋子基础价值 +【2基础价值】
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type2] = function(proxy)
    local isTrigger, piece = proxy:IsNeighbour()
    if isTrigger then
        proxy:DeleteSelfPiece(piece)
        proxy:AddScore()
        local neighbours = proxy:GetNeighboursByType()
        for i = 1, #neighbours do
            local neighbour = neighbours[i]
            if proxy:CheckPieceExecuted(neighbour) then
                proxy:AddPieceValue(neighbour, proxy.Params[2])
                return
            end
        end
    end
end

-- 与【1类型】相邻自己会被消除，被消除后立即获得【score】分数，消除自己的棋子基础价值 +【自身基础价值】
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type3] = function(proxy)
    local isTrigger, piece = proxy:IsNeighbour()
    if isTrigger then
        proxy:DeleteSelfPiece(piece)
        proxy:AddScore()
        proxy:AddPieceValue(piece, proxy.Piece:GetValueIncludingTemp())
    end
end

--【1】回合后转化成【2棋子ID】【3棋子ID】【4棋子ID】里的随机一个棋子
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type4] = function(proxy)
    if proxy:CheckAfterRounds() then
        local index = math.random(2, #proxy.Params)
        local pieceId = proxy.Params[index]
        proxy:Transform(proxy.Piece, pieceId)
        return true
    end
    return false
end

--与【1类型】相邻自己会被消除，自己被消除后增加【2】个【3】
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type5] = function(proxy)
    local isTrigger, piece = proxy:IsNeighbour()
    if isTrigger then
        proxy:AddMultipleNewPieces(proxy.Params[2], proxy.Params[3])
        proxy:DeleteSelfPiece(piece)
        return true
    end
    return false
end

--消除相邻所有【1棋子ID】【2棋子ID】【3棋子ID】【4棋子ID】【5棋子ID】，至少配一个，最多配N个s
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type7] = function(proxy)
    local neighbours = proxy:GetNeighbours()
    for i = 1, #neighbours do
        local piece = neighbours[i]
        for j = 1, #proxy.Params do
            if piece and piece:GetId() == proxy.Params[j] then
                proxy:DeletePieceOnBoard(piece)
                break
            end
        end
    end
end

-- 每【1】回合，自身价值+【2】
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type8] = function(proxy)
    if proxy:ExecuteIfNotExecuted() then
        if proxy:CheckEveryNTurns() then
            proxy:AddPieceValue(proxy.Piece, proxy.Params[2])
            return true
        end
    end
    return false
end

-- 每过【1】回合，产出【2】个【3】棋子
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type9] = function(proxy)
    if proxy:ExecuteIfNotExecuted() then
        if proxy:CheckEveryNTurns() then
            proxy:AddMultipleNewPieces(proxy.Params[2], proxy.Params[3])
            return true
        end
    end
    return false
end

-- 【1】回合后变成【3棋子ID】，产出(【2】-1)个【3】棋子
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type10] = function(proxy)
    if proxy:ExecuteIfNotExecuted() then
        if proxy:CheckAfterRounds() then
            proxy:TransformSelf(proxy.Params[3])
            if proxy.Params[3] then
                local amount = proxy.Params[2]
                proxy:AddMultipleNewPieces(amount - 1, proxy.Params[3])
            else
                proxy:TransformSelf(proxy.Params[2])
            end
            return true
        end
    end
    return false
end

-- 和【1棋子ID】相邻，消除自身，可让【1棋子ID】的倒计时回合技能立即生效，若场上有两个自身，按照位置排序依次消耗自身
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type11] = function(proxy)
    local pieces = proxy:GetNeighbours()
    local isDone = false
    for i = 1, #pieces do
        local piece = pieces[i]
        if piece and piece:GetId() == proxy.Params[1] then
            if proxy:ExecuteIfNotExecutedShareOnSkill(piece:GetUid()) then
                proxy:DeleteSelfPiece(piece)
                isDone = true
                -- 把所有的技能加速
                local skills = piece:GetSkills(proxy.Model)
                for i = 1, #skills do
                    local skill = skills[i]
                    if skill:IsEffectEveryNTurns() then
                        skill:SetEffectTurns(0)
                    end
                end
                break
            end
        end
    end
    return isDone
end

-- 与【1】棋子相邻会被消除，被消除后增加【2数量】个【3类型】棋子和【4数量】个【5类型】
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type12] = function(proxy)
    if proxy:IsNeighbour() then
        proxy:DeletePieceOnBoard(proxy.Piece)
        proxy:AddMultipleNewPieces(proxy.Params[2], proxy.Params[3])
        if proxy.Params[4] and proxy.Params[5] then
            proxy:AddMultipleNewPieces(proxy.Params[4], proxy.Params[5])
        end
        return true
    end
    return false
end

-- 蒲牢棋子进入背包后，初始价值=初始价值+（【1】-【2】之间的随机值）
---@param skill XLuckyTenantChessSkill
_OnStartDict[SkillType.Type13] = function(skill)
    local params = skill:GetParams()
    local piece = skill:GetPiece()
    local value = math.random(params[1], params[2])
    piece:SetValue(piece:GetValue() + value)
    XMVCA.XLuckyTenant:Print("浦牢进入背包, 价值为", piece:GetValue())
end

---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type13] = function(proxy)
end

-- 消除相邻的【1棋子id】，每消除1个【1棋子id】，自身价值+【2】
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type14] = function(proxy)
    local times = proxy:DeleteNeighbourById()
    if times > 0 then
        proxy:AddPieceValue(proxy.Piece, times * proxy.Params[2])
        return true
    end
    return false
end

-- 消除相邻的【1棋子ID】，每消除1个可额外获得【score】分
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type15] = function(proxy)
    local neighbours = proxy:GetNeighbours()
    local times = 0
    for i = 1, #neighbours do
        local piece = neighbours[i]
        if piece and piece:GetId() == proxy.Params[1] then
            proxy:DeletePieceOnBoard(piece)
            times = times + 1
        end
    end
    if times > 0 then
        proxy:AddScore(times * proxy.Skill:GetScore())
        return true
    end
    return false
end

-- 消除相邻的所有蓝色绿色怪物，自身价值=基础价值加上吸收怪物价值总和（优先级最高）(没支持配置，个人觉得这个不需要)
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type16] = function(proxy)
    local pieces = proxy:GetNeighbours()
    local value = 0
    for i = 1, #pieces do
        local piece = pieces[i]
        if piece then
            if piece:GetPieceType() == PieceType.Monster then
                local quality = piece:GetQuality()
                if quality == Quality.Green or quality == Quality.Blue then
                    if proxy:DeletePieceOnBoard(piece) then
                        value = value + piece:GetValueIncludingTemp()
                    end
                end
            end
        end
    end
    if value > 0 then
        proxy:AddPieceValue(proxy.Piece, value)
        XMVCA.XLuckyTenant:Print("母体吸收:", value)
    end
end

-- 可以被基础价值大于【1数值】的【2类型】棋子相邻消除，被消除后，获得【3倍数】自身基础价值的分数
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type17] = function(proxy)
    local isTrigger = false
    local neighbours = proxy:GetNeighbours()
    ---@type XLuckyTenantPiece
    local from
    for i = 1, #neighbours do
        local neighbour = neighbours[i]
        if neighbour then
            if neighbour:GetPieceType() == proxy.Params[2] then
                if neighbour:GetValue() >= proxy.Params[1] then
                    from = neighbour
                    isTrigger = true
                    break
                end
            end
        end
    end
    if isTrigger then
        local value = proxy.Params[3] * proxy.Piece:GetValue()
        proxy:AddPieceValueUponDeletion(proxy.Piece, value)
        proxy:DeleteSelfPiece(from)
        XMVCA.XLuckyTenant:Print("母体被消除获得:", value)
    end
end

-- 棋盘上发生任意一个【战斗角色】消除【怪物】or【特殊怪物】  莉莉丝基础价值+1
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type18] = function(proxy)
    ---@type XLuckyTenantOperation[]
    local operations = proxy:GetOperationsLastCalculate()
    local times = 0
    for i = 1, #operations do
        ---@type XLuckyTenantOperationDeletePiece
        local operation = operations[i]
        if operation:GetType() == XLuckyTenantEnum.Operation.DeletePiece then
            local from = operation:GetFrom()
            local fromConfig = proxy.Model:GetLuckyTenantChessConfigById(from)
            if fromConfig.Type == XLuckyTenantEnum.PieceType.FightingRole then
                local to = operation:GetTo()
                local toConfig = proxy.Model:GetLuckyTenantChessConfigById(to)
                if toConfig.Type == XLuckyTenantEnum.PieceType.Monster or
                        toConfig.Type == XLuckyTenantEnum.PieceType.SpecialMonster then
                    times = times + 1
                end
            end
        end
    end
    if times > 0 then
        XMVCA.XLuckyTenant:Print("棋盘上发生任意一个【战斗角色】消除【怪物】or【特殊怪物】, 次数为:", times)
        local value = times * proxy.Params[1] or 1
        proxy:AddPieceValue(proxy.Piece, value)
    end
end

-- 与【2分数】的【1类型】棋子同时出现在棋盘上时会被消除
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type19] = function(proxy)
    local isTrigger = false
    local from
    local pieces = proxy:GetChessboardPieces()
    for i = 1, #pieces do
        local piece = pieces[i]
        if piece and piece:GetUid() ~= proxy.Piece then
            if piece:GetPieceType() == proxy.Params[2] then
                if piece:GetValueIncludingTemp() >= proxy.Params[1] then
                    from = piece
                    isTrigger = true
                    break
                end
            end
        end
    end
    if isTrigger then
        proxy:DeleteSelfPiece(from)
    end
end

-- 与自身相邻的【1类型】【2类型】棋子的基础价值+【3score】分（不包括自身），类型支持配置多个
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type20] = function(proxy)
    local neighbours = proxy:GetNeighbours()
    for i = 1, #neighbours do
        local neighbour = neighbours[i]

        if neighbour and proxy:CheckPieceExecuted(neighbour) then
            for j = 1, #proxy.Params do
                if neighbour:GetPieceType() == proxy.Params[j] then
                    proxy:AddPieceValue(neighbour, proxy.Skill:GetScore())
                    break
                end
            end
        end
    end
end

--每【1】回合从group表取id为【2】的随机池随机产生【3】个棋子 
-- 只配一个groupId
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type21] = function(proxy)
    if proxy:ExecuteIfNotExecuted() then
        if proxy:CheckEveryNTurns() then
            proxy:AddPiecesFromRandomGroup(proxy.Params[2], proxy.Params[3])
        end
    end
end

--与【1类型】相邻自己会被消除， 自己被消除后转化变成【3棋子id】
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type23] = function(proxy)
    if proxy:IsNeighbour() then
        proxy:Transform(proxy.Piece, proxy.Params[2])
        return true
    end
    return false
end

--每【1】回合结算分数时可额外获得【2】-【3】分
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type25] = function(proxy)
    if proxy:ExecuteIfNotExecuted() then
        local score = math.random(proxy.Params[2], proxy.Params[3])
        proxy:AddScore(score)
        return true
    end
    return false
end

--【1】回合后消失
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type26] = function(proxy)
    if proxy:CheckAfterRounds() then
        proxy:DeleteSelfPiece()
        return true
    end
    return false
end

-- 与【1】相邻时，每回合结算分数时可额外获得【2】-【3】分
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type28] = function(proxy)
    if proxy:ExecuteIfNotExecuted() then
        if proxy:IsNeighbour() then
            local score = math.random(proxy.Params[2], proxy.Params[3])
            proxy:AddScore(score)
            return true
        end
    end
    return false
end

-- 消除身边的【1棋子Id】
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type29] = function(proxy)
    local x, y = proxy.Piece:GetPosition()
    local neighbours = proxy.Neighbours
    proxy.Chessboard:GetNeighbours(x, y, neighbours)
    local isTrigger = false
    for i = 1, #neighbours do
        local piece = neighbours[i]
        if piece then
            if piece:GetId() == proxy.Params[1] then
                isTrigger = true
                proxy:DeletePieceOnBoard(piece)
            end
        end
    end
    return isTrigger
end

-- 结算分数=棋盘上价值最高的棋子
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type30] = function(proxy)
    if proxy:ExecuteIfNotExecuted() then
        local maxValue = 0
        local pieces = proxy.Chessboard:GetPieces()
        for i = 1, #pieces do
            local piece = pieces[i]
            if piece and piece:GetValueIncludingTemp() > maxValue then
                maxValue = piece:GetValueIncludingTemp()
            end
        end
        proxy:AddScore(maxValue)
        --proxy.Piece:SetScoreValidThisRound(maxValue)
    end
end

-- 与【1】相邻时，自身临时分数+【2】
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type31] = function(proxy)
    if proxy:IsSkillExecuted() then
        return
    end
    if proxy:IsNeighbour() then
        proxy:SetSkillExecuted()
        proxy:AddPieceScoreValidThisRound(proxy.Piece, proxy.Params[2])
    end
end

-- 与【1】相邻后生成1个【2】
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type32] = function(proxy)
    if proxy:IsSkillExecuted() then
        return
    end
    if proxy:IsNeighbour() then
        proxy:SetSkillExecuted()
        proxy:AddNewPiece(proxy.Params[2])
    end
end

-- 曲所在的某一行上所有棋子基础价值+【1】
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type33] = function(proxy)
    local selfPiece = proxy.Piece
    local x, y = selfPiece:GetPosition()
    for i = 1, proxy.Chessboard:GetColumn() do
        if i ~= x then
            local piece = proxy.Chessboard:GetPieceByPosition(i, y)
            if piece and proxy:CheckPieceExecuted(piece) then
                proxy:AddPieceValue(piece, proxy.Params[1])
            end
        end
    end
end

-- 每与一个棋子相邻，可额外获得【3score】分
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type35] = function(proxy)
    local times = 0
    local neighbours = proxy:GetNeighbours()
    for i = 1, #neighbours do
        local neighbour = neighbours[i]
        if neighbour and proxy:CheckPieceExecuted(neighbour) then
            times = times + 1
        end
    end
    if times > 0 then
        local score = times * proxy.Skill:GetScore()
        proxy:AddScore(score)
    end
end

-- 每次结算基础分数，自身基础价值会变成场上所有【1棋子类型】【2棋子类型】【3棋子类型】基础价值之和，至少配一个类型
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type36] = function(proxy)
    local value = 0
    local pieces = proxy.Chessboard:GetPieces()
    for i = 1, #pieces do
        local piece = pieces[i]
        if piece then
            if not piece:Equals(proxy.Piece) then
                if piece:GetPieceType() == proxy.Params[1]
                        or piece:GetPieceType() == proxy.Params[2]
                        or piece:GetPieceType() == proxy.Params[3]
                then
                    value = value + piece:GetValueIncludingTemp()
                end
            end
        end
    end
    if value > 0 then
        proxy:SetPieceScoreValidThisRound(proxy.Piece, value)
        return true
    end
    return false
end

-- 该棋子出现在棋盘上时，场上所有【1类型】【2类型】自身价值+【3score】，至少配一个类型
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type37] = function(proxy)
    local pieces = proxy.Chessboard:GetPieces()
    for i = 1, #pieces do
        local piece = pieces[i]
        if piece and proxy:CheckPieceExecuted(piece) then
            if piece:GetPieceType() == proxy.Params[1]
                    or piece:GetPieceType() == proxy.Params[2]
            then
                --piece:AddScoreValidThisRound(proxy.Skill:GetScore())
                proxy:AddPieceValue(piece, proxy.Skill:GetScore())
            end
        end
    end
end

-- 累计消除【1】个【2】后，福袋变成【3】个【4】
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type38] = function(proxy)
    ---@type XLuckyTenantOperation[]
    local operations = proxy:GetOperationsLastCalculate()
    local times = 0
    for i = 1, #operations do
        ---@type XLuckyTenantOperationDeletePiece
        local operation = operations[i]
        if operation:GetType() == XLuckyTenantEnum.Operation.DeletePiece then
            local to = operation:GetTo()
            if to == proxy.Params[2] then
                times = times + 1
            end
        end
    end
    if times > 0 then
        proxy.Skill:SetLastDeletedAmount(proxy.Skill:GetLastDeletedAmount() + times)
        XMVCA.XLuckyTenant:Print("棋盘上发生任意一个【战斗角色】消除【怪物】or【特殊怪物】, 次数为:", times)

        local amount = proxy.Skill:GetLastDeletedAmount()
        if amount >= proxy.Params[1] then
            local pieceId = proxy.Params[4]
            proxy:Transform(proxy.Piece, pieceId)
            local newPiecesAmount = proxy.Params[3]
            if newPiecesAmount > 1 then
                for i = 2, newPiecesAmount do
                    proxy:AddNewPiece(pieceId)
                end
            end
        end
    end
end

--棋盘上的【1棋子ID】、【2棋子ID】、【3棋子ID】至少配一个棋子ID，额外得分+【4score】,技能在背包里生效
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type39] = function(proxy)
    local score = 0
    for i = 1, #proxy.PiecesOnBoard do
        local piece = proxy.PiecesOnBoard[i]
        if piece then
            if piece:GetId() == proxy.Params[1]
                    or piece:GetId() == proxy.Params[2]
                    or piece:GetId() == proxy.Params[3]
            then
                if proxy:CheckPieceExecuted(piece) then
                    score = score + proxy.Skill:GetScore()
                    proxy:AddScore(proxy.Skill:GetScore(), piece)
                end
            end
        end
    end
    if score > 0 then
        -- 获得0分，但是希望他抖一下...
        proxy:AddScore(0)
    end
end

-- 棋盘上的【1棋子ID】、【2棋子ID】、【3棋子ID】至少配一个棋子ID，基础价值+【4score】,技能在背包里生效
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type40] = function(proxy)
    for i = 1, #proxy.PiecesOnBoard do
        local piece = proxy.PiecesOnBoard[i]
        if piece then
            if piece:GetId() == proxy.Params[1]
                    or piece:GetId() == proxy.Params[2]
                    or piece:GetId() == proxy.Params[3]
            then
                if proxy:CheckPieceExecuted(piece) then
                    proxy:AddPieceValue(piece, proxy.Skill:GetScore())
                end
            end
        end
    end
end

-- 棋盘上存在【2棋子ID】【3棋子ID】【4棋子ID】【5棋子ID】这些棋子中的任意【1数量】种棋子时会被消除，同时，棋盘上的【2棋子ID】【3棋子ID】【4棋子ID】【5棋子ID】基础价值+【6score】
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type42] = function(proxy)
    local typeAmountDict = {}
    for i = 1, #proxy.PiecesOnBoard do
        local piece = proxy.PiecesOnBoard[i]
        if piece then
            local pieceId = piece:GetId()
            if pieceId == proxy.Params[2]
                    or pieceId == proxy.Params[3]
                    or pieceId == proxy.Params[4]
                    or pieceId == proxy.Params[5]
            then
                typeAmountDict[pieceId] = true
            end
        end
    end
    local typeAmount = 0
    for i, v in pairs(typeAmountDict) do
        typeAmount = typeAmount + 1
    end
    if typeAmount >= proxy.Params[1] then
        proxy:DeleteSelfPiece()
        for i = 1, #proxy.PiecesOnBoard do
            local piece = proxy.PiecesOnBoard[i]
            if piece then
                local pieceId = piece:GetId()
                if pieceId == proxy.Params[2]
                        or pieceId == proxy.Params[3]
                        or pieceId == proxy.Params[4]
                        or pieceId == proxy.Params[5]
                then
                    proxy:AddPieceValue(piece, proxy.Skill:GetScore())
                end
            end
        end
    end
end

-- 与【2棋子ID】【3棋子ID】【4棋子ID】【5棋子ID】相邻被消除，变成1个【1棋子ID】
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type43] = function(proxy)
    local neighbours = proxy:GetNeighbours()
    for i = 1, #neighbours do
        local neighbour = neighbours[i]
        if neighbour then
            for j = 1, #proxy.Params do
                if neighbour:GetId() == proxy.Params[j] then
                    proxy:Transform(proxy.Piece, proxy.Params[1])
                    return
                end
            end
        end
    end
end

-- 当棋盘上同时出现【1棋子ID】，【2棋子ID】，【3棋子ID】至少配一个时，3人的自身基础价值+【4score】
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type44] = function(proxy)
    local typeAmountDict = {}
    for i = 1, #proxy.PiecesOnBoard do
        local piece = proxy.PiecesOnBoard[i]
        if piece then
            local pieceId = piece:GetId()
            if pieceId == proxy.Params[1]
                    or pieceId == proxy.Params[2]
                    or pieceId == proxy.Params[3]
            then
                typeAmountDict[pieceId] = true
            end
        end
    end

    local needAmount = 0
    for i = 1, 3 do
        if proxy.Params[i] > 0 then
            needAmount = needAmount + 1
        end
    end

    local typeAmount = 0
    for i, v in pairs(typeAmountDict) do
        typeAmount = typeAmount + 1
    end
    if typeAmount >= needAmount then
        for i = 1, #proxy.PiecesOnBoard do
            local piece = proxy.PiecesOnBoard[i]
            if piece then
                if proxy:CheckPieceExecuted(piece) then
                    local pieceId = piece:GetId()
                    if pieceId == proxy.Params[1]
                            or pieceId == proxy.Params[2]
                            or pieceId == proxy.Params[3]
                    then
                        proxy:AddPieceValue(piece, proxy.Skill:GetScore())
                    end
                end
            end
        end
    end
end

-- 【1】回合后产生【2数量】个随机【3棋子ID】【4棋子ID】【5棋子ID】棋子
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type45] = function(proxy)
    if proxy:ExecuteIfNotExecuted() then
        if proxy:CheckAfterRounds() then
            for i = 1, proxy.Params[2] do
                local index = math.random(3, #proxy.Params)
                local pieceId = proxy.Params[index]
                proxy:AddNewPiece(pieceId)
            end
        end
    end
end

-- 与【1类型】相邻自己会被消除，被消除后，使消除本身棋子的消除价值+【2消除价值】
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type46] = function(proxy)
    local isTrigger, piece = proxy:IsNeighbour()
    if isTrigger then
        proxy:DeleteSelfPiece(piece)
        proxy:AddPieceValueUponDeletion(piece, proxy.Params[2])
    end
end

-- 每回合该棋子的临时基础价值=所在行列全部【1类型】棋子价值总和，类型支持配置多个
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type47] = function(proxy)
    local x, y = proxy.Piece:GetPosition()
    local selfId = proxy.Piece:GetId()
    local value = 0
    for i = 1, proxy.Chessboard:GetColumn() do
        if i ~= x then
            local piece = proxy.Chessboard:GetPieceByPosition(i, y)
            if piece and piece:GetId() ~= selfId then
                value = value + piece:GetValueIncludingTemp()
            end
        end
    end
    for i = 1, proxy.Chessboard:GetRow() do
        if i ~= y then
            local piece = proxy.Chessboard:GetPieceByPosition(x, i)
            if piece and piece:GetId() ~= selfId then
                value = value + piece:GetValueIncludingTemp()
            end
        end
    end
    proxy:SetPieceScoreValidThisRound(proxy.Piece, value)
end

-- 每【1数量】回合消除自身，转化为【2数量】个【3棋子ID】棋子
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type48] = function(proxy)
    if proxy:CheckEveryNTurns() then
        proxy:TransformAndNewPiece(proxy.Piece, proxy.Params[2], proxy.Params[3])
    end
end

-- 每与一个棋子相邻，可额外获得【score】分
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type49] = function(proxy)
    local neighbours = proxy:GetNeighbours()
    local amount = 0
    for i = 1, #neighbours do
        local neighbour = neighbours[i]
        if neighbour then
            local x, y = neighbour:GetPosition()
            if proxy:ExecuteIfNotExecuted(x, y) then
                amount = amount + 1
            end
        end
    end
    if amount > 0 then
        proxy:AddScore(amount * proxy.Skill:GetScore())
    end
end

-- 消除相邻的【1类型】棋子，消除时，额外获得被消除【1类型】棋子的分数，每消除一次，自身基础价值+【2分数】【有问题，要问下数值】
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type50] = function(proxy)
    local neighbours = proxy:GetNeighbours()
    local value = 0
    local amount = 0
    for i = 1, #neighbours do
        local piece = neighbours[i]
        if piece and piece:GetPieceType() == proxy.Params[1] then
            --value = value + piece:GetValueIncludingTemp()
            proxy:AddScore(piece:GetValue())
            proxy:DeletePieceOnBoard(piece)
            amount = amount + 1
        end
    end
    if amount > 0 then
        proxy:AddPieceValue(proxy.Piece, value + amount * proxy.Params[2])
        return true
    end
    return false
end

local function SortPieceSmall(a, b)
    return a:GetValue() < b:GetValue()
end

local function SortPieceBig(a, b)
    return a:GetValue() > b:GetValue()
end

-- 该棋子在棋盘上时，会随机将棋盘上基础价值最低的三个棋子替换成背包里价值高的棋子（包括自身）
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type51] = function(proxy)
    if not proxy:ExecuteIfNotExecuted() then
        return
    end

    ---@type XLuckyTenantPiece[]
    local piecesSmallest = {}
    local piecesOnBoard = proxy.PiecesOnBoard
    for i = 1, #piecesOnBoard do
        local piece = piecesOnBoard[i]
        if piece then
            piecesSmallest[#piecesSmallest + 1] = piece
        end
    end
    if #piecesSmallest > 3 then
        local smallest = { piecesSmallest[1], piecesSmallest[2], piecesSmallest[3] }
        table.sort(smallest, SortPieceSmall)
        for i = 4, #piecesSmallest do
            local element = piecesSmallest[i]
            local num = element:GetValue()
            if num < smallest[1]:GetValue() then
                smallest[3] = smallest[2]
                smallest[2] = smallest[1]
                smallest[1] = element
            elseif num < smallest[2]:GetValue() then
                smallest[3] = smallest[2]
                smallest[2] = element
            elseif num < smallest[3]:GetValue() then
                smallest[3] = element
            end
        end
        piecesSmallest = smallest
    end

    local piecesOnBoardDict = {}
    for i = 1, #piecesOnBoard do
        local piece = piecesOnBoard[i]
        if piece then
            piecesOnBoardDict[piece:GetUid()] = true
        end
    end

    ---@type XLuckyTenantPiece[]
    local piecesBiggest = {}
    local piecesOnBag = proxy.Bag:GetPieces()
    for i = 1, #piecesOnBag do
        local piece = piecesOnBag[i]
        if piece and not piecesOnBoardDict[piece:GetUid()] then
            piecesBiggest[#piecesBiggest + 1] = piece
        end
    end
    if #piecesBiggest > 3 then
        local biggest = { piecesBiggest[1], piecesBiggest[2], piecesBiggest[3] }
        table.sort(biggest, SortPieceBig)
        for i = 4, #piecesBiggest do
            local element = piecesBiggest[i]
            local num = element:GetValue()
            if num > biggest[1]:GetValue() then
                biggest[3] = biggest[2]
                biggest[2] = biggest[1]
                biggest[1] = element
            elseif num > biggest[2]:GetValue() then
                biggest[3] = biggest[2]
                biggest[2] = element
            elseif num > biggest[3]:GetValue() then
                biggest[3] = element
            end
        end
        piecesBiggest = biggest
    end

    for i = 1, #piecesSmallest do
        local pieceSmall = piecesSmallest[i]
        local pieceBig = piecesBiggest[i]
        if pieceBig then
            if pieceBig:IsOnChessboard() then
                XLog.Error("[XLuckyTenantCHessSkill] 从背包里查找最大的3个棋子替换棋盘上最小的3个棋子, 逻辑存在问题, 最大的棋子已经在棋盘上了")
            end
            local x, y = pieceSmall:GetPosition()
            proxy:SetPieceByPosition(x, y, pieceBig)
            XMVCA.XLuckyTenant:Print("查找背包里最大的3个替换最小的3个", string.format("(%s,%s)", x, y), pieceSmall:GetName(), "替换为", pieceBig:GetName())
        end
    end
end

--与【1类型】相邻自己会被消除，自己被消除后增加【2】个【3】
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type52] = function(proxy)
    local isTrigger, from = proxy:IsNeighbourById()
    if isTrigger then
        proxy:DeleteSelfPiece(from)
        proxy:AddMultipleNewPieces(proxy.Params[2], proxy.Params[3])
        return true
    end
    return false
end

-- 消除相邻的【1】时，若成功消除，自己的基础价值增加1，每回合最多增加一次。
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type53] = function(proxy)
    local times = proxy:DeleteNeighbourById()
    if times > 0 then
        if proxy:ExecuteIfNotExecuted() then
            proxy:AddPieceValue(proxy.Piece, (proxy.Params[2] or 1))
        end
        return true
    end
    return false
end

-- 每隔【1回合】有【2%】的概率产出【3数量】个【4棋子ID】棋子
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type54] = function(proxy)
    if proxy:ExecuteIfNotExecuted() then
        if proxy:CheckEveryNTurns() then
            if proxy:RandomFrom1To100(proxy.Params[2]) then
                proxy:AddMultipleNewPieces(proxy.Params[3], proxy.Params[4])
            end
            return true
        end
    end
    return false
end

-- 只有一个欧皇指挥官! 全局共享
-- 每一回合，有【1%】概率的基础概率变成【2棋子ID】欧皇指挥官，相邻棋子有【3棋子ID】虹卡的回合，基础概率+【4%】
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type55] = function(proxy)
    if proxy:ExecuteIfNotExecuted() then
        local percent = proxy.Params[1] + proxy.Skill:GetExtraPercent()
        if proxy:IsNeighbourById(3) then
            percent = percent + proxy.Params[4]
            proxy.Skill:SetExtraPercent(proxy.Skill:GetExtraPercent() + proxy.Params[4])
        end
        if proxy.Bag:FindPiece(proxy.Params[2]) then
            XMVCA.XLuckyTenant:Print("已经有欧皇指挥官了，非鸦变身失败")
            return false
        end
        if proxy:RandomFrom1To100(percent) then
            proxy:TransformSelf(proxy.Params[2])

            -- 变身成功后，屏蔽其他非鸦变身的可能
            --proxy:SetSkillsExecutedById(proxy.Skill:GetId())
            -- 按顺序触发， 不再有这个问题
        end
    end
    return false
end

-- 与【1棋子ID】、【2棋子ID】、【3棋子ID】、【4棋子ID】一起出现在棋盘时，消除自身，额外得分=四名角色基础价值之和
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type56] = function(proxy)
    local typeAmountDict = {}
    for i = 1, #proxy.PiecesOnBoard do
        local piece = proxy.PiecesOnBoard[i]
        if piece then
            local pieceId = piece:GetId()
            if pieceId == proxy.Params[1]
                    or pieceId == proxy.Params[2]
                    or pieceId == proxy.Params[3]
                    or pieceId == proxy.Params[4]
            then
                typeAmountDict[pieceId] = true
            end
        end
    end

    local typeAmount = 0
    for i, v in pairs(typeAmountDict) do
        typeAmount = typeAmount + 1
    end
    if typeAmount >= 4 then
        local value = 0
        for i = 1, #proxy.PiecesOnBoard do
            local piece = proxy.PiecesOnBoard[i]
            if piece then
                local pieceId = piece:GetId()
                if pieceId == proxy.Params[1]
                        or pieceId == proxy.Params[2]
                        or pieceId == proxy.Params[3]
                        or pieceId == proxy.Params[4]
                then
                    value = value + piece:GetValue()
                end
            end
        end
        proxy:DeleteSelfPiece()
        proxy:AddScore(value)
    end
end

-- 与【1棋子ID】相邻后生成1个【2棋子ID】，最多1个，每回合只能触发1次
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type57] = function(proxy)
    local matchNeighbours = proxy:GetNeighboursById()
    if #matchNeighbours > 0 then
        if proxy:ExecuteIfNotExecuted() then
            proxy:AddMultipleNewPieces(#matchNeighbours, proxy.Params[2])
        end
    end
end

-- 与【1棋子ID】相邻被消除，获得消除分数
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type58] = function(proxy)
    local isTrigger, piece = proxy:IsNeighbourById()
    if isTrigger then
        if proxy:ExecuteIfNotExecuted() then
            proxy:DeleteSelfPiece(piece)
        end
    end
end

-- 与【1棋子ID】相邻被消除，同时消除它的棋子的基础价值+[3分数]
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type59] = function(proxy)
    local isTrigger, piece = proxy:IsNeighbourById()
    if isTrigger then
        if proxy:ExecuteIfNotExecuted() then
            proxy:DeleteSelfPiece(piece)
            if piece then
                proxy:AddPieceValue(piece, proxy.Skill:GetScore())
            end
        end
    end
end

-- 自己被消除后转化变成【1棋子id】
---@param skill XLuckyTenantChessSkill
---@param proxy XLuckyTenantOperationProxy
_OnDestroyDict[SkillType.Type61] = function(skill, proxy)
    local x, y = skill._Piece:GetPosition()
    local params = skill:GetParams()
    proxy:AddMultipleNewPieces(params[2] or 1, params[1], x, y)
end
_UpdateDict[SkillType.Type61] = function(skill, proxy)
end

-- 与【1类型】棋子相邻时，自身基础价值永久+【2分数】
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type62] = function(proxy)
    if proxy:IsNeighbour() then
        if proxy:ExecuteIfNotExecuted() then
            proxy:AddPieceValue(proxy.Piece, proxy.Skill:GetScore())
        end
    end
end

-- 棋盘上发生阿尔法杀普通怪物, 每消除1个可额外获得【score】分
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type63] = function(proxy)
    ---@type XLuckyTenantOperation[]
    local operations = proxy:GetOperationsLastCalculate()
    local times = 0
    for i = 1, #operations do
        ---@type XLuckyTenantOperationDeletePiece
        local operation = operations[i]
        if operation:GetType() == XLuckyTenantEnum.Operation.DeletePiece then
            local fromUid = operation:GetFromUid()
            if fromUid == proxy.Piece:GetUid() then
                local to = operation:GetTo()
                local toConfig = proxy.Model:GetLuckyTenantChessConfigById(to)
                if toConfig.Type == XLuckyTenantEnum.PieceType.Monster then
                    times = times + 1
                end
            end
        end
    end
    if times > 0 then
        XMVCA.XLuckyTenant:Print("棋盘上发生阿尔法杀普通怪物, 次数为:", times)
        local value = times * proxy.Skill:GetScore() or 1
        proxy:AddScore(value, proxy.Piece)
    end
end

-- 每回合该棋子的临时价值等于, 棋盘上除了自己(相同id)以外的, 全部【1类型】棋子的棋子价值 * 该棋子所在行数的分数总和
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type64] = function(proxy)
    local selfId = proxy.Piece:GetId()
    local pieces = proxy.PiecesOnBoard
    local value = 0
    for i = 1, #pieces do
        local piece = pieces[i]
        if piece and piece:GetId() ~= selfId and piece:GetPieceType() == proxy.Params[1] then
            local x, y = piece:GetPosition()
            value = value + piece:GetValueIncludingTemp() * (proxy.Chessboard:GetRow() - y + 1)
        end
    end
    proxy:SetPieceScoreValidThisRound(proxy.Piece, value)
end

-- 与【1类型】相邻自己会被消除
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type65] = function(proxy)
    local neighbours = proxy:GetNeighbours()
    local isTrigger = false  -- 默认未触发
    ---@type XLuckyTenantPiece
    local piece
    for i = 1, #neighbours do
        piece = neighbours[i]  -- 遍历相邻棋子
        if piece and piece:GetPieceType() == proxy.Params[1] then
            isTrigger = true  -- 如果相邻棋子的类型匹配，标记为触发
        end
    end
    if isTrigger then
        proxy:DeleteSelfPiece(piece)
    end
end

-- 自己被消除后从【2随机池ID】取出【3数量】个棋子
---@param proxy XLuckyTenantOperationProxy
---@param skill XLuckyTenantChessSkill
_OnDestroyDict[SkillType.Type66] = function(skill, proxy)
    local params = skill:GetParams()
    if params[1] then
        proxy:AddPiecesFromRandomGroup(params[1], params[2] or 1)
    end
end

_UpdateDict[SkillType.Type66] = function()
end

-- 与【1棋子ID】相邻被消除，同时消除它的棋子的基础价值+【被消除棋子的基础分数】
---@param proxy XLuckyTenantOperationProxy
_UpdateDict[SkillType.Type67] = function(proxy)
    local result, from = proxy:IsNeighbourById()
    if result then
        proxy:DeleteSelfPiece(from)
        proxy:AddPieceValue(from, proxy.Piece:GetValue())
    end
end

function XLuckyTenantChessSkill:IsEffectUponJoining()
    return self._IsEffectUponJoining
end

function XLuckyTenantChessSkill:IsEffectJustOnFirstRound()
    return self._EffectJustOnFirstRound
end

function XLuckyTenantChessSkill:GetSelfSpace()
    if not self._SelfSpace then
        self._SelfSpace = {}
    end
    return self._SelfSpace
end

function XLuckyTenantChessSkill:IsEffectEveryNTurns()
    return _IsEffectEveryNTurns[self:GetType()]
end

function XLuckyTenantChessSkill:GetInitialEffectTurns()
    return self._Params[1]
end

return XLuckyTenantChessSkill