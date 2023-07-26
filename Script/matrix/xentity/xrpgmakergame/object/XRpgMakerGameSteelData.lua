local XRpgMakerGameObject = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameObject")

local type = type
local pairs = pairs
local Vector3 = CS.UnityEngine.Vector3

---钢板对象
---@class XRpgMakerGameSteelData:XRpgMakerGameObject
local XRpgMakerGameSteelData = XClass(XRpgMakerGameObject, "XRpgMakerGameSteelData")

function XRpgMakerGameSteelData:Ctor(id, gameObject)
    self.SteelStatus = XRpgMakerGameConfigs.XRpgMakerGameSteelBrokenType.Init
    self.IsCheckPlayFlat = false    --是否需要根据当前的状态加载对应的特效
end

function XRpgMakerGameSteelData:InitData()
    -- local id = self:GetId()
    -- local x = XRpgMakerGameConfigs.GetEntityX(id)
    -- local y = XRpgMakerGameConfigs.GetEntityY(id)
    -- self:UpdatePosition({PositionX = x, PositionY = y})
    if not XTool.IsTableEmpty(self.MapObjData) then
        self:InitDataByMapObjData(self.MapObjData)
    end
    self:SetStatus(XRpgMakerGameConfigs.XRpgMakerGameSteelBrokenType.Init)
end

---@param mapObjData XMapObjectData
function XRpgMakerGameSteelData:InitDataByMapObjData(mapObjData)
    self.MapObjData = mapObjData
    self:UpdatePosition({PositionX = self.MapObjData:GetX(), PositionY = self.MapObjData:GetY()})
end

---@return XMapObjectData
function XRpgMakerGameSteelData:GetMapObjData()
    return self.MapObjData
end

--0正常，1破损
function XRpgMakerGameSteelData:SetStatus(steelType)
    if self.SteelStatus ~= steelType then
        self.IsCheckPlayFlat = true
    end
    self.SteelStatus = steelType
end

function XRpgMakerGameSteelData:GetStatus()
    return self.SteelStatus
end

--检查加载哪种特效
function XRpgMakerGameSteelData:CheckPlayFlat()
    if not self.IsCheckPlayFlat then
        return
    end

    local status = self:GetStatus()
    local modelKey = status == XRpgMakerGameConfigs.XRpgMakerGameSteelBrokenType.Init and 
        XRpgMakerGameConfigs.ModelKeyMaps.Steel or
        XRpgMakerGameConfigs.ModelKeyMaps.SteelBroken
    local modelPath = XRpgMakerGameConfigs.GetRpgMakerGameModelPath(modelKey)
    self:LoadModel(modelPath)
    self.IsCheckPlayFlat = false

    if status == XRpgMakerGameConfigs.XRpgMakerGameSteelBrokenType.Flat or status == XRpgMakerGameConfigs.XRpgMakerGameSteelBrokenType.Trap then
        XSoundManager.PlaySoundByType(XSoundManager.UiBasicsMusic.RpgMakerGame_Broken, XSoundManager.SoundType.Sound)
    end
end

return XRpgMakerGameSteelData