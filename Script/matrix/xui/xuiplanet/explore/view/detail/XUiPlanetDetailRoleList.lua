local XUiPlanetUtil = require("XUi/XUiPlanet/Explore/View/XUiPlanetUtil")
local XUiPlanetGridBuff = require("XUi/XUiPlanet/Explore/View/Stage/XUiPlanetGridBuff")
local XUiPlanetDetailGridAttr = require("XUi/XUiPlanet/Explore/View/Detail/XUiPlanetDetailGridAttr")
local XUiPlanetDetailRoleGrid = require("XUi/XUiPlanet/Explore/View/Detail/XUiPlanetDetailRoleGrid")
local ATTR = XPlanetCharacterConfigs.ATTR

---@class XUiPlanetDetailRoleList
local XUiPlanetDetailRoleList = XClass(nil, "XUiPlanetDetailRoleList")

function XUiPlanetDetailRoleList:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    XUiHelper.RegisterClickEvent(self, self.BtnHelp, self.OpenDescAttr)
    XUiHelper.RegisterClickEvent(self, self.BtnFight, self.OnClickCaptain)
    self.BtnFight.gameObject:SetActiveEx(true)
    self.TxtGuardian.gameObject:SetActiveEx(false)
    self.PanelProperty.gameObject:SetActiveEx(false)
    self.ImgBuffBg.gameObject:SetActiveEx(false)
    self.ImgDeBuffBg.gameObject:SetActiveEx(false)
    self.GridRole.gameObject:SetActiveEx(false)

    self._StageId = XDataCenter.PlanetManager:GetStageData():GetStageId()
    ---@type XPlanetRoleBase[]
    self._CharacterList = {}
    self._GridPropertyList = {}
    ---@type XUiPlanetDetailRoleGrid[]
    self._GridRoleList = {}
    ---@type XUiPlanetGridBuff[]
    self._GridBuffList = {}
    ---@type XUiPlanetGridBuff[]
    self._GridDeBuffList = {}
    self._CharacterSelected = false
end

function XUiPlanetDetailRoleList:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_PLANET_UPDATE_DETAIL, self.UpdateAttr, self)
end

function XUiPlanetDetailRoleList:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_PLANET_UPDATE_DETAIL, self.UpdateAttr, self)
end

function XUiPlanetDetailRoleList:Update()
    local roleBase = self._CharacterSelected
    self.RImgRole:SetRawImage(roleBase:GetIcon())
    self.TxtName.text = roleBase:GetName()
    self:UpdateCaptain()
    self:UpdateBuff()
    self:UpdateAttr()
end

function XUiPlanetDetailRoleList:HideAllAttr()
    for i = 1, #self._GridPropertyList do
        local grid = self._GridPropertyList[i]
        if grid then
            grid.GameObject:SetActiveEx(false)
        end
    end
end

function XUiPlanetDetailRoleList:SetAttr(index, attrType, textValue)
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

function XUiPlanetDetailRoleList:OnClickCaptain()
    if not self._CharacterSelected then
        return
    end
    --XEventManager.DispatchEvent(XEventId.EVENT_PLANET_SET_CAPTAIN, self._CharacterSelected)
    if not self._CharacterSelected:IsPlayer() then
        return
    end
    XDataCenter.PlanetExploreManager.SetCaptain(self._CharacterSelected:GetCharacterId(), function()
        self:SetCaptainFirst()
        self:UpdateCaptain()
    end)
end

function XUiPlanetDetailRoleList:OpenDescAttr()
    XLuaUiManager.Open("UiPlanetPropertyDetail")
end

function XUiPlanetDetailRoleList:UpdateAttr()
    local character = self._CharacterSelected
    local baseAttr = character:GetAttr()
    self.TxtNum.text = XPlanetExploreConfigs.GetFightingPowerByAttrList(baseAttr)

    local hp = baseAttr[ATTR.Life] or 0
    local hpMax = baseAttr[ATTR.MaxLife] or 1
    if hpMax <= 0 then
        hp = 0
    else
        hp = hp / hpMax
    end
    XUiPlanetUtil.SetHp(self.ImgHp, hp)

    self:HideAllAttr()
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
end

