local XNormalGWNode = require("XEntity/XGuildWar/Battle/Node/XNormalGWNode")

---@class XTerm4BossChildGWNode:XGWNode@ 4期boss
local XTerm4BossChildGWNode = XClass(XNormalGWNode, "XTerm4BossChildGWNode")

function XTerm4BossChildGWNode:Ctor(id)
end

function XTerm4BossChildGWNode:GetShowMonsterName()
    local lv = self:GetBossLevel()
    return self.Super.GetShowMonsterName(self) .. " Lv." .. lv
end

function XTerm4BossChildGWNode:GetBossLevel()
    return self:GetParentNode():GetBossLevel()
end

return XTerm4BossChildGWNode
