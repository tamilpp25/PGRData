local XUiLottoQuickWearBase = require("XUi/XUiLotto/Tip/XUiLottoQuickWearBase")
---@class XUiLottoLunaQuickWear : XUiLottoQuickWearBase
local XUiLottoLunaQuickWear = XLuaUiManager.Register(XUiLottoQuickWearBase, "UiLottoLunaQuickWear")

function XUiLottoLunaQuickWear:DoGetCharacterId()
    return XLottoConfigs.GetLottoClientConfigNumber("LunaWeaponFashionCharacter")
end

return XUiLottoLunaQuickWear