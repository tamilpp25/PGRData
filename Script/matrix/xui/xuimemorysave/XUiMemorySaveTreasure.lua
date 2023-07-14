local XUiMemorySaveTreasure = XClass(nil, "XUiMemorySaveTreasure")

function XUiMemorySaveTreasure:Ctor(rootUi, ui, treasureType)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.TreasureType = treasureType or XDataCenter.FubenManager.StageType.MemorySave
    self:InitAutoScript()
    self.GridCommonItem = self.Transform:Find("PanelTreasureList/Viewport/PanelTreasureContent/GridCommon")
    self.GridCommonItem.gameObject:SetActive(false)
    self.PanelMultipleWeeksJindu.gameObject:SetActiveEx(false)
    self.GridList = {}
end

function XUiMemorySaveTreasure:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiMemorySaveTreasure:AutoInitUi()
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
    self.TxtGrade.text = CSXTextManagerGetText("MemorySaveTreasureTip")
end

function XUiMemorySaveTreasure:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiMemorySaveTreasure:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiMemorySaveTreasure:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiMemorySaveTreasure:AutoAddListener()
    self:RegisterClickEvent(self.BtnReceive, self.OnBtnReceiveClick)
end

function XUiMemorySaveTreasure:OnBtnReceiveClick()
    if self.CurStars < self.RequireStar then
        return
    end
    if self.TreasureType == XDataCenter.FubenManager.StageType.MemorySave then
        XDataCenter.MemorySaveManager.MemorySaveChapterAwardRequest(function (reward)
            XDataCenter.MemorySaveManager.SetRewardIsGet(self.ChapterId, self.Index)
            XUiManager.OpenUiObtain(reward, CS.XTextManager.GetText("Award"))
            self:Refresh()
            XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_CHAPTER_REWARD) -- 领取奖励触发红点检查
        end, self.ChapterId, self.Index)
    end
end

--@curStars 当前条件
--@requireStar 需求条件
--@rewardId 奖励id
--@chapterId 章节id
--@index 奖励Id下标, 奖励Id可能重复
function XUiMemorySaveTreasure:UpdateGradeGrid(curStars, requireStar, rewardId, chapterId, index, starColor, starDisColor)
    self.CurStars = curStars
    self.RequireStar = requireStar
    self.RewardId = rewardId
    self.ChapterId = chapterId
    self.Index = index
    self.ImgGradeStarActive.color = starColor or self.OriginalColors.starColor
    self.ImgGradeStarUnactive.color = starDisColor or self.OriginalColors.starDisColor
    self:Refresh()
end

function XUiMemorySaveTreasure:Refresh()
    local requireStars = self.RequireStar
    local curStars = self.CurStars > requireStars and requireStars or self.CurStars

    self.PanelMultipleWeeksJindu.gameObject:SetActiveEx(false)
    self.TxtGradeStarNums.gameObject:SetActiveEx(true)
    self.TxtGradeStarNums.text = CS.XTextManager.GetText("GradeStarNum", curStars, requireStars)

    if requireStars > 0 and self.CurStars >= requireStars then
        self:SetStarsActive(true)
        local isGet
        if self.TreasureType == XDataCenter.FubenManager.StageType.MemorySave then
            isGet = XDataCenter.MemorySaveManager.IsTreasureGet(self.ChapterId, self.Index)
        end
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

function XUiMemorySaveTreasure:SetBtnActive()
    self.BtnReceive.gameObject:SetActive(true)
    self.ImgAlreadyReceived.gameObject:SetActive(false)
    self.ImgCannotReceive.gameObject:SetActive(false)
end

function XUiMemorySaveTreasure:SetBtnCannotReceive()
    self.BtnReceive.gameObject:SetActive(false)
    self.ImgAlreadyReceived.gameObject:SetActive(false)
    self.ImgCannotReceive.gameObject:SetActive(true)
end

function XUiMemorySaveTreasure:SetBtnAlreadyReceive()
    self.BtnReceive.gameObject:SetActive(false)
    self.ImgAlreadyReceived.gameObject:SetActive(true)
    self.ImgCannotReceive.gameObject:SetActive(false)
end

function XUiMemorySaveTreasure:SetStarsActive(flag)
    self.ImgGradeStarActive.gameObject:SetActiveEx(flag)
    self.ImgGradeStarUnactive.gameObject:SetActiveEx(not flag)
end

-- 初始化 treasure grid panel，填充数据
function XUiMemorySaveTreasure:InitTreasureList()
    local rewards
    if self.RewardId == 0 then
        XLog.Error("treasure have no RewardId ")
        return
    end
    rewards = XRewardManager.GetRewardList(self.RewardId)

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

return XUiMemorySaveTreasure