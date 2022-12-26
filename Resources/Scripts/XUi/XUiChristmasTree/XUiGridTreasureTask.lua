XUiGridTreasureTask = XClass(nil, "XUiGridTreasureTask")

function XUiGridTreasureTask:Ctor(rootUi, ui, treasureType)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.TreasureType = treasureType or XDataCenter.FubenManager.StageType.Mainline
    self:InitAutoScript()
    self.GridCommonItem = self.Transform:Find("PanelTreasureList/Viewport/PanelTreasureContent/GridCommon")
    self.GridCommonItem.gameObject:SetActive(false)
    self.PanelProgress.gameObject:SetActiveEx(false)
    self.GridList = {}
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiGridTreasureTask:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiGridTreasureTask:AutoInitUi()
    self.ImgGradeLine = self.Transform:Find("ImgGradeLine"):GetComponent("Image")
    self.TxtGrade = self.Transform:Find("TxtGrade"):GetComponent("Text")
    self.TxtGradeStarNums = self.Transform:Find("TxtGradeStarNums"):GetComponent("Text")
    self.ImgGradeStarActive = self.Transform:Find("ImgGradeStarActive"):GetComponent("Image")
    self.ImgGradeStarUnactive = self.Transform:Find("ImgGradeStarUnactive"):GetComponent("Image")
    self.BtnReceive = self.Transform:Find("BtnReceive"):GetComponent("Button")
    self.ImgCannotReceive = self.Transform:Find("ImgCannotReceive"):GetComponent("Image")
    self.ImgAlreadyReceived = self.Transform:Find("ImgAlreadyReceived"):GetComponent("Image")
    self.PanelTreasureList = self.Transform:Find("PanelTreasureList")
    self.PanelTreasureContent = self.Transform:Find("PanelTreasureList/Viewport/PanelTreasureContent")
    self.GridCommon = self.Transform:Find("PanelTreasureList/Viewport/PanelTreasureContent/GridCommon")
    self.RImgIcon = self.Transform:Find("PanelTreasureList/Viewport/PanelTreasureContent/GridCommon/RImgIcon"):GetComponent("RawImage")
    self.ImgQuality = self.Transform:Find("PanelTreasureList/Viewport/PanelTreasureContent/GridCommon/ImgQuality"):GetComponent("Image")
    self.BtnClick = self.Transform:Find("PanelTreasureList/Viewport/PanelTreasureContent/GridCommon/BtnClick"):GetComponent("Button")
    self.TxtCount = self.Transform:Find("PanelTreasureList/Viewport/PanelTreasureContent/GridCommon/TxtCount"):GetComponent("Text")
    self.PanelProgress = self.Transform:Find("PanelProgress")
    self.TxtTaskDescribe = self.Transform:Find("PanelProgress/TxtTaskDescribe"):GetComponent("Text")
    self.TxtTaskNumQian = self.Transform:Find("PanelProgress/TxtTaskNumQian"):GetComponent("Text")
    self.ProgressBg  = self.Transform:Find("PanelProgress/ProgressBg")
    self.ImgProgress = self.Transform:Find("PanelProgress/ProgressBg/ImgProgress"):GetComponent("Image")

    --保存初始颜色
    self.OriginalColors = {
        starColor = self.ImgGradeStarActive.color,
        starDisColor = self.ImgGradeStarUnactive.color
    }
end

function XUiGridTreasureTask:AutoAddListener()
    CsXUiHelper.RegisterClickEvent(self.BtnReceive, function () self:OnBtnReceiveClick() end)
end
-- auto
function XUiGridTreasureTask:OnBtnReceiveClick()
    local TaskData = XDataCenter.TaskManager.GetTaskDataById(self.TaskId)

    XDataCenter.TaskManager.FinishTask(TaskData.Id, function(rewardGoodsList)
        XUiManager.OpenUiObtain(rewardGoodsList)
        self:Refresh()
        XEventManager.DispatchEvent(EVENT_CHRISTMAS_TREE_GOT_REWARD)
    end)
end

-- 显示挑战任务
function XUiGridTreasureTask:UpdateGradeGridTask(taskId)
    self.TaskId = taskId
    self:Refresh()
end

function XUiGridTreasureTask:Refresh()
    self.ImgGradeStarActive.gameObject:SetActiveEx(false)
    self.ImgGradeStarUnactive.gameObject:SetActiveEx(false)
    self.TxtGradeStarNums.gameObject:SetActiveEx(false)
    self.PanelProgress.gameObject:SetActiveEx(true)
    self.ProgressBg.gameObject:SetActive(false)

    local config = XDataCenter.TaskManager.GetTaskTemplate(self.TaskId)
    local TaskData = XDataCenter.TaskManager.GetTaskDataById(self.TaskId)

    if #config.Condition < 2 then--显示进度
        self.ProgressBg.gameObject:SetActive(true)
        self.TxtTaskNumQian.gameObject:SetActive(true)

        local result = config.Result > 0 and config.Result or 1
        self.TxtTaskDescribe.text = config.Desc

        XTool.LoopMap(TaskData.Schedule, function(_, pair)
            self.ImgProgress.fillAmount = pair.Value / result
            pair.Value = (pair.Value >= result) and result or pair.Value
            self.TxtTaskNumQian.text = CS.XTextManager.GetText("AlreadyobtainedCount", pair.Value, result)
        end)
    end

    if TaskData.State == XDataCenter.TaskManager.TaskState.Achieved then
        self:SetBtnActive()
    elseif TaskData.State == XDataCenter.TaskManager.TaskState.Finish then
        self:SetBtnAlreadyReceive()
    else
        self:SetBtnCannotReceive()
    end
end

function XUiGridTreasureTask:SetBtnActive()
    self.BtnReceive.gameObject:SetActive(true)
    self.ImgAlreadyReceived.gameObject:SetActive(false)
    self.ImgCannotReceive.gameObject:SetActive(false)
end

function XUiGridTreasureTask:SetBtnCannotReceive()
    self.BtnReceive.gameObject:SetActive(false)
    self.ImgAlreadyReceived.gameObject:SetActive(false)
    self.ImgCannotReceive.gameObject:SetActive(true)
end

function XUiGridTreasureTask:SetBtnAlreadyReceive()
    self.BtnReceive.gameObject:SetActive(false)
    self.ImgAlreadyReceived.gameObject:SetActive(true)
    self.ImgCannotReceive.gameObject:SetActive(false)
end

function XUiGridTreasureTask:SetStarsActive(flag)
    self.ImgGradeStarActive.gameObject:SetActiveEx(flag)
    self.ImgGradeStarUnactive.gameObject:SetActiveEx(not flag)
end

-- 初始化 treasure grid panel，填充数据
function XUiGridTreasureTask:InitTreasureList()
    local config = XDataCenter.TaskManager.GetTaskTemplate(self.TaskId)
    local rewards = XRewardManager.GetRewardList(config.RewardId)

    for i, item in ipairs(rewards) do
        local grid = self.GridList[i]
        if not grid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridCommonItem)
            grid = XUiGridCommon.New(self.RootUi, ui)
            grid.Transform:SetParent(self.PanelTreasureContent, false)
            self.GridList[i] = grid
        end
        grid:Refresh(item)
        grid.GameObject:SetActive(true)
        -- i = i + 1
    end

    for j = 1, #self.GridList do
        if j > #rewards then
            self.GridList[j].GameObject:SetActive(false)
        end
    end
end