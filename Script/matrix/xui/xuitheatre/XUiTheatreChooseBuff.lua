
--######################## XUiBuffGrid ########################
local XUiTheatreSkillGrid = require("XUi/XUiTheatre/XUiTheatreSkillGrid")
local XUiBuffGrid = XClass(nil, "XUiBuffGrid")

function XUiBuffGrid:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
end

-- skill : XAdventureSkill
function XUiBuffGrid:SetData(skill, selectSkillId)
    self.TxtName.text = skill:GetName()
    self.TxtDetail.text = skill:GetDesc()
    -- 等级信息显示
    local operationType, lastSkill = skill:GetSkillOperationType()
    local showLevelInfo = operationType ~= XTheatreConfigs.SkillOperationType.AddBuff
    local isLevelUp = operationType == XTheatreConfigs.SkillOperationType.LevelUp
    if showLevelInfo then
        self.TxtLevelDetail.text = skill:GetLevelDesc()
        self.TxtCurrentLevel.text = lastSkill == skill and 1 or lastSkill:GetCurrentLevel()
        self.TxtNextLevel.text = skill:GetCurrentLevel()
    end
    self.ImgUp.gameObject:SetActiveEx(showLevelInfo and isLevelUp)
    self.TxtLevelDetail.gameObject:SetActiveEx(showLevelInfo)
    self.TxtCurrentLevel.gameObject:SetActiveEx(showLevelInfo)
    self.TxtNextLevel.gameObject:SetActiveEx(showLevelInfo and isLevelUp)
    -- 显示标签 
    self.GridTabAdd.gameObject:SetActiveEx(operationType == XTheatreConfigs.SkillOperationType.AddBuff)
    self.GridTabLevelUp.gameObject:SetActiveEx(operationType == XTheatreConfigs.SkillOperationType.LevelUp)
    self.GridTabReplace.gameObject:SetActiveEx(operationType == XTheatreConfigs.SkillOperationType.Replace)
    XUiTheatreSkillGrid.New(self.GridSkill):SetData(skill, true)
    XUiHelper.MarkLayoutForRebuild(self.PanelBuffDesc1)
    self.PanelBuffDesc1.gameObject:SetActiveEx(operationType ~= XTheatreConfigs.SkillOperationType.AddBuff)
    self:SetSelectStatus(skill:GetId() == selectSkillId)
end

function XUiBuffGrid:SetSelectStatus(value)
    if value then
        self.BtnSelf:SetButtonState(CS.UiButtonState.Select)
    else
        self.BtnSelf:SetButtonState(CS.UiButtonState.Normal)
    end
end

--######################## XUiTheatreChooseBuff ########################
local XAdventureSkill = require("XEntity/XTheatre/Adventure/XAdventureSkill")
local XUiTheatreChooseBuff = XLuaUiManager.Register(XLuaUi, "UiTheatreChooseBuff")

function XUiTheatreChooseBuff:OnAwake()
    self.TheatreManager = XDataCenter.TheatreManager
    self.AdventureManager = self.TheatreManager.GetCurrentAdventureManager()
    self.CurrentChapter = self.AdventureManager:GetCurrentChapter()
    -- buff列表
    self.DynamicTable = XDynamicTableNormal.New(self.PanelList)
    self.DynamicTable:SetProxy(XUiBuffGrid)
    self.DynamicTable:SetDelegate(self)
    self.GridBuff.gameObject:SetActiveEx(false)
    -- 技能 XAdventureSkill
    self.Skills = nil
    -- 当前选择的技能id
    self.CurrentSkillId = nil
    self.Callback = nil
    -- 注册资源面板
    XUiHelper.NewPanelActivityAssetSafe(self.TheatreManager.GetAdventureAssetItemIds(), self.PanelAssetitems, self)
    self:RegisterUiEvents()
    -- 隐藏头部信息
    self.BtnBack.gameObject:SetActiveEx(false)
    self.BtnMainUi.gameObject:SetActiveEx(false)
    self.BtnHelp.gameObject:SetActiveEx(false)
    self.PanelAssetitems.gameObject:SetActiveEx(false)
end

