local XUiLottoQuickWearBase = require("XUi/XUiLotto/Tip/XUiLottoQuickWearBase")
---@class XUiLottoVeraQuickWear : XUiLottoQuickWearBase
local XUiLottoVeraQuickWear = XLuaUiManager.Register(XUiLottoQuickWearBase, "UiLottoVeraQuickWear")

function XUiLottoVeraQuickWear:DoGetCharacterId()
    return XLottoConfigs.GetLottoClientConfigNumber("VeraWeaponCharacter")
end

return XUiLottoVeraQuickWear