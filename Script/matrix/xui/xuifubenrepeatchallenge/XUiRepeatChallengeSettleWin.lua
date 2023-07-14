local XUiPanelExpBar = require("XUi/XUiSettleWinMainLine/XUiPanelExpBar")
local XUiGridRewardLine = require("XUi/XUiFubenRepeatchallenge/XUiGridRewardLine")

local CsXTextManagerGetText = CS.XTextManager.GetText

local XUiRepeatChallengeSettleWin = XLuaUiManager.Register(XLuaUi, "UiRepeatChallengeSettleWin")

function XUiRepeatChallengeSettleWin:OnAwake()
    self:InitAutoScript()
    self:InitDynamicTable()
end

function XUiRepeatChallengeSettleWin:OnStart(data, addLevelTip)
    self.WinData = data
    self.StageInfos = XDataCenter.FubenManager.GetStageInfo(data.StageId)
    self.StageCfg = XDataCenter.FubenManager.GetStageCfg(data.StageId)
    self.CurrentStageId = data.StageId
    self.CurrAssistInfo = data.ClientAssistInfo
    self.WinCount = data.SettleData.ChallengeCount or 1
    self:InitInfo(data)
    XDataCenter.FunctionEventManager.UnLockFunctionEvent()

    if addLevelTip then
        XUiManager.TipMsg(CsXTextManagerGetText("ActivityRepeatChallengeAddExpTip", addLevelTip))
        XDataCenter.FubenRepeatChallengeManager.ClearAddLevelTip()
    end
    -- "再次挑战"上方显示血清消耗
    self.UiEncorePrice = require("XUi/XUiSettleWin/XUiSettleEncorePrice").New(self, data.StageId)
end

function XUiRepeatChallengeSettleWin:OnDestroy()
    XDataCenter.AntiAddictionManager.EndFightAction()
end

function XUiRepeatChallengeSettleWin:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelRewards)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridRewardLine)
    self.GridRewardLine.gameObject:SetActiveEx(false)
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiRepeatChallengeSettleWin:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiRepeatChallengeSettleWin:AutoInitUi()
    self.PanelBtns = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelBtn/PanelBtns")
    self.BtnLeft = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelBtn/PanelBtns/BtnLeft"):GetComponent("Button")
    self.TxtLeft = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelBtn/PanelBtns/BtnLeft/TxtLeft"):GetComponent("Text")
    self.BtnRight = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelBtn/PanelBtns/BtnRight"):GetComponent("Button")
    self.TxtRight = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelBtn/PanelBtns/BtnRight/TxtRight"):GetComponent("Text")
    self.PanelTouch = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelBtn/PanelTouch")
    self.BtnBlock = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelBtn/PanelTouch/BtnBlock"):GetComponent("Button")
    self.PanelRight = self.Transform:Find("SafeAreaContentPane/PanelNorWinInfo/PanelNor/PanelRight")
    self.PanelFriend = self.Transform:Find("SafeAreaContentPane/PanelFriend")
    self.PanelInf = self.Transform:Find("SafeAreaContentPane/PanelFriend/PanelInf")
    self.PanelHead = self.Transform:Find("SafeAreaContentPane/PanelFriend/PanelInf/PanelHead")
    self.ImgHead = self.Transform:Find("SafeAreaContentPane/PanelFriend/PanelInf/PanelHead/ImgHead"):GetComponent("Image")
    self.TxtName = self.Transform:Find("SafeAreaContentPane/PanelFriend/PanelInf/TxtName"):GetComponent("Text")
    self.TxtLv = self.Transform:Find("SafeAreaContentPane/PanelFriend/PanelInf/TxtLv"):GetComponent("Text")
    self.BtnFriClose = self.Transform:Find("SafeAreaContentPane/PanelFriend/BtnFriClose"):GetComponent("Button")
    self.BtnFriAdd = self.Transform:Find("SafeAreaContentPane/PanelFriend/BtnFriAdd"):GetComponent("Button")
end

