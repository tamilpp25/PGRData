---@class XRogueSimBuildingBluePrint
local XRogueSimBuildingBluePrint = XClass(nil, "XRogueSimBuildingBluePrint")

function XRogueSimBuildingBluePrint:Ctor()
    self.Id = 0
    self.Count = 0
end

function XRogueSimBuildingBluePrint:UpdateBuildingBluePrintData(data)
    self.Id = data.Id or 0
    self.Count = data.Count or 0
end

function XRogueSimBuildingBluePrint:GetId()
    return self.Id
end

function XRogueSimBuildingBluePrint:GetCount()
    return self.Count
end

return XRogueSimBuildingBluePrint
