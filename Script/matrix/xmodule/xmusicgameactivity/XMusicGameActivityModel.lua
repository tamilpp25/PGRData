---@class XMusicGameActivityModel : XModel
local XMusicGameActivityModel = XClass(XModel, "XMusicGameActivityModel")
local TableKey = 
{
    MusicGameActivity = { CacheType = XConfigUtil.CacheType.Normal },
}

function XMusicGameActivityModel:OnInit()
    --初始化内部变量
    self.ActivityId = 0
    self.ArrangementMusicIds = nil
    self.PassRhythmMapIds = nil
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    self._ConfigUtil:InitConfigByTableKey("MiniActivity/MusicGameActivity", TableKey)
end

function XMusicGameActivityModel:RefreshServerData(data)
    local tempData = data.MusicGameData
    self.ActivityId = tempData.ActivityId
    self.ArrangementMusicIds = tempData.ArrangementMusicIds
    self.PassRhythmMapIds = tempData.PassRhythmMapIds
end

function XMusicGameActivityModel:ClearPrivate()
    --这里执行内部数据清理
end

function XMusicGameActivityModel:ResetAll()
    --这里执行重登数据清理
    self.ActivityId = 0
    self.ArrangementMusicIds = nil
    self.PassRhythmMapIds = nil
end

----------config start----------
---@return XTableMusicGameActivity[]
function XMusicGameActivityModel:GetMusicGameActivity()
    return self._ConfigUtil:GetByTableKey(TableKey.MusicGameActivity)
end
----------config end----------


return XMusicGameActivityModel