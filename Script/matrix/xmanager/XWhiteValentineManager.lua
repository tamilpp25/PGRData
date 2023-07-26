--2021年白情约会活动管理器
XWhiteValentineManagerCreator = function()
    --================
    --请求协议名称
    --================
    local REQUEST_NAMES = { --请求名称
        EnterActivity = "WhiteValentinesDayActivityEnterRequest", -- 购买商店物品
        Encounter = "WhiteValentinesDayActivityRandomMeetRequest", -- 刷新商店商品
        Invite = "WhiteValentinesDayActivityInviteRequest", -- 领取合成进度奖励
        Dispatch = "WhiteValentinesDayActivityDispatchRequest", -- 派遣角色
        FinishEvent = "WhiteValentinesDayActivityFinishEventRequest", -- 结束事件
        CancelDispatch = "WhiteValentinesDayActivityCancelDispatchRequest", -- 取消派遣
    }

    local WhiteValentineManager = {}
    local ScheduleId
    WhiteValentineManager.StoryType = {
        Encounter = 1, --偶遇
        Invite = 2, --邀请
    }

    WhiteValentineManager.StoryTypeName = {
        [1] = "Encounter", --偶遇
        [2] = "Invite", --邀请
    }
    --活动控制器对象
    local GameControl
    --=================
    --初始化
    --=================
    function WhiteValentineManager.Init()
        local XGame = require("XEntity/XMiniGame/WhiteValentine2021/XWhiteValentineGame")
        GameControl = XGame.New()
    end
    --=================
    --构建奖励列表(用于UiObtain显示奖励)
    --=================
    function WhiteValentineManager.CreateRewardList(contributionCount, coinCount)
        if not contributionCount or not coinCount then return nil end
        local rewardList = {}
        local contributionItem = { RewardType = 1, TemplateId = GameControl:GetContributionItemId(), Count = contributionCount}
        local coinItem = { RewardType = 1, TemplateId = GameControl:GetCoinItemId(), Count = coinCount}
        table.insert(rewardList, contributionItem)
        table.insert(rewardList, coinItem)
        return rewardList
    end
    --=================
    --播放角色通讯
    --=================
    function WhiteValentineManager.PlayCommu(roleDb, callBack)
        if not roleDb then return end
        local chara = GameControl:GetChara(roleDb.Id)
        if not chara then return end
        if not XPlayer.IsCommunicationMark(chara:GetCommuId()) then
            XDataCenter.CommunicationManager.ShowGameStoryCommunication(chara:GetCommuId(), callBack)
        end
    end
    --=================
    --进入活动时请求
    --@param callBack:回调
    --=================
    function WhiteValentineManager.OnEnterActivity(callBack)
        XNetwork.Call(REQUEST_NAMES.EnterActivity, {}, function(reply)
                if reply.Code ~= XCode.Success then
                    XUiManager.TipCode(reply.Code)
                    return
                end
                GameControl:RefreshData(reply.ActivityDb)
                WhiteValentineManager.ScheduleCanFinishEvent()
                XEventManager.DispatchEvent(XEventId.EVENT_WHITEVALENTINE_SHOW_PLACE)
                if callBack then callBack() end
            end)
    end
    --=================
    --发起偶遇角色请求
    --@param callBack:成功时回调
    --=================
    function WhiteValentineManager.EncounterChara(callBack)
        if not GameControl then return end
        if GameControl:CheckCanEncounter() then
            XNetwork.Call(REQUEST_NAMES.Encounter, {}, function(reply)
                    -- reply = {XCode Code //错误码, int RoleId //偶遇的角色Id}
                    if reply.Code ~= XCode.Success then
                        XUiManager.TipCode(reply.Code)
                        return
                    end
                    GameControl:AddNewChara(reply.RoleId)
                    if callBack then callBack() end
                    CsXGameEventManager.Instance:Notify(XEventId.EVENT_WHITEVALENTINE_ENCOUNTER_CHARA, GameControl:GetChara(reply.RoleId))
                end)
        end
    end
    --=================
    --发起邀请角色请求
    --@param chara:邀请角色对象
    --@param callBack:成功时回调
    --=================
    function WhiteValentineManager.InviteChara(chara, callBack)
        XNetwork.Call(REQUEST_NAMES.Invite, { RoleId = chara:GetCharaId() }, function(reply)
                -- reply = {XCode Code //错误码,
                --          int RoleId //邀请的角色Id}
                if reply.Code ~= XCode.Success then
                    XUiManager.TipCode(reply.Code)
                    return
                end
                GameControl:AddNewChara(reply.RoleId)
                GameControl:SetInviteChance(GameControl:GetInviteChance() - 1)
                if callBack then callBack() end
                CsXGameEventManager.Instance:Notify(XEventId.EVENT_WHITEVALENTINE_INVITE_CHARA, chara)
            end)
    end
    --=================
    --发起角色派遣请求
    --@param place:要派遣的地点对象
    --@param chara:要派遣的角色对象
    --@param callBack:成功时回调
    --=================
    function WhiteValentineManager.CharaDispatch(place, chara, callBack)
        if not GameControl:CheckCanDispatch(place) then return end
        XNetwork.Call(REQUEST_NAMES.Dispatch, { PlaceId = place:GetPlaceId(), RoleId = chara:GetCharaId() }, function(reply)
                -- reply = {XCode Code //错误码,
                --          XWhiteValentinesDayRoleDb RoleDb //派遣出去的角色Id
                --          XWhiteValentinesDayPlaceDb PlaceDb //事件Id
                --          int SubEnergy //扣除的体力
                --          int LastRefreshTimestamp //下次体力刷新时间}
                if reply.Code ~= XCode.Success then
                    XUiManager.TipCode(reply.Code)
                    return
                end
                GameControl:CharaDispatch(reply.PlaceDb, reply.RoleDb, reply.SubEnergy, reply.LastRefreshTimestamp)
                if callBack then callBack() end
                XEventManager.DispatchEvent(XEventId.EVENT_WHITEVALENTINE_REFRESH_PLACE, place:GetPlaceId())
            end)
    end
    --=================
    --取消角色派遣请求
    --@param place:要派遣的地点对象
    --@param chara:要派遣的角色对象
    --@param callBack:成功时回调
    --=================
    function WhiteValentineManager.CancelDispatch(place, callBack)
        if place:CheckCanFinishEvent() then
            XUiManager.TipMsg(CS.XTextManager.GetText("WhiteValentineAlreadyFinishEvent"))
            return
        end
        XNetwork.Call(REQUEST_NAMES.CancelDispatch, { PlaceId = place:GetPlaceId() }, function(reply)
                -- reply = {XCode Code //错误码,
                --          XWhiteValentinesDayRoleDb RoleDb //派遣出去的角色Id
                --          XWhiteValentinesDayPlaceDb PlaceDb //事件Id}
                if reply.Code ~= XCode.Success then
                    XUiManager.TipCode(reply.Code)
                    return
                end
                GameControl:RefreshChara(reply.RoleDb)
                GameControl:RefreshPlace(reply.PlaceDb)
                if callBack then callBack() end
                XEventManager.DispatchEvent(XEventId.EVENT_WHITEVALENTINE_REFRESH_PLACE, place:GetPlaceId())
            end)
    end
    --=================
    --发起完成事件请求
    --@param place:要完成事件的地点
    --@param callBack:成功时回调
    --=================
    function WhiteValentineManager.FinishEvent(place, callBack)
        if place:CheckCanFinishEvent() then
            XNetwork.Call(REQUEST_NAMES.FinishEvent, { PlaceId = place:GetPlaceId() }, function(reply)
                    -- reply = {XCode Code //错误码, XWhiteValentinesDayRoleDb UpdateRoleDb //刷新的角色数据
                    --          XWhiteValentinesDayPlaceDb UpdatePlaceDb //刷新的地点数据
                    --          List<XWhiteValentinesDayPlaceDb> NewPlaceDb //新增的地点数据
                    --          int AddContribution //奖励的贡献值
                    --          int AddCoin //奖励的金币}
                    if reply.Code ~= XCode.Success then
                        XUiManager.TipCode(reply.Code)
                        return
                    end
                    GameControl:RefreshChara(reply.UpdateRoleDb)
                    GameControl:RefreshPlace(reply.UpdatePlaceDb)
                    GameControl:RefreshPlaceRange(reply.NewPlaceDb)
                    if callBack then callBack() end
                    CsXGameEventManager.Instance:Notify(XEventId.EVENT_WHITEVALENTINE_REFRESH_PLACE, reply.UpdatePlaceDb.Id)

                    local rewardList = WhiteValentineManager.CreateRewardList(reply.AddContribution, reply.AddCoin)
                    if rewardList then XUiManager.OpenUiObtain
                        (rewardList, nil,
                            function()
                                if reply.UpdateRoleDb.FinishEventCount >= 1 then
                                    WhiteValentineManager.PlayCommu(reply.UpdateRoleDb, function() CsXGameEventManager.Instance:Notify(XEventId.EVENT_WHITEVALENTINE_OPEN_PLACE, reply.NewPlaceDb) end)
                                else
                                    CsXGameEventManager.Instance:Notify(XEventId.EVENT_WHITEVALENTINE_OPEN_PLACE, reply.NewPlaceDb)
                                end
                            end)
                    end
                end)
        else
            XUiManager.TipMsg(CS.XTextManager.GetText("WhiteValentineEventNotFinish"))
            return
        end
    end
    --=================
    --游戏登陆时刷新活动数据
    --=================    
    function WhiteValentineManager.RefreshData(data)
        GameControl:RefreshData(data.ActivityDb)
        WhiteValentineManager.ScheduleCanFinishEvent()
    end
    
    function WhiteValentineManager.ScheduleCanFinishEvent()
        if ScheduleId then return end
        GameControl:CheckCanFinishEvent()
        XEventManager.DispatchEvent(XEventId.EVENT_FINGER_GUESS_CHECK_EVENT_FINISH)
        ScheduleId = XScheduleManager.ScheduleForever(function()
                if ScheduleId and not WhiteValentineManager.CheckCanGoTo() then
                    XScheduleManager.UnSchedule(ScheduleId)
                end
                GameControl:CheckCanFinishEvent()
                XEventManager.DispatchEvent(XEventId.EVENT_FINGER_GUESS_CHECK_EVENT_FINISH)
                XEventManager.DispatchEvent(XEventId.EVENT_ACTIVITY_INFO_UPDATE, XActivityConfigs.ActivityType.Skip)
            end,
            5000
        )
    end
    --=================
    --获取活动控制器
    --=================
    function WhiteValentineManager.GetGameController()
        return GameControl
    end
    --=================
    --获取地点管理器
    --=================
    function WhiteValentineManager.GetPlaceManager()
        return GameControl:GetPlaceManager()
    end
    --=================
    --获取角色管理器
    --=================
    function WhiteValentineManager.GetCharaManager()
        return GameControl:GetCharaManager()
    end
    --=================
    --获取是否有完成事件未领取奖励
    --=================
    function WhiteValentineManager.GetCanFinishEvent()
        return GameControl:GetCanFinishEvent()
    end
    --================
    --跳转到活动主界面
    --================
    function WhiteValentineManager.JumpTo()
        local canGoTo, notStart = WhiteValentineManager.CheckCanGoTo()
        if notStart then
            XUiManager.TipMsg(CS.XTextManager.GetText("CommonActivityNotStart"))
        elseif XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.WhiteValentineDay) and
            canGoTo then
            XLuaUiManager.Open("UiWhitedayMain")
        else
            XUiManager.TipMsg(CS.XTextManager.GetText("CommonActivityEnd"))
        end
    end
    --================
    --检查是否能进入玩法
    --@return param1:是否在活动时间内(true为在活动时间内)
    --@return param2:是否未开始活动(true为未开始活动)
    --================
    function WhiteValentineManager.CheckCanGoTo()
        local endTime = GameControl:GetActivityEndTime()
        local startTime = GameControl:GetActivityStartTime()
        local nowTime = XTime.GetServerNowTimestamp()
        local isActivityEnd = (nowTime >= endTime) and (nowTime > startTime)
        local notStart = nowTime < startTime
        return not isActivityEnd, notStart
    end

    WhiteValentineManager.Init()
    return WhiteValentineManager
end

XRpc.NotifyWhiteValentinesDayActivity = function(data)
    XDataCenter.WhiteValentineManager.RefreshData(data)
end