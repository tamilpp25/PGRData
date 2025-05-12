XPhotographConfigs = XPhotographConfigs or {}

XPhotographConfigs.PhotographViewState = {
    Normal = 1,
    Capture = 2,
    SDK = 3,
}

XPhotographConfigs.BackGroundState = {
    Full = 1,
    Low = 2,
}

XPhotographConfigs.BackGroundType = {
    PowerSaved = 1,     -- 省电模式
    Date = 2,           -- 昼夜模式
    Normal=3,           -- 普通类型，无特殊模式
}

XPhotographConfigs.SceneRotationType = {
    None = 0,           -- 省电模式
    YRotation = 1,      -- 基于Y轴旋转
}

XPhotographConfigs.PreviewOpenType=
{
    SceneSetting=1, --场景切换设置界面里打开
    Others=2 --其他地方
}

--- 需要弹窗提示权限获取的一级渠道
XPhotographConfigs.NeedShowPermissionRequestDialogChannelId = {
    [11] = true, -- 华为渠道
}

local TABLE_BACK_GROUND = "Share/PhotoMode/Background.tab"
local TABLE_PHOTOMODE_SHARE_INFO = "Client/PhotoMode/ShareInfo.tab"

-- XTablePhotoModeSdk

local SceneTemplates = {}
local ShareInfo = {}

function XPhotographConfigs.Init()
    SceneTemplates = XTableManager.ReadByIntKey(TABLE_BACK_GROUND, XTable.XTableBackground, "Id")
    ShareInfo = XTableManager.ReadByIntKey(TABLE_PHOTOMODE_SHARE_INFO, XTable.XTablePhotoModeShareInfo, "Id")
end

function XPhotographConfigs.GetSceneTemplates()
    return SceneTemplates
end

function XPhotographConfigs.GetShareInfoByType(platformType)
    return ShareInfo[platformType]
end

function XPhotographConfigs.GetSceneTemplateById(id)
    if not SceneTemplates then
        return nil
    end

    return SceneTemplates[id]
end

function XPhotographConfigs.GetBackgroundNameById(id)
    if not SceneTemplates then
        return nil
    end

    return SceneTemplates[id].Name
end

function XPhotographConfigs.GetBackgroundQualityById(id)
    if not SceneTemplates then
        return nil
    end

    return SceneTemplates[id].Quality
end

function XPhotographConfigs.GetBackgroundDescriptionById(id)
    if not SceneTemplates then
        return nil
    end

    return SceneTemplates[id].Description
end

function XPhotographConfigs.GetBackgroundWorldDescriptionById(id)
    if not SceneTemplates then
        return nil
    end

    return SceneTemplates[id].WorldDescription
end

function XPhotographConfigs.GetBackgroundIconById(id)
    if not SceneTemplates then
        return nil
    end

    return SceneTemplates[id].Icon
end

function XPhotographConfigs.GetBackgroundBigIconById(id)
    if not SceneTemplates then
        return nil
    end

    return SceneTemplates[id].BigIcon
end

function XPhotographConfigs.GetBackgroundPriorityById(id)
    if not SceneTemplates then
        return nil
    end

    return SceneTemplates[id].Priority
end

function XPhotographConfigs.GetBackgroundTypeById(id)
    if not SceneTemplates then
        return nil
    end
    return SceneTemplates[id].Type or nil
end

function XPhotographConfigs.GetBackgroundTagById(id)
    if not SceneTemplates then
        return nil
    end
    return SceneTemplates[id].Tag or nil
end

function XPhotographConfigs.GetBackgroundSwitchDescById(id)
    if not SceneTemplates then
        return nil
    end
    return SceneTemplates[id].SwitchDesc or nil
end

function XPhotographConfigs.GetBackgroundSceneRotation(id)
    if not SceneTemplates then
        return nil
    end
    return SceneTemplates[id].SceneRotation or nil
end

function XPhotographConfigs.SetLogoOrInfoPos(rectTransform, alignment, delayFrame, offsetX, offsetY, autoLayout)
    if not rectTransform or not alignment then
        return
    end
    local anchor = alignment.Anchor
    rectTransform.anchorMin = anchor
    rectTransform.anchorMax = anchor
    rectTransform.pivot = anchor
    --ContentSizeFitter，获取Size会出现数据异常，强制刷新
    if delayFrame then
        CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(rectTransform)
    end
    local x, y = anchor.x >= 0.5 and -offsetX or offsetX, anchor.y >= 0.5 and -offsetY or offsetY
    rectTransform.anchoredPosition = CS.UnityEngine.Vector2(x, y)
    if autoLayout then
        autoLayout.ChildAlignment = anchor.x >= 0.5 and CS.UnityEngine.TextAnchor.UpperRight or CS.UnityEngine.TextAnchor.UpperLeft
    end
end

function XPhotographConfigs.GetRankLevelText()
    if XPlayer.IsHonorLevelOpen() then
        return CS.XTextManager.GetText("HonorLevelShort") .. ":"
    else
        return CS.XTextManager.GetText("HostelDeviceLevel") .. ":"
    end
end 

function XPhotographConfigs.CsRecord(btnId, data)
    local dict = {}
    dict["button"] = btnId
    dict["role_level"] = XPlayer.GetLevel()
    if data then
        for k, v in pairs(data) do
            dict[k] = v
        end
    end
    CS.XRecord.Record(dict, "200007", "Photograph")
end 