local TABLE_IMAGE_PATH = "Client/Fight/UiFightCommonImage.tab"
local ImageConfigs = {}

XFightCommonImageConfigs = XFightCommonImageConfigs or {}

function XFightCommonImageConfigs.Init()
    ImageConfigs = XTableManager.ReadByIntKey(TABLE_IMAGE_PATH, XTable.XTableUiFightCommonImage, "Id")
end

local GetImageConfig = function(id)
    local config = ImageConfigs[id]
    if not config then
        XLog.ErrorTableDataNotFound("XFightCommonImageConfigs.GetImageConfig", "ImageConfigs", TABLE_IMAGE_PATH, "Id", id)
        return
    end
    return config
end

function XFightCommonImageConfigs.GetRawImagePath(id)
    local config = GetImageConfig(id)
    return config.RawImagePath
end

function XFightCommonImageConfigs.GetImageX(id)
    local config = GetImageConfig(id)
    return config.PosX
end

function XFightCommonImageConfigs.GetImageY(id)
    local config = GetImageConfig(id)
    return config.PosY
end

function XFightCommonImageConfigs.GetImageWidth(id)
    local config = GetImageConfig(id)
    return config.Width
end

function XFightCommonImageConfigs.GetImageHeight(id)
    local config = GetImageConfig(id)
    return config.Height
end

function XFightCommonImageConfigs.GetIsShowBg(id)
    local config = GetImageConfig(id)
    return config.IsShowBg
end

function XFightCommonImageConfigs.GetIsShowMask(id)
    local config = GetImageConfig(id)
    return config.IsShowMask
end