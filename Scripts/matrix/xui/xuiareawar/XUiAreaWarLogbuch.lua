local XUiGridChapterProgress = XClass(nil, "XUiGridChapterProgress")

local Decimal = 10 ^ 2 --保留2位小数

function XUiGridChapterProgress:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
end

function XUiGridChapterProgress:Refresh(chapterId)
    self.TxtChapter.text = XAreaWarConfigs.GetChapterName(chapterId)
    local progress = XDataCenter.AreaWarManager.GetChapterProgress(chapterId)
    local isZero = progress <= 0
    local isFinish = progress >= 1
    local isInProgress = progress > 0 and progress < 1
    self.PanelZero.gameObject:SetActiveEx(isZero)
    self.PanelInProgress.gameObject:SetActiveEx(isInProgress)
    self.PanelFinish.gameObject:SetActiveEx(isFinish)
    if isInProgress then
        self.TxtInProgress.text = math.floor(progress * 100 * Decimal) / Decimal .. "%"
        self.ImgProgress.fillAmount = progress
    end
end


---@class XUiAreaWarLogbuch : XLuaUi 全服战况
---@field PanelTitleBtnGroup XUiButtonGroup
local XUiAreaWarLogbuch = XLuaUiManager.Register(XLuaUi, "UiAreaWarLogbuch")

local TabButtonType = {
    Primary     = 1,
    Secondary   = 2
}

local MaxShowCount = 4 --当前位置最大显示个数

function XUiAreaWarLogbuch:OnAwake()
    self:InitCb()
    self:InitUi()
end

function XUiAreaWarLogbuch:OnStart()
    self:InitView()
end

function XUiAreaWarLogbuch:OnEnable()
    self:UpdateView()
end

function XUiAreaWarLogbuch:OnGetEvents()
    return {
        XEventId.EVENT_AREA_WAR_BLOCK_STATUS_CHANGE,
    }
end

function XUiAreaWarLogbuch:OnNotify(evt, ...)
    if evt == XEventId.EVENT_AREA_WAR_BLOCK_STATUS_CHANGE then
        self:UpdateProgress()
        self:RefreshTab()
        self:RefreshCoord()
    end
end

function XUiAreaWarLogbuch:InitCb()
    self.BtnBack.CallBack = function() 
        self:Close()
    end
    
    self.BtnZan.CallBack = function() 
        self:OnBtnLikeClick()
    end

    self.BtnStory.CallBack = function()
        self:OnBtnStoryClick()
    end
    
    self.SortBlockId = function(a, b) 
        return a > b
    end
    
    self.OnRefreshCb = handler(self, self.RefreshTabCb)
end

function XUiAreaWarLogbuch:InitUi()
    --进度
    self.GridProgress = {}
    self.ChapterList = XAreaWarConfigs.GetChapterIds()
    --位置
    self.GridCoords = {}
    --页签
    local tab = {}
    local groupList = XAreaWarConfigs.GetArticleGroupList()
    
    self.Index2Id = {}
    
    local btnIndex = 0
    for _, groupId in pairs(groupList) do
        local list = XDataCenter.AreaWarManager.GetUnlockArticleList(groupId)  or {}
        local childCount = #list
        local hasChild = childCount > 0
        local btn = self:_CreateTabBtn(TabButtonType.Primary, hasChild)
        btn:SetNameByGroup(0, XAreaWarConfigs.GetArticleGroupName(groupId))
        table.insert(tab, btn)
        btnIndex = btnIndex + 1
        self.Index2Id[btnIndex] = {
            Id = groupId,
            IsGroup = true
        }
        local validCount = 0
        if hasChild then
            local firstIndex = btnIndex
            for index, article in pairs(list) do
                local articleId = article:GetId()
                local unlockArticle = XDataCenter.AreaWarManager.CheckArticleUnlock(articleId)
                if not unlockArticle then
                    goto continue
                end
                local subBtn = self:_CreateTabBtn(TabButtonType.Secondary, false, index, childCount)
                subBtn.gameObject:SetActiveEx(unlockArticle)
                subBtn:ShowReddot(XDataCenter.AreaWarManager.CheckIsNewUnlockArticle(articleId))
                subBtn:SetNameByGroup(0, XAreaWarConfigs.GetArticleTitle(articleId))
                subBtn.SubGroupIndex = firstIndex
                table.insert(tab, subBtn)
                btnIndex = btnIndex + 1
                self.Index2Id[btnIndex] = {
                    Id = articleId,
                    IsGroup = false
                }
                validCount = validCount + 1
                ::continue::
            end
        end
        local unlockGroup = XDataCenter.AreaWarManager.CheckArticleGroupUnlock(groupId) and validCount > 0
        btn:SetDisable(not unlockGroup, unlockGroup)
        btn:ShowReddot(XDataCenter.AreaWarManager.CheckIsNewUnlockArticleByGroupId(groupId))
    end
    self.TabBtnList = tab
    self.PanelTitleBtnGroup:Init(tab, function(tabIndex) self:OnSelectTab(tabIndex) end)
    
    self.PanelTitleBtnGroup:SelectIndex(XDataCenter.AreaWarManager.GetLastWarLogTabIndex())
    
    self.HideZanEffectCb = function()
        if XTool.UObjIsNil(self.Effect2) then
            return
        end
        self.Effect2.gameObject:SetActiveEx(false)
    end

    self.HideZanEffectCb()
