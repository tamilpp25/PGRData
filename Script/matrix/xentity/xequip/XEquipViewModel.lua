local XEquip = require("XEntity/XEquip/XEquip")
local XEquipViewModel = XClass(nil, "XEquipViewModel")

function XEquipViewModel:Ctor(equipCid)
    self.Config = XMVCA.XEquip:GetConfigEquip(equipCid)
    -- XEquip
    self.Equip = nil
    self.UpdatedData = nil
    -- 初始化来自XEquip的默认字段,保持一致性
    for key, value in pairs(XEquip.GetDefaultFields()) do
        if type(value) == "table" then
            self[key] = XTool.Clone(value)
        else
            self[key] = value
        end
    end
end

function XEquipViewModel:UpdateWithData(data)
    self.UpdatedData = data
    for key, value in pairs(data) do
        self[key] = value
    end
end

function XEquipViewModel:GetName()
    return XMVCA.XEquip:GetEquipName(self.Config.Id)
end

function XEquipViewModel:GetLevel()
    return self.Level
end

function XEquipViewModel:GetQualityIcon()
    return XMVCA.XEquip:GetEquipQualityPath(self.Config.Id)
end

function XEquipViewModel:GetIcon()
    return XMVCA.XEquip:GetEquipIconPath(self.Config.Id, self.Breakthrough)
end

function XEquipViewModel:GetResonanceInfos()
    return self.ResonanceInfo
end

function XEquipViewModel:GetBreakthrough()
    return self.Breakthrough
end

function XEquipViewModel:GetEquip()
    if self.Equip == nil then
        self.Equip = XEquip.New(self.UpdatedData)
    end 
    return self.Equip   
end

function XEquipViewModel:GetSuitId()
    return self.Config.SuitId
end

return XEquipViewModel