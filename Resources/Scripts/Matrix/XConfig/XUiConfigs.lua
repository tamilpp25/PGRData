XUiConfigs = XUiConfigs or {}

local TABLE_UICOMPONENT_PATH = "Client/Ui/UiComponent.tab"
--local TABLE_UI_PATH = "Client/Ui/Ui.tab"
local UiComponentTemplates = {}
--local UiTemplates = {}

--UI界面枚举 处理打开这个界面的界面类型
XUiConfigs.OpenUiType = {
    NieRCharacterUI = 1,
}

function XUiConfigs.Init()
    UiComponentTemplates = XTableManager.ReadByStringKey(TABLE_UICOMPONENT_PATH, XTable.XTableUiComponent, "Key")
    -- UiTemplates = XTableManager.ReadByStringKey(TABLE_UI_PATH, XTable.XTableUi, "UiName")
end

function XUiConfigs.GetComponentUrl(key)
    local template = UiComponentTemplates[key]

    if not template then
        XLog.ErrorTableDataNotFound("XUiConfigs.GetComponentUrl", "UiComponent", TABLE_UICOMPONENT_PATH, "key", key)
        return
    end

    return template.PrefabUrl
end

function XUiConfigs.GetUiModelUrl(uiName)
    if not uiName then
        return
    end

    local uiTemplate = nil -- CS.XUiManager.Instance.UiTemplate[uiName]

    if CS.XUiManager.Instance.UiTemplate:ContainsKey(uiName) then
        uiTemplate = CS.XUiManager.Instance.UiTemplate[uiName]
    end

    if not uiTemplate then
        XLog.ErrorTableDataNotFound("XUiConfigs.GetUiModelUrl", "Ui", TABLE_UI_PATH, "UiName", uiName)
        return
    end

    return uiTemplate.ModelUrl
end