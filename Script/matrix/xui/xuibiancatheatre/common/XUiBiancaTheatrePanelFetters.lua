---------------羁绊节点---------------
local XUiNodeElement = XClass(nil, "XUiNodeElement")
local MAX_PHASE_COUNT = 4   --可显示的最大阶级

function XUiNodeElement:Ctor(ui)
    self.Gameobject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:Init()
    self.Gameobject:SetActiveEx(true)
end

function XUiNodeElement:Init()
    self.TextNoneList = {}
    self.TextUpList = {}
    for i = 1, MAX_PHASE_COUNT do
        local panelPhase = self["PanelPhase" .. i]
        if panelPhase then
            self.TextNoneList[i] = XUiHelper.TryGetComponent(panelPhase, "TextNone", "Text")
            self.TextUpList[i] = XUiHelper.TryGetComponent(panelPhase, "TextUp", "Text")
        end
    end
end

--combo: XTheatreCombo
function XUiNodeElement:Refresh(combo)
    self.Combo = combo
    --羁绊总星级
    local curStarLevel = combo:GetTotalRank()
    self.TextStar.text = curStarLevel
    --图标
    self.ImgIcon:SetRawImage(combo:GetIconPath())
    --名字
    self.TxtName.text = combo:GetName()
    --名字和背景颜色
    local color = combo:GetQualityColor()
    if color then
        self.TxtName.color = color
        self.ImgTextBg.color = color
        self.ImgIconBg.color = color
    end
    --羁绊层数
    local phase = combo:GetPhaseNum()
    local isShowTextUp = false  --只显示当前最高等级的
    for i = phase, 1, -1 do
        if not isShowTextUp and curStarLevel >= combo:GetConditionLevel(i) then
            isShowTextUp = true
            self:SetPhaseData(i, true)
        else
            self:SetPhaseData(i, false)
        end
        self:SetPanelPhaseActive(i, true)
    end
    for i = phase + 1, MAX_PHASE_COUNT do
        self:SetPanelPhaseActive(i, false)
    end
end

function XUiNodeElement:SetEffectActive(isActive)
    if isActive then
        self.Effect.gameObject:SetActiveEx(false)
    end
    self.Effect.gameObject:SetActiveEx(isActive)
end

function XUiNodeElement:SetPhaseData(index, isShowTextUp)
    local level = self.Combo:GetConditionLevel(index)
    local textNone = self.TextNoneList[index]
    local textUp = self.TextUpList[index]
    if textNone then
        textNone.text = level
        textNone.gameObject:SetActiveEx(not isShowTextUp)
    end
    if textUp then
        textUp.text = level
        textUp.gameObject:SetActiveEx(isShowTextUp)
    end
end

function XUiNodeElement:SetPanelPhaseActive(i, isActive)
    if self["PanelPhase" .. i] then
        self["PanelPhase" .. i].gameObject:SetActiveEx(isActive)
    end
end


---------------羁绊格子---------------
local XUiFettersGrid = XClass(nil, "XUiFettersGrid")

function XUiFettersGrid:Ctor(ui, btnFetters)
    self.Gameobject = ui.gameObject
    self.Transform = ui.transform
    self.BtnFetters = btnFetters and btnFetters:GetComponent("XUiButton")
    XTool.InitUiObject(self)
    if self.BtnFetters then
        XUiHelper.RegisterClickEvent(self, self.BtnFetters, self.OnBtnFettersClick)
    end
    XUiHelper.RegisterClickEvent(self, self.Button, self.OnBtnFettersClick)
    
    self.ElementNode = XUiNodeElement.New(self.NodeElement)
    self.NodeTeam.gameObject:SetActiveEx(false)
    self.ImgKuang = XUiHelper.TryGetComponent(self.Transform, "NodeElement/ImgKuang")
    self.ImgKuang2 = XUiHelper.TryGetComponent(self.Transform, "NodeElement/ImgKuang2")
    if self.ImgKuang then self.ImgKuang.gameObject:SetActiveEx(false) end
    if self.ImgKuang2 then self.ImgKuang2.gameObject:SetActiveEx(false) end

    self:SetComboLevel(0)   --当前显示的羁绊等级
