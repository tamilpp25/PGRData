local XUiGridMonsterCombatChapter = require("XUi/XUiMonsterCombat/XUiGridMonsterCombatChapter")
---@class XUiMonsterCombatChapter : XLuaUi
---@field CurChapterGrid XUiGridMonsterCombatChapter
local XUiMonsterCombatChapter = XLuaUiManager.Register(XLuaUi, "UiMonsterCombatChapter")

function XUiMonsterCombatChapter:OnAwake()
    self:RegisterUiEvents()
    -- 货币Ui隐藏
    self.PanelSpecialTool.gameObject:SetActiveEx(false)
    self.PanelTanChuang.gameObject:SetActiveEx(false)
    self.GridMoster.gameObject:SetActiveEx(false)
end

function XUiMonsterCombatChapter:OnStart(chapterId)
    self.ChapterId = chapterId
    self.ChapterEntity = XDataCenter.MonsterCombatManager.GetChapterEntity(chapterId)
    self:InitChapterView()
    -- 开启自动关闭检查
    local endTime = XDataCenter.MonsterCombatManager.GetActivityEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            XDataCenter.MonsterCombatManager.OnActivityEnd(true)
        end
    end)
end

function XUiMonsterCombatChapter:OnEnable()
    self.Super.OnEnable(self)
    self:UpdateCurrentChapter()
    self:GoToLastPassStage()
end

function XUiMonsterCombatChapter:OnGetEvents()
    return {
        XEventId.EVENT_FUBEN_ENTERFIGHT,
    }
end

function XUiMonsterCombatChapter:OnNotify(event, ...)
    if event == XEventId.EVENT_FUBEN_ENTERFIGHT then
        self:EnterFight(...)
    end
end

function XUiMonsterCombatChapter:OnDisable()
    self.Super.OnDisable(self)
    self:CloseChildUi(XMonsterCombatConfigs.StageDetailUiName)
    if self.CurChapterGrid then
        self.CurChapterGrid:CancelSelect()
        self.CurChapterGrid:OnDisable()
    end
end

function XUiMonsterCombatChapter:InitChapterView()
    -- 章节标题
    self.TxtTitle.text = self.ChapterEntity:GetName()
    -- 章节背景
    self.BgCommon:SetRawImage(self.ChapterEntity:GetBgIcon())
    -- 章节描述
    self.TxtDesc.text = self.ChapterEntity:GetDescription()
    -- 解锁怪物
    local unlockMonsterIds = self.ChapterEntity:GetUnlockMonsterIds()
    for i, monsterId in pairs(unlockMonsterIds) do
        local go = i == 1 and self.GridMoster or XUiHelper.Instantiate(self.GridMoster, self.PanelMoster)
        local grid = XTool.InitUiObjectByUi({}, go)
        local monsterEntity = XDataCenter.MonsterCombatManager.GetMonsterEntity(monsterId)
        grid.RImgIcon:SetRawImage(monsterEntity:GetAchieveIcon())
        grid.GameObject:SetActiveEx(true)
    end
end

function XUiMonsterCombatChapter:UpdateCurrentChapter()
    local data = {
        ChapterId = self.ChapterId,
        HideStageDetail = handler(self, self.HideStageDetail),
        ShowStageDetail = handler(self, self.ShowStageDetail),
    }
    if not self.CurChapterGrid then
        local prefabName = self.ChapterEntity:GetPrefabName()
        local gameObject = self.PanelChapter:LoadPrefab(prefabName)
        if gameObject == nil or not gameObject:Exist() then
            return
        end
        self.CurChapterGrid = XUiGridMonsterCombatChapter.New(gameObject, self)
    end
    self.CurChapterGrid:Refresh(data)
    self.CurChapterGrid:Show()
end

function XUiMonsterCombatChapter:HideStageDetail()
    if not self.CurStageId then
        return
    end
    local childUiObj = self:FindChildUiObj(XMonsterCombatConfigs.StageDetailUiName)
    if childUiObj then
        childUiObj:Hide()
    end
end

function XUiMonsterCombatChapter:ShowStageDetail(stageId)
    self.CurStageId = stageId
    if not XLuaUiManager.IsUiShow(XMonsterCombatConfigs.StageDetailUiName) then
        self:OpenOneChildUi(XMonsterCombatConfigs.StageDetailUiName, self)
    end
    self:FindChildUiObj(XMonsterCombatConfigs.StageDetailUiName):Refresh(stageId)
end

function XUiMonsterCombatChapter:OnCloseStageDetail()
    if XLuaUiManager.IsUiShow(XMonsterCombatConfigs.StageDetailUiName) then
        if self.CurChapterGrid then
            self.CurChapterGrid:CancelSelect()
        end
        return true
    end
    return false
end

function XUiMonsterCombatChapter:GoToLastPassStage()
    if self.CurChapterGrid then
        local index = self.ChapterEntity:GetUnPassedStageIndex()
        self.CurChapterGrid:GoToStage(index)
    end
end

-- 进入编队界面
function XUiMonsterCombatChapter:EnterFight(stage)
    if not XDataCenter.FubenManager.CheckPreFight(stage) then
        return
    end

    local monsterTeam = self.ChapterEntity:GetMonsterTeam()
    XLuaUiManager.Open("UiMonsterCombatBattlePrepare", stage.StageId, monsterTeam, require("XUi/XUiMonsterCombat/Battle/XUiMonsterCombatBattleRoleRoom"))
end

function XUiMonsterCombatChapter:PanelChapterDescActive(isActive)
    if isActive then
        XDataCenter.UiPcManager.OnUiEnable(self, "OnBtnTanchuangBackClick")
    else
        XDataCenter.UiPcManager.OnUiDisableAbandoned(true, self)
    end
    self.PanelTanChuang.gameObject:SetActiveEx(isActive)
end

function XUiMonsterCombatChapter:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
    XUiHelper.RegisterClickEvent(self, self.BtnChapterDesc, self.OnBtnChapterDescClick)
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangBack, self.OnBtnTanchuangBackClick)
end

function XUiMonsterCombatChapter:OnBtnBackClick()
    if self:OnCloseStageDetail() then
        return
    end
    self:Close()
end

function XUiMonsterCombatChapter:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiMonsterCombatChapter:OnBtnChapterDescClick()
    if self:OnCloseStageDetail() then
        return
    end
    self:PanelChapterDescActive(true)
end

function XUiMonsterCombatChapter:OnBtnTanchuangBackClick()
    self:PanelChapterDescActive(false)
end

return XUiMonsterCombatChapter