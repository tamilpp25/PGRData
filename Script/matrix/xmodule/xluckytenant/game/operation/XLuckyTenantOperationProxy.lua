-- 引入所需的模块
local XLuckyTenantOperationPackage = require("XModule/XLuckyTenant/Game/Operation/XLuckyTenantOperationPackage")
local XLuckyTenantOperationAddNewPiece = require("XModule/XLuckyTenant/Game/Operation/XLuckyTenantOperationAddNewPiece")
local XLuckyTenantOperationAddPassiveSkill = require("XModule/XLuckyTenant/Game/Operation/XLuckyTenantOperationAddPassiveSkill")
local XLuckyTenantOperationAddPieceValue = require("XModule/XLuckyTenant/Game/Operation/XLuckyTenantOperationAddPieceValue")
local XLuckyTenantOperationAddScore = require("XModule/XLuckyTenant/Game/Operation/XLuckyTenantOperationAddScore")
local XLuckyTenantOperationDeletePiece = require("XModule/XLuckyTenant/Game/Operation/XLuckyTenantOperationDeletePiece")
local XLuckyTenantOperationSetPieceByPosition = require("XModule/XLuckyTenant/Game/Operation/XLuckyTenantOperationSetPieceByPosition")
local XLuckyTenantOperationTransformPiece = require("XModule/XLuckyTenant/Game/Operation/XLuckyTenantOperationTransformPiece")
local XLuckyTenantOperationAddPieceScoreValidThisRound = require("XModule/XLuckyTenant/Game/Operation/XLuckyTenantOperationAddPieceScoreValidThisRound")
local XLuckyTenantOperationSetPieceScoreValidThisRound = require("XModule/XLuckyTenant/Game/Operation/XLuckyTenantOperationSetPieceScoreValidThisRound")
local XLuckyTenantOperationAddValueUponDeletion = require("XModule/XLuckyTenant/Game/Operation/XLuckyTenantOperationAddValueUponDeletion")
local XLuckyTenantOperationUpdatePiece = require("XModule/XLuckyTenant/Game/Operation/XLuckyTenantOperationUpdatePiece")

---@class XLuckyTenantOperationProxy
local XLuckyTenantOperationProxy = XClass(nil, "XLuckyTenantOperationProxy")

--- 构造函数
---@param game XLuckyTenantGame 游戏实例
---@param model XLuckyTenantModel 模型实例
function XLuckyTenantOperationProxy:Ctor(game, model)
    self.Game = game  -- 保存游戏实例
    self.Model = model  -- 保存模型实例
    self.Chessboard = game:GetChessboard()  -- 获取棋盘
    self.Bag = game:GetBag()  -- 获取背包
    ---@type XLuckyTenantPiece[] 复用table，用来接收相邻棋子
    self.Neighbours = {}
    self.PiecesOnBoard = self.Chessboard:GetPieces()
    ---@type XLuckyTenantOperationPackage 操作包
    self.OperationPackage = XLuckyTenantOperationPackage.New()
    ---@type XLuckyTenantOperationPackage[] 操作包
    self.ManyOperationPackages = {}
    self.UniqueSkillExecuted = {}  -- 存储已执行的独特技能
    self._ExecutedSkills = {}  -- 存储已执行的技能
    self._DeletedPieces = {}
    ---@type XLuckyTenantPiece
    self.Piece = false
    ---@type XLuckyTenantPiece@这部分棋子,已经从棋盘和背包上移除,但是要等到本轮次结束后,才真正移除
    self._ToDelete = {}
    -- 一轮次计算中，产生的操作
    self._OperationsLastCalculate = {}
    self.Times = 0
end

---@param skills XLuckyTenantChessSkill[]
function XLuckyTenantOperationProxy:UpdateMultiSkills(skills)
    for i = 1, #skills do
        local skill = skills[i]
        self:Update(skill)
    end
end

---@param skill XLuckyTenantChessSkill
function XLuckyTenantOperationProxy:Update(skill)
    if not skill:GetPiece() then
        XMVCA.XLuckyTenant:Print("释放技能的主体不存在", skill:GetDesc())
        return
    end
    self.Skill = skill  -- 保存当前技能
    self.Piece = skill:GetPiece()  -- 获取当前技能对应的棋子
    self.Params = skill:GetParams()  -- 获取技能参数
    skill:Update(self)  -- 更新技能状态
