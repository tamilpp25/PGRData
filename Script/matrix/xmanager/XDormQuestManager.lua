local tableInsert = table.insert
local tableSort = table.sort
local tableIndexOf = table.indexof
local tableRemove = table.remove

local XDormQuestData = require("XEntity/XHome/Quest/XDormQuestData")
local XDormQuest = require("XEntity/XHome/Quest/XDormQuest")
local XDormQuestFile = require("XEntity/XHome/Quest/XDormQuestFile")
local XDormQuestTerminal = require("XEntity/XHome/Quest/XDormQuestTerminal")
local XDormTerminalTeam = require("XEntity/XHome/Quest/XDormTerminalTeam")

XDormQuestManagerCreator = function()
    ---@class XDormQuestManager
    local XDormQuestManager = {}

    -- 委托信息
    ---@type XDormQuestData
    local _DormQuestData

    local _DormQuest = {}
    local _DormQuestFile = {}
    local _DormQuestTerminal = {}

    -- 队伍实体信息
    ---@type XDormTerminalTeam
    local _DormTerminalTeamEntity

    -- 终端最高等级
    local _DormTerminalMaxLevel = 0
    -- 终端最大委托数量
    local _DormTerminalMaxQuestCount = 0

    -- 是否有新文件
    local _IsHaveNewQuestFile = false
    -- 是否正在领取奖励
    local _IsAwarding = false
    -- 遣测商店Id
    local _DormShopId = 0
    -- 遣测商店逆元碎片Id
    local _DormQuestFragmentId
    -- 弹出的逆元碎片Id
    local _ShowFragmentId

    local RequestProto = {
        QuestUpgradeTerminalLvRequest = "QuestUpgradeTerminalLvRequest", -- 委托终端升级请求
        QuestAcceptRequest = "QuestAcceptRequest", -- 接取委托请求
        QuestGetAllRewardRequest = "QuestGetAllRewardRequest", -- 一键领取委托奖励请求
        QuestRecallTeamRequest = "QuestRecallTeamRequest", -- 召回队伍请求
        QuestReadFileRequest = "QuestReadFileRequest", -- 查看文件请求
    }

    ---@return XDormQuest
    local function GetDormQuest(id)
        if not XTool.IsNumberValid(id) then
            XLog.Error("XDormQuestManager GetDormQuest error: Id错误, id: " .. id)
            return
        end

        local dormQuest = _DormQuest[id]
        if not dormQuest then
            dormQuest = XDormQuest.New(id)
            _DormQuest[id] = dormQuest
        end
        return dormQuest
    end

    function XDormQuestManager.GetDormQuestViewModel(id)
        return GetDormQuest(id)
    end

    ---@return XDormQuestFile
    local function GetDormQuestFile(id)
        if not XTool.IsNumberValid(id) then
            XLog.Error("XDormQuestManager GetDormQuestFile error: Id错误, id: " .. id)
            return
        end

        local dormQuestFile = _DormQuestFile[id]
        if not dormQuestFile then
            dormQuestFile = XDormQuestFile.New(id)
            _DormQuestFile[id] = dormQuestFile
        end
        return dormQuestFile
    end

    function XDormQuestManager.GetDormQuestFileViewModel(id)
        return GetDormQuestFile(id)
    end

    ---@return XDormQuestTerminal
    local function GetDormQuestTerminal(lv)
        if not XTool.IsNumberValid(lv) then
            XLog.Error("XDormQuestManager GetDormQuestTerminal error: lv错误, lv: " .. lv)
            return
        end

        local dormQuestTerminal = _DormQuestTerminal[lv]
        if not dormQuestTerminal then
            dormQuestTerminal = XDormQuestTerminal.New(lv)
            _DormQuestTerminal[lv] = dormQuestTerminal
        end
        return dormQuestTerminal
    end

    local function CheckPopupByFragmentId(itemId)
        local goods = XShopManager.GetShopRewardGoods(XDormQuestManager.GetShopId(), itemId)
        if not goods then
            return false
        end
        local buyCount = goods.TotalBuyTimes
        local totalCount = goods.BuyTimesLimit
        if buyCount >= totalCount then
            return false
        end

        local popup = true
        local consumeList = goods.ConsumeList or {}
        for _, consume in ipairs(consumeList) do
            local needCount = consume.Count
            local hasCount = XDataCenter.ItemManager.GetCount(consume.Id)
            if needCount > hasCount then
                popup = false
                break
            end
        end

        return popup
    end

    local function GetFragmentIds()
        if _DormQuestFragmentId then
            return _DormQuestFragmentId
        end
        local idStr = CS.XGame.ClientConfig:GetString("DormQuestTerminalFragment")
        _DormQuestFragmentId = {}
        local idStrList = string.Split(idStr, "|")

        for _, sId in pairs(idStrList) do
            tableInsert(_DormQuestFragmentId, tonumber(sId))
        end

        return _DormQuestFragmentId
    end

    function XDormQuestManager.GetDormQuestTerminalViewModel(lv)
        return GetDormQuestTerminal(lv)
    end

    -- 获取当前等级终端的数据
    function XDormQuestManager.GetCurLevelTerminalViewModel()
        local curTerminalLv = _DormQuestData:GetTerminalLv()
        return GetDormQuestTerminal(curTerminalLv)
    end

    -- 获取下一等级终端的数据
    function XDormQuestManager.GetNextLevelTerminalViewModel()
        local curTerminalLv = _DormQuestData:GetTerminalLv()
        if _DormTerminalMaxLevel - curTerminalLv > 0 then
            return GetDormQuestTerminal(curTerminalLv + 1)
        end
    end

    function XDormQuestManager.GetDormTerminalTeamEntity()
        return _DormTerminalTeamEntity
    end

    -- 遣测商店Id
    function XDormQuestManager.GetShopId()
        if XTool.IsNumberValid(_DormShopId) then
            return _DormShopId
        end
        _DormShopId = XUiHelper.GetClientConfig("DormQuestTerminalShopId", XUiHelper.ClientConfigType.Int)
        return _DormShopId
    end

    --- 检查是否弹出购买提示
    ---@param checkCb function 检查回调
    --------------------------
    function XDormQuestManager.CheckPopupShopTip(checkCb)
        --商店未开启
        if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.ShopCommon) then
            if checkCb then
                checkCb(false)
            end
            return
        end
        XShopManager.GetShopInfo(XDormQuestManager.GetShopId(), function()
            _ShowFragmentId = nil
            local ids = GetFragmentIds()
            local popup = false
            for _, id in ipairs(ids) do
                popup = CheckPopupByFragmentId(id)
                if popup then
                    _ShowFragmentId = id
                    break
                end
            end
            if checkCb then
                checkCb(popup)
            end
        end)
    end

    function XDormQuestManager.GetShowFragmentId()
        return _ShowFragmentId or XDataCenter.ItemManager.ItemId.SEllaFragment
    end

    --region 终端信息

    -- 获取终端最大等级
    function XDormQuestManager.GetTerminalMaxLevel()
        return _DormTerminalMaxLevel
    end

    -- 获取终端最大委托数量
    function XDormQuestManager.GetTerminalMaxQuestCount()
        return _DormTerminalMaxQuestCount
    end

    -- 获取完成委托数（升级后会清零）
    function XDormQuestManager.GetTerminalUpgradeExp()
        return _DormQuestData:GetTerminalUpgradeExp()
    end

    -- 获取升级开始时间
    function XDormQuestManager.GetTerminalUpgradeTime()
        return _DormQuestData:GetTerminalUpgradeTime()
    end

    -- 获取升级状态
    function XDormQuestManager.GetTerminalUpgradeStatus()
        return _DormQuestData:GetTerminalUpgradeStatus()
    end

    -- 检测等级是否合法
    function XDormQuestManager.CheckTerminalLevelIsValid()
        local lv = _DormQuestData:GetTerminalLv()
        return XTool.IsNumberValid(lv)
    end

    -- 检查当前角色Id是否在队伍中
    function XDormQuestManager.CheckDispatchCharacter(characterId)
        return _DormTerminalTeamEntity:CheckDispatchCharacter(characterId)
    end

    -- 检查是否是正在领奖
    function XDormQuestManager.CheckIsAwarding()
        return _IsAwarding
    end

    -- 设置是否正在领奖
    function XDormQuestManager.SetIsAwarding(value)
        _IsAwarding = value
    end

    -- 检查终端是否升级
    function XDormQuestManager.CheckTerminalUpgradeSuccess(callBack)
        local curTerminalLv = _DormQuestData:GetTerminalLv()
        local curTerminalViewModel = XDormQuestManager.GetDormQuestTerminalViewModel(curTerminalLv)
        local isGoing = curTerminalViewModel:CheckTerminalOnGoing()
        if isGoing then
            local newTime = XTime.GetServerNowTimestamp()
            local finishTime = curTerminalViewModel:GetTerminalUpgradeFinishTime()
            -- 升级完成
            if newTime >= finishTime then
                -- 刷新终端相关信息
                _DormQuestData:UpdateUpgradeSuccessData()
                if callBack then
                    callBack(true, true, curTerminalLv, _DormQuestData:GetTerminalLv())
                end
            end
        else
            local localSaveLevel = XDormQuestManager.GetQuestTerminalLevel()
            -- 没有本地信息时直接保存
            if not XTool.IsNumberValid(localSaveLevel) then
                localSaveLevel = curTerminalLv
                XDormQuestManager.SaveQuestTerminalLevel()
            end
            -- 检查是否升级
            if curTerminalLv > localSaveLevel and curTerminalLv - localSaveLevel == 1 then
                if callBack then
                    callBack(true, false, localSaveLevel, curTerminalLv)
                end
            end
        end
        if callBack then
            callBack(false, false)
        end
    end

    --endregion

    --region 委托信息

    -- 获取终端所有委托
    function XDormQuestManager.GetTerminalAllQuestData()
        local allQuestData = {}
        allQuestData.Quest = {}
        local totalQuest = _DormQuestData:GetTotalQuest()
        for _, data in pairs(totalQuest) do
            if data:GetIsSpecialQuest() then
                allQuestData.SpecialQuest = data
            else
                tableInsert(allQuestData.Quest, data)
            end
        end
        tableSort(allQuestData.Quest, function(a, b)
            local questIdA = a:GetQuestId()
            local questIdB = b:GetQuestId()

            local viewModelA = XDormQuestManager.GetDormQuestViewModel(questIdA)
            local viewModelB = XDormQuestManager.GetDormQuestViewModel(questIdB)

            local levelA = viewModelA:GetQuestQuality()
            local levelB = viewModelB:GetQuestQuality()

            if levelA ~= levelB then
                return levelA > levelB
            end

            local timeA = viewModelA:GetQuestNeedTime()
            local timeB = viewModelB:GetQuestNeedTime()

            if timeA ~= timeB then
                return timeA > timeB
            end

            return questIdA < questIdB
        end)
        return allQuestData
    end

    -- 返回 1、可领取数量 2、队伍栏位剩余数量
    function XDormQuestManager.GetEntranceShowData()
        if not XDormQuestManager.CheckTerminalLevelIsValid() then
            return 0, 0
        end
        -- 等级为1 完成委托数为0 时不显示气泡
        if _DormQuestData:GetTerminalLv() <= 1 and XDormQuestManager.GetTerminalUpgradeExp() <= 0 then
            return 0, 0
        end
        -- 可领取
        local dispatchedCount = 0
        local questAccept = _DormQuestData:GetQuestAccept()
        for _, questData in pairs(questAccept) do
            if not questData:IsAward() then
                local state = XDormQuestManager.GetQuestAcceptTeamState(questData)
                if state == XDormQuestConfigs.TerminalTeamState.Dispatched then
                    dispatchedCount = dispatchedCount + 1
                end
            end
        end
        -- 可派遣 （有可接取委托 和 有空余队伍栏位）
        local unDispatchCount = 0
        if XDormQuestManager.CheckHaveCanAcceptQuest() then
            unDispatchCount = _DormTerminalTeamEntity:GetFreeTeamPosCount()
        end
        return dispatchedCount, unDispatchCount
    end

    -- 获取已接取委托的状态
    ---@param questAccept XDormQuestAcceptInfo
    function XDormQuestManager.GetQuestAcceptTeamState(questAccept)
        local dormQuestViewModel = XDormQuestManager.GetDormQuestViewModel(questAccept:GetQuestId())
        local acceptTime = questAccept:GetAcceptTime()
        local needTime = dormQuestViewModel:GetQuestNeedTime()
        local finishTime = acceptTime + needTime
        local newTime = XTime.GetServerNowTimestamp()
        if newTime > finishTime then
            return XDormQuestConfigs.TerminalTeamState.Dispatched
        end
        return XDormQuestConfigs.TerminalTeamState.Dispatching
    end

    -- 检查是否是已接取委托
    function XDormQuestManager.CheckQuestAccept(questId, index, resetCount)
        local questAccept = _DormQuestData:GetQuestAccept()
        for _, questData in pairs(questAccept) do
            if questData:GetQuestId() == questId and questData:GetIndex() == index and questData:GetResetCount() == resetCount then
                return true
            end
        end
        return false
    end

    -- 检查是否有可接取的委托
    function XDormQuestManager.CheckHaveCanAcceptQuest()
        local totalQuest = _DormQuestData:GetTotalQuest()
        local canDispatchCount = XDormQuestManager.GetCanDispatchCharacterNumberAndList()
        for _, data in pairs(totalQuest) do
            local isAccept = XDormQuestManager.CheckQuestAccept(data:GetQuestId(), data:GetIndex(), data:GetResetCount())
            local dormQuestViewModel = XDormQuestManager.GetDormQuestViewModel(data:GetQuestId())
            local memberCount = dormQuestViewModel:GetQuestMemberCount()
            if not isAccept and canDispatchCount >= memberCount then
                return true
            end
        end
        return false
    end

    function XDormQuestManager.GetCanDispatchCharacterNumberAndList()
        local count = 0
        local allCharacterIds = XDataCenter.DormManager.GetAllCharacterIds()
        local canDispatchCharacterList = {}
        for _, characterId in pairs(allCharacterIds) do
            if not XDormQuestManager.CheckDispatchCharacter(characterId) then
                count = count + 1
                tableInsert(canDispatchCharacterList, characterId)
            end
        end
        return count, canDispatchCharacterList
    end

    -- 获取可派遣的委托数量 (不考虑栏位和成员)
    function XDormQuestManager.GetCanAcceptQuestCountAndList()
        local acceptQuestCount = 0
        local canAcceptQuestList = {}
        local totalQuest = _DormQuestData:GetTotalQuest()
        for _, data in pairs(totalQuest) do
            local isAccept = XDormQuestManager.CheckQuestAccept(data:GetQuestId(), data:GetIndex(), data:GetResetCount())
            if not isAccept then
                acceptQuestCount = acceptQuestCount + 1
                tableInsert(canAcceptQuestList, data)
            end
        end
        return acceptQuestCount, canAcceptQuestList
    end

    -- 获取空闲栏位数量
    function XDormQuestManager.GetFreeTeamPosCount()
        if _DormTerminalTeamEntity then
            return _DormTerminalTeamEntity:GetFreeTeamPosCount()
        end
        return 0
    end

    -- 获取可领取委托和派遣中的数量
    function XDormQuestManager.GetQuestAcceptStateCount()
        local dispatchedCount = 0
        local dispatchingCount = 0
        local questAccept = _DormQuestData:GetQuestAccept()
        for _, questData in pairs(questAccept) do
            if not questData:IsAward() then
                local state = XDormQuestManager.GetQuestAcceptTeamState(questData)
                if state == XDormQuestConfigs.TerminalTeamState.Dispatched then
                    dispatchedCount = dispatchedCount + 1
                end
                if state == XDormQuestConfigs.TerminalTeamState.Dispatching then
                    dispatchingCount = dispatchingCount + 1
                end
            end
        end
        return dispatchedCount, dispatchingCount
    end

    -- 检查是否有可以领取的委托奖励
    function XDormQuestManager.CheckHasCanClaimRewardQuest()
        local questAccept = _DormQuestData:GetQuestAccept()
        for _, questData in pairs(questAccept) do
            if not questData:IsAward() then
                local state = XDormQuestManager.GetQuestAcceptTeamState(questData)
                if state == XDormQuestConfigs.TerminalTeamState.Dispatched then
                    return true
                end
            end
        end

        return false
    end

    function XDormQuestManager.CheckCanAcceptQuestAndHasNewPos()
        -- 可派遣 (有可接取委托 和 有空余队伍栏位)
        local isTeamHaveNewPos = _DormTerminalTeamEntity:CheckHaveNewPos()
        if isTeamHaveNewPos and XDormQuestManager.CheckHaveCanAcceptQuest() then
            return true
        end
        return false
    end
    --endregion

    --region 文件相关

    function XDormQuestManager.GetCollectFileDataBySubGroupId(groupId)
        local collectFiles = _DormQuestData:GetCollectFiles()
        local fileData = {}
        for _, data in pairs(collectFiles) do
            local fileId = data:GetFileId()
            local questFileViewModel = XDormQuestManager.GetDormQuestFileViewModel(fileId)
            local subGroupId = questFileViewModel:GetQuestFileDetailSubGroupId()
            if subGroupId == groupId then
                tableInsert(fileData, fileId)
            end
        end
        return fileData
    end

    -- 检测文件是否已查阅
    function XDormQuestManager.CheckReadFile(fileId)
        return _DormQuestData:CheckReadFile(fileId)
    end

    -- 获取是否有新文件
    function XDormQuestManager.GetIsHaveNewQuestFile()
        return _IsHaveNewQuestFile
    end

    -- 设置是否有新文件
    function XDormQuestManager.SetIsHaveNewQuestFile(value)
        _IsHaveNewQuestFile = value
    end

    -- 获取未查阅的文件
    function XDormQuestManager.GetNotReadQuestFile()
        local notReadFile = {}
        local collectFiles = _DormQuestData:GetCollectFiles()
        for _, data in pairs(collectFiles) do
            if not data:GetIsRead() then
                tableInsert(notReadFile, data:GetFileId())
            end
        end
        return notReadFile
    end

    --endregion

    --region 红点相关

    -- 检查委托文件红点
    function XDormQuestManager.CheckQuestFileRedPoint()
        local notReadFile = XDormQuestManager.GetNotReadQuestFile()
        if XTool.IsTableEmpty(notReadFile) then
            return false
        end
        return true
    end

    -- 检查入口红点
    -- isNotContainUpgrade 是否不包含可升级 默认是包含
    function XDormQuestManager.CheckDormEntrustRedPoint(isNotContainUpgrade)
        if not XDormQuestManager.CheckTerminalLevelIsValid() then
            return false
        end
        if _DormQuestData:GetTerminalLv() <= 1 and XDormQuestManager.GetTerminalUpgradeExp() <= 0 then
            return false
        end
        -- 可升级
        local curTerminalViewModel = XDormQuestManager.GetCurLevelTerminalViewModel()
        local isUpgrade = curTerminalViewModel:CheckTerminalCanUpgrade()
        if isUpgrade and not isNotContainUpgrade then
            return true
        end
        -- 可领取
        local questAccept = _DormQuestData:GetQuestAccept()
        for _, questData in pairs(questAccept) do
            if not questData:IsAward() then
                local state = XDormQuestManager.GetQuestAcceptTeamState(questData)
                if state == XDormQuestConfigs.TerminalTeamState.Dispatched then
                    return true
                end
            end
        end
        -- 可派遣 (有可接取委托 和 有空余队伍栏位)
        if XDormQuestManager.CheckCanAcceptQuestAndHasNewPos() then
            return true
        end

        return false
    end

    --endregion

    --region 本地数据

    function XDormQuestManager.GetQuestTerminalLevelKey()
        if XPlayer.Id then
            return string.format("DormQuestTerminalLevelKey_%s", tostring(XPlayer.Id))
        end
    end

    function XDormQuestManager.GetQuestTerminalLevel()
        local key = XDormQuestManager.GetQuestTerminalLevelKey()
        local level = XSaveTool.GetData(key) or 0
        return level
    end

    function XDormQuestManager.SaveQuestTerminalLevel()
        local key = XDormQuestManager.GetQuestTerminalLevelKey()
        XSaveTool.SaveData(key, _DormQuestData:GetTerminalLv())
    end

    function XDormQuestManager.GetTerminalShowUpgradeTip()
        local lv = _DormQuestData:GetTerminalLv()
        if XPlayer.Id then
            return string.format("DormQuestTerminalShowUpgradeTip_%s_%s", tostring(XPlayer.Id), tostring(lv))
        end
    end

    function XDormQuestManager.CheckTerminalShowUpgradeTip()
        local key = XDormQuestManager.GetTerminalShowUpgradeTip()
        local isShow = XSaveTool.GetData(key) or false
        return isShow
    end

    function XDormQuestManager.SaveTerminalShowUpgradeTip(value)
        local key = XDormQuestManager.GetTerminalShowUpgradeTip()
        XSaveTool.SaveData(key, value)
    end

    --endregion

    --region 一键领取委托
    --================
    --一键接取委托
    --================
    function XDormQuestManager.QuestAutoAcceptReq()
        -- 没有空闲位置
        if not _DormTerminalTeamEntity:CheckHaveNewPos() then
            XUiManager.TipText("DormQuestAutoQuestTeamPosNotEnough")
            return
        end

        -- 暂无空闲成员或可接取委托
        if not XDormQuestManager.CheckHaveCanAcceptQuest() then
            XUiManager.TipText("DormQuestAutoQuestCanNotAcceptQuest")
            return
        end
        
        local canDispatchCharacterNumber, canDispatchCharacterList = XDataCenter.DormQuestManager.GetCanDispatchCharacterNumberAndList()
        local freeTeamPosCount = XDataCenter.DormQuestManager.GetFreeTeamPosCount()
        local _, canAcceptQuestList = XDataCenter.DormQuestManager.GetCanAcceptQuestCountAndList()

        -- 重新组织委托数据列表结构（方便动态规划算法处理，按照总价值从大到小排序）
        local regroupQuestList = XDormQuestManager._GetRegroupQuestList(canAcceptQuestList)
        -- 动态规划筛选出来的能够被派遣的最好委托列表(已排好序)
        local filteredQuestList = XDormQuestManager._GetFilteredQuestList(regroupQuestList, canDispatchCharacterNumber, freeTeamPosCount)
        -- 属性对应的角色数量字典
        local attribCharacterCountDic = XDormQuestManager._GetAttribCharacterCountDic(canDispatchCharacterList)
        -- 获取角色评估表(已经按规则排好序,总价值从小到大,总价值为0的排在最后)
        local characterEvaluateList = XDormQuestManager._GetCharacterEvaluateTable(filteredQuestList, canDispatchCharacterList, attribCharacterCountDic)

        local questAcceptRequestParamsList = XDormQuestManager._GetQuestAcceptRequestParamsList(filteredQuestList, characterEvaluateList)

        --XLog.Error(questAcceptRequestParamsList)
        XDormQuestManager.QuestAcceptRequest(questAcceptRequestParamsList, function()
            XEventManager.DispatchEvent(XEventId.EVENT_DORM_QUEST_AUTO_ACCEPT)
        end)
    end

    function XDormQuestManager._GetQuestAcceptRequestParamsList(filteredQuestList, characterEvaluateList)
        local tempQuestDistributionList = {}
        -- 初始化临时分配字典
        for _, questData in ipairs(filteredQuestList) do
            local questId = questData:GetQuestId()
            local questViewModel = XDormQuestManager.GetDormQuestViewModel(questId)
            tableInsert(tempQuestDistributionList, {
                QuestId = questId,
                Index = questData:GetIndex(),
                IsDistributed = false, -- 是否分配过一次
                IsDistributeComplete = false, -- 是否分配完成
                TeamList = {},
                NeedMemberCount = questViewModel:GetQuestMemberCount(),
                NeedAttrib = XTool.Clone(questViewModel:GetQuestRecommendAttrib()),
            })
        end

        local completeCount = 0
        local questCount = #filteredQuestList
        local index = 1
        while completeCount < questCount do
            local realIndex = index % questCount
            if realIndex == 0 then
                realIndex = questCount
            elseif realIndex == 1 then
                completeCount = 0
            end

            local questDistData = tempQuestDistributionList[realIndex]
            local questId = questDistData.QuestId
            local characterDistIdxList = {}

            if questDistData.IsDistributeComplete then
                goto continue
            end

            if not questDistData.isDistributed then
                -- 第一次分配
                for characterEvaluateIdx, characterEvaluate in ipairs(characterEvaluateList) do
                    if not questDistData.NeedAttrib then
                        -- 如果需要的属性为空 说明不需要再匹配属性了 后面等着补位就行
                        break
                    end
                    if #characterDistIdxList >= questDistData.NeedMemberCount then
                        -- 第一次分配就分配满了 不需要后续补位了
                        break
                    end
                    local suggestQuestValueDict = characterEvaluate.SuggestQuestValueDict
                    if suggestQuestValueDict[questId] then
                        local catchAttribList = suggestQuestValueDict[questId].CatchAttribList
                        local isCatch, tempCatchAttrList = XDormQuestManager._GetIsCatchSameAttrib(questDistData.NeedAttrib, catchAttribList)
                        if isCatch then
                            for _, catchAttrib in ipairs(tempCatchAttrList) do
                                local attribIndex = tableIndexOf(questDistData.NeedAttrib, catchAttrib)
                                if attribIndex then
                                    tableRemove(questDistData.NeedAttrib, attribIndex)
                                end
                            end

                            if #questDistData.NeedAttrib == 0 then
                                questDistData.NeedAttrib = nil
                            end

                            tableInsert(characterDistIdxList, characterEvaluateIdx)
                        end
                    end
                end
                questDistData.isDistributed = true
            else
                --剩余补位
                for i = 1, questDistData.NeedMemberCount do
                    tableInsert(characterDistIdxList, i)
                end
            end

            if #characterDistIdxList <= 0 then goto continue end
            
            for i = #characterDistIdxList, 1, -1 do
                local characterEvaluate = tableRemove(characterEvaluateList, characterDistIdxList[i])
                local characterId = characterEvaluate.CharacterId
                tableInsert(questDistData.TeamList, characterId)
            end
            
            questDistData.NeedMemberCount = questDistData.NeedMemberCount - #characterDistIdxList
            if questDistData.NeedMemberCount <= 0 then
                questDistData.IsDistributeComplete = true
            end

            :: continue ::

            if questDistData.IsDistributeComplete then
                completeCount = completeCount + 1
            end

            index = index + 1
            if index >= 500 then
                -- 防止死循环及过大的循环次数
                return {}
            end
        end

        local questAcceptRequestParamsList = {}

        for _, questDistData in ipairs(tempQuestDistributionList) do
            local questIndex = questDistData.Index
            local teamList = questDistData.TeamList
            tableInsert(questAcceptRequestParamsList, { Index = questIndex, TeamCharacter = teamList })
        end

        return questAcceptRequestParamsList
    end

    function XDormQuestManager._GetCharacterEvaluateTable(filteredQuestList, canDispatchCharacterList, attribCharacterCountDic)
        local characterEvaluateList = {}
        for _, characterId in ipairs(canDispatchCharacterList) do
            local characterEvaluate = {}
            characterEvaluate.CharacterId = characterId
            local suggestQuestValueDict = {}
            characterEvaluate.SuggestQuestValueDict = suggestQuestValueDict
            characterEvaluate.GetTotalValue = function(self)
                local totalValue = 0
                for _, data in pairs(self.SuggestQuestValueDict) do
                    totalValue = totalValue + data.Value
                end
                return totalValue
            end

            local characterStyleConfig = XDormConfig.GetCharacterStyleConfigById(characterId)
            local characterAttrib = characterStyleConfig.QuestAttrib
            for _, questData in ipairs(filteredQuestList) do
                local questId = questData:GetQuestId()
                local questViewModel = XDormQuestManager.GetDormQuestViewModel(questId)
                local questRecommendAttrib = questViewModel:GetQuestRecommendAttrib()
                local isCatchSameAttrib, catchAttribList = XDormQuestManager._GetIsCatchSameAttrib(characterAttrib, questRecommendAttrib)
                if isCatchSameAttrib then
                    local isOnlyOne = false
                    for _, catchAttrib in ipairs(catchAttribList) do
                        if attribCharacterCountDic[catchAttrib] and attribCharacterCountDic[catchAttrib] == 1 then
                            isOnlyOne = true
                            break
                        end
                    end
                    if isOnlyOne then
                        suggestQuestValueDict[questId] = { Value = 30, CatchAttribList = catchAttribList }
                    else
                        suggestQuestValueDict[questId] = { Value = 1, CatchAttribList = catchAttribList }
                    end
                end
            end

            tableInsert(characterEvaluateList, characterEvaluate)
        end

        -- 为评估表按照总价值排序，从小到大，但是总价值为0的排在最后
        tableSort(characterEvaluateList, function(a, b)
            if a:GetTotalValue() == 0 then
                return false
            elseif b:GetTotalValue() == 0 then
                return true
            end
            return a:GetTotalValue() < b:GetTotalValue()
        end)

        return characterEvaluateList
    end

    function XDormQuestManager._GetAttribCharacterCountDic(characterList)
        local attribCharacterCountDic = {}
        for _, characterId in ipairs(characterList) do
            local characterStyleConfig = XDormConfig.GetCharacterStyleConfigById(characterId)
            local characterAttrib = characterStyleConfig.QuestAttrib
            for _, attrib in ipairs(characterAttrib) do
                if not attribCharacterCountDic[attrib] then
                    attribCharacterCountDic[attrib] = 1
                else
                    attribCharacterCountDic[attrib] = attribCharacterCountDic[attrib] + 1
                end
            end
        end
        return attribCharacterCountDic
    end

    function XDormQuestManager._GetIsCatchSameAttrib(characterAttrib, questRecommendAttrib)
        local isCatchSameAttrib = false
        local catchAttribList = {}
        for _, characterAttr in pairs(characterAttrib) do
            for _, questAttr in pairs(questRecommendAttrib) do
                if characterAttr == questAttr then
                    isCatchSameAttrib = true
                    tableInsert(catchAttribList, characterAttr)
                    break
                end
            end
        end

        return isCatchSameAttrib, catchAttribList
    end

    function XDormQuestManager._GetRegroupQuestList(canAcceptQuestList)
        local regroupQuestList = {}
        for _, questData in ipairs(canAcceptQuestList) do
            local questViewModel = XDormQuestManager.GetDormQuestViewModel(questData:GetQuestId())
            local regroupQuest = {
                QuestData = questData,
                NeedMemberCount = questViewModel:GetQuestMemberCount(), -- 需要的队伍成员数量
                NeedFreePosition = 1, -- 需要的空闲栏位
                TotalValue = XDormQuestManager._CalcQuestRewardsValue(questData), -- 奖励价值
            }
            tableInsert(regroupQuestList, regroupQuest)
        end

        tableSort(regroupQuestList, function(a, b)
            return a.TotalValue > b.TotalValue
        end)

        return regroupQuestList
    end

    -- 目前奖励只有一种类型，所以简单计算所有数量作为总价值
    function XDormQuestManager._CalcQuestRewardsValue(questData)
        local questViewModel = XDormQuestManager.GetDormQuestViewModel(questData:GetQuestId())
        local isSpecialQuest = questData:GetIsSpecialQuest()
        local finishRewardId = questViewModel:GetQuestFinishReward()
        local extraRewardId = questViewModel:GetQuestExtraReward()
        local finishRewardValue = 0
        local extraRewardValue = 0
        if XTool.IsNumberValid(finishRewardId) then
            local finishRewardList = XRewardManager.GetRewardList(finishRewardId)
            for _, reward in pairs(finishRewardList) do
                finishRewardValue = finishRewardValue + reward.Count
            end
        end
        if XTool.IsNumberValid(extraRewardId) then
            local extraRewardList = XRewardManager.GetRewardList(extraRewardId)
            for _, reward in pairs(extraRewardList) do
                extraRewardValue = extraRewardValue + reward.Count
            end
        end

        local totalValue = finishRewardValue + extraRewardValue
        if isSpecialQuest then
            -- 特殊委托优先级最高，总价值*10
            totalValue = totalValue * 10
        end
        return totalValue
    end

    -- 使用动态规划算法，根据队伍栏位数量(freeTeamPosCount)、可以派遣的角色数量(canDispatchCharacterNumber)、重组后的委托列表(regroupQuestList)，计算最优解
    function XDormQuestManager._GetFilteredQuestList(regroupQuestList, canDispatchCharacterNumber, freeTeamPosCount)
        -- 初始化dp表
        local dpTable = {}
        for i = 1, #regroupQuestList do
            dpTable[i] = {}
            for j = 1, canDispatchCharacterNumber do
                dpTable[i][j] = {}
                for k = 1, freeTeamPosCount do
                    dpTable[i][j][k] = { Value = 0, Pre = nil }
                end
            end
        end

        -- 如果索引超出边界，价值为0 开始通过已知状态推导未知状态
        for i = 1, #regroupQuestList do
            for j = 1, canDispatchCharacterNumber do
                for k = 1, freeTeamPosCount do
                    local needMemberCount = regroupQuestList[i].NeedMemberCount
                    local needFreePosition = regroupQuestList[i].NeedFreePosition
                    local totalValue = regroupQuestList[i].TotalValue

                    local preValue = 0

                    if i > 1 then
                        preValue = dpTable[i - 1][j][k].Value
                    end
                    if j >= needMemberCount and k >= needFreePosition then
                        if i == 1 then
                            dpTable[i][j][k].Value = totalValue
                        else
                            local remainValue = 0
                            if j == needMemberCount or k == needFreePosition then
                                remainValue = 0
                            else
                                remainValue = dpTable[i - 1][j - needMemberCount][k - needFreePosition].Value
                            end
                            local acceptedValue = totalValue + remainValue -- 接受当前委托的总价值
                            local notAcceptedValue = preValue -- 不接受当前委托的总价值

                            if acceptedValue > notAcceptedValue then
                                dpTable[i][j][k].Value = acceptedValue
                                dpTable[i][j][k].Pre = { I = i - 1, J = j - needMemberCount, K = k - needFreePosition }
                            else
                                dpTable[i][j][k].Value = notAcceptedValue
                                dpTable[i][j][k].Pre = { I = i - 1, J = j, K = k }
                            end
                        end
                    else
                        dpTable[i][j][k].Value = preValue
                        dpTable[i][j][k].Pre = { I = i - 1, J = j, K = k }
                    end
                    if dpTable[i][j][k].Pre then
                        if dpTable[i][j][k].Pre.I <= 0 or dpTable[i][j][k].Pre.J <= 0 or dpTable[i][j][k].Pre.K <= 0 then
                            dpTable[i][j][k].Pre = nil
                        end
                    end
                end
            end
        end

        -- 打印最大价值
        --XLog.Error(dpTable[canAcceptQuestCount][canDispatchCharacterNumber][freeTeamPosCount].Value)
        -- 通过已经填充完毕数据的dpTable获取最优解的委托列表
        local bestValueQuestList = {}

        local preNode = dpTable[#regroupQuestList][canDispatchCharacterNumber][freeTeamPosCount]
        local preQuestIdx = #regroupQuestList
        while preNode do
            if not preNode.Pre then
                -- 没有前置节点,说明最后一个节点被接受
                if preNode.Value > 0 then
                    tableInsert(bestValueQuestList, regroupQuestList[preQuestIdx])
                end
                break
            end
            local preIndex = preNode.Pre
            if preNode.Value ~= dpTable[preIndex.I][preIndex.J][preIndex.K].Value then
                tableInsert(bestValueQuestList, regroupQuestList[preIndex.I + 1])
            end
            preNode = dpTable[preIndex.I][preIndex.J][preIndex.K]
            preQuestIdx = preIndex.I
        end

        -- 按照价值从大到小排序
        tableSort(bestValueQuestList, function(a, b)
            return a.TotalValue > b.TotalValue
        end)

        -- 将QuestData从bestValueQuestList中提取出来
        local filteredQuestList = {}
        for _, data in ipairs(bestValueQuestList) do
            tableInsert(filteredQuestList, data.QuestData)
        end

        return filteredQuestList
    end
    --endregion

    --region 网络数据

    local function DormQuestUpdate(data)
        _DormQuestData:UpdateQuestAccept(data.QuestAccept)
        _DormQuestData:UpdateCollectFile(data.CollectFiles, true)
        _DormQuestData:UpdateTerminalUpgradeExp(data.TerminalUpgradeExp)
    end

    -- 登录的时候下发
    function XDormQuestManager.InitQuestData(data)
        if not data then
            return
        end
        _DormQuestData:UpdateData(data)
    end

    -- 第一次进入宿舍下发
    function XDormQuestManager.NotifyDormQuestTerminalInit(data)
        _DormQuestData:UpdateTerminalLv(data.TerminalLv)
        _DormQuestData:UpdateTotalQuest(data.TotalQuest)
    end

    -- 委托更新时下发
    function XDormQuestManager.NotifyDormQuestData(data)
        _DormQuestData:UpdateTotalQuest(data.TotalQuest)
        _DormQuestData:UpdateQuestAccept(data.QuestAccept)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_DORM_TERMINAL_QUEST_UPDATE)
    end

    -- 委托终端升级请求
    function XDormQuestManager.QuestUpgradeTerminalLvRequest(cb)
        XNetwork.Call(RequestProto.QuestUpgradeTerminalLvRequest, nil, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            -- 刷新升级开始时间
            _DormQuestData:UpdateTerminalUpgradeTime(res.TerminalUpgradeTime)
            -- 刷新升级状态
            _DormQuestData:UpdateTerminalUpgradeStatus(XDormQuestConfigs.TerminalUpgradeState.OnGoing)

            if cb then
                cb()
            end
        end)
    end

    -- 接取委托请求 reqParam结构 : { Index , TeamCharacter }
    function XDormQuestManager.QuestAcceptRequest(reqParamsList, cb)
        XNetwork.Call(RequestProto.QuestAcceptRequest, { QuestAcceptParams = reqParamsList }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            _DormQuestData:UpdateQuestAccept(res.QuestAccept)

            if cb then
                cb()
            end
        end)
    end

    -- 一键领取委托奖励请求
    function XDormQuestManager.QuestGetAllRewardRequest(cb)
        _IsAwarding = true
        XNetwork.Call(RequestProto.QuestGetAllRewardRequest, nil, function(res)
            if res.Code ~= XCode.Success then
                _IsAwarding = false
                XUiManager.TipCode(res.Code)
                return
            end

            DormQuestUpdate(res.DormQuestUpdate)
            -- 奖励排序 按照委托等级 从低到高
            local finishQuestInfos = res.FinishQuestInfos or {}
            tableSort(finishQuestInfos, function(a, b)
                local qualityA = XDormQuestManager.GetDormQuestViewModel(a.QuestId):GetQuestQuality()
                local qualityB = XDormQuestManager.GetDormQuestViewModel(b.QuestId):GetQuestQuality()
                if qualityA ~= qualityB then
                    return qualityA < qualityB
                end
                return a.QuestId < b.QuestId
            end)

            if cb then
                cb(finishQuestInfos)
            end
        end)
    end

    -- 召回队伍请求
    function XDormQuestManager.QuestRecallTeamRequest(index, resetCount, cb)
        local req = { Index = index, ResetCount = resetCount }

        XNetwork.Call(RequestProto.QuestRecallTeamRequest, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            _DormQuestData:UpdateQuestAccept(res.QuestAccept)

            if cb then
                cb()
            end
        end)
    end

    -- 查看文件请求
    function XDormQuestManager.QuestReadFileRequest(fileId, cb)
        local req = { FileId = fileId }

        XNetwork.Call(RequestProto.QuestReadFileRequest, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            _DormQuestData:RecordReadFile(fileId)

            if cb then
                cb()
            end
        end)
    end

    --endregion

    function XDormQuestManager.Init()
        local questTerminalConfigs = XDormQuestConfigs.GetAllConfigs(XDormQuestConfigs.TableKey.QuestTerminal)
        if not questTerminalConfigs then
            return
        end
        -- 获取最大等级
        for _, config in pairs(questTerminalConfigs) do
            if config.Lv > _DormTerminalMaxLevel then
                _DormTerminalMaxLevel = config.Lv
            end
        end
        local config = questTerminalConfigs[_DormTerminalMaxLevel]
        _DormTerminalMaxQuestCount = config.QuestCount

        _DormTerminalTeamEntity = XDormTerminalTeam.New()
        _DormTerminalTeamEntity:InitTeamLimit(config.TeamCount)
        -- 初始化宿舍委托信息
        if not _DormQuestData then
            _DormQuestData = XDormQuestData.New()
        end
    end

    function XDormQuestManager.Test(cb)
        local finishQuestInfos = {}
        local questIds = { 1001, 1002, 1003 }
        for _, id in ipairs(questIds) do
            local info = {
                QuestId = id,
                TeamCharacter = { 1021001 },
                FinishReward = 204,
                ExtraReward = 205,
                FileId = 0,
            }
            tableInsert(finishQuestInfos, info)
        end
        if cb then
            cb(finishQuestInfos)
        end
    end

    XDormQuestManager.Init()
    return XDormQuestManager
end

XRpc.NotifyDormQuestTerminalInit = function(data)
    XDataCenter.DormQuestManager.NotifyDormQuestTerminalInit(data)
end

XRpc.NotifyDormQuestData = function(data)
    XDataCenter.DormQuestManager.NotifyDormQuestData(data)
end