end

function XUiAreaWarLogbuch:InitView()

end

function XUiAreaWarLogbuch:UpdateView()
    self:UpdateProgress()
    self:RefreshCoord()
end

--region   ------------------界面更新 start-------------------

--进度相关
function XUiAreaWarLogbuch:UpdateProgress()
    --章节进度
    for i, chapterId in pairs(self.ChapterList) do
        local grid = self.GridProgress[chapterId]
        if not grid then
            local ui = i == 1 and self.GridChapter or XUiHelper.Instantiate(self.GridChapter, self.PanelChapter)
            ui.gameObject.name = "Chapter" .. chapterId
            grid = XUiGridChapterProgress.New(ui)
            self.GridProgress[chapterId] = grid
        end
        grid:Refresh(chapterId)
    end
    --角色收集进度
    local unlockCount, totalRoleCount = XDataCenter.AreaWarManager.GetSpecialRoleProgress()
    self.TxtGatherRoleSu.text = string.format("%d/%d", unlockCount, totalRoleCount)

    local curExp, totalExp = XDataCenter.AreaWarManager.GetSelfPurificationProgress()
    self.TxtGatherSu.text = string.format("%d/%d", curExp, totalExp)
end

--文章相关
function XUiAreaWarLogbuch:UpdateArticle()
    self:UpdateArticleState(false)
    local cfg = self.Index2Id[self.TabIndex]
    if not cfg then
        return  
    end
    if cfg.IsGroup then
        return
    end

    local articleId = cfg.Id
    if not XDataCenter.AreaWarManager.CheckArticleUnlock(articleId) then
        return
    end
    local article = XDataCenter.AreaWarManager.GetArticleData(articleId)
    if not article then
        return
    end

    self:UpdateArticleState(true)
    self.TxtStoryTittle.text = XAreaWarConfigs.GetArticleTitle(articleId)
    
    self.TxtStoryName.text = string.format(XAreaWarConfigs.GetArticleAuthorAndTimeTips(), XAreaWarConfigs.GetArticleAuthor(articleId), 
            article:GetTimeString())
    self.TxtStoryWold.text = XAreaWarConfigs.GetArticleContent(articleId)
    self.BtnZan:SetNameByGroup(0, article:GetLikeCountString())
    local disable = XDataCenter.AreaWarManager.CheckIsLiked(articleId)
    self.BtnZan:SetDisable(disable, not disable)
    
    local storyId = XAreaWarConfigs.GetArticleStoryId(articleId)
    self.CurStoryId = storyId
    local disableStory = string.IsNilOrEmpty(storyId)
    self.BtnStory.gameObject:SetActiveEx(not disableStory)
    local background = XAreaWarConfigs.GetArticleBackground(articleId)
    if not string.IsNilOrEmpty(background) and self.RImgStory then
        self.RImgStory:SetRawImage(background)
    end
    
    XDataCenter.AreaWarManager.MarkNewUnlockArticle(articleId)
end

function XUiAreaWarLogbuch:UpdateArticleState(state)
    self.BtnStory.gameObject:SetActiveEx(state)
    self.PanelYou.gameObject:SetActiveEx(state)
end

--页签按钮
function XUiAreaWarLogbuch:RefreshTab()
    XDataCenter.AreaWarManager.RequestWarLog(self.OnRefreshCb)
end

function XUiAreaWarLogbuch:RefreshTabCb()
    for index, config in pairs(self.Index2Id) do
        if config.IsGroup then
            local unlock = XDataCenter.AreaWarManager.CheckArticleGroupUnlock(config.Id)
            self.TabBtnList[index]:SetDisable(not unlock, unlock)
        --else
        --    local unlock = XDataCenter.AreaWarManager.CheckArticleUnlock(config.Id)
        --    self.TabBtnList[index].gameObject:SetActiveEx(unlock)
        end
    end
end