end

--combo: XTheatreCombo
function XUiFettersGrid:Refresh(combo, isShowBtnFetters, isShowEffect)
    self.Combo = combo
    if not combo then
        self:SetComboLevel(0)
        self.Gameobject:SetActiveEx(false)
        self:SetBtnFettersActive(isShowBtnFetters)
        return
    end

    self:SetComboLevel(combo:GetTotalRank())
    self.ElementNode:Refresh(combo)
    self:SetEffectActive(isShowEffect)
    self:SetBtnFettersActive(false)
    self.Gameobject:SetActiveEx(true)

    local isDecay = combo:GetComboIsHaveDecay() and combo:GetDisplayReferenceListIsHaveDecay()
    --腐化外框
    if self.ImgKuang then
        self.ImgKuang.gameObject:SetActiveEx(isDecay)
    end
    --满级外框
    if self.ImgKuang2 then
        self.ImgKuang2.gameObject:SetActiveEx(isDecay and self:GetComboLevel() >= combo:GetConditionLevel(combo:GetPhaseNum()))
    end
end

function XUiFettersGrid:SetBtnFettersActive(isActive)
    if self.BtnFetters then
        self.BtnFetters.gameObject:SetActiveEx(isActive)
    end
end

--打开羁绊预览界面
function XUiFettersGrid:OnBtnFettersClick()
    XLuaUiManager.Open("UiBiancaTheatreComboTips", self.Combo)
end

function XUiFettersGrid:SetEffectActive(isShowEffect)
    self.ElementNode:SetEffectActive(isShowEffect)
end

function XUiFettersGrid:GetCombo()
    return self.Combo
end

function XUiFettersGrid:SetComboLevel(level)
    self.ComboLevel = level
end

function XUiFettersGrid:GetComboLevel()
    return self.ComboLevel
end


---------------肉鸽2.0 羁绊通用展示面板-------------
local XUiBiancaTheatrePanelFetters = XClass(nil, "XUiBiancaTheatrePanelFetters")
local CSXResourceManagerLoad = CS.XResourceManager.Load
local FETTERS_COUNT = 5 --羁绊挂点的最大数量
local SHOW_COMBO_MAX_COUNT = 4  --可显示的羁绊最大数量
local BTN_FETTERS_DEFAULT_INDEX = 3 --显示更多羁绊按钮的默认节点位置下标

function XUiBiancaTheatrePanelFetters:Ctor(ui)
    self.Gameobject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.ResourcePool = {}
    self:Init()
    self:RegisterClickEvent()

    self.ComboList = XDataCenter.BiancaTheatreManager.GetComboList()
end

function XUiBiancaTheatrePanelFetters:Delete()
    for _, resource in pairs(self.ResourcePool) do
        resource:Release()
    end
    self.ResourcePool = {}
end

function XUiBiancaTheatrePanelFetters:Init()
    self.GridFettersNone = XUiHelper.TryGetComponent(self.Transform, "GridFettersNone")
    self.BtnOpen = XUiHelper.TryGetComponent(self.Transform, "GridFettersNone/BtnPutAway", "XUiButton")
    self.GridFetters = XUiHelper.TryGetComponent(self.Transform, "GridFetters")
    self.BtnClose = XUiHelper.TryGetComponent(self.Transform, "GridFetters/BtnPutAway", "XUiButton")
    self:InitFetters()
end

