---@class XArrangementGameModel : XModel
local XArrangementGameModel = XClass(XModel, "XArrangementGameModel")
local TableKey = 
{
    ArrangementGameControl = { CacheType = XConfigUtil.CacheType.Normal },
    ArrangementGameMusic = { CacheType = XConfigUtil.CacheType.Normal },
    ArrangementGameSelection = {},
}

function XArrangementGameModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    self._ConfigUtil:InitConfigByTableKey("MiniActivity/MusicGame/MusicCreation/ArrangementGame", TableKey, XConfigUtil.CacheType.Private)
end

function XArrangementGameModel:ClearPrivate()
    --这里执行内部数据清理
end

function XArrangementGameModel:ResetAll()
    --这里执行重登数据清理
end

----------config start----------

---@return XTableArrangementGameControl[]
function XArrangementGameModel:GetArrangementGameControl()
    return self._ConfigUtil:GetByTableKey(TableKey.ArrangementGameControl)
end

---@return XTableArrangementGameMusic[]
function XArrangementGameModel:GetArrangementGameMusic()
    return self._ConfigUtil:GetByTableKey(TableKey.ArrangementGameMusic)
end

---@return XTableArrangementGameSelection[]
function XArrangementGameModel:GetArrangementGameSelection()
    return self._ConfigUtil:GetByTableKey(TableKey.ArrangementGameSelection)
end
----------config end----------


return XArrangementGameModel