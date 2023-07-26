--######################## XUiBiancaTheatreRoleGrid ########################
local XUiBattleRoomRoleGrid = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleGrid")
---@class XUiBiancaTheatreRoleGrid:XUiBattleRoomRoleGrid
local XUiBiancaTheatreRoleGrid = XClass(XUiBattleRoomRoleGrid, "XUiBiancaTheatreRoleGrid")

-- function XUiBiancaTheatreRoleGrid:Ctor()
--     self.RImgCharElementList = {}
--     self.RImgCharElement.gameObject:SetActiveEx(false)
-- end

--entity：XAdventureRole
function XUiBiancaTheatreRoleGrid:SetData(entity)
    self.Super.SetData(self, entity)
    -- --战力
    -- self.TxtPower.text = entity:GetAbility()
    -- --头像
    local characterViewModel = entity:GetCharacterViewModel()
    -- self.RImgHeadIcon:SetRawImage(characterViewModel:GetSmallHeadIcon())
    -- --元素图标
    -- local obtainElementIcons = characterViewModel:GetObtainElementIcons()
    -- local elementIcon, rImgCharElement
    -- for i = 1, 3 do
    --     elementIcon = obtainElementIcons[i]
    --     rImgCharElement = self.RImgCharElementList[i]
    --     if not rImgCharElement then
    --         rImgCharElement = XUiHelper.Instantiate(self.RImgCharElement, self.PanelIcon)
    --         self.RImgCharElementList[i] = rImgCharElement
    --     end

    --     if elementIcon then
    --         rImgCharElement:SetRawImage(elementIcon)
    --     end
    --     rImgCharElement.gameObject:SetActiveEx(elementIcon ~= nil)
    -- end
    --星星数
    self.PanelStar.text = entity:GetLevel()
    self.PanelStar.gameObject:SetActiveEx(true)
    self.PanelTry.gameObject:SetActiveEx(XEntityHelper.GetIsRobot(characterViewModel:GetSourceEntityId()))
    self.RImgQuality.gameObject:SetActiveEx(false)
end

function XUiBiancaTheatreRoleGrid:UpdateFight()
    if self.IsFragment then
        self.PanelFight.gameObject:SetActiveEx(false)
        return
    end

    self.PanelFight.gameObject:SetActiveEx(true)
    self.TxtFight.gameObject:SetActiveEx(true)
    self.TxtFight.text = self.Character:GetCharacterViewModel():GetAbility()
end

--######################## XUiBiancaTheatreBattleRoomRoleDetail ########################
local XUiBattleRoomRoleDetailDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleDetailDefaultProxy")

---@class XUiBiancaTheatreBattleRoomRoleDetail:XUiBattleRoomRoleDetailDefaultProxy
local XUiBiancaTheatreBattleRoomRoleDetail = XClass(XUiBattleRoomRoleDetailDefaultProxy, "XUiBiancaTheatreBattleRoomRoleDetail")

function XUiBiancaTheatreBattleRoomRoleDetail:Ctor()
    self.TheatreManager = XDataCenter.BiancaTheatreManager
    self.AdventureManager = self.TheatreManager.GetCurrentAdventureManager()
    self.Chapter = self.AdventureManager:GetCurrentChapter()
end

function XUiBiancaTheatreBattleRoomRoleDetail:AOPOnStartAfter(rootUi)
    local curCharacterType = rootUi.CurrentCharacterType
    local characterList = rootUi.FiltSortListTypeDic[curCharacterType] or rootUi.Proxy:SortEntitiesWithTeam(rootUi.Team, rootUi.Proxy:GetEntities(curCharacterType))
    if XTool.IsTableEmpty(characterList) then
        rootUi.CurrentCharacterType = curCharacterType == XCharacterConfigs.CharacterType.Normal and XCharacterConfigs.CharacterType.Isomer or XCharacterConfigs.CharacterType.Normal
    end
    -- 界定音效滤镜界限
    XDataCenter.BiancaTheatreManager.ResetAudioFilter()
end

-- characterType : XCharacterConfigs.CharacterType
function XUiBiancaTheatreBattleRoomRoleDetail:GetEntities(characterType)
    local roles = self.AdventureManager:GetCurrentRoles(true)
    -- local result = {}
    -- for _, role in ipairs(roles) do
    --     if role:GetCharacterViewModel():GetCharacterType() == characterType then
    --         table.insert(result, role)
    --     end
    -- end
    return roles
end

function XUiBiancaTheatreBattleRoomRoleDetail:GetCharacterViewModelByEntityId(entityId)
    local role = self.AdventureManager:GetRole(entityId)
    if role == nil then return nil end
    return role:GetCharacterViewModel()
end

-- team : XTeam
-- sortTagType : XRoomCharFilterTipsConfigs.EnumSortTag
function XUiBiancaTheatreBattleRoomRoleDetail:SortEntitiesWithTeam(team, entities, sortTagType)
    table.sort(entities, function(entityA, entityB)
        local _, posA = team:GetEntityIdIsInTeam(entityA:GetId())
        local _, posB = team:GetEntityIdIsInTeam(entityB:GetId())
        local teamWeightA = posA ~= -1 and (10 - posA) * 100000 or 0
        local teamWeightB = posB ~= -1 and (10 - posB) * 100000 or 0
        teamWeightA = teamWeightA + entityA:GetAbility()
        teamWeightB = teamWeightB + entityB:GetAbility()
        if teamWeightA == teamWeightB then
            return entityA:GetId() > entityB:GetId()
        else
            return teamWeightA > teamWeightB
        end
    end)
    return entities
end

function XUiBiancaTheatreBattleRoomRoleDetail:GetGridProxy()
    return XUiBiancaTheatreRoleGrid
end

-- 获取角色战力
function XUiBiancaTheatreBattleRoomRoleDetail:GetRoleAbility(entityId)
    local role = self.AdventureManager:GetRole(entityId)
    if role then
        return role:GetAbility()
    end
    return 0
end

function XUiBiancaTheatreBattleRoomRoleDetail:GetRoleDynamicGrid(rootUi)
    return rootUi.GridCharacterBiancaTheatre
end

return XUiBiancaTheatreBattleRoomRoleDetail