function XUiTheatreChooseBuff:OnStart(skillIds, callback)
    self.Callback = callback
    skillIds = skillIds or self.CurrentChapter:GetWaitSelectableSkillIds()
    self.Skills = {}
    for _, id in ipairs(skillIds) do
        table.insert(self.Skills, XAdventureSkill.New(id))
    end
    self:RefreshSkillList()
    -- 势力图标
    self.RImgPowerIcon:SetRawImage(self.Skills[1]:GetPowerIcon())
    -- 势力标题
    self.TxtPowerTitle.text = self.Skills[1]:GetPowerTitle()
    self:UpdateSceneUrl()
    self:UpdateBg()
end

--######################## 私有方法 ########################

function XUiTheatreChooseBuff:RegisterUiEvents()
    self.BtnMainUi.CallBack = function() XLuaUiManager.RunMain() end
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.Close)
    XUiHelper.RegisterHelpButton(self.BtnHelp, self.TheatreManager.GetHelpKey())
    XUiHelper.RegisterClickEvent(self, self.BtnDetail, self.OnBtnDetailClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnConfirm, self.OnBtnConfirmClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnSkip, self.OnBtnSkipClicked)
end

function XUiTheatreChooseBuff:OnBtnSkipClicked()
    self.AdventureManager:RequestSkipSelectSkill(function()
        self:Close()
    end)
end

function XUiTheatreChooseBuff:OnBtnDetailClicked()
    XLuaUiManager.Open("UiTheatreFieldGuide", nil, nil, nil, nil, nil, true)
end

function XUiTheatreChooseBuff:OnBtnConfirmClicked()
    if self.CurrentSkillId == nil then
        XUiManager.TipErrorWithKey("TheatreNotSelectSkill")
        return
    end
    local selectSkill = nil
    for _, skill in pairs(self.DynamicTable.DataSource) do
        if skill:GetId() == self.CurrentSkillId then
            selectSkill = skill
            break
        end
    end
    RunAsyn(function()
        local operationType, fromSkill = selectSkill:GetSkillOperationType()
        local signalCode, isOK = nil, true
        if operationType == XTheatreConfigs.SkillOperationType.Replace then
            XLuaUiManager.Open("UiTheatreReplaceTips", fromSkill, selectSkill)
            signalCode, isOK = XLuaUiManager.AwaitSignal("UiTheatreReplaceTips", "Close", self)
            if signalCode ~= XSignalCode.SUCCESS then return end
        end
        if isOK then
            self.AdventureManager:RequestSelectSkill(self.CurrentSkillId, operationType, fromSkill
            , function()
                XUiManager.TipMsg(XUiHelper.GetText("TheatreGetSkillTip"))
                self:Close()
            end)
        end
    end)
end

function XUiTheatreChooseBuff:RefreshSkillList()
    self.DynamicTable:SetDataSource(self.Skills)
    self.DynamicTable:ReloadDataSync(1)
end

function XUiTheatreChooseBuff:OnDynamicTableEvent(event, index, grid)
    local skill = self.DynamicTable.DataSource[index]
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetData(skill, self.CurrentSkillId)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then 
        for _, value in pairs(self.DynamicTable:GetGrids()) do
            value:SetSelectStatus(false)
        end
        grid:SetSelectStatus(true)
        self.CurrentSkillId = skill:GetId()
    end
end

function XUiTheatreChooseBuff:Close()
    self.Super.Close(self)
    if self.Callback then self.Callback() end
end

function XUiTheatreChooseBuff:UpdateSceneUrl()
    XDataCenter.TheatreManager.UpdateSceneUrl(self)
    XScheduleManager.ScheduleOnce(function()
        XDataCenter.TheatreManager.ShowRoleModelCamera(self, "FarCameraChooseBuff", "NearCameraChooseBuff", true)
    end, 1)
end

function XUiTheatreChooseBuff:UpdateBg()
    local chapterId = self.CurrentChapter:GetCurrentChapterId()
    if self.RImgBgA then
        local bgA = XTheatreConfigs.GetChapterBgA(chapterId)
        self.RImgBgA:SetRawImage(bgA)
    end
    if self.RImgBgB then
        local bgB = XTheatreConfigs.GetChapterBgB(chapterId)
        self.RImgBgB:SetRawImage(bgB)
    end
end

return XUiTheatreChooseBuff