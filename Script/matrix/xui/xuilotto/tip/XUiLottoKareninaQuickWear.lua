local XUiLottoQuickWearBase = require("XUi/XUiLotto/Tip/XUiLottoQuickWearBase")
---@class XUiLottoKareninaQuickWear : XUiLottoQuickWearBase
local XUiLottoKareninaQuickWear = XLuaUiManager.Register(XUiLottoQuickWearBase, "UiLottoKareninaQuickWear")

function XUiLottoKareninaQuickWear:DoGetCharacterId()
    return XLottoConfigs.GetLottoClientConfigNumber("WeaponFashionCharacter")
end

return XUiLottoKareninaQuickWear