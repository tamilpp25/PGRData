XUiConfigs = XUiConfigs or {}

local TABLE_UICOMPONENT_PATH = "Client/Ui/UiComponent.tab"
local TABLE_SCENE_THEME_MATCHING_PATH = "Client/Ui/UiMainThemeMatching.tab"
local TABLE_UI_MAIN_SUB_MENU_PATH = "Client/Ui/UiMainSubMenu.tab"
local TABLE_UI_MAIN_SUB_MENU_DYNAMIC_PATH = "Client/Ui/UiMainSubMenuDynamic.tab"
local TABLE_UI_GOODS_LABEL_PATH = "Client/Ui/UiGoodsLabel.tab"
--local TABLE_UI_PATH = "Client/Ui/Ui.tab"
local UiComponentTemplates = {}
--local UiTemplates = {}
local UiThemeTemplates = {}

local UiMainSubMenu = {}

local UiMainSubMenuDynamic = {}

---@type table<number, XTableUiGoodsLabel>
local GoodsLabelTemplate = {}

--UI界面枚举 处理打开这个界面的界面类型
XUiConfigs.OpenUiType = {
    NieRCharacterUI = 1,
    RobotFashion = 2, --机器人涂装
}

XUiConfigs.SubMenuType = {
    System  = 1, --系统按钮
    Operate = 2, --运营按钮
}

XUiConfigs.LabelLocation = {
    --右上
    RT = 0,
    --右下
    RB = 1,
    --左下
    LB = 2,
    --左上
    LT = 3,
    --居中
    MID = 4,
}

XUiConfigs.SubMenuDefaultStyleType='Loading'

function XUiConfigs.Init()
    UiComponentTemplates = XTableManager.ReadByStringKey(TABLE_UICOMPONENT_PATH, XTable.XTableUiComponent, "Key")
    UiThemeTemplates = XTableManager.ReadByIntKey(TABLE_SCENE_THEME_MATCHING_PATH, XTable.XTableUiMainThemeMatching, "Id")
    UiMainSubMenu = XTableManager.ReadByIntKey(TABLE_UI_MAIN_SUB_MENU_PATH, XTable.XTableUiMainSubMenu, "Id")
    -- UiTemplates = XTableManager.ReadByStringKey(TABLE_UI_PATH, XTable.XTableUi, "UiName")
    UiMainSubMenuDynamic = XTableManager.ReadByStringKey(TABLE_UI_MAIN_SUB_MENU_DYNAMIC_PATH,XTable.XTableUiMainSubMenuDynamic,"Key")
    GoodsLabelTemplate = XTableManager.ReadByIntKey(TABLE_UI_GOODS_LABEL_PATH, XTable.XTableUiGoodsLabel, "Id")
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

function XUiConfigs.GetUiTheme(sceneId)
    local config = UiThemeTemplates[sceneId]
    if not config then
        XLog.ErrorTableDataNotFound("XUiConfigs.GetUiTheme", "SceneThemeMatching", TABLE_SCENE_THEME_MATCHING_PATH, "Id", sceneId)
        return {}
    end
    return config
end 

function XUiConfigs.GetSystemSubMenuList()
    local list = {}
    for _, config in pairs(UiMainSubMenu) do
        local timeId = config.TimeId or 0
        local conditionId = config.ConditionId or 0
        local unlock, desc = true, ""
        if XTool.IsNumberValid(conditionId) then
            unlock, desc = XConditionManager.CheckCondition(conditionId)
        end
        if XFunctionManager.CheckInTimeByTimeId(timeId) and unlock then
            table.insert(list, config)
        end
    end
    return list
end 

function XUiConfigs.GetDynamicSubMenuList()
    return UiMainSubMenuDynamic
end 

function XUiConfigs.GetDynamicSubMenuIconPath(styleType)
    local imgPathData=UiMainSubMenuDynamic[styleType]

    if imgPathData then
        if not imgPathData.ImgPath then
            XLog.ErrorTableDataNotFound('二级菜单指定的图片路径为空:','键名为'..styleType..'的图片路径',TABLE_UI_MAIN_SUB_MENU_DYNAMIC_PATH,imgPathData.StyleType,imgPathData.ImgPath)
        end
        return imgPathData.ImgPath
    elseif styleType==XUiConfigs.SubMenuDefaultStyleType then
        XLog.Warning("二级菜单列表为空，使用了默认数据，图片key："..XUiConfigs.SubMenuDefaultStyleType.." 但未在配置表"..TABLE_UI_MAIN_SUB_MENU_DYNAMIC_PATH.."中对自定义的图片进行配置，请自行确认是否需要进行配置")
    else
        XLog.ErrorTableDataNotFound('二级菜单指定的图片路径键不存在,请检查配置表数据与后台二级菜单填入数据是否一致，或需重启游戏以读取配置信息','键名为'..styleType..'的',TABLE_UI_MAIN_SUB_MENU_DYNAMIC_PATH)
    end
end 

--- 根据GoodsId获取对应的道具的标签, 注意判空，不一定所有道具都有
---@param templateId number
---@return XTableUiGoodsLabel
--------------------------
function XUiConfigs.GetGoodsLabelTemplate(templateId)
    return GoodsLabelTemplate[templateId]
end

function XUiConfigs.CheckHasLabel(templateId)
    return XUiConfigs.GetGoodsLabelTemplate(templateId) ~= nil
end

function XUiConfigs.GetLabelDescription(templateId)
    local template = XUiConfigs.GetGoodsLabelTemplate(templateId)
    return template and template.Description or ""
end