local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiBiancaTheatreItemGrid = require("XUi/XUiBiancaTheatre/Common/XUiBiancaTheatreItemGrid")

--############# 羁绊面板的格子 #############
local XUiComboGrid = XClass(nil, "XUiComboGrid")

function XUiComboGrid:Ctor(ui, adventureRoles)
    self.Gameobject = ui.gameObject
    self.Transform = ui.transform
    self.AdventureRoles = adventureRoles
    XTool.InitUiObject(self)
    self.ComboList = XDataCenter.BiancaTheatreManager.GetComboList()
    self.ImgQuality.gameObject:SetActiveEx(false)
end

function XUiComboGrid:Refresh(combo)
    self.RImgIcon:SetRawImage(combo:GetIconPath())
    self.TextCount.text = combo:GetTotalRank(self.AdventureRoles)
end



--############# 羁绊面板 #############
local XUiComboPanel = XClass(nil, "XUiComboPanel")

--activeComboList：已激活的羁绊列表
function XUiComboPanel:Ctor(ui, activeComboList, adventureRoles)
    self.Gameobject = ui.gameObject
    self.Transform = ui.transform
    self.AdventureRoles = adventureRoles
    XTool.InitUiObject(self)
    self:InitDynamicTable(activeComboList)
end

function XUiComboPanel:InitDynamicTable(activeComboList)
    self.DynamicTable = XDynamicTableNormal.New(self.PanelNormalBuffList)
    self.DynamicTable:SetProxy(XUiComboGrid, self.AdventureRoles)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetDataSource(activeComboList)
    self.DynamicTable:ReloadDataASync(1)
    self.TxtComboNone.gameObject:SetActiveEx(not XTool.IsNumberValid(#activeComboList))
    self.Grid.gameObject:SetActiveEx(false)
end

function XUiComboPanel:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.DynamicTable.DataSource[index])
    end
end



--############# 本局拥有道具面板 #############
local XUiItemPanel = XClass(nil, "XUiItemPanel")

function XUiItemPanel:Ctor(ui, theatreItemIdList)
    self.Gameobject = ui.gameObject
    self.Transform = ui.transform
    self.TheatreItemIdList = theatreItemIdList
    XTool.InitUiObject(self)
    self:InitDynamicTable(theatreItemIdList)
end

function XUiItemPanel:InitDynamicTable(theatreItemIdList)
    self.DynamicTable = XDynamicTableNormal.New(self.PanelBuffList)
    self.DynamicTable:SetProxy(XUiBiancaTheatreItemGrid)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetDataSource(theatreItemIdList)
    self.DynamicTable:ReloadDataASync(1)
    self.TxtItemNone.gameObject:SetActiveEx(not XTool.IsNumberValid(#theatreItemIdList))
    self.Grid.gameObject:SetActiveEx(false)
end

function XUiItemPanel:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.DynamicTable.DataSource[index])
    end
end



--############# 总结算 #############
local XUiBiancaTheatreInfiniteSettleWin = XLuaUiManager.Register(XLuaUi, "UiBiancaTheatreInfiniteSettleWin")

function XUiBiancaTheatreInfiniteSettleWin:OnAwake()
    self.Transform:GetComponent("XPlayMusic").enabled = false
    self.TheatreManager = XDataCenter.BiancaTheatreManager
    self.AdventureManager = self.TheatreManager:GetCurrentAdventureManager()
    self.CurrentChapter = self.AdventureManager:GetCurrentChapter()
    -- 结算数据 XAdventureEnd
    self.AdventureEnd = nil
    self:RegisterUiEvents()
end

-- adventureEnd : XAdventureEnd
function XUiBiancaTheatreInfiniteSettleWin:OnStart(adventureEnd, lastChapteEndStoryId)
    self.UiEnable:Play()
    
    self.AdventureManager:ShowNextOperation()
    self.AdventureEnd = adventureEnd
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
    self.TxtName.text = self.CurrentChapter and self.CurrentChapter:GetTitle() or ""
    -- 角色总星级数
    self.TxtLevel.text = adventureEnd:GetTotalCharacterLevel()
    -- 平均战力 
    self.TxtPower.text = adventureEnd:GetRoleAveragePower()
    -- 角色数量
    self.TxtRoleCount.text = adventureEnd:GetRolesCount()
    -- 分队
    local teamId = adventureEnd:GetTeamId()
    if XTool.IsNumberValid(teamId) then
        self.TextTeam.text = XBiancaTheatreConfigs.GetTeamName(teamId)
        self.ImageTeam:SetSprite(XBiancaTheatreConfigs.GetTeamIcon(teamId))
    else
        self.TextTeam.gameObject:SetActiveEx(false)
        self.ImageTeam.gameObject:SetActiveEx(false)
    end
    -- 本局拥有道具
    XUiItemPanel.New(self.PanelBuffList, adventureEnd:GetItems())
    -- 获得的羁绊
    XUiComboPanel.New(self.PanelNormalBuffList, adventureEnd:GetActiveComboList(), adventureEnd:GetCurrentRoles())

    local currentDifficulty = self.AdventureManager:GetCurrentDifficulty() or self.TheatreManager:GetCurrentDifficulty()
    local endFactor = adventureEnd:GetEndFactor()
    local titleIcon = currentDifficulty and currentDifficulty:GetTitleIcon()
    -- 数据统计
    local scoreDatas = adventureEnd:GetScoreDatas()
    self.GridScore.gameObject:SetActiveEx(false)  
    local scoreData, scoreUiObject
    for i = 1, #scoreDatas + 1 do
        scoreData = scoreDatas[i]
        scoreUiObject = XUiHelper.Instantiate(self.GridScore, self.PanelScore):GetComponent("UiObject")
        scoreUiObject:GetObject("TxtName").text = scoreData and scoreData.Name or ""
        scoreUiObject:GetObject("TxtCount").text = scoreData and scoreData.Count or ""
        scoreUiObject:GetObject("TxtScore").text = scoreData and string.format( "+%s", scoreData.Score) 
            or string.format( "X%s", endFactor)
        scoreUiObject:GetObject("TextEndName").text = adventureEnd:GetTitle()
        scoreUiObject:GetObject("PanelText").gameObject:SetActiveEx(i ~= #scoreDatas + 1)
        scoreUiObject:GetObject("PanelDifficulty").gameObject:SetActiveEx(i == #scoreDatas + 1)
        scoreUiObject.gameObject:SetActiveEx(true)
    end
    -- 总分数
    self.TxtTotalScore.text = adventureEnd:GetTotalScore()
    -- 新记录
    self.TxtNewNumber.gameObject:SetActiveEx(adventureEnd:GetIsNewScore())
    -- 难度标题
    if currentDifficulty then
        self.RImgDifficultyIcon:SetRawImage(currentDifficulty:GetTitleIcon())
    end
    -- 难度掉落概率
    self.TxtDifficultyRate.text = XUiHelper.GetText("TheatreDifficultyRateTip"
        , adventureEnd:GetDifficultyFactor())
    -- 本轮奖励一览
    self:UpdateReward(adventureEnd)
    -- 上一步隐藏
    self.BtnPreviousStep.gameObject:SetActiveEx(false)
    -- 结局背景音乐
    XDataCenter.BiancaTheatreManager.CheckEndBgmPlay(adventureEnd)
    -- 播放最后一章剧情
    if lastChapteEndStoryId then
        XDataCenter.MovieManager.PlayMovie(lastChapteEndStoryId)
    --     XDataCenter.MovieManager.PlayMovie(lastChapteEndStoryId, handler(self, self.PlayMoveAnima))
    -- else
    --     self:PlayMoveAnima()
    end
end

function XUiBiancaTheatreInfiniteSettleWin:OnEnable()
    local adventureManager = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager()
    local visionValue = adventureManager:GetOldVisionValue() or 0
    if XTool.IsNumberValid(visionValue) then
        XLuaUiManager.Open("UiBiancaTheatrePsionicVision", nil, nil, nil, nil, true)
    end
end

--自动滑动到底部
function XUiBiancaTheatreInfiniteSettleWin:PlayMoveAnima()
    self:PlayAnimation("UiMove")
end

function XUiBiancaTheatreInfiniteSettleWin:StopMoveAnima()
    self.UiMove:Stop()
    if self.UiEnable.state == CS.UnityEngine.Playables.PlayState.Playing and self.UiEnable.time < self.UiEnable.duration then
        self.UiEnable:Play()
        self.UiEnable.time = self.UiEnable.duration
    end
end

function XUiBiancaTheatreInfiniteSettleWin:UpdateReward(adventureEnd)
    --等级经验奖励
    local count = adventureEnd:GetTotalExp()
    if XTool.IsNumberValid(count) then
        local totalExpGrid = XUiGridCommon.New(XUiHelper.Instantiate(self.GridReward, self.PanelItemScrollView))
        totalExpGrid:Refresh({TemplateId = XBiancaTheatreConfigs.GetLevelItemId(), Count = count})
        XUiHelper.RegisterClickEvent(totalExpGrid, totalExpGrid.BtnClick, function()
            XLuaUiManager.Open("UiBiancaTheatreTips", XBiancaTheatreConfigs.GetLevelItemId())
        end)
    end
    --外循环材料奖励
    count = adventureEnd:GetOutItemCount()
    if XTool.IsNumberValid(count) then
        local outItemGrid = XUiGridCommon.New(XUiHelper.Instantiate(self.GridReward, self.PanelItemScrollView))
        outItemGrid:Refresh({TemplateId = XBiancaTheatreConfigs.GetStrengthenCoinId(), Count = count})
        XUiHelper.RegisterClickEvent(outItemGrid, outItemGrid.BtnClick, function()
            XLuaUiManager.Open("UiBiancaTheatreTips", XBiancaTheatreConfigs.GetStrengthenCoinId())
        end)
    end
    self.GridReward.gameObject:SetActiveEx(false)
end


-- Ui交互相关
--------------------------------------------------------------------------------

function XUiBiancaTheatreInfiniteSettleWin:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnNext, self.OnBtnNextClick)
    XUiHelper.RegisterClickEvent(self, self.BtnPreviousStep, self.OnBtnPreviousStepClick)
    -- ScrollRect的点击和滑动监听
    XUiHelper.RegisterClickEvent(self, self.SafeAreaContentPane, self.StopMoveAnima)
    local dragProxy = self.SafeAreaContentPane.gameObject:AddComponent(typeof(CS.XUguiDragProxy))
    dragProxy:RegisterHandler(handler(self, self.OnDragProxy))
end

function XUiBiancaTheatreInfiniteSettleWin:OnBtnNextClick()
    self:PlayAnimationWithMask("NextEnable")
    self.Viewpoet.gameObject:SetActiveEx(false)
    self.Viewpoet2.gameObject:SetActiveEx(true)
    self.BtnNext.gameObject:SetActiveEx(false)
    self.BtnPreviousStep.gameObject:SetActiveEx(true)
    self.BtnClose.gameObject:SetActiveEx(true)
end

function XUiBiancaTheatreInfiniteSettleWin:OnBtnPreviousStepClick()
    self:PlayAnimationWithMask("PreviousStepEnable")
    self.Viewpoet.gameObject:SetActiveEx(true)
    self.Viewpoet2.gameObject:SetActiveEx(false)
    self.BtnNext.gameObject:SetActiveEx(true)
    self.BtnPreviousStep.gameObject:SetActiveEx(false)
    self.BtnClose.gameObject:SetActiveEx(false)
end

function XUiBiancaTheatreInfiniteSettleWin:OnDragProxy(dragType)
    if dragType == 0 then
        self:StopMoveAnima()
    end
end

function XUiBiancaTheatreInfiniteSettleWin:Close()
    self.TheatreManager.UpdateCurrentAdventureManager(nil)
    XDataCenter.BiancaTheatreManager.RemoveStepView()
    self.Super.Close(self)
end

--------------------------------------------------------------------------------

return XUiBiancaTheatreInfiniteSettleWin