---@class XRogueSimMapArea
local XRogueSimMapArea = XClass(nil, "XRogueSimMapArea")

function XRogueSimMapArea:Ctor(data)
    self.Id = data.Id
    self.State = data.State
    self.IsObtain = data.IsObtain
end

-- 更新区域数据
function XRogueSimMapArea:UpdateData(data)
    self.State = data.State or 0
end

-- 设置区域解锁
function XRogueSimMapArea:SetUnlock()
    self.State = XEnumConst.RogueSim.AreaStateType.Unlocked
end

-- 是否已解锁
function XRogueSimMapArea:GetIsUnlock()
    return self.State == XEnumConst.RogueSim.AreaStateType.Unlocked
end

-- 设置区域已获得
function XRogueSimMapArea:SetObtain()
    self.IsObtain = 1
end

-- 是否已获得
function XRogueSimMapArea:GetIsObtain()
    return self.IsObtain > 0
end

return XRogueSimMapArea
