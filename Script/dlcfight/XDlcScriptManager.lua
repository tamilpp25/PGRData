XDlcScriptManager = {}
local XDlcScript = require("XDlcScript")
require("XDlcFightEnum")

local SCRIPT_PATHS = {
    CHAR = "Character/Char_%04d",
    LEVEL = "Level/%04d",
    LEVEL_LOGIC = "Level/Level_%04d_Logic",
    LEVEL_PRESENT = "Level/Level_%04d_Present",
    SCENE_OBJ = "SceneObject/%04d",
}

local ScriptClassDict = {
    Char = {},
    Level = {},
    Level_Logic = {},
    Level_Present = {},
    Scene_Obj = {},
}

local ScriptInstanceDict = {
    Char = {},
    Level = {},
    Scene_Obj = {},
}

---@param id number
function XDlcScriptManager.LoadCharScript(id)
    return XDlcScriptManager.LoadScript("Char", id)
end

---@param id number
--function XDlcScriptManager.LoadLevelScript(id)
--    return XDlcScriptManager.LoadScript("Level", id)
--end

---@param id number
function XDlcScriptManager.LoadLevelLogicScript(id)
    return XDlcScriptManager.LoadLevelScriptWithType(id, 1)
end

---@param id number
function XDlcScriptManager.LoadLevelPresentScript(id)
    return XDlcScriptManager.LoadLevelScriptWithType(id, 2)
end

---@param id number
---@param levelScriptType number
function XDlcScriptManager.LoadLevelScriptWithType(id, levelScriptType)
    if levelScriptType == 1 then
        return XDlcScriptManager.LoadScript("Level_Logic", id)
    elseif levelScriptType == 2 then
        return XDlcScriptManager.LoadScript("Level_Present", id)
    else
        XLog.Error(string.format("XDlcScriptManager.LoadLevelScriptWithType Unknown levelScriptType:%d", levelScriptType))
    end

    return false
end

---@param id number
function XDlcScriptManager.LoadSceneObjScript(id)
    return XDlcScriptManager.LoadScript("Scene_Obj", id)
end

---@param category string
---@param id number
function XDlcScriptManager.LoadScript(category, id)
    local path = string.format(SCRIPT_PATHS[string.upper(category)], id)
    if ScriptClassDict[category][id] ~= nil then
        return true --repeat loading
    end

    if not XLuaEngine:FileExists(path) then
        return false
    end

    local class = require(path)
    return class ~= nil
end

---@param id number
---@param name string
---@param super table
function XDlcScriptManager.RegCharScript(id, name, super)
    return XDlcScriptManager._RegisterScript("Char", id, name, super)
end

---@param id number
---@param name string
---@param super table
--function XDlcScriptManager.RegLevelScript(id, name, super)
--    return XDlcScriptManager._RegisterScript("Level", id, name, super)
--end

---@param id number
---@param name string
---@param super table
function XDlcScriptManager.RegLevelLogicScript(id, name, super)
    name = string.format("XLevelLogicScript_%04d", id)
    return XDlcScriptManager._RegisterScript("Level_Logic", id, name, super)
end

---@param id number
---@param name string
---@param super table
function XDlcScriptManager.RegLevelPresentScript(id, name, super)
    name = string.format("XLevelPresentScript_%04d", id)
    return XDlcScriptManager._RegisterScript("Level_Present", id, name, super)
end

---@param id number
---@param name string
---@param super table
function XDlcScriptManager.RegSceneObjScript(id, name, super)
    return XDlcScriptManager._RegisterScript("Scene_Obj", id, name, super)
end

---@param category string
---@param id number
---@param name string
---@param super table
function XDlcScriptManager._RegisterScript(category, id, name, super)
    super = super or XDlcScript
    local class = XClass(super, name)
    local classDict = ScriptClassDict[category]
    if classDict[id] ~= nil then
        XLog.Error(string.format("XDlcScriptManager._RegisterScript: Repeat register script:%d, %s !", id, name))
        return class
    end
    classDict[id] = class
    return class
end

---@param id number
---@param npcId number
---@param proxy StatusSyncFight.XFightScriptProxy @C#代理对象
function XDlcScriptManager.NewCharScript(id, npcId, proxy)
    return XDlcScriptManager.NewScript("Char", id, npcId, proxy)
end

