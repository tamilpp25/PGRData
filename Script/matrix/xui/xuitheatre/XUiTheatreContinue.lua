local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiTheatreSkillGrid = require("XUi/XUiTheatre/XUiTheatreSkillGrid")
local XUiTheatreContinue = XLuaUiManager.Register(XLuaUi, "UiTheatreContinue")

function XUiTheatreContinue:OnAwake()
    self.TheatreManager = XDataCenter.TheatreManager
    self.CurrentAdventureManager = self.TheatreManager:GetCurrentAdventureManager()
    self.CurrentChapter = nil
    self.IsSettle = false
    -- 奖励列表
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemScrollView)
    self.DynamicTable:SetProxy(XUiGridCommon)
    self.DynamicTable:SetDelegate(self)
    self.GridReward.gameObject:SetActiveEx(false)
    -- 结算数据 XAdventureEnd
    self.AdventureEnd = nil
    self:RegisterUiEvents()
end

-- adventureEnd : XAdventureEnd
function XUiTheatreContinue:OnStart(adventureEnd, closeCb)
    self.CloseCallback = closeCb
    self.AdventureEnd = adventureEnd
end

function XUiTheatreContinue:OnEnable()
    self.Super.OnEnable(self)
    self.IsSettle = self.AdventureEnd ~= nil
    self.CurrentChapter = self.CurrentAdventureManager:GetCurrentChapter()
    local currentDifficulty = self.CurrentAdventureManager:GetCurrentDifficulty()
    -- 标题
    self.TxtTitle.text = self.CurrentChapter:GetTitle()
    -- 难度图标
    self.RImgDifficultyIcon:SetRawImage(currentDifficulty:GetTitleIcon())
    self.RImgDifficultyIcon2:SetRawImage(currentDifficulty:GetTitleIcon())
    -- 重开次数
    self.TxtReopenCount.text = self.CurrentAdventureManager:GetPlayableCount()
    -- 成员数
    self.TxtRoleCount.text = #self.CurrentAdventureManager:GetCurrentRoles(false)
    -- 全员等级
    self.TxtLevel.text = self.CurrentAdventureManager:GetCurrentLevel()
    -- 平均战力
    self.TxtPower.text = self.CurrentAdventureManager:GeRoleAveragePower()
    -- 信物刷新
    local currentToken = self.CurrentAdventureManager:GetCurrentToken()
    self.GridToken.gameObject:SetActiveEx(currentToken ~= nil)
    self.TxtNone.gameObject:SetActiveEx(currentToken == nil)
    if currentToken then
        self.RImgTokenIcon:SetRawImage(currentToken:GetIcon())
        self.ImgTokenQuality:SetSprite(currentToken:GetItemQualityIcon())
    end
    -- 核心技能刷新
    self:RefreshCoreSkills()
    -- 附加技能刷新
    self:RefreshAdditionSkills()
    -- 难度掉落
    self.TxtDifficultyRate.text = XUiHelper.GetText("TheatreDifficultyRateTip", currentDifficulty:GetRewardFactor())
    -- 奖励刷新
    self:RefreshRewardList()
    self.CurrentAdventureManager:ShowNextOperation()
end

function XUiTheatreContinue:OnDestroy()
    if self.CloseCallback then
        self.CloseCallback()
    end
end

--######################## 私有方法 ########################

function XUiTheatreContinue:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnEnd, self.OnBtnEndClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnContinue, self.OnBtnContinueClicked)
end

function XUiTheatreContinue:OnBtnEndClicked()
    XLuaUiManager.Open("UiDialog", XUiHelper.GetText("TheatreChapterSettleSureTitle")
        , XUiHelper.GetText("TheatreChapterSettleSureTip", self.CurrentChapter:GetTitle())
        , XUiManager.DialogType.Normal, nil
        , function()
            self.CurrentAdventureManager:RequestSettleAdventure(function()
                self:Remove()
        end)
    end)
end

function XUiTheatreContinue:OnBtnContinueClicked()
    if self.IsSettle then
        -- 进入下一个章节
        self.CurrentAdventureManager:EnterChapter()
    else
        local currentChapter = self.CurrentChapter
        currentChapter:SetIsReady(true)
        -- todo, 后面把GetIsCanRecruit判断放进GetIsCanEnterGame里
        if currentChapter:GetIsCanRecruit() and not currentChapter:GetIsCanEnterGame() then
            if table.nums(currentChapter:GetRecruitRoleDic()) <= 0 then
                -- 默认刷新一次    
                currentChapter:RequestRefreshRoles(function()
                    XLuaUiManager.Open("UiTheatreRecruit", currentChapter:GetId())        
                end)
            else
                XLuaUiManager.Open("UiTheatreRecruit", currentChapter:GetId())
            end
            return
        end
        XLuaUiManager.Open("UiTheatrePlayMain")
    end
end

function XUiTheatreContinue:RefreshCoreSkills()
    local coreSkills = self.CurrentAdventureManager:GetCoreSkills()
    local grid
    XUiHelper.RefreshCustomizedList(self.PanelBuffList, self.GridBuff, math.max(#coreSkills, 4)
    , function(index, go)
        local data = self.CurrentAdventureManager:GetCoreSkillByPos(index)
        grid = XUiTheatreSkillGrid.New(go):SetData(data, true, index)
        if not data then
            grid:SetLevel(1)
        end
    end)
end

function XUiTheatreContinue:RefreshAdditionSkills()
    local skills, powerCountDic = self.CurrentAdventureManager:GetAdditionSkillDic()
    local grid
    XUiHelper.RefreshCustomizedList(self.PanelNormalBuffList, self.GridNormalBuff, math.max(#skills, 7)
    , function(index, go)
        grid = XUiTheatreSkillGrid.New(go)
        grid:SetIcon(XTheatreConfigs.GetPowerConditionSmallIcon(index))
        grid:SetLevel(powerCountDic[index] or 0)
    end)
end

function XUiTheatreContinue:RefreshRewardList()
    local rewardItemDatas = nil
    if self.IsSettle then
        rewardItemDatas = self.AdventureEnd:GetRewardItemDatas()
    else
        rewardItemDatas = {}
        if self.CurrentAdventureManager:GetCurrentFavorCoin() > 0 then
            table.insert(rewardItemDatas, {
                TemplateId = XTheatreConfigs.TheatreFavorCoin,
                Count = self.CurrentAdventureManager:GetCurrentFavorCoin()
            })
        end
        if self.CurrentAdventureManager:GetCurrentDecorationCoin() > 0 then
            table.insert(rewardItemDatas, {
                TemplateId = XTheatreConfigs.TheatreDecorationCoin,
                Count = self.CurrentAdventureManager:GetCurrentDecorationCoin()
            })
        end
    end
    self.DynamicTable:SetDataSource(rewardItemDatas)
    self.DynamicTable:ReloadDataSync(1)
end

function XUiTheatreContinue:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.DynamicTable.DataSource[index])
    end
end

return XUiTheatreContinue