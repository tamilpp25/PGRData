--######################## XUiBuffGrid ########################
local XUiBuffGrid = XClass(nil, "XUiBuffGrid")

function XUiBuffGrid:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
end

-- data : XFubenConfigs.GetStageFightEventDetailsByStageFightEventId()
function XUiBuffGrid:SetData(data, isRoleBuff)
    self.RImgIcon:SetRawImage(data.Icon)
    self.TxtName.text = data.Name
    self.TxtDesc.text = data.Description
    self.PanelDebuff.gameObject:SetActiveEx(not isRoleBuff) 
    self.PanelBuff.gameObject:SetActiveEx(isRoleBuff)
end

--######################## XUiTheatreChoose ########################
local XUiTheatreChoose = XLuaUiManager.Register(XLuaUi, "UiTheatreChoose")

function XUiTheatreChoose:OnAwake()
    self.TheatreManager = XDataCenter.TheatreManager
    -- XTheatreTokenManager 信物管理
    self.TokenManager = self.TheatreManager.GetTokenManager()
    -- XAdventureManager 当前冒险管理器
    self.CurrentAdventureManager = nil
    -- XAdventureDifficulty 当前选择的难度
    self.CurrentDifficulty = nil
    -- buff列表
    self.DynamicTable = XDynamicTableNormal.New(self.PanelBuffList)
    self.DynamicTable:SetProxy(XUiBuffGrid)
    self.DynamicTable:SetDelegate(self)
    self.GridBuff.gameObject:SetActiveEx(false)
    -- 注册资源面板
    XUiHelper.NewPanelActivityAssetSafe(self.TheatreManager.GetAssetItemIds(), self.PanelAssetitems, self)
    self:RegisterUiEvents()

    local imgAdd = XUiHelper.TryGetComponent(self.BtnAddToken.transform, "ImgAdd")
    if imgAdd then
        imgAdd.gameObject:SetActiveEx(false)
    end
end

function XUiTheatreChoose:OnStart()
    -- 直接获取当前的管理器或者由方法内部创建新的
    self.CurrentAdventureManager = self.TheatreManager.CreateAdventureManager()
    local difficulties = self.CurrentAdventureManager:GetDifficulties()
    self.CurrentDifficulty = difficulties[1]
    -- 描述
    self.TxtDesc.text = XUiHelper.GetText("TheatreReadyDesc")
    -- 初始化难度选择标签
    self:InitDifficultyTags(difficulties)
    -- 刷新信物
    self:RefreshToken()
    -- 刷新3D背景
    self:UpdateSceneUrl()
    -- 刷新背景图片
    self:UpdateBg()
end

--######################## 私有方法 ########################

function XUiTheatreChoose:RegisterUiEvents()
    self.BtnMainUi.CallBack = function() XLuaUiManager.RunMain() end
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.Close)
    XUiHelper.RegisterHelpButton(self.BtnHelp, self.TheatreManager.GetHelpKey())
    XUiHelper.RegisterClickEvent(self, self.BtnFight, self.OnBtnFightClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnAddToken, self.OnBtnAddTokenClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnChooseKeepsake, self.OnBtnAddTokenClicked)
end

-- 初始化难度标0签
function XUiTheatreChoose:InitDifficultyTags(difficulties)
    self.BtnTab.gameObject:SetActiveEx(false)
    local buttons = {}
    -- 获取冒险所有开启的难度
    difficulties = difficulties or self.CurrentAdventureManager:GetDifficulties()
    local go, button
    for i, difficulty in ipairs(difficulties) do
        go = XUiHelper.Instantiate(self.BtnTab, self.PanelTabList.transform)
        button = go:GetComponent("XUiButton")
        button.gameObject:SetActiveEx(true)
        button:SetSprite(difficulty:GetTagIcon())
        go:GetComponent("UiObject"):GetObject("ImgDifficultyTxt"):SetSprite(difficulty:GetTagTextIcon())
        -- 设置禁用状态
        button:SetDisable(not difficulty:GetIsOpen())
        table.insert(buttons, button)
    end
    self.PanelTabList:Init(buttons, function(index)
        self:OnBtnDifficultyClicked(index)
    end)
    self.PanelTabList:SelectIndex(1)
end

-- difficulty : XAdventureDifficulty
function XUiTheatreChoose:OnBtnDifficultyClicked(index)
    local difficulty = self.CurrentAdventureManager:GetDifficulties()[index]
    if not difficulty:GetIsOpen(true) then
        return
    end
    self.CurrentDifficulty = difficulty
    self:RefreshDifficulty(difficulty)
end

-- 刷新当前难度
-- difficulty : XAdventureDifficulty
function XUiTheatreChoose:RefreshDifficulty(difficulty) 
    if difficulty == nil then difficulty = self.CurrentDifficulty end
    -- 标题图片
    self.RImgIconDifficulty:SetRawImage(difficulty:GetTitleIcon())
    -- 刷新词条
    self.DynamicTable:SetDataSource(difficulty:GetAllBuffDatas())
    self.DynamicTable:ReloadDataSync(1)
    -- 刷新奖励掉落
    self:RefreshRewardList(difficulty:GetRewardIds(), difficulty:GetRewardFactor())
    if self.AnimSwitch then
        self.AnimSwitch:Play()
        self.EffectSwitch.gameObject:SetActiveEx(false)
        self.EffectSwitch.gameObject:SetActiveEx(true)
    end
