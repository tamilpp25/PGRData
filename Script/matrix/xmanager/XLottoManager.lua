---@class XLottoUiData
---@field IsAfterFirstEnable boolean
---@field IsAfterDraw boolean

XLottoManagerCreator = function()
    local XLottoGroupEntity = require("XEntity/XLotto/XLottoGroupEntity")
    ---@class XLottoManager
    local XLottoManager = {}
    local GET_LOTTO_DATA_INTERVAL = 10
    local LastGetLottoRewardInfoTimes = 0
    ---@type XLottoGroupEntity[]
    local LottoGroupDataDic = {}

    local METHOD_NAME = {
        LottoInfoRequest = "LottoInfoRequest",
        LottoRequest = "LottoRequest",
        LottoBuyTicketRequest = "LottoBuyTicketRequest",
        LottoSelfChoiceSelectRequest = "LottoSelfChoiceSelectRequest",
    }
    
    local IsInterceptUiObtain = false
    local CacheReward = nil
    local RuleTagIndex = 1
    -- Share\Lotto\LottoPrimary.tab，服务端直接读取LottoPrimary的Id进行抽卡
    -- 服务端会给每个LottoPrimaryId记录一个SelectedLottoId，若在表格里每行配置只有一个LottoId，则SelectedLottoId默认选择这唯一一个LottoId
    -- 若每行配置有多个LottoId，则需要客户端选择一个LottoId，服务端会记录这个SelectedLottoId
    local LPrimaryIdLottoIdDic = {} -- [LottoPrimaryId] = LottoId --这个表记录的是有多个LottoId的LottoPrimaryId选中的LottoId
    local LottoIdLPrimaryIdDic = {} -- 和PrimaryLottoIdLottoDic是相反的，记录的是LottoId对应的LottoPrimaryId
    local CurSelfChoiceLottoPrimaryId = nil --当前自选活动中开启的LottoPrimaryId

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
    
    function XLottoManager.GetCurSelfChoiceLottoPrimaryId()
        return CurSelfChoiceLottoPrimaryId
    end

    function XLottoManager.GetCurSelectedLottoIdByPrimartLottoId(lottoPrimaryId)
        return LPrimaryIdLottoIdDic[lottoPrimaryId]
    end

    function XLottoManager.GetLottoPrimaryIdByLottoId(lottoId)
        local resLottoPrimaryId = LottoIdLPrimaryIdDic[lottoId]
        if XTool.IsNumberValid(resLottoPrimaryId) then
            return resLottoPrimaryId
        end

        for lottoPrimaryId, _lottoId in pairs(LPrimaryIdLottoIdDic) do
            if _lottoId == lottoId then
                LottoIdLPrimaryIdDic[lottoId] = lottoPrimaryId
                return lottoPrimaryId
            end
        end

        local allPrimaryLottoCfg = XLottoConfigs.GetAllConfigs(XLottoConfigs.TableKey.LottoPrimary)
        for lottoPrimaryId, v in pairs(allPrimaryLottoCfg) do
            if v.LottoIdList[1] == lottoId then
                LottoIdLPrimaryIdDic[lottoId] = lottoPrimaryId
                return lottoPrimaryId
            end
        end
    end

    --region Ui
    function XLottoManager.OpenLottoUi(groupId, param1)
        if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Lotto) then
            XLottoManager.GetLottoRewardInfoRequest(function()
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

    function XLottoManager.HandleDrawShowRewardQuality(rewardList, rareLevel)
        if XTool.IsTableEmpty(rewardList) or not XTool.IsNumberValid(rareLevel) then
            return rewardList
        end
        -- 处理奖励展示品质
        for _, reward in ipairs(rewardList) do
            reward.ShowQuality = XLottoConfigs.RareLevelToShowQuality[rareLevel]
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
    
    function XLottoManager.GetLottoGroupDataByGroupId(groupId)
        if not XTool.IsTableEmpty(LottoGroupDataDic) then
            return LottoGroupDataDic[groupId]
        end
    end

    function XLottoManager.UpdateLottoDrawData(lottoDrawId, data)
        local lottoCfg = XLottoConfigs.GetLottoCfgById(lottoDrawId)
        if lottoCfg then
            local lottoGroupEntity = LottoGroupDataDic[lottoCfg.LottoGroupId]:GetDrawData()
            local rewardList = lottoGroupEntity:GetLottoRewardList()
            table.insert(rewardList, data.LottoRewardId)
            local tmpData = {}
            tmpData.ExtraRewardState = data.ExtraRewardState
            tmpData.LottoRecords = data.LottoRecords
            tmpData.LottoRewards = rewardList
            lottoGroupEntity:UpdateData(tmpData)
        end
    end

    function XLottoManager.UpdateLottoGroupData(lottoInfoList)
        local tmpInfoList = {}
        LottoGroupDataDic = {}
        for _, lottoInfo in pairs(lottoInfoList or {}) do
            local lottoCfg = XTool.IsNumberValid(lottoInfo.Id) and XLottoConfigs.GetLottoCfgById(lottoInfo.Id)
            if lottoCfg then
                LottoGroupDataDic[lottoCfg.LottoGroupId] = LottoGroupDataDic[lottoCfg.LottoGroupId] or XLottoGroupEntity.New(lottoCfg.LottoGroupId)
                tmpInfoList[lottoCfg.LottoGroupId] = tmpInfoList[lottoCfg.LottoGroupId] or {}
                table.insert(tmpInfoList[lottoCfg.LottoGroupId], lottoInfo)
            end
            LottoIdLPrimaryIdDic[lottoInfo.Id] = lottoInfo.LottoPrimaryId
            LPrimaryIdLottoIdDic[lottoInfo.LottoPrimaryId] = lottoInfo.Id
        end

        for groupId, infoList in pairs(tmpInfoList or {}) do
            table.sort(infoList, function(a, b)
                return a.Priority < b.Priority
            end)
            LottoGroupDataDic[groupId]:UpdateData({ DrawInfoList = infoList })
        end
        
        XEventManager.DispatchEvent(XEventId.EVENT_LOTTO_UPDATE_GROUP_DATA)
    end

    function XLottoManager.GetLottoRewardInfoRequest(cb, notips)
        local now = XTime.GetServerNowTimestamp()
        if LastGetLottoRewardInfoTimes and now - LastGetLottoRewardInfoTimes <= GET_LOTTO_DATA_INTERVAL then
            if cb then cb() end
            return
        end
        XNetwork.Call(METHOD_NAME.LottoInfoRequest, {}, function(res)
            if res.Code ~= XCode.Success then
                if not notips then
                    XUiManager.TipCode(res.Code)
                end
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
        local lottoPrimaryId = XLottoManager.GetLottoPrimaryIdByLottoId(lottoId)
        XNetwork.Call(METHOD_NAME.LottoRequest, { Id = lottoPrimaryId }, function(res)
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
        local lottoPrimaryId = XLottoManager.GetLottoPrimaryIdByLottoId(lottoId)
        XNetwork.Call(METHOD_NAME.LottoBuyTicketRequest, { LottoPrimaryId = lottoPrimaryId, TicketId = BuyTicketRuleId, TicketKey = ticketKey }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            local reward = XRewardManager.CreateRewardGoodsByTemplate({ TemplateId = res.ItemId, Count = res.ItemCount })
            if cb then cb({ reward }) end
        end)
    end

    function XLottoManager.LottoSelfChoiceSelectRequest(lottoPrimaryId, lottoId, cb)
        XNetwork.Call(METHOD_NAME.LottoSelfChoiceSelectRequest, { LottoPrimaryId = lottoPrimaryId, SelectedLottoId = lottoId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            LPrimaryIdLottoIdDic[lottoPrimaryId] = lottoId
            LottoIdLPrimaryIdDic[lottoId] = lottoPrimaryId
            if cb then cb() end
        end)
    end

    function XLottoManager.NotifySelfChoiceLottoData(data)
        if not data.LottoPrimaryIds then return end
        for k, lottoPrimaryId in pairs(data.LottoPrimaryIds) do
            local lpCfg = XLottoConfigs.GetLottoPrimaryCfgById(lottoPrimaryId)
            if #lpCfg.LottoIdList > 1 then
                CurSelfChoiceLottoPrimaryId = lottoPrimaryId
                return
            end
        end
    end

    XLottoManager.Init()
    return XLottoManager
end

XRpc.NotifySelfChoiceLottoData = function(data)
    XDataCenter.LottoManager.NotifySelfChoiceLottoData(data)
end