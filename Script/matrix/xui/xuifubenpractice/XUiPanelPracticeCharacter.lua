local XUiPanelPracticeCharacter = XClass(nil, "XUiPanelPracticeCharacter")
local XUiGuidPracticeCharacterChapter = require("XUi/XUiFubenPractice/XUiGuidPracticeCharacterChapter")
local XUguiDragProxy = CS.XUguiDragProxy
local UiGridPracticeCharacterMoveTargetX = CS.XGame.ClientConfig:GetInt("UiGridPracticeCharacterMoveTargetX")
local UiGridPracticeCharacterMoveMinX = CS.XGame.ClientConfig:GetInt("UiGridPracticeCharacterMoveMinX")
local UiGridPracticeCharacterMoveMaxX = CS.XGame.ClientConfig:GetInt("UiGridPracticeCharacterMoveMaxX")

function XUiPanelPracticeCharacter:Ctor(rootUi, ui)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:AddBtnsListeners()
end

function XUiPanelPracticeCharacter:AddBtnsListeners()
    self.BtnActDesc.CallBack = function() self:OnBtnActDescClick() end
end

function XUiPanelPracticeCharacter:InitViews(id, selectGroupId)
    self.CharacterDetail = XPracticeConfigs.GetPracticeChapterDetailById(id)
    self.CharacterChapter = XPracticeConfigs.GetPracticeChapterById(id)
    if self.CharacterChapters and #self.CharacterChapters > 0 then
        self:UpdateNodesScroll()
    end
    self.Id = id
    self.SelectGroupId = selectGroupId
    self.CharacterChapterGO = self.PanelPrequelStages:LoadPrefab(self.CharacterDetail.PracticeContentPrefab)
    local uiObj = self.CharacterChapterGO.transform:GetComponent("UiObject")
    for i = 0, uiObj.NameList.Count - 1 do
        self[uiObj.NameList[i]] = uiObj.ObjList[i]
    end

    self.CharacterChapters = {}
    for i = 1, #self.CharacterChapter.Groups do
        local characterStage = self.CharacterContent:Find(string.format("Stage%d", i))
        if not characterStage then
            XLog.Error("XUiPanelPracticeChapter:InitViews() 函数错误: 游戏物体CharacterContent下找不到名字为：" .. string.format("Stage%d", i) .. "的游戏物体")
            return
        end
        characterStage.gameObject:SetActiveEx(true)
        local gridStageGO = characterStage:LoadPrefab(self.CharacterDetail.PracticeGridPrefab)
        self.CharacterChapters[i] = XUiGuidPracticeCharacterChapter.New(self.RootUi, gridStageGO, self)
    end

    local indexChapter = #self.CharacterChapter.Groups + 1
    local extraStage = self.CharacterContent:Find(string.format("Stage%d", indexChapter))
    while extraStage do
        extraStage.gameObject:SetActive(false)
        indexChapter = indexChapter + 1
        extraStage = self.CharacterContent:Find(string.format("Stage%d", indexChapter))
    end

    local dragProxy = self.CharacterScrollRect:GetComponent(typeof(XUguiDragProxy))
    if not dragProxy then
        dragProxy = self.CharacterScrollRect.gameObject:AddComponent(typeof(XUguiDragProxy))
    end
    dragProxy:RegisterHandler(handler(self, self.OnDragProxy))
    
    -- 根据当前分辨率计算滑动边界
    local halfScreenWidth = self.CharacterViewport.transform.rect.width / 2
    UiGridPracticeCharacterMoveMinX = halfScreenWidth
    UiGridPracticeCharacterMoveMaxX = self.CharacterContent.transform.sizeDelta.x - halfScreenWidth
end

function XUiPanelPracticeCharacter:OnDragProxy(dragType)
    if dragType == 0 then
        self.RootUi:CloseStageDetail()
    end
end

function XUiPanelPracticeCharacter:SetPanelActive(value, id, selectGroupId)
    self.GameObject:SetActiveEx(false) -- 打开之前要先关一次(要不复用这个界面PanelStageContent大小会有问题)
    self.GameObject:SetActive(value)
    if value then
        self:InitViews(id, selectGroupId)
        self:ShowPanelDetail()
        self.RootUi:PlayAnimation("PanelCharacterQieHuan")
    end
end

function XUiPanelPracticeCharacter:OnBtnActDescClick()
    XUiManager.UiFubenDialogTip(CS.XTextManager.GetText("DormDes"), XPracticeConfigs.GetPracticeDescriptionById(self.Id))
end

function XUiPanelPracticeCharacter:ShowPanelDetail()
    self.TxtMode.text = self.CharacterDetail.Name

    self:UpdateNodes()
    self.RootUi:SwitchBg(self.Id)
end

function XUiPanelPracticeCharacter:UpdateNodes()
    self.Nodes = XDataCenter.PracticeManager.GetSortedChapterById(self.Id)

    for i = 1, #self.Nodes do
        local node = self.Nodes[i]
        self.CharacterChapters[i].GameObject:SetActive(true)
        self.CharacterChapters[i]:UpdateNode(node.GroupId)
        if self.SelectGroupId and self.SelectGroupId == node.GroupId then
            -- 点击对应的教学，使其居中
            self:PlayScrollViewMove(self.CharacterChapters[i].Transform.parent)
        end
    end

    for i = #self.Nodes + 1, #self.CharacterChapters do
        self.CharacterChapters[i].GameObject:SetActive(false)
    end

    if self.CharacterScrollRect then
        self.CharacterScrollRect.horizontalNormalizedPosition = 0
    end
end

function XUiPanelPracticeCharacter:UpdateNodesScroll()
    self.Nodes = XDataCenter.PracticeManager.GetSortedChapterById(self.Id)
    for i = 1, #self.Nodes do
        local node = self.Nodes[i]
        self.CharacterChapters[i]:UpdateNodeScroll(node.GroupId)
    end
end

function XUiPanelPracticeCharacter:PlayScrollViewMove(gridTransform)
    self.CharacterScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted
    local gridRect = gridTransform:GetComponent("RectTransform")
    self.CharacterViewport.raycastTarget = false

    -- 计算相对位移坐标
    local tarPosX = UiGridPracticeCharacterMoveTargetX - gridRect.localPosition.x
    local tarPos = self.CharacterContent.localPosition
    tarPos.x = tarPosX
    -- 以当前分辨率屏幕中间为界，处于极左和极右部分的元素不进行居中位移
    -- 此处理基于Content为左对齐布局及需要居中。若父节点布局改变，则当前算法可能需要调整
    if gridRect.localPosition.x > UiGridPracticeCharacterMoveMinX and gridRect.localPosition.x < UiGridPracticeCharacterMoveMaxX then
        XLuaUiManager.SetMask(true)
        XUiHelper.DoMove(self.CharacterContent, tarPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
            XLuaUiManager.SetMask(false)
        end)
    end
end

function XUiPanelPracticeCharacter:OnPracticeDetailClose()
    self.CharacterScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
    self.CharacterViewport.raycastTarget = true
end

return XUiPanelPracticeCharacter