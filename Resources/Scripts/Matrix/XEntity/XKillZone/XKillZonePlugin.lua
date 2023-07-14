local type = type
local pairs = pairs

--[[    
public class XKillZonePluginDb
{
    public int Id;
    /// <summary>
    /// 等级索引
    /// </summary>
    public int LevelIndex;
}
]]
local Default = {
    _Id = 0, --插件Id
    _Level = -1, --等级
    _Slot = 0, --穿戴槽位
}

local XKillZonePlugin = XClass(nil, "XKillZonePlugin")

function XKillZonePlugin:Ctor(id)
    self:Init(id)
end

function XKillZonePlugin:Init(id)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end

    self._Id = id
end

function XKillZonePlugin:Reset()
    for key, value in pairs(Default) do
        if key ~= "_Id" then
            if type(value) == "table" then
                self[key] = {}
            else
                self[key] = value
            end
        end
    end
end

function XKillZonePlugin:UpdateData(info)
    self._Level = info.LevelIndex and info.LevelIndex + 1 or self._Level
end

function XKillZonePlugin:GetLevel()
    return self._Level
end

--获取插件展示等级（包含未解锁/未激活/正常/最大等级）
local MaxLevelStr = CS.XTextManager.GetText("KillZonePlguinMaxLevelStr")
function XKillZonePlugin:GetShowLevelStr()
    local level = self._Level

    if self:IsLock()
    or self:IsUnActive()
    then
        level = 1
    end

    if level == XKillZoneConfigs.GetPluginMaxLevel(self._Id) then
        return MaxLevelStr
    end

    return tostring(level)
end

function XKillZonePlugin:PutOn(slot)
    self._Slot = slot
end

function XKillZonePlugin:TakeOff()
    self._Slot = 0
end

--是否未解锁
function XKillZonePlugin:IsLock()
    return self:GetLevel() < 0
end

--是否未激活
function XKillZonePlugin:IsUnActive()
    return self:GetLevel() == 0
end

--是否达到最大等级
function XKillZonePlugin:IsMaxLevel()
    return self:GetLevel() == XKillZoneConfigs.GetPluginMaxLevel(self._Id)
end

--获取升级消耗
function XKillZonePlugin:GetLevelUpCost()
    local itemId, itemCount = XKillZoneConfigs.GetPluginLevelUpCost(self._Id, self._Level + 1)
    return itemId, itemCount
end

return XKillZonePlugin