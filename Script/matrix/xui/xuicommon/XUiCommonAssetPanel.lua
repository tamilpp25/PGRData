-- 通用道具显示按钮面板控件
local XUiCommonAssetPanel = XClass(nil, "XUiCommonAsset")
local CommonAsset = require("XUi/XUiCommon/XUiCommonAsset")
local InitAssetsList = function(panel, assetDataList)
    local i = 1
    while true do
        local assetUi = panel["PanelTool" .. i]
        if not assetUi then
            break
        end
        CommonAsset.New(assetUi, assetDataList[i])
        i = i + 1
    end
end
function XUiCommonAssetPanel:Ctor(ui, assetDataList)
    XTool.InitUiObjectByUi(self, ui)
    InitAssetsList(self, assetDataList)
end
return XUiCommonAssetPanel