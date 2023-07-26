---@class XGoldenMinerComponentBuff
local XGoldenMinerComponentBuff = XClass(nil, "XGoldenMinerComponentBuff")

function XGoldenMinerComponentBuff:Ctor()
    self.Status = XGoldenMinerConfigs.GAME_HOOK_ENTITY_STATUS
    self.Id = 0
    self.BuffType = 0
    self.BuffParams = {}
    
    self.TimeType = 0
    self.TimeTypeParam = 0
    self.CurTimeTypeParam = 0
end

return XGoldenMinerComponentBuff