end

function XUiTheatreChoose:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetData(self.DynamicTable.DataSource[index], index <= self.CurrentDifficulty:GetRoleBuffCount())
    end
end

function XUiTheatreChoose:RefreshRewardList(itemIds, factor)
    self.GridReward.gameObject:SetActiveEx(false)
    local child
    local childCount = self.PanelRewardList.childCount
    for i = 0, childCount - 1 do
        child = self.PanelRewardList:GetChild(i)
        child.gameObject:SetActiveEx(false)
    end
    for i = 1, #itemIds do
        if i > childCount then
            child = XUiHelper.Instantiate(self.GridReward, self.PanelRewardList)
        else
            child = self.PanelRewardList:GetChild(i - 1)
        end
        child.gameObject:SetActiveEx(true)
        XUiGridCommon.New(self, child):Refresh(itemIds[i])
    end
    self.TxtNumber.text = factor
end

-- 刷新当前信物
function XUiTheatreChoose:RefreshToken()
    local hasAnyToken = self.TokenManager:CheckHasToken()
    self.PanelKeepsake.gameObject:SetActiveEx(hasAnyToken)
    if not hasAnyToken then return end

    local currentToken = self.CurrentAdventureManager:GetCurrentToken()
    self.GridToken.gameObject:SetActiveEx(currentToken ~= nil)
    self.BtnAddToken.gameObject:SetActiveEx(currentToken ~= nil)
    if self.BtnChooseKeepsake then
        self.BtnChooseKeepsake.gameObject:SetActiveEx(currentToken == nil)
    end
    if currentToken == nil then return end

    self.RImgTokenIcon:SetRawImage(currentToken:GetIcon())
    self.ImgTokenQuality:SetSprite(currentToken:GetItemQualityIcon())
end

-- 开始冒险
function XUiTheatreChoose:OnBtnFightClicked()
    local asynCheckDefficulty = asynTask(function(cb)
        XLuaUiManager.Open("UiDialog", nil, XUiHelper.GetText("TheatreDifficultyTip", self.CurrentDifficulty:GetName()), XUiManager.DialogType.Normal, nil, function()
            if cb then
                cb()
            end
        end)
    end)
    local asynCheckDecorationCanLvUp = asynTask(function(cb)
        XLuaUiManager.Open("UiDialog", nil, XUiHelper.GetText("TheatreDecorationCanLvUpTips"), XUiManager.DialogType.Normal, nil, function() 
            if cb then
                cb()
            end
        end)
    end)
    local asynCheckSelectToken = asynTask(function(cb)
        XLuaUiManager.Open("UiDialog", nil, XUiHelper.GetText("TheatreNotSelectTokenTip"), XUiManager.DialogType.Normal,nil, function()
            if cb then
                cb()
            end
        end)
    end)

    RunAsyn(function()
        -- 检查配置指定的装修组是否可升级
        if XDataCenter.TheatreManager.CheckDecorationGroupIndexLvUp() then
            asynCheckDecorationCanLvUp()
        end
        -- 检查信物
        if self.TokenManager:CheckHasToken() and self.CurrentAdventureManager:GetCurrentToken() == nil then
            asynCheckSelectToken()
        end
        -- 提示难度
        asynCheckDefficulty()
        -- 更新当前难度
        self.CurrentAdventureManager:UpdateCurrentDifficulty(self.CurrentDifficulty)
        -- 进入冒险
        self.CurrentAdventureManager:Enter()
    end)
end

-- 选择信物
function XUiTheatreChoose:OnBtnAddTokenClicked()
    XLuaUiManager.Open("UiTheatreFieldGuide", { XTheatreConfigs.FieldGuideIds.Item }, true, function(token)
        self.CurrentAdventureManager:UpdateCurrentToken(token)
        self:RefreshToken()
    end)
end

function XUiTheatreChoose:UpdateSceneUrl()
    XDataCenter.TheatreManager.UpdateSceneUrl(self)
    XScheduleManager.ScheduleOnce(function()
        XDataCenter.TheatreManager.ShowRoleModelCamera(self, "FarCameraChoose", "NearCameraChoose", true)
    end, 1)
end

function XUiTheatreChoose:UpdateBg()
    local chapter = self.CurrentAdventureManager:GetCurrentChapter()
    local chapterId = chapter:GetCurrentChapterId()
    if self.RImgBgA then
        local bgA = XTheatreConfigs.GetChapterBgA(chapterId)
        self.RImgBgA:SetRawImage(bgA)
    end
    if self.RImgBgB then
        local bgB = XTheatreConfigs.GetChapterBgB(chapterId)
        self.RImgBgB:SetRawImage(bgB)
    end
end

return XUiTheatreChoose