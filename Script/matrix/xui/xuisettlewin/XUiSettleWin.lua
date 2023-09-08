local XUiPanelExpBar = require("XUi/XUiSettleWinMainLine/XUiPanelExpBar")
local XUiPanelSettleWinPokemon = require("XUi/XUiSettleWin/XUiPanelSettleWinPokemon")
local XUiStageSettleSound = require("XUi/XUiSettleWin/XUiStageSettleSound")

local XUiSettleWin = XLuaUiManager.Register(XLuaUi, "UiSettleWin")
local CSTextManagerGetText = CS.XTextManager.GetText

function XUiSettleWin:OnAwake()
    self:InitAutoScript()

    self.GridReward.gameObject:SetActiveEx(false)
    self.PanelPokemon.gameObject:SetActiveEx(false)
    self.PanelLivRealistic.gameObject:SetActiveEx(false)
    self.GridWinRole.gameObject:SetActiveEx(false)
    self.PanelLeft.gameObject:SetActiveEx(true)
end

function XUiSettleWin:OnStart(data, cb, closeCb, onlyTouchBtn)
    self.WinData = data
    self.StageInfos = XDataCenter.FubenManager.GetStageInfo(data.StageId)
    self.StageCfg = XDataCenter.FubenManager.GetStageCfg(data.StageId)
    self.CurrentStageId = data.StageId
    self.CurrAssistInfo = data.ClientAssistInfo
    self.Cb = cb
    self.CloseCb = closeCb
    self.OnlyTouchBtn = onlyTouchBtn
    self.IsFirst = true;
    self.Data = data
    self:InitInfo(data)
    XLuaUiManager.SetMask(true)
    self:PlayRewardAnimation()
    -- "再次挑战"上方显示血清消耗
    self.UiEncorePrice = require("XUi/XUiSettleWin/XUiSettleEncorePrice").New(self, data.StageId)
    ---@type XUiStageSettleSound
    self.UiStageSettleSound = XUiStageSettleSound.New(self, self.CurrentStageId, true)
end

function XUiSettleWin:OnEnable()
    if not self.IsFirst then
        XLuaUiManager.SetMask(true)
        XScheduleManager.ScheduleOnce(function()
            self:PlaySecondAnimation()
        end, 0)
    end
    self.UiStageSettleSound:PlaySettleSound()
end

function XUiSettleWin:OnDestroy()
    XDataCenter.AntiAddictionManager.EndFightAction()
    self.UiStageSettleSound:StopSettleSound()
end

