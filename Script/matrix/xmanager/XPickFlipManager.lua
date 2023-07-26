local XPFRewardGroup = require("XEntity/XPickFlip/XPFRewardGroup")

XPickFlipManagerCreator = function()
    local XPickFlipManager = {}
    local RewardGroupDic = {}
    -- groupId : 奖励组Id
    function XPickFlipManager.OpenMainUi(groupId)
        if groupId == nil then groupId = XPickFlipConfigs.GetCurrentGroupId() end
        local group = XPickFlipManager.GetRewardGroup(groupId)
        if not group:GetIsOpen(true) then return end
        XPickFlipManager.RequestActivityData(groupId, function()
            XLuaUiManager.Open("UiPickFlipMain", groupId)    
        end)
    end

    function XPickFlipManager.GetRewardGroup(id)
        if RewardGroupDic[id] == nil then
            RewardGroupDic[id] = XPFRewardGroup.New(id)
        end
        return RewardGroupDic[id]
    end

    function XPickFlipManager.HandleActivityEndTime()
        XLuaUiManager.RunMain()
        XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
    end

    --######################## 请求 ########################

    function XPickFlipManager.RequestActivityData(id, callback)
        XNetwork.CallWithAutoHandleErrorCode("PickFlipActivityDataRequest", { Id = id }, function(res)
            -- 初始化数据
            local rewardGroup = XPickFlipManager.GetRewardGroup(id)
            rewardGroup:InitOrUpdateWithServerData(res)
            if callback then callback() end
        end)
    end

    -- 一次性选择完所有的固定奖励
    -- id : 活动id，即奖励组id
    -- rewardIds : 需要选择的固定奖励id数组
    function XPickFlipManager.RequestPickReward(id, rewardIds, callback)
        local requestBody = {
            Id = id,
            PickedRewardIds = rewardIds
        }
        XNetwork.CallWithAutoHandleErrorCode("PickFlipActivityPickRewardRequest", requestBody, function(res)
            -- 更新层级数据
            local rewardGroup = XPickFlipManager.GetRewardGroup(id)
            rewardGroup:UpdateLayerRewardDatas(res.GroupDatas)
            if callback then callback() end
        end)
    end

    -- 请求翻卡
    -- id : 活动id，即奖励组id
    function XPickFlipManager.RequestFlipReward(id, rewardIndex, callback)
        local requestBody = {
            Id = id,
            RewardIndex = rewardIndex
        }
        XNetwork.CallWithAutoHandleErrorCode("PickFlipActivityFlipRewardRequest", requestBody, function(res)
            -- 更新层级数据
            local rewardGroup = XPickFlipManager.GetRewardGroup(id)
            local reward = rewardGroup:GetCurrentLayer():GetRewardByIndex(rewardIndex)
            reward:SetState(res.RewardState)
            XUiManager.OpenUiObtain(res.RewardGoodsList)
            if callback then callback(reward) end
        end)
    end

    -- id : 活动id，即奖励组id
    function XPickFlipManager.RequestFinishGroup(id, callback)
        XNetwork.CallWithAutoHandleErrorCode("PickFlipActivityFinishGroupRequest", { Id = id }, function(res)
            -- 更新层级数据
            local rewardGroup = XPickFlipManager.GetRewardGroup(id)
            local lastLayerId = rewardGroup:GetCurrentLayer():GetId()
            rewardGroup:InitOrUpdateWithServerData(res)
            XUiManager.OpenUiObtain(res.RewardGoodsList)
            if callback then callback(lastLayerId ~= res.RewardGroupId) end
        end)
    end

    return XPickFlipManager
end