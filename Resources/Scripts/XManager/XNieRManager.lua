local XNieRChapter = require("XEntity/XNieR/XNieRChapter")
local XNieRCharacter = require("XEntity/XNieR/XNieRCharacter")
local XNieRRepeat = require("XEntity/XNieR/XNieRRepeat")
local XNieRBoss = require("XEntity/XNieR/XNieRBoss")
local XNierPOD = require("XEntity/XNieR/XNierPOD")
--尼尔玩法管理器
XNieRManagerCreator = function()
    local XNieRManager = {}
    local NieRRepeatPOIndex = 3--复刷权限关在主线关卡位置
    local ActivityId = XNieRConfigs.GetDefaultActivityId()
    local CurActivityConfig = {}
    local ChapterDataList = {}
    local ChapterDataDic = {}
    local RepeatDataList = {}
    local RepeatDataDic = {}
    local BossStageIdToChapterId = {}

    local IsActivityEnd = true
    local PassMainStageCount = 0
    local AllMainStageCount = 0

    local NieRCharacterDic = {}
    local NieRRobotIdToCharacterIdDic = {}
    local SelCharacterId = 0
    local NieRBossDic = {}

    local NieRMainLineStageDic = {}
    local NieRMainLineBossStageDic = {}
    local NieRRepeatMainStage = {}
    local NieRRepeatStage = {}
    local NieREasterEggStage = {}
    local NieRTeachingStage = {}
    local SaveRepeatConsumCount = 0



    local NierPODData = nil

    local BeginNieRData = {}

    local PlayerTeamData = {}
    local TypeId = CS.XGame.Config:GetInt("TypeIdNieR")
    local RepeatTypeId = CS.XGame.Config:GetInt("TypeIdNieRRepeat")
    local DefaultTeam = {
        CaptainPos = 1,
        FirstFightPos = 1,
        TeamData = { 0, 0, 0 },
    }

    local IsRegisterEditBattleProxy = false
    local NierFubenPassed = false

    local NieREasterEggData = {}
    local IsNieREasterEggDataRealPass = false
    local CurSelEasterEggDataIndex = 0
    local LastSelEasterEggDataIndex = 0

    local NieRRpc = {
        NieRCharacterChangeFashion = "NieRCharacterChangeFashionRequest", --更换涂装请求
        NieRUpdateBossScore = "NieRUpdateBossScoreRequest", --保存BOSS分数
        NieRUpgradeSupportSkill = "NieRUpgradeSupportSkillRequest", --辅助机技能升级
        NieRSelectSupportSkill = "NieRSelectSupportSkillRequest", --选择辅助机技能
        NieREasterEggLeaveMessage = "NieREasterEggLeaveMessageRequest", --尼尔彩蛋关留言请求
    }

    local NieREasterEggStageShow = false

    local NierCharacterAbilityDicInit = false
    local NieRCharacterAbilityDic = {}
    local NieRRepeatExStagePass = false

    local NieRMainLineUITipsInfoInit = false
    local NieRCharacterOpenDic = {}
    local NieRRepeatPoStageOpenDic = {}
    local NieRBossStageOpenDic = {}
    local NierMainLineStagePass = false


    function XNieRManager.RegisterEditBattleProxy()
        if IsRegisterEditBattleProxy then return end
        IsRegisterEditBattleProxy = true
        XUiNewRoomSingleProxy.RegisterProxy(XDataCenter.FubenManager.StageType.NieR,
        require("XUi/XUiNieR/XUiNieRNewRoomSingle"))
    end
    -- 初始化副本info
    function XNieRManager.InitStageInfo()
        local nieRType = XDataCenter.FubenManager.StageType.NieR
        local nierChapterCfgs = XNieRConfigs.GetAllChapterConfig()
        local nierCharacterCfgs = XNieRConfigs.GetAllCharacterConfig()
        --主线剧情关
        for _, chapterCfg in pairs(nierChapterCfgs) do
            for index, stageId in ipairs(chapterCfg.StageIds) do
                local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
                if stageInfo then
                    if stageInfo.Type and stageInfo.Type ~= nieRType then
                        XLog.Error(string.format("%s已设置了Type", stageId))
                    end
                    stageInfo.Type = nieRType
                else
                    XLog.Error(string.format("没有找到StageInfo，stageId：%s", stageId))
                end
                NieRMainLineStageDic[stageId] = chapterCfg.ChapterId
            end
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(chapterCfg.BossStageId)
            if stageInfo then
                if stageInfo.Type and stageInfo.Type ~= nieRType then
                    XLog.Error(string.format("%s已设置了Type", stageId))
                end
                stageInfo.Type = nieRType
            else
                XLog.Error(string.format("没有找到StageInfo，stageId：%s", chapterCfg.BossStageId))
            end
            NieRMainLineBossStageDic[chapterCfg.BossStageId] = chapterCfg.ChapterId
        end
        -- --教学关
        for _, characterCfg in pairs(nierCharacterCfgs) do
            for _, stageId in pairs(characterCfg.TeachingStageIds) do
                local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
                if stageInfo then
                    if stageInfo.Type and stageInfo.Type ~= nieRType then
                        XLog.Error(string.format("%s已设置了Type", stageId))
                    end
                    stageInfo.Type = nieRType
                else
                    XLog.Error(string.format("没有%s", stageId))
                end
                NieRTeachingStage[stageId] = characterCfg.CharacterId
            end
        end
        --复刷关
        local repeatableCfgs = XNieRConfigs.GetRepeatableStageConfig()
        for _, repeatableCfg in pairs(repeatableCfgs) do
            for _, stageId in pairs(repeatableCfg.ExStageIds) do
                local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
                if stageInfo then
                    if stageInfo.Type and stageInfo.Type ~= nieRType then
                        XLog.Error(string.format("%s已设置了Type", stageId))
                    end
                    stageInfo.Type = nieRType
                else
                    XLog.Error(string.format("没有找到StageInfo，stageId：%s", stageId))
                end
                NieRRepeatStage[stageId] = repeatableCfg.RepeatableStageId
            end
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(repeatableCfg.RepeatableStageId)
            if stageInfo then
                if stageInfo.Type and stageInfo.Type ~= nieRType then
                    XLog.Error(string.format("%s已设置了Type", stageId))
                end
                stageInfo.Type = nieRType
            else
                XLog.Error(string.format("没有找到StageInfo，stageId：%s", repeatableCfg.RepeatableStageId))
            end
            NieRRepeatMainStage[repeatableCfg.RepeatableStageId] = repeatableCfg.RepeatableStageId
        end
        --彩蛋关
        local nieRActivityConfigs = XNieRConfigs.GetAllActivityConfig()
        for _, nieRActiveityCfg in pairs(nieRActivityConfigs) do
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(nieRActiveityCfg.EasterEggStageId)
            if stageInfo then
                if stageInfo.Type and stageInfo.Type ~= nieRType then
                    XLog.Error(string.format("%s已设置了Type", stageId))
                end
                stageInfo.Type = nieRType
            else
                XLog.Error(string.format("没有找到StageInfo，stageId：%s", stageId))
            end
            NieREasterEggStage[nieRActiveityCfg.EasterEggStageId] = nieRActiveityCfg.EasterEggStageId
        end

        for _, nieRCharacter in pairs(NieRCharacterDic) do
            nieRCharacter:ResetNeedUpdateNieRCharAbility()
        end
    end

    function XNieRManager.CheckPreFight(stage, challengeCount)
        local stageId = stage.StageId

        if NieRRepeatMainStage[stageId] then
            local repeatData = XNieRManager.GetRepeatDataById(stageId)
            local itemId, count = XDataCenter.NieRManager.GetRepeatStageConsumeId(), repeatData:GetNierRepeatStageConsumeCount()
            local itemCount = XDataCenter.ItemManager.GetCount(itemId)
            if not XDataCenter.ItemManager.DoNotEnoughBuyAsset(itemId, count, 1, nil, "NieRRepeatTickNotEnough") then
                return false
            end
        elseif NieRRepeatStage[stageId] then
            local repeatData = XNieRManager.GetRepeatDataById(NieRRepeatStage[stageId])
            local itemId, count = repeatData:GetExConsumIdAndCount(stageId)
            if not XDataCenter.ItemManager.DoNotEnoughBuyAsset(itemId, count, 1, nil, "NieRRepeatTickNotEnough") then
                return false
            end
        end

        return true
    end
    --战斗开始前记录一部分数据
    function XNieRManager.OpenFightLoading(stageId)
        if NieRRepeatMainStage[stageId] or NieRRepeatStage[stageId] then
            for _, nierCharcter in pairs(XNieRManager.GetNieRCharacterDic()) do
                local tmpCharacter = {}
                tmpCharacter.Id = nierCharcter:GetNieRCharacterId()
                tmpCharacter.OldLevel = nierCharcter:GetNieRCharacterLevel()
                tmpCharacter.OldExp = nierCharcter:GetNieRCharacterExp()
                tmpCharacter.OldMaxExp = nierCharcter:GetNieRCharacterMaxExp()
                tmpCharacter.IsOldMaxLevel = nierCharcter:CheckNieRCharacterMaxLevel()
                BeginNieRData.NierCharacter = BeginNieRData.NierCharacter or {}
                BeginNieRData.NierCharacter[nierCharcter:GetNieRCharacterUpLevelItemId()] = tmpCharacter
            end
            if NierPODData then
                local tmpNieRPOD = {}
                tmpNieRPOD.Id = NierPODData:GetNieRPODId()
                tmpNieRPOD.OldLevel = NierPODData:GetNieRPODLevel()
                tmpNieRPOD.OldExp = NierPODData:GetNieRPODExp()
                tmpNieRPOD.IsOldMaxLevel = NierPODData:CheckNieRPODMaxLevel()
                tmpNieRPOD.OldMaxExp = NierPODData:GetNieRPODMaxExp()
                BeginNieRData.NierPOD = BeginNieRData.NierPOD or {}
                BeginNieRData.NierPOD[NierPODData:GetNieRPODUpLevelItemId()] = tmpNieRPOD
            end
        end
        NierFubenPassed = XDataCenter.FubenManager.CheckStageIsPass(stageId)
        XDataCenter.FubenManager.OpenFightLoading(stageId)
    end

    function XNieRManager.ShowReward(winData)
        if not winData then return end
        if NierFubenPassed then
            XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_NIER_STAGE_REWARD)
            NierFubenPassed = false
        end
        if winData.SettleData.NieRBossFightResult then
            XLuaUiManager.Open("UiNieRBossFightResult", winData)
            return
        end
        if NieREasterEggStage[winData.StageId] then
            XLuaUiManager.Open("UiNieREasterEgg", true, false)
            return
        end

        if NieRRepeatStage[winData.StageId] then
            NieRRepeatExStagePass = true
        end
        if NieRMainLineStageDic[winData.StageId] then
            NierMainLineStagePass = true
        end

        local closeCb = function()
            local stageId = winData.StageId
            if (NieRRepeatMainStage[stageId] or NieRRepeatStage[stageId]) and next(BeginNieRData) ~= nil then
                local showList = {}
                local podInfo
                for _, item in pairs(winData.SettleData.RewardGoodsList) do
                    local nierCharacterData = BeginNieRData.NierCharacter[item.TemplateId]
                    if nierCharacterData then
                        -- local nierCharacterId = nierCharacterData.id
                        -- local nierCharcter = XNieRManager.GetNieRCharacterByCharacterId(nierCharacterId)
                        -- nierCharacterData.NewLevel = nierCharcter:GetNieRCharacterLevel()
                        -- nierCharacterData.NewExp = nierCharcter:GetNieRCharacterExp()
                        nierCharacterData.Item = item
                        table.insert(showList, nierCharacterData)
                    end
                    if not podInfo and BeginNieRData.NierPOD[item.TemplateId] then
                        podInfo = BeginNieRData.NierPOD[item.TemplateId]
                        if podInfo then
                            podInfo.Item = item
                        end
                    end
                end

                if #showList > 0 or podInfo then
                    local donotShow = true
                    if #showList > 0 then
                        for _, info in ipairs(showList) do
                            if not info.IsOldMaxLevel then
                                donotShow = false
                                break
                            end
                        end
                    end
                    if donotShow and podInfo and not podInfo.IsOldMaxLevel then
                        donotShow = false
                    end
                    if donotShow then
                    else
                        XLuaUiManager.Open("UiFubenNierShengji", showList, podInfo)
                    end
                end
            elseif (NieRMainLineStageDic[stageId] or NieRMainLineBossStageDic[stageId]) then
                local nieRChapterId = NieRMainLineStageDic[stageId] or NieRMainLineBossStageDic[stageId]
                local nieRChapter = XNieRManager.GetChapterDataById(nieRChapterId)
                if not nieRChapter:CheckNieRChapterUnLock() then
                    XUiManager.TipText("NieRActivityChapterEnd")
                    XLuaUiManager.RunMain()

                end
            end
            BeginNieRData = {}
        end
        XLuaUiManager.Open("UiSettleWin", winData, nil, closeCb, true)
    end

    --判断活动是否开启
    function XNieRManager.GetIsActivityEnd()
        local timeNow = XTime.GetServerNowTimestamp()
        local isEnd = timeNow >= XNieRManager.GetEndTime()
        local isStart = timeNow >= XNieRManager.GetStartTime()
        local inActivity = (not isEnd) and (isStart)
        return IsActivityEnd or not inActivity, timeNow < XNieRManager.GetStartTime()
    end

    --获取本轮开始时间
    function XNieRManager.GetStartTime()
        if not CurActivityConfig then return 0 end
        return XFunctionManager.GetStartTimeByTimeId(CurActivityConfig.TimeId) or 0
    end

    --获取本轮结束时间
    function XNieRManager.GetEndTime()
        if not CurActivityConfig then return 0 end
        return XFunctionManager.GetEndTimeByTimeId(CurActivityConfig.TimeId) or 0
    end

    --===================
    --获取活动配置简表
    --===================
    function XNieRManager.GetActivityChapters()
        local chapters = {}
        if CurActivityConfig and not XNieRManager.GetIsActivityEnd() then
            local tempChapter = {}
            tempChapter.Id = CurActivityConfig.Id
            tempChapter.Name = XNieRManager.GetActivityName()
            tempChapter.Type = XDataCenter.FubenManager.ChapterType.NieR
            tempChapter.BannerBg = CurActivityConfig.BannerBg
            table.insert(chapters, tempChapter)
        -- else
        --     local nieRActivityConfigs = XNieRConfigs.GetAllActivityConfig()
        --     if nieRActivityConfigs then
        --         for _, cfg in pairs(nieRActivityConfigs) do
        --             local startTime = XFunctionManager.GetStartTimeByTimeId(cfg.TimeId)
        --             local endTime = XFunctionManager.GetEndTimeByTimeId(cfg.TimeId)
        --             local timeNow = XTime.GetServerNowTimestamp()
        --             XLog.Debug(".GetActivityChapters..",startTime,endTime,timeNow)
        --             if timeNow >= startTime and timeNow < endTime then
        --                 local tempChapter = {}
        --                 tempChapter.Id = cfg.Id
        --                 tempChapter.Name = cfg.Name or ""
        --                 tempChapter.Type = XDataCenter.FubenManager.ChapterType.NieR
        --                 tempChapter.BannerBg = cfg.BannerBg
        --                 table.insert(chapters, tempChapter)
        --                 break
        --             end
        --         end
        --     end
        end

        return chapters
    end

    --获取当前已通过的关卡数
    function XNieRManager.GetPassMainStageCount()
        PassMainStageCount = 0
        if not CurActivityConfig then
            return 0
        end
        for index, chapterId in ipairs(CurActivityConfig.ChapterIds) do
            local chapterConfig = XNieRConfigs.GetChapterConfigById(chapterId)
            for __, stageId in ipairs(chapterConfig.StageIds) do

                if XDataCenter.FubenManager.CheckStageIsPass(stageId) then
                    PassMainStageCount = PassMainStageCount + 1
                end
            end
            if chapterConfig.BossStageId ~= 0 then
                if XDataCenter.FubenManager.CheckStageIsPass(chapterConfig.BossStageId) then
                    PassMainStageCount = PassMainStageCount + 1
                end
            end
        end
        return PassMainStageCount
    end

    --获取所有的关卡数
    function XNieRManager.GetAllMainStageCount()
        return AllMainStageCount
    end

    --获取当前通关情况的字符串
    function XNieRManager.GetChapterProgressStr()
        return CS.XTextManager.GetText("NieRChapterProgressStr", XNieRManager.GetPassMainStageCount(), XNieRManager.GetAllMainStageCount())
    end

    --获得活动名字
    function XNieRManager.GetActivityName()
        if not CurActivityConfig then return "" end
        return CurActivityConfig.Name or ""
    end

    --处理当前活动状态改变的方法
    function XNieRManager.CurActivtityConfigChange()
        PassMainStageCount = 0
        AllMainStageCount = 0
        ChapterDataList = {}
        ChapterDataDic = {}
        RepeatDataList = {}
        RepeatDataDic = {}
        BossStageIdToChapterId = {}

        NierCharacterAbilityDicInit = false
        NieRCharacterAbilityDic = {}
        NieRRepeatExStagePass = false

        NieRMainLineUITipsInfoInit = false
        NieRCharacterOpenDic = {}
        NieRRepeatPoStageOpenDic = {}
        NieRBossStageOpenDic = {}
        NierMainLineStagePass = false

        if ActivityId == 0 then return end
        CurActivityConfig = XNieRConfigs.GetActivityConfigById(ActivityId)

       
        if not CurActivityConfig then
            return 
        end
        for index, chapterId in ipairs(CurActivityConfig.ChapterIds) do
            local chapterConfig = XNieRConfigs.GetChapterConfigById(chapterId)

            for __, stageId in ipairs(chapterConfig.StageIds) do
                AllMainStageCount = AllMainStageCount + 1
            end
            if chapterConfig.BossStageId ~= 0 then
                AllMainStageCount = AllMainStageCount + 1
            end
            BossStageIdToChapterId[chapterConfig.BossStageId] = chapterId
            XNieRManager.InitChapterEntity(chapterId, index)
        end
        for index, repeatId in ipairs(CurActivityConfig.RepeatableStageIds) do
            XNieRManager.InitRepeatEntity(repeatId, index)
        end

        IsActivityEnd = false
    end

    --获取当前活动的章节表
    function XNieRManager.GetCurActivityChapterIds()
        if not CurActivityConfig then return {} end
        return CurActivityConfig.ChapterIds or {}
    end

    function XNieRManager.GetCurDevelopCharacterIds()
        if not CurActivityConfig then return {} end
        return CurActivityConfig.DevelopCharacterIds
    end

    --初始化章节对象
    function XNieRManager.InitChapterEntity(chapterId, index)
        local tmpChapterData = XNieRChapter.New(chapterId, index)
        local lastChapterData
        if index > 1 then
            lastChapterData = ChapterDataList[index - 1]
        end


        table.insert(ChapterDataList, tmpChapterData)
        ChapterDataDic[chapterId] = tmpChapterData
    end

    --获取章节对象列表
    function XNieRManager.GetChapterDataList()
        return ChapterDataList
    end

    --根据Index获取章节对象
    function XNieRManager.GetChapterDataByIndex(index)
        return ChapterDataList[index]
    end

    --根据Id获取章节对象
    function XNieRManager.GetChapterDataById(chapterId)
        return ChapterDataDic[chapterId]
    end

    --尼尔玩法复刷关信息
    --初始化复刷关对象
    function XNieRManager.InitRepeatEntity(repeatId, index)
        local tmpRepeatData = XNieRRepeat.New(repeatId, index)
        local lastChapterData

        table.insert(RepeatDataList, tmpRepeatData)
        RepeatDataDic[repeatId] = tmpRepeatData
    end

    --获取复刷关对象列表
    function XNieRManager.GetRepeatDataList()
        return RepeatDataList
    end

    --根据Index获取复刷关对象
    function XNieRManager.GetRepeatDataByIndex(index)
        return RepeatDataList[index]
    end

    --根据Id获取复刷关对象
    function XNieRManager.GetRepeatDataById(repeatId)
        return RepeatDataDic[repeatId]
    end

    --根据Id获取复刷关门票Id
    function XNieRManager.GetRepeatStageConsumeId()
        if not CurActivityConfig then return 0 end
        return CurActivityConfig.RepeatableConsumeId
    end

    --获得复刷关门票最大数量
    function XNieRManager.GetNieRRepeatConsumeMaxCount()
        if not CurActivityConfig then return 0 end
        return CurActivityConfig.RepeatableConsumeMaxCount or 0
    end

    function XNieRManager.CheckNieRRepeatMainStage(stageId)
        return NieRRepeatMainStage[stageId] or false
    end

    --处理尼尔POD辅助机
    function XNieRManager.UpdateNieRPODData(data)
        if not NierPODData then
            NierPODData = XNierPOD.New(data)
        else
            NierPODData:UpdateNierPOD(data)
        end
    end

    function XNieRManager.GetNieRPODData()
        return NierPODData
    end

    --处理尼尔Boss
    function XNieRManager.UpdateNieRBossData(data)
        local stageId = data.StageId

        if not NieRBossDic[stageId] then
            NieRBossDic[stageId] = XNieRBoss.New(data, BossStageIdToChapterId[stageId])
        else
            NieRBossDic[stageId]:UpdateData(data, BossStageIdToChapterId[stageId])
        end
        return NieRBossDic[stageId]
    end

    function XNieRManager.GetNieRBossDataById(stageId)
        if not NieRBossDic[stageId] then
            local data = {}
            data.StageId = stageId
            data.LeftHp = XNieRConfigs.GetChapterConfigById(BossStageIdToChapterId[stageId]).BossHp
            data.Score = 0
            NieRBossDic[stageId] = XNieRBoss.New(data, BossStageIdToChapterId[stageId])
        end
        return NieRBossDic[stageId]
    end

    --处理尼尔角色
    function XNieRManager.UpdateNieRCharacterData(data)
        local characterId = data.CharacterId
        if not NieRCharacterDic[characterId] then
            NieRCharacterDic[characterId] = XNieRCharacter.New(data)
            local robotId = NieRCharacterDic[characterId]:GetNieRCharacterRobotId()
            NieRRobotIdToCharacterIdDic[robotId] = characterId
        else
            local nieRCharacter = NieRCharacterDic[characterId]
            local lastRobotId = nieRCharacter:GetNieRCharacterRobotId()
            NieRRobotIdToCharacterIdDic[lastRobotId] = nil
            nieRCharacter:UpdateNieRCharacter(data)
            local robotId = NieRCharacterDic[characterId]:GetNieRCharacterRobotId()
            NieRRobotIdToCharacterIdDic[robotId] = characterId
            NieRCharacterDic[characterId]:ResetNeedUpdateNieRCharAbility()
            if lastRobotId ~= robotId then
                XNieRManager.ChangeAllPlayerTeam(lastRobotId, robotId, TypeId)
                XNieRManager.ChangeAllPlayerTeam(lastRobotId, robotId, RepeatTypeId)
            end
        end
    end

    --获得角色列表
    function XNieRManager.GetChapterCharacterList(repeatId, chapterId)
        local CharacterList = {}
        local CharacterDic = {}
        if not repeatId then
            local roboteIds = XNieRManager.GetChapterDataById(chapterId):GetNierChapterRobotIds() or {}
            for _, robotId in ipairs(roboteIds) do
                table.insert(CharacterList, robotId)
                CharacterDic[robotId] = true
            end
        else
            local nieRRepeat = XNieRManager.GetRepeatDataById(repeatId)
            local roboteIds = nieRRepeat:GetNieRRepeatRobotIds() or {}
            for _, robotId in ipairs(roboteIds) do
                table.insert(CharacterList, robotId)
                CharacterDic[robotId] = true
            end
        end
        local characterIds = XNieRManager.GetCurDevelopCharacterIds()
        for _, id in pairs(characterIds) do
            local nieRCharacter = NieRCharacterDic[id]
            if nieRCharacter:CheckNieRCharacterCondition() then
                local robotId = nieRCharacter:GetNieRCharacterRobotId()
                table.insert(CharacterList, robotId)
                CharacterDic[robotId] = true
            end
        end
        return CharacterList, CharacterDic
    end

    function XNieRManager.GetCharacterCount()
        local count, unlockCount = 0, 0
        local characterIds = XNieRManager.GetCurDevelopCharacterIds() or {}
        for _, id in pairs(characterIds) do
            local nieRCharacter = NieRCharacterDic[id]
            if nieRCharacter and nieRCharacter:CheckNieRCharacterCondition() then
                unlockCount = unlockCount + 1
            end
            count = count + 1
        end
        return unlockCount, count
    end

    --根据机器人Id获取尼尔角色的角色Id
    function XNieRManager.GetCharacterIdByNieRRobotId(robotId)
        return NieRRobotIdToCharacterIdDic[robotId] or 0
    end

    function XNieRManager.SetSelCharacterId(value)
        SelCharacterId = value
    end

    function XNieRManager.GetSelNieRCharacter()
        return NieRCharacterDic[SelCharacterId]
    end

    function XNieRManager.GetNieRCharacterByCharacterId(characterId)
        return NieRCharacterDic[characterId]
    end

    function XNieRManager.GetNieRCharacterDic()
        return NieRCharacterDic
    end

    --获取尼尔玩法队伍信息
    function XNieRManager.GetPlayerTeamData(stageId)
        local typeId = TypeId
        local robotList
        local robotDic = {}
        local CurTeamData
        local teamData
        if NieREasterEggStage[stageId] then
            local characterIds = XNieRManager.GetCurDevelopCharacterIds()
            local CharacterList = {}
            for _, id in pairs(characterIds) do
                local nieRCharacter = NieRCharacterDic[id]
                if nieRCharacter:CheckNieRCharacterCondition() and nieRCharacter:GetNieRCharacterCfgEasterEggFightTag() ~= 0 then
                    table.insert(CharacterList, nieRCharacter)
                end
            end
            table.sort(CharacterList, function(a, b)
                return a:GetNieRCharacterCfgEasterEggFightTag() < b:GetNieRCharacterCfgEasterEggFightTag()
            end)
            teamData = XTool.Clone(DefaultTeam)
            for key, id in pairs(teamData.TeamData) do
                if CharacterList[key] then
                    teamData.TeamData[key] = CharacterList[key]:GetNieRCharacterRobotId()
                end
            end
            return teamData
        elseif NieRRepeatMainStage[stageId] or NieRRepeatStage[stageId] then
            typeId = RepeatTypeId
            robotList, robotDic = XDataCenter.NieRManager.GetChapterCharacterList(NieRRepeatMainStage[stageId] or NieRRepeatStage[stageId], nil)
        elseif NieRMainLineBossStageDic[stageId] or NieRMainLineStageDic[stageId] then
            typeId = TypeId
            robotList, robotDic = XDataCenter.NieRManager.GetChapterCharacterList(nil, NieRMainLineBossStageDic[stageId] or NieRMainLineStageDic[stageId])
        end
        local teamId = XDataCenter.TeamManager.GetTeamId(typeId)

        if XDataCenter.TeamManager.GetPlayerTeamData(teamId) then
            CurTeamData = XDataCenter.TeamManager.GetPlayerTeamData(teamId)
            teamData = XTool.Clone(CurTeamData)
        else
            DefaultTeam.TeamId = teamId
            teamData = XTool.Clone(DefaultTeam)
        end

        for key, id in pairs(teamData.TeamData) do
            if not robotDic[id] then
                teamData.TeamData[key] = 0
            end
        end
        return teamData
    end

    function XNieRManager.SetPlayerTeamData(curTeam, stageId)
        local typeId = TypeId
        if NieRRepeatMainStage[stageId] or NieRRepeatStage[stageId] then
            typeId = RepeatTypeId
        elseif NieRMainLineBossStageDic[stageId] then
            typeId = TypeId
        end
        XDataCenter.TeamManager.SetPlayerTeam(curTeam, false, function()

        end)
    end

    function XNieRManager.ChangeAllPlayerTeam(lastRobotId, robotId, typeId)
        local teamId = XDataCenter.TeamManager.GetTeamId(typeId)
        local CurTeamData = XDataCenter.TeamManager.GetPlayerTeamData(teamId)
        if not CurTeamData or not CurTeamData.TeamData then
            return
        end

        local needSaveToServer = false
        for key, id in ipairs(CurTeamData.TeamData) do
            if id == lastRobotId then
                CurTeamData.TeamData[key] = robotId
                needSaveToServer = true
                break
            end
        end

        if needSaveToServer then
            XDataCenter.TeamManager.SetPlayerTeam(CurTeamData, false, function()

            end)
        end
    end

    function XNieRManager.CheckCharacterInformationUnlock(id, isUnlockClick)
        local isUnlock = XSaveTool.GetData(string.format("%d%s%d", XPlayer.Id, "NieRCharacterInformation", id))
        if not isUnlock then
            XSaveTool.SaveData(string.format("%d%s%d", XPlayer.Id, "NieRCharacterInformation", id), isUnlockClick)
            if isUnlockClick then
                XEventManager.DispatchEvent(XEventId.EVENT_NIER_CHARACTER_UPDATE)
            end
            return false
        else
            return true
        end
    end

    function XNieRManager.SaveSelRepeatStageId(stageId)
        XSaveTool.SaveData(string.format("%d%s", XPlayer.Id, "NieRRepeatSelMainStageId"), stageId)
    end
    
    function XNieRManager.GetSelRepeatStageId()
        local lastSelStageId = XSaveTool.GetData(string.format("%d%s", XPlayer.Id, "NieRRepeatSelMainStageId"))
        return lastSelStageId or 0
    end
    
    function XNieRManager.RemoveAllPreData()
        local allCharacterConfig = XNieRConfigs.GetAllCharacterConfig()
        for _, charConfig in pairs(allCharacterConfig) do
            local inforList = XNieRConfigs.GetNieRCharacterInforListById(charConfig.CharacterId)
            for _, config in ipairs(inforList) do
                XSaveTool.RemoveData(string.format("%d%s%d", XPlayer.Id, "NieRCharacterInformation", config.Id))
            end  
        end
        
        XSaveTool.RemoveData(string.format("%d%s", XPlayer.Id, "NieRRepeatSelMainStageId"))
        XSaveTool.RemoveData(string.format("%d%s", XPlayer.Id, "NieREasterEggStageShow"))
        XSaveTool.RemoveData(string.format("%d%s", XPlayer.Id, "NieRRepeatRedCheckCount"))
        XSaveTool.RemoveData(string.format("%d%s", XPlayer.Id, "NieRActivityIdSave"))
    end
    
    --尼尔玩法商店信息
    function XNieRManager.GetActivityShopIds()
        if not CurActivityConfig then return {} end
        return CurActivityConfig.ShopIds
    end

    function XNieRManager.GetActivityShopConditionByShopId(shopId)
        return XShopManager.GetShopConditionIdList(shopId)
    end

    function XNieRManager.GetActivityShopGoodsByShopId(shopId)
        local goods = XShopManager.GetShopGoodsList(shopId)
        return goods
    end

    function XNieRManager.GetActivityShopBtnNameById(shopId)
        return XNieRConfigs.GetNieRShopById(shopId).BtnName
    end

    function XNieRManager.GetActivityShopItemBgById(shopId)
        return XNieRConfigs.GetNieRShopById(shopId).ShopItemBg
    end

    function XNieRManager.GetActivityShopBgById(shopId)
        return XNieRConfigs.GetNieRShopById(shopId).ShopBg
    end

    function XNieRManager.GetActivityShopIconById(shopId)
        return XNieRConfigs.GetNieRShopById(shopId).ShopIcon
    end

    function XNieRManager.GetActivityNierTaskGroupList()
        local taskGroupList = CurActivityConfig and CurActivityConfig.TaskGroupIds or {}
        local taskGroupCfgsList = {}

        for _, groupId in ipairs(taskGroupList) do
            local cfg = XNieRConfigs.GetNieRTaskGroupByGroupId(groupId)
            if not XNieRManager.CheckNieREasterEggStagePassed() and cfg.EasterEggTask == 1 then
            else
                table.insert(taskGroupCfgsList, cfg)
            end

        end
        table.sort(taskGroupCfgsList, function(a, b)
            return a.Priority < b.Priority
        end)
        return taskGroupCfgsList
    end

    --处理尼尔玩法任务部分
    function XNieRManager.GetActivityNierTaskByChapterId(groupId)
        return XDataCenter.TaskManager.GetNierTaskListByGroupId(groupId)
    end

    --检查尼尔玩法任务红点
    function XNieRManager.CheckNieRTaskRed(groupId)
        if XNieRManager.GetIsActivityEnd() then return false end
        if groupId > 0 then
            local taskList = XDataCenter.TaskManager.GetNierTaskListByGroupId(groupId)
            for _, tasks in ipairs(taskList) do
                if tasks ~= nil and tasks.State == XDataCenter.TaskManager.TaskState.Achieved then
                    return true
                end
            end
        else
            return XDataCenter.TaskManager.GetIsRewardForEx(XDataCenter.TaskManager.TaskType.NieR)
        end
    end

    -----------------------------------------尼尔彩蛋关-----------------------------------------------
    function XNieRManager.UpdateNieREasterEggData(players)
        NieREasterEggData = {}
        CurSelEasterEggDataIndex = 0
        LastSelEasterEggDataIndex = 0
        for _, info in pairs(players) do
            local tmp = {}
            tmp.PlayerId = info.PlayerId
            tmp.PlayerName = info.PlayerName
            tmp.MessageId = info.MessageId
            tmp.Age = info.Age
            tmp.LabelId = info.LabelId
            table.insert(NieREasterEggData, tmp)
        end
        local needCount = XNieRManager.GetCurMaxEasterEggMessageCount() - #NieREasterEggData
        if needCount > 0 then
            local ConfigMsg = XNieRConfigs.GetNieREasterEggInitMessageConfig()
            for i = 1, needCount do
                local config = ConfigMsg[i]
                if config then
                    local tmp = {}
                    tmp.PlayerName = config.PlayerName
                    tmp.MessageId = config.MessageId
                    tmp.Age = config.Age
                    tmp.LabelId = config.LabelId
                    table.insert(NieREasterEggData, tmp)
                end
            end
        end
    end

    function XNieRManager.NieREasterEggDataRealPass()
        IsNieREasterEggDataRealPass = true
    end

    function XNieRManager.GetNieREasterEggData()
        return NieREasterEggData
    end

    function XNieRManager.GetCurNieREasterEggStageId()
        if not CurActivityConfig then return 0 end
        return CurActivityConfig.EasterEggStageId
    end

    function XNieRManager.GetCurNieREasterEggAgeInfo()
        if not CurActivityConfig then return 0, 0 end
        return CurActivityConfig.EasterEggMinAge, CurActivityConfig.EasterEggMaxAge
    end

    function XNieRManager.GetCurMaxEasterEggMessageCount()
        if not CurActivityConfig then return 0 end
        return CurActivityConfig.MaxEasterEggMessageCount
    end

    function XNieRManager.OpenNieREasterEggCom()
        if not XLuaUiManager.IsUiLoad("UiFunctionalOpen") then
            XLuaUiManager.Open("UiFunctionalOpen", XNieRConfigs.GetNieREasterEggComConfig(), false, false)
        end
    end

    function XNieRManager.OpenNieRDataSaveUi()
        XLuaUiManager.Open("UiNieRSaveData")
    end
    
    function XNieRManager.GetNieREasrerEggPlayerName()
        local lastName, nowName
        if LastSelEasterEggDataIndex == 0 then
            CurSelEasterEggDataIndex = CurSelEasterEggDataIndex + 1
            nowName = NieREasterEggData[CurSelEasterEggDataIndex].PlayerName
        else
            lastName = NieREasterEggData[LastSelEasterEggDataIndex].PlayerName
            nowName = NieREasterEggData[CurSelEasterEggDataIndex].PlayerName
        end
        LastSelEasterEggDataIndex = CurSelEasterEggDataIndex
        CurSelEasterEggDataIndex = CurSelEasterEggDataIndex + 1
        CurSelEasterEggDataIndex = CurSelEasterEggDataIndex > XNieRManager.GetCurMaxEasterEggMessageCount() and 1 or CurSelEasterEggDataIndex
        return lastName, nowName
    end

    --检查是否需要显示彩蛋关（每次BOSS数据更新后检查）
    function XNieRManager.CheckNieREasterEggStageShow()
        if NieREasterEggStageShow then return end
        for _, nieRBossData in pairs(NieRBossDic) do
            if not nieRBossData:IsBossDeath() then
                NieREasterEggStageShow = false
                return
            end
        end
        NieREasterEggStageShow = true
    end

    --获取彩蛋关显示状态
    function XNieRManager.GetNieREasterEggStageShow()
        return NieREasterEggStageShow
    end

    --是否第一次通过所有BOSS播放彩蛋剧情
    function XNieRManager.CheckFirstNieREasterEggStageShow()
        if NieREasterEggStageShow then
            if not XSaveTool.GetData(string.format("%d%s", XPlayer.Id, "NieREasterEggStageShow")) then
                XSaveTool.SaveData(string.format("%d%s", XPlayer.Id, "NieREasterEggStageShow"), true)
                return true
            end
        end
        return false
    end

    --检查彩蛋关是否已经完成
    function XNieRManager.CheckNieREasterEggStagePassed()
        return IsNieREasterEggDataRealPass
    end
    -----------------------------------------尼尔彩蛋关结束-----------------------------------------------
    -----------------------------------------尼尔内部条件检测----------------------------------------------
    function XNieRManager.CheckNieRMainLineUITips()
        local nierCharacterDic = XNieRManager.GetNieRCharacterDic() or {}

        if not NieRMainLineUITipsInfoInit then
            local nierChapterDataList = XNieRManager.GetChapterDataList() or {}
            for key, nieRCharacter in pairs(nierCharacterDic) do
                if not nieRCharacter:CheckNieRCharacterCondition() then
                    NieRCharacterOpenDic[key] = true
                end
            end
            for _, nieRChapter in pairs(nierChapterDataList) do
                local stageId = nieRChapter:GetNieRRepeatPoStageId()
                if not XDataCenter.FubenManager.CheckStageIsUnlock(stageId) then
                    NieRRepeatPoStageOpenDic[stageId] = true
                end
                stageId = nieRChapter:GetNieRBossStageId()
                if not XDataCenter.FubenManager.CheckStageIsUnlock(stageId) then
                    NieRBossStageOpenDic[stageId] = true
                end
            end
            NieRMainLineUITipsInfoInit = true
        else
            if not NierMainLineStagePass then return end
            local haveOpenBoss = {}
            local haveOpenCharacter = {}
            local haveOpenRepeatPo = {}
            for stageId, _ in pairs(NieRBossStageOpenDic) do
                if XDataCenter.FubenManager.CheckStageIsUnlock(stageId) then
                    haveOpenBoss[stageId] = true
                end
            end
            for characterId, _ in pairs(NieRCharacterOpenDic) do
                local character = nierCharacterDic[characterId]
                if character and character:CheckNieRCharacterCondition() then
                    haveOpenCharacter[characterId] = true
                end
            end
            for stageId, _ in pairs(NieRRepeatPoStageOpenDic) do
                if XDataCenter.FubenManager.CheckStageIsUnlock(stageId) then
                    haveOpenRepeatPo[stageId] = true
                end
            end
            for stageId, _ in pairs(haveOpenBoss) do
                NieRBossStageOpenDic[stageId] = nil
                XUiManager.TipMsgEnqueue(CS.XTextManager.GetText("NieRMainLineNewJieDuanOpenTips"))
            end
            for characterId, _ in pairs(haveOpenCharacter) do
                NieRCharacterOpenDic[characterId] = nil
                local character = nierCharacterDic[characterId]
                if character then
                    local name = character:GetNieRCharName()
                    XUiManager.TipMsgEnqueue(CS.XTextManager.GetText("NieRNewCharacterOpenTips", name))
                end
            end
            for stageId, _ in pairs(haveOpenRepeatPo) do
                NieRRepeatPoStageOpenDic[stageId] = nil
                XUiManager.TipMsgEnqueue(CS.XTextManager.GetText("NieRNewQuanXianStageOpenTips"))
            end
            NierMainLineStagePass = false
        end
    end

    --检查尼尔角色能力开启（优化TIPS弹出）
    function XNieRManager.CheckNieRCharacterAbilityOpen()
        local nierCharacterDic = XNieRManager.GetNieRCharacterDic() or {}
        if not NierCharacterAbilityDicInit then
            for _, nieRCharacter in pairs(nierCharacterDic) do
                local abilityConfigList = nieRCharacter:GetAllNieRAbilityConfigList()
                local tmpNotOpenAbility = {}
                for _, config in pairs(abilityConfigList) do
                    if config.Condition ~= 0 and not XConditionManager.CheckCondition(config.Condition) then
                        tmpNotOpenAbility[config.Id] = config
                    end
                end
                NieRCharacterAbilityDic[nieRCharacter:GetNieRCharacterId()] = tmpNotOpenAbility
            end
            NierCharacterAbilityDicInit = true
        else
            if not NieRRepeatExStagePass then return end
            for nieRCharacterId, notOpenAbilityList in pairs(NieRCharacterAbilityDic) do
                local haveOpenAbility = {}
                for _, config in pairs(notOpenAbilityList) do
                    if XConditionManager.CheckCondition(config.Condition) then
                        local tmp = {}
                        tmp.NieRCharacterId = nieRCharacterId
                        tmp.ConfigName = config.TitleStr or ""
                        haveOpenAbility[config.Id] = tmp
                    end
                end
                for id, info in pairs(haveOpenAbility) do
                    notOpenAbilityList[id] = nil
                    local nierCharacter = nierCharacterDic[info.NieRCharacterId]
                    if nierCharacter then
                        local name = nierCharacter:GetNieRCharName()
                        XUiManager.TipMsgEnqueue(CS.XTextManager.GetText("NieRCharacterAbilityOpenTips", name, info.ConfigName))
                    end

                end
            end
            NieRRepeatExStagePass = false
        end
    end

    -----------------------------------------尼尔内部条件检测结束-------------------------------------------
    function XNieRManager.SaveNieRRepeatRedCheckCount()
        -- local consumeId, consumCount = XNieRManager.GetRepeatStageConsumeId(), 0
        -- local haveCount = XDataCenter.ItemManager.GetCount(consumeId)
        -- SaveRepeatConsumCount = haveCount
        -- XSaveTool.SaveData(string.format("%d%s", XPlayer.Id, "NieRRepeatRedCheckCount"), haveCount)
        local nowTime = XTime.GetServerNowTimestamp()
        XSaveTool.SaveData(string.format("%d%s", XPlayer.Id, "NieRRepeatRedCheckCount"), nowTime)
    end

    function XNieRManager.CheckNieRRepeatRedTime()
        -- local saveCount
        -- if SaveRepeatConsumCount ~= 0 then
        --     saveCount = SaveRepeatConsumCount
        -- else
        --     saveCount = XSaveTool.GetData(string.format("%d%s", XPlayer.Id, "NieRRepeatRedCheckCount"))
        -- end
        -- if saveCount then
        --     return tonumber(saveCount)
        -- end
        -- return 0
        local saveTime = XSaveTool.GetData(string.format("%d%s", XPlayer.Id, "NieRRepeatRedCheckCount")) or 0
        local nowTime = XTime.GetServerNowTimestamp()
        local refreshTime = XTime.GetSeverTodayFreshTime()
        local lastRefreshTime = XTime.GetSeverYesterdayFreshTime()
        if saveTime <= refreshTime then
            if saveTime > lastRefreshTime then
                return false
            else
                return true
            end
        else
            return false
        end
    end

    --检查尼尔玩法复刷关红点
    function XNieRManager.CheckRepeatRed()
        if XNieRManager.GetIsActivityEnd() then return false end

        local nierRepeatList = XNieRManager.GetRepeatDataList()
        local consumeId, consumCount = XNieRManager.GetRepeatStageConsumeId(), 0
        local haveCount = XDataCenter.ItemManager.GetCount(consumeId)
        local haveCountEx = 0

        -- local saveCount
        -- if SaveRepeatConsumCount ~= 0 then
        --     saveCount = SaveRepeatConsumCount
        -- else
        --     saveCount = XSaveTool.GetData(string.format("%d%s", XPlayer.Id, "NieRRepeatRedCheckCount"))
        -- end
        -- if saveCount then
        --     local numCount = tonumber(saveCount)
        --     if numCount == haveCount then
        --         return false
        --     elseif numCount > haveCount then
        --         SaveRepeatConsumCount = haveCount
        --         XSaveTool.SaveData(string.format("%d%s", XPlayer.Id, "NieRRepeatRedCheckCount"), haveCount)
        --         return false
        --     end
        -- end
        if not XNieRManager.CheckNieRRepeatRedTime() then
            return false
        end

        for _, repeatData in ipairs(nierRepeatList) do
            if repeatData:CheckNieRRepeatMainStageUnlock() then
                consumCount = repeatData:GetNierRepeatStageConsumeCount()
                local stageCfg = XDataCenter.FubenManager.GetStageCfg(repeatData:GetNieRRepeatStageId())
                local needActionPoint = stageCfg.RequireActionPoint
                local haveActionPoint = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.ActionPoint)
                if haveCount >= consumCount and haveActionPoint >= needActionPoint then
                    return true
                end
                -- for _, stageId in ipairs(repeatData:GetNieRExStageIds()) do
                --     if repeatData:CheckNieRRepeatStageUnlock(stageId) then
                --         consumeId, consumCount = repeatData:GetExConsumIdAndCount(stageId)
                --         if consumeId ~= 0 then
                --             haveCountEx = XDataCenter.ItemManager.GetCount(consumeId)
                --             if haveCountEx >= consumCount then
                --                 return true
                --             end
                --         end
                --     end
                -- end
            end
        end
        return false
    end

    --检查尼尔玩家红点
    function XNieRManager.CheckNieRCharacterRed(characterId, isInfor, isTeach)
        if XNieRManager.GetIsActivityEnd() then return false end
        local nieRCharacterDic = XNieRManager.GetNieRCharacterDic() or {}
        if characterId > 0 then
            local nieRCharacter = nieRCharacterDic[characterId]
            if nieRCharacter and nieRCharacter:CheckNieRCharacterCondition() then
                if isInfor then
                    local inforList = XNieRConfigs.GetNieRCharacterInforListById(characterId)
                    for _, config in ipairs(inforList) do
                        local condit
                        if config.UnlockCondition ~= 0 then
                            condit = XConditionManager.CheckCondition(config.UnlockCondition)
                        else
                            condit = true
                        end
                        if condit then
                            if not XDataCenter.NieRManager.CheckCharacterInformationUnlock(config.Id, false) then
                                return true
                            end

                        end
                    end
                end
                if isTeach then
                    local teachingStageIds = nieRCharacter:GetTeachingStageIds()
                    for _, stageId in pairs(teachingStageIds) do
                        if XDataCenter.FubenManager.CheckStageIsUnlock(stageId) and not XDataCenter.FubenManager.CheckStageIsPass(stageId) then
                            return true
                        end
                    end
                end

            end
        else
            for tmpCharacterId, nieRCharacter in pairs(nieRCharacterDic) do
                if nieRCharacter:CheckNieRCharacterCondition() then
                    if isInfor then
                        local inforList = XNieRConfigs.GetNieRCharacterInforListById(tmpCharacterId)
                        for _, config in ipairs(inforList) do
                            local condit
                            if config.UnlockCondition ~= 0 then
                                condit = XConditionManager.CheckCondition(config.UnlockCondition)
                            else
                                condit = true
                            end
                            if condit then
                                if not XDataCenter.NieRManager.CheckCharacterInformationUnlock(config.Id, false) then
                                    return true
                                end

                            end
                        end
                    end
                    if isTeach then
                        local teaChaningStageIds = nieRCharacter:GetTeachingStageIds()
                        for _, stageId in pairs(teaChaningStageIds) do
                            if XDataCenter.FubenManager.CheckStageIsUnlock(stageId) and not XDataCenter.FubenManager.CheckStageIsPass(stageId) then
                                return true
                            end
                        end
                    end
                end
            end
        end
        return false
    end

    --检查尼尔POD红点
    function XNieRManager.CheckNieRPODRed()
        if XNieRManager.GetIsActivityEnd() then return false end
        local nieRPODData = XNieRManager.GetNieRPODData()
        if not nieRPODData then return false end
        for _, skill in pairs(nieRPODData:GetNieRPODSkillList()) do
            if nieRPODData:CheckNieRPODSkillActive(skill.SkillId) and nieRPODData:CheckNieRPODSkillUpLevel(skill.SkillId) then
                local cousumId, consumCount = nieRPODData:GetNieRPODSkillUpLevelItem(skill.SkillId)
                if cousumId ~= 0 then
                    local haveCount = XDataCenter.ItemManager.GetCount(cousumId)
                    if haveCount >= consumCount then
                        return true
                    end
                end

            end
        end
        return false
    end

    --检查尼尔活动入口可挑战条件
    function XNieRManager.CheckNieRCanFightTag()
        if not XNieRManager.CheckRepeatRed() then return false end

        --有角色未达到满级
        local nierCharacters = XNieRManager.GetCurDevelopCharacterIds()
        for _, characterId in pairs(nierCharacters) do
            local nieRCharacter = XNieRManager.GetNieRCharacterByCharacterId(characterId)
            if nieRCharacter:CheckNieRCharacterCondition() and not nieRCharacter:CheckNieRCharacterMaxLevel() then
                return true
            end
        end

        return false
    end

    function XNieRManager.OnActivityEnd()
        if CS.XFight.IsRunning or XLuaUiManager.IsUiLoad("UiLoading") then
            return
        end
        XUiManager.TipText("NieREnd")
        XLuaUiManager.RunMain()
    end

    --服务端下推部分
    --处理尼尔数据
    function XNieRManager.AsyncNieRData(notifyData)
        if notifyData.ActivityId ~= 0 then
            ActivityId = notifyData.ActivityId
            NieRRobotIdToCharacterIdDic = {}
            NieRCharacterDic = {}
            NieRBossDic = {}
            NieREasterEggStageShow = false
            IsNieREasterEggDataRealPass = false
            XNieRManager.CurActivtityConfigChange()
            local nierSaveActivityId =  XSaveTool.GetData(string.format("%d%s", XPlayer.Id, "NieRActivityIdSave"))
            if not nierSaveActivityId then
                XSaveTool.SaveData(string.format("%d%s", XPlayer.Id, "NieRActivityIdSave"), ActivityId)
            else
                if nierSaveActivityId ~= ActivityId then
                    XSaveTool.SaveData(string.format("%d%s", XPlayer.Id, "NieRActivityIdSave"), ActivityId)
                    XNieRManager.RemoveAllPreData()
                end
            end
        else
            ActivityId = XNieRConfigs.GetDefaultActivityId()
            IsNieREasterEggDataRealPass = false
            IsActivityEnd = true
            CurActivityConfig = false
            XNieRManager.CurActivtityConfigChange()
            XNieRManager.RemoveAllPreData()
            XEventManager.DispatchEvent(XEventId.EVENT_NIER_ACTIVITY_END)
            return
        end
        
        for _, data in ipairs(notifyData.Characters) do
            XNieRManager.UpdateNieRCharacterData(data)
        end
        if notifyData.Bosses then
            for _, data in ipairs(notifyData.Bosses) do
                XNieRManager.UpdateNieRBossData(data)
            end
        end
        XNieRManager.UpdateNieRPODData(notifyData.Support)
        XNieRManager.RegisterEditBattleProxy()
        XNieRManager.CheckNieREasterEggStageShow()
        IsNieREasterEggDataRealPass = notifyData.EasterEggFinish
        XEventManager.DispatchEvent(XEventId.EVENT_NIER_ACTIVITY_REFRESH)
    end

    --处理尼尔角色数据
    function XNieRManager.AsyncNieRCharacterData(notifyData)
        XNieRManager.UpdateNieRCharacterData(notifyData.Character)
        XEventManager.DispatchEvent(XEventId.EVENT_NIER_CHARACTER_UPDATE, notifyData.Character.CharacterId)
    end
    --服务端下推部分结束
    --服务器请求部分
    function XNieRManager.NieRCharacterChangeFashion(characterId, fashionId, func)
        XNetwork.Call(NieRRpc.NieRCharacterChangeFashion, {
            CharacterId = characterId,
            FashionId = fashionId
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XNieRManager.GetNieRCharacterByCharacterId(characterId):ChangeNieRFashionId(fashionId)
            if func then
                func()
            end
        end)
    end

    function XNieRManager.NieRUpdateBossScore(func)
        XNetwork.Call(NieRRpc.NieRUpdateBossScore, {

        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            if func then
                func()
            end
        end)
    end

    function XNieRManager.NieRUpgradeSupportSkill(skillId, func)
        XNetwork.Call(NieRRpc.NieRUpgradeSupportSkill, {
            SkillId = skillId
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            local nierPOD = XNieRManager.GetNieRPODData()
            nierPOD:AddNieRPODSkillLevelById(skillId)
            XEventManager.DispatchEvent(XEventId.EVENT_NIER_POD_UPDATE)
            if func then
                func()
            end
        end)
    end

    function XNieRManager.NieRSelectSupportSkill(skillId, func)
        XNetwork.Call(NieRRpc.NieRSelectSupportSkill, {
            SkillId = skillId
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            local nierPOD = XNieRManager.GetNieRPODData()
            nierPOD:SetNieRPODSelectSkillId(skillId)
            if func then
                func()
            end
        end)

    end

    function XNieRManager.NieREasterEggLeaveMessage(messageId, age, labelId, func)
        XNetwork.Call(NieRRpc.NieREasterEggLeaveMessage, {
            MessageId = messageId,
            Age = age,
            LabelId = labelId
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            if func then
                func(res.RewardGoodsList)
            end
        end)
    end
    --服务器请求部分结束
    --[[    ================
    本地初始化管理器
    ================
    ]]
    function XNieRManager.Init()
        XNieRManager.CurActivtityConfigChange()
        XNieRManager.UpdateNieREasterEggData({})
    end

    XNieRManager.Init()
    return XNieRManager
end

-- 通知玩法数据
XRpc.NotifyNieRData = function(notifyData)
    XDataCenter.NieRManager.AsyncNieRData(notifyData)
end

-- 通知玩法角色数据
XRpc.NotifyNieRCharacterData = function(notifyData)
    XDataCenter.NieRManager.AsyncNieRCharacterData(notifyData)
end

--通知玩法BOSS数据
XRpc.NotifyNieRBossData = function(notifyData)
    local bossData = XDataCenter.NieRManager.UpdateNieRBossData(notifyData.Boss)
    if bossData:IsBossDeath() then
        XDataCenter.NieRManager.CheckNieREasterEggStageShow()
    end
end

--通知辅助机数据
XRpc.NotifyNieRSupportData = function(notifyData)
    XDataCenter.NieRManager.UpdateNieRPODData(notifyData.Support)
    XEventManager.DispatchEvent(XEventId.EVENT_NIER_POD_UPDATE)
end

--通知彩蛋关数据
XRpc.NotifyNieREasterEggData = function(notifyData)
    XDataCenter.NieRManager.UpdateNieREasterEggData(notifyData.Messages)
end