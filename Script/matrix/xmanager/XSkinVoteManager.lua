XSkinVoteManagerCreator = function() 
    
    --region   ------------------require start-------------------
    local XSkinVote = require("XEntity/XSkinVote/XSkinVote")
    --endregion------------------require finish------------------
    
    local XSkinVoteManager = {}
    ---@type XSkinVote
    local XSkinVoteViewModel
    local RequestSkinVoteDataTimeStamp = 0
    local RequestSkinVoteDataInterval = 5 * 60
    
    local ViewPublicResultKey =  "ViewPublicResultKey"

    local function GetCookiesKey(key) 
        local activityId = 0
        if XSkinVoteManager.IsOpen() then
            activityId = XSkinVoteViewModel:GetProperty("_Id")
        end
        return string.format("XSkinVoteManager_%s_%s_%s", XPlayer.Id, activityId, key)
    end
    
    function XSkinVoteManager.OnLoginNotify(notifyData)
        local skinVoteData = notifyData.SkinVoteDataDb
        local activityId = skinVoteData.ActivityId
       
        if XTool.IsNumberValid(activityId) then
            XSkinVoteViewModel = XSkinVote.New(activityId)
            local voteId = skinVoteData.VoteId
            XSkinVoteViewModel:SetProperty("_VoteNameId", voteId)
        else
            XSkinVoteManager.OnActivityEnd()
        end
    end
    
    function XSkinVoteManager.IsOpen()
        if not XSkinVoteViewModel then
            return false
        end
        
        return XSkinVoteViewModel:IsOpen()
    end
    
    function XSkinVoteManager.EnterMainUi()
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.SkinVote) then
            return
        end
        
        if not XSkinVoteManager.IsOpen() then
            XUiManager.TipText("CommonActivityNotStart")
            return
        end

        XLuaUiManager.Open("UiSkinVoteMain")
    end
    
    function XSkinVoteManager.GetViewModel()
        return XSkinVoteViewModel
    end
    
    function XSkinVoteManager.OnActivityEnd()
        if XSkinVoteManager.IsOpen() then
            return
        end

        local checkUiName = { "UiSkinVoteMain", "UiSkinVoteSee" }
        for _, uiName in ipairs(checkUiName) do
            if XLuaUiManager.IsUiShow(uiName) then
                XLuaUiManager.RunMain()
                XUiManager.TipText("CommonActivityEnd")
                return
            end
        end

        for _, uiName in ipairs(checkUiName) do
            if XLuaUiManager.IsUiLoad(uiName) then
                XLuaUiManager.Remove(uiName)
            end
        end
    end
    
    --region   ------------------request and response start-------------------
    
    --- 请求投票
    ---@param nameId number 涂装投票Id
    ---@param cb function 回调
    ---@return nil
    --------------------------
    function XSkinVoteManager.RequestSkinVoteName(nameId, cb)
        if not XSkinVoteManager.IsOpen() then
            return
        end
        
        local voteId = XSkinVoteViewModel:GetProperty("_VoteNameId")
        --已经投过票
        if XTool.IsNumberValid(voteId) then
            return
        end
        
        XNetwork.Call("SkinVoteRequest", { SkinId = nameId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            local onRefresh = function()
                XSkinVoteViewModel:Vote(nameId)
                XSkinVoteViewModel:SetProperty("_VoteNameId", nameId)
                if cb then cb() end
            end
            if not XTool.IsTableEmpty(res.RewardList) then
                XUiManager.OpenUiObtain(res.RewardList, nil, onRefresh)
            else
                onRefresh()
            end
            
            
        end)
    end
    
    --- 请求投票数据
    ---@param cb function 协议返回回调
    ---@return nil
    --------------------------
    function XSkinVoteManager.RequestSkinVoteData(cb)
        if not XSkinVoteManager.IsOpen() then
            return
        end
        local timeOfNow = XTime.GetServerNowTimestamp()
        --不发协议
        if timeOfNow - RequestSkinVoteDataTimeStamp < RequestSkinVoteDataInterval then
            if cb then cb() end
            return
        end
        XNetwork.Call("SkinVoteDataRequest", nil, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            RequestSkinVoteDataTimeStamp = timeOfNow
            --活动数据
            local data = res.CenterData
            local activityId = data.ActivityId
            local openActivityId = XSkinVoteViewModel:GetProperty("_Id")
            if not XTool.IsNumberValid(activityId) then
                XSkinVoteManager.OnActivityEnd()
                return
            end
            if activityId ~= openActivityId  then
                XSkinVoteViewModel = XSkinVote.New(activityId)
            end
            XSkinVoteViewModel:UpdateVoteData(data.SkinVoteDataInfos)

            if cb then cb() end
        end)
        
    end
    --endregion------------------request and response finish------------------
    
    --region   ------------------RedPoint start-------------------
    local CommonRedCheck = function()
        if not XSkinVoteManager.IsOpen() then
            return false
        end

        if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.SkinVote) then
            return false
        end
        
        return true
    end
    
    function XSkinVoteManager.MarkPreviewRedPoint(index)
        local key = "PreviewIndex" .. index
        key = GetCookiesKey(key)
        if not XSaveTool.GetData(key) then
            XSaveTool.SaveData(key, true)
        end
    end
    
    function XSkinVoteManager.CheckPreviewRedPoint()
        if not CommonRedCheck() then
            return false
        end
        local list = XSkinVoteViewModel:GetActivityPreviewImgFull()
        for idx, _ in ipairs(list or {}) do
            local key = "PreviewIndex" .. idx
            key = GetCookiesKey(key)
            if not XSaveTool.GetData(key) then
                return true
            end
        end
        
        return false
    end
    
    function XSkinVoteManager.CheckVoteRedPoint()
        if not CommonRedCheck() then
            return false
        end
        local isVoteExpired = XSkinVoteViewModel:IsVoteExpired()
        local voteId = XSkinVoteViewModel:GetProperty("_VoteNameId")
        return not isVoteExpired and not XTool.IsNumberValid(voteId)
    end
    
    --投票结束后提示玩家进入界面查看投票结果
    function XSkinVoteManager.CheckViewPublicRedPoint()
        if not CommonRedCheck() then
            return false
        end
        local isVoteExpired = XSkinVoteViewModel:IsVoteExpired()
        if not isVoteExpired then
            return false
        end
        
        return not XSaveTool.GetData(GetCookiesKey(ViewPublicResultKey))
    end
    
    function XSkinVoteManager.MarkViewPublicRedPoint()
        if not CommonRedCheck() then
            return
        end
        local isVoteExpired = XSkinVoteViewModel:IsVoteExpired()
        if not isVoteExpired then
            return
        end
        local key = GetCookiesKey(ViewPublicResultKey)
        if not XSaveTool.GetData(key) then
            XSaveTool.SaveData(key, true)
        end
    end
    --endregion------------------RedPoint finish------------------
    
    return XSkinVoteManager
end

--region   ------------------RPC start-------------------
XRpc.NotifySkillVotePlayerData = function(skinVoteData) 
    XDataCenter.SkinVoteManager.OnLoginNotify(skinVoteData)
end
--endregion------------------RPC finish------------------