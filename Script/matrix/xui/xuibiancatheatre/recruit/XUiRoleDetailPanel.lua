---------------羁绊节点---------------
local XUiNodeElement = XClass(nil, "XUiNodeElement")

function XUiNodeElement:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.GameObject:SetActiveEx(true)
    self.ImgKuang = XUiHelper.TryGetComponent(self.Transform, "ImgKuang")
end

---刷新招募/腐化/升星界面羁绊变化Ui Grid
---@param combo XTheatreCombo
---@param isNextLevel boolean 是否是下一级
---@param starLevel number 现阶段该羁绊星级
---@param isDecay boolean 现阶段是否处于腐化券中
---@param isRoleDecaied boolean 该角色是否被腐化
function XUiNodeElement:Refresh(combo, isNextLevel, starLevel, isDecay, isRoleDecaied)
    self.Combo = combo  --XTheatreCombo
    --羁绊总星级
    local curStarLevel = combo:GetTotalRank()
    curStarLevel = isNextLevel and curStarLevel + 1 or curStarLevel
    self.TextStar.text = "+" .. curStarLevel
    --增加的羁绊星级
    self.TxtAddStar.text = "+" .. (isNextLevel and starLevel + 1 or starLevel)
    --图标
    self.Icon:SetRawImage(combo:GetIconPath())
    --名字
    self.TextName.text = combo:GetName()
    --品质颜色
    local color = combo:GetQualityColor(isNextLevel)
    if color then
        self.TextName.color = color
        self.Bg.color = color
    end
    if self.ImgKuang then
        self.ImgKuang.gameObject:SetActiveEx(combo:GetComboIsHaveDecay() and ((isNextLevel and isDecay) or isRoleDecaied))
    end
end


---------------羁绊格子---------------
local XUiFettersGrid = XClass(nil, "XUiFettersGrid")

function XUiFettersGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:Init()
end

function XUiFettersGrid:Init()
    local nodeElement = XUiHelper.TryGetComponent(self.Transform, "GridFetters/GridFettersNode/NodeElement")
    nodeElement.gameObject:SetActiveEx(false)
    nodeElement = XUiHelper.TryGetComponent(self.Transform, "GridFetters2/GridFettersNode/NodeElement")
    nodeElement.gameObject:SetActiveEx(false)

    self.CurStarLevelNode = XUiNodeElement.New(XUiHelper.TryGetComponent(self.Transform, "GridFetters/GridFettersNode/NodeTeam"))
    self.NextStarLevelNode = XUiNodeElement.New(XUiHelper.TryGetComponent(self.Transform, "GridFetters2/GridFettersNode/NodeTeam"))

    local curStarButton = XUiHelper.TryGetComponent(self.Transform, "GridFetters/GridFettersNode", "XUiButton")
    local nextStarButton = XUiHelper.TryGetComponent(self.Transform, "GridFetters2/GridFettersNode", "XUiButton")
    XUiHelper.RegisterClickEvent(self, curStarButton, function() self:OnButtonClick() end)
    XUiHelper.RegisterClickEvent(self, nextStarButton, function() self:OnButtonClick() end)
end

---刷新招募/腐化/升星界面羁绊变化面板
---@param childComboId number BiancaTheatreChildCombo表的Id
---@param starLevel number
---@param isDecay boolean 现阶段是否处于腐化券中
---@param isRoleDecaied boolean 该角色是否被腐化
function XUiFettersGrid:Refresh(childComboId, starLevel, isDecay, isRoleDecaied)
    local combo = XDataCenter.BiancaTheatreManager.GetComboList():GetComboByComboId(childComboId)
    if not combo then
        self.GameObject:SetActiveEx(false)
        return
    end

    self.Combo = combo
    self.CurStarLevelNode:Refresh(combo, false, starLevel, false, isRoleDecaied)
    self.NextStarLevelNode:Refresh(combo, true, starLevel, isDecay)
    self.GameObject:SetActiveEx(true)
end

function XUiFettersGrid:OnButtonClick()
    XLuaUiManager.Open("UiBiancaTheatreComboTips", self.Combo)
end


------------------招募界面：角色详情---------------------
local XUiRoleDetailPanel = XClass(nil, "XUiRoleDetailPanel")
local PANEL_FETTERS_COUNT = 4   --可显示的羁绊面板的数量

