local XUiGridColorTableStage = require("XUi/XUiColorTable/Grid/XUiGridColorTableStage")

-- 调色战争选择关卡界面
local XUiColorTableChoicePlay = XLuaUiManager.Register(XLuaUi, "UiColorTableChoicePlay")

function XUiColorTableChoicePlay:OnAwake()
    self.ChapterId = nil -- 章节id
    self.DifficultyType = nil -- 难度类型
    self.IsSelectDifficult = false -- 是否在选择难度

    self:SetButtonCallBack()
    self:InitTimes()
    self:InitDynamicTable()
end

function XUiColorTableChoicePlay:OnStart(chapterId, difficultyId)
    self.ChapterId = chapterId
    self.DifficultyType = self:GetDifficultSaveData() or XColorTableConfigs.StageDifficultyType.Normal
end

function XUiColorTableChoicePlay:OnEnable()
    self.Super.OnEnable(self)
    self:Refresh()
end

function XUiColorTableChoicePlay:OnDisable()
    self.Super.OnDisable(self)
end

function XUiColorTableChoicePlay:SetButtonCallBack()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    XUiHelper.RegisterClickEvent(self, self.BtnNormal, self.OnBtnNormalClick)
    XUiHelper.RegisterClickEvent(self, self.BtnHard, self.OnBtnHardClick)
    XUiHelper.RegisterClickEvent(self, self.BtnCloseDifficult, self.OnBtnCloseDifficultClick)
    XUiHelper.RegisterClickEvent(self, self.BtnTreasure, self.OnBtnTreasureClick)
    self:BindHelpBtn(self.BtnHelp, XColorTableConfigs.GetUiChooseStageHelpKey())
end

function XUiColorTableChoicePlay:OnBtnNormalClick()
    self.IsSelectDifficult = not self.IsSelectDifficult
    self.BtnCloseDifficult.gameObject:SetActiveEx(self.IsSelectDifficult)

    if self.IsSelectDifficult then
        self.BtnNormal.gameObject:SetActiveEx(true)
        self.BtnHard.gameObject:SetActiveEx(true)
        self.BtnHard.transform:SetAsLastSibling()
    else
        self.DifficultyType = XColorTableConfigs.StageDifficultyType.Normal
        self:Refresh()
        self:PlayAnimation("QieHuan")
    end
end

function XUiColorTableChoicePlay:OnBtnHardClick()
    self.IsSelectDifficult = not self.IsSelectDifficult
    self.BtnCloseDifficult.gameObject:SetActiveEx(self.IsSelectDifficult)

    if self.IsSelectDifficult then
        self.BtnNormal.gameObject:SetActiveEx(true)
        self.BtnHard.gameObject:SetActiveEx(true)
        self.BtnNormal.transform:SetAsLastSibling()
    else
        self.DifficultyType = XColorTableConfigs.StageDifficultyType.Difficult
        self:Refresh()
        self:PlayAnimation("QieHuan")
    end
end

function XUiColorTableChoicePlay:OnBtnCloseDifficultClick()
    local isNormal = self.DifficultyType == XColorTableConfigs.StageDifficultyType.Normal
    local isChapter1 = self.ChapterId == 1
    self.BtnNormal.gameObject:SetActiveEx(isNormal)
    self.BtnHard.gameObject:SetActiveEx(not isNormal)
    self.IsSelectDifficult = false
    self.BtnCloseDifficult.gameObject:SetActiveEx(false)
    self.RImgBlueBg.gameObject:SetActiveEx(isNormal)
    self.RImgTittleBlue.gameObject:SetActiveEx(isNormal and isChapter1)
    self.RImgTittleBlue2.gameObject:SetActiveEx(isNormal and not isChapter1)

    self.RImgRedBg.gameObject:SetActiveEx(not isNormal)
    self.RImgTittleRed.gameObject:SetActiveEx(not isNormal and isChapter1)
    self.RImgTittleRed2.gameObject:SetActiveEx(not isNormal and not isChapter1)
end

function XUiColorTableChoicePlay:Refresh()
    self:RefreshDynamicTable()
    self:RefreshBtnTreasure()
    self:OnBtnCloseDifficultClick()
    self:RefreshDifficultPercent()
    self:RefreshDifficultSaveData()
end

function XUiColorTableChoicePlay:InitDynamicTable()
    self.GridStage.gameObject:SetActiveEx(false)
    self.DynamicTable = XDynamicTableNormal.New(self.PanelList)
    self.DynamicTable:SetProxy(XUiGridColorTableStage)
    self.DynamicTable:SetDelegate(self)
