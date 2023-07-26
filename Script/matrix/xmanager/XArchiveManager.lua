
--
-- Author: zhanghsuang、wujie
-- Note: 图鉴数据管理

XArchiveManagerCreator = function()
    local EntityType = {
        Info = 1,
        Setting = 2,
        Skill = 3,
    }

    local tableInsert = table.insert
    local XArchiveMonsterDetailEntity = require("XEntity/XArchive/XArchiveMonsterDetailEntity")
    local XArchiveMonsterEntity = require("XEntity/XArchive/XArchiveMonsterEntity")
    local XArchiveStoryChapterEntity = require("XEntity/XArchive/XArchiveStoryChapterEntity")
    local XArchiveStoryDetailEntity = require("XEntity/XArchive/XArchiveStoryDetailEntity")

    local XArchiveCGEntity = require("XEntity/XArchive/XArchiveCGEntity")
    local XArchiveCommunicationEntity = require("XEntity/XArchive/XArchiveCommunicationEntity")
    local XArchiveMailEntity = require("XEntity/XArchive/XArchiveMailEntity")
    local XArchiveNpcDetailEntity = require("XEntity/XArchive/XArchiveNpcDetailEntity")
    local XArchiveNpcEntity = require("XEntity/XArchive/XArchiveNpcEntity")
    local XArchivePartnerEntity = require("XEntity/XArchive/XArchivePartnerEntity")
    local XArchivePartnerSettingEntity = require("XEntity/XArchive/XArchivePartnerSettingEntity")

    local XArchiveManager ={}
    local ArchiveCfg = {}
    local ArchiveMonsterCfg = {}
    local ArchiveMonsterInfoCfg = {}
    local ArchiveMonsterSkillCfg = {}
    local ArchiveMonsterSettingCfg = {}

    -- local AwarenessSettingCfg = {}
    -- local WeaponSettingCfg = {}

    -- local ArchiveWeaponGroupCfg = {}
    local ArchiveWeaponTemplateIdToSettingListDic = {}
    local ArchiveAwarenessGroupCfg = {}

    local ArchiveStoryChapterCfg = {}
    local ArchiveStoryDetailCfg = {}

    local ArchiveStoryNpcCfg = {}
    local ArchiveStoryNpcSettingCfg = {}

    local ArchiveCGGroupCfg = {}
    local ArchiveCGDetailCfg = {}

    local ArchiveMailCfg = {}
    local ArchiveCommunicationCfg = {}
    local EventDateGroupCfg = {}

    local ArchiveAwarenessShowedStatusDic = {}
    local ArchiveShowedMonsterList = {}

    local ArchiveTagList = {}
    local ArchiveMonsterList = {}
    local ArchiveMonsterInfoList = {}
    local ArchiveMonsterSkillList = {}
    local ArchiveMonsterSettingList = {}

    local MonsterRedPointDic = {}

    local ArchiveNpcToMonster = {}
    local ArchiveMonsterData = {}

    local ArchiveStoryGroupList = {}
    local ArchiveStoryChapterList = {}
    local ArchiveStoryDetailList = {}
    local ArchiveStoryChapterDic = {}

    local ArchiveStoryNpcList = {}
    local ArchiveStoryNpcSettingList = {}

    local ArchiveCGDetailList = {}
    local ArchiveShowedCGList = {}
    local ArchiveCGDetailData = {}
    local ArchiveShowedStoryList = {}--只保存通关的活动关卡ID，到了解禁事件后会被清除

    local ArchiveMailList = {}
    local ArchiveCommunicationList = {}

    local ArchivePartnerList = {}
    local ArchivePartnerSettingList = {}
    local PartnerUnLockDic = {}
    local PartnerUnLockSettingDic = {}

    local ArchiveMonsterUnlockIdsList = {}
    local ArchiveMonsterInfoUnlockIdsList = {}
    local ArchiveMonsterSkillUnlockIdsList = {}
    local ArchiveMonsterSettingUnlockIdsList = {}

    local ArchiveMonsterEvaluateList = {}
    local ArchiveMonsterMySelfEvaluateList = {}
    local ArchiveStoryEvaluateList = {}
    local ArchiveStoryMySelfEvaluateList = {}

    local LastSyncMonsterEvaluateTimes = {}
    local LastSyncStoryEvaluateTimes = {}
    -- 记录服务端武器数据，以TemplateId为键
    local ArchiveWeaponServerData = {}
    -- 记录服务端意识数据，以TemplateId为键
    local ArchiveAwarenessServerData = {}
    -- 记录suitId对应获得的数量
    local ArchiveAwarenessSuitToAwarenessCountDic = {}
    -- 记录解锁的武器是否已读（解锁）（已读则无相关红点）
    local ArchiveWeaponUnlockServerData = {}
    -- 记录解锁的意识套装是否已读（解锁）
    local ArchiveAwarenessSuitUnlockServerData = {}
    -- 记录服务端武器设定已读（解锁）数据，以SettingId为键
    local ArchiveWeaponSettingUnlockServerData = {}
    -- 记录服务端意识设定已读（解锁）数据，以SettingId为键
    local ArchiveAwarenessSettingUnlockServerData = {}
    -- 记录服务端PV解锁Id
    local UnlockPvDetails = {}
    -- 记录解锁邮件图鉴
    local UnlockArchiveMails = {}

    -->>>红点相关
    local ArchiveWeaponRedPointCountDic = {}    --每个武器类型拥有的红点数量
    local ArchiveWeaponTotalRedPointCount = 0   --武器图鉴拥有的红点数量

    local ArchiveAwarenessSuitRedPointCountDic = {} --每个意识获取类型下对应套装拥有的红点数量
    local ArchiveAwarenessSuitTotalRedPointCount = 0    --意识图鉴拥有的红点数量

    local ArchiveWeaponSettingCanUnlockDic = {} --武器设定可以解锁的
    local ArchiveNewWeaponSettingIdsDic = {}  --武器id对应的新的武器设定ids
    local ArchiveWeaponSettingRedPointCountDic = {} --每个武器类型下对应设定拥有的红点数量
    local ArchiveWeaponSettingTotalRedPointCount = 0  --武器设定拥有的总红点数量

    local ArchiveAwarenessSettingCanUnlockDic = {} --意识设定可以解锁的
    local ArchiveNewAwarenessSettingIdsDic = {}  --意识suitId对应的新的设定ids
    local ArchiveAwarenessSettingRedPointCountDic = {} --每个意识获取类型下对应设定拥有的红点数量
    local ArchiveAwarenessSettingTotalRedPointCount = 0  --意识设定拥有的总红点数量
    --<<<红点相关

    XArchiveManager.EquipInfoChildUiType = {
        Details = 1,
        Setting = 2,
    }

    XArchiveManager.MonsterRedPointType = {
        Monster = 1,
        MonsterInfo = 2,
        MonsterSkill = 3,
        MonsterSetting = 4,
    }

    local SYNC_EVALUATE_SECOND = 5

    local METHOD_NAME = {
        GetEvaluateRequest = "GetEvaluateRequest",
        GetStoryEvaluateRequest = "GetStoryEvaluateRequest",
        ArchiveEvaluateRequest = "ArchiveEvaluateRequest",
        ArchiveGiveLikeRequest = "ArchiveGiveLikeRequest",
        UnlockMonsterSettingRequest = "UnlockMonsterSettingRequest",
        UnlockArchiveMonsterRequest = "UnlockArchiveMonsterRequest",
        UnlockMonsterInfoRequest = "UnlockMonsterInfoRequest",
        UnlockMonsterSkillRequest = "UnlockMonsterSkillRequest",

        UnlockArchiveWeaponRequest = "UnlockArchiveWeaponRequest",
        UnlockArchiveAwarenessRequest = "UnlockArchiveAwarenessRequest",
        UnlockWeaponSettingRequest = "UnlockWeaponSettingRequest",
        UnlockAwarenessSettingRequest = "UnlockAwarenessSettingRequest",
    }

    function XArchiveManager.Init()
        PartnerUnLockSettingDic = {}
        PartnerUnLockDic = {}
        
        ArchiveCfg = XArchiveConfigs.GetArchiveConfigs()--图鉴入口
        -- AwarenessSettingCfg = XArchiveConfigs.GetAwarenessSettings()--意识设定
        -- WeaponSettingCfg = XArchiveConfigs.GetWeaponSettings()--武器设定

        ArchiveMonsterCfg = XArchiveConfigs.GetArchiveMonsterConfigs()--图鉴怪物
        ArchiveTagList = XArchiveConfigs.GetArchiveTagAllList()--图鉴标签
        ArchiveMonsterInfoCfg = XArchiveConfigs.GetArchiveMonsterInfoConfigs()--图鉴怪物信息
        ArchiveMonsterSkillCfg = XArchiveConfigs.GetArchiveMonsterSkillConfigs()--图鉴怪物技能
        ArchiveMonsterSettingCfg = XArchiveConfigs.GetArchiveMonsterSettingConfigs()--图鉴怪物设定

        -- ArchiveWeaponGroupCfg = XArchiveConfigs.GetWeaponGroup()
        ArchiveWeaponTemplateIdToSettingListDic = XArchiveConfigs.GetWeaponTemplateIdToSettingListDic()
        ArchiveAwarenessGroupCfg = XArchiveConfigs.GetAwarenessGroup()
        ArchiveAwarenessShowedStatusDic = XArchiveConfigs.GetAwarenessShowedStatusDic()

        ArchiveStoryGroupList = XArchiveConfigs.GetArchiveStoryGroupAllList()
        ArchiveStoryChapterCfg = XArchiveConfigs.GetArchiveStoryChapterConfigs()
        ArchiveStoryDetailCfg = XArchiveConfigs.GetArchiveStoryDetailConfigs()

        ArchiveStoryNpcCfg = XArchiveConfigs.GetArchiveStoryNpcConfigs()--图鉴NPC
        ArchiveStoryNpcSettingCfg = XArchiveConfigs.GetArchiveStoryNpcSettingConfigs()--图鉴NPC设定

        ArchiveCGGroupCfg = XArchiveConfigs.GetArchiveCGGroupConfigs()--图鉴CG组信息
        ArchiveCGDetailCfg = XArchiveConfigs.GetArchiveCGDetailConfigs()--图鉴CG详情

        ArchiveMailCfg = XArchiveConfigs.GetArchiveMailsConfigs()
        ArchiveCommunicationCfg = XArchiveConfigs.GetArchiveCommunicationsConfigs()
        EventDateGroupCfg = XArchiveConfigs.GetEventDateGroupsConfigs()

        XArchiveManager.InitArchiveMonsterList()
        XArchiveManager.InitArchiveMonsterDetail(EntityType.Info,ArchiveMonsterInfoCfg,ArchiveMonsterInfoList,true)
        XArchiveManager.InitArchiveMonsterDetail(EntityType.Skill,ArchiveMonsterSkillCfg,ArchiveMonsterSkillList,false)
        XArchiveManager.InitArchiveMonsterDetail(EntityType.Setting,ArchiveMonsterSettingCfg,ArchiveMonsterSettingList,true)

        XArchiveManager.InitArchiveStoryChapterList()
        XArchiveManager.InitArchiveStoryDetailAllList()

        XArchiveManager.InitArchiveStoryNpcAllList()
        XArchiveManager.InitArchiveStoryNpcSettingAllList()

        XArchiveManager.InitArchiveCGAllList()

        XArchiveManager.InitArchiveMailList()
        XArchiveManager.InitArchiveCommunicationList()

        XArchiveManager.InitArchivePartnerSetting()
        XArchiveManager.InitArchivePartnerList()
    end
    
    --------------------------------怪物图鉴，数据初始化------------------------------------------>>>
    function XArchiveManager.InitArchiveMonsterList()
        ArchiveMonsterList = {}
        ArchiveNpcToMonster = {}
        ArchiveMonsterData = {}
        for _, monster in pairs(ArchiveMonsterCfg or {}) do
            if not ArchiveMonsterList[monster.Type] then
                ArchiveMonsterList[monster.Type] = {}
            end
            local tmp = XArchiveMonsterEntity.New(monster.Id)
            for _,id in pairs(monster.NpcId or {})do
                ArchiveNpcToMonster[id] = monster.Id
            end
            tableInsert(ArchiveMonsterList[monster.Type], tmp)
        end
        for _,list in pairs(ArchiveMonsterList)do
            XArchiveConfigs.SortByOrder(list)
            for _,monster in pairs(list) do
                ArchiveMonsterData[monster:GetId()] = monster
            end
        end
    end

    function XArchiveManager.InitArchiveMonsterDetail(entityType,detailCfg,allList,IsHavetype)
        for _, detail in pairs(detailCfg or {}) do

            if not allList[detail.GroupId] then
                allList[detail.GroupId] = {}
            end

            if IsHavetype and not allList[detail.GroupId][detail.Type] then
                allList[detail.GroupId][detail.Type] = {}
            end

            local tmp = XArchiveMonsterDetailEntity.New(entityType,detail.Id)

            if IsHavetype then
                table.insert(allList[detail.GroupId][detail.Type], tmp)
            else
                table.insert(allList[detail.GroupId], tmp)
            end
        end
        for _,group in pairs(allList) do
            if IsHavetype then
                for _,type in pairs(group) do
                    XArchiveConfigs.SortByOrder(type)
                end
            else
                XArchiveConfigs.SortByOrder(group)
            end
        end
    end
    --------------------------------怪物图鉴，数据初始化------------------------------------------<<<
    --------------------------------怪物图鉴，数据获取相关------------------------------------------>>>

    function XArchiveManager.GetArchiveMonsterEvaluate(npcId)
        return ArchiveMonsterEvaluateList[npcId] or {}
    end

    function XArchiveManager.GetArchiveMonsterMySelfEvaluate(npcId)
        return ArchiveMonsterMySelfEvaluateList[npcId] or {}
    end

    function XArchiveManager.GetArchiveMonsterEvaluateList()
        return ArchiveMonsterEvaluateList
    end

    function XArchiveManager.GetArchiveMonsterMySelfEvaluateList()
        return ArchiveMonsterMySelfEvaluateList
    end

    function XArchiveManager.GetArchiveMonsterUnlockIdsList()
        return ArchiveMonsterUnlockIdsList
    end

    function XArchiveManager.GetArchiveMonsterInfoUnlockIdsList()
        return ArchiveMonsterInfoUnlockIdsList
    end

    function XArchiveManager.GetArchiveMonsterSkillUnlockIdsList()
        return ArchiveMonsterSkillUnlockIdsList
    end

    function XArchiveManager.GetArchiveMonsterSettingUnlockIdsList()
        return ArchiveMonsterSettingUnlockIdsList
    end

    function XArchiveManager.GetArchiveMonsterEntityByNpcId(npcId)
        local monsterId = XArchiveManager.GetMonsterIdByNpcId(npcId)
        if monsterId == nil then
            XLog.Error(string.format("npcId:%s没有在Share/Archive/Monster.tab或SameNpcGroup.tab配置", npcId))
            return nil
        end
        return ArchiveMonsterData[monsterId]
    end

    function XArchiveManager.GetArchiveMonsterType(monsterId)
        return ArchiveMonsterData[monsterId] and ArchiveMonsterData[monsterId]:GetType() or nil
    end

    function XArchiveManager.GetArchives()------------------------------------修改技能设定等的条件判定
        local list = {}
        for _, v in pairs(ArchiveCfg) do
            local SkipFunctional = XFunctionConfig.GetSkipList(v.SkipId)
            if SkipFunctional and not XFunctionManager.CheckFunctionFitter(SkipFunctional.FunctionalId) then
                table.insert(list, v)
            end
        end
        --return XArchiveConfigs.SortByOrder(list)
        return list
    end

    function XArchiveManager.GetMonsterKillCount(npcId)
        local sameNpcId = XArchiveConfigs.GetSameNpcId(npcId)
        local monsterId = ArchiveNpcToMonster[sameNpcId]
        if not monsterId then return 0 end
        local killCount = ArchiveMonsterData[monsterId].Kill[sameNpcId]
        return killCount and killCount or 0
    end

    function XArchiveManager.GetMonsterArchiveName(monster)
        if monster:GetName() then
            return monster:GetName()
        end
        if monster:GetNpcId(1) then
            return XArchiveConfigs.GetMonsterRealName(monster:GetNpcId(1))
        end
        return "NULL"
    end

    function XArchiveManager.GetArchiveTagList(group)
        return ArchiveTagList[group]
    end

    function XArchiveManager.GetArchiveMonsterList(type)--type为空时不作为判断条件，获取相应类型的图鉴怪物列表
        if type then
            return ArchiveMonsterList[type] or {}
        end
        local list = {}
        for _,tmpType in pairs(ArchiveMonsterList) do
            for _,monster in pairs(tmpType) do
                tableInsert(list,monster)
            end
        end
        return XArchiveConfigs.SortByOrder(list)
    end

    function XArchiveManager.GetArchiveMonsterInfoList(groupId,type)--type为空时不作为判断条件，获取相应类型的图鉴怪物信息列表
        if type then
            return ArchiveMonsterInfoList[groupId] and ArchiveMonsterInfoList[groupId][type] or {}
        end
        local list = {}
        for _,tmpType in pairs(ArchiveMonsterInfoList[groupId]) do
            for _,monster in pairs(tmpType) do
                tableInsert(list,monster)
            end
        end
        return XArchiveConfigs.SortByOrder(list)
    end

    function XArchiveManager.GetArchiveMonsterSkillList(groupId)--groupId为空时不作为判断条件，获取相应类型的图鉴怪物技能列表
        if groupId then
            return ArchiveMonsterSkillList[groupId] or {}
        end
        local list = {}
        for _,group in pairs(ArchiveMonsterSkillList) do
            for _,monster in pairs(group) do
                tableInsert(list,monster)
            end
        end
        return XArchiveConfigs.SortByOrder(list)
    end

    function XArchiveManager.GetArchiveMonsterSettingList(groupId,type)--type为空时不作为判断条件，获取相应类型的图鉴怪物设定列表
        if type then
            return ArchiveMonsterSettingList[groupId] and ArchiveMonsterSettingList[groupId][type] or {}
        end
        local list = {}
        for _,tmpType in pairs(ArchiveMonsterSettingList[groupId]) do
            for _,monster in pairs(tmpType) do
                tableInsert(list,monster)
            end
        end
        return XArchiveConfigs.SortByOrder(list)
    end

    function XArchiveManager.GetMonsterCompletionRate(type)
        local monsterList = XArchiveManager.GetArchiveMonsterList(type)
        if #monsterList < 1 then
            return 0
        end
        local unlockCount = 0
        for _,v in pairs(monsterList or {}) do
            if not v.IsLockMain then
                unlockCount = unlockCount + 1
            end
        end
        return XArchiveManager.GetPercent((unlockCount / #monsterList) * 100)
    end

    function XArchiveManager.IsMonsterHaveRedPointByAll()
        local IsHaveRedPoint = false
        for type,_ in pairs(MonsterRedPointDic or {}) do
            if XArchiveManager.IsMonsterHaveRedPointByType(type) then
                IsHaveRedPoint = true
                break
            end
            if XArchiveManager.IsMonsterHaveNewTagByType(type) then
                IsHaveRedPoint = true
                break
            end
        end
        return IsHaveRedPoint
    end

    function XArchiveManager.IsMonsterHaveNewTagByType(type)
        local IsHaveNewTag = false
        for monsterId,_ in pairs(MonsterRedPointDic[type] or {}) do
            if XArchiveManager.IsMonsterHaveNewTagById(monsterId) then
                IsHaveNewTag = true
                break
            end
        end
        return IsHaveNewTag
    end

    function XArchiveManager.IsMonsterHaveRedPointByType(type)
        local IsHaveRedPoint = false
        for monsterId,_ in pairs(MonsterRedPointDic[type] or {}) do
            if XArchiveManager.IsMonsterHaveRedPointById(monsterId) then
                IsHaveRedPoint = true
                break
            end
        end
        return IsHaveRedPoint
    end

    function XArchiveManager.IsMonsterHaveNewTagById(monsterId)
        local monsterType = XArchiveManager.GetArchiveMonsterType(monsterId)
        return monsterType and MonsterRedPointDic[monsterType] and
        MonsterRedPointDic[monsterType][monsterId] and
        MonsterRedPointDic[monsterType][monsterId].IsNewMonster or false
    end

    function XArchiveManager.IsMonsterHaveRedPointById(monsterId)
        return XArchiveManager.IsHaveNewMonsterInfoByNpcId(monsterId) or
        XArchiveManager.IsHaveNewMonsterSkillByNpcId(monsterId) or
        XArchiveManager.IsHaveNewMonsterSettingByNpcId(monsterId)
    end

    function XArchiveManager.IsHaveNewMonsterInfoByNpcId(monsterId)
        local monsterType = XArchiveManager.GetArchiveMonsterType(monsterId)
        return monsterType and MonsterRedPointDic[monsterType] and
        MonsterRedPointDic[monsterType][monsterId] and
        MonsterRedPointDic[monsterType][monsterId].IsNewInfo or false
    end

    function XArchiveManager.IsHaveNewMonsterSkillByNpcId(monsterId)
        local monsterType = XArchiveManager.GetArchiveMonsterType(monsterId)
        return monsterType and MonsterRedPointDic[monsterType] and
        MonsterRedPointDic[monsterType][monsterId] and
        MonsterRedPointDic[monsterType][monsterId].IsNewSkill or false
    end

    function XArchiveManager.IsHaveNewMonsterSettingByNpcId(monsterId)
        local monsterType = XArchiveManager.GetArchiveMonsterType(monsterId)
        return monsterType and MonsterRedPointDic[monsterType] and
        MonsterRedPointDic[monsterType][monsterId] and
        MonsterRedPointDic[monsterType][monsterId].IsNewSetting or false
    end

    function XArchiveManager.IsArchiveMonsterUnlockByNpcId(monsterId)
        local id = ArchiveNpcToMonster[monsterId]
        if XTool.IsNumberValid(id) then
            return ArchiveMonsterUnlockIdsList[id]
        end
        return false
    end

    function XArchiveManager.IsArchiveMonsterUnlockByArchiveId(id)
        if XTool.IsNumberValid(id) then
            return ArchiveMonsterUnlockIdsList[id]
        end
        return false
    end
    --------------------------------怪物图鉴，数据获取相关------------------------------------------<<<

    --------------------------------怪物图鉴，数据更新相关------------------------------------------>>>
    function XArchiveManager.UpdateMonsterData()
        MonsterRedPointDic = {}
        XArchiveManager.UpdateMonsterList()
        XArchiveManager.UpdateMonsterInfoList()
        XArchiveManager.UpdateMonsterSettingList()
        XArchiveManager.UpdateMonsterSkillList()
        XEventManager.DispatchEvent(XEventId.EVNET_ARCHIVE_MONSTER_KILLCOUNTCHANGE)
    end

    function XArchiveManager.UpdateMonsterList() --更新图鉴怪物列表数据
        local killCount = {}
        local tmpData = {}
        for _,showedMonster in pairs(ArchiveShowedMonsterList or {}) do
            local sameNpcId = XArchiveConfigs.GetSameNpcId(showedMonster.Id)
            local monsterId = ArchiveNpcToMonster[sameNpcId]
            local monsterData = ArchiveMonsterData[monsterId]
            if monsterId and monsterData then
                tmpData.IsLockMain = false
                if not killCount[sameNpcId] then killCount[sameNpcId] = 0 end
                killCount[sameNpcId] = killCount[sameNpcId] + showedMonster.Killed
                tmpData.Kill = tmpData.Kill or {}
                tmpData.Kill[sameNpcId] = killCount[sameNpcId]
                monsterData:UpdateData(tmpData)
                XArchiveManager.SetMonsterRedPointDic(monsterId,XArchiveManager.MonsterRedPointType.Monster,nil)
            end
        end
    end

    function XArchiveManager.UpdateMonsterInfoList()--更新图鉴怪物信息列表数据
        for _,showedMonster in pairs(ArchiveShowedMonsterList or {}) do
            local sameNpcId = XArchiveConfigs.GetSameNpcId(showedMonster.Id)
            local monsterId = ArchiveNpcToMonster[sameNpcId]
            local monsterData = ArchiveMonsterData[monsterId]
            if monsterId and monsterData then
                for _,npcId in pairs(monsterData:GetNpcId() or {}) do
                    for _,type in pairs(ArchiveMonsterInfoList[npcId] or {}) do
                        for _,monsterInfo in pairs(type) do
                            local IsUnLock = false
                            local lockDes = ""
                            if monsterInfo:GetCondition() == 0 then
                                IsUnLock =true
                            else
                                IsUnLock,lockDes = XConditionManager.CheckCondition(monsterInfo:GetCondition(),monsterInfo:GetGroupId())
                            end
                            local tmpData = {}
                            tmpData.IsLock = not IsUnLock
                            tmpData.LockDesc = lockDes
                            monsterInfo:UpdateData(tmpData)
                            if IsUnLock then
                                XArchiveManager.SetMonsterRedPointDic(monsterId,XArchiveManager.MonsterRedPointType.MonsterInfo,monsterInfo:GetId())
                            end
                        end
                    end
                end
            end
        end
    end



    function XArchiveManager.UpdateMonsterSkillList()--更新图鉴怪物技能列表数据
        for _,showedMonster in pairs(ArchiveShowedMonsterList or {}) do
            local sameNpcId = XArchiveConfigs.GetSameNpcId(showedMonster.Id)
            local monsterId = ArchiveNpcToMonster[sameNpcId]
            local monsterData = ArchiveMonsterData[monsterId]
            if monsterId and monsterData then
                for _,npcId in pairs(monsterData:GetNpcId() or {}) do
                    for _,monsterSkill in pairs(ArchiveMonsterSkillList[npcId] or {}) do
                        local IsUnLock = false
                        local lockDes = ""
                        if monsterSkill:GetCondition() == 0 then
                            IsUnLock =true
                        else
                            IsUnLock,lockDes = XConditionManager.CheckCondition(monsterSkill:GetCondition(),monsterSkill:GetGroupId())
                        end
                        local tmpData = {}
                        tmpData.IsLock = not IsUnLock
                        tmpData.LockDesc = lockDes
                        monsterSkill:UpdateData(tmpData)
                        if IsUnLock then
                            XArchiveManager.SetMonsterRedPointDic(monsterId,XArchiveManager.MonsterRedPointType.MonsterSkill,monsterSkill:GetId())
                        end
                    end
                end
            end
        end
    end

    function XArchiveManager.UpdateMonsterSettingList()--更新图鉴怪物设定列表数据
        for _,showedMonster in pairs(ArchiveShowedMonsterList or {}) do
            local sameNpcId = XArchiveConfigs.GetSameNpcId(showedMonster.Id)
            local monsterId = ArchiveNpcToMonster[sameNpcId]
            local monsterData = ArchiveMonsterData[monsterId]
            if monsterId and monsterData then
                for _,npcId in pairs(monsterData:GetNpcId() or {}) do
                    for _,type in pairs(ArchiveMonsterSettingList[npcId] or {}) do
                        for _,monsterStting in pairs(type) do
                            local IsUnLock = false
                            local lockDes = ""
                            if monsterStting:GetCondition() == 0 then
                                IsUnLock =true
                            else
                                IsUnLock,lockDes = XConditionManager.CheckCondition(monsterStting:GetCondition(),monsterStting:GetGroupId())
                            end
                            local tmpData = {}
                            tmpData.IsLock = not IsUnLock
                            tmpData.LockDesc = lockDes
                            monsterStting:UpdateData(tmpData)
                            if IsUnLock then
                                XArchiveManager.SetMonsterRedPointDic(monsterId,XArchiveManager.MonsterRedPointType.MonsterSetting,monsterStting:GetId())
                            end
                        end
                    end
                end
            end
        end
    end

    function XArchiveManager.SetMonsterRedPointDic(monsterId,type,id)
        local monsterType = XArchiveManager.GetArchiveMonsterType(monsterId)
        if not monsterType then return end
        if not MonsterRedPointDic[monsterType] then
            MonsterRedPointDic[monsterType] = {}
        end
        if not MonsterRedPointDic[monsterType][monsterId] then
            MonsterRedPointDic[monsterType][monsterId] = {}
        end
        if type == XArchiveManager.MonsterRedPointType.Monster then
            if not ArchiveMonsterUnlockIdsList[monsterId] then
                MonsterRedPointDic[monsterType][monsterId].IsNewMonster = true
            end
        elseif type == XArchiveManager.MonsterRedPointType.MonsterInfo then
            if not ArchiveMonsterInfoUnlockIdsList[id] then
                MonsterRedPointDic[monsterType][monsterId].IsNewInfo = true
            end
        elseif type == XArchiveManager.MonsterRedPointType.MonsterSkill then
            if not ArchiveMonsterSkillUnlockIdsList[id] then
                MonsterRedPointDic[monsterType][monsterId].IsNewSkill = true
            end
        elseif type == XArchiveManager.MonsterRedPointType.MonsterSetting then
            if not ArchiveMonsterSettingUnlockIdsList[id] then
                MonsterRedPointDic[monsterType][monsterId].IsNewSetting = true
            end
        end

    end

    function XArchiveManager.ClearMonsterRedPointDic(monsterId,type)
        local monsterType = XArchiveManager.GetArchiveMonsterType(monsterId)
        if not monsterType then return end
        if not MonsterRedPointDic[monsterType] then return end
        if not MonsterRedPointDic[monsterType][monsterId] then return end
        if type == XArchiveManager.MonsterRedPointType.Monster then
            MonsterRedPointDic[monsterType][monsterId].IsNewMonster = false
        elseif type == XArchiveManager.MonsterRedPointType.MonsterInfo then
            MonsterRedPointDic[monsterType][monsterId].IsNewInfo = false
        elseif type == XArchiveManager.MonsterRedPointType.MonsterSkill then
            MonsterRedPointDic[monsterType][monsterId].IsNewSkill = false
        elseif type == XArchiveManager.MonsterRedPointType.MonsterSetting then
            MonsterRedPointDic[monsterType][monsterId].IsNewSetting = false
        end
        if not MonsterRedPointDic[monsterType][monsterId].IsNewMonster and
            not MonsterRedPointDic[monsterType][monsterId].IsNewInfo and
            not MonsterRedPointDic[monsterType][monsterId].IsNewSkill and
            not MonsterRedPointDic[monsterType][monsterId].IsNewSetting then

            MonsterRedPointDic[monsterType][monsterId] = nil
        end
    end

    function XArchiveManager.SetArchiveShowedMonsterList(list)
        for _,monster in pairs(list or {}) do
            ArchiveShowedMonsterList[monster.Id] = monster
        end
    end

    function XArchiveManager.AddArchiveShowedMonsterList(list)
        for _,monster in pairs(list or {}) do
            if not ArchiveShowedMonsterList[monster] then
                ArchiveShowedMonsterList[monster.Id] = monster
            else
                ArchiveShowedMonsterList[monster.Id].Killed = monster.Killed
            end
        end
    end

    function XArchiveManager.SetArchiveMonsterEvaluate(evaluates)
        for _,evaluate in pairs(evaluates or {}) do
            if evaluate and evaluate.Id then
                ArchiveMonsterEvaluateList[evaluate.Id] = evaluate
                for index,tag in pairs(ArchiveMonsterEvaluateList[evaluate.Id].Tags) do
                    local tagCfg = XArchiveConfigs.GetArchiveTagCfgById(tag.Id)
                    if tagCfg and tagCfg.IsNotShow == 1 then
                        ArchiveMonsterEvaluateList[evaluate.Id].Tags[index] = nil
                    end
                end
            end
        end
    end

    function XArchiveManager.SetArchiveMonsterMySelfEvaluate(mySelfEvaluates)
        for _,mySelfEvaluate in pairs(mySelfEvaluates or {}) do
            if mySelfEvaluate and mySelfEvaluate.Id then
                ArchiveMonsterMySelfEvaluateList[mySelfEvaluate.Id] = mySelfEvaluate
                for index,tag in pairs(ArchiveMonsterMySelfEvaluateList[mySelfEvaluate.Id].Tags) do
                    local tagCfg = XArchiveConfigs.GetArchiveTagCfgById(tag)
                    if tagCfg and tagCfg.IsNotShow == 1 then
                        ArchiveMonsterMySelfEvaluateList[mySelfEvaluate.Id].Tags[index] = nil
                    end
                end
            end
        end
    end

    function XArchiveManager.SetArchiveMonsterMySelfEvaluateLikeStatus(npcId,likeState)
        if not ArchiveMonsterMySelfEvaluateList[npcId] then
            ArchiveMonsterMySelfEvaluateList[npcId] ={}
        end
        ArchiveMonsterMySelfEvaluateList[npcId].LikeStatus = likeState
    end

    function XArchiveManager.SetArchiveMonsterMySelfEvaluateDifficulty(npcId,score,difficulty,tags)
        if not ArchiveMonsterMySelfEvaluateList[npcId] then
            ArchiveMonsterMySelfEvaluateList[npcId] ={}
        end
        ArchiveMonsterMySelfEvaluateList[npcId].Score = score
        ArchiveMonsterMySelfEvaluateList[npcId].Difficulty = difficulty
        ArchiveMonsterMySelfEvaluateList[npcId].Tags = tags
    end

    function XArchiveManager.SetArchiveMonsterUnlockIdsList(list)
        for _,id in pairs(list) do
            ArchiveMonsterUnlockIdsList[id] = true
        end
    end

    function XArchiveManager.SetArchiveMonsterInfoUnlockIdsList(list)
        for _,id in pairs(list) do
            ArchiveMonsterInfoUnlockIdsList[id] = true
        end
    end

    function XArchiveManager.SetArchiveMonsterSkillUnlockIdsList(list)
        for _,id in pairs(list) do
            ArchiveMonsterSkillUnlockIdsList[id] = true
        end
    end

    function XArchiveManager.SetArchiveMonsterSettingUnlockIdsList(list)
        for _,id in pairs(list) do
            ArchiveMonsterSettingUnlockIdsList[id] = true
        end
    end

    function XArchiveManager.ClearMonsterNewTag(datas)
        local idList = {}

        if not datas then
            return
        end

        local IsHasNew = false
        for _,data in pairs(datas) do
            if XArchiveManager.IsMonsterHaveNewTagById(data.Id) then
                IsHasNew = true
                break
            end
        end
        if not IsHasNew then return end

        for _,data in pairs(datas) do
            if not data.IsLockMain then
                tableInsert(idList,data.Id)
            end
        end

        if #idList < 1 then
            return
        end

        XDataCenter.ArchiveManager.UnlockArchiveMonster(idList,function ()
                for _,id in pairs(idList) do
                    XDataCenter.ArchiveManager.ClearMonsterRedPointDic(id,XDataCenter.ArchiveManager.MonsterRedPointType.Monster)
                end
                XDataCenter.ArchiveManager.SetArchiveMonsterUnlockIdsList(idList)
                XEventManager.DispatchEvent(XEventId.EVNET_ARCHIVE_MONSTER_UNLOCKMONSTER)
            end)
    end

    function XArchiveManager.ClearDetailRedPoint(type,datas)
        local idList = {}
        if not datas then
            return
        end
        --------------------检测各类型是否有新增记录------------------
        if type == XArchiveConfigs.MonsterDetailType.Info then
            local IsHasNew = false
            for _,data in pairs(datas) do
                if XArchiveManager.IsHaveNewMonsterInfoByNpcId(data:GetId()) then
                    IsHasNew = true
                    break
                end
            end
            if not IsHasNew then return end
        elseif type == XArchiveConfigs.MonsterDetailType.Setting then
            local IsHasNew = false
            for _,data in pairs(datas) do
                if XArchiveManager.IsHaveNewMonsterSettingByNpcId(data:GetId()) then
                    IsHasNew = true
                    break
                end
            end
            if not IsHasNew then return end
        elseif type == XArchiveConfigs.MonsterDetailType.Skill then
            local IsHasNew = false
            for _,data in pairs(datas) do
                if XArchiveManager.IsHaveNewMonsterSkillByNpcId(data:GetId()) then
                    IsHasNew = true
                    break
                end
            end
            if not IsHasNew then return end
        end
        --------------------将各类型新增记录的ID放入一个List------------------
        for _,data in pairs(datas) do
            for _,npcId in pairs(data:GetNpcId() or {}) do
                if type == XArchiveConfigs.MonsterDetailType.Info then
                    local list = XArchiveManager.GetArchiveMonsterInfoList(npcId,nil)
                    for _,info in pairs(list or {}) do
                        if not info:GetIsLock() then
                            tableInsert(idList,info:GetId())
                        end
                    end
                elseif type == XArchiveConfigs.MonsterDetailType.Setting then
                    local list = XArchiveManager.GetArchiveMonsterSettingList(npcId,nil)
                    for _,setting in pairs(list or {}) do
                        if not setting:GetIsLock() then
                            tableInsert(idList,setting:GetId())
                        end
                    end
                elseif type == XArchiveConfigs.MonsterDetailType.Skill then
                    local list = XArchiveManager.GetArchiveMonsterSkillList(npcId)
                    for _,skill in pairs(list or {}) do
                        if not skill:GetIsLock() then
                            tableInsert(idList,skill:GetId())
                        end
                    end
                end
            end
        end

        if #idList < 1 then
            return
        end
        --------------------将各类型新增记录的红点取消通知服务器------------------
        if type == XArchiveConfigs.MonsterDetailType.Info then
            XArchiveManager.UnlockMonsterInfo(idList,function ()
                    for _,data in pairs(datas) do
                        XArchiveManager.ClearMonsterRedPointDic(data:GetId(),XArchiveManager.MonsterRedPointType.MonsterInfo)
                    end
                    XArchiveManager.SetArchiveMonsterInfoUnlockIdsList(idList)
                    XEventManager.DispatchEvent(XEventId.EVNET_ARCHIVE_MONSTER_UNLOCKMONSTERINFO)
                end)
        elseif type == XArchiveConfigs.MonsterDetailType.Setting then
            XArchiveManager.UnlockMonsterSetting(idList,function ()
                    for _,data in pairs(datas) do
                        XArchiveManager.ClearMonsterRedPointDic(data:GetId(),XArchiveManager.MonsterRedPointType.MonsterSetting)
                    end
                    XArchiveManager.SetArchiveMonsterSettingUnlockIdsList(idList)
                    XEventManager.DispatchEvent(XEventId.EVNET_ARCHIVE_MONSTER_UNLOCKMONSTERSETTING)
                end)
        elseif type == XArchiveConfigs.MonsterDetailType.Skill then
            XArchiveManager.UnlockMonsterSkill(idList,function ()
                    for _,data in pairs(datas) do
                        XArchiveManager.ClearMonsterRedPointDic(data:GetId(),XArchiveManager.MonsterRedPointType.MonsterSkill)
                    end
                    XArchiveManager.SetArchiveMonsterSkillUnlockIdsList(idList)
                    XEventManager.DispatchEvent(XEventId.EVNET_ARCHIVE_MONSTER_UNLOCKMONSTERSKILL)
                end)
        end
    end

    function XArchiveManager.GetMonsterEvaluateFromSever(NpcIds, cb)
        local now = XTime.GetServerNowTimestamp()
        local monsterId = ArchiveNpcToMonster[NpcIds[1]]
        local syscTime = LastSyncMonsterEvaluateTimes[monsterId]

        if syscTime and now - syscTime < SYNC_EVALUATE_SECOND then
            if cb then
                cb()
                return
            end
        end

        XNetwork.Call(METHOD_NAME.GetEvaluateRequest, {Ids = NpcIds}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                XArchiveManager.SetArchiveMonsterEvaluate(res.Evaluates)
                XArchiveManager.SetArchiveMonsterMySelfEvaluate(res.PersonalEvaluates)
                LastSyncMonsterEvaluateTimes[monsterId] = XTime.GetServerNowTimestamp()
                if cb then cb() end
            end)
    end

    function XArchiveManager.MonsterGiveEvaluate(npcId ,score ,difficulty ,tags ,cbBeFore ,cbAfter)
        local type = XArchiveConfigs.SubSystemType.Monster
        local tb = {Id = npcId ,Type = type ,Score = score ,Difficulty = difficulty ,Tags = tags}
        XNetwork.Call(METHOD_NAME.ArchiveEvaluateRequest, tb, function(res)
                if cbBeFore then cbBeFore() end
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                XArchiveManager.SetArchiveMonsterMySelfEvaluateDifficulty(npcId,score,difficulty,tags)
                if cbAfter then cbAfter() end
            end)
    end

    function XArchiveManager.MonsterGiveLike(likeList ,cb)
        local type = XArchiveConfigs.SubSystemType.Monster
        XNetwork.Call(METHOD_NAME.ArchiveGiveLikeRequest, {LikeList = likeList ,Type = type}, function(res)
                if cb then cb() end
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                for _,id in pairs(res.SuccessIds or {}) do
                    for _,like in pairs(likeList or {}) do
                        if id == like.Id then
                            XArchiveManager.SetArchiveMonsterMySelfEvaluateLikeStatus(id,like.LikeStatus)
                        end
                    end
                end
            end)
    end

    function XArchiveManager.UnlockArchiveMonster(ids,cb)
        local list = {}
        for _,id in pairs(ids or {}) do
            if not ArchiveMonsterUnlockIdsList[id] then
                tableInsert(list,id)
            end
        end
        if #list == 0 then
            return
        end
        XNetwork.Call(METHOD_NAME.UnlockArchiveMonsterRequest, {Ids = list}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                if cb then cb() end
            end)
    end

    function XArchiveManager.UnlockMonsterInfo(ids,cb)
        local list = {}
        for _,id in pairs(ids or {}) do
            if not ArchiveMonsterInfoUnlockIdsList[id] then
                tableInsert(list,id)
            end
        end
        if #list == 0 then
            return
        end
        XNetwork.Call(METHOD_NAME.UnlockMonsterInfoRequest, {Ids = ids}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                if cb then cb() end
            end)
    end

    function XArchiveManager.UnlockMonsterSkill(ids,cb)
        local list = {}
        for _,id in pairs(ids or {}) do
            if not ArchiveMonsterSkillUnlockIdsList[id] then
                tableInsert(list,id)
            end
        end
        if #list == 0 then
            return
        end
        XNetwork.Call(METHOD_NAME.UnlockMonsterSkillRequest, {Ids = ids}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                if cb then cb() end
            end)
    end

    function XArchiveManager.UnlockMonsterSetting(ids,cb)
        local list = {}
        for _,id in pairs(ids or {}) do
            if not ArchiveMonsterSettingUnlockIdsList[id] then
                tableInsert(list,id)
            end
        end
        if #list == 0 then
            return
        end
        XNetwork.Call(METHOD_NAME.UnlockMonsterSettingRequest, {Ids = ids}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                if cb then cb() end
            end)
    end
    --------------------------------怪物图鉴，数据更新相关------------------------------------------<<<
    --检查怪物的开放列表以及怪物的从属信息列表，检查是否有关于某个怪的新增，关于某个怪的信息开放
    --------------------------------怪物图鉴，数据检查相关------------------------------------------>>>
    --------------------------------怪物图鉴，数据检查相关------------------------------------------<<<

    -- 武器、意识部分------------------->>>

    -- 武器相关
    function XArchiveManager.IsWeaponGet(templateId)
        return ArchiveWeaponServerData[templateId] ~= nil
    end

    function XArchiveManager.GetWeaponCollectRate()
        local sumNum = XArchiveConfigs.GetWeaponSumCollectNum()
        if sumNum == 0 then
            return 0
        end
        local haveNum = 0
        for _, _ in pairs(ArchiveWeaponServerData) do
            haveNum = haveNum + 1
        end
        return XArchiveManager.GetPercent(haveNum * 100 / sumNum)
    end

    -- 武器new标签
    function XArchiveManager.IsNewWeapon(templateId)
        local isNew = false
        if not ArchiveWeaponUnlockServerData[templateId] and ArchiveWeaponServerData[templateId] then
            isNew = true
        end

        return isNew
    end

    -- 某个武器类型下是否有new标签
    function XArchiveManager.IsHaveNewWeaponByWeaponType(type)
        return ArchiveWeaponRedPointCountDic[type] > 0
    end

    -- 武器图鉴是否有new标签
    function XArchiveManager.IsHaveNewWeapon()
        return ArchiveWeaponTotalRedPointCount > 0
    end

    -- 武器图鉴是否有红点
    function XArchiveManager.IsNewWeaponSetting(templateId)
        local newSettingList = ArchiveNewWeaponSettingIdsDic[templateId]
        if newSettingList and #newSettingList > 0 then
            return true
        end
        return false
    end

    function XArchiveManager.IsWeaponSettingOpen(settingId)
        return ArchiveWeaponSettingUnlockServerData[settingId] or ArchiveWeaponSettingCanUnlockDic[settingId] == true
    end

    -- 武器设定有红点的列表,列表可能为空
    function XArchiveManager.GetNewWeaponSettingIdList(templateId)
        return ArchiveNewWeaponSettingIdsDic[templateId]
    end

    -- 某个武器类型下是否有红点
    function XArchiveManager.IsHaveNewWeaponSettingByWeaponType(type)
        return ArchiveWeaponSettingRedPointCountDic[type] > 0
    end

    -- 武器图鉴是否有红点
    function XArchiveManager.IsHaveNewWeaponSetting()
        return ArchiveWeaponSettingTotalRedPointCount > 0
    end

    -- 意识相关
    function XArchiveManager.IsAwarenessGet(templateId)
        return ArchiveAwarenessServerData[templateId] ~= nil
    end

    function XArchiveManager.GetAwarenessCollectRate()
        local sumNum = XArchiveConfigs.GetAwarenessSumCollectNum()
        if sumNum == 0 then
            return 0
        end
        local haveNum = 0
        for _, _ in pairs(ArchiveAwarenessServerData) do
            haveNum = haveNum + 1
        end
        return XArchiveManager.GetPercent(haveNum * 100 / sumNum)
    end

    -- 意识new标签
    function XArchiveManager.IsNewAwarenessSuit(suitId)
        local isNew = false
        if not ArchiveAwarenessSuitUnlockServerData[suitId] and ArchiveAwarenessSuitToAwarenessCountDic[suitId] then
            isNew = true
        end
        return isNew
    end

    -- 某个意识的获得类型下是否有new标签
    function XArchiveManager.IsHaveNewAwarenessSuitByGetType(type)
        return ArchiveAwarenessSuitRedPointCountDic[type] > 0
    end

    -- 意识图鉴是否有new标签
    function XArchiveManager.IsHaveNewAwarenessSuit()
        return ArchiveAwarenessSuitTotalRedPointCount > 0
    end

    -- 意识设定是否有红点
    function XArchiveManager.IsNewAwarenessSetting(suitId)
        local newSettingList = ArchiveNewAwarenessSettingIdsDic[suitId]
        if newSettingList and #newSettingList > 0 then
            return true
        end
        return false
    end

    function XArchiveManager.IsAwarenessSettingOpen(settingId)
        return ArchiveAwarenessSettingUnlockServerData[settingId] or ArchiveAwarenessSettingCanUnlockDic[settingId] == true
    end

    -- 有红点的意识列表
    function XArchiveManager.GetNewAwarenessSettingIdList(suitId)
        return ArchiveNewAwarenessSettingIdsDic[suitId]
    end

    -- 意识图鉴是否有红点
    function XArchiveManager.IsHaveNewAwarenessSetting()
        return ArchiveAwarenessSettingTotalRedPointCount > 0
    end

    -- 意识的获得类型下是否有红点
    function XArchiveManager.IsHaveNewAwarenessSettingByGetType(type)
        return ArchiveAwarenessSettingRedPointCountDic[type] > 0
    end

    function XArchiveManager.GetAwarenessCountBySuitId(suitId)
        return ArchiveAwarenessSuitToAwarenessCountDic[suitId] or 0
    end

    function XArchiveManager.IsEquipGet(templateId)
        return XArchiveManager.IsWeaponGet(templateId) or XArchiveManager.IsAwarenessGet(templateId)
    end

    function XArchiveManager.GetEquipLv(templateId)
        local data = ArchiveWeaponServerData[templateId] or ArchiveAwarenessServerData[templateId]
        return data and data.Level or 0
    end

    function XArchiveManager.GetEquipBreakThroughTimes(templateId)
        local data = ArchiveWeaponServerData[templateId] or ArchiveAwarenessServerData[templateId]
        return data and data.Breakthrough or 0
    end

    function XArchiveManager.CheckSpecialEquip()
        local specialData = XArchiveConfigs.SpecialData
        local data = ArchiveWeaponServerData[specialData.Equip.Id]
        local settingListDic = ArchiveWeaponTemplateIdToSettingListDic[specialData.Equip.Id]
        if not data and settingListDic then
            local state = XDataCenter.PurchaseManager.PurchaseAddRewardState(specialData.PayRewardId)
            if state == XPurchaseConfigs.PurchaseRewardAddState.Geted then
                ArchiveWeaponServerData[specialData.Equip.Id] = specialData.Equip
            end
        end
    end

    -- 从服务端获取武器和意识相关数据
    function XArchiveManager.SetEquipServerData(equipData)
        ArchiveAwarenessSuitToAwarenessCountDic = {}
        local templateId
        local suitId
        --只有在配置表中出现id才会记录在本地的serverData
        for _, data in ipairs(equipData) do
            templateId = data.Id
            if XDataCenter.EquipManager.IsWeaponByTemplateId(templateId) and ArchiveWeaponTemplateIdToSettingListDic[templateId] then
                ArchiveWeaponServerData[templateId] = data
            elseif XDataCenter.EquipManager.IsAwarenessByTemplateId(templateId) and ArchiveAwarenessShowedStatusDic[templateId] then
                ArchiveAwarenessServerData[templateId] = data
                suitId = XDataCenter.EquipManager.GetSuitIdByTemplateId(templateId)
                ArchiveAwarenessSuitToAwarenessCountDic[suitId] = ArchiveAwarenessSuitToAwarenessCountDic[suitId] or 0
                ArchiveAwarenessSuitToAwarenessCountDic[suitId] = ArchiveAwarenessSuitToAwarenessCountDic[suitId] + 1
            end
        end
    end

    -- 从服务端获取武器和意识相关数据，并判断是否有新的武器或者意识
    function XArchiveManager.UpdateEquipServerData(equipData)
        local templateId
        --只有在配置表中出现id才会记录在本地的serverData
        local isNewWeaponSetting = false
        local isNewAwarenessSetting = false
        local weaponIdList
        local awarenessSuitIdList
        local suitId
        local weaponType
        local awarenessSuitGetType
        local settingDataList
        local settingId
        local conditionId
        local updateSuitIdDic
        for _, data in ipairs(equipData) do
            templateId = data.Id
            if XDataCenter.EquipManager.IsWeaponByTemplateId(templateId) and ArchiveWeaponTemplateIdToSettingListDic[templateId] then
                weaponType = XDataCenter.EquipManager.GetEquipTypeByTemplateId(templateId)
                if not ArchiveWeaponUnlockServerData[templateId] then
                    weaponIdList = weaponIdList or {}
                    tableInsert(weaponIdList, templateId)
                    if not ArchiveWeaponServerData[templateId] then
                        ArchiveWeaponRedPointCountDic[weaponType] =  ArchiveWeaponRedPointCountDic[weaponType] + 1
                        ArchiveWeaponTotalRedPointCount = ArchiveWeaponTotalRedPointCount + 1
                    end
                end
                ArchiveWeaponServerData[templateId] = data
                settingDataList = XArchiveConfigs.GetWeaponSettingList(templateId)
                for _, settingData in ipairs(settingDataList) do
                    settingId = settingData.Id
                    conditionId = settingData.Condition
                    if not ArchiveWeaponSettingUnlockServerData[settingId] then
                        if not ArchiveWeaponSettingCanUnlockDic[settingId] and XConditionManager.CheckCondition(conditionId, templateId) then
                            isNewWeaponSetting = true
                            ArchiveWeaponSettingCanUnlockDic[settingId] = true
                            ArchiveNewWeaponSettingIdsDic[templateId] = ArchiveNewWeaponSettingIdsDic[templateId] or {}
                            table.insert(ArchiveNewWeaponSettingIdsDic[templateId], settingId)
                            ArchiveWeaponSettingRedPointCountDic[weaponType] = ArchiveWeaponSettingRedPointCountDic[weaponType] + 1
                            ArchiveWeaponSettingTotalRedPointCount = ArchiveWeaponSettingTotalRedPointCount + 1
                        end
                    end
                end

            elseif XDataCenter.EquipManager.IsAwarenessByTemplateId(templateId) and ArchiveAwarenessShowedStatusDic[templateId] then
                suitId = XDataCenter.EquipManager.GetSuitIdByTemplateId(templateId)
                updateSuitIdDic = updateSuitIdDic or {}
                updateSuitIdDic[suitId] = true
                if not ArchiveAwarenessServerData[templateId] then
                    if not ArchiveAwarenessSuitToAwarenessCountDic[suitId] then
                        awarenessSuitIdList = awarenessSuitIdList or {}
                        tableInsert(awarenessSuitIdList, suitId)
                        awarenessSuitGetType = XArchiveConfigs.GetAwarenessSuitInfoGetType(suitId)
                        ArchiveAwarenessSuitRedPointCountDic[awarenessSuitGetType] = ArchiveAwarenessSuitRedPointCountDic[awarenessSuitGetType] + 1
                        ArchiveAwarenessSuitTotalRedPointCount = ArchiveAwarenessSuitTotalRedPointCount + 1
                    end
                    ArchiveAwarenessSuitToAwarenessCountDic[suitId] = ArchiveAwarenessSuitToAwarenessCountDic[suitId] or 0
                    ArchiveAwarenessSuitToAwarenessCountDic[suitId] = ArchiveAwarenessSuitToAwarenessCountDic[suitId] + 1
                end

                ArchiveAwarenessServerData[templateId] = data
            end
        end

        if updateSuitIdDic then
            for tmpSuitId, _ in pairs(updateSuitIdDic) do
                settingDataList = XArchiveConfigs.GetAwarenessSettingList(tmpSuitId)
                for _, settingData in ipairs(settingDataList) do
                    settingId = settingData.Id
                    conditionId = settingData.Condition

                    if not ArchiveAwarenessSettingUnlockServerData[settingId] and
                        not ArchiveAwarenessSettingCanUnlockDic[settingId] and
                        XConditionManager.CheckCondition(conditionId, tmpSuitId) then

                        isNewAwarenessSetting = true
                        ArchiveAwarenessSettingCanUnlockDic[settingId] = true
                        ArchiveNewAwarenessSettingIdsDic[tmpSuitId] = ArchiveNewAwarenessSettingIdsDic[tmpSuitId] or {}
                        table.insert(ArchiveNewAwarenessSettingIdsDic[tmpSuitId], settingId)

                        awarenessSuitGetType = XArchiveConfigs.GetAwarenessSuitInfoGetType(tmpSuitId)
                        ArchiveAwarenessSettingRedPointCountDic[awarenessSuitGetType] = ArchiveAwarenessSettingRedPointCountDic[awarenessSuitGetType] + 1
                        ArchiveAwarenessSettingTotalRedPointCount = ArchiveAwarenessSettingTotalRedPointCount + 1
                    end
                end
            end
        end

        if weaponIdList then
            XEventManager.DispatchEvent(XEventId.EVENET_ARCHIVE_NEW_WEAPON, weaponIdList)
        end
        if isNewWeaponSetting then
            XEventManager.DispatchEvent(XEventId.EVENET_ARCHIVE_UNLOCK_WEAPON_SETTING)
        end

        if awarenessSuitIdList then
            XEventManager.DispatchEvent(XEventId.EVENET_ARCHIVE_NEW_AWARENESS_SUIT, awarenessSuitIdList)
        end
        if isNewAwarenessSetting then
            XEventManager.DispatchEvent(XEventId.EVENET_ARCHIVE_UNLOCK_AWARENESS_SETTING)
        end
    end

    function XArchiveManager.UpdateWeaponUnlockServerData(idList)
        for _, id in ipairs(idList) do
            ArchiveWeaponUnlockServerData[id] = true
        end
    end

    function XArchiveManager.UpdateAwarenessSuitUnlockServerData(idList)
        for _, id in ipairs(idList) do
            ArchiveAwarenessSuitUnlockServerData[id] = true
        end
    end

    function XArchiveManager.UpdateWeaponSettingUnlockServerData(idList)
        for _, id in ipairs(idList) do
            ArchiveWeaponSettingUnlockServerData[id] = true
        end
    end

    function XArchiveManager.UpdateAwarenessSettingUnlockServerData(idList)
        for _, id in ipairs(idList) do
            ArchiveAwarenessSettingUnlockServerData[id] = true
        end
    end

    function XArchiveManager.CreateRedPointCountDic()
        local weaponTypeList = XArchiveConfigs.GetShowedWeaponTypeList()
        local groupTypeList = XArchiveConfigs.GetAwarenessGroupTypes()

        for _,type in ipairs(weaponTypeList) do
            ArchiveWeaponRedPointCountDic[type] = 0
            ArchiveWeaponSettingRedPointCountDic[type] = 0
        end

        for _, type in pairs(groupTypeList) do
            ArchiveAwarenessSuitRedPointCountDic[type.GroupId] = 0
            ArchiveAwarenessSettingRedPointCountDic[type.GroupId] = 0
        end

        local weaponType
        for id, _ in pairs(ArchiveWeaponServerData) do
            if not ArchiveWeaponUnlockServerData[id] then
                weaponType = XDataCenter.EquipManager.GetEquipTypeByTemplateId(id)
                if weaponType then
                    ArchiveWeaponRedPointCountDic[weaponType] = ArchiveWeaponRedPointCountDic[weaponType] + 1
                    ArchiveWeaponTotalRedPointCount = ArchiveWeaponTotalRedPointCount + 1
                end
            end
        end

        local awarenessGetType
        for id, _ in pairs(ArchiveAwarenessSuitToAwarenessCountDic) do
            if not ArchiveAwarenessSuitUnlockServerData[id] then
                awarenessGetType = XArchiveConfigs.GetAwarenessSuitInfoGetType(id)
                if ArchiveAwarenessSuitRedPointCountDic[awarenessGetType] then
                    ArchiveAwarenessSuitRedPointCountDic[awarenessGetType] = ArchiveAwarenessSuitRedPointCountDic[awarenessGetType] + 1
                    ArchiveAwarenessSuitTotalRedPointCount = ArchiveAwarenessSuitTotalRedPointCount + 1
                end
            end
        end


        local settingDataList
        local settingId
        for weaponId, _ in pairs(ArchiveWeaponTemplateIdToSettingListDic) do
            settingDataList = XArchiveConfigs.GetWeaponSettingList(weaponId)
            for _, settingData in ipairs(settingDataList) do
                settingId = settingData.Id
                if not ArchiveWeaponSettingUnlockServerData[settingId] and XConditionManager.CheckCondition(settingData.Condition, weaponId) then
                    ArchiveWeaponSettingCanUnlockDic[settingId] = true
                    weaponType = XDataCenter.EquipManager.GetEquipTypeByTemplateId(weaponId)
                    ArchiveNewWeaponSettingIdsDic[weaponId] = ArchiveNewWeaponSettingIdsDic[weaponId] or {}
                    table.insert(ArchiveNewWeaponSettingIdsDic[weaponId],settingId)
                    ArchiveWeaponSettingRedPointCountDic[weaponType] = ArchiveWeaponSettingRedPointCountDic[weaponType] + 1
                    ArchiveWeaponSettingTotalRedPointCount = ArchiveWeaponSettingTotalRedPointCount + 1
                end
            end
        end

        local getType
        for suitId, _ in pairs(ArchiveAwarenessGroupCfg) do
            settingDataList = XArchiveConfigs.GetAwarenessSettingList(suitId)
            for _, settingData in ipairs(settingDataList) do
                settingId = settingData.Id
                if not ArchiveAwarenessSettingUnlockServerData[settingId] and XConditionManager.CheckCondition(settingData.Condition, suitId) then
                    ArchiveAwarenessSettingCanUnlockDic[settingId] = true
                    getType = XArchiveConfigs.GetAwarenessSuitInfoGetType(suitId)
                    ArchiveNewAwarenessSettingIdsDic[suitId] = ArchiveNewAwarenessSettingIdsDic[suitId] or {}
                    table.insert(ArchiveNewAwarenessSettingIdsDic[suitId], settingId)
                    ArchiveAwarenessSettingRedPointCountDic[getType] = ArchiveAwarenessSettingRedPointCountDic[getType] + 1
                    ArchiveAwarenessSettingTotalRedPointCount = ArchiveAwarenessSettingTotalRedPointCount + 1
                end
            end
        end
    end

    function XArchiveManager.RequestUnlockWeapon(idList)
        XNetwork.Call(METHOD_NAME.UnlockArchiveWeaponRequest, {Ids = idList}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                end

                local successIdList = res.SuccessIds
                if successIdList then
                    local weaponType
                    for _, id in ipairs(successIdList) do
                        ArchiveWeaponUnlockServerData[id] = true
                        weaponType = XDataCenter.EquipManager.GetEquipTypeByTemplateId(id)
                        ArchiveWeaponRedPointCountDic[weaponType] = ArchiveWeaponRedPointCountDic[weaponType] - 1
                    end
                    ArchiveWeaponTotalRedPointCount = ArchiveWeaponTotalRedPointCount - #successIdList

                    XEventManager.DispatchEvent(XEventId.EVENET_ARCHIVE_UNLOCK_WEAPON)
                end
            end)
    end

    function XArchiveManager.HandleCanUnlockWeapon()
        local isHaveNew = XArchiveManager.IsHaveNewWeapon()
        if isHaveNew then
            local idList = {}
            for id, _ in pairs(ArchiveWeaponServerData) do
                if XArchiveManager.IsNewWeapon(id) then
                    table.insert(idList, id)
                end
            end
            XArchiveManager.RequestUnlockWeapon(idList)
        end
    end

    function XArchiveManager.HandleCanUnlockWeaponByWeaponType(type)
        local isHaveNew = XArchiveManager.IsHaveNewWeaponByWeaponType(type)
        if isHaveNew then
            local idList = {}
            local needCheckIdList = XArchiveConfigs.GetWeaponTemplateIdListByType(type)
            if needCheckIdList then
                for _, id in ipairs(needCheckIdList) do
                    if XArchiveManager.IsNewWeapon(id) then
                        table.insert(idList, id)
                    end
                end
                XArchiveManager.RequestUnlockWeapon(idList)
            end
        end
    end

    function XArchiveManager.RequestUnlockAwarenessSuit(idList)
        XNetwork.Call(METHOD_NAME.UnlockArchiveAwarenessRequest, {Ids = idList}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                end

                local successIdList = res.SuccessIds
                if successIdList then
                    local awarenessGetType
                    for _, id in ipairs(successIdList) do
                        ArchiveAwarenessSuitUnlockServerData[id] = true
                        awarenessGetType = XArchiveConfigs.GetAwarenessSuitInfoGetType(id)
                        ArchiveAwarenessSuitRedPointCountDic[awarenessGetType] = ArchiveAwarenessSuitRedPointCountDic[awarenessGetType] - 1
                    end
                    ArchiveAwarenessSuitTotalRedPointCount = ArchiveAwarenessSuitTotalRedPointCount - #successIdList

                    XEventManager.DispatchEvent(XEventId.EVENET_ARCHIVE_UNLOCK_AWARENESS_SUIT)
                end
            end)
    end

    function XArchiveManager.HandleCanUnlockAwarenessSuit()
        local isHaveNew = XArchiveManager.IsHaveNewAwarenessSuit()
        if isHaveNew then
            local idList = {}
            for id, _ in pairs(ArchiveAwarenessSuitToAwarenessCountDic) do
                if XArchiveManager.IsNewAwarenessSuit(id) then
                    table.insert(idList, id)
                end
            end
            XArchiveManager.RequestUnlockAwarenessSuit(idList)
        end
    end

    function XArchiveManager.HandleCanUnlockAwarenessSuitByGetType(type)
        local isHaveNew = XArchiveManager.IsHaveNewAwarenessSuitByGetType(type)
        if isHaveNew then
            local typeToGroupDatasDic = XArchiveConfigs.GetAwarenessTypeToGroupDatasDic()
            local groupDataList = typeToGroupDatasDic[type]
            if groupDataList then
                local newSettingId
                local requestIdList = {}
                for _, groupData in ipairs(groupDataList) do
                    newSettingId = groupData.Id
                    if XArchiveManager.IsNewAwarenessSuit(newSettingId) then
                        tableInsert(requestIdList, newSettingId)
                    end
                end
                XArchiveManager.RequestUnlockAwarenessSuit(requestIdList)
            end
        end
    end

    function XArchiveManager.CheckWeaponsCollectionLevelUp(type,curLevel)
        local oldlevel = XSaveTool.GetData(string.format("%d%s%d", XPlayer.Id, "ArchiveWeaponsCollection",type))
        if not oldlevel then
            XSaveTool.SaveData(string.format("%d%s%d", XPlayer.Id, "ArchiveWeaponsCollection",type), curLevel)
            return false
        else
            if curLevel > oldlevel then
                XSaveTool.SaveData(string.format("%d%s%d", XPlayer.Id, "ArchiveWeaponsCollection",type), curLevel)
                return true, oldlevel
            else
                return false
            end
        end
    end

    function XArchiveManager.SaveWeaponsCollectionDefaultData(type,level)
        local oldlevel = XSaveTool.GetData(string.format("%d%s%d", XPlayer.Id, "ArchiveWeaponsCollection",type))
        if not oldlevel then
            XSaveTool.SaveData(string.format("%d%s%d", XPlayer.Id, "ArchiveWeaponsCollection",type), level)
        end
    end

    function XArchiveManager.RequestUnlockWeaponSetting(settingIdList)
        XNetwork.Call(METHOD_NAME.UnlockWeaponSettingRequest, {Ids = settingIdList}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                end

                local successIdList = res.SuccessIds
                if successIdList then
                    local templateId
                    local weaponType
                    local newWeaponSettingIdList
                    for _, id in ipairs(successIdList) do
                        ArchiveWeaponSettingUnlockServerData[id] = true
                        ArchiveWeaponSettingCanUnlockDic[id] = nil
                        templateId = XArchiveConfigs.GetWeaponTemplateIdBySettingId(id)
                        weaponType = XDataCenter.EquipManager.GetEquipTypeByTemplateId(templateId)
                        ArchiveWeaponSettingRedPointCountDic[weaponType] = ArchiveWeaponSettingRedPointCountDic[weaponType] - 1
                        newWeaponSettingIdList = ArchiveNewWeaponSettingIdsDic[templateId]
                        if newWeaponSettingIdList then
                            for index, settingId in ipairs(newWeaponSettingIdList) do
                                if id == settingId then
                                    table.remove(newWeaponSettingIdList, index)
                                    break
                                end
                            end
                            if #newWeaponSettingIdList == 0 then
                                ArchiveNewWeaponSettingIdsDic[templateId] = nil
                            end
                        end
                    end
                    ArchiveWeaponSettingTotalRedPointCount = ArchiveWeaponSettingTotalRedPointCount - #successIdList

                    XEventManager.DispatchEvent(XEventId.EVENET_ARCHIVE_UNLOCK_WEAPON_SETTING)
                end
            end)
    end

    function XArchiveManager.HandleCanUnlockWeaponSetting()
        local isHaveNew = XArchiveManager.IsHaveNewWeaponSetting()
        if isHaveNew then
            local idList = {}
            for id, _ in pairs(ArchiveWeaponSettingCanUnlockDic) do
                tableInsert(idList, id)
            end
            XArchiveManager.RequestUnlockWeaponSetting(idList)
        end
    end

    function XArchiveManager.HandleCanUnlockWeaponSettingByWeaponType(type)
        local isHaveNew = XArchiveManager.IsHaveNewWeaponSettingByWeaponType(type)
        if not isHaveNew then return end
        local idList = {}
        local needCheckIdList = XArchiveConfigs.GetWeaponTemplateIdListByType(type)
        for _, templateId in ipairs(needCheckIdList) do
            if ArchiveNewWeaponSettingIdsDic[templateId] then
                for _, id in ipairs(ArchiveNewWeaponSettingIdsDic[templateId]) do
                    tableInsert(idList, id)
                end
            end
        end
        XArchiveManager.RequestUnlockWeaponSetting(idList)
    end

    function XArchiveManager.RequestUnlockAwarenessSetting(settingIdList)
        XNetwork.Call(METHOD_NAME.UnlockAwarenessSettingRequest, {Ids = settingIdList}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                end

                local successIdList = res.SuccessIds
                if successIdList then
                    local suitId
                    local getType
                    local newAwarenessSettingIdList
                    for _, id in ipairs(successIdList) do
                        ArchiveAwarenessSettingUnlockServerData[id] = true
                        ArchiveAwarenessSettingCanUnlockDic[id] = nil
                        suitId = XArchiveConfigs.GetAwarenessSuitIdBySettingId(id)
                        getType = XArchiveConfigs.GetAwarenessSuitInfoGetType(suitId)
                        ArchiveAwarenessSettingRedPointCountDic[getType] = ArchiveAwarenessSettingRedPointCountDic[getType] - 1
                        newAwarenessSettingIdList = ArchiveNewAwarenessSettingIdsDic[suitId]
                        if newAwarenessSettingIdList then
                            for index, settingId in ipairs(newAwarenessSettingIdList) do
                                if id == settingId then
                                    table.remove(newAwarenessSettingIdList, index)
                                    break
                                end
                            end
                            if #newAwarenessSettingIdList == 0 then
                                ArchiveNewAwarenessSettingIdsDic[suitId] = nil
                            end
                        end
                    end
                    ArchiveAwarenessSettingTotalRedPointCount = ArchiveAwarenessSettingTotalRedPointCount - #successIdList
                    XEventManager.DispatchEvent(XEventId.EVENET_ARCHIVE_UNLOCK_AWARENESS_SETTING)
                end
            end)
    end

    function XArchiveManager.HandleCanUnlockAwarenessSetting()
        local isHaveNew = XArchiveManager.IsHaveNewAwarenessSetting()
        if isHaveNew then
            local idList = {}
            for id, _ in pairs(ArchiveAwarenessSettingCanUnlockDic) do
                tableInsert(idList, id)
            end
            XArchiveManager.RequestUnlockAwarenessSetting(idList)
        end
    end

    function XArchiveManager.HandleCanUnlockAwarenessSettingByGetType(type)
        local isHaveNew = XArchiveManager.IsHaveNewAwarenessSettingByGetType(type)
        if not isHaveNew then return end
        local typeToGroupDatasDic = XArchiveConfigs.GetAwarenessTypeToGroupDatasDic()
        local groupDataList = typeToGroupDatasDic[type]
        if groupDataList then
            local newSettingIdList
            local requestIdList = {}
            for _, groupData in ipairs(groupDataList) do
                newSettingIdList = ArchiveNewAwarenessSettingIdsDic[groupData.Id]
                if newSettingIdList then
                    for _, id in ipairs(newSettingIdList) do
                        tableInsert(requestIdList, id)
                    end
                end
            end
            XArchiveManager.RequestUnlockAwarenessSetting(requestIdList)
        end
    end

    -- 武器、意识部分-------------------<<<

    -- 剧情相关------------->>>

    function XArchiveManager.InitArchiveStoryChapterList()
        for _, chapter in pairs(ArchiveStoryChapterCfg or {}) do

            if not ArchiveStoryChapterList[chapter.GroupId] then
                ArchiveStoryChapterList[chapter.GroupId] = {}
            end

            local tmp = XArchiveStoryChapterEntity.New(chapter.Id)
            table.insert(ArchiveStoryChapterList[chapter.GroupId], tmp)
            
            ArchiveStoryChapterDic[chapter.Id] = tmp
        end
        for _,group in pairs(ArchiveStoryChapterList) do
            XArchiveConfigs.SortByOrder(group)
        end
    end

    function XArchiveManager.InitArchiveStoryDetailAllList()
        for _, detail in pairs(ArchiveStoryDetailCfg or {}) do

            if not ArchiveStoryDetailList[detail.ChapterId] then
                ArchiveStoryDetailList[detail.ChapterId] = {}
            end

            local tmp = XArchiveStoryDetailEntity.New(detail.Id)
            table.insert(ArchiveStoryDetailList[detail.ChapterId], tmp)
        end
        for _,group in pairs(ArchiveStoryDetailList) do
            XArchiveConfigs.SortByOrder(group)
        end
    end

    function XArchiveManager.GetArchiveStoryGroupList()
        return ArchiveStoryGroupList
    end

    function XArchiveManager.GetArchiveStoryEvaluate(id)
        return ArchiveStoryEvaluateList[id] or {}
    end

    function XArchiveManager.GetArchiveStoryMySelfEvaluate(id)
        return ArchiveStoryMySelfEvaluateList[id] or {}
    end

    function XArchiveManager.GetArchiveStoryEvaluateList()
        return ArchiveStoryEvaluateList
    end

    function XArchiveManager.GetArchiveStoryMySelfEvaluateList()
        return ArchiveStoryMySelfEvaluateList
    end
    
    function XArchiveManager.GetArchiveStoryChapter(chapterId)
        return ArchiveStoryChapterDic[chapterId]
    end

    function XArchiveManager.GetStoryCollectRate()
        local storyDetailList = XArchiveManager.GetArchiveStoryDetailList()
        if #storyDetailList < 1 then
            return 0
        end
        local unlockCount = 0
        for _,v in pairs(storyDetailList or {}) do
            if not v:GetIsLock() then
                unlockCount = unlockCount + 1
            end
        end
        return XArchiveManager.GetPercent((unlockCount/#storyDetailList)*100)
    end

    function XArchiveManager.GetArchiveStoryChapterList(groupId)--groupId为空时不作为判断条件
        if groupId then
            return ArchiveStoryChapterList[groupId] or {}
        end
        local list = {}
        for _,group in pairs(ArchiveStoryChapterList or {}) do
            for _,chapter in pairs(group) do
                tableInsert(list,chapter)
            end
        end
        return XArchiveConfigs.SortByOrder(list)
    end

    function XArchiveManager.GetArchiveStoryDetailList(chapterId)--chapterId为空时不作为判断条件
        if chapterId then
            return ArchiveStoryDetailList[chapterId] or {}
        end
        local list = {}
        for _,group in pairs(ArchiveStoryDetailList or {}) do
            for _,detail in pairs(group) do
                tableInsert(list,detail)
            end
        end
        return XArchiveConfigs.SortByOrder(list)
    end

    function XArchiveManager.GetArchiveStoryDetailIdList(chapterId)
        local list = {}
        for _,detail in pairs(ArchiveStoryDetailList[chapterId] or {}) do
            tableInsert(list,detail:GetId())
        end
        return list
    end

    function XArchiveManager.SetArchiveStoryEvaluate(likes)
        for _,like in pairs(likes or {}) do
            if like and like.Id then
                ArchiveStoryEvaluateList[like.Id] = like
            end
        end
    end

    function XArchiveManager.SetArchiveStoryMySelfEvaluate(mySelfLikes)
        for _,myLike in pairs(mySelfLikes or {}) do
            if myLike and myLike.Id then
                ArchiveStoryMySelfEvaluateList[myLike.Id] = myLike
            end
        end
    end

    function XArchiveManager.SetArchiveStoryMySelfEvaluateLikeStatus(id,likeState)
        if not ArchiveStoryMySelfEvaluateList[id] then
            ArchiveStoryMySelfEvaluateList[id] ={}
        end
        ArchiveStoryMySelfEvaluateList[id].LikeStatus = likeState
    end

    function XArchiveManager.UpdateStoryData()
        XArchiveManager.UpdateStoryDetailList()
        XArchiveManager.UpdateStoryChapterList()
    end

    function XArchiveManager.UpdateStoryChapterList()--更新图鉴剧情关卡列表数据
        for _,chapterList in pairs(ArchiveStoryChapterList or {}) do
            for _,chapter in pairs(chapterList or {}) do
                local IsUnLock = false
                local lockDes = CS.XTextManager.GetText("StoryArchiveErrorHint")
                local storyDetailList = XArchiveManager.GetArchiveStoryDetailList(chapter:GetId())
                for _,detail in pairs(storyDetailList or {}) do
                    IsUnLock = IsUnLock or (not detail:GetIsLock())
                    if IsUnLock then
                        break
                    end
                end
                local tmpData = {}
                tmpData.IsLock = not IsUnLock
                local FirstIndex = 1
                local storyDetail = storyDetailList[FirstIndex]
                if storyDetail and storyDetail:GetLockDesc() then
                    tmpData.LockDesc = storyDetail:GetLockDesc()
                else
                    tmpData.LockDesc = lockDes
                    XLog.Error("detail is nil or LockDesc is nil by chapterId:" .. chapter:GetId())
                end
                chapter:UpdateData(tmpData)
            end
        end
    end

    function XArchiveManager.UpdateStoryDetailList()--更新图鉴剧情详细列表数据
        for _,detailList in pairs(ArchiveStoryDetailList or {}) do
            for _,detail in pairs(detailList or {}) do
                local IsUnLock = false
                local lockDes = ""
                local nowTime = XTime.GetServerNowTimestamp()
                local unLockTime = detail:GetUnLockTime() and XTime.ParseToTimestamp(detail:GetUnLockTime()) or 0
                local IsPassCondition = ((unLockTime ~= 0) and (nowTime > unLockTime)) or ArchiveShowedStoryList[detail:GetId()]
                if detail:GetCondition()  == 0 or IsPassCondition then
                    IsUnLock = true
                else
                    IsUnLock, lockDes = XConditionManager.CheckCondition(detail:GetCondition())
                end
                local tmpData = {}
                tmpData.IsLock = not IsUnLock
                tmpData.LockDesc = lockDes
                detail:UpdateData(tmpData)
            end
        end
    end

    function XArchiveManager.GetStoryEvaluateFromSever(chapterId,Ids, cb)
        local now = XTime.GetServerNowTimestamp()
        local syscTime = LastSyncStoryEvaluateTimes[chapterId]

        if syscTime and now - syscTime < SYNC_EVALUATE_SECOND then
            if cb then
                cb()
                return
            end
        end

        XNetwork.Call(METHOD_NAME.GetStoryEvaluateRequest, {Ids = Ids}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                XArchiveManager.SetArchiveStoryEvaluate(res.Likes)
                XArchiveManager.SetArchiveStoryMySelfEvaluate(res.PersonalLikes)
                LastSyncStoryEvaluateTimes[chapterId] = XTime.GetServerNowTimestamp()
                if cb then cb() end
            end)
    end

    function XArchiveManager.StoryGiveLike(likeList ,cb)
        local type = XArchiveConfigs.SubSystemType.Story
        XNetwork.Call(METHOD_NAME.ArchiveGiveLikeRequest, {LikeList = likeList ,Type = type}, function(res)
                if cb then cb() end
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                for _,id in pairs(res.SuccessIds or {}) do
                    for _,like in pairs(likeList or {}) do
                        if id == like.Id then
                            XArchiveManager.SetArchiveStoryMySelfEvaluateLikeStatus(id,like.LikeStatus)
                        end
                    end
                end
            end)
    end
    -- 剧情相关-------------<<<

    -- Npc相关------------->>>
    function XArchiveManager.InitArchiveStoryNpcAllList()--创建图鉴Npc数据
        for _, npcCfg in pairs(ArchiveStoryNpcCfg or {}) do

            local tmp = XArchiveNpcEntity.New(npcCfg.Id)
            table.insert(ArchiveStoryNpcList, tmp)
        end
        XArchiveConfigs.SortByOrder(ArchiveStoryNpcList)
    end

    function XArchiveManager.InitArchiveStoryNpcSettingAllList()--创建图鉴NpcSetting数据
        for _, settingCfg in pairs(ArchiveStoryNpcSettingCfg or {}) do

            if not ArchiveStoryNpcSettingList[settingCfg.GroupId] then
                ArchiveStoryNpcSettingList[settingCfg.GroupId] = {}
            end

            if not ArchiveStoryNpcSettingList[settingCfg.GroupId][settingCfg.Type] then
                ArchiveStoryNpcSettingList[settingCfg.GroupId][settingCfg.Type] = {}
            end

            local tmp = XArchiveNpcDetailEntity.New(settingCfg.Id)
            table.insert(ArchiveStoryNpcSettingList[settingCfg.GroupId][settingCfg.Type], tmp)
        end
        for _,group in pairs(ArchiveStoryNpcSettingList) do
            for _,type in pairs(group) do
                XArchiveConfigs.SortByOrder(type)
            end
        end
    end

    function XArchiveManager.UpdateStoryNpcList()--更新图鉴Npc数据
        for _,npc in pairs(ArchiveStoryNpcList or {}) do
            local IsUnLock = false
            local lockDes = ""
            local nowTime = XTime.GetServerNowTimestamp()
            local unLockTime = npc:GetUnLockTime() and XTime.ParseToTimestamp(npc:GetUnLockTime()) or 0
            local IsPassCondition = (unLockTime ~= 0) and (nowTime > unLockTime)
            if npc:GetCondition() == 0 or IsPassCondition then
                IsUnLock = true
            else
                IsUnLock, lockDes = XConditionManager.CheckCondition(npc:GetCondition())
            end
            local tmpData = {}
            tmpData.IsLock = not IsUnLock
            tmpData.LockDesc = lockDes
            npc:UpdateData(tmpData)
        end
    end

    function XArchiveManager.UpdateStoryNpcSettingList()--更新图鉴NpcSetting数据
        for _,settingGroupList in pairs(ArchiveStoryNpcSettingList or {}) do
            for _,settingList in pairs(settingGroupList or {}) do
                for _,setting in pairs(settingList or {}) do
                    local IsUnLock
                    local lockDes = ""
                    local nowTime = XTime.GetServerNowTimestamp()
                    local unLockTime = setting:GetUnLockTime() and XTime.ParseToTimestamp(setting:GetUnLockTime()) or 0
                    local IsPassCondition = (unLockTime ~= 0) and (nowTime > unLockTime)
                    if setting:GetCondition() == 0 or IsPassCondition then
                        IsUnLock = true
                    else
                        IsUnLock, lockDes = XConditionManager.CheckCondition(setting:GetCondition())
                    end
                    local tmpData = {}
                    tmpData.IsLock = not IsUnLock
                    tmpData.LockDesc = lockDes
                    setting:UpdateData(tmpData)
                end
            end
        end
    end

    function XArchiveManager.UpdateStoryNpcData()
        XArchiveManager.UpdateStoryNpcList()
        XArchiveManager.UpdateStoryNpcSettingList()
    end

    function XArchiveManager.GetArchiveStoryNpcList()
        return ArchiveStoryNpcList or {}
    end

    function XArchiveManager.GetArchiveStoryNpcSettingList(group,type)--type为空时不作为判断条件，获取相应类型的图鉴Npc设定列表
        if type then
            return ArchiveStoryNpcSettingList[group] and ArchiveStoryNpcSettingList[group][type] or {}
        end
        local list = {}
        for _,settingList in pairs(ArchiveStoryNpcSettingList[group]) do
            for _,setting in pairs(settingList) do
                tableInsert(list,setting)
            end
        end
        return XArchiveConfigs.SortByOrder(list)
    end

    function XArchiveManager.GetNPCCompletionRate()
        local npcList = XArchiveManager.GetArchiveStoryNpcList()
        if #npcList < 1 then
            return 0
        end
        local unlockCount = 0
        for _,v in pairs(npcList or {}) do
            if not v:GetIsLock() then
                unlockCount = unlockCount + 1
            end
        end
        return XArchiveManager.GetPercent((unlockCount/#npcList)*100)
    end
    -- Npc相关-------------<<<

    -- CG相关------------->>>
    function XArchiveManager.InitArchiveCGAllList()--创建图鉴NpcSetting数据
        for _, CGDetailCfg in pairs(ArchiveCGDetailCfg or {}) do

            if not ArchiveCGDetailList[CGDetailCfg.GroupId] then
                ArchiveCGDetailList[CGDetailCfg.GroupId] = {}
            end

            local tmp = XArchiveCGEntity.New(CGDetailCfg.Id)
            table.insert(ArchiveCGDetailList[CGDetailCfg.GroupId], tmp)
            ArchiveCGDetailData[CGDetailCfg.Id] = tmp
        end
        for _,group in pairs(ArchiveCGDetailList) do
            XArchiveConfigs.SortByOrder(group)
        end
    end

    function XArchiveManager.GetArchiveCgEntity(id)
        return ArchiveCGDetailData[id]
    end

    function XArchiveManager.SetArchiveShowedCGList(idList)
        for _,id in pairs(idList or {}) do
            ArchiveShowedCGList[id] = id
        end
    end

    function XArchiveManager.SetUnlockPvDetails(idList)
        if type(idList) ~= "table" then
            UnlockPvDetails[idList] = idList
            return
        end

        for _, id in pairs(idList or {}) do
            UnlockPvDetails[id] = id
        end
    end

    function XArchiveManager.SetArchiveShowedStoryList(idList)
        for _,id in pairs(idList or {}) do
            ArchiveShowedStoryList[id] = id
        end
    end

    function XArchiveManager.UpdateCGAllList()--更新图鉴Npc数据
        for _,group in pairs(ArchiveCGDetailList or {}) do
            for _,CGDetail in pairs(group) do
                local lockDes = ""
                local IsUnLock = ""
                if ArchiveShowedCGList[CGDetail:GetId()] then
                    IsUnLock = true
                else
                    if CGDetail:GetCondition() ~= 0 then
                        _,lockDes = XConditionManager.CheckCondition(CGDetail:GetCondition())
                    end
                    IsUnLock = false
                end
                local tmpData = {}
                tmpData.IsLock = not IsUnLock
                tmpData.LockDesc = lockDes
                CGDetail:UpdateData(tmpData)
            end
        end
    end

    function XArchiveManager.GetArchiveCGGroupList(isCustomLoading)
        local list = {}
        for _, group in pairs(ArchiveCGGroupCfg) do
            if isCustomLoading and XLoadingConfig.CheckCustomBlockGroup(group.Id) then
                goto CONTINUE
            end
            tableInsert(list, group)
            ::CONTINUE::
        end
        return XArchiveConfigs.SortByOrder(list)
    end

    function XArchiveManager.GetArchiveCGDetailList(group)--group为空时不作为判断条件，获取相应类型的图鉴CG列表
        if group then
            return ArchiveCGDetailList[group] and ArchiveCGDetailList[group] or {}
        end
        local list = {}
        for _,CGDetailGroup in pairs(ArchiveCGDetailList) do
            for _,CGDetail in pairs(CGDetailGroup) do
                tableInsert(list,CGDetail)
            end
        end
        return XArchiveConfigs.SortByOrder(list)
    end

    function XArchiveManager.GetCGCompletionRate(type)
        local CGList = XArchiveManager.GetArchiveCGDetailList(type)
        if #CGList < 1 then
            return 0
        end
        local unlockCount = 0
        for _,v in pairs(CGList or {}) do
            if not v:GetIsLock() then
                unlockCount = unlockCount + 1
            end
        end
        return XArchiveManager.GetPercent((unlockCount/#CGList)*100)
    end

    function XArchiveManager.CheckCGRedPointByGroup(groupId)
        local list = XArchiveManager.GetArchiveCGDetailList(groupId)
        for _,cgDetail in pairs(list) do
            if XArchiveManager.CheckCGRedPoint(cgDetail:GetId()) then
                return true
            end
        end
        return false
    end

    function XArchiveManager.ClearCGRedPointByGroup(groupId)
        local list = XArchiveManager.GetArchiveCGDetailList(groupId)
        for _,cgDetail in pairs(list) do
            XArchiveManager.ClearCGRedPoint(cgDetail:GetId())
        end
        XEventManager.DispatchEvent(XEventId.EVENET_ARCHIVE_MARK_CG)
    end

    function XArchiveManager.ClearCGRedPointById(id)
        XArchiveManager.ClearCGRedPoint(id)
        XEventManager.DispatchEvent(XEventId.EVENET_ARCHIVE_MARK_CG)
    end

    function XArchiveManager.CheckCGRedPoint(id)
        if XSaveTool.GetData(string.format("%d%s%d", XPlayer.Id, "ArchiveCG",id)) then
            return true
        else
            return false
        end
    end

    function XArchiveManager.AddNewCGRedPoint(idList)
        for _,id in pairs(idList) do
            if ArchiveCGDetailData[id] and ArchiveCGDetailData[id]:GetIsShowRedPoint() == 1 then

                if not XSaveTool.GetData(string.format("%d%s%d", XPlayer.Id, "ArchiveCG",id)) then
                    XSaveTool.SaveData(string.format("%d%s%d", XPlayer.Id, "ArchiveCG",id), id)
                end
            end
        end
    end

    function XArchiveManager.ClearCGRedPoint(id)
        if XSaveTool.GetData(string.format("%d%s%d", XPlayer.Id, "ArchiveCG",id)) then
            XSaveTool.RemoveData(string.format("%d%s%d", XPlayer.Id, "ArchiveCG",id))
        end
    end
    -- CG相关-------------<<<

    -- 邮件通讯相关------------->>>

    function XArchiveManager.InitArchiveMailList()--创建图鉴邮件数据
        for _, mailCfg in pairs(ArchiveMailCfg or {}) do
            if not ArchiveMailList[mailCfg.GroupId] then
                ArchiveMailList[mailCfg.GroupId] = {}
            end
            local tmp = XArchiveMailEntity.New(mailCfg.Id)
            table.insert(ArchiveMailList[mailCfg.GroupId], tmp)
        end
        for _,group in pairs(ArchiveMailList) do
            XArchiveConfigs.SortByOrder(group)
        end
    end

    function XArchiveManager.InitArchiveCommunicationList()--创建图鉴通讯数据
        for _, communicationCfg in pairs(ArchiveCommunicationCfg or {}) do

            if not ArchiveCommunicationList[communicationCfg.GroupId] then
                ArchiveCommunicationList[communicationCfg.GroupId] = {}
            end

            local tmp = XArchiveCommunicationEntity.New(communicationCfg.Id)
            table.insert(ArchiveCommunicationList[communicationCfg.GroupId], tmp)
        end
        for _,group in pairs(ArchiveCommunicationList) do
            XArchiveConfigs.SortByOrder(group)
        end
    end

    function XArchiveManager.UpdateMailList()--更新邮件数据
        for _,group in pairs(ArchiveMailList or {}) do
            for _,mail in pairs(group) do
                local IsUnLock = false
                local lockDes = ""
                local nowTime = XTime.GetServerNowTimestamp()
                local unLockTime = mail:GetUnLockTime() and XTime.ParseToTimestamp(mail:GetUnLockTime()) or 0
                local condition = mail:GetCondition() or 0
                
                if unLockTime == 0 and condition == 0 then
                    IsUnLock = true
                end
                if condition ~= 0 then
                    IsUnLock, lockDes = XConditionManager.CheckCondition(condition)
                end
                if unLockTime ~= 0 and nowTime > unLockTime then
                    IsUnLock = true
                end
                
                local tmpData = {}
                tmpData.IsLock = not IsUnLock
                tmpData.LockDesc = lockDes
                mail:UpdateData(tmpData)
            end
        end
    end

    function XArchiveManager.UpdateCommunicationList()--更新通讯数据
        for _,group in pairs(ArchiveCommunicationList or {}) do
            for _,communication in pairs(group) do
                local IsUnLock = false
                local lockDes = ""
                local nowTime = XTime.GetServerNowTimestamp()
                local unLockTime = communication:GetUnLockTime() and XTime.ParseToTimestamp(communication:GetUnLockTime()) or 0
                local IsPassCondition = (unLockTime ~= 0) and (nowTime > unLockTime)

                if communication:GetCondition() == 0 or IsPassCondition then
                    --IsUnLock = XPlayer.IsCommunicationMark(communication:GetCommunicationId())
                    -- 需求调整为时间到/未配置Condition则直接解锁
                    IsUnLock = true
                else
                    IsUnLock, lockDes = XConditionManager.CheckCondition(communication:GetCondition())
                end

                local tmpData = {}
                tmpData.IsLock = not IsUnLock
                tmpData.LockDesc = lockDes
                communication:UpdateData(tmpData)
            end
        end
    end

    function XArchiveManager.UpdateMailAndCommunicationData()
        XArchiveManager.UpdateMailList()
        XArchiveManager.UpdateCommunicationList()
    end

    function XArchiveManager.GetArchiveCommunicationList(group)--group为空时不作为判断条件
        local list = {}
        if group then
            if ArchiveCommunicationList and ArchiveCommunicationList[group] then
                for _,communication in pairs(ArchiveCommunicationList[group]) do
                    if not communication:GetIsLock() then
                        tableInsert(list,communication)
                    end
                end
            end
            return XArchiveConfigs.SortByOrder(list)
        end

        for _,communicationList in pairs(ArchiveCommunicationList) do
            for _,communication in pairs(communicationList) do
                if not communication:GetIsLock() then
                    tableInsert(list,communication)
                end
            end
        end
        return XArchiveConfigs.SortByOrder(list)
    end

    function XArchiveManager.GetArchiveMailList(group)--group为空时不作为判断条件
        local list = {}
        if group then
            if ArchiveMailList and ArchiveMailList[group] then
                for _,mail in pairs(ArchiveMailList[group]) do
                    if not mail:GetIsLock() then
                        tableInsert(list,mail)
                    end
                end
            end
            return XArchiveConfigs.SortByOrder(list)
        end

        for _,mailList in pairs(ArchiveMailList) do
            for _,mail in pairs(mailList) do
                if not mail:GetIsLock() then
                    tableInsert(list,mail)
                end
            end
        end
        return XArchiveConfigs.SortByOrder(list)
    end
    function XArchiveManager.GetEventDateGroupList()
        local list = {}
        for _,group in pairs(EventDateGroupCfg) do
            local showTime = group.ShowTime
            local nowTime = XTime.GetServerNowTimestamp()
            local unlockTime = XTool.IsNumberValid(showTime) and XTime.ParseToTimestamp(showTime) or nowTime
            if unlockTime <= nowTime then
                list[group.GroupType] = list[group.GroupType] or {}
                tableInsert(list[group.GroupType],group)
            end
        end

        for _,group in pairs(list)do
            XArchiveConfigs.SortByOrder(group)
        end

        return list
    end
    -- 邮件通讯相关-------------<<<

    --------------------------------伙伴图鉴相关------------------------------------------>>>
    function XArchiveManager.InitArchivePartnerSetting()
        ArchivePartnerSettingList = {}
        local detailCfg = XArchiveConfigs.GetPartnerSettingConfigs()
        for _, detail in pairs(detailCfg or {}) do

            if not ArchivePartnerSettingList[detail.GroupId] then
                ArchivePartnerSettingList[detail.GroupId] = {}
            end

            if not ArchivePartnerSettingList[detail.GroupId][detail.Type] then
                ArchivePartnerSettingList[detail.GroupId][detail.Type] = {}
            end

            local tmp = XArchivePartnerSettingEntity.New(detail.Id)
            table.insert(ArchivePartnerSettingList[detail.GroupId][detail.Type], tmp)
        end
        for _,group in pairs(ArchivePartnerSettingList) do
            for _,type in pairs(group) do
                XArchiveConfigs.SortByOrder(type)
            end
        end
    end
    
    function XArchiveManager.InitArchivePartnerList()--生成图鉴伙伴数据
        ArchivePartnerList = {}
        local templateList = XArchiveConfigs.GetPartnerConfigs()
        for _,template in pairs(templateList or {}) do
            if not ArchivePartnerList[template.GroupId] then
                ArchivePartnerList[template.GroupId] = {}
            end
            local entity = XArchivePartnerEntity.New(template.Id, 
                XArchiveManager.GetArchivePartnerSetting(template.Id,XArchiveConfigs.PartnerSettingType.Story),
                XArchiveManager.GetArchivePartnerSetting(template.Id,XArchiveConfigs.PartnerSettingType.Setting))
            table.insert(ArchivePartnerList[template.GroupId],entity)
        end
        for _,group in pairs(ArchivePartnerList) do
            XArchiveConfigs.SortByOrder(group)
        end
    end
    
    function XArchiveManager.UpdateArchivePartnerList()--更新图鉴伙伴数据
        for _,group in pairs(ArchivePartnerList or {}) do
            for _,partner in pairs(group) do
                local IsUnLock = false
                if PartnerUnLockDic[partner:GetTemplateId()] then
                    IsUnLock = true
                end
                partner:UpdateData({IsArchiveLock = not IsUnLock})
            end
        end
    end
    
    function XArchiveManager.UpdateArchivePartnerSettingList()--更新图鉴伙伴设定数据
        for _,group in pairs(ArchivePartnerList or {}) do
            for _,partner in pairs(group) do
                partner:UpdateStoryAndSettingEntity(PartnerUnLockSettingDic)
            end
        end
    end

    function XArchiveManager.UpdateUnLockPartnerDic(dataList)
        for _,data in pairs(dataList) do
            if not PartnerUnLockDic[data] then
                PartnerUnLockDic[data] = data
            end
        end
    end
    
    function XArchiveManager.UpdateUnLockArchiveMailDict(dataList)
        for _, archiveMailId in pairs(dataList or {}) do
            UnlockArchiveMails[archiveMailId] = true        
        end
    end
    
    function XArchiveManager.CheckArchiveMailUnlock(archiveMailId)
        return UnlockArchiveMails[archiveMailId] and true or false
    end
    
    function XArchiveManager.UpdateUnLockPartnerSettingDic(dataList)
        for _,data in pairs(dataList) do
            if not PartnerUnLockSettingDic[data] then
                PartnerUnLockSettingDic[data] = data
            end
        end
    end
    
    function XArchiveManager.GetPartnerUnLockDic()
        return PartnerUnLockDic
    end
    
    function XArchiveManager.GetPartnerUnLockById(templateId)
        return PartnerUnLockDic[templateId]
    end

    function XArchiveManager.GetPartnerSettingUnLockDic()
        return PartnerUnLockSettingDic
    end
    
    function XArchiveManager.GetPartnerGroupList()
        local list = {}
        local groupConfigs = XArchiveConfigs.GetPartnerGroupConfigs()
        for groupId,_ in pairs(ArchivePartnerList) do
            if groupConfigs[groupId] then
                table.insert(list,groupConfigs[groupId])
            end
        end
        XArchiveConfigs.SortByOrder(list)
        return list
    end
    
    function XArchiveManager.GetArchivePartnerList(group)
        if group then
            return ArchivePartnerList[group] and ArchivePartnerList[group] or {}
        end
        local list = {}
        for _,partnerGroup in pairs(ArchivePartnerList) do
            for _,partner in pairs(partnerGroup) do
                tableInsert(list,partner)
            end
        end
        return XArchiveConfigs.SortByOrder(list)
    end

    function XArchiveManager.GetArchivePartnerSetting(partnerTemplateId,type)
        local settingList = ArchivePartnerSettingList[partnerTemplateId]
        if not settingList then
            XLog.Error("Id is not exist in Share/Archive/PartnerSetting.tab".." id = " .. partnerTemplateId)
            return
        end
        local setting = settingList[type]
        if not setting then
            return
        end
        return XArchiveConfigs.SortByOrder(setting)
    end
    
    function XArchiveManager.GetPartnerCompletionRate(type)
        local partnerList = XArchiveManager.GetArchivePartnerList(type)
        if #partnerList < 1 then
            return 0
        end
        local unlockCount = 0
        for _,v in pairs(partnerList or {}) do
            if not v:GetIsArchiveLock() then
                unlockCount = unlockCount + 1
            end
        end
        return XArchiveManager.GetPercent((unlockCount/#partnerList)*100)
    end
    
    -- 根据npcId获取monsterId
    -- PS:XArchiveConfigs.GetSameNpcId该方法关联配置的Npc的会计入图鉴击杀计算内
    -- PS:这里两张表的配置其实是强关联，详细配法最好问图鉴相关负责人
    -- PS:以后根据NpcId获取MonsterId时不要直接走ArchiveNpcToMonster变量
    function XArchiveManager.GetMonsterIdByNpcId(npcId)
        local sameNpcId = XArchiveConfigs.GetSameNpcId(npcId)
        return ArchiveNpcToMonster[sameNpcId]
    end

    --------------------------------伙伴图鉴相关------------------------------------------<<<

    --------------------------------PV相关------------------------------------------>>>
    local GetPVRedPointKey = function(id)
        return string.format("%d%s%d", XPlayer.Id, "ArchivePV", id)
    end

    --groupId为空时获得所有PV的解锁进度，否则获得对应组Id的PV解锁进度
    function XArchiveManager.GetPVCompletionRate(groupId)
        local pvIdList = XArchiveConfigs.GetPVDetailIdList(groupId)
        if #pvIdList < 1 then
            return 0
        end
        local unlockCount = 0
        for _, pvDetailId in ipairs(pvIdList) do
            if XArchiveManager.GetPVUnLock(pvDetailId) then
                unlockCount = unlockCount + 1
            end
        end
        return XArchiveManager.GetPercent((unlockCount / #pvIdList) * 100)
    end

    function XArchiveManager.GetPVUnLock(pvDetailId)
        if UnlockPvDetails[pvDetailId] then
            return true
        end

        local isUnLock, lockDes
        local unLockTime = XArchiveConfigs.GetPVDetailUnLockTime(pvDetailId)
        unLockTime = unLockTime and XTime.ParseToTimestamp(unLockTime) or 0
        local conditionId = XArchiveConfigs.GetPVDetailCondition(pvDetailId)

        if not XTool.IsNumberValid(unLockTime) and not XTool.IsNumberValid(conditionId) then
            isUnLock, lockDes = true, ""
        else
            if XTool.IsNumberValid(unLockTime) then
                local nowTime = XTime.GetServerNowTimestamp()
                isUnLock, lockDes = nowTime >= unLockTime, CS.XTextManager.GetText("ArchiveNotUnLockTime")
            end
            if not isUnLock and XTool.IsNumberValid(conditionId) then
                isUnLock, lockDes = XConditionManager.CheckCondition(conditionId)
            end
        end

        return isUnLock, lockDes
    end
    --------------------------------PV相关------------------------------------------<<<

    --进度大于0小于1时固定返回1，否则返回向下取整的进度
    function XArchiveManager.GetPercent(percent)
        return (percent > 0 and percent < 1) and 1 or math.floor(percent)
    end

    XArchiveManager.Init()
    return XArchiveManager
end


XRpc.NotifyArchiveLoginData = function(data)
    XDataCenter.ArchiveManager.SetArchiveShowedMonsterList(data.Monsters)
    XDataCenter.ArchiveManager.SetArchiveMonsterSettingUnlockIdsList(data.MonsterSettings)
    XDataCenter.ArchiveManager.SetArchiveMonsterUnlockIdsList(data.MonsterUnlockIds)
    XDataCenter.ArchiveManager.SetArchiveMonsterInfoUnlockIdsList(data.MonsterInfos)
    XDataCenter.ArchiveManager.SetArchiveMonsterSkillUnlockIdsList(data.MonsterSkills)
    XDataCenter.ArchiveManager.SetEquipServerData(data.Equips)
    --XDataCenter.ArchiveManager.CheckSpecialEquip()
    
    XDataCenter.ArchiveManager.SetArchiveShowedCGList(data.UnlockCgs)
    XDataCenter.ArchiveManager.SetArchiveShowedStoryList(data.UnlockStoryDetails)--只保存通关的活动剧情ID，到了解禁事件后会被清除
    XDataCenter.ArchiveManager.SetUnlockPvDetails(data.UnlockPvDetails)
    
    XDataCenter.ArchiveManager.UpdateWeaponUnlockServerData(data.WeaponUnlockIds)
    XDataCenter.ArchiveManager.UpdateAwarenessSuitUnlockServerData(data.AwarenessUnlockIds)
    XDataCenter.ArchiveManager.UpdateWeaponSettingUnlockServerData(data.WeaponSettings)
    XDataCenter.ArchiveManager.UpdateAwarenessSettingUnlockServerData(data.AwarenessSettings)
    XDataCenter.ArchiveManager.UpdateUnLockPartnerSettingDic(data.PartnerSettings)
    XDataCenter.ArchiveManager.UpdateUnLockPartnerDic(data.PartnerUnlockIds)
    XDataCenter.ArchiveManager.UpdateUnLockArchiveMailDict(data.UnlockMails)
    
    XDataCenter.ArchiveManager.UpdateMonsterData()
    XDataCenter.ArchiveManager.UpdateCGAllList()
    XDataCenter.ArchiveManager.CreateRedPointCountDic()
    
    XDataCenter.PartnerManager.UpdateAllPartnerStory()
    XDataCenter.ArchiveManager.UpdateArchivePartnerList()
    XDataCenter.ArchiveManager.UpdateArchivePartnerSettingList()
end

XRpc.NotifyArchiveMonsterRecord = function(data)
    XDataCenter.ArchiveManager.AddArchiveShowedMonsterList(data.Monsters)
    XDataCenter.ArchiveManager.UpdateMonsterData()
end

XRpc.NotifyArchiveCgs = function(data)
    XDataCenter.ArchiveManager.SetArchiveShowedCGList(data.UnlockCgs)
    XDataCenter.ArchiveManager.UpdateCGAllList()
    XDataCenter.ArchiveManager.AddNewCGRedPoint(data.UnlockCgs)
    XEventManager.DispatchEvent(XEventId.EVENET_ARCHIVE_NEW_CG)
end

XRpc.NotifyArchivePvDetails = function(data)
    XDataCenter.ArchiveManager.SetUnlockPvDetails(data.UnlockPvDetails) --这的UnlockPvDetails是个int
end
-----------------武器、意识相关------------------->>>
XRpc.NotifyArchiveEquip = function(data)
    XDataCenter.ArchiveManager.UpdateEquipServerData(data.Equips)
end

-----------------武器、意识相关-------------------<<<
-----------------剧情相关------------------->>>
XRpc.NotifyArchiveStoryDetails = function(data)
    XDataCenter.ArchiveManager.SetArchiveShowedStoryList(data.UnlockStoryDetails)
end
-----------------剧情相关-------------------<<<

-----------------伙伴相关------------------->>>

XRpc.NotifyArchivePartners = function(data)
    XDataCenter.ArchiveManager.UpdateUnLockPartnerDic(data.PartnerUnlockIds)
    XDataCenter.ArchiveManager.UpdateArchivePartnerList()
end

XRpc.NotifyPartnerSettings = function(data)
    XDataCenter.ArchiveManager.UpdateUnLockPartnerSettingDic(data.PartnerSettings)
    XDataCenter.ArchiveManager.UpdateArchivePartnerSettingList()
    XDataCenter.PartnerManager.UpdateAllPartnerStory()
end
-----------------伙伴相关-------------------<<<

--region   ------------------邮件相关 start-------------------
XRpc.NotifyArchiveMail = function(data) 
    local id = data.UnlockArchiveMailId
    if XTool.IsNumberValid(id) then
        XDataCenter.ArchiveManager.UpdateUnLockArchiveMailDict({ id })
    end
end
--endregion------------------邮件相关 finish------------------