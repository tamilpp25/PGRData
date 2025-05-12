local XUiLottoQuickWearBase = require("XUi/XUiLotto/Tip/XUiLottoQuickWearBase")
---@class XUiLottoLifuQuickWear : XUiLottoQuickWearBase
local XUiLottoLifuQuickWear = XLuaUiManager.Register(XUiLottoQuickWearBase, "UiLottoLifuQuickWear")

function XUiLottoLifuQuickWear:DoGetCharacterId()
    return XLottoConfigs.GetLottoClientConfigNumber("LifuWeaponCharacter")
end

return XUiLottoLifuQuickWear