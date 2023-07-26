local XSmashBAssistanceMonsterViewModel = require("XEntity/XSuperSmashBros/XSmashBAssistanceMonsterViewModel")

---@class XSmashBAssistanceMonsterRawData:XSmashBCharacter
local XSmashBAssistanceMonsterRawData = XClass(nil, "XSmashBAssistanceMonsterRawData")

function XSmashBAssistanceMonsterRawData:Ctor(config)
    self._Config = config
    self.CharacterViewModel = false
end

function XSmashBAssistanceMonsterRawData:GetCharacterViewModel()
    if self.CharacterViewModel == nil then
        self.CharacterViewModel = XSmashBAssistanceMonsterViewModel.New(self._Config.AssistId)
    end
    return self.CharacterViewModel
end

return XSmashBAssistanceMonsterRawData