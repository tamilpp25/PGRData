---V2.9魔方嘉年华 关卡逻辑脚本
local XLevelScript100 = XDlcScriptManager.RegLevelLogicScript(100, "XLevelLogicScript100")
local XPlayerNpcContainer = require("Level/Common/XPlayerNpcContainer")
local Timer = require("Level/Common/XTaskScheduler")


--脚本构造函数
---@param proxy StatusSyncFight.XFightScriptProxy
function XLevelScript100:Ctor(proxy)
    self._proxy = proxy
    self._playerNpcContainer = XPlayerNpcContainer.New(self._proxy)
    self._timer = Timer.New()

    self._triggerOfFalling = 101
    self._trigger102 = 102
    self._trigger103 = 103
    self._trigger104 = 104
    self._playerSkillStatus = {} --记录玩家放了哪个技能（缓存复用，避免重复创建table
    self._gridIndexesOfPlayers = {} --记录玩家在哪块砖（缓存复用，避免重复创建table
    self._explosionGridsOfPlayers = {} --记录玩家的技能阵型（缓存复用，避免重复创建table

    self._playerSkillBuff = {}    --玩家球技能判断buff,通过index找特效和阵型
    self._playerSkillBuff[200001] = "FxFloorGreen"
    self._playerSkillBuff[200002] = "FxFloorYellow"
    self._playerSkillBuff[200003] = "FxFloorBlue"
    self._playerSkillBuffList = {200001, 200002, 200003}
    self._bossSkillBuff = {200004, 200005, 200006}    --boss球技能判断buff
    self._effectIdOfPlayer1 = {11, 12, 13, 14, 15, 16, 17, 18, 19}   --记录每个玩家技能点亮的地板特效ID
    self._effectIdOfPlayer2 = {21, 22, 23, 24, 25, 26, 27, 28, 29}
    self._effectIdOfPlayer3 = {31, 32, 33, 34, 35, 36, 37, 38, 39}
    self._effectIdOfBoss = {1, 2, 3, 4, 5, 6, 7, 8, 9}
    self._planeEffect = {
        "FxFloorBlue", "FxFloorGreen", "FxFloorRed", "FxFloorYellow",
        "FxFloorBlue", "FxFloorBombGreen", "FxFloorBombRed", "FxFloorBombYellow",
        "FxScene02706Green", "FxScene02706Blue", "FxScene02706Yellow"
    }

    self._tilePosition = {34.23,37.981,41.729,45.481,49.23,56.4,52.649,48.901,45.152,41.401}    --记录地砖每个交点的坐标
    --地板特效的坐标
    self._effectPositionX = {
        36.1055,39.855,43.605,47.3555,
        36.1055,39.855,43.605,47.3555,
        36.1055,39.855,43.605,47.3555,
        36.1055,39.855,43.605,47.3555
    }
    self._effectPositionZ = {
        54.5245, 54.5245, 54.5245, 54.5245,
        50.775, 50.775, 50.775, 50.775,
        47.0265, 47.0265, 47.0265, 47.0265,
        43.2765, 43.2765, 43.2765, 43.2765
    }
    self._effectPositionY = 0.55
    self._respawnPositionFall = {
        [1] = {x=self._effectPositionX[6], y=1, z=self._effectPositionZ[6]},       
        [2] = {x=self._effectPositionX[7], y=1, z=self._effectPositionZ[7]},       
        [3] = {x=self._effectPositionX[10], y=1, z=self._effectPositionZ[10]},       
        [4] = {x=self._effectPositionX[11], y=1, z=self._effectPositionZ[11]},       
     }
     self._respawnRotationFall = {x=0.0, y=0.0, z=0.0}


    self._rows = 4 --行数
    self._columns = 4 --列数
    self._explosionGrids = {} --爆炸格子列表（缓存复用，避免重复创建table
    self._explosionMatrix = { --爆炸格子阵型（缓存复用，避免重复创建table。直接查询返回使用，不可修改
        square = {
            [1] = {1, 2, 5, 6},
            [2] = {1, 2, 3, 5, 6, 7},
            [3] = {2, 3, 4, 6, 7, 8},
            [4] = {3, 4, 7, 8},
            [5] = {1, 2, 5, 6, 9, 10},
            [6] = {1, 2, 3, 5, 6, 7, 9, 10, 11},
            [7] = {2, 3, 4, 6, 7, 8, 10, 11, 12},
            [8] = {3, 4, 7, 8, 11, 12},
            [9] = {5, 6, 9, 10, 13, 14},
            [10] = {5, 6, 7, 9, 10, 11, 13, 14, 15},
            [11] = {6, 7, 8, 10, 11, 12, 14, 15, 16},
            [12] = {7, 8, 11, 12, 15, 16},
            [13] = {9, 10, 13, 14},
            [14] = {9, 10, 11, 13, 14, 15},
            [15] = {10, 11, 12, 14, 15, 16},
            [16] = {11, 12, 15, 16},
        },
        plusSign = {
            [1] = {1, 2, 3, 4, 5, 9, 13},
            [2] = {1, 2, 3, 4, 6, 10, 14},
            [3] = {1, 2, 3, 4, 7, 11, 15},
            [4] = {1, 2, 3, 4, 8, 12, 16},
            [5] = {1, 5, 6, 7, 8, 9, 13},
            [6] = {2, 5, 6, 7, 8, 10, 14},
            [7] = {3, 5, 6, 7, 8, 11, 15},
            [8] = {4, 5, 6, 7, 8, 12, 16},
            [9] = {1, 5, 9, 10, 11, 12, 13},
            [10] = {2, 6, 9, 10, 11, 12, 14},
            [11] = {3, 7, 9, 10, 11, 12, 15},
            [12] = {4, 8, 9, 10, 11, 12, 16},
            [13] = {1, 5, 9, 13, 14, 15, 16},
            [14] = {2, 6, 10, 13, 14, 15, 16},
            [15] = {3, 7, 11, 13, 14, 15, 16},
            [16] = {4, 8, 12, 13, 14, 15, 16},
        },
        xShape = {
            [1] = {1, 6, 11, 16},
            [2] = {2, 5, 7, 12},
            [3] = {3, 6, 8, 9},
            [4] = {4, 7, 10, 13},
            [5] = {2, 5, 10, 15},
            [6] = {1, 3, 6, 9, 11, 16},
            [7] = {2, 4, 7, 10, 12, 13, 16},
            [8] = {3, 8, 11, 14},
            [9] = {3, 6, 9, 14},
            [10] = {4, 5, 7, 10, 13, 15},
            [11] = {1, 6, 8, 11, 14, 16},
            [12] = {2, 7, 12, 15},
            [13] = {4, 7, 10, 13},
            [14] = {8, 9, 11, 14},
            [15] = {5, 10, 12, 15},
            [16] = {1, 6, 11, 16},
        },
    }
    self._floorRootPos = {x = 34.18, y = 0, z = 41.48} --整个大地板的原点
    self._gridSize = 3.73816 --格子尺寸
    self._round = 1 --回合数
    self._levelTime = 0  --关卡已进行时间
    self._itemTime = 15 --道具生成间隔
    self._switch = true --开关

    
    --分数部分    
    
    self._teamScore = 0           --团队分数
    self._playerScore = {0, 0, 0}    --个人分数
    self._attackScore = {0, 0, 0}    --攻击得分
    self._stunScore = {0, 0, 0}    --受击扣分=被boss击中+坠落
    self._extraScore = {0, 0, 0}    --额外得分(捡道具，救队友)
    
    self._fallingTimes = {0, 0, 0}    --坠落复活次数
    self._stunTimes = {0, 0, 0}    --眩晕次数
    self._saveTimes = {0, 0, 0}    --救人次数
    self._pickupTimes = {0, 0, 0}    --拾取道具次数
    self._attackTimes = {0, 0, 0}    --攻击次数
    self._remainderOfBossHp = 0.0    --boss剩余HP
    self._remainderOfTime = 0    --剩余时间
    
    self._preItemTime = 0 --上一次生成道具的时间
    
