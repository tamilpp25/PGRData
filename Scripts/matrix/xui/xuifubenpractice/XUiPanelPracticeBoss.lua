local XUiPanelPracticeBoss = XClass(nil, "XUiPanelPracticeBoss")
local XUguiDragProxy = CS.XUguiDragProxy
local Dropdown = CS.UnityEngine.UI.Dropdown
local XUiPracticeBasicsStage = require("XUi/XUiFubenPractice/XUiPracticeBasicsStage")
function XUiPanelPracticeBoss:Ctor(rootUi, ui)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:AddBtnsListeners()

    self.StageObjs = {}
end

function XUiPanelPracticeBoss:AddBtnsListeners()
    self.BtnActDesc.CallBack = function()
        self:OnBtnActDescClick()
    end
    self.BtnScreenWords.onValueChanged:AddListener(function(index)
        local groupId = self.ScreenTagList and self.ScreenTagList[index] or 0
        self.GroupId = groupId
        self:UpdateNodes(self.GroupId)
        
        --刷新PanelStageContent大小
        self.GameObject:SetActiveEx(false)
        self.GameObject:SetActiveEx(true)
    end)
end

function XUiPanelPracticeBoss:OnDragProxy(dragType)
    if dragType == 0 then
        self.RootUi:CloseStageDetail()
    end
end

function XUiPanelPracticeBoss:SetPanelActive(value, id, selectStageId)
    self.SelectStageId = selectStageId
    self.GameObject:SetActiveEx(false) -- 打开之前要先关一次(要不复用这个界面PanelStageContent大小会有问题)
    self.GameObject:SetActiveEx(value)
    self.PanelShaixuan.gameObject:SetActiveEx(true)
    if value then
        self:InitViews(id)
        self:ShowPanelDetail()
        self.RootUi:PlayAnimation("PanelCharacterQieHuan")

        local id = XTool.IsNumberValid(selectStageId) and self.DicStageIdToId[selectStageId]
        if id and self.BossStages[id] then
            self.BossStages[id]:OnBtnStageClick()
        end
    end
end

function XUiPanelPracticeBoss:InitViews(id)
    self:UpdateDropdown(id)
    self.CharacterDetail = XPracticeConfigs.GetPracticeChapterDetailById(id)
    self.CharacterChapter = XPracticeConfigs.GetPracticeChapterById(id)
    self.ChapterId = id

    self.CharacterChapterGO = self.PanelPracticeStages:LoadPrefab(self.CharacterDetail.PracticeContentPrefab)
    local uiObj = self.CharacterChapterGO.transform:GetComponent("UiObject")
    for i = 0, uiObj.NameList.Count - 1 do
        self[uiObj.NameList[i]] = uiObj.ObjList[i]
    end

    self.BossStages = {}
    for i = 1, #self.CharacterChapter.StageId do
        local characterStage = self.CharacterContent:Find(string.format("Stage%d", i))
        if not characterStage then
            XLog.Error("XUiPanelPracticeBoss:InitViews() 函数错误: 游戏物体CharacterContent下找不到名字为：" .. string.format("Stage%d", i) .. "的游戏物体")
            return
        end

        if not self.StageObjs[i] then
            self.StageObjs[i] = characterStage
        end
        characterStage.gameObject:SetActiveEx(true)
        local gridStageGO = characterStage:LoadPrefab(self.CharacterDetail.PracticeGridPrefab)
        self.BossStages[i] = XUiPracticeBasicsStage.New(self.RootUi, gridStageGO, self)
    end

    local indexChapter = #self.CharacterChapter.StageId + 1
    local extraStage = self.CharacterContent:Find(string.format("Stage%d", indexChapter))
    while extraStage do
        extraStage.gameObject:SetActiveEx(false)
        indexChapter = indexChapter + 1
        extraStage = self.CharacterContent:Find(string.format("Stage%d", indexChapter))
    end

    local dragProxy = self.CharacterScrollRect:GetComponent(typeof(XUguiDragProxy))
    if not dragProxy then
        dragProxy = self.CharacterScrollRect.gameObject:AddComponent(typeof(XUguiDragProxy))
    end
    dragProxy:RegisterHandler(handler(self, self.OnDragProxy))
end

function XUiPanelPracticeBoss:OnBtnActDescClick()
    XUiManager.UiFubenDialogTip(CS.XTextManager.GetText("DormDes"), XPracticeConfigs.GetPracticeDescriptionById(self.ChapterId))
end

function XUiPanelPracticeBoss:ShowPanelDetail()
    self.TxtMode.text = self.CharacterDetail.Name

    self:UpdateNodes(self.GroupId)
    self.RootUi:SwitchBg(self.ChapterId)
end

function XUiPanelPracticeBoss:UpdateNodes(groupId)
    self.Nodes = XDataCenter.PracticeManager.GetSortedChapterStage(self.ChapterId, groupId)
    self.DicStageIdToId = {}
    for i = 1, #self.Nodes do
        local node = self.Nodes[i]
        self.StageObjs[i].gameObject:SetActiveEx(true)
        self.BossStages[i]:UpdateNode(node.StageId, XPracticeConfigs.PracticeType.Boss)
        self.DicStageIdToId[node.StageId] = i
    end
    for i = #self.Nodes + 1, #self.StageObjs do
        self.StageObjs[i].gameObject:SetActiveEx(false)
    end

    if self.CharacterScrollRect then
        self.CharacterScrollRect.horizontalNormalizedPosition = 0
    end
end

function XUiPanelPracticeBoss:PlayScrollViewMove(gridTransform)
    self.CharacterScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted
    local gridRect = gridTransform:GetComponent("RectTransform")
    self.CharacterViewport.raycastTarget = false
    local diffX = gridRect.localPosition.x + self.CharacterContent.localPosition.x
    if diffX < XDataCenter.FubenMainLineManager.UiGridChapterMoveMinX or diffX > XDataCenter.FubenMainLineManager.UiGridChapterMoveMaxX then
        local tarPosX = XDataCenter.FubenMainLineManager.UiGridChapterMoveTargetX - gridRect.localPosition.x
        local tarPos = self.CharacterContent.localPosition
        tarPos.x = tarPosX
        XLuaUiManager.SetMask(true)
        XUiHelper.DoMove(self.CharacterContent, tarPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
            XLuaUiManager.SetMask(false)
        end)
    end
end

function XUiPanelPracticeBoss:OnPracticeDetailClose()
    if self.CharacterScrollRect then
        self.CharacterScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
    end
    if self.CharacterViewport then
        self.CharacterViewport.raycastTarget = true
    end
end

--下拉列表
function XUiPanelPracticeBoss:UpdateDropdown(chapterId)
    self.ScreenTagList = XPracticeConfigs.GetSimulateTrainGroupIds(chapterId)
    self.BtnScreenWords:ClearOptions()
    self.BtnScreenWords.captionText.text = CS.XTextManager.GetText("ScreenAll")
    local op = Dropdown.OptionData()
    op.text = CS.XTextManager.GetText("ScreenAll")
    self.BtnScreenWords.options:Add(op)
    for _, id in ipairs(self.ScreenTagList or {}) do
        local op = Dropdown.OptionData()
        op.text = XPracticeConfigs.GetSimulateTrainGroupGroupName(id)
        self.BtnScreenWords.options:Add(op)
    end
    self.BtnScreenWords.value = 0
    self.GroupId = 0
end

return XUiPanelPracticeBoss