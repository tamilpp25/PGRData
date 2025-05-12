---@class XUiFightWheelPickerSlotData
---@field Id number         @按钮Id
---@field Key number        @按键Key
---@field Icon string       @图标Url
---@field Order number      @顺序
---@field IsDisable boolean @是否禁用
---@field IsEmpty   boolean @是否为空
local XUiFightWheelPickerSlotData = XClass(nil, "XUiFightWheelPickerSlotData")

function XUiFightWheelPickerSlotData.Default()
    return XUiFightWheelPickerSlotData.Create(0, 0, "", 0, false, true)
end

---@param id number
---@param key number
---@param icon string
---@param order number
---@param isDisable boolean
---@param isEmpty boolean
function XUiFightWheelPickerSlotData.Create(id, key, icon, order, isDisable, isEmpty)
    ---@type XUiFightWheelPickerSlotData
    local t = {
        Id = id,
        Key = key,
        Icon = icon,
        Order = order,
        IsDisable = isDisable,
        IsEmpty = isEmpty
    }

    return t
end

return XUiFightWheelPickerSlotData
