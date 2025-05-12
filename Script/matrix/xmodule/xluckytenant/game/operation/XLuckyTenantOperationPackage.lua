local XLuckyTenantAnimationGroup = require("XModule/XLuckyTenant/Game/Animation/XLuckyTenantAnimationGroup")

---@class XLuckyTenantOperationPackage
local XLuckyTenantOperationPackage = XClass(nil, "XLuckyTenantOperationPackage")

function XLuckyTenantOperationPackage:Ctor()
    self._Operations = {}
end

function XLuckyTenantOperationPackage:Push(operation)
    self._Operations[#self._Operations + 1] = operation
end

function XLuckyTenantOperationPackage:GetOperations()
    return self._Operations
end

function XLuckyTenantOperationPackage:IsNotEmpty()
    return #self._Operations > 0
end

function XLuckyTenantOperationPackage:Do(model, game, animationGroup, proxy)
    local operations = self._Operations
    for i = 1, #operations do
        ---@type XLuckyTenantOperation
        local operation = operations[i]
        operation:Do(model, game, animationGroup, proxy)
    end
end

function XLuckyTenantOperationPackage:SaveRecord(record)
    for i = 1, #self._Operations do
        record[#record + 1] = self._Operations[i]
    end
end

return XLuckyTenantOperationPackage