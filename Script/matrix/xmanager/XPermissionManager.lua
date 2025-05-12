XPermissionManager = XPermissionManager or {}

local Application = CS.UnityEngine.Application
local Platform = Application.platform
local RuntimePlatform = CS.UnityEngine.RuntimePlatform

-- 权限授权状态
local PERMISSION_DENIED = -1
local PERMISSION_GRANTED = 0
local PERMISSION_CUSTOMER_DENIED = 1
local PERMISSION_STATE_NONE = 2

local PERMISSION_STATE_KEY = "PERMISSION_GRANTED_"
local CSXToolGetPermission = function() print("PermissionManager not init") end 

local PermissionStateMap = {}
local PermissionTextMap = {}

-- [权限] = 设置权限文字提示key
local PermissionEnumMap = {
    [CS.XPermissionEnum.CAMERA] = "PremissionCameraDesc",
    [CS.XPermissionEnum.READ_EXTERNAL_STORAGE] = "PremissionReadDesc",
    [CS.XPermissionEnum.WRITE_EXTERNAL_STORAGE] = "PremissionWriteDesc",
}

-- 权限初始化逻辑
function XPermissionManager.Init()
    
    -- 暂不允许直接调用请求权限接口
    CSXToolGetPermission = CS.XTool.GetPermission
    CS.XTool.GetPermission = nil

    for enum, desc in pairs(PermissionEnumMap) do
        local code = enum:GetHashCode()
        PermissionTextMap[code] = CS.XTextManager.GetText(desc)
    end
    
    if not CS.XTool.CheckPermission then -- 兼容线上版本
        return
    end

    for enum, desc in pairs(PermissionEnumMap) do
        local code = enum:GetHashCode()
        local customerState = CS.UnityEngine.PlayerPrefs.GetInt(PERMISSION_STATE_KEY .. code, PERMISSION_STATE_NONE)
        PermissionStateMap[code] = customerState

        local state = CS.XTool.CheckPermission(enum) -- 设备权限情况
        if state == PERMISSION_GRANTED then
            CS.UnityEngine.PlayerPrefs.SetInt(PERMISSION_STATE_KEY .. code, state)
            PermissionStateMap[code] = state
        end
    end
end

-- 检查并获取权限（拒绝后不重复询问）
function XPermissionManager.TryGetPermission(permissionEnum, description, cb)
    local code = permissionEnum:GetHashCode()

    -- 兼容安卓13的情况提示，小于安卓13的版本申请写入权限时才走客户端拦截判断
    if not (Platform == RuntimePlatform.Android and permissionEnum == CS.XPermissionEnum.WRITE_EXTERNAL_STORAGE and CS.XPlugin.OsVersion >= 130000 ) then
        if PermissionStateMap[code] == PERMISSION_CUSTOMER_DENIED and 
            (CS.XTool.CheckPermission == nil or CS.XTool.CheckPermission(permissionEnum) ~= PERMISSION_GRANTED) then
            local text = PermissionTextMap[code]
            if not PermissionTextMap[code] then
                XLog.Error("获取权限错误，在PermissionEnumMap中缺少处理代码")
            end
            text = text or CS.XTextManager.GetText("PremissionDesc")
            XUiManager.TipMsg(text, XUiManager.UiTipType.Tip)
            return
        end
    end

    local resultCB = function(isGranted, dontTip)
        local state = isGranted and PERMISSION_GRANTED or PERMISSION_CUSTOMER_DENIED
        if PermissionStateMap[code] ~= state then
            CS.UnityEngine.PlayerPrefs.SetInt(PERMISSION_STATE_KEY .. code, state)
            CS.UnityEngine.PlayerPrefs.Save()
            PermissionStateMap[code] = state
        end
        cb(isGranted, dontTip)
    end
    return CSXToolGetPermission(permissionEnum, description, resultCB)
end


function XPermissionManager.GetPermissionStateMap()
    return PermissionStateMap
end

--- 检查是否有权限
function XPermissionManager.CheckPermission(permissionEnum)
    local code = permissionEnum:GetHashCode()
    return PermissionStateMap[code] == PERMISSION_GRANTED
end
