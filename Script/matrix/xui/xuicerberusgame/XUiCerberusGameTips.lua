local XUiCerberusGameTips = XLuaUiManager.Register(XLuaUi, "UiCerberusGameTips")

function XUiCerberusGameTips:OnAwake()
    self.GridStarDic = {}
    self.GridBuffDic = {}
    self:InitButton()
end

function XUiCerberusGameTips:InitButton()
    self:RegisterClickEvent(self.BtnTanchuangCloseBig, self.Close)
    self:RegisterClickEvent(self.BtnEnter, self.OnBtnEnterClick)
end

function XUiCerberusGameTips:OnStart(stageId, chapterId, currDifficulty, bossIndex)
    self.StageId = stageId
    self.ChapterId = chapterId
    self.CurrDifficulty = currDifficulty
    self.BossIndex = bossIndex
end

function XUiCerberusGameTips:OnEnable()
    self:RefreshUiShow()
end

function XUiCerberusGameTips:RefreshUiShow()
    local xStage = XDataCenter.CerberusGameManager.GetXStageById(self.StageId)
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    local bossCfg = XCerberusGameConfig.GetAllConfigs(XCerberusGameConfig.TableKey.CerberusGameBoss)[self.BossIndex]

    -- 关卡信息
    self.TxtStageName.text = stageCfg.Name
    self.BossIcon1:SetRawImage(bossCfg.BossImg)
    self.BossIcon2:SetRawImage(bossCfg.BossImg)
    self.Normal.gameObject:SetActiveEx(self.CurrDifficulty == XCerberusGameConfig.StageDifficulty.Normal)
    self.Hard.gameObject:SetActiveEx(self.CurrDifficulty == XCerberusGameConfig.StageDifficulty.Hard)

    -- 星级
    self.GridStar.gameObject:SetActiveEx(false)
    local starMap = xStage:GetStarsMapByMark()
    for k, desc in pairs(stageCfg.StarDesc) do
        local gridStar = self.GridStarDic[k]
        if not gridStar then
            gridStar = {}
            local ui = CS.UnityEngine.Object.Instantiate(self.GridStar, self.GridStar.parent)
            ui.gameObject:SetActiveEx(true)
            XTool.InitUiObjectByUi(gridStar, ui)
            gridStar.GridRewardDic = {}
            gridStar.Grid1.gameObject:SetActiveEx(false)
            gridStar.Grid2.gameObject:SetActiveEx(false)
            self.GridStarDic[k] = gridStar
        end
        gridStar.TxtActive.text = desc
        gridStar.TxtUnActive.text = desc

        local starInfo = starMap[k]
        gridStar.PanelUnActive.gameObject:SetActiveEx(true)
        gridStar.PanelActive.gameObject:SetActiveEx(starInfo)

        -- 每星的奖励
        local rewardId = stageCfg.StarRewardId[k]
        local rewards = {}
        if rewardId > 0 then
            rewards = XRewardManager.GetRewardList(rewardId)
        end
        if rewards then
            for i, item in ipairs(rewards) do
                local grid = gridStar.GridRewardDic[i]
                if not grid then
                    local baseGrid = starInfo and gridStar.Grid2 or gridStar.Grid1
                    local ui = CS.UnityEngine.Object.Instantiate(baseGrid, baseGrid.parent)
                    grid = XUiGridCommon.New(self, ui)
                    gridStar.GridRewardDic[i] = grid
                end
                grid:Refresh(item)
                grid.GameObject:SetActive(true)
            end
        end
    end

    -- buff
    self.GridBuff.gameObject:SetActiveEx(false)
    local challengeStageCfg = XCerberusGameConfig.GetAllConfigs(XCerberusGameConfig.TableKey.CerberusGameChallenge)[self.StageId]
    for k, title in pairs(challengeStageCfg.BuffTitle) do
        local gridBuff = self.GridBuffDic[k]
        if not gridBuff then
            gridBuff = {}
            local ui = CS.UnityEngine.Object.Instantiate(self.GridBuff, self.GridBuff.parent)
            ui.gameObject:SetActiveEx(true)
            XTool.InitUiObjectByUi(gridBuff, ui)
            self.GridBuffDic[k] = gridBuff
        end

        -- 刷新
        local icon = challengeStageCfg.BuffIcon[k]
        local desc = challengeStageCfg.BuffDescs[k]
        gridBuff.RImgBuffIcon:SetRawImage(icon)
        gridBuff.TxtDesc.text = desc
    end
end

function XUiCerberusGameTips:OnBtnEnterClick()
    local xStage = XDataCenter.CerberusGameManager.GetXStageById(self.StageId)
    -- 检查队伍
    XDataCenter.CerberusGameManager.ReInitXTeam(self.BossIndex, self.StageId,
        XDataCenter.CerberusGameManager.GetCanSelectRoleListForChallengeMode(self.StageId), self.ChapterId, self.CurrDifficulty)

    XLuaUiManager.PopThenOpen("UiBattleRoleRoom", self.StageId
            , xStage:GetXTeam()
            , require("XUi/XUiCerberusGame/Proxy/XUiCerberusGameBattleRoomProxy"))
end

return XUiCerberusGameTips