end

--初始化
function XLevelScript100:Init()
    self._playerNpcContainer:Init(
        function(npc)
            self:InitialPlayerSet(npc)
        end
    )
    self._playerNpcList = self._playerNpcContainer:GetPlayerNpcList()
    
    self._levelId = self._proxy:GetCurrentLevelId()    --关卡ID(1011普通，1021困难，1031新手教学)
    XLog.Debug("关卡ID是",self._levelId)
    local monTableId = self._levelId == 1011 and 8102 or 8101  --怪物：鲨碧（8101困难,8102普通）
    
    --or前面的是普通数值，后面的是困难数值
    self._stunValue = self._levelId == 1011 and 50 or 100  --眩晕扣分
    self._falingValue = self._levelId == 1011 and 100 or 100  --坠落扣分
    self._itemValue = self._levelId == 1011 and 0 or 500  --捡道具得分
    self._saveValue = self._levelId == 1011 and 100 or 100  --救队友得分
    self._attackValue = self._levelId == 1011 and 500 or 900  --命中boss得分
    self._doubleValue = self._levelId == 1011 and 1.3 or 1.3  --双人同色倍率
    self._trebleValue = self._levelId == 1011 and 1.5 or 1.5  --三人同色倍率
    self._killValue = self._levelId == 1011 and 1000 or 2000  --击杀boss得分
    self._timeValue = self._levelId == 1011 and 100 or 200  --击杀后剩余每秒得分
    self._endTime = self._levelId == 1011 and 110 or 140 --关卡限时
    
    self._timer:Schedule(self._endTime, self, self.FinishLevel, true)--关卡时间
    local monPosition = {x=41.65, y=1.04, z=44.17}
    local monRotation = {x=0.0, y=0.0, z=0.0}
    self._monNpcId = nil
    self._monNpcId = self._proxy:GenerateNpc(monTableId, 2, monPosition, monRotation)
    self._proxy:SetLevelMemoryInt(2002, self._monNpcId)  --Boss动态血条相关
    self._proxy:RegisterEvent(EWorldEvent.ActorTrigger)
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
    
    self._proxy:SetFloatConfig("JumpGravity", -35)    --设置跳跃重力
    self._proxy:SetFloatConfig("FreeFallGravity", -35)    --设置自由落体重力
    self._proxy:SetFloatConfig("JumpSpeed", 12)    --设置跳跃速度
    self._proxy:SetFloatConfig("IdleJumpSpeed", 1.8)    --设置站立时跳跃向前速度
    self._proxy:SetFloatConfig("MoveJumpSpeed", 3.3)    --设置移动时跳跃向前速度

    --[[为了对齐判定坐标点所加的特效
    local testid = {101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116}
    for index, value in ipairs(testid) do
        self._proxy:CreateLevelEffect(testid[index], self._planeEffect[10], self._effectPositionx[index], self._effectPositiony, self._effectPositionz[index],
        0, 0, 0, 0, 0, 0) 
    end--]]
    self._proxy:SetLevelMemoryInt(4000, 1)
    self._proxy:SetLevelMemoryInt(4001, self._round)
end

