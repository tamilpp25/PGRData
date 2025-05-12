---@class XInstrumentSimulatorAgency : XAgency
---@field private _Model XInstrumentSimulatorModel
local XInstrumentSimulatorAgency = XClass(XAgency, "XInstrumentSimulatorAgency")
function XInstrumentSimulatorAgency:OnInit()
    --初始化一些变量
    self.InstrumentPlayingAudioState = {}
end

function XInstrumentSimulatorAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
end

function XInstrumentSimulatorAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

----------public start----------
function XInstrumentSimulatorAgency:OpenUi(furnitureId)
    -- local enum = XEnumConst.InstrumentSimulator.InstrumentFurnitureId
    -- if furnitureId == enum.Piano then
    -- end
    XLuaUiManager.Open("UiPianoSimulator", furnitureId)
end

function XInstrumentSimulatorAgency:CheckIsInstrumentPlayingAudio(furnitureId)
    return self.InstrumentPlayingAudioState[furnitureId]
end

function XInstrumentSimulatorAgency:SetInstrumentPlayingState(furnitureId, flag)
    self.InstrumentPlayingAudioState[furnitureId] = flag
end

function XInstrumentSimulatorAgency:GetModelInstrumentKeyMap()
    return self._Model:GetInstrumentKeyMap()
end

function XInstrumentSimulatorAgency:GetModelInstrumentKeyMapConfigByFurnitureIdAndIndex(furnitureId, index)
    return self._Model:GetInstrumentKeyMapConfigByFurnitureIdAndIndex(furnitureId, index)
end

function XInstrumentSimulatorAgency:PlayInstrumentKeyAudio(cueId, finCb)
    local source = CS.XAudioManager.GamePlaySpecialSource
    local volume = source.volume
    local info = XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, cueId, source.gameObject, volume, -1, -1, -1, -1, -1, 0, 0,finCb)
    return info
end

function XInstrumentSimulatorAgency:MuteInstrumentSimulator(flag)
    local source = CS.XAudioManager.GamePlaySpecialSource
    if flag then
        source.volume = 0
    else
        source.volume = 1
    end
end

----------public end----------

return XInstrumentSimulatorAgency