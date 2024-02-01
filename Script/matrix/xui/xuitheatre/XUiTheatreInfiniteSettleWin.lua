local XUiTheatreSkillGrid = require("XUi/XUiTheatre/XUiTheatreSkillGrid")
local XUiTheatreInfiniteSettleWin = XLuaUiManager.Register(XLuaUi, "UiTheatreInfiniteSettleWin")

function XUiTheatreInfiniteSettleWin:OnAwake()
    self.TheatreManager = XDataCenter.TheatreManager
    self.AdventureManager = self.TheatreManager:GetCurrentAdventureManager()
    self.CurrentChapter = self.AdventureManager:GetCurrentChapter()
    self.PowerManager = self.TheatreManager:GetPowerManager()
    -- 奖励列表
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemScrollView)
    self.DynamicTable:SetProxy(XUiGridCommon)
    self.DynamicTable:SetDelegate(self)
    self.GridReward.gameObject:SetActiveEx(false)
    -- 结算数据 XAdventureEnd
    self.AdventureEnd = nil
    self.RewardItemDatas = nil
    self:RegisterUiEvents()
end

-- adventureEnd : XAdventureEnd
function XUiTheatreInfiniteSettleWin:OnStart(adventureEnd, lastChapteEndStoryId)
    self.AdventureManager:ShowNextOperation()
    self.AdventureEnd = adventureEnd
    self.RewardItemDatas = adventureEnd:GetRewardItemDatas()
    -- 结局标题
    self.TxtTitle.text = adventureEnd:GetTitle()
    -- 结局描述
    self.TxtEndDetail.text = adventureEnd:GetDesc()
    -- 新结局
    self.NewTag.gameObject:SetActiveEx(adventureEnd:GetIsNewEnd())
    -- 玩家名字
    self.TxtPlayerName.text = XPlayer.Name
    -- 时间
    self.TxtTime.text = XTime.TimestampToGameDateTimeString(XTime.GetServerNowTimestamp(), "yyyy/MM/dd")
    -- 章节名字
    self.TxtName.text = self.CurrentChapter:GetTitle()
    -- 等级
    self.TxtLevel.text = self.AdventureManager:GetCurrentLevel()
    -- 战力
    self.TxtPower.text = self.AdventureManager:GeRoleAveragePower()
    -- 角色数量
    self.TxtRoleCount.text = #self.AdventureManager:GetCurrentRoles(false)
    -- 信物
    local currentToken = self.AdventureManager:GetCurrentToken()
    self.GridToken.gameObject:SetActiveEx(currentToken ~= nil)
    self.TxtNone.gameObject:SetActiveEx(currentToken == nil)
    if currentToken then
        self.RImgTokenIcon:SetRawImage(currentToken:GetIcon())
        self.ImgTokenQuality:SetSprite(currentToken:GetItemQualityIcon())
    end
    local currentDifficulty = self.AdventureManager:GetCurrentDifficulty()
    -- 其他分数，节点，战斗，事件，boss，重开次数
    local scoreDatas = adventureEnd:GetScoreDatas()
    self.GridScore.gameObject:SetActiveEx(false)  
    local scoreData, scoreUiObject
    for i = 1, #scoreDatas + 1 do
        scoreData = scoreDatas[i]
        scoreUiObject = XUiHelper.Instantiate(self.GridScore, self.PanelScore):GetComponent("UiObject")
        scoreUiObject:GetObject("TxtName").text = scoreData and scoreData.Name or ""
        scoreUiObject:GetObject("TxtCount").text = scoreData and scoreData.Count or ""
        scoreUiObject:GetObject("TxtScore").text = scoreData and string.format( "+%s", scoreData.Score) 
            or string.format( "X%s", currentDifficulty:GetRewardFactor())
        scoreUiObject:GetObject("RImgIcon").gameObject:SetActiveEx(i == #scoreDatas + 1)
        scoreUiObject:GetObject("RImgIcon"):SetRawImage(currentDifficulty:GetTitleIcon())
        scoreUiObject.gameObject:SetActiveEx(true)
        
    end
    -- 总分数
    self.TxtTotalScore.text = adventureEnd:GetTotalScore()
    -- 新记录
    self.TxtNewNumber.gameObject:SetActiveEx(adventureEnd:GetIsNewScore())
    -- 难度标题
    self.RImgDifficultyIcon:SetRawImage(currentDifficulty:GetTitleIcon())
    -- 难度掉落概率
    self.TxtDifficultyRate.text = XUiHelper.GetText("TheatreDifficultyRateTip"
        , currentDifficulty:GetRewardFactor())
    -- 刷新核心技能
    self:RefreshCoreSkills()
    -- 刷新额外技能
    self:RefreshAdditionSkills()
    -- 刷新获得的奖励
    self:RefreshRewardList()
    -- 更新解锁的势力
    self.PowerManager:UpdateUnlockPowerFavorIds(adventureEnd:GetUnlockPowerFavorIds())
    -- 播放最后一章剧情
    if lastChapteEndStoryId then
        XDataCenter.MovieManager.PlayMovie(lastChapteEndStoryId)
    end
end

function XUiTheatreInfiniteSettleWin:OnDisable()
    if XLuaUiManager.IsUiLoad("UiTheatrePlayMain") then
        XLuaUiManager.Remove("UiTheatrePlayMain")
    end
end

function XUiTheatreInfiniteSettleWin:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
end

function XUiTheatreInfiniteSettleWin:RefreshCoreSkills()
    local coreSkills = self.AdventureManager:GetCoreSkills()
    local grid
    XUiHelper.RefreshCustomizedList(self.PanelBuffList, self.GridBuff, math.max(#coreSkills, 4)
    , function(index, go)
        local data = self.AdventureManager:GetCoreSkillByPos(index)
        grid = XUiTheatreSkillGrid.New(go):SetData(data, true, index)
        if not data then
            grid:SetLevel(1)
        end
    end)
end

function XUiTheatreInfiniteSettleWin:RefreshAdditionSkills()
    local skills, powerCountDic = self.AdventureManager:GetAdditionSkillDic()
    local grid
    XUiHelper.RefreshCustomizedList(self.PanelNormalBuffList, self.GridNormalBuff, math.max(#skills, 7)
    , function(index, go)
        grid = XUiTheatreSkillGrid.New(go)
        grid:SetIcon(XTheatreConfigs.GetPowerConditionSmallIcon(index))
        grid:SetLevel(powerCountDic[index] or 0)
    end)
end

function XUiTheatreInfiniteSettleWin:RefreshRewardList()
    self.DynamicTable:SetDataSource(self.RewardItemDatas)
    self.DynamicTable:ReloadDataSync(1)
end

function XUiTheatreInfiniteSettleWin:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.DynamicTable.DataSource[index])
    end
end

function XUiTheatreInfiniteSettleWin:Close()
    self.TheatreManager.UpdateCurrentAdventureManager(nil)
    self.Super.Close(self)
end

return XUiTheatreInfiniteSettleWin