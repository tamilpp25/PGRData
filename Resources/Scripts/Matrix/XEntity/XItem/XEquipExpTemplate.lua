local XEquipExpTemplate = {}

function XEquipExpTemplate.New(itemTemplate)
    local extendObj = {
        Classify = itemTemplate.SubTypeParams[1],
        Exp = itemTemplate.SubTypeParams[2],
        Cost = itemTemplate.SubTypeParams[3],
    }

    extendObj.GetExp = function()
        return extendObj.Exp
    end

    extendObj.GetCost = function()
        return extendObj.Cost
    end

    return setmetatable({}, {
        __metatable = "readonly table",
        __index = function(_, k)
            if extendObj[k] ~= nil then
                return extendObj[k]
            else
                return itemTemplate[k]
            end
        end,
        __newindex = function()
            XLog.Error("attempt to update a readonly table")
        end,
    })
end

return XEquipExpTemplate