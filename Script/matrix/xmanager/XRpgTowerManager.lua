local XExRpgTowerManager = require("XEntity/XFuben/XExRpgTowerManager")

--兵法蓝图玩法管理器
XRpgTowerManagerCreator = function()
    local XRpgTowerManager = XExRpgTowerManager.New(XFubenConfigs.ChapterType.RpgTower, "RpgTowerManager")
    local RpgTowerConfig = XRpgTowerConfig
    local RpgTowerCharacter = require("XEntity/XRpgTower/XRpgTowerCharacter")
    local RpgTowerStage = require("XEntity/XRpgTower/XRpgTowerStage")
    local RpgTowerChapter = require("XEntity/XRpgTower/XRpgTowerChapter")
    --[[    *********搜索以下关键字快速到达该类方法模块*********
    =========初始化方法
    =========角色管理方法
    =========FubenManager代理方法
    =========协议方法
    =========玩法配置Get方法
    =========XRpc方法
    ]]
    --
    --  **** 玩法基础配置变量
    local CurrentConfig -- 基本活动配置，读取RpgConfig表
    local StartTime = 0 -- 本轮结束时间
    local EndTime = 0 -- 本轮开始时间
    --  **** 玩法关卡管理模块变量
    local CurrentChapter -- 现在的章节对象
    local RStageList = {} --关卡对象列表
    local ChapterNOrderId2RStageDic = {} --章节与序号对应活动关卡对象字典
    local HadGetDailyReward = true --是否领取了今日宝箱
    --  **** 玩法角色管理模块变量
    local MyTeamMember = {} -- 角色小队
    local PreTeamLevel = 1 --经验变化前一个节点的队伍等级
    local TeamLevel = 1 --队伍等级
    local PreTeamExp = 0 --经验变化前一个节点的当前队伍等级经验
    local TeamExp = 0 --当前队伍等级的经验
    local ChangeExp = 0 --等级变化增加的经验值
    local TeamExpNewChange = false --是否有新的经验变动
    local IsActivityEnd = false -- 是否玩法已关闭(优先判断此条件)
    local IsInit = false -- 是否从服务器获取消息并初始化了数据
    local IsReset = false -- 是否重置了数据
    local IsStageDataInit = false -- 是否已初始化过关卡信息
    local IsRegisterEditBattleProxy = false -- 是否已注册出战界面代理
    local UPGRADE_ITEM_ID = 60815
    --  **** 玩法枚举类型
    --================
    --协议名称
    --================
    local REQUEST_NAMES = { --请求名称
        CharaUpgrade = "RpgUpgradeRequest", -- 角色升星
        CharaTalentActive = "RpgActivateTalentRequest", -- 角色激活天赋
        CharaTalentReset = "RpgResetTalentRequest", --角色天赋重置
        GetDailyReward = "RpgGetDailyRewardRequest", -- 角色重置
        CharaSetTalentType = "RpgChangeTalentTypeRequest", --设置角色天赋类型
    }

    --================
    --角色头像面板展示样式
    --================
    XRpgTowerManager.CharaItemShowType = {
        Normal = 1, -- Ui有头像，星数，名称，战力
        OnlyIconAndStar = 2 -- Ui仅有头像和星数
    }

    --================
    --怪兽模型位置
    --================
    XRpgTowerManager.MonsterModelPos = {
        Middle = 1,
        Left = 2,
        Right = 3
    }
    --================
    --主界面关卡图标枚举
    --================
    XRpgTowerManager.StageDifficultyData = {
        [1] = {
            IconPath = CS.XGame.ClientConfig:GetString("RpgTowerStageIconNormal")
        },
        [2] = {
            IconPath = CS.XGame.ClientConfig:GetString("RpgTowerStageIconHard")
        },
        [3] = {
            IconPath = CS.XGame.ClientConfig:GetString("RpgTowerStageIconChallenge")
        }
    }

    XRpgTowerManager.StageDifficultyNewData = {
        [1] = { -- easy
            Normal = CS.XGame.ClientConfig:GetString("UiRpgTowerEasy"),
            Select = CS.XGame.ClientConfig:GetString("UiRpgTowerEasySelect"),
            Disable = CS.XGame.ClientConfig:GetString("UiRpgTowerEasyDisable"),
        },
        [2] = { -- normal
            Normal = CS.XGame.ClientConfig:GetString("UiRpgTowerNormal"),
            Select = CS.XGame.ClientConfig:GetString("UiRpgTowerNormalSelect"),
            Disable = CS.XGame.ClientConfig:GetString("UiRpgTowerNormalDisable"),
        },
        [3] = { -- hard
            Normal = CS.XGame.ClientConfig:GetString("UiRpgTowerHard"),
            Select = CS.XGame.ClientConfig:GetString("UiRpgTowerHardSelect"),
            Disable = CS.XGame.ClientConfig:GetString("UiRpgTowerHardDisable"),
        }
    }
    --================
    --玩法养成界面的3D镜头枚举
    --================
    XRpgTowerManager.UiCharacter_Camera = {
        MAIN = 0, -- 主页面镜头
        ADAPT = 1,
        GRADE = 2, -- 升级页签镜头
        NATURE = 4, -- 天赋页签镜头
        CHANGEMEMBER = 5 -- 切换队员镜头
    }
    --================
    --玩法养成界面的子页面枚举
    --================
    XRpgTowerManager.PARENT_PAGE = {
        MAIN = 1, -- 主页面
        ADAPT = 2, -- 改造页面
        CHANGEMEMBER = 3, -- 切换队员
        TYPESELECT = 4, --选择天赋类型页面
    }
    --================
    --编队界面警告面板
    --================
    XRpgTowerManager.STAGE_WARNING_LEVEL = {
        NoWarning = 1, --无警告
        Warning = 2, --警告
        Danger = 3, --危险
    }

    XRpgTowerManager.TALENT_TYPE = {
        SINGLE = 1, --单人作战
        TEAM = 2, --轮换作战
    }
    -- 相关数据模型
    --[[    **** 协议用角色模型数据
    XRpgCharacter =
    {
    int CharacterId,
    int Level,
    HashSet<int> Talents
    }

    **** 刷新玩法数据协议(在服务器推送刷新数据和开始玩法时传入)
    NotifyRpgData =
    {
    int ActivityId;
    List<XRpgCharacter> Characters;
    }

    **** 玩法角色模型类(客户端构建)
    XRpgTowerCharacter
    ]]
    -- =========         =========
    -- =========初始化方法=========
    -- =========         =========
    --[[    ================
    本地初始化管理器
    ================
    ]]
    function XRpgTowerManager.Init()
        CurrentChapter = RpgTowerChapter.New()
    end

    --[[    ================
    初始化/重置玩法数据
    @param:notifyRpgData 后端推送的初始化数据
    ================
    ]]
    function XRpgTowerManager.Reset(notifyRpgData)
        CurrentConfig = RpgTowerConfig.GetRpgTowerConfigById(notifyRpgData.ActivityId)
        if CurrentConfig then
            XRpgTowerManager.InitTeamMember()
            XRpgTowerManager.SetTeam(notifyRpgData.Characters)
            if IsInit then
                IsReset = true
                CurrentChapter:ResetStage()
            end
            IsInit = true
        else
            XLog.Error(string.format("兵法蓝图配置未成功初始化！将导致玩法不能正常运行，请检查！%s",
                    tostring(notifyRpgData.ActivityId)))
            IsActivityEnd = true
            IsReset = true
            return
        end
        --先刷新关卡数据,刷新章节时才能正确刷新关卡进度
        XRpgTowerManager.RefreshStageInfo(notifyRpgData.Stages)
        if not CurrentChapter then
            CurrentChapter = RpgTowerChapter.New(notifyRpgData.ActivityId)
        else
            CurrentChapter:RefreshData(notifyRpgData.ActivityId)
        end
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_RPGTOWER_RESET)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_ACTIVITY_ON_RESET, XDataCenter.FubenManager.StageType.RpgTower)
    end

    --[[    ================
    关闭玩法(在后端推送活动结束时调用)
    ================
    ]]
    function XRpgTowerManager.EndActivity()
        if CurrentConfig then
            StartTime = XRpgTowerManager.GetStartTime()
            EndTime = XRpgTowerManager.GetEndTime()
            XRpgTowerManager.InitTeamMember()
        end
        IsActivityEnd = true
        IsReset = true
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_RPGTOWER_RESET)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_ACTIVITY_ON_RESET, XDataCenter.FubenManager.StageType.RpgTower)
    end

    -- =========                   =========
    -- =========FubenManager代理方法=========
    -- =========                   =========
    --================
    --初始化关卡信息
    --================
    local StageInit = false
    function XRpgTowerManager.InitStageInfo()
        --if StageInit then return end
        local stageList = RpgTowerConfig.GetRStageList()
        if StageInit then
        else
            RStageList = {}
            ChapterNOrderId2RStageDic = {}
            for rStageId, rStageCfg in pairs(stageList) do
                RStageList[rStageId] = RpgTowerStage.New(rStageId)
                if not ChapterNOrderId2RStageDic[rStageCfg.ActivityId] then
                    ChapterNOrderId2RStageDic[rStageCfg.ActivityId] = {}
                end
                ChapterNOrderId2RStageDic[rStageCfg.ActivityId][rStageCfg.OrderId] = RStageList[rStageId]
            end
            StageInit = true
        end
    end

    function XRpgTowerManager.CheckUnlockByStageId(stageId)
        local rStage = XDataCenter.RpgTowerManager.GetRStageByStageId(stageId)
        return rStage:GetIsUnlock()
    end
    --================
    --刷新关卡信息
    --@param xrpgStageList:List<XRpgStage>
    --XRpgStage : {int StageId, int Score}
    --================
    function XRpgTowerManager.RefreshStageInfo(rpgStageList)
        for _, rpgStage in pairs(rpgStageList) do
            local rStage = XRpgTowerManager.GetRStageByStageId(rpgStage.StageId)
            if rStage then
                rStage:RefreshData(rpgStage)
            end
        end
    end
    --================
    --战斗前信息处理
    --================
    function XRpgTowerManager.PreFight(stage, teamId, isAssist, challengeCount, challengeId)
        local preFight = {}
        preFight.CardIds = {}
        preFight.StageId = stage.StageId
        preFight.IsHasAssist = isAssist and true or false
        preFight.ChallengeCount = challengeCount or 1
        preFight.RobotIds = {}
        local teamData = XDataCenter.TeamManager.GetTeamData(teamId)
        for i in pairs(teamData) do
            if teamData[i] > 0 then
                preFight.CardIds[i] = XRobotManager.GetCharacterId(teamData[i])
            else
                preFight.CardIds[i] = 0
            end
        end
        preFight.CaptainPos = XDataCenter.TeamManager.GetTeamCaptainPos(teamId)
        preFight.FirstFightPos = XDataCenter.TeamManager.GetTeamFirstFightPos(teamId)
        return preFight
    end
    --===================
    --调用结算界面
    --===================
    function XRpgTowerManager.ShowReward(winData)
        XLuaUiManager.Open("UiRpgTowerSettleWin", winData)
    end

    function XRpgTowerManager.FinishFight(settle)
        local stageId = settle.StageId
        local rStage = XRpgTowerManager.GetRStageByStageId(stageId)
        if rStage and settle.RpgSettleResult and settle.IsWin then
            rStage:RefreshData(settle.RpgSettleResult)
        end
        XDataCenter.FubenManager.FinishFight(settle)
    end
    -- =========           =========
    -- =========角色管理方法=========
    -- =========           =========
    --[[    ================
    初始化角色数据，在初始化管理器时调用
    ================
    ]]
    function XRpgTowerManager.InitTeamMember()
        if not CurrentConfig then
            XLog.Error("兵法蓝图配置未成功初始化！将导致玩法不能正常运行，请检查！")
            return
        end
        MyTeamMember = {}
        for i = 1, #CurrentConfig.CharacterIds do
            local chara = RpgTowerCharacter.New(CurrentConfig.CharacterIds[i], i)
            if chara then MyTeamMember[chara:GetCharacterId()] = chara end
        end
    end
    --[[    ================
    设置新的角色数据，在重置数据和刷新数据时调用
    @param teamInfo 角色数据 List<XRpgCharacters>
    ================
    ]]
    function XRpgTowerManager.SetTeam(teamInfo)
        for _, memberInfo in pairs(teamInfo) do
            if not MyTeamMember[memberInfo.CharacterId] then
                XLog.Error(string.format("兵法蓝图要刷新的成员不存在！角色Id:%s",
                        tostring(memberInfo.CharacterId)))
                return
            else
                MyTeamMember[memberInfo.CharacterId]:RefreshCharacterData(memberInfo)
            end
        end
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_RPGTOWER_MEMBERCHANGE)
    end

    -- =========              =========
    -- =========玩法配置Get方法=========
    -- =========              =========
    --===================
    --获取活动配置简表
    --===================
    function XRpgTowerManager.GetActivityChapters()
        if not CurrentConfig then
            CurrentConfig = RpgTowerConfig.GetLatestConfig()
        end
        local timeNow = XTime.GetServerNowTimestamp()
        local isEnd = 0
        local isStart = 0
        isEnd = timeNow >= XRpgTowerManager.GetEndTime()
        isStart = timeNow >= XRpgTowerManager.GetStartTime()
        local inActivity = (not isEnd) and (isStart)
        if not inActivity then return {} end
        local chapters = {}
        local tempChapter = {}
        tempChapter.Type = XDataCenter.FubenManager.ChapterType.RpgTower
        tempChapter.Id = CurrentConfig.Id
        table.insert(chapters, tempChapter)
        return chapters
    end
    --===================
    --获取活动名称
    --===================
    function XRpgTowerManager.GetActivityName()
        return CurrentConfig.ActivityName
    end
    --===================
    --获取活动入口配图地址
    --===================
    function XRpgTowerManager.GetEntryTexture()
        return CurrentConfig.EntryTexture
    end
    --[[    ================
    使用关卡ID获取玩法关卡对象
    @param stageId:关卡ID
    ================
    ]]
    function XRpgTowerManager.GetRStageByStageId(stageId)
        local rStageId = RpgTowerConfig.GetRStageIdByStageId(stageId)
        return RStageList[rStageId]
    end
    --================
    --使用章节ID和章节关卡序号获取玩法关卡对象
    --@param chapterId:章节ID
    --@param orderId:章节关卡序号
    --================
    function XRpgTowerManager.GetRStageByChapterNOrderId(chapterId, orderId)
        return ChapterNOrderId2RStageDic[chapterId] and ChapterNOrderId2RStageDic[chapterId][orderId - 1]
    end
    --[[    ================
    获取所有队员信息
    ================
    ]]
    function XRpgTowerManager.GetTeam()
        local team = {}
        for _, member in pairs(MyTeamMember) do
            team[member:GetOrder()] = member
        end
        return team
    end
    --[[    ================
    通过角色ID获取队员信息
    ================
    ]]
    function XRpgTowerManager.GetTeamMemberByCharacterId(charaId)
        if not charaId then return nil end
        if not MyTeamMember[charaId] then
            XLog.Error(string.format("要查找的成员数据不存在！请检查！角色ID：%s",
                    tostring(charaId)))
            --XLog.Debug("本地兵法蓝图成员数据：", MyTeamMember)
            return nil
        end
        return MyTeamMember[charaId]
    end
    --================
    --检查总成员等级是否高于检查数值
    --@param checkNum:检查数值
    --================
    function XRpgTowerManager.GetMemberTotalLevelReachNum(checkNum)
        local total = 0
        for _, member in pairs(MyTeamMember) do
            total = total + member:GetLevel()
        end
        return total >= checkNum
    end
    --[[    ================
    检查玩法角色中是否存在指定角色ID
    ================
    ]]
    function XRpgTowerManager.GetTeamMemberExist(charaId)
        if not charaId then return false end
        if not MyTeamMember[charaId] then return false end
        return true
    end
    --================
    --检查对应角色是否在出战队伍中(4期把队伍数据存储的ID改为RobotId，导致需要额外转换处理)
    --================
    function XRpgTowerManager.GetCharacterIsInTeam(charaId)
        local teamInfos = XDataCenter.TeamManager.GetPlayerTeam(CS.XGame.Config:GetInt("TypeIdRpgTower"))
        if not teamInfos or not charaId then return false end
        for _, v in pairs(teamInfos.TeamData) do
            if XRobotManager.GetCharacterId(v) == charaId then
                return true
            end
        end
        return false
    end
    --[[    ================
    获取队员未使用的天赋点数
    ================
    ]]
    function XRpgTowerManager.GetTeamMemberTalentPointsByCharacterId(charaId, talentTypeId)
        if not MyTeamMember[charaId] then
            XLog.Error(string.format("要查找的成员数据不存在！请检查！角色ID：%s",
                    tostring(charaId)))
            --XLog.Debug("本地兵法蓝图成员数据：", MyTeamMember)
            return 0
        end
        return MyTeamMember[charaId]:GetTalentPoints(talentTypeId)
    end
    --[[    ================
    获取剩余挑战次数字符串
    ================
    ]]
    function XRpgTowerManager.GetChallengeCountStr()
        return CS.XTextManager.GetText("RpgTowerChallengeCountStr",
            XRpgTowerManager.GetChallengeCount(),
            CurrentConfig.MaxChallengeCount)
    end
    --[[    ================
    获取能否挑战关卡
    ================
    ]]
    function XRpgTowerManager.GetCanChallenge()
        return true
    end
    --[[    ================
    获取当前章节通关进度字符串
    ================
    ]]
    function XRpgTowerManager.GetChapterProgressStr()
        return CurrentChapter:GetPassProgressStr()
    end
    -- 获取全局进度，显示在入口的
    function XRpgTowerManager.GetWholeProgressStr()
        local stageList = {}
        for id, v in pairs(XRpgTowerConfig.GetRTagConfigs()) do
            stageList = appendArray(stageList, XDataCenter.RpgTowerManager.GetCurrActivityStageListByTagId(id))
        end
        if XTool.IsTableEmpty(stageList) then
            return
        end 
        local currProgress = 0
        for k, stageCfg in pairs(stageList) do -- 只要该标签下有解锁的stage就解锁
            local rStage = XDataCenter.RpgTowerManager.GetRStageByStageId(stageCfg.StageId)
            if rStage:GetIsPass() then
                currProgress = currProgress + 1
            end
        end
        return CS.XTextManager.GetText("RpgTowerChapterProgressStr",currProgress, #stageList)
    end
    --[[    ================
    获取玩法是否关闭(用于判断玩法入口，进入活动条件等)
    @return param1:玩法是否关闭
    @return param2:是否活动未开启
    ================
    ]]
    function XRpgTowerManager.GetIsEnd()
        local timeNow = XTime.GetServerNowTimestamp()
        local isEnd = timeNow >= XRpgTowerManager.GetEndTime()
        local isStart = timeNow >= XRpgTowerManager.GetStartTime()
        local inActivity = (not isEnd) and (isStart)
        return IsActivityEnd or not inActivity, timeNow < XRpgTowerManager.GetStartTime()
    end
    --[[    ================
    获取本轮开始时间
    ================
    ]]
    function XRpgTowerManager.GetStartTime()
        if not CurrentConfig then
            CurrentConfig = RpgTowerConfig.GetLatestConfig()
        end
        return XFunctionManager.GetStartTimeByTimeId(CurrentConfig.TimeId) or 0
    end
    --[[    ================
    获取本轮结束时间
    ================
    ]]
    function XRpgTowerManager.GetEndTime()
        if not CurrentConfig then
            CurrentConfig = RpgTowerConfig.GetLatestConfig()
        end
        return XFunctionManager.GetEndTimeByTimeId(CurrentConfig.TimeId) or 0
    end
    -- 获取现在是活动第几天
    function XRpgTowerManager.GetDayCount()
        local startTime =  XRpgTowerManager.GetStartTime()
        local now = XTime.GetServerNowTimestamp()
        local Timeoffset = now - startTime
        local dayPass = math.floor( Timeoffset/ (3600 * 24)) + 1 -- + 1 因为第0天也算第一天，偏移后才能匹配配置表下标

        return dayPass
    end
    --[[    ================
    获取现在的章节对象
    ================
    ]]
    function XRpgTowerManager.GetCurrentChapter()
        return CurrentChapter
    end
    --[[    ================
    获取是否可挑战新关卡
    ================
    ]]
    function XRpgTowerManager.GetHaveNewStage()
        return (not CurrentChapter:GetIsClear())
    end
    --================
    --获取是否有角色可以升级天赋
    --================
    function XRpgTowerManager.GetMemberCanActiveTalent()
        for _, member in pairs(MyTeamMember) do
            if member:CheckCanActiveTalent() then return true end
        end
        return false
    end
    --[[    ================
    获取是否重置了数据(用于重置数据后的边界处理)
    ================
    ]]
    function XRpgTowerManager.GetIsReset()
        return IsReset
    end
    --[[    ================
    获取本轮的天赋道具ID(玩法道具Id)
    ================
    ]]
    function XRpgTowerManager.GetTalentItemId()
        return CurrentConfig.TalentItemId
    end

    function XRpgTowerManager.GetDailyRewards()
        return CurrentConfig.DailyRewards
    end
    --[[    ================
    获取本轮的升级道具ID
    ================
    ]]
    function XRpgTowerManager.GetLevelUpItemId()
        return UPGRADE_ITEM_ID
    end
    --==============
    --初始化数据是否重置的状态(重置数据后再次重新进入玩法时初始化)
    --==============
    function XRpgTowerManager.SetNewBegining()
        IsReset = false
    end
    --================
    --判断是否第一次进入玩法(本地存储纪录)
    --================
    function XRpgTowerManager.GetIsFirstIn()
        local localData = XSaveTool.GetData("RpgTowerFirstIn" .. XPlayer.Id .. CurrentConfig.ActivityName)
        if localData == nil then
            XSaveTool.SaveData("RpgTowerFirstIn" .. XPlayer.Id .. CurrentConfig.ActivityName, true)
            return true
        end
        return false
    end
    --================
    --判断是否能获取每日补给
    --================
    function XRpgTowerManager.GetCanReceiveSupply()
        return not HadGetDailyReward
    end
    --================
    --获取队伍等级最大值
    --================
    function XRpgTowerManager.GetMaxLevel()
        return RpgTowerConfig.GetTeamMaxLevel()
    end
    --================
    --获取当前等级
    --================
    function XRpgTowerManager.GetCurrentLevel()
        return TeamLevel
    end
    --================
    --获取当前等级配置
    --================
    function XRpgTowerManager.GetCurrentLevelCfg()
        return RpgTowerConfig.GetTeamLevelCfgByLevel(XRpgTowerManager.GetCurrentLevel())
    end
    --================
    --获取当前经验值字符串
    --================
    function XRpgTowerManager.GetCurrentExp()
        return TeamExp
    end
    --================
    --获取等级变化信息
    --================
    function XRpgTowerManager.GetExpChanges()
        local changes = {
            TeamExpNewChange = TeamExpNewChange,
            PreTeamExp = PreTeamExp,
            PreTeamLevel = PreTeamLevel,
            TeamExp = TeamExp,
            TeamLevel = TeamLevel,
            ChangeExp = ChangeExp
        }
        TeamExpNewChange = false
        return changes
    end
    --================
    --检查是否有等级变动
    --================
    function XRpgTowerManager.CheckExpChange()
        local result = TeamExpNewChange
        return result
    end
    -- =========        =========
    -- =========跳转方法 =========
    -- =========        =========
    --[[    ================
    跳转到活动主界面
    ================
    ]]
    function XRpgTowerManager.JumpTo()
        if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.RpgTower) then
            local canGoTo, notStart = XRpgTowerManager.CheckCanGoTo()
            if canGoTo then
                XLuaUiManager.Open("UiRpgTowerNewMain")
            elseif notStart then
                XUiManager.TipMsg(CS.XTextManager.GetText("RpgTowerNotStart"))
            else
                XUiManager.TipMsg(CS.XTextManager.GetText("RpgTowerEnd"))
            end
        end
    end
    --[[    ================
    检查是否能进入玩法
    @return param1:是否在活动时间内(true为在活动时间内)
    @return param2:是否未开始活动(true为未开始活动)
    ================
    ]]
    function XRpgTowerManager.CheckCanGoTo()
        local isActivityEnd, notStart = XRpgTowerManager.GetIsEnd()
        return not isActivityEnd, notStart
    end
    -- =========       =========
    -- =========协议方法=========
    -- =========       =========
    --[[    ================
    请求：激活天赋
    ================
    ]]
    function XRpgTowerManager.CharaTalentActive(rTalent)
        --检查天赋是否跟人物激活天赋类型相同
        if not rTalent:CheckCurrentTalentType() then
            XUiManager.TipMsg(XUiHelper.GetText("RpgTowerTalentTypeNotActive"))
            return
        end
        if rTalent:GetIsUnLock() then
            XUiManager.TipMsg(CS.XTextManager.GetText("RpgTowerCharaTalentIsAlreadyUnlock"))
            return
        end
        if not rTalent:CheckNeedTeamLevel() then
            XUiManager.TipMsg(CS.XTextManager.GetText("RpgTowerTalentLevelNotEnough", rTalent:GetNeedTeamLevel()))
            return
        end
        if not rTalent:GetCanUnLock() then
            if not rTalent:CheckCostEnough() then
                XUiManager.TipMsg(CS.XTextManager.GetText("RpgTowerTalentPointsNotEnough"))
            else
                XUiManager.TipMsg(CS.XTextManager.GetText("RpgTowerTalentCannotUnlock"))
            end
            return
        end
        local characterId = rTalent:GetCharacterId()
        if not MyTeamMember[characterId] then
            XLog.Error(string.format("要激活天赋的成员数据不存在！请检查！角色ID：%s",
                    tostring(characterId)))
            --XLog.Debug("本地兵法蓝图成员数据：", MyTeamMember)
            return
        end
        local layer = rTalent:GetLayer()
        if layer > 1 and MyTeamMember[characterId]:CheckNoActiveByLayer(layer - 1) then
            XUiManager.TipText("RpgTowerPreLayerNotActive")
            return
        end
        if MyTeamMember[characterId]:GetTalentPoints(rTalent:GetTalentType()) < rTalent:GetTalentConsume() then
            XUiManager.TipMsg(CS.XTextManager.GetText("RpgTowerTalentPointsNotEnough"))
            return
        end
        XNetwork.Call(REQUEST_NAMES.CharaTalentActive, { CharacterId = characterId, TalentId = rTalent:GetId() }, function(reply)
                if reply.Code ~= XCode.Success then
                    XUiManager.TipCode(reply.Code)
                    return
                end
                MyTeamMember[characterId]:TalentActive(rTalent, reply.TalentPoints)
                CsXGameEventManager.Instance:Notify(XEventId.EVENT_RPGTOWER_MEMBERCHANGE)
            end)
    end
    --================
    --请求：重置单个天赋
    --================
    function XRpgTowerManager.ResetOneTalent(characterId, talent)
        if not talent then return end
        if not MyTeamMember[characterId] then
            XUiManager.TipText("RpgTowerCharacterNotExist")
            return
        end
        if not MyTeamMember[characterId]:CheckTalentCanReset(talent) then
            XUiManager.TipText("RpgTowerTalentCannotActive")
            return
        end
        XNetwork.Call(REQUEST_NAMES.CharaTalentReset, { CharacterId = characterId, TalentId = talent:GetId() or 0, TalentType = talent:GetTalentType() }, function(reply)
                if reply.Code ~= XCode.Success then
                    XUiManager.TipCode(reply.Code)
                    return
                end
                MyTeamMember[characterId]:LockOneTalent(talent)
                MyTeamMember[characterId]:AddTalentPoints(talent:GetCost(), talent:GetTalentType())
                CsXGameEventManager.Instance:Notify(XEventId.EVENT_RPGTOWER_MEMBERCHANGE)
            end)
    end
    --[[    ================
    请求：重置天赋
    ================
    ]]
    function XRpgTowerManager.CharacterReset(characterId, talentTypeId)
        local tipTitle = CS.XTextManager.GetText("RpgTowerResetTalentConfirmTitle")
        local content = CS.XTextManager.GetText("RpgTowerResetTalentConfirmContent")
        local confirmCb = function()
            if not MyTeamMember[characterId] then
                XUiManager.TipText("RpgTowerCharacterNotExist")
                return
            end
            XNetwork.Call(REQUEST_NAMES.CharaTalentReset, { CharacterId = characterId, TalentId = 0, TalentType = talentTypeId }, function(reply)
                    if reply.Code ~= XCode.Success then
                        XUiManager.TipCode(reply.Code)
                        return
                    end
                    MyTeamMember[characterId]:CharacterReset(reply.TalentPoints, talentTypeId)
                    CsXGameEventManager.Instance:Notify(XEventId.EVENT_RPGTOWER_MEMBERCHANGE)
                end)
        end
        XLuaUiManager.Open("UiDialog", tipTitle, content, XUiManager.DialogType.Normal, nil, confirmCb)
    end
    --================
    --请求：获取今日补给
    --================
    function XRpgTowerManager.ReceiveSupply(cb)
        if not XRpgTowerManager.GetCanReceiveSupply() then
            XUiManager.TipMsg(CS.XTextManager.GetText("RpgTowerCantGetSupply"))
            return
        end
        XNetwork.Call(REQUEST_NAMES.GetDailyReward, {}, function(reply)
                if reply.Code ~= XCode.Success then
                    XUiManager.TipCode(reply.Code)
                    return
                end
                XUiManager.OpenUiObtain(reply.RewardGoodsList)
                HadGetDailyReward = true
                CsXGameEventManager.Instance:Notify(XEventId.EVENT_RPGTOWER_REFRESH_DAILYREWARD)
                XEventManager.DispatchEvent(XEventId.EVENT_RPGTOWER_REFRESH_DAILYREWARD)
            end)
    end
    --================
    --请求：设置角色天赋类型
    --================
    function XRpgTowerManager.SetTalentType(rChara, talentTypeId, cb)
        local tipTitle = CS.XTextManager.GetText("RpgTowerSetTalentTypeTitle")
        local targetTalentName = XRpgTowerConfig.GetTalentTypeConfigByCharacterId(rChara:GetCharacterId(), talentTypeId).Name
        local content = XUiHelper.GetText("RpgTowerChangeTalentTypeTips", rChara:GetCharaTalentTypeName(), targetTalentName, targetTalentName)
        local confirmCb = function()
            XNetwork.Call(REQUEST_NAMES.CharaSetTalentType, {CharacterId = rChara:GetCharacterId(), TalentType = talentTypeId}, function(reply)
                    if reply.Code ~= XCode.Success then
                        XUiManager.TipCode(reply.Code)
                        return
                    end
                    rChara:SetTalentType(talentTypeId)
                    CsXGameEventManager.Instance:Notify(XEventId.EVENT_RPGTOWER_MEMBERCHANGE)
                    if cb then
                        cb()
                    end
                end)
        end
        XLuaUiManager.Open("UiDialog", tipTitle, content, XUiManager.DialogType.Normal, nil, confirmCb)
    end
    --================
    --协议处理：初始化玩法数据
    --================
    function XRpgTowerManager.RefreshData(data)
        if data.ActivityId == 0 then
            XRpgTowerManager.EndActivity()
        elseif CurrentChapter:GetChapterId() ~= data.ActivityId then
            TeamLevel = data.TeamLevel
            TeamExp = data.TeamExp
            HadGetDailyReward = data.HadGetDailyReward
            XRpgTowerManager.Reset(data)
        else
            IsActivityEnd = false
            TeamLevel = data.TeamLevel
            TeamExp = data.TeamExp
            HadGetDailyReward = data.HadGetDailyReward
            XRpgTowerManager.SetTeam(data.Characters) -- List<XRpgCharacter>
            XRpgTowerManager.RefreshStageInfo(data.Stages)
        end
    end
    --[[    ================
    协议处理：每日重置处理
    ================
    ]]
    function XRpgTowerManager.DailyReset()
        HadGetDailyReward = false
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_RPGTOWER_REFRESH_DAILYREWARD)
    end
    --================
    --协议处理：刷新队伍等级
    --@param data : {
    -- int TeamLevel
    -- int TeamExp
    -- List<XRpgCharacter> Characters
    -- List<XRpgStage> Stages
    -- int AddExp }
    --================
    function XRpgTowerManager.RefreshTeamLevelData(data)
        if data.AddExp <= 0 then return end
        PreTeamExp = TeamExp
        PreTeamLevel = TeamLevel
        TeamExp = data.TeamExp
        TeamLevel = data.TeamLevel
        ChangeExp = data.AddExp
        TeamExpNewChange = true
        XRpgTowerManager.SetTeam(data.Characters)
        XEventManager.DispatchEvent(XEventId.EVENT_RPGTOWER_TEAM_LV_REFRESH, data.TeamLevel, data.TeamExp)
    end

    -- 根据TagId获取本期的stage
    function XRpgTowerManager.GetCurrActivityStageListByTagId(tagId)
        if not CurrentConfig then
            return
        end

        local list = XRpgTowerConfig.GetStageListByTagId(tagId)
        local result = {}
        for k, stageCfg in pairs(list) do
            if CurrentConfig.Id == stageCfg.ActivityId then
                table.insert(result, stageCfg)
            end
        end

        return result
    end

    XRpgTowerManager.Init()
    return XRpgTowerManager
end

-- =========        =========
-- =========XRpc方法=========
-- =========        =========
--================
--初始化活动数据
--================
XRpc.NotifyRpgData = function(data)
    XDataCenter.RpgTowerManager.RefreshData(data.Data)
end

XRpc.NotifyRpgStageData = function(data)
    -- XDataCenter.RpgTowerManager.RefreshStageInfo(data.RpgStages)
end

--================
--通知每日重置
--================
XRpc.NotifyRpgDailyReset = function()
    XDataCenter.RpgTowerManager.DailyReset()
end
--================
--通知队伍经验变化
--@param data : {
-- int TeamLevel
-- int TeamExp
-- List<XRpgCharacter> Characters
-- int AddExp }
--================
XRpc.NotifyRpgTeamData = function(data)
    XDataCenter.RpgTowerManager.RefreshTeamLevelData(data)
end