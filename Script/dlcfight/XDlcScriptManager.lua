XDlcScriptManager = {}
local XDlcScript = require("XDlcScript")
require("XDlcFightEnum")

local SCRIPT_PATHS = {
    CHAR = "Character/Char_%04d",
    LEVEL = "Level/%04d",
    LEVEL_LOGIC = "Level/Level_%04d_Logic",
    LEVEL_PRESENT = "Level/Level_%04d_Present",
    SCENE_OBJ = "SceneObject/%04d",
    QUEST_STEP = "Quest/Quest_%04d"
}

local ScriptClassDict = { --<string, <int, table(class)>>
    Char = {},
    Level = {},
    Level_Logic = {},
    Level_Present = {},
    Scene_Obj = {},
    Quest_Step = {},
}

---@param id number@脚本文件名上的id
function XDlcScriptManager.LoadCharScript(id)
    return XDlcScriptManager.LoadScript("Char", id)
end

---@param id number@脚本文件名上的id
function XDlcScriptManager.LoadLevelLogicScript(id)
    return XDlcScriptManager.LoadLevelScriptWithType(id, 1)
end

---@param id number@脚本文件上的id
function XDlcScriptManager.LoadLevelPresentScript(id)
    return XDlcScriptManager.LoadLevelScriptWithType(id, 2)
end

---@param id number@脚本文件名上的id
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

---@param id number @脚本文件名上的id
function XDlcScriptManager.LoadSceneObjScript(id)
    return XDlcScriptManager.LoadScript("Scene_Obj", id)
end

---@param id number @脚本文件名上的id
function XDlcScriptManager.LoadQuestScript(id)
    return XDlcScriptManager.LoadScript("Quest_Step", id)
end

---根据id找到脚本文件，通过require脚本执行其内部的RegXXXScript来注册脚本类table。
---@param category string
---@param id number @脚本文件名上的id，通常与文件内脚本类Id相同，除非文件内有不止一个脚本类。
function XDlcScriptManager.LoadScript(category, id)
    local path = string.format(SCRIPT_PATHS[string.upper(category)], id)
    if not XLuaEngine:FileExists(path) then
        return false
    end

    local class = require(path)
    return class ~= nil
end

---@param scriptClassId number @脚本类的id
---@param name string
---@param super table
function XDlcScriptManager.RegCharScript(scriptClassId, name, super)
    return XDlcScriptManager._RegisterScript("Char", scriptClassId, name, super)
end

---@param scriptClassId number @脚本类的id
---@param name string
---@param super table
function XDlcScriptManager.RegLevelLogicScript(scriptClassId, name, super)
    name = string.format("XLevelLogicScript_%04d", scriptClassId)
    return XDlcScriptManager._RegisterScript("Level_Logic", scriptClassId, name, super)
end

---@param scriptClassId number @脚本类的id
---@param name string
---@param super table
function XDlcScriptManager.RegLevelPresentScript(scriptClassId, name, super)
    name = string.format("XLevelPresentScript_%04d", scriptClassId)
    return XDlcScriptManager._RegisterScript("Level_Present", scriptClassId, name, super)
end

---@param scriptClassId number @脚本类的id
---@param name string
---@param super table
function XDlcScriptManager.RegSceneObjScript(scriptClassId, name, super)
    return XDlcScriptManager._RegisterScript("Scene_Obj", scriptClassId, name, super)
end

---@param id number
---@param name string
---@param super table
function XDlcScriptManager.RegQuestStepScript(id, name, super)
    return XDlcScriptManager._RegisterScript("Quest_Step", id, name, super)
end

---@param category string
---@param scriptClassId number @脚本类的id
---@param name string
---@param super table
function XDlcScriptManager._RegisterScript(category, scriptClassId, name, super)
    super = super or XDlcScript
    local class = XClass(super, name)
    local classDict = ScriptClassDict[category]
    if classDict[scriptClassId] ~= nil then
        XLog.Warning(string.format("XDlcScriptManager._RegisterScript: Repeat register scriptClass:%d, %s !", scriptClassId, name))
        return class
    end
    classDict[scriptClassId] = class
    return class
end

---@param scriptClassId number
---@param proxy StatusSyncFight.XFightScriptProxy @C#代理对象
function XDlcScriptManager.NewCharScript(scriptClassId, proxy)
    return XDlcScriptManager.NewScript("Char", scriptClassId, proxy)
end

---@param scriptClassId number
---@param proxy StatusSyncFight.XFightScriptProxy @C#代理对象
function XDlcScriptManager.NewLevelLogicScript(scriptClassId, proxy)
    return XDlcScriptManager._NewLevelScriptWithType(scriptClassId, proxy, 1)
end

---@param scriptClassId number
---@param proxy StatusSyncFight.XFightScriptProxy @C#代理对象
function XDlcScriptManager.NewLevelPresentScript(scriptClassId, proxy)
    return XDlcScriptManager._NewLevelScriptWithType(scriptClassId, proxy, 2)
end

---@param scriptClassId number
---@param proxy StatusSyncFight.XFightScriptProxy @C#代理对象
---@param levelScriptType number
---@return table
function XDlcScriptManager._NewLevelScriptWithType(scriptClassId, proxy, levelScriptType)
    local class = nil
    if levelScriptType == 1 then
        class = require(string.format(SCRIPT_PATHS.LEVEL_LOGIC, scriptClassId))
    elseif levelScriptType == 2 then
        class = require(string.format(SCRIPT_PATHS.LEVEL_PRESENT, scriptClassId))
    end

    if class == nil then
        XLog.Error(string.format("XDlcScriptManager._NewLevelScriptWithType: Script class not found [id:%04d][levelScriptType:%d]", scriptClassId, levelScriptType))
        return nil
    end

    return class.New(proxy)
end

---@param id string
---@param proxy StatusSyncFight.XFightScriptProxy @C#代理对象
function XDlcScriptManager.NewSceneObjScript(id, proxy)
    return XDlcScriptManager.NewScript("Scene_Obj", id, proxy)
end

---@param id string
---@param proxy StatusSyncFight.XFightScriptProxy @C#代理对象
function XDlcScriptManager.NewQuestScript(id, proxy)
    return XDlcScriptManager.NewScript("Quest_Step", id, proxy)
end

---创建指定脚本的实例
---@param category string @脚本类别
---@param id number
---@param proxy StatusSyncFight.XFightScriptProxy @C#代理对象
function XDlcScriptManager.NewScript(category, id, proxy)
    local class = XDlcScriptManager._GetScriptClass(category, id)
    if not class then
        return nil
    end

    local scriptInstance = class.New(proxy)
    return scriptInstance
end

---@param category string
---@param id number
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