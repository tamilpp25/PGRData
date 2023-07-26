---@class XTheatre3Character
local XTheatre3Character = XClass(nil, "XTheatre3Character")

function XTheatre3Character:Ctor()
    ---角色
    self.CharacterId = 0
    ---当前等级
    self.Level = 0
    ---当前经验（结算时要加上ExpTemp）
    self.Exp = 0
    ---临时经验，结算再通过此字段计算等级和经验
    self.ExpTemp = 0
    ---已达成结局ID, 引自CharacterEnding表Id
    self.EndingIds = {}
end

--region DataUpdate
function XTheatre3Character:UpdateEndingIds(data)
    self.EndingIds = { }
    if XTool.IsTableEmpty(data) then
        return
    end
    for _, endingId in ipairs(data) do
        self.EndingIds[endingId] = true
    end
end

function XTheatre3Character:SetLevel(level)
    self.Level = level
end

function XTheatre3Character:SetExp(exp)
    self.Exp = exp
end

function XTheatre3Character:SetExpTemp(expTemp)
    self.ExpTemp = expTemp
end
--endregion

--region Checker
function XTheatre3Character:CheckEnding(endingId)
    return self.EndingIds[endingId]
end
--endregion

function XTheatre3Character:NotifyTheatre3Character(data)
    self.CharacterId = data.CharacterId
    self.Level = data.Level
    self.Exp = data.Exp
    self.ExpTemp = data.ExpTemp
    self:UpdateEndingIds(data.EndingIds)
end

return XTheatre3Character