function XUiRoleDetailPanel:Ctor(ui, rootUi, closeCb)
    self.Transform = ui.transform
    self.GameObject = ui.gameObject
    self.RootUi = rootUi
    self.CloseCallback = closeCb
    XTool.InitUiObject(self)

    self.AdventureManager = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager()
    self:InitPanelFettersList()
    self:InitBtn()
    self.GameObject:SetActiveEx(false)
end

function XUiRoleDetailPanel:InitPanelFettersList()
    self.PanelFettersList = {}
    for i = 1, PANEL_FETTERS_COUNT do
        self.PanelFettersList[i] = XUiFettersGrid.New(self["PanelFetters" .. i])
    end
end

function XUiRoleDetailPanel:InitBtn()
    XUiHelper.RegisterClickEvent(self, self.BtnRecruit, self.OnBtnRecruitClick)
    XUiHelper.RegisterClickEvent(self, self.BtnCareerTips, self.OnBtnCareerTipsClick)
end

function XUiRoleDetailPanel:Refresh(adventureRole, isRecruitRole, isShowRankUp, isDecay)
    self.AdventureRole = adventureRole  --后端数据的角色对象
    self.IsRecruitRole = isRecruitRole  --是否已招募的角色
    self.IsShowRankUp = isShowRankUp    --按钮是否显示升星
    self.IsDecay = isDecay              --是否腐化
    
    --角色名
    self.TxtName.text = adventureRole:GetRoleNotFullName()
    --型号
    self.TxtNameOther.text = adventureRole:GetCharacterTradeName()
    --职业类型
    local jobType = adventureRole:GetCareerType()
    self.RImgTypeIcon:SetRawImage(XMVCA.XCharacter:GetNpcTypeIcon(jobType))
    --当前羁绊星级
    local curRecruitRole = self.AdventureManager:GetRoleByCharacterId(adventureRole:GetBaseId())
    local curRoleLevel = curRecruitRole and curRecruitRole:GetLevel() or 0
    self.TxtLevel.text = adventureRole:GetLevel() + curRoleLevel
    --按钮名：1：招募，2：升星
    local btnNameIndex = not isShowRankUp and not isDecay and 1 or isDecay and 3 or 2
    self.BtnRecruit:SetName(XBiancaTheatreConfigs.GetClientConfig("BtnRecruitName", btnNameIndex))
    --文本标题
    self.TextTitle.text = XBiancaTheatreConfigs.GetClientConfig("RecruitTipsTitle", btnNameIndex)
    if self.Text then
        self.Text.text = XBiancaTheatreConfigs.GetClientConfig("RecruitDecayTip")
    end

    self:UpdateElement()
    local isRoleDecaied = self.AdventureManager:CheckRoleIsDecayByCharacterId(adventureRole:GetBaseId())
    self:UpdateCurCombo(adventureRole:GetCharacterComboIds(), curRoleLevel, isRoleDecaied)
end

--刷新当前羁绊
function XUiRoleDetailPanel:UpdateCurCombo(childComboIds, curRoleLevel, isRoleDecaied)
    local panelFetter
    for i, childComboId in ipairs(childComboIds) do
        panelFetter = self.PanelFettersList[i]
        if panelFetter then
            panelFetter:Refresh(childComboId, curRoleLevel, self.IsDecay, isRoleDecaied)
        end
    end
    for i = #childComboIds + 1, PANEL_FETTERS_COUNT do
        panelFetter = self.PanelFettersList[i]
        if panelFetter then
            panelFetter.GameObject:SetActiveEx(false)
        end
    end
end

--刷新能量（属性）
function XUiRoleDetailPanel:UpdateElement()
    local elementList = self.AdventureRole:GetElementList()
    for i = 1, 3 do
        local rImg = self["RImgCharElement" .. i]
        if elementList[i] then
            rImg.gameObject:SetActive(true)
            rImg:SetRawImage(XBiancaTheatreConfigs.GetCharacterElementsIcon(elementList[i]))
        else
            rImg.gameObject:SetActive(false)
        end
    end
end

--招募/升星/腐化
function XUiRoleDetailPanel:OnBtnRecruitClick()
    local adventureManager = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager()
    local adventureChapter = adventureManager:GetCurrentChapter()
    local reqCallback = function()
        if self.CloseCallback then
            self.CloseCallback()
        end
    end
    adventureChapter:RequestRecruitRole(self.AdventureRole:GetId(), reqCallback, self.IsDecay)
end

function XUiRoleDetailPanel:OnBtnCareerTipsClick()
    XLuaUiManager.Open("UiCharacterAttributeDetail", self.AdventureRole:GetCharacterId())
end

return XUiRoleDetailPanel