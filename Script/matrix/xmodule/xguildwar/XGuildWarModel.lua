--- 公会战
---@class XGuildWarModel : XModel
local XGuildWarModel = XClass(XModel, "XGuildWarModel")

local TableNormal = {
    GuildWarPlayThrough = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = "Id" },
    GuildWarDragonRage = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = "Id" },
    GuildWarDragonRageNodeChange = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = "Id" },

}

function XGuildWarModel:OnInit()
    -- 初始化配置表
    self._ConfigUtil:InitConfigByTableKey("GuildWar", TableNormal, XConfigUtil.CacheType.Normal)
    
    --- 初始化驻守玩法数据管理对象
    self._GarrisonData = require('XModule/XGuildWar/Entity/XGuildWarGarrisonData').New()
    --- 初始化龙怒系统玩法数据管理对象
    self._DragonRageData = require('XModule/XGuildWar/Entity/XGuildWarDragonRageData').New()
end

function XGuildWarModel:ClearPrivate()

end

function XGuildWarModel:ResetAll()
    self._DragonRageData:ResetData()
end

function XGuildWarModel:GetGarrisonData()
    return self._GarrisonData
end

---@return XGuildWarDragonRageData
function XGuildWarModel:GetDragonRageData()
    return self._DragonRageData
end


--region Configs

function XGuildWarModel:GetDragonRageCfgById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableNormal.GuildWarDragonRage, id)
end

function XGuildWarModel:GetDragonRageNodeChangeCfgById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableNormal.GuildWarDragonRageNodeChange, id)
end

function XGuildWarModel:GetDragonRagePlayThroughCfgById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableNormal.GuildWarPlayThrough, id)
end
--endregion

return XGuildWarModel