function XUiRepeatChallengeSettleWin:AutoAddListener()
    self:RegisterClickEvent(self.BtnLeft, self.OnBtnLeftClick)
    self:RegisterClickEvent(self.BtnRight, self.OnBtnRightClick)
    self:RegisterClickEvent(self.BtnBlock, self.OnBtnBlockClick)
    self:RegisterClickEvent(self.BtnFriClose, self.OnBtnFriCloseClick)
    self:RegisterClickEvent(self.BtnFriAdd, self.OnBtnFriAddClick)
end
-- auto
function XUiRepeatChallengeSettleWin:OnBtnLeftClick()
    self:SetBtnByType(self.StageCfg.FunctionLeftBtn)
end

function XUiRepeatChallengeSettleWin:OnBtnFriCloseClick()
    self.PanelFriend.gameObject:SetActive(false)
end

function XUiRepeatChallengeSettleWin:OnBtnFriAddClick()
    if not self.CurrAssistInfo then
        return
    end

    XDataCenter.SocialManager.ApplyFriend(self.CurrAssistInfo.Id)

    self.CurrAssistInfo = nil
    self.PanelFriend.gameObject:SetActive(false)
end

function XUiRepeatChallengeSettleWin:InitInfo(data)
    self.PanelFriend.gameObject:SetActive(false)
    XTipManager.Execute()

    self:SetBtnsInfo(data)
    self:SetStageInfo(data)
    self:UpdatePlayerInfo(data)
    self:InitRewardCharacterList(data)
    self:UpdateDynamicTable(data.SettleData.MultiRewardGoodsList)

    XTipManager.Add(function()
        if data.UrgentId > 0 then
            XLuaUiManager.Open("UiSettleUrgentEvent", data.UrgentId)
        end
    end)
end

function XUiRepeatChallengeSettleWin:SetBtnsInfo(data)
    local stageData = XDataCenter.FubenManager.GetStageData(data.StageId)

    if self.StageCfg.HaveFirstPass and stageData and stageData.PassTimesToday < 2 then
        self.PanelTouch.gameObject:SetActive(true)
        self.PanelBtns.gameObject:SetActive(false)
    else
        local leftType = self.StageCfg.FunctionLeftBtn
        local rightType = self.StageCfg.FunctionRightBtn

        self.BtnLeft.gameObject:SetActive(leftType > 0)
        self.BtnRight.gameObject:SetActive(rightType > 0)
        self.TxtLeft.text = XRoomSingleManager.GetBtnText(leftType)
        self.TxtRight.text = XRoomSingleManager.GetBtnText(rightType)

        self.PanelTouch.gameObject:SetActive(false)
        self.PanelBtns.gameObject:SetActive(true)
    end
end

function XUiRepeatChallengeSettleWin:SetStageInfo(data)
    local _, stageName = XDataCenter.FubenManager.GetFubenNames(data.StageId)
    self.TxtStageName.text = stageName
end

-- 角色奖励列表
function XUiRepeatChallengeSettleWin:InitRewardCharacterList(data)
    self.GridWinRole.gameObject:SetActive(false)
    if self.StageCfg.RobotId and #self.StageCfg.RobotId > 0 then
        for i = 1, #self.StageCfg.RobotId do
            if self.StageCfg.RobotId[i] > 0 then
                local ui = CS.UnityEngine.Object.Instantiate(self.GridWinRole)
                local grid = XUiGridWinRole.New(self, ui)
                grid.Transform:SetParent(self.PanelRoleContent, false)
                grid:UpdateRobotInfo(self.StageCfg.RobotId[i])
                grid.GameObject:SetActive(true)
            end
        end
    else
        local charExp = data.CharExp
        local count = #charExp
        if count <= 0 then
            return
        end

        -- 原先机制只加一次经验，而且读的本地表，多重挑战需要乘以次数
        local winCount = self.WinCount
        for i = 1, count do
            local ui = CS.UnityEngine.Object.Instantiate(self.GridWinRole)
            local grid = XUiGridWinRole.New(self, ui)
            grid.Transform:SetParent(self.PanelRoleContent, false)
            local cardExp = XDataCenter.FubenManager.GetCardExp(self.CurrentStageId)
            grid:UpdateRoleInfo(charExp[i], cardExp * winCount)
            grid.GameObject:SetActive(true)
        end
    end
