local XUiPlanetGridBuff = require("XUi/XUiPlanet/Explore/View/Stage/XUiPlanetGridBuff")
local XUiPlanetDetailGridAttr = require("XUi/XUiPlanet/Explore/View/Detail/XUiPlanetDetailGridAttr")
local ATTR = XPlanetCharacterConfigs.ATTR

---@class XUiPlanetDetailRole
local XUiPlanetDetailRole = XClass(nil, "XUiPlanetDetailRole")

function XUiPlanetDetailRole:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    XUiHelper.RegisterClickEvent(self, self.BtnHelp, self.OpenDescAttr)
    self.BtnFight.gameObject:SetActiveEx(false)
    self.BtnBoss = XUiHelper.TryGetComponent(self.BtnFight.transform.parent, "BtnBoss", "XUiButton")
    XUiHelper.RegisterClickEvent(self, self.BtnBoss, self.OnClickBoss)

    self.PanelProperty.gameObject:SetActiveEx(false)
    self._GridPropertyList = {}
    local stageId = XDataCenter.PlanetManager.GetStageData():GetStageId()
    self._StageId = stageId
    self._Boss = false

    ---@type XUiPlanetGridBuff[]
    self._GridBuffList = {}
    self._GridDebuffList = {}
end

function XUiPlanetDetailRole:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_PLANET_UPDATE_DETAIL, self.Update, self)
end

function XUiPlanetDetailRole:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_PLANET_UPDATE_DETAIL, self.Update, self)
end

---@param boss XPlanetBoss
function XUiPlanetDetailRole:Update(boss)
    if not boss then
        boss = self._Boss
    else
        self._Boss = boss
    end
    self.RImgRole:SetRawImage(boss:GetIcon())
    local attrList = boss:GetAttr()

    local fightingPower = boss:GetFightingPower()
    self.TxtNum.text = fightingPower
    self.TxtName.text = boss:GetName()

    local baseAttr = attrList
    local hp = baseAttr[ATTR.Life] or 0
    local hpMax = baseAttr[ATTR.MaxLife] or 1
    if hpMax <= 0 then
        hp = 0
    else
        hp = hp / hpMax
    end
    self.ImgHp.fillAmount = hp

    self:SetAttr(1, ATTR.Life, string.format("%d/%d", baseAttr[ATTR.Life] or 0, baseAttr[ATTR.MaxLife] or 0))
    self:SetAttr(2, ATTR.Attack, baseAttr[ATTR.Attack])
    local defense = baseAttr[ATTR.Defense]
    if defense and defense ~= 0 then
        self:SetAttr(3, ATTR.Defense, defense)
    end

    local criticalChance = baseAttr[ATTR.CriticalChance]
    if criticalChance and criticalChance ~= 0 then
        self:SetAttr(4, ATTR.CriticalChance, criticalChance)
    end

    local criticalDamage = baseAttr[ATTR.CriticalDamage]
    if criticalDamage and criticalDamage ~= 0 then
        self:SetAttr(5, ATTR.CriticalDamage, criticalDamage)
    end

    local speed = baseAttr[ATTR.AttackSpeed]
    if speed and speed ~= 0 then
        self:SetAttr(6, ATTR.AttackSpeed, speed)
    end

    self:UpdateBuff(boss)

    if boss:IsSpecialBoss() then
        local stageData = XDataCenter.PlanetManager.GetStageData()
        local curRound = stageData:GetCycle() - 1
        local maxRound = boss:GetRound2Born()
        self.TxtGuardianTime.text = XUiHelper.GetText("PlanetRunningBossRound", curRound, maxRound)
        self.TxtGuardian.gameObject:SetActiveEx(true)
    else
        self.TxtGuardian.gameObject:SetActiveEx(false)
    end

    if boss:IsSpecialBoss() and boss:IsAlive() then
        self.BtnBoss.gameObject:SetActiveEx(false)
        self.TxtGuardian.gameObject:SetActiveEx(false)
        if self.TxtGuardian02 then
            self.TxtGuardian02.gameObject:SetActiveEx(true)
        end
    else
        if self.TxtGuardian02 then
            self.TxtGuardian02.gameObject:SetActiveEx(false)
        end
        self.BtnBoss.gameObject:SetActiveEx(true)
    end
end

---@param boss XPlanetBoss
function XUiPlanetDetailRole:UpdateBuff(boss)
    --生效的effect
    self.ImgBuffBg.gameObject:SetActiveEx(false)
    self.ImgDeBuffBg.gameObject:SetActiveEx(false)
    local buffList, debuffList = boss:GetBuff()
    for i, buff in pairs(buffList) do
        local buffGrid = self._GridBuffList[i]
        if not buffGrid then
            local go = XUiHelper.Instantiate(self.ImgBuffBg.gameObject, self.ImgBuffBg.transform.parent)
            buffGrid = XUiPlanetGridBuff.New(go)
            self._GridBuffList[i] = buffGrid
        end
        buffGrid:Update(buff)
        buffGrid.GameObject:SetActiveEx(true)
    end
    for i = #buffList + 1, #self._GridBuffList do
        local grid = self._GridBuffList[i]
        grid.GameObject:SetActiveEx(false)
    end
    if #buffList > 0 then
        self.PanelBuff.gameObject:SetActiveEx(true)
        self.PanelNoBuff.gameObject:SetActiveEx(false)
    else
        self.PanelBuff.gameObject:SetActiveEx(false)
        self.PanelNoBuff.gameObject:SetActiveEx(true)
    end

    for i, buff in pairs(debuffList) do
        local buffGrid = self._GridDebuffList[i]
        if not buffGrid then
            local go = XUiHelper.Instantiate(self.ImgDeBuffBg.gameObject, self.ImgDeBuffBg.transform.parent)
            buffGrid = XUiPlanetGridBuff.New(go)
            self._GridDebuffList[i] = buffGrid
        end
        buffGrid:Update(buff)
        buffGrid.GameObject:SetActiveEx(true)
    end
    for i = #debuffList + 1, #self._GridDebuffList do
        local grid = self._GridDebuffList[i]
        grid.GameObject:SetActiveEx(false)
    end
    if #debuffList > 0 then
        self.PanelDeBuff.gameObject:SetActiveEx(true)
        self.PanelNoDeBuff.gameObject:SetActiveEx(false)
    else
        self.PanelDeBuff.gameObject:SetActiveEx(false)
        self.PanelNoDeBuff.gameObject:SetActiveEx(true)
    end
end

function XUiPlanetDetailRole:SetAttr(index, attrType, textValue)
    local grid = self._GridPropertyList[index]
    if not grid then
        local uiGrid = CS.UnityEngine.Object.Instantiate(self.PanelProperty, self.PanelProperty.transform.parent)
        grid = XUiPlanetDetailGridAttr.New(uiGrid)
        self._GridPropertyList[index] = grid
    end
    grid.GameObject:SetActiveEx(true)
    textValue = XPlanetCharacterConfigs.GetAttrValue4Ui(attrType, textValue)
    grid:Update(XPlanetCharacterConfigs.GetAttrName(attrType), textValue)
end

function XUiPlanetDetailRole:OpenDescAttr()
    XLuaUiManager.Open("UiPlanetPropertyDetail")
end

function XUiPlanetDetailRole:OnClickBoss()
    XDataCenter.PlanetExploreManager.RequestSummonBoss(function()
        -- 召唤后, 就关闭此界面了
        --self.BtnBoss.gameObject:SetActiveEx(false)
    end)
end

return XUiPlanetDetailRole