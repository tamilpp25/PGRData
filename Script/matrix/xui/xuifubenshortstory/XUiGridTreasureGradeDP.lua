local XUiGridTreasureGrade = require("XUi/XUiFubenMainLineChapter/XUiGridTreasureGrade")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiGridTreasureGradeDP = XClass(nil, "XUiGridTreasureGradeDP")

function XUiGridTreasureGradeDP:Ctor(rootUi, ui, treasureType)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.TreasureType = treasureType or XEnumConst.FuBen.StageType.Mainline
    self:InitAutoScript()
    self.GridCommonItem = self.Transform:Find("PanelTreasureList/Viewport/PanelTreasureContent/GridCommon")
    self.GridCommonItem.gameObject:SetActiveEx(false)
    self.PanelMultipleWeeksJindu.gameObject:SetActiveEx(false)
    self.GridList = {}
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiGridTreasureGradeDP:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiGridTreasureGradeDP:AutoInitUi()
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
    self.PanelMultipleWeeksJindu = self.Transform:Find("PanelMultipleWeeksJindu")
    self.TxtTaskDescribe = self.Transform:Find("PanelMultipleWeeksJindu/TxtTaskDescribe"):GetComponent("Text")
    self.TxtTaskNumQian = self.Transform:Find("PanelMultipleWeeksJindu/TxtTaskNumQian"):GetComponent("Text")
    self.ProgressBg  = self.Transform:Find("PanelMultipleWeeksJindu/ProgressBg")
    self.ImgProgress = self.Transform:Find("PanelMultipleWeeksJindu/ProgressBg/ImgProgress"):GetComponent("Image")

    --保存初始颜色
    self.OriginalColors = {
        starColor = self.ImgGradeStarActive.color,
        starDisColor = self.ImgGradeStarUnactive.color
    }
end

function XUiGridTreasureGradeDP:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiGridTreasureGradeDP:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiGridTreasureGradeDP:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiGridTreasureGradeDP:AutoAddListener()
    self:RegisterClickEvent(self.BtnReceive, self.OnBtnReceiveClick)
    -- self:RegisterClickEvent(self.BtnClick, self.OnBtnClickClick)
end
-- auto
function XUiGridTreasureGradeDP:OnBtnReceiveClick()
    if self.IsOnZhouMu then
        local TaskData = XDataCenter.TaskManager.GetTaskDataById(self.TaskId)
        local config = XDataCenter.TaskManager.GetTaskTemplate(self.TaskId)
        local rewards = XRewardManager.GetRewardList(config.RewardId)
        local weaponCount = 0
        local chipCount = 0

        for i = 1, #rewards do
            local rewardsId = rewards[i].TemplateId
            if XMVCA.XEquip:IsClassifyEqualByTemplateId(rewardsId, XEnumConst.EQUIP.CLASSIFY.WEAPON) then
                weaponCount = weaponCount + 1
            elseif XMVCA.XEquip:IsClassifyEqualByTemplateId(rewardsId, XEnumConst.EQUIP.CLASSIFY.AWARENESS) then
                chipCount = chipCount + 1
            end
        end
        if weaponCount > 0 and XMVCA.XEquip:CheckBagCount(weaponCount, XEnumConst.EQUIP.CLASSIFY.WEAPON) == false or
                chipCount > 0 and XMVCA.XEquip:CheckBagCount(chipCount, XEnumConst.EQUIP.CLASSIFY.AWARENESS) == false then
            return
        end

        XDataCenter.TaskManager.FinishTask(TaskData.Id, function(rewardGoodsList)
            XUiManager.OpenUiObtain(rewardGoodsList)
            self:Refresh()
        end)
    else
        if self.CurStars < self.RequireStar then
            return
        end
        if self.TreasureType == XEnumConst.FuBen.StageType.ShortStory then
            XDataCenter.ShortStoryChapterManager.ReceiveTreasureReward(function(reward)
                XUiManager.OpenUiObtain(reward, CS.XTextManager.GetText("Award"))
                self:Refresh()
            end, self.TreasureId)
        end
    end
end

function XUiGridTreasureGradeDP:UpdateGradeGrid(curStars, treasureId, chapterId, starColor, starDisColor)
    self.IsOnZhouMu = false
    self.CurStars = curStars
    self.TreasureId = treasureId
    self.RequireStar = XFubenShortStoryChapterConfigs.GetRequireStarByTreasureId(treasureId)
    self.RewardId = XFubenShortStoryChapterConfigs.GetRewardIdByTreasureId(treasureId)
    self.ChapterId = chapterId
    self.ImgGradeStarActive.color = starColor or self.OriginalColors.starColor
    self.ImgGradeStarUnactive.color = starDisColor or self.OriginalColors.starDisColor
    self:Refresh()