function XUiPlanetDetailRoleList:UpdateBuff()
    local buffList, debuffList = self._CharacterSelected:GetBuff()
    for i, buff in pairs(buffList) do
        local go = XUiHelper.Instantiate(self.ImgBuffBg.gameObject, self.ImgBuffBg.transform.parent)
        local buffGrid = self._GridBuffList[i]
        if not buffGrid then
            buffGrid = XUiPlanetGridBuff.New(go)
            self._GridBuffList[i] = buffGrid
        end
        buffGrid:Update(buff)
        buffGrid.GameObject:SetActiveEx(true)
    end
    if #buffList > 0 then
        self.PanelBuff.gameObject:SetActiveEx(true)
        self.PanelNoBuff.gameObject:SetActiveEx(false)
    else
        self.PanelBuff.gameObject:SetActiveEx(false)
        self.PanelNoBuff.gameObject:SetActiveEx(true)
    end

    for i, buff in pairs(debuffList) do
        local go = XUiHelper.Instantiate(self.ImgDeBuffBg.gameObject, self.ImgDeBuffBg.transform.parent)
        local buffGrid = self._GridDeBuffList[i]
        if not buffGrid then
            buffGrid = XUiPlanetGridBuff.New(go)
            self._GridDeBuffList[i] = buffGrid
        end
        buffGrid:Update(buff)
        buffGrid.GameObject:SetActiveEx(true)
    end
    if #debuffList > 0 then
        self.PanelDeBuff.gameObject:SetActiveEx(true)
        self.PanelNoDeBuff.gameObject:SetActiveEx(false)
    else
        self.PanelDeBuff.gameObject:SetActiveEx(false)
        self.PanelNoDeBuff.gameObject:SetActiveEx(true)
    end
end

function XUiPlanetDetailRoleList:UpdateRoleList()
    local characterList = self._CharacterList
    for i = 1, #characterList do
        local character = characterList[i]
        ---@type XUiPlanetDetailRoleGrid
        local grid = self._GridRoleList[i]
        if not grid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridRole, self.GridRole.parent.transform)
            grid = XUiPlanetDetailRoleGrid.New(ui)
            self._GridRoleList[i] = grid
            grid:RegisterClick(function()
                local role = grid:GetRole()
                self:SetRoleSelected(role)
                role:RequestUpdateAttr()
            end)
        end
        grid.GameObject:SetActiveEx(true)
        grid:Update(character)
    end
    for i = #characterList + 1, #self._GridRoleList do
        local grid = self._GridRoleList[i]
        grid.gameObject:SetActiveEx(false)
    end
end

---@param roleList XPlanetRoleBase
function XUiPlanetDetailRoleList:SetRoleList(roleList)
    self._CharacterList = roleList
    self:UpdateRoleList()
end

---@param role XPlanetRoleBase
function XUiPlanetDetailRoleList:SetRoleSelected(role)
    self._CharacterSelected = role
    self:Update()
    self:UpdateSelected()
end

function XUiPlanetDetailRoleList:UpdateSelected()
    for i = 1, #self._GridRoleList do
        local grid = self._GridRoleList[i]
        grid:UpdateSelected(self._CharacterSelected)
    end
end

function XUiPlanetDetailRoleList:SetCaptainFirst()
    -- 将队长移到第一位
    local index
    for i = 1, #self._CharacterList do
        local character = self._CharacterList[i]
        if character == self._CharacterSelected then
            index = i
            break
        end
    end
    if index and index ~= 1 then
        table.remove(self._CharacterList, index)
        table.insert(self._CharacterList, 1, self._CharacterSelected)
    end
    self:UpdateRoleList()
    self:UpdateSelected()
end

function XUiPlanetDetailRoleList:UpdateCaptain()
    local roleBase = self._CharacterSelected
    local explore = XDataCenter.PlanetExploreManager.GetExplore()
    if roleBase:IsPlayer() then
        if explore:IsCaptain(roleBase:GetUid()) then
            self.BtnFight:SetButtonState(CS.UiButtonState.Disable)
            self.BtnFight:SetDisable(true)
        else
            self.BtnFight:SetButtonState(CS.UiButtonState.Normal)
            self.BtnFight:SetDisable(false)
        end
    else
        self.BtnFight.gameObject:SetActiveEx(false)
    end

    local entityLeader = explore:GetCaptain()
    for i = 1, #self._GridRoleList do
        local grid = self._GridRoleList[i]
        grid:UpdateCaptain(entityLeader)
    end
end

return XUiPlanetDetailRoleList