function XUiBiancaTheatrePanelFetters:InitFetters()
    self.FettersGridList = {}
    local gridFettersNode = self:ResourceManagerLoad(XBiancaTheatreConfigs.GetClientConfig("GridFettersAsset"))
    local btnFetters = self:ResourceManagerLoad(XBiancaTheatreConfigs.GetClientConfig("BtnFettersAsset"))
    local panelFetters
    for i = 1, FETTERS_COUNT do
        panelFetters = XUiHelper.TryGetComponent(self.GridFetters.transform, "PanelFetters/PanelFetters" .. i)
        if panelFetters and gridFettersNode then
            local gridFetter = XUiHelper.Instantiate(gridFettersNode.Asset, panelFetters)
            local btnFetter = XUiHelper.Instantiate(btnFetters.Asset, panelFetters)
            table.insert(self.FettersGridList, XUiFettersGrid.New(gridFetter, btnFetter))
        end
    end
    self:SetGridFettersActive(true)
end

function XUiBiancaTheatrePanelFetters:RegisterClickEvent()
    XUiHelper.RegisterClickEvent(self, self.BtnOpen, function() self:SetGridFettersActive(true) end)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, function() self:SetGridFettersActive(false) end)
end

--isCheckShowEffect：是否检查特效的显示
function XUiBiancaTheatrePanelFetters:Refresh(isCheckShowEffect)
    local activeComboList = self.ComboList:GetActiveComboList(nil, XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager():GetCurrentRoles())
    local fettersGrid
    table.sort(activeComboList, function(a, b) 
        local pA = a:GetPhaseLevel()
        local pB = b:GetPhaseLevel()
        if pA ~= pB then
            return pA > pB
        end
        local rA = a:GetTotalRank()
        local rB = b:GetTotalRank()
        return rA > rB
    end)

    local isShowEffect
    local isNotComboList = XTool.IsTableEmpty(activeComboList)
    for i, combo in ipairs(activeComboList) do
        if i > SHOW_COMBO_MAX_COUNT then break end
        fettersGrid = self.FettersGridList[i]
        if fettersGrid then
            local curCombo = fettersGrid:GetCombo()
            isShowEffect = (isCheckShowEffect) and 
                    (not curCombo or 
                    curCombo:GetComboId() ~= combo:GetComboId() or
                    fettersGrid:GetComboLevel() ~= combo:GetTotalRank())
            fettersGrid:Refresh(combo, false, isShowEffect)
        end
    end
    --“更多羁绊”按钮
    local btnFettersIndex = isNotComboList and BTN_FETTERS_DEFAULT_INDEX or math.min(#activeComboList + 1, FETTERS_COUNT)
    fettersGrid = self.FettersGridList[btnFettersIndex]
    if fettersGrid then
        fettersGrid:Refresh(nil, true)
    end
    --隐藏多余的格子
    local startIndex = isNotComboList and 0 or btnFettersIndex
    for i = startIndex + 1, FETTERS_COUNT do
        if not (isNotComboList and i == btnFettersIndex) then
            fettersGrid = self.FettersGridList[i]
            if fettersGrid then
                fettersGrid:Refresh()
            end
        end
    end
end

function XUiBiancaTheatrePanelFetters:SetGridFettersActive(isActive)
    if self.GridFetters then
        self.GridFetters.gameObject:SetActiveEx(isActive)
    end
    if self.GridFettersNone then
        self.GridFettersNone.gameObject:SetActiveEx(not isActive)
    end
    --隐藏所有羁绊格子的特效
    if not isActive then
        for _, fetterGrid in ipairs(self.FettersGridList) do
            fetterGrid:SetEffectActive(false)
        end
    end
end

function XUiBiancaTheatrePanelFetters:ResourceManagerLoad(path)
    local resource = self.ResourcePool[path]
    if resource then
        return resource
    end

    resource = CSXResourceManagerLoad(path)
    if resource == nil or not resource.Asset then
        XLog.Error(string.format("XUiBiancaTheatrePanelFetters:ResourceManagerLoad加载资源失败，路径：%s", path))
        return
    end

    self.ResourcePool[path] = resource
    return resource
end

return XUiBiancaTheatrePanelFetters