--事件
---@param eventType number
---@param eventArgs userdata               
function XLevelScript100:HandleEvent(eventType, eventArgs)
    self._playerNpcContainer:HandleEvent(eventType, eventArgs)
    XLog.Debug("Level100 handle event:" .. tostring(eventType))
    --Trigger处理模块
    if (eventType == EWorldEvent.ActorTrigger) then
        XLog.Debug("有trigger被触发了")
        if (eventArgs.HostSceneObjectPlaceId == self._triggerOfFalling and eventArgs.TriggerState == 1)  then
            XLog.Debug("收到来自trigger101的事件")
            for index, _ in ipairs(self._playerNpcList) do
                if (eventArgs.EnteredActorUUID == self._playerNpcList[index]) then
                    local triggerNpc = self._playerNpcList[index]
                    self._fallingTimes[index] = self._fallingTimes[index] + 1  --坠落次数+1
                    local playerScoreValue = self._playerScore[index] - self._falingValue --预计算个人分数
                    --个人分数不够扣时的处理:扣光剩余分数
                    if playerScoreValue < 0 then
                        self._stunScore[index] = self._stunScore[index] + self._playerScore[index]  --坠落扣分
                        self._proxy:ChangeRubikPlayerScore(self._playerNpcList[index], -self._falingValue)--个人分处理，程序会自动处理小于0情况
                        self._teamScore = self._teamScore - self._playerScore[index]  --团队分数处理
                        self._proxy:ChangeRubikTeamScore(-self._playerScore[index])
                        self._playerScore[index] = 0
                    else
                        self._stunScore[index] = self._stunScore[index] + self._falingValue  --坠落扣分
                        self._playerScore[index] = self._playerScore[index] - self._falingValue  --个人分数处理
                        self._proxy:ChangeRubikPlayerScore(self._playerNpcList[index], -self._falingValue)
                        self._teamScore = self._teamScore - self._falingValue  --团队分数处理
                        if self._teamScore < 0 then
                            self._teamScore = 0
                        end
                        self._proxy:ChangeRubikTeamScore(-self._falingValue) 
                    end
                    XLog.Debug(index.."号玩家掉下去了")
                    --传送到复活点，并解晕
                    self._proxy:SetNpcPosAndRot(triggerNpc, self._respawnPositionFall[math.random(1, 4)], self._respawnRotationFall, true)
                    self._proxy:ApplyMagic(triggerNpc, triggerNpc, 8101016, 1)  
                end 
            end 
        end
    --眩晕，救人，捡道具处理部分
    elseif (eventType == EWorldEvent.NpcAddBuff) then
        local index = nil
        for npcIndex, playNpc in ipairs(self._playerNpcList) do
            if playNpc == eventArgs.NpcUUID then
                index = npcIndex  --获得npc的index
            end
        end
        if index ~= nil then
            if eventArgs.BuffTableId == 8101018 then    --检测被眩晕
                self._proxy:ApplyMagic(eventArgs.NpcUUID, eventArgs.NpcUUID, 8101027, 1)    --删除判定buff
                self._stunTimes[index] = self._stunTimes[index] + 1  --眩晕次数+1
                local playerScoreValue = self._playerScore[index] - self._stunValue --预计算个人分数
                --个人分数不够扣时的处理:扣光剩余分数
                if playerScoreValue < 0 then
                    self._stunScore[index] = self._stunScore[index] + self._playerScore[index]  --受击扣分
                    self._proxy:ChangeRubikPlayerScore(self._playerNpcList[index], -self._stunValue)--个人分处理，程序会自动处理小于0情况
                    self._teamScore = self._teamScore - self._playerScore[index]  --团队分数处理
                    self._proxy:ChangeRubikTeamScore(-self._playerScore[index])
                    self._playerScore[index] = 0
                else        
                    self._stunScore[index] = self._stunScore[index] + self._stunValue  --受击扣分              
                    self._playerScore[index] = self._playerScore[index] - self._stunValue  --个人分数处理
                    self._proxy:ChangeRubikPlayerScore(self._playerNpcList[index], -self._stunValue)
                    self._teamScore = self._teamScore - self._stunValue  --团队分数处理
                    self._proxy:ChangeRubikTeamScore(-self._stunValue)
                    if self._teamScore < 0 then
                        self._teamScore = 0
                    end
                end
            elseif eventArgs.BuffTableId == 8101022 then    --检测救人
                self._proxy:ApplyMagic(eventArgs.NpcUUID, eventArgs.NpcUUID, 8101030, 1)    --删除救人判定buff
                self._saveTimes[index] = self._saveTimes[index] + 1  --救人次数+1
                self._extraScore[index] = self._extraScore[index] + self._saveValue  --救人加分
                self._playerScore[index] = self._playerScore[index] + self._saveValue  --个人分数处理
                self._proxy:ChangeRubikPlayerScore(self._playerNpcList[index], self._saveValue)

                self._teamScore = self._teamScore + self._saveValue  --团队分数处理
                self._proxy:ChangeRubikTeamScore(self._saveValue)
            elseif eventArgs.BuffTableId == 8101025 then    --检测捡到加分道具
                XLog.Debug("捡到加分道具了")
                self._proxy:ApplyMagic(eventArgs.NpcUUID, eventArgs.NpcUUID, 8101033, 1)    --删除加分道具判定buff
                XLog.Debug("删除判断buff")
                self._pickupTimes[index] = self._pickupTimes[index] + 1  --拾取道具次数+1
                self._extraScore[index] = self._extraScore[index] + self._itemValue  --拾取道具加分
                self._playerScore[index] = self._playerScore[index] + self._itemValue  --个人分数处理
                self._proxy:ChangeRubikPlayerScore(self._playerNpcList[index], self._itemValue)
                XLog.Debug("完成个人分数处理")

                self._teamScore = self._teamScore + self._itemValue  --团队分数处理
                self._proxy:ChangeRubikTeamScore(self._itemValue)
                XLog.Debug("完成团队分数处理")
            end
        end
    end

end

