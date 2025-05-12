local XLuckyTenantEnum = require("XModule/XLuckyTenant/Game/XLuckyTenantEnum")

---@class XLuckyTenantOperation
local XLuckyTenantOperation = XClass(nil, "XLuckyTenantOperation")

---@param proxy XLuckyTenantOperationProxy
function XLuckyTenantOperation:Ctor(proxy)
    self._Type = XLuckyTenantEnum.Operation.None
    if proxy and proxy.Piece then
        self._SourcePosition = proxy.Game:GetChessboard():GetIndex(proxy.Piece:GetPosition())
    else
        XLog.Error("[XLuckyTenantOperation] 发动技能的piece主体不存在")
    end
end

---@param model XLuckyTenantModel
---@param game XLuckyTenantGame
function XLuckyTenantOperation:Do(model, game, animationGroup, proxy)
    XLog.Error("[XLuckyTenantOperation] do nothing")
    return true
end

function XLuckyTenantOperation:GetType()
    return self._Type
end

return XLuckyTenantOperation