end

function XLuckyTenantOperationProxy:SaveOperationPackage()
    -- 如果操作包不为空，则保存它
    if self.OperationPackage:IsNotEmpty() then
        self.ManyOperationPackages[#self.ManyOperationPackages + 1] = self.OperationPackage
        self.OperationPackage = XLuckyTenantOperationPackage.New()  -- 重置操作包
    end
end

---@param piece1 XLuckyTenantPiece
function XLuckyTenantOperationProxy:CheckPieceExecuted(piece1)
    if not piece1 then
        return false
    end
    return self:ExecuteIfNotExecuted(piece1:GetUid())
end

--function XLuckyTenantOperationProxy:ClearSkillExecuted(piece)
--    local pieceUid = piece and piece:GetUid() or 0
--    self._ExecutedSkills[pieceUid] = false
--end

function XLuckyTenantOperationProxy:ExecuteIfNotExecuted(params1, params2, params3, params4)
    local pieceUid = self.Piece and self.Piece:GetUid() or 0
    local skillId = self.Skill:GetId()
    local key
    if params4 then
        key = pieceUid .. skillId .. "_" .. params1 .. "_" .. params2 .. "_" .. params3 .. "_" .. params4
    elseif params3 then
        key = pieceUid .. skillId .. "_" .. params1 .. "_" .. params2 .. "_" .. params3
    elseif params2 then
        key = pieceUid .. skillId .. "_" .. params1 .. "_" .. params2
    elseif params1 then
        key = pieceUid .. skillId .. "_" .. params1
    else
        -- 有一个技能利用了这个id，如果要修改这个格式，麻烦谨慎
        key = pieceUid .. skillId -- 如果没有任何参数，使用 pieceUid
    end
    if self._ExecutedSkills[key] then
        return false
    end
    self._ExecutedSkills[key] = true
    return true
end

function XLuckyTenantOperationProxy:ExecuteIfNotExecutedShareOnSkill(params1)
    local skillId = self.Skill:GetId()
    local key
    if params1 then
        key = "Skill" .. skillId .. "_" .. params1
    else
        -- 有一个技能利用了这个id，如果要修改这个格式，麻烦谨慎
        key = "Skill" .. skillId -- 如果没有任何参数，使用 pieceUid
    end
    if self._ExecutedSkills[key] then
        return false
    end
    self._ExecutedSkills[key] = true
    return true
end

function XLuckyTenantOperationProxy:IsSkillExecuted()
    local pieceUid = self.Piece and self.Piece:GetUid() or 0
    return self._ExecutedSkills[pieceUid]
end

function XLuckyTenantOperationProxy:SetSkillExecuted()
    local pieceUid = self.Piece and self.Piece:GetUid() or 0
    self._ExecutedSkills[pieceUid] = true
end

--- 设置已执行的独特技能
---@param skillId number 技能ID
function XLuckyTenantOperationProxy:SetUniqueSkillExecuted(skillId)
    self.UniqueSkillExecuted[skillId] = true  -- 标记技能为已执行
end

--- 检查独特技能是否已执行
---@param skillId number 技能ID
---@return boolean 是否已执行
function XLuckyTenantOperationProxy:IsUniqueSkillExecuted(skillId)
    return self.UniqueSkillExecuted[skillId] == true  -- 返回技能是否已执行
end

--- 添加新棋子
---@param pieceId number 棋子ID
function XLuckyTenantOperationProxy:AddNewPiece(pieceId, x, y)
    local operation = XLuckyTenantOperationAddNewPiece.New(self)  -- 创建新棋子操作
    if not x and not y and self.Piece then
        x, y = self.Piece:GetPosition()
    end
    operation:SetData(pieceId, x, y, self)  -- 设置棋子数据
    self.OperationPackage:Push(operation)  -- 将操作推入操作包
end

--- 添加多个新棋子
---@param amount number 添加的棋子数量
---@param pieceId number 棋子ID
function XLuckyTenantOperationProxy:AddMultipleNewPieces(amount, pieceId, x, y)
    if not pieceId then
        XLog.Error("[XLuckyTenantOperationProxy] 要生成的棋子不存在:" .. tostring(pieceId) .. "，技能id是:", self.Skill:GetId())
        return
    end
    if (not x and not y) and self.Piece then
        x, y = self.Piece:GetPosition()
    end
    for i = 1, amount do
        -- 根据数量添加新棋子
        local operation = XLuckyTenantOperationAddNewPiece.New(self)
        operation:SetData(pieceId, x, y, self)  -- 设置棋子数据
        self.OperationPackage:Push(operation)  -- 将操作推入操作包
    end
end

--- 添加棋子值
---@param piece XLuckyTenantPiece 棋子
---@param value number 值
function XLuckyTenantOperationProxy:AddPieceValue(piece, value)
    local operation = XLuckyTenantOperationAddPieceValue.New(self)  -- 创建添加棋子值操作
    operation:SetData(piece:GetUid(), value, self.Skill, piece:GetName())  -- 设置棋子UID和值
    self.OperationPackage:Push(operation)  -- 将操作推入操作包
end

--- 添加分数
---@param value number 分数值
function XLuckyTenantOperationProxy:AddScore(value, piece)
    if not value then
        value = self.Skill:GetScore()
    end
    local operation = XLuckyTenantOperationAddScore.New(self)  -- 创建添加分数操作
    piece = piece or self.Piece
    local x, y = piece:GetPosition()  -- 获取棋子的位置
    operation:SetData(x, y, value, self.Skill)  -- 设置分数数据
    self.OperationPackage:Push(operation)  -- 将操作推入操作包
end

--- 删除棋子
---@param piece XLuckyTenantPiece 棋子
---@param from XLuckyTenantPiece
function XLuckyTenantOperationProxy:DeletePieceOnBoard(piece, from)
    if not piece then
        XLog.Error("[XLuckyTenantOperationProxy] 删除棋子失败，棋子不存在")  -- 错误日志
        return false
    end

    local uid = piece:GetUid()
    local x, y = piece:GetPosition()  -- 获取棋子的位置
    if self._DeletedPieces[uid] then
        XMVCA.XLuckyTenant:Print(piece:GetName(), "已经被移除，坐标是", x, y)
        return false
    end
    self._DeletedPieces[uid] = true

    ---@type XLuckyTenantOperationDeletePiece
    local operation = XLuckyTenantOperationDeletePiece.New(self)  -- 创建删除棋子操作
    operation:SetData(x, y, from or self.Skill:GetPiece(), self.Skill, piece, from and from:GetPositionIndex(self.Game))  -- 设置棋子位置数据
    self.OperationPackage:Push(operation)  -- 将操作推入操作包

    --local skills = piece:GetSkills(self.Model)
    --for i = 1, #skills do
    --    local skill = skills[i]
    --    skill:OnDestroy(self)
    --end
    return true
end

--- 删除当前棋子
function XLuckyTenantOperationProxy:DeleteSelfPiece(from)
    local isSuccess = self:DeletePieceOnBoard(self.Piece, from)  -- 删除当前棋子
    return isSuccess
end

--- 转换棋子
---@param piece XLuckyTenantPiece 棋子
---@param pieceIdToTransform number 要转换为的棋子ID
function XLuckyTenantOperationProxy:Transform(piece, pieceIdToTransform)
    if not pieceIdToTransform then
        XLog.Error("[XLuckyTenantOperationTransformPiece] 要变形的棋子配置不存在, 技能id是" .. self.Skill:GetId())
        return
    end
    --local operation = XLuckyTenantOperationTransformPiece.New(self)  -- 创建转换棋子操作
    --operation:SetData(piece:GetUid(), pieceIdToTransform)  -- 设置棋子UID和目标棋子ID
    --self.OperationPackage:Push(operation)  -- 将操作推入操作包
    --local nameToTransform = self.Model:GetLuckyTenantChessNameById(pieceIdToTransform)

    -- 转换棋子 改为 消除后添加
    self:DeleteSelfPiece()
    self:AddNewPiece(pieceIdToTransform)
    --XMVCA.XLuckyTenant:Print(string.format("位置(%s,%s)的", piece:GetPosition()), piece:GetName(), "转化为:", nameToTransform)
end

function XLuckyTenantOperationProxy:TransformAndNewPiece(piece, amount, pieceId)
    self:Transform(piece, pieceId)
    if amount > 1 then
        self:AddMultipleNewPieces(amount - 1, pieceId)
    end
end

--- 转换棋子
---@param piece XLuckyTenantPiece 棋子
---@param pieceIdToTransform number 要转换为的棋子ID
function XLuckyTenantOperationProxy:TransformSelf(pieceIdToTransform)
    if not pieceIdToTransform then
        XLog.Error("[XLuckyTenantOperationTransformPiece] 要变形的棋子配置不存在, 技能id是" .. self.Skill:GetId())
        return
    end
    self:Transform(self.Piece, pieceIdToTransform)
    --local operation = XLuckyTenantOperationTransformPiece.New(self)  -- 创建转换棋子操作
    --operation:SetData(self.Piece:GetUid(), pieceIdToTransform)  -- 设置棋子UID和目标棋子ID
    --self.OperationPackage:Push(operation)  -- 将操作推入操作包
end

--- 添加被动技能
---@param skillId number 技能ID
function XLuckyTenantOperationProxy:AddPassiveSkill(skillId)
    local operation = XLuckyTenantOperationAddPassiveSkill.New(self)  -- 创建添加被动技能操作
    operation:SetData(skillId)  -- 设置技能ID数据
    self.OperationPackage:Push(operation)  -- 将操作推入操作包
end

--- 根据位置设置棋子
---@param x number X坐标
---@param y number Y坐标
---@param piece XLuckyTenantPiece 棋子
function XLuckyTenantOperationProxy:SetPieceByPosition(x, y, piece)
    local operation = XLuckyTenantOperationSetPieceByPosition.New(self)  -- 创建设置棋子位置操作
    operation:SetData(x, y, piece:GetUid())  -- 设置位置和棋子UID
    self.OperationPackage:Push(operation)  -- 将操作推入操作包
end

--- 检查是否与某种类型相邻
---@param paramsIndex number 参数索引
function XLuckyTenantOperationProxy:IsNeighbour(paramsIndex)
    local x, y = self.Piece:GetPosition()  -- 获取当前棋子的位置
    local neighbours = self.Neighbours  -- 获取相邻棋子列表
    self.Chessboard:GetNeighbours(x, y, neighbours)  -- 获取相邻棋子
    local isTrigger = false  -- 默认未触发

    local piece
    for i = 1, #neighbours do
        piece = neighbours[i]  -- 遍历相邻棋子
        if piece and piece:GetPieceType() == self.Params[paramsIndex or 1] then
            isTrigger = true  -- 如果相邻棋子的类型匹配，标记为触发
            break
        end
    end
    return isTrigger, piece  -- 返回是否触发
end

--- 检查是否与某种棋子相邻
---@param paramsIndex number 参数索引
function XLuckyTenantOperationProxy:IsNeighbourById(paramsIndex)
    local x, y = self.Piece:GetPosition()  -- 获取当前棋子的位置
    local neighbours = self.Neighbours  -- 获取相邻棋子列表
    self.Chessboard:GetNeighbours(x, y, neighbours)  -- 获取相邻棋子
    local isTrigger = false  -- 默认未触发

    local from
    for i = 1, #neighbours do
        local piece = neighbours[i]  -- 遍历相邻棋子
        if piece and piece:GetId() == self.Params[paramsIndex or 1] then
            from = piece
            isTrigger = true  -- 如果相邻棋子的类型匹配，标记为触发
            break
        end
    end
    return isTrigger, from  -- 返回是否触发
end

function XLuckyTenantOperationProxy:GetNeighboursByType(paramsIndex)
    paramsIndex = paramsIndex or 1
    local pieceType = self.Params[paramsIndex]
    local x, y = self.Piece:GetPosition()  -- 获取当前棋子的位置
    local neighbours = self.Neighbours  -- 获取相邻棋子列表
    self.Chessboard:GetNeighbours(x, y, neighbours)  -- 获取相邻棋子
    local result = {}
    for i = 1, #neighbours do
        local piece = neighbours[i]
        if piece and piece:GetPieceType() == pieceType then
            result[#result + 1] = piece
        end
    end
    return result
end

function XLuckyTenantOperationProxy:GetNeighboursById(paramsIndex)
    paramsIndex = paramsIndex or 1
    local pieceId = self.Params[paramsIndex]
    local x, y = self.Piece:GetPosition()  -- 获取当前棋子的位置
    local neighbours = self.Neighbours  -- 获取相邻棋子列表
    self.Chessboard:GetNeighbours(x, y, neighbours)  -- 获取相邻棋子
    local result = {}
    for i = 1, #neighbours do
        local piece = neighbours[i]
        if piece and piece:GetId() == pieceId then
            result[#result + 1] = piece
        end
    end
    return result
end

--- 检查在多少回合之后生效
---@param paramsIndex number 参数索引
function XLuckyTenantOperationProxy:CheckAfterRounds()
    local skill = self.Skill  -- 获取当前技能

    local remainRounds = skill:GetEffectTurns()
    local isFirstTime = false
    if remainRounds < 0 then
        isFirstTime = true
        local roundsToEffect = skill:GetInitialEffectTurns() -- 获取生效回合数
        -- 第一回合显示时，不加1
        remainRounds = roundsToEffect + 1
    end

    -- 只在第一次计算时，纪录回合
    if self.Times == 1 then
        remainRounds = remainRounds - 1
        if not isFirstTime then
            ---@type XLuckyTenantOperationUpdatePiece
            local operation = XLuckyTenantOperationUpdatePiece.New(self)
            operation:SetData(self.Piece, skill:GetId(), remainRounds)
            self.OperationPackage:Push(operation)
        end
    end
    skill:SetEffectTurns(remainRounds)  -- 设置技能生效剩余回合
    if remainRounds <= 0 then
        skill:SetEffectTurns(-2)  -- 重置回合数
        return true
    end
    return false
end

--- 检查每隔多少个回合生效
---@param paramsIndex number 参数索引
function XLuckyTenantOperationProxy:CheckEveryNTurns()
    local skill = self.Skill  -- 获取当前技能

    local remainRounds = skill:GetEffectTurns()
    local isFirstTime = false
    if remainRounds < 0 then
        isFirstTime = true
        local roundsToEffect = skill:GetInitialEffectTurns() -- 获取生效回合数
        -- 第一回合显示时，不加1
        if remainRounds <= 0 then
            remainRounds = roundsToEffect + 1
        end
    end

    -- 只在第一次计算时，纪录回合
    if self.Times == 1 then
        remainRounds = remainRounds - 1
        skill:SetEffectTurns(remainRounds)

        if not isFirstTime then
            ---@type XLuckyTenantOperationUpdatePiece
            local operation = XLuckyTenantOperationUpdatePiece.New(self)
            operation:SetData(self.Piece, skill:GetId(), remainRounds)
            self.OperationPackage:Push(operation)
        end
    end
    skill:SetEffectTurns(remainRounds)  -- 设置技能生效剩余回合
    if remainRounds <= 0 then
        skill:SetEffectTurns(skill:GetInitialEffectTurns() + 1)  -- 重置回合数
        return true
    end
    return false
end

--- 消除相邻的棋子
---@param paramsIndex number 参数索引
function XLuckyTenantOperationProxy:DeleteNeighbourByType(paramsIndex)
    local times = 0  -- 记录消除的次数
    local x, y = self.Piece:GetPosition()  -- 获取当前棋子的位置
    local neighbours = self.Neighbours  -- 获取相邻棋子列表
    self.Chessboard:GetNeighbours(x, y, neighbours)  -- 获取相邻棋子

    for i = 1, #neighbours do
        local piece = neighbours[i]  -- 遍历相邻棋子
        if piece and piece:GetPieceType() == self.Params[paramsIndex or 1] then
            self:DeletePieceOnBoard(piece)  -- 删除匹配的棋子
            times = times + 1  -- 增加消除次数
        end
    end
    return times  -- 返回消除次数
end

--- 消除相邻的棋子
---@param paramsIndex number 参数索引
function XLuckyTenantOperationProxy:DeleteNeighbourById(paramsIndex)
    local times = 0  -- 记录消除的次数
    local x, y = self.Piece:GetPosition()  -- 获取当前棋子的位置
    local neighbours = self.Neighbours  -- 获取相邻棋子列表
    self.Chessboard:GetNeighbours(x, y, neighbours)  -- 获取相邻棋子

    for i = 1, #neighbours do
        local piece = neighbours[i]  -- 遍历相邻棋子
        if piece and piece:GetId() == self.Params[paramsIndex or 1] then
            self:DeletePieceOnBoard(piece)  -- 删除匹配的棋子
            times = times + 1  -- 增加消除次数
        end
    end
    return times  -- 返回消除次数
end

---@return XLuckyTenantPiece[] 获取相邻棋子
function XLuckyTenantOperationProxy:GetNeighbours()
    local x, y = self.Piece:GetPosition()  -- 获取当前棋子的位置
    local neighbours = self.Neighbours  -- 获取相邻棋子列表
    self.Chessboard:GetNeighbours(x, y, neighbours)  -- 获取相邻棋子
    return neighbours  -- 返回相邻棋子列表
end

function XLuckyTenantOperationProxy:GetChessboardPieces()
    return self.Chessboard:GetPieces()
end

--- 添加棋子本回合有效分数
---@param piece XLuckyTenantPiece 棋子
---@param score number 分数
function XLuckyTenantOperationProxy:AddPieceScoreValidThisRound(piece, score)
    local operation = XLuckyTenantOperationAddPieceScoreValidThisRound.New(self)  -- 创建添加分数操作
    operation:SetData(piece:GetUid(), score)  -- 设置棋子UID和分数
    self.OperationPackage:Push(operation)  -- 将操作推入操作包
end

--- 设置棋子本回合有效分数
---@param piece XLuckyTenantPiece 棋子
---@param score number 分数
function XLuckyTenantOperationProxy:SetPieceScoreValidThisRound(piece, score)
    local tempScore = piece:GetScoreValidThisRound()
    if tempScore ~= score then
        local operation = XLuckyTenantOperationSetPieceScoreValidThisRound.New(self)  -- 创建设置分数操作
        operation:SetData(piece:GetUid(), score, self.Skill)  -- 设置棋子UID和分数
        self.OperationPackage:Push(operation)  -- 将操作推入操作包
    end
end

function XLuckyTenantOperationProxy:AddPieceValueUponDeletion(piece, value)
    local operation = XLuckyTenantOperationAddValueUponDeletion.New(self)
    operation:SetData(piece, value)
    self.OperationPackage:Push(operation)
end

function XLuckyTenantOperationProxy:RandomFrom1To100(percent)
    if math.random(1, 100) <= percent then
        return true
    end
    return false
end

---@param piece XLuckyTenantPiece
function XLuckyTenantOperationProxy:AddToDelete(piece)
    self._ToDelete[piece:GetUid()] = piece
end

function XLuckyTenantOperationProxy:ExecuteToDelete()
    for uid, piece in pairs(self._ToDelete) do
        self.Game:GetBag():DeletePieceByUid(uid)
        self._ToDelete[uid] = nil
    end
end

function XLuckyTenantOperationProxy:IsToDelete(piece)
    if self._ToDelete[piece] then
        return true
    end
    return false
end

function XLuckyTenantOperationProxy:AddPiecesFromRandomGroup(groupId, amount)
    local elements = {}
    self.Game:GetRandomBucketByGroupId(elements, self.Model, groupId)
    local selected = self.Game:RandomSelect(self.Model, elements, amount)
    local x, y = self.Piece:GetPosition()
    for i = 1, #selected do
        ---@type XTableLuckyTenantChessRandomGroup
        local groupConfig = selected[i]
        local pieceId = groupConfig.PieceId
        self:AddNewPiece(pieceId, x, y)
    end
end

function XLuckyTenantOperationProxy:GetOperationsLastCalculate()
    return self._OperationsLastCalculate
end

function XLuckyTenantOperationProxy:SetOperationsLastCalculate(record)
    self._OperationsLastCalculate = record
end

return XLuckyTenantOperationProxy