end

-- 玩家经验
function XUiRepeatChallengeSettleWin:UpdatePlayerInfo(data)
    if not data or not next(data) then return end

    local lastLevel = data.RoleLevel
    local lastExp = data.RoleExp
    local lastMaxExp = XPlayerManager.GetMaxExp(lastLevel, XPlayer.IsHonorLevelOpen())
    local curLevel = XPlayer.GetLevelOrHonorLevel()
    local curExp = XPlayer.Exp
    local curMaxExp = XPlayerManager.GetMaxExp(curLevel, XPlayer.IsHonorLevelOpen())
    local txtLevelName = XPlayer.IsHonorLevelOpen() and CS.XTextManager.GetText("HonorLevel") or nil


    -- 原先机制只加一次经验，而且读的本地表，多重挑战需要乘以次数
    local winCount = self.WinCount
    local teamExp = XDataCenter.FubenManager.GetTeamExp(self.CurrentStageId)
    local addExp = teamExp * winCount
    self.PlayerExpBar = self.PlayerExpBar or XUiPanelExpBar.New(self.PanelPlayerExpBar)
    self.PlayerExpBar:LetsRoll(lastLevel, lastExp, lastMaxExp, curLevel, curExp, curMaxExp, addExp, txtLevelName)
end

function XUiRepeatChallengeSettleWin:UpdateDynamicTable(rewardLineList)
    self.RewardLineList = rewardLineList
    self.DynamicTable:SetDataSource(self.RewardLineList)
    self.DynamicTable:ReloadDataSync(-1)
end

function XUiRepeatChallengeSettleWin:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:InitRootUi(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local rewardGoodsList = self.RewardLineList[index]
        grid:Refresh(rewardGoodsList, index)
    end
end

function XUiRepeatChallengeSettleWin:OnBtnRightClick()
    self:SetBtnByType(self.StageCfg.FunctionRightBtn)
end

function XUiRepeatChallengeSettleWin:SetBtnByType(btnType)
    if btnType == XRoomSingleManager.BtnType.SelectStage then
        self:OnBtnBackClick(false)
    elseif btnType == XRoomSingleManager.BtnType.Again then
        -- 多重挑战需要传递上次挑战的次数
        local data = { ChallengeCount = XDataCenter.FubenManager.GetFightChallengeCount() }
        -- XLuaUiManager.PopThenOpen("UiNewRoomSingle", self.StageCfg.StageId, data)
        XLuaUiManager.PopThenOpen("UiBattleRoleRoom", self.StageCfg.StageId, nil, nil, nil, true)
    elseif btnType == XRoomSingleManager.BtnType.Next then
        self:OnBtnEnterNextClick()
    elseif btnType == XRoomSingleManager.BtnType.Main then
        self:OnBtnBackClick(true)
    end
end

function XUiRepeatChallengeSettleWin:OnBtnEnterNextClick()
    if self.StageInfos.Type == XDataCenter.FubenManager.StageType.Tower then
        local stageId = XDataCenter.TowerManager.GetTowerData().CurrentStageId
        if XDataCenter.TowerManager.CheckStageCanEnter(stageId) then
            XLuaUiManager.PopThenOpen("UiNewRoomSingle", stageId)
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

function XUiRepeatChallengeSettleWin:OnBtnBackClick(isRunMain)
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

function XUiRepeatChallengeSettleWin:OnBtnBlockClick()
    if self.StageCfg.FirstGotoSkipId > 0 then
        XFunctionManager.SkipInterface(self.StageCfg.FirstGotoSkipId)
        self:Remove()
    else
        self:HidePanel()
    end
end

function XUiRepeatChallengeSettleWin:HidePanel()
    self:Close()
end

-- function XUiRepeatChallengeSettleWin:PlayReward(index, cb)
--     self.GridRewardList[index].GameObject:SetActive(true)
--     self:PlayAnimation("GridReward", cb)
-- end