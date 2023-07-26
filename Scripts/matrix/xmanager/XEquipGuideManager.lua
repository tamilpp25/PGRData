XEquipGuideManagerCreator = function()
    local XEquipGuide = require("XEntity/XEquipGuide/XEquipGuide")
    
    local XEquipGuideManager = {}
    local CurrentEquipGuide --当前装备目标
    local EquipGuideDict = {} --装备指引字典
    local IsSendingRequest = false
    
    local RequestFuncName = {
        EquipGuideSetTargetRequest    = "EquipGuideSetTargetRequest",    --装备目标设置请求
        EquipGuideTargetFinishRequest = "EquipGuideTargetFinishRequest", --装备目标完成确认请求
        EquipGuideAddOrClearPutOnPosRequest = "EquipGuideAddOrClearPutOnPosRequest",   --装备目标穿戴请求
    }
    
    local function ProgressChangeByCulture(equipId)
        XEquipGuideManager.RefreshProgress(equipId, XEquipGuideConfigs.ProgressChangeReason.Culture)
    end

    local function ProgressChangeByWear(equipId)
        XEquipGuideManager.RefreshProgress(equipId, XEquipGuideConfigs.ProgressChangeReason.Wear)
    end

    local function ProgressChangeByTakeOff(equipId)
        XEquipGuideManager.RefreshProgress(equipId, XEquipGuideConfigs.ProgressChangeReason.TakeOff)
    end
    
    local function Init() 
        local targetConfig = XEquipGuideConfigs.TargetConfig:GetConfigs()
        for _, config in ipairs(targetConfig) do
            local characterId = config.CharacterId
            if not EquipGuideDict[characterId] then
                EquipGuideDict[characterId] = XEquipGuide.New(characterId)
            end
            EquipGuideDict[characterId]:InsertTarget(config.Id)
        end
        XEventManager.AddEventListener(XEventId.EVENT_EQUIP_QUICK_STRENGTHEN_NOTYFY, ProgressChangeByCulture)
        XEventManager.AddEventListener(XEventId.EVENT_EQUIP_BREAKTHROUGH_NOTYFY, ProgressChangeByCulture)
        XEventManager.AddEventListener(XEventId.EVENT_EQUIP_STRENGTHEN_NOTYFY, ProgressChangeByCulture)
        XEventManager.AddEventListener(XEventId.EVENT_EQUIP_PUTON_NOTYFY, ProgressChangeByWear)
    end

    local function GetEquipGuide(characterId)
        local tmp = EquipGuideDict[characterId]
        if not tmp then
            XLog.Error("XEquipGuideManager GetEquipGuide: 未找到装备引导数据, CharacterId = "..characterId)
            return
        end
        return tmp
    end
    
    local function GetCookiesKey(key) 
        return string.format("XEquipGuideManager.GetCookiesKey_%s_%s", XPlayer.Id, key)
    end
    
    --==============================
     ---@desc 设定装备目标
     ---@targetId 设置的目标Id  
    --==============================
    local function SetEquipTarget(targetId, putOnPosList)
        if CurrentEquipGuide then
            CurrentEquipGuide:ClearTarget()
        end
        if not XTool.IsNumberValid(targetId) then
            CurrentEquipGuide = nil
            XEventManager.DispatchEvent(XEventId.EVENT_EQUIP_GUIDE_REFRESH_TARGET_STATE)
            return 
        end
        
        local characterId = XEquipGuideConfigs.TargetConfig:GetProperty(targetId, "CharacterId")
        CurrentEquipGuide = GetEquipGuide(characterId)
        CurrentEquipGuide:SetTarget(targetId, putOnPosList)
        XEventManager.DispatchEvent(XEventId.EVENT_EQUIP_GUIDE_REFRESH_TARGET_STATE)
    end

    --==============================
     ---@desc 更新数据
     ---@data EquipGuideData 
    --==============================
    local function UpdateEquipData(data)
        local targetId, finishIds = data.TargetId, data.FinishedTargets
        local putOnPosList = data.PutOnPosList
        SetEquipTarget(targetId, putOnPosList)
        
        for _, finishId in ipairs(finishIds) do
            local characterId = XEquipGuideConfigs.TargetConfig:GetProperty(finishId, "CharacterId")
            local guide = GetEquipGuide(characterId)
            guide:UpdateTarget(finishId, { _IsFinish = true })
        end
    end
    
    --==============================
     ---@desc 检测目标完成情况
    --==============================
    function XEquipGuideManager.RefreshProgress(equipId, reason)
        if not CurrentEquipGuide then
            return
        end
        local target = CurrentEquipGuide:GetProperty("_EquipTarget")
        if not target then
            return
        end
        local characterId = target:GetProperty("_CharacterId")
        local targetId = target:GetProperty("_Id")
        local beforeProgress = target:GetProperty("_Progress")
        target:UpdateProgress()
        local afterProgress = target:GetProperty("_Progress")
        local templateId
        if XTool.IsNumberValid(equipId) then
            local equip = XDataCenter.EquipManager.GetEquip(equipId)
            templateId = equip and equip.TemplateId or 0
        end
        local changeReason = {
            Id = templateId,
            Reason = reason
        }
        XEquipGuideManager.RecordProgressChangeEvent(characterId, targetId, beforeProgress, afterProgress, changeReason)
    end

    --==============================
     ---@desc 打开装备推荐界面
     ---@characterId 角色Id 
    --==============================
    function XEquipGuideManager.OpenEquipGuideView(characterId)
        local guide = GetEquipGuide(characterId)
        local equipGuideCharacter = XEquipGuideManager.IsEquipGuideCharacter(characterId)
        if equipGuideCharacter then
            XLuaUiManager.Open("UiEquipGuideDetail", guide:GetProperty("_EquipTarget"))
        else
            XLuaUiManager.Open("UiEquipGuideRecommend", guide)
        end
    end

    --==============================
    ---@desc 仅打开装备推荐
    ---@characterId 角色Id 
    ---@isHideSetTarget 隐藏设为目标按钮 
    --==============================
    function XEquipGuideManager.OpenEquipGuideRecommend(characterId, isHideSetTarget)
        local guide = GetEquipGuide(characterId)
        XLuaUiManager.Open("UiEquipGuideRecommend", guide, isHideSetTarget)
    end
    
    --==============================
     ---@desc 打开装备目标细节界面
    --==============================
    function XEquipGuideManager.OpenEquipGuideDetail()
        if not CurrentEquipGuide then
            XUiManager.TipText("EquipGuideNotSetTarget")
            return
        end
        XUiHelper.RecordBuriedSpotTypeLevelOne(XGlobalVar.BtnBuriedSpotTypeLevelOne.BtnUiMainBtnEquipGuide)
        XLuaUiManager.Open("UiEquipGuideDetail", CurrentEquipGuide:GetProperty("_EquipTarget"))
    end
    
    --==============================
     ---@desc 该成员是否设定了装备目标
     ---@characterId 角色Id 
     ---@return boolean
    --==============================
    function XEquipGuideManager.IsEquipGuideCharacter(characterId)
        if not CurrentEquipGuide then
            return false
        end
        return CurrentEquipGuide:GetProperty("_Id") == characterId
    end
    
    --==============================
     ---@desc 是否设置了装备目标
     ---@return boolean
    --==============================
    function XEquipGuideManager.IsSetEquipTarget()
        return CurrentEquipGuide and true or false
    end
    
    --==============================
     ---@desc 是否被设定目标
     ---@targetId 装备目标Id 
     ---@return boolean
    --==============================
    function XEquipGuideManager.IsCurrentEquipTarget(targetId)
        if not CurrentEquipGuide then
            return false
        end
        return CurrentEquipGuide and CurrentEquipGuide:IsEquipTarget(targetId) or false
    end
    
    --==============================
     ---@desc 装备推荐
     ---@characterId characterId 
     ---@return XEquipGuide
    --==============================
    function XEquipGuideManager.GetEquipGuide(characterId)
        return GetEquipGuide(characterId)
    end
    
    --==============================
     ---@desc 当前目标
     ---@return XEquipTarget
    --==============================
    function XEquipGuideManager.GetCurrentTarget()
        if not CurrentEquipGuide then
            return
        end
        local target = CurrentEquipGuide:GetProperty("_EquipTarget")
        return target
    end
    
    --==============================
     ---@desc 装备是否穿在指定角色身上
     ---@equipId 装备Id  
     ---@characterId 角色Id 
     ---@return boolean
    --==============================
    function XEquipGuideManager.CheckEquipIsWearingOnCharacter(equipId, characterId)
        if not XTool.IsNumberValid(equipId) then
            return false
        end
        local equip = XDataCenter.EquipManager.GetEquip(equipId)
        return equip and equip.CharacterId == characterId or false
    end
    
    --==============================
     ---@desc 穿戴/卸下 装备时，处理装备目标
     ---@equipId 装备Id 
     ---@templateId 装备配置id 
     ---@characterId 角色Id 
     ---@isPutOn 穿戴 or 卸下 
    --==============================
    function XEquipGuideManager.HandleEquipGuidePutOnOrTakeOff(equipIds, characterId, isPutOn)
        local isTargetCharacter = XEquipGuideManager.IsEquipGuideCharacter(characterId)
        if not isTargetCharacter then
            return
        end
        local target = XEquipGuideManager.GetCurrentTarget()
        local tmpEquipIds = {}
        for i, equipId in ipairs(equipIds or {}) do
            local equip = XDataCenter.EquipManager.GetEquip(equipId)
            if equip then
                local isEquipGuide = target and target:CheckIsTargetEquipByTemplateId(equip.TemplateId) or false
                if isEquipGuide then
                    table.insert(tmpEquipIds, equipId)
                end
            end
        end
        if XTool.IsTableEmpty(tmpEquipIds) then
            return
        end
        XEquipGuideManager.EquipGuideAddOrClearPutOnPosRequest(characterId, tmpEquipIds, isPutOn)
    end
    
    --region   ------------------运营埋点 start-------------------
    
    ---@desc 运营埋点--设定目标
    ---@param characterId 角色Id
    ---@param equipTargetId 装备目标Id
    ---@param progress 装备目标进度
    ---@param weaponState 武器状态
    ---@param chipsState 意识状态
    function XEquipGuideManager.RecordSetTargetEvent(characterId, equipTargetId, progress, weaponState, chipsState)
        local dict = {}
        dict["event_time"] = XTime.TimestampToLocalDateTimeString(XTime.GetServerNowTimestamp())
        dict["role_id"] = XPlayer.Id
        dict["role_level"] = XPlayer.GetLevel()
        dict["server_id"] = XServerManager.Id
        dict["event_id"] = XEquipGuideConfigs.BuryingPointEvent.SetTargetEvent
        dict["character_id"] = characterId
        dict["project"] = equipTargetId
        dict["progress"] = progress
        dict["weapon"] = weaponState
        dict["equip"] = chipsState
        
        CS.XRecord.Record(dict, "200008", "EquipGuide")
    end

    ---@desc 运营埋点--装备跳转
    ---@param characterId 角色Id
    ---@param equipTargetId 装备目标Id
    ---@param equipTemplateId 装备Id
    ---@param skipType 跳转类型
    ---@param skipScene 跳转场景
    function XEquipGuideManager.RecordSkipEvent(characterId, equipTargetId, equipTemplateId, skipType, skipScene)
        local dict = {}
        dict["event_time"] = XTime.TimestampToLocalDateTimeString(XTime.GetServerNowTimestamp())
        dict["role_id"] = XPlayer.Id
        dict["role_level"] = XPlayer.GetLevel()
        dict["server_id"] = XServerManager.Id
        dict["event_id"] = XEquipGuideConfigs.BuryingPointEvent.SkipEvent
        dict["character_id"] = characterId
        dict["project"] = equipTargetId
        dict["item_id"] = equipTemplateId
        dict["skip_type"] = skipType
        dict["skip_scene"] = skipScene

        CS.XRecord.Record(dict, "200008", "EquipGuide")
    end

    ---@desc 运营埋点--装备目标进度改变
    ---@param characterId 角色Id
    ---@param equipTargetId 装备目标Id
    ---@param beforeProgress 变化前的进度
    ---@param afterProgress 变化后的进度
    ---@param reason 变化原因
    function XEquipGuideManager.RecordProgressChangeEvent(characterId, equipTargetId, beforeProgress, afterProgress, reason)
        local before = math.floor(beforeProgress * 100000)
        local after = math.floor(afterProgress * 100000)
        if before == after then
            return
        end
        local dict = {}
        dict["event_time"] = XTime.TimestampToLocalDateTimeString(XTime.GetServerNowTimestamp())
        dict["role_id"] = XPlayer.Id
        dict["role_level"] = XPlayer.GetLevel()
        dict["server_id"] = XServerManager.Id
        dict["event_id"] = XEquipGuideConfigs.BuryingPointEvent.ProgressEvent
        dict["character_id"] = characterId
        dict["project"] = equipTargetId
        dict["before_progress"] = beforeProgress
        dict["progress"] = afterProgress - beforeProgress
        dict["after_progress"] = afterProgress
        dict["reason"] = reason

        CS.XRecord.Record(dict, "200008", "EquipGuide")
    end

    --endregion------------------运营埋点 finish------------------


    --region   ------------------红点检查 start-------------------
    
    --==============================
     ---@desc 当前目标有装备可以装备，传参则只检查一个
     ---@equipId 装备Id 
     ---@return boolean
    --==============================
    function XEquipGuideManager.CheckEquipCanEquip(templateId)
        if not CurrentEquipGuide then
            return false
        end
        local target = CurrentEquipGuide:GetProperty("_EquipTarget")
        return target:CheckEquipCanEquip(templateId)
    end
    
    --==============================
     ---@desc 检查目标武器升强，传参则只检查一个，否则检查当前模板下所有的目标
     ---@target XEquipTarget
     ---@return boolean
    --==============================
    function XEquipGuideManager.CheckHasStrongerWeapon(target)
        if not CurrentEquipGuide then
            return false
        end
        --local key = GetCookiesKey(CurrentEquipGuide:GetProperty("_Id") .. CurrentEquipGuide:GetWeaponCount())
        --if XSaveTool.GetData(key) then
        --    return false
        --end
        if not target then
            local targetList = CurrentEquipGuide:GetTargetList()
            for _, tar in ipairs(targetList or {}) do
                local state = tar:CheckHasStrongerWeapon()
                if state then
                    return true
                end
            end
            return false
        else
            local guide = XEquipGuideManager.GetEquipGuide(target:GetProperty("_CharacterId"))
            if not guide then
                return false
            end
            if guide:GetProperty("_Id") ~= CurrentEquipGuide:GetProperty("_Id") then
                return false
            end
            return target:CheckHasStrongerWeapon()
        end
    end

    --endregion------------------红点检查 finish------------------
    
    --region   ------------------Cookies start-------------------
    function XEquipGuideManager.MarkStrongerWeapon(isShow)
        if not CurrentEquipGuide then return end
        if not isShow then return end
        local key = GetCookiesKey(CurrentEquipGuide:GetProperty("_Id") .. CurrentEquipGuide:GetWeaponCount())
        XSaveTool.SaveData(key, true)
    end
    --endregion------------------Cookies finish------------------

    --region   ------------------网络协议 start-------------------
    --==============================
     ---@desc 登录下发
     ---@data EquipGuideData 
    --==============================
    function XEquipGuideManager.NotifyEquipGuideData(data)
        Init()
        UpdateEquipData(data)
    end

    --==============================
    ---@desc 装备目标设置请求
    ---@targetId 设置的目标Id 
    ---@cb 回调
    --==============================
    local function RequestSetTarget(targetId, putOnPosList, cb)
        XNetwork.Call(RequestFuncName.EquipGuideSetTargetRequest, { TargetId = targetId, PutOnPosList = putOnPosList }
        , function(res)
                    if res.Code ~= XCode.Success then
                        XUiManager.TipCode(res.Code)
                        return
                    end
                    local equipData = res.EquipGuideData
                    SetEquipTarget(targetId, equipData.PutOnPosList)

                    local tips
                    local validTargetId = XTool.IsNumberValid(targetId)
                    if validTargetId then
                        tips = XUiHelper.GetText("EquipGuideSetTarget")
                    else
                        tips = XUiHelper.GetText("EquipGuideCancelTarget")
                    end
                    XDataCenter.EquipManager.TipEquipOperation(nil, tips)
                    
                    if cb then cb() end
                end)
    end
    
    --==============================
     ---@desc 装备目标设置请求
     ---@targetId 设置的目标Id 
     ---@cb 回调
    --==============================
    function XEquipGuideManager.EquipGuideSetTargetRequest(targetId, putOnPosList, cb)
        local validTargetId = XTool.IsNumberValid(targetId)
        --更换目标
        if validTargetId and CurrentEquipGuide and not CurrentEquipGuide:IsEquipTarget(targetId) then
            local oldTargetId = CurrentEquipGuide:GetProperty("_EquipTarget"):GetProperty("_Id")
            local oldCharacterId = XEquipGuideConfigs.TargetConfig:GetProperty(oldTargetId, "CharacterId")
            local characterId = XEquipGuideConfigs.TargetConfig:GetProperty(targetId, "CharacterId")
            local content
            --相同角色切换
            if oldCharacterId == characterId then
                --content = XUiHelper.GetText("EquipGuideChangeTargetIdenticalRoleTips", XEquipGuideConfigs.TargetConfig:GetProperty(oldTargetId, "Description"),
                --        XEquipGuideConfigs.TargetConfig:GetProperty(targetId, "Description"))
                RequestSetTarget(targetId, putOnPosList, cb)
            else--不同角色切换
                content = XUiHelper.GetText("EquipGuideChangeTargetInequalityRoleTips", XCharacterConfigs.GetCharacterLogName(oldCharacterId),
                        XCharacterConfigs.GetCharacterLogName(characterId))
                XUiManager.DialogTip(XUiHelper.GetText("TipTitle"), content, nil, nil, function()
                    RequestSetTarget(targetId, putOnPosList, cb)
                end)
            end
            
        else --设定目标
            RequestSetTarget(targetId, putOnPosList, cb)
        end
        
        
        
    end
    
    --==============================
     ---@desc 装备目标完成确认请求
     ---@characterId 角色Id 
     ---@cb 协议响应回调 
    --==============================
    function XEquipGuideManager.EquipGuideTargetFinishRequest(characterId, cb)
        if IsSendingRequest then return end

        IsSendingRequest = true
        XNetwork.Call(RequestFuncName.EquipGuideTargetFinishRequest, { CharacterId = characterId }
        , function(res)
                    IsSendingRequest = false
                    if (res.Code ~= XCode.Success) then
                        XUiManager.TipCode(res.Code)
                        return
                    end
                    UpdateEquipData(res.EquipGuideData)
                    if cb then cb() end
                end)
    end
    
    function XEquipGuideManager.EquipGuideAddOrClearPutOnPosRequest(characterId, equipIds, isAdd)
        local sites = {}
        for i, equipId in ipairs(equipIds or {}) do
            local site = XDataCenter.EquipManager.GetEquipSite(equipId)
            sites[i] = site
        end 
        
        local req = { CharacterId = characterId, Sites = sites, EquipIds = equipIds, IsAdd = isAdd}
        
        XNetwork.Call(RequestFuncName.EquipGuideAddOrClearPutOnPosRequest, req, function(res)
            if (res.Code ~= XCode.Success) then
                XUiManager.TipCode(res.Code)
                return
            end
            
            --携带装备时，如果是模板装备，可能会存在 EquipGuideAddOrClearPutOnPosRequest 与 EquipGuideTargetFinishRequest 协议返回不一致情况
            --1. 正常逻辑：先 EquipGuideAddOrClearPutOnPosRequest 再 EquipGuideTargetFinishRequest
            --2. 因为延迟或者其他原因，导致 EquipGuideTargetFinishRequest 顺序大于 EquipGuideAddOrClearPutOnPosRequest，则不处理数据层
            if CurrentEquipGuide then
                local func = isAdd and ProgressChangeByWear or ProgressChangeByTakeOff
                for _, equipId in pairs(equipIds or {}) do
                    func(equipId)
                end
                
                UpdateEquipData(res.EquipGuideData)
            end
        end)
    end
    --endregion------------------网络协议 finish------------------

    return XEquipGuideManager
end

--region   ------------------RPC start-------------------
XRpc.NotifyEquipGuideData = function(data)
    XDataCenter.EquipGuideManager.NotifyEquipGuideData(data.EquipGuideData)
end
--endregion------------------RPC finish------------------