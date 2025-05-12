local XLuckyTenantEnum = require("XModule/XLuckyTenant/Game/XLuckyTenantEnum")
local XLuckyTenantOperation = require("XModule/XLuckyTenant/Game/Operation/XLuckyTenantOperation")

---@class XLuckyTenantOperationAddPieceValue:XLuckyTenantOperation
local XLuckyTenantOperationAddPieceValue = XClass(XLuckyTenantOperation, "XLuckyTenantOperationAddPieceValue")

function XLuckyTenantOperationAddPieceValue:Ctor()
    self._Type = XLuckyTenantEnum.Operation.AddPieceValue
    self._PieceUid = 0
    self._Value = 0
end

function XLuckyTenantOperationAddPieceValue:SetData(uid, value, skill, name)
    self._PieceUid = uid
    if uid == 0 then
        XLog.Error("[XLuckyTenantOperationAddPieceValue] ")
    end
    if not value then
        XLog.Error("增加棋子价值，但是 value=0")
        value = 0
    end

    self._Value = value
    if skill then
        local piece = skill:GetPiece()
        if piece then
            local px, py = piece:GetPosition()
            XMVCA.XLuckyTenant:Print("增加棋子价值", name, value, "分", " " .. piece:GetName() .. "(" .. px .. "," .. py .. ")" .. ":技能id:" .. skill:GetId() .. "," .. skill:GetDesc())
        end
    end
end

---@param animationGroup XLuckyTenantAnimationGroup
function XLuckyTenantOperationAddPieceValue:Do(model, game, animationGroup)
    local bag = game:GetBag()
    local piece = bag:GetPiece(self._PieceUid)
    if not piece then
        XMVCA.XLuckyTenant:Print("[XLuckyTenantOperationTransformPiece] 要加分的棋子已经不存在了:" .. tostring(self._PieceUid))
        return false
    end
    piece:SetValue(piece:GetValue() + self._Value)

    animationGroup:SetAnimation({
        Type = XLuckyTenantEnum.Animation.Shake,
        Position = self._SourcePosition,
    })
    animationGroup:SetAnimation({
        Type = XLuckyTenantEnum.Animation.Shake,
        Position = piece:GetPositionIndex(game),
    })
    animationGroup:SetAnimation({
        Type = XLuckyTenantEnum.Animation.AddScore,
        Position = piece:GetPositionIndex(game),
        PieceUiData = piece:GetUiData(model, game)
    })

    return true
end

return XLuckyTenantOperationAddPieceValue
