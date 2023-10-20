local XUiCerberusGameDetail = XLuaUiManager.Register(XLuaUi, "UiCerberusGameDetail")

function XUiCerberusGameDetail:OnAwake()
    self.GridReward = {}
    self.GridStarDic = {}
    self.GridBuffDic = {}
    self:InitButton()
end

function XUiCerberusGameDetail:InitButton()
    self:RegisterClickEvent(self.BtnCloseMask, self.Close)
    self:RegisterClickEvent(self.BtnEnter, self.OnBtnEnterClick)
end

---@param xStoryPoint XCerberusGameStoryPoint
function XUiCerberusGameDetail:OnStart(xStoryPoint, chapterId, currDifficulty, gridStage)
    self.XStoryPoint = xStoryPoint
    self.ChapterId = chapterId
    self.CurrDifficulty = currDifficulty
    self.GridStage = gridStage
    gridStage:SetPanelSelect(true)
end

function XUiCerberusGameDetail:OnEnable()
    XMVCA.XCerberusGame:SetLastSelectXStoryPoint(self.XStoryPoint)
    self:RefreshUi()
end

function XUiCerberusGameDetail:RefreshUi()
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.XStoryPoint:GetXStage().StageId)
    self.TxtName.text = stageCfg.Name
    -- 星级
    self.GridStar.gameObject:SetActiveEx(false)
    local starMap = self.XStoryPoint:GetXStage():GetStarsMapByMark()
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
        gridStar.TxtTitle1.text = desc
        gridStar.TxtTitle2.text = desc

        local starInfo = starMap[k]
        gridStar.TxtTitle2.gameObject:SetActiveEx(starInfo)
        gridStar.Img2.gameObject:SetActiveEx(starInfo)

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
    local storyPointCfg = self.XStoryPoint:GetConfig()
    for k, title in pairs(storyPointCfg.BuffTitle) do
        local gridBuff = self.GridBuffDic[k]
        if not gridBuff then
            gridBuff = {}
            local ui = CS.UnityEngine.Object.Instantiate(self.GridBuff, self.GridBuff.parent)
            ui.gameObject:SetActiveEx(true)
            XTool.InitUiObjectByUi(gridBuff, ui)
            self.GridBuffDic[k] = gridBuff
        end

        -- 刷新
        local icon = storyPointCfg.BuffIcon[k]
        local desc = storyPointCfg.BuffDescs[k]
        gridBuff.RImgBuffIcon:SetRawImage(icon)
        gridBuff.TxtBuffName.text = title
        gridBuff.TxtTitle.text = desc
    end

    local isOpen, desc = self.XStoryPoint:GetIsOpen()
    self.TxtNoBattle.gameObject:SetActiveEx(not isOpen)
    self.BtnEnter.gameObject:SetActiveEx(isOpen)
    self.TxtNoBattle.text = desc
end

function XUiCerberusGameDetail:OnBtnEnterClick()
    if not self.XStoryPoint:GetIsOpen() then
        return
    end

    local canSeleRole = XMVCA.XCerberusGame:GetCanSelectRoleListForStoryMode()
    local xStage = self.XStoryPoint:GetXStage()
    local xTeam = XMVCA.XCerberusGame:GetXTeamByChapterId(self.ChapterId)
    XMVCA.XCerberusGame:ReInitXTeamV2P9(canSeleRole, self.ChapterId)
    
    -- local xTeam = xStage:GetXTeam()
    -- XMVCA.XCerberusGame:ReInitXTeam(self.GridStage.GridIndex, xStage.StageId, 
    -- canSeleRole, self.ChapterId, self.CurrDifficulty)

    XLuaUiManager.Open("UiBattleRoleRoom", xStage.StageId, xTeam, require("XUi/XUiCerberusGame/Proxy/XUiCerberusGameBattleRoomProxy"))
end

function XUiCerberusGameDetail:OnDestroy()
    self.GridStage:SetPanelSelect(false)
end

return XUiCerberusGameDetail