
---@class WeakRefCollector
WeakRefCollector = {}
WeakRefCollector.Type = {
    UI = "UI",
    Agency = "Agency",
    Control = "Control",
    Model = "Model",
    Entity = "Entity",
    Config = "Config",
    Custom = "Custom"
}

WeakRefCollector.CollectTab = {}
WeakRefCollector.TempRefPrintStr = nil

---添加弱引用监控对象
function WeakRefCollector.AddRef(type, obj, name)
    if not WeakRefCollector.Type[type] then
        XLog.Error("不存在的类型: " .. type)
        return
    end
    local tbl = WeakRefCollector.CollectTab[type]
    if not tbl then
        tbl = {}
        setmetatable(tbl, {__mode = "kv"})
        WeakRefCollector.CollectTab[type] = tbl
    end
    local refName = nil
    if name then
        refName = name
    elseif obj.__cname then
        refName = obj.__cname
    else
        refName = tostring(obj)
    end
    tbl[obj] = refName
end

function WeakRefCollector.RefPrint(str)
    WeakRefCollector.TempRefPrintStr = WeakRefCollector.TempRefPrintStr .. str
end

---根据类型数组输出引用
function WeakRefCollector.PrintRefWithTypes(types, snapshot)
    WeakRefCollector.TempRefPrintStr = ""
    LuaProfilerTool.SetLuaMemoryRefOutputPrint(WeakRefCollector.RefPrint)
    collectgarbage("collect")
    local content = ""
    for _, type in ipairs(types) do
        local refTab = WeakRefCollector.CollectTab[type]
        if refTab and next(refTab) then
            content = content .. "\n" .. ":::[" .. tostring(type) .. "]::: => \n"
            local count = 0
            for obj, refName in pairs(refTab) do
                count = count + 1
                WeakRefCollector.TempRefPrintStr = ""
                content = content .. tostring(count) .. ". " .. "[" .. refName .. "(" .. tostring(obj) .. ")" .. "]\n"
                if snapshot then
                    LuaProfilerTool.SnapshotObjectOutput(obj)
                    content = content .. WeakRefCollector.TempRefPrintStr .. "========================================================\n"
                end
            end
        end
    end
    LuaProfilerTool.ResetLuaMemoryRefOutputPrint()
    XLog.Error("WeakRefCollector.PrintRef : " .. content)
end

---输出单个类型的引用
function WeakRefCollector.PrintRef(type)
    WeakRefCollector.PrintRefWithTypes({type})
end

---输出所有引用
function WeakRefCollector.PrintAllRef()
    local allTypes = {}
    for _, v in pairs(WeakRefCollector.Type) do
        table.insert(allTypes, v)
    end
    WeakRefCollector.PrintRefWithTypes(allTypes)
end

---输出mvca相关的引用
function WeakRefCollector.PrintMVCARef(snapshot)
    local types = {
        WeakRefCollector.Type.UI,
        WeakRefCollector.Type.Agency,
        WeakRefCollector.Type.Control,
        WeakRefCollector.Type.Model,
        WeakRefCollector.Type.Entity,
        WeakRefCollector.Type.Config
    }
    WeakRefCollector.PrintRefWithTypes(types, snapshot)
end

---输出自定义相关的引用
function WeakRefCollector.PrintCustomRef(snapshot)
    local types = {
        WeakRefCollector.Type.Custom
    }
    WeakRefCollector.PrintRefWithTypes(types, snapshot)
end