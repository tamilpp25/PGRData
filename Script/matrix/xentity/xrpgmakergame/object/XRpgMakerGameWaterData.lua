local XRpgMakerGameObject = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameObject")

local type = type
local pairs = pairs
local Vector3 = CS.UnityEngine.Vector3

--水、冰对象
local XRpgMakerGameWaterData = XClass(XRpgMakerGameObject, "XRpgMakerGameWaterData")

function XRpgMakerGameWaterData:Ctor(id, gameObject)
    self.WaterStatus = XRpgMakerGameConfigs.XRpgMakerGameWaterType.Water
    self.IsCheckPlayFlat = false    --是否需要根据当前的状态加载对应的特效
end

function XRpgMakerGameWaterData:InitData()
    local id = self:GetId()
    local x = XRpgMakerGameConfigs.GetEntityX(id)
    local y = XRpgMakerGameConfigs.GetEntityY(id)
    self:UpdatePosition({PositionX = x, PositionY = y})
    
    local type = XRpgMakerGameConfigs.GetEntityType(id)
    self:SetStatus(type == XRpgMakerGameConfigs.XRpgMakerGameEntityType.Water and 
        XRpgMakerGameConfigs.XRpgMakerGameWaterType.Water or
        XRpgMakerGameConfigs.XRpgMakerGameWaterType.Ice)
end

--1水，2冰
function XRpgMakerGameWaterData:SetStatus(waterType)
    if self.WaterStatus ~= waterType then
        self.IsCheckPlayFlat = true
    end
    self.WaterStatus = waterType
end

function XRpgMakerGameWaterData:GetStatus()
    return self.WaterStatus
end

--检查加载哪种特效
function XRpgMakerGameWaterData:CheckPlayFlat()
    if not self.IsCheckPlayFlat then
        return
    end

    local status = self:GetStatus()
    local modelKey = (status == XRpgMakerGameConfigs.XRpgMakerGameWaterType.Ice and XRpgMakerGameConfigs.ModelKeyMaps.Freeze) or
        (status == XRpgMakerGameConfigs.XRpgMakerGameWaterType.Melt and XRpgMakerGameConfigs.ModelKeyMaps.Melt) or
        XRpgMakerGameConfigs.ModelKeyMaps.WaterRipper
        
    local modelPath = XRpgMakerGameConfigs.GetRpgMakerGameModelPath(modelKey)
    self:LoadModel(modelPath, nil, nil, modelKey)

    --融化动画播完后切换水波纹特效
    if status == XRpgMakerGameConfigs.XRpgMakerGameWaterType.Melt then
        XScheduleManager.ScheduleOnce(function()
            self:LoadModel(XRpgMakerGameConfigs.GetRpgMakerGameModelPath(XRpgMakerGameConfigs.ModelKeyMaps.WaterRipper))
        end, 500)
    end
    self.IsCheckPlayFlat = false

    --播放音效
    if status == XRpgMakerGameConfigs.XRpgMakerGameWaterType.Ice then
        XSoundManager.PlaySoundByType(XSoundManager.UiBasicsMusic.RpgMakerGame_Frezz, XSoundManager.SoundType.Sound)
    elseif status == XRpgMakerGameConfigs.XRpgMakerGameWaterType.Melt then
        XSoundManager.PlaySoundByType(XSoundManager.UiBasicsMusic.RpgMakerGame_Melt, XSoundManager.SoundType.Sound)
    end
end

return XRpgMakerGameWaterData