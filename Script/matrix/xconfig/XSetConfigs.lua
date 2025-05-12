XSetConfigs = XSetConfigs or {}

XSetConfigs.SelfNumKeyConfig = {
    SelfNumSmall = "SelfNumSmall",
    SelfNumMiddle = "SelfNumMiddle",
    SelfNumBig = "SelfNumBig",
}

XSetConfigs.SelfNumKeyIndexConfig = {
    [1] = 0,
    [2] = XSetConfigs.SelfNumKeyConfig.SelfNumSmall,
    [3] = XSetConfigs.SelfNumKeyConfig.SelfNumMiddle,
    [4] = XSetConfigs.SelfNumKeyConfig.SelfNumBig,
}

---伤害数字样式（旧版， 新版）
XSetConfigs.NumStyleConfig = {
    Old = 1,
    New = 2,
}

local XInputManager = CS.XInputManager
local TABLE_CONTROLLER_MAP_PATH = "Client/KeySet/ControllerMap.tab"
local TABLE_INPUT_MAP_PATH = "Client/KeySet/InputMap.tab"
local ControllerMapTemplates = {}
---@type XTableInputMap[]
local InputMapTemplates = {}

XSetConfigs.LoadingType = {
    Default = 1,
    Custom = 2,
}

XSetConfigs.DamageNumSize = {
    Close = 1,
    Small = 2,
    Middle = 3,
    Big = 4,
}

XSetConfigs.FriendNumEnum = {
    Close = 1,
    Open = 2,
}

XSetConfigs.FriendEffectEnum = {
    Close = 1,
    Open = 2,
}

XSetConfigs.WeaponTransEnum = {
    Close = 1,
    Open = 2,
}

XSetConfigs.RechargeEnum = {
    Close = 1,
    Open = 2,
}

XSetConfigs.CaptionEnum = {
    Close = 1,
    Open = 2,
}

XSetConfigs.ControllerSetItemType = {
    Section = 1, -- 副标题
    SetButton = 2, -- 键位设置按键
    Slider = 3, -- 滑动条（仅支持镜头灵敏度调节）
}

XSetConfigs.KeyCodeType = {
    Default = 0,
    SingleKey = 1,
    NotCustom = 2,
    OneKeyCustom = 3,
    KeyMouseCustom = 4,
    NotCustomIgnoreCheck = 5,
}

XSetConfigs.FocusType = {
    Auto = 1,       -- 智能锁定
    Manual = 2,     -- 手动锁定
    SemiAuto = 3,   -- 半自动锁定
}

XSetConfigs.FocusTypeDlcHunt = {
    Auto = 1,       -- 智能锁定
    Manual = 2,     -- 手动锁定
    --SemiAuto = 3,   -- 半自动锁定 dlc不存在
}

--按键下标
XSetConfigs.PressKeyIndex = {
    One = 0,
    Two = 1,
    End = 2
}

--用户设置的输入设备类型
XSetConfigs.InputDeviceType = {
    None = 0,
    Xbox = 1,
    Ps = 2,
    Keyboard = 3,
    Tabmacro = 4,
}

--运营埋点
XSetConfigs.RecordOperationType = {
    Back = 1,       --返回
    Retreat = 2,    --撤退
    ReStart = 3,    --重开
}

XSetConfigs.SelfNum = "SelfNum"---自身伤害数字
XSetConfigs.FriendNum = "FriendNum"--队友伤害数字
XSetConfigs.NumStyleKey = "NumStyle" -- 伤害数字样式
XSetConfigs.FriendEffect = "FriendEffect"--队友特效
XSetConfigs.IsFirstFriendEffect = "IsFirstFriendEffect"--是否是第一次在联机页面开启队友特效
XSetConfigs.ScreenOff = "ScreenOff"
XSetConfigs.DefaultDynamicJoystickKey = "DefaultDynamicJoystick"
--region focus
XSetConfigs.DefaultFocusTypeKey = "DefaultFocusType"
XSetConfigs.DefaultFocusButtonKey = "DefaultFocusButton"
--region focus
--region focus dlcHunt
XSetConfigs.DefaultFocusTypeDlcHuntKey = "DefaultFocusTypeDlcHunt"
XSetConfigs.DefaultFocusButtonDlcHuntKey = "DefaultFocusButtonDlcHunt"
--region focus dlcHunt
XSetConfigs.DefaultInviteButtonKey = "DefaultInviteButton"
XSetConfigs.DefaultWeaponTransTypeKey = "DefaultWeaponTransType"
XSetConfigs.DefaultRechargeTypeKey = "DefaultRechargeType"
XSetConfigs.DefaultCaptionTypeKey = "DefaultCaptionType"
XSetConfigs.DefaultFightCameraVibrationKey = "DefaultFightCameraVibration"

