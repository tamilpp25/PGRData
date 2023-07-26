local XUiTheatreSkillGrid = require("XUi/XUiTheatre/XUiTheatreSkillGrid")
local XAdventureSkill = require("XEntity/XTheatre/Adventure/XAdventureSkill")

local Select = CS.UiButtonState.Select
local Normal = CS.UiButtonState.Normal
local Disable = CS.UiButtonState.Disable

--增益的格子控件（存在2种UI）
local XUiGuideGainNowGrid = XClass(nil, "XUiGuideGainNowGrid")

--isCoreGrid：是否来自4个核心技能
function XUiGuideGainNowGrid:Ctor(ui, isCoreGrid)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.IsCoreGrid = isCoreGrid
    self.TokenManager = XDataCenter.TheatreManager.GetTokenManager()

    self:InitUi()
    self:InitSkillGrid()
    self:SetButtonCallBack()
end

function XUiGuideGainNowGrid:Init(clickCb, isCurSelectSkillFunc, gridIndex)
    self.ClickCallback = clickCb
    self.IsCurSelectSkillFunc = isCurSelectSkillFunc
    self.GridIndex = gridIndex
end

function XUiGuideGainNowGrid:SetButtonCallBack()
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnGridBtnClick)
    XUiHelper.RegisterClickEvent(self, self.GridBtn, self.OnGridBtnClick)
end

function XUiGuideGainNowGrid:InitUi()
    if self.GridBuff then
        self.SkillGrid = XUiTheatreSkillGrid.New(self.GridBuff)
    end
    self.GridBuffByNormal = XUiHelper.TryGetComponent(self.Transform, "ImgNormal/GridBuff")
    self.GridBuffByPress = XUiHelper.TryGetComponent(self.Transform, "ImgPress/GridBuff")
    self.GridBuffBySelect = XUiHelper.TryGetComponent(self.Transform, "ImgSelect/GridBuff")
    self.GridBuffByDisable = XUiHelper.TryGetComponent(self.Transform, "ImgDisable/GridBuff")
    self.GridBtn = self.GameObject:GetComponent("XUiButton")
end

function XUiGuideGainNowGrid:InitSkillGrid()
    self.SkillGrids = {}
    if self.GridBuffByNormal then
        table.insert(self.SkillGrids, XUiTheatreSkillGrid.New(self.GridBuffByNormal))
    end
    if self.GridBuffByPress then
        table.insert(self.SkillGrids, XUiTheatreSkillGrid.New(self.GridBuffByPress))
    end
    if self.GridBuffBySelect then
        table.insert(self.SkillGrids, XUiTheatreSkillGrid.New(self.GridBuffBySelect))
    end
    if self.GridBuffByDisable then
        table.insert(self.SkillGrids, XUiTheatreSkillGrid.New(self.GridBuffByDisable))
    end
end

--skill：XAdventureSkill
--isForceShowDefaultName：是否强制显示默认技能名
function XUiGuideGainNowGrid:SetData(skill, isForceShowDefaultName)
    self.Skill = skill
    local isSelect = self.IsCurSelectSkillFunc(skill)
    if self.ImgSelect then
        self.ImgSelect.gameObject:SetActiveEx(isSelect)
    end

    local theatreSkillId = skill and skill:GetId()
    local isActive = theatreSkillId and self.TokenManager:IsActiveSkill(theatreSkillId)
    if self.ImgNormalLock then
        self.ImgNormalLock.gameObject:SetActiveEx(not isActive)
    end

    local gridIndex = self.GridIndex
    local isShowLevelOne = not skill and gridIndex  --未激活的技能显示等级1
    if self.SkillGrid then
        self.SkillGrid:SetData(skill, nil, gridIndex)
        if isShowLevelOne then
            self.SkillGrid:SetLevel(1)
        end
    end

    for _, skillGrid in ipairs(self.SkillGrids) do
        skillGrid:SetData(skill, nil, gridIndex)
        if isShowLevelOne then
            skillGrid:SetLevel(1)
        end
    end

    local name = (not isForceShowDefaultName and skill and skill:GetName()) or XTheatreConfigs.GetClientConfig("SkillPosDesc", gridIndex)
    self.GridBtn:SetName(name or "")

    self.GridBtn:SetButtonState(isSelect and Select or self:GetDefaultBtnState())
end

function XUiGuideGainNowGrid:OnGridBtnClick()
    local skill = self:GetSkill()
    if self.ClickCallback then
        self.ClickCallback(skill, self, self.IsCoreGrid)
    end
    if self.ImgSelect then
        self.ImgSelect.gameObject:SetActiveEx(skill and true or false)
    end
    self.GridBtn:SetButtonState(skill and Select or Normal)
end

function XUiGuideGainNowGrid:GetDefaultBtnState()
    local skill = self.Skill
    if not skill then
        return Normal
    end

    local theatreSkillId = skill:GetId()
    return self.TokenManager:IsActiveSkill(theatreSkillId) and Normal or Disable
end

function XUiGuideGainNowGrid:CancelSelect()
    if self.ImgSelect then
        self.ImgSelect.gameObject:SetActiveEx(false)
    end
    self.GridBtn:SetButtonState(self:GetDefaultBtnState())
end

function XUiGuideGainNowGrid:GetSkill()
    return self.Skill
end

return XUiGuideGainNowGrid