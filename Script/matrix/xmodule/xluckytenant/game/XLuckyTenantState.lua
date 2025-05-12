local XLuckyTenantState = XClass(nil, "XLuckyTenantState")
local STATE = {
    ENABLE = 1,
    UPDATE = 2,
    END = 3,
}

function XLuckyTenantState:Ctor()
    self._State = 0
end

return XLuckyTenantState