XSetConfigs.SelfNumSizes = {}

function XSetConfigs.Init()
    local key1 = XSetConfigs.SelfNumKeyConfig.SelfNumSmall
    local key2 = XSetConfigs.SelfNumKeyConfig.SelfNumMiddle
    local key3 = XSetConfigs.SelfNumKeyConfig.SelfNumBig
    XSetConfigs.SelfNumSizes[key1] = CS.XGame.ClientConfig:GetInt(key1) or 0
    XSetConfigs.SelfNumSizes[key2] = CS.XGame.ClientConfig:GetInt(key2) or 0
    XSetConfigs.SelfNumSizes[key3] = CS.XGame.ClientConfig:GetInt(key3) or 0
    XSetConfigs.DefaultDynamicJoystick = CS.XGame.ClientConfig:GetInt(XSetConfigs.DefaultDynamicJoystickKey)
    XSetConfigs.NumStyle = CS.XGame.ClientConfig:GetInt(XSetConfigs.NumStyleKey) or 1
    --region focus
    XSetConfigs.DefaultFocusType = CS.XGame.ClientConfig:GetInt(XSetConfigs.DefaultFocusTypeKey)
    XSetConfigs.DefaultFocusButton = CS.XGame.ClientConfig:GetInt(XSetConfigs.DefaultFocusButtonKey)
    --endregion focus
    --region focus dlcHunt
    XSetConfigs.DefaultFocusTypeDlcHunt = CS.XGame.ClientConfig:GetInt(XSetConfigs.DefaultFocusTypeDlcHuntKey)
    XSetConfigs.DefaultFocusButtonDlcHunt = CS.XGame.ClientConfig:GetInt(XSetConfigs.DefaultFocusButtonDlcHuntKey)
    --endregion focus dlcHunt
    XSetConfigs.DefaultInviteButton = CS.XGame.ClientConfig:GetInt(XSetConfigs.DefaultInviteButtonKey)
    XSetConfigs.DefaultWeaponTransType = CS.XGame.ClientConfig:GetInt(XSetConfigs.DefaultWeaponTransTypeKey)
    XSetConfigs.DefaultRechargeType = CS.XGame.ClientConfig:GetInt(XSetConfigs.DefaultRechargeTypeKey)
    XSetConfigs.DefaultCaptionType = CS.XGame.ClientConfig:GetInt(XSetConfigs.DefaultCaptionTypeKey)
    XSetConfigs.DefaultFightCameraVibration = CS.XGame.ClientConfig:GetInt(XSetConfigs.DefaultFightCameraVibrationKey)
    ControllerMapTemplates = XTableManager.ReadByIntKey(TABLE_CONTROLLER_MAP_PATH, XTable.XTableControllerMap, "Id")
end

function XSetConfigs.GetControllerMapCfg()
    return ControllerMapTemplates
end

function XSetConfigs.GetDefaultKeyMapTable(id)
    return XInputManager.GetDefaultKeyMapTable(id)
end

function XSetConfigs.GetControllerKeyText(operationKey)
    local curInputMapId = CS.System.Convert.ToInt32(CS.XInputManager.InputMapper:GetCurEditInputMapID())
    local defaultKeyMapTable
    for _, config in pairs(XSetConfigs.GetControllerMapCfg()) do
        for _, id in ipairs(config.DefaultKeyMapIds) do
            defaultKeyMapTable = XSetConfigs.GetDefaultKeyMapTable(id)
            if defaultKeyMapTable and config.InputMapId == curInputMapId and defaultKeyMapTable.OperationKey == operationKey then
                return config.Title
            end
        end
    end
end

local InputMapIdList = {}
local IsInitInputMapConfig = false
local InitInputMapIdConfig = function()
    if IsInitInputMapConfig then
        return
    end

    InputMapTemplates = XTableManager.ReadByIntKey(TABLE_INPUT_MAP_PATH, XTable.XTableInputMap, "InputMapId")
    for inputMapId in pairs(InputMapTemplates) do
        table.insert(InputMapIdList, inputMapId)
    end
    table.sort(InputMapIdList)

    IsInitInputMapConfig = true
end

function XSetConfigs.GetInputMapIdList()
    InitInputMapIdConfig()
    return InputMapIdList
end

function XSetConfigs.GetInputMapIdStr(inputMapId)
    InitInputMapIdConfig()
    local config = InputMapTemplates[inputMapId]
    return config and config.Str or ""
end

function XSetConfigs.GetInputMapIdTimeId(inputMapId)
    InitInputMapIdConfig()
    local config = InputMapTemplates[inputMapId]
    return config and config.TimeId or ""
end

function XSetConfigs.GetInputMapIdTimeStageTypes(inputMapId)
    InitInputMapIdConfig()
    local config = InputMapTemplates[inputMapId]
    return config and config.StageType or nil
end