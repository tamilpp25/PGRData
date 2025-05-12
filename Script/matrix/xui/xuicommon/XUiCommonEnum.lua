XUiButtonState = {
    Normal = 0,
    Press = 1,
    Select = 2,
    Disable = 3,
}

XUiFightControlState = {
    Normal = 0,
    Hard = 1,
    Ex = 2,
}

XUiAppearanceShowType = {
    ToAll = 1,
    ToFriend = 2,
    ToSelf = 3,
}

XUiToggleState = {
    Off = 0,
    On = 1,
}

XUiCompareType = {
    Equal = 1, --等于
    NoLess = 2, --大于等于
}

XUiMainChargeState = {
    None = 0, --初始状态
    Enough = 1, --电量充足
    LowPower = 2, --电量不足
    Charge = 3, --充电中
}

UiCharacterGridType = {
    Normal = 1, --我拥有的角色
    Try = 2, --试玩角色(robot)
}

--自定义选择种类
UiSelectCharacterType = {
    Normal = 1, --选取我所拥有的角色
    LimitedByCharacterAndRobot = 2, --在给定的限制范围（robotId，以及这些robot对应的characterid）内选取角色 工会boss使用
    WorldBoss = 3, --选取我所拥有的角色和开放的机器人（世界Boss用）
    NieROnlyRobot = 4, --仅使用开放的机器人（尼尔玩法用）
}

XUiPlayerHead = require("XUi/XUiCommon/XUiPlayerHead")