--每帧执行
---@param dt number @ delta time
function XLevelScript100:Update(dt)
    self._timer:Update(dt)
    self._levelTime = self._levelTime + dt  --记录关卡已进行时间
    if not self._proxy:CheckNpc(self._monNpcId) and self._switch then
        self:BossDieSet()
        self._switch = false 
    end

    if self._levelId ~= 1011 and self._proxy:CheckNpc(self._monNpcId) then  --非普通难度则生成道具
        if (self._levelTime - self._preItemTime) >= self._itemTime then  --生成道具
            self._preItemTime = self._levelTime
            self._proxy:ApplyMagic(self._monNpcId, self._monNpcId, 8101035, 1)     
        end
    end
    

    if self._proxy:CheckNpc(self._monNpcId) then
        if self._proxy:CheckBuffByKind(self._monNpcId, 8101020) then    --检测boss是否进入躲避球阶段
            for index, playerNpc in ipairs(self._playerNpcList) do
                self._proxy:ApplyMagic(playerNpc, playerNpc, self._playerSkillBuffList[math.random(1, 3)], 1)    --随机先给玩家一个技能buff 
            end
            self._proxy:ApplyMagic(self._monNpcId, self._monNpcId, 8101028, 1)    --删除技能判定buff
            self._proxy:ApplyMagic(self._monNpcId, self._monNpcId, self._bossSkillBuff[math.random(1, 3)], 1)    --随机给boss一个技能buff
            self:BossSkillWarning()  --立刻调用boss预警

            local difficulty = self._proxy:CheckNpcNoteInt(self._monNpcId, 81010202) and self._proxy:GetNpcNoteInt(self._monNpcId, 81010202) or 1  --获得boss的2#值作为难度，缺省则为1
            local delayTime = nil
            if difficulty == 1 then  --根据难度决定几秒后爆炸
                delayTime = 7
            elseif difficulty == 2 or 3 then
                delayTime = 6
            else
                delayTime = 5
            end
            XLog.Debug("boss难度为",difficulty,delayTime,"秒后爆炸")
            self._timer:Schedule(delayTime, self, self.PlayerSkillJudge, true)     -- n秒后调用结算
            for _, playNpc in ipairs(self._playerNpcList) do
                self._proxy:ApplyMagic(playNpc, playNpc, 200019, 1)    --显示技能按钮

                self._proxy:SetLevelMemoryInt(4000, 2)
                self._proxy:SetLevelMemoryInt(4001, self._round)
                self._proxy:SetLevelMemoryInt(4002, delayTime)  --爆炸倒计时
                self._proxy:ApplyMagic(playNpc, playNpc, 200023, 1)    --UI设置
            end
        end

        if self._proxy:CheckBuffByKind(self._monNpcId, 8101021) then    --检测boss是否退出躲避球阶段
            self._proxy:ApplyMagic(self._monNpcId, self._monNpcId, 8101029, 1)    --删除技能判定buff
            self._round = self._round + 1
        end
    end
    --[[
    --分数计算需要
    for index, playNpc in ipairs(self._playerNpcList) do
        if self._proxy:CheckBuffByKind(playNpc, 8101018) then    --检测被眩晕
            self._proxy:ApplyMagic(playNpc, playNpc, 8101027, 1)    --删除技能判定buff
            self._stunTimes[index] = self._stunTimes[index] + 1  --眩晕次数+1
            local playerScoreValue = self._playerScore[index] - self._stunValue --预计算个人分数
            --个人分数不够扣时的处理:扣光剩余分数
            if playerScoreValue < 0 then
                self._stunScore[index] = self._stunScore[index] + self._playerScore[index]  --受击扣分
                self._proxy:ChangeRubikPlayerScore(self._playerNpcList[index], -self._stunValue)--个人分处理，程序会自动处理小于0情况
                self._teamScore = self._teamScore - self._playerScore[index]  --团队分数处理
                self._proxy:ChangeRubikTeamScore(-self._playerScore[index])
                self._playerScore[index] = 0
            else        
                self._stunScore[index] = self._stunScore[index] + self._stunValue  --受击扣分              
                self._playerScore[index] = self._playerScore[index] - self._stunValue  --个人分数处理
                self._proxy:ChangeRubikPlayerScore(self._playerNpcList[index], -self._stunValue)
                self._teamScore = self._teamScore - self._stunValue  --团队分数处理
                self._proxy:ChangeRubikTeamScore(-self._stunValue)
                if self._teamScore < 0 then
                    self._teamScore = 0
                end
            end
        end
        if self._proxy:CheckBuffByKind(playNpc, 8101022) then    --检测救人
            self._proxy:ApplyMagic(playNpc, playNpc, 8101030, 1)    --删除救人判定buff
            self._saveTimes[index] = self._saveTimes[index] + 1  --救人次数+1
            self._extraScore[index] = self._extraScore[index] + self._saveValue  --救人加分
            self._playerScore[index] = self._playerScore[index] + self._saveValue  --个人分数处理
            self._proxy:ChangeRubikPlayerScore(self._playerNpcList[index], self._saveValue)

            self._teamScore = self._teamScore + self._saveValue  --团队分数处理
            self._proxy:ChangeRubikTeamScore(self._saveValue)
        end
        if self._proxy:CheckBuffByKind(playNpc, 8101025) then    --检测捡到加分道具
            XLog.Debug("捡到加分道具了")
            self._proxy:ApplyMagic(playNpc, playNpc, 8101033, 1)    --删除加分道具判定buff
            XLog.Debug("删除判断buff")
            self._pickupTimes[index] = self._pickupTimes[index] + 1  --拾取道具次数+1
            self._extraScore[index] = self._extraScore[index] + self._itemValue  --拾取道具加分
            self._playerScore[index] = self._playerScore[index] + self._itemValue  --个人分数处理
            self._proxy:ChangeRubikPlayerScore(self._playerNpcList[index], self._itemValue)
            XLog.Debug("完成个人分数处理")

            self._teamScore = self._teamScore + self._itemValue  --团队分数处理
            self._proxy:ChangeRubikTeamScore(self._itemValue)
            XLog.Debug("完成团队分数处理")
        end
    end
    --]]