---@param id number
---@param levelProcessId number
---@param proxy StatusSyncFight.XFightScriptProxy @C#代理对象
--function XDlcScriptManager.NewLevelScript(id, levelProcessId, proxy)
--    return XDlcScriptManager.NewScript("Level", id, levelProcessId, proxy)
--end

---@param id number
---@param levelProcessId number
---@param proxy StatusSyncFight.XFightScriptProxy @C#代理对象
function XDlcScriptManager.NewLevelLogicScript(id, levelProcessId, proxy)
    return XDlcScriptManager._NewLevelScriptWithType(id, levelProcessId, proxy, 1)
end

---@param id number
---@param levelProcessId number
---@param proxy StatusSyncFight.XFightScriptProxy @C#代理对象
function XDlcScriptManager.NewLevelPresentScript(id, levelProcessId, proxy)
    return XDlcScriptManager._NewLevelScriptWithType(id, levelProcessId, proxy, 2)
end

---@param id number
---@param levelProcessId number
---@param proxy StatusSyncFight.XFightScriptProxy @C#代理对象
---@param levelScriptType number
---@return table
function XDlcScriptManager._NewLevelScriptWithType(id, levelProcessId, proxy, levelScriptType)
    local class = nil
    if levelScriptType == 1 then
        class = require(string.format(SCRIPT_PATHS.LEVEL_LOGIC, id))
    elseif levelScriptType == 2 then
        class = require(string.format(SCRIPT_PATHS.LEVEL_PRESENT, id))
    end

    if class == nil then
        XLog.Error(string.format("XDlcScriptManager.NewLevelScriptWithType NO Script: %04d %d", id, levelScriptType))
        return nil
    end

    return class.New(proxy)
end

---@param id string
---@param soPlaceId number
---@param proxy StatusSyncFight.XFightScriptProxy @C#代理对象
function XDlcScriptManager.NewSceneObjScript(id, soPlaceId, proxy)
    return XDlcScriptManager.NewScript("Scene_Obj", id, soPlaceId, proxy)
end

---创建指定脚本的实例
---@param category string @脚本类别
---@param id number|string
---@param hostId number @脚本宿主id
---@param proxy StatusSyncFight.XFightScriptProxy @C#代理对象
function XDlcScriptManager.NewScript(category, id, hostId, proxy)
    local class = XDlcScriptManager._GetScriptClass(category, id)
    if not class then
        return nil
    end

    local script = class.New(proxy)
    local instanceDict = ScriptInstanceDict[category]
    if instanceDict == nil then
        XLog.Error("XDlcScriptManager.NewScript error, no instance dict of " .. category)
    end

    instanceDict[hostId] = script --目前仅为宿主存储最后挂载的脚本，多脚本对象的存储与获取后续再考虑。

    return script
end

---@param category string
---@param id number|string
function XDlcScriptManager._GetScriptClass(category, id)
    local dict = ScriptClassDict[category]
    if not dict then
        XLog.Error("XDlcScriptManager._GetScriptClass error, unknown script category:" .. category)
        return nil
    end

    local class = dict[id]
    if not class then
        XLog.Error("XDlcScriptManager._GetScriptClass error, no fight script class:" .. category .. " " .. tostring(id))
        return nil
    end

    return class
end

function XDlcScriptManager.GetCharScript(soPlaceId)
    return XDlcScriptManager._GetScriptInstance("Char", soPlaceId)
end

--function XDlcScriptManager.GetLevelScript(soPlaceId)
--    return XDlcScriptManager._GetScriptInstance("Level", soPlaceId)
--end

function XDlcScriptManager.GetSceneObjectScript(soPlaceId)
    return XDlcScriptManager._GetScriptInstance("Scene_Obj", soPlaceId)
end

function XDlcScriptManager._GetScriptInstance(category, hostId)
    local instanceDict = ScriptInstanceDict[category]
    if not instanceDict then
        XLog.Error("XDlcScriptManager._GetScriptInstance error, no instance dict of " .. category)
        return nil
    end

    local script = instanceDict[hostId]
    if not script then
        XLog.Error("XDlcScriptManager._GetScriptInstance error, no script instance of " .. category .. " " .. tostring(hostId))
        return nil
    end

    return script
end

function XDlcScriptManager.GetCharEffectRefTable(id)
    local scriptClassType = XDlcScriptManager._GetScriptClass("Char", id)
    if not scriptClassType or scriptClassType.GetEffectRefTable == nil then
        return nil
    end

    return scriptClassType.GetEffectRefTable()
end