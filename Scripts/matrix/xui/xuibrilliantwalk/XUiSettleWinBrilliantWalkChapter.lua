local XUiPanelExpBar = require("XUi/XUiSettleWinMainLine/XUiPanelExpBar")
local XUiSettleEncorePrice = require("XUi/XUiSettleWin/XUiSettleEncorePrice")
local XUiSettleWinBrilliantWalkChapter = XLuaUiManager.Register(XLuaUi, "UiSettleWinBrilliantWalkChapter")
local CSTextManagerGetText = CS.XTextManager.GetText
local StarKnightName = CSTextManagerGetText("BrilliantWalkResultWords")
local StarKnightIcon = CS.XGame.ClientConfig:GetString("BrilliantWalkResultIcon")
local BrilliantWalkEnergyItem = CS.XGame.ClientConfig:GetInt("BrilliantWalkEnergyItem")

--光辉同行普通关卡胜利结算画面，复用通用胜利结算的UI和代码，再进行小修改。
--=========== 初始化Begin ==========
function XUiSettleWinBrilliantWalkChapter:OnAwake()
    self:InitAutoScript()

    self.GridReward.gameObject:SetActiveEx(false)
    self.PanelPokemon.gameObject:SetActiveEx(false)
    self.PanelLivRealistic.gameObject:SetActiveEx(false)
    self.PanelLeft.gameObject:SetActiveEx(true)
end
-- auto
-- Automatic generation of code, forbid to edit
function XUiSettleWinBrilliantWalkChapter:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end
function XUiSettleWinBrilliantWalkChapter:AutoInitUi()
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
    --机器人头像
    local tempGrid = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelLeft/Team/PanelRoleContent/GridWinRole")
    self.GridWinRole = {}
    self.GridWinRole.GameObject = tempGrid.gameObject
    self.GridWinRole.Transform = tempGrid
    XTool.InitUiObject(self.GridWinRole)
    self.GridWinRole.PanelPlayerExpBar.gameObject:SetActiveEx(false)
    self.GridWinRole.PanelBrilliantWalk.gameObject:SetActiveEx(true)
    self.GridWinRole.TextStarKnightName = self.GridWinRole.PanelBrilliantWalk:Find("BrilliantwalkText"):GetComponent("Text")
end
function XUiSettleWinBrilliantWalkChapter:AutoAddListener()
    self:RegisterClickEvent(self.BtnLeft, self.OnBtnLeftClick)
    self:RegisterClickEvent(self.BtnRight, self.OnBtnRightClick)
    self:RegisterClickEvent(self.BtnBlock, self.OnBtnBlockClick)
    self:RegisterClickEvent(self.BtnFriClose, self.OnBtnFriCloseClick)
    self:RegisterClickEvent(self.BtnFriAdd, self.OnBtnFriAddClick)
end
--=========== 初始化End ==========

function XUiSettleWinBrilliantWalkChapter:OnStart(data, cb, closeCb, onlyTouchBtn)
    self.WinData = data
    self.SettleData = self.WinData.SettleData.BrilliantWalkResult
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
    self.UiEncorePrice = XUiSettleEncorePrice.New(self, data.StageId)
end

function XUiSettleWinBrilliantWalkChapter:OnEnable()
    if not self.IsFirst then
        XLuaUiManager.SetMask(true)
        XScheduleManager.ScheduleOnce(function()
            self:PlaySecondAnimation()
        end, 0)
    end
end

function XUiSettleWinBrilliantWalkChapter:OnDestroy()
    XDataCenter.AntiAddictionManager.EndFightAction()
end

-- 奖励动画
function XUiSettleWinBrilliantWalkChapter:PlayRewardAnimation()
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

function XUiSettleWinBrilliantWalkChapter:PlaySecondAnimation()
    local this = self
    self:PlayAnimation("AnimEnable2", function()
        XLuaUiManager.SetMask(false)
        -- this:PlayTipMission()
        XDataCenter.FunctionEventManager.UnLockFunctionEvent()
        this:PlayShowFriend()
        self.IsFirst = false;
    end)
end

function XUiSettleWinBrilliantWalkChapter:PlayShowFriend()
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
function XUiSettleWinBrilliantWalkChapter:OnBtnLeftClick()
    self:SetBtnByType(self.StageCfg.FunctionLeftBtn)
end

function XUiSettleWinBrilliantWalkChapter:OnBtnFriCloseClick()
    self:PlayAnimation("PanelFriendDisable")
    self.PanelFriend.gameObject:SetActiveEx(false)
end

function XUiSettleWinBrilliantWalkChapter:OnBtnFriAddClick()
    if not self.CurrAssistInfo then
        return
    end

    XDataCenter.SocialManager.ApplyFriend(self.CurrAssistInfo.Id)

    self.CurrAssistInfo = nil
    self:PlayAnimation("PanelFriendDisable")
    self.PanelFriend.gameObject:SetActiveEx(false)
end