end

--boss死亡时的分数计算和结算
function XLevelScript100:BossDieSet()
    local score = self._killValue + self._timeValue * math.ceil((self._endTime - self._levelTime)) --击杀积分+剩余时间奖励
    for index, _ in ipairs(self._playerNpcList) do
        XLog.Debug("鲨士碧儿已经死翘翘啦！每人获得",self._killValue,"分数，击杀时间为",self._levelTime,"剩余每秒奖励每人",self._timeValue,"分")
        self._extraScore[index] = self._extraScore[index] + self._timeValue * math.ceil((self._endTime - self._levelTime))  --剩余时间奖励算入额外积分
        self._attackScore[index] = self._attackScore[index] + self._killValue --击杀得分算入攻击积分

        self._playerScore[index] = self._playerScore[index] + score--个人分数处理
        self._proxy:ChangeRubikPlayerScore(self._playerNpcList[index], score)
        XLog.Debug(index,"号玩家分数处理完毕，个人分数为",self._playerScore[index],"其中击杀后获得奖励为",score,"分")

        self._teamScore = self._teamScore + score  --团队分数处理
        self._proxy:ChangeRubikTeamScore(score)
        XLog.Debug("团队分数处理完毕，团队分数为",self._teamScore,"分")

    end
    XLog.Debug("分数算完，准备进入结算")

    self:FinishLevel()
end

--初始玩家设置
function XLevelScript100:InitialPlayerSet(npc)
    self._proxy:SetSceneColliderIgnoreCollision(npc, "Wall", -1, 0)  --四面墙对所有玩家不生效
    self._proxy:ChangeRubikPlayerScore(npc, 1000)  --每个玩家初始分为1000
    --防止单机时，在self._playerNpcList未初始化情况下进行访问。
    if self._playerNpcList == nil then
        self._playerNpcList = self._playerNpcContainer:GetPlayerNpcList()
    end
    for index, playerNpc in ipairs(self._playerNpcList) do
        if npc == playerNpc then
            self._playerScore[index] = self._proxy:GetRubikPlayerScore(playerNpc)
        end
    end
    self._proxy:ChangeRubikTeamScore(1000)    --设置初始团队分数
    self._teamScore = self._proxy:GetRubikTeamScore()
    self._proxy:ApplyMagic(npc, npc, 200023, 1)    --初始UI设置
end

--boss的技能预警
function XLevelScript100:BossSkillWarning()
    local bossGrid = nil    --算出boss在哪一块地板
    local grids = nil         --调用方法计算地板阵型
    for _, buffId in ipairs(self._bossSkillBuff) do
        local bossSkillStatus = nil  --记录boss放了哪个技能
        if self._proxy:CheckBuffByKind(self._monNpcId, buffId) then
            bossSkillStatus = buffId                  --boss肯定有且只有3buff之一
            local position = self._proxy:GetNpcPosition(self._monNpcId)    --获取boss位置
            bossGrid = self:GetGridIndexByPos(position.x, position.z)    --算出boss在哪一块地板
            
            grids = self:GetExplosionGrids(bossGrid, bossSkillStatus)         --调用方法计算地板阵型
            self:LightUpPlane(4, grids, "FxFloorRed")    --调用方法点亮地板
            break
        end
    end
end

