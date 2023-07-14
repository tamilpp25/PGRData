XPlatformShareConfigs = XPlatformShareConfigs or {}

XPlatformShareConfigs.PlatformType = {
    QQ = 1,
    QQSpace = 2,
    WeChat = 3,
    WeChatTimeline = 4,
    Weibo = 5,
    Local = 100,
}

XPlatformShareConfigs.PlatformTypeToHeroSharePlatform = {
    [XPlatformShareConfigs.PlatformType.QQ] = CS.SharePlatform.QQ,
    [XPlatformShareConfigs.PlatformType.QQSpace] = CS.SharePlatform.QQ_Space,
    [XPlatformShareConfigs.PlatformType.WeChat] = CS.SharePlatform.WeChat,
    [XPlatformShareConfigs.PlatformType.WeChatTimeline] = CS.SharePlatform.WXTimeLine,
    [XPlatformShareConfigs.PlatformType.Weibo] = CS.SharePlatform.Weibo,
}

XPlatformShareConfigs.ShareType = {
    Image = 1,
    Link = 2,
    Text = 3,
}

XPlatformShareConfigs.ShareTypeToHeroShareType = {
    [XPlatformShareConfigs.ShareType.Image] = CS.ShareType.Image,
    [XPlatformShareConfigs.ShareType.Link] = CS.ShareType.Link,
    [XPlatformShareConfigs.ShareType.Text] = CS.ShareType.Text,
}

XPlatformShareConfigs.ShareResult = {
    Successful = 0,
    Failed = 1,
    Canceled = -1,
}

local TABLE_PLATFORM_SHARE = "Client/PlatformShare/PlatformShare.tab"
local TABLE_PLATFORM_SHARE_OPEN = "Client/PlatformShare/PlatformShareOpen.tab"  --根据服务器id控制是否开启分享功能

local PlatformShareTemplates
local PlatformShareOpenTemplates

function XPlatformShareConfigs.Init()
    PlatformShareTemplates = XTableManager.ReadByIntKey(TABLE_PLATFORM_SHARE, XTable.XTablePlatformShare, "Id")
    PlatformShareOpenTemplates = XTableManager.ReadByStringKey(TABLE_PLATFORM_SHARE_OPEN, XTable.XTablePlatformShareOpen, "Id")
end

function XPlatformShareConfigs.GetPlatformShareTemplate(id)
    local template = PlatformShareTemplates[id]
    if template then return template end
    XLog.ErrorTableDataNotFound("XPlatformShareConfigs.GetPlatformShareTemplate", "template", TABLE_PLATFORM_SHARE, "id", tostring(id))
end

function XPlatformShareConfigs.IsPlatformShareOpen(id)
    local template = PlatformShareOpenTemplates[id]
    return template ~= nil and template.IsOpen
end