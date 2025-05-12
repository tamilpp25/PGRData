---@class XInstrumentSimulatorModel : XModel
local XInstrumentSimulatorModel = XClass(XModel, "XInstrumentSimulatorModel")
local TableKey = 
{ 
    InstrumentKeyMap = {DirPath = XConfigUtil.DirectoryType.Client, Identifier = "FId"}
}

function XInstrumentSimulatorModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    self._ConfigUtil:InitConfigByTableKey("MiniActivity/MusicGame/MusicCreation/InstrumentSimulator", TableKey, XConfigUtil.CacheType.Normal)
end

function XInstrumentSimulatorModel:ClearPrivate()
    --这里执行内部数据清理
end

function XInstrumentSimulatorModel:ResetAll()
    --这里执行重登数据清理
end

----------public start----------

---@return XTablePianoBtnKeyMap[]
function XInstrumentSimulatorModel:GetInstrumentKeyMap()
    return self._ConfigUtil:GetByTableKey(TableKey.InstrumentKeyMap)
end

function XInstrumentSimulatorModel:GetInstrumentKeyMapConfigByFurnitureIdAndIndex(furnitureId, index)
    local fId = furnitureId * 1000 + index
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.InstrumentKeyMap, fId)
end

----------public end----------

return XInstrumentSimulatorModel