end

-- 显示多周目挑战任务
function XUiGridTreasureGradeDP:UpdateGradeGridTask(taskId)
    self.IsOnZhouMu = true
    self.TaskId = taskId
    self:Refresh()
end

function XUiGridTreasureGradeDP:Refresh()
    if self.IsOnZhouMu then
        self.ImgGradeStarActive.gameObject:SetActiveEx(false)
        self.ImgGradeStarUnactive.gameObject:SetActiveEx(false)
        self.TxtGradeStarNums.gameObject:SetActiveEx(false)
        self.PanelMultipleWeeksJindu.gameObject:SetActiveEx(true)
        self.ProgressBg.gameObject:SetActiveEx(false)

        local config = XDataCenter.TaskManager.GetTaskTemplate(self.TaskId)
        local TaskData = XDataCenter.TaskManager.GetTaskDataById(self.TaskId)

        if #config.Condition < 2 then--显示进度
            self.ProgressBg.gameObject:SetActiveEx(true)
            self.TxtTaskNumQian.gameObject:SetActiveEx(true)

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
    else
        local requireStars = self.RequireStar
        local curStars = self.CurStars > requireStars and requireStars or self.CurStars

        self.PanelMultipleWeeksJindu.gameObject:SetActiveEx(false)
        self.TxtGradeStarNums.gameObject:SetActiveEx(true)
        self.TxtGradeStarNums.text = CS.XTextManager.GetText("GradeStarNum", curStars, requireStars)

        if requireStars > 0 and self.CurStars >= requireStars then
            self:SetStarsActive(true)
            local isGet = XDataCenter.ShortStoryChapterManager.IsTreasureGet(self.TreasureId)
            if isGet then
                self:SetBtnAlreadyReceive()
            else
                self:SetBtnActive()
            end
        else
            self:SetStarsActive(false)
            self:SetBtnCannotReceive()
        end
    end
end

function XUiGridTreasureGradeDP:SetBtnActive()
    self.BtnReceive.gameObject:SetActiveEx(true)
    self.ImgAlreadyReceived.gameObject:SetActiveEx(false)
    self.ImgCannotReceive.gameObject:SetActiveEx(false)
end

function XUiGridTreasureGradeDP:SetBtnCannotReceive()
    self.BtnReceive.gameObject:SetActiveEx(false)
    self.ImgAlreadyReceived.gameObject:SetActiveEx(false)
    self.ImgCannotReceive.gameObject:SetActiveEx(true)
end

function XUiGridTreasureGradeDP:SetBtnAlreadyReceive()
    self.BtnReceive.gameObject:SetActiveEx(false)
    self.ImgAlreadyReceived.gameObject:SetActiveEx(true)
    self.ImgCannotReceive.gameObject:SetActiveEx(false)
end

function XUiGridTreasureGradeDP:SetStarsActive(flag)
    self.ImgGradeStarActive.gameObject:SetActiveEx(flag)
    self.ImgGradeStarUnactive.gameObject:SetActiveEx(not flag)
end

-- 初始化 treasure grid panel，填充数据
function XUiGridTreasureGradeDP:InitTreasureList()
    local rewards
    if self.IsOnZhouMu then
        local config = XDataCenter.TaskManager.GetTaskTemplate(self.TaskId)
        rewards = XRewardManager.GetRewardList(config.RewardId)
    else
        if self.RewardId == 0 then
            XLog.Error("treasure have no RewardId ")
            return
        end
        rewards = XRewardManager.GetRewardList(self.RewardId)
    end

    for i, item in ipairs(rewards) do
        local grid = self.GridList[i]
        if not grid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridCommonItem)
            grid = XUiGridCommon.New(self.RootUi, ui)
            grid.Transform:SetParent(self.PanelTreasureContent, false)
            self.GridList[i] = grid
        end
        grid:Refresh(item)
        grid.GameObject:SetActiveEx(true)
        -- i = i + 1
    end

    for j = 1, #self.GridList do
        if j > #rewards then
            self.GridList[j].GameObject:SetActiveEx(false)
        end
    end
end
return XUiGridTreasureGradeDP