-- 奖励动画
function XUiSettleWin:PlayRewardAnimation()
    local delay = XDataCenter.FubenManager.SettleRewardAnimationDelay
    local interval = XDataCenter.FubenManager.SettleRewardAnimationInterval
    local this = self

    -- 没有奖励则直接播放第二个动画
    if not self.GridRewardList or #self.GridRewardList == 0 then
        XScheduleManager.ScheduleOnce(function()
            this:PlaySecondAnimation()
        end, delay)
        return
    end

    self.RewardAnimationIndex = 1
    XScheduleManager.Schedule(function()
        if XTool.UObjIsNil(self.GridRewardList[this.RewardAnimationIndex].GameObject) then
            return
        end
        if this.RewardAnimationIndex == #self.GridRewardList then
            this:PlayReward(this.RewardAnimationIndex, function()
                this:PlaySecondAnimation()
            end)
        else
            this:PlayReward(this.RewardAnimationIndex)
        end
        this.RewardAnimationIndex = this.RewardAnimationIndex + 1
    end, interval, #self.GridRewardList, delay)
end

function XUiSettleWin:PlaySecondAnimation()
    local this = self
    self:PlayAnimation("AnimEnable2", function()
        XLuaUiManager.SetMask(false)
        -- this:PlayTipMission()
        XDataCenter.FunctionEventManager.UnLockFunctionEvent()
        this:PlayShowFriend()
        self.IsFirst = false;
        XEventManager.DispatchEvent(XEventId.EVENT_CHARACTER_TOWER_CONDITION_LISTENING, XFubenCharacterTowerConfigs.ListeningType.Stage, { StageId = self.StageCfg.StageId })
    end)
end

function XUiSettleWin:PlayShowFriend()
    if not (self.CurrAssistInfo ~= nil and self.CurrAssistInfo.Id ~= 0 and self.CurrAssistInfo.Id ~= XPlayer.Id) then
        if self.Cb then
            self.Cb()
        end
        return
    end

    if XDataCenter.SocialManager.CheckIsApplyed(self.CurrAssistInfo.Id) or XDataCenter.SocialManager.CheckIsFriend(self.CurrAssistInfo.Id) then
        if self.Cb then
            self.Cb()
        end
        return
    end

    self.TxtName.text = self.CurrAssistInfo.Name
    self.TxtLv.text = self.CurrAssistInfo.Level

    XUiPLayerHead.InitPortrait(self.CurrAssistInfo.HeadPortraitId, self.CurrAssistInfo.HeadFrameId, self.Head)

    self.PanelFriend.gameObject:SetActiveEx(true)
    self:PlayAnimation("PanelFriendEnable", self.Cb)
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiSettleWin:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiSettleWin:AutoInitUi()
    self.PanelNorWinInfo = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo")
    self.PanelNor = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor")
    self.PanelBtn = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelBtn")
    self.PanelBtns = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelBtn/PanelBtns")
    self.BtnLeft = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelBtn/PanelBtns/BtnLeft"):GetComponent("Button")
    self.TxtLeft = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelBtn/PanelBtns/BtnLeft/TxtLeft"):GetComponent("Text")
    self.BtnRight = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelBtn/PanelBtns/BtnRight"):GetComponent("Button")
    self.TxtRight = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelBtn/PanelBtns/BtnRight/TxtRight"):GetComponent("Text")
    self.PanelTouch = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelBtn/PanelTouch")
    self.BtnBlock = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelBtn/PanelTouch/BtnBlock"):GetComponent("Button")
    self.TxtLeftA = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelBtn/PanelTouch/BtnBlock/TxtLeft"):GetComponent("Text")
    self.PanelLeft = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelLeft")
    self.PanelRoleContent = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelLeft/Team/PanelRoleContent")
    self.GridWinRole = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelLeft/Team/PanelRoleContent/GridWinRole")
    self.PanelRight = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelRight")
    self.TxtChapterName = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelRight/StageInfo/TxtChapterName"):GetComponent("Text")
    self.TxtStageName = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelRight/StageInfo/TxtStageName"):GetComponent("Text")
    self.PanelRewardContent = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelRight/RewardList/Viewport/PanelRewardContent")
    self.GridReward = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelRight/RewardList/Viewport/PanelRewardContent/GridReward")
    self.PanelFriend = self.Transform:Find("SafeAreaContentPane/PanelFriend")
    self.PanelInf = self.Transform:Find("SafeAreaContentPane/PanelFriend/PanelInf")
    self.TxtName = self.Transform:Find("SafeAreaContentPane/PanelFriend/PanelInf/TxtName"):GetComponent("Text")
    self.TxtLv = self.Transform:Find("SafeAreaContentPane/PanelFriend/PanelInf/TxtLv"):GetComponent("Text")
    self.BtnFriClose = self.Transform:Find("SafeAreaContentPane/PanelFriend/BtnFriClose"):GetComponent("Button")
    self.BtnFriAdd = self.Transform:Find("SafeAreaContentPane/PanelFriend/BtnFriAdd"):GetComponent("Button")
    self.PanelPlayerExpBar = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelLeft/PlayerExp/PanelPlayerExpBar")
    self.TxtDamage = self.PanelLivRealistic:Find("Text/RImgDamage/Text"):GetComponent("Text")
    self.TxtLife = self.PanelLivRealistic:Find("Text/RimgLife/Text"):GetComponent("Text")
    self.TxtPassTime = self.PanelLivRealistic:Find("TxtTime"):GetComponent("Text")
    self.TxtBossInfo = self.PanelLivRealistic:Find("Text"):GetComponent("Text")
end

function XUiSettleWin:AutoAddListener()
    self:RegisterClickEvent(self.BtnLeft, self.OnBtnLeftClick)
    self:RegisterClickEvent(self.BtnRight, self.OnBtnRightClick)
    self:RegisterClickEvent(self.BtnBlock, self.OnBtnBlockClick)
    self:RegisterClickEvent(self.BtnFriClose, self.OnBtnFriCloseClick)
    self:RegisterClickEvent(self.BtnFriAdd, self.OnBtnFriAddClick)
end
-- auto
function XUiSettleWin:OnBtnLeftClick()
    self:SetBtnByType(self.StageCfg.FunctionLeftBtn)
end

function XUiSettleWin:OnBtnFriCloseClick()
    self:PlayAnimation("PanelFriendDisable")
    self.PanelFriend.gameObject:SetActiveEx(false)
end

function XUiSettleWin:OnBtnFriAddClick()
    if not self.CurrAssistInfo then
        return
    end

    XDataCenter.SocialManager.ApplyFriend(self.CurrAssistInfo.Id)

    self.CurrAssistInfo = nil
    self:PlayAnimation("PanelFriendDisable")
    self.PanelFriend.gameObject:SetActiveEx(false)
end

function XUiSettleWin:InitInfo(data)
    self.PanelFriend.gameObject:SetActiveEx(false)
    XTipManager.Execute()

    self:SetBtnsInfo(data)
    self:SetStageInfo(data)
    self:UpdatePlayerInfo(data)
    self:InitRewardCharacterList(data)
    self:InitRewardList(data.RewardGoodsList)
    XTipManager.Add(function()
        if data.UrgentId > 0 then
            XLuaUiManager.Open("UiSettleUrgentEvent", data.UrgentId)
        end
    end)
end

function XUiSettleWin:SetBtnsInfo(data)
    local stageData = XDataCenter.FubenManager.GetStageData(data.StageId)

    local passTimes = stageData and stageData.PassTimesToday or 0
    if (self.StageCfg.HaveFirstPass and passTimes < 2) or self.OnlyTouchBtn then
        self.PanelTouch.gameObject:SetActiveEx(true)
        self.PanelBtns.gameObject:SetActiveEx(false)
    else
        local leftType = self.StageCfg.FunctionLeftBtn
        local rightType = self.StageCfg.FunctionRightBtn

        self.BtnLeft.gameObject:SetActiveEx(leftType > 0)
        self.BtnRight.gameObject:SetActiveEx(rightType > 0)
        self.TxtLeft.text = XRoomSingleManager.GetBtnText(leftType)
        self.TxtRight.text = XRoomSingleManager.GetBtnText(rightType)

        self.PanelTouch.gameObject:SetActiveEx(false)
        self.PanelBtns.gameObject:SetActiveEx(true)
    end
end

function XUiSettleWin:SetStageInfo(data)
    local chapterName, stageName = XDataCenter.FubenManager.GetFubenNames(data.StageId)
    self.TxtChapterName.text = chapterName
    self.TxtStageName.text = stageName
    --拟真Boss玩法需要特殊显示
    if self.StageInfos.Type == XDataCenter.FubenManager.StageType.PracticeBoss and self.WinData.SettleData then
        local simulateTrainFightResult = self.WinData.SettleData.SimulateTrainFightResult
        self.PanelLivRealistic.gameObject:SetActiveEx(true)
        self.TxtDamage.text = simulateTrainFightResult.AtkLevel
        self.TxtLife.text = simulateTrainFightResult.HpLevel
        self.TxtPassTime.text = XUiHelper.GetTime(math.floor(simulateTrainFightResult.FightTime))

        local difficulty = simulateTrainFightResult.Difficulty
        local stageId = data.StageId
        local npcIdList = XPracticeConfigs.GetSimulateTrainNpcIdIdByStageId(stageId)
        local npcId = npcIdList[difficulty]
        if XTool.IsNumberValid(npcId) then
            local bossData = XDataCenter.ArchiveManager.GetArchiveMonsterEntityByNpcId(npcId)
            local name = bossData and bossData:GetName() or ""
            self.TxtBossInfo.text = CSTextManagerGetText("PracticeBossSettle", XPracticeConfigs.GetSimulateTrainMonsterStageNameByStageId(stageId, difficulty), name)
        else
            self.TxtBossInfo.text = ""
        end
    end
end

-- 角色奖励列表
function XUiSettleWin:InitRewardCharacterList(data)
    if self.StageInfos.Type == XDataCenter.FubenManager.StageType.RogueLike then
        local robotInfos = XDataCenter.FubenRogueLikeManager.GetRogueLikeStageRobots(self.StageCfg.StageId)
        if robotInfos.IsAssis then
            for i = 1, #robotInfos.RobotId do
                local id = robotInfos.RobotId[i]
                if id > 0 then
                    local ui = CS.UnityEngine.Object.Instantiate(self.GridWinRole)
                    local grid = XUiGridWinRole.New(self, ui)
                    grid.Transform:SetParent(self.PanelRoleContent, false)
                    grid:UpdateRobotInfo(id)
                    grid.GameObject:SetActiveEx(true)
                end
            end

            return
        end
    end

    -- 巨麻烦的处理，仅狙击战有效
    if self.StageInfos.Type == XDataCenter.FubenManager.StageType.UnionKill then
        if self.WinData.SettleData then
            local teamCache = XDataCenter.FubenUnionKillManager.GetCacheTeam()
            for _, teamItem in pairs(teamCache or {}) do
                if teamItem.CharacterId and teamItem.CharacterId > 0 then
                    local ui = CS.UnityEngine.Object.Instantiate(self.GridWinRole)
                    local grid = XUiGridWinRole.New(self, ui)
                    grid.Transform:SetParent(self.PanelRoleContent, false)
                    grid.GameObject:SetActiveEx(true)

                    if teamItem.IsShare then
                        grid:UpdateShareRoleInfo(teamItem.Character, 0)
                    else
                        local character = XDataCenter.CharacterManager.GetCharacter(teamItem.CharacterId)
                        for _, charExpRecord in pairs(data.CharExp or {}) do
                            if charExpRecord.Id == teamItem.CharacterId then
                                character = charExpRecord
                                break
                            end
                        end
                        local cardExp = XDataCenter.FubenManager.GetCardExp(self.CurrentStageId)
                        grid:UpdateRoleInfo(character, cardExp)
                    end
                end
            end
        end

        return
    end

    -- 尼尔玩法特殊处理
    if self.StageInfos.Type == XDataCenter.FubenManager.StageType.NieR and (not self.StageCfg.RobotId or #self.StageCfg.RobotId <= 0) then
        if self.WinData.SettleData then
            local teamCache = XDataCenter.NieRManager.GetPlayerTeamData(self.StageCfg.StageId)
            local teamData = teamCache and teamCache.TeamData or {}
            for _, robotId in ipairs(teamData) do
                if robotId > 0 then
                    local ui = CS.UnityEngine.Object.Instantiate(self.GridWinRole)
                    local grid = XUiGridWinRole.New(self, ui)
                    grid.Transform:SetParent(self.PanelRoleContent, false)
                    grid:UpdateNieRRobotInfo(robotId)
                    grid.GameObject:SetActiveEx(true)
                end
            end
        end

        return
    end
    
    -- 音游玩法特殊处理
    if self.StageInfos.Type == XEnumConst.FuBen.StageType.TaikoMaster then
        if self.WinData.SettleData then
            local teamData = XMVCA.XTaikoMaster:GetTeam():GetEntityIds()
            for _, robotId in ipairs(teamData) do
                if robotId > 0 then
                    local ui = CS.UnityEngine.Object.Instantiate(self.GridWinRole)
                    ---@type XUiGridSettleWinRole
                    local grid = XUiGridWinRole.New(self, ui)
                    grid.Transform:SetParent(self.PanelRoleContent, false)
                    grid:UpdateTaikoRoleInfo(robotId)
                    grid.GameObject:SetActiveEx(true)
                end
            end
        end
        return
    end

    --口袋妖怪
    if self.StageInfos.Type == XDataCenter.FubenManager.StageType.Pokemon then
        self.PanelLeft.gameObject:SetActiveEx(false)

        self.PokemonPanel = self.PokemonPanel or XUiPanelSettleWinPokemon.New(self.PanelPokemon)
        self.PokemonPanel:Refresh(data)
        self.PokemonPanel.GameObject:SetActiveEx(true)

        return
    end

    if self.StageCfg.RobotId and #self.StageCfg.RobotId > 0 then
        for i = 1, #self.StageCfg.RobotId do
            if self.StageCfg.RobotId[i] > 0 then
                local ui = CS.UnityEngine.Object.Instantiate(self.GridWinRole)
                local grid = XUiGridWinRole.New(self, ui)
                grid.Transform:SetParent(self.PanelRoleContent, false)
                grid:UpdateRobotInfo(self.StageCfg.RobotId[i])
                grid.GameObject:SetActiveEx(true)
            end
        end
    else
        local charExp = data.CharExp
        local count = #charExp
        if count <= 0 then
            return
        end

        for i = 1, count do
            local ui = CS.UnityEngine.Object.Instantiate(self.GridWinRole)
            local grid = XUiGridWinRole.New(self, ui)
            local charId = charExp[i].Id
            local isRobot = XRobotManager.CheckIsRobotId(charId)

            grid.Transform:SetParent(self.PanelRoleContent, false)
            if isRobot then
                grid:UpdateRobotInfo(charId)
            else
                local cardExp = XDataCenter.FubenManager.GetCardExp(self.CurrentStageId)
                grid:UpdateRoleInfo(charExp[i], cardExp)
            end
            grid.GameObject:SetActiveEx(true)
        end
    end

end

-- 玩家经验
function XUiSettleWin:UpdatePlayerInfo(data)
    if not data or not next(data) then return end

    local lastLevel = data.RoleLevel
    local lastExp = data.RoleExp
    local lastMaxExp = XPlayerManager.GetMaxExp(lastLevel, XPlayer.IsHonorLevelOpen())
    local curLevel = XPlayer.GetLevelOrHonorLevel()
    local curExp = XPlayer.Exp
    local curMaxExp = XPlayerManager.GetMaxExp(curLevel, XPlayer.IsHonorLevelOpen())
    local txtLevelName = XPlayer.IsHonorLevelOpen() and CS.XTextManager.GetText("HonorLevel") or nil
    local addExp = XDataCenter.FubenManager.GetTeamExp(self.CurrentStageId)
    self.PlayerExpBar = self.PlayerExpBar or XUiPanelExpBar.New(self.PanelPlayerExpBar)
    self.PlayerExpBar:LetsRoll(lastLevel, lastExp, lastMaxExp, curLevel, curExp, curMaxExp, addExp, txtLevelName)
end

-- 物品奖励列表
function XUiSettleWin:InitRewardList(rewardGoodsList)
    rewardGoodsList = rewardGoodsList or {}
    self.GridRewardList = {}
    local rewards = XRewardManager.FilterRewardGoodsList(rewardGoodsList)
    rewards = XRewardManager.MergeAndSortRewardGoodsList(rewards)
    for _, item in ipairs(rewards) do
        local ui = CS.UnityEngine.Object.Instantiate(self.GridReward)
        local grid = XUiGridCommon.New(self, ui)
        grid.Transform:SetParent(self.PanelRewardContent, false)
        grid:Refresh(item, nil, nil, true)
        grid.GameObject:SetActiveEx(false)
        table.insert(self.GridRewardList, grid)
    end
end

function XUiSettleWin:OnBtnRightClick()
    self:SetBtnByType(self.StageCfg.FunctionRightBtn)
end

function XUiSettleWin:SetBtnByType(btnType)
    --CS.XAudioManager.RemoveCueSheet(CS.XAudioManager.BATTLE_MUSIC_CUE_SHEET_ID)
    --CS.XAudioManager.PlayMusic(CS.XAudioManager.MAIN_BGM)
    if btnType == XRoomSingleManager.BtnType.SelectStage then
        self:OnBtnBackClick(false)
    elseif btnType == XRoomSingleManager.BtnType.Again then
        -- 音游需要进入自己的战斗房间
        if self.StageInfos.Type == XEnumConst.FuBen.StageType.TaikoMaster then
            ---@type XTaikoMasterAgency
            local agency = XMVCA:GetAgency(ModuleId.XTaikoMaster)
            agency:OpenBattleRoom(self.CurrentStageId)
            return
        end
        XLuaUiManager.PopThenOpen("UiBattleRoleRoom", self.StageCfg.StageId, nil, nil, nil, true)
    elseif btnType == XRoomSingleManager.BtnType.Next then
        self:OnBtnEnterNextClick()
    elseif btnType == XRoomSingleManager.BtnType.Main then
        self:OnBtnBackClick(true)
    end
end

function XUiSettleWin:OnBtnEnterNextClick()
    if self.StageInfos.Type == XDataCenter.FubenManager.StageType.Tower then
        local stageId = XDataCenter.TowerManager.GetTowerData().CurrentStageId
        if XDataCenter.TowerManager.CheckStageCanEnter(stageId) then
            XLuaUiManager.PopThenOpen("UiBattleRoleRoom", stageId, nil, nil, nil, true)
        else
            local text = CS.XTextManager.GetText("TowerCannotEnter")
            XUiManager.TipMsg(text, XUiManager.UiTipType.Tip)
        end
    else
        if self.StageInfos.NextStageId then
            local nextStageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageInfos.NextStageId)
            self:HidePanel()
            XDataCenter.FubenManager.OpenRoomSingle(nextStageCfg)
        else
            local text = CS.XTextManager.GetText("BattleWinMainCannotEnter")
            XUiManager.TipMsg(text, XUiManager.UiTipType.Tip)
        end
    end
end

function XUiSettleWin:OnBtnBackClick(isRunMain)
    if self.StageInfos.Type == XDataCenter.FubenManager.StageType.Tower then
        if XDataCenter.TowerManager.GetChapterLastMapId(self.CurrentStageId) == self.CurrentStageId then
            XDataCenter.TowerManager.GetTowerChapterReward(function()
                if isRunMain then
                    XLuaUiManager.RunMain()
                else
                    self:HidePanel()
                end
            end, self.CurrentStageId)
        else
            if isRunMain then
                XLuaUiManager.RunMain()
            else
                self:HidePanel()
            end
        end
    elseif self.StageInfos.Type == XDataCenter.FubenManager.StageType.BossSingle then
        if isRunMain then
            XLuaUiManager.RunMain()
        else
            self:HidePanel()
        end
    elseif self.StageInfos.Type == XDataCenter.FubenManager.StageType.Urgent then
        if isRunMain then
            XLuaUiManager.RunMain()
        else
            -- 跳转到挑战界面
            XLuaUiManager.RunMain()
            XFunctionManager.SkipInterface(600)
        end
    else
        if isRunMain then
            XLuaUiManager.RunMain()
        else
            self:HidePanel()
        end
    end
end

function XUiSettleWin:OnBtnBlockClick()
    if self.StageCfg.FirstGotoSkipId > 0 then
        XFunctionManager.SkipInterface(self.StageCfg.FirstGotoSkipId)
        self:Remove()
    else
        self:HidePanel()
    end

    if self.CloseCb then
        self:CloseCb()
    end
end

function XUiSettleWin:HidePanel()
    self:Close()
end

function XUiSettleWin:PlayReward(index, cb)
    self.GridRewardList[index].GameObject:SetActiveEx(true)
    self:PlayAnimation("GridReward", cb)
end