--当前位置
function XUiAreaWarLogbuch:RefreshCoord()
    for _, grid in pairs(self.GridCoords) do
        grid.GameObject:SetActiveEx(false)
    end
    
    local fightBlockIds = XDataCenter.AreaWarManager.GetFightingBlockIds()
    if XTool.IsTableEmpty(fightBlockIds) then
        self.PanelCoord.gameObject:SetActiveEx(false)
        return
    end
    if #fightBlockIds > 4 then
        table.sort(fightBlockIds, self.SortBlockId)
        local list = {}
        table.move(fightBlockIds, 1, MaxShowCount, 1, list)
        fightBlockIds = list
    end
    self.PanelCoord.gameObject:SetActiveEx(true)
    for i, blockId in pairs(fightBlockIds) do
        local grid = self.GridCoords[i]
        if not grid then
            grid = {}
            local ui = i == 1 and self.GridCoord or XUiHelper.Instantiate(self.GridCoord, self.PanelCoord)
            XTool.InitUiObjectByUi(grid, ui)
            self.GridCoords[i] = grid
        end
        grid.TxtGatherSu.text = XAreaWarConfigs.GetBlockNameEn(blockId)
        grid.GameObject:SetActiveEx(true)
        grid.GameObject.name = "Block" .. tostring(blockId)
    end
end

--endregion------------------界面更新 finish------------------


--region   ------------------UI Event start-------------------

function XUiAreaWarLogbuch:OnSelectTab(tabIndex)
    if tabIndex == self.TabIndex then
        return
    end
    local btn = self.TabBtnList[tabIndex]
    if btn.ButtonState == CS.UiButtonState.Disable then
        XUiManager.TipMsg(XAreaWarConfigs.GetArticleGroupLockTip()) 
        return
    end
    self:PlayAnimation("QieHuan")
    self.TabIndex = tabIndex
    
    self:UpdateArticle()
    
    btn:ShowReddot(false)
    if btn.SubGroupIndex > 0 then
        local parent = self.TabBtnList[btn.SubGroupIndex]
        local groupId = self.Index2Id[btn.SubGroupIndex].Id
        parent:ShowReddot(XDataCenter.AreaWarManager.CheckIsNewUnlockArticleByGroupId(groupId))
    end
    XDataCenter.AreaWarManager.SaveLastWarLogTabIndex(tabIndex)
end

function XUiAreaWarLogbuch:OnBtnLikeClick()
    local cfg = self.Index2Id[self.TabIndex]
    if not cfg then
        return
    end
    if cfg.IsGroup then
        return
    end
    XDataCenter.AreaWarManager.RequestLikeArticle(cfg.Id, function() 
        self:UpdateArticle()
        if self.Effect2 then
            self.Effect2.gameObject:SetActiveEx(true)
        end
        XScheduleManager.ScheduleOnce(self.HideZanEffectCb, 500)
    end)
end

function XUiAreaWarLogbuch:OnBtnStoryClick()
    if string.IsNilOrEmpty(self.CurStoryId) then
        return
    end
    XDataCenter.MovieManager.PlayMovie(self.CurStoryId)
end

--endregion------------------UI Event finish------------------

--region   ------------------private function start-------------------


function XUiAreaWarLogbuch:_GetButtonPrefab(btnType, hasChild, index, totalNum)
    if btnType == TabButtonType.Primary then
        return hasChild and self.BtnFirstHasSnd or self.BtnFirst
    elseif btnType == TabButtonType.Secondary then
        if totalNum == 1 then
            return self.BtnSecondAll
        end

        if index == 1 then
            return self.BtnSecondTop
        elseif index == totalNum then
            return self.BtnSecondBottom
        else
            return self.BtnSecond
        end
    end
    XLog.Error(string.format("XUiAreaWarLogbuch:_GetButtonPrefab 获取按钮预制失败 btnType = %d, hasChild = %s, index = %d, totalNum = %d", 
            btnType, tostring(hasChild), index, totalNum))
end

function XUiAreaWarLogbuch:_CreateTabBtn(btnType, hasChild, index, totalNum)
    local prefab = self:_GetButtonPrefab(btnType, hasChild, index, totalNum)
    if not prefab then
        return
    end
    local btn = XUiHelper.Instantiate(prefab, self.PanelTitleBtnGroup.transform)
    btn.gameObject:SetActiveEx(true)
    return btn
end

function XUiAreaWarLogbuch:_GetSafeTabIndex(tabIndex)
    local index = tabIndex
    local btn = self.TabBtnList[tabIndex]
    if btn.ButtonState == CS.UiButtonState.Disable then
        for idx, data in pairs(self.Index2Id) do
            --使用第一篇解锁文章下标
            if not data.IsGroup then
                index = idx
                break
            end
        end
    end
    
    return index
end

--endregion------------------private function finish------------------
