local XCharacterViewModel = require("XEntity/XCharacter/XCharacterViewModel")

local XSmashBAssistanceMonsterViewModel = XClass(XCharacterViewModel, "XSmashBAssistanceMonsterViewModel")

function XSmashBAssistanceMonsterViewModel:Ctor(config)
    self.Config = config
    self.Id = self.Config.AssistId
end

function XSmashBAssistanceMonsterViewModel:GetCharacterType()
    return 1
end

return XCharacterViewModel