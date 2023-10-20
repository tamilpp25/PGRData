local XUiCerberusGameRole = require("XUi/XUiCerberusGame/XUiCerberusGameRole")
local XUiCerberusGameRoleV2P9 = XLuaUiManager.Register(XUiCerberusGameRole, "UiCerberusGameRoleV2P9")

function XUiCerberusGameRole:GetConfig(index)
    local allConfig = XMVCA.XCerberusGame:GetConfigByTableKey(XMVCA.XCerberusGame:GetTableKey().CerberusGameCharacterInfoV2P9)
    return allConfig[index]
end

return XUiCerberusGameRoleV2P9