--技能效果处理
function XLevelScript100:PlayerSkillJudge()
    local playerGridIndex = nil     --算出玩家在哪一块地板
    local explosionGrids = nil     --调用方法计算地板阵型
    for index, playerNpc in ipairs(self._playerNpcList) do
        self._proxy:ApplyMagic(playerNpc, playerNpc, 200018, 1)    --隐藏技能按钮
        self._timer:Schedule(2, self, self.ShowTip, true)     -- 显示下一回合UI
        for skillBuffId, effectName in pairs(self._playerSkillBuff) do
            if self._proxy:CheckBuffByKind(playerNpc, skillBuffId) then
                local position = self._proxy:GetNpcPosition(playerNpc)    --获取玩家位置
                playerGridIndex = self:GetGridIndexByPos(position.x, position.z)     --算出玩家在哪一块地板
                explosionGrids = self:GetExplosionGrids(playerGridIndex, skillBuffId)     --调用方法计算地板阵型
                self:LightUpPlane(index, explosionGrids, effectName)    --调用方法点亮地板

                self._gridIndexesOfPlayers[index] = playerGridIndex
                self._playerSkillStatus[index] = skillBuffId     --玩家肯定有且只有3buff之一，默认给个球
                self._explosionGridsOfPlayers[index] = explosionGrids --记录玩家技能阵型
                self._proxy:ApplyMagic(playerNpc, playerNpc, 200017, 1)    --删除技能判定buff
            end
        end
    end
    local bossPosition = nil    --算出boss在哪一块地板
    local table = nil         --调用方法计算地板阵型
    for _, buffId in ipairs(self._bossSkillBuff) do
        local bossSkillStatus = nil  --记录boss放了哪个技能
        if self._proxy:CheckBuffByKind(self._monNpcId, buffId) then
            bossSkillStatus = buffId                  --boss肯定有且只有3buff之一
            local position = self._proxy:GetNpcPosition(self._monNpcId)    --获取boss位置
            bossPosition = self:GetGridIndexByPos(position.x, position.z)    --算出boss在哪一块地板
            self._proxy:ApplyMagic(self._monNpcId, self._monNpcId, 200017, 1)    --删除技能判定buff
            table = self:GetExplosionGrids(bossPosition, bossSkillStatus)         --调用方法计算地板阵型
            --self:LightUpPlane(4, table, "FxFloorRed")    --调用方法点亮地板
            break
        end
    end
    --【【【【是否中招的判定】】】】
    XLog.Debug("准备判断玩家是否被boss打中")
    for index, _ in ipairs(self._playerNpcList) do  --先检测每个玩家是否中了boss的招o(￣ヘ￣o＃)
        XLog.Debug("准备判断",index,"号玩家是否被boss打中")
        for _, value in ipairs(table) do
            XLog.Debug(index,"号玩家所在地板编号为",self._gridIndexesOfPlayers[index])
            if self._gridIndexesOfPlayers[index] == value then
                XLog.Debug("玩家被boss打中了")
                local playerScoreValue = self._playerScore[index] - self._stunValue --预计算个人分数
                --个人分数不够扣时的处理:扣光剩余分数
                if playerScoreValue < 0 then
                    self._stunScore[index] = self._stunScore[index] + self._playerScore[index]  --受击扣分
                    self._proxy:ChangeRubikPlayerScore(self._playerNpcList[index], -self._stunValue)--个人分处理，程序会自动处理小于0情况
                    self._teamScore = self._teamScore - self._playerScore[index]  --团队分数处理
                    self._proxy:ChangeRubikTeamScore(-self._playerScore[index])
                    self._playerScore[index] = 0
                else
                    self._stunScore[index] = self._stunScore[index] + self._stunValue  --受击扣分
                    XLog.Debug("玩家被boss打中扣分计算完毕")
                    self._playerScore[index] = self._playerScore[index] - self._stunValue  --个人分数处理
                    self._proxy:ChangeRubikPlayerScore(self._playerNpcList[index], -self._stunValue)
                    XLog.Debug("玩家被boss打中扣分操作完毕")   
                    self._teamScore = self._teamScore - self._stunValue  --团队分数处理
                    XLog.Debug("玩家被boss打中团队扣分计算完毕")
                    self._proxy:ChangeRubikTeamScore(-self._stunValue)
                    XLog.Debug("玩家被boss打中团队扣分操作完毕")
                    if self._teamScore < 0 then
                        self._teamScore = 0
                    end
                end
            end
        end   
    end

    local multiple = nil  --倍率
    if self._playerSkillStatus[1] == self._playerSkillStatus[2] and self._playerSkillStatus[1] == self._playerSkillStatus[3]  then
        multiple = 1.5
    elseif self._playerSkillStatus[1] == self._playerSkillStatus[2] or self._playerSkillStatus[1] == self._playerSkillStatus[3] or self._playerSkillStatus[2] == self._playerSkillStatus[3] then
        multiple = 1.3
    else
        multiple = 1
    end
    for index, table in pairs(self._explosionGridsOfPlayers) do  --再检测boss是否中了每个玩家的招w(ﾟДﾟ)w
        for _, value in ipairs(table) do
            if bossPosition == value then
                self._attackTimes[index] = self._attackTimes[index] + 1  --攻击次数+1
                self._attackScore[index] = self._attackScore[index] + self._attackValue * multiple  --命中boss加分
                self._playerScore[index] = self._playerScore[index] + self._attackValue * multiple  --个人分数处理
                self._proxy:ChangeRubikPlayerScore(self._playerNpcList[index], self._attackValue * multiple)
                
                self._teamScore = self._teamScore + self._attackValue * multiple  --团队分数处理
                self._proxy:ChangeRubikTeamScore(self._attackValue * multiple)
                if multiple == 1.5 then
                    self._proxy:ApplyMagic(self._monNpcId, self._monNpcId, 200022, 1)    --boss受到1.5伤害
                elseif multiple == 1.3 then
                    self._proxy:ApplyMagic(self._monNpcId, self._monNpcId, 200021, 1)    --boss受到1.3伤害    
                else
                    self._proxy:ApplyMagic(self._monNpcId, self._monNpcId, 200020, 1)    --boss受到1伤害
                end
                break
            end
        end
    end
end

--计算地板阵型
---@param gridIndex number @ 输入npc所在地板编号
---@param skillBuffId number @ 技能
function XLevelScript100:GetExplosionGrids(gridIndex, skillBuffId)
    XLog.Debug("玩家所在的地板编号是", gridIndex,"玩家所带buff是", skillBuffId)
    local result = nil    --记录结果
    if skillBuffId == 200001 or skillBuffId == 200004 then    --九宫格
        result = self._explosionMatrix.square[gridIndex]
    elseif skillBuffId == 200002 or skillBuffId == 200005 then    --十字
        result = self._explosionMatrix.plusSign[gridIndex]
    elseif skillBuffId == 200003 or skillBuffId == 200006 then    --X型
        result = self._explosionMatrix.xShape[gridIndex]
    end

    if result ~= nil then
        XLog.Debug("关卡0100 GetExplosionGrids 需要亮起的地板编号依次是",table.concat(result, ","))
    else
        XLog.Warning("关卡0100 GetExplosionGrids 返回空table gridIndex:", gridIndex, " skillBuffId:", skillBuffId)
    end

    return result
end

