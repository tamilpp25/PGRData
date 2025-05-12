---@class XBigWorldSetControl : XControl
---@field private _Model XBigWorldSetModel
local XBigWorldSetControl = XClass(XControl, "XBigWorldSetControl")

function XBigWorldSetControl:OnInit()
    -- 初始化内部变量
    self._MaxScreenOff = false

    ---@type table<number, XBWSettingBase>
    self._SettingCache = {}
end

function XBigWorldSetControl:AddAgencyEvent()
    -- control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XBigWorldSetControl:RemoveAgencyEvent()

end

function XBigWorldSetControl:OnRelease()
    -- XLog.Error("这里执行Control的释放")
    self._SettingCache = {}
end

---@return XBWSetTypeData[]
function XBigWorldSetControl:GetSetTypeDatas(setTypes)
    local result = {}

    if not XTool.IsTableEmpty(setTypes) then
        for _, type in pairs(setTypes) do
            table.insert(result, self._Model:GetSetTypeData(type))
        end

        table.sort(result, function(dataA, dataB)
            return dataA:GetPriority() < dataB:GetPriority()
        end)
    end

    return result
end

function XBigWorldSetControl:GetDefaultSetTypes()
    return self:GetAgency():GetDefaultSetTypes()
end

---@return XBWSettingBase
function XBigWorldSetControl:GetSettingBySetType(setType)
    if not self._SettingCache[setType] then
        self._SettingCache[setType] = self._Model:GetSettingBySetType(setType)
    end

    return self._SettingCache[setType]
end

function XBigWorldSetControl:SaveSettingBySetType(setType)
    local setting = self:GetSettingBySetType(setType)

    if setting then
        setting:SaveChange()
        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_SETTING_SAVE, setType)
    end
end

function XBigWorldSetControl:ResetSettingBySetType(setType)
    local setting = self:GetSettingBySetType(setType)

    if setting then
        setting:Reset()
        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_SETTING_RESET, setType)
    end
end

function XBigWorldSetControl:RestoreSettingBySetType(setType)
    local setting = self:GetSettingBySetType(setType)

    if setting then
        setting:RestoreDefault()
        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_SETTING_RESTORE, setType)
    end
end

function XBigWorldSetControl:CheckSettingChangedBySetType(setType)
    local setting = self:GetSettingBySetType(setType)
    
    if setting then
        return setting:IsChanged()
    end

    return false
end

function XBigWorldSetControl:GetCurrentResolutionSize()
    return {
        x = CS.UnityEngine.Screen.width,
        y = CS.UnityEngine.Screen.height,
    }
end

function XBigWorldSetControl:GetResolutionSizeText(size)
    return string.format("%d x %d", size.x, size.y)
end

function XBigWorldSetControl:GetResolutionSizeCurrentIndex()
    local currentSize = self:GetCurrentResolutionSize()
    local defaultSizeArray = self:GetResolutionSizeArray()
    local defaultSizeIndex = false

    for i = 1, #defaultSizeArray do
        if defaultSizeArray[i].x == currentSize.x and defaultSizeArray[i].y == currentSize.y then
            defaultSizeIndex = i
            break
        end
    end
    if not defaultSizeIndex then
        defaultSizeIndex = #defaultSizeArray
    end

    return defaultSizeIndex
end

function XBigWorldSetControl:GetResolutionSizeArray()
    return XDataCenter.UiPcManager.GetTabUiPcResolution()
end

function XBigWorldSetControl:RefreshSpecialScreenOff(safeAreaContent)
    safeAreaContent:UpdateSpecialScreenOff()
end

return XBigWorldSetControl
