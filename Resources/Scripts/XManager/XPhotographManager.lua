local CSTextManagerGetText = CS.XTextManager.GetText
local tableInsert = table.insert
local tableSort = table.sort

XPhotographManagerCreator = function()
    local XPhotographManager = {}
    local SceneIdList = {} -- 场景Id列表
    local SceneIdListInTime = {} -- 当前时间可以显示的场景列表Id
    local OwnCharDatas = {} -- 拥有的角色数据表
    local OwnCharDatasDic = {} -- 拥有的角色数据字典
    local HasSceneIdDic = {} -- 拥有的场景Id字典
    local TextureCache = {} -- 已保存图片缓存
    local ShareSDKIds = {} -- 当前渠道分享类型
    local CurSceneId = 0
    local CurSelectSceneId = 0 -- 当前选中的场景ID
    local DirPath = "" -- 准备分享的照片保存路径

    local PHOTOGRAPH_PROTO = {
        ChangeDisplayRequest = "ChangeDisplayRequest",
        ShareBackgroundRequest = "ShareBackgroundRequest", -- 分享消息
        PhotoBackgroundRequest = "PhotoBackgroundRequest", -- 拍照消息
    }

    function XPhotographManager.Init()
        for id in pairs(XPhotographConfigs.GetSceneTemplates()) do
            tableInsert(SceneIdList, id)
        end
        XEventManager.AddEventListener(XEventId.EVENT_CHARACTER_FIRST_GET, function() XPhotographManager.InitCharacterList() end)
        XEventManager.AddEventListener(XEventId.EVENT_FAVORABILITY_LEVELCHANGED, function() XPhotographManager.InitCharacterList() end)

        if XUserManager.Platform == XUserManager.PLATFORM.Android then
            DirPath = CS.UnityEngine.Application.persistentDataPath .. "/../../../../DCIM/ScreenShot/"
        elseif XUserManager.Platform == XUserManager.PLATFORM.IOS then
            DirPath = CS.UnityEngine.Application.persistentDataPath .. "/"
        elseif XUserManager.Platform == XUserManager.PLATFORM.Win then
            DirPath = CS.UnityEngine.Application.persistentDataPath .. "/PhotoAlbum/"
        else
            DirPath = CS.UnityEngine.Application.persistentDataPath .. "/"
        end
    end

    function XPhotographManager.InitSharePlatform(list)
        if not list then return end
        local channelId = 0 -- 默认值
        if XUserManager.Channel == XUserManager.CHANNEL.HERO then
            channelId = CS.XHgSdkAgent.GetChannelId()
        end
        for _,config in pairs(list) do
            if config.Id == channelId then
                ShareSDKIds = config.SdkId
            end
        end
    end

    function XPhotographManager.HandlerPhotoLoginData(data)
        CurSceneId = data.UseBackgroundId
        CurSelectSceneId = CurSceneId
        local haveSceneIds = data.HaveBackgroundIds
        HasSceneIdDic = {}
        for _, id in pairs(haveSceneIds) do
            HasSceneIdDic[id] = id
        end
        XPhotographManager.SortSceneIdList() -- 场景列表排序
        XPhotographManager.InitCharacterList() -- 网络数据下发时可以初始化一下角色数据列表 避免获取时再初始化
    end

    function XPhotographManager.HandlerAddPhotoScene(data)
        HasSceneIdDic[data.BackgroundId] = data.BackgroundId
        XPhotographManager.SortSceneIdList()
    end

    function XPhotographManager.GetSceneIdList()
        XPhotographManager.InitSceneIdListInTime()
        return SceneIdListInTime
    end

    function XPhotographManager.InitSceneIdListInTime()
        local nowTimeStamp = XTime.GetServerNowTimestamp()
        SceneIdListInTime = {}
        for _, id in ipairs(SceneIdList) do
            local timeStr = XPhotographManager.GetSceneTemplateById(id).ShowStr
            if not timeStr or timeStr == "" then
                tableInsert(SceneIdListInTime, id)
            else
                if XTime.ParseToTimestamp(timeStr) <= nowTimeStamp then
                    tableInsert(SceneIdListInTime, id)
                end
            end
        end
    end

    function XPhotographManager.SortSceneIdList()
        tableSort(SceneIdList, function(idA, idB)
            if idA ~= CurSelectSceneId and idB ~= CurSelectSceneId then
                local isSceneAHave = XPhotographManager.CheckSceneIsHaveById(idA)
                local isSceneBHave = XPhotographManager.CheckSceneIsHaveById(idB)
                if isSceneAHave == isSceneBHave then
                    local priorityA = XPhotographManager.GetSceneTemplateById(idA).Priority
                    local priorityB = XPhotographManager.GetSceneTemplateById(idB).Priority
                    if priorityA == priorityB then
                        return idA < idB
                    else
                        return priorityA > priorityB
                    end
                else
                    return isSceneAHave
                end
            else
                return idA == CurSelectSceneId
            end
        end)
    end

    function XPhotographManager.GetSceneIdByIndex(index)
        if not SceneIdListInTime or #SceneIdListInTime <= 0 then
            XPhotographManager.InitSceneIdListInTime()
        end

        return SceneIdListInTime[index]
    end

    function XPhotographManager.GetSceneTemplateById(id)
        return XPhotographConfigs.GetSceneTemplateById(id)
    end

    function XPhotographManager.InitCharacterList()
        local allCharDatas = XDataCenter.CharacterManager.GetCharacterList()
        local curAssistantId = XDataCenter.DisplayManager.GetDisplayChar().Id

        OwnCharDatas = {}
        for _, v in pairs(allCharDatas or {}) do
            local characterId = v.Id
            local isOwn = XDataCenter.CharacterManager.IsOwnCharacter(characterId)
            if isOwn then
                local name = XCharacterConfigs.GetCharacterName(characterId)
                local tradeName = XCharacterConfigs.GetCharacterTradeName(characterId)
                local logName = XCharacterConfigs.GetCharacterLogName(characterId)
                local enName = XCharacterConfigs.GetCharacterEnName(characterId)

                tableInsert(OwnCharDatas, {
                    Id = characterId,
                    Name = name,
                    TradeName = tradeName,
                    LogName = logName,
                    EnName = enName,
                    TrustLv = v.TrustLv or 1,
                    Selected = (curAssistantId == characterId),
                })
                OwnCharDatasDic[characterId] = {
                    Name = name,
                    TradeName = tradeName,
                    LogName = logName,
                    EnName = enName,
                    TrustLv = v.TrustLv or 1,
                }
            end
        end
        tableSort(OwnCharDatas, function(dataA, dataB)
            if dataA.TrustLv == dataB.TrustLv then
                return dataA.Id < dataB.Id
            else
                return dataA.TrustLv > dataB.TrustLv
            end
        end)
    end

    function XPhotographManager.GetCharacterList()
        if not OwnCharDatas or #OwnCharDatas <= 0 then
            XPhotographManager.InitCharacterList()
        end

        if not OwnCharDatas or #OwnCharDatas <= 0 then
            return nil
        end

        return OwnCharDatas
    end

    function XPhotographManager.GetCharacterDataByIndex(index)
        if not OwnCharDatas or #OwnCharDatas <= 0 then
            XPhotographManager.InitCharacterList()
        end

        if not OwnCharDatas or #OwnCharDatas <= 0 then
            return nil
        end

        return OwnCharDatas[index]
    end

    function XPhotographManager.GetCharacterDataById(id)
        if not OwnCharDatasDic then
            return nil
        end

        return OwnCharDatasDic[id]
    end

    function XPhotographManager.CheckSceneIsHaveById(id)
        if HasSceneIdDic and HasSceneIdDic[id] then
            return true
        else
            return false
        end
    end

    function XPhotographManager.GetCurSceneId()
        return CurSceneId
    end

    function XPhotographManager.GetSceneIndexById(sceneId)
        if not SceneIdListInTime or #SceneIdListInTime <= 0 then
            XPhotographManager.InitSceneIdListInTime()
        end

        for index, id in ipairs(SceneIdListInTime) do
            if sceneId == id then
                return index
            end
        end

        return nil
    end

    function XPhotographManager.GetCharIndexById(charId)
        for index, data in ipairs(OwnCharDatas) do
            if charId == data.Id then
                return index
            end
        end

        return nil
    end

    function XPhotographManager.GetFashionIndexByFashionList(charId, fashionList)
        local curFashionId = XDataCenter.FashionManager.GetFashionIdByCharId(charId)
        for index, fashionId in ipairs(fashionList) do
            if curFashionId == fashionId then
                return index
            end
        end

        return nil
    end

    function XPhotographManager.SharePhoto(photoName, texture, platformType)
        if not photoName or not texture then
            return
        end

        local writeDesc = CS.XTextManager.GetText("PremissionWriteDesc")
        XPermissionManager.TryGetPermission(CS.XPermissionEnum.WRITE_EXTERNAL_STORAGE, writeDesc, function(isWriteGranted, dontTip)
            if not isWriteGranted then
                XUiManager.TipText("PremissionDesc", XUiManager.UiTipType.Tip)
                XLog.Debug("获取权限错误_NotisWriteGranted")
                return
            end

            if not XPhotographManager.IsInTextureCache(photoName) then
                CS.XTool.SavePhotoAlbumImg(photoName, texture, function(errorCode)
                    if errorCode > 0 then
                        XUiManager.TipText("PremissionDesc", XUiManager.UiTipType.Tip) -- ios granted总是true, 权限未开通code返回1
                        XLog.Debug("照片保存失败 Code："..errorCode)
                        return
                    end
                    XPhotographManager.SetTextureCache(photoName)
                    XPhotographManager.DoShare(photoName, platformType)
                end)
            else
                XPhotographManager.DoShare(photoName, platformType)
            end
        end)
    end

    function XPhotographManager.DoShare(photoName, platformType)
        if platformType == XPlatformShareConfigs.PlatformType.Local then -- 本地保存
            XUiManager.TipText("PhotoModeSaveSuccess", XUiManager.UiTipType.Tip)
        else
            local cfg = XPhotographConfigs.GetShareInfoByType(platformType)
            local fileFullPath = string.format("%s%s%s", DirPath, photoName, ".png")
            -- XLog.Debug("fileFullPath", fileFullPath, "cfg.Text", cfg.Text, "platformType", platformType, "XPlatformShareConfigs.ShareType.Image", XPlatformShareConfigs.ShareType.Image, "XPhotographManager.ShareCallback", XPhotographManager.ShareCallback)
            XPlatformShareManager.Share(XPlatformShareConfigs.ShareType.Image, platformType, XPhotographManager.ShareCallback, fileFullPath, cfg.Text, cfg.Param[1], cfg.Param[2], false)
            XNetwork.Send(PHOTOGRAPH_PROTO.ShareBackgroundRequest, {})
        end
    end

    function XPhotographManager.ShareCallback(result)
        -- XLog.Debug("ShareCallback result:", result)
        if result == XPlatformShareConfigs.ShareResult.Successful then
            XUiManager.TipText("PhotoModeShareSuccess", XUiManager.UiTipType.Tip)
        elseif result == XPlatformShareConfigs.ShareResult.Canceled then
            XUiManager.TipText("PhotoModeShareCancel", XUiManager.UiTipType.Tip)
        elseif result == XPlatformShareConfigs.ShareResult.Failed then
            XUiManager.TipText("PhotoModeShareFailed", XUiManager.UiTipType.Tip)
        end
    end

    function XPhotographManager.SetTextureCache(photoName)
        tableInsert(TextureCache, photoName)
    end

    function XPhotographManager.IsInTextureCache(photoName)
        for i = #TextureCache, 1, -1 do
            if TextureCache[i] == photoName then
                return true
            end
        end

        return false
    end

    function XPhotographManager.ClearTextureCache()
        if XUserManager.Platform == XUserManager.PLATFORM.IOS then
            if next(TextureCache) then
                for _, textureName in pairs(TextureCache) do
                    local fileFullPath = string.format("%s%s%s", DirPath, textureName, ".png")
                    CS.XTool.DeleteFile(fileFullPath)
                end
            end
        end
        TextureCache = {}
    end

    function XPhotographManager.ChangeDisplay(sceneId, charId, fashionId, cb)
        if not XPhotographManager.CheckSceneIsHaveById(sceneId) then -- 场景未拥有
            XUiManager.TipError(CSTextManagerGetText("PhotoModeChangeFailedNotHasBackground"))
            return
        end

        if not XDataCenter.CharacterManager.IsOwnCharacter(charId) then -- 角色未拥有
            XUiManager.TipError(CSTextManagerGetText("PhotoModeChangeFailedNotHasCharacter"))
            return
        end

        if not XDataCenter.FashionManager.CheckHasFashion(fashionId) then -- 涂装未拥有
        XUiManager.TipError(CSTextManagerGetText("PhotoModeChangeFailedNotHasFashion"))
            return
        end

        XNetwork.Call(PHOTOGRAPH_PROTO.ChangeDisplayRequest, { BackgroundId = sceneId, CharId = charId, FashionId = fashionId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            CurSceneId = sceneId
            XPhotographManager.SortSceneIdList()

            local curDisplayCharId = XDataCenter.DisplayManager.GetDisplayChar().Id
            if curDisplayCharId ~= charId then
                XDataCenter.SignBoardManager.ChangeDisplayCharacter(charId)
            end
            XDataCenter.DisplayManager.SetDisplayCharByCharacterId(charId)
            XPlayer.SetDisplayCharId(charId)

            XUiManager.TipMsg(CSTextManagerGetText("PhotoModeChangeSuccess"))
            if cb then
                cb()
            end
        end)
    end

    function XPhotographManager.GetShareSDKIds()
        return ShareSDKIds
    end

    function XPhotographManager.GetShareTypeByIndex(index)
        if not ShareSDKIds then
            return nil
        end

        return ShareSDKIds[index]
    end

    function XPhotographManager.SetCurSelectSceneId(SceneId)
        local sceneId = SceneId
        if not SceneId then
            sceneId = CurSceneId
        end
        CurSelectSceneId = sceneId
        XPhotographManager.SortSceneIdList()
    end

    function XPhotographManager.GetCurSelectSceneId()
        return CurSelectSceneId
    end

    function XPhotographManager.SendPhotoGraphRequest()
        XNetwork.Send(PHOTOGRAPH_PROTO.PhotoBackgroundRequest, {})
    end

    XPhotographManager.Init()
    return XPhotographManager
end

XRpc.NotifyBackgroundLoginData = function(data)
    XDataCenter.PhotographManager.HandlerPhotoLoginData(data)
end

XRpc.NotifyAddBackground = function(data)
    XDataCenter.PhotographManager.HandlerAddPhotoScene(data)
end

XRpc.NotifySharePlatformConfigList = function (data)
    XDataCenter.PhotographManager.InitSharePlatform(data)
end