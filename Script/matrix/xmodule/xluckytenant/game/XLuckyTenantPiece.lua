local XLuckyTenantEnum = require("XModule/XLuckyTenant/Game/XLuckyTenantEnum")
local XLuckyTenantChessSkill = require("XModule/XLuckyTenant/Game/Skill/XLuckyTenantChessSkill")

---@class XLuckyTenantPiece
local XLuckyTenantPiece = XClass(nil, "XLuckyTenantPiece")

function XLuckyTenantPiece:Ctor(uid, config)
    self._Id = 0
    self._Uid = 0
    self._PieceType = 0
    self._Quality = 0
    self._Name = ""
    self._Desc = false
    self._InitialValue = 0
    self._ScoreValidThisRound = 0
    self._Icon = false
    self._IsCanDelete = false
    self._IsCanDie = false
    self._SkillId = false
    self._Tag = false

    self._Amount = 0
    self._Value = 0
    self._ValueUponDeletion = 0
    self._InitialValueUponDeletion = 0

    self._IsPiece = false
    self._IsProp = false
    ---@type XLuckyTenantChessSkill[]
    self._Skills = false

    self._X = 0
    self._Y = 0

    -- 非鸦技能需要动态显示概率
    self._IsDescDynamic = true
    self._DynamicDesc = false
    self._IsHideRound = false
end

function XLuckyTenantPiece:ResetPosition()
    self._X = 0
    self._Y = 0
end

function XLuckyTenantPiece:SetConfigAndClear(config)
    self:Clear()
    self:__SetConfig(config)
end

function XLuckyTenantPiece:SetConfigButRetainPositionAndUid(config)
    self:ClearButRetainPositionAndUid()
    self:__SetConfig(config)
end

---@param config XTable.XTableLuckyTenantChess
function XLuckyTenantPiece:__SetConfig(config)
    if config then
        self._Id = config.Id
        self._Amount = 1
        self._PieceType = config.Type
        self._Quality = config.Quality
        self._Name = config.Name
        self._Desc = config.Desc
        self._InitialValue = config.Value
        self._Value = config.Value
        self._Icon = config.Icon
        self._IsCanDelete = config.CanDelete
        self._IsCanDie = config.CanDie
        self._SkillId = config.SkillId
        self._Tag = config.Tag
        self._ValueUponDeletion = config.ValueUponDeletion
        self._InitialValueUponDeletion = self._ValueUponDeletion
        local isProp = config.Type == XLuckyTenantEnum.Item.DeleteProp
                or config.Type == XLuckyTenantEnum.Item.RefreshProp
        self._IsProp = isProp
        self._IsPiece = not isProp
    else
        XLog.Error("[XLuckyTenantPiece] 设置棋子config失败")
    end
end

function XLuckyTenantPiece:SetUid(uid)
    self._Uid = uid
end

function XLuckyTenantPiece:Set(uid, config)
    self:SetConfigAndClear(config)
    self:SetUid(uid)
end

function XLuckyTenantPiece:SetPosition(x, y)
    self._X = x
    self._Y = y
    if self._Uid == 9 then
        XMVCA.XLuckyTenant:Print(self._Name, self._Uid, "设置坐标", x, y)
    end
end

function XLuckyTenantPiece:GetName()
    if XMain.IsZlbDebug then
        return self._Name .. "\nid:" .. self._Id .. " Uid:" .. self._Uid
    end
    return self._Name
end

---@param model  XLuckyTenantModel
function XLuckyTenantPiece:GetDesc(model)
    if self._IsDescDynamic then
        local skills = self:GetSkills(model)
        if skills then
            local isFind = false
            for i = 1, #skills do
                local skill = skills[i]
                -- 非鸦技能需要动态显示概率
                if skill:GetType() == XLuckyTenantEnum.Skill.Type55 then
                    if not self._DynamicDesc then
                        self._DynamicDesc = XTool.CloneEx(self._Desc)
                    end
                    for i = 1, #self._Desc do
                        if string.find(self._Desc[i], "percent") then
                            isFind = true
                            local extraPercent = skill:GetExtraPercent()
                            self._DynamicDesc[i] = string.gsub(self._Desc[i], "percent", skill:GetParams()[1] + extraPercent)
                        end
                    end
                    break
                end
            end
            if not isFind then
                self._IsDescDynamic = false
            end
        end
    end
    if self._DynamicDesc then
        return self._DynamicDesc
    end
    return self._Desc
end

function XLuckyTenantPiece:SetDescDirty()
    self._IsDescDynamic = true
end

function XLuckyTenantPiece:IsPiece()
    return self._IsPiece
end

function XLuckyTenantPiece:IsCanDelete()
    return self._IsCanDelete
end

function XLuckyTenantPiece:IsProp()
    return self._IsProp
end

function XLuckyTenantPiece:GetAmount()
    return self._Amount
end