function XUiSettleWinBrilliantWalkChapter:InitInfo(data)
    self.PanelFriend.gameObject:SetActiveEx(false)
    XTipManager.Execute()
    self:SetBtnsInfo(data)
    self:SetStageInfo(data)
    self:UpdatePlayerInfo(data)
    self:InitRewardCharacterList(data)
    self:InitRewardList()
    XTipManager.Add(function()
        if data.UrgentId > 0 then
            XLuaUiManager.Open("UiSettleUrgentEvent", data.UrgentId)
        end
    end)
end

function XUiSettleWinBrilliantWalkChapter:SetBtnsInfo(data)
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

function XUiSettleWinBrilliantWalkChapter:SetStageInfo(data)
    local chapterName, stageName = XDataCenter.FubenManager.GetFubenNames(data.StageId)
    self.TxtChapterName.text = chapterName
    self.TxtStageName.text = stageName
end

-- 角色奖励列表
function XUiSettleWinBrilliantWalkChapter:InitRewardCharacterList()
    self.GridWinRole.RImgIcon:SetRawImage(StarKnightIcon)
    self.GridWinRole.TextStarKnightName.text = StarKnightName
    
end

-- 玩家经验
function XUiSettleWinBrilliantWalkChapter:UpdatePlayerInfo(data)
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

-- 物品奖励列表(重写 插件和能量并非真实道具 后端也不派发数据)
function XUiSettleWinBrilliantWalkChapter:InitRewardList()
    local GetGrid = function()
        local ui = CS.UnityEngine.Object.Instantiate(self.GridReward)
        local grid = XUiGridCommon.New(self, ui)
        grid.Transform:SetParent(self.PanelRewardContent, false)
        return grid
    end
    local FirstClean = self.SettleData.IsNewRecord
    if FirstClean then
        local UiData = XDataCenter.BrilliantWalkManager.GetUiDataStageDetail(self.SettleData.StageId)
        self.GridRewardList = {}
        --解锁能量
        if UiData.UnlockEnergy > 0 then
            local grid = GetGrid()
            grid:Refresh({
                TemplateId = BrilliantWalkEnergyItem,
                TipNotShowCount = true,
            })
            grid.GameObject:SetActiveEx(false)
            grid:SetUiActive(grid.ImgQuality, false)
            grid:SetUiActive(grid.TxtCount, true)
            grid.TxtCount.text = XDataCenter.ItemManager.GetItemName(BrilliantWalkEnergyItem)
            table.insert(self.GridRewardList, grid)
        end    
        --解锁插件
        if #UiData.UnlockPlugin > 0 then
            for index,plugInId in pairs(UiData.UnlockPlugin) do
                local grid = GetGrid()
                local itemId = XBrilliantWalkConfigs.GetBuildPluginItemId(plugInId)
                grid:Refresh({
                    TemplateId = itemId,
                    TipNotShowCount = true,
                    TipShowBlackBg = true,
                })
                grid.GameObject:SetActiveEx(false)
                grid:SetUiActive(grid.ImgQuality, false)
                grid:SetUiActive(grid.TxtCount, true)
                grid.TxtCount.text = XDataCenter.ItemManager.GetItemName(itemId)
                table.insert(self.GridRewardList, grid)
            end
        end
    end
end

function XUiSettleWinBrilliantWalkChapter:OnBtnRightClick()
    self:SetBtnByType(self.StageCfg.FunctionRightBtn)
end

function XUiSettleWinBrilliantWalkChapter:SetBtnByType(btnType)
    --CS.XAudioManager.RemoveCueSheet(CS.XAudioManager.BATTLE_MUSIC_CUE_SHEET_ID)
    --CS.XAudioManager.PlayMusic(CS.XAudioManager.MAIN_BGM)
    if btnType == XRoomSingleManager.BtnType.SelectStage then
        self:OnBtnBackClick(false)
    elseif btnType == XRoomSingleManager.BtnType.Again then
        XLuaUiManager.PopThenOpen("UiBattleRoleRoom", self.StageCfg.StageId, nil, nil, nil, true)
    elseif btnType == XRoomSingleManager.BtnType.Next then
        self:OnBtnEnterNextClick()
    elseif btnType == XRoomSingleManager.BtnType.Main then
        self:OnBtnBackClick(true)
    end
end

function XUiSettleWinBrilliantWalkChapter:OnBtnEnterNextClick()
    if self.StageInfos.NextStageId then
        local nextStageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageInfos.NextStageId)
        self:HidePanel()
        XDataCenter.FubenManager.OpenRoomSingle(nextStageCfg)
    else
        local text = CS.XTextManager.GetText("BattleWinMainCannotEnter")
        XUiManager.TipMsg(text, XUiManager.UiTipType.Tip)
    end
end

function XUiSettleWinBrilliantWalkChapter:OnBtnBackClick(isRunMain)
    if isRunMain then
        XLuaUiManager.RunMain()
    else
        self:HidePanel()
    end
end

function XUiSettleWinBrilliantWalkChapter:OnBtnBlockClick()
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

function XUiSettleWinBrilliantWalkChapter:HidePanel()
    self:Close()
end

function XUiSettleWinBrilliantWalkChapter:PlayReward(index, cb)
    self.GridRewardList[index].GameObject:SetActiveEx(true)
    self:PlayAnimation("GridReward", cb)
end