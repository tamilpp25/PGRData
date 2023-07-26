XDlcScriptManager = {}
local XDlcScript = require("XDLCFight/XDlcScript")
require("XDLCFight/XDlcFightEnum")

local SCRIPT_PATHS = {
    CHAR = "XDLCFight/Character/%04d",
    LEVEL = "XDLCFight/Level/%04d",
    SCENEOBJ = "XDLCFight/SceneObject/%04d",
}

local _scriptClassDict = {
    Char = {},
    Level = {},
    SceneObj = {},
}

local _scriptInstanceDict = {
    Char = {},
    Level = {},
    SceneObj = {},
}

function XDlcScriptManager.LoadCharScript(id)
    return XDlcScriptManager.LoadScript("Char", id)
end

function XDlcScriptManager.LoadLevelScript(id)
    return XDlcScriptManager.LoadScript("Level", id)
end

function XDlcScriptManager.LoadSceneObjScript(id)
    return XDlcScriptManager.LoadScript("SceneObj", id)
end

function XDlcScriptManager.LoadScript(category, id)
    local path = string.format(SCRIPT_PATHS[string.upper(category)], id)
    if _scriptClassDict[category][id] ~= nil then
        return true --repeat loading
    end

    local class = require(path)
    return class ~= nil
end

---@param id number
---@param name string
---@param super table
function XDlcScriptManager.RegCharScript(id, name, super)
    return XDlcScriptManager._RegScript("Char", id, name, super)
end

---@param id number
---@param name string
---@param super table
function XDlcScriptManager.RegLevelScript(id, name, super)
    return XDlcScriptManager._RegScript("Level", id, name, super)
end

---@param id number
---@param name string
---@param super table
function XDlcScriptManager.RegSceneObjScript(id, name, super)
    return XDlcScriptManager._RegScript("SceneObj", id, name, super)
end

---@param category string
---@param id number
---@param name string
---@param super table
function XDlcScriptManager._RegScript(category, id, name, super)
    super = super or XDlcScript
    local class = XClass(super, name)
    _scriptClassDict[category][id] = class
    return class
end

---@param id number
---@param npcId number
---@param proxy StatusSyncFight.XScriptLuaProxy @C#代理对象
function XDlcScriptManager.NewCharScript(id, npcId, proxy)
    return XDlcScriptManager.NewScript("Char", id, npcId, proxy)
end

---@param id number
---@param levelId number
---@param proxy StatusSyncFight.XScriptLuaProxy @C#代理对象
function XDlcScriptManager.NewLevelScript(id, levelId, proxy)
    return XDlcScriptManager.NewScript("Level", id, levelId, proxy)
end

---@param id string
---@param soPlaceId number
---@param proxy StatusSyncFight.XScriptLuaProxy @C#代理对象
function XDlcScriptManager.NewSceneObjScript(id, soPlaceId, proxy)
    return XDlcScriptManager.NewScript("SceneObj", id, soPlaceId, proxy)
end

---创建指定脚本的实例
---@param category string @脚本类别
---@param id number|string
---@param hostId number @脚本宿主id
---@param proxy StatusSyncFight.XScriptLuaProxy @C#代理对象
function XDlcScriptManager.NewScript(category, id, hostId, proxy)
    local class = XDlcScriptManager._GetScriptClass(category, id)
    if not class then
        return nil
    end

    local script = class.New(proxy)
    local instanceDict = _scriptInstanceDict[category]
    if instanceDict then
        instanceDict[hostId] = script
    else
        XLog.Error("XDlcScriptManager.NewScript error, no instance dict of " .. category)
    end

    return script
end

---@param category string
---@param id number|string
function XDlcScriptManager._GetScriptClass(category, id)
    local dict = _scriptClassDict[category]
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

function XDlcScriptManager.GetLevelScript(soPlaceId)
    return XDlcScriptManager._GetScriptInstance("Level", soPlaceId)
end

function XDlcScriptManager.GetSceneObjectScript(soPlaceId)
    return XDlcScriptManager._GetScriptInstance("SceneObj", soPlaceId)
end

function XDlcScriptManager._GetScriptInstance(category, hostId)
    local instanceDict = _scriptInstanceDict[category]
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

---@param id number
function XDlcScriptManager.GetLevelVCameraRefTable(id)
    local scriptClassType = XDlcScriptManager._GetScriptClass("Level", id)
    if not scriptClassType then
        return nil
    end

    return scriptClassType.GetCameraResRefTable()
end

function XDlcScriptManager.GetLevelEffectRefTable(id)
    local scriptClassType = XDlcScriptManager._GetScriptClass("Level", id)
    if not scriptClassType or scriptClassType.GetEffectRefTable == nil then
        return nil
    end

    return scriptClassType.GetEffectRefTable()
end

function XDlcScriptManager.GetCharEffectRefTable(id)
    local scriptClassType = XDlcScriptManager._GetScriptClass("Char", id)
    if not scriptClassType or scriptClassType.GetEffectRefTable == nil then
        return nil
    end

    return scriptClassType.GetEffectRefTable()
end