-- 战双大秘境管理器
local XExFubenActivityManager = require("XEntity/XFuben/XExFubenActivityManager")
local XRiftChapter = require("XEntity/XRift/XRiftChapter")
local XRiftFightLayer = require("XEntity/XRift/XRiftFightLayer")
local XRiftRole = require("XEntity/XRift/XRiftRole")
local XRiftMonster = require("XEntity/XRift/XRiftMonster")
local XRiftTeam = require("XEntity/XRift/XRiftTeam")
local XRobot = require("XEntity/XRobot/XRobot")
local XRiftPlugin = require("XEntity/XRift/XRiftPlugin")
local XRiftAttributeTemplate = require("XEntity/XRift/XRiftAttributeTemplate")
local ScreenAll = CS.XTextManager.GetText("ScreenAll")

XRiftManagerCreator = function()
    local XRiftManager = XExFubenActivityManager.New(XFubenConfigs.ChapterType.Rift, "RiftManager")
    -- 活动配置数据
    local CurrentConfig = nil -- 基本活动配置
    local StartTime = 0 -- 本轮开始时间
    local EndTime = 0 -- 本轮结束时间
    -- 实体数据
    local AllRoles = {}
    local AllPluginDicById = {} -- XPlugin插件列表
    local ChapterDicById = {} -- 区域
    local FightLayerDicById = {} -- 作战层
    local RoleDicById = {}
    local MonsterDicById = {}
    -- 自定义数据
    local TargetCanResetTimestamp = 0 -- 在这个时间戳之后才可以重置
    local MultiTeamData = {} -- 多队伍数据（存本地）
    local SingleTeamData = {}
    local CurrSelectRiftStageGroup = nil -- 全局数据，最后一次点击过的关卡节点，用来作为进入战斗时传入的参数
    local LastFightXStage = nil -- 记录最后1次战斗过的stage，扫荡也算
    local PluginShopGoodList = nil -- 插件商店物品列表
    local NewLayerIdTrigger = nil -- 层结算后是否确认跳转到下一层
    local IsFirstPassChapterTrigger = nil -- 区域首通后是否弹提示
    local IsLayerSettleTrigger = nil -- 层结算ui（必须在外面显示）
    local IsEnterNextFightTrigger = nil -- 触发了进入下一关战斗
    local IsJumpOpenTrigger = nil -- 触发了跨层解锁
    local IsJumpResTrigger = nil -- 触发高盖低(跨层通关)奖励机制
    -- 服务器下发确认的数据
    local ActivityId = 1
    local MaxUnLockFightLayerOrder = nil -- 当前解锁的最高层作战层
    local MaxPassFightLayerOrder = nil  -- 当前通过的最高层作战层
    local MaxLoad = 0 -- 角色负载上限
    local SweepTimes = 0 -- 已扫荡次数
    local AttrTemplateDicById = {} -- 队伍加点模板列表
    local TotalAttrLevel = 0 -- 队伍加点：当前已拥有的属性点数
    local AttrLevelMax = 0 -- 队伍加点：当前单个属性加点最大值
    local RankData = {} -- 排行榜数据
    local TeamDatas = {} -- 队伍对应的加点模板

    function XRiftManager.Init()
        XRiftManager.RegisterEvents()
        XRiftManager.InitChapter()
        XRiftManager.InitFightLayer()
        -- StageGroup和Stage比较特殊，和作战层位置绑定，必须等服务器下发后再创建实例,所以具体的某个StageGroup和Stage都不能通过ID查找，只能通过【作战层-关卡节点序号】这样的关系查找
        XRiftManager.GenerateMonsterData()
        XRiftManager.GenerateAttrTemplate()
        XRiftManager.GeneratePluginData()
    end

    --注册事件
    function XRiftManager.RegisterEvents()
        --玩家角色增加时，增加成员
        XEventManager.AddEventListener(XEventId.EVENT_CHARACTER_ADD_SYNC, XRiftManager.OnCharacterAdd)
        XEventManager.AddEventListener(XEventId.EVENT_FUBEN_SETTLE_REWARD,
    function(settleData)
            if not LastFightXStage then
                return
            end
            -- 这条代码开新手指引检测
            XDataCenter.FunctionEventManager.UnLockFunctionEvent()
            -- 不是大秘境stage 返回
            local isRiftStageRes = XRiftConfig.GetStageConfigById(settleData.StageId)
            if not isRiftStageRes then
                return
            end 

            -- 因为会在战斗结束后重复请求战斗 提前移除
            XLuaUiManager.Remove("UiRiftSettlePlugin")
            XLuaUiManager.Remove("UiRiftSettleWin")

            if settleData.IsWin then
                XRiftManager.DoShowReward({SettleData = settleData})
            else
                CS.XFight.ExitForClient(true)
            end
        end)
    end

    function XRiftManager.GetCurrentConfig()
        return CurrentConfig
    end

    function XRiftManager.GetTime()
        return StartTime, EndTime
    end

    function XRiftManager.IsInActivity()
        if XTool.IsTableEmpty(CurrentConfig) then
            return false
        end
        return XFunctionManager.CheckInTimeByTimeId(CurrentConfig.TimeId)
    end

    function XRiftManager.GetLastFightXStage()
        return LastFightXStage
    end

    function XRiftManager.SetCurrSelectRiftStage(xStageGroup)
        CurrSelectRiftStageGroup = xStageGroup
    end

    function XRiftManager.GetCurrSelectRiftStageGroup()
        return CurrSelectRiftStageGroup
    end
    
    function XRiftManager.GetMaxUnLockFightLayerId()
        return MaxUnLockFightLayerOrder
    end

    function XRiftManager.GetMaxPassFightLayerId()
        return MaxPassFightLayerOrder
    end

    function XRiftManager.GetIsNewLayerIdTrigger() --(Trigger)触发后关闭
        if NewLayerIdTrigger then
            local tempId = NewLayerIdTrigger
            NewLayerIdTrigger = nil
            return tempId
        end
    end

    function XRiftManager.SetNewLayerTrigger(newFightLayerId)
        NewLayerIdTrigger = newFightLayerId
    end

    function XRiftManager.GetIsFirstPassChapterTrigger() --(Trigger)触发后关闭
        if IsFirstPassChapterTrigger then
            local tempId = IsFirstPassChapterTrigger
            IsFirstPassChapterTrigger = nil
            return tempId
        end
    end

    function XRiftManager.SetFirstPassChapterTrigger(fightLayerId)
        IsFirstPassChapterTrigger = fightLayerId
    end

    function XRiftManager.GetIsLayerSettleTrigger() --(Trigger)触发后关闭
        if IsLayerSettleTrigger then
            local tempData = IsLayerSettleTrigger
            IsLayerSettleTrigger = nil
            return tempData
        end
    end

    function XRiftManager.SetLayerSettleTrigger(fun)
        IsLayerSettleTrigger = fun
    end

    function XRiftManager.GetIsEnterNextFightTrigger() --(Trigger)触发后关闭
        if IsEnterNextFightTrigger then
            local tempData = IsEnterNextFightTrigger
            IsEnterNextFightTrigger = nil
            return tempData
        end
    end

    function XRiftManager.SetEnterNextFightTrigger(fun)
        IsEnterNextFightTrigger = fun
    end

    function XRiftManager.GetIsTriggerJumpOpen() --(Trigger)触发后关闭
        if IsJumpOpenTrigger then
            local tmpData = IsJumpOpenTrigger
            IsJumpOpenTrigger = nil
            return tmpData
        end
    end

    -- 是否触发了高盖低机制
    function XRiftManager.GetIsTriggerJumpRes() --(Trigger)触发后关闭
        if IsJumpResTrigger then
            local tmpData = IsJumpResTrigger
            IsJumpResTrigger = nil
            return tmpData
        end
    end

    -- 设置每日提示
    local SetDayTip = function (isSelect)
        local key = "RiftDayTipLuckValue"..XPlayer.Id
        if not isSelect then
            XSaveTool.RemoveData(key)
        else
            local updateTime = XTime.GetSeverTomorrowFreshTime()
            XSaveTool.SaveData(key, updateTime)
        end
    end

    -- 今天是否可以弹每日提示
    local GetIsNewDayUpdate = function ()
        local key = "RiftDayTipLuckValue"..XPlayer.Id
        local data = XSaveTool.GetData(key)

        if not data then
            return true
        end

        return data ~= XTime.GetSeverTomorrowFreshTime()
    end

    -- 检测每日提示并继续
    function XRiftManager.CheckDayTipAndDoFun(xChapter, doFun)
        if XRiftManager.IsFuncUnlock(XRiftConfig.FuncUnlockId.LuckyStage) and xChapter:GetLuckValueProgress() >= 1 and GetIsNewDayUpdate() then
            local titile = CS.XTextManager.GetText("TipTitle")
            local content = CS.XTextManager.GetText("RiftLuckValueTip")
            local hitInfo = 
            {
                SetHintCb = SetDayTip,
                Status = false
            }
            XUiManager.DialogHintTip(titile, content, nil, nil , doFun, hitInfo)
        else
            doFun()
        end
    end

    function XRiftManager.InitMultiTeamData()
        if not XPlayer or not XPlayer.Id then
            return
        end
        
        -- 队伍数据会在实例XRiftTeam更新时自动保存到本地
        local data = {}
        for i = 1, CurrentConfig.AttrLevelSetCount do
            data[i] = XRiftTeam.New(i)
        end
        MultiTeamData = data
    end

    function XRiftManager.GetMultiTeamData()
        if XTool.IsTableEmpty(MultiTeamData) then
            XRiftManager.InitMultiTeamData()
        end
        return MultiTeamData
    end

    function XRiftManager.GetSingleTeamData()
        if XTool.IsTableEmpty(SingleTeamData) then
            SingleTeamData = XRiftTeam.New(-1)
        end
        return SingleTeamData
    end

    function XRiftManager.ChangeMultiTeamData(data)
        MultiTeamData = data
    end

    function XRiftManager.CheckRoleInTeam(roleId)
        for teamIndex, xTeam in pairs(MultiTeamData) do
            for i = 1, 3 do
                local idInTeam = xTeam:GetEntityIdByTeamPos(i)
                if roleId == idInTeam then
                    return true, xTeam, i
                end
            end
        end
        return false  
    end

    -- 检查该队伍是否有关卡进度
    function XRiftManager.CheckRoleInMultiTeamLock(xTeam)
        if not xTeam or not CurrSelectRiftStageGroup then
            return
        end

        local xStageGroup = CurrSelectRiftStageGroup
        if xStageGroup:GetParent():CheckNoneData() then -- 没有战斗数据
            return false
        end

        local index = xTeam:GetId()
        local xStage = xStageGroup:GetAllEntityStages()[index]
        return xStage:CheckHasPassed()
    end

    function XRiftManager.AddMultiTeamMember(teamIndex, pos, xRole)
        MultiTeamData[teamIndex]:UpdateEntityTeamPos(xRole:GetId(), pos, true) -- 如果存在会替换
    end

    function XRiftManager.RemoveTeamMember(teamIndex, pos)
        MultiTeamData[teamIndex]:UpdateEntityTeamPos(nil, pos, true)
    end

    function XRiftManager.SwapMultiTeamMember(aTeamIndex, aPos, bTeamIndex, bPos)
        local aRoleId = MultiTeamData[aTeamIndex]:GetEntityIdByTeamPos(aPos)
        local bRoleId = MultiTeamData[bTeamIndex]:GetEntityIdByTeamPos(bPos)

        MultiTeamData[aTeamIndex]:UpdateEntityTeamPos(bRoleId, aPos, true)
        MultiTeamData[bTeamIndex]:UpdateEntityTeamPos(aRoleId, bPos, true)
    end

    function XRiftManager.InitStageInfo()
        local allConfigs = XRiftConfig.GetAllConfigs(XRiftConfig.TableKey.RiftStage)
        for k, config in pairs(allConfigs) do
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(config.StageId)
            stageInfo.Type = XDataCenter.FubenManager.StageType.Rift
        end
    end

    function XRiftManager.InitChapter()
        local allConfigs = XRiftConfig.GetAllConfigs(XRiftConfig.TableKey.RiftChapter)
        for k, config in pairs(allConfigs) do
            local XRiftChapter = XRiftChapter.New(config)
            ChapterDicById[config.Id] = XRiftChapter
        end
    end

    function XRiftManager.InitFightLayer()
        local allConfigs = XRiftConfig.GetAllConfigs(XRiftConfig.TableKey.RiftLayer)
        for k, config in pairs(allConfigs) do
            local XRiftFightLayer = XRiftFightLayer.New(config)
            FightLayerDicById[config.Id] = XRiftFightLayer
        end
    end

    function XRiftManager.GetEntityChapterById(id)
        return ChapterDicById[id]
    end

    function XRiftManager.GetEntityFightLayerById(id)
        return FightLayerDicById[id]
    end

    function XRiftManager.CheckIsHasFightLayerRedPoint()
        for k, xFightLayer in pairs(FightLayerDicById) do
            if xFightLayer:CheckRedPoint() then
                return true
            end
        end
    end

    -- 创建【区域-作战层-关卡节点-关卡】关系链,所有的关系必须在初始化所有实例后才能建立
    -- tips:双向关系链仅有【区域 - 作战层】1条
    -- 不构建【关卡节点 - 关卡】，【关卡 - 怪物】，【怪物 - 词缀】双向关系链，因为策划说他们子节点可重复配置，是单向关系
    function XRiftManager.CreateChapterLayerRelationshipChain()
        -- 作战层(向上建立的关系都是双向关系)
        for k, xFightLayer in pairs(FightLayerDicById) do
            xFightLayer:InitRelationshipChainUp()
        end
    end

    -- 【关卡库】【怪物库】【词缀库】是随机的，需要提供重置接口，且他们的关系都为单向向下关系
    -- 重置【作战层 - 关卡节点】关系链，点击重置按钮或初始化关系链调用（都是服务端下发数据后）
    function XRiftManager.ResetOrCreateStageGroupRelationshipChain(data)
        if not data or not data.LayerId or data.LayerId <= 0 then
            return
        end

        local xFightLayer = FightLayerDicById[data.LayerId]
        xFightLayer:InitRelationshipChainDown(data.NodeDatas)
        xFightLayer:AddRecordPluginDrop(data.PluginDropRecords)
    end

    -- 重置按钮点击后清除随机数据。【作战层 - 关卡节点】【关卡 - 怪物(库)】【怪物 - 词缀】
    function XRiftManager.ClearStageGroupRelationshipChain()
        for k, xFightLayer in pairs(FightLayerDicById) do
            xFightLayer:ClearRelationShipChainDown()
        end

        for k, xMonster in pairs(MonsterDicById) do
            xMonster:ClearAffixs()
        end
    end
    
    -- 生成大秘境专用角色实例
    function XRiftManager.GenerateRoleData()
        local characters = XDataCenter.CharacterManager.GetOwnCharacterList()
        -- 拥有角色
        for _, character in pairs(characters) do
            XRiftManager.AddNewRole(character)
        end
        -- 机器人
        for _, config in pairs(XRiftConfig.GetAllConfigs(XRiftConfig.TableKey.RiftCharacterAndRobot)) do
            if config.RobotId and config.RobotId > 0 then
                XRiftManager.AddNewRole(XRobot.New(config.RobotId))
            end
        end
    end

    --玩家角色增加时
    function XRiftManager.OnCharacterAdd(character)
        if character == nil then return end
        if RoleDicById[character.Id] then return end
        -- 防止错误判断Roles，新增角色时先调用一遍初始化
        if XTool.IsTableEmpty(AllRoles) then
            XRiftManager.GenerateRoleData()
        end
        XRiftManager.AddNewRole(character)
    end
 
    function XRiftManager.AddNewRole(roleData)
        -- 如果已经存在，直接不处理
        if RoleDicById[roleData.Id] then return end
        local role = XRiftRole.New(roleData)
        table.insert(AllRoles, role)
        RoleDicById[role:GetId()] = role
    end

    function XRiftManager.GetEntityRoleById(id)
        if XTool.IsTableEmpty(AllRoles) then
            XRiftManager.GenerateRoleData()
        end
        return RoleDicById[id]
    end

    function XRiftManager.GetEntityRoleListByCharacterId(id)
        if XTool.IsTableEmpty(AllRoles) then
            XRiftManager.GenerateRoleData()
        end
        local res = {}
        for k, xRole in pairs(RoleDicById) do
            if xRole:GetCharacterId() == id then
                table.insert(res, xRole)
            end
        end

        return res
    end

    function XRiftManager.GetEntityRoleListByCharaType(charaType)
        if XTool.IsTableEmpty(AllRoles) then
            XRiftManager.GenerateRoleData()
        end
        if not charaType then
            return AllRoles
        end

        local result = {}
        for _, xRole in ipairs(AllRoles) do
            if xRole:GetCharacterType() == charaType then
                table.insert(result, xRole)
            end
        end
        return result
    end

    function XRiftManager.GenerateMonsterData()
        local allConfigs = XRiftConfig.GetAllConfigs(XRiftConfig.TableKey.RiftMonster)
        for k, config in pairs(allConfigs) do
            local xMonster = XRiftMonster.New(config)
            MonsterDicById[config.Id] = xMonster
        end
    end

    function XRiftManager.GetEntitytMonsterById(id)
        return MonsterDicById[id]
    end

    function XRiftManager.GetRandomCDLeftTime()
        local nowTime = XTime.GetServerNowTimestamp()
        return TargetCanResetTimestamp - nowTime
    end

    function XRiftManager.GetResetCountkey()
        return "RiftResetCount"..XPlayer.Id
    end

    function XRiftManager.GetResetCDkey()
        return "RiftResetCD"..XPlayer.Id
    end

    function XRiftManager.ClearResetCDAndCount()
        XSaveTool.SaveData(XRiftManager.GetResetCountkey(), CurrentConfig.ResetNoCdTimes)
        XSaveTool.SaveData(XRiftManager.GetResetCDkey(), CurrentConfig.ResetCdIncrease)
    end

    function XRiftManager.CheckRequestResetRandom()
        local nowTime = XTime.GetServerNowTimestamp() -- 使用目标时间点做标记来替代计时器
        local leftNoneCdResetCount = XSaveTool.GetData(XRiftManager.GetResetCountkey())
        leftNoneCdResetCount = (not leftNoneCdResetCount) and CurrentConfig.ResetNoCdTimes or leftNoneCdResetCount -- 做1次判空处理
        if leftNoneCdResetCount > 0 then
            leftNoneCdResetCount = leftNoneCdResetCount - 1
            XSaveTool.SaveData(XRiftManager.GetResetCountkey(), leftNoneCdResetCount)
            if leftNoneCdResetCount == 0 then -- 如果保存的时候次数已经是0了，说明这是你最后1次机会了。先上CD，下把再按就直接检测CD
                TargetCanResetTimestamp = nowTime + CurrentConfig.ResetCdIncrease
                XSaveTool.SaveData(XRiftManager.GetResetCDkey(), CurrentConfig.ResetCdIncrease)
            end
            return true
        else
            local leftTime = TargetCanResetTimestamp - nowTime
            if leftTime > 0 then
                return false
            end
            
            local resetCD = XSaveTool.GetData(XRiftManager.GetResetCDkey())
            resetCD = (not resetCD) and CurrentConfig.ResetCdIncrease or resetCD
            if resetCD < CurrentConfig.ResetCdMax then -- CD时间单位是秒。
                resetCD = resetCD + CurrentConfig.ResetCdIncrease 
                resetCD = resetCD > CurrentConfig.ResetCdMax and CurrentConfig.ResetCdMax or resetCD -- CD上限处理
                XSaveTool.SaveData(XRiftManager.GetResetCDkey(), resetCD)
            end
            TargetCanResetTimestamp = nowTime + resetCD
            return true
        end

    end

    function XRiftManager.GetCurrPlayingChapter()
        for k, xChapter in pairs(ChapterDicById) do
            local curPlayingLayer = xChapter:GetCurPlayingFightLayer()
            if curPlayingLayer then
                return xChapter, curPlayingLayer
            end
        end
    end

    -- 获取上一次进入的作战层
    function XRiftManager.GetLastRecordFightLayer()
        local key = "LastFightLayer"..XPlayer.Id .. "ActivityId".. CurrentConfig.Id
        return XSaveTool.GetData(key)
    end

    -- 上一次进入的作战层
    function XRiftManager.SaveLastFightLayer(XFightLayer)
        local key = "LastFightLayer"..XPlayer.Id .. "ActivityId".. CurrentConfig.Id
        local data = 
        {
            ChapterId = XFightLayer:GetParent():GetId(),
            FightLayerId = XFightLayer:GetId() 
        }
        XSaveTool.SaveData(key, data)
    end

    function XRiftManager.GetActivityStartTime()
        return StartTime
    end

    function XRiftManager.GetActivityEndTime()
        return EndTime
    end

    function XRiftManager.RefreshWholeData(data)
        XRiftManager.RefreshMaxLoad(data.PluginPeakLoad) -- 角色负载上限
        XRiftManager.RefreshSweepTimes(data.SweepTimes)
    end

    function XRiftManager.RefreshMaxLoad(maxLoad)
        MaxLoad = maxLoad
    end
    
    function XRiftManager.RefreshSweepTimes(sweepTimes)
        SweepTimes = sweepTimes
    end
    
    function XRiftManager.GetMaxLoad()
        return MaxLoad
    end

    function XRiftManager.GetSweepLeftTimes()
        return  CurrentConfig.DailySweepTimes - SweepTimes
    end

    -- 请求刷新作战层内数据（开始/重置）
    function XRiftManager.RiftStartLayerRequest(layerId, cb)  
        XNetwork.Call("RiftStartLayerRequest", {LayerId = layerId}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            
            XRiftManager.RefreshRandomDataByServer(res.LayerData)
            if cb then
                cb()
            end
        end)
    end

    -- 请求刷新作战层内数据（开始/重置）附带检测CD
    function XRiftManager.RiftStartLayerRequestWithCD(layerId, cb)
        if XRiftManager.CheckRequestResetRandom() then
            XRiftManager.RiftStartLayerRequest(layerId, cb)
        end
    end

    -- 请求下发幸运关信息
    function XRiftManager.RiftStartLuckyNodeRequest(cb)    
        XNetwork.Call("RiftStartLuckyNodeRequest", nil, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XRiftManager.RefreshChapterData({[1] = res.ChapterData})
            if cb then
                cb()
            end
        end)
    end
 
    -- 请求中止该层作战
    function XRiftManager.RiftStopLayerRequest(cb)
        XNetwork.Call("RiftStopLayerRequest", nil, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            -- 弹出层结算
            local currXFightLayer = LastFightXStage and LastFightXStage:GetParent():GetParent()
            if currXFightLayer and currXFightLayer:CheckIsOwnFighting() then -- 放弃作战时，只有打过任意一关才能结算
                XLuaUiManager.Open("UiRiftSettleWin", currXFightLayer:GetId(), nil, true)
            end

            -- 清空数据
            XRiftManager.RefreshRandomDataByServer(res.LayerData)
            if cb then
                cb()
            end
        end)
    end

    -- 请求扫荡
    function XRiftManager.RiftSweepLayerRequest(layerId, cb)
        XNetwork.Call("RiftSweepLayerRequest", {LayerId = layerId}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            -- 区域信息
            XRiftManager.RefreshChapterData({[1] = res.ChapterData})
            -- 解锁插件
            XRiftManager.UnlockedPluginByDrop(res.PluginDropRecords)
            -- 记录当前层累计的插件掉落
            local xFightLayer = FightLayerDicById[layerId]
            xFightLayer:AddRecordPluginDrop(res.PluginDropRecords)
            SweepTimes = SweepTimes + 1
            -- 扫荡也算作作战层
            local layer = XRiftManager.GetEntityFightLayerById(layerId)
            local tempSg = layer and layer:GetAllStageGroups()[1]
            LastFightXStage = tempSg and tempSg:GetAllEntityStages()[1] or LastFightXStage
            -- 弹层结算
            XLuaUiManager.Open("UiRiftSettleWin", layerId, nil, true, true)
        
            if cb then
                cb()
            end
        end)
    end

    -- 请求装备/卸载角色插件
    function XRiftManager.RiftSetCharacterPluginsRequest(xRole, pluginIdList, cb)
        local data =
        {
            CharacterId = not xRole:GetIsRobot() and xRole:GetId() or nil,
            RobotId = xRole:GetIsRobot() and xRole:GetId() or nil,
            PluginIds = pluginIdList,
        }
        XNetwork.Call("RiftSetCharacterPluginsRequest", data, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            -- 装备成功 刷新角色插件
            xRole:SyncPlugInIds(pluginIdList)
            if cb then
                cb()
            end
        end)
    end

    -- 请求更改队伍对应模板
    function XRiftManager.RiftSetTeamRequest(xTeam, newChangeTempId, cb)
        if newChangeTempId == xTeam:GetAttrTemplateId() then
            return
        end
        
        for i = 1, CurrentConfig.AttrLevelSetCount do
            local tempTeam = XRiftManager.GetMultiTeamData()[i]
            TeamDatas[i] = {Id = i, AttrSetId = tempTeam and tempTeam:GetShowAttrTemplateId()}
        end
        local teamId = xTeam:GetId()
        local currAttrTeamData = TeamDatas[teamId]
        currAttrTeamData.AttrSetId = newChangeTempId

        XNetwork.Call("RiftSetTeamRequest", {TeamDatas = TeamDatas}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            xTeam:SetAttrTemplateId(newChangeTempId)
            
            if cb then
                cb()
            end
        end)
    end
    
    function XRiftManager.OpenFightLoading(stageId)
        if CurrSelectRiftStageGroup:GetType() == XRiftConfig.StageGroupType.Multi then
            XLuaUiManager.Open("UiRiftLoading")
        else
            XDataCenter.FubenManager.OpenFightLoading(stageId)
        end
    end

    function XRiftManager.CloseFightLoading(stageId)
        if XLuaUiManager.IsUiLoad("UiRiftLoading") then
            XLuaUiManager.Remove("UiRiftLoading")
        else
            XDataCenter.FubenManager.CloseFightLoading(stageId)
        end
    end

    -- 战斗胜利 & 奖励界面
    function XRiftManager.DoShowReward(winData)
        local currFightStageGroup = LastFightXStage:GetParent()
        local currFightLayer = currFightStageGroup:GetParent()
        local xStageList = currFightStageGroup:GetAllEntityStages()
        local nextStageGroup = nil -- 是否仍有可进行连续战斗的下一关卡节点(有下一个【关卡】或者有下一个【关卡节点】时，就可以连续战斗)
        local nextStageIndex = nil -- 需要继续进行战斗的关卡在关卡节点中的序号
        local curStageIndex = LastFightXStage:GetIndex() -- 当前战斗的stage在父节点stageList的顺序下标
        if LastFightXStage.StageId == winData.SettleData.StageId then
            if curStageIndex < #xStageList then
                nextStageGroup = currFightStageGroup
                nextStageIndex = curStageIndex + 1
            elseif curStageIndex == #xStageList then
                local currStageGroupIndex = currFightStageGroup.NodePositionIndex
                local nxStageGroup = currFightLayer:GetAllStageGroups()[currStageGroupIndex + 1]
                if nxStageGroup then    -- 如果打到下一个关卡节点，从第一个关卡开始打
                    nextStageGroup = nxStageGroup
                    nextStageIndex = 1
                end
            end
        end

        local riftSettleResult = winData.SettleData.RiftSettleResult
        -- 刷新当前Stage的信息
        LastFightXStage:SetHasPassed(true) -- 通关了一定是pass，由于尽量减少服务器发放信息，这里就手动设置了
        LastFightXStage:SetPassTime(riftSettleResult.PassTime)
        -- 刷新战斗结算后的区域信息
        local chapterData = 
        {
            [1] = riftSettleResult.ChapterData
        }
        XDataCenter.RiftManager.RefreshChapterData(chapterData)
        -- 刷新当前跃升信息
        local xStageGroup = LastFightXStage:GetParent()
        local fightLayer = xStageGroup:GetParent()
        if xStageGroup:GetType() == XRiftConfig.StageGroupType.Zoom then
            fightLayer:SetJumpCount(riftSettleResult.JumpLayerRecord.AddOrderMax)
        end
        -- 记录当前层累计的插件掉落
        fightLayer:AddRecordPluginDrop(riftSettleResult.PluginDropRecords)
        -- 解锁插件
        XRiftManager.UnlockedPluginByDrop(riftSettleResult.PluginDropRecords)
        -- 如果多队伍完成全部压制，返回时不再出现多队伍编辑界面
        local isAllClear = true
        for k, xStage in pairs(xStageList) do
            if not xStage:CheckHasPassed() then
                isAllClear = false
            end
        end
        if isAllClear or currFightLayer:CheckNoneData() then
            XLuaUiManager.Remove("UiRiftDeploy")
        end
        -- 打开结算界面
        XLuaUiManager.Open("UiRiftSettlePlugin", winData.SettleData, nextStageGroup, nextStageIndex)
    end

    function XRiftManager.ShowReward()
        -- nothing
        -- 不走通用结算，改为在关卡内结算
    end

    function XRiftManager.EnterFight(xTeam)
        if not xTeam then -- 如果没传xteam，则根据上一次点击的stageGroup，判断当前层类型，选择对应的队伍自动进入该stageGroup的第一个stage
            if CurrSelectRiftStageGroup:GetType() == XRiftConfig.StageGroupType.Multi then
                xTeam = XRiftManager.GetMultiTeamData()[1]
            else
                xTeam = XRiftManager.GetSingleTeamData()
            end
        end

        local index = math.abs(xTeam:GetId()) --由于单关卡的队伍id是-1，但是它仅有1个关卡，所以如果是-1也传1
        LastFightXStage = CurrSelectRiftStageGroup:GetAllEntityStages()[index]
        -- 进入战斗层，记录进入打个卡(为了避免通过下一层战斗直接进入战斗而没打开切层列表，这里也记录一遍)
        local currLayer = CurrSelectRiftStageGroup:GetParent()
        XDataCenter.RiftManager.SaveLastFightLayer(currLayer)
        currLayer:SaveFirstEnter()
        XDataCenter.FubenManager.EnterRiftFight(xTeam, CurrSelectRiftStageGroup, index)
    end

    --战斗是否自动退出
    function XRiftManager.CheckAutoExitFight(stageId)
        return false
    end
    -------------------------------------------------- 5加点 begin --------------------------------------------------

    function XRiftManager.GenerateAttrTemplate()
        -- 生成属性模板实例
        for id = 1, XRiftConfig.AttrTemplateCnt do
            AttrTemplateDicById[id] = XRiftAttributeTemplate.New(id)
        end
    end

    function XRiftManager.RefreshAttrTemplate(riftData)
        TotalAttrLevel = riftData.TotalAttrLevel
        XRiftManager.RefreshAttrLevelMax(riftData.AttrLevelMax)

        for _, attrSet in ipairs(riftData.AttrSets) do
            local xAttrTemplate = XRiftAttributeTemplate.New(attrSet.Id, attrSet.AttrLevels)
            AttrTemplateDicById[attrSet.Id] = xAttrTemplate
        end
    end

    function XRiftManager.RefreshAttrLevelMax(attrLevelMax)
        AttrLevelMax = attrLevelMax
    end

    function XRiftManager.GetAttrLevelMax()
        return AttrLevelMax
    end

    function XRiftManager.GetTotalAttrLevel()
        return TotalAttrLevel
    end

    -- 获取队伍加点模板
    function XRiftManager.GetAttrTemplate(id)
        if id == nil then id = XRiftConfig.DefaultAttrTemplateId end -- 不传参是使用默认加点
        return AttrTemplateDicById[id]
    end

    -- 获取默认模板属性加点的属性等级
    function XRiftManager.GetDefaultTemplateAttrLevel(attrId)
        local attrTemplate = XRiftManager.GetAttrTemplate()
        return attrTemplate:GetAttrLevel(attrId)
    end

    function XRiftManager.GetAttributeCost(attrLevel)
        if attrLevel <= TotalAttrLevel then
            return 0
        end

        local attrCostCfgs = XRiftConfig.GetAllConfigs(XRiftConfig.TableKey.RiftTeamAttributeCost)
        local cost = 0 
        for i = TotalAttrLevel + 1, attrLevel do
            if attrCostCfgs[i] then 
                cost = cost + attrCostCfgs[i].Cost
            end
        end
        return cost
    end

    -- 获取可预览加点的总等级:当前已购买等级 + 可购买等级
    function XRiftManager.GetCanPreviewAttrAllLevel()
        local attrCostCfgs = XRiftConfig.GetAllConfigs(XRiftConfig.TableKey.RiftTeamAttributeCost)
        local ownCnt = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.RiftGold)
        local attrIndex = TotalAttrLevel
        local const = 0
        while(true)
        do
            local nextIndex = attrIndex + 1
            if attrCostCfgs[nextIndex] and (ownCnt >= const + attrCostCfgs[nextIndex].Cost) then
                const = const + attrCostCfgs[nextIndex].Cost
                attrIndex = nextIndex
            else
                break
            end
        end

        return attrIndex
    end

    -- 请求保存属性模板
    function XRiftManager.RequestSetAttrSet(attrTemplate, cb)
        local allLevel = attrTemplate:GetAllLevel()
        local attrList = XTool.Clone(attrTemplate.AttrList)
        local isClear = attrTemplate.Id ~= XRiftConfig.DefaultAttrTemplateId and allLevel == 0 -- 默认模板不能设置为nil
        local request = { AttrSet = { Id = attrTemplate.Id, AttrLevels = nil } }
        if not isClear then
            request.AttrSet.AttrLevels = attrList
        end

        XNetwork.Call("RiftSetAttrSetRequest", request, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            -- 更新本地模板
            local attrTemp = AttrTemplateDicById[attrTemplate.Id]
            if attrTemp then
                for _, attr in ipairs(attrList) do
                    attrTemp:SetAttrLevel(attr.Id, attr.Level)
                end
            else
                AttrTemplateDicById[attrTemplate.Id] = XRiftAttributeTemplate.New(attrTemplate.Id, attrList)
            end

            -- 更新已购买点数
            if allLevel > TotalAttrLevel then
                TotalAttrLevel = allLevel 
            end
            
            if cb then
                cb()
            end
        end)
    end

    function XRiftManager.GetBuyAttrRedSaveKey()
        return XPlayer.Id .. "_XRiftManager_BuyAttrRed_Key"
    end

    -- 是否显示购买属性红点
    function XRiftManager.IsBuyAttrRed()
        local ownCnt = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.RiftGold)
        local recordCnt = XSaveTool.GetData(XRiftManager.GetBuyAttrRedSaveKey())
        if recordCnt == nil or ownCnt > recordCnt then
            local attrCostCfgs = XRiftConfig.GetAllConfigs(XRiftConfig.TableKey.RiftTeamAttributeCost)
            local nextAttrLevel = TotalAttrLevel + 1
            local canBuy = attrCostCfgs[nextAttrLevel] and (ownCnt >= attrCostCfgs[nextAttrLevel].Cost)
            return canBuy
        elseif ownCnt < recordCnt then
            XRiftManager.CloseBuyAttrRed()
        end

        return false
    end

    -- 关闭购买属性红点
    function XRiftManager.CloseBuyAttrRed()
        local ownCnt = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.RiftGold)
        XSaveTool.SaveData(XRiftManager.GetBuyAttrRedSaveKey(), ownCnt)
    end

    -------------------------------------------------- 5加点 end --------------------------------------------------

    -------------------------------------------------- 6插件背包 begin --------------------------------------------------

    function XRiftManager.GeneratePluginData()
        local pluginCfgs = XRiftConfig.GetAllConfigs(XRiftConfig.TableKey.RiftPlugin)
        for _, config in ipairs(pluginCfgs) do
            local xPlugin = XRiftPlugin.New(config)
            AllPluginDicById[config.Id] = xPlugin
        end
    end

    -- 活动协议/作弊指令 解锁插件
    function XRiftManager.UnlockedPlugin(unlockedPluginIds)
        if unlockedPluginIds == nil then return end

        for _, pluginId in ipairs(unlockedPluginIds) do
            XRiftManager.SetPluginHave(pluginId)
        end
    end

    -- 战斗结算掉落插件 解锁
    function XRiftManager.UnlockedPluginByDrop(pluginDropRecords)
        for _, dropPlugin in ipairs(pluginDropRecords) do
            local xPluginDrop = AllPluginDicById[dropPlugin.PluginId]
            -- 1 先检测生成蓝点
            local charId = xPluginDrop.Config.CharacterId
            if dropPlugin.DecomposeCount <= 0 and XTool.IsNumberValid(charId) then -- 通用插件不会显示蓝点,已获得的插件也不会显示蓝点
                local setRed = true
                for k, xPluginInBag in pairs(AllPluginDicById) do
                    if xPluginInBag:GetHave() and xPluginInBag.Config.Type == xPluginDrop.Config.Type and xPluginInBag:GetStar() >= xPluginDrop:GetStar() then
                        setRed = false -- 如果掉落的插件 背包已经存在更高星数的同类型插件了 也不显示蓝点
                        break
                    end
                end
                if setRed then
                    xPluginDrop:SetCharacterUpgradeRedpoint(true)
                end
            end
            -- 2 再设置掉落获取
            xPluginDrop:SetHave()
        end
    end

    function XRiftManager.GetOwnPluginList(starSelectList)
        local pluginList = {}
        for _, plugin in pairs(AllPluginDicById) do
            local star = plugin:GetStar()
            if starSelectList[star] and plugin:GetHave() and not plugin:GetIsDisplay() then 
                table.insert(pluginList, plugin)
            end
        end

        table.sort(pluginList, function(a, b)
            if a:GetStar() ==  b:GetStar() then 
                return a:GetId() > b:GetId()
            else
                return a:GetStar() > b:GetStar()
            end
        end)

        return pluginList
    end

    function XRiftManager.GetAllPluginList(starSelectList)
        local pluginList = {}
        for _, plugin in pairs(AllPluginDicById) do
            local star = plugin:GetStar()
            if starSelectList[star] and not plugin:GetIsDisplay() then 
                table.insert(pluginList, plugin)
            end
        end

        table.sort(pluginList, function(a, b)
            local isHaveA = a:GetHave()
            local isHaveB = b:GetHave()

            if isHaveA == isHaveB then
                if a:GetStar() ==  b:GetStar() then 
                    return a:GetId() > b:GetId()
                else
                    return a:GetStar() > b:GetStar()
                end
            else
                return isHaveA
            end
        end)

        return pluginList
    end

    function XRiftManager.GetPluginHaveAndAllCnt()
        local haveCnt = 0
        local allCnt = 0
        for _, plugin in pairs(AllPluginDicById) do
            if not plugin:GetIsDisplay() then 
                if plugin:GetHave() then 
                    haveCnt = haveCnt + 1
                end
                allCnt = allCnt + 1
            end
        end
        return haveCnt, allCnt
    end

    function XRiftManager.GetPlugin(pluginId)
        return AllPluginDicById[pluginId]
    end
    function XRiftManager.GetAllPlugin()
        return AllPluginDicById
    end

    function XRiftManager.SetPluginHave(pluginId)
        AllPluginDicById[pluginId]:SetHave()
    end

    function XRiftManager.GetPluginSaveKey(pluginId)
        return XPlayer.Id .. "_XRiftManager_PluginRed_" .. pluginId
    end

    function XRiftManager.IsPluginRed(pluginId)
        local plugin = XRiftManager.GetPlugin(pluginId)
        if not plugin:GetHave() then 
            return false
        end

        local saveKey = XRiftManager.GetPluginSaveKey(pluginId)
        local isRed = XSaveTool.GetData(saveKey) == nil
        return isRed
    end

    function XRiftManager.ClosePluginRed(pluginId)
        local plugin = XRiftManager.GetPlugin(pluginId)
        if not plugin:GetHave() then 
            return
        end

        local saveKey = XRiftManager.GetPluginSaveKey(pluginId)
        XSaveTool.SaveData(saveKey, true)
    end

    function XRiftManager.IsPluginBagRed()
        for _, plugin in pairs(AllPluginDicById) do
            if XRiftManager.IsPluginRed(plugin:GetId())  then
                return true
            end
        end
        return false
    end

    function XRiftManager.ClosePluginBagRed()
        for _, plugin in pairs(AllPluginDicById) do
            if plugin:GetHave() then
                XRiftManager.ClosePluginRed(plugin:GetId())
            end
        end
    end

    -------------------------------------------------- 6插件背包 end --------------------------------------------------

    -------------------------------------------------- 7任务 begin --------------------------------------------------

    function XRiftManager.GetTaskGroupIdList()
        local config = XRiftConfig.GetCfgByIdKey(XRiftConfig.TableKey.RiftActivity, ActivityId)
        return config.TaskGroupId
    end

    -- 检查所有任务是否有奖励可领取
    function XRiftManager.CheckTaskCanReward()
        local groupIdList = XRiftManager.GetTaskGroupIdList()
        for _, groupId in pairs(groupIdList) do
            if XDataCenter.TaskManager.CheckLimitTaskList(groupId) then
                return true
            end
        end
        return false
    end

    -- 获取任务按钮显示的任务
    function XRiftManager.GetBtnShowTask()
        local finish = XDataCenter.TaskManager.TaskState.Finish
        local groupIdList = XRiftManager.GetTaskGroupIdList()
        for index, groupId in ipairs(groupIdList) do
            local taskList = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(groupId)
            for _, taskData in pairs(taskList) do
                if taskData.State ~= finish then
                    local taskCfgs = XRiftConfig.GetAllConfigs(XRiftConfig.TableKey.RiftTask)
                    local config = XDataCenter.TaskManager.GetTaskTemplate(taskData.Id)
                    return taskCfgs[index].Name, config.Desc
                end
            end
        end

        return XUiHelper.GetText("PokerGuessingTask"), XUiHelper.GetText("DlcHuntTaskFinish")    
    end

    -------------------------------------------------- 7任务 end --------------------------------------------------

    -------------------------------------------------- 8商店 begin --------------------------------------------------

    function XRiftManager.GetActivityShopIds()
        return XRiftConfig.GetActivityShopIds(ActivityId)
    end

    function XRiftManager.OpenUiShop()
        if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon) 
            or XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopActive) then
            
            local shopIds = XRiftManager.GetActivityShopIds()
            XShopManager.GetShopInfoList(shopIds, function()
                XLuaUiManager.Open("UiRiftShop")
                XRiftManager.CloseShopRed()
            end, XShopManager.ActivityShopType.RiftShop)
        end
    end

    function XRiftManager.GetPluginShopGoodList()
        if PluginShopGoodList == nil then
            PluginShopGoodList = {}
            local goodCfgs = XRiftConfig.GetAllConfigs(XRiftConfig.TableKey.RiftPluginShopGoods)
            for _, goodCfg in ipairs(goodCfgs) do
                if goodCfg.ActivityId == ActivityId then
                    table.insert(PluginShopGoodList, goodCfg)
                end
            end
        end
        return PluginShopGoodList
    end

    function XRiftManager.GetPluginShopTagList()
        local tagDic = {}
        local tagList = { ScreenAll }

        local goodList = XRiftManager.GetPluginShopGoodList()
        for _, good in pairs(goodList) do
            local plugin = XRiftManager.GetPlugin(good.PluginId)
            local tag = plugin:GetTag()
            if tagDic[tag] == nil then
                tagDic[tag] = true
                table.insert(tagList, tag)
            end
        end

        return tagList
    end

    local PluginShopSortFunc = function(goodA, goodB)
        local pluginA = XRiftManager.GetPlugin(goodA.PluginId)
        local isSellOutA = pluginA:GetHave()
        local pluginB = XRiftManager.GetPlugin(goodB.PluginId)
        local isSellOutB = pluginB:GetHave()

        if isSellOutA == isSellOutB then
            return goodA.Id < goodB.Id
        else
            return isSellOutB
        end
    end

    function XRiftManager.FilterPluginShopGoodList(selectTag)
        local goodList = {}
        for _, good in pairs(PluginShopGoodList) do
            local plugin = XRiftManager.GetPlugin(good.PluginId)
            local tag = plugin:GetTag()
            if selectTag == ScreenAll or tag == selectTag then
                table.insert(goodList, good)
            end
        end

        table.sort(goodList, PluginShopSortFunc)
        return goodList
    end

    function XRiftManager.RequestBuyPlugin(id, cb)
        local request = { GoodsId = id }
        XNetwork.Call("RiftBuyPluginRequest", request, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            XRiftManager.SetPluginHave(res.AddedPluginId)
            cb()
        end)
    end

    function XRiftManager.GetShopRedSaveKey()
        return XPlayer.Id .. "_XRiftManager_ShopRed"
    end

    function XRiftManager.IsShopRed()
        local ownCnt = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.RiftCoin)
        if ownCnt > 0 then
            local recordTime = XSaveTool.GetData(XRiftManager.GetShopRedSaveKey())
            if recordTime then
                local now = XTime.GetServerNowTimestamp()
                return not XTime.IsToday(now, recordTime)
            else
                return true
            end
        end

        return false
    end

    function XRiftManager.CloseShopRed()
        local now = XTime.GetServerNowTimestamp()
        XSaveTool.SaveData(XRiftManager.GetShopRedSaveKey(), now)
    end

    -------------------------------------------------- 8商店 end --------------------------------------------------


    -------------------------------------------------- 9排行榜 begin --------------------------------------------------

    function XRiftManager.OpenUiPluginRanking()
        local request = { ActivityId = ActivityId }
        XNetwork.Call("RiftGetRankRequest", request, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            RankData = res
            
            XLuaUiManager.Open("UiRiftRanking")
        end)
    end

    function XRiftManager.GetRankingList()
        return RankData.RankPlayerInfos
    end

    function XRiftManager.GetMyRankInfo()
        local myRank = {}
        local percentRank = 100 -- 101名及以上显示百分比
        local rank = RankData.Rank
        if RankData.Rank > percentRank then
            rank = math.floor(RankData.Rank * 100 / RankData.TotalCount) .. "%"
        elseif RankData.Rank == 0 then
            rank = XUiHelper.GetText("ExpeditionNoRanking")
        end
        myRank["Rank"] = rank
        myRank["Id"] = XPlayer.Id
        myRank["Name"] = XPlayer.Name
        myRank["HeadPortraitId"] = XPlayer.CurrHeadPortraitId
        myRank["HeadFrameId"] = XPlayer.CurrHeadFrameId
        myRank["Score"] = RankData.Score
        myRank["CharacterIds"] = RankData.CharacterIds
        return myRank
    end

    function XRiftManager.GetRankingSpecialIcon(rank)
        if type(rank) ~= "number" or rank < 1 or rank > 3 then return end
        local icon = CS.XGame.ClientConfig:GetString("BabelTowerRankIcon"..rank) 
        return icon
    end
    -------------------------------------------------- 9排行榜 end --------------------------------------------------

    -------------------------------------------------- 特权解锁 begin --------------------------------------------------
    
    function XRiftManager.IsFuncUnlock(unlockCfgId)
        local funcUnlockCfg = XRiftConfig.GetCfgByIdKey(XRiftConfig.TableKey.RiftFuncUnlock, unlockCfgId)
        local isOpen, desc =  XConditionManager.CheckCondition(funcUnlockCfg.Condition)
        local funcUnlockCfg = XRiftConfig.GetCfgByIdKey(XRiftConfig.TableKey.RiftFuncUnlock, unlockCfgId)
        desc = funcUnlockCfg.Desc
        return isOpen, desc
    end

    -- 获取下一个特权解锁的配置
    function XRiftManager.GetNextFuncUnlockConfig()
        local funcUnlockCfgs = XRiftConfig.GetAllConfigs(XRiftConfig.TableKey.RiftFuncUnlock)
        local unlockCfg = nil
        for _, cfg in ipairs(funcUnlockCfgs) do
            if not XConditionManager.CheckCondition(cfg.Condition) then
                if unlockCfg then
                    if cfg.Order < unlockCfg.Order then
                        unlockCfg = cfg
                    end
                else
                    unlockCfg = cfg
                end
            end
        end

        return unlockCfg
    end

    function XRiftManager.GetFuncUnlockRedSaveKey(unlockCfgId)
        return XPlayer.Id .. "_XRiftManager_FuncUnlockRed_CfgId_" .. unlockCfgId
    end

    -- 判断功能解锁是否显示红点
    function XRiftManager.IsFuncUnlockRed()
        local config = XRiftManager.GetNextFuncUnlockConfig()
        if config then
            local key = XRiftManager.GetFuncUnlockRedSaveKey(config.Id)
            local isRed = XSaveTool.GetData(key) == nil
            return isRed
        end
        return false
    end

    -- 关闭功能解锁的红点
    function XRiftManager.CloseFuncUnlockRed()
        local config = XRiftManager.GetNextFuncUnlockConfig()
        if config then
            local key = XRiftManager.GetFuncUnlockRedSaveKey(config.Id)
            XSaveTool.SaveData(key, true)
        end
    end

    -------------------------------------------------- 特权解锁 end --------------------------------------------------

    -- 服务器刷新
    function XRiftManager.RefreshActivityData(activityId)
        CurrentConfig = XRiftConfig.GetAllConfigs(XRiftConfig.TableKey.RiftActivity)[activityId]
        StartTime = XFunctionManager.GetStartTimeByTimeId(CurrentConfig.TimeId)
        EndTime = XFunctionManager.GetEndTimeByTimeId(CurrentConfig.TimeId)
        XRiftManager.CreateChapterLayerRelationshipChain()
    end

    -- 服务器刷新随机重置数据(在登录和手动请求时都要调用)
    function XRiftManager.RefreshRandomDataByServer(LayerData)
        -- 服务器下发一个Layer数据 包含所有的关系链信息，自上而下建立关系
        XRiftManager.ClearStageGroupRelationshipChain()
        XRiftManager.ResetOrCreateStageGroupRelationshipChain(LayerData)
    end

    -- 区域信息
    function XRiftManager.RefreshChapterData(ChapterDatas)
        if XTool.IsTableEmpty(ChapterDatas) then
            return
        end

        for k, cpData in pairs(ChapterDatas) do
            local XChapter = XRiftManager.GetEntityChapterById(cpData.ChapterId)
            XChapter:SyncData(cpData)
        end
        -- 【已解锁】和【通关】的作战层
        local maxUnlockOrder = 0
        local maxPassOrder = 0
        for k, XChapter in pairs(ChapterDicById) do          
            maxUnlockOrder = XChapter:GetMaxUnlockLayer() > maxUnlockOrder and XChapter:GetMaxUnlockLayer() or maxUnlockOrder
            maxPassOrder = XChapter:GetMaxPassLayer() > maxPassOrder and XChapter:GetMaxPassLayer() or maxPassOrder
        end
        -- 对unlock【已解锁】做特殊处理，因为当A区域完成所有作战层后下发同步的数据，服务器是不会下发下一区域的unlock的信息的，因此必须检查前置区域是否全部通关来设置下一关区域的第一个作战层解锁
        for i = #ChapterDicById, 1, -1 do
            local xChapter = XRiftManager.GetEntityChapterById(i) -- 降序检查
            local layerList = xChapter:GetAllFightLayersOrderList()
            local currChapterLastLayerId = layerList[#layerList]:GetId()
            -- 进入这个判断说明, 当前区域已全部通关, 且该区域是全部通关区域的最高区域。如果还有下一区域，需要设置下一区域的第一个作战层为已解锁状态
            if i < #ChapterDicById and maxPassOrder == currChapterLastLayerId then 
                local nextChapter = XRiftManager.GetEntityChapterById(i+1)
                if nextChapter then
                    local nextLayerList = nextChapter:GetAllFightLayersOrderList()
                    maxUnlockOrder = nextLayerList[1]:GetId()
                end
                break
            end
        end

        for k, xFightLayer in pairs(FightLayerDicById) do
            if xFightLayer:GetConfig().Order <= maxUnlockOrder then
                xFightLayer:SetHasLock(false)
            end

            if xFightLayer:GetConfig().Order <= maxPassOrder then
                xFightLayer:SetHasPassed(true)
            end
        end
        if MaxUnLockFightLayerOrder and maxUnlockOrder - MaxUnLockFightLayerOrder > 1 then
            IsJumpOpenTrigger = maxUnlockOrder - MaxUnLockFightLayerOrder
        end
        if MaxPassFightLayerOrder and maxPassOrder - MaxPassFightLayerOrder > 1 then
            IsJumpResTrigger = maxPassOrder - MaxPassFightLayerOrder
        end

        MaxUnLockFightLayerOrder = maxUnlockOrder
        MaxPassFightLayerOrder = maxPassOrder
    end

    function XRiftManager.RefreshZoomJumpData(jumpLayerRecords)
        for k, data in pairs(jumpLayerRecords) do
            local xFightLayer = FightLayerDicById[data.LayerId]
            xFightLayer:SetJumpCount(data.AddOrderMax)
        end
    end

    -- 服务器刷新关卡/战斗数据
    function XRiftManager.RefreshBattleDataByServer(data)
        -- 关系链信息
        XRiftManager.RefreshRandomDataByServer(data.CurLayerData)
        -- 区域信息
        XRiftManager.RefreshChapterData(data.ChapterDatas)
        -- 跃升记录数据
        XRiftManager.RefreshZoomJumpData(data.JumpLayerRecords)
    end
    
    -- 服务器刷新角色信息
    function XRiftManager.RefreshCharacterData(data)
        XRiftManager.RefreshCharacterPluginData(data)
        XRiftManager.RefreshTeamTemplateData(data)
    end

    function XRiftManager.RefreshCharacterPluginData(data)
        for k, data in pairs(data.CharacterDatas) do
            local roleId = XTool.IsNumberValid(data.CharacterId) and data.CharacterId or data.RobotId
            local xRole = XRiftManager.GetEntityRoleById(roleId)
            xRole:SyncPlugInIds(data.PluginIds)
        end
    end

    function XRiftManager.RefreshTeamTemplateData(data)
        -- 队伍对应的模板
        for k, data in pairs(data.TeamDatas) do
            local xTeam = XRiftManager.GetMultiTeamData()[data.Id]
            if xTeam then
                xTeam:SetAttrTemplateId(data.AttrSetId)
            end
        end
        TeamDatas = data.TeamDatas
    end

    -- 服务器刷新
    function XRiftManager.RefreshDataByServer(data)
        ActivityId = data.ActivityId
        -- 活动配置数据
        XRiftManager.RefreshActivityData(data.ActivityId)
        -- 关卡/战斗数据
        XRiftManager.RefreshBattleDataByServer(data)
        -- 角色相关数据
        XRiftManager.RefreshCharacterData(data)
        -- 全局数据
        XRiftManager.RefreshWholeData(data)
        -- 加点模板
        XRiftManager.RefreshAttrTemplate(data)
        -- 解锁插件
        XRiftManager.UnlockedPlugin(data.UnlockedPluginIds)
    end
    ------------------副本入口扩展
    --region
    --endregion
    ------------------副本入口扩展结束

    XRiftManager.Init()
    return XRiftManager
end

-- =========网络=========
XRpc.NotifyRiftData = function(data)
    XDataCenter.RiftManager.RefreshDataByServer(data.Data)
end

XRpc.NotifyRiftNewPlugin = function(data)
    XDataCenter.RiftManager.UnlockedPlugin(data.PluginIds)
end

XRpc.NotifyRiftPluginPeakLoadChanged = function(data)
    XDataCenter.RiftManager.RefreshMaxLoad(data.PluginPeakLoad)
end

XRpc.NotifyRiftAttrLevelMaxChanged = function(data)
    XDataCenter.RiftManager.RefreshAttrLevelMax(data.AttrLevelMax)
end

XRpc.NotifyRiftDailyReset = function(data)
    XDataCenter.RiftManager.RefreshSweepTimes(data.SweepTimes)
end