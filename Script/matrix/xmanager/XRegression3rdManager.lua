
---@desc V2.0版本特殊回归系统管理器 第三版回归活动
---@return XRegression3rdManager 特殊回归系统管理器
XRegression3rdManagerCreator = function()

    --region   ------------------模块引入 start-------------------
    local XRegression3rd = require("XEntity/XRegression3rd/XRegression3rd")
    --endregion------------------模块引入 finish------------------

    local XRegression3rdManager = {}
    local XRegressionViewModel

    local Version = "Version200"

    local ActivityRedPoint = "ActivityRedPoint"
    local PassportRedPoint = "PassportRedPoint"
    local GiftShopRedPoint = "GiftShopRedPoint"
    local ShopRedPoint = "ShopRedPoint"
    local TaskRedPoint = "TaskRedPoint"
    local SignRedPoint = "SignRedPoint"

    local StoryKey = "StoryKey"
    local InvitationKey = "InvitationKey"

    --region   ------------------Cookies start-------------------
    local function GetCookiesKey(key)
        local activityId = 0
        if XRegressionViewModel then
            activityId = XRegressionViewModel:GetProperty("_Id")
        end
        return string.format("Regression3rd_%s_%s_%s_%s", XPlayer.Id, activityId, key, Version)
    end

    local function CheckTabActivityLocalRedPoint(key)
        return XSaveTool.GetData(GetCookiesKey(key))
    end

    local function MarkabActivityLocalRedPoint(key)
        XSaveTool.SaveData(GetCookiesKey(key), true)
    end

    function XRegression3rdManager.CheckOpenAutoWindow()
        if not XRegression3rdManager.IsOpen() then
            return false
        end
        local key = GetCookiesKey("AutoWindow")
        if XSaveTool.GetData(key) then
            return false
        end
        XSaveTool.SaveData(key, true)
        return true
    end

    function XRegression3rdManager.CheckActivityLocalRedPointData()
        return CheckTabActivityLocalRedPoint(ActivityRedPoint)
    end

    function XRegression3rdManager.CheckPassportLocalRedPointData()
        return CheckTabActivityLocalRedPoint(PassportRedPoint)
    end

    function XRegression3rdManager.CheckShopLocalRedPointData()
        return CheckTabActivityLocalRedPoint(ShopRedPoint)
    end

    function XRegression3rdManager.CheckTaskLocalRedPointData()
        return CheckTabActivityLocalRedPoint(TaskRedPoint)
    end

    function XRegression3rdManager.CheckSignLocalRedPointData()
        return CheckTabActivityLocalRedPoint(SignRedPoint)
    end

    function XRegression3rdManager.CheckGiftShopRedPointData()
        return CheckTabActivityLocalRedPoint(GiftShopRedPoint)
    end

    function XRegression3rdManager.MarkActivityLocalRedPointData()
        MarkabActivityLocalRedPoint(ActivityRedPoint)
    end

    function XRegression3rdManager.MarkPassportLocalRedPointData()
        MarkabActivityLocalRedPoint(PassportRedPoint)
    end

    function XRegression3rdManager.MarkShopLocalRedPointData()
        MarkabActivityLocalRedPoint(ShopRedPoint)
    end

    function XRegression3rdManager.MarkTaskLocalRedPointData()
        MarkabActivityLocalRedPoint(TaskRedPoint)
    end

    function XRegression3rdManager.MarkSignLocalRedPointData()
        MarkabActivityLocalRedPoint(SignRedPoint)
    end

    function XRegression3rdManager.MarkGiftShopRedPointData()
        MarkabActivityLocalRedPoint(GiftShopRedPoint)
    end

    --endregion------------------Cookies finish------------------

    function XRegression3rdManager.GetViewModel()
        return XRegressionViewModel
    end

    function XRegression3rdManager.IsOpen()
        if not XRegressionViewModel then
            return false
        end

        if not XRegressionViewModel:IsOpen() then
            return false
        end

        return true
    end

    --- 回归活动状态, 1 开放 0 关闭
    ---@param activityId number 活动Id,可选参数，不填则判断当期
    ---@return number
    --------------------------
    function XRegression3rdManager.ActivityState(activityId)
        if not XTool.IsNumberValid(activityId) then
            return XRegression3rdManager.IsOpen() and 1 or 0
        end

        if not XRegression3rdManager.IsOpen() then
            return 0
        end

        return XRegressionViewModel:GetProperty("_Id") == tonumber(activityId) and 1 or 0
    end

    --- Ui入口
    --------------------------
    function XRegression3rdManager.EnterUiMain()
        if not XRegression3rdManager.IsOpen() then
            return
        end
        --活动分包资源检测
        if not XMVCA.XSubPackage:CheckSubpackage() then
            return
        end
        local storyId = XRegressionViewModel:GetStoryId()
        local storyKey = GetCookiesKey(StoryKey .. tostring(storyId))
        local invitationKey = GetCookiesKey(InvitationKey)

        if not XSaveTool.GetData(storyKey) then
            XDataCenter.MovieManager.PlayMovie(storyId, function()
                local onClose = function()
                    XSaveTool.SaveData(invitationKey, true)
                    XLuaUiManager.Open("UiRegressionActivity")
                end
                XSaveTool.SaveData(storyKey, true)
                XLuaUiManager.Open("UiRegressionInvitation", onClose)
            end)
        elseif not XSaveTool.GetData(invitationKey) then
            local onClose = function()
                XSaveTool.SaveData(invitationKey, true)
                XLuaUiManager.Open("UiRegressionActivity")
            end
            XLuaUiManager.Open("UiRegressionInvitation", onClose)
        else
            XLuaUiManager.Open("UiRegressionActivity")
        end
    end

    --- 活动结束
    --------------------------
    function XRegression3rdManager.OnActivityEnd()
        if XRegression3rdManager.IsOpen() then
            return
        end
        
        local uiNameList = { "UiRegressionActivity", "UiRegressionInvitation", "UiRegressionGiftShop", "UiRegressionTips" }
        --处于玩法界面内
        for _, uiName in ipairs(uiNameList) do
            if XLuaUiManager.IsUiShow(uiName) then
                XLuaUiManager.RunMain()
                XUiManager.TipText("CommonActivityEnd")
                return
            end
        end
        --通过玩法跳转到其他界面
        for _, uiName in ipairs(uiNameList) do
            if XLuaUiManager.IsUiLoad(uiName) then
                XLuaUiManager.Remove(uiName)
            end
        end
    end

    --- 登录/活动状态改变 下发
    ---@param notifyData Server.XRegression3DataDb
    ---@return nil
    --------------------------
    function XRegression3rdManager.OnLoginNotify(notifyData)
        local data = notifyData.Data
        local activityData  = data.ActivityData
        local signData      = data.SignInData
        local passportData  = data.PassportData
        local activityId = activityData and activityData.Id or 0
        local surveyData = data.SurveyData

        if activityId > 0 then
            XRegressionViewModel = XRegressionViewModel or XRegression3rd.New(activityId)
            XRegressionViewModel:UpdateData(activityData)
            XRegressionViewModel:GetProperty("_SignViewModel"):UpdateData(signData)
            XRegressionViewModel:GetProperty("_PassportViewModel"):UpdateData(passportData)
            XRegressionViewModel:GetProperty("_SurveyViewModel"):UpdateData(surveyData)
        end

        XEventManager.DispatchEvent(XEventId.EVENT_REGRESSION3_ACTIVITY_STATUS_CHANGE)
    end

    function XRegression3rdManager.OnNotifySignData(signData)
        if not XRegression3rdManager.IsOpen() then
            return
        end

        local viewModel = XRegressionViewModel:GetProperty("_SignViewModel")
        viewModel:SetSignTimes(signData.SigninTimes)
        viewModel:ReceiveMultiSign(signData.Rewards)
    end

    function XRegression3rdManager.OnNotifyPassportData(data)
        if not XRegression3rdManager.IsOpen() then
            return
        end

        local baseInfo = data.BaseInfo
        if not baseInfo then
            return
        end

        local viewModel = XRegressionViewModel:GetProperty("_PassportViewModel")
        viewModel:SetProperty("_Level", baseInfo.Level)
        viewModel:SetAccumulated(baseInfo.Exp)
    end

    function XRegression3rdManager.OnNotifySurveyData(data)
        if not XRegression3rdManager.IsOpen() then
            return
        end

        local activeSurveyData = data.SurveyData
        if not activeSurveyData then
            return
        end
        ---@type XRegression3rdSurvey
        local viewModel = XRegressionViewModel:GetProperty("_SurveyViewModel")
        viewModel:AddSurveyData(activeSurveyData)
    end

    --- 通知通行证自动领取任务奖励列表
    ---@param data Server.NotifyRegression3PassportAutoGetTaskReward
    ---@return nil
    --------------------------
    function XRegression3rdManager.OnNotifyAutoReward(data)
        if not XRegression3rdManager.IsOpen() then
            return
        end
        local oldList = XRegressionViewModel:GetProperty("_AutoRewardList")
        if not XTool.IsTableEmpty(oldList) then
            oldList = appendArray(oldList, data.RewardList)
        else
            oldList = data.RewardList
        end
        XRegressionViewModel:SetProperty("_AutoRewardList", oldList)
    end

    --region   ------------------Request start-------------------

    --- 签到请求
    ---@param signId 签到Id
    ---@param cb 协议返回回调
    ---@return nil
    --------------------------
    function XRegression3rdManager.RequestSignIn(signId, cb)
        local signVideModel = XRegressionViewModel:GetProperty("_SignViewModel")
        if signVideModel:CheckIsReceive(signId) then
            XUiManager.TipMsg(XRegression3rdConfigs.GetClientConfigValue("RepeatSignTips", 1))
            return
        end
        XNetwork.Call("Regression3SignInGetRewardRequest", { SignInId = signId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            signVideModel:ReceiveSign(signId)
            XUiManager.OpenUiObtain(res.RewardGoods)

            XEventManager.DispatchEvent(XEventId.EVENT_REGRESSION3_SIGN_STATUS_CHANGE)

            if cb then cb() end
        end)
    end

    --- 购买战令
    ---@param passportTypeId 战令类型Id
    ---@param cb 协议返回回调
    ---@return nil
    --------------------------
    function XRegression3rdManager.RequestBuyPassport(passportTypeId, cb)
        local viewModel = XRegressionViewModel:GetProperty("_PassportViewModel")

        XNetwork.Call("Regression3PassportBuyPassportRequest", { Id = passportTypeId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            viewModel:BuyPassport(passportTypeId)
            viewModel:ReceiveAvailable( { res.PassportInfo } )
            local rewardList = res.RewardList
            if not XTool.IsTableEmpty(rewardList) then
                XUiManager.OpenUiObtain(rewardList)
            end

            --XUiManager.TipText("BuySuccess")

            XEventManager.DispatchEvent(XEventId.EVENT_REGRESSION3_PASSPORT_STATUS_CHANGE)

            if cb then cb() end
        end)
    end

    --- 领取单个战令奖励
    ---@param rewardId 奖励Id
    ---@param cb 协议返回回调
    ---@return nil
    --------------------------
    function XRegression3rdManager.RequestSinglePassportReward(rewardId, cb)
        local viewModel = XRegressionViewModel:GetProperty("_PassportViewModel")
        XNetwork.Call("Regression3PassportRecvRewardRequest", { Id = rewardId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local template = XRegression3rdConfigs.GetPassportRewardInfoById(rewardId)
            viewModel:ReceiveSingleReward(rewardId, template.PassportId)

            XUiManager.OpenUiObtain(res.RewardList)
            XEventManager.DispatchEvent(XEventId.EVENT_REGRESSION3_PASSPORT_STATUS_CHANGE)

            if cb then cb() end
        end)
    end

    --- 一键领取战令奖励
    ---@param cb 协议返回回调
    ---@return nil
    --------------------------
    function XRegression3rdManager.RequestAvailablePassportReward(cb)
        local viewModel = XRegressionViewModel:GetProperty("_PassportViewModel")
        if not viewModel:IsRewardsAvailable() then
            XUiManager.TipMsg(XRegression3rdConfigs.GetClientConfigValue("NoRewardAvailableTips", 1))
            return
        end

        XNetwork.Call("Regression3PassportRecvAllRewardRequest", nil, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            viewModel:ReceiveAvailable(res.PassportInfos)

            XUiManager.OpenUiObtain(res.RewardList)
            XEventManager.DispatchEvent(XEventId.EVENT_REGRESSION3_PASSPORT_STATUS_CHANGE)

            if cb then cb() end
        end)
    end
    --endregion------------------Request finish------------------

    --region   ------------------红点 start-------------------

    local function CheckRedPointBase()
        if not XRegression3rdManager.IsOpen() then
            return false
        end
        return true
    end

    function XRegression3rdManager.CheckMainRedPoint()
        if not CheckRedPointBase() then
            return false
        end

        if not XRegression3rdManager.CheckGiftShopRedPointData() then
            return true
        end

        return false
    end

    function XRegression3rdManager.CheckTaskRedPoint()
        if not CheckRedPointBase() then
            return false
        end

        if not XRegression3rdManager.CheckTaskLocalRedPointData() then
            return true
        end

        local taskViewModel = XRegressionViewModel:GetProperty("_TaskVideModel")
        local taskIds = taskViewModel:GetAchievedTaskList()
        return not XTool.IsTableEmpty(taskIds)
    end

    function XRegression3rdManager.CheckSignRedPoint()
        if not CheckRedPointBase() then
            return false
        end

        if not XRegression3rdManager.CheckSignLocalRedPointData() then
            return true
        end

        local signVideModel = XRegressionViewModel:GetProperty("_SignViewModel")
        return signVideModel:CheckHasReward()
    end

    function XRegression3rdManager.CheckPassportRedPoint()
        if not CheckRedPointBase() then
            return false
        end
        if not XRegression3rdManager.CheckPassportLocalRedPointData() then
            return true
        end
        local passportViewModel = XRegressionViewModel:GetProperty("_PassportViewModel")
        if passportViewModel:IsRewardsAvailable() then
            return true
        end
        return false
    end

    function XRegression3rdManager.CheckNewContentRedPoint()
        if not CheckRedPointBase() then
            return false
        end
        if XRegressionViewModel:IsEmptyNewContent() then
            return false
        end

        if not XRegression3rdManager.CheckActivityLocalRedPointData() then
            return true
        end

        return false
    end

    function XRegression3rdManager.CheckShopRedPoint()
        if not CheckRedPointBase() then
            return false
        end

        if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.ShopCommon) then
            return false
        end

        if not XRegression3rdManager.CheckShopLocalRedPointData() then
            return true
        end

        return false
    end

    function XRegression3rdManager.CheckSurveyRedPoint()
        if not CheckRedPointBase() then
            return false
        end
        
        ---@type XRegression3rdSurvey
        local surveyViewModel = XRegressionViewModel:GetProperty("_SurveyViewModel")

        if surveyViewModel:CheckHasAnySurvey() and not surveyViewModel:CheckHasFinished() then
            return XMVCA.XDailyReset:CheckDailyRedPoint(XRegression3rdManager.SurveyDailyRedPointKey())
        end

        return false
    end
    
    function XRegression3rdManager.SurveyDailyRedPointKey()
        return 'Regression3Survey'..XPlayer.Id
    end
    --endregion------------------红点 finish------------------
    
    return XRegression3rdManager
end

--region   ------------------RPC Notify start-------------------

--登录/活动状态改变 下发
XRpc.NotifyRegression3Data = function(notifyData)
    XDataCenter.Regression3rdManager.OnLoginNotify(notifyData)
end

--推送签到数据
XRpc.NotifyRegression3SignInData = function(signData)
    XDataCenter.Regression3rdManager.OnNotifySignData(signData)
end

--通知通行证自动领取任务奖励列表
XRpc.NotifyRegression3PassportAutoGetTaskReward = function(data)
    XDataCenter.Regression3rdManager.OnNotifyAutoReward(data)
end

--通知战令基础信息
XRpc.NotifyRegression3PassportBaseInfo = function(data)
    XDataCenter.Regression3rdManager.OnNotifyPassportData(data)
end

--推送问卷数据
XRpc.NotifyRegression3SurveyData = function(data)
    XDataCenter.Regression3rdManager.OnNotifySurveyData(data)
end
--endregion------------------RPC Notify finish------------------