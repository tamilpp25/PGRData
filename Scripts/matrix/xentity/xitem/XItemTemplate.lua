local XItemTemplate = {}


function XItemTemplate.New(itemTable)
    local extendObj = {}

    if itemTable.RecType ~= XResetManager.ResetType.NoNeed then
        local secondes, days = XResetManager.GetResetTimeByString(itemTable.RecType, itemTable.RecTime)
        extendObj["RecSeconds"] = secondes
        extendObj["RecDays"] = days
    end

    return setmetatable({}, {
        __metatable = "readonly table",
        __index = function(_, k)
            if extendObj[k] ~= nil then
                return extendObj[k]
            else
                return itemTable[k]
            end
        end,
        __newindex = function()
            XLog.Error("attempt to update a readonly table")
        end,
    })
end


return XItemTemplate