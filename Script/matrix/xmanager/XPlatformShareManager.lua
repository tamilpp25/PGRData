
--
--Author: wujie
--Note: 平台分享操作管理

local CSXHeroShareAgent = CS.XHeroShareAgent

XPlatformShareManager = XPlatformShareManager or {}

-- CS.XHeroShareAgent.Share方法中的isEmbedImage目前不需要，均传false即可
-- CS.XHeroShareAgent.Share方法中showUi为是否使用sdk自带的渠道分享窗口

-- path为必传字符串
function XPlatformShareManager.ShareImage(shareId, callback, path, text, showUi)

    if string.IsNilOrEmpty(path) then
        XLog.Error("XPlatformShareManager.ShareImage函数错误，image路径不能为空")
        return
    end
    local hasValue = table.contains(XEnumConst.SharePlatform,shareId)
    if not hasValue then
        XLog.Error("XPlatformShareManager.ShareImage函数错误, shareId不存在，shareId是 " .. shareId)
        return
    end
    XHeroSdkManager.Share(shareId,path,callback,nil,text)
end

-- shareLink, shareLinkTitle为必传字符串
function XPlatformShareManager.ShareLink(shareId, callback, shareLink, shareLinkTitle, shareLinkDesc, imageLink, showUi)
    if string.IsNilOrEmpty(shareLink) then
        XLog.Error("XPlatformShareManager.ShareLink函数错误, shareLink 分享的链接不能为空")
        return
    end
    if string.IsNilOrEmpty(shareLinkTitle) then
        XLog.Error("XPlatformShareManager.ShareLink函数错误, shareLinkTitle 不能为空")
        return
    end
    local hasValue = table.contains(XEnumConst.SharePlatform,shareId)
    if not hasValue then
        XLog.Error("XPlatformShareManager.ShareLink函数错误, shareId不存在，shareId是 " .. shareId)
        return
    end

    CSXHeroShareAgent.Share(
            callback,
            showUi or false,
            XPlatformShareConfigs.ShareTypeToHeroShareType[XPlatformShareConfigs.ShareType.Link],
            shareId,
            nil,
            false,
            nil,
            imageLink,
            shareLink,
            shareLinkTitle,
            shareLinkDesc
    )
end

-- text为必传字段
function XPlatformShareManager.ShareText(shareId, callback, text, showUi)
    if string.IsNilOrEmpty(text) then
        XLog.Error("text is nil Or empty")
        return
    end
    local hasValue = table.contains(XEnumConst.SharePlatform,shareId)
    if not hasValue then
        XLog.Error("shareId not exist, shareId is " .. shareId)
        return
    end

    if shareId == XEnumConst.SharePlatform.WXMoments and XUserManager.Platform == XUserManager.PLATFORM.Android then
        CSXHeroShareAgent.Share(
                callback,
                showUi or false,
                XPlatformShareConfigs.ShareTypeToHeroShareType[XPlatformShareConfigs.ShareType.Text],
                shareId,
                text,
                false,
                nil,
                nil,
                nil,
                " ",
                nil
        )
    else
        CSXHeroShareAgent.Share(
                callback,
                showUi or false,
                XPlatformShareConfigs.ShareTypeToHeroShareType[XPlatformShareConfigs.ShareType.Text],
                shareId,
                text,
                false
        )
    end
end



--callback 为非必传字段，不一定需要
function XPlatformShareManager.Share(shareType, shareId, callback, param1, param2, param3, param4, showUi)
    if shareType == XPlatformShareConfigs.ShareType.Image then
        XPlatformShareManager.ShareImage(shareId, callback, param1, param2, showUi)
    elseif shareType == XPlatformShareConfigs.ShareType.Link then
        XPlatformShareManager.ShareLink(shareId, callback, param1, param2, param3, param4, showUi)
    elseif shareType == XPlatformShareConfigs.ShareType.Text then
        XPlatformShareManager.ShareText(shareId, callback, param1, showUi)
    else
        XLog.Error("XPlatformShareManager.Share 函数错误，不能分享 类型为： " .. shareType .. "的内容")
    end
end

--当分享内容完全依赖表格时可以调用这个接口
function XPlatformShareManager.ShareByPlatformShareId(platformType, callback, platformShareId, showUi)
    local template = XPlatformShareConfigs.GetPlatformShareTemplate(platformShareId)
    XPlatformShareManager.Share(
            template.ShareType,
            platformType,
            callback,
            template.ShareParam[1],
            template.ShareParam[2],
            template.ShareParam[3],
            template.ShareParam[4],
            showUi
    )
end