function XLuckyTenantPiece:HasTag(tag)
    for i = 1, #self._Tag do
        if self._Tag[i] == tag then
            return true
        end
    end
    return false
end

function XLuckyTenantPiece:GetTag()
    return self._Tag
end

function XLuckyTenantPiece:SetAmount(value)
    if self._IsPiece and value ~= 1 then
        XLog.Error("[XLuckyTenantPiece] 棋子数量只能为1")
        return
    end
    self._Amount = value
end

function XLuckyTenantPiece:GetUid()
    return self._Uid
end

function XLuckyTenantPiece:GetId()
    return self._Id
end

-- 因为变身后, uid不变, 但是id发生了变化
function XLuckyTenantPiece:GetIdConcatUid()
    local id = (self._Uid << 10) | self._Id
    return id
end

---@param piece XLuckyTenantPiece
function XLuckyTenantPiece:Equals(piece)
    return self._Uid == piece:GetUid()
end

---@return XLuckyTenantChessSkill[]
function XLuckyTenantPiece:GetSkills(model)
    if not self._Skills then
        if not model then
            XMVCA.XLuckyTenant:Print("[XLuckyTenantPiece] 删除技能未初始化的棋子")
            return
        end
        self._Skills = {}
        local skillId = self._SkillId
        for i = 1, #skillId do
            local id = skillId[i]
            ---@type XLuckyTenantChessSkill
            local skill = XLuckyTenantChessSkill.New()
            skill:Set(self, id, model)
            self._Skills[#self._Skills + 1] = skill
        end
    end
    return self._Skills
end

function XLuckyTenantPiece:GetInitialValue()
    return self._InitialValue
end

function XLuckyTenantPiece:GetValue()
    return self._Value
end

function XLuckyTenantPiece:GetValueIncludingTemp()
    return self._Value + self._ScoreValidThisRound
end

function XLuckyTenantPiece:GetScoreValidThisRound()
    return self._ScoreValidThisRound
end

function XLuckyTenantPiece:SetScoreValidThisRound(value)
    self._ScoreValidThisRound = math.min(999, value)
end

function XLuckyTenantPiece:AddScoreValidThisRound(value)
    self._ScoreValidThisRound = math.min(999, self._ScoreValidThisRound + value)
end

function XLuckyTenantPiece:GetPosition()
    return self._X, self._Y
end

---@param game XLuckyTenantGame
function XLuckyTenantPiece:GetPositionIndex(game)
    return game:GetChessboard():GetIndex(self._X, self._Y)
end

function XLuckyTenantPiece:IsOnChessboard()
    if self._X > 0 and self._Y > 0 then
        return true
    end
    return false
end

function XLuckyTenantPiece:GetIcon()
    return self._Icon
end

function XLuckyTenantPiece:SetValue(value)
    if value > 999 then
        XLog.Error("[XLuckyTenantPiece] 棋子价值超过999")
        value = 999
    end
    self._Value = value
end

function XLuckyTenantPiece:GetPieceType()
    return self._PieceType
end

function XLuckyTenantPiece:GetQuality()
    return self._Quality
end

function XLuckyTenantPiece:ClearEveryTurn()
    -- 清空临时值
    self:ResetPosition()
    self:SetScoreValidThisRound(0)
    self._IsHideRound = false
end

function XLuckyTenantPiece:ClearButRetainPositionAndUid()
    self._DynamicDesc = false
    self._IsDescDynamic = true
    self._Id = 0
    self._Amount = 0
    self._PieceType = 0
    self._Quality = 0
    self._Name = ""
    self._InitialValue = 0
    self._Value = 0
    self._ScoreValidThisRound = 0
    self._Icon = false
    self._IsCanDelete = false
    self._IsCanDie = false
    self._SkillId = false
    self._ValueUponDeletion = 0
    self._InitialValueUponDeletion = 0
    self._Tag = false
    self._IsPiece = false
    self._IsProp = false
    if self._Skills then
        for i = 1, #self._Skills do
            local skill = self._Skills[i]
            skill:ClearPiece()
        end
    end
    self._Skills = false
end

function XLuckyTenantPiece:Clear()
    self:ClearButRetainPositionAndUid()
    self:ResetPosition()
end

function XLuckyTenantPiece:GetSkillEffectRemainingTurns(model, currentTurns)
    local skills = self:GetSkills(model)
    local turns
    ---@type XLuckyTenantChessSkill
    local maxSkill
    for i = #skills, 1, -1 do
        local skill = skills[i]
        if skill:IsEffectEveryNTurns() then
            -- 每回合生效的棋子，不显示
            local initialEffectTurns = skill:GetInitialEffectTurns()
            if initialEffectTurns > 0 then
                maxSkill = skill
                local effectTurns = skill:GetEffectTurns()
                if effectTurns then
                    local remainingTurns = effectTurns
                    if remainingTurns > 0 then
                        turns = remainingTurns
                    elseif remainingTurns == 0 then
                        turns = false
                    elseif remainingTurns < 0 then
                        turns = initialEffectTurns
                    end
                end
                if not turns then
                    turns = initialEffectTurns
                end
                break
            end
        end
    end
    return turns or false, maxSkill
end

function XLuckyTenantPiece:GetValueUponDeletion()
    return self._ValueUponDeletion
end

function XLuckyTenantPiece:SetValueUponDeletion(value)
    self._ValueUponDeletion = math.min(999, value)
end

function XLuckyTenantPiece:FindSkill(model, skillId)
    local skills = self:GetSkills(model)
    for i = 1, #skills do
        local skill = skills[i]
        if skill:GetId() == skillId then
            return skill
        end
    end
end

---@param message XLuckyTenantPieceMessage
function XLuckyTenantPiece:DecodeMessage(message, model)
    if message.Value then
        self:SetValue(message.Value)
    end
    if message.Amount then
        self:SetAmount(message.Amount)
    end
    if message.ValueUponDeletion then
        self:SetValueUponDeletion(message.ValueUponDeletion)
    end
    if message.Skills then
        for i, skillData in pairs(message.Skills) do
            local skill = self:FindSkill(model, skillData.SkillId)
            if skill then
                if skillData.EffectTurns then
                    skill:SetEffectTurns(skillData.EffectTurns)
                end
                if skillData.LastDeletedAmount then
                    skill:SetLastDeletedAmount(skillData.LastDeletedAmount)
                end
                if skillData.ExtraPercent then
                    skill:SetExtraPercent(skillData.ExtraPercent)
                end
                if skillData.IsHideRound then
                    self:SetHideRound()
                end
            end
        end
    end
end

function XLuckyTenantPiece:GetEncodeMessage()
    local params = XMessagePack.Encode(self:GetParamsEncodeMessage())
    local message = {
        ChessId = self:GetId(),
        Uid = self:GetUid(),
        ChessParams = params,
    }
    return message
end

function XLuckyTenantPiece:GetParamsEncodeMessage()
    local amount = self._Amount
    -- 节约一点
    --if amount <= 1 then
    --    amount = nil
    --end
    local value = self._Value
    if value == self._InitialValue then
        value = nil
    end
    local valueUponDeletion = self._ValueUponDeletion
    if valueUponDeletion == self._InitialValueUponDeletion then
        valueUponDeletion = nil
    end
    ---@class XLuckyTenantPieceMessage
    local message = {
        Amount = amount,
        Value = value,
        ValueUponDeletion = valueUponDeletion,
        Skills = nil
    }
    if self._Skills then
        for i = 1, #self._Skills do
            local skill = self._Skills[i]
            local effectTurns = skill:GetEffectTurns()
            local isHideRound = nil
            if effectTurns == -1 then
                effectTurns = nil
            end
            if skill:IsEffectEveryNTurns() then
                if self:GetIsHideRound() then
                    isHideRound = true
                end
            end
            local extraPercent = skill:GetExtraPercent()
            if extraPercent == 0 then
                extraPercent = nil
            end
            local lastDeletedAmount = skill:GetLastDeletedAmount()
            if lastDeletedAmount == 0 then
                lastDeletedAmount = nil
            end
            if effectTurns or lastDeletedAmount or extraPercent or isHideRound then
                message.Skills = message.Skills or {}
                message.Skills[tostring(i)] = {
                    EffectTurns = effectTurns,
                    LastDeletedAmount = lastDeletedAmount,
                    ExtraPercent = extraPercent,
                    SkillId = skill:GetId(),
                    IsHideRound = isHideRound
                }
            end
        end
    end
    return message
end

---@param model XLuckyTenantModel
---@param data XUiLuckyTenantChessGridData
function XLuckyTenantPiece:GetUiData(model, game, data)
    data = data or {}
    data.Icon = self:GetIcon()
    local quality = self:GetQuality()
    data.Quality = model:GetQualityIconQuad(quality)
    data.QualityValue = quality
    data.Uid = self:GetUid()
    data.Name = self:GetName()
    data.IsValid = true
    data.Score = self:GetValueIncludingTemp()
    data.Value = self:GetValue()
    data.ValueUponDeletion = self:GetValueUponDeletion()
    local currentTurns = game:GetRound()
    if self._IsHideRound then
        data.Round = false
    else
        ---@type XLuckyTenantChessSkill
        local skill
        data.Round, skill = self:GetSkillEffectRemainingTurns(model, currentTurns)
        if skill then
            data.RoundInFact = skill:GetEffectTurns()
        end
    end
    if XMain.IsZlbDebug then
        if self:GetValueUponDeletion() > 0 then
            data.Score = data.Score .. string.format("(%s)", self:GetValueUponDeletion())
        end
    end
    return data
end

function XLuckyTenantPiece:SetHideRound()
    self._IsHideRound = true
end

function XLuckyTenantPiece:GetIsHideRound()
    return self._IsHideRound
end

return XLuckyTenantPiece