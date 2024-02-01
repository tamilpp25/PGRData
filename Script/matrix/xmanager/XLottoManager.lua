---@class XLottoUiData
---@field IsAfterFirstEnable boolean
---@field IsAfterDraw boolean

XLottoManagerCreator = function()
    local XLottoGroupEntity = require("XEntity/XLotto/XLottoGroupEntity")
    ---@class XLottoManager
    local XLottoManager = {}
    local GET_LOTTO_DATA_INTERVAL = 10
    local LastGetLottoRewardInfoTimes = 0
    local LottoGroupDataDic = {}

    local METHOD_NAME = {
        LottoInfoRequest = "LottoInfoRequest",
        LottoRequest = "LottoRequest",
        LottoBuyTicketRequest = "LottoBuyTicketRequest",
    }
    
    local IsInterceptUiObtain = false
    local CacheReward = nil
    local RuleTagIndex = 1

    function XLottoManager.Init()
        RuleTagIndex = 1
    end
    
    --region RuleTagIndex
    function XLottoManager.SetRuleTagIndex(index)
        RuleTagIndex = index
    end

    function XLottoManager.GetRuleTagIndex()
        return RuleTagIndex
    end
    --endregion
    
    --region Ui
    function XLottoManager.OpenLottoUi(groupId, param1)
        if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Lotto) then
            XLottoManager.GetLottoRewardInfoRequest(function()
                ---@type XLottoGroupEntity
                local entity = LottoGroupDataDic[groupId]
                if not entity then
                    XUiManager.TipError(CS.XTextManager.GetText("ActivityBranchNotOpen"))
                    return
                end
                local UiName = XLottoConfigs.GetLottoOpenUiName(groupId)
                if string.IsNilOrEmpty(UiName) then
                    UiName = "UiLotto"
                end
                if XLuaUiManager.IsUiLoad(UiName) then
                    XLuaUiManager.Close(XLuaUiManager.GetTopUiName())
                else
                    XLuaUiManager.Open(UiName, entity, nil, entity:GetUiBackGround(), param1)
                end
            end)
        end
    end
    
    function XLottoManager.OnActivityEnd()
        XUiManager.TipText("LottoActivityOver")
        XLuaUiManager.RunMain()
    end

    --- 三头犬联动薇拉皮肤卡池接口
    ---@field ui XLuaUi
    function XLottoManager.OpenVeraLotto(ui)
        if XLuaUiManager.IsUiLoad("UiLottoVera") then
            ui:Close()
        else
            local skipId = XLottoConfigs.GetLottoClientConfigNumber("VeraLottoSkipId", 1)
            if XTool.IsNumberValid(skipId) then
                XFunctionManager.SkipInterface(skipId)
            else
                XLog.Error("[Error]Config 'VeraLottoSkipId' is null")
            end
        end
    end
    --endregion
    
    --region Ui - ShowData
    function XLottoManager.HandleDrawShowRewardEffect(rewardList, effectId)
        if XTool.IsTableEmpty(rewardList) or not XTool.IsNumberValid(effectId) then
            return rewardList
        end
        -- 处理奖励特殊特效
        for _, reward in ipairs(rewardList) do
            reward.SpecialDrawEffectGroupId = effectId
        end
        return rewardList
    end
    
    ---@return XLottoUiData
    function XLottoManager.CreateLottoUiData()
        ---@type XLottoUiData
        local uiData = {}
        uiData.IsAfterFirstEnable = false
        return uiData
    end
    --endregion
    
    --region Data
    function XLottoManager.GetTemplateQuality(templateId)
        local templateIdData = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(templateId)
        local Type = XTypeManager.GetTypeById(templateId)
        local quality
        if Type == XArrangeConfigs.Types.Wafer then
            quality = templateIdData.Star
        elseif Type == XArrangeConfigs.Types.Weapon then
            quality = templateIdData.Star
        elseif Type == XArrangeConfigs.Types.Character then
            quality = XMVCA.XCharacter:GetCharMinQuality(templateId)
        else
            quality = XTypeManager.GetQualityById(templateId)
        end
        return quality
    end
    --endregion
    
    --region LocalCacheData
    local _GetSkipCacheKey = function(lottoGroupId)
        return string.format("LottoSkipAnim_%s_%s", XPlayer.Id, lottoGroupId)
    end
    
    function XLottoManager.GetSkipAnim(lottoGroupId)
        return XSaveTool.GetData(_GetSkipCacheKey(lottoGroupId))
    end

    function XLottoManager.SetSkipAnim(lottoGroupId, value)
        XSaveTool.SaveData(_GetSkipCacheKey(lottoGroupId), value)
    end

    local _GetFirstCacheKey = function(lottoGroupId)
        return string.format("LottoFirstAnim_%s_%s", XPlayer.Id, lottoGroupId)
    end

    function XLottoManager.GetFirstAnim(lottoGroupId)
        return not XSaveTool.GetData(_GetFirstCacheKey(lottoGroupId))
    end

    function XLottoManager.SetFirstAnim(lottoGroupId, value)
        XSaveTool.SaveData(_GetFirstCacheKey(lottoGroupId), value)
    end
    --endregion

    function XLottoManager.GetIsInterceptUiObtain()
        return IsInterceptUiObtain
    end

    function XLottoManager.CacheWeaponFashionRewards(reward)
        CacheReward = reward
    end

    function XLottoManager.GetWeaponFashionCacheReward()
        return CacheReward
    end
    
    function XLottoManager.ClearWeaponFashionCacheReward()
        CacheReward = nil
    end

    function XLottoManager.GetLottoGroupDataList()
        local list = {}
        for _, groupData in pairs(LottoGroupDataDic or {}) do
            table.insert(list, groupData)
        end

        table.sort(list, function(a, b)
            return a:GetPriority() < b:GetPriority()
        end)

        return list
    end

    function XLottoManager.UpdateLottoGroupData(lottoDrawInfoList)
        local tmpInfoList = {}
        LottoGroupDataDic = {}
        for _, drawInfo in pairs(lottoDrawInfoList or {}) do
            local drawCfg = XLottoConfigs.GetLottoCfgById(drawInfo.Id)
            if drawCfg then
                LottoGroupDataDic[drawCfg.LottoGroupId] = LottoGroupDataDic[drawCfg.LottoGroupId] or XLottoGroupEntity.New(drawCfg.LottoGroupId)
                tmpInfoList[drawCfg.LottoGroupId] = tmpInfoList[drawCfg.LottoGroupId] or {}
                table.insert(tmpInfoList[drawCfg.LottoGroupId], drawInfo)
            end
        end

        for groupId, infoList in pairs(tmpInfoList or {}) do
            table.sort(infoList, function(a, b)
                return a.Priority < b.Priority
            end)
            LottoGroupDataDic[groupId]:UpdateData({ DrawInfoList = infoList })
        end
    end

    function XLottoManager.UpdateLottoDrawData(lottoDrawId, data)
        local drawCfg = XLottoConfigs.GetLottoCfgById(lottoDrawId)
        if drawCfg then
            local drawData = LottoGroupDataDic[drawCfg.LottoGroupId]:GetDrawData()
            local rewardList = drawData:GetLottoRewardList()
            table.insert(rewardList, data.LottoRewardId)
            local tmpData = {}
            tmpData.ExtraRewardState = data.ExtraRewardState
            tmpData.LottoRecords = data.LottoRecords
            tmpData.LottoRewards = rewardList
            drawData:UpdateData(tmpData)
        end
    end

    function XLottoManager.GetLottoRewardInfoRequest(cb)
        local now = XTime.GetServerNowTimestamp()
        if LastGetLottoRewardInfoTimes and now - LastGetLottoRewardInfoTimes <= GET_LOTTO_DATA_INTERVAL then
            if cb then cb() end
            return
        end
        XNetwork.Call(METHOD_NAME.LottoInfoRequest, {}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                if cb then cb() end
                return
            end
            XLottoManager.UpdateLottoGroupData(res.LottoInfos)
            LastGetLottoRewardInfoTimes = XTime.GetServerNowTimestamp()
            if cb then cb() end
        end)
    end

    function XLottoManager.SetIsInterceptUiObtain(value)
        IsInterceptUiObtain = value
    end
    
    function XLottoManager.DoLotto(lottoId, cb, errorCb)
        IsInterceptUiObtain = true
        XNetwork.Call(METHOD_NAME.LottoRequest, { Id = lottoId }, function(res)
            IsInterceptUiObtain = false
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                if errorCb then errorCb() end
                return
            end
            XLottoManager.UpdateLottoDrawData(lottoId, res)
            if cb then cb(res.RewardList, res.ExtraRewardList, res.LottoRewardId) end
        end)
    end

    function XLottoManager.BuyTicket(lottoId, BuyTicketRuleId, ticketKey, cb)
        XNetwork.Call(METHOD_NAME.LottoBuyTicketRequest, { LottoId = lottoId, TicketId = BuyTicketRuleId, TicketKey = ticketKey }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            local reward = XRewardManager.CreateRewardGoodsByTemplate({ TemplateId = res.ItemId, Count = res.ItemCount })
            if cb then cb({ reward }) end
        end)
    end

    XLottoManager.Init()
    return XLottoManager
end
