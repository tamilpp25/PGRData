---@class XFangKuaiRuleExpand
local XFangKuaiRuleExpand = XClass(nil, "XFangKuaiRuleExpand")

function XFangKuaiRuleExpand:Ctor()
    ---@type XTableFangKuaiStageBlockRule[]|XTableFangKuaiStageItemRule[]
    self.Rules = {}
    self.MinKey = 0
    self.MaxKey = 0
end

function XFangKuaiRuleExpand:UpdateKeyRange()
    local min = math.maxinteger
    local max = math.mininteger
    for key, _ in pairs(self.Rules) do
        if key < min then
            min = key
        end
        if key > max then
            max = key
        end
    end
    self.MinKey = min
    self.MaxKey = max
end

return XFangKuaiRuleExpand