end

function XUiColorTableChoicePlay:RefreshDynamicTable()
    self.DataList = XColorTableConfigs.GetStageList(self.ChapterId, self.DifficultyType)
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync(1)
end

function XUiColorTableChoicePlay:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local stageCfg = self.DataList[index]
        grid:Refresh(self, stageCfg)
    end
end

function XUiColorTableChoicePlay:OpenStageDetail(stageId)
    XLuaUiManager.Open("UiColorTableStay", stageId)
end

-- 刷新进度奖励按钮
function XUiColorTableChoicePlay:RefreshBtnTreasure()
    local isShow = self:IsShowProgressReward()
    self.PanelBottom.gameObject:SetActive(isShow)
    if isShow then
        -- 刷新进度
        local passCount, allCount = XDataCenter.ColorTableManager.GetStageProgress(self.ChapterId, self.DifficultyType)
        self.TxtStarNum.text = string.format("%s<size=30>/%s</size>", passCount, allCount)
        self.ImgJindu.fillAmount = passCount/allCount

        -- 刷新已领取标签
        local isGet = self:IsGetDifficultyReward()
        self.ImgLingqu.gameObject:SetActiveEx(isGet)

        -- 可领取红点
        local isShowRed = XDataCenter.ColorTableManager.IsShowProgressRed(self.ChapterId, self.DifficultyType)
        self.RedJindu.gameObject:SetActiveEx(isShowRed)
    end
end

function XUiColorTableChoicePlay:OnBtnTreasureClick()
    -- 是否已经领取奖励
    if self:IsGetDifficultyReward() then 
        return 
    end

    local passCount, allCount = XDataCenter.ColorTableManager.GetStageProgress(self.ChapterId, self.DifficultyType)
    if passCount >= allCount then
        -- 进度到达了 请求领取奖励，然后刷新奖励
        XDataCenter.ColorTableManager.RequestRecvDifficultyReward(self.ChapterId, self.DifficultyType, function()
            self:RefreshBtnTreasure()
        end)
    else
        -- 进度未到达，显示奖励物品详情界面
        local config = XColorTableConfigs.GetDifficultyRewardConfig(self.ChapterId, self.DifficultyType)
        local rewards = XRewardManager.GetRewardList(config.RewardId)
        local data = {
            Id = rewards[1].TemplateId,
            Count = rewards[1].Count
        }
        XLuaUiManager.Open("UiTip", data)
    end
end

function XUiColorTableChoicePlay:InitTimes()
    self:SetAutoCloseInfo(XDataCenter.ColorTableManager.GetActivityEndTime(), function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        end
    end)
end

function XUiColorTableChoicePlay:IsShowProgressReward()
    local config = XColorTableConfigs.GetDifficultyRewardConfig(self.ChapterId, self.DifficultyType)
    return config.RewardId ~= 0
end

function XUiColorTableChoicePlay:IsGetDifficultyReward()
    return XDataCenter.ColorTableManager.IsGetDifficultyReward(self.ChapterId, self.DifficultyType)
end

function XUiColorTableChoicePlay:RefreshDifficultPercent()
    local norPassCount, norAllCount = XDataCenter.ColorTableManager.GetStageProgress(self.ChapterId, XColorTableConfigs.StageDifficultyType.Normal)
    self.TxetNormalPercent.text = math.floor(norPassCount * 100 / norAllCount)
    local difPassCount, difAllCount = XDataCenter.ColorTableManager.GetStageProgress(self.ChapterId, XColorTableConfigs.StageDifficultyType.Difficult)
    self.TxetHardlPercent.text = math.floor(difPassCount * 100 / difAllCount)
end

-- 刷新难度类型的保存数据
function XUiColorTableChoicePlay:RefreshDifficultSaveData()
    local key = self:GetChapterDifficultSaveKey(self.ChapterId)
    XSaveTool.SaveData(key, self.DifficultyType)
end

-- 获取上次章节所选难度类型
function XUiColorTableChoicePlay:GetDifficultSaveData()
    local key = self:GetChapterDifficultSaveKey(self.ChapterId)
    return XSaveTool.GetData(key)
end

function XUiColorTableChoicePlay:GetChapterDifficultSaveKey(chapterId)
    return XDataCenter.ColorTableManager.GetActivitySaveKey() .. "_UiColorTableChoicePlay_GetChapterDifficultSaveKey_ChapterId:" .. chapterId
end
