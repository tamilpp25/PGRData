--- 玩法分数的封装，方便使用buff机制暂存结果
---@class XBagOrganizeScoreEntity: XBagOrganizeScopeEntity
local XBagOrganizeScoreEntity = XClass(require('XModule/XBagOrganizeActivity/InGame/Entity/XBagOrganizeScopeEntity'), 'XBagOrganizeScoreEntity')

function XBagOrganizeScoreEntity:Ctor()
    self.Id = 'TotalScore'
    ---@type XBagOrganizeNumVal
    self.Value = require('XModule/XBagOrganizeActivity/InGame/Entity/XBagOrganizeNumVal').New(self)
end


return XBagOrganizeScoreEntity