--点亮地板
---@param playerIndex number @ 玩家序号1234(boss)
---@param tileTable table @ 要点亮的地板序号
---@param effectName string @ 特效名
function XLevelScript100:LightUpPlane(playerIndex, tileTable, effectName)
    if tileTable == nil then
        XLog.Error("关卡0100 LightUpPlane: tileTable为空！")
        return
    end


    local effectId = nil
    local effectExp = nil
    if playerIndex == 1 then
        effectId = self._effectIdOfPlayer1    --分配id
    elseif playerIndex == 2 then
        effectId = self._effectIdOfPlayer2
    elseif playerIndex == 3 then
        effectId = self._effectIdOfPlayer3
    else
        effectId = self._effectIdOfBoss
    end

    for index, value in ipairs(tileTable) do 
        self._proxy:CreateLevelEffect(effectId[index], effectName,
            self._effectPositionX[value], self._effectPositionY, self._effectPositionZ[value],
            0, 0, 0, 0, 0, 0)    --放地板特效
        XLog.Debug("已点亮编号为",value, "的地板，特效名是",effectName,"坐标是",self._effectPositionX[value], ",", self._effectPositionY, ",", self._effectPositionZ[value])

        if effectName == "FxFloorBlue" then
            effectExp = "FXFloorBombBlue"
        elseif effectName == "FxFloorGreen" then
            effectExp = "FxFloorBombGreen"
        elseif effectName == "FxFloorRed" then
            effectExp = "FxFloorBombRed"
        elseif effectName == "FxFloorYellow" then
            effectExp = "FxFloorBombYellow"
        end

        local delayTime = nil
        if playerIndex == 4 then --是boss的话
            local difficulty = self._proxy:CheckNpcNoteInt(self._monNpcId, 81010202) and self._proxy:GetNpcNoteInt(self._monNpcId, 81010202) or 1  --获得boss的2#值作为难度，缺省则为1
            if difficulty == 1 then  --根据难度决定几秒后爆炸
                delayTime = 7
            elseif difficulty == 2 or 3 then
                delayTime = 6
            else
                delayTime = 5
            end
            XLog.Debug("boss难度为",difficulty,delayTime,"秒后爆炸")
        else
            delayTime = 0.5 --是玩家的话
        end
        self._timer:Schedule(delayTime, nil, function()
            self._proxy:RemoveLevelEffect(effectId[index])--删除地板特效
            self._proxy:CreateLevelEffect(effectId[index], effectExp,
                self._effectPositionX[value], self._effectPositionY, self._effectPositionZ[value],
                0, 0, 0, 0, 0, 0)  --放爆炸特效
            self._timer:Schedule(5, self._proxy, self._proxy.RemoveLevelEffect, effectId[index])     -- 销毁爆炸特效
        end)
    end
end

--坐标处于哪块地板
function XLevelScript100:GetGridIndexByPos(x, z)
    XLog.Debug("玩家的坐标是", x, z)
    local gridIndex = nil  -- 记录计算结果
    if x >= self._tilePosition[1] and x < self._tilePosition[2] then
        if z <= self._tilePosition[6] and z > self._tilePosition[7] then
            gridIndex = 1
        elseif z <= self._tilePosition[7] and z > self._tilePosition[8] then
            gridIndex = 5
        elseif z <= self._tilePosition[8] and z > self._tilePosition[9] then
            gridIndex = 9
        elseif z <= self._tilePosition[9] and z > self._tilePosition[10] then
            gridIndex = 13
        end
    elseif x >= self._tilePosition[2] and x < self._tilePosition[3] then
        if z <= self._tilePosition[6] and z > self._tilePosition[7] then
            gridIndex = 2
        elseif z <= self._tilePosition[7] and z > self._tilePosition[8] then
            gridIndex = 6
        elseif z <= self._tilePosition[8] and z > self._tilePosition[9] then
            gridIndex = 10
        elseif z <= self._tilePosition[9] and z > self._tilePosition[10] then
            gridIndex = 14
        end
    elseif x >= self._tilePosition[3] and x < self._tilePosition[4] then
        if z <= self._tilePosition[6] and z > self._tilePosition[7] then
            gridIndex = 3
        elseif z <= self._tilePosition[7] and z > self._tilePosition[8] then
            gridIndex = 7
        elseif z <= self._tilePosition[8] and z > self._tilePosition[9] then
            gridIndex = 11
        elseif z <= self._tilePosition[9] and z > self._tilePosition[10] then
            gridIndex = 15
        end
    elseif x >= self._tilePosition[4] and x < self._tilePosition[5] then
        if z <= self._tilePosition[6] and z > self._tilePosition[7] then
            gridIndex = 4
        elseif z <= self._tilePosition[7] and z > self._tilePosition[8] then
            gridIndex = 8
        elseif z <= self._tilePosition[8] and z > self._tilePosition[9] then
            gridIndex = 12
        elseif z <= self._tilePosition[9] and z > self._tilePosition[10] then
            gridIndex = 16
        end
    end
    return gridIndex
end

--关卡结束
function XLevelScript100:FinishLevel()
    
    for index, playerNpc in ipairs(self._playerNpcList) do
        self._proxy:SetLevelMemoryInt(4003, 1) --关闭UI信号值
        self._proxy:ApplyMagic(playerNpc, playerNpc, 200024, 1)    --finish特效
        local playerId = self._proxy:GetPlayerIdByNpc(playerNpc)
        self._proxy:SetFightResultCustomData(playerId, 1, self._playerScore[index])    --个人积分
        self._proxy:SetFightResultCustomData(playerId, 2, self._teamScore)     --队伍积分
        self._proxy:SetFightResultCustomData(playerId, 3, self._attackScore[index])    --命中得分
        self._proxy:SetFightResultCustomData(playerId, 4, self._stunScore[index])    --受击扣分
        self._proxy:SetFightResultCustomData(playerId, 5, self._extraScore[index])    --合作加分
        self._proxy:SetFightResultCustomData(playerId, 6, self._attackTimes[index])    --攻击boss次数
        self._proxy:SetFightResultCustomData(playerId, 7, self._pickupTimes[index])    --拾取道具次数
        self._proxy:SetFightResultCustomData(playerId, 8, self._saveTimes[index])    --救人次数
        self._proxy:SetFightResultCustomData(playerId, 9, self._stunTimes[index])    --眩晕次数
        self._proxy:SetFightResultCustomData(playerId, 10, self._fallingTimes[index])    --坠落复活次数
    end
    self._proxy:DestroyAllMissileDependOnLauncher(self._monNpcId)  --移除boss的所有子弹
    self._timer:Schedule(2, self._proxy, function(proxy, isWin)
        proxy:SettleFight(isWin)
        proxy:FinishFight()
    end, true)  --"已经结束啦！"
