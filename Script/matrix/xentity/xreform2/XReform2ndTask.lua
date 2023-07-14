---@class XReform2ndTask
local XReform2ndTask = XClass(nil, "XReform2ndTask")

function XReform2ndTask:Ctor(id, totalStar, state)
    self.Id = id
    self.TotalStar = totalStar
    self.State = state
end

function XReform2ndTask:GetId()
    return self.Id
end

function XReform2ndTask:SetId(id)
    self.Id = id
end

function XReform2ndTask:GetTotalStar()
    return self.TotalStar
end

function XReform2ndTask:SetTotalStar(totalStar)
    self.TotalStar = totalStar
end

function XReform2ndTask:GetState()
    return self.State
end

function XReform2ndTask:SetState(state)
    self.State = state
end

return XReform2ndTask
