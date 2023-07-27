local CSTextManagerGetText = CS.XTextManager.GetText
local tableInsert = table.insert
local tableSort = table.sort

local XPhotographSet = require("XEntity/XPhotograph/XPhotographSet")

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
    local PhotographSetKey = string.format("PhotographSetKey_%s_Setting", XPlayer.Id)
    local PhotographSetData

    local PHOTOGRAPH_PROTO = {
        ChangeDisplayRequest = "ChangeDisplayRequest",
        ShareBackgroundRequest = "ShareBackgroundRequest", -- 分享消息
        PhotoBackgroundRequest = "PhotoBackgroundRequest", -- 拍照消息
    }

    -- 背景场景预览状态
    local PreviewState = XPhotographConfigs.BackGroundState.Full
    local PreviewSceneId = nil

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
        local cacheData = XSaveTool.GetData(PhotographSetKey)
        PhotographSetData = XPhotographSet.New()
        if cacheData then
            PhotographSetData:Update(cacheData.LogoValue, cacheData.InfoValue, cacheData.OpenLevel, cacheData.OpenUId)
        end
    end
    
    function XPhotographManager.GetSetData()
        return PhotographSetData
    end
    
    function XPhotographManager.SaveSetData()
        if not PhotographSetData then
            return
        end
        XSaveTool.SaveData(PhotographSetKey, PhotographSetData:GetSampleData())
    end

    function XPhotographManager.InitSharePlatform(list)
        if not list then return end
        local channelId = 0 -- 默认值
        if XUserManager.IsUseSdk() then
            channelId = CS.XHeroSdkAgent.GetChannelId()
        end
        for _,config in pairs(list) do
            if config.Id == channelId then
                ShareSDKIds = config.SdkId
            end
        end
    end

    function XPhotographManager.InitCurSceneId(sceneId)
        CurSceneId = sceneId
        CurSelectSceneId = CurSceneId
    end

    function XPhotographManager.HandlerPhotoLoginData(data)
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
        --获得新场景时打开提示窗
        XLuaUiManager.Open('UiSceneSettingObtain',data)
        --新获得场景需要刷新终端红点
        XEventManager.DispatchEvent(XEventId.EVENT_MAINUI_TERMINAL_STATUS_CHANGE)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_MAINUI_TERMINAL_STATUS_CHANGE)
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
        --tableSort(SceneIdList, function(idA, idB)
        --    if idA ~= CurSelectSceneId and idB ~= CurSelectSceneId then
        --        local isSceneAHave = XPhotographManager.CheckSceneIsHaveById(idA)
        --        local isSceneBHave = XPhotographManager.CheckSceneIsHaveById(idB)
        --        if isSceneAHave == isSceneBHave then
        --            local priorityA = XPhotographManager.GetSceneTemplateById(idA).Priority
        --            local priorityB = XPhotographManager.GetSceneTemplateById(idB).Priority
        --            if priorityA == priorityB then
        --                return idA < idB
        --            else
        --                return priorityA > priorityB
        --            end
        --        else
        --            return isSceneAHave
        --        end
        --    else
        --        return idA == CurSelectSceneId
        --    end
        --end)
        tableSort(SceneIdList, function(idA, idB)
            local priorityA = XPhotographManager.GetSceneTemplateById(idA).Priority
            local priorityB = XPhotographManager.GetSceneTemplateById(idB).Priority
            return priorityA > priorityB
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
        local allCharDatas = XMVCA.XCharacter:GetCharacterList()
        local curAssistantId = XDataCenter.DisplayManager.GetDisplayChar().Id

        OwnCharDatas = {}
        for _, v in pairs(allCharDatas or {}) do
            local characterId = v.Id
            local isOwn = XMVCA.XCharacter:IsOwnCharacter(characterId)
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
        return PreviewSceneId or CurSceneId
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

    function XPhotographManager.GetFashionIndexByFashionList(fashionId, fashionList)
        for index, fId in ipairs(fashionList) do
            if fId == fashionId then
                return index
            end
        end

        return nil
    end
    
    function XPhotographManager.GetFashionIndexById(charId, fashionId)
        local list = XDataCenter.FashionManager.GetCurrentTimeFashionByCharId(charId)
        for i, fId in ipairs(list or {}) do
            if fashionId == fId then
                return i
            end
        end
        return 0
    end

    function XPhotographManager.SharePhoto(photoName, texture, platformType, shareText)
        if not photoName or not texture then
            return
        end

        local writeDesc = CS.XTextManager.GetText("PremissionWriteDesc")
        local tipFunc = XLuaUiManager.IsUiShow("UiPhotographPortrait") and XUiManager.TipPortraitText or XUiManager.TipText
        XPermissionManager.TryGetPermission(CS.XPermissionEnum.WRITE_EXTERNAL_STORAGE, writeDesc, function(isWriteGranted, dontTip)
            if not isWriteGranted then
                tipFunc("PremissionDesc")
                XLog.Debug("获取权限错误_NotisWriteGranted")
                return
            end

            if not XPhotographManager.IsInTextureCache(photoName) then
                CS.XTool.SavePhotoAlbumImg(photoName, texture, function(errorCode)
                    if errorCode > 0 then
                        tipFunc("PremissionDesc") -- ios granted总是true, 权限未开通code返回1
                        XLog.Debug("照片保存失败 Code："..errorCode)
                        return
                    end
                    XPhotographManager.SetTextureCache(photoName)
                    XPhotographManager.DoShare(photoName, platformType, shareText)
                end)
            else
                XPhotographManager.DoShare(photoName, platformType, shareText)
            end
        end)
    end
    local SharePhotoName
    function XPhotographManager.DoShare(photoName, platformType, shareText)
        local tipFunc = XLuaUiManager.IsUiShow("UiPhotographPortrait") and XUiManager.TipPortraitText or XUiManager.TipText
        if platformType == XPlatformShareConfigs.PlatformType.Local then -- 本地保存
            tipFunc("PhotoModeSaveSuccess")
        else
            local cfg = XPhotographConfigs.GetShareInfoByType(platformType)
            local fileFullPath = string.format("%s%s%s", DirPath, photoName, ".png")
            if shareText == nil then
                shareText = cfg.Text
            end
            SharePhotoName = photoName
            -- XLog.Debug("fileFullPath", fileFullPath, "cfg.Text", cfg.Text, "platformType", platformType, "XPlatformShareConfigs.ShareType.Image", XPlatformShareConfigs.ShareType.Image, "XPhotographManager.ShareCallback", XPhotographManager.ShareCallback)
            XPlatformShareManager.Share(XPlatformShareConfigs.ShareType.Image, platformType, XPhotographManager.ShareCallback, fileFullPath, shareText, cfg.Param[1], cfg.Param[2], false)
            XNetwork.Send(PHOTOGRAPH_PROTO.ShareBackgroundRequest, {})
        end
    end

    function XPhotographManager.ShareCallback(result)
        -- XLog.Debug("ShareCallback result:", result)
        local tipFunc = XLuaUiManager.IsUiShow("UiPhotographPortrait") and XUiManager.TipPortraitText or XUiManager.TipText
        if result == XPlatformShareConfigs.ShareResult.Successful then
            tipFunc("PhotoModeShareSuccess")
            XEventManager.DispatchEvent(XEventId.EVENT_PHOTO_SHARE_SUCCESS, SharePhotoName)
        elseif result == XPlatformShareConfigs.ShareResult.Canceled then
            tipFunc("PhotoModeShareCancel")
        elseif result == XPlatformShareConfigs.ShareResult.Failed then
            tipFunc("PhotoModeShareFailed")
        end
        SharePhotoName = nil
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
            -- if curDisplayCharId ~= charId then
            --     XDataCenter.SignBoardManager.ChangeDisplayCharacter(charId)
            -- end
            -- XDataCenter.DisplayManager.SetDisplayCharByCharacterId(charId)
            -- XPlayer.SetDisplayCharId(charId)
            XPlayer.SetDisplayCharIdList(res.DisplayCharIdList)
            --下一次拿看板娘队列不要进行随机
            XDataCenter.DisplayManager.SetNextDisplayChar(charId)
            XEventManager.DispatchEvent(XEventId.EVENT_PHOTO_SYNC_CHANGE_TO_MAIN)
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
        --XPhotographManager.SortSceneIdList()
    end

    function XPhotographManager.GetCurSelectSceneId()
        return CurSelectSceneId
    end

    function XPhotographManager.SendPhotoGraphRequest()
        XNetwork.Send(PHOTOGRAPH_PROTO.PhotoBackgroundRequest, {})
    end
    
    -- 设置场景预览状态
    function XPhotographManager.SetDefaultPreviewState()
        PreviewState = XPhotographConfigs.BackGroundState.Full
    end

    -- 切换场景预览状态
    --@ fitterEvent: 是否仅修改状态的值而不进行事件广播
    function XPhotographManager.UpdatePreviewState(isFull,fitterEvent)
        if isFull then
            PreviewState = XPhotographConfigs.BackGroundState.Full
        else
            PreviewState = XPhotographConfigs.BackGroundState.Low
        end
        if not fitterEvent then
            XEventManager.DispatchEvent(XEventId.EVENT_SCENE_PREVIEW_STATE_CHANGE)
        end
    end

    -- 获取场景预览状态
    function XPhotographManager.GetPreviewState()
        return PreviewState
    end

    -- 设置场景预览的场景Id
    function XPhotographManager.SetPreviewSceneId(sceneId)
        PreviewSceneId = sceneId
    end

    -- 清空场景预览Id防止返回UiMain场景错误
    function XPhotographManager.ClearPreviewSceneId()
        PreviewSceneId = nil
    end
    
    -- 获取场景预览状态相关键名
    function XPhotographManager.GetSceneStateKey(sceneId)
        return tostring(XPlayer.Id)..'scene_'..tostring(sceneId)..'_use_state'
    end

    -- 打开指定场景的预览界面
    function XPhotographManager.OpenScenePreview(sceneId)
        if not sceneId or not XTool.IsNumberValid(sceneId) then return end

        XDataCenter.PhotographManager.SetPreviewSceneId(sceneId)
        XDataCenter.GuideManager.SetDisableGuide(true)
        XEventManager.DispatchEvent(XEventId.EVENT_SCENE_UIMAIN_RIGHTMIDTYPE_CHANGE, 1) --1即UiMain的Main状态
        XLuaUiManager.Open("UiMain")
        XLuaUiManager.Open("UiSceneMainPreview", sceneId,true)
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