end

--脚本终止
function XLevelScript100:Terminate()

end

---计算爆炸格子阵型
---@param grid number @ 输入npc所在格子一维序号
---@param skillID number @ 技能
function XLevelScript100:CalcExplosionGrids(grid, skillID)
    XLog.Debug("玩家所在的地板编号是", grid, "玩家所带buff是", skillID)

    local result = nil ---@type table

    --清除爆炸格子列表
    for i = 1, #self._explosionGrids do
        self._explosionGrids[i] = nil
    end

    local npcGridIndex = grid --Npc所处格子的一维索引
    local npcRow = math.ceil(npcGridIndex / self._columns) --所处格子的行
    local npcColumn = npcGridIndex % self._columns --所处格子的列

    if skillID == 200001 or skillID == 200004 then -- □ （九宫格阵型
        --从左上邻近格子开始，以3X3的方式遍历并将格子索引加入列表中
        for i = npcRow - 1, 3 do
            for j = npcColumn - 1, 3 do
                --检查格子索引是否有效
                if i > 0 and j > 0 and i <= self._rows and j <= self._columns then
                    --计算格子的一维索引
                    local gridIndex = (i - 1) * self._columns + j
                    --添加到列表尾部
                    self._explosionGrids[#self._explosionGrids + 1] = gridIndex
                end
            end
        end
    elseif skillID == 200002 or skillID == 200005 then -- + （十字阵型
        --先添加所处格子的这一整列
        for row = 1, self._rows do
            local gridIndex = (row - 1) * self._columns + npcColumn
            self._explosionGrids[#self._explosionGrids + 1] = gridIndex
        end
        --再添加所处格子的这一整行
        for column = 1, self._columns do
            local gridIndex = (npcRow - 1) * self._columns + column
            self._explosionGrids[#self._explosionGrids + 1] = gridIndex
        end
    elseif skillID == 200003 or skillID == 200006 then -- X （斜十字阵型
        --假设玩家的起始格子位置是有效的（如果有可能无效，需在函数开始时检查并做返回处理
        --增加起点格子
        self._explosionGrids[#self._explosionGrids + 1] = (npcRow - 1) * self._columns + npcColumn

        --以下注释中的方向具体取决于格子布局详情，见文件末尾的注释：场景格子布局
        --向左下延伸，直至遇到无效的格子索引
        local row = npcRow - 1
        local column = npcColumn - 1
        while row > 0 and column > 0 do
            local gridIndex = (npcRow - 1) * self._columns + column
            self._explosionGrids[#self._explosionGrids + 1] = gridIndex

            row = row - 1
            column = column - 1
        end

        --向右下延伸
        row = npcRow - 1
        column = npcColumn + 1
        while row > 0 and column <= self._columns do
            local gridIndex = (npcRow - 1) * self._columns + column
            self._explosionGrids[#self._explosionGrids + 1] = gridIndex

            row = row - 1
            column = column + 1
        end

        --左上
        row = npcRow + 1
        column = npcColumn - 1
        while row <= self._rows and column > 0 do
            local gridIndex = (npcRow - 1) * self._columns + column
            self._explosionGrids[#self._explosionGrids + 1] = gridIndex

            row = row + 1
            column = column - 1
        end

        --右上
        row = npcRow + 1
        column = npcColumn + 1
        while row <= self._rows and column <= self._columns do
            local gridIndex = (npcRow - 1) * self._columns + column
            self._explosionGrids[#self._explosionGrids + 1] = gridIndex

            row = row + 1
            column = column + 1
        end
    end

    result = self._explosionGrids

    if result ~= nil then
        XLog.Debug("需要亮起的地板编号依次是", table.concat(result, ","))
    else
        XLog.Debug("得到了个空表")
    end

    return result
end

---根据坐标计算所在格子的一维索引
---@param x number
---@param z number
function XLevelScript100:GetGridIndexByPosNew(x, z)
    --先阅读文件末尾注释：场景格子布局

    local gridIndex = 0

    local posOnFloorX = x - self._floorRootPos.x
    local posOnFloorZ = z - self._floorRootPos.z
    local column = math.floor(posOnFloorX / self._gridSize) + 1
    local row = math.ceil(posOnFloorZ / self._gridSize)

    if column > self._columns then
        column = self._columns
    end

    if row <= 0 then
        row = 1
    end

    XLog.Debug("--------计算格子行列：" .. tostring(row) .. ", " .. tostring(column))

    gridIndex = (row - 1) * self._columns + column

    return gridIndex
end

---用于计算格子中心坐标，以便创建特效
---@param gridIndex number @格子的一维索引，大于0的整数
function XLevelScript100:GetGridCenterPosByIndex(gridIndex)
    --先阅读文件末尾注释：场景格子布局

    local row = math.ceil(gridIndex / self._columns) --所处格子的行
    local column = gridIndex % self._columns --所处格子的列
    -- effectPos = gridPos + gridSize / 2
    local x = (column - 1) * self._gridSize + self._gridSize / 2 + self._floorRootPos.x
    local z = (row - 1) * self._gridSize + self._gridSize / 2 + self._floorRootPos.z

    return x, z
end

--[[ 场景格子布局
    Z
    ↑
    |13| 14| 15| 16|
    |9 | 10| 11| 12|
    |5 | 6 | 7 | 8 |
    |1 | 2 | 3 | 4 |
    +---------------->X
--]]

--新一回合开始的UI设置
function XLevelScript100:ShowTip() 
    for _, playNpc in ipairs(self._playerNpcList) do
        self._proxy:SetLevelMemoryInt(4000, 1)
        self._proxy:SetLevelMemoryInt(4001, self._round)
        self._proxy:ApplyMagic(playNpc, playNpc, 200023, 1)    --UI设置
    end
end

return XLevelScript100