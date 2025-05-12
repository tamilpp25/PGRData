local CSTextManagerGetText = CS.XTextManager.GetText
local tableInsert = table.insert
local tableSort = table.sort

local XPhotographSet = require("XEntity/XPhotograph/XPhotographSet")

local DefaultSceneId = 14000001 --默认初始场景

XPhotographManagerCreator = function()
    ---@class XPhotographManager
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
    local IsRandomBackground = false -- 是否开启背景随机(开启才可以进入设置面板)
    local IsBackgroundRandomFashion = false -- 是否开启背景涂装随机
    local RandomBackgroundPool = {} -- 随机背景池
    local CharRandomBackgroundFashionDic = {} -- 记录角色随机背景涂装字典
    local LastRandomBackgroundId = nil
    local LastRandomSceneTimeStamp = nil
    local DirPath = "" -- 准备分享的照片保存路径
    local PhotographSetKey = string.format("PhotographSetKey_%s_Setting", XPlayer.Id)
    local PhotographSetData
    local NewBackGroundTempData = {} -- 新获得的背景数据，展示蓝点用，重登就清除

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

        NewBackGroundTempData = {}
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
        local channelId = '' -- 默认值
        if XUserManager.IsUseSdk() then
            if XUserManager.Platform == XUserManager.PLATFORM.IOS then
                channelId = 'A1348'
            else
                channelId = CS.XHeroSdkAgent.GetPkgId()
            end
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

    function XPhotographManager.InitRandomBackgroundLoginData(data)
        if not data then
            return
        end
        IsRandomBackground = data.IsRandomBackground
        IsBackgroundRandomFashion = data.IsBackgroundRandomFashion
        RandomBackgroundPool = data.RandomBackgroundPool
    end

    function XPhotographManager.GetIsRandomBackground()
        return IsRandomBackground
    end

    function XPhotographManager.GetIsBackgroundRandomFashion()
        if XTool.IsNumberValid(PreviewSceneId) then -- 预览模式开启 关闭随机场景模式
            return false
        end

        if not IsRandomBackground then
            return false
        end

        return IsBackgroundRandomFashion
    end

    function XPhotographManager.GetRandomBackgroundPool()
        return RandomBackgroundPool
    end

    -- 根据场景id返回当前场景的随机背景数据
    function XPhotographManager.GetRandomBackgroundDataInRandomPoolById(id)
        for k, backgroundData in pairs(RandomBackgroundPool) do
            if backgroundData.BackgroundId == id then
                return backgroundData
            end
        end
    end

    -- 进行一次场景随机
    function XPhotographManager.GetNextRandomSceneId()
        if XTool.IsTableEmpty(RandomBackgroundPool) then
            return
        end

        local cd = CS.XGame.ClientConfig:GetInt("RandomBackgroundCD")
        if LastRandomSceneTimeStamp and XTime.GetServerNowTimestamp() - LastRandomSceneTimeStamp < cd then
            return LastRandomBackgroundId
        end
        
        -- 获取表中的所有值
        local values = {}
        for _, backgroundData in pairs(RandomBackgroundPool) do
            if backgroundData.BackgroundId ~= LastRandomBackgroundId or #RandomBackgroundPool == 1 then
                table.insert(values, backgroundData.BackgroundId)
            end
        end

        -- 计算表中的元素数量
        local numValues = #values

        -- 生成一个随机索引
        local randomIndex = math.random(1, numValues)

        -- 返回随机索引对应的值
        LastRandomBackgroundId = values[randomIndex]
        LastRandomSceneTimeStamp = XTime.GetServerNowTimestamp()
        return LastRandomBackgroundId
    end
    
    -- 获取当前随机场景下的随机助理列表
    function XPhotographManager.GetRandomCharIdListByRandomBackgroundId()
        local curSceneId = XPhotographManager.GetCurSceneId()
        local randomBackgroundData = XPhotographManager.GetRandomBackgroundDataInRandomPoolById(curSceneId)
        local charList = randomBackgroundData.RandomChars
        local charIdList = {}
        for k, v in pairs(charList) do
            if v.IsRandom then
                table.insert(charIdList, v.CharId)
            end
        end

        return charIdList
    end

    -- 获取当前随机助理的随机时装列表
    function XPhotographManager.GetRandomFashionIdListByRandomCharId(charId)
        local curSceneId = XPhotographManager.GetCurSceneId()
        local randomBackgroundData = XPhotographManager.GetRandomBackgroundDataInRandomPoolById(curSceneId)
        local charList = randomBackgroundData.RandomChars
        for k, v in pairs(charList) do
            if v.CharId == charId then
                if not v.IsRandom then
                    local backgroundName = XPhotographManager.GetSceneTemplateById(randomBackgroundData.BackgroundId).Name
                    XLog.Error("XPhotographManager.GetRandomFashionIdListByRandomCharId 查找的助理并未编入场景随机队列 backgroundData = ",charId, backgroundName, randomBackgroundData)
                end

                return v.RandomFashions
            end
        end

        return nil
    end

    -- 判断当前角色是否是当前随机场景下的随机助理
    function XPhotographManager.CheckIsCharInCurRandomBackground(charId)
        local curSceneId = XPhotographManager.GetCurSceneId()
        local randomBackgroundData = XPhotographManager.GetRandomBackgroundDataInRandomPoolById(curSceneId)
        local charList = randomBackgroundData.RandomChars
        for k, v in pairs(charList) do
            if v.CharId == charId then
                return true
            end
        end

        return false
    end

    -- 进行一次随机 随机助理的下一套随机时装
    function XPhotographManager.GetNextRandomCharFashionId(charId)
        local lastFashionId = CharRandomBackgroundFashionDic[charId]
        local curSceneId = XPhotographManager.GetCurSceneId()
        local randomBackgroundData = XPhotographManager.GetRandomBackgroundDataInRandomPoolById(curSceneId)
        local charList = randomBackgroundData.RandomChars
        for k, v in pairs(charList) do
            if v.CharId == charId then
                local fashionList = v.RandomFashions
                local resId = nil
                if #fashionList == 1 then
                    resId =  fashionList[1]
                else
                    fashionList = XTool.Clone(fashionList)
                    local _, index = table.contains(fashionList, lastFashionId)
                    table.remove(fashionList, index)
                    local randomIndex = math.random(1, #fashionList)
                    local randomFashionId = fashionList[randomIndex]
                    resId = randomFashionId
                end
                CharRandomBackgroundFashionDic[charId] = resId
                return resId
            end
        end
    end

    -- 获取角色上一次随机的涂装
    function XPhotographManager.GetCharRandomBackgroundFashionDic(charId)
        return CharRandomBackgroundFashionDic[charId]
    end

    function XPhotographManager.HandlerPhotoLoginData(data)
        local haveSceneIds = data.HaveBackgroundIds
        if not haveSceneIds then
            return
        end
        HasSceneIdDic = {}
        for _, id in pairs(haveSceneIds) do
            HasSceneIdDic[id] = id
        end
        XPhotographManager.SortSceneIdList() -- 场景列表排序
        XPhotographManager.InitCharacterList() -- 网络数据下发时可以初始化一下角色数据列表 避免获取时再初始化
    end

    function XPhotographManager.GetIgnoreUiOnDraw()
        return {
            "UiEpicFashionGacha",
            "UiGachaLamiyaMain",
            "UiGachaAlphaMain",
            "UiGachaLuciaMain",
        }
    end

    function XPhotographManager.HandlerAddPhotoScene(data)
        HasSceneIdDic[data.BackgroundId] = data.BackgroundId
        XPhotographManager.SortSceneIdList()
        --获得新场景时打开提示窗 在抽卡时`
        local isOpenSceneSettingObtain = true
        for _, uiName in pairs(XPhotographManager.GetIgnoreUiOnDraw()) do
            if XLuaUiManager.IsUiShow(uiName) then
                isOpenSceneSettingObtain = false
                break
            end
        end
        if isOpenSceneSettingObtain then
            XLuaUiManager.Open("UiSceneSettingObtain", data)
        end
        --新获得场景需要刷新终端红点
        XPhotographManager.CheckAndSaveNewSceneTempData(data.BackgroundId)
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
                local name = XMVCA.XCharacter:GetCharacterName(characterId)
                local tradeName = XMVCA.XCharacter:GetCharacterTradeName(characterId)
                local logName = XMVCA.XCharacter:GetCharacterLogName(characterId)
                local enName = XMVCA.XCharacter:GetCharacterEnName(characterId)

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

    function XPhotographManager.GetOwnSceneCount()
        local count = XTool.GetTableCount(HasSceneIdDic)
        return count
    end

    function XPhotographManager.CheckSceneCanSkipById(id)
        local skipId = XDataCenter.PhotographManager.GetSceneSkipIdById(id)
        
        if XTool.IsNumberValid(skipId) then
            local config = XFunctionConfig.GetSkipFuncCfg(skipId)

            if config then
                return XFunctionManager.CheckInTimeByTimeId(config.TimeId, true)
            end
        end

        return false
    end

    function XPhotographManager.GetSceneSkipIdById(id)
        local template = XDataCenter.PhotographManager.GetSceneTemplateById(id)

        return template and template.SkipId or 0
    end

    -- 优先返回预览场景id
    -- 其次若开启场景随机返回场景随机id
    -- 最后返回当前服务端记录的场景id
    function XPhotographManager.GetCurSceneId()
        if not XMVCA.XSubPackage:CheckNecessaryComplete() then
            return DefaultSceneId
        end

        if PreviewSceneId then
            return PreviewSceneId
        end

        -- 由于随机场景是纯客户端展示的场景，而当开启随机场景时CurSecene同步的是服务端存储的数据
        if XPhotographManager.GetIsRandomBackground() then
            return LastRandomBackgroundId
        end

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

    --- 分享照片之前处理
    function XPhotographManager.SharePhotoBefore(photoName, texture, shareId, shareText)
        local channelId = CS.XHeroSdkAgent.GetChannelId()
        if XPhotographConfigs.NeedShowPermissionRequestDialogChannelId[channelId] and not XDataCenter.UiPcManager.IsPc() then
            if not XPermissionManager.CheckPermission(CS.XPermissionEnum.WRITE_EXTERNAL_STORAGE) then
                local title = XUiHelper.GetText("PermissionTitle")
                local content = XUiHelper.GetText("PermissionContent")
                local okText = XUiHelper.GetText("PermissionOkText")
                XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, function()
                    XPhotographManager.SharePhoto(photoName, texture, shareId, shareText)
                end, { sureText = okText })
                return
            end
        end
        XPhotographManager.SharePhoto(photoName, texture, shareId, shareText)
    end

    function XPhotographManager.SharePhoto(photoName, texture, shareId, shareText)
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
                    XPhotographManager.DoShare(photoName, shareId, shareText)
                end)
            else
                XPhotographManager.DoShare(photoName, shareId, shareText)
            end
        end)
    end
    local SharePhotoName
    function XPhotographManager.DoShare(photoName, shareId, shareText)
        local tipFunc = XLuaUiManager.IsUiShow("UiPhotographPortrait") and XUiManager.TipPortraitText or XUiManager.TipText
        if shareId == XPlatformShareConfigs.PlatformType.Local then -- 本地保存
            tipFunc("PhotoModeSaveSuccess")
        else
            local cfg = XPhotographConfigs.GetShareInfoByType(shareId)
            local fileFullPath = string.format("%s%s%s", DirPath, photoName, ".png")
            if shareText == nil then
                shareText = cfg.Text
            end
            SharePhotoName = photoName
            -- XLog.Debug("fileFullPath", fileFullPath, "cfg.Text", cfg.Text, "platformType", platformType, "XPlatformShareConfigs.ShareType.Image", XPlatformShareConfigs.ShareType.Image, "XPhotographManager.ShareCallback", XPhotographManager.ShareCallback)
            XPlatformShareManager.Share(XPlatformShareConfigs.ShareType.Image, shareId, XPhotographManager.ShareCallback, fileFullPath, shareText, cfg.Param[1], cfg.Param[2], false)
            XNetwork.Send(PHOTOGRAPH_PROTO.ShareBackgroundRequest, {})
        end
        XEventManager.DispatchEvent(XEventId.EVENT_PHOTO_SHARE)
    end

    function XPhotographManager.ShareCallback(result)
        -- XLog.Debug("ShareCallback result:", result)
        local tipFunc = XLuaUiManager.IsUiShow("UiPhotographPortrait") and XUiManager.TipPortraitText or XUiManager.TipText
        if result == "success" then
            tipFunc("PhotoModeShareSuccess")
            XEventManager.DispatchEvent(XEventId.EVENT_PHOTO_SHARE_SUCCESS, SharePhotoName)

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

        if not XMVCA.XCharacter:IsOwnCharacter(charId) then -- 角色未拥有
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

            if CurSceneId ~= sceneId then
                XEventManager.DispatchEvent(XEventId.EVENT_PHOTO_SYNC_CHANGE_BACKGROUND, sceneId)
            end

            CurSceneId = sceneId
            XPhotographManager.SortSceneIdList()

            -- local curDisplayCharId = XDataCenter.DisplayManager.GetDisplayChar().Id
            -- if curDisplayCharId ~= charId then
            --     XDataCenter.SignBoardManager.ChangeDisplayCharacter(charId)
            -- end
            -- XDataCenter.DisplayManager.SetDisplayCharByCharacterId(charId)
            -- XPlayer.SetDisplayCharId(charId)
            XPhotographManager.RemoveNewSceneTempData(sceneId)
            XPlayer.SetDisplayCharIdList(res.DisplayCharIdList)
            -- 同步按钮点击后 下一次随机要用当前同步的角色
            XDataCenter.DisplayManager.SetNextDisplayChar(charId)
            XEventManager.DispatchEvent(XEventId.EVENT_PHOTO_SYNC_CHANGE_TO_MAIN)
            if cb then
                cb()
            end
        end)
    end

    -- 随机场景相关协议 start
    -- 随机场景开启
    function XPhotographManager.SwitchRandomBackgroundRequest(isRandomBackground, CurRandomBackgroundId, cb)
        XNetwork.Call("SwitchRandomBackgroundRequest", { IsRandomBackground = isRandomBackground, CurRandomBackgroundId = CurRandomBackgroundId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            IsRandomBackground = isRandomBackground
            -- 账号初次切换自动添加
            if res.AddRandomBackground and not table.containsKey(RandomBackgroundPool, "BackgroundId", res.AddRandomBackground) then
                table.insert(RandomBackgroundPool, res.AddRandomBackground)
            end
            -- 随机场景关闭时 将最后随机到的场景id同步到当前场景id
            if not isRandomBackground then
                CurSceneId = LastRandomBackgroundId
            end

            XEventManager.DispatchEvent(XEventId.EVENT_PHOTO_SYNC_CHANGE_TO_MAIN)

            if cb then
                cb()
            end
        end)
    end

    -- 场景涂装随机开启
    function XPhotographManager.SwitchRandomFashionRequest(isBackgroundRandomFashion, cb)
        XNetwork.Call("SwitchRandomFashionRequest", { IsBackgroundRandomFashion = isBackgroundRandomFashion }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            IsBackgroundRandomFashion = isBackgroundRandomFashion

            if cb then
                cb()
            end
        end)
    end

    -- 保存按钮
    function XPhotographManager.EditRandomBackGroundFashionRequest(editRandomBackgroundData, cb)
        XNetwork.Call("EditRandomBackGroundFashionRequest", { EditRandomBackground = editRandomBackgroundData }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local _, index = table.containsKey(RandomBackgroundPool, "BackgroundId", editRandomBackgroundData.BackgroundId)
            RandomBackgroundPool[index] = editRandomBackgroundData
            XEventManager.DispatchEvent(XEventId.EVENT_PHOTO_SYNC_CHANGE_TO_MAIN)

            if cb then
                cb()
            end
        end)
    end

    function XPhotographManager.AddRandomBackgroundRequest(backgroundId, cb)
        if #RandomBackgroundPool >= CS.XGame.Config:GetInt("RandomBackgroundCountLimit") then
            XUiManager.TipMsg(CS.XTextManager.GetText("UiSceneRandomOverLimit"))
            return
        end

        XNetwork.Call("AddRandomBackgroundRequest", { BackgroundId = backgroundId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            -- 手动添加
            if not table.containsKey(RandomBackgroundPool, "BackgroundId", backgroundId) then
                table.insert(RandomBackgroundPool, res.AddRandomBackground)
            end
            XEventManager.DispatchEvent(XEventId.EVENT_PHOTO_SYNC_CHANGE_TO_MAIN)

            if cb then
                cb()
            end
        end)
    end

    function XPhotographManager.RemoveRandomBackgroundRequest(backgroundId, cb)
        if #RandomBackgroundPool == 1 then
            XUiManager.TipMsg(CS.XTextManager.GetText("RandomBackgroundPoolCannotEmpty"))
            return
        end

        XNetwork.Call("RemoveRandomBackgroundRequest", { BackgroundId = backgroundId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            -- 手动移除
            local isIn, index = table.containsKey(RandomBackgroundPool, "BackgroundId", backgroundId)
            if isIn then
                table.remove(RandomBackgroundPool, index)
            end

            -- 移除的是当前使用中的随机场景时 再进行一次随机
            if backgroundId == LastRandomBackgroundId then
                XPhotographManager.GetNextRandomSceneId()
            end

            XEventManager.DispatchEvent(XEventId.EVENT_PHOTO_SYNC_CHANGE_TO_MAIN)

            if cb then
                cb()
            end
        end)
    end

    -- 移除助理对随机涂装的变更,不管随机场景功能是否开启都推送,否则开启随机涂装时需要获取全量数据.
    -- 移除助理导致场景涂装队列为空时,将首席助理当前穿戴的战斗涂装勾选加入此场景.
    function XPhotographManager.NotifyRandomCharUpdate(data)
        if data.RemoveRandomChars then
            for backgroundId, charId in pairs(data.RemoveRandomChars) do
                local curBackgroundData = XPhotographManager.GetRandomBackgroundDataInRandomPoolById(backgroundId)
                local isIn, index = table.containsKey(curBackgroundData.RandomChars, "CharId", charId)
                table.remove(curBackgroundData.RandomChars, index)
            end
        end

        if data.AddRandomChars then
            for backgroundId, randomCharData in pairs(data.AddRandomChars) do
                local curBackgroundData = XPhotographManager.GetRandomBackgroundDataInRandomPoolById(backgroundId)
                table.insert(curBackgroundData.RandomChars, randomCharData)
            end
        end

        XEventManager.DispatchEvent(XEventId.EVENT_PHOTO_SYNC_CHANGE_TO_MAIN)
    end
    -- 随机场景相关协议 end

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
        return tostring(XPlayer.Id)..'scene_'..tostring(sceneId)..'_has_check'
    end

    -- 本地缓存是否点击过该场景(旧蓝点展示逻辑，无本地缓存数据则显示蓝点)
    function XPhotographManager.CheckAndSaveNewSceneSaveToolData(sceneId)
        local checkData = XSaveTool.GetData(XPhotographManager.GetSceneStateKey(sceneId))
        if not checkData and XPhotographManager.CheckSceneIsHaveById(sceneId) then
            XSaveTool.SaveData(XPhotographManager.GetSceneStateKey(sceneId), true)
        end
    end

    -- 临时缓存是否点击过该场景(现用蓝点展示逻辑，有数据则显示蓝点)
    function XPhotographManager.CheckAndSaveNewSceneTempData(sceneId)
        if not XPhotographManager.CheckSceneIsHaveById(sceneId) then
            return
        end
        NewBackGroundTempData[sceneId] = true
    end

    function XPhotographManager.CheckSceneIsNewInTempData(sceneId)
        return NewBackGroundTempData[sceneId] == true
    end

    function XPhotographManager.RemoveNewSceneTempData(sceneId)
        NewBackGroundTempData[sceneId] = nil
    end

    -- 打开指定场景的预览界面
    function XPhotographManager.OpenScenePreview(sceneId, customUiName, customOpenType, ...)
        if not sceneId or not XTool.IsNumberValid(sceneId) then return end

        if not XMVCA.XSubPackage:CheckSubpackage() then
            return
        end

        XDataCenter.PhotographManager.SetPreviewSceneId(sceneId)
        XDataCenter.GuideManager.SetDisableGuide(true)
        XEventManager.DispatchEvent(XEventId.EVENT_SCENE_UIMAIN_RIGHTMIDTYPE_CHANGE, 1) --1即UiMain的Main状态
        XLuaUiManager.Open("UiMain")
        
        local uiName = not string.IsNilOrEmpty(customUiName) and customUiName or "UiSceneMainPreview"
        local openType = XTool.IsNumberValid(customOpenType) and customOpenType or XPhotographConfigs.PreviewOpenType.SceneSetting
        XLuaUiManager.Open(uiName, sceneId, openType, ...)
    end
    
    function XPhotographManager.OpenUiSceneSetting(...)
        if not XMVCA.XSubPackage:CheckSubpackage() then
            return
        end
        XLuaUiManager.Open("UiSceneSettingMain", ...)
    end

    XPhotographManager.Init()
    return XPhotographManager
end

-- XRpc.NotifyBackgroundLoginData = function(data)
--     -- XDataCenter.PhotographManager.HandlerPhotoLoginData(data)
-- end

XRpc.NotifyRandomCharUpdate = function(data)
    XDataCenter.PhotographManager.NotifyRandomCharUpdate(data)
end

XRpc.NotifyAddBackground = function(data)
    XDataCenter.PhotographManager.HandlerAddPhotoScene(data)
end

XRpc.NotifySharePlatformConfigList = function (data)
    XDataCenter.PhotographManager.InitSharePlatform(data.SharePlatformConfigList)
end