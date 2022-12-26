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

local TABLE_KEYBOARD_MAP_PATH = "Client/KeySet/KeyboardMap.tab"
local TABLE_CONTROLLER_MAP_PATH = "Client/KeySet/ControllerMap.tab"
local KeyboardMapTemplates = {}
local ControllerMapTemplates = {}

XSetConfigs.SelfNumEnum = {
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

XSetConfigs.ControllerSetItemType = {
    Section = 1, -- 副标题
    SetButton = 2, -- 键位设置按键
    Slider = 3, -- 滑动条（仅支持镜头灵敏度调节）
}

XSetConfigs.SelfNum = "SelfNum"---自身伤害数字
XSetConfigs.FriendNum = "FriendNum"--队友伤害数字
XSetConfigs.FriendEffect = "FriendEffect"--队友特效
XSetConfigs.IsFirstFriendEffect = "IsFirstFriendEffect"--是否是第一次在联机页面开启队友特效
XSetConfigs.ScreenOff = "ScreenOff"
XSetConfigs.DefaultDynamicJoystickKey = "DefaultDynamicJoystick"
XSetConfigs.DefaultFocusTypeKey = "DefaultFocusType"
XSetConfigs.DefaultFocusButtonKey = "DefaultFocusButton"
XSetConfigs.DefaultInviteButtonKey = "DefaultInviteButton"
XSetConfigs.DefaultWeaponTransTypeKey = "DefaultWeaponTransType"
XSetConfigs.DefaultRechargeTypeKey = "DefaultRechargeType"

XSetConfigs.SelfNumSizes = {}

function XSetConfigs.Init()
    local key1 = XSetConfigs.SelfNumKeyConfig.SelfNumSmall
    local key2 = XSetConfigs.SelfNumKeyConfig.SelfNumMiddle
    local key3 = XSetConfigs.SelfNumKeyConfig.SelfNumBig
    XSetConfigs.SelfNumSizes[key1] = CS.XGame.ClientConfig:GetInt(key1) or 0
    XSetConfigs.SelfNumSizes[key2] = CS.XGame.ClientConfig:GetInt(key2) or 0
    XSetConfigs.SelfNumSizes[key3] = CS.XGame.ClientConfig:GetInt(key3) or 0
    XSetConfigs.DefaultDynamicJoystick = CS.XGame.ClientConfig:GetInt(XSetConfigs.DefaultDynamicJoystickKey)
    XSetConfigs.DefaultFocusType = CS.XGame.ClientConfig:GetInt(XSetConfigs.DefaultFocusTypeKey)
    XSetConfigs.DefaultFocusButton = CS.XGame.ClientConfig:GetInt(XSetConfigs.DefaultFocusButtonKey)
    XSetConfigs.DefaultInviteButton = CS.XGame.ClientConfig:GetInt(XSetConfigs.DefaultInviteButtonKey)
    XSetConfigs.DefaultWeaponTransType = CS.XGame.ClientConfig:GetInt(XSetConfigs.DefaultWeaponTransTypeKey)
    XSetConfigs.DefaultRechargeType = CS.XGame.ClientConfig:GetInt(XSetConfigs.DefaultRechargeTypeKey)
    KeyboardMapTemplates = XTableManager.ReadByIntKey(TABLE_KEYBOARD_MAP_PATH, XTable.XTableInputSetKeyboardMap, "Id")
    ControllerMapTemplates = XTableManager.ReadByIntKey(TABLE_CONTROLLER_MAP_PATH, XTable.XTableInputSetControllerMap, "Id")
end

function XSetConfigs.GetKeyboardMapCfg()
    return KeyboardMapTemplates
end

function XSetConfigs.GetControllerMapCfg()
    return ControllerMapTemplates
end

function XSetConfigs.GetControllerKeyText(npcOperationKey)
    for i, config in pairs(ControllerMapTemplates) do
        if config.NpcOperationKey == npcOperationKey then
            return config.Title
        end
    end
    return false
end
